from pathlib import Path
import csv, json
from datetime import datetime
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image, Preformatted
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from xml.sax.saxutils import escape

root=Path(__file__).resolve().parents[1]; out=root/'reports'; out.mkdir(exist_ok=True)
def read(name):
    with (root/'results'/name).open(newline='') as f: return list(csv.DictReader(f))
status=json.loads((root/'results/run_status.json').read_text())
if status['status'] != 'PASS':
    raise SystemExit('Latest model run is incomplete. Fix it and rerun verify_group10 before building a report.')
m=json.loads((root/'results/model_summary.json').read_text())
if m['run_id'] != status['run_id'] or m['status'] != 'PASS':
    raise SystemExit('Result summaries are from different runs. Rerun verify_group10.')
states=read('state_table.csv'); residuals=read('validation.csv'); comp=read('composition.csv')
if not all(r['Passed'].lower() in ('1','true') for r in residuals):
    raise SystemExit('Validation includes failed checks. Report not generated.')
checks={r['Check']:r for r in residuals}
run_date=datetime.strptime(m['run_id'][:8],'%Y%m%d').strftime('%d %B %Y')
verification=None
vp=root/'results/verification_summary.json'
if vp.exists():
    candidate=json.loads(vp.read_text())
    if candidate.get('run_id') == m['run_id'] and candidate.get('status') == 'PASS':
        verification=candidate

styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='TitleCustom',fontName='Helvetica-Bold',fontSize=25,leading=29,textColor=colors.HexColor('#16364a'),spaceAfter=12))
styles.add(ParagraphStyle(name='BodyCustom',fontName='Helvetica',fontSize=10,leading=14,spaceAfter=8))
styles.add(ParagraphStyle(name='SmallCustom',fontName='Helvetica',fontSize=8,leading=11,spaceAfter=5))
styles.add(ParagraphStyle(name='HCustom',fontName='Helvetica-Bold',fontSize=13,leading=17,textColor=colors.HexColor('#176d80'),spaceBefore=10,spaceAfter=7))
styles.add(ParagraphStyle(name='CodeCustom',fontName='Courier',fontSize=8.5,leading=12,spaceAfter=9,backColor=colors.HexColor('#eef3f5'),borderPadding=7))
story=[]
def p(t,style='BodyCustom'): story.append(Paragraph(t,styles[style]))
def h(t): p(t,'HCustom')
def code(t): story.append(Preformatted(t,styles['CodeCustom']))
def table(data,widths,fs=8.4):
    rows=[[Paragraph(escape(str(c)),ParagraphStyle(name='cell',fontName='Helvetica-Bold' if i==0 else 'Helvetica',fontSize=fs,leading=fs+3,textColor=colors.white if i==0 else colors.HexColor('#1d2933'))) for c in row] for i,row in enumerate(data)]
    t=Table(rows,colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#16364a')),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#f0f5f6'),colors.white]),('VALIGN',(0,0),(-1,-1),'TOP'),('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),5)]))
    story.append(t);story.append(Spacer(1,8))
def page(title): story.append(PageBreak());p(title,'TitleCustom')
def footer(c,doc):
    c.setFont('Helvetica',8);c.setFillColor(colors.HexColor('#5b6c77'))
    c.drawString(42,27,f'4EB00 | Group 10 | Provisional settings | {run_date}')
    c.drawRightString(A4[0]-42,27,str(doc.page))

p('Jet engine cycle analysis','TitleCustom')
p('Group 10 - integrated model and validation','HCustom')
p(f"The NASA-property model predicts an exhaust speed of <b>{m['v6']:.2f} m/s</b>, a combustor outlet temperature of <b>{m['T4']:.2f} K</b>, and matched compressor/turbine power of <b>{m['Wcomp']/1e6:.3f} MW</b>. All {len(residuals)} independent numerical residual checks pass.")
h('Inputs and provisional settings')
table([['Group input','Value','Model setting','Value'],
    ['Fuel','H2','eta_c / eta_t / eta_n',f"{m['eta_c']:g} / {m['eta_t']:g} / {m['eta_n']:g}"],
    ['Ambient T / P',f"{m['Tamb']:g} K / {m['Pamb']/1000:g} kPa",'Fuel temperature',f"{m['Tfuel']:g} K"],
    ['Flight speed',f"{m['v1']:g} m/s",'P4 / P3',f"{m['P4overP3']:g}"],
    ['Compressor ratio',f"{m['P3overP2']:g}",'Combustor heat loss',f"{m['Qloss']:g} W"],
    ['Fuel flow / AF',f"{m['mfuel']:g} kg/s / {m['AF']:g}",'Shaft','Lossless']], [110,140,150,111])
p('<b>Settings reminder:</b> the efficiencies, fuel inlet temperature and loss assumptions are provisional model inputs, not confirmed against the current course settings. They are centralized in the code and exported in provisional_assumptions.csv.')
p('The model is steady and adiabatic by default, with negligible potential-energy changes and negligible internal kinetic energy at states 2-5. Air is 21% O2 and 79% N2 by mole. Hydrogen burns completely; downstream composition is frozen. The nozzle exit pressure is prescribed as ambient.')
h('Complete state results')
data=[['State','T [K]','P [kPa]','v [m/s]','h [kJ/kg]','s_mix [kJ/kg K]']]
for r in states:data.append([r['State']]+[f"{float(r[k]):.2f}" for k in ['T_K','P_kPa','v_m_s','h_kJ_kg']]+[f"{float(r['s_mix_kJ_kgK']):.5f}"])
table(data,[40,83,92,90,100,106])
p('States: 1 inlet; 2 diffuser outlet; 3 compressor outlet; 4 combustor outlet; 5 turbine outlet; 6 nozzle exit. States 1-3 use air properties; states 4-6 use product properties. Enthalpy and mixture entropy above are evaluated directly from NASA polynomials at the solved temperatures.','SmallCustom')
p(f"Air flow = <b>{m['mair']:.4f} kg/s</b>; fuel flow = <b>{m['mfuel']:.4f} kg/s</b>; product flow = <b>{m['mprod']:.4f} kg/s</b>. Internal zero velocities represent neglected kinetic-energy terms, not zero mass flow.",'SmallCustom')

page('Thermodynamic method')
p('NASA species enthalpies include formation enthalpies. Mixture properties are mass-weighted: h(T)=sum(Y_i h_i(T)); s_T(T)=sum(Y_i SNasa_i(T)); R_mix=R_u/M_mix. The main script inverts property curves on a 200-3000 K grid with 1 K spacing. No constant-cp Poisson relation is used. [1-3]')
h('Diffuser and compressor - Part 1')
code('h2 = h1 + v1^2/2                     (v2 = 0)\nP2 = P1 exp[(s_T,2 - s_T,1)/R_air]\ns_T,3s = s_T,2 + R_air ln(P3/P2)\nh3 = h2 + (h3s - h2)/eta_c\nWcomp = m_air (h3 - h2)')
p(f"The diffuser converts flight kinetic energy into enthalpy and satisfies s2=s1. Invert h_air(T2)=h2 to find T2. For the compressor, entropy gives T3s at the prescribed pressure ratio; efficiency gives actual h3, then inversion gives T3. Here T3={float(states[2]['T_K']):.2f} K and T3s={m['T3s']:.2f} K.")
h('Combustion and combustor - Part 2')
code('H2 + 0.5 O2 -> H2O\nn_products = n_in + [-1 -0.5 0 1 0] n_H2,in\nh4 = (m_air h3 + m_fuel h_fuel - Qloss)/m_products\nh_products(T4) = h4;              P4 = (P4/P3) P3')
p(f"Species order is [H2, O2, CO2, H2O, N2]. Mass flows are converted to molar flows with database molecular masses; product mass and mole fractions follow from the reacted flows. The equivalence ratio is {m['phi']:.4f}, leaving excess oxygen. Adding an LHV term would double-count chemical energy. This is an open-flow enthalpy balance, unlike the closed-vessel internal-energy exercise in Lecture 1. [2,4]")
h('Turbine and nozzle - Part 3')
code('h5 = h4 - Wcomp/m_products\nh5s = h4 - (h4 - h5)/eta_t\nP5 = P4 exp[(s_T,5s - s_T,4)/R_products]\ns_T,6s = s_T,5 + R_products ln(Pamb/P5)\nh6 = h5 - eta_n (h5 - h6s)\nv6 = sqrt[2(h5 - h6)]                (v5 = 0)')
p('The turbine supplies exactly the compressor power through a lossless shaft. Its mass flow includes added fuel. Inversions yield T5, T5s and T6s; turbine pressure follows from s5s=s4. The nozzle converts the remaining enthalpy drop into kinetic energy while expanding to ambient. Enthalpies inside the velocity formula are in J/kg. [3,5]')

page('Independent validation - Part 4')
p('Each solved state is re-evaluated directly with HNasa and SNasa. This checks the temperature inversions rather than only substituting an enthalpy target back into its defining equation. The table reports signed residuals; PASS requires absolute residual no greater than the tolerance.')
data=[['Check','Residual','Tolerance','Unit']]
for r in residuals: data.append([r['Check'],f"{float(r['Residual']):.4g}",f"{float(r['Tolerance']):.4g}",r['Unit']])
table(data,[230,88,88,105],7.8)
p(f"A 1 J/kg single-state enthalpy allowance and 0.01 J/(kg K) entropy allowance account for interpolation. Flow-energy tolerances sum allowed state errors multiplied by mass flow. The largest enthalpy inversion error is only <b>{abs(float(checks['Max h inversion']['Residual'])):.5f} J/kg</b>. The largest tolerance fraction is {max(float(r['ToleranceFraction']) for r in residuals):.5f} (limit 1). Reconstructed component efficiencies also pass. These checks assess numerical consistency, not physical model accuracy.",'SmallCustom')
p(f"The whole-engine balance is m_air(h1+v1^2/2)+m_fuel h_fuel - m_products(h6+v6^2/2)-Qloss=0. Its <b>{abs(float(checks['Whole engine energy']['Residual'])):.3f} W</b> residual is tiny compared with the energy flows. Internal compressor/turbine work cancels for the lossless shaft.",'SmallCustom')
if verification:
    p(f"<b>Separate solver:</b> verify_group10.m solves the same run using direct NASA functions and fzero. Maximum temperature disagreement is <b>{verification['max_temperature_error_K']:.6f} K</b>; exhaust-speed disagreement is <b>{verification['velocity_error_m_s']:.6f} m/s</b>. The check uses different numerical inversion; it shares the same physical assumptions and database.",'SmallCustom')
else:
    p('<b>Separate solver:</b> no verification result is available for this run. Run verify_group10 to check these settings and rebuild the report.','SmallCustom')

page('Results interpretation')
story.append(Image(str(root/'results/cycle_overview.png'),width=511,height=358))
p('Figure 1. Computed state trends and product composition. Connecting lines guide the eye; they are not spatially resolved profiles or equilibrium paths.','SmallCustom')
h('What the trends mean')
p(f"The diffuser and compressor heat the incoming air. Combustion produces the highest temperature. The turbine then extracts compressor power, and the nozzle accelerates the products. A local frozen-composition sound-speed calculation gives an exit Mach number of <b>{m['Mach6']:.4f}</b>.")
if m['Mach6'] > 1:
    p('The prescribed fully expanded solution is supersonic and assumes suitable nozzle geometry; this is not a prediction for an arbitrary converging-only nozzle.','SmallCustom')
p(f"The combustor can have h4 slightly below h3 even though T4 is much higher. Enthalpy flow is conserved while composition changes the enthalpy-temperature curve. Likewise, h6={float(states[5]['h_kJ_kg']):.2f} kJ/kg is valid: NASA formation-enthalpy reference values can be negative. The positive h5-h6 drives nozzle acceleration.")
h('Entropy and composition')
p('The original model omits the constant mixing contribution for each fixed mixture. This leaves its isentropic calculations valid. Part 4 also reports full mixture entropy using species partial pressures: s_mix=s_model-sum[Y_i(R_u/M_i)ln(X_i)], excluding zero-fraction species. Do not interpret s4-s3 alone as combustor entropy production; fuel entropy and the unequal stream mass flows must also be included.')
p('Product mass fractions [H2, O2, CO2, H2O, N2]: ['+', '.join(f"{float(r['Yprod']):.6f}" for r in comp)+']. Mole fractions: ['+', '.join(f"{float(r['Xprod']):.6f}" for r in comp)+']. Complete species flows are exported to composition.csv.','SmallCustom')

page('Integration, review and source record')
h('Assessment of the existing work')
p('<b>Part 1:</b> correct NASA-based diffuser/compressor method for the chosen baseline. The original current-folder dependency is fixed; direct property checks strengthen its validation. <b>Part 2:</b> correct hydrogen stoichiometry, mass/element accounting and formation-enthalpy energy balance. <b>Part 3:</b> correct turbine mass-flow factor, efficiency equations and nozzle energy conversion. Default efficiencies and losses remain provisional. No grade is inferred from the rubric.')
h('Part 4 implementation and reproducibility')
p('The model remains a single sequential script, with one input/settings block and script-relative database access. It collects all six stations, evaluates 21 residual checks, enforces physical trends and valid efficiencies, and exports the state, composition, validation and assumptions tables, a MAT result file and the figure. The component comparison and a plain-text results summary are also exported. Failed residual checks are saved with their names for diagnosis. The supplied NASA base functions and database remain unchanged.')
code('JetEngine_Group10       % solve, validate and export results\nverify_group10          % compare against direct NASA roots')
p('Extract the scripts package and use that folder as MATLAB Current Folder, or add it to the MATLAB path. Outputs are regenerated under results/. MATLAB R2026a was used for validation. PART4_EXPLANATION.md gives the detailed integration and checking rationale.')
h('Items to confirm before submission')
p('Confirm the default efficiencies, fuel inlet state, combustor losses, shaft model and any turbine-temperature limit against the current course files. Use the actual Canvas Word template, fill in student details and verify packaging/team requirements there. This report supplies technical content; its structure has not been checked against the unavailable template. The 2026 Lecture 2, p. 15, gives 9 October regular and 16 October late submission, with the late grade capped at 8. The 2025 handout dates are superseded by that supplied lecture.')
h('Sources inspected')
for t in [
'[1] 4EB00 Special Topic Jet Engine Info 2025.pdf, pp. 1-2: NASA/MATLAB method and deliverables; 4EB00 Special Topic Jet Engine Rubric.pdf, pp. 1-2: methodology, composition and result criteria.',
'[2] Lecture 1 Ideal Gas Mixtures 2026.pdf, pp. 9-10, 19-27, 29-34: mixture definitions, formation enthalpy, NASA functions and reacting systems.',
'[3] Lecture 2 Cycle analysis 2026.pdf, pp. 7-15: component models, entropy method, group conditions and 2026 dates.',
'[4] CollegeThermo1-2-eng-1.pdf: systems, properties, first law and enthalpy. [5] CollegeThermo3-4-eng.pdf, pp. 9-16: steady-flow energy balances and turbine/nozzle models.',
'[6] CollegeThermo5-6-eng.pdf: heat-engine cycles and efficiency context. Its constant-cp closed Brayton-cycle formula is not used for this reacting turbojet.',
'[7] Jet_Engine_Project_Working_Plan_Group10.docx, sections 3-6: four-part scope, integration and validation. The working plan defines the four-part division.',
'[8] github.com/kapnistos/Thermodynamics, commit 8bfbf18a1d044f59f87f9d72e3682f26f9f8e72a, downloaded 26 September 2026: main script, README, starter, scratch file, all General functions/database, older lectures and working plan.'
]: p(t,'SmallCustom')

doc=SimpleDocTemplate(str(out/'Group10_report_provisional.pdf'),pagesize=A4,rightMargin=42,leftMargin=42,topMargin=40,bottomMargin=45,title='Group 10 Jet Engine - Provisional Settings',author='Group 10')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
print(out/'Group10_report_provisional.pdf')
