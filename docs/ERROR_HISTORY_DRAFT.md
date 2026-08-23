# Error History Register — OSINT Platform

> **Status:** APPROVED  
> **Version:** 1.0  
> **Decision authority:** Principal Architect  
> **Repository SSOT:** `XandXander/n8n-workflows`  
> **Workflow JSON baseline:** `beb2e716f94abfdd674d946962e01fad868127c5`  
> **WORKFLOW_MAP baseline:** `ad9e9b92c7d76f76154d4b322f829c70ff1597e1`  
> **ARCHITECTURE baseline:** `ef1abcf42293c67dae068efe88e8b41a15cd9059`  
> **ENVIRONMENT baseline:** `577ff1c47b192451cc4039e9c99b3daed710d8bc`  
> **DECISIONS baseline:** `4b1b85c5b4f7639b8488bd19e606adfc376e83f9`  
> **Compatibility baseline:** n8n 2.32.7  
> **Current filename:** `docs/ERROR_HISTORY_DRAFT.md`  
> **Canonical filename after separate approved rename:** `docs/ERROR_HISTORY.md`  
> **Last audited:** 2026-08-03

* * *

## 1. Purpose

This document is the canonical register of error-related evidence for the OSINT Platform.
It records:

*   incident occurrence evidence;
    
*   historical incident claims;
    
*   Root Cause confidence;
    
*   remediation implementation state;
    
*   runtime-verification state;
    
*   evidence debt derived from incident investigations;
    
*   technical debt associated with error-prone contracts.
    

This document does not replace:

*   `docs/WORKFLOW_MAP.md`;
    
*   `docs/ARCHITECTURE.md`;
    
*   `docs/ENVIRONMENT.md`;
    
*   `docs/DECISIONS_DRAFT.md`;
    
*   canonical workflow JSON;
    
*   runtime execution logs;
    
*   server or container logs;
    
*   technical specifications;
    
*   ADR records.
    

GitHub is the repository SSOT.
The presence of a remediation in workflow JSON or an approved document does not independently prove:

*   that the historical incident occurred;
    
*   that the stated Root Cause was correct;
    
*   that the remediation was deployed;
    
*   that the remediation succeeded at runtime;
    
*   that the incident is resolved.
    

No incident is marked resolved solely because a configuration or code change exists in GitHub.

* * *

## 2. Evidence Rules

### 2.1 Accepted evidence

Canonical statements may be supported by:

*   canonical workflow JSON;
    
*   approved project documents;
    
*   confirmed Git commits;
    
*   sanitized execution logs;
    
*   sanitized server or container logs;
    
*   confirmed live data.
    

### 2.2 Evidence boundaries

Canonical workflow JSON can confirm:

*   current node configuration;
    
*   current data mappings;
    
*   current connections;
    
*   current retry and timeout settings;
    
*   current response-field handling;
    
*   current code patterns.
    

Canonical workflow JSON cannot independently confirm:

*   historical incident occurrence;
    
*   historical runtime output;
    
*   active or published workflow state;
    
*   successful provider access;
    
*   successful end-to-end execution;
    
*   Root Cause of a historical failure.
    

Approved documents can confirm:

*   architecture;
    
*   accepted decisions;
    
*   current evidence boundaries;
    
*   known contract conflicts;
    
*   approved deployment contracts.
    

Approved documents cannot independently confirm:

*   current runtime health;
    
*   current credential validity;
    
*   successful external-service execution;
    
*   incident occurrence without separate evidence.
    

A Git commit can confirm that repository content changed.
A Git commit does not independently confirm:

*   successful deployment;
    
*   successful execution;
    
*   Root Cause;
    
*   incident resolution.
    

### 2.3 Historical source markers

Markers such as:

```text
[6]
[11]
[15]
[19]
[20]
```

and references to unapproved historical files are not canonical evidence.
Historical material may be retained only as a clearly labelled `HISTORICAL CLAIM`.

### 2.4 Sensitive data

This document must not contain:

*   API key values;
    
*   tokens;
    
*   passwords;
    
*   credential IDs;
    
*   `.env` contents;
    
*   authentication cookies;
    
*   secret headers;
    
*   unsanitized payloads containing personal or confidential data.
    

* * *

## 3. Status Models

### 3.1 Record Class

| Record class | Meaning |
| --- | --- |
| `INCIDENT RECORD` | A failure claim retained for investigation and evidence tracking |
| `HISTORICAL CLAIM — NON-INCIDENT` | A historical claim that is not accepted as a production incident |
| `TECHNICAL DEBT` | A current implementation or contract weakness; not an ERR |
| `EVIDENCE DEBT` | Missing evidence required to confirm occurrence, Root Cause or runtime resolution |

