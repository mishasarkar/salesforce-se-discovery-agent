# Agentforce SE Discovery Agent — Build Spec

> **Read this entire document before doing anything.** This is a build specification for an Agentforce AI agent that will be used as an interview demo for a Salesforce Solution Engineer (Early Career) role. Some steps must be done by the human in the Salesforce UI; some are pro-code and you (Claude Code) will execute them. Every step is labeled `[HUMAN]`, `[CLAUDE CODE]`, or `[BOTH]`.
>
> **You are Claude Code.** Your job is to scaffold the Salesforce DX project, write the Agent Script, custom object metadata, Apex classes, prompt templates, and Flow XML, and run CLI commands to deploy. You will **not** click in the Salesforce UI — when UI steps are required, pause and tell the user what to do, then wait for confirmation before continuing.

---

## 1. Project Goal

Build an Agentforce agent named **SE Discovery Assistant** that role-plays a Salesforce Solution Engineer running early-stage discovery with a prospect. The agent:

1. Asks structured discovery questions about the prospect's business, pain points, current tech stack, and goals.
2. Captures the answers in a custom Salesforce object (`Discovery_Session__c`).
3. Generates a tailored "Solution Brief" mapping the prospect's needs to specific Salesforce clouds (Sales, Service, Data, Agentforce, Marketing, Commerce) with business-value justifications.
4. Drafts a follow-up recap email the SE could send to the prospect.

This will be demoed live in an interview. Polish, narrative coherence, and reliability matter more than feature breadth.

---

## 2. Success Criteria (Definition of Done)

The build is complete when **all** of the following are true:

- [ ] A Developer Edition org with Agentforce enabled is connected via Salesforce CLI as the default org.
- [ ] A custom object `Discovery_Session__c` exists in the org with all fields listed in §5.
- [ ] An Agentforce agent named `SE_Discovery_Assistant` exists with three subagents: `Discovery_Conversation`, `Solution_Recommendation`, `Followup_Generation`.
- [ ] The agent has at least four working actions (see §6) wired through Flows, Apex, or Prompt Templates.
- [ ] A Prompt Template `Generate_Solution_Brief` produces a structured solution recommendation when given a Discovery Session record.
- [ ] The agent runs end-to-end in the Agentforce Builder Preview panel for the test scenario in §10 without error.
- [ ] All metadata is committed to a local git repo with clean commits per phase.
- [ ] A `DEMO_SCRIPT.md` exists at the repo root with the interview talk track and three pre-rehearsed prospect personas.

---

## 3. Prerequisites — `[HUMAN]` does these BEFORE starting Claude Code

Claude Code: do not begin until the user confirms each item below is done. Print this checklist back to the user and ask them to confirm.

1. **Sign up for an Agentforce-enabled Developer Edition org.**
   - Go to: https://developer.salesforce.com/signup
   - Choose the Agentforce Developer Edition (or sign up via the Trailhead "Quick Start: Assemble a Service Agent with Agentforce Builder" module which provisions one).
   - Verify the email, set a password, save the username and password somewhere safe.

2. **Enable Einstein and Agentforce in the org.**
   - Setup → Quick Find: `Einstein Setup` → ensure Einstein is **On**.
   - Setup → Quick Find: `Agentforce Agents` → toggle Agentforce **On**.
   - Refresh the browser.

3. **Install local tooling** (verify with the version commands):
   - Node.js 20+ (`node --version`)
   - Salesforce CLI (`sf --version`) — install: `npm install -g @salesforce/cli`
   - Git (`git --version`)
   - VS Code with Salesforce Extension Pack (includes Agentforce DX) — optional but recommended for the human to inspect work

4. **Authorize the org to the CLI:**
   ```
   sf org login web --alias se-discovery-dev --set-default
   ```
   Browser opens, user logs in to the Dev Edition org. Confirm with `sf org display`.

5. **Confirm Agentforce DX plugin is installed:**
   ```
   sf plugins
   ```
   If `@salesforce/plugin-agent` is not listed, install: `sf plugins install @salesforce/plugin-agent`.

