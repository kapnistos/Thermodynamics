# Thermodynamics
# 4EB00 Thermodynamics - Jet Engine Project

Run `JetEngine_Group10` for the complete cycle; run `verify_group10` to check it.
Start with `START_HERE.md`; results and the report are in `results/` and `reports/`.
The model is the ideal cycle: all component efficiencies are 1, as confirmed by the lecturers. See `PART4_HANDOFF.md` before submission.

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

Modelling choices of the ideal cycle, confirmed by the lecturers. The efficiencies and the fuel temperature are single variables at the top of `JetEngine_Group10.m`.

| Assumption | Value in code | Part | Reason |
|---|---|---|---|
| Component isentropic efficiencies | `eta_c = eta_t = eta_n = 1.0` | 1, 3 | Ideal cycle, confirmed by the lecturers |
| Fuel inlet state | `Tfuel = Tref` (H2 gas, 298.15 K) | 2 | Reference state; using 300 K instead changes T4 by only ~0.1 K |
| Combustor pressure | `P4 = P3` | 2 | Constant-pressure combustion of the ideal cycle |
| Combustor heat loss | none | 2 | Adiabatic combustor: no heat crosses its walls |
| Combustion | complete: H2 + 0.5 O2 -> H2O | 2 | Very lean mixture (phi ~ 0.17): excess O2, no dissociation |

Species order everywhere: `[H2, O2, CO2, H2O, N2]`. From state 4 on, use the product properties (`hprod_a`, `sprod_a`, `Rprod`), not the air ones.


