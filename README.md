# Thermodynamics
# 4EB00 Thermodynamics - Jet Engine Project

See `PART4_HANDOFF.md` for completed work and the remaining Canvas submission steps.
The compact report is in `reports/`; numerical snapshots are in `results/`.

## Improved Part 4

Start with `PART4_REPORT_SECTION.md` for a concise report-ready section.
New exports: `results/component_comparison.csv` and `results/results_summary.txt`.
Validation includes tolerance fractions and identifies/export failed checks.

## Completed Parts 1-4 (26 September 2026)

Run `JetEngine_Group10` in MATLAB. The script locates `General` relative to
its own location and writes checked tables, a MAT file and a PNG to `results/`.
Run `verify_group10` for a separate full-cycle direct-NASA root-solver check.
Both were tested with MATLAB R2026a. They require no additional toolbox.

**PROVISIONAL DEFAULTS:** eta_c=eta_t=eta_n=1, Tfuel=298.15 K,
P4/P3=1, Qloss=0, and a lossless shaft. The user authorized using these
repository defaults, but they remain unconfirmed against the course materials.
Change the central settings in the main script after confirmation.

Read `PART4_EXPLANATION.md` for the assessment of Parts 1-3, equations,
validation design, entropy conventions, results interpretation and source record.
The supplied Canvas report template was unavailable; the accompanying report
is technical content for that template, not confirmation of its formatting.

Expected default results: T4=1082.46 K, T5=848.87 K, T6=580.54 K,
v6=778.827595 m/s, compressor/turbine power=33.241777 MW.
The main script runs 21 independent residual checks plus physical assertions.
Do not run `untitled2.m` (scratch text) or use `Assignment.m` as the Group 10 model.

The 2026 Lecture 2 states 9 October 2026 regular / 16 October 2026 late submission.
The 2025 dates below/in archived handouts are historical. Confirm Canvas before submission.

This repository contains the MATLAB model for the 4EB00 Thermodynamics Jet Engine assignment.

The final goal is to create one complete MATLAB script that models the jet engine cycle:

1 -> 2 -> 3 -> 4 -> 5 -> 6

with:

- 1 -> 2: Diffuser
- 2 -> 3: Compressor
- 3 -> 4: Combustor
- 4 -> 5: Turbine
- 5 -> 6: Nozzle

The thermodynamic properties are calculated using the NASA thermodynamic database and the provided MATLAB functions.

---

# Group 10 Input Data

The Group 10 conditions are:

- Fuel: H2
- Ambient temperature: 300 K
- Ambient pressure: 100000 Pa
- Compressor pressure ratio P3/P2: 9
- Fuel mass flow rate: 0.58 kg/s
- Air-Fuel ratio: 204.42
- Flight velocity: 200 m/s

The air mass flow rate is therefore:

mair = AF * mfuel

which gives:

mair = 118.5636 kg/s

---

# Project Folder Structure

Every group member should keep the same internal folder structure.

The recommended structure is:

```text
Jet engine/
│
├── JetEngine_Group10.m
├── README.md
│
└── General/
    ├── HNasa.m
    ├── SNasa.m
    ├── CpNasa.m
    ├── CvNasa.m
    ├── UNasa.m
    ├── myfind.m
    └── NasaThermalDatabase.mat
```

---

# Model Assumptions

Current modelling choices. Each one is a single variable in `JetEngine_Group10.m`, so it can be changed in one place if the official model (Turns / Canvas template) says otherwise.

| Assumption | Value in code | Part | Reason |
|---|---|---|---|
| Compressor isentropic efficiency | `eta_c = 1.0` (provisional) | 1 | Ideal turbojet (Turns Fig. 8.19); still to be confirmed |
| Fuel inlet state | `Tfuel = Tref` (H2 gas, 298.15 K) | 2 | Reference state; using 300 K instead changes T4 by only ~0.1 K |
| Combustor pressure | `P4overP3 = 1` (P4 = P3) | 2 | Constant-pressure combustor of the ideal turbojet |
| Combustor heat loss | `Qloss = 0` | 2 | Adiabatic combustor: no heat crosses its walls |
| Combustion | complete: H2 + 0.5 O2 -> H2O | 2 | Very lean mixture (phi ~ 0.17): excess O2, no dissociation |

Species order everywhere: `[H2, O2, CO2, H2O, N2]`. From state 4 on, use the product properties (`hprod_a`, `sprod_a`, `Rprod`), not the air ones.

<!-- Git push test: 2026-09-26 -->
