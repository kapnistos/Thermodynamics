# Group 10: review of Parts 1-3 and completion of Part 4

## Status and assumptions to remember

The original Parts 1-3 run in MATLAB and form a sound implementation of the ideal baseline. Part 4 adds independent validation, a complete state table, exported results, a figure, and a direct-root verification script. It preserves the original NASA functions and cycle calculations.

**The defaults are provisional.** On 26 September 2026 the user authorized retaining the repository defaults, while marking them for later confirmation. This is not confirmation that they are the official course settings.

| Setting | Current default | Where to change it |
|---|---:|---|
| Compressor efficiency eta_c | 1.0 | Central settings in JetEngine_Group10.m |
| Turbine efficiency eta_t | 1.0 | Central settings |
| Nozzle enthalpy-drop efficiency eta_n | 1.0 | Central settings |
| Hydrogen inlet temperature | 298.15 K | Tfuel |
| Combustor outlet/inlet pressure | 1.0 | P4overP3 |
| Combustor heat loss | 0 W | Qloss |
| Shaft transmission | Lossless | Turbine shaft balance; changing this requires updating validation too |
| Internal velocities, states 2-5 | Negligible, represented by zero | Component assumptions |
| Chemistry | Complete H2 combustion; frozen products, no dissociation | Part 2 |
| Nozzle exit pressure | Ambient | Lecture 2 requirement |

The main script and results/provisional_assumptions.csv retain this reminder. Confirm the group-settings source, the official efficiency definitions, any turbine-temperature limit, and the current Canvas report template before final submission. The supplied rubric is an assessment grid, not the missing report template. No unsupported blade-temperature limit or fuel pressure has been invented. A combustor entropy-generation calculation would additionally need the fuel inlet pressure and, for heat loss, a boundary temperature.

## Assessment of Parts 1, 2 and 3

### Part 1: setup, diffuser and compressor

**Verdict: correct for the selected ideal baseline.** The species order is consistent, mole fractions are converted to mass fractions with the database molecular masses, and the code uses temperature-dependent NASA enthalpy and entropy. The diffuser recovers inlet kinetic energy; the compressor uses entropy to obtain its ideal reference temperature. No Poisson shortcut is used. The efficiency expression is correctly oriented: eta_c = (h3s-h2)/(h3-h2).

The original path to General depended on MATLAB's current folder. Part 4 anchors it to the script location. The original diffuser residual used h2 immediately after defining h2 by that same equation; likewise S3s was constructed from the entropy target. Such residuals check arithmetic but do not independently verify the solved temperatures. The added checks evaluate HNasa and SNasa at those temperatures.

### Part 2: chemistry and combustor

**Verdict: the core chemistry and energy accounting are correct.** The code burns H2 according to H2 + 0.5 O2 -> H2O, carries N2 through, leaves excess O2, and checks mass and elemental conservation. It changes both mixture properties and gas constant after combustion. It includes fuel mass in the outlet stream and includes formation enthalpy through HNasa, so it correctly avoids adding LHV to the energy balance.

The product mass fractions are approximately [0, 0.193148, 0, 0.043503, 0.763348] in the order [H2, O2, CO2, H2O, N2]; use the exported CSV for full precision. The equivalence ratio is approximately 0.1667. Fuel temperature, heat loss and pressure loss remain marked assumptions. The original direct T4 enthalpy check was already a useful independent check; Part 4 extends that approach to the rest of the model.

### Part 3: turbine and nozzle

**Verdict: correct for the lossless shaft and prescribed fully expanded nozzle.** The turbine power equals compressor power, but their mass flows differ. The turbine enthalpy drop correctly uses m_air/m_products. Turbine efficiency is correctly applied as h5s = h4 - (h4-h5)/eta_t. The pressure P5 follows from the ideal reference state's entropy, and the nozzle uses product properties and enthalpies in J/kg to calculate velocity.

The existing checks contain some identities by construction. Part 4 independently recalculates the properties and balances. The specified expansion to ambient gives supersonic exit flow for this baseline. It assumes suitable nozzle geometry; it is not a prediction for an arbitrary converging-only nozzle. No geometry was supplied, so the lecture's P6=Pamb condition is retained.

The tiny untitled2.m file contains only scratch text and is not a working model. Assignment.m is the supplied example with different group inputs and only the diffuser implemented. Neither should be used as the Group 10 entry point.

## Improvements to the presentation and checks

