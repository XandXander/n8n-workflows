# Architecture Decision Register — OSINT Platform

> **Status:** APPROVED  
> **Version:** 1.0  
> **Decision authority:** Principal Architect  
> **Repository SSOT:** `XandXander/n8n-workflows`  
> **Workflow JSON baseline:** `8420e423c98dcb1d11fa02f554e0674b9705bb81`  
> **WORKFLOW_MAP baseline:** `ad9e9b92c7d76f76154d4b322f829c70ff1597e1`  
> **ARCHITECTURE baseline:** `ef1abcf42293c67dae068efe88e8b41a15cd9059`  
> **ENVIRONMENT baseline:** `577ff1c47b192451cc4039e9c99b3daed710d8bc`  
> **Compatibility baseline:** n8n 2.32.7  
> **Current filename:** `docs/DECISIONS_DRAFT.md`  
> **Canonical filename after separate approved rename:** `docs/DECISIONS.md`  
> **Last updated:** 2026-08-03

* * *

## 1. Purpose

This document is the canonical register of architectural and engineering decisions for the OSINT Platform.
An ADR records:

*   the context requiring a decision;
    
*   the selected rule or architecture;
    
*   its status;
    
*   affected components;
    
*   implementation evidence;
    
*   consequences;
    
*   related decisions.
    

This document does not replace:

*   `ERROR_HISTORY_DRAFT.md`;
    
*   technical-debt tracking;
    
*   runtime logs;
    
*   `WORKFLOW_MAP.md`;
    
*   `ARCHITECTURE.md`;
    
*   `ENVIRONMENT.md`;
    
*   implementation specifications.
    

Incidents, defects, observations and functional hypotheses are not ADRs.

* * *

## 2. Evidence Model

| Evidence class | Meaning |
| --- | --- |
| `CONFIRMED BY JSON` | Directly supported by canonical workflow JSON |
| `CONFIRMED BY APPROVED DOCUMENT` | Supported by an approved canonical project document |
| `CONFIRMED BY LIVE DATA` | Supported by current server or runtime evidence |
| `CONFIRMED BY LOGS` | Supported by sanitized execution or infrastructure logs |
| `UNKNOWN` | Current evidence does not establish the statement |
| `CONFLICT` | Confirmed representations are incompatible |

A dependency configured in workflow JSON is not automatically runtime-available.
GitHub presence does not prove active or published state.

* * *

## 3. ADR Status Model

| Status | Meaning |
| --- | --- |
| `PROPOSED` | Decision is formally proposed but not accepted |
| `ACCEPTED` | Decision is approved and governs future or current work |
| `IMPLEMENTED` | Decision is approved and represented in canonical repository artifacts |
| `PARTIAL` | Only part of the accepted or claimed decision is represented |
| `SUPERSEDED` | Replaced by another decision |
| `REJECTED` | Considered and not adopted |
| `REQUIRES VERIFICATION` | Decision claim depends on missing live or log evidence |
| `UNKNOWN` | Acceptance or implementation cannot be established from the evidence baseline |

`IMPLEMENTED` does not prove runtime availability or end-to-end success.
Related ERR identifiers are not canonicalized in this revision because the error journal is outside the current audit scope.

* * *

## 4. Decision Index

