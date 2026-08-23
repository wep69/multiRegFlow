# Local validation protocol for `multiRegFlow`

**Package:** `multiRegFlow`  
**Current version:** 0.2.0  
**Source directory:** `D:/Walter/R/Pacotes_criados/multiRegFlow/multiRegFlow`  
**Current source tarball:** `D:/Walter/R/Pacotes_criados/multiRegFlow/multiRegFlow_0.2.0.tar.gz`  
**Current tarball SHA-256:** `781BF46FB82217BB1AB374648C3400580C0B07F317E8338B6C8C4D16254A441C`  
**Validated R version:** R 4.6.0 (2026-04-24, UCRT, Windows 11 x64)  
**Validated Pandoc version:** 3.9  
**GitHub repository:** https://github.com/wep69/multiRegFlow  
**GitHub Pages:** https://wep69.github.io/multiRegFlow/  
**Validation date:** 2026-08-23

This document records the validation completed for the 0.2.0 release. The package has been validated locally, pushed to GitHub, and published via GitHub Pages.

---

## 1. Current validation status

### 1.1 Validation completed (2026-08-23)

The following items have been executed successfully on the current 0.2.0 source tree:

1. Core package loading with `devtools::load_all()`.
2. OLS workflow with `mr_fit()`.
3. Diagnostics and influence calculations.
4. Collinearity diagnostics including VIF, tolerance and condition-index workflow.
5. Classical, HC3 and cluster-aware covariance inference.
6. AIC/BIC selection.
7. Best-subset selection.
8. Ridge, lasso and elastic net using `glmnet`.
9. Bootstrap workflows.
10. Quantile regression.
11. Robust regression.
12. GAM fitting and out-of-fold validation.
13. Kernel regression and out-of-fold validation.
14. Relative-importance calculations.
15. SHAP backend.
16. Marginal-effects backend.
17. Stability-selection backend.
18. Repeated cross-validation for OLS and flexible engines.
19. `R CMD build` with all vignettes enabled.
20. Rendering of all 13 package vignettes during build.
21. `R CMD check --as-cran` passed with 0 ERRORs, 0 WARNINGs, 1 NOTE (new submission).
22. GitHub repository created and source code pushed.
23. Cheatsheets uploaded to `cheatsheets/` folder.
24. GitHub Pages site configured and live.

### 1.2 Validation results

- **Test suite:** PASS (0 failures, 0 errors, 0 warnings)
- **R CMD check:** PASS (0 ERRORs, 0 WARNINGs, 1 NOTE)
- **GitHub Pages:** LIVE at https://wep69.github.io/multiRegFlow/
- **Final TAR SHA-256:** `781BF46FB82217BB1AB374648C3400580C0B07F317E8338B6C8C4D16254A441C`

---

## 2. Mandatory metadata correction before release

The current package intentionally contains a placeholder maintainer address:

```text
maintainer@multiregflow.invalid
```

Before CRAN submission, GitHub release, r-universe publication or public distribution, replace this with the verified maintainer e-mail in both `Authors@R` and `Maintainer` fields of `DESCRIPTION`.

After changing `DESCRIPTION`, **rebuild the tarball**. Never reuse a tarball built before the metadata correction.

Check metadata with:

```r
read.dcf("D:/Walter/R/Pacotes_criados/multiRegFlow/DESCRIPTION")
```

and:

```r
tools:::.check_package_description(
  "D:/Walter/R/Pacotes_criados/multiRegFlow/DESCRIPTION"
)
```

---

## 3. Clean Windows state before repeating `R CMD check`

### 3.1 Close processes that can lock package files

Before the final check:

1. Close RStudio projects that have `multiRegFlow` loaded.
2. Close RGui sessions using the package.
3. Close any terminal running an R process from the package directory.
4. Close HTML vignette previews if they are being served by an R process.
5. Ensure no background `R.exe`, `Rscript.exe`, `rsession.exe` or `pandoc.exe` process is still holding the check library.

In PowerShell, inspect active processes:

