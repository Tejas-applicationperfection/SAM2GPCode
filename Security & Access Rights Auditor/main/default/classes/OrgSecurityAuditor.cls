/**
 * @description Comprehensive Organization Security Auditor for Agentforce
 * Analyzes overall security posture by auditing profiles, system permissions, and high-risk patterns
 * Returns risk assessment and audit summaries (read-only analysis)
 * 
 * @author Application Perfection
 * @date 2025
 */
public with sharing class OrgSecurityAuditor {
    
    /**
     * Input wrapper for audit requests
     */
    public class AuditRequest {
        @InvocableVariable(label='Include Inactive Users' description='Include inactive users in analysis' required=false)
        public Boolean includeInactive = false;
        
        @InvocableVariable(label='Risk Level Filter' description='Filter by risk level: All, Critical, High, Medium' required=false)
        public String riskLevelFilter = 'All';
    }
    
    /**
     * Output wrapper for audit results
     */
    public class AuditResult {
        @InvocableVariable(label='Executive Summary' description='High-level audit summary')
        public String executiveSummary;
        
        @InvocableVariable(label='Risk Assessment' description='Overall risk score and assessment')
        public String riskAssessment;
        
        @InvocableVariable(label='Critical Findings' description='Most critical security issues')
        public String criticalFindings;
        
        @InvocableVariable(label='Profile Analysis' description='Analysis of profile permissions')
        public String profileAnalysis;
        
        @InvocableVariable(label='System Permission Analysis' description='Analysis of system permissions')
        public String systemPermissionAnalysis;
        
        @InvocableVariable(label='High-Risk Users' description='Users with elevated access')
        public String highRiskUsers;
        
        @InvocableVariable(label='Recommendations' description='Security improvement recommendations')
        public String recommendations;
        
        @InvocableVariable(label='Compliance Status' description='Compliance and best practices status')
        public String complianceStatus;
        
        // Metrics
        @InvocableVariable(label='Total Users Analyzed' description='Number of users analyzed')
        public Integer totalUsers = 0;
        
        @InvocableVariable(label='Critical Risk Count' description='Number of critical risks')
        public Integer criticalRiskCount = 0;
        
        @InvocableVariable(label='High Risk Count' description='Number of high risks')
        public Integer highRiskCount = 0;
        
        @InvocableVariable(label='Overall Risk Score' description='Risk score 0-100')
        public Integer overallRiskScore = 0;
    }
    
    /**
     * Main invocable method for Agentforce
     */
    @InvocableMethod(
        label='Audit Organization Security' 
        description='Performs comprehensive security audit of the organization'
        category='Security Analysis'
    )
    public static List<AuditResult> auditOrganization(List<AuditRequest> requests) {
        List<AuditResult> results = new List<AuditResult>();
        
        for (AuditRequest req : requests) {
            try {
                // Delegate to new service for data collection + exports, then reuse narrative builders below
                OrgSecurityAuditService.AuditArtifacts art = OrgSecurityAuditService.runAudit(
                    (req != null ? req.includeInactive : false),
                    (req != null ? req.riskLevelFilter : 'All')
                );

                // Gather data again in-memory for narrative using existing private methods (no exports here)
                Map<String, Object> auditData = gatherSecurityData(req != null ? req.includeInactive : false);
                AuditResult interim = analyzeSecurityPosture(auditData, req);

                // Overlay metrics from service to keep numbers consistent
                interim.totalUsers = art.totalUsers;
                interim.criticalRiskCount = art.criticalCount;
                interim.highRiskCount = art.highCount;
                interim.overallRiskScore = art.overallRiskScore;

                results.add(interim);
            } catch (Exception e) {
                AuditResult errorResult = new AuditResult();
                errorResult.executiveSummary = 'Error performing audit: ' + e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    /**
     * Perform comprehensive security audit
     */
    private static AuditResult performAudit(AuditRequest req) {
        AuditResult result = new AuditResult();
        
        // Gather all security data
        Map<String, Object> auditData = gatherSecurityData(req.includeInactive);
        
        // Analyze data
        result = analyzeSecurityPosture(auditData, req);
        
        return result;
    }
    
    /**
     * Gather comprehensive security data
     */
    @TestVisible
    private static Map<String, Object> gatherSecurityData(Boolean includeInactive) {
        Map<String, Object> data = new Map<String, Object>();
        
        // Input validation
        if (includeInactive == null) {
            includeInactive = false;
        }
        
        // 1. User Analysis - Use safe SOQL
        List<User> users;
        if (includeInactive) {
            users = [SELECT Id, Name, Username, Profile.Name, IsActive, UserRole.Name,
                     LastLoginDate, CreatedDate, UserType FROM User];
        } else {
            users = [SELECT Id, Name, Username, Profile.Name, IsActive, UserRole.Name,
                     LastLoginDate, CreatedDate, UserType FROM User WHERE IsActive = true];
        }
        data.put('users', users);
        
        // 2. Profile Permissions
        List<Profile> profiles = [
            SELECT Id, Name, PermissionsModifyAllData, PermissionsViewAllData,
                   PermissionsManageUsers, PermissionsCustomizeApplication,
                   PermissionsApiEnabled, PermissionsAuthorApex,
                   PermissionsEditPublicDocuments, PermissionsTransferAnyEntity
            FROM Profile
            WHERE Id IN (SELECT ProfileId FROM User WHERE IsActive = true)
        ];
        data.put('profiles', profiles);
        
        // 3. Permission Set Assignments
        List<PermissionSetAssignment> psetAssignments = [
            SELECT AssigneeId, Assignee.Name, PermissionSet.Name, PermissionSet.IsOwnedByProfile,
                   PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
            FROM PermissionSetAssignment
            WHERE Assignee.IsActive = true
            AND PermissionSet.IsOwnedByProfile = false
        ];
        data.put('permissionSetAssignments', psetAssignments);
        
        // 4. Object Sharing Settings (using FieldPermissions as proxy)
        // Note: SharingRule is not directly queryable, using count as metric
        Integer sharingRuleCount = 0;
        data.put('sharingRuleCount', sharingRuleCount);
        
        return data;
    }
    
    /**
     * Analyze security posture and generate findings
     */
    private static AuditResult analyzeSecurityPosture(Map<String, Object> data, AuditRequest req) {
        AuditResult result = new AuditResult();
        
        List<User> users = (List<User>) data.get('users');
        List<Profile> profiles = (List<Profile>) data.get('profiles');
        List<PermissionSetAssignment> psetAssignments = (List<PermissionSetAssignment>) data.get('permissionSetAssignments');
        
        result.totalUsers = users.size();
        
        // Analyze critical permissions
        Map<String, Integer> riskMetrics = analyzeCriticalPermissions(profiles, psetAssignments, users);
        result.criticalRiskCount = riskMetrics.get('critical');
        result.highRiskCount = riskMetrics.get('high');
        
        // Calculate overall risk score
        result.overallRiskScore = calculateRiskScore(riskMetrics, users.size());
        
        // Build Executive Summary
        result.executiveSummary = buildExecutiveSummary(result, users.size());
        
        // Build Risk Assessment
        result.riskAssessment = buildRiskAssessment(result.overallRiskScore, riskMetrics);
        
        // Build Critical Findings
        result.criticalFindings = buildCriticalFindings(profiles, psetAssignments, users);
        
        // Build Profile Analysis
        result.profileAnalysis = buildProfileAnalysis(profiles);
        
        // Build System Permission Analysis
        result.systemPermissionAnalysis = buildSystemPermissionAnalysis(riskMetrics);
        
        // Build High-Risk Users
        result.highRiskUsers = buildHighRiskUsers(profiles, psetAssignments, users);
        
        // Build Recommendations
        result.recommendations = buildRecommendations(result.overallRiskScore, riskMetrics);
        
        // Build Compliance Status
        result.complianceStatus = buildComplianceStatus(riskMetrics, users.size());
        
        return result;
    }
    
    /**
     * Analyze critical permissions across profiles and permission sets
     */
    private static Map<String, Integer> analyzeCriticalPermissions(
        List<Profile> profiles, 
        List<PermissionSetAssignment> psetAssignments,
        List<User> users
    ) {
        Map<String, Integer> metrics = new Map<String, Integer>{
            'critical' => 0,
            'high' => 0,
            'medium' => 0,
            'modifyAllData' => 0,
            'viewAllData' => 0,
            'manageUsers' => 0,
            'customizeApp' => 0,
            'apiEnabled' => 0,
            'authorApex' => 0,
            'inactiveWithAccess' => 0,
            'noLoginInDays' => 0
        };
        
        // Analyze profiles
        for (Profile p : profiles) {
            if (p.PermissionsModifyAllData) {
                metrics.put('modifyAllData', metrics.get('modifyAllData') + 1);
                metrics.put('critical', metrics.get('critical') + 1);
            }
            if (p.PermissionsViewAllData) {
                metrics.put('viewAllData', metrics.get('viewAllData') + 1);
                metrics.put('high', metrics.get('high') + 1);
            }
            if (p.PermissionsManageUsers) {
                metrics.put('manageUsers', metrics.get('manageUsers') + 1);
                metrics.put('critical', metrics.get('critical') + 1);
            }
            if (p.PermissionsCustomizeApplication) {
                metrics.put('customizeApp', metrics.get('customizeApp') + 1);
                metrics.put('high', metrics.get('high') + 1);
            }
            if (p.PermissionsAuthorApex) {
                metrics.put('authorApex', metrics.get('authorApex') + 1);
                metrics.put('high', metrics.get('high') + 1);
            }
        }
        
        // Analyze permission set assignments
        for (PermissionSetAssignment psa : psetAssignments) {
            if (psa.PermissionSet.PermissionsModifyAllData) {
                metrics.put('critical', metrics.get('critical') + 1);
            }
            if (psa.PermissionSet.PermissionsViewAllData) {
                metrics.put('high', metrics.get('high') + 1);
            }
        }
        
        // Analyze inactive users and stale accounts
        Date ninetyDaysAgo = Date.today().addDays(-90);
        for (User u : users) {
            if (!u.IsActive && u.Profile.Name.contains('System Administrator')) {
                metrics.put('inactiveWithAccess', metrics.get('inactiveWithAccess') + 1);
            }
            if (u.LastLoginDate != null && u.LastLoginDate < ninetyDaysAgo && u.IsActive) {
                metrics.put('noLoginInDays', metrics.get('noLoginInDays') + 1);
            }
        }
        
        return metrics;
    }
    
    /**
     * Calculate overall risk score (0-100)
     */
    private static Integer calculateRiskScore(Map<String, Integer> metrics, Integer totalUsers) {
        Integer score = 0;
        
        // Weighted scoring
        score += metrics.get('critical') * 15; // Critical issues worth 15 points each
        score += metrics.get('high') * 10;     // High issues worth 10 points each
        score += metrics.get('medium') * 5;    // Medium issues worth 5 points each
        
        // Normalize to 0-100
        Integer maxPossibleScore = totalUsers * 15;
        if (maxPossibleScore > 0) {
            score = (score * 100) / maxPossibleScore;
        }
        
        return Math.min(100, score);
    }
    
    /**
     * Build executive summary
     */
    private static String buildExecutiveSummary(AuditResult result, Integer totalUsers) {
        String summary = '🔒 **ORGANIZATION SECURITY AUDIT SUMMARY**\n\n';
        summary += '**Audit Date:** ' + DateTime.now().format('yyyy-MM-dd HH:mm') + '\n';
        summary += '**Total Users Analyzed:** ' + totalUsers + '\n';
        summary += '**Overall Risk Score:** ' + result.overallRiskScore + '/100 ';
        
        if (result.overallRiskScore >= 70) {
            summary += '🔴 **CRITICAL**\n';
        } else if (result.overallRiskScore >= 40) {
            summary += '🟡 **HIGH**\n';
        } else if (result.overallRiskScore >= 20) {
            summary += '🟠 **MEDIUM**\n';
        } else {
            summary += '🟢 **LOW**\n';
        }
        
        summary += '**Critical Issues:** ' + result.criticalRiskCount + '\n';
        summary += '**High-Risk Issues:** ' + result.highRiskCount + '\n\n';
        
        summary += 'This audit analyzed your organization\'s security posture across profiles, ';
        summary += 'system permissions, and access patterns. Review the detailed findings below.';
        
        return summary;
    }
    
    /**
     * Build risk assessment
     */
    private static String buildRiskAssessment(Integer riskScore, Map<String, Integer> metrics) {
        String assessment = '⚠️ **RISK ASSESSMENT**\n\n';
        
        if (riskScore >= 70) {
            assessment += '**Status:** CRITICAL RISK\n\n';
            assessment += 'Your organization has significant security vulnerabilities that require ';
            assessment += 'immediate attention. Multiple users have elevated permissions that could ';
            assessment += 'pose serious data security risks.\n\n';
        } else if (riskScore >= 40) {
            assessment += '**Status:**  HIGH RISK\n\n';
            assessment += 'Your organization has elevated security risks that should be addressed ';
            assessment += 'promptly. Several users have permissions that exceed typical requirements.\n\n';
        } else if (riskScore >= 20) {
            assessment += '**Status:** MEDIUM RISK\n\n';
            assessment += 'Your organization has moderate security concerns. Some permission ';
            assessment += 'assignments could be optimized for better security.\n\n';
        } else {
            assessment += '**Status:** LOW RISK\n\n';
            assessment += 'Your organization follows good security practices. Continue monitoring ';
            assessment += 'and reviewing permissions regularly.\n\n';
        }
        
        assessment += '**Key Metrics:**\n';
        assessment += '• Modify All Data: ' + metrics.get('modifyAllData') + ' profiles/users\n';
        assessment += '• View All Data: ' + metrics.get('viewAllData') + ' profiles/users\n';
        assessment += '• Manage Users: ' + metrics.get('manageUsers') + ' profiles\n';
        assessment += '• Author Apex: ' + metrics.get('authorApex') + ' profiles\n';
        
        return assessment;
    }
    
    /**
     * Build critical findings
     */
    private static String buildCriticalFindings(
        List<Profile> profiles,
        List<PermissionSetAssignment> psetAssignments,
        List<User> users
    ) {
        String findings = '🚨 **CRITICAL FINDINGS**\n\n';
        List<String> issues = new List<String>();
        
        // Check for excessive Modify All Data
        Integer modifyAllCount = 0;
        for (Profile p : profiles) {
            if (p.PermissionsModifyAllData) modifyAllCount++;
        }
        if (modifyAllCount > 2) {
            issues.add('⚠️ **Excessive Modify All Data Permission**: ' + modifyAllCount + 
                      ' profiles have this critical permission. This should be limited to 1-2 system admin profiles.');
        }
        
        // Check for stale accounts
        Date ninetyDaysAgo = Date.today().addDays(-90);
        Integer staleAccounts = 0;
        for (User u : users) {
            if (u.LastLoginDate != null && u.LastLoginDate < ninetyDaysAgo && u.IsActive) {
                staleAccounts++;
            }
        }
        if (staleAccounts > 0) {
            issues.add('⚠️ **Stale User Accounts**: ' + staleAccounts + 
                      ' active users haven\'t logged in for 90+ days. These should be reviewed and deactivated if no longer needed.');
        }
        
        // Check for inactive admin accounts
        Integer inactiveAdmins = 0;
        for (User u : users) {
            if (!u.IsActive && (u.Profile.Name.contains('Admin') || u.Profile.Name.contains('System'))) {
                inactiveAdmins++;
            }
        }
        if (inactiveAdmins > 5) {
            issues.add('⚠️ **Inactive Admin Accounts**: ' + inactiveAdmins + 
                      ' inactive users still have admin profiles. Clean these up for compliance.');
        }
        
        if (issues.isEmpty()) {
            findings += '✅ No critical findings detected. Your org follows security best practices.\n';
        } else {
            for (String issue : issues) {
                findings += issue + '\n\n';
            }
        }
        
        return findings;
    }
    
    /**
     * Build profile analysis
     */
    private static String buildProfileAnalysis(List<Profile> profiles) {
        String analysis = '👥 **PROFILE PERMISSIONS ANALYSIS**\n\n';
        
        analysis += 'Analyzed ' + profiles.size() + ' profiles in use:\n\n';
        
        for (Profile p : profiles) {
            List<String> permissions = new List<String>();
            if (p.PermissionsModifyAllData) permissions.add('Modify All Data');
            if (p.PermissionsViewAllData) permissions.add('View All Data');
            if (p.PermissionsManageUsers) permissions.add('Manage Users');
            if (p.PermissionsCustomizeApplication) permissions.add('Customize Application');
            
            if (!permissions.isEmpty()) {
                analysis += '**' + p.Name + ':**\n';
                for (String perm : permissions) {
                    analysis += '  • ' + perm + '\n';
                }
                analysis += '\n';
            }
        }
        
        return analysis;
    }
    
    /**
     * Build system permission analysis
     */
    private static String buildSystemPermissionAnalysis(Map<String, Integer> metrics) {
        String analysis = '🔐 **SYSTEM PERMISSIONS BREAKDOWN**\n\n';
        
        analysis += '| Permission | Count | Risk Level |\n';
        analysis += '|------------|-------|------------|\n';
        analysis += '| Modify All Data | ' + metrics.get('modifyAllData') + ' | 🔴 Critical |\n';
        analysis += '| View All Data | ' + metrics.get('viewAllData') + ' | 🟡 High |\n';
        analysis += '| Manage Users | ' + metrics.get('manageUsers') + ' | 🔴 Critical |\n';
        analysis += '| Customize App | ' + metrics.get('customizeApp') + ' | 🟠 Medium |\n';
        analysis += '| Author Apex | ' + metrics.get('authorApex') + ' | 🟡 High |\n';
        
        return analysis;
    }
    
    /**
     * Build high-risk users list
     */
    private static String buildHighRiskUsers(
        List<Profile> profiles,
        List<PermissionSetAssignment> psetAssignments,
        List<User> users
    ) {
        String result = '⚡ **HIGH-RISK USER ACCESS**\n\n';
        
        Set<String> highRiskProfileNames = new Set<String>();
        for (Profile p : profiles) {
            if (p.PermissionsModifyAllData || p.PermissionsManageUsers) {
                highRiskProfileNames.add(p.Name);
            }
        }
        
        Integer highRiskUserCount = 0;
        for (User u : users) {
            if (u.IsActive && highRiskProfileNames.contains(u.Profile.Name)) {
                highRiskUserCount++;
            }
        }
        
        result += '**Users with Critical Permissions:** ' + highRiskUserCount + '\n\n';
        result += 'These users have Modify All Data or Manage Users permissions. ';
        result += 'Ensure each has a legitimate business need for this level of access.\n\n';
        
        result += '**Permission Set Assignments:** ' + psetAssignments.size() + '\n';
        result += 'Review these assignments to ensure they follow the principle of least privilege.';
        
        return result;
    }
    
    /**
     * Build recommendations
     */
    private static String buildRecommendations(Integer riskScore, Map<String, Integer> metrics) {
        String recommendations = '💡 **SECURITY RECOMMENDATIONS**\n\n';
        
        List<String> recs = new List<String>();
        
        if (metrics.get('modifyAllData') > 2) {
            recs.add('**Reduce Modify All Data Permission:** Limit to 1-2 system admin profiles only.');
        }
        
        if (metrics.get('viewAllData') > 5) {
            recs.add('**Review View All Data Permission:** Consider using sharing rules instead of blanket access.');
        }
        
        if (metrics.get('noLoginInDays') > 0) {
            recs.add('**Deactivate Stale Accounts:** Review and deactivate users who haven\'t logged in for 90+ days.');
        }
        
        recs.add('**Implement Regular Audits:** Schedule quarterly permission reviews.');
        recs.add('**Use Permission Sets:** Prefer permission sets over modifying standard profiles.');
        recs.add('**Enable Login IP Ranges:** Restrict access by IP address for enhanced security.');
        recs.add('**Enable MFA:** Require multi-factor authentication for all users.');
        
        for (Integer i = 0; i < recs.size(); i++) {
            recommendations += (i + 1) + '. ' + recs[i] + '\n\n';
        }
        
        return recommendations;
    }
    
    /**
     * Build compliance status
     */
    private static String buildComplianceStatus(Map<String, Integer> metrics, Integer totalUsers) {
        String status = '✅ **COMPLIANCE & BEST PRACTICES**\n\n';
        
        Integer compliantCount = 0;
        Integer totalChecks = 5;
        
        status += '**Security Checklist:**\n\n';
        
        if (metrics.get('modifyAllData') <= 2) {
            status += '✅ Modify All Data limited to admin profiles\n';
            compliantCount++;
        } else {
            status += '❌ Modify All Data assigned too broadly\n';
        }
        
        if (metrics.get('viewAllData') <= 5) {
            status += '✅ View All Data appropriately restricted\n';
            compliantCount++;
        } else {
            status += '❌ View All Data needs review\n';
        }
        
        if (metrics.get('noLoginInDays') == 0) {
            status += '✅ No stale user accounts detected\n';
            compliantCount++;
        } else {
            status += '❌ Stale user accounts need cleanup\n';
        }
        
        if (metrics.get('inactiveWithAccess') < 5) {
            status += '✅ Minimal inactive users with elevated access\n';
            compliantCount++;
        } else {
            status += '❌ Too many inactive users with admin access\n';
        }
        
        // General best practice
        status += '⚠️ Enable MFA for all users (verify manually)\n\n';
        
        Integer compliancePercent = (compliantCount * 100) / totalChecks;
        status += '**Compliance Score:** ' + compliancePercent + '%\n';
        
        return status;
    }
}