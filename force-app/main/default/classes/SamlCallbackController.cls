public with sharing class SamlCallbackController {
    
    public String samlResponse { get; set; }
    public String relayState { get; set; }
    public String errorMessage { get; set; }
    public Boolean hasError { get; set; }
    public Boolean isProcessing { get; set; }
    
    public SamlCallbackController() {
        this.hasError = false;
        this.isProcessing = true;
        
        // Get SAML response from POST parameters
        this.samlResponse = ApexPages.currentPage().getParameters().get('SAMLResponse');
        this.relayState = ApexPages.currentPage().getParameters().get('RelayState');
        
        if (String.isNotBlank(this.samlResponse)) {
            processSamlResponse();
        } else {
            this.hasError = true;
            this.errorMessage = 'No SAML response received';
            this.isProcessing = false;
        }
    }
    
    private void processSamlResponse() {
        try {
            UserManagementController.UserManagementResponse result = 
                UserManagementController.processSamlLogin(this.samlResponse);
            
            if (result.success) {
                // Authentication successful
                UserManagementController.UserSession userSession = 
                    (UserManagementController.UserSession) result.data;
                
                // Store session information
                storeUserSession(userSession);
                
                // Redirect to the intended page or dashboard
                String redirectUrl = getRedirectUrl();
                
                // Use JavaScript to redirect
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                    'Authentication successful. Redirecting...'));
                
                this.isProcessing = false;
                
                // Set up client-side redirect
                executeRedirect(redirectUrl);
                
            } else {
                this.hasError = true;
                this.errorMessage = result.message;
                this.isProcessing = false;
            }
            
        } catch (Exception e) {
            System.debug('Error processing SAML response: ' + e.getMessage());
            this.hasError = true;
            this.errorMessage = 'Failed to process authentication response';
            this.isProcessing = false;
        }
    }
    
    private void storeUserSession(UserManagementController.UserSession userSession) {
        // Store session in cache or custom object
        try {
            String sessionKey = 'UserSession_' + UserInfo.getSessionId();
            Cache.Org.put(sessionKey, userSession, 3600); // 1 hour
            
            // Also store in page state for immediate access
            ApexPages.currentPage().getParameters().put('userEmail', userSession.email);
            ApexPages.currentPage().getParameters().put('userFirstName', userSession.firstName);
            ApexPages.currentPage().getParameters().put('userLastName', userSession.lastName);
            
        } catch (Exception e) {
            System.debug('Error storing user session: ' + e.getMessage());
        }
    }
    
    private String getRedirectUrl() {
        // Decode relay state to get original URL
        if (String.isNotBlank(this.relayState)) {
            try {
                return EncodingUtil.urlDecode(this.relayState, 'UTF-8');
            } catch (Exception e) {
                System.debug('Error decoding relay state: ' + e.getMessage());
            }
        }
        
        // Default redirect to dashboard or profile page
        return '/dashboard';
    }
    
    private void executeRedirect(String redirectUrl) {
        try {
            PageReference pageRef = new PageReference(redirectUrl);
            pageRef.setRedirect(true);
            
            // For immediate redirect in Visualforce context
            System.debug('Redirecting to: ' + redirectUrl);
            
        } catch (Exception e) {
            System.debug('Error setting up redirect: ' + e.getMessage());
        }
    }
    
    public PageReference redirectToDestination() {
        String redirectUrl = getRedirectUrl();
        PageReference pageRef = new PageReference(redirectUrl);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    @AuraEnabled
    public static Map<String, Object> getSamlCallbackData() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get current page parameters
            Map<String, String> params = ApexPages.currentPage().getParameters();
            
            result.put('userEmail', params.get('userEmail'));
            result.put('userFirstName', params.get('userFirstName'));
            result.put('userLastName', params.get('userLastName'));
            result.put('success', true);
            
        } catch (Exception e) {
            System.debug('Error getting SAML callback data: ' + e.getMessage());
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        
        return result;
    }
}