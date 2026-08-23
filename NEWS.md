# multiRegFlow 0.2.0

- Expanded the guided multiple-regression workflow for agricultural, soil and plant sciences.
- Added design-rank and fitted-value-power specification screens to `mr_diagnose()`.
- Added transparent leverage, Cook, DFFITS and DFBETA screening flags to `mr_influence()`.
- Expanded `mr_collinearity()` with VIF flags, condition-index flags and strongest pairwise correlations.
- Added percentile, basic and normal bootstrap intervals and successful-replicate accounting.
- Extended `mr_validate()` to OLS, robust regression, GAM, kernel regression and single-quantile regression, with calibration intercept and slope.
- Expanded penalized selection outputs and explicit `lambda.1se`/`lambda.min` selection.
- Added semi-partial R-squared to `mr_importance()`.
- Expanded rule-based recommendations for rank deficiency, low information per predictor, heteroscedasticity and nonlinear specification signals.
- Expanded Markdown audit reports with coefficient inference, collinearity, influential observations and optional out-of-fold validation.
- Added extensive agricultural examples and revised long-form pedagogical vignettes.

# multiRegFlow 0.1.0

- Initial guided workflow for multiple linear regression, diagnostics, collinearity, selection, regularization, bootstrap, relative importance and flexible alternatives.
