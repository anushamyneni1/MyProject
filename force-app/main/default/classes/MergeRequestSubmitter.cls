public with sharing class MergeRequestSubmitter {

    @InvocableMethod(
        label='Submit Merge Request'
        description='Sets Merge_Requested__c = true on the flagged record, signalling to admins that an employee has reviewed and approved the merge request.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(submitRequest(req));
        }
        return results;
    }

    private static Result submitRequest(Request req) {
        Result r = new Result();
        try {
            // Detect object type from ID prefix to build the right SObject
            String idPrefix = String.isNotBlank(req.flagId) && req.flagId.length() >= 3
                ? req.flagId.substring(0, 3) : '';

            // Standard Salesforce key prefixes: 001=Account, 003=Contact, 006=Opportunity
            SObject record;
            String objLabel;
            if (idPrefix == '001') {
                record = new Account(Id = req.flagId, Merge_Requested__c = true, Duplicate_Notes__c = req.adminNotes);
                objLabel = 'Account';
            } else if (idPrefix == '003') {
                record = new Contact(Id = req.flagId, Merge_Requested__c = true, Duplicate_Notes__c = req.adminNotes);
                objLabel = 'Contact';
            } else if (idPrefix == '006') {
                record = new Opportunity(Id = req.flagId, Merge_Requested__c = true, Duplicate_Notes__c = req.adminNotes);
                objLabel = 'Opportunity';
            } else {
                r.success = false;
                r.confirmationMessage = 'Could not determine object type from ID: ' + req.flagId;
                return r;
            }
            update record;
            r.requestId = req.flagId;
            r.success = true;
            r.confirmationMessage = 'Merge request submitted for ' + objLabel + ' ' + req.flagId + '. Admin review queue updated.';
        } catch (Exception e) {
            r.success = false;
            r.confirmationMessage = 'Failed to submit merge request: ' + e.getMessage();
        }
        return r;
    }

    public class Request {
        @InvocableVariable(
            label='Flag ID'
            description='Salesforce ID of the flagged record to submit for merge'
            required=true
        )
        public String flagId;

        @InvocableVariable(
            label='Admin Notes'
            description='Optional notes for the admin processing the merge request'
            required=false
        )
        public String adminNotes;
    }

    public class Result {
        @InvocableVariable(
            label='Request ID'
            description='Salesforce ID of the record updated with the merge request'
        )
        public String requestId;

        @InvocableVariable(
            label='Confirmation Message'
            description='Human-readable confirmation that the merge request was submitted'
        )
        public String confirmationMessage;

        @InvocableVariable(
            label='Success'
            description='True if the merge request was submitted successfully'
        )
        public Boolean success;
    }
}
