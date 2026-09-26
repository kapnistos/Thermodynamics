%% 4EB00 Thermodynamics - Jet Engine
% Group 10
%
% Complete jet-engine cycle:
%
% State 1 -> 2 : Diffuser
% State 2 -> 3 : Compressor
% State 3 -> 4 : Combustor
% State 4 -> 5 : Turbine
% State 5 -> 6 : Nozzle
%
% At the moment this file contains PART 1 and PART 2 and Part 3.
%
% PART 1:
%   - Setup
%   - Group 10 data
%   - Air mixture
%   - NASA properties
%   - State 1
%   - Diffuser 1 -> 2
%   - Compressor 2 -> 3
%
% PART 2:
%   - Combustion chemistry (H2 + air -> products)
%   - NASA properties of the product mixture
%   - Combustor 3 -> 4
%
% IMPORTANT:
% Compressor efficiency eta_c is temporarily assumed to be 1.0.
% This must be checked/replaced before final submission.

clear all;
close all;
clc;

%% ========================================================================
% SETUP
% =========================================================================

% Relative path to the General folder.
% The General folder must be inside the main project folder.
relativepath_to_generalfolder = 'General';

% Check that the General folder exists
assert(isfolder(relativepath_to_generalfolder), ...
    'General folder not found. Check MATLAB Current Folder.');

% Add NASA functions to MATLAB path
addpath(relativepath_to_generalfolder);

%% Load NASA database

TdataBase = fullfile('General','NasaThermalDatabase');

assert(isfile([TdataBase '.mat']), ...
    'NasaThermalDatabase.mat not found inside General.');

load(TdataBase);

assert(exist('Sp','var') == 1, ...
    'NASA database did not load correctly.');

fprintf('NASA database loaded successfully.\n');

%% NASA constants
% These values are supplied by the course and should not be changed.

global Runiv Pref

Runiv = 8.314472;      % Universal gas constant [J/mol/K]
Pref  = 1.01235e5;     % Reference pressure [Pa]
Tref  = 298.15;        % Reference temperature [K]

%% Convenient units

kJ   = 1e3;
kmol = 1e3;
dm   = 0.1;
bara = 1e5;
kPa  = 1e3;
kN   = 1e3;
kg   = 1;
s    = 1;

%% ========================================================================
% GROUP 10 INPUT DATA
% =========================================================================

v1       = 200;          % Flight velocity [m/s]
Tamb     = 300;          % Ambient temperature [K]
P3overP2 = 9;            % Compressor pressure ratio [-]
Pamb     = 100000;       % Ambient pressure [Pa]
mfurate  = 0.58*kg/s;    % Fuel mass flow rate [kg/s]
AF       = 204.42;       % Air-fuel ratio [-]

cFuel    = 'H2';         % Fuel

% Air-fuel ratio definition:
%
% AF = mair / mfuel
%
% therefore:
%
% mair = AF * mfuel

mair = AF*mfurate;

fprintf('\n--- GROUP 10 INPUT DATA ---\n');
fprintf('Fuel                 : %s\n',cFuel);
fprintf('Ambient temperature  : %.2f K\n',Tamb);
fprintf('Ambient pressure     : %.0f Pa\n',Pamb);
fprintf('Pressure ratio P3/P2 : %.2f\n',P3overP2);
fprintf('Fuel mass flow       : %.4f kg/s\n',mfurate);
fprintf('Air-fuel ratio       : %.2f\n',AF);
fprintf('Air mass flow        : %.4f kg/s\n',mair);
fprintf('Flight velocity      : %.2f m/s\n',v1);

%% ========================================================================
% SELECT SPECIES
% =========================================================================
%
% Species order:
%
% [H2, O2, CO2, H2O, N2]

iSp = myfind({Sp.Name},{cFuel,'O2','CO2','H2O','N2'});

% Select only the required species from the NASA database
SpS = Sp(iSp);

% Number of selected species
NSp = length(SpS);

% Molecular masses [kg/mol]
Mi = [SpS.Mass];

%% ========================================================================
% AIR COMPOSITION
% =========================================================================
%
% Air consists approximately of:
%
% 21% O2
% 79% N2
%
% These are MOLE fractions.
%
% Species order:
% [H2, O2, CO2, H2O, N2]

Xair = [0 0.21 0 0 0.79];

% Mean molar mass of air
MAir = Xair*Mi';

% Convert mole fractions to mass fractions
%
% Yi = Xi*Mi / Mmix

Yair = Xair.*Mi/MAir;

%% Fuel composition

% Pure hydrogen fuel
Yfuel = [1 0 0 0 0];

%% Check air composition

fprintf('\n--- AIR COMPOSITION ---\n');

fprintf('Sum of mole fractions Xair = %.6f\n',sum(Xair));
fprintf('Sum of mass fractions Yair = %.6f\n',sum(Yair));