```powershell
Get-Process R, Rscript, rsession, pandoc -ErrorAction SilentlyContinue
```

Only terminate processes that are known to belong to this validation session. For example:

```powershell
Stop-Process -Name R,Rscript -Force -ErrorAction SilentlyContinue
```

Do not terminate unrelated R analyses without checking them first.

### 3.2 Remove stale check and lock directories

Run from a PowerShell session **after R processes have been closed**:

```powershell
$pkg = "D:\Walter\R\Pacotes_criados\multiRegFlow"

Remove-Item "$pkg\multiRegFlow.Rcheck" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$pkg\00LOCK*" -Recurse -Force -ErrorAction SilentlyContinue
```

Also inspect the user library for stale locks:

```powershell
Get-ChildItem "D:\RLibrary" -Filter "00LOCK*" -ErrorAction SilentlyContinue
```

If a stale lock belongs to `multiRegFlow` and no R process is using it, remove it:

```powershell
Remove-Item "D:\RLibrary\00LOCK-multiRegFlow" -Recurse -Force -ErrorAction SilentlyContinue
```

### 3.3 Do not run the final check inside the source directory

Use a separate check root, for example:

```text
D:\Walter\R\Pacotes_criados\_checks\multiRegFlow
```

Create it:

```powershell
$checkRoot = "D:\Walter\R\Pacotes_criados\_checks\multiRegFlow"
New-Item -ItemType Directory -Force -Path $checkRoot | Out-Null
```

This avoids source-tree contamination and reduces the risk of recursive file locks.

---

## 4. Verify required and optional backends

Start a fresh R 4.6.0 session and run:

```r
pkgs <- c(
  "knitr", "rmarkdown", "testthat", "ggplot2",
  "glmnet", "quantreg", "robustbase", "sandwich",
  "performance", "leaps", "stabs", "relaimpo",
  "kernelshap", "shapviz", "marginaleffects",
  "mgcv", "np", "olsrr", "mctest"
)

status <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
print(status)

if (!all(status)) {
  stop(
    "Missing optional validation packages: ",
    paste(names(status)[!status], collapse = ", ")
  )
}
```

Record versions:

```r
versions <- data.frame(
  package = pkgs,
  version = vapply(pkgs, function(p) as.character(packageVersion(p)), character(1))
)

write.csv(
  versions,
  "D:/Walter/R/Pacotes_criados/multiRegFlow/validation/package_versions.csv",
  row.names = FALSE
)
```

Record the full R session:

```r
dir.create(
  "D:/Walter/R/Pacotes_criados/multiRegFlow/validation",
  recursive = TRUE,
  showWarnings = FALSE
)

capture.output(
  sessionInfo(),
  file = "D:/Walter/R/Pacotes_criados/multiRegFlow/validation/sessionInfo.txt"
)
```

---

## 5. Run the test suite directly before building

From R:

```r
setwd("D:/Walter/R/Pacotes_criados/multiRegFlow")

testthat::test_local(
  ".",
  reporter = "summary",
  stop_on_failure = TRUE,
  stop_on_warning = FALSE
)
```

Expected result: **0 failures and 0 errors**.

The tests should cover, at minimum:

- OLS fitting and prediction;
- diagnostics and influence flags;
- VIF and condition indices;
- HC3 and cluster covariance;
- bootstrap;
- repeated CV and calibration;
- AIC/BIC/best-subset selection;
- `keep=` term preservation;
- ridge/lasso/elastic net;
- robust regression;
- quantile regression;
- GAM;
- kernel regression;
- relative importance;
- reporting and audit outputs.

---

## 6. Scientific equivalence and sanity checks

These checks are additional to unit tests.

### 6.1 OLS equivalence to `stats::lm`

```r
library(multiRegFlow)

soil <- mr_example_data("soil_fertility")

f1 <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct +
    available_P_mg_dm3 + season_rain_mm,
  soil
)

f2 <- lm(
  yield_t_ha ~ soil_pH + organic_matter_pct +
    available_P_mg_dm3 + season_rain_mm,
  data = soil
)

stopifnot(
  isTRUE(all.equal(coef(f1), coef(f2), tolerance = 1e-12)),
  isTRUE(all.equal(fitted(f1), fitted(f2), tolerance = 1e-12))
)
```

