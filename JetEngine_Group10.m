%% 4EB00 Thermodynamics - Jet Engine
% Group 10
%
% Cycle:
% 1 -> 2 : Diffuser
% 2 -> 3 : Compressor
% 3 -> 4 : Combustor
% 4 -> 5 : Turbine
% 5 -> 6 : Nozzle

clear;
close all;
clc;

%% Setup

% Folder containing the NASA functions and database
generalFolder = 'General';

% Check that the folder exists
assert(isfolder(generalFolder), ...
    'General folder not found. Check the MATLAB Current Folder.');

% Make NASA functions available to MATLAB
addpath(generalFolder);

% Useful units
kJ   = 1e3;
kmol = 1e3;
kPa  = 1e3;
bara = 1e5;

% Constants used by NASA functions
global Runiv pref

Runiv = 8.314472;     % Universal gas constant [J/mol/K]
pref  = 1.01235e5;    % Reference pressure [Pa]
Tref  = 298.15;       % Reference temperature [K]

% Load NASA thermodynamic database
databaseFile = fullfile(generalFolder, 'NasaThermalDatabase.mat');

assert(isfile(databaseFile), ...
    'NasaThermalDatabase.mat not found inside General.');

load(databaseFile);

% Check that the database loaded correctly
assert(exist('Sp','var') == 1, ...
    'NASA database did not load correctly.');

disp('NASA database loaded successfully.');

%% Group 10 input data

cFuel    = 'H2';      % Fuel

Tamb     = 300;       % Ambient temperature [K]
Pamb     = 100000;    % Ambient pressure [Pa]

P3overP2 = 9;         % Compressor pressure ratio [-]

mfurate  = 0.58;      % Fuel mass flow rate [kg/s]
AF       = 204.42;    % Air-fuel ratio [-]

v1       = 200;       % Flight velocity [m/s]

% Air mass flow rate
mair = AF * mfurate;

%% Display initial data

fprintf('\n--- GROUP 10 INPUT DATA ---\n');
fprintf('Fuel                 : %s\n', cFuel);
fprintf('Ambient temperature  : %.2f K\n', Tamb);
fprintf('Ambient pressure     : %.0f Pa\n', Pamb);
fprintf('Pressure ratio P3/P2 : %.2f\n', P3overP2);
fprintf('Fuel mass flow       : %.4f kg/s\n', mfurate);
fprintf('Air-fuel ratio       : %.2f\n', AF);
fprintf('Air mass flow        : %.4f kg/s\n', mair);
fprintf('Flight velocity      : %.2f m/s\n', v1);

%% Species and air mixture

% Species used in the jet engine model
speciesNames = {cFuel, 'O2', 'CO2', 'H2O', 'N2'};

% Find the corresponding species in the NASA database
iSp = myfind({Sp.Name}, speciesNames);

% Store only the selected species
SpS = Sp(iSp);

% Molecular masses [kg/mol]
Mi = [SpS.Mass];

% Air composition in mole fractions
% Order: [H2, O2, CO2, H2O, N2]
Xair = [0, 0.21, 0, 0, 0.79];

% Mean molar mass of air
MAir = Xair * Mi';

% Convert mole fractions to mass fractions
Yair = Xair .* Mi / MAir;

%% Check air composition

fprintf('\n--- AIR COMPOSITION ---\n');

fprintf('Sum of mole fractions Xair = %.6f\n', sum(Xair));
fprintf('Sum of mass fractions Yair = %.6f\n', sum(Yair));

disp('Mole fractions Xair:');
disp(Xair);

disp('Mass fractions Yair:');
disp(Yair);

%% NASA properties of air

% Temperature range used for the cycle calculations
TR = (200:1:3000)';      % Temperature [K]

% Number of selected species
nSp = length(SpS);

% Preallocate matrices
hia = zeros(length(TR), nSp);
sia = zeros(length(TR), nSp);

% Calculate enthalpy and temperature-dependent entropy
% for every species over the full temperature range
for i = 1:nSp

    hTemp = HNasa(TR, SpS(i));
    sTemp = SNasa(TR, SpS(i));

    hia(:,i) = hTemp(:);
    sia(:,i) = sTemp(:);

end

