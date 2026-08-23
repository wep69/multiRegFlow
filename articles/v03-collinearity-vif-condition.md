# Multicollinearity: VIF, condition indices and agronomic interpretation

## Collinearity is not merely a threshold problem

In agronomy, correlated predictors are often expected. Soil organic
matter, CEC and clay can co-vary; N rate, N uptake and canopy N
represent related processes; plant height, leaf area and biomass can
track plant vigor. The question is not simply whether two predictors
correlate, but whether the data contain enough independent information
to estimate their conditional effects.

For predictor $`X_j`$, VIF is based on the coefficient of determination
from regressing $`X_j`$ on the remaining predictors. Large VIF therefore
indicates that the unique variation available for estimating its slope
is limited.

## Example 1: deliberately collinear N-status indicators

``` r

d <- mr_example_data("agronomy_collinear")
fit <- mr_fit(yield_t_ha ~ ., d)
col <- mr_collinearity(fit)
col$VIF
#>                   term       VIF  tolerance flag_vif5 flag_vif10
#> 1         N_rate_kg_ha 11.449832 0.08733752      TRUE       TRUE
#> 2       N_uptake_kg_ha  8.485220 0.11785198      TRUE      FALSE
#> 3        canopy_N_g_m2  1.707740 0.58556922     FALSE      FALSE
#> 4                 NDVI  3.597993 0.27793270     FALSE      FALSE
#> 5       season_rain_mm  1.033892 0.96721862     FALSE      FALSE
#> 6 soil_mineral_N_mg_kg  1.024386 0.97619415     FALSE      FALSE
```

``` r

head(col$correlations, 10)
#>             term1                term2 correlation abs_correlation
#> 1    N_rate_kg_ha       N_uptake_kg_ha  0.93898235      0.93898235
#> 4    N_rate_kg_ha                 NDVI  0.84737848      0.84737848
#> 5  N_uptake_kg_ha                 NDVI  0.79671287      0.79671287
#> 2    N_rate_kg_ha        canopy_N_g_m2  0.63003106      0.63003106
#> 3  N_uptake_kg_ha        canopy_N_g_m2  0.60092016      0.60092016
#> 6   canopy_N_g_m2                 NDVI  0.55493868      0.55493868
#> 13  canopy_N_g_m2 soil_mineral_N_mg_kg -0.14581160      0.14581160
#> 8  N_uptake_kg_ha       season_rain_mm  0.10920771      0.10920771
#> 7    N_rate_kg_ha       season_rain_mm  0.10514353      0.10514353
#> 12 N_uptake_kg_ha soil_mineral_N_mg_kg -0.07916093      0.07916093
col$condition_index
#>   dimension condition_index flag_ci15 flag_ci30
#> 1      Dim1        1.000000     FALSE     FALSE
#> 2      Dim2        1.768396     FALSE     FALSE
#> 3      Dim3        1.821708     FALSE     FALSE
#> 4      Dim4        2.541635     FALSE     FALSE
#> 5      Dim5        3.880533     FALSE     FALSE
#> 6      Dim6        7.689868     FALSE     FALSE
```

Variance-decomposition proportions help identify which coefficient
dimensions are associated with high condition indices.

``` r

round(col$variance_decomposition, 3)
#>                       Dim1  Dim2  Dim3  Dim4  Dim5  Dim6
#> N_rate_kg_ha         0.008 0.000 0.000 0.006 0.030 0.955
#> N_uptake_kg_ha       0.010 0.001 0.000 0.010 0.163 0.816
#> canopy_N_g_m2        0.032 0.017 0.000 0.918 0.019 0.014
#> NDVI                 0.022 0.000 0.003 0.056 0.798 0.121
#> season_rain_mm       0.001 0.509 0.431 0.027 0.031 0.002
#> soil_mineral_N_mg_kg 0.002 0.394 0.556 0.045 0.000 0.003
```

A high condition index becomes more informative when two or more
variables have large variance proportions concentrated in the same
high-index dimension.

## Example 2: soil fertility variables

