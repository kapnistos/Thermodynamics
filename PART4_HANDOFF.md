# Part 4 handoff - Group 10

## Completed work

- [x] Integrate the six states in one sequential MATLAB script.
- [x] Keep Group 10 inputs and provisional settings together.
- [x] Use script-relative paths for the unchanged NASA database/functions.
- [x] Independently evaluate 21 conservation/property residuals.
- [x] Compare actual and ideal component states and reconstruct efficiencies.
- [x] Export the state, composition, component, validation and assumptions tables.
- [x] Export a readable result summary and the cycle figure.
- [x] Verify the interpolation solution with a direct-NASA root solver.
- [x] Check preservation of the original Parts 1-3 baseline results.
- [x] Test nonideal efficiencies and diagnostic handling of a deliberately failed balance.
- [x] Prepare a detailed explanation, a report-ready Part 4 section and a compact PDF report.

## Which files to use

| Purpose | File |
|---|---|
| Understand the engine and get started | `START_HERE.md` |
| Run the complete cycle | `JetEngine_Group10.m` |
| Verify with the separate root solver | `verify_group10.m` |
| Your report section | `PART4_REPORT_SECTION.md` |
| Detailed explanation for questions/presentation | `PART4_EXPLANATION.md` |
| Compact full report | `reports/Group10_report_provisional.pdf` |
| Ready-to-read numerical summary | `results/results_summary.txt` |
| Evidence of checks and tests | `results/validation.csv`, `TEST_RESULTS.md` |
| Settings to confirm later | `results/provisional_assumptions.csv` |

Run both MATLAB entry points from the project folder. Generated results are
refreshed in `results/`. The committed results are the default baseline snapshot.
Do not use `Assignment.m` or `untitled2.m` as the Group 10 entry point.

## Your remaining submission steps

- [ ] Confirm the official settings when available: component efficiencies,
      fuel inlet state, combustor losses, shaft assumptions and any T4 limit.
      For now the existing defaults are intentionally retained and labelled.
- [ ] Transfer the report content into the current Canvas Word template and
      add the actual student names and numbers. That template was not supplied.
- [ ] Check the current group-settings file against the recorded Group 10 inputs.
- [ ] Confirm the current Canvas naming/group rules. The supplied 2026 lecture
      states 9 October regular and 16 October late submission.
- [ ] If official inputs change, run `verify_group10`, then rebuild the PDF.
      Update baseline examples in the Markdown report section before using them.
- [ ] Submit the final report PDF and runnable scripts ZIP through Canvas.

No Canvas submission or official confirmation is represented by the checked
technical work above.

## Rebuilding the provisional PDF

The optional Python report builder reads the MATLAB results. Install the package
listed in `requirements-report.txt`, then run `python scripts/build_report.py`.
It writes `reports/Group10_report_provisional.pdf`, with numerical text, tables
and figures drawn from the current results. It refuses incomplete model runs
and only reports a direct-root verification when it belongs to the same run.
Review the output and physical assumptions before use. The Markdown guide and
report section contain labelled baseline examples; they are not regenerated.
Python is not needed to run the MATLAB model.
