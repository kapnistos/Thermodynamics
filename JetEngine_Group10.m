clear all;close all;clc;
warning off

%% Setup
% General contains the NASA database and all supplied NASA functions.
projectRoot=fileparts(mfilename('fullpath'));
relativepath_to_generalfolder=fullfile(projectRoot,'General');
resultsDir=fullfile(projectRoot,'results');

if ~isfolder(resultsDir),mkdir(resultsDir);end
addpath(relativepath_to_generalfolder);

TdataBase=fullfile(relativepath_to_generalfolder,'NasaThermalDatabase');
assert(isfile([TdataBase '.mat']),'NasaThermalDatabase.mat not found inside General.');
load(TdataBase);
assert(exist('Sp','var')==1,'NASA database did not load correctly.');

runId=char(datetime('now','TimeZone','UTC','Format','yyyyMMdd''T''HHmmssSSS'));
writeJson(fullfile(resultsDir,'run_status.json'),struct('run_id',runId,'status','INCOMPLETE'));

%% NASA constants
% Values supplied by the course and used by the NASA functions.
global Runiv Pref
Runiv=8.314472;       % Universal gas constant [J/mol/K]
Pref=1.01235e5;       % Reference pressure [Pa]
Tref=298.15;          % Reference temperature [K]

%% Convenient units
kJ=1e3;kmol=1e3;dm=0.1;bara=1e5;kPa=1e3;kN=1e3;kg=1;s=1;

%% Group 10 given conditions
v1=200;               % Flight velocity [m/s]
Tamb=300;             % Ambient temperature [K]
P3overP2=9;           % Compressor pressure ratio [-]
Pamb=100000;          % Ambient pressure [Pa]
mfurate=0.58*kg/s;    % Fuel mass flow [kg/s]
AF=204.42;            % Air-fuel ratio [-]
cFuel='H2';           % Fuel

%% Model assumptions
% Ideal cycle: all component efficiencies are 1 (confirmed by the lecturers).
% The combustor is adiabatic and burns at constant pressure (P4=P3).
eta_c=1.0;            % Compressor isentropic efficiency [-]
eta_t=1.0;            % Turbine isentropic efficiency [-]
eta_n=1.0;            % Nozzle efficiency [-]
Tfuel=Tref;           % Fuel inlet temperature [K]

assert(all([eta_c eta_t eta_n]>0 & [eta_c eta_t eta_n]<=1),...
    'Component efficiencies must lie in (0,1].');
assert(Tfuel>=200 && Tfuel<=3000,'Fuel inlet temperature outside the NASA range.');
assert(v1>0 && Tamb>=200 && Tamb<=3000 && P3overP2>1 && Pamb>0 && mfurate>0 && AF>0,...
    'Invalid Group 10 input data.');
assert(strcmp(cFuel,'H2'),'This reaction model is written for H2.');

% AF=mair/mfuel
mair=AF*mfurate;

fprintf('\n--- GROUP 10 INPUT DATA ---\n');
fprintf('Fuel                 : %s\n',cFuel);
fprintf('Ambient temperature  : %.2f K\n',Tamb);
fprintf('Ambient pressure     : %.0f Pa\n',Pamb);
fprintf('Pressure ratio P3/P2 : %.2f\n',P3overP2);
fprintf('Fuel mass flow       : %.4f kg/s\n',mfurate);
fprintf('Air-fuel ratio       : %.2f\n',AF);
fprintf('Air mass flow        : %.4f kg/s\n',mair);
fprintf('Flight velocity      : %.2f m/s\n',v1);

%% Select species
% Species order throughout the code: [H2 O2 CO2 H2O N2].
iSp=myfind({Sp.Name},{cFuel,'O2','CO2','H2O','N2'});
assert(all(iSp>0),'A required species is missing from the NASA database.');

SpS=Sp(iSp);
NSp=length(SpS);
Mi=[SpS.Mass];        % Molecular masses [kg/mol]

%% Air and fuel composition
% Xair contains mole fractions and Yair the corresponding mass fractions.
Xair=[0 0.21 0 0 0.79];
MAir=Xair*Mi';
Yair=Xair.*Mi/MAir;
Yfuel=[1 0 0 0 0];

assert(abs(sum(Xair)-1)<1e-10,'Air mole fractions do not sum to 1.');
assert(abs(sum(Yair)-1)<1e-10,'Air mass fractions do not sum to 1.');

fprintf('\n--- AIR COMPOSITION ---\n');
fprintf('Sum Xair = %.6f\n',sum(Xair));
fprintf('Sum Yair = %.6f\n',sum(Yair));