disp('Mole fractions Xair:');
disp(Xair);

disp('Mass fractions Yair:');
disp(Yair);

assert(abs(sum(Xair)-1) < 1e-10, ...
    'Mole fractions do not sum to 1.');

assert(abs(sum(Yair)-1) < 1e-10, ...
    'Mass fractions do not sum to 1.');

%% ========================================================================
% NASA PROPERTIES OF AIR
% =========================================================================
%
% We calculate enthalpy and the thermal part of entropy over a large
% temperature range.
%
% This allows us later to numerically solve:
%
% h -> T
%
% and
%
% s_thermal -> T

TR = 200:1:3000;

NTR = length(TR);

% Preallocate matrices
hia = zeros(NTR,NSp);
sia = zeros(NTR,NSp);

% Calculate properties of every species over temperature range TR
for i = 1:NSp

    hia(:,i) = HNasa(TR,SpS(i));
    sia(:,i) = SNasa(TR,SpS(i));

end

% Air mixture enthalpy over temperature range
%
% h_air(T) = sum Yi*hi(T)

hair_a = Yair*hia';

% Thermal part of air entropy over temperature range
%
% sT_air(T) = sum Yi*sTi(T)

sair_a = Yair*sia';

%% Check NASA air properties at 300 K

hAir300  = interp1(TR,hair_a,300);
sAirT300 = interp1(TR,sair_a,300);

fprintf('\n--- NASA AIR PROPERTIES ---\n');
fprintf('Air enthalpy at 300 K            : %.2f J/kg\n',hAir300);
fprintf('Air entropy temperature part     : %.2f J/(kg K)\n',sAirT300);

assert(all(isfinite(hair_a)), ...
    'Invalid values found in air enthalpy array.');

assert(all(isfinite(sair_a)), ...
    'Invalid values found in air entropy array.');

%% ========================================================================
% STATE 1 - ENGINE INLET
% =========================================================================

T1 = Tamb;
P1 = Pamb;

% Gas constant of air mixture
%
% Rg = Runiv / Mair

Rg = Runiv/MAir;        % [J/(kg K)]

%% Enthalpy at state 1

h1 = interp1(TR,hair_a,T1);

%% Thermal entropy at state 1

s1thermal = interp1(TR,sair_a,T1);

%% Total entropy at state 1
%
% For an ideal gas:
%
% S = s_thermal(T) - Rg*ln(P/Pref)

S1 = s1thermal - Rg*log(P1/Pref);

fprintf('\n--- STATE 1 ---\n');
fprintf('T1   = %.2f K\n',T1);
fprintf('P1   = %.0f Pa\n',P1);
fprintf('v1   = %.2f m/s\n',v1);
fprintf('h1   = %.2f J/kg\n',h1);
fprintf('S1   = %.2f J/(kg K)\n',S1);
fprintf('Rg   = %.2f J/(kg K)\n',Rg);

%% ========================================================================
% DIFFUSER 1 -> 2
% =========================================================================
%
% Assumptions:
%
% - steady flow
% - adiabatic
% - no shaft work
% - negligible potential energy change
% - outlet velocity approximately zero
% - isentropic process
%
% Energy conservation:
%
% h1 + v1^2/2 = h2 + v2^2/2

v2 = 0;                    % Diffuser outlet velocity [m/s]

%% Enthalpy at state 2

h2 = h1 + 0.5*v1^2 - 0.5*v2^2;

%% Determine T2 from NASA enthalpy curve
%
% We know h2.
% NASA gives h_air(T).
%
% Therefore interpolate:
%
% h2 -> T2

T2 = interp1(hair_a,TR,h2);

%% Thermal entropy at state 2

s2thermal = interp1(TR,sair_a,T2);

%% Determine P2 using isentropic condition
%
% S2 = S1
%
% Therefore:
%
% s2thermal - s1thermal - Rg*ln(P2/P1) = 0
%
% Rearranged:
%
% ln(P2/P1) = (s2thermal-s1thermal)/Rg

lnPr = (s2thermal-s1thermal)/Rg;

Pr = exp(lnPr);

P2 = P1*Pr;

%% Total entropy at state 2

S2 = s2thermal - Rg*log(P2/Pref);

%% Check enthalpy interpolation

h2check = interp1(TR,hair_a,T2);

%% Diffuser energy residual

diffuserEnergyResidual = ...
    (h1 + v1^2/2) - (h2 + v2^2/2);

%% Diffuser checks

assert(T2 > T1, ...
    'Diffuser check failed: T2 should be greater than T1.');

assert(P2 > P1, ...
    'Diffuser check failed: P2 should be greater than P1.');

assert(abs(diffuserEnergyResidual) < 1e-6, ...
    'Diffuser energy balance is not satisfied.');

