# Session Memory Capture

You are about to save everything valuable from this conversation into the `memory` MCP server. This runs at the end of a session, so be thorough — anything not captured now is lost when context resets.

Do NOT ask questions. Analyze the full conversation and execute immediately.

---

## Step 1: Read existing memory

Call `mcp__memory__read_graph` to get the current knowledge graph. You need this to:
- Avoid creating duplicate entities (use `add_observations` on existing ones instead of `create_entities`)
- Know what relations already exist
- Understand naming conventions already in use

Hold this graph in working memory for the rest of the process.

## Step 2: Analyze the conversation

Scan the ENTIRE conversation from top to bottom. Extract every piece of valuable information, organized into these categories:

### What to extract

**Projects & codebases** — repo names, project names, what they do, tech stacks, directory structures, deployment targets, environments
- Entity type: `project`, name prefix: `project:`
- Example: `project:myapp`

**Technologies & tools** — languages, frameworks, libraries, CLI tools, services, APIs used or discussed
- Entity type: `technology`, name prefix: `tech:`
- Example: `tech:nextjs`, `tech:prisma`

**Decisions & rationale** — architectural choices, library selections, design tradeoffs, "we chose X because Y"
- Entity type: `decision`, name prefix: `decision:`
- Example: `decision:jwt-over-sessions`

**Bugs & fixes** — error messages (exact text), root causes, solutions applied, workarounds
- Entity type: `bug`, name prefix: `bug:`
- Example: `bug:cors-preflight-failing`

**Patterns & techniques** — reusable approaches, code patterns, configuration recipes, deployment procedures
- Entity type: `pattern`, name prefix: `pattern:`
- Example: `pattern:retry-with-backoff`

**People & teams** — who's responsible for what, contacts, team structures
- Entity type: `person`, name prefix: `person:`

**Configuration & environment** — env vars, ports, URLs, credentials locations (not values), file paths that matter, CLI flags that solved problems
- Entity type: `config`, name prefix: `config:`
- Example: `config:myapp-env`

**Next steps & TODOs** — things the user said they'd do later, planned work, open questions
- Entity type: `todo`, name prefix: `todo:`

### What NOT to extract
- Small talk, greetings, "thanks", meta-discussion about this skill
- Anything trivially obvious from the code itself (like "the project has a package.json")
- Vague observations — every observation must be a specific, actionable fact

## Step 3: Deduplicate against existing graph

For each entity you want to save, check the graph from Step 1:
- **Entity exists?** → use `mcp__memory__add_observations` to append new facts. Do NOT re-add observations that are already stored (compare content, not exact string match — semantically equivalent = duplicate).
- **Entity doesn't exist?** → use `mcp__memory__create_entities` to create it with all observations.
- **Relation exists?** → skip it.
- **Relation doesn't exist?** → queue it for creation.

If an existing entity has observations that are now outdated based on what happened in this session, use `mcp__memory__delete_observations` to remove the stale ones before adding corrected versions.

## Step 4: Create the session index entity

Every `/remember` invocation creates a session entity:

- **Name**: `session:YYYY-MM-DD:brief-topic` (use today's date and a 2-4 word slug describing the main theme)
- **Type**: `session`
- **Observations**: A list of what happened, e.g.:
  - "Refactored auth middleware to use JWT validation"
  - "Fixed CORS bug — missing Access-Control-Allow-Headers for Authorization"
  - "Decided to use Prisma over Drizzle for type safety"
  - "Set up CI pipeline with GitHub Actions"
  - "Next: implement rate limiting on /api/auth endpoints"

If multiple sessions happen on the same date, add a numeric suffix: `session:2026-03-21-2:topic`.

## Step 5: Create relations

Relations connect entities and make the graph navigable. Use active voice for relation types. Common relations:

| From | Relation | To |
|------|----------|-----|
| `project:X` | `uses` | `tech:Y` |
| `project:X` | `deployed_on` | `tech:Y` |
| `bug:X` | `fixed_in` | `project:Y` |
| `bug:X` | `caused_by` | `tech:Y` |
| `decision:X` | `affects` | `project:Y` |
| `decision:X` | `chose` | `tech:Y` |
| `decision:X` | `rejected` | `tech:Y` |
| `pattern:X` | `applies_to` | `project:Y` |
| `person:X` | `works_on` | `project:Y` |
| `session:X` | `covered` | `project:Y` |
| `session:X` | `fixed` | `bug:Y` |
| `session:X` | `created` | `decision:Y` |
| `todo:X` | `belongs_to` | `project:Y` |

Create relations in a single `mcp__memory__create_relations` call with all relations batched together.

## Step 6: Execute the writes

Batch your MCP calls efficiently:
1. One `mcp__memory__create_entities` call with ALL new entities
2. One `mcp__memory__add_observations` call with ALL additions to existing entities
3. One `mcp__memory__delete_observations` call if any stale observations need removal
4. One `mcp__memory__create_relations` call with ALL new relations

Make independent calls in parallel where possible.

## Step 7: Print the summary

After all writes succeed, print a summary in this exact format:

```
## Memory updated — [N] entities, [M] observations, [K] relations

**New entities:**
  - `session:2026-03-21:auth-refactor` — 5 observations
  - `bug:cors-headers` — created with fix

**Updated entities:**
  - `project:myapp` — 3 new observations added
  - `tech:nextjs` — 1 new observation added

**Relations:**
  - `project:myapp` → uses → `tech:nextjs`
  - `bug:cors-headers` → fixed_in → `project:myapp`
  - `session:2026-03-21:auth-refactor` → covered → `project:myapp`
```

Count [N] as total entities touched (created + updated), [M] as total observations written (new + added), [K] as relations created.

If nothing meaningful was found to save, say so honestly rather than manufacturing fluff observations.

---

## Quality bar for observations

Each observation should pass this test: "If I read this in 3 months with no other context, would it be useful?"

**Good observations:**
- "Uses Next.js 14 App Router with server components for /dashboard routes"
- "CORS fix: added 'Authorization' to Access-Control-Allow-Headers in middleware.ts:47"
- "Database connection string is in .env.local as DATABASE_URL, pointing to Supabase Postgres"
- "Chose pnpm over npm because of workspace support and disk efficiency"
- "Error 'ECONNREFUSED 127.0.0.1:5432' was caused by Postgres not running — fix: brew services start postgresql@16"

**Bad observations:**
- "Worked on the project"
- "Fixed a bug"
- "Uses JavaScript"
- "Had some issues with the database"
