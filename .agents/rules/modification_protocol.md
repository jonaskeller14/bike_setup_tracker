---
trigger: always_on
---

Strict Modification Protocol: Surgical Edits Only

Scope of Change: You are strictly forbidden from modifying lines of code that are not directly required for the functional implementation of the task.

Zero-Reformatting Policy: Do not perform "cleanup," "beautification," or "reformatting" on existing code to meet style guides (e.g., line length, trailing commas, or quote types) unless those lines are being changed for functional reasons.

Indentation Integrity: Only adjust indentation for existing code if it is being wrapped in a new logical block (like an if statement or try/except). Do not "re-align" unrelated surrounding blocks.

Diff Minimization: Prioritize a "clean diff." If a task can be accomplished by changing 3 lines instead of 10, choose the 3-line approach.

Generation vs. Editing: For entirely new functions or files, follow standard style guidelines. For existing code, adopt the "leave it as you found it" (Campsite Rule) only for the lines you touch.