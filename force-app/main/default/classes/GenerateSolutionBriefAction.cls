/**
 * Invocable action called by the SE Discovery Assistant agent to generate a Solution Brief.
 *
 * Flow:
 *   1. Receives one or more Discovery Session record Ids from the agent.
 *   2. Invokes the Generate_Solution_Brief Flex Prompt Template via ConnectApi.EinsteinLLM.
 *   3. Writes the AI-generated text back to Solution_Brief__c on the record.
 *   4. Advances Discovery_Status__c to "Brief Generated".
 *   5. Returns the brief text so the agent can display it in the chat.
 *
 * The method is bulkified (accepts a List) to satisfy Apex best practices,
 * but in practice the agent will always pass a single-element list.
 */
public with sharing class GenerateSolutionBriefAction {

    @InvocableMethod(
        label='Generate Solution Brief'
        description='Invokes the Generate_Solution_Brief prompt template for a Discovery Session and writes the result back to the record.'
        callout=true
    )
    public static List<String> generateBrief(List<Id> sessionIds) {
        List<String> results = new List<String>();

        for (Id sessionId : sessionIds) {
            String briefText = invokePromptTemplate(sessionId);

            // Write the brief and advance the status in a single DML operation.
            update new Discovery_Session__c(
                Id = sessionId,
                Solution_Brief__c = briefText,
                Discovery_Status__c = 'Brief Generated'
            );

            results.add(briefText);
        }

        return results;
    }

    /**
     * Calls the Generate_Solution_Brief Flex Prompt Template via the Einstein LLM API.
     * Passes the Discovery Session record Id as the SObject input so the template
     * can merge all relevant fields into the prompt.
     */
    private static String invokePromptTemplate(Id sessionId) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput ptInput =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        ptInput.isPreview = false;

        ConnectApi.EinsteinLlmAdditionalConfigInput config =
            new ConnectApi.EinsteinLlmAdditionalConfigInput();
        config.applicationName = 'PromptTemplateGenerationsInvocations';
        ptInput.additionalConfig = config;

        // Wire the Discovery Session record into the template's "DiscoverySession" input.
        ConnectApi.WrappedValue recordValue = new ConnectApi.WrappedValue();
        recordValue.value = String.valueOf(sessionId);

        Map<String, ConnectApi.WrappedValue> inputParams =
            new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:DiscoverySession', recordValue);
        ptInput.inputParams = inputParams;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'Generate_Solution_Brief',
                ptInput
            );

        return response.generations[0].text;
    }
}
