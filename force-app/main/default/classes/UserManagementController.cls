public with sharing class UserManagementController {
    
    public class UserManagementResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Object data { get; set; }
        
        public UserManagementResponse(Boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data = data;
        }
    }
    
    public class UserSession {
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String accessToken { get; set; }
        @AuraEnabled public String refreshToken { get; set; }
        @AuraEnabled public DateTime expiresAt { get; set; }
        
        public UserSession() {}
    }
    
    @AuraEnabled
    public static UserManagementResponse getAuthenticationMethod() {
        try {
            OktaService.OktaResponse oktaResponse = OktaService.getAuthenticationMethod();
            
            if (oktaResponse.success) {
                return new UserManagementResponse(true, 'Authentication method retrieved', oktaResponse.data);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in getAuthenticationMethod: ' + e.getMessage());
            return new UserManagementResponse(false, 'Failed to get authentication method: ' + e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static UserManagementResponse initiateSamlLogin(String relayState) {
        try {
            OktaService.OktaResponse oktaResponse = OktaService.initiateSamlAuthentication(relayState);
            
            if (oktaResponse.success) {
                return new UserManagementResponse(true, 'SAML request initiated', oktaResponse.data);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in initiateSamlLogin: ' + e.getMessage());
            return new UserManagementResponse(false, 'SAML login failed: ' + e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static UserManagementResponse processSamlLogin(String samlResponse) {
        try {
            OktaService.OktaResponse oktaResponse = OktaService.processSamlResponse(samlResponse);
            
            if (oktaResponse.success) {
                OktaService.OktaAuthResult authResult = (OktaService.OktaAuthResult) oktaResponse.data;
                
                // Create or update user session
                UserSession userSession = new UserSession();
                userSession.email = authResult.user.email;
                userSession.firstName = authResult.user.firstName;
                userSession.lastName = authResult.user.lastName;
                userSession.userId = authResult.user.login;
                // For SAML, we don't have OAuth tokens, use Salesforce session
                userSession.accessToken = UserInfo.getSessionId();
                userSession.expiresAt = DateTime.now().addHours(8); // Default 8-hour session
                
                // Store session in custom object or cache
                storeUserSession(userSession);
                
                return new UserManagementResponse(true, 'SAML login successful', userSession);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in processSamlLogin: ' + e.getMessage());
            return new UserManagementResponse(false, 'SAML login processing failed: ' + e.getMessage(), null);
        }
    }

    @AuraEnabled
    public static UserManagementResponse loginUser(String username, String password) {
        try {
            OktaService.OktaResponse oktaResponse = OktaService.authenticateUser(username, password);
            
            if (oktaResponse.success) {
                OktaService.OktaAuthResult authResult = (OktaService.OktaAuthResult) oktaResponse.data;
                
                // Create or update user session
                UserSession userSession = new UserSession();
                userSession.email = authResult.user.email;
                userSession.firstName = authResult.user.firstName;
                userSession.lastName = authResult.user.lastName;
                userSession.accessToken = authResult.accessToken;
                userSession.refreshToken = authResult.refreshToken;
                userSession.expiresAt = DateTime.now().addSeconds(authResult.expiresIn);
                
                // Store session in custom object or cache
                storeUserSession(userSession);
                
                return new UserManagementResponse(true, 'Login successful', userSession);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in loginUser: ' + e.getMessage());
            return new UserManagementResponse(false, 'Login failed: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static UserManagementResponse registerUser(String email, String firstName, String lastName, String password, String confirmPassword) {
        try {
            // Validate input
            if (String.isBlank(email) || String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(password)) {
                return new UserManagementResponse(false, 'All fields are required', null);
            }
            
            if (password != confirmPassword) {
                return new UserManagementResponse(false, 'Passwords do not match', null);
            }
            
            if (!isValidEmail(email)) {
                return new UserManagementResponse(false, 'Invalid email format', null);
            }
            
            if (!isValidPassword(password)) {
                return new UserManagementResponse(false, 'Password must be at least 8 characters with uppercase, lowercase, number, and special character', null);
            }
            
            // Create user in Okta
            OktaService.OktaResponse oktaResponse = OktaService.createUser(email, firstName, lastName, password);
            
            if (oktaResponse.success) {
                // Optionally create corresponding Salesforce Contact/User record
                createSalesforceContact(email, firstName, lastName);
                
                return new UserManagementResponse(true, 'Registration successful', oktaResponse.data);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in registerUser: ' + e.getMessage());
            return new UserManagementResponse(false, 'Registration failed: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static UserManagementResponse updateUserProfile(String userId, String email, String firstName, String lastName) {
        try {
            // Validate input
            if (String.isBlank(userId) || String.isBlank(email) || String.isBlank(firstName) || String.isBlank(lastName)) {
                return new UserManagementResponse(false, 'All fields are required', null);
            }
            
            if (!isValidEmail(email)) {
                return new UserManagementResponse(false, 'Invalid email format', null);
            }
            
            // Update user in Okta
            OktaService.OktaResponse oktaResponse = OktaService.updateUser(userId, email, firstName, lastName);
            
            if (oktaResponse.success) {
                // Optionally update corresponding Salesforce Contact record
                updateSalesforceContact(email, firstName, lastName);
                
                return new UserManagementResponse(true, 'Profile updated successfully', oktaResponse.data);
            } else {
                return new UserManagementResponse(false, oktaResponse.message, null);
            }
        } catch (Exception e) {
            System.debug('Error in updateUserProfile: ' + e.getMessage());
            return new UserManagementResponse(false, 'Profile update failed: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static UserManagementResponse getCurrentUser() {
        try {
            // Get current user session from cache or custom object
            UserSession userSession = getCurrentUserSession();
            
            if (userSession != null) {
                // Check if token is expired
                if (userSession.expiresAt < DateTime.now()) {
                    // Try to refresh token
                    OktaService.OktaResponse refreshResponse = OktaService.refreshAccessToken(userSession.refreshToken);
                    
                    if (refreshResponse.success) {
                        Map<String, Object> tokenData = (Map<String, Object>) refreshResponse.data;
                        userSession.accessToken = (String) tokenData.get('access_token');
                        userSession.expiresAt = DateTime.now().addSeconds((Integer) tokenData.get('expires_in'));
                        
                        // Update stored session
                        storeUserSession(userSession);
                    } else {
                        return new UserManagementResponse(false, 'Session expired. Please login again.', null);
                    }
                }
                
                return new UserManagementResponse(true, 'User session retrieved', userSession);
            } else {
                return new UserManagementResponse(false, 'No active session found', null);
            }
        } catch (Exception e) {
            System.debug('Error in getCurrentUser: ' + e.getMessage());
            return new UserManagementResponse(false, 'Failed to get current user: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static UserManagementResponse logoutUser() {
        try {
            // Clear user session
            clearUserSession();
            return new UserManagementResponse(true, 'Logout successful', null);
        } catch (Exception e) {
            System.debug('Error in logoutUser: ' + e.getMessage());
            return new UserManagementResponse(false, 'Logout failed: ' + e.getMessage(), null);
        }
    }
    
    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        return emailPattern.matcher(email).matches();
    }
    
    private static Boolean isValidPassword(String password) {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
        if (password.length() < 8) return false;
        
        Boolean hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
        
        for (Integer i = 0; i < password.length(); i++) {
            String ch = password.substring(i, i + 1);
            if (ch >= 'A' && ch <= 'Z') hasUpper = true;
            else if (ch >= 'a' && ch <= 'z') hasLower = true;
            else if (ch >= '0' && ch <= '9') hasDigit = true;
            else hasSpecial = true;
        }
        
        return hasUpper && hasLower && hasDigit && hasSpecial;
    }
    
    private static void createSalesforceContact(String email, String firstName, String lastName) {
        try {
            // Check if contact already exists
            List<Contact> existingContacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
            
            if (existingContacts.isEmpty()) {
                Contact newContact = new Contact(
                    FirstName = firstName,
                    LastName = lastName,
                    Email = email
                );
                insert newContact;
            }
        } catch (Exception e) {
            System.debug('Error creating Salesforce contact: ' + e.getMessage());
        }
    }
    
    private static void updateSalesforceContact(String email, String firstName, String lastName) {
        try {
            List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
            
            if (!contacts.isEmpty()) {
                Contact contact = contacts[0];
                contact.FirstName = firstName;
                contact.LastName = lastName;
                update contact;
            }
        } catch (Exception e) {
            System.debug('Error updating Salesforce contact: ' + e.getMessage());
        }
    }
    
    private static void storeUserSession(UserSession userSession) {
        // Store in platform cache for demo purposes
        // In production, consider using custom objects or secure storage
        Cache.Org.put('UserSession_' + UserInfo.getSessionId(), userSession, 3600); // 1 hour
    }
    
    private static UserSession getCurrentUserSession() {
        // Retrieve from platform cache
        return (UserSession) Cache.Org.get('UserSession_' + UserInfo.getSessionId());
    }
    
    private static void clearUserSession() {
        // Clear from platform cache
        Cache.Org.remove('UserSession_' + UserInfo.getSessionId());
    }
}