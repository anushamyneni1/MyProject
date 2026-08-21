public with sharing class DuplicateReviewQueueFetcher {

    @InvocableMethod(
        label='Get Duplicate Review Queue'
        description='Returns records flagged as potential duplicates (Potential_Duplicate_Id__c populated, Merge_Requested__c false), optionally filtered by object type.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(fetchQueue(req));
        }
        return results;
    }

    private static Result fetchQueue(Request req) {
        Result r = new Result();
        r.flaggedPairs = new List<FlaggedPair>();

        String objType = String.isNotBlank(req.objectTypeFilter) ? req.objectTypeFilter : null;

        if (objType == null || objType == 'Account') {
            String q = 'SELECT Id, Name, Potential_Duplicate_Id__c, Duplicate_Notes__c, LastModifiedDate'
                + ' FROM Account WHERE Potential_Duplicate_Id__c != null AND Merge_Requested__c = false'
                + ' ORDER BY LastModifiedDate DESC LIMIT 25';
            for (Account a : Database.query(q, AccessLevel.USER_MODE)) {
                r.flaggedPairs.add(buildPair(a.Id, a.Name, a.Potential_Duplicate_Id__c, a.Duplicate_Notes__c, 'Account', String.valueOf(a.LastModifiedDate)));
            }
        }
        if (objType == null || objType == 'Contact') {
            String q = 'SELECT Id, Name, Potential_Duplicate_Id__c, Duplicate_Notes__c, LastModifiedDate'
                + ' FROM Contact WHERE Potential_Duplicate_Id__c != null AND Merge_Requested__c = false'
                + ' ORDER BY LastModifiedDate DESC LIMIT 25';
            for (Contact c : Database.query(q, AccessLevel.USER_MODE)) {
                r.flaggedPairs.add(buildPair(c.Id, c.Name, c.Potential_Duplicate_Id__c, c.Duplicate_Notes__c, 'Contact', String.valueOf(c.LastModifiedDate)));
            }
        }
        if (objType == null || objType == 'Opportunity') {
            String q = 'SELECT Id, Name, Potential_Duplicate_Id__c, Duplicate_Notes__c, LastModifiedDate'
                + ' FROM Opportunity WHERE Potential_Duplicate_Id__c != null AND Merge_Requested__c = false'
                + ' ORDER BY LastModifiedDate DESC LIMIT 25';
            for (Opportunity o : Database.query(q, AccessLevel.USER_MODE)) {
                r.flaggedPairs.add(buildPair(o.Id, o.Name, o.Potential_Duplicate_Id__c, o.Duplicate_Notes__c, 'Opportunity', String.valueOf(o.LastModifiedDate)));
            }
        }

        r.hasResults = !r.flaggedPairs.isEmpty();
        return r;
    }

    private static FlaggedPair buildPair(Id recordId, String recordName, String duplicateId, String notes, String objType, String modifiedDate) {
        FlaggedPair fp = new FlaggedPair();
        fp.flagId = recordId;
        fp.objectType = objType;
        fp.recordName1 = recordName;
        fp.recordName2 = duplicateId;
        fp.confidenceScore = 'N/A';
        fp.status = 'Pending Review';
        fp.createdDate = modifiedDate;
        return fp;
    }

    public class Request {
        @InvocableVariable(
            label='Object Type Filter'
            description='Filter results by object type: Account, Contact, or Opportunity. Leave blank for all.'
            required=false
        )
        public String objectTypeFilter;
    }

    public class Result {
        @InvocableVariable(
            label='Flagged Pairs'
            description='Records flagged as potential duplicates awaiting admin review'
        )
        public List<FlaggedPair> flaggedPairs;

        @InvocableVariable(
            label='Has Results'
            description='True if any flagged records were found'
        )
        public Boolean hasResults;
    }

    public class FlaggedPair {
        @InvocableVariable(label='Flag ID' description='Salesforce ID of the flagged record')
        public String flagId;

        @InvocableVariable(label='Object Type' description='Salesforce object type of the flagged record')
        public String objectType;

        @InvocableVariable(label='Record Name 1' description='Name of the flagged record')
        public String recordName1;

        @InvocableVariable(label='Record Name 2' description='ID of the suspected duplicate record')
        public String recordName2;

        @InvocableVariable(label='Confidence Score' description='Confidence score from original search')
        public String confidenceScore;

        @InvocableVariable(label='Status' description='Review status')
        public String status;

        @InvocableVariable(label='Created Date' description='Date the record was last modified')
        public String createdDate;
    }
}