| ADR | Decision | Status | Components |
| --- | --- | --- | --- |
| ADR-001 | Eight-workflow modular architecture | IMPLEMENTED | WF1–WF8 |
| ADR-002 | DeepSeek model allocation | IMPLEMENTED | WF1, WF3, WF4, WF5, WF6 |
| ADR-003 | Google Sheets operational state boundary | IMPLEMENTED | WF1–WF6, WF8 |
| ADR-004 | Execute Workflow communication model | IMPLEMENTED | WF1–WF8 |
| ADR-005 | HTTP response preservation with Put Output in Field | PARTIAL | WF2 |
| ADR-006 | Gotenberg HTML-to-PDF service | PARTIAL | WF6, WF8 |
| ADR-007 | `prepareBinaryData` for Gotenberg HTML input | IMPLEMENTED | WF6 |
| ADR-008 | Sandbox-safe canonical Code-node patterns | IMPLEMENTED | WF1–WF8 |
| ADR-009 | n8n Public API v1 for workflow updates | IMPLEMENTED | `n8n_workflow_manager` |
| ADR-010 | Sanitized PUT update contract | IMPLEMENTED | `n8n_workflow_manager` |
| ADR-011 | DeepSeek retry and timeout policy | PARTIAL | WF1, WF3, WF4, WF5, WF6 |
| ADR-012 | Firecrawl bypass for protected targets | UNKNOWN | WF2 |
| ADR-013 | Serper queries without `site:` operator | IMPLEMENTED | WF2, WF3, WF4 |
| ADR-014 | Jina embeddings and Pinecone vector facade | IMPLEMENTED | WF2, WF3, WF4, WF7 |
| ADR-015 | Filesystem binary-data mode | REQUIRES VERIFICATION | n8n runtime |
| ADR-016 | Always Output Data for entity reads | IMPLEMENTED | WF5, WF6 |
| ADR-017 | IMAP post-processing policy | UNKNOWN | WF1 |
| ADR-018 | Open WebUI and DeepSeek development context | UNKNOWN | Development process |
| ADR-019 | Manual subworkflow test harness | UNKNOWN | WF2 |
| ADR-020 | Blanket ban on dynamic Sheet Name expressions | REJECTED | WF5, WF6 |
| ADR-021 | Convert to File for Gotenberg input | SUPERSEDED | WF6 |
| ADR-022 | Google AI Studio and Gemini platform integration | UNKNOWN | External tooling |
| ADR-023 | Groq retry and error policy | PARTIAL | WF8 |
| ADR-024 | Workflow JSON artifact profiles | ACCEPTED | Workflow JSON, standards, deployment tooling |

* * *

# ADR-001 — Eight-Workflow Modular Architecture

**Status:** IMPLEMENTED  
**Affected components:** WF1–WF8  
**Evidence:** CONFIRMED BY JSON; CONFIRMED BY APPROVED DOCUMENT

## Context

The platform separates ingestion, search, enrichment, scoring, reporting, vector operations and utility operations.

## Decision

Maintain eight canonical workflows with responsibilities defined in `WORKFLOW_MAP.md`.
Inter-workflow processing uses:

*   Execute Workflow nodes;
    
*   Google Sheets for shared operational state;
    
*   WF7 as the Pinecone and Jina facade.
    

## Implementation evidence

Eight canonical workflow JSON files exist and their caller/callee graph is documented.

## Consequences

Positive:

*   isolated workflow responsibilities;
    
*   explicit workflow boundaries.
    

Negative:

*   cross-workflow contracts require strict synchronization;
    
*   asynchronous execution complicates end-to-end verification.
    

* * *

# ADR-002 — DeepSeek Model Allocation

**Status:** IMPLEMENTED  
**Affected components:** WF1, WF3, WF4, WF5, WF6  
**Evidence:** CONFIRMED BY JSON

## Context

Different LLM operations use different DeepSeek models.

## Decision

Use:
| Workflow | Function | Model |
| --- | --- | --- |
| WF1 | Intent classification | `deepseek-v4-flash` |
| WF3 | Company analysis | `deepseek-v4-pro` |
| WF4 | Tender analysis | `deepseek-v4-flash` |
| WF5 | Entity scoring | `deepseek-v4-pro` |
| WF6 | Report generation | `deepseek-v4-pro` |

## Implementation evidence

The model names are present in canonical HTTP Request node bodies.

## Consequences

The repository contains the selected model allocation.
Provider availability, model availability and successful execution remain runtime concerns.

* * *

# ADR-003 — Google Sheets Operational State Boundary

**Status:** IMPLEMENTED  
**Affected components:** WF1, WF2, WF3, WF4, WF5, WF6, WF8  
**Evidence:** CONFIRMED BY JSON; CONFIRMED BY APPROVED DOCUMENT

