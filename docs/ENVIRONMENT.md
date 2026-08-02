# ENVIRONMENT.md

> **Status:** APPROVED  
> **Version:** 1.0  
> **Owner:** Open WebUI / AI Engineer  
> **Final approver:** ChatGPT / Principal Architect  
> **Source of truth:** GitHub repository  
> **Workflow JSON baseline:** `8420e423c98dcb1d11fa02f554e0674b9705bb81`  
> **WORKFLOW_MAP baseline:** `ad9e9b92c7d76f76154d4b322f829c70ff1597e1`  
> **ARCHITECTURE baseline:** `ef1abcf42293c67dae068efe88e8b41a15cd9059`  
> **Compatibility baseline:** n8n 2.32.7  
> **Last updated:** 2026-08-02

* * *

## 1. Purpose

This document defines the confirmed runtime-environment boundary of the OSINT Platform.
It records:

*   the n8n compatibility baseline;
    
*   configured application dependencies visible in canonical workflow JSON;
    
*   data-storage dependencies;
    
*   environment-variable names referenced by workflows;
    
*   the approved deployment contract;
    
*   workflow-level execution settings visible in canonical JSON;
    
*   runtime facts that remain unverified.
    

Detailed workflow topology is maintained in `docs/WORKFLOW_MAP.md`.
System architecture and evidence boundaries are maintained in `docs/ARCHITECTURE.md`.
This document does not infer live server, container, network or operating-system state from the presence of workflow files in GitHub.

* * *

## 2. Evidence Model

| Status | Meaning |
| --- | --- |
| `CONFIRMED BY JSON` | Directly supported by canonical workflow JSON |
| `CONFIRMED BY LIVE DATA` | Supported by a current runtime observation supplied for this environment |
| `CONFIRMED BY LOGS` | Supported by server, container or execution logs |
| `UNKNOWN` | Current evidence does not establish the fact |
| `CONFLICT` | Two confirmed representations are incompatible |

GitHub is the SSOT for project configuration and documentation.
GitHub workflow presence does not prove:

*   live deployment;
    
*   active or published state;
    
*   credential validity;
    
*   successful external-service access;
    
*   container availability;
    
*   end-to-end execution.
    

* * *

## 3. Confirmed Baseline

| Property | Value | Evidence status |
| --- | --- | --- |
| Runtime platform | n8n | CONFIRMED BY JSON |
| n8n version | `2.32.7` | CONFIRMED BY LIVE DATA |
| Workflow definitions | Eight canonical OSINT workflow JSON files | CONFIRMED BY JSON |
| Workflow compatibility baseline | n8n `2.32.7` | CONFIRMED BY LIVE DATA |
| Workflow deployment source | GitHub | CONFIRMED BY ADR-009 / ADR-010 |
| Existing-workflow update method | HTTP `PUT` | CONFIRMED BY ADR-010 |
| Public API family | n8n Public API v1 | CONFIRMED BY ADR-009 |
| Active/published state | Not established | UNKNOWN |
| End-to-end runtime status | Not established | UNKNOWN |

No server or container logs are included in the current evidence baseline.

* * *

## 4. Configured Application Dependencies

The following dependencies are confirmed as configured in workflow JSON.
Their runtime availability is not implied.
| Dependency | Workflows | Configured purpose | Runtime status |
| --- | --- | --- | --- |
| DeepSeek | WF1, WF3, WF4, WF5, WF6 | Classification, analysis, scoring and report generation | UNKNOWN |
| Serper | WF2, WF3, WF4 | Search | UNKNOWN |
| Tavily | WF4 | Tender search | UNKNOWN |
| Firecrawl | WF2, WF3 | Web scraping | UNKNOWN |
| DaData | WF3 | Company lookup by INN | UNKNOWN |
| Jina | WF7 | Text embeddings | UNKNOWN |
| Pinecone | WF7 | Vector query, upsert and delete | UNKNOWN |
| Groq | WF8 | Whisper speech-to-text | UNKNOWN |
| Gotenberg | WF6, WF8 | HTML-to-PDF conversion | UNKNOWN |
| Google Sheets | WF1, WF2, WF3, WF4, WF5, WF6, WF8 | Operational state | UNKNOWN |
| Google Drive | WF6 | Configured PDF storage | UNKNOWN |
| Telegram | WF1, WF6, WF8 | Input, confirmation, delivery and notification paths | UNKNOWN |
| IMAP | WF1 | Email input | UNKNOWN |
| SMTP | WF6 | Configured email delivery | UNKNOWN |

