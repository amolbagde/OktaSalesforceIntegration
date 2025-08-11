import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import updateUserProfile from '@salesforce/apex/UserManagementController.updateUserProfile';
import getCurrentUser from '@salesforce/apex/UserManagementController.getCurrentUser';
import logoutUser from '@salesforce/apex/UserManagementController.logoutUser';

export default class UserProfile extends NavigationMixin(LightningElement) {
    @track userId = '';
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track originalFirstName = '';
    @track originalLastName = '';
    @track originalEmail = '';
    @track isLoading = false;
    @track isEditing = false;
    @track userSession = null;

    connectedCallback() {
        this.loadUserProfile();
    }

    async loadUserProfile() {
        this.isLoading = true;

        try {
            // First try to get from session storage
            const sessionData = sessionStorage.getItem('userSession');
            if (sessionData) {
                this.userSession = JSON.parse(sessionData);
                this.populateUserData(this.userSession);
            } else {
                // If not in session storage, try to get from server
                const result = await getCurrentUser();
                if (result.success) {
                    this.userSession = result.data;
                    this.populateUserData(this.userSession);
                    sessionStorage.setItem('userSession', JSON.stringify(this.userSession));
                } else {
                    this.showToast('Error', 'Unable to load user profile. Please login again.', 'error');
                    this.navigateToLogin();
                }
            }
        } catch (error) {
            console.error('Error loading user profile:', error);
            this.showToast('Error', 'Failed to load user profile', 'error');
            this.navigateToLogin();
        } finally {
            this.isLoading = false;
        }
    }

    populateUserData(userData) {
        this.userId = userData.userId || '';
        this.firstName = userData.firstName || '';
        this.lastName = userData.lastName || '';
        this.email = userData.email || '';
        
        // Store original values for comparison
        this.originalFirstName = this.firstName;
        this.originalLastName = this.lastName;
        this.originalEmail = this.email;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleEditClick() {
        this.isEditing = true;
    }

    handleCancelEdit() {
        // Reset to original values
        this.firstName = this.originalFirstName;
        this.lastName = this.originalLastName;
        this.email = this.originalEmail;
        this.isEditing = false;
        
        // Reset field validation
        this.resetFieldValidation();
    }

    async handleSaveProfile() {
        // Validate inputs
        if (!this.validateForm()) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await updateUserProfile({
                userId: this.userId,
                email: this.email,
                firstName: this.firstName,
                lastName: this.lastName
            });

            if (result.success) {
                this.showToast('Success', 'Profile updated successfully', 'success');
                
                // Update stored values
                this.originalFirstName = this.firstName;
                this.originalLastName = this.lastName;
                this.originalEmail = this.email;
                
                // Update session storage
                this.userSession.firstName = this.firstName;
                this.userSession.lastName = this.lastName;
                this.userSession.email = this.email;
                sessionStorage.setItem('userSession', JSON.stringify(this.userSession));
                
                this.isEditing = false;
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            console.error('Error updating profile:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleLogout() {
        this.isLoading = true;

        try {
            const result = await logoutUser();
            
            // Clear session storage regardless of server response
            sessionStorage.removeItem('userSession');
            
            if (result.success) {
                this.showToast('Success', 'Logged out successfully', 'success');
            }
            
            this.navigateToLogin();
        } catch (error) {
            console.error('Error during logout:', error);
            // Still navigate to login even if logout fails
            sessionStorage.removeItem('userSession');
            this.navigateToLogin();
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        // Reset custom validity
        this.resetFieldValidation();

        let isValid = true;

        // Check required fields
        if (!this.firstName.trim()) {
            this.setFieldError('firstName', 'First name is required');
            isValid = false;
        }

        if (!this.lastName.trim()) {
            this.setFieldError('lastName', 'Last name is required');
            isValid = false;
        }

        if (!this.email.trim()) {
            this.setFieldError('email', 'Email is required');
            isValid = false;
        } else if (!this.isValidEmail(this.email)) {
            this.setFieldError('email', 'Please enter a valid email address');
            isValid = false;
        }

        return isValid;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
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

    navigateToLogin() {
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

    get displayName() {
        return `${this.firstName} ${this.lastName}`.trim();
    }

    get initials() {
        const firstInitial = this.firstName ? this.firstName.charAt(0).toUpperCase() : '';
        const lastInitial = this.lastName ? this.lastName.charAt(0).toUpperCase() : '';
        return `${firstInitial}${lastInitial}`;
    }

    get hasChanges() {
        return this.firstName !== this.originalFirstName ||
               this.lastName !== this.originalLastName ||
               this.email !== this.originalEmail;
    }

    get isSaveDisabled() {
        return this.isLoading || !this.hasChanges || !this.firstName.trim() || !this.lastName.trim() || !this.email.trim();
    }

    get profileImage() {
        // Generate a simple profile image URL based on initials
        // You can replace this with actual profile image logic
        return `https://ui-avatars.com/api/?name=${encodeURIComponent(this.displayName)}&background=667eea&color=fff&size=120&bold=true`;
    }
}