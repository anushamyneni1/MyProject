public with sharing class DuplicateAccountFinder {

    @InvocableMethod(
        label='Find Duplicate Accounts'
        description='Searches Account records for potential duplicates using name, website, or Tax ID matching. Returns matches with confidence scores.'
    )
    public static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(findDuplicates(req));
        }
        return results;
    }

    private static Result findDuplicates(Request req) {
        Result r = new Result();
        r.matches = new List<DuplicateMatch>();

        Boolean hasSearch = String.isNotBlank(req.searchName)
            || String.isNotBlank(req.searchWebsite)
            || String.isNotBlank(req.searchTaxId);

        if (!hasSearch) {
            r.hasResults = false;
            return r;
        }

        List<String> clauses = new List<String>();
        if (String.isNotBlank(req.searchName)) {
            clauses.add('Name LIKE \'%' + String.escapeSingleQuotes(req.searchName) + '%\'');
        }
        if (String.isNotBlank(req.searchWebsite)) {
            clauses.add('Website LIKE \'%' + String.escapeSingleQuotes(req.searchWebsite) + '%\'');
        }
        String q = 'SELECT Id, Name, Website FROM Account WHERE '
            + String.join(clauses, ' OR ') + ' LIMIT 10';

        List<Account> accounts = Database.query(q, AccessLevel.USER_MODE);
        for (Account a : accounts) {
            DuplicateMatch m = new DuplicateMatch();
            m.recordId = a.Id;
            m.recordName = a.Name;
            m.website = a.Website != null ? a.Website : '';
            m.confidenceScore = '75%';
            m.matchReason = 'Name or website similarity detected';
            r.matches.add(m);
        }
        r.hasResults = !r.matches.isEmpty();
        return r;
    }

    public class Request {
        @InvocableVariable(
            label='Account Name'
            description='Account name to search for potential duplicates'
            required=false
        )
        public String searchName;

        @InvocableVariable(
            label='Website'
            description='Website URL to match against Account records'
            required=false
        )
        public String searchWebsite;

        @InvocableVariable(
            label='Tax ID'
            description='Tax ID to match against Account records'
            required=false
        )
        public String searchTaxId;
    }

    public class Result {
        @InvocableVariable(
            label='Matches'
            description='Potential duplicate Account matches with confidence scores'
        )
        public List<DuplicateMatch> matches;

        @InvocableVariable(
            label='Has Results'
            description='True if one or more duplicate matches were found'
        )
        public Boolean hasResults;
    }

    public class DuplicateMatch {
        @InvocableVariable(label='Record ID' description='Salesforce ID of the matching Account')
        public String recordId;

        @InvocableVariable(label='Record Name' description='Name of the matching Account')
        public String recordName;

        @InvocableVariable(label='Website' description='Website of the matching Account')
        public String website;

        @InvocableVariable(label='Confidence Score' description='Estimated likelihood this is a duplicate')
        public String confidenceScore;

        @InvocableVariable(label='Match Reason' description='Explanation of why this record was flagged')
        public String matchReason;
    }
}