### Internal service reference

Canonical workflow JSON contains the internal URL:

```text
http://gotenberg:3000/forms/chromium/convert/html
```

This confirms that workflow configuration expects DNS or network resolution for host `gotenberg`.
It does not confirm:

*   that a Gotenberg container is currently running;
    
*   its image tag;
    
*   its health;
    
*   the Docker network topology;
    
*   successful PDF conversion.
    

* * *

## 5. Data and Storage Dependencies

### Google Sheets

Confirmed sheet names:

*   `jobs`;
    
*   `leads`;
    
*   `companies`;
    
*   `tenders`;
    
*   `reports`;
    
*   `logs`.
    

Google Sheets is used as the shared operational state boundary between workflows.
Runtime availability, quota state and current sheet schema are not established by static workflow JSON.

### Pinecone

Confirmed namespaces used by current callers:

*   `leads`;
    
*   `companies`;
    
*   `tenders`.
    

Confirmed embedding configuration in WF7:

*   model: `jina-embeddings-v3`;
    
*   dimensions: `1024`;
    
*   upsert task: `retrieval.passage`;
    
*   query task: `retrieval.query`.
    

Pinecone index availability and dimension compatibility remain UNKNOWN without live evidence.

### Google Drive

WF6 contains a configured Google Drive upload operation and consumes the resulting `webViewLink`.
Successful upload and current folder accessibility remain UNKNOWN.

### n8n internal persistence

The following are not established by the approved workflow/document baseline:

*   database type and version;
    
*   queue backend;
    
*   execution database host;
    
*   filesystem volume paths;
    
*   binary-data persistence path;
    
*   backup storage.
    

Status:

```text
N8N INTERNAL PERSISTENCE — UNKNOWN
```

* * *

## 6. Environment Variables and Credentials

### Environment-variable names referenced by workflow JSON

The current workflows reference these environment-variable names:

```text
TELEGRAM_BOT_TOKEN
ADMIN_CHAT_ID
```

Only names may be documented.
Values must never be:

*   committed to Git;
    
*   displayed in audit output;
    
*   included in prompts;
    
*   included in logs returned for documentation review.
    

### n8n credentials

Canonical workflows contain credential references for configured integrations.
This confirms that credential-backed nodes are configured.
It does not confirm:

*   the current credential values;
    
*   credential validity;
    
*   provider authentication success;
    
*   permission scope;
    
*   credential ownership.
    

Credential IDs and secret values must not be reproduced in this document.

### Secret-file location

The current GitHub and workflow evidence does not establish the live location of `.env` or another secret store.
Status:

```text
SECRET FILE PATH — UNKNOWN
```

* * *

## 7. Workflow-Level Execution Settings

Canonical JSON explicitly contains workflow-level settings for WF1, WF5 and WF6:

```text
executionOrder: v1
saveDataSuccessExecution: all
saveExecutionProgress: true
callerPolicy: workflowsFromSameOwner
```

These settings are `CONFIRMED BY JSON` for the canonical workflow representation.
They do not establish:

*   the live server value after import or update;
    
*   global instance defaults;
    
*   settings of workflows where the fields are absent;
    
*   failure-data retention;
    
*   global pruning policy.
    

The global effective values for execution retention and pruning remain UNKNOWN.

* * *

## 8. Deployment and API Contract

Related decisions:

*   ADR-009;
    
*   ADR-010;
    
*   ADR-024.
    

### Existing workflow update

The approved update contract is:

1.  Read the canonical workflow JSON from GitHub.
    
2.  Read `workflow_id` from the root `id`.
    
3.  Stop the update if root `id` is absent.
    