## Decision

Use Google Sheets as the shared operational state boundary.
| Sheet | Writer | Readers or updaters |
| --- | --- | --- |
| `jobs` | WF1 | WF6 |
| `leads` | WF2 | WF5, WF6 |
| `companies` | WF3 | WF5, WF6 |
| `tenders` | WF4 | WF5, WF6 |
| `reports` | WF6 | None confirmed |
| `logs` | WF8 | None confirmed |

`job_id` is the primary cross-workflow correlation field.

## Consequences

Positive:

*   transparent operational state;
    
*   direct inspection of workflow outputs.
    

Constraints:

*   runtime quota and schema validity require separate evidence;
    
*   Google Sheets is not treated as a transactional database.
    

* * *

# ADR-004 — Execute Workflow Communication Model

**Status:** IMPLEMENTED  
**Affected components:** WF1–WF8  
**Evidence:** CONFIRMED BY JSON; CONFIRMED BY APPROVED DOCUMENT

## Decision

Use native Execute Workflow nodes for all confirmed inter-workflow calls.
Synchronous calls:

*   WF1 → WF8 for STT;
    
*   WF2 → WF7;
    
*   WF3 → WF7;
    
*   WF4 → WF7.
    

Asynchronous calls:

*   WF1 → WF2, WF3, WF4 and WF5;
    
*   WF2, WF3 and WF4 → WF5;
    
*   WF5 → WF6.
    

## Consequences

Synchronous calls provide immediate operation results.
Asynchronous calls require persistence-based coordination and do not prove downstream completion.

* * *

# ADR-005 — HTTP Response Preservation with Put Output in Field

**Status:** PARTIAL  
**Affected components:** WF2  
**Evidence:** CONFIRMED BY JSON; CONFLICT

## Decision

Preserve HTTP response data in dedicated fields:

*   Serper → `serperResult`;
    
*   Firecrawl → `firecrawlResult`.
    

## Implementation evidence

Both HTTP nodes configure `putOutputInField`.

## Partial implementation

*   Firecrawl downstream handling reads `firecrawlResult`.
    
*   Serper `Extract URLs` reads root-level `organic`.
    
*   Context recovery still uses `$items(..., $runIndex)` and `.item` fallback.
    

## Consequences

The node-level response-preservation mechanism exists, but the full downstream contract is not consistently implemented.

* * *

# ADR-006 — Gotenberg HTML-to-PDF Service

**Status:** PARTIAL  
**Affected components:** WF6, WF8  
**Evidence:** CONFIRMED BY JSON; UNKNOWN runtime version

## Decision

Use the Gotenberg-compatible internal endpoint:

```text
http://gotenberg:3000/forms/chromium/convert/html
```

for HTML-to-PDF conversion.

## Implementation evidence

WF6 and WF8 contain HTTP Request nodes using this endpoint.

## Unverified portion

The evidence baseline does not establish:

*   Docker image tag;
    
*   major version;
    
*   container health;
    
*   successful runtime conversion.
    

The historical claim `gotenberg/gotenberg:8` is not canonicalized.

* * *

# ADR-007 — `prepareBinaryData` for Gotenberg Input

**Status:** IMPLEMENTED  
**Affected components:** WF6  
**Evidence:** CONFIRMED BY JSON  
**Supersedes:** ADR-021

## Decision

Use:

```javascript
await this.helpers.prepareBinaryData(html, 'index.html', 'text/html')
```

to create the HTML binary expected by Gotenberg.

## Implementation evidence

WF6 `Create HTML Binary` implements this pattern.

## Consequences

The workflow no longer relies on the superseded Convert to File approach.

* * *

# ADR-008 — Sandbox-Safe Canonical Code Patterns

**Status:** IMPLEMENTED  
**Affected components:** Canonical workflow Code nodes  
**Evidence:** CONFIRMED BY JSON

## Decision

Canonical workflow code uses:

*   `prepareBinaryData` instead of `Buffer.from()` for report binary preparation;
    