``` r

soil <- mr_example_data("soil_fertility")
fit_soil <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct + CEC_cmolc_dm3 +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 + soil_moisture_pct,
  soil
)
col_soil <- mr_collinearity(fit_soil)
col_soil$VIF
#>                    term      VIF tolerance flag_vif5 flag_vif10
#> 1               soil_pH 1.079348 0.9264855     FALSE      FALSE
#> 2    organic_matter_pct 1.598825 0.6254592     FALSE      FALSE
#> 3              clay_pct 3.713320 0.2693008     FALSE      FALSE
#> 4         CEC_cmolc_dm3 4.281042 0.2335880     FALSE      FALSE
#> 5    available_P_mg_dm3 1.017423 0.9828751     FALSE      FALSE
#> 6 exchangeable_K_mg_dm3 1.044288 0.9575906     FALSE      FALSE
#> 7     soil_moisture_pct 1.024203 0.9763686     FALSE      FALSE
head(col_soil$correlations, 8)
#>                 term1                 term2 correlation abs_correlation
#> 6            clay_pct         CEC_cmolc_dm3  0.78397595      0.78397595
#> 5  organic_matter_pct         CEC_cmolc_dm3  0.39062683      0.39062683
#> 13           clay_pct exchangeable_K_mg_dm3  0.18659494      0.18659494
#> 14      CEC_cmolc_dm3 exchangeable_K_mg_dm3  0.18610336      0.18610336
#> 2             soil_pH              clay_pct  0.17079525      0.17079525
#> 1             soil_pH    organic_matter_pct -0.11147098      0.11147098
#> 16            soil_pH     soil_moisture_pct  0.09309839      0.09309839
#> 20 available_P_mg_dm3     soil_moisture_pct  0.08405767      0.08405767
```

Here CEC, clay and organic matter have an agronomic reason to share
information. If the goal is to estimate the effect of available P while
adjusting for soil buffering properties, dropping all correlated soil
descriptors merely to reduce VIF can change the scientific estimand.

## Example 3: plant growth indicators

``` r

plant <- mr_example_data("plant_growth")
fit_plant <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    stomatal_conductance + plant_height_cm + root_mass_g +
    specific_leaf_area_cm2_g,
  plant
)
mr_collinearity(fit_plant)$VIF
#>                       term      VIF tolerance flag_vif5 flag_vif10
#> 1            leaf_area_cm2 1.023202 0.9773243     FALSE      FALSE
#> 2         chlorophyll_spad 1.033957 0.9671583     FALSE      FALSE
#> 3               leaf_N_pct 1.013308 0.9868669     FALSE      FALSE
#> 4     stomatal_conductance 1.038567 0.9628651     FALSE      FALSE
#> 5          plant_height_cm 1.028080 0.9726870     FALSE      FALSE
#> 6              root_mass_g 1.029847 0.9710178     FALSE      FALSE
#> 7 specific_leaf_area_cm2_g 1.012667 0.9874915     FALSE      FALSE
```

This third example demonstrates that the same diagnostics can be used
when predictors represent physiology and morphology rather than soil
attributes.

## Why VIF = 5 or 10 is not a universal decision rule

Thresholds are useful for screening, but their practical meaning depends
on the scientific objective, sample size, effect size, measurement
precision and the role of the predictor. A high VIF may be acceptable
for a nuisance covariate that must remain in the model, while it may
seriously limit attempts to separate the effects of two competing
treatments or nutrient indicators.

`multiRegFlow` therefore returns two flags, VIF \>= 5 and VIF \>= 10,
but never automatically removes a term.

## Compare OLS with ridge under collinearity

``` r

if (requireNamespace("glmnet", quietly = TRUE)) {
  ridge <- mr_regularize(fit, "ridge", nfolds = 5, seed = 44)
  ridge$coefficients
}
#>                       lambda.1se
#> (Intercept)          2.684121969
#> N_rate_kg_ha         0.009551325
#> N_uptake_kg_ha       0.008453892
#> canopy_N_g_m2        0.015665531
#> NDVI                 1.641964466
#> season_rain_mm       0.003410322
#> soil_mineral_N_mg_kg 0.058140766
```

Ridge does not make collinearity disappear. It changes the estimation
problem by shrinking coefficients, which can greatly improve stability
and prediction. For explanatory work, this makes ridge a useful
sensitivity analysis rather than an automatic replacement for the
prespecified OLS estimand.

## Compare selection stability

``` r

if (requireNamespace("stabs", quietly = TRUE) &&
    requireNamespace("glmnet", quietly = TRUE)) {
  stab <- mr_select(fit, "stability", cutoff = 0.75, PFER = 1)
  stab$selected
  sort(stab$selection_probabilities, decreasing = TRUE)
}
```

If two correlated indicators alternate across resamples, the instability
itself is scientifically informative. It suggests that the dataset
supports a shared signal more strongly than a unique ranking between the
indicators.

## Practical decisions

When multicollinearity is substantial, consider:

- retaining scientifically mandatory variables and emphasizing their
  joint role;
- choosing one indicator based on measurement quality or biological
  priority, not p-value alone;
- creating a justified composite if several measurements represent one
  construct;
- using ridge for coefficient stabilization or prediction;
- using stability selection when variable-screening reproducibility is
  important;
- collecting data that separate the predictors more effectively in
  future experiments.

The final decision should follow the research question rather than an
arbitrary VIF target.
