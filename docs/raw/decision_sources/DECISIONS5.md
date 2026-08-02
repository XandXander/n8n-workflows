DECISIONS.md

Project Decision Log

Decision: Stateless Workflow Deployment Pipeline via Python Manager

Date

July 2026

Context

Modifying complex JSON workflows in n8n directly via LLM chat leads to context
degradation, invalid schemas, hallucinated id fields, and overwritten variables.
Relying on chat history to maintain workflow state was error-prone.

Decision

Implemented a Python-based Open WebUI tool (n8n_workflow_manager) that enforces
a "Stateless" development approach.

  - The LLM must use read_workflow_file before making modifications.
  - The tool handles validation, auto-fixing (stripping id, versionId, inserting
    real credentials for PLACEHOLDER_*), and deployment via API PUT/PATCH.
  - The tool automatically syncs changes to a local Git repository.

Alternatives Considered

  - Direct HTTP requests from LLM to n8n API (Rejected: LLM hallucinates
    read-only fields, breaking the API).
  - Manual copy-pasting of JSON from chat to n8n UI (Rejected: Time-consuming,
    error-prone).

Why This Decision Was Made

  - Technical constraints of the n8n API (strict rejection of root/node id
    fields during updates).
  - Token economy: Prevents outputting massive JSONs into the chat, reducing
    context window bloat.

Trade-offs

Плюсы:

  - Zero-touch resolution for syntax errors.
  - Version control (Git) is automated.
  - Protection against n8n schema corruption.

Минусы:

  - Requires strict adherence to the tool's interface.
  - Obscures some real-time errors from the LLM if the Python script handles
    them silently.

Consequences

Significantly stabilized the development process. The LLM acts purely as a logic
designer, while the Python tool acts as a strict compiler/deployer.

Current Status

Accepted

Decision: "Self-Healing" Multi-Stage JSON Parser (Parser Guard)

Date

July 2026

Context

