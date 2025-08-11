import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import loginUser from '@salesforce/apex/UserManagementController.loginUser';
import getAuthenticationMethod from '@salesforce/apex/UserManagementController.getAuthenticationMethod';
import initiateSamlLogin from '@salesforce/apex/UserManagementController.initiateSamlLogin';

export default class OktaLogin extends NavigationMixin(LightningElement) {
    @track username = '';
    @track password = '';
    @track isLoading = false;
    @track showPassword = false;
    @track authMethod = 'OAuth';
    @track isSamlAuth = false;

    handleUsernameChange(event) {
        this.username = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    togglePasswordVisibility() {
        this.showPassword = !this.showPassword;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleLogin();
        }
    }

    async handleLogin() {
        if (this.isSamlAuth) {
            await this.handleSamlLogin();
            return;
        }

        // Validate inputs for OAuth
        if (!this.username || !this.password) {
            this.showToast('Error', 'Please enter both username and password', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const result = await loginUser({
                username: this.username,
                password: this.password
            });

            if (result.success) {
                this.showToast('Success', result.message, 'success');
                
                // Store user session data
                sessionStorage.setItem('userSession', JSON.stringify(result.data));
                
                // Navigate to user profile or dashboard
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/dashboard' // Adjust this URL based on your community structure
                    }
                });
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            console.error('Login error:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleRegisterClick() {
        // Navigate to registration page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/register'
            }
        });
    }

    handleForgotPasswordClick() {
        // Navigate to forgot password page or show modal
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/forgot-password'
            }
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    get passwordInputType() {
        return this.showPassword ? 'text' : 'password';
    }

    get passwordToggleIcon() {
        return this.showPassword ? 'utility:hide' : 'utility:preview';
    }

    connectedCallback() {
        this.loadAuthenticationMethod();
    }

    async loadAuthenticationMethod() {
        try {
            const result = await getAuthenticationMethod();
            if (result.success) {
                this.authMethod = result.data.method;
                this.isSamlAuth = this.authMethod === 'SAML';
            }
        } catch (error) {
            console.error('Error loading authentication method:', error);
            // Default to OAuth if unable to determine
            this.authMethod = 'OAuth';
            this.isSamlAuth = false;
        }
    }

    async handleSamlLogin() {
        this.isLoading = true;

        try {
            const relayState = encodeURIComponent(window.location.href);
            const result = await initiateSamlLogin(relayState);

            if (result.success) {
                // Redirect to Okta SAML SSO URL
                window.location.href = result.data.redirectUrl;
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            console.error('SAML login error:', error);
            this.showToast('Error', 'Failed to initiate SAML login. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get isLoginDisabled() {
        if (this.isSamlAuth) {
            return this.isLoading;
        }
        return this.isLoading || !this.username || !this.password;
    }

    get showUsernamePassword() {
        return !this.isSamlAuth;
    }

    get showSamlButton() {
        return this.isSamlAuth;
    }

    get loginButtonLabel() {
        return this.isSamlAuth ? 'Sign In with SSO' : 'Sign In';
    }
}