%% Print diffuser results

fprintf('\n--- DIFFUSER 1 -> 2 ---\n');
fprintf('T1 = %.2f K\n',T1);
fprintf('T2 = %.2f K\n',T2);
fprintf('P1 = %.0f Pa\n',P1);
fprintf('P2 = %.0f Pa\n',P2);
fprintf('v1 = %.2f m/s\n',v1);
fprintf('v2 = %.2f m/s\n',v2);
fprintf('h1 = %.2f J/kg\n',h1);
fprintf('h2 = %.2f J/kg\n',h2);
fprintf('S1 = %.2f J/(kg K)\n',S1);
fprintf('S2 = %.2f J/(kg K)\n',S2);

fprintf('Diffuser energy residual = %.6f J/kg\n', ...
    diffuserEnergyResidual);

%% ========================================================================
% COMPRESSOR 2 -> 3
% IDEAL ISENTROPIC REFERENCE STATE 3s
% =========================================================================
%
% Compressor pressure ratio is given:
%
% P3/P2 = 9

P3 = P3overP2*P2;

%% Ideal compressor state 3s
%
% For the ideal reference process:
%
% S3s = S2
%
% Therefore:
%
% s3s_thermal - s2thermal - Rg*ln(P3/P2) = 0
%
% Rearranged:
%
% s3s_thermal = s2thermal + Rg*ln(P3/P2)

s3sthermal = ...
    s2thermal + Rg*log(P3/P2);

%% Determine T3s from NASA entropy curve
%
% We know s3s_thermal.
% NASA gives s_air(T).
%
% Therefore:
%
% s3s_thermal -> T3s

T3s = interp1(sair_a,TR,s3sthermal);

%% Determine ideal compressor outlet enthalpy

h3s = interp1(TR,hair_a,T3s);

%% Total entropy at state 3s

S3s = s3sthermal - Rg*log(P3/Pref);

%% Ideal specific compressor work
%
% Neglecting kinetic and potential energy:
%
% ws = h3s - h2

ws = h3s - h2;

%% Ideal compressor checks

assert(P3 > P2, ...
    'Compressor check failed: P3 should be greater than P2.');

assert(T3s > T2, ...
    'Compressor check failed: T3s should be greater than T2.');

assert(h3s > h2, ...
    'Compressor check failed: h3s should be greater than h2.');

%% Entropy residual
%
% For an isentropic process:
%
% S3s - S2 = 0

compressorEntropyResidual = S3s-S2;

%% Print ideal compressor results

fprintf('\n--- COMPRESSOR IDEAL STATE 3s ---\n');
fprintf('P2   = %.0f Pa\n',P2);
fprintf('P3   = %.0f Pa\n',P3);
fprintf('T2   = %.2f K\n',T2);
fprintf('T3s  = %.2f K\n',T3s);
fprintf('h2   = %.2f J/kg\n',h2);
fprintf('h3s  = %.2f J/kg\n',h3s);
fprintf('S2   = %.2f J/(kg K)\n',S2);
fprintf('S3s  = %.2f J/(kg K)\n',S3s);

fprintf('Ideal specific compressor work = %.2f J/kg\n',ws);

fprintf('Isentropic entropy residual = %.6f J/(kg K)\n', ...
    compressorEntropyResidual);

%% ========================================================================
% ACTUAL COMPRESSOR STATE 3
% =========================================================================
%
% IMPORTANT TEMPORARY ASSUMPTION
%
% The numerical compressor isentropic efficiency has not yet been located
% in the supplied assignment material.
%
% For now:
%
% eta_c = 1.0
%
% This temporarily means that the compressor is treated as perfectly
% isentropic.
%
% THIS VALUE MUST BE CHECKED BEFORE FINAL SUBMISSION.

eta_c = 1.0;

%% Compressor isentropic efficiency
%
% For compression:
%
% eta_c = ideal work / actual work
%
% eta_c = (h3s-h2)/(h3-h2)
%
% Rearranged:
%
% h3 = h2 + (h3s-h2)/eta_c

h3 = h2 + (h3s-h2)/eta_c;

%% Determine actual compressor outlet temperature

T3 = interp1(hair_a,TR,h3);

%% Thermal entropy at state 3

s3thermal = interp1(TR,sair_a,T3);

%% Total entropy at state 3

S3 = s3thermal - Rg*log(P3/Pref);

%% ========================================================================
% COMPRESSOR WORK
% =========================================================================
%
% Actual specific compressor work input:
%
% wcomp = h3-h2

wcomp = h3-h2;              % [J/kg]

%% Compressor power input
%
% Wcomp = mair*wcomp

Wcomp = mair*wcomp;         % [W]

%% Actual compressor checks

assert(T3 >= T3s-1e-6, ...
    'Compressor check failed: actual T3 should be >= T3s.');

