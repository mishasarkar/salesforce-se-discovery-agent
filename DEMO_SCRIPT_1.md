# Demo Script 1 — How to Run the Demo
### SE Discovery Assistant · Agentforce Agent
> **Who is presenting:** A fresh college grad showing Salesforce interviewers what they built.
> **Tone:** Confident, conversational, enthusiastic — like you're showing a friend something really cool you made.

---

## Before You Start — Setup Checklist

Open these three things in separate browser tabs **before** the interview begins:

| Tab | What to open | Why |
|-----|-------------|-----|
| 1 | Agentforce Builder → SE Discovery Assistant → **Preview** | This is where the demo lives |
| 2 | Salesforce App → **Discovery Sessions** object | To show the record being created live |
| 3 | This script | So you never lose your place |

> 💡 **Pro tip:** Do a full dry run the night before. The agent occasionally skips a question — know where those gaps are so you can bridge them naturally.

---

## The Story You're Telling

> *"I built an AI agent that helps a Salesforce Solution Engineer run a structured discovery call — automatically. The agent asks the right questions, saves everything to Salesforce, writes a Solution Brief using AI, and drafts the follow-up email. What used to take 2-3 hours now takes one conversation."*

Keep that one sentence in your head. Everything you show ties back to it.

---

## Demo Flow

```
START
  │
  ▼
[1] Introduce the persona (30 sec)
  │
  ▼
[2] Run the discovery conversation (3-4 min)
  │
  ▼
[3] Show the live Salesforce record (30 sec)
  │
  ▼
[4] Generate the Solution Brief (1 min)
  │
  ▼
[5] Generate the Follow-Up Email (1 min)
  │
  ▼
[6] Wrap up and invite questions (30 sec)
```

**Total time: ~7 minutes**

---

## Step 1 — Introduce the Persona (30 seconds)

**Say this out loud:**

> *"I'm going to demo this as Sarah Chen, a VP of Sales at Acme Manufacturing. She's interested in Salesforce but hasn't committed yet. Watch how the agent guides the entire discovery — one question at a time."*

Then click into the **Preview** panel. You'll see the welcome message from Alex the agent.

---

## Step 2 — Run the Discovery Conversation

Type each message below **exactly as shown**. After each agent response, read the **What to say** line out loud to the interviewers before typing the next one.

---

### Opening

**You type:**
```
Hi, I'm Sarah Chen from Acme Manufacturing
```

**Agent will ask:** How many employees?

**What to say:**
> *"Notice the agent already picked up the name and company — it didn't ask twice. It's one question at a time, just like a real SE would run a call."*

---

### Company Size

**You type:**
```
51-250
```

**Agent will ask:** What CRM and tools do you use?

---

### Current Tools

**You type:**
```
HubSpot and spreadsheets
```

**Agent will ask:** What is your biggest challenge?

**What to say:**
> *"This is the key moment in any discovery — getting to the real pain. The agent knows to ask for challenges before jumping to solutions."*

---

### Pain Point 1

**You type:**
```
We can't tell which deals are at risk until it's too late
```

**Agent will ask:** What's the business impact?

---

### Business Impact

**You type:**
```
We estimate we're losing about 20% of pipeline because we don't catch at-risk deals in time
```

**Agent will ask:** What is your second biggest challenge?

---

### Pain Point 2

**You type:**
```
Our sales reps spend too much time on manual data entry instead of actually selling
```

**Agent will ask:** Third challenge? *(or may ask for timeline — either is fine)*

---

### Pain Point 3 *(if asked)*

**You type:**
```
We have no visibility into customer data across our different systems
```

---

### Decision Timeline

**You type:**
```
Near-term, about 3 to 6 months
```

---

### Budget

**You type:**
```
$250K to $1M
```

---

### Stakeholders

**You type:**
```
VP of Sales John Smith and CIO Lisa Park
```

---

### Wrap Up Discovery

**What to say:**
> *"Now watch — I'm going to tell the agent we're done and ask for the Solution Brief."*

**You type:**
```
That's everything. Can you generate my Solution Brief now?
```

---

## Step 3 — Show the Live Salesforce Record (30 seconds)

**Switch to Tab 2** (Discovery Sessions).

Refresh the page and open the most recent record.

**What to say:**
> *"While the agent was having that conversation with Sarah, it was automatically creating and updating this Salesforce record in the background. Every answer she gave is saved here — pain points, timeline, budget, stakeholders. No manual data entry. No copy-pasting from notes."*

Point to the fields on the record — Top Pain Point 1, 2, 3, Decision Timeline, Budget Range.

**Switch back to Tab 1.**

---

## Step 4 — Generate the Solution Brief (1 minute)

The agent should now be generating or displaying the Solution Brief.

**What to say:**
> *"The agent is now calling a custom Apex action I built. That action sends this Discovery Session record to a prompt template — think of it like giving a very specific briefing document to ChatGPT — and it comes back with a full, tailored Solution Brief. This isn't a generic pitch deck. It's written specifically for Sarah's three pain points."*

Let the brief display fully. Read one section out loud (Customer Snapshot or Top Business Challenges works well).

**What to say:**
> *"See how it uses Sarah's exact words — 'losing 20% of pipeline,' 'manual data entry.' It doesn't Salesforce-ify her language. That's because I told the AI to mirror the customer's vocabulary in the prompt."*

---

## Step 5 — Generate the Follow-Up Email (1 minute)

**You type:**
```
This looks great. Can you draft the follow-up email now?
```

**What to say:**
> *"The third and final piece — the recap email. The agent calls a Prompt Template I configured that takes everything from the Discovery Session — the pain points, the recommended solutions, the timeline — and writes a warm, professional email. Under 200 words, no fluff."*

Let the email display. Point out the Subject line.

**What to say:**
> *"And notice — it starts with a suggested subject line, thanks Sarah for something specific, and ends with a concrete next step. Not just 'let me know if you have questions.'"*

---

## Step 6 — Wrap Up (30 seconds)

**What to say:**
> *"So what we just saw in about five minutes: the agent ran a full discovery, captured everything in Salesforce, generated a tailored AI brief, and drafted a follow-up email. For a real SE, that's prep work that normally takes 2-3 hours after the call.*
>
> *I built this entirely on Salesforce — Agentforce for the agent, Apex for the AI integration, Flows for the data capture, and Prompt Builder for the AI writing. Everything lives in one org, connected together.*
>
> *Happy to dig into any piece of this — the agent config, the Apex code, the prompt design, or the data model."*

---

## If Something Goes Wrong

| Problem | What to do |
|---------|-----------|
| Agent repeats a question | Just answer again — say *"The agent occasionally re-asks — in a production build I'd tighten the instructions further."* |
| Brief generation fails | Say *"Let me trigger that directly"* and open the Discovery Session record → run the Apex action manually if needed |
| Agent doesn't transition topics | Say *"Great, let's move to the Solution Brief"* to nudge it |
| Record fields are empty | Say *"The record is created — in a live build the update frequency can be tuned"* |

---

## One-Line Summary to Close With

> *"This is a fully functional Agentforce agent — built from scratch — that turns a discovery call into a Salesforce record, an AI brief, and a ready-to-send email. No manual work. No lost notes."*
