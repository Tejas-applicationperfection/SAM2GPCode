import { LightningElement, track, wire } from 'lwc';
import getLicenseUtilization from '@salesforce/apex/userCloneAnalytics.getLicenseUtilization';
import getCloningPatterns from '@salesforce/apex/userCloneAnalytics.getCloningPatterns';
import getPermissionDistribution from '@salesforce/apex/userCloneAnalytics.getPermissionDistribution';
import getCloneHistory from '@salesforce/apex/userCloneAnalytics.getCloneHistory';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/ChartJS';
import { NavigationMixin } from 'lightning/navigation';

// Security utility functions
const SecurityUtils = {
    sanitizeString(str) {
        if (!str) return '';
        return String(str)
            .replace(/[<>]/g, '')
            .trim();
    },

    maskUserData(userData) {
        if (!userData) return 'Unknown';
        const sanitized = this.sanitizeString(userData);
        return sanitized.length > 8 
            ? sanitized.substring(0, 4) + '...' + sanitized.substring(sanitized.length - 4)
            : sanitized;
    },

    validateUrl(url) {
        try {
            const parsed = new URL(url);
            return parsed.origin === window.location.origin;
        } catch {
            return false;
        }
    },

    sanitizeChartData(data) {
        if (!data) return null;
        if (Array.isArray(data)) {
            return data.map(item => this.sanitizeChartData(item));
        }
        if (typeof data === 'object') {
            const sanitized = {};
            for (const [key, value] of Object.entries(data)) {
                if (typeof value === 'string') {
                    sanitized[key] = this.sanitizeString(value);
                } else {
                    sanitized[key] = this.sanitizeChartData(value);
                }
            }
            return sanitized;
        }
        return data;
    }
};

// Chart.js configuration override to disable ResizeObserver
const disableResizeObserver = () => {
    if (window.Chart) {
        // Completely disable the ResizeObserver by replacing it with a dummy implementation
        window.ResizeObserver = function() {
            return {
                observe: function() {},
                unobserve: function() {},
                disconnect: function() {}
            };
        };
        
        // Also patch Chart.js platform resize method
        if (window.Chart.platform) {
            window.Chart.platform.resize = function(chart) {
                if (chart && typeof chart.update === 'function') {
                    chart.update('none');
                }
            };
        }
        
        // Disable all animations and transitions
        if (window.Chart.defaults) {
            window.Chart.defaults.animation = false;
            window.Chart.defaults.transitions = {
                active: {
                    animation: {
                        duration: 0
                    }
                },
                resize: {
                    animation: {
                        duration: 0
                    }
                },
                show: {
                    animation: {
                        duration: 0
                    }
                },
                hide: {
                    animation: {
                        duration: 0
                    }
                }
            };
            
            // Set responsive options
            window.Chart.defaults.responsive = true;
            window.Chart.defaults.maintainAspectRatio = false;
            
            // Ensure plugins are configured
            if (!window.Chart.defaults.plugins) {
                window.Chart.defaults.plugins = {};
            }
            window.Chart.defaults.plugins.resizeDelay = 0;
            
            // Ensure tooltips work
            window.Chart.defaults.plugins.tooltip = window.Chart.defaults.plugins.tooltip || {};
            window.Chart.defaults.plugins.tooltip.enabled = true;
        }
    }
};

