# Pearson Correlation Analysis Tool

MATLAB tool to compute Pearson correlations and linear regressions between two sets of variables (X and Y) read from an Excel workbook, and to automatically generate:

- A results table (correlations, regressions, p-values)
- A settings sheet documenting exactly how the analysis was configured
- One Excel sheet per correlation with |r| > 0.6, containing the raw data used (optionally split by a grouping variable, for easy plotting)
- A correlation heatmap (.jpg), with cells annotated when |r| > 0.6 (and marked with `*` if p < 0.05)

---

## 1. Repository structure

```
your-project-folder/
│
├── CorrelationAnalysis.m        <- main script (run this one)
│
└── utils/
    ├── selectData.m
    ├── checkAnimalOrder.m
    ├── runCorrelations.m
    ├── saveCorrelationResults.m
    ├── saveSignificantCorrelationSheets.m
    └── plotCorrelationHeatmap.m
```

`CorrelationAnalysis.m` automatically adds the `utils` folder to the MATLAB path at the start of the script (based on its own location), so **you do not need to manually add anything to the path** — just keep this folder structure intact.

> **Note:** the repository may also include a `filterExperiments.m` file. This is a helper function that is **not currently used** by `CorrelationAnalysis.m` — filtering by experiment/group is done through the grouping-variable questions described below instead. You can ignore it.

---

## 2. Requirements

- MATLAB (tested on R2021b or later; needs `datetime` with custom format strings, `exportgraphics`, and `matlab.lang.makeValidName`)
- **Statistics and Machine Learning Toolbox** (required for `corr` and `fitlm`, used in `runCorrelations.m`)
- Your data in an Excel file (`.xlsx` or `.xls`)

---

## 3. How to organize your Excel file

The tool works with **one or more sheets** in the same Excel workbook. X and Y variables can come from the same sheet or from different sheets — you will be asked to pick a sheet separately for each.

Each sheet you intend to use must follow this structure:

| Column type | Requirement |
|---|---|
| **Animal ID column** | One column with a unique identifier per animal/subject. Any column name is fine — you'll be asked to pick it. |
| **Grouping column(s)** *(optional)* | Any column you want to be able to filter or split by (e.g. `Sex`, `Experiment`, `Pilo`, `Group(s)`). You can have as many as you like — you'll choose which one to use, if any, each time it's relevant. |
| **Variable columns** | One column per numeric variable you want to correlate (e.g. brain region values, ECG parameters, heart rate, QTc, etc.). Must be numeric. Missing values can be left blank (they will show up as `NaN` and are excluded pairwise from each specific correlation). |

Example layout (based on a typical dataset used with this tool):

| ID | Sex | Experiment | Pilo | Group(s) | Schiffer_mask | Accumbens_l | ... |
|---|---|---|---|---|---|---|---|
| JBR418 | F | PiloSERT | PiloSE | A | 0.6885 | 1.0344 | ... |
| PSP24  | F | PSP      | CTRL   | 7d | 1.0434 | 1.2957 | ... |

**Important:**
- **X and Y must contain the same animals, in the same order**, once any filtering (by grouping variable) has been applied. The script checks this automatically and will stop with an error if the IDs don't match — see step 4 below.
- If X and Y come from different sheets, make sure the ID values are written identically in both (e.g. not `"JBR418"` in one sheet and `"jbr418 "` with a trailing space in the other).
- Avoid special characters (`\ / ? * [ ] :`) in variable names if possible — they get sanitized automatically for sheet names, but plain names are clearer in the output.

---

## 4. Running the analysis

Run `CorrelationAnalysis.m` from MATLAB. You will be guided through a series of dialog boxes, in this exact order:

### Step 1 — Select Excel file
A file browser opens. Select the `.xlsx`/`.xls` file containing your data.

### Step 2 — Select X variables
This repeats for X, then again for Y (Step 3), using the same questions each time:

1. **"Select sheet for X"** — pick which sheet in the workbook contains your X data.
2. **"Select the column containing the animal IDs"** — pick the ID column for that sheet.
3. **"Do you want to use a grouping variable to filter X data?"** (Yes/No)
   - **If No:** all animals in the sheet are used.
   - **If Yes:**
     - **"Select the grouping variable"** — pick the column to filter by (e.g. `Experiment`).
     - **"Select category/categories"** — pick one, several, or `<All>` from the categories found in that column (e.g. `PiloSERT`, `PSP`, `PRG`). Only animals matching your selection are kept for X.