%% NASA properties of air
% Calculate h(T) and the thermal entropy part over the full temperature range.
TR=200:1:3000;
NTR=length(TR);
hia=zeros(NTR,NSp);
sia=zeros(NTR,NSp);

for i=1:NSp
    hia(:,i)=HNasa(TR,SpS(i));
    sia(:,i)=SNasa(TR,SpS(i));
end

hair_a=Yair*hia';     % Air enthalpy curve [J/kg]
sair_a=Yair*sia';     % Air thermal entropy curve [J/(kg K)]

assert(all(isfinite(hair_a)),'Invalid values in air enthalpy curve.');
assert(all(isfinite(sair_a)),'Invalid values in air entropy curve.');

%% State 1 - engine inlet
% Ideal-gas entropy convention: S=s_thermal(T)-Rg*ln(P/Pref).
T1=Tamb;
P1=Pamb;
Rg=Runiv/MAir;

h1=interp1(TR,hair_a,T1);
s1thermal=interp1(TR,sair_a,T1);
S1=s1thermal-Rg*log(P1/Pref);

fprintf('\n--- STATE 1 ---\n');
fprintf('T1 = %.2f K\n',T1);
fprintf('P1 = %.2f kPa\n',P1/kPa);
fprintf('h1 = %.2f kJ/kg\n',h1/kJ);
fprintf('S1 = %.4f kJ/(kg K)\n',S1/kJ);

%% Diffuser 1 -> 2
% Steady, adiabatic, no shaft work and v2=0.
% h1+v1^2/2=h2+v2^2/2 and the diffuser is assumed isentropic.
v2=0;
h2=h1+0.5*v1^2-0.5*v2^2;

T2=invertProperty(hair_a,TR,h2,'Diffuser T2');
s2thermal=interp1(TR,sair_a,T2);

% S2=S1 determines the diffuser pressure rise.
P2=P1*exp((s2thermal-s1thermal)/Rg);
S2=s2thermal-Rg*log(P2/Pref);

diffuserEnergyResidual=(h1+v1^2/2)-(h2+v2^2/2);

assert(T2>T1,'Diffuser: T2 should be greater than T1.');
assert(P2>P1,'Diffuser: P2 should be greater than P1.');
assert(abs(diffuserEnergyResidual)<1e-6,'Diffuser energy balance is not satisfied.');

fprintf('\n--- DIFFUSER 1 -> 2 ---\n');
fprintf('T1 = %.2f K   T2 = %.2f K\n',T1,T2);
fprintf('P1 = %.2f kPa   P2 = %.2f kPa\n',P1/kPa,P2/kPa);
fprintf('h1 = %.2f kJ/kg   h2 = %.2f kJ/kg\n',h1/kJ,h2/kJ);

%% Compressor 2 -> 3
% First determine the ideal state 3s. For an isentropic compressor S3s=S2.
P3=P3overP2*P2;
s3sthermal=s2thermal+Rg*log(P3/P2);

T3s=invertProperty(sair_a,TR,s3sthermal,'Compressor T3s');
h3s=interp1(TR,hair_a,T3s);
S3s=s3sthermal-Rg*log(P3/Pref);

% eta_c=(h3s-h2)/(h3-h2)
h3=h2+(h3s-h2)/eta_c;
T3=invertProperty(hair_a,TR,h3,'Compressor T3');
s3thermal=interp1(TR,sair_a,T3);
S3=s3thermal-Rg*log(P3/Pref);

wcomp=h3-h2;          % Specific compressor work input [J/kg]
Wcomp=mair*wcomp;     % Compressor power input [W]

assert(P3>P2,'Compressor: P3 should be greater than P2.');
assert(T3s>T2,'Compressor: T3s should be greater than T2.');
assert(T3>=T3s-1e-6,'Compressor: actual T3 should be >= T3s.');
assert(h3>=h3s-1e-6,'Compressor: actual h3 should be >= h3s.');
assert(S3>=S2-1e-6,'Compressor: entropy should not decrease.');

fprintf('\n--- COMPRESSOR 2 -> 3 ---\n');
fprintf('eta_c = %.3f\n',eta_c);
fprintf('P2 = %.2f kPa   P3 = %.2f kPa\n',P2/kPa,P3/kPa);
fprintf('T2 = %.2f K   T3s = %.2f K   T3 = %.2f K\n',T2,T3s,T3);
fprintf('Compressor power = %.3f MW\n',Wcomp/1e6);

