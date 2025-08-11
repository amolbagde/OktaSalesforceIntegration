public with sharing class SamlUtility {
    
    public class SamlRequest {
        public String samlRequestId;
        public String samlRequest;
        public String relayState;
        public String redirectUrl;
        
        public SamlRequest() {
            this.samlRequestId = generateRequestId();
        }
    }
    
    public class SamlResponse {
        public Boolean isValid;
        public String nameId;
        public String email;
        public String firstName;
        public String lastName;
        public Map<String, String> attributes;
        public String errorMessage;
        
        public SamlResponse() {
            this.attributes = new Map<String, String>();
        }
    }
    
    public static SamlRequest generateSamlRequest(OktaConfiguration__mdt config, String relayState) {
        try {
            SamlRequest samlReq = new SamlRequest();
            
            String issueInstant = DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            String acsUrl = config.SamlCallbackUrl__c;
            String issuer = getSalesforceIssuer();
            
            String samlRequestXml = 
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ' +
                'xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ' +
                'ID="' + samlReq.samlRequestId + '" ' +
                'Version="2.0" ' +
                'IssueInstant="' + issueInstant + '" ' +
                'Destination="' + config.SamlSsoUrl__c + '" ' +
                'AssertionConsumerServiceURL="' + acsUrl + '" ' +
                'ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST">' +
                '<saml:Issuer>' + issuer + '</saml:Issuer>' +
                '<samlp:NameIDPolicy Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" ' +
                'AllowCreate="true"/>' +
                '</samlp:AuthnRequest>';
            
            // Encode the SAML request
            Blob samlBlob = Blob.valueOf(samlRequestXml);
            String encodedSamlRequest = EncodingUtil.base64Encode(samlBlob);
            
            samlReq.samlRequest = encodedSamlRequest;
            samlReq.relayState = relayState;
            
            // Create redirect URL
            String redirectUrl = config.SamlSsoUrl__c + 
                '?SAMLRequest=' + EncodingUtil.urlEncode(encodedSamlRequest, 'UTF-8');
            
            if (String.isNotBlank(relayState)) {
                redirectUrl += '&RelayState=' + EncodingUtil.urlEncode(relayState, 'UTF-8');
            }
            
            samlReq.redirectUrl = redirectUrl;
            
            return samlReq;
            
        } catch (Exception e) {
            System.debug('Error generating SAML request: ' + e.getMessage());
            return null;
        }
    }
    
    public static SamlResponse parseSamlResponse(String samlResponseBase64, OktaConfiguration__mdt config) {
        SamlResponse response = new SamlResponse();
        
        try {
            // Decode the SAML response
            Blob samlBlob = EncodingUtil.base64Decode(samlResponseBase64);
            String samlXml = samlBlob.toString();
            
            System.debug('SAML Response XML: ' + samlXml);
            
            // Validate the signature (simplified - in production use proper XML signature validation)
            if (!validateSamlSignature(samlXml, config.SamlCertificate__c)) {
                response.isValid = false;
                response.errorMessage = 'Invalid SAML signature';
                return response;
            }
            
            // Parse XML to extract user information
            Dom.Document doc = new Dom.Document();
            doc.load(samlXml);
            
            Dom.XMLNode rootNode = doc.getRootElement();
            
            // Extract NameID
            String nameId = extractNameId(rootNode);
            if (String.isBlank(nameId)) {
                response.isValid = false;
                response.errorMessage = 'NameID not found in SAML response';
                return response;
            }
            
            response.nameId = nameId;
            response.email = nameId; // Assuming NameID is email
            
            // Extract attributes
            Map<String, String> attributes = extractAttributes(rootNode);
            response.attributes = attributes;
            
            // Map standard attributes
            response.firstName = attributes.get('firstName') != null ? 
                attributes.get('firstName') : attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname');
            
            response.lastName = attributes.get('lastName') != null ? 
                attributes.get('lastName') : attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname');
            
            if (String.isBlank(response.email)) {
                response.email = attributes.get('email') != null ? 
                    attributes.get('email') : attributes.get('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress');
            }
            
            response.isValid = true;
            
        } catch (Exception e) {
            System.debug('Error parsing SAML response: ' + e.getMessage());
            response.isValid = false;
            response.errorMessage = 'Error parsing SAML response: ' + e.getMessage();
        }
        
        return response;
    }
    
    public static String generateLogoutRequest(OktaConfiguration__mdt config, String nameId, String sessionIndex) {
        try {
            String requestId = generateRequestId();
            String issueInstant = DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            String issuer = getSalesforceIssuer();
            
            String logoutRequestXml = 
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ' +
                'xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ' +
                'ID="' + requestId + '" ' +
                'Version="2.0" ' +
                'IssueInstant="' + issueInstant + '" ' +
                'Destination="' + config.SamlLogoutUrl__c + '">' +
                '<saml:Issuer>' + issuer + '</saml:Issuer>' +
                '<saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">' + 
                nameId + '</saml:NameID>';
            
            if (String.isNotBlank(sessionIndex)) {
                logoutRequestXml += '<samlp:SessionIndex>' + sessionIndex + '</samlp:SessionIndex>';
            }
            
            logoutRequestXml += '</samlp:LogoutRequest>';
            
            // Encode the logout request
            Blob logoutBlob = Blob.valueOf(logoutRequestXml);
            return EncodingUtil.base64Encode(logoutBlob);
            
        } catch (Exception e) {
            System.debug('Error generating logout request: ' + e.getMessage());
            return null;
        }
    }
    
    private static String extractNameId(Dom.XMLNode rootNode) {
        try {
            // Navigate through the XML structure to find NameID
            for (Dom.XMLNode child : rootNode.getChildElements()) {
                if (child.getName() == 'Assertion') {
                    for (Dom.XMLNode assertionChild : child.getChildElements()) {
                        if (assertionChild.getName() == 'Subject') {
                            for (Dom.XMLNode subjectChild : assertionChild.getChildElements()) {
                                if (subjectChild.getName() == 'NameID') {
                                    return subjectChild.getText();
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error extracting NameID: ' + e.getMessage());
        }
        return null;
    }
    
    private static Map<String, String> extractAttributes(Dom.XMLNode rootNode) {
        Map<String, String> attributes = new Map<String, String>();
        
        try {
            // Navigate to AttributeStatement
            for (Dom.XMLNode child : rootNode.getChildElements()) {
                if (child.getName() == 'Assertion') {
                    for (Dom.XMLNode assertionChild : child.getChildElements()) {
                        if (assertionChild.getName() == 'AttributeStatement') {
                            for (Dom.XMLNode attrChild : assertionChild.getChildElements()) {
                                if (attrChild.getName() == 'Attribute') {
                                    String attrName = attrChild.getAttribute('Name', null);
                                    for (Dom.XMLNode valueChild : attrChild.getChildElements()) {
                                        if (valueChild.getName() == 'AttributeValue') {
                                            attributes.put(attrName, valueChild.getText());
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error extracting attributes: ' + e.getMessage());
        }
        
        return attributes;
    }
    
    private static Boolean validateSamlSignature(String samlXml, String certificate) {
        // Simplified signature validation
        // In production, implement proper XML signature validation using the certificate
        try {
            // Basic checks
            if (String.isBlank(samlXml) || String.isBlank(certificate)) {
                return false;
            }
            
            // Check if the response contains signature element
            return samlXml.contains('<ds:Signature') || samlXml.contains('<Signature');
            
            // TODO: Implement actual signature verification using the certificate
            // This would involve validating the XML signature against the provided certificate
            
        } catch (Exception e) {
            System.debug('Error validating SAML signature: ' + e.getMessage());
            return false;
        }
    }
    
    private static String generateRequestId() {
        // Generate a unique request ID
        String timestamp = String.valueOf(DateTime.now().getTime());
        String randomString = String.valueOf(Math.random()).substring(2, 8);
        return 'SFDC_' + timestamp + '_' + randomString;
    }
    
    private static String getSalesforceIssuer() {
        // Return the Salesforce organization as the issuer
        return 'https://' + URL.getOrgDomainUrl().getHost();
    }
    
    public static String createSamlRedirectForm(String samlRequest, String targetUrl, String relayState) {
        String form = '<html><body onload="document.forms[0].submit()">' +
            '<form method="post" action="' + targetUrl + '">' +
            '<input type="hidden" name="SAMLRequest" value="' + samlRequest + '"/>';
        
        if (String.isNotBlank(relayState)) {
            form += '<input type="hidden" name="RelayState" value="' + relayState + '"/>';
        }
        
        form += '<noscript>' +
            '<input type="submit" value="Continue"/>' +
            '</noscript>' +
            '</form></body></html>';
        
        return form;
    }
}