assert(h3 >= h3s-1e-6, ...
    'Compressor check failed: actual h3 should be >= h3s.');

assert(S3 >= S2-1e-6, ...
    'Compressor check failed: entropy should not decrease.');

%% Print actual compressor results

fprintf('\n--- ACTUAL COMPRESSOR STATE 3 ---\n');

fprintf('TEMPORARY eta_c = %.3f\n',eta_c);

fprintf('P3   = %.0f Pa\n',P3);
fprintf('T3   = %.2f K\n',T3);
fprintf('h3   = %.2f J/kg\n',h3);
fprintf('S3   = %.2f J/(kg K)\n',S3);

fprintf('Specific compressor work = %.2f J/kg\n',wcomp);
fprintf('Compressor power         = %.3f MW\n',Wcomp/1e6);

%% ========================================================================
% PART 1 SUMMARY
% =========================================================================

fprintf('\n============================================================\n');
fprintf('                    PART 1 SUMMARY\n');
fprintf('============================================================\n');

fprintf('\nState 1:\n');
fprintf('T1 = %.2f K\n',T1);
fprintf('P1 = %.2f kPa\n',P1/kPa);
fprintf('h1 = %.2f kJ/kg\n',h1/kJ);
fprintf('S1 = %.4f kJ/(kg K)\n',S1/kJ);

fprintf('\nState 2:\n');
fprintf('T2 = %.2f K\n',T2);
fprintf('P2 = %.2f kPa\n',P2/kPa);
fprintf('h2 = %.2f kJ/kg\n',h2/kJ);
fprintf('S2 = %.4f kJ/(kg K)\n',S2/kJ);

fprintf('\nIdeal compressor state 3s:\n');
fprintf('T3s = %.2f K\n',T3s);
fprintf('P3  = %.2f kPa\n',P3/kPa);
fprintf('h3s = %.2f kJ/kg\n',h3s/kJ);
fprintf('S3s = %.4f kJ/(kg K)\n',S3s/kJ);

fprintf('\nActual compressor state 3:\n');
fprintf('T3 = %.2f K\n',T3);
fprintf('P3 = %.2f kPa\n',P3/kPa);
fprintf('h3 = %.2f kJ/kg\n',h3/kJ);
fprintf('S3 = %.4f kJ/(kg K)\n',S3/kJ);

fprintf('\nAir mass flow rate = %.4f kg/s\n',mair);

fprintf('Compressor power   = %.3f MW\n',Wcomp/1e6);

fprintf('\nNOTE: eta_c = %.3f is TEMPORARY.\n',eta_c);
fprintf('Replace eta_c when the official compressor efficiency is found.\n');

fprintf('============================================================\n');

%% ========================================================================
% END OF PART 1
% =========================================================================
%
% Values required by Part 2:
%
% T3
% P3
% h3
% S3
% mair
% Wcomp
% Yair
%
% The next section will be:
%
% PART 2 - COMBUSTOR
%
% Do not continue until the Part 1 results have been checked.


%% ========================================================================
% PART 2 - COMBUSTOR 3 -> 4
% =========================================================================
%
% The combustor has two separate jobs:
%
%   A) Chemistry : which species leave the combustor   -> Yprod
%   B) Energy    : how hot the products leave           -> T4
%
% Model (ideal turbojet, Turns Fig. 8.19 / Lecture 2 slide 13):
%
% - steady flow, adiabatic (Qloss = 0), no shaft work
% - kinetic and potential energy neglected (flow is slow, as v2 = 0)
% - complete combustion H2 + 0.5 O2 -> H2O (no dissociation)
% - N2 does not react; the excess O2 leaves unreacted
% - constant-pressure combustion (P4 = P3)
% - fuel enters as H2 gas at the reference temperature Tref
%
% Species order (same as Part 1): [H2, O2, CO2, H2O, N2]

%% Part 2 model inputs
% Only these lines need to change if the official model differs.

Tfuel    = Tref;     % Fuel inlet temperature [K]
P4overP3 = 1;        % Combustor pressure ratio [-] (1 = no pressure loss)
Qloss    = 0;        % Heat lost to the surroundings [W]

% Qloss = 0 because the combustor is assumed adiabatic: no heat crosses
% its walls, so all energy released by the reaction stays in the gas.

%% ========================================================================
% A) COMBUSTION CHEMISTRY
% =========================================================================

%% Mass flow through the combustor
%
% Mass is conserved: everything that enters the combustor also leaves it.

mprod = mair + mfurate;                 % Product mass flow [kg/s]

%% Species flows entering the combustor
%
% Air stream  : mair*Yair
% Fuel stream : mfurate*Yfuel (pure H2)
%
% A reaction equation counts molecules, not kilograms, so the mass flows
% are converted to molar flows: ndot_i = mdot_i/M_i.

