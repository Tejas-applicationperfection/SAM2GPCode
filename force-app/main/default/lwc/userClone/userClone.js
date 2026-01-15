import { LightningElement, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import cloneUser from "@salesforce/apex/UserCloneController.cloneUser";
import freezeAndCloneUser from "@salesforce/apex/UserCloneController.freezeAndCloneUser";
import clonePermissions from "@salesforce/apex/UserCloneController.clonePermissions";
import clonePermissionsWithOverride from "@salesforce/apex/UserCloneController.clonePermissionsWithOverride";
import getInitialUsers from "@salesforce/apex/UserCloneController.getInitialUsers";
import searchUsers from "@salesforce/apex/UserCloneController.searchUsers";
import getSourceUserDetails from "@salesforce/apex/UserCloneController.getSourceUserDetails";
import getUserCloneHistory from "@salesforce/apex/UserCloneController.getUserCloneHistory";
// Phase 1 imports
import previewCloneDiff from "@salesforce/apex/UserCloneController.previewCloneDiff";
import getCompatibleProfiles from "@salesforce/apex/UserCloneController.getCompatibleProfiles";
import clonePermissionsSelectively from "@salesforce/apex/UserCloneController.clonePermissionsSelectively";

/* Security utility functions */
const SecurityUtils = {
  sanitizeString(str) {
    if (!str) {
      return "";
    }
    if (typeof str === "string") {
      // Allow letters, numbers, spaces, dots, hyphens, apostrophes, and @ symbols
      return str.replace(/[^\w\s.@'-]/gu, "").trim();
    }
    return "";
  },

  validateId(id) {
    /*
     * Salesforce IDs are either 15 or 18 characters
     * and consist of alphanumeric characters
     */
    return (
      typeof id === "string" &&
      /^[a-zA-Z0-9]{15}(?<suffix>[a-zA-Z0-9]{3})?$/u.test(id)
    );
  },

  sanitizeForHtml(str) {
    if (!str) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
};

export default class UserClone extends NavigationMixin(LightningElement) {
  // Track properties
  @track newUserId;
  @track username = "";
  @track alias = "";
  @track isModalOpen = false;
  @track sourceUserDetails;
  @track expandedSections = {
    basicInfo: true,
    securityInfo: true,
    localeInfo: false,
    permissionSets: false,
    publicGroups: false
  };
  @track isFreeze = false;
  @track sourceUserId;
  @track newUserEmail;
  @track newUserFirstName;
  @track newUserLastName;
  @track isLoading = false;
  @track userOptions = [];
  @track error;
  @track showSummary = false;
  @track cloneSummary = {};
  @track prevEmail;
  @track isSearching = false;

  @track searchTerm = "";
  @track searchTimeout;
  @track allUserOptions = [];
  @track showDropdown = false;

  // Permissions cloning properties
  @track isPermissionsModalOpen = false;
  @track targetUserOptions = [];
  @track targetSearchTerm = "";
  @track showTargetDropdown = false;
  @track selectedTargetUserId;
  @track selectedTargetUserName;
  @track isTargetSearching = false;
  @track showPermissionsSummary = false;
  @track permissionsCloneResult;

  // History modal properties
  @track showHistory = false;
  @track cloneHistory = [];
  @track isLoadingHistory = false;
  @track historyError = null;
  
  // License compatibility handling
  @track showLicenseCompatibilityModal = false;
  @track licenseCompatibilityData = null;
  
  // Phase 1 properties for Dry-Run Preview + Diff, License Compatibility Assistant, and Compare View
  @track showCompareModal = false;
  @track compareResult = null;
  @track isLoadingCompare = false;
  @track showLicenseAssistantModal = false;
  @track compatibleProfiles = [];
  @track isLoadingCompatibleProfiles = false;
  @track selectedCompatibleProfileId = null;
  @track isDryRunPreviewOpen = false;
  @track dryRunResult = null;
  @track isLoadingDryRun = false;
  @track compareSourceUserId = null;
  @track compareTargetUserId = null;
  
  // Selective permission cloning properties
  @track selectedPermissions = {
    profileChange: false,
    roleChange: false,
    selectedPermissionSets: [],
    selectedPermissionSetGroups: [],
    selectedPublicGroups: [],
    selectedUserPermissions: [],
    removedPermissionSets: [],
    removedPermissionSetGroups: [],
    removedPublicGroups: [],
    removeUnselectedPermissions: false
  };
  @track isSelectiveCloning = false;
  
  // Enhanced comparison properties
  @track activeCompareTab = 'permissionSets';
  @track compareSearchTerm = '';
  @track showDifferencesOnly = false;
  @track expandAllResults = false;
  @track compareSourceUserName = '';
  @track compareTargetUserName = '';
  @track comparisonSummary = {
    total: 0,
    added: 0,
    removed: 0,
    changed: 0,
    unchanged: 0
  };

  // Dynamically compute combobox CSS classes based on dropdown visibility
  get comboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showDropdown ? "slds-is-open" : ""}`;
  }
  @track selectedUserLabel = "";

  // Load initial users on component initialization
  connectedCallback() {
    console.log("UserClone component connected");
    // Initialize permissions cloning properties
    this.isPermissionsModalOpen = false;
    this.targetUserOptions = [];
    this.targetSearchTerm = "";
    this.showTargetDropdown = false;

    // Initialize clone options
    this.initializeCloneOptions();
    this.selectedTargetUserId = null;
    this.selectedTargetUserName = null;
    this.isTargetSearching = false;
    this.showPermissionsSummary = false;
    this.permissionsCloneResult = null;

    this.loadInitialUsers();
  }

  async loadInitialUsers() {
    try {
      console.log("Loading initial users...");
      this.isSearching = true;
      const data = await getInitialUsers();
      console.log("Initial users data:", data);
      const mappedUsers = data.map((user) => ({
        label: SecurityUtils.sanitizeString(user.name),
        value: user.id,
        email: user.email,
        username: user.username
      }));
      this.userOptions = mappedUsers;
      this.allUserOptions = [...mappedUsers];
      console.log("User options:", this.userOptions);
      this.error = undefined;
    } catch (error) {
      console.error("Error loading initial users:", error);
      this.error = error;
      this.userOptions = [];
      this.allUserOptions = [];
      this.handleError(error);
    } finally {
      this.isSearching = false;
    }
  }

  // Handle search input
  handleUserSearch(event) {
    const searchTerm = event.target.value;
    this.searchTerm = searchTerm;

    // Show dropdown when user starts typing
    this.showDropdown = true;

    // Clear existing timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    // Debounce search to avoid too many API calls
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.searchTimeout = setTimeout(() => {
      this.performSearch(searchTerm);
    }, 300);
  }

  // Handle search input focus
  handleSearchFocus() {
    // Show dropdown if we have options or if search term is empty (show initial users)
    if (
      this.userOptions.length > 0 ||
      !this.searchTerm ||
      this.searchTerm.length === 0
    ) {
      this.showDropdown = true;
      // If no search term, show all initial users
      if (!this.searchTerm || this.searchTerm.length === 0) {
        this.userOptions = [...this.allUserOptions];
        this.showDropdown = this.userOptions.length > 0;
      }
    }
  }

  // Handle search input blur
  handleSearchBlur() {
    // Delay hiding dropdown to allow for selection
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.showDropdown = false;
    }, 300);
  }

  // Handle user selection from dropdown
  handleUserSelection(event) {
    event.preventDefault();
    event.stopPropagation();

    const userId = event.currentTarget.dataset.userId;
    const selectedUser = this.userOptions.find((user) => user.value === userId);

    if (selectedUser) {
      this.sourceUserId = userId;
      this.selectedUserLabel = selectedUser.label;
      this.searchTerm = selectedUser.label;
      this.showDropdown = false;

      console.log("Selected user:", selectedUser);

      // Focus back to the input after selection
      const inputElement = this.template.querySelector('input[type="text"]');
      if (inputElement) {
        inputElement.blur();
      }
    }
  }

  // Handle mousedown on dropdown to prevent blur
  handleDropdownMouseDown(event) {
    event.preventDefault();
  }

  async performSearch(searchTerm) {
    try {
      if (!searchTerm || searchTerm.length < 1) {
        // Show initial users if search term is empty
        this.userOptions = [...this.allUserOptions];
        this.showDropdown = this.userOptions.length > 0;
        return;
      }

      // For very short search terms (1-2 characters), still perform search
      // but also include initial users that match

      this.isSearching = true;
      console.log("Searching for:", searchTerm, "Length:", searchTerm.length);

      const searchResult = await searchUsers({
        searchTerm: searchTerm,
        pageSize: 50,
        offset: 0
      });

      console.log("Search results:", searchResult);
      console.log(
        "Search result users count:", 
        searchResult?.users?.length || 0
      );

      if (searchResult && searchResult.users) {
        console.log("Raw users from search:", searchResult.users);
        const mappedUsers = [];
        searchResult.users.forEach((user) => {
          const sanitizedLabel = SecurityUtils.sanitizeString(user.name);
          console.log(
            "Original name:",
            user.name,
            "Sanitized label:",
            sanitizedLabel
          );
          if (sanitizedLabel) {
            // Only add if label is not empty
            mappedUsers.push({
              label: sanitizedLabel,
              value: user.id,
              email: user.email,
              username: user.username
            });
          }
        });
        console.log("Mapped users array:", mappedUsers);
        this.userOptions = mappedUsers;
        console.log("Final userOptions after assignment:", this.userOptions);
      } else {
        this.userOptions = [];
      }

      // Set dropdown visibility based on results
      this.showDropdown = this.userOptions.length > 0;
      console.log(
        "showDropdown updated to:",
        this.showDropdown,
        "with userOptions length:",
        this.userOptions.length
      );
    } catch (error) {
      console.error("Error searching users:", error);
      this.handleError(error);
      // Fallback to showing all users
      this.userOptions = [...this.allUserOptions];
      this.showDropdown = this.userOptions.length > 0;
    } finally {
      this.isSearching = false;
    }
  }

  handleAliasChange(event) {
    this.alias = SecurityUtils.sanitizeString(event.target.value);
  }

  handleUsernameChange(event) {
    this.username = SecurityUtils.sanitizeString(event.target.value);
  }

  // Navigate to New User page in a new tab
  navigateToNewUser() {
    // Use window.open to ensure new tab behavior
    const newUserUrl = '/lightning/setup/ManageUsers/page?address=%2F005%2Fe';
    window.open(newUserUrl, '_blank', 'noopener,noreferrer');
  }

  handleEmailChange(event) {
    this.newUserEmail = SecurityUtils.sanitizeString(event.detail.value);
    if (!this.username || this.username === this.prevEmail) {
      this.username = this.newUserEmail;
      this.prevEmail = this.newUserEmail;
    }
  }

  handleFirstNameChange(event) {
    this.newUserFirstName = SecurityUtils.sanitizeString(event.detail.value);
    this.generateAlias();
    this.dispatchEvent(
      new CustomEvent("firstnamechange", {
        detail: this.newUserFirstName
      })
    );
  }

  handleLastNameChange(event) {
    this.newUserLastName = SecurityUtils.sanitizeString(event.detail.value);
    this.generateAlias();
  }

  generateAlias() {
    if (this.newUserFirstName && this.newUserLastName) {
      const firstInitial = this.newUserFirstName[0] || "";
      const lastPart = this.newUserLastName.substring(0, 4) || "";
      this.alias = `${firstInitial}${lastPart}`.toLowerCase();
    }
  }

  /**
   * Displays the clone summary screen with the results of the cloning operation
   * @param {Object} result - The result object from the cloning operation
   */
  showCloneSummary(result) {
    // Ensure we have valid data before showing the summary
    if (!result) {
      console.error("No result data available for summary");
      return;
    }

    // Log the result for debugging
    console.debug("Clone result:", JSON.stringify(result));

    // Populate the summary data with sanitized values
    this.cloneSummary = {
      profileName: SecurityUtils.sanitizeString(result.profileName) || "N/A",
      userRole: SecurityUtils.sanitizeString(result.userRole) || "N/A",
      permissionSetsCloned: result.permissionSetsCloned || 0,
      permissionSetGroupsCloned: result.permissionSetGroupsCloned || 0,
      groupsCloned: result.groupsCloned || 0,
      userPermissionsCloned: result.userPermissionsCloned || 0,
      // Add a flag to indicate if user permissions are available and were cloned
      hasUserPermissions:
        result.userPermissionsCloned !== undefined &&
        result.userPermissionsCloned !== null &&
        result.userPermissionsCloned > 0
    };

    // Log detailed analytics for monitoring and troubleshooting
    console.debug("Clone summary prepared:", JSON.stringify(this.cloneSummary));

    // Show the summary screen
    this.showSummary = true;

    // Log analytics event for successful clone
    this.logAnalyticsEvent("User_Clone_Completed", {
      permissionSetsCount: this.cloneSummary.permissionSetsCloned,
      permissionSetGroupsCount: this.cloneSummary.permissionSetGroupsCloned,
      groupsCount: this.cloneSummary.groupsCloned,
      userPermissionsCount: this.cloneSummary.userPermissionsCloned
    });
  }

  resetForm() {
    this.sourceUserId = "";
    this.newUserEmail = "";
    this.newUserFirstName = "";
    this.newUserLastName = "";
    this.username = "";
    this.alias = "";
    this.showSummary = false;
    this.searchTerm = "";
    this.showDropdown = false;
    this.selectedUserLabel = "";
    this.prevEmail = "";

    // Clear clone history cache to ensure fresh data on next load
    this.cloneHistory = [];

    this.template.querySelectorAll("lightning-input").forEach((input) => {
      input.value = "";
    });
  }

  /**
   * Clears all input fields in the form to allow for fresh data entry
   * This method resets all user input fields and related state variables
   */
  clearAllFields() {
    try {
      // Reset all form-related tracked properties
      this.sourceUserId = "";
      this.newUserEmail = "";
      this.newUserFirstName = "";
      this.newUserLastName = "";
      this.username = "";
      this.alias = "";
      this.searchTerm = "";
      this.selectedUserLabel = "";
      this.prevEmail = "";
      
      // Reset UI state
      this.showDropdown = false;
      this.showSummary = false;
      this.error = null;
      
      // Reset source user details
      this.sourceUserDetails = null;
      
      // Clear any existing clone summary
      this.cloneSummary = {};
      
      // Reset permissions modal related fields
      this.selectedTargetUserId = "";
      this.selectedTargetUserName = "";
      this.targetSearchTerm = "";
      this.showTargetDropdown = false;
      this.showPermissionsSummary = false;
      this.permissionsCloneResult = null;
      
      // Reset comparison fields
      this.compareSourceUserId = null;
      this.compareTargetUserId = null;
      this.compareSourceUserName = "";
      this.compareTargetUserName = "";
      this.compareResult = null;
      
      // Clear all lightning-input elements
      this.template.querySelectorAll("lightning-input").forEach((input) => {
        input.value = "";
      });
      
      // Clear any combobox selections
      this.template.querySelectorAll("lightning-combobox").forEach((combobox) => {
        combobox.value = "";
      });
      
      // Show success message
      this.showToast(
        "Success", 
        "All fields have been cleared successfully", 
        "success"
      );
      
      // Log analytics event for tracking
      this.logAnalyticsEvent("clear_all_fields", {
        timestamp: new Date().toISOString(),
        component: "userClone"
      });
      
    } catch (error) {
      console.error("Error clearing fields:", error);
      this.showToast(
        "Error", 
        "An error occurred while clearing fields. Please try again.", 
        "error"
      );
    }
  }

  /**
   * Logs analytics events for tracking user actions and feature usage
   * @param {String} eventName - Name of the event to log
   * @param {Object} params - Additional parameters to include with the event
   */
  logAnalyticsEvent(eventName, params) {
    try {
      // Validate inputs
      if (!eventName) {
        console.warn("Analytics event name is required");
        return;
      }

      // Sanitize event name and parameters
      const sanitizedEventName = SecurityUtils.sanitizeString(eventName);
      const sanitizedParams = {};

      // Sanitize each parameter value
      if (params) {
        Object.keys(params).forEach((key) => {
          const value = params[key];
          if (typeof value === "string") {
            sanitizedParams[key] = SecurityUtils.sanitizeString(value);
          } else {
            sanitizedParams[key] = value;
          }
        });
      }

      // Add timestamp and context information
      sanitizedParams.timestamp = new Date().toISOString();
      sanitizedParams.component = "userClone";

      // Log to console for development/debugging
      console.debug(`Analytics Event: ${sanitizedEventName}`, sanitizedParams);

      // TODO: In production, this would call a Lightning Experience Analytics Service
      // or a custom Apex method to track events in a custom object

      // Example of future implementation:
      // trackUserEvent({
      //     eventName: sanitizedEventName,
      //     params: sanitizedParams
      // })
      // .then(() => console.debug('Event tracked successfully'))
      // .catch(error => console.error('Error tracking event:', error));

      // Example of future event dispatch implementation:
      // this.dispatchEvent(new CustomEvent('analyticstrack', {
      //    detail: { name: sanitizedEventName, params: sanitizedParams }
      // }));
    } catch (error) {
      // Log error but don't disrupt user experience - analytics should never break core functionality
      console.error("Error logging analytics event:", error);
    }
  }

  /*
   * Original showToast method commented out
   * Sanitize inputs for the toast
   * const sanitizedTitle = SecurityUtils.sanitizeString(title);
   * const sanitizedMessage = SecurityUtils.sanitizeString(message).replace(/<br>/g, '\n');
   *
   * const evt = new ShowToastEvent({
   *     title: sanitizedTitle,
   *     message: sanitizedMessage,
   *     variant: variant,
   *     mode: 'sticky'
   * });
   * this.dispatchEvent(evt);
   */

  handleError(error) {
    let errorMessage = "Unknown error";
    let errorTitle = "Information";
    let errorVariant = "info";
    
    if (error.body && error.body.message) {
      errorMessage = error.body.message;
      
      // Check if this is an AuraHandledException with our formatted error message
      if (error.body.exceptionType === 'System.AuraHandledException') {
        // Our enhanced error messages should be displayed as info
        errorTitle = "Information";
        errorVariant = "info";
      } else {
        // Other system errors can remain as errors
        errorTitle = "Error";
        errorVariant = "error";
      }
    } else if (typeof error.message === "string") {
      errorMessage = error.message;
      // Default to info for consistency
      errorTitle = "Information";
      errorVariant = "info";
    }
    
    /* Don't sanitize error messages from the server, they're already safe */
    this.showToast(errorTitle, errorMessage, errorVariant);
  }

  showToast(title, message, variant) {
    /* Only sanitize user-generated content, not server messages */
    const sanitizedTitle = SecurityUtils.sanitizeString(title);

    /*
     * Don't apply the same sanitization to error messages from the server
     * Just do HTML escaping instead of removing spaces
     */
    let sanitizedMessage;
    if (variant === "error") {
      sanitizedMessage = SecurityUtils.sanitizeForHtml(message);
    } else {
      sanitizedMessage = SecurityUtils.sanitizeString(message).replace(
        /<br>/g,
        "\n"
      );
    }

    const evt = new ShowToastEvent({
      title: sanitizedTitle,
      message: sanitizedMessage,
      variant: variant,
      mode: "sticky"
    });
    this.dispatchEvent(evt);
  }

  validateInputs() {
    /* Validate all required inputs */
    console.log("Validation check:", {
      sourceUserId: this.sourceUserId,
      newUserEmail: this.newUserEmail,
      newUserFirstName: this.newUserFirstName,
      newUserLastName: this.newUserLastName
    });

    if (
      !this.sourceUserId ||
      !this.newUserEmail ||
      !this.newUserFirstName ||
      !this.newUserLastName
    ) {
      let missingFields = [];
      if (!this.sourceUserId) missingFields.push("Source User");
      if (!this.newUserEmail) missingFields.push("Email");
      if (!this.newUserFirstName) missingFields.push("First Name");
      if (!this.newUserLastName) missingFields.push("Last Name");

      this.showToast(
        "Error",
        `Please fill in all required fields: ${missingFields.join(", ")}`,
        "error"
      );
      return false;
    }

    /* Validate email format */
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/u;
    if (!emailRegex.test(this.newUserEmail)) {
      this.showToast("Error", "Please enter a valid email address", "error");
      return false;
    }

    return true;
  }

  async showConfirmationModal() {
    if (!this.validateInputs()) {
      return;
    }

    this.isFreeze = false;
    await this.fetchAndShowUserDetails();
  }

  async showFreezeConfirmationModal() {
    if (!this.validateInputs()) {
      return;
    }

    this.isFreeze = true;
    await this.fetchAndShowUserDetails();
  }

  async fetchAndShowUserDetails() {
    this.isLoading = true;
    try {
      if (!SecurityUtils.validateId(this.sourceUserId)) {
        throw new Error("Invalid source user ID format");
      }

      this.sourceUserDetails = await getSourceUserDetails({
        userId: this.sourceUserId
      });
      this.isModalOpen = true;
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  closeModal() {
    this.isModalOpen = false;
  }

  handleCloneUser() {
    this.isLoading = true;
    this.isModalOpen = false;

    // Determine which Apex method to call based on freeze flag
    const apexMethod = this.isFreeze ? freezeAndCloneUser : cloneUser;

    // Call the appropriate Apex method
    apexMethod({
      sourceUserId: this.sourceUserId,
      newUserEmail: this.newUserEmail,
      newUserFirstName: this.newUserFirstName,
      newUserLastName: this.newUserLastName,
      newUserAlias: this.newUserAlias,
      newUsername: this.newUsername
    })
      .then((result) => {
        this.isLoading = false;
        this.newUserId = result.newUserId;

        // Show success toast
        this.showToast("Success", "User cloned successfully!", "success");

        // Clear clone history cache to ensure fresh data on next load
        this.cloneHistory = [];

        // Show the clone summary screen
        this.showCloneSummary(result);
      })
      .catch((error) => {
        this.isLoading = false;
        this.handleError(error);
      });
  }

  // Use direct URL navigation to open user in the setup page
navigateToUser() {
    if (!this.newUserId) return;

    // Construct the relative URL to the User detail in Setup
    const userDetailPath = `/${this.newUserId}?noredirect=1&isUserEntityOverride=1&appLayout=setup&clc=1`;

    // Encode it for use in the address parameter
    const encodedAddress = encodeURIComponent(userDetailPath);

    // Full Setup URL for Manage Users with deep link
    const setupUrl = `/lightning/setup/ManageUsers/page?address=${encodedAddress}`;

    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: setupUrl
        },
        state: {
            navigationLocation: 'newTab'
        }
    });
}

  // Show a custom modal instead of using native confirm()
  showFreezeConfirmation() {
    if (!this.validateInputs()) {
      return;
    }

    this.isFreeze = true;
    this.fetchAndShowUserDetails();
  }

  // Section expansion/collapse handlers
  toggleSection(event) {
    const sectionName = event.target.dataset.section;
    this.expandedSections = {
      ...this.expandedSections,
      [sectionName]: !this.expandedSections[sectionName]
    };
  }

  // Permissions Clone Modal Methods
  showPermissionsModal() {
    console.log("showPermissionsModal called");
    console.log("selectedUserId:", this.selectedUserId);
    console.log("selectedUserName:", this.selectedUserName);

    if (!this.selectedUserId) {
      console.log("No source user selected, showing error toast");
      this.showToast("Error", "Please select a source user first", "error");
      return;
    }

    console.log("Setting isPermissionsModalOpen to true");
    this.isPermissionsModalOpen = true;
    console.log(
      "isPermissionsModalOpen after setting:",
      this.isPermissionsModalOpen
    );

    this.targetSearchTerm = "";
    this.targetUserOptions = [];
    this.selectedTargetUserId = null;
    this.selectedTargetUserName = null;
  }

  closePermissionsModal() {
    console.log("closePermissionsModal called");
    this.isPermissionsModalOpen = false;
    console.log(
      "isPermissionsModalOpen after closing:",
      this.isPermissionsModalOpen
    );
  }

  // Target user search and selection methods
  handleTargetUserSearch(event) {
    this.targetSearchTerm = SecurityUtils.sanitizeString(event.target.value);
    this.performTargetSearch();
  }

  handleTargetSearchFocus() {
    this.showTargetDropdown = true;
  }

  handleTargetSearchBlur() {
    // Use Promise.resolve().then() to defer execution and allow click events to fire before hiding dropdown
    // This is the Salesforce-approved approach for LWC instead of setTimeout
    Promise.resolve().then(() => {
      Promise.resolve().then(() => {
        this.showTargetDropdown = false;
      });
    });
  }

  handleTargetDropdownMouseDown(event) {
    // Prevent dropdown from closing when clicking inside it
    event.preventDefault();
  }

  performTargetSearch() {
    // Don't search for terms less than 2 characters
    if (this.targetSearchTerm.length < 2) {
      this.targetUserOptions = [];
      this.showTargetDropdown = false;
      return;
    }

    this.isTargetSearching = true;
    console.log("Target search term:", this.targetSearchTerm);

    // Call Apex method to search users
    searchUsers({ searchTerm: this.targetSearchTerm, pageSize: 10, offset: 0 })
      .then((result) => {
        console.log("Target search result:", result);
        // Process search results
        this.processTargetSearchResults(result);
      })
      .catch((error) => {
        console.error("Target search error:", error);
        this.handleError(error);
      })
      .finally(() => {
        this.isTargetSearching = false;
      });
  }

  processTargetSearchResults(result) {
    if (result && result.users) {
      console.log("Processing target search results:", result.users);
      // Map users to dropdown options, excluding the source user
      this.targetUserOptions = result.users
        .filter((user) => user.id !== this.selectedUserId) // Exclude source user
        .map((user) => ({
          label: SecurityUtils.sanitizeString(user.name),
          value: user.id,
          email: SecurityUtils.sanitizeString(user.email)
        }));
      console.log(
        "Target user options after processing:",
        this.targetUserOptions
      );
    } else {
      console.log("No users found in target search result");
      this.targetUserOptions = [];
    }

    // Set dropdown visibility based on results
    this.showTargetDropdown = this.targetUserOptions.length > 0;
    console.log("Target dropdown visibility:", this.showTargetDropdown);
  }

  handleTargetUserSelection(event) {
    const userId = event.currentTarget.dataset.userId;
    const selectedOption = this.targetUserOptions.find(
      (option) => option.value === userId
    );

    if (selectedOption) {
      this.selectedTargetUserId = selectedOption.value;
      this.selectedTargetUserName = selectedOption.label;
      this.targetSearchTerm = selectedOption.label;
      this.showTargetDropdown = false;
    }
  }

  // Initialize clone options with default values
  initializeCloneOptions() {
    this.cloneOptions = {
      userPermissions: true,
      userRole: true,
      profile: true,
      permissionSets: true,
      permissionSetGroups: true,
      publicGroups: true,
      queueMembership: true
    };
  }

  // Handle checkbox changes for clone options
  handleCloneOptionChange(event) {
    const optionName = event.target.dataset.option;
    const isChecked = event.target.checked;

    if (optionName && this.cloneOptions) {
      this.cloneOptions[optionName] = isChecked;
    }
  }

  // Clone permissions method
  handleClonePermissions(allowRemovals = true) {
    if (!this.selectedUserId || !this.selectedTargetUserId) {
      this.showToast(
        "Error",
        "Please select both source and target users",
        "error"
      );
      return;
    }

    this.isLoading = true;

    // Add allowRemovals option to clone options
    const cloneOptionsWithRemovals = {
      ...this.cloneOptions,
      allowRemovals: allowRemovals
    };

    // Call Apex method to clone permissions with selected options
    clonePermissions({
      sourceUserId: this.selectedUserId,
      targetUserId: this.selectedTargetUserId,
      cloneOptions: cloneOptionsWithRemovals
    })
      .then((result) => {
        // Check if there's a license compatibility error
        if (result.licenseCompatibilityError) {
          this.licenseCompatibilityData = result;
          this.showLicenseCompatibilityModal = true;
          this.isLoading = false;
          return;
        }
        
        // Check if there's an error in the result
        if (result.hasError) {
          // Handle different error types with appropriate messaging
          let toastVariant = "info";
          let toastTitle = "Information";
          
          if (result.errorType === 'LICENSE_LIMIT_ERROR') {
            toastVariant = "warning";
            toastTitle = "License Limit Exceeded";
          } else if (result.errorType === 'ROLE_UPDATE_ERROR') {
            toastVariant = "warning";
            toastTitle = "Role Update Restricted";
          } else if (result.errorType === 'PROFILE_RESTRICTION') {
            toastVariant = "warning";
            toastTitle = "Profile Restriction";
          }
          
          this.showToast(
            toastTitle,
            result.errorMessage || "Permission cloning completed with restrictions",
            toastVariant
          );
          
          // Still show summary if some operations succeeded
          if (result.permissionSetsCloned > 0 || result.permissionSetGroupsCloned > 0 || result.groupsCloned > 0) {
            this.permissionsCloneResult = result;
            this.closePermissionsModal();
            this.showPermissionsSummary = true;
          }
          
          return;
        }
        
        this.permissionsCloneResult = result;
        this.closePermissionsModal();
        this.showPermissionsSummary = true;

        // Clear clone history cache to ensure fresh data on next load
        this.cloneHistory = [];

        this.showToast(
          "Success",
          "User permissions cloned successfully",
          "success"
        );
      })
      .catch((error) => {
        this.handleError(error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  closePermissionsSummaryModal() {
    this.showPermissionsSummary = false;
  }

  // License compatibility handling methods
  handleLicenseCompatibilityProceed() {
    this.showLicenseCompatibilityModal = false;
    this.isLoading = true;

    // Call Apex method with override flag to skip profile cloning
    clonePermissionsWithOverride({
      sourceUserId: this.selectedUserId,
      targetUserId: this.selectedTargetUserId,
      cloneOptions: this.cloneOptions,
      overrideLicenseCompatibility: true
    })
      .then((result) => {
        // Check if there's an error in the result
        if (result.hasError) {
          this.showToast(
            "Information",
            result.errorMessage || "Permission cloning completed with restrictions",
            "info"
          );
          return;
        }
        
        this.permissionsCloneResult = result;
        this.closePermissionsModal();
        this.showPermissionsSummary = true;

        // Clear clone history cache to ensure fresh data on next load
        this.cloneHistory = [];

        this.showToast(
          "Success",
          "User permissions cloned successfully (profile skipped due to license incompatibility)",
          "success"
        );
      })
      .catch((error) => {
        this.handleError(error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  handleLicenseCompatibilityCancel() {
    this.showLicenseCompatibilityModal = false;
    this.licenseCompatibilityData = null;
  }

  // Target combobox class getter
  get targetComboboxClass() {
    return this.showTargetDropdown
      ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open"
      : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
  }

  // Getters for section expansion state
  get isBasicInfoExpanded() {
    return this.expandedSections.basicInfo
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get isSecurityInfoExpanded() {
    return this.expandedSections.securityInfo
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get isLocaleInfoExpanded() {
    return this.expandedSections.localeInfo
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  // Getter for selectedUserId to ensure compatibility with permissions cloning
  get selectedUserId() {
    return this.sourceUserId;
  }

  // Getter for selectedUserName to ensure compatibility with permissions cloning
  get selectedUserName() {
    return this.selectedUserLabel;
  }

  get isPermissionSetsExpanded() {
    return this.expandedSections.permissionSets
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get isPublicGroupsExpanded() {
    return this.expandedSections.publicGroups
      ? "utility:chevrondown"
      : "utility:chevronright";
  }

  get isBasicInfoSectionExpanded() {
    return this.expandedSections.basicInfo;
  }

  get isSecurityInfoSectionExpanded() {
    return this.expandedSections.securityInfo;
  }

  get isLocaleInfoSectionExpanded() {
    return this.expandedSections.localeInfo;
  }

  get isPermissionSetsSectionExpanded() {
    return this.expandedSections.permissionSets;
  }

  get isPublicGroupsSectionExpanded() {
    return this.expandedSections.publicGroups;
  }

  // Helper methods for displaying data
  get formattedLastLoginDate() {
    if (this.sourceUserDetails?.basicInfo?.lastLoginDate) {
      return new Date(
        this.sourceUserDetails.basicInfo.lastLoginDate
      ).toLocaleDateString();
    }
    return "Never";
  }

  get hasPermissionSets() {
    return this.sourceUserDetails?.permissionSets?.length > 0;
  }

  get hasPublicGroups() {
    return this.sourceUserDetails?.publicGroups?.length > 0;
  }

  // Debug getter for userOptions length
  get userOptionsLength() {
    return this.userOptions ? this.userOptions.length : 0;
  }

  // History modal methods
  async showHistoryModal() {
    console.log("Opening history modal...");
    this.showHistory = true;
    this.isLoadingHistory = true;
    this.historyError = null;

    try {
      console.log("Calling getUserCloneHistory...");
      const result = await getUserCloneHistory();
      console.log("Clone history result:", result);
      this.cloneHistory = result || [];
      console.log("Clone history length:", this.cloneHistory.length);
    } catch (error) {
      console.error("Error loading clone history:", error);
      this.historyError = error.body?.message || "Failed to load clone history";
    } finally {
      this.isLoadingHistory = false;
    }
  }

  closeHistoryModal() {
    this.showHistory = false;
    this.cloneHistory = [];
    this.historyError = null;
  }

  navigateToClonedUser(event) {
    const clonedUserId = event.target.value;
    if (clonedUserId && SecurityUtils.validateId(clonedUserId)) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: clonedUserId,
                objectApiName: "User",
                actionName: "view"
            },
            state: {
                navigationLocation: "newTab"
            }
        });
    }
}

  get hasHistoryData() {
    return this.cloneHistory && this.cloneHistory.length > 0;
  }
  
  // Phase 1 Methods for Dry-Run Preview + Diff, License Compatibility Assistant, and Compare View
  
  /**
   * Shows the compare modal for comparing two users
   */
  showCompareUsersModal() {
    this.showCompareModal = true;
    this.compareSourceUserId = null;
    this.compareTargetUserId = null;
    this.compareResult = null;
  }
  
  /**
   * Closes the compare modal
   */
  closeCompareModal() {
    this.showCompareModal = false;
    this.compareResult = null;
    this.isLoadingCompare = false;
  }
  
  /**
   * Handles source user selection for comparison
   */
  handleCompareSourceUserChange(event) {
    this.compareSourceUserId = event.detail.value;
    const selectedOption = this.userOptions.find(option => option.value === event.detail.value);
    this.compareSourceUserName = selectedOption ? selectedOption.label : '';
  }
  
  /**
   * Handles target user selection for comparison
   */
  handleCompareTargetUserChange(event) {
    this.compareTargetUserId = event.detail.value;
    const selectedOption = this.userOptions.find(option => option.value === event.detail.value);
    this.compareTargetUserName = selectedOption ? selectedOption.label : '';
  }
  
  /**
   * Performs the comparison between two users
   */
  async performComparison() {
    if (!this.compareSourceUserId || !this.compareTargetUserId) {
      this.showToast('Error', 'Please select both source and target users', 'error');
      return;
    }
    
    if (this.compareSourceUserId === this.compareTargetUserId) {
      this.showToast('Error', 'Source and target users cannot be the same', 'error');
      return;
    }
    
    try {
      this.isLoadingCompare = true;
      console.log('Starting comparison between:', this.compareSourceUserId, 'and', this.compareTargetUserId);
      
      this.compareResult = await previewCloneDiff({
        sourceUserId: this.compareSourceUserId,
        targetUserId: this.compareTargetUserId
      });
      
      console.log('Comparison result received:', JSON.stringify(this.compareResult, null, 2));
      console.log('compareResult.addedPermissionSetGroups:', this.compareResult.addedPermissionSetGroups);
      console.log('compareResult.removedPermissionSetGroups:', this.compareResult.removedPermissionSetGroups);
      console.log('compareResult.userPermissionChanges:', this.compareResult.userPermissionChanges);
      console.log('compareResult.profileChange:', this.compareResult.profileChange);
      console.log('compareResult.roleChange:', this.compareResult.roleChange);
      
      // Log each data type separately
      const permissionSetsData = this.getPermissionSetsData();
      const permissionSetGroupsData = this.getPermissionSetGroupsData();
      const userPermissionsData = this.getUserPermissionsData();
      const profileRoleData = this.getProfileRoleData();
      
      console.log('Permission sets data:', permissionSetsData);
      console.log('Permission set groups data:', permissionSetGroupsData);
      console.log('User permissions data:', userPermissionsData);
      console.log('Profile role data:', profileRoleData);
      
      // Check if we have any data at all
      const totalItems = permissionSetsData.length + permissionSetGroupsData.length + userPermissionsData.length + profileRoleData.length;
      console.log('Total comparison items:', totalItems);
      
      if (totalItems === 0) {
        console.warn('No comparison data found - this might indicate an issue with the comparison logic');
      }
      
      // Update comparison summary after getting results
      this.updateComparisonSummary();
      
      this.logAnalyticsEvent('compare_users_performed', {
        sourceUserId: this.compareSourceUserId,
        targetUserId: this.compareTargetUserId,
        hasChanges: this.hasComparisonChanges
      });
      
    } catch (error) {
      console.error('Error performing comparison:', error);
      this.handleError(error);
    } finally {
      this.isLoadingCompare = false;
    }
  }
  
  /**
   * Shows the license compatibility assistant modal
   */
  async showLicenseAssistant() {
    if (!this.selectedUserId) {
      this.showToast('Error', 'Please select a source user first', 'error');
      return;
    }
    
    // When called from the permissions modal, ensure target user is selected
    if (this.isPermissionsModalOpen && !this.selectedTargetUserId) {
      this.showToast('Error', 'Please select a target user first', 'error');
      return;
    }
    
    try {
      this.isLoadingCompatibleProfiles = true;
      this.showLicenseAssistantModal = true;
      
      // Get source user profile
      const sourceUserDetails = await getSourceUserDetails({ userId: this.selectedUserId });
      
      // Validate that we have the required profile information
      if (!sourceUserDetails || !sourceUserDetails.securityInfo || !sourceUserDetails.securityInfo.profileId) {
        throw new Error('Unable to retrieve source user profile information. Please ensure the user has a valid profile assigned.');
      }
      
      const sourceProfileId = sourceUserDetails.securityInfo.profileId;
      
      // Additional validation for profileId
      if (!sourceProfileId || sourceProfileId.trim() === '') {
        throw new Error('Source user does not have a valid profile ID.');
      }
      
      // Use target user if selected, otherwise use source user (for backward compatibility)
      const targetUserId = this.selectedTargetUserId || this.selectedUserId;
      
      console.log('Calling getCompatibleProfiles with:', {
        userId: targetUserId,
        sourceProfileId: sourceProfileId
      });
      
      this.compatibleProfiles = await getCompatibleProfiles({
        userId: targetUserId,
        sourceProfileId: sourceProfileId
      });
      
      this.logAnalyticsEvent('license_assistant_opened', {
        sourceUserId: this.selectedUserId,
        targetUserId: targetUserId,
        profilesFound: this.compatibleProfiles.length
      });
      
    } catch (error) {
      console.error('Error loading compatible profiles:', error);
      this.handleError(error);
      this.showLicenseAssistantModal = false;
    } finally {
      this.isLoadingCompatibleProfiles = false;
    }
  }
  
  /**
   * Closes the license assistant modal
   */
  closeLicenseAssistantModal() {
    this.showLicenseAssistantModal = false;
    this.compatibleProfiles = [];
    this.selectedCompatibleProfileId = null;
  }

  /**
   * Getter to check if there are compatible profiles available
   */
  get hasCompatibleProfiles() {
    return this.compatibleProfiles && this.compatibleProfiles.length > 0;
  }
  
  /**
   * Handles compatible profile selection
   */
  handleCompatibleProfileSelection(event) {
    this.selectedCompatibleProfileId = event.target.value;
    console.log('Profile selected:', this.selectedCompatibleProfileId);
  }
  
  /**
   * Applies the selected compatible profile
   */
  applyCompatibleProfile() {
    if (!this.selectedCompatibleProfileId) {
      this.showToast('Error', 'Please select a profile', 'error');
      return;
    }
    
    // Find the selected profile
    const selectedProfile = this.compatibleProfiles.find(
      profile => profile.profileId === this.selectedCompatibleProfileId
    );
    
    if (selectedProfile) {
      this.showToast(
        'Success',
        `Profile "${selectedProfile.profileName}" will be used for cloning`,
        'success'
      );
      
      this.logAnalyticsEvent('compatible_profile_applied', {
        profileId: selectedProfile.profileId,
        profileName: selectedProfile.profileName
      });
      
      this.closeLicenseAssistantModal();
    }
  }
  
  /**
   * Shows dry-run preview for permission cloning
   */
  async showDryRunPreview() {
    if (!this.selectedUserId || !this.selectedTargetUserId) {
      this.showToast('Error', 'Please select both source and target users', 'error');
      return;
    }
    
    try {
       this.isLoadingDryRun = true;
       // Close the permissions modal first
       this.isPermissionsModalOpen = false;
       this.isDryRunPreviewOpen = true;
       
       this.dryRunResult = await previewCloneDiff({
         sourceUserId: this.selectedUserId,
         targetUserId: this.selectedTargetUserId
       });
       
       this.logAnalyticsEvent('dry_run_preview_shown', {
         sourceUserId: this.selectedUserId,
         targetUserId: this.selectedTargetUserId,
         changesCount: this.getTotalChangesCount(this.dryRunResult)
       });
       
     } catch (error) {
       console.error('Error generating dry-run preview:', error);
       this.handleError(error);
       this.isDryRunPreviewOpen = false;
     } finally {
       this.isLoadingDryRun = false;
     }
  }
  
  /**
    * Closes the dry-run preview
    */
   closeDryRunPreview() {
     this.isDryRunPreviewOpen = false;
     this.dryRunResult = null;
   }
  
  /**
   * Proceeds with cloning without removing existing permissions
   */
  proceedWithoutRemovals() {
    this.closeDryRunPreview();
    this.handleClonePermissions(false); // false = don't remove existing permissions
  }

  /**
   * Proceeds with complete cloning (including removals)
   */
  proceedWithCloning() {
    this.closeDryRunPreview();
    this.handleClonePermissions(true); // true = allow removals
  }
  
  /**
   * Handles selective permission checkbox changes
   */
  handleSelectivePermissionChange(event) {
    const permissionType = event.target.dataset.type;
    const permissionId = event.target.dataset.id;
    const isChecked = event.target.checked;
    
    if (permissionType === 'profileChange') {
      this.selectedPermissions.profileChange = isChecked;
    } else if (permissionType === 'roleChange') {
      this.selectedPermissions.roleChange = isChecked;
    } else if (permissionType === 'permissionSet') {
      if (isChecked) {
        if (!this.selectedPermissions.selectedPermissionSets.includes(permissionId)) {
          this.selectedPermissions.selectedPermissionSets.push(permissionId);
        }
      } else {
        this.selectedPermissions.selectedPermissionSets = this.selectedPermissions.selectedPermissionSets.filter(id => id !== permissionId);
      }
    } else if (permissionType === 'permissionSetGroup') {
      if (isChecked) {
        if (!this.selectedPermissions.selectedPermissionSetGroups.includes(permissionId)) {
          this.selectedPermissions.selectedPermissionSetGroups.push(permissionId);
        }
      } else {
        this.selectedPermissions.selectedPermissionSetGroups = this.selectedPermissions.selectedPermissionSetGroups.filter(id => id !== permissionId);
      }
    } else if (permissionType === 'publicGroup') {
      if (isChecked) {
        if (!this.selectedPermissions.selectedPublicGroups.includes(permissionId)) {
          this.selectedPermissions.selectedPublicGroups.push(permissionId);
        }
      } else {
        this.selectedPermissions.selectedPublicGroups = this.selectedPermissions.selectedPublicGroups.filter(id => id !== permissionId);
      }
    } else if (permissionType === 'userPermission') {
      if (isChecked) {
        if (!this.selectedPermissions.selectedUserPermissions.includes(permissionId)) {
          this.selectedPermissions.selectedUserPermissions.push(permissionId);
        }
      } else {
        this.selectedPermissions.selectedUserPermissions = this.selectedPermissions.selectedUserPermissions.filter(id => id !== permissionId);
      }
    } else if (permissionType === 'removeUnselected') {
      this.selectedPermissions.removeUnselectedPermissions = isChecked;
      
      // Update removal lists based on current selections
      this.updateRemovalLists();
    }
  }
  
  /**
   * Updates the removal lists based on current selections
   */
  updateRemovalLists() {
    if (!this.dryRunResult) return;
    
    // Update removed permission sets
    if (this.dryRunResult.removedPermissionSets) {
      this.selectedPermissions.removedPermissionSets = this.dryRunResult.removedPermissionSets
        .filter(ps => !this.selectedPermissions.selectedPermissionSets.includes(ps.id))
        .map(ps => ps.id);
    }
    
    // Update removed permission set groups
    if (this.dryRunResult.removedPermissionSetGroups) {
      this.selectedPermissions.removedPermissionSetGroups = this.dryRunResult.removedPermissionSetGroups
        .filter(psg => !this.selectedPermissions.selectedPermissionSetGroups.includes(psg.id))
        .map(psg => psg.id);
    }
    
    // Update removed public groups
    if (this.dryRunResult.removedPublicGroups) {
      this.selectedPermissions.removedPublicGroups = this.dryRunResult.removedPublicGroups
        .filter(group => !this.selectedPermissions.selectedPublicGroups.includes(group.id))
        .map(group => group.id);
    }
  }
  
  /**
   * Proceeds with selective cloning based on user selections
   */
  async proceedWithSelectiveCloning() {
    if (!this.selectedUserId || !this.selectedTargetUserId) {
      this.showToast('Error', 'Please select both source and target users', 'error');
      return;
    }
    
    this.isLoading = true;
    this.closeDryRunPreview();
    
    try {
      const result = await clonePermissionsSelectively({
        sourceUserId: this.selectedUserId,
        targetUserId: this.selectedTargetUserId,
        selectedPermissions: this.selectedPermissions
      });
      
      // Handle the result similar to regular cloning
      if (result.hasError) {
        let toastVariant = "info";
        let toastTitle = "Information";
        
        if (result.errorType === 'LICENSE_LIMIT_ERROR') {
          toastVariant = "warning";
          toastTitle = "License Limit Exceeded";
        } else if (result.errorType === 'ROLE_UPDATE_ERROR') {
          toastVariant = "warning";
          toastTitle = "Role Update Restricted";
        } else if (result.errorType === 'PROFILE_UPDATE_ERROR') {
          toastVariant = "warning";
          toastTitle = "Profile Update Restricted";
        }
        
        this.showToast(
          toastTitle,
          result.errorMessage || "Selective permission cloning completed with restrictions",
          toastVariant
        );
        
        // Still show summary if some operations succeeded
        if (result.permissionSetsCloned > 0 || result.permissionSetGroupsCloned > 0 || result.groupsCloned > 0) {
          this.permissionsCloneResult = result;
          this.showPermissionsSummary = true;
        }
      } else {
        this.permissionsCloneResult = result;
        this.showPermissionsSummary = true;
        this.showToast(
          "Success",
          "Selected permissions cloned successfully",
          "success"
        );
      }
      
      // Clear clone history cache
      this.cloneHistory = [];
      
      // Log analytics
      this.logAnalyticsEvent('selective_permissions_cloned', {
        sourceUserId: this.selectedUserId,
        targetUserId: this.selectedTargetUserId,
        permissionSetsCloned: result.permissionSetsCloned || 0,
        permissionSetGroupsCloned: result.permissionSetGroupsCloned || 0,
        groupsCloned: result.groupsCloned || 0,
        userPermissionsCloned: result.userPermissionsCloned || 0
      });
      
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
      this.resetSelectivePermissions();
    }
  }
  
  /**
   * Resets selective permission selections
   */
  resetSelectivePermissions() {
    this.selectedPermissions = {
      profileChange: false,
      roleChange: false,
      selectedPermissionSets: [],
      selectedPermissionSetGroups: [],
      selectedPublicGroups: [],
      selectedUserPermissions: [],
      removedPermissionSets: [],
      removedPermissionSetGroups: [],
      removedPublicGroups: [],
      removeUnselectedPermissions: false
    };
    this.isSelectiveCloning = false;
  }
  
  /**
   * Toggles selective cloning mode
   */
  toggleSelectiveCloning() {
    this.isSelectiveCloning = !this.isSelectiveCloning;
    if (!this.isSelectiveCloning) {
      this.resetSelectivePermissions();
    }
  }
  
  /**
   * Selects all available permissions for cloning
   */
  selectAllPermissions() {
    if (!this.dryRunResult) return;
    
    // Select profile and role changes
    this.selectedPermissions.profileChange = !!this.dryRunResult.profileChange;
    this.selectedPermissions.roleChange = !!this.dryRunResult.roleChange;
    
    // Select all permission sets to add
    if (this.dryRunResult.addedPermissionSets) {
      this.selectedPermissions.selectedPermissionSets = this.dryRunResult.addedPermissionSets.map(ps => ps.id);
    }
    
    // Select all permission set groups to add
    if (this.dryRunResult.addedPermissionSetGroups) {
      this.selectedPermissions.selectedPermissionSetGroups = this.dryRunResult.addedPermissionSetGroups.map(psg => psg.id);
    }
    
    // Select all public groups to add
    if (this.dryRunResult.addedGroups) {
      this.selectedPermissions.selectedPublicGroups = this.dryRunResult.addedGroups.map(group => group.id);
    }
    
    // Select all user permission changes
    if (this.dryRunResult.userPermissionChanges) {
      this.selectedPermissions.selectedUserPermissions = this.dryRunResult.userPermissionChanges.map(perm => perm.fieldName);
    }
  }
  
  /**
   * Deselects all permissions
   */
  deselectAllPermissions() {
    this.resetSelectivePermissions();
    this.isSelectiveCloning = true; // Keep selective mode on
  }
  
  /**
   * Gets the count of selected permissions
   */
  get selectedPermissionsCount() {
    let count = 0;
    if (this.selectedPermissions.profileChange) count++;
    if (this.selectedPermissions.roleChange) count++;
    count += this.selectedPermissions.selectedPermissionSets.length;
    count += this.selectedPermissions.selectedPermissionSetGroups.length;
    count += this.selectedPermissions.selectedPublicGroups.length;
    count += this.selectedPermissions.selectedUserPermissions.length;
    return count;
  }
  
  /**
   * Checks if any permissions are selected
   */
  get hasSelectedPermissions() {
    return this.selectedPermissionsCount > 0;
  }
  
  /**
   * Checks if no permissions are selected (for button disabled state)
   */
  get noPermissionsSelected() {
    return this.selectedPermissionsCount === 0;
  }
  
  /**
   * Gets the label for the selective cloning toggle button
   */
  get selectiveCloneButtonLabel() {
    return this.isSelectiveCloning ? 'Exit Selective Mode' : 'Select Permissions';
  }
  
  // Getter methods for Phase 1 features
  
  /**
   * Checks if comparison has any changes
   */
  get hasComparisonChanges() {
    if (!this.compareResult || !this.compareResult.summary) {
      return false;
    }
    
    const summary = this.compareResult.summary;
    return summary.hasProfileChange || 
           summary.hasRoleChange || 
           summary.permissionSetsAdded > 0 || 
           summary.permissionSetsRemoved > 0 || 
           summary.permissionSetGroupsAdded > 0 || 
           summary.permissionSetGroupsRemoved > 0 || 
           summary.groupsAdded > 0 || 
           summary.groupsRemoved > 0 ||
           summary.userPermissionsChanged > 0;
  }
  
  /**
   * Gets total count of changes for dry-run
   */
  getTotalChangesCount(result) {
    if (!result || !result.summary) {
      return 0;
    }
    
    const summary = result.summary;
    return (summary.hasProfileChange ? 1 : 0) +
           (summary.hasRoleChange ? 1 : 0) +
           summary.permissionSetsAdded +
           summary.permissionSetsRemoved +
           summary.permissionSetGroupsAdded +
           summary.permissionSetGroupsRemoved +
           summary.groupsAdded +
           summary.groupsRemoved +
           summary.userPermissionsChanged;
  }
  
  /**
   * Checks if dry-run has any changes
   */
  get hasDryRunChanges() {
    return this.dryRunResult && this.getTotalChangesCount(this.dryRunResult) > 0;
  }

  /**
   * Checks if dry-run has any removals (permission sets, groups, etc.)
   */
  get hasRemovals() {
    if (!this.dryRunResult) return false;
    
    return (this.dryRunResult.removedPermissionSets && this.dryRunResult.removedPermissionSets.length > 0) ||
           (this.dryRunResult.removedPermissionSetGroups && this.dryRunResult.removedPermissionSetGroups.length > 0) ||
           (this.dryRunResult.removedPublicGroups && this.dryRunResult.removedPublicGroups.length > 0) ||
           (this.dryRunResult.removedQueues && this.dryRunResult.removedQueues.length > 0) ||
           (this.dryRunResult.userPermissionChanges && this.dryRunResult.userPermissionChanges.some(change => change.toValue === 'false'));
  }
  
  /**
   * Checks if there are public groups to add
   */
  get hasAddedPublicGroups() {
    return this.dryRunResult && this.dryRunResult.addedPublicGroups && this.dryRunResult.addedPublicGroups.length > 0;
  }
  
  /**
   * Checks if there are public groups to remove
   */
  get hasRemovedPublicGroups() {
    return this.dryRunResult && this.dryRunResult.removedPublicGroups && this.dryRunResult.removedPublicGroups.length > 0;
  }
  
  /**
   * Checks if there are queues to add
   */
  get hasAddedQueues() {
    return this.dryRunResult && this.dryRunResult.addedQueues && this.dryRunResult.addedQueues.length > 0;
  }
  
  /**
   * Checks if there are queues to remove
   */
  get hasRemovedQueues() {
    return this.dryRunResult && this.dryRunResult.removedQueues && this.dryRunResult.removedQueues.length > 0;
  }
  
  /**
   * Gets formatted comparison summary
   */
  get comparisonSummaryText() {
    if (!this.compareResult || !this.hasComparisonChanges) {
      return 'No differences found between the selected users.';
    }
    
    const changes = [];
    const summary = this.compareResult.summary;
    
    if (summary.hasProfileChange) changes.push('Profile');
    if (summary.hasRoleChange) changes.push('Role');
    if (summary.permissionSetsAdded > 0) changes.push(`+${summary.permissionSetsAdded} Permission Sets`);
    if (summary.permissionSetsRemoved > 0) changes.push(`-${summary.permissionSetsRemoved} Permission Sets`);
    if (summary.permissionSetGroupsAdded > 0) changes.push(`+${summary.permissionSetGroupsAdded} Permission Set Groups`);
    if (summary.permissionSetGroupsRemoved > 0) changes.push(`-${summary.permissionSetGroupsRemoved} Permission Set Groups`);
    if (summary.groupsAdded > 0) changes.push(`+${summary.groupsAdded} Groups`);
    if (summary.groupsRemoved > 0) changes.push(`-${summary.groupsRemoved} Groups`);
    if (summary.userPermissionsChanged > 0) changes.push(`${summary.userPermissionsChanged} User Permissions`);
    
    return `Changes detected: ${changes.join(', ')}`;
  }
  
  // Enhanced comparison methods
  
  /**
   * Handles tab change in comparison modal
   */
  handleCompareTabChange(event) {
    this.activeCompareTab = event.target.value;
  }
  
  /**
   * Handles search input in comparison modal
   */
  handleCompareSearch(event) {
    this.compareSearchTerm = event.target.value;
  }
  
  /**
   * Toggles show differences only filter
   */
  handleToggleDifferencesOnly(event) {
    this.showDifferencesOnly = event.target.checked;
  }
  
  /**
   * Toggles expand/collapse all results
   */
  handleToggleExpandAll(event) {
    this.expandAllResults = event.target.checked;
  }
  
  /**
   * Exports comparison results
   */
  handleExportComparison() {
    if (!this.compareResult) {
      this.showToast('Error', 'No comparison data to export', 'error');
      return;
    }
    
    try {
      const exportData = this.prepareExportData();
      const dataStr = JSON.stringify(exportData, null, 2);
      const dataBlob = new Blob([dataStr], { type: 'application/json' });
      
      const link = document.createElement('a');
      link.href = URL.createObjectURL(dataBlob);
      link.download = `user-comparison-${this.compareSourceUserName}-vs-${this.compareTargetUserName}-${new Date().toISOString().split('T')[0]}.json`;
      link.click();
      
      this.showToast('Success', 'Comparison data exported successfully', 'success');
      
      this.logAnalyticsEvent('comparison_exported', {
        sourceUserId: this.compareSourceUserId,
        targetUserId: this.compareTargetUserId,
        exportFormat: 'json'
      });
      
    } catch (error) {
      console.error('Error exporting comparison:', error);
      this.showToast('Error', 'Failed to export comparison data', 'error');
    }
  }
  
  /**
   * Prepares data for export
   */
  prepareExportData() {
    return {
      exportDate: new Date().toISOString(),
      sourceUser: {
        id: this.compareSourceUserId,
        name: this.compareSourceUserName
      },
      targetUser: {
        id: this.compareTargetUserId,
        name: this.compareTargetUserName
      },
      summary: this.compareResult.summary,
      changes: {
        profile: this.compareResult.profileChange,
        role: this.compareResult.roleChange,
        permissionSets: {
          added: this.compareResult.addedPermissionSets || [],
          removed: this.compareResult.removedPermissionSets || []
        },
        permissionSetGroups: {
          added: this.compareResult.addedPermissionSetGroups || [],
          removed: this.compareResult.removedPermissionSetGroups || []
        },
        publicGroups: {
          added: this.compareResult.addedPublicGroups || [],
          removed: this.compareResult.removedPublicGroups || []
        },
        userPermissions: this.compareResult.userPermissionChanges || []
      }
    };
  }
  
  /**
   * Updates comparison summary based on results
   */
  updateComparisonSummary() {
    if (!this.compareResult) {
      this.comparisonSummary = { total: 0, added: 0, removed: 0, changed: 0, unchanged: 0 };
      return;
    }
    
    const summary = this.compareResult.summary;
    let total = 0;
    let added = 0;
    let removed = 0;
    let changed = 0;
    
    // Count profile and role changes
    if (summary.hasProfileChange) {
      total++;
      changed++;
    }
    if (summary.hasRoleChange) {
      total++;
      changed++;
    }
    
    // Count permission sets
    added += summary.permissionSetsAdded || 0;
    removed += summary.permissionSetsRemoved || 0;
    total += (summary.permissionSetsAdded || 0) + (summary.permissionSetsRemoved || 0);
    
    // Count permission set groups
    added += summary.permissionSetGroupsAdded || 0;
    removed += summary.permissionSetGroupsRemoved || 0;
    total += (summary.permissionSetGroupsAdded || 0) + (summary.permissionSetGroupsRemoved || 0);
    
    // Count public groups
    added += summary.groupsAdded || 0;
    removed += summary.groupsRemoved || 0;
    total += (summary.groupsAdded || 0) + (summary.groupsRemoved || 0);
    
    // Count user permissions
    changed += summary.userPermissionsChanged || 0;
    total += summary.userPermissionsChanged || 0;
    
    this.comparisonSummary = {
      total,
      added,
      removed,
      changed,
      unchanged: 0 // This would need to be calculated based on total items vs changes
    };
  }
  
  /**
   * Gets filtered comparison data for active tab
   */
  get filteredComparisonData() {
    if (!this.compareResult) {
      console.log('No compareResult available');
      return [];
    }
    
    let data = [];
    
    switch (this.activeCompareTab) {
      case 'permissionSets':
        data = this.getPermissionSetsData();
        break;
      case 'permissionSetGroups':
        data = this.getPermissionSetGroupsData();
        break;
      case 'userPermissions':
        data = this.getUserPermissionsData();
        break;
      case 'profileRole':
        data = this.getProfileRoleData();
        break;
      default:
        data = [];
    }
    
    console.log(`Filtered data for ${this.activeCompareTab}:`, data);
    
    // Apply search filter
    if (this.compareSearchTerm) {
      const searchLower = this.compareSearchTerm.toLowerCase();
      data = data.filter(item => {
        const name = item.name || '';
        const label = item.label || '';
        const description = item.description || '';
        
        return name.toLowerCase().includes(searchLower) ||
               label.toLowerCase().includes(searchLower) ||
               description.toLowerCase().includes(searchLower);
      });
    }
    
    // Apply differences filter
    if (this.showDifferencesOnly) {
      data = data.filter(item => item.status !== 'unchanged');
    }
    
    console.log(`Final filtered data for ${this.activeCompareTab}:`, data);
    return data;
  }
  
  /**
   * Gets filtered permission sets data
   */
  get filteredPermissionSets() {
    const data = this.getPermissionSetsData();
    console.log('UserClone - filteredPermissionSets:', data);
    return data;
  }
  
  /**
   * Gets filtered permission set groups data
   */
  get filteredPermissionSetGroups() {
    const data = this.getPermissionSetGroupsData();
    console.log('UserClone - filteredPermissionSetGroups:', data);
    return data;
  }
  
  /**
   * Gets filtered user permissions data
   */
  get filteredUserPermissions() {
    const data = this.getUserPermissionsData();
    console.log('UserClone - filteredUserPermissions called');
    console.log('UserClone - filteredUserPermissions data:', data);
    console.log('UserClone - filteredUserPermissions data length:', data ? data.length : 'null/undefined');
    console.log('UserClone - compareResult exists:', !!this.compareResult);
    return data;
  }
  
  /**
   * Gets filtered profile and role data
   */
  get filteredProfileRole() {
    const data = this.getProfileRoleData();
    console.log('UserClone - filteredProfileRole:', data);
    return data;
  }
  
  /**
   * Tab state getters
   */
  get isPermissionSetsTabActive() {
    return this.activeCompareTab === 'permissionSets';
  }
  
  get isPermissionSetGroupsTabActive() {
    return this.activeCompareTab === 'permissionSetGroups';
  }
  
  get isUserPermissionsTabActive() {
    const isActive = this.activeCompareTab === 'userPermissions';
    console.log('UserClone - isUserPermissionsTabActive called');
    console.log('UserClone - activeCompareTab:', this.activeCompareTab);
    console.log('UserClone - isUserPermissionsTabActive result:', isActive);
    return isActive;
  }
  
  get isProfileRoleTabActive() {
    return this.activeCompareTab === 'profileRole';
  }
  
  /**
   * Tab click handlers
   */
  handlePermissionSetsTab() {
    this.activeCompareTab = 'permissionSets';
  }
  
  handlePermissionSetGroupsTab() {
    this.activeCompareTab = 'permissionSetGroups';
  }
  
  handleUserPermissionsTab() {
    console.log('UserClone - handleUserPermissionsTab called');
    console.log('UserClone - Previous activeCompareTab:', this.activeCompareTab);
    this.activeCompareTab = 'userPermissions';
    console.log('UserClone - New activeCompareTab:', this.activeCompareTab);
    console.log('UserClone - User permissions data length:', this.getUserPermissionsData().length);
  }
  
  handleProfileRoleTab() {
    this.activeCompareTab = 'profileRole';
  }
  
  /**
   * Summary count getters
   */
  get addedCount() {
    return this.comparisonSummary.added || 0;
  }
  
  get removedCount() {
    return this.comparisonSummary.removed || 0;
  }
  
  get changedCount() {
    return this.comparisonSummary.changed || 0;
  }
  
  get unchangedCount() {
    return this.comparisonSummary.unchanged || 0;
  }
  
  get totalCount() {
    return this.comparisonSummary.total || 0;
  }
  
  /**
   * Tab count getters
   */
  get permissionSetsCount() {
    return this.getPermissionSetsData().length;
  }
  
  get permissionSetGroupsCount() {
    return this.getPermissionSetGroupsData().length;
  }
  
  get userPermissionsCount() {
    return this.getUserPermissionsData().length;
  }
  
  get profileRoleCount() {
    return this.getProfileRoleData().length;
  }
  
  /**
   * Search and filter handlers
   */
  handleSearchChange(event) {
    this.compareSearchTerm = event.target.value;
  }
  
  handleSortChange(event) {
    this.sortBy = event.target.value;
  }
  
  handleDifferencesOnlyToggle(event) {
    this.showDifferencesOnly = event.target.checked;
  }
  
  handleExpandCollapseAll() {
    this.expandAllResults = !this.expandAllResults;
  }

  /**
   * Clears all filters in the comparison modal
   */
  handleClearFilters() {
    this.compareSearchTerm = '';
    this.showDifferencesOnly = false;
  }

  /**
   * Handles exporting comparison results
   */
  handleExportResults() {
    // Call the existing export method
    this.handleExportComparison();
  }

  /**
   * Handles cloning selected items from comparison
   */
  handleCloneSelected() {
    // TODO: Implement clone selected functionality
    console.log('Clone selected functionality not yet implemented');
    this.showToast('Info', 'Clone selected functionality coming soon', 'info');
  }

  /**
   * Gets whether no items are selected for cloning
   */
  get noItemsSelected() {
    // TODO: Implement selection tracking
    return true; // For now, always disable the button
  }

  /**
   * Handles item actions from compare results list
   */
  handleItemAction(event) {
    const { action, itemId, itemType } = event.detail;
    
    switch (action) {
      case 'view':
        // Handle view action
        console.log('View item:', itemId, itemType);
        break;
      case 'select':
        // Handle select action
        console.log('Select item:', itemId, itemType);
        break;
      default:
        console.log('Unknown action:', action);
    }
  }

  /**
   * Additional getters for UI elements
   */
  get sortBy() {
    return this._sortBy || 'name';
  }
  
  set sortBy(value) {
    this._sortBy = value;
  }
  
  get sortOptions() {
    return [
      { label: 'Name', value: 'name' },
      { label: 'Status', value: 'status' },
      { label: 'Type', value: 'type' }
    ];
  }
  
  get expandCollapseLabel() {
    return this.expandAllResults ? 'Collapse All' : 'Expand All';
  }
  
  get expandCollapseIcon() {
    return this.expandAllResults ? 'utility:collapse_all' : 'utility:expand_all';
  }

  /**
   * Shows empty state when no differences found
   */
  get showEmptyState() {
    return this.compareResult && !this.hasComparisonChanges && !this.isLoadingCompare;
  }

  /**
   * Shows no results state when search/filter returns no results
   */
  get showNoResultsState() {
    return this.compareResult && this.hasComparisonChanges && 
           this.filteredComparisonData && this.filteredComparisonData.length === 0;
  }

  /**
   * Gets permission sets comparison data
   */
  getPermissionSetsData() {
    const data = [];
    
    // Added permission sets (present in source user, not in target user)
    if (this.compareResult.addedPermissionSets) {
      this.compareResult.addedPermissionSets.forEach(ps => {
        data.push(this.formatComparisonItem({
          id: ps.id,
          name: ps.name,
          label: ps.label,
          description: ps.description,
          status: 'added',
          type: 'permissionSet',
          sourceUser: this.compareSourceUserName,
          targetUser: this.compareTargetUserName,
          belongsTo: 'source',
          userInfo: `Present in ${this.compareSourceUserName}, Missing in ${this.compareTargetUserName}`
        }));
      });
    }
    
    // Removed permission sets (present in target user, not in source user)
    if (this.compareResult.removedPermissionSets) {
      this.compareResult.removedPermissionSets.forEach(ps => {
        data.push(this.formatComparisonItem({
          id: ps.id,
          name: ps.name,
          label: ps.label,
          description: ps.description,
          status: 'removed',
          type: 'permissionSet',
          sourceUser: this.compareSourceUserName,
          targetUser: this.compareTargetUserName,
          belongsTo: 'target',
          userInfo: `Present in ${this.compareTargetUserName}, Missing in ${this.compareSourceUserName}`
        }));
      });
    }
    
    return data;
  }

  /**
   * Formats a comparison item with all required properties for the compareResultsList component
   */
  formatComparisonItem(item) {
    const statusClass = this.getItemStatusClass(item.status);
    const statusIcon = this.getItemStatusIcon(item.status);
    const statusLabel = this.getItemStatusLabel(item.status);
    
    return {
      ...item,
      statusClass: statusClass,
      statusIcon: statusIcon,
      statusIconClass: statusClass,
      statusLabel: statusLabel,
      statusBadgeClass: `status-badge ${statusClass}`,
      expandIcon: 'utility:chevronright',
      expandTitle: 'Expand details',
      expanded: this.expandAllResults,
      selected: false,
      selectable: true,
      details: {
        id: item.id,
        apiName: item.name,
        type: item.type,
        description: item.description
      }
    };
  }

  /**
   * Gets CSS class for item status
   */
  getItemStatusClass(status) {
    switch (status) {
      case 'added':
        return 'status-added';
      case 'removed':
        return 'status-removed';
      case 'changed':
        return 'status-changed';
      case 'unchanged':
        return 'status-unchanged';
      default:
        return 'status-unknown';
    }
  }

  /**
   * Gets icon for item status
   */
  getItemStatusIcon(status) {
    switch (status) {
      case 'added':
        return 'utility:add';
      case 'removed':
        return 'utility:dash';
      case 'changed':
        return 'utility:swap';
      case 'unchanged':
        return 'utility:check';
      default:
        return 'utility:info';
    }
  }

  /**
   * Gets label for item status
   */
  getItemStatusLabel(status) {
    switch (status) {
      case 'added':
        return 'Added';
      case 'removed':
        return 'Removed';
      case 'changed':
        return 'Changed';
      case 'unchanged':
        return 'Unchanged';
      default:
        return 'Unknown';
    }
  }
  
  /**
   * Gets permission set groups comparison data
   */
  getPermissionSetGroupsData() {
    const data = [];
    
    if (!this.compareResult) {
      console.log('UserClone - getPermissionSetGroupsData: No compareResult available');
      return data;
    }
    
    // Added permission set groups (present in source user, not in target user)
    if (this.compareResult.addedPermissionSetGroups) {
      console.log('UserClone - addedPermissionSetGroups:', this.compareResult.addedPermissionSetGroups);
      this.compareResult.addedPermissionSetGroups.forEach(psg => {
        data.push(this.formatComparisonItem({
          id: psg.id,
          name: psg.name,
          label: psg.label,
          description: psg.description,
          status: 'added',
          type: 'permissionSetGroup',
          sourceUser: this.compareSourceUserName,
          targetUser: this.compareTargetUserName,
          belongsTo: 'source',
          userInfo: `Present in ${this.compareSourceUserName}, Missing in ${this.compareTargetUserName}`
        }));
      });
    }
    
    // Removed permission set groups (present in target user, not in source user)
    if (this.compareResult.removedPermissionSetGroups) {
      console.log('UserClone - removedPermissionSetGroups:', this.compareResult.removedPermissionSetGroups);
      this.compareResult.removedPermissionSetGroups.forEach(psg => {
        data.push(this.formatComparisonItem({
          id: psg.id,
          name: psg.name,
          label: psg.label,
          description: psg.description,
          status: 'removed',
          type: 'permissionSetGroup',
          sourceUser: this.compareSourceUserName,
          targetUser: this.compareTargetUserName,
          belongsTo: 'target',
          userInfo: `Present in ${this.compareTargetUserName}, Missing in ${this.compareSourceUserName}`
        }));
      });
    }
    
    console.log('UserClone - getPermissionSetGroupsData result:', data);
    return data;
  }
  
  /**
   * Gets user permissions comparison data
   */
  getUserPermissionsData() {
    const data = [];
    
    console.log('UserClone - getUserPermissionsData: Starting method');
    console.log('UserClone - compareResult:', this.compareResult);
    
    if (!this.compareResult) {
      console.log('UserClone - getUserPermissionsData: No compareResult available');
      return data;
    }
    
    console.log('UserClone - compareResult.userPermissionChanges exists:', !!this.compareResult.userPermissionChanges);
    console.log('UserClone - compareResult.userPermissionChanges:', this.compareResult.userPermissionChanges);
    
    if (this.compareResult.userPermissionChanges && Array.isArray(this.compareResult.userPermissionChanges)) {
      console.log('UserClone - userPermissionChanges length:', this.compareResult.userPermissionChanges.length);
      
      this.compareResult.userPermissionChanges.forEach((change, index) => {
        console.log(`UserClone - Processing change ${index}:`, change);
        console.log(`UserClone - Change ${index} fieldName:`, change.fieldName);
        console.log(`UserClone - Change ${index} label:`, change.label);
        console.log(`UserClone - Change ${index} fromValue:`, change.fromValue);
        console.log(`UserClone - Change ${index} toValue:`, change.toValue);
        console.log(`UserClone - Change ${index} changeType:`, change.changeType);
        
        // Handle both string and boolean values for fromValue and toValue
        let fromValueBool, toValueBool;
        
        if (typeof change.fromValue === 'string') {
          fromValueBool = change.fromValue === 'true';
        } else {
          fromValueBool = Boolean(change.fromValue);
        }
        
        if (typeof change.toValue === 'string') {
          toValueBool = change.toValue === 'true';
        } else {
          toValueBool = Boolean(change.toValue);
        }
        
        const fromValueText = fromValueBool ? 'Enabled' : 'Disabled';
        const toValueText = toValueBool ? 'Enabled' : 'Disabled';
        
        const formattedItem = this.formatComparisonItem({
          id: change.fieldName,
          name: change.fieldName,
          label: change.label || change.fieldName,
          description: `Permission: ${change.label || change.fieldName}`,
          status: 'changed',
          type: 'userPermission',
          sourceUser: this.compareSourceUserName,
          targetUser: this.compareTargetUserName,
          fromValue: fromValueBool,
          toValue: toValueBool,
          userInfo: `${this.compareTargetUserName}: ${fromValueText} → ${this.compareSourceUserName}: ${toValueText}`,
          valueComparison: {
            sourceValue: toValueText,
            targetValue: fromValueText,
            sourceUser: this.compareSourceUserName,
            targetUser: this.compareTargetUserName
          }
        });
        
        console.log(`UserClone - Formatted item ${index}:`, formattedItem);
        data.push(formattedItem);
      });
    } else {
      console.log('UserClone - userPermissionChanges is not an array or is undefined');
    }
    
    console.log('UserClone - getUserPermissionsData final result:', data);
    console.log('UserClone - getUserPermissionsData final result length:', data.length);
    return data;
  }
  
  /**
   * Gets profile and role comparison data
   */
  getProfileRoleData() {
    const data = [];
    
    if (!this.compareResult) {
      console.log('UserClone - getProfileRoleData: No compareResult available');
      return data;
    }
    
    if (this.compareResult.profileChange) {
      console.log('UserClone - profileChange:', this.compareResult.profileChange);
      data.push(this.formatComparisonItem({
        id: 'profile',
        name: 'Profile',
        label: 'User Profile',
        description: 'User\'s assigned profile',
        status: 'changed',
        type: 'profile',
        fromValue: this.compareResult.profileChange.fromProfileName,
        toValue: this.compareResult.profileChange.toProfileName,
        sourceUser: this.compareSourceUserName,
        targetUser: this.compareTargetUserName,
        belongsTo: 'both',
        userInfo: `${this.compareTargetUserName}: ${this.compareResult.profileChange.fromProfileName} → ${this.compareSourceUserName}: ${this.compareResult.profileChange.toProfileName}`
      }));
    }
    
    if (this.compareResult.roleChange) {
      console.log('UserClone - roleChange:', this.compareResult.roleChange);
      data.push(this.formatComparisonItem({
        id: 'role',
        name: 'Role',
        label: 'User Role',
        description: 'User\'s assigned role',
        status: 'changed',
        type: 'role',
        fromValue: this.compareResult.roleChange.fromRoleName,
        toValue: this.compareResult.roleChange.toRoleName,
        sourceUser: this.compareSourceUserName,
        targetUser: this.compareTargetUserName,
        belongsTo: 'both',
        userInfo: `${this.compareTargetUserName}: ${this.compareResult.roleChange.fromRoleName || 'No Role'} → ${this.compareSourceUserName}: ${this.compareResult.roleChange.toRoleName || 'No Role'}`
      }));
    }
    
    console.log('UserClone - getProfileRoleData result:', data);
    return data;
  }
}