### 3.2 Incident Occurrence Status

| Status | Meaning |
| --- | --- |
| `CONFIRMED BY LOGS` | Occurrence is directly supported by sanitized logs |
| `CONFIRMED BY LIVE DATA` | Occurrence is directly supported by current runtime observation |
| `HISTORICAL CLAIM` | Occurrence is reported historically but lacks accepted direct evidence |
| `UNKNOWN` | Available evidence does not establish whether the incident occurred |
| `CONFLICT` | Accepted evidence sources disagree about occurrence or scope |

### 3.3 Root Cause Confidence

| Status | Meaning |
| --- | --- |
| `CONFIRMED` | Direct evidence establishes the causal mechanism |
| `SUPPORTED` | Current evidence supports the mechanism but does not fully prove historical causality |
| `UNKNOWN` | Root Cause is not established |
| `CONFLICT` | The stated Root Cause conflicts with current accepted evidence |
| `NOT APPLICABLE` | Record is not treated as an incident requiring Root Cause |

`CONFIRMED` requires direct evidence.
A remediation that appears to work is not, by itself, sufficient Root Cause evidence.

### 3.4 Implementation State

| Status | Meaning |
| --- | --- |
| `IMPLEMENTED IN CANONICAL JSON` | Remediation is represented in canonical workflow JSON |
| `IMPLEMENTED IN APPROVED CONTRACT` | Remediation is represented in an approved architectural or deployment contract |
| `PARTIAL` | Only part of the remediation is represented |
| `CONFLICT` | Current implementation conflicts with the claimed remediation |
| `NOT PRESENT` | Claimed remediation is not represented in current canonical artifacts |
| `SUPERSEDED` | Historical remediation or configuration has been replaced |
| `UNKNOWN` | Implementation state cannot be established |
| `NOT APPLICABLE` | Record is not an implementation incident |

### 3.5 Runtime Verification

| Status | Meaning |
| --- | --- |
| `VERIFIED` | Current runtime evidence confirms the remediation succeeds |
| `NOT VERIFIED` | Remediation exists, but current runtime success is not established |
| `UNKNOWN` | Runtime state cannot be determined |
| `NOT APPLICABLE` | Runtime verification does not apply to the record |

* * *

## 4. Incident Index

| ID | Record class | Occurrence | Root Cause | Implementation | Runtime verification |
| --- | --- | --- | --- | --- | --- |
| ERR-001 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | PARTIAL | NOT VERIFIED |
| ERR-002 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | IMPLEMENTED IN CANONICAL JSON | NOT VERIFIED |
| ERR-003 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | NOT PRESENT | NOT VERIFIED |
| ERR-004 | HISTORICAL CLAIM — NON-INCIDENT | HISTORICAL CLAIM | NOT APPLICABLE | NOT PRESENT | NOT APPLICABLE |
| ERR-005 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | CONFLICT | NOT VERIFIED |
| ERR-006 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | IMPLEMENTED IN CANONICAL JSON | NOT VERIFIED |
| ERR-007 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | IMPLEMENTED IN CANONICAL JSON | NOT VERIFIED |
| ERR-008 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | IMPLEMENTED IN CANONICAL JSON | NOT VERIFIED |
| ERR-009 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | PARTIAL | NOT VERIFIED |
| ERR-010 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | IMPLEMENTED IN CANONICAL JSON | NOT VERIFIED |
| ERR-011 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | SUPERSEDED | NOT VERIFIED |
| ERR-012 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | IMPLEMENTED IN APPROVED CONTRACT | NOT VERIFIED |
| ERR-013 | INCIDENT RECORD | HISTORICAL CLAIM | CONFLICT | IMPLEMENTED IN APPROVED CONTRACT | NOT VERIFIED |
| ERR-014 | HISTORICAL CLAIM — NON-INCIDENT | HISTORICAL CLAIM | UNKNOWN | UNKNOWN | NOT VERIFIED |
| ERR-015 | INCIDENT RECORD | HISTORICAL CLAIM | SUPPORTED | PARTIAL | NOT VERIFIED |
| ERR-016 | INCIDENT RECORD | HISTORICAL CLAIM | UNKNOWN | PARTIAL | NOT VERIFIED |

Severity is not canonicalized in this revision because the accepted evidence baseline does not establish reliable impact measurements for each record.

* * *

## 5. Incident Records

# ERR-001 — WF2 Context Loss Around HTTP Request Loops

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** PARTIAL  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF2  
**Related decision:** ADR-005

## Historical occurrence claim

Historical reports state that WF2 lost fields such as:

*   `job_id`;
    
*   `query`;
    
*   `source_platform`;
    

