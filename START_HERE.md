# Start here - understand the engine and your Part 4

Your job is to explain how the results were obtained and show that they make sense. Start with the five components below. You can understand the project before reading every line of MATLAB.

## 1. Follow one stream through the engine

```text
Air -> Diffuser -> Compressor -> Combustor -> Turbine -> Nozzle -> Exhaust
  1            2             3            4           5         6
                                  fuel in     |
                          compressor <--------+
                                      shaft power
```

The numbers are measuring stations, not six separate machines. For example, state 3 is both the compressor outlet and the combustor inlet.

| Component | What happens | What to notice in our default results |
|---|---|---|
| Diffuser, 1 to 2 | Slows the incoming air; its kinetic energy raises enthalpy. | Temperature rises from 300 to 319.78 K. |
| Compressor, 2 to 3 | The shaft supplies work to compress the air. | Pressure rises by a factor of 9; temperature reaches 591.58 K. |
| Combustor, 3 to 4 | Hydrogen reacts with oxygen, producing water and heating the mixture. | Temperature reaches 1082.46 K; the mixture and mass flow change. |
| Turbine, 4 to 5 | Expanding gas supplies the power needed by the compressor. | Temperature falls to 848.87 K; turbine power equals compressor power. |
| Nozzle, 5 to 6 | Converts an enthalpy drop into gas speed. | Temperature falls to 580.54 K; exhaust speed reaches 778.83 m/s. |

Accelerating gas backwards produces forward thrust through the momentum balance. The turbine's role here is to power the compressor. Equal turbine and compressor powers do not mean the engine does nothing: the nozzle still accelerates the gas.

The numbers in this guide describe the provisional default baseline. After changing settings, use the newly generated tables and PDF.

## 2. Learn these symbols first

| Symbol | Meaning | Unit / example |
|---|---|---|
| T | Temperature | K; subtract 273.15 to obtain degrees Celsius. |
| P | Pressure | Pa internally; 100 kPa = 100,000 Pa. |
| v | Flow speed | m/s. |
| h | Enthalpy per kilogram: internal energy plus the flow-work term. | J/kg internally; 1 kJ/kg = 1,000 J/kg. |
| s | Specific entropy, used to calculate ideal reversible reference states. | J/(kg K). For fixed-composition adiabatic flow, irreversibility increases it. |
| m_dot | How much mass passes through each second. | kg/s. |
| W_dot | Power transferred through the shaft. | W = J/s; 1 MW = 1,000,000 W. |
| eta | Component efficiency relative to an ideal reference process. | 1 means the ideal component limit. |
| AF | Air mass divided by fuel mass. | 204.42 kg of air per kg of hydrogen. |

The suffix `s` in T3s means the **isentropic reference** temperature. It does not mean seconds or a seventh station. The model first calculates an ideal reference, then uses efficiency to find the actual state. With eta=1 they coincide.

The three component efficiencies being 1 does **not** mean the complete engine converts 100% of fuel energy into useful propulsion.

## 3. Understand three balances

### Mass: count what enters and leaves

Air flow = AF x fuel flow = 204.42 x 0.58 = **118.5636 kg/s**.

Products flow = air + fuel = 118.5636 + 0.5800 = **119.1436 kg/s**.

This is why the turbine and compressor cannot use the same mass flow. Fuel was added between them.

### Shaft power: the turbine pays for the compressor

```text
Compressor power = air flow x (h3 - h2)
Turbine power    = product flow x (h4 - h5)
```

Both are **33.242 MW** in this baseline. The energy increase across the compressor is positive; the turbine's enthalpy drop supplies that energy through the shaft.

### Nozzle: enthalpy becomes kinetic energy

```text
h5 - h6 = v6^2 / 2      (neglecting inlet speed)
```

Our enthalpy drop is about 303.286 kJ/kg. Convert it to 303,286 J/kg, multiply by 2, then take the square root: about **778.83 m/s**. This is one calculation you should be able to explain yourself. Using kJ/kg without converting gives the wrong speed.

## 4. What NASA properties actually do

The supplied database contains coefficients for functions such as h(T) and s_T(T). MATLAB uses these coefficients to calculate properties at a chosen temperature. It does not call NASA online.

