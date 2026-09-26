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
% Parts 1-4: integrated cycle, independent validation and exported results.
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

clearvars;
close all;
clc;

%% ========================================================================
% SETUP
% =========================================================================

% Relative path to the General folder.
% The General folder must be inside the main project folder.
projectRoot = fileparts(mfilename('fullpath'));
relativepath_to_generalfolder = fullfile(projectRoot,'General');

% Check that the General folder exists
assert(isfolder(relativepath_to_generalfolder), ...
    'General folder not found. Check MATLAB Current Folder.');

% Add NASA functions to MATLAB path
addpath(relativepath_to_generalfolder);

%% Load NASA database

TdataBase = fullfile(relativepath_to_generalfolder,'NasaThermalDatabase');

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

%% PROVISIONAL MODEL SETTINGS - confirm against current Canvas/Turns
% User authorized retaining the repository defaults on 2026-09-26.
% Authorization to use these defaults is NOT course confirmation.
eta_c = 1.0;             % Compressor isentropic efficiency [-]
eta_t = 1.0;             % Turbine isentropic efficiency [-]
eta_n = 1.0;             % Nozzle enthalpy-drop efficiency [-]
Tfuel = Tref;            % Pure H2 gas inlet temperature [K]
P4overP3 = 1;            % No combustor pressure loss [-]
Qloss = 0;              % Adiabatic combustor [W]
% Fixed assumptions: lossless shaft; v2=v3=v4=v5=0; complete combustion;
% frozen products, no dissociation; fully expanded nozzle P6=Pamb.
assert(all(isfinite([eta_c eta_t eta_n Tfuel P4overP3 Qloss])));
assert(all([eta_c eta_t eta_n] > 0 & [eta_c eta_t eta_n] <= 1), ...
    'Component efficiencies must lie in (0,1].');
assert(Tfuel >= 200 && Tfuel <= 3000 && P4overP3 > 0 && P4overP3 <= 1 ...
    && Qloss >= 0, 'Invalid fuel temperature, pressure ratio or heat loss.');
fprintf('\nPROVISIONAL DEFAULTS: confirm efficiencies and loss assumptions before submission.\n');

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
% eta_c is set in the central model settings.
%
% This temporarily means that the compressor is treated as perfectly
% isentropic.
%
% THIS VALUE MUST BE CHECKED BEFORE FINAL SUBMISSION.


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

% Values are defined once in the provisional model settings near the top.

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

% Efficiencies are defined once in the provisional model settings.
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

%% ========================================================================
% PART 4 - INTEGRATION, INDEPENDENT VALIDATION AND RESULTS
% =========================================================================
% Keep Parts 1-3 as the calculation chain. Re-evaluate NASA polynomials here
% at the solved temperatures, rather than checking identities constructed
% from the same enthalpy targets. SI units internally; display units in tables.

resultsDir = fullfile(projectRoot,'results');
if ~isfolder(resultsDir), mkdir(resultsDir); end

v3 = 0;  % Negligible compressor outlet KE, consistent with combustor model.
Tstate = [T1 T2 T3 T4 T5 T6];
Pstate = [P1 P2 P3 P4 P5 P6];
Vstate = [v1 v2 v3 v4 v5 v6];
Htarget = [h1 h2 h3 h4 h5 h6];
Smodel = [S1 S2 S3 S4 S5 S6];
Mflow = [mair mair mair mprod mprod mprod];
Ystate = [repmat(Yair,3,1); repmat(Yprod,3,1)];
Xstate = [repmat(Xair,3,1); repmat(Xprod,3,1)];
Rstate = [Rg Rg Rg Rprod Rprod Rprod];
assert(isreal([Tstate Pstate Vstate Htarget Smodel]) && ...
    all(isfinite([Tstate Pstate Vstate Htarget Smodel])), ...
    'Part 4: all state properties must be finite and real.');
assert(all(Tstate >= min(TR) & Tstate <= max(TR)) && all(Pstate > 0), ...
    'Part 4: temperature outside property grid or nonpositive pressure.');
assert(all(diff(hair_a)>0) && all(diff(hprod_a)>0) && ...
    all(diff(sair_a)>0) && all(diff(sprod_a)>0), ...
    'Part 4: inverse interpolation requires monotonic property arrays.');