mdot_in = mair*Yair + mfurate*Yfuel;    % [kg/s]  per species
ndot_in = mdot_in./Mi;                  % [mol/s] per species

%% Reaction H2 + 0.5 O2 -> H2O
%
% nu is the change in moles of each species per mole of H2 burned
% (negative = consumed, positive = formed).
%
%          H2    O2   CO2  H2O   N2
nu     = [ -1  -0.5    0    1     0 ];

% Complete combustion: all hydrogen burns
ndot_H2_burned = ndot_in(1);

ndot_prod = ndot_in + nu*ndot_H2_burned;    % [mol/s] per species
mdot_prod = ndot_prod.*Mi;                  % [kg/s]  per species

%% Equivalence ratio
%
% Stoichiometric = exactly enough air to burn all fuel.
% Per mole of H2: 0.5 mol O2 is needed, i.e. 0.5/0.21 mol of air.
%
% AF_st = mass of that air / mass of 1 mol H2
% phi   = AF_st/AF        (phi < 1: lean mixture, O2 is left over)

AF_st = (-nu(2)/Xair(2))*MAir/Mi(1);
phi   = AF_st/AF;

%% Product composition

Yprod = mdot_prod/sum(mdot_prod);       % Mass fractions
Xprod = ndot_prod/sum(ndot_prod);       % Mole fractions

% Mean molar mass (mole-weighted, as for air in Part 1) and gas constant
MProd = Xprod*Mi';                      % [kg/mol]
Rprod = Runiv/MProd;                    % [J/(kg K)]

%% Chemistry checks
%
% 1) No negative species: there must be enough O2 for complete combustion
% 2) Mass conservation:  sum of product flows = mair + mfurate
% 3) Element conservation: H, O, C and N atoms are only rearranged
%
% Number of atoms in each molecule:
%            H2  O2  CO2  H2O  N2
atoms = [    2   0    0    2    0 ;     % H
             0   2    2    1    0 ;     % O
             0   0    1    0    0 ;     % C
             0   0    0    0    2 ];    % N

elementsIn  = atoms*ndot_in';           % [mol/s] of H, O, C, N atoms
elementsOut = atoms*ndot_prod';

combustionMassResidual    = sum(mdot_prod) - mprod;
combustionElementResidual = max(abs(elementsOut - elementsIn));

assert(all(ndot_prod >= 0), ...
    'Combustion check failed: not enough O2 for complete combustion.');

assert(abs(combustionMassResidual) < 1e-9*mprod, ...
    'Combustion check failed: product mass flow is not mair + mfurate.');

assert(combustionElementResidual < 1e-9*max(elementsIn), ...
    'Combustion check failed: elements are not conserved.');

%% Print chemistry results

fprintf('\n--- COMBUSTION CHEMISTRY ---\n');
fprintf('Reaction             : H2 + 0.5 O2 -> H2O\n');
fprintf('Stoichiometric AF    : %.2f\n',AF_st);
fprintf('Equivalence ratio    : %.4f (lean, excess O2)\n',phi);
fprintf('Product mass flow    : %.4f kg/s\n',mprod);

fprintf('\n%8s %11s %11s %11s %9s %9s\n', ...
    'Species','in [kg/s]','out [kg/s]','out[mol/s]','Yprod','Xprod');
for i = 1:NSp
    fprintf('%8s %11.4f %11.4f %11.2f %9.4f %9.4f\n', SpS(i).Name, ...
        mdot_in(i), mdot_prod(i), ndot_prod(i), Yprod(i), Xprod(i));
end

fprintf('\nSum of mass fractions Yprod = %.6f\n',sum(Yprod));
fprintf('Sum of mole fractions Xprod = %.6f\n',sum(Xprod));
fprintf('Mass residual               = %.2e kg/s\n',combustionMassResidual);
fprintf('Element residual            = %.2e mol/s\n',combustionElementResidual);
fprintf('Rprod                       = %.2f J/(kg K)\n',Rprod);

%% ========================================================================
% B) PRODUCT PROPERTIES AND ENERGY BALANCE
% =========================================================================

%% NASA properties of the product mixture
%
% Same mixing rule as for air, now weighted with Yprod:
%
% h_prod(T)  = sum Yprod_i*h_i(T)
% sT_prod(T) = sum Yprod_i*sT_i(T)
%
% From state 4 on (turbine, nozzle) these curves replace the air curves.

hprod_a = Yprod*hia';
sprod_a = Yprod*sia';

%% Fuel inlet enthalpy

hfuel = HNasa(Tfuel,SpS(1));            % Pure H2 [J/kg]

