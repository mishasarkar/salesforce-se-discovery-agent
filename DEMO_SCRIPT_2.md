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
   ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐
   │    FLOWS    │   │  APEX CLASS  │   │ PROMPT TEMPLATE  │
   │  (Create +  │   │(Solution     │   │ (Followup Email) │
   │   Update)   │   │  Brief)      │   └──────────────────┘
   └──────┬──────┘   └──────┬───────┘
          │                  │
          ▼                  ▼
   ┌─────────────────────────────────┐
   │      CUSTOM OBJECT              │
   │     Discovery_Session__c        │
   │  (The CRM record that stores    │
   │   everything from the call)     │
   └─────────────────────────────────┘
```

**Translation:** The agent talks to the prospect → Flows save the answers → Apex calls AI for the brief → Prompt Template writes the email → everything lives in one Salesforce record.

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

**What it does:** Updates the existing Discovery Session record with new answers after every 2-3 questions.

**The problem I had to solve:** Salesforce flows, when you pass a blank/empty value for a field, will wipe out whatever was already saved there. So if the agent calls Update with `top_pain_point_1` but not `top_pain_point_2` yet, the flow would blank out `top_pain_point_2` even if it was already saved.

**How I fixed it:** I added a **Get Records** step before the update, plus an Apex class (`UpdateDiscoverySessionAction`) that does a smarter merge:

```
Agent calls Update with new answers
         │
         ▼
Apex fetches the EXISTING record from Salesforce
         │
         ▼
For each field:
  IF new value is not blank → use the new value
  IF new value IS blank → keep the existing value
         │
         ▼
Update record with merged values
         │
         ▼
No data ever gets accidentally wiped out
```

**Why this matters for the demo:** Pain points accumulate correctly. If the agent saves Pain Point 1 first, then Pain Point 2 in the next call, both stay in the record. Without this fix, the second call would erase Pain Point 1.

---

## Component 3 — The Apex Classes

I wrote **two custom Apex classes** — these are Java-like programs that run on Salesforce's servers.

### Class 1: `GenerateSolutionBriefAction`

**What it does:** Calls the Salesforce Einstein AI API with the Discovery Session data and saves the returned brief back to the record.

**Why I needed custom code instead of a Flow:**
Salesforce's built-in AI integration (`ConnectApi.EinsteinLLM`) can only be called from Apex. There's no drag-and-drop Flow element for it. I had to write the code myself.

**What happens when the agent calls it:**

```
Agent passes: Discovery Session Record ID
         │
         ▼
Apex queries the full record (all 15 fields)
         │
         ▼
Apex calls: ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()
  └── Passes: the record data + the prompt template name
         │
         ▼
Einstein AI returns: the full Solution Brief text
         │
         ▼
Apex saves:
  - Solution_Brief__c = the brief text
  - Discovery_Status__c = "Brief Generated"
         │
         ▼
