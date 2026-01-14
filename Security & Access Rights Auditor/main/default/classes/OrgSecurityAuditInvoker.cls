/**
 * @description Invocable wrapper to run Org Security Audit and return narrative plus export file ids
 * Exposes Flow-friendly interface and can be called by Agentforce Bot actions.
 *
 * Compliance:
 * - with sharing, invocable variables, enums via strings for Flow
 * - Uses OrgSecurityAuditService under the hood
 */
public with sharing class OrgSecurityAuditInvoker {

    // Input
    public class AuditInput {
        @InvocableVariable(label='Include Inactive Users' description='Include inactive users in analysis' required=false)
        public Boolean includeInactive;

        @InvocableVariable(label='Risk Level Filter' description='Filter result datasets by risk level: All, CRITICAL, HIGH, MEDIUM, LOW' required=false)
        public String riskLevelFilter;
    }

    // Output DTO for Flow/Agent
    public class AuditOutput {
        @InvocableVariable(label='Executive Summary')
        public String executiveSummary;

        @InvocableVariable(label='Risk Assessment')
        public String riskAssessment;

        @InvocableVariable(label='Critical Findings')
        public String criticalFindings;

        @InvocableVariable(label='Profile Analysis')
        public String profileAnalysis;

        @InvocableVariable(label='System Permission Analysis')
        public String systemPermissionAnalysis;

        @InvocableVariable(label='High-Risk Users')
        public String highRiskUsers;

        @InvocableVariable(label='Recommendations')
        public String recommendations;

        @InvocableVariable(label='Compliance Status')
        public String complianceStatus;

        // Metrics
        @InvocableVariable(label='Total Users')
        public Integer totalUsers;
        @InvocableVariable(label='Critical Risk Count')
        public Integer criticalRiskCount;
        @InvocableVariable(label='High Risk Count')
        public Integer highRiskCount;
        @InvocableVariable(label='Medium Risk Count')
        public Integer mediumRiskCount;
        @InvocableVariable(label='Overall Risk Score')
        public Integer overallRiskScore;

        // Export files
        @InvocableVariable(label='Export Files (CSV)')
        public List<FileLink> files;
    }

    public class FileLink {
        @InvocableVariable(label='File Name')
        public String fileName;
        @InvocableVariable(label='ContentVersion Id')
        public Id contentVersionId;
        @InvocableVariable(label='Download Url')
        public String downloadUrl;
    }

    @InvocableMethod(
        label='Run Organization Security Audit'
        description='Runs comprehensive security audit, returns narrative summary and CSV exports (as ContentVersion records)'
        category='Security Analysis'
    )
    public static List<AuditOutput> run(List<AuditInput> inputs) {
        List<AuditOutput> outputs = new List<AuditOutput>();
        for (AuditInput inputParam : inputs) {
            Boolean includeInactive = (inputParam != null && inputParam.includeInactive != null) ? inputParam.includeInactive : false;
            String riskFilter = (inputParam != null && String.isNotBlank(inputParam.riskLevelFilter)) ? inputParam.riskLevelFilter : 'All';

            OrgSecurityAuditService.AuditArtifacts art = OrgSecurityAuditService.runAudit(includeInactive, riskFilter);

            // Build narrative using existing OrgSecurityAuditor helpers if available
            // Fallback: construct minimal summaries if those helpers are not used directly here.
            AuditOutput out = new AuditOutput();
            out.totalUsers = art.totalUsers;
            out.criticalRiskCount = art.criticalCount;
            out.highRiskCount = art.highCount;
            out.mediumRiskCount = art.mediumCount;
            out.overallRiskScore = art.overallRiskScore;

            // Prefer narratives if supplied by caller/service; otherwise, provide concise summaries
            out.executiveSummary = (art.executiveSummary != null) ? art.executiveSummary :
                ('Organization Security Audit - Users: ' + art.totalUsers + ', Score: ' + art.overallRiskScore);

            out.riskAssessment = (art.riskAssessment != null) ? art.riskAssessment :
                ('Critical=' + art.criticalCount + ', High=' + art.highCount + ', Medium=' + art.mediumCount);

            out.criticalFindings = (art.criticalFindings != null) ? art.criticalFindings : 'See CSV exports for details.';
            out.profileAnalysis = (art.profileAnalysis != null) ? art.profileAnalysis : 'See ProfilesObjectPerms.csv';
            out.systemPermissionAnalysis = (art.systemPermissionAnalysis != null) ? art.systemPermissionAnalysis : 'See SystemPermissions.csv';
            out.highRiskUsers = (art.highRiskUsers != null) ? art.highRiskUsers : 'See HighRiskUsers.csv';
            out.recommendations = (art.recommendations != null) ? art.recommendations : defaultRecommendations(art);
            out.complianceStatus = (art.complianceStatus != null) ? art.complianceStatus : defaultCompliance(art);

            // Build file links
            out.files = new List<FileLink>();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            List<String> downloadInstructions = new List<String>();
            downloadInstructions.add('\n📊 **DOWNLOAD YOUR AUDIT FILES:**\n');
            
            for (String fname : art.exportsByFile.keySet()) {
                OrgSecurityAuditService.ExportDescriptor d = art.exportsByFile.get(fname);
                FileLink fl = new FileLink();
                fl.fileName = d.fileName;
                fl.contentVersionId = d.contentVersionId;
                fl.downloadUrl = baseUrl + '/sfc/servlet.shepherd/version/download/' + String.valueOf(d.contentVersionId);
                out.files.add(fl);
                
                // Add to download instructions
                downloadInstructions.add('• ' + d.fileName + ': ' + fl.downloadUrl);
            }
            
            // Add download instructions to recommendations
            out.recommendations = (art.recommendations != null ? art.recommendations : defaultRecommendations(art)) + 
                                 '\n\n' + String.join(downloadInstructions, '\n') + 
                                 '\n\n**Alternative:** Go to Files tab in Salesforce and search for today\'s date to find all CSV files.';

            outputs.add(out);
        }
        return outputs;
    }

    // Minimal fallbacks

    private static String defaultRecommendations(OrgSecurityAuditService.AuditArtifacts art) {
        List<String> recs = new List<String>();
        if (art.criticalCount > 0) recs.add('Reduce critical permissions (Modify All Data, Manage Users) to the minimum necessary.');
        if (art.highCount > 0) recs.add('Review View All Data, API Enabled, and Author Apex assignments.');
        recs.add('Deactivate stale accounts and enforce MFA for all users.');
        recs.add('Adopt quarterly access reviews and use Permission Sets over profiles.');
        return String.join(recs, '\n');
    }

    private static String defaultCompliance(OrgSecurityAuditService.AuditArtifacts art) {
        Integer checks = 3;
        Integer pass = 0;
        if (art.criticalCount <= 2) pass++;
        if (art.highCount <= 5) pass++;
        if (art.mediumCount <= 10) pass++;
        Integer pct = (pass * 100) / checks;
        return 'Estimated Compliance Score: ' + pct + '% (see Summary.csv for metrics)';
    }
}