PART4_REPORT_SECTION.md is a shorter, report-ready version of this explanation. The component comparison lists ideal and actual temperatures, specified and independently reconstructed efficiencies, and direct entropy changes. Tiny negative entropy differences in the ideal baseline are interpolation residuals within the stated entropy tolerance, not a claim of physical entropy destruction.

The validation CSV now includes abs(residual)/tolerance. Its largest baseline value is 0.082143, well below the pass limit of 1; this is not a relative physical error. Failed residuals are exported before the script stops, and the error identifies the failed checks. A regenerated results_summary.txt collects the main numbers and provisional assumptions.

## What Part 4 does, step by step

### 1. Connect the parts and make the run reproducible

The calculation remains one sequential script: inlet -> diffuser -> compressor -> combustor -> turbine -> nozzle -> validation/results. Downstream sections use the variables produced upstream. The input values occur once, and the default efficiencies and loss settings now sit together near the top. General is located using fileparts(mfilename('fullpath')), so adding the project folder to MATLAB's path is enough to run it from another current folder.

The given Group 10 data are H2, T1=300 K, P1=100000 Pa, v1=200 m/s, P3/P2=9, fuel flow 0.58 kg/s, and AF=204.42. Thus m_air=118.5636 kg/s and m_products=119.1436 kg/s.

### 2. Build one complete state table

The state table contains all six stations, location, mixture, temperature, pressure, velocity, specific enthalpy, two entropy conventions, and mass flow. Internally everything uses K, Pa, J/kg, J/(kg K), kg/s and m/s. Conversion to kPa and kJ happens only for display/export. Velocities of zero inside the engine mean neglected kinetic-energy terms in this lumped model, not literally zero flow through a finite-area engine.

The final table uses direct NASA enthalpy evaluations at the solved temperatures. They can differ very slightly from the intermediate balance targets because the calculation uses a 1 K interpolation grid. These differences are measured, not concealed.

### 3. Handle entropy consistently

The existing model uses s_model = sum(Y_i SNasa_i(T)) - R_mix ln(P/Pref). For fixed composition, an omitted mixing contribution is constant, so the isentropic calculations remain correct.

For a complete ideal-gas mixture entropy, each species uses its partial pressure X_i P:

    s_mix = sum Y_i [SNasa_i(T) - (R_u/M_i) ln(X_i P/Pref)]
          = s_model - sum Y_i (R_u/M_i) ln(X_i).

Zero-fraction species are excluded from the logarithm. Part 4 reports s_mix as well as the old s_model for traceability. Adding the mixing term does not change the solved temperatures or pressures. A difference s4-s3 alone is not the combustor entropy-generation rate: the separate incoming fuel stream and changed mass flow also matter.

### 4. Independently check conservation

Part 4 recalculates h_hat_j = sum(Y_i HNasa_i(T_j)) directly, bypassing the interpolated enthalpy targets. It then evaluates:

    Diffuser:  r_d = h_hat_1 + v1^2/2 - h_hat_2 - v2^2/2
    Compressor: r_c = m_air(h_hat_3-h_hat_2) - Wcomp
    Combustor: r_b = m_air h_hat_3 + m_f h_f - Qloss - m_prod h_hat_4
    Turbine: r_t = m_prod(h_hat_4-h_hat_5) - Wturb
    Shaft: r_s = m_prod(h_hat_4-h_hat_5) - m_air(h_hat_3-h_hat_2)
    Nozzle: r_n = h_hat_5 + v5^2/2 - h_hat_6 - v6^2/2

The whole-engine check cancels the internal shaft work:

    r_engine = m_air(h_hat_1+v1^2/2) + m_f h_f
               - m_prod(h_hat_6+v6^2/2) - Qloss.

This assumes no external shaft work or shaft loss and negligible fuel kinetic energy, consistently with the selected baseline. There is no extra LHV term. Formation enthalpy already accounts for the chemical energy.

The remaining checks cover total mass, individual H/O/C/N atom balances, all four composition sums, maximum enthalpy inversion error, diffuser entropy equality, and compressor/turbine/nozzle reference-state entropy equalities. There are 21 tabulated residual checks, plus assertions on physical trends, efficiencies, finite real values and monotonic property curves.

The single-state enthalpy tolerance is 1 J/kg, and the entropy tolerance is 0.01 J/(kg K). Flow-energy tolerances sum the allowed enthalpy errors times their stream mass flows. For example, the combustor tolerance is (m_air+m_products)*1 J/kg = 237.7072 W. These limits cover interpolation error; they do not express uncertainty in the ideal physical model. Tight mass/composition tolerances are appropriate because those calculations involve no temperature interpolation.