%% Part 1 summary
fprintf('\n============================================================\n');
fprintf('PART 1 SUMMARY\n');
fprintf('============================================================\n');
fprintf('State 1: T=%.2f K, P=%.2f kPa, h=%.2f kJ/kg\n',T1,P1/kPa,h1/kJ);
fprintf('State 2: T=%.2f K, P=%.2f kPa, h=%.2f kJ/kg\n',T2,P2/kPa,h2/kJ);
fprintf('State 3: T=%.2f K, P=%.2f kPa, h=%.2f kJ/kg\n',T3,P3/kPa,h3/kJ);
fprintf('Air mass flow = %.4f kg/s\n',mair);
fprintf('Compressor power = %.3f MW\n',Wcomp/1e6);

%% Part 2 - combustion chemistry
% Complete reaction: H2+0.5O2 -> H2O.
% N2 is inert and excess oxygen leaves the combustor unreacted.
mprod=mair+mfurate;
mdot_in=mair*Yair+mfurate*Yfuel;
ndot_in=mdot_in./Mi;

nu=[-1 -0.5 0 1 0];       % Change per mole H2 burned
ndot_H2_burned=ndot_in(1);
ndot_prod=ndot_in+nu*ndot_H2_burned;
mdot_prod=ndot_prod.*Mi;

% Stoichiometric air-fuel ratio and equivalence ratio.
AF_st=(-nu(2)/Xair(2))*MAir/Mi(1);
phi=AF_st/AF;

%% Initial and final mixture composition
% Initial = air + fuel before combustion. Final = combustion products.
Yreac=mdot_in/sum(mdot_in);
Xreac=ndot_in/sum(ndot_in);
MReac=Xreac*Mi';
Rreac=Runiv/MReac;

Yprod=mdot_prod/sum(mdot_prod);
Xprod=ndot_prod/sum(ndot_prod);
MProd=Xprod*Mi';
Rprod=Runiv/MProd;

%% Combustion checks
% Check mass and conservation of H, O, C and N atoms.
atoms=[2 0 0 2 0;...
       0 2 2 1 0;...
       0 0 1 0 0;...
       0 0 0 0 2];

elementsIn=atoms*ndot_in';
elementsOut=atoms*ndot_prod';

combustionMassResidual=sum(mdot_prod)-mprod;
combustionElementResidual=max(abs(elementsOut-elementsIn));

assert(all(ndot_prod>=0),'Combustion: not enough O2 for complete combustion.');
assert(abs(combustionMassResidual)<1e-9*mprod,'Combustion mass is not conserved.');
assert(combustionElementResidual<1e-9*max(elementsIn),'Combustion elements are not conserved.');

fprintf('\n--- COMBUSTION CHEMISTRY ---\n');
fprintf('Reaction          : H2 + 0.5 O2 -> H2O\n');
fprintf('Stoichiometric AF : %.2f\n',AF_st);
fprintf('Equivalence ratio : %.4f\n',phi);
fprintf('Product mass flow : %.4f kg/s\n',mprod);

fprintf('\n%8s %11s %11s %11s %9s %9s\n',...
    'Species','in [kg/s]','out [kg/s]','out[mol/s]','Yprod','Xprod');

for i=1:NSp
    fprintf('%8s %11.4f %11.4f %11.2f %9.4f %9.4f\n',...
        SpS(i).Name,mdot_in(i),mdot_prod(i),ndot_prod(i),Yprod(i),Xprod(i));
end

%% Product NASA properties
% From state 4 onward the working mixture is the combustion products.
hprod_a=Yprod*hia';
sprod_a=Yprod*sia';

%% Combustor 3 -> 4
% Steady, adiabatic, no shaft work and negligible kinetic/potential energy.
% mair*h3+mfurate*hfuel=mprod*h4
% NASA enthalpies include formation enthalpy, so LHV is not added here.
hfuel=HNasa(Tfuel,SpS(1));
Hdot_in=mair*h3+mfurate*hfuel;
h4=Hdot_in/mprod;

T4=invertProperty(hprod_a,TR,h4,'Combustor T4');

% Combustion at constant pressure.
P4=P3;
s4thermal=interp1(TR,sprod_a,T4);
S4=s4thermal-Rprod*log(P4/Pref);

% Independent combustor energy check.
hi4=zeros(1,NSp);

for i=1:NSp
    hi4(i)=HNasa(T4,SpS(i));
end

h4check=Yprod*hi4';
combustorEnergyResidual=Hdot_in-mprod*h4check;

assert(T4>T3,'Combustor: T4 should be greater than T3.');
assert(abs(combustorEnergyResidual)/mprod<1,...
    'Combustor energy balance error above 1 J/kg.');

% LHV check is diagnostic only and is not used in the model.
hair_ref=interp1(TR,hair_a,Tref);
hprod_ref=interp1(TR,hprod_a,Tref);
hfuel_ref=HNasa(Tref,SpS(1));
LHVcheck=(mair*hair_ref+mfurate*hfuel_ref-mprod*hprod_ref)/mfurate;

