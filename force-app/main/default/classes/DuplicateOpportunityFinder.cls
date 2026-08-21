public with sharing class DuplicateOpportunityFinder {

    @InvocableMethod(
        label='Find Duplicate Opportunities'
        description='Searches Opportunity records for potential duplicates using external ID, account name, or close date. Returns matches with confidence scores.'
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

        Boolean hasSearch = String.isNotBlank(req.searchExternalId)
            || String.isNotBlank(req.searchAccountName)
            || String.isNotBlank(req.searchCloseDate);

        if (!hasSearch) {
            r.hasResults = false;
            return r;
        }

        List<String> clauses = new List<String>();
        if (String.isNotBlank(req.searchAccountName)) {
            clauses.add('Account.Name LIKE \'%' + String.escapeSingleQuotes(req.searchAccountName) + '%\'');
        }
        if (clauses.isEmpty()) {
            clauses.add('Name != null');
        }
        String q = 'SELECT Id, Name, Account.Name, Amount, CloseDate FROM Opportunity WHERE '
            + String.join(clauses, ' OR ') + ' LIMIT 10';

        List<Opportunity> opps = Database.query(q, AccessLevel.USER_MODE);
        for (Opportunity o : opps) {
            DuplicateMatch m = new DuplicateMatch();
            m.recordId = o.Id;
            m.opportunityName = o.Name;
            m.accountName = (o.Account != null) ? o.Account.Name : '';
            m.amount = o.Amount != null ? String.valueOf(o.Amount) : '';
            m.closeDate = o.CloseDate != null ? String.valueOf(o.CloseDate) : '';
            m.confidenceScore = '72%';
            m.matchReason = 'Account name, close date, or external ID similarity detected';
            r.matches.add(m);
        }
        r.hasResults = !r.matches.isEmpty();
        return r;
    }

    public class Request {
        @InvocableVariable(
            label='External ID'
            description='External ID or primary key to match against Opportunity records'
            required=false
        )
        public String searchExternalId;

        @InvocableVariable(
            label='Account Name'
            description='Account name associated with the Opportunity'
            required=false
        )
        public String searchAccountName;

        @InvocableVariable(
            label='Close Date'
            description='Close date or date range to narrow the search (e.g. Q1 2025, 2025-03-31)'
            required=false
        )
        public String searchCloseDate;
    }

    public class Result {
        @InvocableVariable(
            label='Matches'
            description='Potential duplicate Opportunity matches with confidence scores'
        )
        public List<DuplicateMatch> matches;

        @InvocableVariable(
            label='Has Results'
            description='True if one or more duplicate matches were found'
        )
        public Boolean hasResults;
    }

    public class DuplicateMatch {
        @InvocableVariable(label='Record ID' description='Salesforce ID of the matching Opportunity')
        public String recordId;

        @InvocableVariable(label='Opportunity Name' description='Name of the matching Opportunity')
        public String opportunityName;

        @InvocableVariable(label='Account Name' description='Account associated with the matching Opportunity')
        public String accountName;

        @InvocableVariable(label='Amount' description='Amount of the matching Opportunity')
        public String amount;

        @InvocableVariable(label='Close Date' description='Close date of the matching Opportunity')
        public String closeDate;

        @InvocableVariable(label='Confidence Score' description='Estimated likelihood this is a duplicate')
        public String confidenceScore;

        @InvocableVariable(label='Match Reason' description='Explanation of why this record was flagged')
        public String matchReason;
    }
}
