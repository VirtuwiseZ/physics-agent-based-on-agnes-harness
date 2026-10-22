# AGENTS.md - Workspace Instructions & AI Progressive Disclosure Router

> **Current Branch (`UPC`) Mission**: This workspace on branch `UPC` is strictly focused on **University Physics Competition (UPC, 48h) modeling, MATLAB R2023b simulation co-pilot, and physics academic advising**.
> Upstream Agnes Harness engine development rules (Node.js/C++ daemon) are secondary and preserved at the bottom under `## Upstream Agnes Harness Core Engine (Reference Only)`.

---

## Level 0: AI Progressive Disclosure Master Router (Read This First)

To avoid context/token waste and guideline corruption, follow the **Progressive Disclosure** model:
1. Start with this Level 0 router (automatically inlined by DeepSeek Harness).
2. Read ONLY the Level 1 Quickstart corresponding to your immediate task.
3. Escalate to Level 2 Deep Specifications ONLY when an explicit "Escalation Signal" is triggered.

### 1. Absolute Engineering Red Lines (Must Follow Across All Tasks)
- **Branch Confinement**: All physics modeling, simulation, and dev-notes work MUST stay on branch `UPC`. NEVER checkout, modify, or push to `main` or `physics-agent`.
- **Git Push Prohibition**: NEVER execute `git push`. Only perform clean, localized `git commit` on branch `UPC`. Remote pushing is strictly reserved for human developers.
- **PowerShell 5.1 ASCII Encoding**: On Windows pwsh, multi-line Chinese commit messages passed inline with `-m "..."` will cause UTF-8 byte mangling and git log corruption. ALWAYS write commit messages to an external file (`commit_msg.txt`), commit with `git commit -F commit_msg.txt`, then delete the temporary file.
- **Human-AI Division of Labor**: Humans lead paper writing in Microsoft Word (`.docx`) and interactive MATLAB figure inspection. AI serves as scientific co-pilot: equation derivation, ODE/PDE coding, `.mat` data analysis, error recovery, and vision review. NEVER unilaterally generate full LaTeX papers unless explicitly requested.

### 2. Task Routing Matrix (Level 0 -> Level 1 Quickstarts)

| If Your Immediate Task Is... | Level 1 Quickstart / Router to Read | Happy Path Scope (80% Normal Cases) | Escalation Signal (When to Read Level 2) | Level 2 Deep Specification |
| :--- | :--- | :--- | :--- | :--- |
| **Git Commit / Branch / Environment** | [`dev-notes/notes-for-ai/_QUICKSTART.md`](dev-notes/notes-for-ai/_QUICKSTART.md) | Standard 3-step commit, ASCII safety, status checks | Multi-line Chinese commit formatting, sandbox permission denial, branch conflicts | [`commit规范与暂存操作指南.md`](dev-notes/notes-for-ai/commit规范与暂存操作指南.md)<br>[`分支管理与开发协作规范.md`](dev-notes/notes-for-ai/分支管理与开发协作规范.md) |
| **UPC Full-Cycle Coaching & Workflow** | [`physics-agent/knowledge/upc_competition_workflow_guide.md`](physics-agent/knowledge/upc_competition_workflow_guide.md) | 5-phase 48h rhythm, 6 logic steps, Word paper template, AI peer review | Full paper drafting, Word .docx generation, multi-question decomposition | [`paper_templates/UPC_Paper_Standard_Template.docx`](physics-agent/knowledge/paper_templates/UPC_Paper_Standard_Template.docx)<br>[`report_structure_guide.md`](physics-agent/knowledge/report_structure_guide.md) |
| **UPC Physics Modeling & MATLAB Simulation** | [`physics-agent/knowledge/matlab_upc_guide/README.md`](physics-agent/knowledge/matlab_upc_guide/README.md) | Problem-to-solver routing, 48h rhythm, 5 model quality defense lines | Solver stiffness/tolerance tuning, ODE/PDE code debugging, modern R2023b syntax pitfalls | [`01_solver_matrix.md`](physics-agent/knowledge/matlab_upc_guide/01_solver_matrix.md)<br>[`04_modern_matlab_style_guide.md`](physics-agent/knowledge/matlab_upc_guide/04_modern_matlab_style_guide.md)<br>[`02_battle_tested_templates/`](physics-agent/knowledge/matlab_upc_guide/02_battle_tested_templates/) |
| **External Parameters & Physical Constants** | [`physics-agent/knowledge/物理竞赛与仿真数据源权威指引.md`](physics-agent/knowledge/物理竞赛与仿真数据源权威指引.md) | Level 1 free public APIs (NASA, NIST) & Level 0 offline libraries | Network VPN/TUN blocking, restricted academic databases (CNKI, IEEE) | [`network_and_vpn_guidelines.md`](dev-notes/notes-for-ai/network_and_vpn_guidelines.md)<br>[`需人工查找与整理的数据源.md`](dev-notes/notes-for-ai/需人工查找与整理的数据源.md) |
| **Academic Figure Generation & Vision Loop** | [`physics-agent/knowledge/matlab_upc_guide/05_paper_figure_recipes.md`](physics-agent/knowledge/matlab_upc_guide/05_paper_figure_recipes.md) | 300 DPI `exportgraphics`, LaTeX font, tiledlayout recipes | Image visual inspection (`read_image`) shows overlapped text or clipped legends | [`report_structure_guide.md`](physics-agent/knowledge/report_structure_guide.md) |
| **Human Strategic Review & Learning Guide** | [`dev-notes/UPC备赛与AI科学协同工作流复盘总结.md`](dev-notes/UPC备赛与AI科学协同工作流复盘总结.md) | Human-facing summary of past rounds, high-value AI workflow details, study advice | N/A (Read when human asks for retrospective or workflow guidance) | Same document |

