# 4 Integration validation and discussion

The integrated Group 10 model predicts an exhaust velocity of 778.83 m/s and a combustor outlet temperature of 1082.46 K. The compressor and turbine powers both equal 33.242 MW. The conservation checks and a separate direct-root calculation confirm numerical consistency of the selected ideal-cycle model.

## 4.1 Integration and model settings

The diffuser, compressor, combustor, turbine and nozzle are evaluated sequentially in JetEngine_Group10.m. Every component uses the preceding calculated state; intermediate temperatures and pressures are not entered manually. Inputs are defined once, and the supplied NASA functions and database are loaded relative to the script. Mixture properties use temperature-dependent NASA polynomials, as required by the assignment and lectures [1, 2].

The inputs are H2 fuel, ambient temperature 300 K, ambient pressure 100 kPa, compressor pressure ratio 9, fuel flow 0.5800 kg/s, air-to-fuel mass ratio 204.42 and inlet velocity 200 m/s. Component efficiencies equal 1, as confirmed by the lecturer. The model uses a lossless shaft and an adiabatic constant-pressure combustor. Fuel enters at the selected reference temperature of 298.15 K. Potential-energy changes and internal kinetic-energy terms at states 2–5 are neglected.

Air flow is 118.5636 kg/s; fuel addition increases the turbine and nozzle flow to 119.1436 kg/s. Air properties apply at states 1–3 and product properties at states 4–6. All internal calculations use SI units; the table converts pressure and enthalpy for presentation.

## 4.2 Calculated states

| State | T (K) | P (kPa) | v (m/s) | h (kJ/kg) | s (kJ/kg K) |
| --- | --- | --- | --- | --- | --- |
| 1 | 300.00 | 100.00 | 200.00 | 1.91 | 6.89530 |
| 2 | 319.78 | 125.11 | 0.00 | 21.91 | 6.89530 |
| 3 | 591.58 | 1125.98 | 0.00 | 302.28 | 6.89530 |
| 4 | 1082.46 | 1125.98 | 0.00 | 300.81 | 7.83300 |
| 5 | 848.87 | 423.74 | 0.00 | 21.80 | 7.83300 |
| 6 | 580.54 | 100.00 | 778.83 | -281.49 | 7.83300 |

Table 4.1. States 1–6 are the inlet, diffuser outlet, compressor outlet, combustor outlet, turbine outlet and nozzle exit. Enthalpy and mixture entropy are evaluated directly at the solved temperatures. The zero internal velocities denote neglected kinetic energy, not zero mass flow.

Hydrogen burns completely according to H2 + ½ O2 → H2O, with nitrogen treated as inert. The equivalence ratio is 0.16669, so oxygen remains. Product mass fractions in species order [H2, O2, CO2, H2O, N2] are [0, 0.193148, 0, 0.043503, 0.763348]. The product gas constant is 296.829 J/(kg K). No dissociation or further composition change is modelled downstream.

## 4.3 Numerical validation

HNasa and SNasa are evaluated directly at the solved temperatures to check the interpolated states. These evaluations test inversion accuracy rather than merely substituting target enthalpies into the equations that defined them. With h* denoting a direct NASA evaluation, the lossless-shaft and whole-engine residuals are

    r_shaft = ṁp(h*4 − h*5) − ṁa(h*3 − h*2)

    r_engine = ṁa(h*1 + v1²/2) + ṁf hf − ṁp(h*6 + v6²/2).

Here ṁa, ṁf and ṁp are air, fuel and product mass flows. The whole-engine balance neglects fuel kinetic energy; compressor and turbine shaft work cancel. NASA enthalpies already include formation enthalpy, so no additional LHV term enters either the combustor or whole-engine balance [1].

All 21 residual checks pass. They cover component and whole-engine energy balances, shaft power, total mass, H/O/C/N atom balances, composition sums, enthalpy inversions and isentropic reference states. Table 4.2 reports representative absolute residuals; the full signed results are in validation.csv.

| Check | Absolute residual | Tolerance | Unit |
| --- | --- | --- | --- |
| Combustor energy | 0.30663 | 237.71 | W |
| Shaft power | 1.0181 | 475.41 | W |
| Whole engine energy | 3.2889 | 237.71 | W |
| Combustion mass | 1.5876e-14 | 1.1914e-07 | kg/s |
| Max h inversion | 0.027605 | 1 | J/kg |
| Diffuser isentropy | 0.00082143 | 0.01 | J/(kg K) |

