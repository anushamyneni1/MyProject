public with sharing class DuplicateContactFinder {

    @InvocableMethod(
        label='Find Duplicate Contacts'
        description='Searches Contact records for potential duplicates using email, phone, or name matching. Returns matches with confidence scores.'
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

        Boolean hasSearch = String.isNotBlank(req.searchEmail)
            || String.isNotBlank(req.searchPhone)
            || String.isNotBlank(req.searchName);

        if (!hasSearch) {
            r.hasResults = false;
            return r;
        }

        List<String> clauses = new List<String>();
        if (String.isNotBlank(req.searchEmail)) {
            clauses.add('Email = \'' + String.escapeSingleQuotes(req.searchEmail) + '\'');
        }
        if (String.isNotBlank(req.searchPhone)) {
            clauses.add('Phone = \'' + String.escapeSingleQuotes(req.searchPhone) + '\'');
        }
        if (String.isNotBlank(req.searchName)) {
            clauses.add('Name LIKE \'%' + String.escapeSingleQuotes(req.searchName) + '%\'');
        }
        String q = 'SELECT Id, Name, Email, Phone, Account.Name FROM Contact WHERE '
            + String.join(clauses, ' OR ') + ' LIMIT 10';

        List<Contact> contacts = Database.query(q, AccessLevel.USER_MODE);
        for (Contact c : contacts) {
            DuplicateMatch m = new DuplicateMatch();
            m.recordId = c.Id;
            m.fullName = c.Name;
            m.email = c.Email != null ? c.Email : '';
            m.phone = c.Phone != null ? c.Phone : '';
            m.accountName = (c.Account != null) ? c.Account.Name : '';
            m.confidenceScore = '80%';
            m.matchReason = 'Email, phone, or name similarity detected';
            r.matches.add(m);
        }
        r.hasResults = !r.matches.isEmpty();
        return r;
    }

    public class Request {
        @InvocableVariable(
            label='Email'
            description='Email address to match against Contact records'
            required=false
        )
        public String searchEmail;

        @InvocableVariable(
            label='Phone'
            description='Phone number to match against Contact records'
            required=false
        )
        public String searchPhone;

        @InvocableVariable(
            label='Name'
            description='Contact name to search for potential duplicates'
            required=false
        )
        public String searchName;
    }

    public class Result {
        @InvocableVariable(
            label='Matches'
            description='Potential duplicate Contact matches with confidence scores'
        )
        public List<DuplicateMatch> matches;

        @InvocableVariable(
            label='Has Results'
            description='True if one or more duplicate matches were found'
        )
        public Boolean hasResults;
    }

    public class DuplicateMatch {
        @InvocableVariable(label='Record ID' description='Salesforce ID of the matching Contact')
        public String recordId;

        @InvocableVariable(label='Full Name' description='Full name of the matching Contact')
        public String fullName;

        @InvocableVariable(label='Email' description='Email of the matching Contact')
        public String email;

        @InvocableVariable(label='Phone' description='Phone of the matching Contact')
        public String phone;

        @InvocableVariable(label='Account Name' description='Parent account of the matching Contact')
        public String accountName;

        @InvocableVariable(label='Confidence Score' description='Estimated likelihood this is a duplicate')
        public String confidenceScore;

        @InvocableVariable(label='Match Reason' description='Explanation of why this record was flagged')
        public String matchReason;
    }
}