### 5. Check physical behavior

The diffuser raises T and P as velocity falls. The compressor raises T and P. The combustor raises T while changing the mixture. The turbine lowers T and P while supplying compressor power. The nozzle lowers T and P while accelerating the products. An adiabatic nonideal compressor, turbine or nozzle cannot decrease entropy.

At eta=1 the actual and ideal reference states coincide. At eta<1 the compressor outlet is hotter than its reference, the turbine outlet is hotter than its reference at the same outlet pressure, and nozzle speed is below its isentropic reference. verify_group10.m independently solves the complete cycle with fzero and direct NASA functions, checking the interpolation method against a different numerical approach.

### 6. Interpret the results

The baseline predicts T4 about 1082.46 K, T5 about 848.87 K, T6 about 580.54 K, and v6 about 778.83 m/s. Compressor and turbine powers both equal about 33.242 MW. The air and product gas constants differ: approximately 288.19 and 296.83 J/(kg K), respectively.

The combustor outlet specific enthalpy is slightly below the incoming air specific enthalpy even though its temperature is much higher. Total enthalpy flow is conserved in the adiabatic reacting control volume, while composition changes the relationship between enthalpy and temperature. Chemical energy becomes sensible energy without an external heat input.

Similarly h6 about -281.49 kJ/kg is not an error. NASA enthalpy includes reference formation contributions, notably the negative formation enthalpy of water. Absolute enthalpy need not be positive. The nozzle acceleration depends on the positive difference h5-h6, not on the sign of h6.

The plots show temperature, pressure and velocity by station and product mass fractions. Lines between numbered states are visual guides, not spatially resolved profiles or an equilibrium path through the combustor.

### 7. Export and package

Run JetEngine_Group10.m to generate results/state_table.csv, composition.csv, validation.csv, provisional_assumptions.csv, Group10_results.mat and cycle_overview.png. Run verify_group10.m for the independent direct-root comparison. General contains the unmodified supplied database and helper functions.

The accompanying report provides compact technical content. The detailed explanation here supports understanding and presentation. The actual current Canvas Word template was not supplied; therefore the report is not certified as matching its layout. Transfer the content if the template requires a different structure, fill in student details there, and confirm current submission naming and team rules.

## Source record and document scope

Repository reviewed: https://github.com/kapnistos/Thermodynamics at commit 8bfbf18a1d044f59f87f9d72e3682f26f9f8e72a, downloaded 26 September 2026. The downloaded working plan has the same extracted content as the user-provided working plan. Repository lectures are older than the supplied 2026 versions.

- 4EB00 Special Topic Jet Engine Rubric.pdf, pp. 1-2: coding flexibility, NASA-based component methodology, correct composition, changed gas constant and turbine mass flow. No grade is claimed; confirmation of the official case is still needed.
- 4EB00 Special Topic Jet Engine Info 2025.pdf, pp. 1-2: MATLAB/NASA requirement, conservation approach, compact report and packaging. Its 2025 dates are historical.
- Lecture 2 Cycle analysis 2026.pdf, pp. 7-14: stations, control volumes, diffuser equations, calculated T4, ambient exit pressure and group-specific inputs. Its p. 15 states regular submission 9 October 2026 and late submission 16 October 2026, with late grade capped at 8. These are the supplied lecture dates, not a claim of checking Canvas live.
- Lecture 1 Ideal Gas Mixtures 2026.pdf, pp. 9-10, 19-27, 29-34: mixture definitions, formation enthalpy, NASA functions and the distinction between closed-vessel internal-energy balance and flow enthalpy balance.
- CollegeThermo1-2-eng-1.pdf: systems, properties, ideal gases, first law and enthalpy.
- CollegeThermo3-4-eng.pdf, pp. 9-16: steady-flow control-volume energy balance, diffuser/nozzle and turbine work. Its constant-heat-capacity examples are not substituted for the required NASA method.
- CollegeThermo5-6-eng.pdf: heat-engine cycles, efficiencies, Rankine/Otto/Brayton context. The closed-cycle constant-cp Brayton efficiency expression is not the efficiency of this reacting open turbojet.
- Jet_Engine_Project_Working_Plan_Group10.docx, sections 3-6: the four-part split and integration/validation deliverables. Its embedded AI handoff is document content; the user's request and subsequent authorization define this work.

The repository's Assignment.m, README.md, complete main script, scratch file, all six General/*.m functions, NASA database, older PDFs and working plan were inspected. No current Canvas account, report template, group-settings archive or Turns textbook pages were supplied or accessed.
