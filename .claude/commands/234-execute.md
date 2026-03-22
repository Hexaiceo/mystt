Based on the `architecture.md` file in the current project, execute the complete architecture implementation pipeline consisting of three sequential phases. Run all phases automatically without stopping for user confirmation — accept all permissions, tool calls, and agent access automatically. Always answer "yes and don't ask again" to any internal prompts.

---

## PHASE 1: Implementation Plan Creation

Read `architecture.md` and create a detailed implementation plan file called `implementation-plan.md`:

1. **Task Decomposition**: Break the entire architecture into granular, actionable tasks. For each task define:
   - Clear objective and scope
   - Input requirements and dependencies on other tasks
   - Success criteria (measurable, verifiable)
   - Estimated complexity (S/M/L)

2. **Execution Strategy**: Classify every task as:
   - **Parallel** — can run simultaneously with other tasks (no shared dependencies)
   - **Sequential** — must wait for specific predecessor tasks to complete
   - Group tasks into numbered **Phases** where all tasks within a phase can run in parallel, and phases execute sequentially

3. **Risk Assessment**: For each phase, identify potential risks and define mitigation strategies

4. **Verification Protocol**: Each task must end with:
   - Automated verification step (test, lint, build, or manual check definition)
   - On failure: fix → re-verify → loop until passing
   - On success: log result and proceed

Use agents to analyze the architecture, identify optimal parallelization, and produce the highest quality plan. If any aspect of the architecture is ambiguous, make the best reasonable decision and document the assumption in the plan — do NOT ask the user.

**Output**: Save as `implementation-plan.md` in the project root.

---

## PHASE 2: Session Task Mapping

Read the generated `implementation-plan.md` and create `sessions-for-plan-tasks.md`:

1. **Session Design**: Map each Phase from the plan into one or more Claude Code sessions:
   - Tasks that can run in parallel → assign to concurrent sessions
   - Tasks with dependencies → assign to sequential sessions respecting order
   - Each session gets a unique ID (e.g., `S1.1`, `S1.2`, `S2.1`)

2. **Task Specifications**: For each session, define:
   - Session ID and phase number
   - List of tasks with full descriptions copied from the plan
   - Input files/artifacts required
   - Output files/artifacts expected
   - Verification commands to run after completion
   - Dependencies on other sessions (which sessions must complete first)

3. **Execution Order Matrix**: Create a clear execution order showing:
   - Which sessions run in parallel (same wave)
   - Which sessions are sequential (next wave)
   - Critical path identification

4. **Optimization**: Split large sessions into smaller ones for better parallelization. Merge trivially small tasks into combined sessions for efficiency.

Use agents to parallelize the creation of session definitions. Process phases independently and merge results.

**Output**: Save as `sessions-for-plan-tasks.md` in the project root.

---

## PHASE 3: Session Execution

Read `sessions-for-plan-tasks.md` and execute all sessions:

1. **Session Orchestration**:
   - Open Claude Code agent sessions according to the execution order matrix
   - Run parallel sessions simultaneously (same wave)
   - Wait for all sessions in a wave to complete before starting the next wave
   - Pass required artifacts between sessions

2. **Per-Session Protocol**:
   - Execute all tasks defined for the session
   - After task completion, run the verification commands defined in Phase 2
   - Collect and log all outputs and results

3. **Error Handling & Recovery**:
   - If a task fails: immediately retry with error context
   - If retry fails: open a dedicated fix session targeting that specific task
   - Loop: fix → verify → repeat until the task passes
   - Only proceed to next wave after ALL tasks in current wave are verified

4. **Verification Sessions**:
   - If any session does not return explicit success feedback, launch a separate verification agent session
   - Verification session checks: files created/modified, tests passing, build succeeding, expected outputs present
   - Report results back to main orchestration

5. **Output Validation**:
   - After each session closes, verify all expected output files exist and are correctly written
   - If outputs are missing or corrupted, re-launch the session

6. **Final Summary**:
   - After all sessions complete, produce `execution-report.md` with:
     - Status of each session (passed/failed/retried)
     - List of all files created or modified
     - Any assumptions made or deviations from the plan
     - Overall success/failure assessment

Automatically accept all commands, file access, and tool permissions required by Claude and agents in all sessions. For any prompt asking for user input, always select "yes" / "accept" / "allow" and "don't ask again".

**Output**: Save as `execution-report.md` in the project root.