during Serper and Firecrawl processing, resulting in empty or incomplete lead records.
No accepted execution log is currently attached to this record.

## Current confirmed evidence

Canonical WF2 contains:

*   `Serper Search` with response output field `serperResult`;

*   `Extract URLs` consuming `serperResult.organic`;

*   repository-static alignment `CONFIRMED BY GITHUB @ beb2e71`;

*   `Firecrawl Scrape` with response output field `firecrawlResult`;

*   `$items("Loop Queries", 0, $runIndex)` context recovery;

*   `.item` fallback context recovery;

*   `Extract Contacts` reading `firecrawlResult`.

The pre-`beb2e71` Serper producer/consumer mismatch is no longer a current repository-static conflict.

## Root Cause assessment

At the pre-`beb2e71` repository baseline, the Serper producer/consumer mismatch supported a possible response-path failure mechanism. Commit `beb2e71` removes that mismatch from canonical WF2.

This does not prove that the mismatch was the sole historical Root Cause or that runtime remediation succeeds.

## Implementation state

ADR-005 is `IMPLEMENTED` for repository artifacts only.
Firecrawl downstream handling is aligned with `firecrawlResult`.
Serper downstream handling is aligned with `serperResult.organic`.

```text
TD-004 — STATICALLY RESOLVED / RUNTIME TO VERIFY
MIS-001 — CLOSED FOR REPOSITORY-LEVEL STATIC IMPLEMENTATION / RUNTIME NOT VERIFIED
```

ERR-001 remains `PARTIAL / NOT VERIFIED` because it is broader than TD-004 and still requires runtime evidence. Legacy context-recovery patterns remain.

## Runtime verification required

Required evidence:

*   sanitized output from `Serper Search`;
    
*   sanitized output from `Extract URLs`;
    
*   sanitized output from `Firecrawl Scrape`;
    
*   sanitized output from `Extract Contacts`;
    
*   sanitized input to `Append Lead`;
    
*   final Google Sheets row for the same `job_id`.
    

* * *

# ERR-002 — DeepSeek JSON-Object Prompt Validation Failure

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** IMPLEMENTED IN CANONICAL JSON  
**Runtime verification:** NOT VERIFIED  
**Affected components:** WF1, WF6

## Historical occurrence claim

Historical reports describe an HTTP 400 response when `response_format.type` was set to `json_object` without an explicit JSON instruction in the prompt.
The exact API response is not supported by an accepted current log.

## Current confirmed evidence

Canonical WF1 and WF6:

*   use `response_format: { type: "json_object" }`;
    
*   contain an explicit instruction to return JSON.
    

## Root Cause assessment

The current implementation is consistent with a provider-side JSON-prompt requirement.
The historical provider response and exact causal requirement are not directly established by the accepted evidence baseline.

## Implementation state

The mitigation is represented in canonical JSON for the affected nodes inspected by this record.

## Runtime verification required

Required evidence:

*   sanitized provider response from a failing pre-mitigation request, if retained;
    
*   sanitized successful execution after the current prompt;
    
*   confirmation that the returned content is valid JSON.
    

* * *

# ERR-003 — Intent Classification Failure Associated with `OSINT-AI:` Prefix

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** NOT PRESENT  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF1

## Historical occurrence claim

Historical reports state that a request containing the prefix:

```text
OSINT-AI:
```

produced an invalid or fallback intent.

## Current confirmed evidence

The canonical WF1 classifier prompt defines intent and entity-extraction rules.
It does not contain an explicit rule instructing the model to ignore the `OSINT-AI:` prefix.

## Root Cause assessment

The claim that the model was confused by the prefix is not supported by accepted comparative execution evidence.
Possible interactions with parsing, confidence handling or prompt interpretation remain unverified.

## Implementation state

The claimed prompt remediation is not represented in current canonical WF1 JSON.

## Runtime verification required

Required evidence:

*   sanitized classifier request and response with the prefix;
    
*   sanitized classifier request and response without the prefix;
    
*   parsed output from `Parse Intent`;
    
*   confidence values from both executions.
    

* * *

# ERR-005 — Firecrawl Failure on Protected or Restricted Targets

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** CONFLICT  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF2  
**Related decision:** ADR-012

## Historical occurrence claim

Historical reports state that Firecrawl returned blocked or inaccessible responses for some targets.
Claims about specific anti-bot technologies, encryption mechanisms and affected domains are not canonicalized without direct evidence.

## Current confirmed evidence

Canonical WF2 sends URL items passing `Filter Empty` to `Firecrawl Scrape`.
No protected-domain bypass is present.
ADR-012 is:

```text
UNKNOWN
```

with conflicting evidence.

## Root Cause assessment