4. **"Select X variable(s)"** — pick one or more numeric columns to use as X variables. You can select multiple; a correlation will be run for every X–Y combination.

### Step 3 — Select Y variables
Identical set of questions as Step 2, but for your Y dataset (sheet, ID column, optional grouping/filtering, and Y variable(s)).

> You can use the same sheet for both X and Y (e.g. correlating two numeric columns within one table), or different sheets/files structure as long as animal IDs match after filtering.

### Step 4 — Automatic ID check
The script automatically checks that the animals used for X and Y match exactly, in the same order. If they don't, it stops with an error and shows a table comparing both ID lists so you can see the mismatch. This usually means your grouping/category selection in Step 2 vs Step 3 filtered the two datasets differently — check that you selected the same animals on both sides.

### Step 5 — Correlations are computed
No further input needed. The script computes, for every X–Y variable pair: Pearson's r, R², p-value, number of observations (N), and the linear regression equation (slope/intercept).

### Step 6 — Save results to Excel
1. **"Enter a name for the output file"** — choose a base name (e.g. `CorrelationAnalysis`). A timestamp is appended automatically, and the file is saved as `.xlsx` inside a `CorrelationResults` subfolder (created automatically next to your original Excel file).

The output file contains two sheets:
- **Correlations** — the full results table (XVariable, YVariable, N, r, r2, p, Slope, Intercept, Equation).
- **Settings** — a record of exactly how the analysis was configured (original file, date/time, sheets used, ID/grouping columns, selected categories, selected variables for X and Y), so you can always trace back how a given result file was generated.

### Step 7 — Save detail sheets for strong correlations (|r| > 0.6)
1. **"Do you want to use a grouping variable for plotting purposes?"** (Yes/No)
   - **If No:** each strong correlation gets a sheet with 3 columns only (see layout below).
   - **If Yes:**
     - **"Select the sheet containing the grouping variable"** — from the same original Excel file.
     - **"Select the column containing the animal IDs"** (in that sheet).
     - **"Select the grouping variable"** (e.g. `Sex`).

This is asked **once** and applied to every strong correlation found. For each correlation with |r| > 0.6, a new sheet named `VariableX_&_VariableY` is added to the results Excel file, with:

| Column | Content |
|---|---|
| 1 (no header) | Animal ID |
| 2 (header = X variable name) | X values |
| 3 (header = Y variable name) | Y values |
| 4+ (header = category name, only if grouping was used) | Y values split by category — **only for categories actually present among the animals used in that specific correlation** (e.g. if a correlation only involves animals with `Sex = Female`, no `Male` column will be created) |

If fewer than 2 categories are present among the animals in a given correlation, the grouping columns are skipped for that sheet only (columns 1–3 are still saved).

### Step 8 — Heatmap
1. **"Enter a name for the heatmap file"** — choose a base name (e.g. `CorrelationHeatmap`). A timestamp is appended automatically, and the image is saved as a `.jpg` (300 dpi) in the same `CorrelationResults` folder as the Excel output.

The heatmap shows all X–Y Pearson r values on a symmetric blue–white–red scale (−1 to 1). Any cell with |r| > 0.6 is annotated with its value, and marked with a trailing `*` if that correlation is also statistically significant (p < 0.05).

---

## 5. Output summary

After a full run, inside `CorrelationResults/` (created next to your original Excel file) you will find:

```
CorrelationResults/
├── CorrelationAnalysis_20260728T143210.xlsx
│     ├── Correlations           <- full results table
│     ├── Settings                <- analysis configuration log
│     └── VariableX_&_VariableY   <- one sheet per correlation with |r| > 0.6
│
└── CorrelationHeatmap_20260728T143245.jpg
```

---

## 6. Troubleshooting

- **"The order of the X and Y variables does not match"** → your X and Y grouping/category selections filtered different animals. Re-run and make sure both selections keep the same set of animals.
- **"No sheets found in Excel file"** → check the file isn't corrupted or open in another program while MATLAB tries to read it.
- **`fitlm`/`corr` not recognized** → you need the Statistics and Machine Learning Toolbox installed.
- Cancelling any dialog box stops the script with an error message — simply re-run `CorrelationAnalysis.m` to start over.