*   `Math.random()` and timestamp-based identifiers instead of `crypto.randomUUID()`;
    
*   `new Date().toISOString()` instead of `$now.format()`.
    

## Scope

This decision describes canonical repository code.
It does not independently establish global n8n sandbox configuration.

* * *

# ADR-009 — n8n Public API v1 for Workflow Updates

**Status:** IMPLEMENTED  
**Affected components:** `n8n_workflow_manager`  
**Evidence:** CONFIRMED BY APPROVED DOCUMENT  
**Related:** ADR-010, ADR-024

## Decision

Use n8n Public API v1 for existing-workflow updates.

```text
PUT https://xandai.ru/api/v1/workflows/{workflow_id}
```

Use authorization header name:

```text
X-N8N-API-KEY
```

The header value must never be documented.
The internal `/rest/workflows` route is not part of the approved deployment pipeline.

* * *

# ADR-010 — Sanitized PUT Update Contract

**Status:** IMPLEMENTED  
**Affected components:** `n8n_workflow_manager`  
**Evidence:** CONFIRMED BY APPROVED DOCUMENT  
**Related:** ADR-009, ADR-024

## Decision

For an existing workflow:

1.  Read `workflow_id` from Profile A root `id`.
    
2.  Stop if root `id` is missing.
    
3.  Use root `id` in the PUT endpoint.
    
4.  Remove from the request body:
    

```text
id
versionId
active
createdAt
updatedAt
shared
tags
triggerCount
pinData
meta
```

5.  Preserve existing `nodes[].id`.
    
6.  Preserve credentials.
    
7.  Do not modify automatic credential substitution.
    
8.  Commit and push only after a successful PUT when changes exist.
    

## Consequences

A Git commit alone is not deployment evidence.

* * *

# ADR-011 — DeepSeek Retry and Timeout Policy

**Status:** PARTIAL  
**Affected components:** WF1, WF3, WF4, WF5, WF6  
**Evidence:** CONFIRMED BY JSON

## Current implementation

| Workflow | Timeout | Retry configuration |
| --- | --- | --- |
| WF1 | 45 seconds | 3 attempts, 5-second wait |
| WF3 | 120 seconds | 3 attempts, 2-second wait |
| WF4 | 120 seconds | 3 attempts, 2-second wait |
| WF5 | 120 seconds | 3 attempts, 5-second wait |
| WF6 | 120 seconds | Retry fields absent |

## Decision state

Retry behavior is implemented for WF1, WF3, WF4 and WF5.
A unified policy covering WF6 is not implemented.

* * *

# ADR-012 — Firecrawl Bypass for Protected Targets

**Status:** UNKNOWN  
**Affected components:** WF2  
**Evidence:** CONFLICT

## Historical claim

Firecrawl should be bypassed for Avito, Telegram, Profi and Zakupki targets.

## Current evidence

Canonical WF2 sends URL items passing `Filter Empty` to `Firecrawl Scrape`.
No protected-domain bypass is present.

## Decision

This historical claim is not an active canonical decision.
It must not be described as implemented without new evidence or a separate approved change.

* * *

# ADR-013 — Serper Queries without `site:` Operator

**Status:** IMPLEMENTED  
**Affected components:** WF2, WF3, WF4  
**Evidence:** CONFIRMED BY JSON

## Decision

Canonical Serper queries do not depend on the `site:` search operator.

## Implementation evidence

No current query template contains `site:`.

## Scope

The historical explanation that a particular tariff blocks `site:` is not included because it is not established by the evidence baseline.

* * *

# ADR-014 — Jina Embeddings and Pinecone Vector Facade

**Status:** IMPLEMENTED  
**Affected components:** WF2, WF3, WF4, WF7  
**Evidence:** CONFIRMED BY JSON

## Decision

Use WF7 as the vector-operation facade.
Embedding configuration:

```text
model: jina-embeddings-v3
dimensions: 1024
upsert task: retrieval.passage
query task: retrieval.query
```