LLMs (DeepSeek/Groq) frequently return JSON wrapped in markdown blockquotes
(```json), or data gets double-stringified ("\"{\\\"service\\\"...\"") when
passed between n8n Sub-Workflows via the Execute Workflow node and Google
Sheets. This caused cascading failures in downstream query builders.

Decision

Implemented a universal "Parser Guard" JS pattern in Code nodes.

  - Strips markdown formatting before parsing.
  - Uses a while loop (up to 3 attempts) to unwrap nested JSON.stringify layers.
  - Uses try/catch with safe fallback objects (e.g., intent: 'error') to prevent
    the entire pipeline from crashing with critical node errors.

Alternatives Considered

  - Relying on LLM response_format: { "type": "json_object" } exclusively
    (Rejected: Does not prevent double-stringification by n8n or Google Sheets).
  - Using n8n's native JSON parse node (Rejected: Lacks markdown stripping and
    loop-unwrapping logic).

Why This Decision Was Made

To ensure workflow resilience (Self-Healing). Downstream nodes (like Serper)
require guaranteed structured objects to prevent generating garbage queries
(e.g., "услуга" Россия).

Trade-offs

Плюсы:

  - Pipeline survives bad LLM responses and data-type coercion bugs in n8n.

Минусы:

  - Masks upstream errors; requires manual log inspection to realize the LLM is
    failing to format correctly.

Consequences

Eliminated undefined variable errors in search query generation.

Current Status

Accepted

Decision: Fallback Recovery for Silent 0-Result Stops

Date

July 31, 2026

Context

If Serper Search found 0 results, n8n passed an empty array ([]). n8n's native
behavior is to silently stop branch execution upon receiving empty arrays. This
caused downstream processes (like Report Generation) to receive null for job_id,
leading to workflow crashes.

Decision

Enforce "Always Output Data" in Google Sheets Read nodes. Inject IF nodes
immediately after data fetches. If an array is empty (True branch), use a Set
node to manually recover the job_id from the parent workflow scope ($('Set Job
Vars').item.json.job_id) and route directly to the Report Trigger, bypassing the
analysis loop.

Alternatives Considered

  - Leaving the silent stop (Rejected: User never receives the final PDF
    report).

Why This Decision Was Made

Business requirement: The user must receive a PDF report acknowledging that the
search completed, even if the result is "0 leads found".

Trade-offs

Плюсы:

  - Guaranteed workflow completion and user notification.

Минусы:

  - Increased visual complexity of the n8n graph (more routing nodes).

Consequences

Pipeline stability achieved. Empty results now correctly generate an empty PDF
report instead of crashing the system.

Current Status

Accepted

Decision: Removal of site: Operator from Serper Queries

Date

July 2026

Context

The system used specific search operators (e.g., site:avito.ru "услуга") to find
private B2C leads. This started throwing HTTP 400 errors.

Decision

Remove site: operator from all search queries in Build Query Matrix. Replace
with semantic keywords (e.g., "услуга" регион Авито).

Alternatives Considered

  - Switching to a paid proxy / different search API (Rejected: Cost
    constraints).

Why This Decision Was Made

The Free tier of Serper API actively blocks the site: operator.

Trade-offs

Плюсы:

  - Restored search functionality without API errors.

Минусы:

  - Decreased precision of search results (more SEO spam, fewer direct target
    pages).

Consequences

Workflow successfully proceeds, but lead quality for B2C sources degraded.

Current Status

Accepted

Decision: HTML to PDF Rendering via Gotenberg

Date

July 2026

Context

OSINT reports generated in Markdown needed to be converted to branded PDF files
for delivery via Telegram.

Decision

Deploy a local Gotenberg Docker container (gotenberg/gotenberg:8) running
alongside n8n. Use an n8n Code Node to convert Markdown to HTML, then generate a
binary buffer named index.html with text/html mime type. Send this via
multipart/form-data to Gotenberg's /forms/chromium/convert/html endpoint.

Alternatives Considered

  - Native n8n HTML-to-PDF nodes / wkhtmltopdf (Rejected: Chromium engine in
    Gotenberg provides better modern CSS support).
  - Cloud PDF generation APIs (Rejected: Privacy concerns and recurring costs).
  - Using n8n's Convert to File node (Rejected: Failed to correctly attach the
    binary stream in the exact format Gotenberg requires for HTML conversion).

Why This Decision Was Made

Provides a free, scalable, and highly customizable (CSS) PDF generation pipeline
entirely within the self-hosted infrastructure.

Trade-offs

Плюсы:

  - No external dependencies or API costs.
  - High-quality rendering.

Минусы:

  - Resource heavy (requires --memory=512m minimum per render).
  - Strict HTTP request formatting required (multipart files containing
    index.html).

Consequences

Reliable PDF generation integrated directly into the report workflow.

Current Status

Accepted

Decision: Disabling Firecrawl for Protected Targets (B2C/Tenders)

Date

July 31, 2026

Context

The LLM was generating "perfect" but completely fake reports (hallucinating
+7 911... phone numbers) for private leads and tenders. Investigation revealed
Firecrawl was hitting Cloudflare/Captcha blocks on Avito, Telegram, and
Zakupki.gov.ru, returning "Access Denied". The LLM attempted to fulfill the
prompt despite the lack of real data.

Decision

Temporarily disable Firecrawl scraping in the Tender intelligence branch. Pass
only the title and snippet from the Serper search results directly to the LLM
for relevance scoring. Acknowledge that B2C scraping is non-functional with the
current toolset.

Alternatives Considered

  - Upgrading to residential proxies for Firecrawl (Rejected: High cost,
    implementation complexity).
  - Adding anti-hallucination grounding prompts (Considered, but does not solve
    the lack of underlying data).

Why This Decision Was Made

Technical limitation. Standard headless browsers/scrapers cannot reliably bypass
enterprise-grade anti-bot systems (GOST encryption, Cloudflare) out-of-the-box.

Trade-offs

Плюсы:

  - Stopped LLM hallucinations and fake data generation.

Минусы:

  - Drastic reduction in data depth. Tender analysis relies entirely on search
    engine snippets, missing full technical specifications. B2C lead generation
    effectively paralyzed.

Consequences

System is currently heavily biased toward, and only reliable for, B2B OSINT
(analyzing open corporate websites).

Current Status

Accepted (Workaround)

Decision: Extended Timeouts and Retry Policies for DeepSeek API

Date

July 31, 2026

Context

The DeepSeek All Scores node in the Analyst workflow was frequently failing with
ECONNABORTED timeout 60000ms exceeded and ECONNRESET.

Decision

1.  Increase HTTP Request Node timeout from 60,000ms to 120,000ms.
2.  Implement Retry On Fail (Max Tries: 3, Wait Between Tries: 5000ms).
3.  Explicitly add the phrase "You must respond with a JSON object" to the
    system prompt alongside response_format: { type: 'json_object' }.

Alternatives Considered

  - Switching to a faster, smaller model (Rejected: Needed the reasoning
    capability for complex scoring).

Why This Decision Was Made

Heavy models analyzing large scraped payloads take longer than standard API
timeout windows. DeepSeek's API routing occasionally drops connections,
requiring native resiliency. Omitting explicit JSON instructions caused
undocumented HTTP 400 errors masked as network resets.

Consequences

Stabilized LLM processing for large context windows.

Current Status

Accepted

Decision: Idempotency Guard for Telegram Webhooks

Date

July 2026

Context

Telegram webhooks occasionally re-delivered updates, causing the workflow to
trigger multiple times for the same user request.

Decision

Implement a Code Node right after the Telegram Trigger that utilizes
getWorkflowStaticData('global') to store the last 200 update_ids. Any incoming
item with a matching update_id is filtered out.

Why This Decision Was Made

Prevents duplicate pipeline executions, saving API costs (LLM tokens, Search
queries) and preventing duplicate database entries.

Current Status

Accepted

Major Architectural Decisions

1.  Micro-Workflow Architecture: The system is split into modular sub-workflows
    (Core Router, Search Engine, Analyst, Report Generator) executed via Execute
    Workflow nodes.
2.  Externalized State Management: Google Sheets is used as the central database
    (jobs, leads, companies, tenders) to pass state between decoupled
    sub-workflows, avoiding memory bloat in n8n execution context.
3.  Self-Hosted Infrastructure: Relies on Docker (n8n, PostgreSQL/pgvector,
    Redis, Gotenberg, Traefik) on a 2 vCPU / 3.8 GB RAM VPS, prioritizing data
    control and minimal recurring server costs.

Technology Choices

  - n8n: Core automation engine. Chosen for visual debugging, sub-workflow
    execution, and native API flexibility.
  - Docker / Ubuntu: Chosen for isolated, predictable deployments and ease of
    managing sidecar services (Gotenberg, Redis).
  - PostgreSQL (pgvector): Chosen as the core n8n database, with pgvector
    extension available for future local embedding storage.
  - Pinecone: Chosen as the primary Vector DB for fast deduplication (check
    duplicate) and memory.
  - Jina Embeddings (jina-embeddings-v3): Chosen for passage/query retrieval
    with 1024 dimensions.
  - LLM Providers:
      - DeepSeek (deepseek-v4-flash / pro): Chosen for cost-effective,
        high-quality reasoning and JSON generation.
      - Groq (Llama 3.1 8B): Chosen for instant intent classification (speed) on
        the free tier.
  - Serper / Tavily: Chosen for search. Serper used for general search; Tavily
    specified for advanced depth (though Serper is primary in the current
    matrix).
  - Firecrawl: Chosen for Markdown extraction from URLs, though struggling with
    bot protection.
  - Gotenberg: Chosen for highly customizable HTML-to-PDF rendering without
    cloud dependencies.

Rejected Approaches

  - Relying on Chat History for Workflow Updates: Rejected due to LLM context
    degradation resulting in corrupted JSON schemas. Replaced by a stateless
    Python manager tool.
  - Direct Scraping of Avito/Zakupki with Firecrawl: Rejected due to Cloudflare
    blocks causing empty data and LLM hallucinations.
  - Using site: operators in free Serper API: Rejected due to HTTP 400 errors.
  - Implicit Array Propagation in n8n Loops: Rejected because empty arrays cause
    silent branch termination. Requires explicit Always Output Data and IF
    fallbacks.
  - Using Convert to File for HTML->PDF prep: Rejected. Creating the buffer
    directly in a Code Node using prepareBinaryData proved necessary for
    Gotenberg's strict multipart requirements.

Cost vs Quality Decisions

  - Free Tier Reliance (Groq / Serper):
      - Choice: Selected free tiers to minimize operational costs.
      - Trade-off: Leads to strict rate limits (Groq 429s require Wait nodes),
        operator restrictions (Serper blocking site:), and occasional connection
        instability, necessitating heavy retry logic inside workflows.
  - Firecrawl vs Dedicated Proxies/APIs:
      - Choice: Used Firecrawl as a general-purpose scraper instead of buying
        specialized access to B2B/B2C platforms.
      - Trade-off: Completely lost the ability to scrape protected targets
        (Tenders, Avito, TG). Quality of leads relies solely on search engine
        snippets for these sources.

Lessons Learned

  - The Hallucination Danger of "Perfect" Prompts: If an LLM is instructed to
    extract 5 leads and format them perfectly, but is fed a Cloudflare "Access
    Denied" page, it will invent 5 highly realistic, fake leads to satisfy the
    system prompt. Grounding and input validation are critical.
  - n8n Array Handling: Empty arrays ([]) silently stop execution branches.
    Designing for failure/empty states requires explicitly checking array
    lengths and maintaining fallback routing.
  - State Loss in Sub-Workflows: Triggering a sub-workflow without explicitly
    passing required parameters (like job_id) via the Execute Workflow node will
    permanently erase that context from the pipeline.

Decision Debt

  - B2C Lead Generation is Broken: Current search+scrape stack cannot bypass
    anti-bot systems on Avito, VK, Telegram, or Zakupki.gov.ru. This requires a
    major architectural pivot (e.g., using official APIs, Apify, or residential
    proxies).
  - Tender Parsing Relies on Snippets: Due to the above, tenders are scored
    based on 160-character search snippets rather than full technical
    documentation. The scoring accuracy is fundamentally compromised.
  - Rate Limit Handlers: The Throttle Check node (WF8) notes stub — реализовать
    через Sheets-счётчик при необходимости. This is technical debt; Groq/Serper
    limits are not systematically tracked, risking pipeline crashes during high
    load.
  - Double JSON Serialization: The architecture still passes stringified JSON
    through Google Sheets and sub-workflows, requiring the heavy while (typeof
    entities === 'string') unwrapping hack. A unified internal data contract
    needs to be established.