No accepted response body, HTTP status, provider log or target-specific diagnostic is attached.
The Root Cause is UNKNOWN.

## Implementation state

The historical claim that Firecrawl was disabled for protected targets conflicts with current canonical WF2.

## Runtime verification required

Required evidence for each affected target:

*   target URL or sanitized domain;
    
*   Firecrawl HTTP status;
    
*   sanitized Firecrawl response;
    
*   execution timestamp;
    
*   fallback behavior;
    
*   resulting lead item;
    
*   confirmation that no fabricated contact data was persisted.
    

* * *

# ERR-006 — Unsupported Code-Node Runtime APIs

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** IMPLEMENTED IN CANONICAL JSON  
**Runtime verification:** NOT VERIFIED  
**Affected components:** Canonical Code nodes  
**Related decisions:** ADR-007, ADR-008

## Historical occurrence claim

Historical reports describe failures involving runtime APIs such as:

*   `Buffer.from()`;
    
*   `crypto.randomUUID()`.
    

No accepted execution log is attached.

## Current confirmed evidence

Canonical workflow code uses:

*   `prepareBinaryData` for WF6 binary preparation;
    
*   `Math.random()` and timestamp-based identifiers;
    
*   `new Date().toISOString()`.
    

Approved `ENVIRONMENT.md` classifies global Code-node environment access as `UNKNOWN`.

## Root Cause assessment

The current evidence confirms the adopted sandbox-safe implementation pattern.
It does not establish the exact historical runtime restriction or global Task Runner configuration.

## Implementation state

The canonical remediation patterns are represented in workflow JSON.

## Runtime verification required

Required evidence:

*   sanitized execution log showing the historical runtime error;
    
*   current successful execution of the affected Code node;
    
*   read-only runtime evidence for Code-node environment access, if needed.
    

* * *

# ERR-007 — Incorrect IMAP Subject Data Path

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** IMPLEMENTED IN CANONICAL JSON  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF1

## Historical occurrence claim

Historical reports state that an email subject filter used a non-working nested path and failed to match expected messages.

## Current confirmed evidence

Canonical WF1 `Filter Email` reads:

```text
$json.subject
```

and checks whether it contains:

```text
OSINT-AI
```

## Root Cause assessment

The current implementation supports the conclusion that the canonical subject field is root-level for this workflow contract.
The historical failing expression and execution output are not present in accepted evidence.

## Implementation state

The root-level subject mapping is represented in canonical JSON.

## Runtime verification required

Required evidence:

*   sanitized IMAP trigger output;
    
*   evaluated `Filter Email` input;
    
*   filter result;
    
*   downstream `Normalize Input` output.
    

* * *

# ERR-008 — WF2 `Filter Empty` Rejecting URL Items

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** IMPLEMENTED IN CANONICAL JSON  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF2

## Historical occurrence claim

Historical reports state that `Filter Empty` rejected URL items even when a URL appeared to be present.

## Current confirmed evidence

Canonical WF2 configures:

```text
looseTypeValidation: true
```

and requires:

*   `skip !== true`;
    
*   non-empty `url`.
    

## Root Cause assessment

The previous filter configuration and evaluated input types are not available.
The Root Cause is UNKNOWN.

## Implementation state

The claimed loose-type-validation mitigation is represented in canonical JSON.

## Runtime verification required

Required evidence:

*   sanitized `Extract URLs` output;
    
*   evaluated IF conditions;
    
*   true-output item count;
    
*   false-output item count;
    
*   one representative passing item.
    

* * *

# ERR-009 — Fragile Paired-Item Context Access After WF2 Loops

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** PARTIAL  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF2  
**Related decision:** ADR-005

## Historical occurrence claim

Historical reports state that node references after `SplitInBatches` returned empty or incorrect context.

## Current confirmed evidence

Canonical WF2 still uses:

```text
$items("Loop Queries", 0, $runIndex)
```

and fallback access through:

```text
$('Loop Queries').item
```

Similar recovery exists around `Loop URLs`.

## Root Cause assessment

The current implementation confirms reliance on fragile context-recovery patterns.
The version-specific claim about n8n paired-item behavior is not directly established.

## Implementation state

The issue is only partially addressed.
The current workflow still contains the patterns associated with the historical failure claim.

## Runtime verification required

Required evidence:

*   loop iteration index;
    
*   source item;
    
*   paired-item metadata;
    
*   `$items()` result;
    
*   `.item` result;
    
*   final context used by downstream nodes.
    

* * *

# ERR-010 — Gotenberg Input Missing Binary `index.html`

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** IMPLEMENTED IN CANONICAL JSON  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF6  
**Related decisions:** ADR-006, ADR-007

