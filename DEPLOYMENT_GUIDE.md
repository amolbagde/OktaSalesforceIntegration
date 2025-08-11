# Okta-Salesforce Integration Deployment Guide

## Overview

This project provides a complete Salesforce Lightning Web Component (LWC) solution for user authentication and management with Okta integration for community pages. It supports both **SAML 2.0** and **OAuth 2.0** authentication methods, with SAML being the recommended approach for enterprise environments.

## Components Included

### Apex Classes
- **OktaService.cls** - Main service class for Okta API integration (supports both SAML and OAuth)
- **UserManagementController.cls** - Controller for user management operations
- **SamlUtility.cls** - Utility class for SAML request/response handling
- **SamlCallbackController.cls** - Controller for SAML callback processing

### Lightning Web Components
- **oktaLogin** - Login screen with Okta authentication (auto-detects SAML vs OAuth)
- **userRegistration** - User registration/creation component
- **userProfile** - User profile management component

### Visualforce Pages
- **SamlCallback** - SAML response callback handler page

### Custom Metadata
- **OktaConfiguration__mdt** - Configuration settings for Okta integration (supports both authentication methods)

## Authentication Methods Comparison

| Feature | SAML 2.0 | OAuth 2.0 |
|---------|----------|-----------|
| **Use Case** | Enterprise SSO | API Access & Social Login |
| **Security** | High (XML signatures) | High (JWT tokens) |
| **User Experience** | Seamless SSO | Username/Password or Social |
| **Session Management** | SAML assertions | Access/Refresh tokens |
| **Enterprise Ready** | ✅ Yes | ⚠️ Requires additional setup |
| **Mobile Support** | ✅ Yes | ✅ Yes |
| **Complexity** | Medium | Low |
| **Recommended For** | Enterprise, existing SAML infrastructure | New implementations, API-first |

## Prerequisites

1. **Salesforce Org** with Experience Cloud (Communities) enabled
2. **Okta Developer Account** or Okta instance
3. **Salesforce CLI** (sfdx) installed
4. **VS Code** with Salesforce Extension Pack (recommended)

## Okta Setup

### Option 1: SAML 2.0 Setup (Recommended for Enterprise)

#### 1. Create SAML Application in Okta

1. Log into your Okta Admin Console
2. Navigate to **Applications** > **Applications**
3. Click **Create App Integration**
4. Select **SAML 2.0**
5. Configure the SAML application:

**General Settings:**
- **App name**: Salesforce Community SAML Integration
- **App logo**: Upload your organization logo (optional)

**SAML Settings:**
- **Single sign on URL**: `https://your-community-domain.force.com/apex/SamlCallback`
- **Audience URI (SP Entity ID)**: `https://your-community-domain.force.com`
- **Default RelayState**: Leave blank or set to `/dashboard`
- **Name ID format**: EmailAddress
- **Application username**: Email

**Attribute Statements:**
- `firstName` → `user.firstName`
- `lastName` → `user.lastName`
- `email` → `user.email`

#### 2. Configure SAML Response

In the **SAML Settings** section:
- **Response**: Signed
- **Assertion Signature**: Signed
- **Signature Algorithm**: RSA-SHA256
- **Digest Algorithm**: SHA256
- **Assertion Encryption**: Unencrypted (unless you have specific requirements)

#### 3. Download SAML Certificate

1. After creating the application, go to the **Sign On** tab
2. Under **SAML 2.0**, click **View Setup Instructions**
3. Copy the **X.509 Certificate** content
4. Note the **Identity Provider Single Sign-On URL**
5. Note the **Identity Provider Issuer**

### Option 2: OAuth 2.0 Setup (Alternative)

#### 1. Create OAuth Application in Okta

1. Log into your Okta Admin Console
2. Navigate to **Applications** > **Applications**
3. Click **Create App Integration**
4. Select **OIDC - OpenID Connect**
5. Choose **Single-Page Application (SPA)**
6. Configure the application:
   - **App integration name**: Salesforce Community Integration
   - **Grant type**: Authorization Code, Refresh Token
   - **Sign-in redirect URIs**: 
     - `https://your-community-domain.force.com/auth/callback`
     - `https://your-community-domain.force.com/login`
   - **Sign-out redirect URIs**: 
     - `https://your-community-domain.force.com/logout`
   - **Trusted Origins**: Add your community domain

### 2. Generate API Token

1. In Okta Admin Console, go to **Security** > **API**
2. Click **Tokens** tab
3. Click **Create Token**
4. Name it "Salesforce Integration Token"
5. **Save the token securely** - you'll need it for configuration

