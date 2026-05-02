# SE Discovery Agent

An Agentforce agent that role-plays a Salesforce Solution Engineer running early-stage discovery with a prospect.

## What It Does

1. Conducts a structured discovery interview (pain points, stack, timeline, budget)
2. Captures answers in a custom `Discovery_Session__c` object
3. Generates a tailored Solution Brief mapping the prospect's needs to Salesforce clouds
4. Drafts a follow-up recap email in the SE's voice

Built as an interview demo for a Salesforce Solution Engineer (Early Career) role.

## Project Structure

```
force-app/main/default/
├── objects/Discovery_Session__c/     # Custom object + 15 fields
├── classes/                          # Apex invocable actions
├── flows/                            # Autolaunched flows for agent actions
├── genAiPromptTemplates/             # LLM prompt templates
├── aiAuthoringBundles/               # Agent Script (SE_Discovery_Assistant)
└── permissionsets/                   # SE_Discovery_Agent_User permission set
```

## Build Spec

See [AGENTFORCE_BUILD_SPEC.md](./AGENTFORCE_BUILD_SPEC.md) for the full specification, phase-by-phase build plan, and demo script guidance.

## Demo Script

See [DEMO_SCRIPT.md](./DEMO_SCRIPT.md) for the interview talk track and three pre-rehearsed prospect personas.

## Prerequisites

- Salesforce Developer Edition org with Agentforce enabled
- Salesforce CLI (`sf`) with `@salesforce/plugin-agent`
- Node.js 20+

## Deploy

```bash
sf project deploy start --source-dir force-app/main/default
```
