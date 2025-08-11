import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import registerUser from '@salesforce/apex/UserManagementController.registerUser';

export default class UserRegistration extends NavigationMixin(LightningElement) {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track password = '';
    @track confirmPassword = '';
    @track isLoading = false;
    @track showPassword = false;
    @track showConfirmPassword = false;
    @track agreeToTerms = false;

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    handleConfirmPasswordChange(event) {
        this.confirmPassword = event.target.value;
    }

    handleTermsChange(event) {
        this.agreeToTerms = event.target.checked;
    }

    togglePasswordVisibility() {
        this.showPassword = !this.showPassword;
    }

    toggleConfirmPasswordVisibility() {
        this.showConfirmPassword = !this.showConfirmPassword;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRegister();
        }
    }

    async handleRegister() {
        // Validate inputs
        if (!this.validateForm()) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await registerUser({
                email: this.email,
                firstName: this.firstName,
                lastName: this.lastName,
                password: this.password,
                confirmPassword: this.confirmPassword
            });

            if (result.success) {
                this.showToast('Success', 'Account created successfully! You can now sign in.', 'success');
                
                // Navigate to login page
                setTimeout(() => {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/login'
                        }
                    });
                }, 2000);
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            console.error('Registration error:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        // Reset custom validity
        this.resetFieldValidation();

        let isValid = true;

        // Check required fields
        if (!this.firstName) {
            this.setFieldError('firstName', 'First name is required');
            isValid = false;
        }

        if (!this.lastName) {
            this.setFieldError('lastName', 'Last name is required');
            isValid = false;
        }

        if (!this.email) {
            this.setFieldError('email', 'Email is required');
            isValid = false;
        } else if (!this.isValidEmail(this.email)) {
            this.setFieldError('email', 'Please enter a valid email address');
            isValid = false;
        }

        if (!this.password) {
            this.setFieldError('password', 'Password is required');
            isValid = false;
        } else if (!this.isValidPassword(this.password)) {
            this.setFieldError('password', 'Password must be at least 8 characters with uppercase, lowercase, number, and special character');
            isValid = false;
        }

        if (!this.confirmPassword) {
            this.setFieldError('confirmPassword', 'Please confirm your password');
            isValid = false;
        } else if (this.password !== this.confirmPassword) {
            this.setFieldError('confirmPassword', 'Passwords do not match');
            isValid = false;
        }

        if (!this.agreeToTerms) {
            this.showToast('Error', 'Please agree to the Terms and Conditions', 'error');
            isValid = false;
        }

        return isValid;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    isValidPassword(password) {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character
        const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
        return passwordRegex.test(password);
    }

    setFieldError(fieldName, message) {
        const field = this.template.querySelector(`[data-field="${fieldName}"]`);
        if (field) {
            field.setCustomValidity(message);
            field.reportValidity();
        }
    }

    resetFieldValidation() {
        const fields = this.template.querySelectorAll('[data-field]');
        fields.forEach(field => {
            field.setCustomValidity('');
        });
    }

    handleLoginClick() {
        // Navigate to login page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/login'
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

    get confirmPasswordInputType() {
        return this.showConfirmPassword ? 'text' : 'password';
    }

    get passwordToggleIcon() {
        return this.showPassword ? 'utility:hide' : 'utility:preview';
    }

    get confirmPasswordToggleIcon() {
        return this.showConfirmPassword ? 'utility:hide' : 'utility:preview';
    }

    get isRegisterDisabled() {
        return this.isLoading || !this.firstName || !this.lastName || !this.email || !this.password || !this.confirmPassword || !this.agreeToTerms;
    }

    get passwordStrength() {
        if (!this.password) return '';
        
        let strength = 0;
        let strengthText = '';
        let strengthClass = '';

        // Check password criteria
        if (this.password.length >= 8) strength++;
        if (/[a-z]/.test(this.password)) strength++;
        if (/[A-Z]/.test(this.password)) strength++;
        if (/\d/.test(this.password)) strength++;
        if (/[@$!%*?&]/.test(this.password)) strength++;

        switch (strength) {
            case 0:
            case 1:
                strengthText = 'Very Weak';
                strengthClass = 'strength-very-weak';
                break;
            case 2:
                strengthText = 'Weak';
                strengthClass = 'strength-weak';
                break;
            case 3:
                strengthText = 'Fair';
                strengthClass = 'strength-fair';
                break;
            case 4:
                strengthText = 'Good';
                strengthClass = 'strength-good';
                break;
            case 5:
                strengthText = 'Strong';
                strengthClass = 'strength-strong';
                break;
        }

        return {
            text: strengthText,
            class: strengthClass,
            width: (strength * 20) + '%'
        };
    }
}