### 3. Note Configuration Values

#### For SAML Setup:
- **Okta Domain**: `your-okta-domain.okta.com`
- **SAML Issuer**: From setup instructions (e.g., `http://www.okta.com/exk1abc2def3ghi4jkl5`)
- **SAML SSO URL**: From setup instructions (e.g., `https://your-domain.okta.com/app/exk1abc2def3ghi4jkl5/sso/saml`)
- **SAML Certificate**: X.509 certificate content
- **API Token**: Generated in step 2 (for user management operations)

#### For OAuth Setup:
- **Okta Domain**: `your-okta-domain.okta.com`
- **Client ID**: From your created application
- **Client Secret**: From your created application (if using confidential client)
- **API Token**: Generated in step 2

## Salesforce Deployment

### 1. Deploy Using Salesforce CLI

```bash
# Clone or navigate to the project directory
cd /path/to/OktaSalesforceIntegration

# Authenticate to your org (replace with your org alias)
sfdx auth:web:login -a your-org-alias

# Deploy the metadata
sfdx force:source:deploy -p force-app -u your-org-alias

# Verify deployment
sfdx force:source:status -u your-org-alias
```

### 2. Deploy Using VS Code

1. Open the project in VS Code
2. Use `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Run **SFDX: Authorize an Org**
4. Use **SFDX: Deploy Source to Org**

### 3. Manual Deployment (Metadata API)

1. Create a deployment package with all components
2. Use Workbench or Salesforce Setup to deploy
3. Ensure all Apex classes and LWC components are deployed successfully

## Configuration

### 1. Update Okta Configuration

1. Navigate to **Setup** > **Custom Metadata Types**
2. Find **Okta Configuration**
3. Click **New** or edit existing **OktaConfig** record
4. Update the values based on your chosen authentication method:

#### For SAML Authentication:
- **Authentication Method**: SAML
- **Okta Domain**: `your-okta-domain.okta.com`
- **SAML Issuer**: Your Okta SAML issuer URL
- **SAML SSO URL**: Your Okta SAML SSO endpoint
- **SAML Certificate**: Your X.509 certificate content (include BEGIN/END CERTIFICATE lines)
- **SAML Callback URL**: `https://your-community.force.com/apex/SamlCallback`
- **SAML Logout URL**: `https://your-domain.okta.com/app/your-app-id/slo/saml`
- **API Token**: Your Okta API token (for user management)

#### For OAuth Authentication:
- **Authentication Method**: OAuth
- **Okta Domain**: `your-okta-domain.okta.com`
- **Client ID**: Your Okta application client ID
- **Client Secret**: Your Okta application client secret
- **Redirect URI**: `https://your-community.force.com/auth/callback`
- **API Token**: Your Okta API token

### 2. Set Remote Site Settings

1. Go to **Setup** > **Remote Site Settings**
2. Click **New Remote Site**
3. Add your Okta domain:
   - **Remote Site Name**: Okta_API
   - **Remote Site URL**: `https://your-okta-domain.okta.com`
   - **Active**: Checked

### 3. Configure CORS (if needed)

In Okta Admin Console:
1. Go to **Security** > **API** > **Trusted Origins**
2. Add your Salesforce community domain
3. Select both **CORS** and **Redirect** options

## Community Setup

### 1. Create or Configure Experience Cloud Site

1. Go to **Setup** > **Digital Experiences** > **All Sites**
2. Create a new site or select existing
3. Choose appropriate template (Customer Service, Partner Central, etc.)

### 2. Add Components to Community Pages

#### Login Page
1. In Experience Builder, create or edit login page
2. Add **oktaLogin** component
3. Configure page settings and layout

#### Registration Page
1. Create a new page for registration
2. Add **userRegistration** component
3. Set appropriate page permissions

#### User Profile Page
1. Create a profile page or edit existing
2. Add **userProfile** component
3. Ensure proper authentication requirements

### 3. Set Community Permissions

1. Configure **Public Access Settings**
2. Set up **Profile** and **Permission Set** assignments
3. Enable proper **Guest User** permissions for public components

## Security Considerations

### 1. API Security

- Store sensitive configuration in **Custom Metadata** or **Custom Settings**
- Use **Named Credentials** for enhanced security (optional)
- Implement proper **error handling** without exposing sensitive information
- For SAML: Validate SAML signatures and certificates
- For OAuth: Secure client secrets and API tokens

### 2. Community Security

- Enable **HTTPS** for all community pages
- Configure **CSP (Content Security Policy)** headers
- Implement **session timeout** settings
- Use **reCAPTCHA** for registration (optional enhancement)
- For SAML: Ensure callback URLs are properly secured