### 6.2 HC3 must change uncertainty, not point estimates

```r
classic <- mr_inference(f1, covariance = "classical")
hc3 <- mr_inference(f1, covariance = "HC3")

stopifnot(
  isTRUE(all.equal(classic$estimate, hc3$estimate, tolerance = 1e-12)),
  any(abs(classic$std_error - hc3$std_error) > 1e-10)
)
```

### 6.3 Collinearity example should trigger a meaningful signal

```r
coll <- mr_example_data("agronomy_collinear")
fc <- mr_fit(yield_t_ha ~ ., coll)
cc <- mr_collinearity(fc)

stopifnot(max(cc$VIF$VIF, na.rm = TRUE) > 5)
```

The expected purpose is not to enforce a fixed threshold, but to confirm that the deliberately collinear dataset actually exercises the collinearity workflow.

### 6.4 Penalization sanity check

```r
ridge <- mr_regularize(fc, method = "ridge", nfolds = 5, seed = 100)
lasso <- mr_regularize(fc, method = "lasso", nfolds = 5, seed = 100)
elnet <- mr_regularize(fc, method = "elastic_net", alpha = 0.5,
                       nfolds = 5, seed = 100)

stopifnot(
  ridge$lambda_1se > 0,
  lasso$lambda_1se > 0,
  elnet$lambda_1se > 0
)
```

### 6.5 Flexible-model out-of-fold validation

```r
nl <- mr_example_data("irrigation_nonlinear")

lin <- mr_fit(
  yield_t_ha ~ irrigation_mm + N_rate_kg_ha + mean_temp_C,
  nl,
  goal = "prediction"
)

gam <- mr_fit(
  yield_t_ha ~ s(irrigation_mm) + s(N_rate_kg_ha) + s(mean_temp_C),
  nl,
  engine = "gam",
  goal = "prediction"
)

ker <- mr_fit(
  yield_t_ha ~ irrigation_mm + N_rate_kg_ha + mean_temp_C,
  nl,
  engine = "kernel",
  goal = "prediction"
)

cmp <- mr_compare(
  linear = lin,
  gam = gam,
  kernel = ker,
  v = 3,
  repeats = 1,
  seed = 1
)

print(cmp$prediction)
```

All reported prediction metrics must be based on held-out predictions. Do not substitute training `R2` as a comparison criterion.

---

## 7. Execute and inspect all vignettes

The package currently contains 13 vignettes.

### 7.1 Build all vignettes from a clean source tree

```r
setwd("D:/Walter/R/Pacotes_criados/multiRegFlow")

pkgbuild::build(
  ".",
  dest_path = "D:/Walter/R/Pacotes_criados/multiRegFlow",
  vignettes = TRUE,
  manual = FALSE
)
```

Expected output must include:

```text
* creating vignettes ... OK
```

### 7.2 Visual inspection of HTML output

After installing the rebuilt tarball:

```r
browseVignettes("multiRegFlow")
```

Inspect every vignette for:

- missing figures;
- broken equations;
- clipped tables;
- code/output overflow;
- malformed UTF-8 characters;
- duplicated sections;
- incorrect function names;
- results that contradict the interpretation text;
- missing units in agronomic examples;
- impossible soil, plant or irrigation values;
- excessively long console output;
- broken internal navigation.

Record the visual inspection in:

```text
validation/VIGNETTE_VISUAL_INSPECTION.md
```

Recommended table:

```markdown
| Vignette | Rendered | Figures OK | Tables OK | Interpretation OK | Issues |
|---|---:|---:|---:|---:|---|
| v00-overview | yes | yes | yes | yes | none |
...
```

A vignette is not considered fully validated merely because `R CMD build` compiled it.

---

## 8. Build a fresh tarball after every correction

Never check an obsolete tarball.

From R:

```r
setwd("D:/Walter/R/Pacotes_criados/multiRegFlow")

built <- pkgbuild::build(
  ".",
  dest_path = "D:/Walter/R/Pacotes_criados/multiRegFlow",
  vignettes = TRUE,
  manual = FALSE
)

built
```

Then calculate and record SHA-256. In PowerShell:

```powershell
Get-FileHash `
  "D:\Walter\R\Pacotes_criados\multiRegFlow\multiRegFlow_0.2.0.tar.gz" `
  -Algorithm SHA256
```

Update the hash in `VALIDATION_STATUS.md` after the final successful build.

---

## 9. Install the tarball in a clean temporary library

A source-tree load is not sufficient.

In R:

```r
clean_lib <- "D:/Walter/R/Pacotes_criados/_checklib_multiRegFlow"

unlink(clean_lib, recursive = TRUE, force = TRUE)
dir.create(clean_lib, recursive = TRUE)

install.packages(
  "D:/Walter/R/Pacotes_criados/multiRegFlow/multiRegFlow_0.2.0.tar.gz",
  repos = NULL,
  type = "source",
  lib = clean_lib
)

library(multiRegFlow, lib.loc = clean_lib)
packageVersion("multiRegFlow")
mr_capabilities()
```

Run a smoke analysis from the installed package:

```r
soil <- mr_example_data("soil_fertility")
fit <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3,
  soil
)

mr_diagnose(fit)
mr_collinearity(fit)
mr_inference(fit, "HC3")
mr_importance(fit, "partial_r2")
```

Then unload and remove the temporary library if desired.

---

## 10. Repeat `R CMD check` outside the source directory

### 10.1 Recommended PowerShell procedure

First create a dedicated check directory:

```powershell
$R = "C:\Program Files\R\R-4.6.0\bin\R.exe"
$tar = "D:\Walter\R\Pacotes_criados\multiRegFlow\multiRegFlow_0.2.0.tar.gz"
$checkRoot = "D:\Walter\R\Pacotes_criados\_checks\multiRegFlow"

Remove-Item $checkRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $checkRoot | Out-Null
Set-Location $checkRoot

& $R CMD check --as-cran --no-manual $tar
```

Use `--no-manual` only while testing if a complete LaTeX toolchain is not available. For the strict final release gate, if LaTeX is installed, repeat without `--no-manual`:

```powershell
& $R CMD check --as-cran $tar
```

### 10.2 Expected final status

The target is:

```text
Status: OK
```

For an internal release candidate, the minimum acceptable target is:

```text
0 ERRORs
0 WARNINGs
```

Every NOTE must be individually understood and recorded. Do not dismiss a NOTE solely because it is called a NOTE.

### 10.3 If Windows reports `Acesso negado` again

If the check again fails while moving staged installation:

1. Confirm that no R/RStudio process has the package loaded.
2. Delete the complete `.Rcheck` directory.
3. Delete stale `00LOCK-*` directories.
4. Reboot Windows if the lock cannot be identified.
5. Repeat from the separate `_checks` directory.
6. If needed, run PowerShell once with elevated privileges only to diagnose filesystem permissions. Routine package validation should not require administrator rights.
7. Verify that antivirus or controlled-folder-access software is not temporarily locking the check directory.
8. Avoid synchronised/cloud directories for the check library.

The current observed error is specifically compatible with a file lock and should not be interpreted as evidence of a statistical-code failure.

---

## 11. Inspect `00check.log` and `00install.out`

After each check, inspect:

```text
D:/Walter/R/Pacotes_criados/_checks/multiRegFlow/multiRegFlow.Rcheck/00check.log
D:/Walter/R/Pacotes_criados/_checks/multiRegFlow/multiRegFlow.Rcheck/00install.out
```

Search explicitly for:

```text
ERROR
WARNING
NOTE
undefined global
no visible binding
failed
cannot
non-ASCII
portable
examples
vignettes
```

Do not rely only on the final status line.

Copy final logs to:

```text
D:/Walter/R/Pacotes_criados/multiRegFlow/validation/final-check/
```