fprintf('\n--- COMBUSTOR 3 -> 4 ---\n');
fprintf('T3 = %.2f K   T4 = %.2f K\n',T3,T4);
fprintf('P3 = %.2f kPa   P4 = %.2f kPa\n',P3/kPa,P4/kPa);
fprintf('h3 = %.2f kJ/kg   h4 = %.2f kJ/kg\n',h3/kJ,h4/kJ);
fprintf('LHV check = %.2f MJ/kg H2\n',LHVcheck/1e6);

%% Part 2 summary
fprintf('\n============================================================\n');
fprintf('PART 2 SUMMARY\n');
fprintf('============================================================\n');
fprintf('mair  = %.4f kg/s\n',mair);
fprintf('mfuel = %.4f kg/s\n',mfurate);
fprintf('mprod = %.4f kg/s\n',mprod);
fprintf('phi   = %.4f\n',phi);
fprintf('T4    = %.2f K\n',T4);
fprintf('P4    = %.2f kPa\n',P4/kPa);

%% Table 2 - mixture before and after combustor
% Report order differs from the internal species order.
tableRows=[1 2 5 3 4];
tableNames={['Fuel (' cFuel ')'],'O2','N2','CO2','H2O'};

fprintf('\nTABLE 2 - Mixture composition before and after the combustor\n');
fprintf('AF = %.2f (equivalence ratio = %.4f)\n',AF,phi);
fprintf('Stoichiometric AF = %.2f, phi = AF_st/AF\n',AF_st);
fprintf('\n%-16s %10s %10s\n','Mass fractions','Initial','Final');

for k=1:numel(tableRows)
    iRow=tableRows(k);
    fprintf('%-16s %10.5f %10.5f\n',...
        tableNames{k},Yreac(iRow),Yprod(iRow));
end

fprintf('%-16s %10.2f %10.2f\n','Rg [J/(kg K)]',Rreac,Rprod);
fprintf('(Initial = air + fuel unburned, Final = products at state 4)\n');

%% Part 3 - turbine 4 -> 5
% Turbine drives only the compressor and the shaft is assumed lossless.
% Wturb=Wcomp=mprod*(h4-h5).
v4=0;v5=0;
Wturb=Wcomp;

h5=h4-Wturb/mprod;
T5=invertProperty(hprod_a,TR,h5,'Turbine T5');

% eta_t=(h4-h5)/(h4-h5s)
h5s=h4-(h4-h5)/eta_t;
T5s=invertProperty(hprod_a,TR,h5s,'Turbine T5s');
s5sthermal=interp1(TR,sprod_a,T5s);

% S5s=S4 gives the turbine outlet pressure.
P5=P4*exp((s5sthermal-s4thermal)/Rprod);
S5s=s5sthermal-Rprod*log(P5/Pref);

s5thermal=interp1(TR,sprod_a,T5);
S5=s5thermal-Rprod*log(P5/Pref);

% Turbine checks.
hi5=zeros(1,NSp);

for i=1:NSp
    hi5(i)=HNasa(T5,SpS(i));
end

turbineInversionError=Yprod*hi5'-h5;
shaftResidual=mprod*(h4-h5)-Wcomp;
turbineEntropyResidual=S5s-S4;

assert(P5<P4 && T5<T4,'Turbine: pressure and temperature must decrease.');
assert(T5>=T5s-1e-6,'Turbine: actual T5 below ideal T5s.');
assert(S5>=S4-1e-6,'Turbine: entropy decreases.');
assert(abs(turbineInversionError)<1,'Turbine h -> T inversion error above 1 J/kg.');
assert(abs(shaftResidual)<1e-6*Wcomp,'Turbine shaft balance is not closed.');
assert(abs(turbineEntropyResidual)<1e-6,'Turbine state 5s is not isentropic.');

fprintf('\n--- TURBINE 4 -> 5 ---\n');
fprintf('eta_t = %.3f\n',eta_t);
fprintf('T4 = %.2f K   T5s = %.2f K   T5 = %.2f K\n',T4,T5s,T5);
fprintf('P4 = %.2f kPa   P5 = %.2f kPa\n',P4/kPa,P5/kPa);
fprintf('Turbine power = %.3f MW\n',Wturb/1e6);

%% Nozzle 5 -> 6
% Nozzle expands the products to ambient pressure.
P6=Pamb;
assert(P5>P6,'Nozzle: P5 must be above ambient pressure.');

% Ideal nozzle state: S6s=S5.
s6sthermal=s5thermal+Rprod*log(P6/P5);
T6s=invertProperty(sprod_a,TR,s6sthermal,'Nozzle T6s');
h6s=interp1(TR,hprod_a,T6s);
S6s=s6sthermal-Rprod*log(P6/Pref);

