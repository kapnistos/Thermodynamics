# Part 4 - Integration, validation and discussion

## Integration of the model

The diffuser, compressor, combustor, turbine and nozzle calculations were integrated into one sequential MATLAB script. Each component receives the state calculated by the preceding component, so changing an input automatically updates the complete cycle. The Group 10 inputs and provisional efficiency settings are defined once. The NASA database is located relative to the script, allowing the package to run without a user-specific folder path.

All calculations use SI units. Pressure and enthalpy are converted to kPa and kJ/kg only when presenting results. Air properties are used at states 1-3, while combustion-product properties are used at states 4-6. The change in mass flow is retained: the compressor processes 118.5636 kg/s of air, whereas the turbine and nozzle process 119.1436 kg/s after adding 0.5800 kg/s of hydrogen.

## Validation method

A plausible state table alone does not establish that the model is correct. For each calculated temperature, the NASA enthalpy and entropy functions were evaluated again directly. These independently evaluated properties were then substituted into the mass, energy and entropy balances. This checks the temperature inversions as well as the component equations.

For example, the shaft residual is

\[
r_{shaft}=\dot m_p[\hat h_4-\hat h_5]
           -\dot m_a[\hat h_3-\hat h_2],
\]

where the hat denotes a direct NASA evaluation at the calculated temperature. The product and air mass flows must remain separate. For the entire engine, the internal shaft work cancels, giving

\[
r_{engine}=\dot m_a(\hat h_1+v_1^2/2)+\dot m_fh_f
 -\dot m_p(\hat h_6+v_6^2/2)-\dot Q_{loss}.
\]

These expressions assume the selected lossless shaft and negligible fuel kinetic energy. A separate heating-value term is unnecessary because the NASA enthalpies already include formation enthalpy.

The model performs 21 residual checks covering component and whole-engine energy balances, shaft power, mass conservation, H/O/C/N atom balances, composition sums, enthalpy inversion accuracy and isentropic reference states. It also reconstructs the three component efficiencies from directly evaluated actual and ideal-state enthalpies. This verifies that the specified efficiency definitions agree with the calculated states.

Each residual is assessed against an explicit tolerance. The exported tolerance fraction is |residual|/tolerance: a value below one passes. This permits comparison between checks expressed in different units, but it is not a percentage error in the physical prediction. Small nonzero residuals are expected because the main calculation uses a 1 K interpolation grid.

## Results and physical interpretation

| State | Location | T (K) | P (kPa) |
|---|---|---:|---:|
| 1 | Inlet | 300.00 | 100.00 |
| 2 | Diffuser outlet | 319.78 | 125.11 |
| 3 | Compressor outlet | 591.58 | 1125.98 |
| 4 | Combustor outlet | 1082.46 | 1125.98 |
| 5 | Turbine outlet | 848.87 | 423.74 |
| 6 | Nozzle exit | 580.54 | 100.00 |

The diffuser converts inlet kinetic energy into enthalpy, and the compressor further increases temperature and pressure. Combustion raises the temperature to 1082.46 K. The turbine then supplies 33.242 MW to the compressor, and the nozzle converts the remaining enthalpy drop into an exhaust velocity of 778.83 m/s. These trends are consistent with the chosen component models.

All 21 residual checks pass. The whole-engine energy residual is 3.29 W, and the maximum enthalpy inversion error is 0.0276 J/kg. A separate calculation using direct NASA functions and a root solver agrees within 0.00045 K and 0.00067 m/s, showing that interpolation error is negligible at the displayed precision.

The negative exhaust enthalpy, approximately -281.49 kJ/kg, is consistent with the NASA formation-enthalpy reference. Nozzle acceleration depends on the positive difference h5-h6, not on the sign of either absolute enthalpy. The final state table also includes mixing entropy. The original entropy convention remains valid for fixed-composition isentropic differences, but the air and product entropy values should not be used alone to calculate combustor entropy generation.

## Assumptions and conclusion

The calculation retains eta_c=eta_t=eta_n=1, hydrogen inlet temperature 298.15 K, zero combustor heat and pressure loss, and a lossless shaft. These values are provisional and recorded in the code and results for later confirmation. The exit Mach number is approximately 1.60, so the prescribed expansion to ambient pressure assumes suitable nozzle geometry. Numerical validation establishes consistency of this model; it does not establish the accuracy of its ideal assumptions for a real engine.

The integrated model is therefore numerically consistent for the selected baseline. Its results can be reproduced by running the supplied MATLAB script, and the exported checks provide a clear basis for reassessing the cycle when the official settings are confirmed.
