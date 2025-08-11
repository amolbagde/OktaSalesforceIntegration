import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import loginUser from '@salesforce/apex/UserManagementController.loginUser';

export default class OktaLogin extends NavigationMixin(LightningElement) {
    @track username = '';
    @track password = '';
    @track isLoading = false;
    @track showPassword = false;

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
        // Validate inputs
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

    get isLoginDisabled() {
        return this.isLoading || !this.username || !this.password;
    }
}