%% Combustor energy balance
%
% Steady flow, W = 0, kinetic and potential energy neglected:
%
% mair*h3 + mfurate*hfuel = mprod*h4 + Qloss
%
% Energy in (air + fuel) = energy out (products + heat lost to the
% surroundings). Adiabatic combustor: Qloss = 0 (see Part 2 model inputs).
%
% No heating value (LHV) is added. The NASA enthalpies contain the
% formation enthalpy of every species, and that of H2O is strongly
% negative. The chemical energy release is therefore already hidden in
% the difference between the reactant and product enthalpy curves.

Hdot_in = mair*h3 + mfurate*hfuel;      % Enthalpy flow entering [W]

h4 = (Hdot_in - Qloss)/mprod;           % Specific enthalpy leaving [J/kg]

%% Determine T4 from the product enthalpy curve
%
% h4 is almost equal to h3: combustion does not add enthalpy, it moves
% the gas onto a different h(T) curve. On the product curve the same
% enthalpy belongs to a much higher temperature.

T4 = interp1(hprod_a,TR,h4);

assert(~isnan(T4), ...
    'Combustor check failed: T4 is outside the temperature range TR.');

%% State 4

P4 = P4overP3*P3;

s4thermal = interp1(TR,sprod_a,T4);

% Total entropy, same convention as Part 1 but with Rprod:
%
% S = s_thermal - Rprod*ln(P/Pref)
%
% Like in Part 1, the mixing-entropy term is left out. It is constant for
% a fixed composition, so it cancels between states 4, 5 and 6. S4 can
% therefore not be compared directly with S3 (different mixture).

S4 = s4thermal - Rprod*log(P4/Pref);

%% Combustor checks
%
% Independent check of the h -> T inversion: evaluate the NASA
% polynomials directly at the T4 found and redo the energy balance.

hi4 = zeros(1,NSp);
for i = 1:NSp
    hi4(i) = HNasa(T4,SpS(i));
end
h4check = Yprod*hi4';

combustorEnergyResidual = Hdot_in - Qloss - mprod*h4check;     % [W]

assert(T4 > T3, ...
    'Combustor check failed: T4 should be greater than T3.');

assert(abs(combustorEnergyResidual)/mprod < 1, ...
    'Combustor check failed: energy balance error above 1 J/kg.');

%% Where is the combustion energy? (check only, NOT used in the model)
%
% Put reactants and products at the same temperature Tref. The enthalpy
% difference per kg of fuel is the heat the reaction can release, i.e.
% the lower heating value. For H2 it should be about 120 MJ/kg.

hair_ref  = interp1(TR,hair_a,Tref);
hprod_ref = interp1(TR,hprod_a,Tref);
hfuel_ref = HNasa(Tref,SpS(1));

LHVcheck = (mair*hair_ref + mfurate*hfuel_ref - mprod*hprod_ref)/mfurate;

%% Print combustor results

fprintf('\n--- COMBUSTOR 3 -> 4 ---\n');
fprintf('Tfuel = %.2f K\n',Tfuel);
fprintf('hfuel = %.2f J/kg\n',hfuel);
fprintf('Qloss = %.2f W\n',Qloss);
fprintf('T3    = %.2f K\n',T3);
fprintf('T4    = %.2f K\n',T4);
fprintf('P3    = %.0f Pa\n',P3);
fprintf('P4    = %.0f Pa\n',P4);
fprintf('h3    = %.2f J/kg\n',h3);
fprintf('h4    = %.2f J/kg\n',h4);
fprintf('S4    = %.2f J/(kg K)\n',S4);

fprintf('Combustor energy residual = %.3f W\n',combustorEnergyResidual);

fprintf('LHV check (not used)      = %.2f MJ/kg H2\n',LHVcheck/1e6);
fprintf('Chemical energy released  = %.2f MW\n',mfurate*LHVcheck/1e6);

%% ========================================================================
% PART 2 SUMMARY
% =========================================================================

fprintf('\n============================================================\n');
fprintf('                    PART 2 SUMMARY\n');
fprintf('============================================================\n');

fprintf('\nCombustion (H2 + 0.5 O2 -> H2O):\n');
fprintf('mair  = %.4f kg/s\n',mair);
fprintf('mfuel = %.4f kg/s\n',mfurate);
fprintf('mprod = %.4f kg/s\n',mprod);
fprintf('phi   = %.4f\n',phi);
fprintf('Yprod [H2 O2 CO2 H2O N2] = [%.4f %.4f %.4f %.4f %.4f]\n',Yprod);
fprintf('Xprod [H2 O2 CO2 H2O N2] = [%.4f %.4f %.4f %.4f %.4f]\n',Xprod);
fprintf('Rprod = %.2f J/(kg K)\n',Rprod);

fprintf('\nCombustor outlet state 4:\n');
fprintf('T4 = %.2f K\n',T4);
fprintf('P4 = %.2f kPa\n',P4/kPa);
fprintf('h4 = %.2f kJ/kg\n',h4/kJ);
fprintf('S4 = %.4f kJ/(kg K)\n',S4/kJ);

