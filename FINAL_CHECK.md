# Final Chapter 4 check — 30 September 2026

Chapter 4 is finalized in Group10_Chapter4_Final.docx/.pdf and PART4_REPORT_SECTION.md.
It covers the integration/validation/reporting responsibility called Part 4 in the work plan.

## Verified in this review

- Retrieved repository HEAD 05e8a6102599aa2e6b4e0bb4ef3feb51f36f13bc.
- Inspected the integrated component equations, supplied NASA helpers and data use,
  the work plan, both attached 2026 lectures, assignment description and rubric.
- Located and read the 2026 report template in Downloads.
- Ran verify_group10 in MATLAB R2026a: 21/21 residuals pass; efficiency reconstruction
  passes; direct-root temperature, pressure and exhaust-speed comparisons pass.
- Exhaust speed 778.827595 m/s; T4 1082.464159 K; shaft power 33.241777 MW.
- Extracted the deliverable ZIP and ran verify_group10 in a fresh MATLAB session
  after restoredefaultpath from a different current folder: all checks pass.
- All three final chapter pages were rendered through Word and visually checked.
- Component equations and all supplied General files are unchanged.
- Lecturer confirmation of unit component efficiencies was reiterated by the user.
- The chapter now includes a complete state table, residuals with units/tolerances,
  limits of the shared-database comparison, and entropy/nozzle interpretation.

## Full report assembly remains separate

The official 2026 template has component sections rather than a Chapter 4 heading.
Use this finalized chapter's results and discussion in the group's report as appropriate;
the standalone chapter is not represented as the complete template-based submission.
The template requires student names/numbers, input conditions, Table 1, component
procedures and code snippets with actual line numbers, and Table 2 with initial/final
mass fractions, gas constants, AF and equivalence ratio. The initial composition in
Table 2 is combined unburned air plus fuel, not air alone. The MATLAB console prints it.

The earlier reports/Group10_report_provisional.pdf in the original repository is a
legacy full-report draft, not this final chapter. Do not submit it as if template-complete.
The current template supersedes the handoff's earlier statement that it was unavailable.
No official GroupSettings file was attached in this review: inputs were cross-checked
against the repository and work plan, which agree. Fuel temperature 298.15 K is the
existing selected model reference state; the efficiency confirmation does not establish
an independent course requirement for this temperature.

Lecture 2 (2026), PDF p. 15, lists 9 October regular and 16 October late submission.
Check current Canvas submission rules and supply team details before submitting.
No Canvas submission, GitHub push or remote repository change has been made.

## Run

Extract Group10_Final_Package.zip, open the extracted folder in MATLAB and run
verify_group10. It regenerates results/. Python and Word are not required to run MATLAB.
