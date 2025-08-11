public with sharing class OktaService {
    
    private static OktaConfiguration__mdt oktaConfig = getOktaConfiguration();
    
    public class OktaResponse {
        public Boolean success;
        public String message;
        public Object data;
        
        public OktaResponse(Boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data = data;
        }
    }
    
    public class OktaUser {
        public String id;
        public String email;
        public String firstName;
        public String lastName;
        public String login;
        public String status;
        
        public OktaUser() {}
        
        public OktaUser(String email, String firstName, String lastName) {
            this.email = email;
            this.firstName = firstName;
            this.lastName = lastName;
            this.login = email;
        }
    }
    
    public class OktaAuthResult {
        public String accessToken;
        public String refreshToken;
        public String idToken;
        public Integer expiresIn;
        public OktaUser user;
        
        public OktaAuthResult() {}
    }
    
    private static OktaConfiguration__mdt getOktaConfiguration() {
        try {
            return [SELECT OktaDomain__c, ClientId__c, ClientSecret__c, RedirectUri__c, ApiToken__c 
                   FROM OktaConfiguration__mdt 
                   WHERE DeveloperName = 'OktaConfig' 
                   LIMIT 1];
        } catch (Exception e) {
            System.debug('Error retrieving Okta configuration: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static OktaResponse authenticateUser(String username, String password) {
        try {
            if (oktaConfig == null) {
                return new OktaResponse(false, 'Okta configuration not found', null);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/api/v1/authn');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'username' => username,
                'password' => password
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String status = (String) responseData.get('status');
                
                if (status == 'SUCCESS') {
                    String sessionToken = (String) responseData.get('sessionToken');
                    OktaAuthResult authResult = exchangeSessionToken(sessionToken);
                    
                    if (authResult != null) {
                        return new OktaResponse(true, 'Authentication successful', authResult);
                    } else {
                        return new OktaResponse(false, 'Failed to exchange session token', null);
                    }
                } else {
                    return new OktaResponse(false, 'Authentication failed: ' + status, null);
                }
            } else {
                return new OktaResponse(false, 'Authentication failed: ' + res.getBody(), null);
            }
        } catch (Exception e) {
            System.debug('Error in authenticateUser: ' + e.getMessage());
            return new OktaResponse(false, 'Authentication error: ' + e.getMessage(), null);
        }
    }
    
    private static OktaAuthResult exchangeSessionToken(String sessionToken) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/oauth2/v1/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/json');
            
            String clientCredentials = EncodingUtil.base64Encode(Blob.valueOf(oktaConfig.ClientId__c + ':' + oktaConfig.ClientSecret__c));
            req.setHeader('Authorization', 'Basic ' + clientCredentials);
            
            String requestBody = 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' +
                               '&subject_token=' + sessionToken +
                               '&subject_token_type=urn:ietf:params:oauth:token-type:access_token' +
                               '&scope=openid profile email';
            
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                OktaAuthResult authResult = new OktaAuthResult();
                authResult.accessToken = (String) responseData.get('access_token');
                authResult.refreshToken = (String) responseData.get('refresh_token');
                authResult.idToken = (String) responseData.get('id_token');
                authResult.expiresIn = (Integer) responseData.get('expires_in');
                
                // Get user info
                authResult.user = getUserInfo(authResult.accessToken);
                
                return authResult;
            }
        } catch (Exception e) {
            System.debug('Error exchanging session token: ' + e.getMessage());
        }
        
        return null;
    }
    
    @AuraEnabled
    public static OktaResponse createUser(String email, String firstName, String lastName, String password) {
        try {
            if (oktaConfig == null) {
                return new OktaResponse(false, 'Okta configuration not found', null);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/api/v1/users?activate=true');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'SSWS ' + oktaConfig.ApiToken__c);
            
            Map<String, Object> profile = new Map<String, Object>{
                'firstName' => firstName,
                'lastName' => lastName,
                'email' => email,
                'login' => email
            };
            
            Map<String, Object> credentials = new Map<String, Object>{
                'password' => new Map<String, Object>{
                    'value' => password
                }
            };
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'profile' => profile,
                'credentials' => credentials
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return new OktaResponse(true, 'User created successfully', responseData);
            } else {
                return new OktaResponse(false, 'User creation failed: ' + res.getBody(), null);
            }
        } catch (Exception e) {
            System.debug('Error in createUser: ' + e.getMessage());
            return new OktaResponse(false, 'User creation error: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static OktaResponse updateUser(String userId, String email, String firstName, String lastName) {
        try {
            if (oktaConfig == null) {
                return new OktaResponse(false, 'Okta configuration not found', null);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/api/v1/users/' + userId);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'SSWS ' + oktaConfig.ApiToken__c);
            
            Map<String, Object> profile = new Map<String, Object>{
                'firstName' => firstName,
                'lastName' => lastName,
                'email' => email,
                'login' => email
            };
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'profile' => profile
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return new OktaResponse(true, 'User updated successfully', responseData);
            } else {
                return new OktaResponse(false, 'User update failed: ' + res.getBody(), null);
            }
        } catch (Exception e) {
            System.debug('Error in updateUser: ' + e.getMessage());
            return new OktaResponse(false, 'User update error: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static OktaResponse getUserInfo(String accessToken) {
        try {
            if (oktaConfig == null) {
                return new OktaResponse(false, 'Okta configuration not found', null);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/oauth2/v1/userinfo');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                OktaUser user = new OktaUser();
                user.email = (String) responseData.get('email');
                user.firstName = (String) responseData.get('given_name');
                user.lastName = (String) responseData.get('family_name');
                user.login = (String) responseData.get('preferred_username');
                
                return new OktaResponse(true, 'User info retrieved successfully', user);
            } else {
                return new OktaResponse(false, 'Failed to get user info: ' + res.getBody(), null);
            }
        } catch (Exception e) {
            System.debug('Error in getUserInfo: ' + e.getMessage());
            return new OktaResponse(false, 'Get user info error: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static OktaResponse refreshAccessToken(String refreshToken) {
        try {
            if (oktaConfig == null) {
                return new OktaResponse(false, 'Okta configuration not found', null);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://' + oktaConfig.OktaDomain__c + '/oauth2/v1/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/json');
            
            String clientCredentials = EncodingUtil.base64Encode(Blob.valueOf(oktaConfig.ClientId__c + ':' + oktaConfig.ClientSecret__c));
            req.setHeader('Authorization', 'Basic ' + clientCredentials);
            
            String requestBody = 'grant_type=refresh_token&refresh_token=' + refreshToken;
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return new OktaResponse(true, 'Token refreshed successfully', responseData);
            } else {
                return new OktaResponse(false, 'Token refresh failed: ' + res.getBody(), null);
            }
        } catch (Exception e) {
            System.debug('Error in refreshAccessToken: ' + e.getMessage());
            return new OktaResponse(false, 'Token refresh error: ' + e.getMessage(), null);
        }
    }
}