public with sharing class GenerateSolutionBriefAction {

    @InvocableMethod(
        label='Generate Solution Brief'
        description='Generates a tailored Solution Brief for a Discovery Session and saves it to the record.'
        callout=true
    )
    public static List<String> generateBrief(List<Id> sessionIds) {
        List<String> results = new List<String>();

        for (Id sessionId : sessionIds) {
            Discovery_Session__c session = [
                SELECT Prospect_Name__c, Company_Name__c, Industry__c,
                       Company_Size__c, Current_CRM__c,
                       Top_Pain_Point_1__c, Top_Pain_Point_2__c, Top_Pain_Point_3__c,
                       Decision_Timeline__c, Budget_Range__c, Key_Stakeholders__c
                FROM Discovery_Session__c
                WHERE Id = :sessionId
                LIMIT 1
            ];

            String prompt = buildPrompt(session);
            String briefText = callLLM(prompt);

            update new Discovery_Session__c(
                Id = sessionId,
                Solution_Brief__c = briefText,
                Discovery_Status__c = 'Brief Generated'
            );

            results.add(briefText);
        }

        return results;
    }

    private static String buildPrompt(Discovery_Session__c s) {
        return 'You are a senior Salesforce Solution Engineer. Given the discovery session below, produce a structured Solution Brief. Use plain language. No fluff. No generic marketing copy. Tie every recommendation to a specific pain point the prospect mentioned.\n\n'
            + 'DISCOVERY SESSION:\n'
            + 'Prospect: '         + nullSafe(s.Prospect_Name__c)    + '\n'
            + 'Company: '          + nullSafe(s.Company_Name__c)      + '\n'
            + 'Industry: '         + nullSafe(s.Industry__c)          + '\n'
            + 'Company Size: '     + nullSafe(s.Company_Size__c)      + '\n'
            + 'Current CRM / Tools: ' + nullSafe(s.Current_CRM__c)   + '\n'
            + 'Top Pain Point 1: ' + nullSafe(s.Top_Pain_Point_1__c)  + '\n'
            + 'Top Pain Point 2: ' + nullSafe(s.Top_Pain_Point_2__c)  + '\n'
            + 'Top Pain Point 3: ' + nullSafe(s.Top_Pain_Point_3__c)  + '\n'
            + 'Decision Timeline: '+ nullSafe(s.Decision_Timeline__c) + '\n'
            + 'Budget Range: '     + nullSafe(s.Budget_Range__c)      + '\n'
            + 'Key Stakeholders: ' + nullSafe(s.Key_Stakeholders__c)  + '\n\n'
            + 'Produce the Solution Brief using EXACTLY these five sections:\n\n'
            + '1. **Customer Snapshot**\n2-3 sentences summarizing who they are and what they do.\n\n'
            + '2. **Top Business Challenges**\nBulleted list in the prospect\'s own language, not Salesforce jargon. Quote their exact words where possible.\n\n'
            + '3. **Recommended Salesforce Solutions**\nFor each recommended cloud:\n  (a) Cloud name\n  (b) One sentence on what it does\n  (c) Two sentences on specific business value tied to THEIR pain points\nOnly recommend clouds that directly address a stated pain point.\n\n'
            + '4. **Why Salesforce vs. Alternatives**\n2-3 sentences of differentiation grounded in the prospect\'s stated needs.\n\n'
            + '5. **Suggested Next Step**\nOne concrete action: a workshop, tailored demo, POC scope, or joint architecture session. Be specific.';
    }

    private static String callLLM(String promptText) {
        aiplatform.ModelsAPI.createGenerations_Request request =
            new aiplatform.ModelsAPI.createGenerations_Request();
        request.modelName = 'sfdc_ai__DefaultBedrockAnthropicClaude45Haiku';

        aiplatform.ModelsAPI_GenerationRequest body =
            new aiplatform.ModelsAPI_GenerationRequest();
        body.prompt = promptText;
        request.body = body;

        aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
        aiplatform.ModelsAPI.createGenerations_Response response =
            modelsAPI.createGenerations(request);
        return response.Code200.generation.generatedText;
    }

    private static String nullSafe(String val) {
        return val == null ? 'Not provided' : val;
    }
}