## Historical occurrence claim

Historical reports describe a Gotenberg request failing because binary input named `index.html` was missing.

## Current confirmed evidence

Canonical WF6:

*   produces HTML text;
    
*   converts the HTML through `prepareBinaryData`;
    
*   names the binary `index.html`;
    
*   uses MIME type `text/html`;
    
*   submits binary field `index.html` to Gotenberg.
    

## Root Cause assessment

The current request contract supports the conclusion that Gotenberg requires the binary file expected by the multipart configuration.
The historical pre-remediation workflow and error log are not part of the accepted baseline.

## Implementation state

The binary-preparation remediation is represented in canonical JSON.
ADR-006 remains `PARTIAL` because Gotenberg runtime availability and successful conversion are unverified.

## Runtime verification required

Required evidence:

*   `Create HTML Binary` output metadata;
    
*   Gotenberg request metadata;
    
*   Gotenberg HTTP status;
    
*   returned binary metadata;
    
*   generated PDF validation.
    

* * *

# ERR-011 — Historical Pinecone Upsert 404 or 400

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** SUPERSEDED  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF7  
**Related decision:** ADR-014

## Historical occurrence claim

Historical reports describe Pinecone upsert requests returning HTTP 404 or 400.
The historical configuration reportedly used earlier endpoint, namespace or vector-dimension assumptions.

## Current confirmed evidence

The canonical architecture now uses:

```text
model: jina-embeddings-v3
dimensions: 1024
upsert task: retrieval.passage
query task: retrieval.query
```

Current caller namespaces are:

*   `leads`;
    
*   `companies`;
    
*   `tenders`.
    

The historical namespace `osint-knowledge` and dimension `768` are not current canonical contracts.

## Root Cause assessment

No accepted request or response log from the historical failure is available.
The exact Root Cause is UNKNOWN.

## Implementation state

The historical configuration has been superseded by ADR-014 and current WF7.

## Runtime verification required

Required evidence:

*   sanitized embedding response dimensions;
    
*   sanitized Pinecone request;
    
*   Pinecone HTTP status;
    
*   index dimension configuration;
    
*   upsert result;
    
*   query result.
    

* * *

# ERR-012 — Unauthorized Use of Internal n8n Workflow Route

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** IMPLEMENTED IN APPROVED CONTRACT  
**Runtime verification:** NOT VERIFIED  
**Affected component:** `n8n_workflow_manager`  
**Related decisions:** ADR-009, ADR-010

## Historical occurrence claim

Historical reports describe an unauthorized response while attempting workflow operations through an internal n8n route.

## Current confirmed evidence

The approved deployment contract uses:

```text
PUT https://xandai.ru/api/v1/workflows/{workflow_id}
```

with authorization header name:

```text
X-N8N-API-KEY
```

The internal `/rest/workflows` route is excluded from the approved deployment pipeline.

## Root Cause assessment

The accepted architecture supports the distinction between the internal route and Public API v1.
The exact historical authentication state and unauthorized response are not supported by accepted logs.

## Implementation state

The remediation is represented in approved ADR-009 and ADR-010.

## Runtime verification required

Required evidence:

*   sanitized Public API request metadata;
    
*   HTTP status;
    
*   response metadata;
    
*   workflow ID;
    
*   confirmation that no internal `/rest/workflows` route was used;
    
*   post-update read-only verification.
    

* * *

# ERR-013 — Workflow Update Payload Rejected by n8n

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** CONFLICT  
**Implementation state:** IMPLEMENTED IN APPROVED CONTRACT  
**Runtime verification:** NOT VERIFIED  
**Affected component:** `n8n_workflow_manager`  
**Related decisions:** ADR-010, ADR-024

## Historical occurrence claim

Historical reports state that n8n rejected an update payload containing unsupported root fields.
The same historical record also claimed that node IDs were forbidden.

## Current confirmed evidence

The approved update contract requires removal of these root fields from the PUT body:

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

The approved contract also requires:

*   reading `workflow_id` from Profile A root `id`;
    
*   using root `id` in the endpoint;
    
*   removing root `id` from the request body;
    
*   preserving existing `nodes[].id`;
    
*   preserving credentials;
    
*   not modifying automatic credential substitution.
    

## Root Cause assessment

The unsupported-root-field portion is consistent with the approved sanitized PUT contract.
The claim that existing node IDs must be removed conflicts with ADR-010 and ADR-024.

## Implementation state

The current remediation is represented in the approved deployment contract.

## Runtime verification required

Required evidence:

*   sanitized pre-sanitation payload field list;
    
*   sanitized PUT payload field list;
    
*   HTTP status;
    
*   response metadata;
    
*   read-only server response after update.
    

* * *

