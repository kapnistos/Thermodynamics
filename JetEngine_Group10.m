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