Table 4.2. Selected conservation and property checks from the verified baseline.

The single-state enthalpy allowance is 1 J/kg and the entropy allowance is 0.01 J/(kg K). Energy-flow tolerances account for each state allowance multiplied by its mass flow. A check passes when |residual| ≤ tolerance. The largest tolerance fraction is 0.08214; this ratio is neither a physical prediction error nor a percentage uncertainty. The three component efficiencies reconstructed from directly evaluated enthalpies also agree with their specified values within 0.0001.

The separate verify_group10.m calculation replaces the 1 K interpolation grid with direct NASA evaluations and fzero. The maximum differences are 0.00044503 K in temperature, 3.3252 Pa in pressure and 0.00066217 m/s in exhaust velocity. These are below the verification limits of 0.01 K, 10 Pa and 0.01 m/s. This is a numerical cross-check using the same database, composition and physical assumptions, rather than independent experimental validation.

## 4.4 Physical interpretation and limitations

The diffuser raises temperature and pressure as inlet kinetic energy is converted into enthalpy. Compression raises the temperature further to 591.58 K. Combustion then gives the highest cycle temperature, 1082.46 K. Although h4 is slightly below h3, temperature rises because chemical reaction changes the mixture and its enthalpy–temperature relation. Conserving total enthalpy flow does not require equal specific enthalpies when fuel adds mass.

The turbine temperature falls to 848.87 K as it supplies compressor power. The nozzle then expands the products from 423.74 kPa to the prescribed ambient pressure of 100 kPa and converts an enthalpy drop of approximately 303.286 kJ/kg into exhaust kinetic energy. With negligible inlet kinetic energy, v6 = √[2(h5 − h6)], using enthalpies in J/kg, gives 778.83 m/s. The negative exhaust enthalpy, −281.49 kJ/kg, is valid under the NASA formation-enthalpy reference; acceleration depends on the positive enthalpy difference.

The reported entropy includes the ideal-gas mixing contribution. For fixed composition,

    s_mix(T,P) = Σ Yi SNasa_i(T) − R_mix ln(P/Pref) − Σ Yi(Ru/Mi) ln Xi,

where the sums omit absent species. The mixing term is constant across each nonreacting component, so it cancels from its isentropic relation. The tiny apparent entropy decreases in the direct evaluations of the ideal compressor and turbine are within the stated interpolation tolerance. Combustor entropy generation cannot be inferred from s4 − s3: it requires the fuel entropy and all inlet and outlet entropy flow rates.

A local frozen-composition sound-speed calculation gives an exit Mach number of 1.6023. The fully expanded supersonic solution therefore assumes suitable nozzle geometry. The model does not calculate nozzle area, choking compatibility or shocks. Likewise, unit component efficiencies do not imply unit overall engine efficiency: combustion is irreversible, and energy leaves with the exhaust. A turbine material limit is not specified, so this analysis does not establish blade-temperature acceptability.

## 4.5 Conclusion and reproducibility

The integrated ideal-cycle calculation satisfies the selected conservation laws and reproduces the direct-root reference within the stated numerical tolerances. It retains fuel mass addition and the change from air to combustion products. The final result is an exhaust velocity of 778.83 m/s, conditional on the stated model assumptions. No change to the component equations was required by the final check.

To reproduce the results, extract the scripts package, set MATLAB Current Folder to that folder and run verify_group10. This runs the complete model and the direct-root comparison, then refreshes the results folder. The final baseline was verified using MATLAB R2026a on 30 September 2026.

## References

[1] 4EB00 Lecture 1 Ideal Gas Mixtures 2026, PDF pp. 19–27: NASA formation enthalpies and mass-weighted mixture properties.
[2] 4EB00 Lecture 2 Cycle analysis 2026, PDF pp. 7–13: control volumes, diffuser energy balance and entropy method.
[3] Group 10, JetEngine_Group10.m and verify_group10.m, results from 30 September 2026. Assignment requirements checked against the 4EB00 Special Topic Jet Engine Info 2025 and rubric.