# ERR-015 — Paired-Item Context Error in WF4 Tender Loop

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** SUPPORTED  
**Implementation state:** PARTIAL  
**Runtime verification:** NOT VERIFIED  
**Affected component:** WF4

## Historical occurrence claim

Historical reports describe a paired-item error while accessing upstream data after `Loop Tenders`.

## Current confirmed evidence

Canonical WF4 uses:

```text
$('Config').first()
```

for stable access to configuration data.
`Enrich Tender` still uses:

```text
$items("Loop Tenders", 0, $runIndex)
```

with `.item` fallback.

## Root Cause assessment

The current code supports the conclusion that paired-item and loop-context access required workarounds.
The exact historical error, n8n version and causal mechanism are not directly established.

## Implementation state

The remediation is partial.
One context path uses `.first()` while another retains `$items()` and `.item` fallback.

## Runtime verification required

Required evidence:

*   `Loop Tenders` input;
    
*   iteration index;
    
*   paired-item metadata;
    
*   `Config` output;
    
*   `Enrich Tender` resolved context;
    
*   final persisted tender row.
    

* * *

# ERR-016 — DeepSeek Timeout or Connection Reset

**Record class:** INCIDENT RECORD  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** PARTIAL  
**Runtime verification:** NOT VERIFIED  
**Affected components:** WF1, WF3, WF4, WF5, WF6  
**Related decision:** ADR-011

## Historical occurrence claim

Historical reports describe DeepSeek requests failing with timeout or connection-reset errors.

## Current confirmed evidence

Canonical retry and timeout configuration is:
| Workflow | Timeout | Retry configuration |
| --- | --- | --- |
| WF1 | 45 seconds | 3 attempts, 5-second wait |
| WF3 | 120 seconds | 3 attempts, 2-second wait |
| WF4 | 120 seconds | 3 attempts, 2-second wait |
| WF5 | 120 seconds | 3 attempts, 5-second wait |
| WF6 | 120 seconds | Retry fields absent |

## Root Cause assessment

The historical claim combines:

*   a network-failure symptom;
    
*   an insufficient-timeout hypothesis.
    

The available evidence does not establish whether the failures were caused by:

*   provider latency;
    
*   network interruption;
    
*   timeout settings;
    
*   request size;
    
*   rate limiting;
    
*   another external condition.
    

The Root Cause is UNKNOWN.

## Implementation state

ADR-011 is `PARTIAL`.
Retry behavior is represented in WF1, WF3, WF4 and WF5.
WF6 has a timeout but no retry configuration.

## Runtime verification required

Required evidence:

*   sanitized error code;
    
*   provider HTTP status, if present;
    
*   request duration;
    
*   attempt count;
    
*   retry intervals;
    
*   request size;
    
*   final execution result.
    

* * *

## 6. Historical Claims Not Canonicalized as Incidents

# ERR-004 — Manual Subworkflow Test Harness Claim

**Record class:** HISTORICAL CLAIM — NON-INCIDENT  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** NOT APPLICABLE  
**Implementation state:** NOT PRESENT  
**Runtime verification:** NOT APPLICABLE
Historical reports describe difficulty supplying mock input to an Execute Workflow Trigger and a temporary Manual Trigger plus Code-node workaround.
Current canonical WF2:

*   begins with an Execute Workflow Trigger;
    
*   does not contain a Manual Trigger;
    
*   does not contain the claimed test harness.
    

This record concerns a development-test technique, not a confirmed production incident.
It is retained only as a historical claim.

* * *

# ERR-014 — Mass Failure After Import of LLM-Generated Workflow JSON

**Record class:** HISTORICAL CLAIM — NON-INCIDENT  
**Occurrence:** HISTORICAL CLAIM  
**Root Cause confidence:** UNKNOWN  
**Implementation state:** UNKNOWN  
**Runtime verification:** NOT VERIFIED
Historical reports describe a broad system failure after importing LLM-generated workflow JSON.
The accepted evidence baseline does not contain:

*   the imported artifacts;
    
*   the affected commit;
    
*   import results;
    
*   execution logs;
    
*   a validated incompatibility report;
    
*   a confirmed Root Cause.
    

The current artifact contract is governed by ADR-024.
The historical claim is not accepted as a confirmed incident.

* * *

## 7. Cross-Record Historical Claims

The following claims are not canonicalized as current facts without direct evidence:

*   exact incident dates where no timestamped evidence is attached;
    
*   exact n8n version responsible for paired-item behavior;
    
*   exact provider error text without a sanitized log;
    
*   exact impact or severity classification;
    
*   exact anti-bot or encryption technology used by target platforms;
    
*   claims that contact data was hallucinated and persisted;
    