### 3. Okta Security

- Enable **Multi-Factor Authentication** (MFA)
- Configure **Password Policies**
- Set up **Rate Limiting**
- Monitor **Security Events**
- For SAML: Use signed assertions and proper certificate validation
- Regular certificate rotation and monitoring

### 4. SAML-Specific Security

- **Certificate Validation**: Ensure proper X.509 certificate validation
- **Signature Verification**: Validate SAML response signatures
- **Assertion Encryption**: Consider encrypting sensitive assertions
- **Time-based Validation**: Implement NotBefore and NotOnOrAfter checks
- **Replay Attack Prevention**: Use unique request IDs and timestamps

## Testing

### 1. Component Testing

Test each component individually:

```javascript
// Example test for login component
@isTest
public class OktaServiceTest {
    @isTest
    static void testAuthenticateUser() {
        // Create test data
        // Mock HTTP callouts
        // Assert expected results
    }
}
```

### 2. Integration Testing

#### For SAML Authentication:
1. Test SAML SSO login flow
2. Verify SAML response parsing and user creation
3. Test RelayState handling for post-login redirection
4. Test SAML logout functionality
5. Verify certificate validation and signature verification

#### For OAuth Authentication:
1. Test complete user flow: Registration → Login → Profile Update
2. Test token refresh and session management
3. Verify OAuth flow with authorization codes

#### General Testing:
1. Test error scenarios and edge cases
2. Verify Okta integration with actual API calls
3. Test mobile responsiveness
4. Cross-browser compatibility testing

### 3. User Acceptance Testing

1. Invite beta users to test the community
2. Gather feedback on user experience
3. Test across different browsers and devices

## Monitoring and Maintenance

### 1. Salesforce Monitoring

- Monitor **Debug Logs** for API errors
- Set up **Custom Notifications** for failures
- Review **Login History** and **Setup Audit Trail**

### 2. Okta Monitoring

- Monitor **System Log** in Okta Admin Console
- Set up **Alerts** for suspicious activities
- Review **Authentication** and **Authorization** logs

### 3. Performance Monitoring

- Monitor **API Rate Limits**
- Track **Response Times**
- Monitor **Community Performance**

## Troubleshooting

### Common Issues

#### 1. CORS Errors
- Verify **Remote Site Settings** in Salesforce
- Check **Trusted Origins** in Okta
- Ensure correct domain configurations

#### 2. Authentication Failures
- Verify **Okta Configuration** metadata
- Check **Client ID** and **Client Secret**
- Validate **API Token** permissions

#### 3. Component Not Loading
- Check **Lightning Web Security** settings
- Verify **Component Visibility** settings
- Review **Profile Permissions**

#### 4. API Limits
- Monitor **Okta API Rate Limits**
- Implement **Caching** strategies
- Optimize **API Calls**

### Debug Steps

1. **Enable Debug Logging**:
   ```apex
   System.debug('OktaService Debug: ' + debugInfo);
   ```

2. **Check Network Requests**:
   - Use browser **Developer Tools**
   - Monitor **Network** tab for failed requests

3. **Verify Permissions**:
   - Check **User Permissions**
   - Verify **Object Permissions**
   - Review **Field-Level Security**

## Best Practices

### 1. Security
- Never hardcode sensitive information
- Use proper error handling
- Implement logging for security events
- Regular security reviews

### 2. Performance
- Minimize API calls
- Implement caching where appropriate
- Optimize component rendering
- Use efficient SOQL queries

### 3. User Experience
- Provide clear error messages
- Implement loading states
- Ensure mobile responsiveness
- Follow accessibility guidelines

### 4. Maintenance
- Regular dependency updates
- Monitor deprecated features
- Document all customizations
- Maintain test coverage

## Support and Resources

### Salesforce Resources
- [Lightning Web Components Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Experience Cloud Documentation](https://help.salesforce.com/s/articleView?id=sf.networks_overview.htm)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)

### Okta Resources
- [Okta Developer Documentation](https://developer.okta.com/)
- [Okta API Reference](https://developer.okta.com/docs/reference/)
- [Okta Security Best Practices](https://help.okta.com/en/prod/Content/Topics/Security/Security.htm)

### Community Support
- [Salesforce Trailblazer Community](https://trailblazers.salesforce.com/)
- [Okta Developer Community](https://devforum.okta.com/)
- [Stack Overflow](https://stackoverflow.com/) with relevant tags

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01-XX | Initial release with login, registration, and profile components |

## License

[Add your license information here]

## Contributing

[Add contribution guidelines if applicable]