% eta_n=(h5-h6)/(h5-h6s)
h6=h5-eta_n*(h5-h6s);
T6=invertProperty(hprod_a,TR,h6,'Nozzle T6');
s6thermal=interp1(TR,sprod_a,T6);
S6=s6thermal-Rprod*log(P6/Pref);

% h5+v5^2/2=h6+v6^2/2
v6s=sqrt(v5^2+2*(h5-h6s));
v6=sqrt(v5^2+2*(h5-h6));

nozzleEnergyResidual=(h5+v5^2/2)-(h6+v6^2/2);
nozzleEntropyResidual=S6s-S5;

assert(T6<T5 && h6<h5,'Nozzle: temperature and enthalpy must decrease.');
assert(v6>v5,'Nozzle: flow does not accelerate.');
assert(v6<=v6s+1e-6,'Nozzle: actual velocity exceeds ideal velocity.');
assert(S6>=S5-1e-6,'Nozzle: entropy decreases.');
assert(abs(nozzleEnergyResidual)<1e-6,'Nozzle energy balance is not closed.');
assert(abs(nozzleEntropyResidual)<1e-6,'Nozzle state 6s is not isentropic.');

fprintf('\n--- NOZZLE 5 -> 6 ---\n');
fprintf('eta_n = %.3f\n',eta_n);
fprintf('T5 = %.2f K   T6s = %.2f K   T6 = %.2f K\n',T5,T6s,T6);
fprintf('P5 = %.2f kPa   P6 = %.2f kPa\n',P5/kPa,P6/kPa);
fprintf('v6 = %.2f m/s\n',v6);

%% Part 3 summary
fprintf('\n============================================================\n');
fprintf('PART 3 SUMMARY\n');
fprintf('============================================================\n');
fprintf('State |   P [kPa] |    T [K] | v [m/s] | h [kJ/kg] | S [kJ/(kg K)]\n');
fprintf('  4   | %9.2f | %8.2f | %7.2f | %9.2f | %8.4f\n',...
    P4/kPa,T4,v4,h4/kJ,S4/kJ);
fprintf('  5   | %9.2f | %8.2f | %7.2f | %9.2f | %8.4f\n',...
    P5/kPa,T5,v5,h5/kJ,S5/kJ);
fprintf('  6   | %9.2f | %8.2f | %7.2f | %9.2f | %8.4f\n',...
    P6/kPa,T6,v6,h6/kJ,S6/kJ);
fprintf('Turbine power = %.3f MW (= compressor power %.3f MW)\n',...
    Wturb/1e6,Wcomp/1e6);

%% Part 4 - independent validation
% Re-evaluate NASA functions at every solved state instead of checking
% equations only with quantities generated by the same interpolation.
v3=0;

Tstate=[T1 T2 T3 T4 T5 T6];
Pstate=[P1 P2 P3 P4 P5 P6];
Vstate=[v1 v2 v3 v4 v5 v6];
Htarget=[h1 h2 h3 h4 h5 h6];
Smodel=[S1 S2 S3 S4 S5 S6];
Mflow=[mair mair mair mprod mprod mprod];

Ystate=[repmat(Yair,3,1);repmat(Yprod,3,1)];
Xstate=[repmat(Xair,3,1);repmat(Xprod,3,1)];
Rstate=[Rg Rg Rg Rprod Rprod Rprod];

assert(all(isfinite([Tstate Pstate Vstate Htarget Smodel])),...
    'Part 4: state properties must be finite.');
assert(all(Tstate>=min(TR) & Tstate<=max(TR)) && all(Pstate>0),...
    'Part 4: state outside property range.');

%% Direct NASA evaluation of states 1-6
Hdirect=zeros(1,6);
STdirect=zeros(1,6);
Cpdirect=zeros(1,6);
Smix=zeros(1,6);

for j=1:6
    hi=zeros(1,NSp);
    si=zeros(1,NSp);
    cpi=zeros(1,NSp);

    for i=1:NSp
        hi(i)=HNasa(Tstate(j),SpS(i));
        si(i)=SNasa(Tstate(j),SpS(i));
        cpi(i)=CpNasa(Tstate(j),SpS(i));
    end

    Hdirect(j)=Ystate(j,:)*hi';
    STdirect(j)=Ystate(j,:)*si';
    Cpdirect(j)=Ystate(j,:)*cpi';

    % Mixing entropy uses species partial pressures Xi*P.
    present=Xstate(j,:)>0;
    mixing=-sum(Ystate(j,present).*(Runiv./Mi(present)).*log(Xstate(j,present)));

    Smix(j)=STdirect(j)-Rstate(j)*log(Pstate(j)/Pref)+mixing;