export default class UserCloneAnalytics extends NavigationMixin(LightningElement) {
    // Add this near the top with other class properties
    userColumns = [
        { label: 'User Name', fieldName: 'userName', type: 'text' },
        { label: 'Email', fieldName: 'userEmail', type: 'email' },
        { label: 'Profile', fieldName: 'profileName', type: 'text' },
        { 
            label: 'Assigned Date', 
            fieldName: 'assignedDate', 
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'long',
                day: '2-digit'
            }
        }
    ];
    @track isLicenseSectionOpen = true;
    @track licenseUtilization = { used: 0, total: 0 };
    @track cloningPatternData = [];
    @track permissionDistributionData = [];
    @track cloneHistory = [];
    @track error;

    @track currentPage = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track isFirstPage = true;
    @track isLastPage = false;
    
    // Chart instances
    cloningChart = null;
    permissionChart = null;
    
    // Chart initialization flag
    @track chartjsInitialized = false;
    
    // Active tab tracking
    @track activeTab = 'license';
    
    // Resize timeout reference
    resizeTimeout = null;

    connectedCallback() {
        try {
            this.debug('Component initializing');
            
            // Disable ResizeObserver to prevent errors
            this.disableResizeObserver();
            
            // Initialize Chart.js
            this.initializeChartJS();
            
            // Load data for the active tab
            setTimeout(() => {
                this.switchTab(this.activeTab);
            }, 100);
        } catch (error) {
            this.debug('Error in connectedCallback:', error);
            this.handleError(error);
        }
    }
    
    disconnectedCallback() {
        // Clean up charts and clear sensitive data
        this.destroyCharts();
        
        // Clear timeout if it exists
        if (this.resizeTimeout) {
            clearTimeout(this.resizeTimeout);
            this.resizeTimeout = null;
        }
        
        // Clear sensitive data
        this.permissionDistributionData = [];
        this.cloneHistory = [];
    }
    
    // Safely destroy all chart instances
    destroyCharts() {
        try {
            // First nullify references to prevent memory leaks
            if (this.cloningChart) {
                this.cloningChart.destroy();
                this.cloningChart = null;
            }
            if (this.permissionChart) {
                this.permissionChart.destroy();
                this.permissionChart = null;
            }
        } catch (error) {
            this.handleError(error, 'Error destroying charts');
        }
    }

    loadPermissionData() {
        this.debug('Loading permission data');
        
        // Ensure Chart.js is initialized
                    if (!this.chartjsInitialized) {
            this.initializeChartJS();
            return; // The connectedCallback will handle initialization after Chart.js loads
        }
        
        // Get permission distribution if not already loaded
        if (!this.permissionDistributionData) {
            getPermissionDistribution()
                .then(result => {
                    this.permissionDistributionData = result;
                    this.initializePermissionChart();
            })
            .catch(error => {
                    this.handleError(error, 'Error loading permission distribution');
            });
        } else {
            // If data already loaded, just initialize chart
            this.initializePermissionChart();
        }
    }
    
    handlePreviousPage() {
        if (this.currentPage > 0) {
            this.currentPage--;
            this.loadPermissionData();
        }
    }

    handleNextPage() {
        if (!this.isLastPage) {
            this.currentPage++;
            this.loadPermissionData();
        }
    }

    handleLicenseTab() {
        this.switchTab('license');
    }

    handleCloningTab() {
        this.switchTab('cloning');
    }

    handlePermissionTab() {
        this.switchTab('permission');
    }

    // Chart configurations
    get cloningChartConfig() {
        return {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Clones per Day',
                    data: [],
                    backgroundColor: 'rgba(54, 162, 235, 0.8)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    borderRadius: 8,
                    barThickness: 25
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            stepSize: 1
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    tooltip: {
                        enabled: true,
                        callbacks: {
                            label: (context) => {
                                const dataPoint = context.raw;
                                const labels = [`Total Clones: ${dataPoint.count}`];
                                if (dataPoint.details) {
                                    dataPoint.details.forEach(clone => {
                                        const maskedSource = SecurityUtils.maskUserData(clone.sourceUser);
                                        const maskedTarget = SecurityUtils.maskUserData(clone.newUser);
                                        labels.push(`${maskedSource} → ${maskedTarget} (${clone.time})`);
                                    });
                                }
                                return labels;
                            }
                        }
                    }
                }
            }
        };
    }
    
    // Helper method to determine if a permission is a group
    isPermissionSetGroup(permission) {
        // If isGroup is explicitly set, use that
        if (permission.isGroup !== undefined) {
            return permission.isGroup === true;
        }
        
        // Otherwise try to infer from the name or other properties
        const nameIndicatesGroup = permission.name && 
            (permission.name.includes('Group') || 
             permission.name.includes('Bundle') ||
             permission.name.toLowerCase().includes('psg'));
        
        // Check if the ID matches known Permission Set Group ID patterns
        const idMightBeGroup = permission.permissionSetId && 
            permission.permissionSetId.startsWith('0PG');
        
        return nameIndicatesGroup || idMightBeGroup;
    }
    
    get permissionChartConfig() {
        return {
        type: 'doughnut',
        data: {
            labels: [],
            datasets: [{
                data: [],
                backgroundColor: [
                    '#1589ee',
                    '#ff9a3c',
                    '#4bca81',
                        '#c23934',
                        '#6b6d70',
                        '#0070d2',
                        '#e6686e',
                        '#9d53f2'
                ],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            onClick: (event, elements) => {
                if (elements && elements.length > 0) {
                    const index = elements[0].index;
                        if (this.permissionDistributionData && 
                            this.permissionDistributionData[index] && 
                            this.permissionDistributionData[index].permissionSetId) {
                            this.handlePermissionSetClick(this.permissionDistributionData[index].permissionSetId);
                    }
                }
            },
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        padding: 10,
                        font: {
                            size: 10
                        }
                    }
                },
                title: {
                    display: true,
                        text: 'Permission Assignments',
                    font: {
                        size: 16,
                        weight: 'bold'
                    },
                    padding: 20
                },
                    subtitle: {
                    display: true,
                        text: 'Click on a segment to view details (opens in new tab)',
                    font: {
                        size: 12,
                        style: 'italic'
                    },
                    padding: {
                        top: 0,
                        bottom: 10
                    }
                },
                tooltip: {
                        enabled: true,
                    callbacks: {
                            label: (context) => {
                                const index = context.dataIndex;
                                if (this.permissionDistributionData && 
                                    this.permissionDistributionData[index]) {
                                    const item = this.permissionDistributionData[index];
                                    const label = item.name || context.label || '';
                                    const count = item.count || 0;
                                    const isGroup = this.isPermissionSetGroup(item);
                                    const type = isGroup ? 'Permission Set Group' : 'Permission Set';
                                    return [`${label}`, `Type: ${type}`, `Assigned to ${count} user(s)`];
                                }
                                return context.label || '';
                        }
                    }
                }
            },
            cutout: '65%'
        }
    };
    }
    
    get licenseToggleIcon() {
        return this.isLicenseSectionOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    toggleLicenseSection() {
        this.isLicenseSectionOpen = !this.isLicenseSectionOpen;
    }
    
    // Wire adapter for clone history
     @wire(getCloneHistory)
     wireCloneHistory({ error, data }) {
         if (data) {
             try {
                 console.log('Clone History Raw Data:', data);
                 this.cloneHistory = data;
                
                // Only update chart if we're on the cloning tab and chart is initialized
                if (this.chartjsInitialized && this.activeTab === 'cloning' && this.cloningChart) {
                    this.updateCloningChartData();
                 }
             } catch (err) {
                 console.error('Error processing clone history:', err);
                 this.error = err;
             }
         } else if (error) {
             console.error('Error fetching clone history:', error);
             this.error = error;
         }
     }
    
    // Format cloning data for chart
        formatCloningData(data) {
            if (!Array.isArray(data)) return [];
            return data.map(item => {
                // Parse the Salesforce datetime string
                const date = item.SA_Audit__UserClonedDate__c ? new Date(item.SA_Audit__UserClonedDate__c.replace('T', ' ')) : new Date();
                return {
                    label: date.toLocaleDateString(),
                    value: {
                        count: 1,
                        sourceUser: item.SA_Audit__Source_User__c || 'Unknown',
                        newUser: item.Name,
                        date: date // Store the parsed date for sorting
                    }
                };
            }).sort((a, b) => a.value.date - b.value.date); // Sort by date
        }

    // Update cloning chart data
    updateCloningChartData() {
        if (!this.chartjsInitialized || !this.cloningChart || !this.cloneHistory) {
            console.log('Cannot update cloning chart: missing prerequisites');
            return;
        }
            
            try {
                const chartData = [];
                const labels = [];
                
                // Group clones by date
                this.cloneHistory.forEach(clone => {
                    const date = new Date(clone.SA_Audit__UserClonedDate__c);
                    const dateStr = date.toLocaleDateString();
                    
                    const existingDataPoint = chartData.find(d => d.x === dateStr);
                    if (existingDataPoint) {
                        existingDataPoint.y++;
                        existingDataPoint.count++;
                        existingDataPoint.details.push({
                            sourceUser: clone.SA_Audit__Source_User__c || 'Unknown',
                            newUser: clone.Name || 'Unknown',
                            time: date.toLocaleTimeString()
                        });
                    } else {
                        labels.push(dateStr);
                        chartData.push({
                            x: dateStr,
                            y: 1,
                            count: 1,
                            details: [{
                                sourceUser: clone.SA_Audit__Source_User__c || 'Unknown',
                                newUser: clone.Name || 'Unknown',
                                time: date.toLocaleTimeString()
                            }]
                        });
                    }
                });
    
                // Update chart
                this.cloningChart.data.labels = labels;
                this.cloningChart.data.datasets[0].data = chartData;
            
            // Make sure tooltips are enabled
            if (!this.cloningChart.options.plugins) {
                this.cloningChart.options.plugins = {};
            }
            if (!this.cloningChart.options.plugins.tooltip) {
                this.cloningChart.options.plugins.tooltip = {};
            }
            this.cloningChart.options.plugins.tooltip.enabled = true;
            
                this.cloningChart.update();
                
            console.log('Chart Data:', chartData);
            } catch (error) {
            console.error('Error updating cloning chart:', error);
            // Don't try to reinitialize immediately to avoid potential loops
                this.handleError(error);
            }
        }
    
    // Update permission chart with data
        updatePermissionChart(data) {
        if (!this.validateChartData(data, ['name', 'count'])) {
            this.handleError(new Error('Invalid permission data format'));
                return;
            }
    
            if (!this.permissionChart) {
            this.handleError(new Error('Permission chart not initialized'));
                return;
            }
    
            try {
            // Log permission data for debugging
            this.debug('Permission data for chart:', data.map(item => ({
                name: item.name,
                count: item.count,
                isGroup: item.isGroup,
                id: item.permissionSetId
            })));
            
                const labels = data.map(item => item.name);
                const counts = data.map(item => item.count);
    
                this.permissionChart.data.labels = labels;
                this.permissionChart.data.datasets[0].data = counts;
            this.permissionChart.update();
    
                this.debug('Permission chart updated with data:', labels, counts);
            } catch (error) {
            this.handleError(error, 'Error updating permission chart');
            }
        }
        
    // Wire adapter for permission distribution
    @wire(getPermissionDistribution)
    wirePermissionDistribution({ error, data }) {
        if (data) {
            try {
                // Sanitize data before processing
                const sanitizedData = SecurityUtils.sanitizeChartData(data);
                this.permissionDistributionData = sanitizedData;
                
                if (this.chartjsInitialized && this.activeTab === 'permission' && this.permissionChart) {
                    this.updatePermissionChart(sanitizedData);
                }
            } catch (err) {
                this.handleError(err, 'Failed to process permission data');
            }
        } else if (error) {
            this.handleError(error, 'Failed to fetch permission data');
        }
    }
    
    // Wire adapter for cloning patterns
    @wire(getCloningPatterns)
    wireCloningPatterns({ error, data }) {
        if (data) {
            try {
                this.cloningPatternData = data.map(pattern => ({
                    label: pattern.label,
                    value: pattern.value
                }));
            } catch (err) {
                this.debug('Error Processing Cloning Data:', err.message);
                this.error = err;
            }
        }
    }
    
    // Rendered callback with improved Chart.js loading
    renderedCallback() {
        this.debug('Rendered Callback - Initialized:', this.chartjsInitialized);
        if (this.chartjsInitialized) {
            return;
        }

        this.debug('Loading Chart.js...');
        Promise.resolve(loadScript(this, CHARTJS))
            .then(() => {
                this.debug('Chart.js loaded successfully');
                
                // Apply ResizeObserver patch before initializing charts
                disableResizeObserver();
                
                this.chartjsInitialized = true;
                
                // Wait for DOM to be fully ready before initializing charts
                setTimeout(() => {
                    try {
                        this.initializeChartForActiveTab();
                    } catch (error) {
                        this.debug('Error initializing chart in renderedCallback:', error);
                        // Try one more time with a longer delay
                        setTimeout(() => {
                            try {
                                this.initializeChartForActiveTab();
                            } catch (retryError) {
                                this.debug('Error in chart initialization retry:', retryError);
                            }
                        }, 500);
                    }
                }, 300);
            })
            .catch(error => {
                this.debug('Chart.js loading error:', error);
                this.handleError(error, 'Failed to load Chart.js library');
            });
    }
    
    // Tab class getters
    get licenseTabClass() {
        return `custom-tab ${this.activeTab === 'license' ? 'active' : ''}`;
    }

    get cloningTabClass() {
        return `custom-tab ${this.activeTab === 'cloning' ? 'active' : ''}`;
    }

    get permissionTabClass() {
        return `custom-tab ${this.activeTab === 'permission' ? 'active' : ''}`;
    }

    get licenseContentClass() {
        return `slds-show ${this.activeTab !== 'license' ? 'slds-hide' : ''}`;
    }

    get cloningContentClass() {
        return `slds-show ${this.activeTab !== 'cloning' ? 'slds-hide' : ''}`;
    }

    get permissionContentClass() {
        return `slds-show ${this.activeTab !== 'permission' ? 'slds-hide' : ''}`;
    }

    // Switch tab handler
    switchTab(tabName) {
        this.debug(`Switching to tab: ${tabName}`);
        
        // Destroy existing charts to prevent canvas reuse issues
        this.destroyCharts();
        
        // Reset active tab
        this.activeTab = tabName;
        
        // Handle tab-specific initialization with a delay to ensure DOM is updated
        setTimeout(() => {
            try {
                if (tabName === 'license') {
                    this.loadLicenseData();
                } else if (tabName === 'cloning') {
                    this.loadCloningData();
                } else if (tabName === 'permission') {
                    this.loadPermissionData();
                }
                this.debug(`Tab ${tabName} initialized successfully`);
            } catch (error) {
                this.debug(`Error initializing tab ${tabName}: ${error.message}`);
                this.handleError(error);
            }
        }, 250); // Increased timeout to ensure DOM is fully updated
    }

    // Initialize chart based on active tab with improved error handling
    initializeChartForActiveTab() {
        try {
            if (this.activeTab === 'cloning') {
                this.initializeCloningChart();
            } else if (this.activeTab === 'permission') {
                this.initializePermissionChart();
            }
        } catch (error) {
            this.debug('Error in initializeChartForActiveTab:', error);
            this.handleError(error, `Error initializing ${this.activeTab} chart`);
        }
    }

    // Initialize cloning chart with improved error handling
    initializeCloningChart() {
        try {
            // Ensure Chart.js is loaded
            if (!window.Chart) {
                throw new Error('Chart.js not loaded properly');
            }
            
            // Get canvas element
                        const cloningCanvas = this.template.querySelector('.cloning-chart');
            if (!cloningCanvas) {
                throw new Error('Cloning canvas not found');
            }
                            
            // Double check that any existing chart is destroyed
                            if (this.cloningChart) {
                                this.cloningChart.destroy();
                this.cloningChart = null;
            }
            
            // Force a specific size to avoid layout issues
            cloningCanvas.style.height = '300px';
            cloningCanvas.style.width = '100%';
            
            // Create a new configuration object each time
            const config = JSON.parse(JSON.stringify(this.cloningChartConfig));
            
            // Add responsive configuration to disable ResizeObserver
            config.options = config.options || {};
            config.options.responsive = true;
            config.options.maintainAspectRatio = false;
            config.options.plugins = config.options.plugins || {};
            config.options.plugins.resizeDelay = 0;
            
            // Ensure tooltips are enabled
            config.options.plugins.tooltip = config.options.plugins.tooltip || {};
            config.options.plugins.tooltip.enabled = true;
            
            // Disable animations to prevent SVG rendering issues
            config.options.animation = false;
            
            // Disable responsive animations
            config.options.transitions = {
                resize: {
                    animation: {
                        duration: 0
                    }
                }
            };
            
            // Create the chart with a delay to ensure canvas is ready
            setTimeout(() => {
                try {
                    // Get context again to ensure it's fresh
                    const cloningCtx = cloningCanvas.getContext('2d');
                    
                    // Create chart with non-responsive option first, then enable it later
                    config.options.responsive = false;
                    this.cloningChart = new window.Chart(cloningCtx, config);
                    
                    // Add dummy data immediately to ensure chart renders
                    this.addDummyDataToChart(this.cloningChart, 'bar');
                    
                    // Update with real data if available
                    if (this.cloneHistory && this.cloneHistory.length > 0) {
                        this.updateCloningChartData();
                    }
                    
                    // Enable responsive after initialization
                    this.cloningChart.options.responsive = true;
                    this.cloningChart.update('none');
                    
                    this.debug('Cloning chart initialized successfully');
                } catch (chartError) {
                    this.debug('Error creating chart instance:', chartError);
                    // Try one more time with simpler config
                    try {
                        const simpleConfig = {
                            type: 'bar',
                            data: {
                                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                                datasets: [{
                                    label: 'Clones per Day',
                                    data: [5, 3, 7, 2, 6],
                                    backgroundColor: 'rgba(54, 162, 235, 0.8)'
                                }]
                            },
                            options: {
                                responsive: false,
                                animation: false,
                                plugins: {
                                    tooltip: {
                                        enabled: true
                                    }
                                }
                            }
                        };
                        
                        const cloningCtx = cloningCanvas.getContext('2d');
                        this.cloningChart = new window.Chart(cloningCtx, simpleConfig);
                        this.debug('Created cloning chart with fallback config');
                    } catch (fallbackError) {
                        this.debug('Fallback chart creation also failed:', fallbackError);
                    }
                }
            }, 100);
        } catch (error) {
            this.debug('Error initializing cloning chart:', error);
            // Reset chart reference
            this.cloningChart = null;
        }
    }
    
    // Initialize permission chart with improved error handling
    initializePermissionChart() {
        try {
            // Ensure Chart.js is loaded
            if (!window.Chart) {
                throw new Error('Chart.js not loaded properly');
            }
            
            // Get canvas element
            const permissionCanvas = this.template.querySelector('.permission-chart');
            if (!permissionCanvas) {
                throw new Error('Permission canvas not found');
            }
            
            // Double check that any existing chart is destroyed
            if (this.permissionChart) {
                this.permissionChart.destroy();
                this.permissionChart = null;
            }
            
            // Force a specific size to avoid layout issues
            permissionCanvas.style.height = '300px';
            permissionCanvas.style.width = '100%';
            
            // Create a new configuration object each time
            const config = JSON.parse(JSON.stringify(this.permissionChartConfig));
            
            // Add responsive configuration to disable ResizeObserver
            config.options = config.options || {};
            config.options.responsive = true;
            config.options.maintainAspectRatio = false;
            config.options.plugins = config.options.plugins || {};
            config.options.plugins.resizeDelay = 0;
            
            // Ensure tooltips are enabled
            config.options.plugins.tooltip = config.options.plugins.tooltip || {};
            config.options.plugins.tooltip.enabled = true;
            
            // Ensure click events are preserved
            const originalOnClick = config.options.onClick;
            
            // Disable animations to prevent SVG rendering issues
            config.options.animation = false;
            
            // Disable responsive animations
            config.options.transitions = {
                resize: {
                    animation: {
                        duration: 0
                    }
                }
            };
            
            // Create the chart with a delay to ensure canvas is ready
            setTimeout(() => {
                try {
                    // Get context again to ensure it's fresh
                    const permissionCtx = permissionCanvas.getContext('2d');
                    
                    // Create chart with non-responsive option first, then enable it later
                    config.options.responsive = false;
                    
                    // Preserve the click handler
                    config.options.onClick = (event, elements) => {
                        if (elements && elements.length > 0) {
                            const index = elements[0].index;
                            if (this.permissionDistributionData && 
                                this.permissionDistributionData[index] && 
                                this.permissionDistributionData[index].permissionSetId) {
                                this.handlePermissionSetClick(this.permissionDistributionData[index].permissionSetId);
                            }
                        }
                    };
                    
                    this.permissionChart = new window.Chart(permissionCtx, config);
                    
                    // Add dummy data immediately to ensure chart renders
                    this.addDummyDataToChart(this.permissionChart, 'doughnut');
                    
                    // Update with real data if available
                    if (this.permissionDistributionData && this.permissionDistributionData.length > 0) {
                        this.updatePermissionChart(this.permissionDistributionData);
                    }
                    
                    // Enable responsive after initialization
                    this.permissionChart.options.responsive = true;
                    this.permissionChart.update('none');
                    
                    this.debug('Permission chart initialized successfully');
                } catch (chartError) {
                    this.debug('Error creating chart instance:', chartError);
                    // Try one more time with simpler config
                    try {
                        const simpleConfig = {
                            type: 'doughnut',
                            data: {
                                labels: ['Admin', 'Standard', 'Custom', 'Other'],
                                datasets: [{
                                    data: [25, 40, 20, 15],
                                    backgroundColor: [
                                        '#1589ee',
                                        '#ff9a3c',
                                        '#4bca81',
                                        '#c23934'
                                    ]
                                }]
                            },
                            options: {
                                responsive: false,
                                animation: false,
                                plugins: {
                                    tooltip: {
                                        enabled: true
                                    }
                                },
                                onClick: (event, elements) => {
                                    if (elements && elements.length > 0) {
                                        const index = elements[0].index;
                                        if (this.permissionDistributionData && 
                                            this.permissionDistributionData[index] && 
                                            this.permissionDistributionData[index].permissionSetId) {
                                            this.handlePermissionSetClick(this.permissionDistributionData[index].permissionSetId);
                                        }
                                    }
                                }
                            }
                        };
                        
                        const permissionCtx = permissionCanvas.getContext('2d');
                        this.permissionChart = new window.Chart(permissionCtx, simpleConfig);
                        this.debug('Created permission chart with fallback config');
                    } catch (fallbackError) {
                        this.debug('Fallback chart creation also failed:', fallbackError);
                    }
                }
            }, 100);
        } catch (error) {
            this.debug('Error initializing permission chart:', error);
            // Reset chart reference
            this.permissionChart = null;
        }
    }

    // Add dummy data to chart to ensure it renders
    addDummyDataToChart(chart, type) {
        if (!chart || !chart.data) return;
        
        try {
            if (type === 'bar') {
                // Add dummy data for bar chart
                if (!chart.data.labels || chart.data.labels.length === 0) {
                    chart.data.labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                }
                
                if (!chart.data.datasets || chart.data.datasets.length === 0) {
                    chart.data.datasets = [{
                        label: 'Clones per Day',
                        data: [5, 3, 7, 2, 6],
                        backgroundColor: 'rgba(54, 162, 235, 0.8)'
                    }];
                } else if (chart.data.datasets[0].data.length === 0) {
                    chart.data.datasets[0].data = [5, 3, 7, 2, 6];
                }
            } else if (type === 'doughnut') {
                // Add dummy data for doughnut chart
                if (!chart.data.labels || chart.data.labels.length === 0) {
                    chart.data.labels = ['Admin', 'Standard', 'Custom', 'Other'];
                }
                
                if (!chart.data.datasets || chart.data.datasets.length === 0) {
                    chart.data.datasets = [{
                        data: [25, 40, 20, 15],
                        backgroundColor: [
                            '#1589ee',
                            '#ff9a3c',
                            '#4bca81',
                            '#c23934'
                        ]
                    }];
                } else if (chart.data.datasets[0].data.length === 0) {
                    chart.data.datasets[0].data = [25, 40, 20, 15];
                }
            }
            
            // Update the chart with the dummy data
            chart.update('none');
            this.debug(`Added dummy data to ${type} chart`);
        } catch (error) {
            this.debug(`Error adding dummy data to chart: ${error.message}`);
        }
    }

    // Handle resize event with improved error handling
    handleResize() {
        if (this.resizeTimeout) {
            clearTimeout(this.resizeTimeout);
        }
        
        this.resizeTimeout = setTimeout(() => {
            try {
                if (this.cloningChart && this.activeTab === 'cloning') {
                    // Use update instead of resize to avoid ResizeObserver issues
                    this.cloningChart.update();
                }
                if (this.permissionChart && this.activeTab === 'permission') {
                    // Use update instead of resize to avoid ResizeObserver issues
                    this.permissionChart.update();
                }
            } catch (error) {
                this.debug('Error resizing charts:', error);
                // Don't show error to user for resize issues
            }
        }, 250);
    }
    
    // Validate chart data
    validateChartData(data, requiredFields = []) {
        if (!data) return false;
        
        if (Array.isArray(data)) {
            if (data.length === 0) return false;
            
            // Check if required fields exist in the first item
            if (requiredFields.length > 0) {
                const firstItem = data[0];
                return requiredFields.every(field => firstItem.hasOwnProperty(field));
            }
            
            return true;
        }
        
        return false;
    }
    
    // Get license variant based on usage
    getLicenseVariant(used, total) {
        const percentage = (used / total) * 100;
        if (percentage >= 90) return 'error';
        if (percentage >= 70) return 'warning';
        return 'success';
    }
    
    // Debug utility
    debugMode = true;
    
    debug(...args) {
        if (this.debugMode) {
            console.log('[UserCloneAnalytics]', ...args);
        }
    }
    
    // Handle errors
    handleError(error, customMessage) {
        const errorMessage = customMessage || 'An error occurred';
        const details = error?.message || error?.body?.message || JSON.stringify(error);
        
        this.debug(`${errorMessage}: ${details}`);
        
        // Show toast notification
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: `${errorMessage}: ${details}`,
                variant: 'error'
            })
        );
    }

    // Handle permission set click
    handlePermissionSetClick(permissionSetId) {
        if (!permissionSetId) return;
        
        try {
            // Find the permission in the data
            const permission = this.permissionDistributionData.find(p => p.permissionSetId === permissionSetId);
            
            if (!permission) {
                this.debug('Permission set not found in data');
                return;
            }
            
            // Use our helper method to determine if this is a group
            const isPermissionSetGroup = this.isPermissionSetGroup(permission);
            
            // Direct URL navigation to avoid nested pages
            if (isPermissionSetGroup) {
                // URL for Permission Set Groups
                const url = `${window.location.origin}/lightning/setup/PermissionSetGroups/page?address=%2F${permissionSetId}`;
                window.open(url, '_blank');
                this.debug(`Opened Permission Set Group in new tab: ${url}`);
            } else {
                // URL for regular Permission Sets
                const url = `${window.location.origin}/lightning/setup/PermSets/page?address=%2F${permissionSetId}`;
                window.open(url, '_blank');
                this.debug(`Opened Permission Set in new tab: ${url}`);
            }
        } catch (error) {
            this.debug('Error navigating to permission set: ' + error.message);
            this.handleError(error, 'Error opening permission set details');
        }
    }

    // Load cloning data
    loadCloningData() {
        this.debug('Loading cloning data');
        
        // Ensure Chart.js is initialized
        if (!this.chartjsInitialized) {
            this.initializeChartJS();
            return; // The connectedCallback will handle initialization after Chart.js loads
        }
        
        // Get clone history if not already loaded
        if (!this.cloneHistory) {
            getCloneHistory()
                .then(result => {
                    this.cloneHistory = result;
                    this.totalClonesThisMonth = result.length;
                    this.initializeCloningChart();
                })
                .catch(error => {
                    this.handleError(error, 'Error loading clone history');
                });
        } else {
            // If data already loaded, just initialize chart
            this.initializeCloningChart();
        }
    }

    // Load license data
    loadLicenseData() {
        this.debug('Loading license data');
        
        // Get license utilization if not already loaded
        if (!this.licenseData) {
            getLicenseUtilization()
                .then(data => {
                    try {
                        // Process the array of licenses with active licenses only
                        this.licenseData = data
                            .filter(license => license.totalLicenses > 0)
                            .map(license => {
                                const percentage = Math.round((license.usedLicenses / license.totalLicenses) * 100);
                                const availableLicenses = license.totalLicenses - license.usedLicenses;
                                const isAtLimit = availableLicenses <= 0;
                                
                                return {
                                    licenseName: license.licenseName,
                                    totalLicenses: license.totalLicenses,
                                    usedLicenses: license.usedLicenses,
                                    availableLicenses,
                                    isAtLimit,
                                    users: license.users || [],
                                    percentage,
                                    variant: this.getLicenseVariant(license.usedLicenses, license.totalLicenses),
                                    warningMessage: isAtLimit ? 'No licenses available' : `${availableLicenses} license(s) available`
                                };
                            });
                        
                        // Check if any Salesforce license is available
                        const salesforceLicense = this.licenseData.find(lic => lic.licenseName === 'Salesforce');
                        if (salesforceLicense && salesforceLicense.isAtLimit) {
                            this.error = {
                                title: 'License Limit Reached',
                                message: 'Your organization has reached its Salesforce user license limit. Please contact your administrator to purchase additional licenses.',
                                variant: 'error'
                            };
                        }
                    } catch (err) {
                        this.debug('Error Processing License Data:', err.message);
                        this.handleError(err);
                    }
                })
                .catch(error => {
                    this.handleError(error, 'Error loading license data');
                });
        }
    }

    // Disable ResizeObserver to prevent errors
    disableResizeObserver() {
        // Create a dummy ResizeObserver implementation
        if (typeof window !== 'undefined' && !window._resizeObserverDisabled) {
            window._resizeObserverDisabled = true;
            window.ResizeObserver = function() {
                return {
                    observe: function() {},
                    unobserve: function() {},
                    disconnect: function() {}
                };
            };
            this.debug('ResizeObserver disabled');
        }
    }

    // Initialize Chart.js
    initializeChartJS() {
        if (this.chartjsInitialized) {
            this.debug('Chart.js already initialized');
            return Promise.resolve();
        }

        this.debug('Initializing Chart.js');
        
        return loadScript(this, CHARTJS)
            .then(() => {
                this.debug('Chart.js loaded successfully');
                
                // Disable animations globally
                if (window.Chart) {
                    window.Chart.defaults.animation = false;
                    window.Chart.defaults.transitions = {
                        active: { animation: { duration: 0 } },
                        resize: { animation: { duration: 0 } },
                        show: { animation: { duration: 0 } },
                        hide: { animation: { duration: 0 } }
                    };
                    
                    // Set this flag to true
                    this.chartjsInitialized = true;
                    
                    // Initialize charts based on active tab
                    setTimeout(() => {
                        if (this.activeTab === 'cloning') {
                            this.loadCloningData();
                        } else if (this.activeTab === 'permission') {
                            this.loadPermissionData();
                        }
                    }, 100);
                    
                    return Promise.resolve();
                } else {
                    const error = new Error('Chart.js failed to load properly');
                    this.debug(error);
                    return Promise.reject(error);
                }
            })
            .catch(error => {
                this.debug('Error loading Chart.js:', error);
                this.handleError(error, 'Failed to load Chart.js library');
                return Promise.reject(error);
            });
    }
    }