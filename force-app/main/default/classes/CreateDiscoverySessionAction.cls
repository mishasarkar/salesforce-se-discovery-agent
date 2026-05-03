public class CreateDiscoverySessionAction {

    public class CreateRequest {
        @InvocableVariable(required=true label='Prospect Name')
        public String prospect_name;
        @InvocableVariable(required=true label='Company Name')
        public String company_name;
        @InvocableVariable(required=true label='Industry')
        public String industry;
    }

    public class CreateResult {
        @InvocableVariable(label='Record Id')
        public String record_id;
    }

    @InvocableMethod(label='Create Discovery Session' description='Creates a new Discovery Session record and returns the Salesforce record Id.')
    public static List<CreateResult> createSession(List<CreateRequest> requests) {
        CreateRequest req = requests[0];

        Discovery_Session__c session = new Discovery_Session__c(
            Prospect_Name__c = req.prospect_name,
            Company_Name__c  = req.company_name,
            Industry__c      = req.industry,
            Discovery_Status__c = 'In Progress'
        );

        insert session;

        CreateResult result = new CreateResult();
        result.record_id = session.Id;
        return new List<CreateResult>{ result };
    }
}