The energy balance often tells us h, while we want T. We calculate a property curve and find the temperature on that curve corresponding to h. This is what inverse interpolation does. The second script checks the answer by solving the NASA equations directly with a root solver.

We use mass fractions to combine species properties. Air has one composition; after burning hydrogen, the products have another. Consequently the h(T) curves and gas constants differ.

Hydrogen reacts as **H2 + 0.5 O2 -> H2O**. Our mixture is lean: there is more oxygen than required, so some oxygen remains. Nitrogen passes through in this simplified chemistry; hydrogen produces no carbon dioxide.

## 5. The two confusing results are explainable

**Why can combustion be adiabatic?** Adiabatic means no heat is transferred through the combustor walls. The fuel already carries chemical energy into the control volume. Reaction changes chemical energy into sensible energy, increasing temperature.

**Why is the exhaust enthalpy negative?** Enthalpy has a reference. The NASA functions include formation enthalpies, including a negative value for water. A negative h is allowed. The nozzle uses h5-h6, which is positive. Adding fuel LHV to the full NASA enthalpy balance would count chemical energy twice.

The code also retains two entropy columns. `s_mix` includes mixing entropy; `s_model` matches the original calculation convention. Both give the same ideal entropy differences for a fixed composition. Do not call s4-s3 alone the combustor entropy generation: fuel enters separately, and the mass flows differ.

## 6. What your Part 4 is responsible for

Parts 1-3 calculate the component states. Part 4 connects, checks and explains them:

1. Make the complete model run from the first line with the correct Group 10 inputs.
2. Collect all six states into one table with units and the correct mixture.
3. Check mass, elements, energy and ideal entropy conditions.
4. Explain whether temperature, pressure and speed change in the expected directions.
5. Present the results, assumptions and numerical checks in the report.
6. Deliver the working scripts and report in the required course format.

A **residual** is the amount by which a balance fails to close. If energy in should equal energy out, the residual is energy in minus energy out. Small numerical errors are allowed by an explicit tolerance. `ToleranceFraction = abs(residual)/tolerance`; below 1 passes. It is not the physical percentage error of the engine prediction.

The baseline has 21 passing residual checks. The full-engine energy mismatch is only **3.29 W**, and the largest tolerance fraction is **0.08214**. This establishes numerical consistency; provisional assumptions still need course confirmation.

## 7. Get on track in one study session

**First 10 minutes:** draw the chain of five components. Explain aloud what each one does and why its temperature rises or falls.

**Next 10 minutes:** open the project folder in MATLAB. In the Command Window, type:

```matlab
verify_group10
```

This runs the model and the independent comparison. Look for `Independent numerical checks: 21/21 passed` and `Independent direct-root reference: PASS`. If MATLAB stops with an error, read it; do not use an old table as the result of the failed run. `results/run_status.json` records whether the latest model run finished.

**Next 10 minutes:** open `results/results_summary.txt`, then `results/state_table.csv`. Match each row to your drawing. Calculate the two mass flows and nozzle speed yourself using the equations above.

**Next 15 minutes:** read `PART4_REPORT_SECTION.md`. Then find `PART 4` in `JetEngine_Group10.m`. Its blocks collect states, evaluate properties directly, calculate residuals, compare components and export results. You do not need to memorize the entire script.

**Before submission:** use `PART4_HANDOFF.md`. Confirm official settings, use the Canvas report template, add student details, regenerate results after any input changes, and submit the required PDF/scripts package. Keep the provisional label until the settings are confirmed.

## 8. Check whether you can explain it

Try answering these without reading the answers:

1. Why does temperature rise in the diffuser without fuel being added?
2. Why is the turbine mass flow larger than the compressor mass flow?
3. Why do we not add LHV to the combustor equation?
4. What does an efficiency of 1 mean, and what does it not mean?
5. What does a passing residual check prove?

<details><summary>Check your answers</summary>

1. The incoming flow slows down; kinetic energy is converted to enthalpy.
2. Fuel is added after the compressor and before the turbine.
3. Full NASA enthalpies already contain the chemical formation-energy contribution.
4. The component matches its ideal reference; it does not mean 100% overall engine efficiency.
5. The selected equations close within numerical tolerances; it does not prove that all physical assumptions are correct for a real engine.

</details>

When you can answer these and explain the six-row state table, you have the main understanding needed to discuss your part.