Operations:

*   `upsert`;
    
*   `query`;
    
*   `delete`.
    

Current caller namespaces:

*   `leads`;
    
*   `companies`;
    
*   `tenders`.
    

## Consequences

Only WF2 performs query-before-upsert deduplication.
WF3 and WF4 perform upsert without a prior query.
Runtime index availability remains UNKNOWN.

* * *

# ADR-015 — Filesystem Binary-Data Mode

**Status:** REQUIRES VERIFICATION  
**Affected components:** n8n runtime  
**Evidence:** UNKNOWN

## Historical claim

The n8n global binary-data mode is configured as filesystem.

## Current evidence

Approved `ENVIRONMENT.md` classifies:

*   global Binary Data Mode;
    
*   binary data path;
    

as `UNKNOWN`.

## Decision state

No implementation claim is accepted until read-only runtime evidence is available.
This evidence debt does not alter WF6 binary preparation logic.

* * *

# ADR-016 — Always Output Data for Entity Reads

**Status:** IMPLEMENTED  
**Affected components:** WF5, WF6  
**Evidence:** CONFIRMED BY JSON

## Decision

Enable `alwaysOutputData: true` on:

*   WF5 `Read Entities`;
    
*   WF6 `Read Qualified Entities`.
    

## Consequences

The nodes are configured to emit data even when the underlying read returns no normal rows.
Exact empty-result runtime behavior remains subject to execution evidence.

* * *

# ADR-017 — IMAP Post-Processing Policy

**Status:** UNKNOWN  
**Affected components:** WF1  
**Evidence:** CONFLICT

## Historical claim

IMAP uses:

```text
postProcessAction: read
```

for one-time processing.

## Current evidence

Canonical WF1 confirms:

```text
customEmailConfig: ["UNSEEN"]
forceReconnect: 60
```

`postProcessAction` is absent.

## Decision

Mark-as-read behavior is not a canonical implemented decision.

* * *

# ADR-018 — Open WebUI and DeepSeek Development Context

**Status:** UNKNOWN  
**Affected components:** Development process  
**Evidence:** UNKNOWN

## Historical claim

Open WebUI with DeepSeek is the principal development context.

## Decision state

This process claim is not established by the allowed GitHub evidence baseline.
It does not govern runtime architecture or workflow behavior in the canonical register.

* * *

# ADR-019 — Manual Subworkflow Test Harness

**Status:** UNKNOWN  
**Affected components:** WF2  
**Evidence:** CONFLICT

## Historical claim

WF2 contains a Manual Trigger and Code node for isolated subworkflow testing.

## Current evidence

Canonical WF2 begins with an Execute Workflow Trigger.
No Manual Trigger is present.

## Decision

The historical test pattern is not part of the current canonical workflow.

* * *

# ADR-020 — Blanket Ban on Dynamic Sheet Name Expressions

**Status:** REJECTED  
**Affected components:** WF5, WF6  
**Evidence:** CONFIRMED BY JSON; CONFLICT with historical claim

## Rejected proposal

Require every Google Sheets `sheetName` to be a static literal.

## Rationale for rejection

WF5 and WF6 select `leads`, `companies` or `tenders` dynamically from `entity_type`.
A blanket prohibition is incompatible with the approved architecture.

## Current rule

*   fixed-purpose Google Sheets nodes may use static names;
    
*   dynamic entity-table selection is permitted where explicitly documented;
    
*   runtime correctness remains a separate verification concern.
    

* * *

# ADR-021 — Convert to File for Gotenberg Input

**Status:** SUPERSEDED  
**Affected components:** WF6  
**Superseded by:** ADR-007  
**Evidence:** CONFIRMED BY JSON

## Historical decision

Use Convert to File for HTML preparation.

## Current decision

ADR-007 replaces this approach with `prepareBinaryData`.
Convert to File is not part of the current WF6 path.

* * *

# ADR-022 — Google AI Studio and Gemini Integration

**Status:** UNKNOWN  
**Affected components:** External tooling  
**Evidence:** UNKNOWN