fprintf('\nAssumptions: Tfuel = %.2f K, P4/P3 = %.2f, Qloss = %.0f W\n', ...
    Tfuel,P4overP3,Qloss);
fprintf('NOTE: state 4 depends on eta_c = %.3f from Part 1.\n',eta_c);

fprintf('============================================================\n');

%% ========================================================================
% END OF PART 2
% =========================================================================
%
% Values required by Part 3 (turbine 4 -> 5, nozzle 5 -> 6):
%
% T4, P4, h4, s4thermal, S4   turbine inlet state
% mprod                       mass flow through turbine and nozzle
% Yprod, Xprod                product composition (fixed from here on)
% Rprod                       gas constant of the products
% hprod_a, sprod_a            product property curves over TR
% Wcomp, mair, h2, h3         compressor power the turbine must deliver
%
% From state 4 on, use hprod_a, sprod_a and Rprod, never the air ones.

%% ========================================================================
% PART 3 - TURBINE 4 -> 5 AND NOZZLE 5 -> 6
% =========================================================================
%
% Model assumptions (ideal turbojet, Lecture 2):
%  - steady flow, adiabatic, negligible potential energy
%  - turbine drives only the compressor, no shaft losses: Wturb = Wcomp
%  - kinetic energy at combustor and turbine outlet neglected: v4 = v5 = 0
%  - nozzle expands to ambient pressure: P6 = Pamb
%  - composition frozen from state 4 on: only product properties used
%  - isentropic efficiencies not provided, assumed eta_t = eta_n = 1
%    (same assumption as eta_c in Part 1)

eta_t = 1.0;    % Turbine isentropic efficiency [-] (assumed)
eta_n = 1.0;    % Nozzle isentropic efficiency  [-] (assumed)
v4    = 0;      % Combustor outlet velocity [m/s]
v5    = 0;      % Turbine outlet velocity   [m/s]

%% ========================================================================
% TURBINE 4 -> 5
% =========================================================================
% Energy balance: Wturb = mprod*(h4 - h5)
% Shaft balance:  Wturb = Wcomp = mair*(h3 - h2)
%
% => h5 = h4 - (mair/mprod)*(h3 - h2)

Wturb = Wcomp;                          % [W]
h5    = h4 - Wturb/mprod;               % [J/kg]
T5    = interp1(hprod_a,TR,h5);         % [K]

% Isentropic reference state 5s: eta_t = (h4-h5)/(h4-h5s)
h5s        = h4 - (h4-h5)/eta_t;
T5s        = interp1(hprod_a,TR,h5s);
s5sthermal = interp1(TR,sprod_a,T5s);

% S5s = S4:  s5s_thermal - s4thermal - Rprod*ln(P5/P4) = 0
P5 = P4*exp((s5sthermal - s4thermal)/Rprod);   % [Pa]

S5s = s5sthermal - Rprod*log(P5/Pref);

s5thermal = interp1(TR,sprod_a,T5);
S5        = s5thermal - Rprod*log(P5/Pref);    % [J/(kg K)]

%% Turbine checks

% Independent check of the h -> T inversion with the NASA polynomials
hi5 = zeros(1,NSp);
for i = 1:NSp
    hi5(i) = HNasa(T5,SpS(i));
end
turbineInversionError  = Yprod*hi5' - h5;           % [J/kg]
shaftResidual          = mprod*(h4-h5) - Wcomp;     % [W]
turbineEntropyResidual = S5s - S4;                  % [J/(kg K)]

assert(~any(isnan([T5 T5s])),         'Turbine: T5 or T5s outside TR range.');
assert(P5 < P4 && T5 < T4,            'Turbine: P and T must drop over turbine.');
assert(T5 >= T5s - 1e-6,              'Turbine: actual T5 below ideal T5s.');
assert(S5 >= S4 - 1e-6,               'Turbine: entropy decreases.');
assert(abs(turbineInversionError) < 1,'Turbine: h -> T inversion error > 1 J/kg.');
assert(abs(shaftResidual) < 1e-6*Wcomp,     'Turbine: shaft balance not closed.');
assert(abs(turbineEntropyResidual) < 1e-6,  'Turbine: 5s not isentropic with 4.');

%% Print turbine results

fprintf('\n--- TURBINE 4 -> 5 ---\n');
fprintf('Assumed eta_t = %.3f\n',eta_t);
fprintf('T4   = %.2f K\n',T4);
fprintf('T5s  = %.2f K\n',T5s);
fprintf('T5   = %.2f K\n',T5);
fprintf('P4   = %.0f Pa\n',P4);
fprintf('P5   = %.0f Pa\n',P5);
fprintf('h5   = %.2f J/kg\n',h5);
fprintf('S5   = %.2f J/(kg K)\n',S5);
fprintf('Turbine power          = %.3f MW\n',Wturb/1e6);
fprintf('Shaft residual         = %.2e W\n',shaftResidual);
fprintf('h5 inversion error     = %.2e J/kg\n',turbineInversionError);

