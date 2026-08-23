# Out-of-sample validation and fair model comparison

## Training fit is not predictive validation

A model evaluated on the same observations used to estimate its
coefficients receives an optimistic assessment of predictive
performance.
[`mr_validate()`](https://wep69.github.io/multiRegFlow/reference/multiRegFlow.md)
uses repeated cross-validation so every reported prediction is generated
by a model that did not use that observation for fitting.

The package reports RMSE, MAE, out-of-fold R-squared, calibration
intercept and calibration slope.

## Example 1: soil yield prediction

``` r

soil <- mr_example_data("soil_fertility")
soil_full <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 +
    soil_moisture_pct + season_rain_mm,
  soil,
  goal = "prediction"
)
cv_soil <- mr_validate(soil_full, v = 5, repeats = 4, seed = 50)
cv_soil$summary
#>                  metric      mean          sd
#> 1                  RMSE 0.5919053 0.004688401
#> 2                   MAE 0.4826185 0.003040008
#> 3                    R2 0.3608136 0.010107838
#> 4 calibration_intercept 0.4109245 0.085424171
#> 5     calibration_slope 0.9271447 0.014846352
```

## Example 2: plant biomass prediction

``` r

plant <- mr_example_data("plant_growth")
plant_fit <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    stomatal_conductance + plant_height_cm + root_mass_g,
  plant,
  goal = "prediction"
)
cv_plant <- mr_validate(plant_fit, v = 5, repeats = 4, seed = 51)
cv_plant$summary
#>                  metric      mean         sd
#> 1                  RMSE 1.4053022 0.02245362
#> 2                   MAE 1.1240903 0.01892549
#> 3                    R2 0.6703392 0.01054982
#> 4 calibration_intercept 0.6639217 0.29270488
#> 5     calibration_slope 0.9721412 0.01246428
```

## Example 3: nonlinear GAM validation

``` r

nl <- mr_example_data("irrigation_nonlinear")
gam_fit <- mr_fit(
  yield_t_ha ~ s(irrigation_mm) + s(N_rate_kg_ha) + s(mean_temp_C),
  nl,
  engine = "gam",
  goal = "prediction"
)
cv_gam <- mr_validate(gam_fit, v = 5, repeats = 3, seed = 52)
cv_gam$summary
#>                  metric      mean         sd
#> 1                  RMSE 0.7837275 0.01277813
#> 2                   MAE 0.6319683 0.01216068
#> 3                    R2 0.6434333 0.01157062
#> 4 calibration_intercept 0.3630109 0.15198219
#> 5     calibration_slope 0.9643819 0.01483864
```

The same interface can validate robust regression and a single-quantile
regression. Kernel models are also supported, although repeated
bandwidth selection can be computationally expensive.

## Observed versus out-of-fold predictions

``` r

p <- cv_soil$predictions
plot(p$observed, p$predicted,
     xlab = "Observed yield (t/ha)",
     ylab = "Out-of-fold predicted yield (t/ha)")
abline(0, 1, lty = 2)
```

![Observed and out-of-fold predicted soil yield from repeated
cross-validation.](v09-validation-comparison_files/figure-html/predplot-1.png)

Observed and out-of-fold predicted soil yield from repeated
cross-validation.

The plot includes predictions from multiple repetitions. It visualizes
both bias and dispersion rather than compressing predictive behavior
into one number.

## Calibration

A calibration intercept near zero indicates little systematic shift in
the mean prediction. A calibration slope near one indicates that
prediction spread is appropriately scaled. A slope below one often
indicates predictions that are too extreme, while a slope above one can
indicate predictions that are too narrow. Calibration is a diagnostic,
not a universal acceptance test.

## Model comparison 1: full versus reduced soil model

``` r

soil_small <- mr_fit(
  yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 + season_rain_mm,
  soil,
  goal = "prediction"
)
cmp1 <- mr_compare(full = soil_full, reduced = soil_small,
                   v = 5, repeats = 3, seed = 60)
cmp1$inference
#>     model engine     AIC      BIC R2_or_gam_R2
#> 1    full    ols 323.118 351.8546    0.4181638
#> 2 reduced    ols 349.723 365.6878    0.2948299
#>   adjusted_R2_or_deviance_explained
#> 1                         0.3944845
#> 2                         0.2828099
cmp1$prediction
#>      model engine                metric      mean          sd note
#> 1     full    ols                  RMSE 0.5905306 0.015206875 <NA>
#> 2     full    ols                   MAE 0.4815092 0.013551591 <NA>
#> 3     full    ols                    R2 0.3635279 0.032955340 <NA>
#> 4     full    ols calibration_intercept 0.3495940 0.206433017 <NA>
#> 5     full    ols     calibration_slope 0.9374532 0.036589971 <NA>
#> 6  reduced    ols                  RMSE 0.6348997 0.006796699 <NA>
#> 7  reduced    ols                   MAE 0.5249750 0.006058162 <NA>
#> 8  reduced    ols                    R2 0.2645621 0.015743427 <NA>
#> 9  reduced    ols calibration_intercept 0.2591840 0.190145482 <NA>
#> 10 reduced    ols     calibration_slope 0.9540196 0.033462963 <NA>
```

AIC/BIC and out-of-fold metrics appear in separate tables because they
are not interchangeable.

## Model comparison 2: linear versus GAM irrigation response

``` r

lin_fit <- mr_fit(
  yield_t_ha ~ irrigation_mm + N_rate_kg_ha + mean_temp_C,
  nl,
  goal = "prediction"
)
cmp2 <- mr_compare(linear = lin_fit, gam = gam_fit,
                   v = 5, repeats = 3, seed = 61)
cmp2$prediction
#>     model engine                metric      mean          sd note
#> 1  linear    ols                  RMSE 1.1391091 0.007913061 <NA>
#> 2  linear    ols                   MAE 0.8972738 0.002531951 <NA>
#> 3  linear    ols                    R2 0.2468556 0.010442612 <NA>
#> 4  linear    ols calibration_intercept 1.1305600 0.294544899 <NA>
#> 5  linear    ols     calibration_slope 0.8878851 0.029724187 <NA>
#> 6     gam    gam                  RMSE 0.7876723 0.002553163 <NA>
#> 7     gam    gam                   MAE 0.6351507 0.003509462 <NA>
#> 8     gam    gam                    R2 0.6398961 0.002336648 <NA>
#> 9     gam    gam calibration_intercept 0.3381058 0.094206075 <NA>
#> 10    gam    gam     calibration_slope 0.9660592 0.007526332 <NA>
```

## Model comparison 3: OLS versus robust regression

``` r

coll <- mr_example_data("agronomy_collinear")
ols <- mr_fit(
  yield_t_ha ~ N_rate_kg_ha + season_rain_mm + soil_mineral_N_mg_kg,
  coll,
  goal = "prediction"
)
rob <- mr_fit(
  yield_t_ha ~ N_rate_kg_ha + season_rain_mm + soil_mineral_N_mg_kg,
  coll,
  engine = "robust",
  goal = "prediction"
)
cmp3 <- mr_compare(OLS = ols, robust = rob,
                   v = 5, repeats = 3, seed = 62)
#> Warning in lmrob.S(x, y, control = control): S refinements did not converge (to
#> refine.tol=1e-07) in 200 (= k.max) steps
#> Warning in lmrob.fit(x, y, control, init = init): initial estim. 'init' not
#> converged -- will be return()ed basically unchanged
cmp3$prediction
#>     model engine                metric        mean          sd note
#> 1     OLS    ols                  RMSE  0.73012252 0.012153651 <NA>
#> 2     OLS    ols                   MAE  0.58456214 0.010312109 <NA>
#> 3     OLS    ols                    R2  0.69205086 0.010298040 <NA>
#> 4     OLS    ols calibration_intercept  0.08844062 0.061558490 <NA>
#> 5     OLS    ols     calibration_slope  0.99081194 0.006449994 <NA>
#> 6  robust robust                  RMSE  0.73382615 0.011978141 <NA>
#> 7  robust robust                   MAE  0.58351210 0.012330459 <NA>
#> 8  robust robust                    R2  0.68892093 0.010201398 <NA>
#> 9  robust robust calibration_intercept -0.20864963 0.140993957 <NA>
#> 10 robust robust     calibration_slope  1.02091951 0.014157313 <NA>
```

Robust regression can improve prediction when extreme observations
distort OLS, but it need not outperform OLS in every dataset. The
comparison should be made with the same folds, response and predictor
information.

## What not to compare directly

Do not compare training `R-squared` from one model with cross-validated
RMSE from another. Do not choose a model solely because its AIC is lower
if the stated goal is prediction. Conversely, a slightly smaller
predictive RMSE does not justify removing a scientifically required
adjustment variable from an explanatory model.

## Repeated CV and uncertainty

[`mr_validate()`](https://wep69.github.io/multiRegFlow/reference/multiRegFlow.md)
reports metrics for each repetition and summarizes their mean and
standard deviation. The repetition-level variation is not a full
confidence interval for generalization performance, but it provides a
useful measure of sensitivity to fold assignment.

``` r

cv_soil$metrics
#>        RMSE       MAE        R2 calibration_intercept calibration_slope
#> 1 0.5910963 0.4830046 0.3625898             0.5168203         0.9090689
#> 2 0.5963804 0.4859250 0.3511425             0.3887481         0.9306524
#> 3 0.5856824 0.4785558 0.3742124             0.3112648         0.9448232
#> 4 0.5944622 0.4829886 0.3553097             0.4268646         0.9240345
```

For high-stakes prediction, nested cross-validation or an untouched
external test set may be preferable, particularly when hyperparameters
and feature sets are tuned extensively.