## Historical claim

Google AI Studio is an implemented platform integration for Gemini access.

## Current evidence

No canonical workflow contains a Gemini or Google AI Studio integration.

## Decision

The claim is not part of the active OSINT Platform architecture.
Absence of integration does not independently prove formal rejection.

* * *

# ADR-023 — Groq Retry and Error Policy

**Status:** PARTIAL  
**Affected components:** WF8  
**Evidence:** CONFIRMED BY JSON; CONFLICT with historical scope

## Historical decision

Do not retry Groq 429 failures and use `continueRegularOutput`.

## Current implementation

The confirmed Groq caller is WF8 `Groq Whisper STT`.
For that node:

*   retry configuration is absent;
    
*   `onError: continueRegularOutput` is absent.
    

## Decision state

The no-explicit-retry portion is represented.
The claimed error-continuation policy and affected workflows are not represented.
Runtime 429 behavior remains UNKNOWN.

* * *

# ADR-024 — Workflow JSON Artifact Profiles

**Decision status:** ACCEPTED  
**Implementation scope:** COMPLETE  
**Architectural block:** CLOSED  
**Affected components:** Workflow JSON, `n8n_workflow_manager`, standards  
**Evidence:** CONFIRMED BY APPROVED DOCUMENT  
**Related:** ADR-009, ADR-010  
**Compatibility baseline:** n8n 2.32.7

## Decision

| Profile | Purpose | Status |
| --- | --- | --- |
| Profile A | GitHub canonical workflow | APPROVED |
| Profile B | POST/create payload | NOT IMPLEMENTED |
| Profile C | Sanitized PUT update payload | APPROVED |
| Profile D | Server response/export | REQUIRES EVIDENCE — NON-BLOCKING |

### Profile A

For an existing workflow:

*   root `id` is required and occurs exactly once;
    
*   duplicate JSON keys are forbidden;
    
*   `nodes[].id` uses `PRESERVE IF PRESENT`;
    
*   missing node IDs are allowed;
    
*   existing node IDs remain unchanged;
    
*   node IDs are opaque strings;
    
*   credentials remain unchanged;
    
*   sanitation is required before update.
    

### Profile B

POST/create contract is not implemented.
Profile C must not be reused for create without a separate ADR.

### Profile C

*   method: PUT;
    
*   workflow ID comes from Profile A root `id`;
    
*   root `id` is removed from body;
    
*   approved root blacklist is removed;
    
*   existing `nodes[].id` is preserved;
    
*   credentials and automatic substitution remain unchanged;
    
*   unknown fields are not removed without evidence.
    

### Profile D

Profile D requires read-only evidence on n8n 2.32.7.
It does not block:

*   Profile A;
    
*   Profile C;
    
*   the current update pipeline;
    
*   canonical documentation;
    
*   engineering work on existing workflows.
    

## Implementation evidence

Completed in commit:

```text
8420e423c98dcb1d11fa02f554e0674b9705bb81
```

Implemented artifacts include:

*   `docs/standards/n8n_schema.md`;
    
*   `docs/standards/node_templates.md`;
    
*   architecture synchronization;
    
*   ADR registration;
    
*   duplicate root-ID correction in WF6.
    

* * *

## 5. Superseded and Rejected Decisions

| ADR | Status | Resolution |
| --- | --- | --- |
| ADR-020 | REJECTED | Blanket static-sheet-name rule conflicts with canonical dynamic routing |
| ADR-021 | SUPERSEDED | Replaced by ADR-007 |

No other rejected alternative is canonicalized in this revision.

* * *

## 6. Open Decisions

### OPEN-DEC-001 — Unified Job and Entity Lifecycle

A future ADR is required to define:

*   valid job statuses;
    
*   valid entity statuses;
    
*   terminal outcomes;
    
*   transition rules;
    
*   handling of `partial`, `no_results` and `failed`.
    

### OPEN-DEC-002 — Unified Provider Failure Policy

A future ADR may define consistent:

*   retry;
    
*   timeout;
    
*   backoff;
    
*   `onError`;
    
*   partial-result handling;
    

for all external providers.

### OPEN-DEC-003 — Tavily Role in Tender Search

A future ADR may define whether Tavily is:

*   mandatory;
    
*   fallback;
    
*   supplementary;
    
*   removable without changing WF4 semantics.
    

No new ADR is created by this document.

* * *

## 7. Non-Blocking Evidence Debt

*   Profile D server response and export;
    
*   n8n Binary Data Mode;
    
*   Gotenberg image and runtime version;
    
*   active or published workflow states;
    
*   external-provider availability;
    
*   credential validity;
    
*   Open WebUI development-process claim;
    
*   Google AI Studio and Gemini usage;
    
*   current runtime and log evidence.
    

* * *

## 8. Technical Debt and Conflicts — Not ADRs

The following are not architectural decisions:

*   WF1 → WF2 missing `intent`;
    
*   WF1 → WF3 serialized `entities` versus object access;
    
*   direct `site_analysis` contract;
    
*   WF2 `serperResult` consumer mismatch;
    
*   WF6 qualification semantics;
    
*   `$items(..., $runIndex)` context recovery;
    
*   inconsistent retry configuration;
    
*   unverified loop input indexes;
    
*   unverified Gotenberg Telegram output index.
    

These items require separate ERR, technical specification or runtime evidence.

* * *

## 9. Evidence Classification

### CONFIRMED BY JSON

*   eight-workflow architecture;
    
*   exact DeepSeek model allocation;
    
*   Google Sheets storage map;
    
*   Execute Workflow graph;
    
*   Jina and Pinecone configuration;
    
*   Gotenberg endpoint;
    
*   `prepareBinaryData`;
    
*   workflow-level retry settings;
    
*   `alwaysOutputData`;
    
*   current IMAP options;
    
*   dynamic sheet selection;
    
*   current Groq caller.
    

### CONFIRMED BY APPROVED DOCUMENT

*   GitHub SSOT;
    
*   caller and callee contracts;
    
*   deployment contract;
    
*   workflow JSON Profiles A–D;
    
*   people verification not implemented;
    
*   active and published state UNKNOWN;
    
*   runtime-environment evidence boundaries.
    

### CONFIRMED BY LIVE DATA

*   n8n version 2.32.7.
    

### CONFIRMED BY LOGS

*   none in the current evidence baseline.
    

### UNKNOWN

*   Binary Data Mode;
    
*   Gotenberg image version;
    
*   protected-target bypass decision;
    
*   Open WebUI process decision;
    
*   Gemini and Google AI Studio usage;
    
*   active or published state;
    
*   runtime provider availability.
    

### CONFLICT

*   ADR-005 full-contract claim;
    
*   ADR-012 Firecrawl bypass;
    
*   ADR-017 `postProcessAction`;
    
*   ADR-019 Manual Trigger;
    
*   ADR-020 static Sheet Name prohibition;
    
*   ADR-023 Groq workflow and error-policy claim.
    

* * *

## 10. Verification Checklist

* [x] ADR numbers `001`–`024` are unique.
* [x] Every ADR has an evidence-based status.
* [x] ADR-009 remains IMPLEMENTED.
* [x] ADR-010 remains IMPLEMENTED.
* [x] ADR-024 remains ACCEPTED.
* [x] ADR-024 implementation scope is COMPLETE.
* [x] ADR-024 architectural block is CLOSED.
* [x] Profile D remains REQUIRES EVIDENCE — NON-BLOCKING.
* [x] Configured dependencies are separated from runtime availability.
* [x] Active and published state is not inferred.
* [x] Historical unsupported source markers are removed.
* [x] Technical debt is separated from ADRs.
* [ ] Related ERR links verified after error-journal finalization.
* [ ] File renamed to `docs/DECISIONS.md` in a separate approved scope.
* [ ] Open decisions receive separate ADRs if the corresponding engineering scope is opened.
