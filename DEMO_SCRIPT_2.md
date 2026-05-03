# Demo Script 2 — Configuration & Customization Deep Dive
### SE Discovery Assistant · Agentforce Agent
> **Who is presenting:** A fresh college grad walking Salesforce interviewers through every technical decision.
> **Tone:** Knowledgeable but approachable — like explaining your school project to someone smart who hasn't seen it.

---

## The Big Picture — How It All Connects

Before diving into each piece, here's the full architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENTFORCE AGENT                         │
│                  "SE Discovery Assistant"                   │
│                                                             │
│  ┌─────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │  Discovery  │  │    Solution      │  │   Followup    │  │
│  │Conversation │→ │ Recommendation   │→ │  Generation   │  │
│  └──────┬──────┘  └────────┬─────────┘  └───────┬───────┘  │
│         │                  │                     │          │
└─────────┼──────────────────┼─────────────────────┼──────────┘
          │                  │                     │
          ▼                  ▼                     ▼
   ┌─────────────┐   ┌──────────────────┐   ┌──────────────────┐
   │    FLOWS    │   │   APEX CLASS     │   │   APEX CLASS     │
   │  (Create)   │   │ GenerateSolution │   │ GenerateFollowup │
   │             │   │  BriefAction     │   │  EmailAction     │
   └──────┬──────┘   └──────┬───────────┘   └──────┬───────────┘
          │                  │                      │
          │           ┌──────▼──────────────────────▼──────┐
          │           │     aiplatform.ModelsAPI            │
          │           │  (Salesforce-hosted LLM — no       │
          │           │   prompt template required)         │
          │           └─────────────────────────────────────┘
          │
          ▼
   ┌─────────────────────────────────┐
   │      CUSTOM OBJECT              │
   │     Discovery_Session__c        │
   │  (The CRM record that stores    │
   │   everything from the call)     │
   └─────────────────────────────────┘
```

**Translation:** The agent talks to the prospect → Flows/Apex save the answers → Two Apex classes call the Salesforce-hosted LLM directly via `aiplatform.ModelsAPI` → everything lives in one Salesforce record.

---

## Component 1 — The Custom Object: `Discovery_Session__c`

### What it is
Think of this as a digital form that gets filled out automatically during the call. Instead of the SE taking notes on paper or a Google Doc that no one can find later, every answer goes directly into Salesforce.

### What I built
A custom Salesforce object with **15 custom fields** — one for each piece of information the SE needs to capture:

```
Discovery_Session__c
├── Prospect_Name__c          → Who are we talking to?
├── Company_Name__c           → What company?
├── Industry__c               → What sector? (Picklist)
├── Company_Size__c           → How big? (Picklist)
├── Current_CRM__c            → What tools do they use now?
├── Top_Pain_Point_1__c       → Biggest challenge
├── Top_Pain_Point_2__c       → Second challenge
├── Top_Pain_Point_3__c       → Third challenge
├── Decision_Timeline__c      → How soon? (Picklist)
├── Budget_Range__c           → How much? (Picklist)
├── Key_Stakeholders__c       → Who decides?
├── Discovery_Status__c       → Where are we? (Picklist)
├── Recommended_Clouds__c     → Which Salesforce products? (Multi-Picklist)
├── Solution_Brief__c         → AI-generated brief (Long Text, 32,000 chars)
└── Followup_Email__c         → AI-generated email (Long Text, 32,000 chars)
```

### Why each design decision matters

| Decision | Why I made it |
|----------|--------------|
| `Discovery_Status__c` defaults to "In Progress" | The agent always knows where it left off, even if the call gets interrupted |
| Pain points are separate fields (not one big text box) | So the AI prompt can reference each one individually and map them to specific Salesforce products |
| Solution Brief and Followup Email are Long Text (32,000 chars) | AI-generated content can be long — a regular Text field has a 255-character limit and would get cut off |
| AutoNumber name field (`DS-{0000}`) | Every session gets a clean, unique identifier — easy to reference and professional looking |

---

## Component 2 — The Flows

I built **two Autolaunched Flows** — these are automation workflows that run silently in the background when the agent calls them.

### Flow 1: `Create_Discovery_Session`

**What it does:** Creates a brand new Discovery Session record the moment the agent has collected the prospect's name, company, and industry.

**Why it matters:** The record needs to exist before we can save anything else to it. This flow runs once, right at the start, and hands back the record's ID so the agent knows where to save everything going forward.

```
Agent has: Name + Company + Industry
         │
         ▼
   Create_Discovery_Session Flow runs
         │
         ▼
   New record created in Salesforce
         │
         ▼
   record_id → stored in {discovery_session_id}
         │
         ▼
   Agent uses this ID for every update going forward