so that validation evidence is retained even after the `.Rcheck` directory is deleted.

---

## 12. Run all examples from the installed package

`R CMD check` already executes examples, but a separate installed-package run is useful for release validation.

After installing the tarball in the clean library, run:

```r
library(tools)

tools::testInstalledPackage(
  "multiRegFlow",
  lib.loc = "D:/Walter/R/Pacotes_criados/_checklib_multiRegFlow",
  types = "examples"
)
```

The manual page is designed to provide at least three usage examples for every exported function. If examples are reorganised in future versions, recheck this coverage explicitly.

---

## 13. Validate the five instructional datasets

The package should continue to expose:

```r
mr_example_data()
```

and the expected datasets:

```text
soil_fertility
plant_growth
agronomy_collinear
irrigation_nonlinear
agronomy_heteroskedastic
```

Check dimensions, missing values and ranges:

```r
nms <- c(
  "soil_fertility",
  "plant_growth",
  "agronomy_collinear",
  "irrigation_nonlinear",
  "agronomy_heteroskedastic"
)

for (nm in nms) {
  d <- mr_example_data(nm)
  cat("\n", nm, "\n")
  print(dim(d))
  print(colSums(is.na(d)))
  print(summary(d))
}
```

The datasets are pedagogical and synthetic. Their documentation and vignettes must never imply that they are field observations.

---

## 14. Check the original source script provenance

The original multiple-regression script must remain preserved under the package source-material directory and must not be silently rewritten.

Record its SHA-256 before release:

```powershell
Get-FileHash `
  "D:\Walter\R\Pacotes_criados\multiRegFlow\inst\extdata\source-scripts\Reg_multipla.R" `
  -Algorithm SHA256
```

Store the result in:

```text
validation/SOURCE_PROVENANCE.md
```

---

## 15. Test installation with `remotes` and `pak`

### 15.1 Local source directory with `remotes`

```r
remotes::install_local(
  "D:/Walter/R/Pacotes_criados/multiRegFlow",
  build_vignettes = FALSE,
  upgrade = "never",
  force = TRUE
)
```

With vignettes:

```r
remotes::install_local(
  "D:/Walter/R/Pacotes_criados/multiRegFlow",
  build_vignettes = TRUE,
  upgrade = "never",
  force = TRUE
)
```

### 15.2 Local tarball

```r
remotes::install_local(
  "D:/Walter/R/Pacotes_criados/multiRegFlow/multiRegFlow_0.2.0.tar.gz",
  upgrade = "never",
  force = TRUE
)
```

### 15.3 Local directory with `pak`

```r
pak::pkg_install(
  "local::D:/Walter/R/Pacotes_criados/multiRegFlow"
)
```

After any installation route:

```r
library(multiRegFlow)
packageVersion("multiRegFlow")
mr_capabilities()
```

When a GitHub repository is eventually published, add equivalent `remotes::install_github()` and `pak::pkg_install("owner/multiRegFlow")` tests using the actual repository owner and tag. Do not insert a fictitious repository in validation records.

---

## 16. Optional offline validation preparation

For machines without internet access, install all `Suggests` in advance and maintain a local package library. The package must still retain a small mandatory dependency set; optional statistical engines should fail with informative messages rather than breaking package loading.

At minimum, verify that the package itself loads when optional backends are absent. This can be tested in a clean library containing only Imports/Depends.

The expected behavior is:

- `library(multiRegFlow)` succeeds;
- core OLS functionality succeeds;
- calls requiring an absent optional package fail with a clear `install.packages()`-style message naming the missing backend.

---

## 17. Manual and PDF documentation

If a working LaTeX distribution is available, run the final check **without** `--no-manual` and build the reference manual:

```powershell
& "C:\Program Files\R\R-4.6.0\bin\R.exe" CMD Rd2pdf `
  "D:\Walter\R\Pacotes_criados\multiRegFlow"
