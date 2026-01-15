public with sharing class ProfileReviewAgentAction {

    public class Request {
        @InvocableVariable(required=true)
        public String profileName; // single profile OR 'ALL'
    }

    public class Response {
        @InvocableVariable
        public String findings;

        @InvocableVariable
        public String riskLevel;
    }

    @InvocableMethod(
        label='Profile Review Apex Action'
        description='Audits one or all profiles for security risks'
    )
    public static List<Response> reviewProfiles(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            
            try {
                // Input validation
                if (req == null || String.isBlank(req.profileName)) {
                    res.findings = 'Error: Profile name is required';
                    res.riskLevel = 'Error';
                    responses.add(res);
                    continue;
                }

                List<Profile> profiles;

        if (req.profileName == 'ALL') {
            profiles = [
                SELECT Id, Name,
                       PermissionsModifyAllData,
                       PermissionsCustomizeApplication
                FROM Profile
                WHERE Name != 'Guest User'
            ];
        } else {
            profiles = [
                SELECT Id, Name,
                       PermissionsModifyAllData,
                       PermissionsCustomizeApplication
                FROM Profile
                WHERE Name = :req.profileName
                LIMIT 1
            ];
        }

        // ✅ FIX 1: extract profile IDs
        Set<Id> profileIds = new Set<Id>();
        for (Profile p : profiles) {
            profileIds.add(p.Id);
        }

        Map<Id, List<ObjectPermissions>> permsByProfile =
            new Map<Id, List<ObjectPermissions>>();

        // Fetch object permissions
        for (ObjectPermissions op : [
            SELECT ParentId, SObjectType,
                   PermissionsEdit,
                   PermissionsDelete,
                   PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId IN :profileIds
        ]) {

            // ✅ FIX 2: Apex-safe map logic
            if (!permsByProfile.containsKey(op.ParentId)) {
                permsByProfile.put(op.ParentId, new List<ObjectPermissions>());
            }
            permsByProfile.get(op.ParentId).add(op);
        }

        Integer orgHighRisk = 0;
        Integer orgMediumRisk = 0;
        String report = '';

        for (Profile p : profiles) {

            Integer high = 0;
            Integer medium = 0;
            String section = 'Profile: ' + p.Name + '\n';

            if (p.PermissionsModifyAllData || p.PermissionsCustomizeApplication) {
                high++;
                section += '  • High Risk: Admin-level system permissions\n';
            }

            if (permsByProfile.containsKey(p.Id)) {
                for (ObjectPermissions op : permsByProfile.get(p.Id)) {
                    if (op.PermissionsModifyAllRecords) {
                        high++;
                        section += '  • High Risk: Modify All on ' + op.SObjectType + '\n';
                    }
                    else if (op.PermissionsEdit && op.PermissionsDelete) {
                        medium++;
                        section += '  • Medium Risk: Edit + Delete on ' + op.SObjectType + '\n';
                    }
                }
            }

            if (high == 0 && medium == 0) {
                section += '  • No critical risks detected\n';
            }

            if (high > 0) orgHighRisk++;
            else if (medium > 2) orgMediumRisk++;

            report += section + '\n';
        }

        res.riskLevel =
            orgHighRisk > 0 ? 'High' :
            orgMediumRisk > 0 ? 'Medium' : 'Low';

        res.findings =
            'ORG-WIDE PROFILE SECURITY AUDIT\n\n' +
            report +
            '\nSummary:\n' +
            '• High-risk profiles: ' + orgHighRisk + '\n' +
            '• Medium-risk profiles: ' + orgMediumRisk + '\n';

                responses.add(res);
            } catch (Exception e) {
                res.findings = 'Error analyzing profiles: ' + e.getMessage();
                res.riskLevel = 'Error';
                responses.add(res);
            }
        }

        return responses;
    }
}