Hdirect = zeros(1,6); STdirect = Hdirect; Cpdirect = Hdirect;
Smix = Hdirect;
for j = 1:6
    hi = zeros(1,NSp); si = hi; cpi = hi;
    for i = 1:NSp
        hi(i) = HNasa(Tstate(j),SpS(i));
        si(i) = SNasa(Tstate(j),SpS(i));
        cpi(i) = CpNasa(Tstate(j),SpS(i));
    end
    Hdirect(j) = Ystate(j,:)*hi';
    STdirect(j) = Ystate(j,:)*si';
    Cpdirect(j) = Ystate(j,:)*cpi';
    % Ideal-mixture entropy uses partial pressures Xi*P. Exclude Xi=0
    % explicitly to avoid 0*log(0). Retain old S separately for traceability.
    present = Xstate(j,:) > 0;
    mixing = -sum(Ystate(j,present).*(Runiv./Mi(present)).* ...
        log(Xstate(j,present)));
    Smix(j) = STdirect(j)-Rstate(j)*log(Pstate(j)/Pref)+mixing;
end
Sdirect = STdirect - Rstate.*log(Pstate/Pref);

% Independently reconstruct ideal-state entropy from the solved T3s/T5s/T6s.
Tideal = [T3s T5s T6s]; Pideal = [P3 P5 P6];
Yideal = [Yair; Yprod; Yprod]; Rideal = [Rg Rprod Rprod];
SidealDirect = zeros(1,3); HidealDirect = zeros(1,3);
for j = 1:3
    si = zeros(1,NSp); hi = zeros(1,NSp);
    for i = 1:NSp
        si(i) = SNasa(Tideal(j),SpS(i));
        hi(i) = HNasa(Tideal(j),SpS(i));
    end
    SidealDirect(j) = Yideal(j,:)*si' - Rideal(j)*log(Pideal(j)/Pref);
    HidealDirect(j) = Yideal(j,:)*hi';
end

% Tolerances reflect a 1 K interpolation grid: 1 J/kg for a single
% enthalpy inversion, 0.01 J/(kg K) for entropy. Flow balances allow
% 1 J/kg per independently evaluated inlet/outlet. These are numerical
% tolerances, not estimates of the physical model uncertainty.
hTol = 1; sTol = 0.01;
Check = ["Diffuser energy";"Compressor power";"Combustor energy"; ...
    "Turbine power";"Shaft power";"Nozzle energy";"Whole engine energy"; ...
    "Combustion mass";"Element H";"Element O";"Element C";"Element N"; ...
    "Air X sum";"Air Y sum";"Product X sum";"Product Y sum"; ...
    "Max h inversion";"Diffuser isentropy";"Compressor reference isentropy"; ...
    "Turbine reference isentropy";"Nozzle reference isentropy"];
Residual = [Hdirect(1)+v1^2/2-Hdirect(2)-v2^2/2; ...
    mair*(Hdirect(3)-Hdirect(2))-Wcomp; ...
    mair*Hdirect(3)+mfurate*hfuel-Qloss-mprod*Hdirect(4); ...
    mprod*(Hdirect(4)-Hdirect(5))-Wturb; ...
    mprod*(Hdirect(4)-Hdirect(5))-mair*(Hdirect(3)-Hdirect(2)); ...
    Hdirect(5)+v5^2/2-Hdirect(6)-v6^2/2; ...
    (mair*(Hdirect(1)+v1^2/2)+mfurate*hfuel ...
        -mprod*(Hdirect(6)+v6^2/2)-Qloss); ...
    sum(mdot_prod)-mair-mfurate; elementsOut-elementsIn; ...
    sum(Xair)-1;sum(Yair)-1;sum(Xprod)-1;sum(Yprod)-1; ...
    max(abs(Hdirect-Htarget)); Sdirect(2)-Sdirect(1); ...
    SidealDirect(1)-Sdirect(2);SidealDirect(2)-Sdirect(4); ...
    SidealDirect(3)-Sdirect(5)];
Tolerance = [2*hTol;2*mair*hTol;(mair+mprod)*hTol;2*mprod*hTol; ...
    2*(mair+mprod)*hTol;2*hTol;(mair+mprod)*hTol;1e-9*mprod; ...
    1e-9*max(abs(elementsIn),1);1e-10;1e-10;1e-10;1e-10; ...
    hTol;sTol;sTol;sTol;sTol];
Unit = ["J/kg";"W";"W";"W";"W";"J/kg";"W";"kg/s"; ...
    repmat("mol atoms/s",4,1);repmat("-",4,1);"J/kg"; ...
    repmat("J/(kg K)",4,1)];