Agent displays the brief in the chat
```

**The `@InvocableMethod` annotation:** This is the magic decorator that makes a regular Apex class callable by Agentforce. Without it, the agent can't see or use the class. Think of it like putting a "Available for Agent Use" label on the code.

---

### Class 2: `UpdateDiscoverySessionAction`

**What it does:** The smarter version of the update flow — handles the null-safe merge I described above.

**Why Apex instead of Flow:** Salesforce Flow's formula engine doesn't support IF() logic on picklist or multi-select picklist fields. The six picklist fields in our object (Company Size, Budget Range, Decision Timeline, Industry, Discovery Status, Recommended Clouds) would have caused formula errors. Apex doesn't have this limitation — it just works.

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

## Component 4 — The Prompt Templates

I built **two Prompt Templates** in Salesforce Prompt Builder — these are the "instructions" I give to the AI model for each output.

### Template 1: `Generate_Solution_Brief`

**What it does:** Takes the Discovery Session data and produces a structured 5-section Solution Brief.

**The AI model I chose:** `Claude Haiku` (fast, good at structured output, lower cost)

**The five sections I defined:**

```
1. Customer Snapshot      → 2-3 sentences: who they are, what they do
2. Top Business Challenges → Their pain points in THEIR words (not Salesforce jargon)
3. Recommended Solutions  → Which Salesforce clouds fix which pain points
4. Why Salesforce         → 2-3 sentences of differentiation
5. Suggested Next Step    → One concrete action (demo, workshop, POC)
```

**Key prompt engineering decisions:**

| Instruction I gave the AI | Why |
|--------------------------|-----|
| *"Use plain language. No fluff. No generic marketing copy."* | Interviewers and customers can smell a generic pitch instantly |
| *"Tie every recommendation to a specific pain point the prospect mentioned."* | Forces the AI to be relevant, not just rattle off product features |
| *"Quote their exact words where possible."* | Makes the prospect feel heard — a core SE skill |
| *"Only recommend clouds that directly address a stated pain point."* | Prevents over-pitching. Don't recommend all 6 clouds when they only have 2 problems. |

---

### Template 2: `Generate_Followup_Email`

**What it does:** Writes a professional follow-up recap email, under 200 words.

**The AI model I chose:** `GPT-4o Mini` (optimized for concise, professional writing)

**Key prompt engineering decisions:**

| Instruction I gave the AI | Why |
|--------------------------|-----|
| *"Start with a suggested Subject: line"* | Makes it truly ready-to-send, nothing left for the SE to figure out |
| *"Thank them genuinely — 1 sentence, not generic"* | "Thanks for your time" is lazy. The AI knows the specific topics discussed. |
| *"Summarize pain points in THEIR exact words, not Salesforce jargon"* | Same reason as the brief — mirror their vocabulary |
| *"Propose a concrete next meeting with a suggested agenda"* | Vague next steps kill deals. The email suggests a specific demo focus. |
| *"Tone: warm, professional, not salesy — write like a trusted advisor"* | SEs are not sales reps. The email should feel like it's from someone who actually listened. |
| *"Do not exceed 200 words in the body"* | Long emails don't get read. 200 words forces ruthless prioritization. |

---

## Component 5 — The Agent Configuration

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

Without this variable, each topic would have no idea which record to update. The agent would either create a new record every time or update the wrong one. This one variable is the thread that connects all three topics together.

**How it gets set:** When the Create Discovery Session action runs, it returns a `record_id` output. In the Agent Builder, I mapped that output to `{discovery_session_id}` so the agent captures and stores it automatically.

---

## Component 6 — The Permission Set

**What it is:** A permission set called `SE_Discovery_Agent_User` that grants the agent's system user access to everything it needs.

**Why it's needed:** Salesforce's security model means nothing has access to anything by default. The agent runs as a special system user — that user needs explicit permission to:

| Permission granted | Why it's needed |
|-------------------|----------------|
| Read + Create + Edit `Discovery_Session__c` | Can't save data to a record you don't have access to |
| Read + Edit all 15 custom fields | Field-level security is separate from object security in Salesforce |
| Run `GenerateSolutionBriefAction` Apex | Apex classes are locked down by default |
| Run `UpdateDiscoverySessionAction` Apex | Same reason |

**Without this:** The agent would crash silently the moment it tried to create a record or call an Apex class. Took me a while to debug this during the build — it's one of the less obvious parts of Agentforce setup.

---

## Summary — What I Built vs. What Salesforce Provided

| Layer | What Salesforce provides out of the box | What I built custom |
|-------|----------------------------------------|---------------------|
| Agent framework | Agentforce runtime, topic routing, variable system | The 3 topics, instructions, action bindings |
| Data storage | Custom object capability | The `Discovery_Session__c` object and all 15 fields |
| Automation | Flow builder | 2 flows (Create + Update) with null-safe merge logic |
| AI integration | Einstein LLM API, Prompt Builder | 2 Apex classes, 2 prompt templates with custom instructions |
| Security | Permission set framework | The `SE_Discovery_Agent_User` permission set |

**The honest answer to "what did you actually build?"**

> *"Salesforce gave me the tools. I designed how they fit together — the data model, the automation logic, the AI prompts, and the agent instructions. Every configuration decision was intentional and I can explain the 'why' behind each one."*

---

## Questions You Might Get — And How to Answer Them

**"Why did you use Apex instead of a Flow for the updates?"**
> *"Salesforce Flow's formula engine doesn't support IF logic on picklist fields, and 6 of our 15 fields are picklists. Apex doesn't have that limitation — it's the right tool for the job."*

**"Why separate the brief and the email into two prompt templates?"**
> *"They're for different audiences and different purposes. The brief is structured reference material. The email is conversational. They need different AI models and different prompt instructions."*

**"How does the agent know which Salesforce record to update?"**
> *"The context variable `discovery_session_id`. It's set once when the first record is created and passed to every action in every topic for the rest of the conversation."*

**"What would you improve if you had more time?"**
> *"Better handling of the topic transition — right now the agent sometimes needs a nudge to move from Discovery to Solution Recommendation. I'd also add error handling for when the AI call fails, so the agent gracefully retries or tells the user what happened."*