4.  Build the endpoint:
    

```text
PUT https://xandai.ru/api/v1/workflows/{workflow_id}
```

5.  Use the authorization header name:
    

```text
X-N8N-API-KEY
```

6.  Never document or display the header value.
    
7.  Remove these root fields from the update body:
    

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

8.  Preserve `nodes[].id` when present.
    
9.  Do not generate missing node IDs automatically.
    
10.  Only after successful PUT, create and push a Git commit when changes exist.
     

### Scope limits

The approved contract does not establish:

*   a POST/create implementation;
    
*   a confirmed GET/server-response contract;
    
*   API-key validity;
    
*   collection endpoint availability;
    
*   the value of `N8N_API_ENABLED`;
    
*   live accessibility of the update endpoint.
    

* * *

## 9. Workflow JSON Artifact Profiles

**Compatibility baseline:** n8n 2.32.7  
**Decision:** ADR-024
| Profile | Purpose | Status |
| --- | --- | --- |
| Profile A | GitHub canonical workflow | APPROVED |
| Profile B | POST/create payload | NOT IMPLEMENTED |
| Profile C | Sanitized PUT update payload | APPROVED |
| Profile D | Server response/export | REQUIRES EVIDENCE — NON-BLOCKING |

No new server-managed field may be added to the Profile C blacklist without evidence.
Fields such as the following remain unresolved:

*   `parentFolderId`;
    
*   `activeVersionId`;
    
*   `nodeGroups`;
    
*   other fields introduced or managed by the n8n server.
    

* * *

## 10. Runtime Host Status

The following values require current live or log evidence.
| Runtime property | Status |
| --- | --- |
| Operating system and release | UNKNOWN |
| Kernel version | UNKNOWN |
| CPU architecture | UNKNOWN |
| Virtualization type | UNKNOWN |
| Server timezone | UNKNOWN |
| CPU count and model | UNKNOWN |
| RAM and swap | UNKNOWN |
| Disk size and free space | UNKNOWN |
| Docker Engine version | UNKNOWN |
| Docker Compose version | UNKNOWN |
| Compose project name | UNKNOWN |
| Compose file path | UNKNOWN |
| n8n image tag and digest | UNKNOWN |
| Container inventory | UNKNOWN |
| Container health state | UNKNOWN |
| Docker network topology | UNKNOWN |
| Published ports | UNKNOWN |
| Restart policies | UNKNOWN |

The compatibility baseline `n8n 2.32.7` must not be converted into an assumed Docker image tag.

* * *

## 11. n8n Global Runtime Status

| Setting | Status |
| --- | --- |
| Execution mode | UNKNOWN |
| Queue mode | UNKNOWN |
| Main/worker topology | UNKNOWN |
| Binary data mode | UNKNOWN |
| Binary data path | UNKNOWN |
| Execution pruning | UNKNOWN |
| Success execution default | UNKNOWN |
| Failure execution default | UNKNOWN |
| Maximum concurrency | UNKNOWN |
| Maximum payload size | UNKNOWN |
| Code-node environment access | UNKNOWN |
| Public API enablement variable | UNKNOWN |
| Encryption-key configuration | UNKNOWN |
| Personalization setting | UNKNOWN |
| Settings-file permission enforcement | UNKNOWN |
| Community-node installation | UNKNOWN |

Workflow-level settings documented in section 7 do not establish global instance settings.

* * *

## 12. Network and Security Status

| Property | Status |
| --- | --- |
| Reverse proxy implementation | UNKNOWN |
| TLS termination | UNKNOWN |
| Certificate provider | UNKNOWN |
| HTTP-to-HTTPS redirect | UNKNOWN |
| Database exposure | UNKNOWN |
| Redis exposure | UNKNOWN |
| Firewall rules | UNKNOWN |
| Publicly reachable ports | UNKNOWN |
| Webhook routing | UNKNOWN |
| Network isolation between services | UNKNOWN |

The deployment endpoint domain is part of the approved API contract.
Its current availability and network path require separate live evidence.

* * *

## 13. Backup and Update Status