% Air mixture properties
% Mass-fraction weighted average of the species properties
hair_a = hia * Yair';
sair_a = sia * Yair';

%% Check NASA air properties

% Evaluate the air properties at 300 K
hAir300 = interp1(TR, hair_a, 300);
sAirT300 = interp1(TR, sair_a, 300);

fprintf('\n--- NASA AIR PROPERTIES ---\n');
fprintf('Air enthalpy at 300 K            : %.2f J/kg\n', hAir300);
fprintf('Air entropy temperature part     : %.2f J/(kg K)\n', sAirT300);

% Basic checks
assert(all(isfinite(hair_a)), ...
    'Invalid values found in air enthalpy array.');

assert(all(isfinite(sair_a)), ...
    'Invalid values found in air entropy array.');

%% State 1 - Engine inlet

T1 = Tamb;         % [K]
P1 = Pamb;         % [Pa]

% Air properties at state 1
h1  = interp1(TR, hair_a, T1);
sT1 = interp1(TR, sair_a, T1);

% Gas constant of the air mixture
Rair = Runiv / MAir;    % [J/(kg K)]

fprintf('\n--- STATE 1 ---\n');
fprintf('T1   = %.2f K\n', T1);
fprintf('P1   = %.0f Pa\n', P1);
fprintf('v1   = %.2f m/s\n', v1);
fprintf('h1   = %.2f J/kg\n', h1);
fprintf('Rair = %.2f J/(kg K)\n', Rair);

%% Diffuser 1 -> 2

% Assumptions:
% - steady flow
% - adiabatic
% - no shaft work
% - negligible change in potential energy
% - outlet velocity approximately zero
% - isentropic process

v2 = 0;       % [m/s]

% Energy conservation:
% h1 + v1^2/2 = h2 + v2^2/2

h2 = h1 + (v1^2 - v2^2)/2;

% Use NASA enthalpy curve to determine T2
T2 = interp1(hair_a, TR, h2);

% Temperature-dependent entropy at state 2
sT2 = interp1(TR, sair_a, T2);

% Isentropic condition:
% s2 - s1 = 0
%
% sT2 - sT1 - Rair*ln(P2/P1) = 0

P2 = P1 * exp((sT2 - sT1)/Rair);

fprintf('\n--- DIFFUSER 1 -> 2 ---\n');
fprintf('h2 = %.2f J/kg\n', h2);
fprintf('T2 = %.2f K\n', T2);
fprintf('P2 = %.0f Pa\n', P2);

%% Diffuser checks

assert(T2 > T1, ...
    'Diffuser check failed: T2 should be greater than T1.');

assert(P2 > P1, ...
    'Diffuser check failed: P2 should be greater than P1.');

diffuserEnergyResidual = ...
    (h1 + v1^2/2) - (h2 + v2^2/2);

fprintf('Diffuser energy residual = %.6f J/kg\n', ...
    diffuserEnergyResidual);

%% Compressor 2 -> 3 : ideal isentropic reference state

% Compressor outlet pressure
P3 = P3overP2 * P2;

% For the ideal compressor reference state 3s:
% s3s = s2
%
% Therefore:
% sT3s - sT2 - Rair*ln(P3/P2) = 0

sT3s = sT2 + Rair * log(P3/P2);

% Use NASA entropy curve to determine T3s
T3s = interp1(sair_a, TR, sT3s);

% Determine ideal outlet enthalpy
h3s = interp1(TR, hair_a, T3s);

fprintf('\n--- COMPRESSOR IDEAL STATE 3s ---\n');
fprintf('P3  = %.0f Pa\n', P3);
fprintf('T3s = %.2f K\n', T3s);
fprintf('h3s = %.2f J/kg\n', h3s);

%% Compressor ideal-state checks

assert(P3 > P2, ...
    'Compressor check failed: P3 should be greater than P2.');

assert(T3s > T2, ...
    'Compressor check failed: T3s should be greater than T2.');

assert(h3s > h2, ...
    'Compressor check failed: h3s should be greater than h2.');

% Check the isentropic condition numerically
compressorEntropyResidual = ...
    (sT3s - sT2) - Rair*log(P3/P2);

fprintf('Isentropic entropy residual = %.6f J/(kg K)\n', ...
    compressorEntropyResidual);