Passed = isfinite(Residual) & abs(Residual) <= Tolerance;
ToleranceFraction = abs(Residual)./Tolerance;
validationTable = table(Check,Residual,Tolerance,Unit,ToleranceFraction,Passed);
% A fraction <= 1 passes. This is NOT relative physical error: its
% denominator is the numerical acceptance tolerance for this specific check.
writetable(validationTable,fullfile(resultsDir,'validation.csv'));
disp(validationTable);
assert(all(Passed), 'Part 4 failed: %s. Inspect results/validation.csv.', ...
    strjoin(Check(~Passed),', '));

% Compare actual and ideal states explicitly, and reconstruct efficiencies
% from direct NASA enthalpies to check both definitions and state inversions.
Component = ["Compressor";"Turbine";"Nozzle"];
EtaSpecified = [eta_c;eta_t;eta_n];
EtaReconstructed = [(HidealDirect(1)-Hdirect(2))/(Hdirect(3)-Hdirect(2)); ...
    (Hdirect(4)-Hdirect(5))/(Hdirect(4)-HidealDirect(2)); ...
    (Hdirect(5)-Hdirect(6))/(Hdirect(5)-HidealDirect(3))];
ActualOutlet_K = [T3;T5;T6]; IdealOutlet_K = Tideal';
DeltaS_J_kgK = [Sdirect(3)-Sdirect(2);Sdirect(5)-Sdirect(4); ...
    Sdirect(6)-Sdirect(5)];
componentTable = table(Component,EtaSpecified,EtaReconstructed, ...
    ActualOutlet_K,IdealOutlet_K,DeltaS_J_kgK);
assert(all(abs(EtaReconstructed-EtaSpecified)<1e-4), ...
    'Part 4: reconstructed efficiencies disagree with specified values.');

assert(all(Yprod>=0) && all(Xprod>=0), 'Negative product fraction.');
assert(T2>T1 && T3>T2 && T4>T3 && T5<T4 && T6<T5, ...
    'Part 4: unexpected temperature trend.');
assert(P2>P1 && P3>P2 && P4<=P3 && P5<P4 && P5>P6 && P6==Pamb, ...
    'Part 4: unexpected pressure trend.');
assert(T3>=T3s-1e-6 && T5>=T5s-1e-6 && T6>=T6s-1e-6 && v6<=v6s+1e-6, ...
    'Part 4: inconsistent efficiency trend.');
assert(all([Sdirect(3)-Sdirect(2),Sdirect(5)-Sdirect(4), ...
    Sdirect(6)-Sdirect(5)] >= -sTol), ...
    'Part 4: entropy decreases in an adiabatic component.');

State = (1:6)';
Location = ["Inlet";"Diffuser outlet";"Compressor outlet"; ...
    "Combustor outlet";"Turbine outlet";"Nozzle exit"];
Mixture = [repmat("Air",3,1);repmat("Products",3,1)];
stateTable = table(State,Location,Mixture,Tstate',Pstate'/kPa,Vstate', ...
    Hdirect'/kJ,Smix'/kJ,Smodel'/kJ,Mflow', ...
    'VariableNames',{'State','Location','Mixture','T_K','P_kPa','v_m_s', ...
    'h_kJ_kg','s_mix_kJ_kgK','s_model_kJ_kgK','mdot_kg_s'});
compositionTable = table(string({SpS.Name})',Mi',Xair',Yair',Xprod',Yprod', ...
    mdot_prod','VariableNames',{'Species','M_kg_mol','Xair','Yair', ...
    'Xprod','Yprod','mdot_products_kg_s'});

% A local frozen-composition sound speed diagnoses the prescribed expansion.
% No constant-cp/Poisson relation is used to solve the cycle.
assert(all(Cpdirect>Rstate), 'Invalid heat capacity for sound-speed check.');
gamma6 = Cpdirect(6)/(Cpdirect(6)-Rprod);
Mach6 = v6/sqrt(gamma6*Rprod*T6);

Setting = ["eta_c";"eta_t";"eta_n";"Tfuel_K";"P4overP3"; ...
    "Qloss_W";"shaft_efficiency";"v2_v3_v4_v5_m_s"];
Value = [eta_c;eta_t;eta_n;Tfuel;P4overP3;Qloss;1;0];
Status = repmat("PROVISIONAL default - confirm against Canvas/Turns",8,1);
assumptionsTable = table(Setting,Value,Status);