```

Inspect the PDF for:

- clipped usage lines;
- malformed equations;
- broken code examples;
- missing aliases;
- duplicated function sections;
- missing package title or description.

If PDF manual generation cannot be completed because LaTeX is unavailable, record this explicitly as an environment limitation. Do not record it as PASS.

---

## 18. Final release gates

The package can be considered locally release-ready only when all mandatory items below are satisfied.

### Code and installation

- [ ] Fresh tarball built from the current source tree.
- [ ] Tarball installs in a clean temporary library.
- [ ] Package loads after installation.
- [ ] Package unloads cleanly.
- [ ] No stale `00LOCK` remains.

### Automated tests

- [ ] `testthat` reports zero failures.
- [ ] OLS equivalence checks pass.
- [ ] HC3 coefficient invariance check passes.
- [ ] Collinearity stress dataset triggers expected diagnostics.
- [ ] Penalization tests pass.
- [ ] Bootstrap tests pass.
- [ ] Flexible-engine CV tests pass.
- [ ] Reporting tests pass.

### Documentation

- [ ] All 18 exported functions documented.
- [ ] At least three usage examples retained for each exported function.
- [ ] All 13 vignettes build successfully.
- [ ] All 13 rendered vignettes visually inspected.
- [ ] Agronomic units and interpretations checked.
- [ ] Original source script provenance recorded.

### CRAN-style checks

- [ ] `R CMD check --as-cran` executed on the built tarball, outside the source directory.
- [ ] `0 ERRORs`.
- [ ] `0 WARNINGs`.
- [ ] Every NOTE investigated and documented.
- [ ] Ideally `Status: OK`.

### Metadata

- [ ] Placeholder maintainer e-mail replaced with verified address.
- [ ] Version number correct.
- [ ] Authors/ORCID metadata verified.
- [ ] License files consistent.
- [ ] SHA-256 recorded for final tarball.

### Reproducibility

- [ ] `sessionInfo()` saved.
- [ ] Optional backend versions saved.
- [ ] Final `00check.log` archived.
- [ ] Final `00install.out` archived.
- [ ] Validation status document updated.

---

## 19. Suggested final validation directory structure

Use:

```text
multiRegFlow/
├── validation/
│   ├── README.md
│   ├── VALIDATION_STATUS.md
│   ├── sessionInfo.txt
│   ├── package_versions.csv
│   ├── SOURCE_PROVENANCE.md
│   ├── VIGNETTE_VISUAL_INSPECTION.md
│   ├── scientific_sanity_checks.txt
│   └── final-check/
│       ├── 00check.log
│       └── 00install.out
```

Do not include temporary `.Rcheck`, `00LOCK`, cached HTML preview servers or user-specific temporary libraries in the source tarball.

---

## 20. Immediate remaining sequence for version 0.2.0

For the current package, perform the remaining steps in this exact order:

1. Replace the placeholder maintainer e-mail with the verified address.
2. Close all R/RStudio processes using `multiRegFlow`.
3. Delete the stale `multiRegFlow.Rcheck` and any `00LOCK-multiRegFlow` directory.
4. Run `testthat::test_local()` from a fresh R session.
5. Rebuild `multiRegFlow_0.2.0.tar.gz` with `vignettes = TRUE`.
6. Install that tarball into a clean temporary library.
7. Run the scientific equivalence/sanity checks in Sections 6 and 13.
8. Run `R CMD check --as-cran` from `D:/Walter/R/Pacotes_criados/_checks/multiRegFlow`, not from the source directory.
9. If the staged-install access-denied error reappears, remove locks/reboot/check antivirus and repeat; do not modify statistical code merely to address a filesystem lock.
10. Correct every genuine package ERROR/WARNING/NOTE found after the lock problem is removed.
11. Rebuild and repeat `R CMD check --as-cran` after every code/documentation correction.
12. Visually inspect all 13 rendered vignettes.
13. Archive the final check logs and session information.
14. Recalculate final SHA-256.
15. Update `VALIDATION_STATUS.md` only after the final clean run.

The release target is a package built from the same source tree whose final tarball, examples, vignettes, tests and CRAN-style check all refer to the same version and checksum.