*   claims that UI operations modified database settings;
    
*   claims that network instability was the Root Cause of DeepSeek failures;
    
*   claims that existing `nodes[].id` must be removed from PUT payloads;
    
*   historical Pinecone namespace `osint-knowledge` as a current namespace;
    
*   historical vector dimension `768` as a current contract;
    
*   claims that a Git commit proves successful deployment;
    
*   claims that a configured provider is currently available.
    

* * *

## 8. Evidence Debt

### ED-001 — Current execution logs

No current sanitized execution logs are included in the approved baseline for the incident records.

### ED-002 — WF2 end-to-end context verification

Required for ERR-001, ERR-008 and ERR-009.

### ED-003 — DeepSeek provider verification

Required for ERR-002, ERR-003 and ERR-016.

### ED-004 — Firecrawl target-specific responses

Required for ERR-005.

### ED-005 — Code-node runtime environment

Required for ERR-006.
Global Code-node environment access remains `UNKNOWN`.

### ED-006 — IMAP runtime payload

Required for ERR-007.

### ED-007 — Gotenberg runtime conversion

Required for ERR-010.
The following remain unverified:

*   container availability;
    
*   image version;
    
*   successful HTML-to-PDF conversion;
    
*   output binary integrity.
    

### ED-008 — Pinecone and Jina live compatibility

Required for ERR-011.
The following remain unverified:

*   Pinecone index availability;
    
*   live index dimension;
    
*   embedding-response dimensions;
    
*   successful upsert and query.
    

### ED-009 — Public API runtime update

Required for ERR-012 and ERR-013.
The following remain unverified:

*   endpoint availability;
    
*   API-key validity;
    
*   successful sanitized PUT;
    
*   server response contract;
    
*   Profile D.
    

### ED-010 — Active and published workflow state

Active and published state remains UNKNOWN for WF1–WF8.

### ED-011 — External-provider availability

Runtime availability remains UNKNOWN for configured providers.

### ED-012 — Credential validity

Credential references exist in canonical workflow JSON.
Credential validity and permission scopes remain UNKNOWN.

### ED-013 — Deploy/runtime authorization provenance gap

**Record class:** EVIDENCE DEBT

**Statement:**

VK V1 repository implementation associated with commit
`6134a35c5b1b9f09c67dd7f857625a4d491d28c7`,
WF2 P0 persistence-gate repository change associated with commit
`d999c5f61875e032cfd8cec7153c2a599db3e89f`,
and WF6 truthful-reporting repository change associated with commit
`b4bfb6837b5e1219f9e14cfe5e45641622ab2816`
were reported as deployed and exercised on live n8n.

Exact deploy provenance is incomplete.

For `d999c5f6...` and `b4bfb683...`, the following have not been independently recovered:

- exact PUT timestamp;
- exact deploying actor/session;
- exact authorizing Architect/Owner message;
- exact chat/session provenance linking authorization → deployment action.

**Evidence status:** HISTORICAL CLAIM / TO VERIFY

**Root Cause confidence:** NOT ESTABLISHED

**Required future practice:**

Every future workflow deployment must retain explicit authorization provenance in a machine/human-auditable form, including at minimum:

`DEPLOY AUTHORIZED BY <role> AT <timestamp>`

plus:

- target workflow;
- repository commit / expected artifact identity;
- deploying actor/session;
- deployment result/readback reference.

This evidence-debt item must NOT be marked:

- CLOSED;
- RESOLVED;
- APPROVED;
- runtime verified.

* * *

## 9. Technical Debt and Current Contract Conflicts — Not ERRs

The following are current technical-debt or contract-conflict items.
They are not incident records unless separate occurrence evidence is established.

### TD-001 — WF1 to WF2 missing `intent`

WF1 does not pass `intent` to WF2.
WF2 defaults to `search_private`.

### TD-002 — WF1 to WF3 serialized `entities`

WF1 passes serialized `entities`.
WF3 contains object-style access expectations.

### TD-003 — Direct `site_analysis` contract

WF1 sends direct `site_analysis` work to WF5 without an explicit `entity_type`.
WF5 defaults to `lead`.

### TD-004 — WF2 Serper static response-path alignment

```text
TD-004 — STATICALLY RESOLVED / RUNTIME TO VERIFY
MIS-001 — CLOSED FOR REPOSITORY-LEVEL STATIC IMPLEMENTATION / RUNTIME NOT VERIFIED
```

`Serper Search` stores its response in `serperResult`.
`Extract URLs` consumes `serperResult.organic`.

The pre-`beb2e71` mismatch is removed from canonical WF2; runtime evidence remains required.

### TD-005 — WF6 qualification semantics

