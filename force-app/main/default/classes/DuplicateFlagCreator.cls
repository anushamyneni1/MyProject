public with sharing class DuplicateFlagCreator {

    @InvocableMethod(
        label='Create Duplicate Flag'
        description='Flags a record as a potential duplicate by writing the paired record ID and notes onto the record itself. Supports Account, Contact, and Opportunity.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(flagRecord(req));
        }
        return results;
    }

    private static Result flagRecord(Request req) {
        Result r = new Result();
        try {
            SObject record;
            if (req.objectType == 'Account') {
                record = new Account(
                    Id = req.recordId1,
                    Potential_Duplicate_Id__c = req.recordId2,
                    Duplicate_Notes__c = req.notes
                );
            } else if (req.objectType == 'Contact') {
                record = new Contact(
                    Id = req.recordId1,
                    Potential_Duplicate_Id__c = req.recordId2,
                    Duplicate_Notes__c = req.notes
                );
            } else if (req.objectType == 'Opportunity') {
                record = new Opportunity(
                    Id = req.recordId1,
                    Potential_Duplicate_Id__c = req.recordId2,
                    Duplicate_Notes__c = req.notes
                );
            } else {
                r.success = false;
                r.confirmationMessage = 'Unsupported object type: ' + req.objectType;
                return r;
            }
            update record;
            r.flagId = req.recordId1;
            r.success = true;
            r.confirmationMessage = req.objectType + ' record flagged as potential duplicate of ' + req.recordId2 + '.';
        } catch (Exception e) {
            r.success = false;
            r.confirmationMessage = 'Failed to flag duplicate: ' + e.getMessage();
        }
        return r;
    }

    public class Request {
        @InvocableVariable(
            label='Record ID 1'
            description='Salesforce ID of the record to flag (the flag is written onto this record)'
            required=true
        )
        public String recordId1;

        @InvocableVariable(
            label='Record ID 2'
            description='Salesforce ID of the suspected duplicate record'
            required=true
        )
        public String recordId2;

        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type: Account, Contact, or Opportunity'
            required=true
        )
        public String objectType;

        @InvocableVariable(
            label='Notes'
            description='Optional notes for the admin reviewer'
            required=false
        )
        public String notes;
    }

    public class Result {
        @InvocableVariable(
            label='Flag ID'
            description='Salesforce ID of the record that was flagged'
        )
        public String flagId;

        @InvocableVariable(
            label='Confirmation Message'
            description='Human-readable confirmation that the duplicate flag was set'
        )
        public String confirmationMessage;

        @InvocableVariable(
            label='Success'
            description='True if the flag was set successfully'
        )
        public Boolean success;
    }
}
