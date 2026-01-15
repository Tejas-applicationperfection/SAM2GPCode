public with sharing class ReviewEmailScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        // Get the current user's email address
        User currentUser = [SELECT Email, FirstName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Define the email parameters
        String toAddress = currentUser.Email;
        String subject = 'Reminder: Time to Review Your Organization\'s Permissions';
        String body = 'Dear ' + currentUser.FirstName + ',\n\n' +
                      'This is a friendly reminder that it’s time to review your organization’s permissions.\n\n' +
                      'Regularly reviewing and updating permissions ensures that our systems remain secure and that users have the appropriate level of access. Please take a moment to check the permissions assigned to your profile and make any necessary adjustments.\n\n' +
                      'To review and update permissions, please visit the Audit Tab in your Salesforce org.\n\n' +
                      'If you have any questions or need assistance with this process, please do not hesitate to reach out to the support team.\n\n' +
                      'Thank you for your attention to this important matter.\n\n' +
                      'Best regards,\n'  ;
        
        // Create a new email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{toAddress});
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        
        // Send the email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
}