fprintf('\n================ PART 4: CHECKED FINAL RESULTS ================\n');
disp(stateTable);
disp(compositionTable);
fprintf('Air / fuel / products: %.4f / %.4f / %.4f kg/s\n',mair,mfurate,mprod);
fprintf('Compressor / turbine: %.6f / %.6f MW\n',Wcomp/1e6,Wturb/1e6);
fprintf('Exhaust velocity: %.6f m/s; exit Mach number: %.4f\n',v6,Mach6);
fprintf('Independent numerical checks: %d/%d passed.\n',sum(Passed),numel(Passed));
[worstFraction,worstIndex] = max(ToleranceFraction);
fprintf('Largest tolerance fraction: %.4f (%s); limit = 1.\n', ...
    worstFraction,Check(worstIndex));
disp(componentTable);
fprintf('s_mix includes mixing entropy; s_model retains the original convention.\n');
fprintf('Negative product enthalpy is permitted by the formation-enthalpy reference.\n');
if Mach6 > 1
    fprintf('P6=Pamb implies supersonic fully expanded flow: suitable nozzle geometry is assumed.\n');
end
disp(assumptionsTable);
fprintf('Defaults are not officially confirmed. See PART4_EXPLANATION.md.\n');

writetable(stateTable,fullfile(resultsDir,'state_table.csv'));
writetable(compositionTable,fullfile(resultsDir,'composition.csv'));
writetable(componentTable,fullfile(resultsDir,'component_comparison.csv'));
writetable(assumptionsTable,fullfile(resultsDir,'provisional_assumptions.csv'));
save(fullfile(resultsDir,'Group10_results.mat'),'stateTable','compositionTable', ...
    'validationTable','componentTable','assumptionsTable','Wcomp','Wturb','v6','Mach6','phi');

% A short, regenerated summary that a teammate can read without MATLAB.
summaryPath = fullfile(resultsDir,'results_summary.txt');
fid = fopen(summaryPath,'w');
assert(fid>=0,'Could not open results summary for writing.');
fprintf(fid,'GROUP 10 - PART 4 VALIDATED RESULTS\n');
fprintf(fid,'Model status: PROVISIONAL assumptions; numerical validation PASS.\n\n');
fprintf(fid,'Exhaust velocity: %.6f m/s\n',v6);
fprintf(fid,'Combustor outlet: %.6f K\n',T4);
fprintf(fid,'Compressor / turbine power: %.6f / %.6f MW\n',Wcomp/1e6,Wturb/1e6);
fprintf(fid,'Air / fuel / products: %.4f / %.4f / %.4f kg/s\n',mair,mfurate,mprod);
fprintf(fid,'Checks: %d/%d pass; reconstructed efficiencies also pass.\n',sum(Passed),numel(Passed));
fprintf(fid,'Largest abs(residual)/tolerance: %.6f (%s); pass limit 1.\n',worstFraction,Check(worstIndex));
fprintf(fid,'Defaults: eta_c=%.3f, eta_t=%.3f, eta_n=%.3f, Tfuel=%.2f K, P4/P3=%.3f, Qloss=%.3f W.\n', ...
    eta_c,eta_t,eta_n,Tfuel,P4overP3,Qloss);
fprintf(fid,'Lossless shaft; negligible internal kinetic energy; frozen complete-combustion products.\n');
fprintf(fid,'Exit Mach %.4f: prescribed fully expanded flow assumes suitable nozzle geometry.\n',Mach6);
fprintf(fid,'See PART4_REPORT_SECTION.md for report-ready explanation.\n');
fclose(fid);

fig = figure('Visible','off','Color','white','Position',[100 100 1100 700]);
tiledlayout(2,2,'TileSpacing','compact');
nexttile; plot(State,Tstate,'o-','LineWidth',1.8); grid on;
xlabel('State'); ylabel('Temperature [K]'); title('Temperature through the engine');
nexttile; plot(State,Pstate/kPa,'o-','LineWidth',1.8); grid on;
xlabel('State'); ylabel('Pressure [kPa]'); title('Compression and expansion');
nexttile; plot(State,Vstate,'o-','LineWidth',1.8); grid on;
xlabel('State'); ylabel('Velocity [m/s]'); title('Negligible internal KE approximation');
nexttile; bar(categorical(string({SpS.Name})),Yprod); grid on;
ylabel('Product mass fraction [-]'); title('Lean hydrogen combustion products');
sgtitle('Group 10 - PROVISIONAL ideal baseline');
exportgraphics(fig,fullfile(resultsDir,'cycle_overview.png'),'Resolution',160);
close(fig);