%% ========================================================================
% NOZZLE 5 -> 6
% =========================================================================

P6 = Pamb;                                     % [Pa]
assert(P5 > P6, 'Nozzle: P5 must be above Pamb.');

% Isentropic reference state 6s: S6s = S5
s6sthermal = s5thermal + Rprod*log(P6/P5);
T6s        = interp1(sprod_a,TR,s6sthermal);
h6s        = interp1(TR,hprod_a,T6s);
S6s        = s6sthermal - Rprod*log(P6/Pref);

% Actual state 6: eta_n = (h5-h6)/(h5-h6s)
h6        = h5 - eta_n*(h5-h6s);
T6        = interp1(hprod_a,TR,h6);
s6thermal = interp1(TR,sprod_a,T6);
S6        = s6thermal - Rprod*log(P6/Pref);

% Energy balance: h5 + v5^2/2 = h6 + v6^2/2  (h in J/kg, not kJ/kg)
v6s = sqrt(v5^2 + 2*(h5-h6s));                 % Ideal exhaust velocity [m/s]
v6  = sqrt(v5^2 + 2*(h5-h6));                  % Actual exhaust velocity [m/s]

%% Nozzle checks

nozzleEnergyResidual  = (h5 + v5^2/2) - (h6 + v6^2/2);   % [J/kg]
nozzleEntropyResidual = S6s - S5;                        % [J/(kg K)]

assert(~any(isnan([T6 T6s])),            'Nozzle: T6 or T6s outside TR range.');
assert(T6 < T5 && h6 < h5,               'Nozzle: T and h must drop over nozzle.');
assert(v6 > v5,                          'Nozzle: flow does not accelerate.');
assert(v6 <= v6s + 1e-6,                 'Nozzle: actual v6 above ideal v6s.');
assert(S6 >= S5 - 1e-6,                  'Nozzle: entropy decreases.');
assert(abs(nozzleEnergyResidual) < 1e-6, 'Nozzle: energy balance not closed.');
assert(abs(nozzleEntropyResidual) < 1e-6,'Nozzle: 6s not isentropic with 5.');

%% Print nozzle results

fprintf('\n--- NOZZLE 5 -> 6 ---\n');
fprintf('Assumed eta_n = %.3f\n',eta_n);
fprintf('T6s  = %.2f K\n',T6s);
fprintf('T6   = %.2f K\n',T6);
fprintf('P6   = %.0f Pa\n',P6);
fprintf('h6   = %.2f J/kg\n',h6);
fprintf('S6   = %.2f J/(kg K)\n',S6);
fprintf('v6s  = %.2f m/s\n',v6s);
fprintf('v6   = %.2f m/s\n',v6);
fprintf('Nozzle energy residual = %.2e J/kg\n',nozzleEnergyResidual);

%% ========================================================================
% PART 3 SUMMARY
% =========================================================================

fprintf('\n============================================================\n');
fprintf('                    PART 3 SUMMARY\n');
fprintf('============================================================\n');
fprintf('State |   P [kPa] |    T [K] |  v [m/s] | h [kJ/kg] | S [kJ/(kg K)]\n');
fprintf('  4   | %9.2f | %8.2f | %8.2f | %9.2f | %8.4f\n',P4/kPa,T4,v4,h4/kJ,S4/kJ);
fprintf('  5   | %9.2f | %8.2f | %8.2f | %9.2f | %8.4f\n',P5/kPa,T5,v5,h5/kJ,S5/kJ);
fprintf('  6   | %9.2f | %8.2f | %8.2f | %9.2f | %8.4f\n',P6/kPa,T6,v6,h6/kJ,S6/kJ);
fprintf('\nTurbine power = %.3f MW (= compressor power %.3f MW)\n', ...
    Wturb/1e6,Wcomp/1e6);
fprintf('Assumed eta_t = %.2f, eta_n = %.2f\n',eta_t,eta_n);
fprintf('============================================================\n');

%% ========================================================================
% END OF PART 3
% =========================================================================
%
% Values required by Part 4:
%
% T5, P5, h5, S5          turbine outlet state
% T5s, h5s, S5s           ideal turbine reference (validation)
% T6, P6, h6, S6, v6      nozzle outlet state + exhaust velocity
% T6s, h6s, S6s, v6s      ideal nozzle reference (validation)
% v4, v5                  velocities for the state table
% Wturb                   shaft-balance validation
% shaftResidual, nozzleEnergyResidual,
% turbineEntropyResidual, nozzleEntropyResidual   residuals for 6.4