| Property | Status |
| --- | --- |
| Backup directory | UNKNOWN |
| Database backup mechanism | UNKNOWN |
| File backup mechanism | UNKNOWN |
| Backup schedule | UNKNOWN |
| Restore test status | UNKNOWN |
| OS automatic updates | UNKNOWN |
| Docker update policy | UNKNOWN |
| Rollback procedure | UNKNOWN |

No backup or update policy is approved by the evidence baseline used for this document.

* * *

## 14. Local Development Environment

User-specific Windows paths, npm installation paths and local Open WebUI URLs are not part of the canonical production-runtime contract.
They may be documented separately only when supported by current local evidence.
Status:

```text
LOCAL DEVELOPMENT ENVIRONMENT — OUTSIDE CURRENT ENVIRONMENT BASELINE
```

* * *

## 15. Log Evidence

No current server, Docker, n8n execution or reverse-proxy logs were supplied for this environment audit.
Therefore no environment statement has status `CONFIRMED BY LOGS`.
Logs must be:

*   sanitized;
    
*   limited to relevant metadata;
    
*   free of API keys, tokens and credential values;
    
*   associated with an explicit collection timestamp.
    

* * *

## 16. Evidence Required for Runtime Verification

A future read-only environment evidence pass may include sanitized outputs of:

```bash
date -Is
uname -a
cat /etc/os-release
nproc
free -h
df -h
docker version
docker compose version
docker compose ps
docker inspect <container> --format '<sanitized fields>'
docker network ls
docker volume ls
```

For n8n:

```bash
n8n --version
```

or an equivalent command executed inside the n8n runtime container.
Evidence collection must not:

*   display `.env`;
    
*   print secret values;
    
*   print authorization headers;
    
*   export credentials;
    
*   modify containers;
    
*   restart services;
    
*   run workflow deployments.
    

* * *

## 17. Current Environment Status

### CONFIRMED BY JSON

*   eight canonical workflow definitions;
    
*   configured external integrations;
    
*   Google Sheets sheet names;
    
*   Pinecone namespaces;
    
*   Jina embedding model and dimensions;
    
*   internal Gotenberg hostname reference;
    
*   environment-variable names `TELEGRAM_BOT_TOKEN` and `ADMIN_CHAT_ID`;
    
*   workflow-level execution settings for WF1, WF5 and WF6.
    

### CONFIRMED BY LIVE DATA

*   n8n version `2.32.7`.
    

### CONFIRMED BY LOGS

*   none in the current evidence baseline.
    

### UNKNOWN

*   host operating system and hardware;
    
*   Docker and container topology;
    
*   global n8n configuration;
    
*   database and queue configuration;
    
*   reverse proxy and TLS;
    
*   persistent paths;
    
*   backup and update mechanisms;
    
*   provider and credential validity;
    
*   runtime availability of configured integrations;
    
*   active/published workflow state.
    

### CONFLICT

The previous document version claimed n8n `2.30.7+`, while the current compatibility and live baseline is n8n `2.32.7`.
The previous global statement `Save Successful Executions: none` was incompatible with the canonical workflow-level setting `saveDataSuccessExecution: all` present in WF1, WF5 and WF6.

* * *

## 18. Verification Checklist

*   n8n compatibility baseline updated to 2.32.7.
    
*   Deployment contract synchronized with ADR-009 and ADR-010.
    
*   Workflow JSON profiles synchronized with ADR-024.
    
*   External dependencies synchronized with canonical workflow JSON.
    
*   Google Sheets and Pinecone usage synchronized with `WORKFLOW_MAP.md`.
    
*   Workflow-level settings separated from global runtime settings.
    
*   Secret values excluded.
    
*   Active/published state not inferred from GitHub.
    
*   Historical hardware and container snapshots removed from confirmed facts.
    
*   Local development paths excluded from the production baseline.
    
*   Current host evidence collected.
    
*   Current Docker/container evidence collected.
    
*   Global n8n configuration verified.
    
*   Network and TLS configuration verified.
    
*   Backup and restore configuration verified.
    
*   Runtime integration health verified.