When all five items are confirmed, Claude Code may proceed to §4.

---

## 4. Project Scaffold — `[CLAUDE CODE]`

Create the SFDX project and folder structure.

```bash
sf project generate --name se-discovery-agent --template standard
cd se-discovery-agent
git init
git add . && git commit -m "chore: scaffold sfdx project"
```

Create the following directory structure under `force-app/main/default/`:

```
force-app/main/default/
├── objects/
│   └── Discovery_Session__c/
│       ├── Discovery_Session__c.object-meta.xml
│       └── fields/
├── classes/                    # Apex classes for custom actions
├── flows/                      # Autolaunched flows for actions
├── genAiPromptTemplates/       # Prompt templates
├── aiAuthoringBundles/         # Agent Script files
│   └── SE_Discovery_Assistant/
└── permissionsets/
```

Add a top-level `README.md` (write a brief project overview and link to this spec) and a `DEMO_SCRIPT.md` placeholder.

Commit: `git commit -am "chore: create directory structure"`.

---

## 5. Custom Object — `[CLAUDE CODE]` writes metadata, `[HUMAN]` verifies in UI after deploy

Create the `Discovery_Session__c` custom object and its fields as metadata XML.

**Object definition** (`Discovery_Session__c.object-meta.xml`): Custom object, label "Discovery Session", plural "Discovery Sessions", record name "Session Number" (auto number, format `DS-{0000}`). Allow reports, activities, search.

**Fields to create** (each as a separate `*.field-meta.xml` file under `fields/`):

| API Name | Type | Length / Details | Purpose |
|---|---|---|---|
| `Prospect_Name__c` | Text | 120 | Person being interviewed |
| `Company_Name__c` | Text | 120 | |
| `Industry__c` | Picklist | Manufacturing, Financial Services, Healthcare, Retail, Technology, Nonprofit, Education, Other | |
| `Company_Size__c` | Picklist | 1-50, 51-250, 251-1000, 1001-5000, 5000+ | |
| `Current_CRM__c` | Text | 80 | What they use today |
| `Top_Pain_Point_1__c` | Long Text Area | 2000 | |
| `Top_Pain_Point_2__c` | Long Text Area | 2000 | |
| `Top_Pain_Point_3__c` | Long Text Area | 2000 | |
| `Decision_Timeline__c` | Picklist | Immediate (0-3mo), Near-term (3-6mo), Long-term (6-12mo), Exploratory | |
| `Budget_Range__c` | Picklist | Under $50K, $50K-$250K, $250K-$1M, $1M+, Not Disclosed | |
| `Key_Stakeholders__c` | Long Text Area | 1000 | |
| `Recommended_Clouds__c` | Multi-Select Picklist | Sales Cloud, Service Cloud, Data Cloud, Agentforce, Marketing Cloud, Commerce Cloud, Experience Cloud, Tableau | |
| `Solution_Brief__c` | Long Text Area | 32000 | AI-generated brief lives here |
| `Followup_Email__c` | Long Text Area | 32000 | AI-generated email lives here |
| `Discovery_Status__c` | Picklist | In Progress, Discovery Complete, Brief Generated, Sent to Prospect | Default: In Progress |

After creating all field metadata files, deploy:

```bash
sf project deploy start --source-dir force-app/main/default/objects
```

Then `[HUMAN]`: open the org, navigate to Object Manager → Discovery Session, confirm all fields are present. Report back. Commit: `git commit -am "feat: add Discovery_Session__c with all fields"`.

---

## 6. Actions — `[CLAUDE CODE]`

The agent needs four actions. Build them in this order.

### 6.1 Action: `Create_Discovery_Session` (Flow)

An autolaunched Flow that takes inputs (prospect_name, company_name, industry) and creates a new `Discovery_Session__c` record. Returns the record Id.

Write the Flow XML at `force-app/main/default/flows/Create_Discovery_Session.flow-meta.xml`. Use a simple Create Records element. Inputs are flow variables marked `availableForInput=true`; output the new record Id with `availableForOutput=true`.

