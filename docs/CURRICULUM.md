# Curriculum Specification

All instructional data lives in structured JSON files under `assets/curriculum/` and is validated at load time and in unit tests (`test/curriculum_integrity_test.dart`) via `CurriculumValidator.validate`.

---

## 1. Curriculum Scale & Assets

| Asset File | Contents | Count |
| --- | --- | --- |
| `assets/curriculum/modules.json` | Modules 1–15 metadata, outcomes, prerequisites, mini-projects, mastery checklists | 15 modules |
| `assets/curriculum/checkpoints_01_03.json` | Modules 1–3 substantive checkpoints | 32 checkpoints |
| `assets/curriculum/checkpoints_04_06.json` | Modules 4–6 substantive checkpoints | 36 checkpoints |
| `assets/curriculum/checkpoints_07_09.json` | Modules 7–9 substantive checkpoints | 40 checkpoints |
| `assets/curriculum/checkpoints_10_12.json` | Modules 10–12 substantive checkpoints | 38 checkpoints |
| `assets/curriculum/checkpoints_13_15.json` | Modules 13–15 substantive checkpoints | 40 checkpoints |
| `assets/curriculum/comparisons.json` | Structured comparison cards (architecture trade-offs & decision rules) | 10 cards |
| `assets/curriculum/projects.json` | Portfolio-grade capstones with rubrics, metrics templates, & security checklists | 4 projects |
| `assets/curriculum/glossary.json` | Searchable terminology with plain-English & technical explanations | 70 terms |
| `assets/curriculum/diagnostic.json` | Diagnostic placement quiz tailored to experienced n8n builders | 10 questions |

**Totals**: **15 modules**, **186 checkpoints** (~4,022 minutes / ~67 estimated hours), **10 comparison cards**, **4 capstone projects**, **70 glossary terms**, and **10 diagnostic placement questions**.

---

## 2. Module Breakdown

| # | Module ID | Title | Checkpoints | Est. Time | Prerequisites |
| --- | --- | --- | --- | --- | --- |
| 1 | `m01` | Engineering Foundations | 8 | 2.6h (158m) | None |
| 2 | `m02` | Computer, Terminal, and Git Foundations | 8 | 2.6h (158m) | `m01` |
| 3 | `m03` | Networking, HTTP, and Hosting | 16 | 5.2h (314m) | `m02` |
| 4 | `m04` | Python for Automation | 12 | 3.9h (232m) | `m02`, `m03` |
| 5 | `m05` | APIs and FastAPI | 12 | 4.1h (244m) | `m03`, `m04` |
| 6 | `m06` | LLM Fundamentals | 12 | 3.9h (234m) | `m01`, `m04`, `m05` |
| 7 | `m07` | Pydantic and Data Contracts | 14 | 4.4h (264m) | `m04`, `m05`, `m06` |
| 8 | `m08` | LangChain Foundations | 12 | 3.8h (226m) | `m06`, `m07` |
| 9 | `m09` | Retrieval and RAG | 14 | 4.4h (266m) | `m06`, `m07`, `m08` |
| 10 | `m10` | LangGraph Fundamentals | 14 | 4.6h (276m) | `m07`, `m08`, `m09` |
| 11 | `m11` | Agent Engineering | 12 | 3.8h (230m) | `m09`, `m10` |
| 12 | `m12` | n8n + Python + AI Integration | 12 | 3.9h (236m) | `m05`, `m07`, `m10` |
| 13 | `m13` | Evaluation and Observability | 12 | 4.2h (250m) | `m06`, `m09`, `m11` |
| 14 | `m14` | Deployment, Cloudflare, and Security | 16 | 5.2h (314m) | `m03`, `m05`, `m12` |
| 15 | `m15` | Production Engineering and Career Portfolio | 12 | 3.7h (220m) | `m13`, `m14` |

*(Prerequisites are informative and softly surfaced on both the Roadmap and Lesson Detail views—learners can explore any module without hard locks.)*

---

## 3. Instructional Structure per Checkpoint

Every checkpoint includes:

- Learning objectives & difficulty/effort estimate
- Plain-English mental model & rigorous technical explanation
- **Why It Matters**, **When to Use**, and **When NOT to Use**
- Prerequisite checkpoints
- Worked code examples (with language tag and horizontal scroll support)
- Linked comparison cards (where relevant)
- Practical exercise & common engineering mistakes
- Concrete acceptance criteria
- Multiple-choice and scenario-based knowledge check questions with explanations for **both** correct and incorrect options
- Official HTTPS documentation links (`MDN`, `Python 3`, `FastAPI`, `Pydantic`, `LangChain`, `LangGraph`, `n8n`, `Cloudflare`, `OWASP LLM Top 10`)

---

## 4. Comparison Cards (`comparisons.json`)

1. LangChain vs. LangGraph (`comp_langchain_vs_langgraph`)
2. Pydantic Models vs. Ordinary Dictionaries (`comp_pydantic_vs_dict`)
3. Workflow vs. Agent (`comp_workflow_vs_agent`)
4. Localhost vs. Public Host (`comp_localhost_vs_public`)
5. HTTP vs. HTTPS (`comp_http_vs_https`)
6. Webhook vs. Polling (`comp_webhook_vs_polling`)
7. RAG vs. Fine-Tuning (`comp_rag_vs_finetuning`)
8. Cloudflare Tunnel vs. Hosting (`comp_cf_tunnel_vs_hosting`)
9. n8n Orchestration vs. Python Backend Service (`comp_n8n_vs_python_service`)
10. Authentication (AuthN) vs. Authorization (AuthZ) (`comp_authN_vs_authZ`)

---

## 5. Capstone Projects (`projects.json`)

| ID | Capstone | Core Modules | Highlights |
| --- | --- | --- | --- |
| `p01` | **Support Triage Assistant** | `m01`, `m05`, `m06`, `m07`, `m13` | FastAPI + Pydantic triage service, structured urgency/category contract, baseline eval set |
| `p02` | **Document Processing Pipeline** | `m04`, `m07`, `m09`, `m13` | Chunking, metadata-filtered retrieval, citation verification, deletion/update lifecycle |
| `p03` | **Human-Approved Research Workflow** | `m08`, `m10`, `m11`, `m13` | Stateful LangGraph workflow, loop budgets, human-in-the-loop interrupts before side effects |
| `p04` | **n8n + Python AI Service** | `m03`, `m05`, `m10`, `m12`, `m14`, `m15` | End-to-end n8n webhook trigger calling Dockerized FastAPI service safely behind Cloudflare Tunnel/Access |

Each capstone provides an architecture diagram, MVP/intermediate/hardening milestones, deliverables, test cases, rubric, evaluation dataset guidance, security checklist, portfolio README template, and editable fields for the learner's own GitHub URL, measured metrics, and reflection.
