# multiRegFlow 0.2.0: scientific scope and design decisions

## Purpose

`multiRegFlow` is an integration and interpretation layer for multiple regression in agricultural, soil and plant sciences. It does not attempt to reimplement every statistical estimator. Specialized estimation is delegated to established R packages, while `multiRegFlow` provides a coherent workflow, stable objects, agronomic examples, validation, interpretation and reporting.

## Primary scientific questions

The workflow starts by distinguishing:

1. **explanation/inference**, where the goal is conditional association, uncertainty and scientific interpretation under a prespecified model; and
2. **prediction**, where the goal is performance for observations not used to fit the model.

This distinction controls how selection, shrinkage and model comparison are interpreted.

## Included methodological blocks

### OLS reference model

- multiple linear regression;
- coefficients, fitted values and predictions;
- rank and residual degrees of freedom;
- conventional fit summaries.

### Diagnostics

- residual summaries;
- Shapiro-Wilk screen when sample size permits;
- Breusch-Pagan heteroscedasticity screen;
- fitted-value-power functional-form screen;
- leverage, Cook distance, DFFITS and DFBETAS;
- transparent influence flags without automatic deletion.

### Multicollinearity

- VIF and tolerance;
- VIF >= 5 and VIF >= 10 screening flags;
- condition indices;
- variance-decomposition proportions;
- strongest pairwise correlations in the model matrix;
- optional `performance::check_collinearity()` output, including GVIF handling where supported.

No predictor is automatically removed because of a VIF threshold.

### Coefficient inference

- classical OLS covariance;
- HC0, HC1, HC2, HC3, HC4, HC4m and HC5 covariance through `sandwich`;
- one-way cluster-robust covariance using the real sampling/experimental cluster when supplied.

### Variable selection

- AIC and BIC stepwise exploration;
- mandatory terms through `keep=`;
- best subsets through `leaps`;
- lasso and elastic-net selection through `glmnet`;
- stability selection through `stabs` and `glmnet`.

Selection is explicitly described as exploratory unless the inferential procedure accounts for the search.

### Regularization

- ridge;
- lasso;
- elastic net;
- `lambda.min` and `lambda.1se`;
- cross-validation curve and nonzero coefficients.

### Bootstrap and resampling

- pairs bootstrap;
- residual bootstrap;
- Rademacher wild bootstrap;
- percentile, basic and normal intervals;
- coefficient sign stability;
- successful-replicate accounting.

The bootstrap unit must follow the design. The built-in bootstrap is intended for independent observational units.

### Importance and effects

- standardized coefficients;
- coefficient-level partial R-squared;
- term-level semi-partial R-squared;
- LMG decomposition through `relaimpo`;
- additive SHAP through `kernelshap` for additive OLS models;
- average marginal slopes through `marginaleffects`.

These measures are deliberately not treated as interchangeable definitions of variable importance.

### Flexible alternatives

- robust regression through `robustbase::lmrob()`;
- quantile regression through `quantreg::rq()`;
- GAM through `mgcv::gam()`;
- kernel regression through `np::npregbw()` and `np::npreg()`.

These models are sensitivity analyses or alternatives motivated by a scientific target or diagnosed functional-form problem. They are not automatic upgrades over OLS.

### Predictive validation

Repeated cross-validation is implemented for:

- OLS;
- robust regression;
- single-quantile regression;
- GAM;
- kernel regression.

Metrics include RMSE, MAE, out-of-fold R-squared, calibration intercept and calibration slope.

### Reporting

`mr_report()` records:

- declared goal;
- formula and sample size;
- fit summaries;
- diagnostic screens;
- classical or robust coefficient inference;
- collinearity evidence;
- most influential observations for inspection;
- rule-based methodological recommendations;
- optional out-of-fold validation.

## Intentionally outside the core scope

The following are not part of the current core because they would change the scientific purpose of the package:

- generalized linear models with many response distributions;
- mixed models and repeated-measures covariance structures;
- survival models;
- spatial regression;
- dedicated time-series regression;
- high-dimensional selective inference;
- Bayesian regression;
- random forest, boosting and deep learning as core engines;
- omics-specific Bioconductor workflows.

These may be useful comparison or future-extension topics but should not turn the package into a generic machine-learning framework.

## Agricultural teaching domains

Examples use synthetic analogues of:

- soil fertility and nutrient availability;
- soil pH, organic matter, texture and CEC;
- plant biomass and morphology;
- chlorophyll, leaf N and stomatal conductance;
- N rate and plant N-status indicators;
- irrigation and temperature response;
- soil water and heteroscedastic yield response.

## Reproducibility principles

- frozen synthetic teaching datasets;
- fixed seeds in resampling examples;
- no use of `attach()`;
- no manual transcription of VIF, tolerance or condition indices;
- no leakage of fitted values back into the predictor set;
- predictive comparisons based on out-of-fold predictions;
- optional backends checked through `requireNamespace()`;
- source script preserved under `inst/extdata/source-scripts/` for provenance.

## Release note

The maintainer email in `DESCRIPTION` remains an explicit `.invalid` placeholder and must be replaced with a verified address before CRAN submission.