`Read Qualified Entities` does not filter by `status=qualified`.
The `qualified` statistic counts structurally non-empty entities.

### TD-006 — Loop context recovery

WF2 and WF4 contain `$items(..., $runIndex)` and `.item` fallback context recovery.

### TD-007 — Inconsistent external-provider retry configuration

DeepSeek retry settings are not uniform.
WF6 has no retry fields.
Other external providers use different timeout and error-handling patterns.

### TD-008 — Unverified loop input indexes

Runtime behavior of done-connections targeting loop input index 1 remains UNKNOWN.

### TD-009 — Unverified Gotenberg Telegram output index

WF6 connects the Telegram delivery node to Gotenberg output index 1.
Runtime emission of that output is UNKNOWN.

* * *

## 10. Excluded Former Technical-Debt Claims

The following claims are not accepted as current technical debt:

*   `Save Successful Executions: none`;
    
*   absence of cron backups as a confirmed fact;
    
*   absence of Watchtower as a confirmed fact;
    
*   empty PDF reports attributed to Firecrawl failures;
    
*   missing Pinecone schema documentation;
    
*   calibration data for tender scoring as an incident-evidence gap.
    

Approved `ENVIRONMENT.md` establishes:

*   workflow-level success-save settings for selected workflows;
    
*   global execution retention as UNKNOWN;
    
*   backup policy as UNKNOWN;
    
*   update policy as UNKNOWN.
    

* * *

## 11. Current Evidence Classification

### CONFIRMED BY JSON

*   current WF2 response-field configuration;
    
*   WF2 Serper static producer/consumer alignment: `Serper Search` stores `serperResult`, `Extract URLs` consumes `serperResult.organic`, CONFIRMED BY GITHUB @ `beb2e71`;
    
*   current WF2 context-recovery patterns;
    
*   current WF1 email subject path;
    
*   current WF2 `looseTypeValidation`;
    
*   current WF6 binary preparation;
    
*   current WF7 Jina and Pinecone contract;
    
*   current WF4 context-recovery patterns;
    
*   current DeepSeek retry and timeout settings.
    

### CONFIRMED BY APPROVED DOCUMENT

*   GitHub SSOT;
    
*   workflow and architecture baselines;
    
*   ADR-005 status `IMPLEMENTED` for repository artifacts only;
    
*   ADR-006 status `PARTIAL`;
    
*   ADR-009 and ADR-010 implementation;
    
*   ADR-011 status `PARTIAL`;
    
*   ADR-012 status `UNKNOWN`;
    
*   ADR-014 implementation;
    
*   ADR-024 closed implementation scope;
    
*   global runtime evidence boundaries.
    

### CONFIRMED BY LIVE DATA

*   compatibility baseline n8n 2.32.7.
    

### CONFIRMED BY LOGS

*   none in the current approved incident baseline.
    

### HISTORICAL CLAIM

*   incident occurrences recorded as ERR-001 through ERR-016;
    
*   exact error strings not supported by current accepted logs;
    
*   historical fixes or workarounds not present in current canonical artifacts.
    

### UNKNOWN

*   current runtime success of all retained incident remediations;
    
*   active or published workflow state;
    
*   external-provider availability;
    
*   credential validity;
    
*   Gotenberg runtime health;
    
*   Pinecone live compatibility;
    
*   global Code-node environment;
    
*   exact Root Cause for most incident records.
    

### CONFLICT

*   ERR-001 full runtime remediation claim;
    
*   ERR-005 protected-target bypass claim;
    
*   ERR-009 fully corrected context-access claim;
    
*   ERR-013 node-ID removal claim;
    
*   current versus historical Pinecone configuration;
    
*   uniform DeepSeek retry-policy claim.
    

* * *

## 12. Verification Checklist

* [x] GitHub repository is identified as SSOT.
* [x] Workflow JSON baseline is recorded.
* [x] Closed-document baselines are recorded.
* [x] Compatibility baseline is n8n 2.32.7.
* [x] Incident occurrence is separated from Root Cause confidence.
* [x] Root Cause confidence is separated from implementation state.
* [x] Implementation state is separated from runtime verification.
* [x] Historical source markers are excluded as canonical evidence.
* [x] ERR records are separated from ADRs.
* [x] ERR records are separated from technical debt.
* [x] Evidence debt is documented separately.
* [x] Current contract conflicts are not presented as confirmed historical Root Causes.
* [x] No secret values are included.
* [x] Principal Architect approval recorded.
* [x] Status changed from `REVIEW CANDIDATE` to `APPROVED`.
* [ ] Runtime evidence attached for retained incident records.
* [ ] File renamed to `docs/ERROR_HISTORY.md` in a separate approved scope.