```

**Key technical detail:** I used `assignRecordIdToReference` inside the flow to capture the new record's ID and expose it as an output variable. Without this, the agent would have no way to know which record to update later.

---

### Flow 2: `Update_Discovery_Session`

**What it does:** Updates the existing Discovery Session record with new answers.

**Important note:** This flow does a direct field update. The null-safe merge logic (preserving existing field values when new ones are blank) lives in the `UpdateDiscoverySessionAction` Apex class, which the agent calls directly. The flow exists as a fallback but the agent uses the Apex class for all updates.

---

## Component 3 — The Apex Classes

I wrote **three custom Apex classes** — these are Java-like programs that run on Salesforce's servers.

### Class 1: `CreateDiscoverySessionAction`

**What it does:** Creates a new Discovery Session record and returns the Salesforce record ID.

**Why Apex instead of just the Flow:** The Apex class uses `session.Id` directly after insert, which is 100% reliable. Early in the build I tried capturing the ID in the flow using `assignRecordIdToReference`, but it was unreliable — the agent would sometimes not receive the ID back. Apex solved this.

---

### Class 2: `UpdateDiscoverySessionAction`

**What it does:** The null-safe merge — updates only the fields that have new values, leaving everything else untouched.

**Why Apex instead of Flow:** Salesforce Flow's formula engine doesn't support `IF()` logic on picklist or multi-select picklist fields. Six of our 15 fields are picklists — using formulas would have caused validation errors on every deploy. Apex doesn't have this limitation.

**The core logic (plain English version):**

```apex
// For each field:
if (the new value is not blank) {
    update the field with the new value
} else {
    leave the existing value alone
}
```

Simple, reliable, and works for every field type.

---

### Class 3: `GenerateSolutionBriefAction`

**What it does:** Queries the Discovery Session record, builds a structured prompt from the field values, calls the Salesforce-hosted LLM directly, and saves the returned brief back to the record.

**The key architectural decision — `aiplatform.ModelsAPI`:**

I'm calling the LLM using Salesforce's `aiplatform.ModelsAPI` — a native Apex API that lets you call Salesforce-hosted models directly without needing a Prompt Template:

```apex
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
```

**Why not Prompt Templates?**
Salesforce's other LLM API (`ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate`) requires a Prompt Template with a `SOBJECT://` input. When you pass a record ID to that input from Apex, it throws `Invalid input value` — the API can't resolve a plain ID string as a SObject reference. `aiplatform.ModelsAPI` takes a plain text prompt directly, so all the prompt engineering lives in Apex where it belongs.

**What happens when the agent calls it:**

```
Agent passes: Discovery Session Record ID
         │
         ▼
Apex queries all 11 discovery fields
         │
         ▼
Apex builds the full prompt (substituting real field values)
         │
         ▼
aiplatform.ModelsAPI calls Claude Haiku (Salesforce-hosted)
         │
         ▼
LLM returns the structured 5-section Solution Brief
         │
         ▼
Apex saves:
  - Solution_Brief__c = the brief text
  - Discovery_Status__c = "Brief Generated"
```

---

### Class 4: `GenerateFollowupEmailAction`

**What it does:** Same pattern as the brief — queries the record, builds a focused email prompt, calls the LLM, saves the email to `Followup_Email__c`.

**Model used:** `sfdc_ai__DefaultGPT5Mini` (GPT-4o Mini — optimized for concise, professional writing)

**Key prompt engineering decisions:**

| Instruction I gave the AI | Why |
|--------------------------|-----|
| *"Start with a suggested Subject: line"* | Makes it truly ready-to-send |
| *"Thank them genuinely — 1 sentence, not generic"* | The AI knows the specific topics discussed — "Thanks for your time" is lazy |
| *"Summarize pain points in THEIR exact words, not Salesforce jargon"* | Mirror their vocabulary |
| *"Propose a concrete next meeting with a suggested agenda"* | Vague next steps kill deals |
| *"Tone: warm, professional, not salesy"* | SEs are trusted advisors, not sales reps |
| *"Do not exceed 200 words in the body"* | Long emails don't get read |

---

## Component 4 — The Agent Configuration

### The 3 Topics (Subagents)

The agent is divided into three distinct conversations, each with a specific job:

```
┌─────────────────────────────────────────────────────────────┐
│ Topic 1: Discovery Conversation                             │
│                                                             │
│ Job: Ask questions, create + update the Salesforce record   │
│ Actions: Create Discovery Session, Update Discovery Session  │
│ Ends when: All fields captured → hands off to Topic 2       │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Topic 2: Solution Recommendation                            │
│                                                             │
│ Job: Generate and present the Solution Brief                │
│ Actions: Generate Solution Brief, Update Discovery Session  │
│ Ends when: Prospect approves → hands off to Topic 3         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Topic 3: Followup Generation                                │
│                                                             │
│ Job: Draft and refine the follow-up email                   │
│ Actions: Generate Followup Email, Update Discovery Session  │
│ Ends when: Prospect approves email → conversation closes    │
└─────────────────────────────────────────────────────────────┘
```

**Why three separate topics instead of one big one?**
Agentforce works best when each topic has a clear, narrow job. If I put everything in one topic, the agent gets confused about when to ask questions vs. when to generate content. Separating them gives the AI clear guardrails.

---

### The Context Variable: `discovery_session_id`

**What it is:** A single text variable that holds the Salesforce record ID of the active Discovery Session.

**Why it's the most important piece of the whole build:**

```
Topic 1 creates the record → gets back the ID (e.g., a00g5000001XyZAA)
                                    │
                    stored in: {discovery_session_id}
                                    │
        ┌───────────────────────────┼──────────────────────────┐
        ▼                           ▼                          ▼
Topic 1 Update         Topic 2 Generate Brief      Topic 3 Generate Email
passes record ID       passes record ID            passes record ID
```

Without this variable, each topic would have no idea which record to update. This one variable is the thread that connects all three topics together.

---

## Component 5 — The Permission Set

**What it is:** A permission set called `SE_Discovery_Agent_User` that grants the agent's system user access to everything it needs.

| Permission granted | Why it's needed |
|-------------------|----------------|
| Read + Create + Edit `Discovery_Session__c` | Can't save data to a record you don't have access to |
| Read + Edit all 15 custom fields | Field-level security is separate from object security in Salesforce |
| Run `GenerateSolutionBriefAction` Apex | Apex classes are locked down by default |
| Run `GenerateFollowupEmailAction` Apex | Same reason |
| Run `UpdateDiscoverySessionAction` Apex | Same reason |
| Run `CreateDiscoverySessionAction` Apex | Same reason |

---

## Summary — What I Built vs. What Salesforce Provided

| Layer | What Salesforce provides out of the box | What I built custom |
|-------|----------------------------------------|---------------------|
| Agent framework | Agentforce runtime, topic routing, variable system | The 3 topics, instructions, action bindings |
| Data storage | Custom object capability | The `Discovery_Session__c` object and all 15 fields |
| Automation | Flow builder | 2 flows (Create + Update) |
| AI integration | `aiplatform.ModelsAPI`, Salesforce-hosted models | 2 Apex classes with custom prompt engineering, calling models directly — no Prompt Templates |
| Security | Permission set framework | The `SE_Discovery_Agent_User` permission set |

**The honest answer to "what did you actually build?"**

> *"Salesforce gave me the tools. I designed how they fit together — the data model, the automation logic, the AI prompts, and the agent instructions. Every configuration decision was intentional and I can explain the 'why' behind each one."*

---

## Questions You Might Get — And How to Answer Them

**"Why did you use Apex instead of a Flow for the updates?"**
> *"Salesforce Flow's formula engine doesn't support IF logic on picklist fields, and 6 of our 15 fields are picklists. Apex doesn't have that limitation — it's the right tool for the job."*

**"Why did you use `aiplatform.ModelsAPI` instead of Prompt Templates?"**
> *"Prompt Templates use a `SOBJECT://` input type that rejects plain record IDs passed from Apex — it throws an `Invalid input value` error at runtime. `aiplatform.ModelsAPI` takes a plain text string directly, so all the prompt engineering lives in Apex where I can version-control it, test it, and iterate on it without touching Salesforce UI config."*

**"How does the agent know which Salesforce record to update?"**
> *"The context variable `discovery_session_id`. It's set once when the first record is created and passed to every action in every topic for the rest of the conversation."*

**"Why two separate Apex classes for the brief and the email?"**
> *"They're for different audiences and purposes. The brief is structured reference material for the SE — five sections, detailed recommendations. The email is conversational, under 200 words, ready to send. Different models too: Claude Haiku for the brief (better at structured output), GPT-4o Mini for the email (better at concise professional writing)."*

**"What would you improve if you had more time?"**
> *"Better handling of the topic transition — right now the agent sometimes needs a nudge to move from Discovery to Solution Recommendation. I'd also add error handling for when the AI call fails, so the agent gracefully retries or tells the user what happened."*
