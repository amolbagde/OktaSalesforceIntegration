# Okta-Salesforce Integration

A complete Salesforce Lightning Web Component (LWC) solution for user authentication and management with Okta integration, designed for Experience Cloud community pages.

## 🚀 Features

### Core Functionality
- **User Authentication** - Secure login with Okta integration
- **User Registration** - Self-service account creation with validation
- **Profile Management** - Update user information seamlessly
- **Session Management** - Automatic token refresh and logout

### User Experience
- **Modern UI/UX** - Beautiful, responsive design with animations
- **Mobile-First** - Optimized for all devices and screen sizes
- **Accessibility** - WCAG compliant components
- **Real-time Validation** - Instant feedback on form inputs

### Security
- **Okta Integration** - Enterprise-grade identity management
- **Token-based Auth** - Secure JWT token handling
- **Input Validation** - Comprehensive client and server-side validation
- **Error Handling** - Graceful error management without exposing sensitive data

## 📋 Components

### Lightning Web Components
- **`oktaLogin`** - Login interface with Okta authentication
- **`userRegistration`** - User registration form with password strength indicator
- **`userProfile`** - Comprehensive profile management with edit capabilities

### Apex Classes
- **`OktaService`** - Core service for Okta API integration
- **`UserManagementController`** - Controller for user operations

### Configuration
- **`OktaConfiguration__mdt`** - Custom metadata for Okta settings

## 🛠️ Quick Start

### Prerequisites
- Salesforce org with Experience Cloud enabled
- Okta developer account or instance
- Salesforce CLI (sfdx)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/OktaSalesforceIntegration.git
   cd OktaSalesforceIntegration
   ```

2. **Deploy to Salesforce**
   ```bash
   sfdx auth:web:login -a your-org-alias
   sfdx force:source:deploy -p force-app -u your-org-alias
   ```

3. **Configure Okta Settings**
   - Navigate to Setup > Custom Metadata Types > Okta Configuration
   - Update the OktaConfig record with your Okta credentials

4. **Set up Community**
   - Add components to your Experience Cloud pages
   - Configure proper permissions and access settings

For detailed setup instructions, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

## 📱 Screenshots

### Login Screen
- Clean, modern interface with Okta integration
- Password visibility toggle
- Responsive design for all devices

### Registration Form
- Multi-step validation with real-time feedback
- Password strength indicator
- Terms and conditions acceptance

### User Profile
- Comprehensive profile management
- In-place editing with change tracking
- Security and preference settings

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LWC Frontend  │────│  Apex Backend   │────│  Okta Service   │
│                 │    │                 │    │                 │
│ • oktaLogin     │    │ • OktaService   │    │ • Authentication│
│ • userReg...    │    │ • UserMgmt...   │    │ • User CRUD     │
│ • userProfile   │    │                 │    │ • Token Mgmt    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration

### Okta Setup
1. Create OIDC application in Okta
2. Configure redirect URIs for your community
3. Generate API token for user management
4. Set up trusted origins and CORS

### Salesforce Setup
1. Deploy all metadata components
2. Configure Remote Site Settings for Okta
3. Update Custom Metadata with Okta credentials
4. Set up Experience Cloud permissions

## 🧪 Testing

Run the included test classes to ensure proper functionality:

```bash
# Run all tests
sfdx force:apex:test:run -u your-org-alias

# Run specific test class
sfdx force:apex:test:run -n OktaServiceTest -u your-org-alias
```

## 📖 Documentation

- [Deployment Guide](./DEPLOYMENT_GUIDE.md) - Complete setup instructions
- [API Documentation](./docs/API.md) - Detailed API reference
- [Component Guide](./docs/COMPONENTS.md) - LWC component documentation
- [Security Guide](./docs/SECURITY.md) - Security best practices

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](./CONTRIBUTING.md) for details on:
- Code of conduct
- Development setup
- Pull request process
- Coding standards

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🆘 Support

### Getting Help
- 📖 Check the [documentation](./docs/)
- 🐛 [Report bugs](https://github.com/your-username/OktaSalesforceIntegration/issues)
- 💬 [Discussion forum](https://github.com/your-username/OktaSalesforceIntegration/discussions)

### Resources
- [Salesforce Developer Docs](https://developer.salesforce.com/)
- [Okta Developer Docs](https://developer.okta.com/)
- [Lightning Web Components Guide](https://lwc.dev/)

## 🗺️ Roadmap

### Upcoming Features
- [ ] Multi-factor authentication support
- [ ] Social login integration (Google, LinkedIn)
- [ ] Advanced user role management
- [ ] Password reset functionality
- [ ] Audit logging and reporting
- [ ] Bulk user import/export

### Version History
- **v1.0.0** - Initial release with core authentication features
- **v1.1.0** - Enhanced UI/UX and mobile responsiveness (planned)
- **v2.0.0** - MFA and social login integration (planned)

## 🏷️ Tags

`salesforce` `lwc` `okta` `authentication` `experience-cloud` `communities` `apex` `lightning`

---

**Built with ❤️ for the Salesforce community**

For questions, feedback, or contributions, please reach out through our [GitHub Issues](https://github.com/your-username/OktaSalesforceIntegration/issues) or [Discussions](https://github.com/your-username/OktaSalesforceIntegration/discussions). 