end

Sdirect=STdirect-Rstate.*log(Pstate/Pref);

%% Independent evaluation of ideal states 3s, 5s and 6s
Tideal=[T3s T5s T6s];
Pideal=[P3 P5 P6];
Yideal=[Yair;Yprod;Yprod];
Rideal=[Rg Rprod Rprod];

SidealDirect=zeros(1,3);
HidealDirect=zeros(1,3);

for j=1:3
    si=zeros(1,NSp);
    hi=zeros(1,NSp);

    for i=1:NSp
        si(i)=SNasa(Tideal(j),SpS(i));
        hi(i)=HNasa(Tideal(j),SpS(i));
    end

    SidealDirect(j)=Yideal(j,:)*si'-Rideal(j)*log(Pideal(j)/Pref);
    HidealDirect(j)=Yideal(j,:)*hi';
end

%% Validation residuals
% Residual is preallocated to avoid row/column concatenation errors.
hTol=1;
sTol=0.01;

Check=["Diffuser energy";"Compressor power";"Combustor energy";...
       "Turbine power";"Shaft power";"Nozzle energy";"Whole engine energy";...
       "Combustion mass";"Element H";"Element O";"Element C";"Element N";...
       "Air X sum";"Air Y sum";"Product X sum";"Product Y sum";...
       "Max h inversion";"Diffuser isentropy";"Compressor reference isentropy";...
       "Turbine reference isentropy";"Nozzle reference isentropy"];

Residual=zeros(21,1);
Residual(1)=Hdirect(1)+v1^2/2-Hdirect(2)-v2^2/2;
Residual(2)=mair*(Hdirect(3)-Hdirect(2))-Wcomp;
Residual(3)=mair*Hdirect(3)+mfurate*hfuel-mprod*Hdirect(4);
Residual(4)=mprod*(Hdirect(4)-Hdirect(5))-Wturb;
Residual(5)=mprod*(Hdirect(4)-Hdirect(5))-mair*(Hdirect(3)-Hdirect(2));
Residual(6)=Hdirect(5)+v5^2/2-Hdirect(6)-v6^2/2;
Residual(7)=mair*(Hdirect(1)+v1^2/2)+mfurate*hfuel-mprod*(Hdirect(6)+v6^2/2);
Residual(8)=sum(mdot_prod)-mair-mfurate;
Residual(9:12)=elementsOut(:)-elementsIn(:);
Residual(13)=sum(Xair)-1;
Residual(14)=sum(Yair)-1;
Residual(15)=sum(Xprod)-1;
Residual(16)=sum(Yprod)-1;
Residual(17)=max(abs(Hdirect-Htarget));
Residual(18)=Sdirect(2)-Sdirect(1);
Residual(19)=SidealDirect(1)-Sdirect(2);
Residual(20)=SidealDirect(2)-Sdirect(4);
Residual(21)=SidealDirect(3)-Sdirect(5);

Tolerance=zeros(21,1);
Tolerance(1)=2*hTol;
Tolerance(2)=2*mair*hTol;
Tolerance(3)=(mair+mprod)*hTol;
Tolerance(4)=2*mprod*hTol;
Tolerance(5)=2*(mair+mprod)*hTol;
Tolerance(6)=2*hTol;
Tolerance(7)=(mair+mprod)*hTol;
Tolerance(8)=1e-9*mprod;
Tolerance(9:12)=1e-9*max(abs(elementsIn(:)),1);
Tolerance(13:16)=1e-10;
Tolerance(17)=hTol;
Tolerance(18:21)=sTol;

Unit=["J/kg";"W";"W";"W";"W";"J/kg";"W";"kg/s";...
      "mol atoms/s";"mol atoms/s";"mol atoms/s";"mol atoms/s";...
      "-";"-";"-";"-";"J/kg";...
      "J/(kg K)";"J/(kg K)";"J/(kg K)";"J/(kg K)"];

assert(numel(Check)==21 && numel(Residual)==21 &&...
    numel(Tolerance)==21 && numel(Unit)==21,...
    'Part 4: validation arrays have inconsistent lengths.');

Passed=isfinite(Residual) & abs(Residual)<=Tolerance;
ToleranceFraction=abs(Residual)./Tolerance;

validationTable=table(Check,Residual,Tolerance,Unit,ToleranceFraction,Passed);

writetable(validationTable,fullfile(resultsDir,'validation.csv'));
disp(validationTable);

if ~all(Passed)
    failedChecks=char(strjoin(Check(~Passed),', '));
    error('Part 4 failed: %s. Inspect results/validation.csv.',failedChecks);