---

## Upstream Agnes Harness Core Engine (Reference Only)

# Working on Agnes Harness

Read [README.md](README.md), the [documentation](docs/README.md), and the relevant module before making changes. Development pull requests are currently limited to invited internal collaborators; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Repository map

- `packages/`: protocol, Core, Host, daemon, clients, extensions and supporting libraries.
- `examples/`: runnable plugin examples and explicit test fixtures.
- `docs/`: user guides, extension tutorials, architecture and maintenance policies.
- `tools/`: generation, acceptance checks, documentation verification and repository guards.
- `third-party/`: dependency provenance; root `NOTICE` and package-local licenses cover attribution.

Use the [source map](docs/develop/source-map.md) to locate the owning module. Preserve package boundaries and consume declared exports. Protocol schemas and generators own generated types and reference documents.

## Workflow

1. Inspect Git status, the configured remotes and recent changes. Preserve other contributors' work; integrate remote changes without rewriting shared history.
2. For changes to public APIs, architecture, storage or security boundaries, describe the design and compatibility impact before implementation.
3. Keep changes focused. Update the affected guides, contracts and meaningful tests in the same change.
4. Run checks appropriate to the affected behavior. Report the commands, results, failures and untested environments accurately.
5. Review the final diff before committing. Commit, push and publish only within the user's or maintainer's authorization.

## Build and checks

Use the Node.js requirement and pinned pnpm version in `package.json`. From the repository root:

```sh
pnpm install --frozen-lockfile
pnpm --filter @agnes/host build:native
pnpm --filter @agnes/system-node build:native
pnpm typecheck
pnpm lint
pnpm gen:check
node tools/public-docs/verify.mjs
pnpm exec vitest run tools/guards/src --maxWorkers=1
```

Run affected package tests from the repository root. `pnpm test` runs the fast tier, `pnpm test:heavy` runs the real-process and large-data tests (`*.e2e.test.ts`, `*.slow.test.ts`), and `pnpm test:all` runs both. Run a single file of either tier with `pnpm exec vitest run <file>`. A focused test command must actually execute matching tests. For a complete local runtime, follow the [installation guide](docs/guide/install.md).

## Tests

Keep the suite growing only where behavior grows.

- Prefer extending an existing test over adding a new one. For a bug fix, add the failing case to the nearest existing test (a new row in a parameterized table, or a stronger assertion) so it fails before the fix and passes after it. Add a new test or test file only for behavior no existing test covers.
- Test observable behavior at the module's contract: inputs, outputs, persisted state, emitted events and errors. Do not pin internal call counts, private helpers, incidental ordering or exact byte layouts unless that layout is itself the contract, such as a wire format, a prompt prefix or the ledger.
- Delete tests together with the code they cover. When a change makes a test redundant because its assertions are covered elsewhere, remove or merge it in the same change and name the covering test in the commit message.
- Choose the tier by file name. A test that starts real daemon, worker or CLI processes is `*.e2e.test.ts`; one that builds large ledgers or waits on real timers is `*.slow.test.ts`. Both run in the heavy tier; every other test file runs in the fast tier.

## Engineering boundaries

- Keep session facts and authorization decisions in their owning backend modules; clients render and request operations through supported interfaces.
- Maintain fail-closed behavior, lifecycle cleanup, cancellation and recovery semantics. Test refusal and failure paths when changing them.
- External UI libraries belong in `packages/web-ui`; other packages use its exports. Preserve the shared theme tokens, accessibility, CSP and public skin hooks.
- Keep guards meaningful. Update exact line budgets or fixture allowances only for reviewed changes; do not remove checks to hide a regression.
- Preserve third-party licenses, copyright notices and source attribution. Update dependency provenance when changing dependencies.
- Keep credentials, customer data, private traces, machine-specific configuration and internal project records out of the repository. Use isolated homes and synthetic accounts for tests.

Release requirements are in [release checks](docs/maintainers/release.md); document maintenance is described in [the maintenance guide](docs/maintainers/maintenance.md).
