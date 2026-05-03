public with sharing class GenerateFollowupEmailAction {

    @InvocableMethod(
        label='Generate Followup Email'
        description='Generates a tailored follow-up email for a Discovery Session and saves it to the record.'
        callout=true
    )
    public static List<String> generateEmail(List<Id> sessionIds) {
        List<String> results = new List<String>();

        for (Id sessionId : sessionIds) {
            Discovery_Session__c session = [
                SELECT Prospect_Name__c, Company_Name__c, Industry__c,
                       Top_Pain_Point_1__c, Top_Pain_Point_2__c, Top_Pain_Point_3__c,
                       Recommended_Clouds__c, Decision_Timeline__c
                FROM Discovery_Session__c
                WHERE Id = :sessionId
                LIMIT 1
            ];

            String prompt = buildPrompt(session);
            String emailText = callLLM(prompt);

            update new Discovery_Session__c(
                Id = sessionId,
                Followup_Email__c = emailText,
                Discovery_Status__c = 'Email Generated'
            );

            results.add(emailText);
        }

        return results;
    }

    private static String buildPrompt(Discovery_Session__c s) {
        return 'You are a Salesforce Solution Engineer writing a follow-up email to a prospect after a discovery call. Write a concise recap email (under 200 words).\n\n'
            + 'DISCOVERY SESSION:\n'
            + 'Prospect: '              + nullSafe(s.Prospect_Name__c)      + '\n'
            + 'Company: '               + nullSafe(s.Company_Name__c)       + '\n'
            + 'Industry: '              + nullSafe(s.Industry__c)           + '\n'
            + 'Top Pain Point 1: '      + nullSafe(s.Top_Pain_Point_1__c)   + '\n'
            + 'Top Pain Point 2: '      + nullSafe(s.Top_Pain_Point_2__c)   + '\n'
            + 'Top Pain Point 3: '      + nullSafe(s.Top_Pain_Point_3__c)   + '\n'
            + 'Recommended Solutions: ' + nullSafe(s.Recommended_Clouds__c) + '\n'
            + 'Decision Timeline: '     + nullSafe(s.Decision_Timeline__c)  + '\n\n'
            + 'Write the email following these rules:\n'
            + '- Start with a suggested subject line in the format "Subject: ..."\n'
            + '- Thank them genuinely for their time (1 sentence, not generic — reference the specific topics discussed)\n'
            + '- Summarize the three pain points in THEIR exact words, not Salesforce jargon\n'
            + '- Name the recommended solutions and briefly explain why each is relevant to their specific situation\n'
            + '- Propose a concrete next meeting with a suggested agenda (e.g., "a 90-minute tailored demo focused on X")\n'
            + '- Tone: warm, professional, not salesy — write like a trusted advisor, not a sales rep\n'
            + '- Do not exceed 200 words in the email body (subject line excluded)';
    }

    private static String callLLM(String promptText) {
        aiplatform.ModelsAPI.createGenerations_Request request =
            new aiplatform.ModelsAPI.createGenerations_Request();
        request.modelName = 'sfdc_ai__DefaultGPT5Mini';

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
