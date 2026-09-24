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