### 6.2 Action: `Update_Discovery_Session` (Flow)

Autolaunched Flow with inputs for every editable field on the Discovery Session and a required `recordId` input. Updates the record.

### 6.3 Action: `Generate_Solution_Brief` (Prompt Template + Apex Invocable wrapper)

Two parts:

**Part A — Prompt Template** at `force-app/main/default/genAiPromptTemplates/Generate_Solution_Brief.genAiPromptTemplate-meta.xml`. Type: `Flex`. Input: a `Discovery_Session__c` record. The template body should instruct the LLM to:

> You are a senior Salesforce Solution Engineer. Given the discovery session below, produce a structured Solution Brief with these exact sections:
> 1. **Customer Snapshot** — 2-3 sentences summarizing who they are and what they do.
> 2. **Top Business Challenges** — bulleted, in their language not Salesforce jargon.
> 3. **Recommended Salesforce Solutions** — for each recommended cloud, give: (a) the cloud name, (b) one sentence on what it does, (c) two sentences on the specific business value for THIS prospect tied to THEIR pain points.
> 4. **Why Salesforce vs. Alternatives** — 2-3 sentences of differentiation grounded in their stated needs.
> 5. **Suggested Next Step** — one concrete action (workshop, demo, POC scope).
>
> Use plain language. No fluff. No generic marketing copy. Tie every recommendation to a specific pain point they mentioned.

Merge fields pull from the input record: `{!$Input:DiscoverySession.Industry__c}`, `{!$Input:DiscoverySession.Top_Pain_Point_1__c}`, etc.

**Part B — Apex Invocable Action** at `force-app/main/default/classes/GenerateSolutionBriefAction.cls`. An `@InvocableMethod` that:
1. Accepts a `List<Id>` of Discovery Session record Ids.
2. Calls the prompt template via `ConnectApi.EinsteinLLM` or the Prompt Template invocation API.
3. Writes the returned text into the record's `Solution_Brief__c` field.
4. Updates `Discovery_Status__c` to "Brief Generated".
5. Returns the brief text.

Include a matching `*.cls-meta.xml` with API version 62.0 and status Active.

### 6.4 Action: `Generate_Followup_Email` (Prompt Template only)

Prompt Template at `force-app/main/default/genAiPromptTemplates/Generate_Followup_Email.genAiPromptTemplate-meta.xml`. Takes the Discovery Session record. Instructs the LLM to write a concise (under 200 words) recap email from the SE to the prospect: thanks them for the conversation, summarizes the three pain points in the prospect's own words, names the recommended solutions, proposes a next meeting. Tone: warm, professional, not salesy.

Deploy all actions:

```bash
sf project deploy start --source-dir force-app/main/default
```

`[HUMAN]`: in the org, run a quick sanity check that each Flow and Prompt Template appears in Setup. Confirm.

Commit: `git commit -am "feat: add four agent actions (flows, prompt templates, apex)"`.

---

## 7. Agent Script — `[CLAUDE CODE]`

Generate the authoring bundle skeleton:

```bash
sf agent generate authoring-bundle --name SE_Discovery_Assistant --type internal
```

This creates `force-app/main/default/aiAuthoringBundles/SE_Discovery_Assistant/SE_Discovery_Assistant.agent`.

Replace the file contents with an Agent Script that defines:

- **Agent role/system instructions** describing the SE persona (warm, curious, business-focused; asks one question at a time; never lectures; mirrors the prospect's vocabulary).
- **Three subagents:**

### 7.1 Subagent: `Discovery_Conversation`

Purpose: conduct the discovery interview. Instructions tell it to:
1. Greet the prospect, briefly introduce itself as a Salesforce SE.
2. Call `Create_Discovery_Session` once it has prospect name, company, and industry.
3. Ask one question at a time, in this order: company size → current CRM/tools → top pain point #1 → "what's the impact of that?" → pain point #2 → pain point #3 → decision timeline → budget range → key stakeholders.
4. After each batch of answers, call `Update_Discovery_Session` to persist them.
5. When all fields are captured, set `Discovery_Status__c` to "Discovery Complete" and hand off to `Solution_Recommendation`.
6. Hard rules: never invent answers; if the prospect is vague, ask a follow-up; never recommend products during discovery — that's the next subagent's job.

### 7.2 Subagent: `Solution_Recommendation`

Purpose: generate and present the Solution Brief.
1. Call `Generate_Solution_Brief` action with the current Discovery Session Id.
2. Present the brief in a readable format in the chat.
3. Ask the prospect: "Does this resonate? Anything off?"
4. If they request changes, update the relevant fields on the record and regenerate.
5. When confirmed, hand off to `Followup_Generation`.

### 7.3 Subagent: `Followup_Generation`

Purpose: produce the recap email.
1. Call `Generate_Followup_Email` action.
2. Present the draft in chat.
3. Offer to refine tone (more formal / more casual / shorter).
4. End the conversation with a clear summary of what was captured and next steps.

**Agent Script syntax notes:** Use the v2.0 compiler syntax. Subagents are declared with the `subagent` keyword (not the legacy `topic`). Reference actions via `@actions.<Action_API_Name>`. Use variables for the active Discovery Session Id so it persists across subagents.

After writing the file, validate it compiles:

```bash
sf agent preview --api-name SE_Discovery_Assistant --validate-only
```

Fix any compilation errors before continuing.

Publish to the org:

```bash
sf agent publish authoring-bundle --api-name SE_Discovery_Assistant
```

`[HUMAN]`: open the org → Setup → Agentforce Studio → Agentforce Agents. Confirm `SE_Discovery_Assistant` appears. Open it in the Builder. Confirm three subagents and four actions are wired. Report back.

Commit: `git commit -am "feat: add SE Discovery Assistant agent script with 3 subagents"`.

---

## 8. Permissions — `[CLAUDE CODE]` writes, `[HUMAN]` assigns

Create a permission set `SE_Discovery_Agent_User` at `force-app/main/default/permissionsets/SE_Discovery_Agent_User.permissionset-meta.xml` granting:
- Read/Create/Edit on `Discovery_Session__c` and all its fields
- Apex class access to `GenerateSolutionBriefAction`
- Flow access to `Create_Discovery_Session` and `Update_Discovery_Session`

Deploy: `sf project deploy start --source-dir force-app/main/default/permissionsets`.

`[HUMAN]`: in the org, assign `SE_Discovery_Agent_User` to (a) your own user and (b) the agent user (the user record the agent runs as). Confirm.

Commit: `git commit -am "feat: add agent permission set"`.

---

## 9. Activate the Agent — `[HUMAN]`

In Agentforce Builder:
1. Open `SE_Discovery_Assistant`.
2. Click the Preview panel and run a test message: *"Hi, I'm Sarah from Acme Manufacturing."*
3. Verify the agent greets back, identifies itself as an SE, and asks the next discovery question.
4. If it works, click **Activate** in the top-right.

If the preview fails, copy the error and report back to Claude Code. Common fixes: re-publish the bundle, check action permissions, verify the agent user has the permission set.

---

## 10. Test Scenario — `[BOTH]`

Run this end-to-end scenario in the Preview panel. Claude Code should write this scenario into `DEMO_SCRIPT.md` along with two more personas.

**Persona 1: Mid-market manufacturer**
- Name: Sarah Chen, VP Operations, Acme Industrial Supply
- Industry: Manufacturing, 250 employees
- Current stack: HubSpot CRM + spreadsheets for inventory, separate ticketing in Zendesk
- Pain 1: "Our reps don't know what's in stock when they're on a call with a customer."
- Pain 2: "We have no idea which accounts are about to churn."
- Pain 3: "Service tickets and sales accounts are in different systems, so the CSM finds out about issues from the customer instead of from us."
- Timeline: 3-6 months
- Budget: $250K-$1M

**Expected agent behavior:**
- Captures all fields in the Discovery Session record.
- Recommends: Sales Cloud (unified account view), Service Cloud (ticket integration), Data Cloud (churn signals across systems), possibly Agentforce (proactive CSM alerts).
- Solution Brief ties each recommendation to one of Sarah's three quoted pain points.
- Follow-up email is under 200 words and uses Sarah's actual language.

**Pass criteria:** record is created, all fields populate, brief addresses all three pains by name, email is reasonable. If any of those fail, debug before the demo.

Add two more personas to `DEMO_SCRIPT.md`: a B2B SaaS company and a healthcare nonprofit. Different industries force the agent to make different recommendations, which proves the demo isn't canned.

---

## 11. Demo Script — `[CLAUDE CODE]` writes, `[HUMAN]` rehearses

Populate `DEMO_SCRIPT.md` with:

1. **30-second opener** — what you built and why. Example beats: "I wanted to actually try the SE job before applying. So I built an Agentforce agent that runs early-stage discovery and produces a solution brief — using the same platform Salesforce sells. Want to see it?"
2. **Live demo flow** (3-4 minutes) — talk track for running Persona 1 in Preview while narrating.
3. **What I learned** (1 minute) — three honest reflections: e.g., "discovery is harder than it looks — the questions are easy, but knowing when to dig deeper requires judgment the LLM doesn't have yet"; "Agentforce's deterministic Agent Script is a real differentiator vs. pure-LLM agents because in B2B sales you cannot have an agent hallucinating product capabilities"; "I'd love to wire this to Data Cloud next so the agent can pull real account context before the call."
4. **Where I'd take it next** (30 seconds) — multi-agent: a discovery agent + a competitive-intel agent + a pricing agent coordinated by a supervisor.
5. **Backup plan** if the live demo fails — a recorded screen video at `/demo/se-discovery-walkthrough.mp4` (the human will record this separately) and screenshots in `/demo/screenshots/`.

---

## 12. Final Checklist Before the Interview — `[HUMAN]`

- [ ] Run all three personas in Preview the day before. All pass.
- [ ] Record a 3-minute screen video of the best run. Save it.
- [ ] Take screenshots of: the Agent Builder canvas, a completed Discovery Session record, a generated Solution Brief, the follow-up email.
- [ ] Push the repo to GitHub (private). Have the URL ready in case the interviewer asks to see code.
- [ ] Practice the talk track out loud 3 times.
- [ ] Charge laptop. Test screen-share. Have a hotspot ready in case office wifi is slow.

---

## 13. Working Norms for Claude Code

- After each numbered phase (§4, §5, §6, §7, §8), stop and summarize what was done. Wait for the human to confirm any UI verification step before moving on.
- When writing Agent Script, prefer clarity over cleverness — the human will need to read and explain it in the interview.
- When writing Apex, include doc comments explaining what each method does in plain English. The human will be asked about this code.
- If a CLI command fails, do not retry blindly. Read the error, propose a fix, ask the human to confirm before re-running.
- Commit after every meaningful unit of work with conventional commit messages (`feat:`, `fix:`, `chore:`, `docs:`).
- If anything in this spec is ambiguous or out of date relative to the current Agentforce release the human is on, ask before guessing. The Salesforce platform changes fast; metadata structures, the `topic`→`subagent` rename, and CLI command names have all shifted in 2025-2026.

---

## 14. Reference Links

- Agentforce Developer Guide: https://developer.salesforce.com/docs/ai/agentforce/guide/get-started.html
- Agentforce DX Guide: https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx.html
- Agent Script Language: https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-lang.html
- Agent Metadata Reference: https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html
- Trailhead — Agentforce Builder Basics: https://trailhead.salesforce.com/content/learn/modules/agent-builder-basics
- Trailhead — Build an Agent Using Agentforce DX: https://trailhead.salesforce.com/content/learn/projects/create-an-agent-using-pro-code-tools

---

**End of spec.** Begin with §3 (verify human prerequisites) and proceed in order.
