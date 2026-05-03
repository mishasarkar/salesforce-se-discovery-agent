public class UpdateDiscoverySessionAction {

    public class UpdateRequest {
        @InvocableVariable(required=true label='Record Id')
        public String recordId;
        @InvocableVariable(label='Budget Range')
        public String budget_range;
        @InvocableVariable(label='Company Size')
        public String company_size;
        @InvocableVariable(label='Current CRM')
        public String current_crm;
        @InvocableVariable(label='Decision Timeline')
        public String decision_timeline;
        @InvocableVariable(label='Discovery Status')
        public String discovery_status;
        @InvocableVariable(label='Followup Email')
        public String followup_email;
        @InvocableVariable(label='Key Stakeholders')
        public String key_stakeholders;
        @InvocableVariable(label='Recommended Clouds')
        public String recommended_clouds;
        @InvocableVariable(label='Solution Brief')
        public String solution_brief;
        @InvocableVariable(label='Top Pain Point 1')
        public String top_pain_point_1;
        @InvocableVariable(label='Top Pain Point 2')
        public String top_pain_point_2;
        @InvocableVariable(label='Top Pain Point 3')
        public String top_pain_point_3;
    }

    public class UpdateResult {
        @InvocableVariable(label='Update Status')
        public String update_status;
    }

    @InvocableMethod(label='Update Discovery Session' description='Updates a Discovery Session record with only the provided non-blank values, preserving all existing data.')
    public static List<UpdateResult> updateSession(List<UpdateRequest> requests) {
        UpdateRequest req = requests[0];

        Discovery_Session__c session = [
            SELECT Id, Budget_Range__c, Company_Size__c, Current_CRM__c,
                   Decision_Timeline__c, Discovery_Status__c, Followup_Email__c,
                   Key_Stakeholders__c, Recommended_Clouds__c, Solution_Brief__c,
                   Top_Pain_Point_1__c, Top_Pain_Point_2__c, Top_Pain_Point_3__c
            FROM Discovery_Session__c
            WHERE Id = :req.recordId
            LIMIT 1
        ];

        if (!String.isBlank(req.budget_range))       session.Budget_Range__c       = req.budget_range;
        if (!String.isBlank(req.company_size))        session.Company_Size__c        = req.company_size;
        if (!String.isBlank(req.current_crm))         session.Current_CRM__c         = req.current_crm;
        if (!String.isBlank(req.decision_timeline))   session.Decision_Timeline__c   = req.decision_timeline;
        if (!String.isBlank(req.discovery_status))    session.Discovery_Status__c    = req.discovery_status;
        if (!String.isBlank(req.followup_email))      session.Followup_Email__c      = req.followup_email;
        if (!String.isBlank(req.key_stakeholders))    session.Key_Stakeholders__c    = req.key_stakeholders;
        if (!String.isBlank(req.recommended_clouds))  session.Recommended_Clouds__c  = req.recommended_clouds;
        if (!String.isBlank(req.solution_brief))      session.Solution_Brief__c      = req.solution_brief;
        if (!String.isBlank(req.top_pain_point_1))    session.Top_Pain_Point_1__c    = req.top_pain_point_1;
        if (!String.isBlank(req.top_pain_point_2))    session.Top_Pain_Point_2__c    = req.top_pain_point_2;
        if (!String.isBlank(req.top_pain_point_3))    session.Top_Pain_Point_3__c    = req.top_pain_point_3;

        update session;

        UpdateResult result = new UpdateResult();
        result.update_status = 'Success';
        return new List<UpdateResult>{ result };
    }
}