end

%% Component efficiency check
% Reconstruct efficiencies from independently evaluated NASA enthalpies.
Component=["Compressor";"Turbine";"Nozzle"];
EtaSpecified=[eta_c;eta_t;eta_n];

EtaReconstructed=[...
    (HidealDirect(1)-Hdirect(2))/(Hdirect(3)-Hdirect(2));...
    (Hdirect(4)-Hdirect(5))/(Hdirect(4)-HidealDirect(2));...
    (Hdirect(5)-Hdirect(6))/(Hdirect(5)-HidealDirect(3))];

ActualOutlet_K=[T3;T5;T6];
IdealOutlet_K=Tideal';
DeltaS_J_kgK=[Sdirect(3)-Sdirect(2);...
               Sdirect(5)-Sdirect(4);...
               Sdirect(6)-Sdirect(5)];

componentTable=table(Component,EtaSpecified,EtaReconstructed,...
    ActualOutlet_K,IdealOutlet_K,DeltaS_J_kgK);

assert(all(abs(EtaReconstructed-EtaSpecified)<1e-4),...
    'Reconstructed efficiencies disagree with the specified efficiencies.');

%% Physical checks
assert(all(Yprod>=0) && all(Xprod>=0),'Negative product fraction.');
assert(T2>T1 && T3>T2 && T4>T3 && T5<T4 && T6<T5,...
    'Unexpected temperature trend.');
assert(P2>P1 && P3>P2 && P4==P3 && P5<P4 && P5>P6 && P6==Pamb,...
    'Unexpected pressure trend.');
assert(T3>=T3s-1e-6 && T5>=T5s-1e-6 && T6>=T6s-1e-6 && v6<=v6s+1e-6,...
    'Inconsistent efficiency trend.');
assert(all([Sdirect(3)-Sdirect(2),Sdirect(5)-Sdirect(4),...
    Sdirect(6)-Sdirect(5)]>=-sTol),...
    'Entropy decreases in an adiabatic component.');

%% Final state and composition tables
State=(1:6)';
Location=["Inlet";"Diffuser outlet";"Compressor outlet";...
          "Combustor outlet";"Turbine outlet";"Nozzle exit"];
Mixture=[repmat("Air",3,1);repmat("Products",3,1)];

stateTable=table(State,Location,Mixture,Tstate',Pstate'/kPa,Vstate',...
    Hdirect'/kJ,Smix'/kJ,Smodel'/kJ,Mflow',...
    'VariableNames',{'State','Location','Mixture','T_K','P_kPa','v_m_s',...
    'h_kJ_kg','s_mix_kJ_kgK','s_model_kJ_kgK','mdot_kg_s'});

compositionTable=table(string({SpS.Name})',Mi',Xair',Yair',Xprod',Yprod',mdot_prod',...
    'VariableNames',{'Species','M_kg_mol','Xair','Yair','Xprod','Yprod',...
    'mdot_products_kg_s'});

%% Nozzle exit Mach number
% Local frozen-composition cp and gamma are used only for this diagnostic.
assert(all(Cpdirect>Rstate),'Invalid heat capacity for sound-speed calculation.');

gamma6=Cpdirect(6)/(Cpdirect(6)-Rprod);
Mach6=v6/sqrt(gamma6*Rprod*T6);

%% Assumptions table
Setting=["eta_c";"eta_t";"eta_n";"Tfuel_K";"shaft_efficiency";"v2_v3_v4_v5_m_s"];

Value=[eta_c;eta_t;eta_n;Tfuel;1;0];

Note=["Ideal compressor";"Ideal turbine";"Ideal nozzle";...
      "H2 gas at the reference temperature";"Lossless shaft";...
      "Kinetic energy inside the engine neglected"];

assumptionsTable=table(Setting,Value,Note);

%% Final results
fprintf('\n================ PART 4: CHECKED FINAL RESULTS ================\n');

disp(stateTable);
disp(compositionTable);

fprintf('Air / fuel / products: %.4f / %.4f / %.4f kg/s\n',...
    mair,mfurate,mprod);

fprintf('Compressor / turbine: %.6f / %.6f MW\n',...
    Wcomp/1e6,Wturb/1e6);

fprintf('Exhaust velocity: %.6f m/s\n',v6);
fprintf('Exit Mach number: %.4f\n',Mach6);

fprintf('Independent checks: %d/%d passed\n',...
    sum(Passed),numel(Passed));

[worstFraction,worstIndex]=max(ToleranceFraction);

fprintf('Largest tolerance fraction: %.4f (%s); limit=1\n',...
    worstFraction,char(Check(worstIndex)));

