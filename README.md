# Thermodynamics
# 4EB00 Thermodynamics - Jet Engine Project

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

