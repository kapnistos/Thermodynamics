% Run after extracting the package. Uses direct NASA roots as an independent
% reference for the main script's 1 K interpolation method.
JetEngine_Group10;
hAir = @(T) sum(Yair.*arrayfun(@(sp) HNasa(T,sp),SpS));
sAir = @(T) sum(Yair.*arrayfun(@(sp) SNasa(T,sp),SpS));
hProd = @(T) sum(Yprod.*arrayfun(@(sp) HNasa(T,sp),SpS));
sProd = @(T) sum(Yprod.*arrayfun(@(sp) SNasa(T,sp),SpS));
bracket = [min(TR) max(TR)];
rh1 = hAir(Tamb);
rh2 = rh1+v1^2/2;
rT2 = fzero(@(T) hAir(T)-rh2,bracket);
rP2 = Pamb*exp((sAir(rT2)-sAir(Tamb))/Rg);
rP3 = P3overP2*rP2;
rT3s = fzero(@(T) sAir(T)-sAir(rT2)-Rg*log(P3overP2),bracket);
rh3 = rh2+(hAir(rT3s)-rh2)/eta_c;
rT3 = fzero(@(T) hAir(T)-rh3,bracket);
rh4 = (mair*rh3+mfurate*hfuel-Qloss)/mprod;
rT4 = fzero(@(T) hProd(T)-rh4,bracket);
rh5 = rh4-mair*(rh3-rh2)/mprod;
rT5 = fzero(@(T) hProd(T)-rh5,bracket);
rh5s = rh4-(rh4-rh5)/eta_t;
rT5s = fzero(@(T) hProd(T)-rh5s,bracket);
rP5 = P4overP3*rP3*exp((sProd(rT5s)-sProd(rT4))/Rprod);
rT6s = fzero(@(T) sProd(T)-sProd(rT5)-Rprod*log(Pamb/rP5),bracket);
rh6 = rh5-eta_n*(rh5-hProd(rT6s));
rT6 = fzero(@(T) hProd(T)-rh6,bracket);
rv6 = sqrt(2*(rh5-rh6));
Root_T_K = [Tamb rT2 rT3 rT4 rT5 rT6]';
Interpolation_T_K = Tstate';
Difference_K = Interpolation_T_K-Root_T_K;
referenceTable = table((1:6)',Interpolation_T_K,Root_T_K,Difference_K, ...
    'VariableNames',{'State','Interpolation_T_K','Root_T_K','Difference_K'});
assert(max(abs(Difference_K))<0.01,'Interpolation vs direct-root T error > 0.01 K.');
assert(abs(v6-rv6)<0.01,'Interpolation vs direct-root exhaust error > 0.01 m/s.');
assert(max(abs([P2 P3 P5]-[rP2 rP3 rP5]))<10,'Pressure difference > 10 Pa.');
disp(referenceTable);
fprintf('Direct-root reference v6 = %.9f m/s; difference = %.9f m/s\n',rv6,v6-rv6);
fprintf('Independent direct-root reference: PASS\n');
writetable(referenceTable,fullfile(resultsDir,'direct_root_comparison.csv'));
verificationSummary = struct('run_id',runId,'status','PASS', ...
    'max_temperature_error_K',max(abs(Difference_K)), ...
    'velocity_error_m_s',abs(v6-rv6), ...
    'max_pressure_error_Pa',max(abs([P2 P3 P5]-[rP2 rP3 rP5])));
fid = fopen(fullfile(resultsDir,'verification_summary.json'),'w');
assert(fid>=0,'Cannot save the direct-root verification summary.');
fprintf(fid,'%s\n',jsonencode(verificationSummary));
fclose(fid);