disp(componentTable);
disp(assumptionsTable);

%% Export results
writetable(stateTable,fullfile(resultsDir,'state_table.csv'));
writetable(compositionTable,fullfile(resultsDir,'composition.csv'));
writetable(componentTable,fullfile(resultsDir,'component_comparison.csv'));
writetable(assumptionsTable,fullfile(resultsDir,'assumptions.csv'));

save(fullfile(resultsDir,'Group10_results.mat'),...
    'stateTable','compositionTable','validationTable','componentTable',...
    'assumptionsTable','Wcomp','Wturb','v6','Mach6','phi',...
    'Yreac','Xreac','Rreac','Yprod','Xprod','Rprod');

%% Write short text summary
summaryPath=fullfile(resultsDir,'results_summary.txt');
fid=fopen(summaryPath,'w');

assert(fid>=0,'Could not open results summary.');

fprintf(fid,'GROUP 10 - VALIDATED RESULTS\n');
fprintf(fid,'Model: ideal cycle (all component efficiencies 1)\n\n');
fprintf(fid,'Exhaust velocity: %.6f m/s\n',v6);
fprintf(fid,'Exit Mach: %.6f\n',Mach6);
fprintf(fid,'Combustor outlet: %.6f K\n',T4);
fprintf(fid,'Compressor/turbine power: %.6f / %.6f MW\n',Wcomp/1e6,Wturb/1e6);
fprintf(fid,'Air/fuel/products: %.4f / %.4f / %.4f kg/s\n',mair,mfurate,mprod);
fprintf(fid,'AF: %.4f\n',AF);
fprintf(fid,'Stoichiometric AF: %.4f\n',AF_st);
fprintf(fid,'Equivalence ratio: %.6f\n',phi);
fprintf(fid,'Checks: %d/%d passed\n',sum(Passed),numel(Passed));

fclose(fid);

%% Overview figure
fig=figure('Visible','off','Color','white','Position',[100 100 1100 700]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile;
plot(State,Tstate,'o-','LineWidth',1.8);grid on;
xlabel('State');ylabel('Temperature [K]');title('Temperature');

nexttile;
plot(State,Pstate/kPa,'o-','LineWidth',1.8);grid on;
xlabel('State');ylabel('Pressure [kPa]');title('Pressure');

nexttile;
plot(State,Vstate,'o-','LineWidth',1.8);grid on;
xlabel('State');ylabel('Velocity [m/s]');title('Velocity');

nexttile;
bar(categorical(string({SpS.Name})),Yprod);grid on;
ylabel('Product mass fraction [-]');title('Combustion products');

sgtitle('Group 10 - ideal cycle');

exportgraphics(fig,fullfile(resultsDir,'cycle_overview.png'),'Resolution',160);
close(fig);

%% Machine-readable model summary
modelSummary=struct('run_id',runId,'status','PASS',...
    'eta_c',eta_c,'eta_t',eta_t,'eta_n',eta_n,...
    'Tfuel',Tfuel,...
    'Tamb',Tamb,'Pamb',Pamb,'P3overP2',P3overP2,...
    'AF',AF,'AF_st',AF_st,'phi',phi,...
    'mair',mair,'mfuel',mfurate,'mprod',mprod,...
    'Rreac',Rreac,'Rprod',Rprod,...
    'v1',v1,'v6',v6,'T4',T4,'T3s',T3s,...
    'Wcomp',Wcomp,'Wturb',Wturb,'Mach6',Mach6);

writeJson(fullfile(resultsDir,'model_summary.json'),modelSummary);
writeJson(fullfile(resultsDir,'run_status.json'),...
    struct('run_id',runId,'status','PASS'));

%% Local functions

function T=invertProperty(propertyCurve,temperatureGrid,target,label)
% Invert a monotonic NASA property curve using linear interpolation.
propertyCurve=propertyCurve(:);
temperatureGrid=temperatureGrid(:);

assert(numel(propertyCurve)==numel(temperatureGrid),...
    '%s: property and temperature arrays have different lengths.',label);

assert(isreal(target) && isscalar(target) && isfinite(target),...
    '%s: target property is invalid.',label);

assert(all(isfinite(propertyCurve)) && all(diff(propertyCurve)>0),...
    '%s: property curve must be finite and increasing.',label);

assert(target>=propertyCurve(1) && target<=propertyCurve(end),...
    '%s: solution is outside %.0f-%.0f K.',...
    label,temperatureGrid(1),temperatureGrid(end));

T=interp1(propertyCurve,temperatureGrid,target,'linear');
end

function writeJson(path,value)
fid=fopen(path,'w');
assert(fid>=0,'Cannot write %s.',path);

cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(value));
end