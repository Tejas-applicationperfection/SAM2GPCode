({
	init : function(component, event, helper) {
		 helper.getPermissionReviewData(component, event, helper);
        helper.getExistingDates(component, event, helper);
        
        
	},
    redirectToAuditApp :function(component, event, helper) {
                    var urlString = window.location.href;
                    console.log('urlString: ' + urlString);
                    var baseURL = urlString.substring(0, urlString.indexOf("/l"));
                    var newurl = baseURL + '/lightning/n/SA_Audit__PermissionAudit/';
                    console.log('newurl: ' + newurl);
                    window.open(newurl, '_blank');  
                } 
})