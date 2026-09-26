# Verification record - 26 September 2026

Runtime: MATLAB R2026a on Windows. Source baseline: GitHub commit
8bfbf18a1d044f59f87f9d72e3682f26f9f8e72a.

| Verification | Result |
|---|---|
| Original main script, Parts 1-3 | Runs successfully |
| Integrated default model | All 21 independent residual checks pass |
| Preservation of original results | All six temperatures and v6 match original exactly |
| Separate direct-NASA fzero solution | Maximum T difference 0.0004450301 K; v6 difference -0.000662167 m/s |
| Nonideal branch in isolated temporary copy | Pass: eta_c=0.85, eta_t=0.90, eta_n=0.95, P4/P3=0.95 |
| Nonideal actual-vs-reference trends | T3>T3s, T5>T5s, T6>T6s, v6<v6s; positive component entropy changes |
| Nonideal direct-root comparison | v6 difference -0.000742279 m/s; all reference tolerances pass |
| Extracted scripts ZIP | Pass in fresh MATLAB session after restoredefaultpath, with a different current folder |
| Supplied General files | Unchanged |
| PDF | Five pages rendered and visually inspected |

The nonideal inputs are software verification cases only. The delivered code
retains all user-authorized repository defaults. Numerical verification does
not confirm those defaults against Canvas or validate a specific nozzle geometry.

Reproduce the numerical checks by running `verify_group10` from the extracted
package. The main model writes `results/validation.csv`; the verification script
also writes `results/direct_root_comparison.csv`.

## Improved Part 4 verification

The updated baseline passes all 21 residuals and the direct-root comparison,
with original six temperatures and exhaust velocity preserved exactly.
The maximum tolerance fraction is 0.082143 (pass limit 1). The three
reconstructed efficiencies also pass. In a separate nonideal test,
eta_c=0.85, eta_t=0.90 and eta_n=0.95 reconstruct within 0.0001.
An injected diffuser residual at ten times its tolerance is correctly rejected;
the error names the check and the failed row is saved in validation.csv.

## Review and report consistency checks

- Repeated the default MATLAB run and direct-root comparison: all checks pass;
  the original six temperatures and exhaust speed still match exactly.
- Repeated the nonideal case above with the separate solver: all checks pass.
- Set eta_c=0.00001 in an isolated copy: the model rejects the out-of-range
  compressor temperature with a component-specific error and leaves the latest
  run marked INCOMPLETE, even when older successful output files are present.
- Built a report from the nonideal run: its speed, temperature, shaft power and
  efficiencies match that run; the previous baseline answers are absent.
- Confirmed the report builder rejects an incomplete model run.
- Gave a verification summary an older run ID in an isolated copy: the report
  correctly states that verification is unavailable for the current run.
- Rebuilt the default five-page PDF and visually inspected every page.

Run IDs connect the model and independent verification summaries. They prevent
accidental reuse of earlier verification; they are not a file-integrity or
tamper-detection mechanism.
