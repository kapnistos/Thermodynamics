# Group 10 jet engine assignment

## Run

Extract the scripts ZIP and set MATLAB Current Folder to that folder. Run:

```matlab
verify_group10
```

This runs JetEngine_Group10.m, checks all 21 conservation/property residuals,
and compares the interpolation results with direct NASA root solutions.
MATLAB R2026a was used for verification. No Python or external MATLAB toolbox
is required. The supplied General/ folder must remain beside the main script.
Results are generated under results/ and are not source files.

The lecturer-confirmed component efficiencies are all 1. The expected baseline
exhaust velocity is 778.827595 m/s, combustor outlet temperature 1082.464159 K,
and matched compressor/turbine power 33.241777 MW.

## Report and submission

10_report.docx is the editable report in the supplied 2026 template.
10_report.pdf is its exported hand-in version. Cover names and student numbers
must be filled before submitting.

Canvas requires one 10.zip containing exactly:

```text
10_report.pdf
10_scripts.zip
```

The inner scripts ZIP contains the two MATLAB entry points, General/, and
run instructions. It excludes old results, drafts and lecture files.
The regular deadline shown on Canvas is 9 October 2026, 23:59.

The removed working material is preserved on codex/pre-submission-archive.
The main branch has not been changed. No Canvas submission has been made.
