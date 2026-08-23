# Guided Multiple Regression for Agricultural Sciences

A teaching-oriented and auditable workflow for multiple regression in
agricultural, soil and plant sciences. Ordinary least squares is
retained as a transparent reference model and is connected to
diagnostics, collinearity analysis, robust covariance inference,
selection, regularization, bootstrap, predictive validation, relative
importance and flexible alternatives.

## Usage

``` r
mr_fit(formula, data, goal = c("explanation", "prediction"),
       engine = c("ols", "robust", "quantile", "kernel", "gam"),
       tau = 0.5, ...)
mr_diagnose(x)
mr_influence(x)
mr_collinearity(x)
mr_select(x, method = c("aic", "bic", "best_subset", "lasso",
          "elastic_net", "stability"), alpha = 0.5, keep = NULL,
          seed = 123, lambda = c("1se", "min"), ...)
mr_regularize(x, method = c("ridge", "lasso", "elastic_net"),
              alpha = 0.5, lambda = c("1se", "min"),
              nfolds = 10, seed = 123, ...)
mr_bootstrap(x, R = 999, type = c("pairs", "residual", "wild"),
             seed = 123, conf = 0.95,
             interval = c("percentile", "basic", "normal"))
mr_validate(x, v = 10, repeats = 5, seed = 123)
mr_importance(x, method = c("standardized", "partial_r2",
              "semi_partial_r2", "lmg", "shap"), ...)
mr_inference(x, vcov = c("classical", "HC3", "HC0", "HC1", "HC2",
             "HC4", "HC4m", "HC5", "cluster"), cluster = NULL,
             conf = 0.95)
mr_effects(x, variables = NULL, ...)
mr_quantile(x, tau = c(0.1, 0.25, 0.5, 0.75, 0.9), ...)
mr_kernel(x, ...)
mr_compare(..., validation = TRUE, v = 10, repeats = 3, seed = 123)
mr_recommend(x)
mr_capabilities()
mr_example_data(name = c("soil_fertility", "plant_growth",
                         "agronomy_collinear", "irrigation_nonlinear",
                         "agronomy_heteroskedastic"))
mr_report(x, file = NULL, vcov = c("auto", "classical", "HC3"),
          validation = NULL, v = 5, repeats = 3, seed = 123)
```

## Arguments

- formula:

  A model formula with a numeric response.

- data:

  A data frame.

- goal:

  Scientific goal: `"explanation"` or `"prediction"`.

- engine:

  Model engine. OLS is the transparent reference implementation.

- tau:

  Quantile or vector of quantiles for quantile regression.

- x:

  An object created by `mr_fit()`.

- method:

  Method-specific option.

- alpha:

  Elastic-net mixing parameter.

- keep:

  Terms that must remain in stepwise search.

- seed:

  Random seed used by resampling or cross-validation methods.

- lambda:

  Cross-validation rule used to select lambda.

- nfolds:

  Number of folds for penalized regression.

- R:

  Number of bootstrap replicates.

- type:

  Bootstrap resampling type.

- conf:

  Confidence level.

- interval:

  Bootstrap interval type.

- v:

  Number of cross-validation folds.

- repeats:

  Number of cross-validation repetitions.

- variables:

  Variables passed to marginaleffects.

- vcov:

  Covariance estimator for coefficient inference or report generation.

- cluster:

  Cluster identifier vector, column name, or one-sided formula.

- name:

  Name of a frozen synthetic teaching dataset.

- validation:

  Whether to compute out-of-fold validation.

- file:

  Optional Markdown output path.

- ...:

  Additional arguments passed to a backend.

## Value

Functions return structured lists, data frames, backend model objects,
or `mr_fit` objects. `mr_report()` returns generated Markdown text
invisibly and optionally writes it to disk.

## Details

The package intentionally separates inferential adequacy from predictive
performance. Automated selection is treated as exploratory unless the
design and inferential procedure justify stronger claims. Collinearity
is evaluated jointly using VIF/tolerance, condition indices,
variance-decomposition proportions and scientific context; variables are
not automatically deleted based on a single threshold. Predictive claims
are evaluated with out-of-fold predictions.

## Examples

``` r
## ------------------------------------------------------------------
## Shared synthetic agronomic datasets
## ------------------------------------------------------------------
soil <- mr_example_data("soil_fertility")
plant <- mr_example_data("plant_growth")
coll <- mr_example_data("agronomy_collinear")
het <- mr_example_data("agronomy_heteroskedastic")
nl <- mr_example_data("irrigation_nonlinear")

## mr_example_data(): three examples
head(mr_example_data("soil_fertility"))
#>   yield_t_ha  soil_pH organic_matter_pct clay_pct available_P_mg_dm3
#> 1   4.939198 5.587541          0.9136292 30.31950          21.236872
#> 2   5.798104 5.892831          3.8554225 28.32172          23.897597
#> 3   5.602376 5.293853          1.5610240 19.34390          36.422502
#> 4   5.065433 5.881771          0.9004022 16.66973           9.359331
#> 5   5.871927 5.611566          1.2689464 52.24648           6.083137
#> 6   5.514284 6.987995          3.0836037 23.83380          10.061138
#>   exchangeable_K_mg_dm3 CEC_cmolc_dm3 soil_moisture_pct season_rain_mm
#> 1             111.23988      22.04730          17.97199       616.6099
#> 2             103.21044      26.49989          21.38650       646.4131
#> 3              56.64054      18.92448          24.18364       521.3450
#> 4              78.63756      22.83040          27.87862       691.7602
#> 5             135.57253      34.23084          26.49413       611.6078
#> 6             127.93277      21.75013          22.01465       707.3954
head(mr_example_data("plant_growth"))
#>   biomass_g leaf_area_cm2 chlorophyll_spad leaf_N_pct stomatal_conductance
#> 1  22.41182      46.57932         29.52748   2.497403            0.4264847
#> 2  26.80686      63.87120         40.46530   3.007287            0.3568904
#> 3  25.07119      65.87807         35.64595   3.252079            0.3347268
#> 4  28.11724      41.45577         41.01836   3.388931            0.3582714
#> 5  23.60631      37.72871         42.98665   2.852986            0.2184418
#> 6  25.92997      42.08849         37.34380   3.145142            0.2602208
#>   plant_height_cm root_mass_g specific_leaf_area_cm2_g
#> 1        98.18931    12.42987                 171.9559
#> 2        86.18181    16.91079                 170.6346
#> 3        91.22507    11.86162                 174.5693
#> 4       106.01501    10.30238                 175.3188
#> 5        61.69300    13.16899                 238.1560
#> 6        86.22245    18.54832                 182.9096
head(mr_example_data("agronomy_collinear"))
#>   yield_t_ha N_rate_kg_ha N_uptake_kg_ha canopy_N_g_m2      NDVI season_rain_mm
#> 1   9.063762     54.80356       42.11326      27.88360 0.4344251       669.2360
#> 2   9.722673    121.59465       83.56063      45.26489 0.6834496       548.2547
#> 3  12.446738    181.85054      125.30026      45.54041 0.8409256       598.3467
#> 4   9.571229    132.57804       95.19560      47.67904 0.6945713       438.1946
#> 5   9.941384    165.33574      126.39859      51.72379 0.8397613       558.3082
#> 6   8.606517     93.45088       54.95173      37.72179 0.5453790       483.9165
#>   soil_mineral_N_mg_kg
#> 1             38.32147
#> 2             41.60750
#> 3             23.18852
#> 4             20.57379
#> 5             17.12780
#> 6             18.79896

## mr_fit(): three examples
fit_soil <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +
    season_rain_mm, soil, goal = "explanation")
fit_plant <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    plant_height_cm, plant, goal = "prediction")
if (requireNamespace("robustbase", quietly = TRUE))
  fit_robust <- mr_fit(yield_t_ha ~ N_rate_kg_ha + season_rain_mm,
                       coll, engine = "robust")

## mr_diagnose(): three examples
mr_diagnose(fit_soil)
#> $goal
#> [1] "explanation"
#> 
#> $fit
#>              n              p effective_rank    residual_df             R2 
#>    180.0000000      4.0000000      5.0000000    175.0000000      0.2954465 
#>    adjusted_R2          sigma            AIC            BIC 
#>      0.2793424      0.6302646    351.5655421    370.7232832 
#> 
#> $rank
#>                 rank_deficient n_to_effective_predictor_ratio 
#>                              0                             45 
#> 
#> $residuals
#>         mean           sd    shapiro_W    shapiro_p 
#> 2.670887e-17 6.231828e-01 9.935283e-01 6.139873e-01 
#> 
#> $heteroscedasticity
#> statistic        df   p.value 
#> 0.6058121 4.0000000 0.9624156 
#> 
#> $specification
#>    statistic          df1          df2      p.value 
#>   0.09015588   2.00000000 173.00000000   0.91383164 
#> 
#> $influence
#>            max_hat max_cooks_distance n_cook_gt_4_over_n 
#>         0.13887206         0.04781363        11.00000000 
#> 
#> $note
#> [1] "Interpret diagnostics jointly. Normality is mainly relevant to exact small-sample inference; heteroscedasticity can often be addressed with robust covariance or wild bootstrap without changing the mean model."
#> 
mr_diagnose(mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                     soil_water_m3_m3, het))
#> $goal
#> [1] "explanation"
#> 
#> $fit
#>              n              p effective_rank    residual_df             R2 
#>    180.0000000      3.0000000      4.0000000    176.0000000      0.2624474 
#>    adjusted_R2          sigma            AIC            BIC 
#>      0.2498755      1.6648444    700.2761650    716.2409493 
#> 
#> $rank
#>                 rank_deficient n_to_effective_predictor_ratio 
#>                              0                             60 
#> 
#> $residuals
#>         mean           sd    shapiro_W    shapiro_p 
#> 1.107829e-16 1.650834e+00 9.941860e-01 7.036736e-01 
#> 
#> $heteroscedasticity
#>    statistic           df      p.value 
#> 11.814804618  3.000000000  0.008045251 
#> 
#> $specification
#>   statistic         df1         df2     p.value 
#>   0.1928865   2.0000000 174.0000000   0.8247516 
#> 
#> $influence
#>            max_hat max_cooks_distance n_cook_gt_4_over_n 
#>         0.08031997         0.06075488        10.00000000 
#> 
#> $note
#> [1] "Interpret diagnostics jointly. Normality is mainly relevant to exact small-sample inference; heteroscedasticity can often be addressed with robust covariance or wild bootstrap without changing the mean model."
#> 
mr_diagnose(mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha +
                     mean_temp_C, nl))
#> $goal
#> [1] "explanation"
#> 
#> $fit
#>              n              p effective_rank    residual_df             R2 
#>    170.0000000      3.0000000      4.0000000    166.0000000      0.3021057 
#>    adjusted_R2          sigma            AIC            BIC 
#>      0.2894932      1.1096817    523.7761820    539.4551742 
#> 
#> $rank
#>                 rank_deficient n_to_effective_predictor_ratio 
#>                        0.00000                       56.66667 
#> 
#> $residuals
#>         mean           sd    shapiro_W    shapiro_p 
#> 2.632028e-17 1.099788e+00 9.714907e-01 1.432535e-03 
#> 
#> $heteroscedasticity
#> statistic        df   p.value 
#> 3.9617267 3.0000000 0.2656267 
#> 
#> $specification
#>   statistic         df1         df2     p.value 
#>   0.7537816   2.0000000 164.0000000   0.4722068 
#> 
#> $influence
#>            max_hat max_cooks_distance n_cook_gt_4_over_n 
#>         0.06622461         0.22522315        10.00000000 
#> 
#> $note
#> [1] "Interpret diagnostics jointly. Normality is mainly relevant to exact small-sample inference; heteroscedasticity can often be addressed with robust covariance or wild bootstrap without changing the mean model."
#> 

## mr_influence(): three examples
head(mr_influence(fit_soil))
#>   row   fitted   residual  rstandard   rstudent   leverage cooks_distance
#> 1   1 5.490345 -0.5511469 -0.8861909 -0.8856448 0.02627948   0.0042390351
#> 2   2 6.134232 -0.3361275 -0.5417124 -0.5406159 0.03077504   0.0018635524
#> 3   3 5.710687 -0.1083105 -0.1752858 -0.1747996 0.03882653   0.0002482276
#> 4   4 5.398272 -0.3328393 -0.5374526 -0.5363577 0.03452093   0.0020656180
#> 5   5 5.103849  0.7680779  1.2373762  1.2392689 0.03002367   0.0094784236
#> 6   6 5.791344 -0.2770606 -0.4487331 -0.4477068 0.04031801   0.0016919129
#>        dffits max_abs_dfbeta flag_leverage flag_cook flag_dffits flag_dfbeta
#> 1 -0.14549591     0.12376707         FALSE     FALSE       FALSE       FALSE
#> 2 -0.09633317     0.08452125         FALSE     FALSE       FALSE       FALSE
#> 3 -0.03513207     0.02231278         FALSE     FALSE       FALSE       FALSE
#> 4 -0.10142017     0.07530557         FALSE     FALSE       FALSE       FALSE
#> 5  0.21803031     0.14075874         FALSE     FALSE       FALSE       FALSE
#> 6 -0.09176554     0.06367622         FALSE     FALSE       FALSE       FALSE
head(mr_influence(mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad +
                           leaf_N_pct + root_mass_g, plant)))
#>   row   fitted   residual   rstandard    rstudent   leverage cooks_distance
#> 1   1 22.54514 -0.1333245 -0.08964872 -0.08936138 0.02734416   4.518805e-05
#> 2   2 27.97504 -1.1681824 -0.79065614 -0.78969560 0.03999526   5.208833e-03
#> 3   3 27.46301 -2.3918211 -1.62451787 -1.63323256 0.04668646   2.584843e-02
#> 4   4 24.77723  3.3400121  2.23492308  2.26448736 0.01780373   1.810789e-02
#> 5   5 23.99011 -0.3837988 -0.25639499 -0.25562079 0.01459331   1.947097e-04
#> 6   6 24.52759  1.4023775  0.93796639  0.93760050 0.01693393   3.030956e-03
#>        dffits max_abs_dfbeta flag_leverage flag_cook flag_dffits flag_dfbeta
#> 1 -0.01498313     0.01091341         FALSE     FALSE       FALSE       FALSE
#> 2 -0.16118599     0.13428892         FALSE     FALSE       FALSE       FALSE
#> 3 -0.36143119     0.31984652         FALSE      TRUE        TRUE        TRUE
#> 4  0.30487814     0.15322725         FALSE     FALSE       FALSE       FALSE
#> 5 -0.03110752     0.01930984         FALSE     FALSE       FALSE       FALSE
#> 6  0.12305673     0.09465873         FALSE     FALSE       FALSE       FALSE
head(mr_influence(mr_fit(grain_yield_t_ha ~ N_rate_kg_ha +
                           soil_water_m3_m3, het)))
#>   row   fitted   residual  rstandard   rstudent    leverage cooks_distance
#> 1   1 8.743829 -2.4894086 -1.4761848 -1.4811546 0.009409256   0.0068995568
#> 2   2 8.965150 -0.5646355 -0.3376836 -0.3368368 0.026132627   0.0010199570
#> 3   3 8.347052  0.9502909  0.5626313  0.5615421 0.006315123   0.0006705939
#> 4   4 8.984257 -0.9591855 -0.5693918 -0.5683018 0.011523966   0.0012599026
#> 5   5 7.908263  2.0872482  1.2361039  1.2379620 0.006834568   0.0035049203
#> 6   6 6.924983  0.1929469  0.1152407  0.1149190 0.023555312   0.0001067902
#>        dffits max_abs_dfbeta flag_leverage flag_cook flag_dffits flag_dfbeta
#> 1 -0.14435469     0.08017848         FALSE     FALSE       FALSE       FALSE
#> 2 -0.05517739     0.04893796         FALSE     FALSE       FALSE       FALSE
#> 3  0.04476606     0.01437235         FALSE     FALSE       FALSE       FALSE
#> 4 -0.06136164     0.04030026         FALSE     FALSE       FALSE       FALSE
#> 5  0.10269565     0.05907034         FALSE     FALSE       FALSE       FALSE
#> 6  0.01784894     0.01554388         FALSE     FALSE       FALSE       FALSE

## mr_collinearity(): three examples
mr_collinearity(mr_fit(yield_t_ha ~ ., coll))$VIF
#>                   term       VIF  tolerance flag_vif5 flag_vif10
#> 1         N_rate_kg_ha 11.449832 0.08733752      TRUE       TRUE
#> 2       N_uptake_kg_ha  8.485220 0.11785198      TRUE      FALSE
#> 3        canopy_N_g_m2  1.707740 0.58556922     FALSE      FALSE
#> 4                 NDVI  3.597993 0.27793270     FALSE      FALSE
#> 5       season_rain_mm  1.033892 0.96721862     FALSE      FALSE
#> 6 soil_mineral_N_mg_kg  1.024386 0.97619415     FALSE      FALSE
mr_collinearity(mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct +
                         clay_pct + CEC_cmolc_dm3, soil))$VIF
#>                 term      VIF tolerance flag_vif5 flag_vif10
#> 1            soil_pH 1.067081 0.9371357     FALSE      FALSE
#> 2 organic_matter_pct 1.583667 0.6314457     FALSE      FALSE
#> 3           clay_pct 3.651977 0.2738243     FALSE      FALSE
#> 4      CEC_cmolc_dm3 4.198189 0.2381979     FALSE      FALSE
mr_collinearity(mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad +
                         leaf_N_pct + plant_height_cm, plant))$VIF
#>               term      VIF tolerance flag_vif5 flag_vif10
#> 1    leaf_area_cm2 1.019349 0.9810179     FALSE      FALSE
#> 2 chlorophyll_spad 1.024345 0.9762332     FALSE      FALSE
#> 3       leaf_N_pct 1.004315 0.9957031     FALSE      FALSE
#> 4  plant_height_cm 1.015295 0.9849357     FALSE      FALSE

## mr_select(): three examples
mr_select(fit_soil, "aic")
#> multiRegFlow selection
#>  Method: aic 
#>  Selected: organic_matter_pct, available_P_mg_dm3, season_rain_mm 
mr_select(fit_soil, "bic")
#> multiRegFlow selection
#>  Method: bic 
#>  Selected: organic_matter_pct, available_P_mg_dm3, season_rain_mm 
if (requireNamespace("leaps", quietly = TRUE))
  mr_select(fit_soil, "best_subset")
#> multiRegFlow selection
#>  Method: best_subset 

## mr_regularize(): three examples
if (requireNamespace("glmnet", quietly = TRUE)) {
  fit_coll <- mr_fit(yield_t_ha ~ ., coll, goal = "prediction")
  mr_regularize(fit_coll, "ridge", nfolds = 5)
  mr_regularize(fit_coll, "lasso", nfolds = 5)
  mr_regularize(fit_coll, "elastic_net", alpha = 0.5, nfolds = 5)
}
#> multiRegFlow regularization
#>  Method: elastic_net 
#>  Lambda rule: 1se 
#>  Selected/nonzero predictors: 6 

## mr_bootstrap(): three examples
mr_bootstrap(fit_soil, R = 40, type = "pairs", seed = 1)
#> $type
#> [1] "pairs"
#> 
#> $interval
#> [1] "percentile"
#> 
#> $R
#> [1] 40
#> 
#> $successful_replicates
#> [1] 40
#> 
#> $coefficients
#>       (Intercept)       soil_pH organic_matter_pct available_P_mg_dm3
#>  [1,]    2.618756 -0.1199353879         0.19613354         0.03179479
#>  [2,]    2.776974 -0.0761202881         0.38496932         0.02229083
#>  [3,]    2.168374  0.0954869922         0.14277127         0.02439576
#>  [4,]    3.214905  0.0456169442         0.08349623         0.03221114
#>  [5,]    3.022366 -0.0872321841         0.07524469         0.03737192
#>  [6,]    2.119145 -0.0353870620         0.21833857         0.02240811
#>  [7,]    3.362287 -0.0529476933         0.12711412         0.02418784
#>  [8,]    2.340699  0.0824964219         0.21609573         0.02351069
#>  [9,]    3.591970 -0.0951173572         0.12155499         0.02665594
#> [10,]    2.126635 -0.0004478571         0.19765629         0.03371657
#> [11,]    2.561297 -0.0306184071         0.28430333         0.03402576
#> [12,]    2.750508 -0.0100554004         0.23548297         0.03042503
#> [13,]    2.816221 -0.0284676363         0.16493137         0.03107747
#> [14,]    2.757943 -0.0317686561         0.15612253         0.02847545
#> [15,]    2.985907 -0.0756465443         0.02430631         0.02867866
#> [16,]    2.051294  0.1118320752         0.16265011         0.02849123
#> [17,]    3.541994 -0.0386640234         0.05075727         0.02868891
#> [18,]    2.951452 -0.0478898012         0.17470818         0.03077886
#> [19,]    3.084309 -0.1219866521         0.14809160         0.02991372
#> [20,]    2.860243  0.0118715298         0.16597927         0.03000589
#> [21,]    3.050460  0.0122510679         0.07752064         0.02663483
#> [22,]    2.888010  0.0530058797         0.15902311         0.02524252
#> [23,]    2.215928  0.0653665619         0.22298998         0.02783324
#> [24,]    2.566358  0.0816500337         0.06152815         0.03003228
#> [25,]    2.671507 -0.1006207751         0.21604877         0.02845239
#> [26,]    1.731093  0.0540977980         0.17693001         0.03547370
#> [27,]    2.275744  0.0389142974         0.22221612         0.02469572
#> [28,]    2.625747 -0.1151173145         0.15734029         0.03353342
#> [29,]    2.796366  0.0267101302         0.20392679         0.01691623
#> [30,]    4.076884 -0.0541387742         0.15177164         0.01855402
#> [31,]    3.374225 -0.0815091932         0.19195529         0.03188770
#> [32,]    3.287547 -0.0358775699         0.06650384         0.03019272
#> [33,]    3.739472 -0.1498190486         0.11799554         0.03418351
#> [34,]    2.688969  0.0662537125         0.20326121         0.02793122
#> [35,]    3.029495 -0.1269715263         0.18707730         0.03162906
#> [36,]    2.173222  0.0826950061         0.19200122         0.02898179
#> [37,]    3.398197 -0.1905391463         0.30185498         0.03061567
#> [38,]    2.439698 -0.0100629266         0.12140893         0.03027360
#> [39,]    2.732474  0.0054395418         0.22693783         0.02969654
#> [40,]    2.559565  0.0758185277         0.15029951         0.02561293
#>       season_rain_mm
#>  [1,]    0.004305964
#>  [2,]    0.003244728
#>  [3,]    0.003506145
#>  [4,]    0.002211945
#>  [5,]    0.003679150
#>  [6,]    0.004517840
#>  [7,]    0.002952915
#>  [8,]    0.003023462
#>  [9,]    0.003102456
#> [10,]    0.003852599
#> [11,]    0.003205194
#> [12,]    0.002971384
#> [13,]    0.003218049
#> [14,]    0.003585003
#> [15,]    0.004078891
#> [16,]    0.003552208
#> [17,]    0.002749145
#> [18,]    0.003181689
#> [19,]    0.003778586
#> [20,]    0.002944082
#> [21,]    0.003072008
#> [22,]    0.002450289
#> [23,]    0.003189619
#> [24,]    0.003044510
#> [25,]    0.004060035
#> [26,]    0.004034556
#> [27,]    0.003397313
#> [28,]    0.004461103
#> [29,]    0.003101965
#> [30,]    0.001989804
#> [31,]    0.002781608
#> [32,]    0.002973953
#> [33,]    0.002999224
#> [34,]    0.002526267
#> [35,]    0.003699276
#> [36,]    0.003302694
#> [37,]    0.003400006
#> [38,]    0.003864098
#> [39,]    0.002845803
#> [40,]    0.002857909
#> 
#> $original
#>        (Intercept)            soil_pH organic_matter_pct available_P_mg_dm3 
#>        2.836102671       -0.030783358        0.162433941        0.028151382 
#>     season_rain_mm 
#>        0.003373274 
#> 
#> $intervals
#>                           lower       median       upper
#> (Intercept)         2.043289270  2.767458154 3.747906927
#> soil_pH            -0.150837051 -0.029543022 0.095895619
#> organic_matter_pct  0.050095997  0.165455320 0.303932835
#> available_P_mg_dm3  0.018513077  0.029339165 0.035521154
#> season_rain_mm      0.002206392  0.003197406 0.004462522
#> 
#> $sign_stability
#>        (Intercept)            soil_pH organic_matter_pct available_P_mg_dm3 
#>                1.0                0.6                1.0                1.0 
#>     season_rain_mm 
#>                1.0 
#> 
mr_bootstrap(fit_soil, R = 40, type = "residual", seed = 1)
#> $type
#> [1] "residual"
#> 
#> $interval
#> [1] "percentile"
#> 
#> $R
#> [1] 40
#> 
#> $successful_replicates
#> [1] 40
#> 
#> $coefficients
#>       (Intercept)      soil_pH organic_matter_pct available_P_mg_dm3
#>  [1,]    2.784893  0.062825030        0.178894840         0.03084319
#>  [2,]    3.443542 -0.173845135        0.265384458         0.02380976
#>  [3,]    4.091283 -0.131059630        0.058037736         0.02452094
#>  [4,]    2.566842 -0.047682774        0.220108321         0.03371605
#>  [5,]    2.728093 -0.032480044        0.166504902         0.02247263
#>  [6,]    3.082306 -0.097063550        0.192938364         0.01682539
#>  [7,]    2.034577  0.095257807        0.188539246         0.02893716
#>  [8,]    2.490857  0.016127699        0.207940584         0.02067667
#>  [9,]    3.637103 -0.087839825        0.181082952         0.03360840
#> [10,]    3.183584 -0.173091929        0.130942045         0.03273375
#> [11,]    2.415837  0.009020910        0.187040097         0.02741260
#> [12,]    3.753411 -0.116799510        0.109993510         0.02447417
#> [13,]    2.314628  0.022791748        0.137804194         0.02963406
#> [14,]    3.070813  0.015394100        0.137493326         0.02237081
#> [15,]    3.084825 -0.102903964        0.114520812         0.03405022
#> [16,]    2.273053 -0.013442435        0.211988761         0.03804504
#> [17,]    2.890342 -0.004255046        0.162936020         0.02238747
#> [18,]    3.620519 -0.156119219        0.172062856         0.02344251
#> [19,]    2.104008  0.011331036        0.199410506         0.02625319
#> [20,]    3.188696 -0.103958375        0.152360203         0.03035952
#> [21,]    2.256660 -0.005020617        0.178500145         0.02650961
#> [22,]    3.831851 -0.133100528        0.072183387         0.02384299
#> [23,]    3.574472 -0.003530213        0.106800405         0.02183048
#> [24,]    2.947626 -0.030663595        0.041126756         0.02648374
#> [25,]    4.511969 -0.242104523       -0.006913627         0.02619800
#> [26,]    3.038357 -0.037184218        0.101486663         0.03102826
#> [27,]    2.579979 -0.058038180        0.221475553         0.03610550
#> [28,]    3.263952 -0.053611019        0.158700304         0.03755360
#> [29,]    3.056296 -0.086328673        0.209711905         0.03450758
#> [30,]    2.856467 -0.086155315        0.253455341         0.02807598
#> [31,]    3.660530 -0.110387240        0.064214009         0.02759928
#> [32,]    2.664179  0.020261011        0.233762336         0.02997116
#> [33,]    3.816832 -0.159578889        0.073331497         0.02349418
#> [34,]    2.994798 -0.053997853        0.238362725         0.03472916
#> [35,]    2.703175 -0.013105555        0.093886610         0.03214616
#> [36,]    2.413586  0.055005451        0.075064550         0.03218852
#> [37,]    1.828308  0.141265694        0.161895687         0.02875377
#> [38,]    2.977809 -0.070500875        0.166813631         0.02258434
#> [39,]    3.504061 -0.146574565        0.206952987         0.02911310
#> [40,]    2.030356  0.060998632        0.127650457         0.02470181
#>       season_rain_mm
#>  [1,]    0.002406125
#>  [2,]    0.003456370
#>  [3,]    0.002861622
#>  [4,]    0.003588925
#>  [5,]    0.003783643
#>  [6,]    0.003841165
#>  [7,]    0.003304649
#>  [8,]    0.003524278
#>  [9,]    0.002518976
#> [10,]    0.004081624
#> [11,]    0.003615243
#> [12,]    0.003029447
#> [13,]    0.003681972
#> [14,]    0.002897043
#> [15,]    0.003678866
#> [16,]    0.003901084
#> [17,]    0.003250695
#> [18,]    0.003377742
#> [19,]    0.004009423
#> [20,]    0.003559868
#> [21,]    0.004130250
#> [22,]    0.003062167
#> [23,]    0.002291202
#> [24,]    0.003677251
#> [25,]    0.003329973
#> [26,]    0.003222826
#> [27,]    0.003457911
#> [28,]    0.002715103
#> [29,]    0.003188191
#> [30,]    0.003539553
#> [31,]    0.003200223
#> [32,]    0.002838164
#> [33,]    0.003483411
#> [34,]    0.002826971
#> [35,]    0.003471078
#> [36,]    0.003507905
#> [37,]    0.003351229
#> [38,]    0.003657065
#> [39,]    0.003138764
#> [40,]    0.003948658
#> 
#> $original
#>        (Intercept)            soil_pH organic_matter_pct available_P_mg_dm3 
#>        2.836102671       -0.030783358        0.162433941        0.028151382 
#>     season_rain_mm 
#>        0.003373274 
#> 
#> $intervals
#>                           lower       median       upper
#> (Intercept)         2.025304833  2.986303373 4.101800163
#> soil_pH            -0.175551620 -0.050646897 0.096408004
#> organic_matter_pct  0.039925746  0.164720461 0.253753569
#> available_P_mg_dm3  0.020580386  0.027837628 0.037565885
#> season_rain_mm      0.002403251  0.003457141 0.004082839
#> 
#> $sign_stability
#>        (Intercept)            soil_pH organic_matter_pct available_P_mg_dm3 
#>              1.000              0.725              0.975              1.000 
#>     season_rain_mm 
#>              1.000 
#> 
fit_het <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                    soil_water_m3_m3, het)
mr_bootstrap(fit_het, R = 40, type = "wild", seed = 1)
#> $type
#> [1] "wild"
#> 
#> $interval
#> [1] "percentile"
#> 
#> $R
#> [1] 40
#> 
#> $successful_replicates
#> [1] 40
#> 
#> $coefficients
#>       (Intercept) N_rate_kg_ha P_rate_kg_ha soil_water_m3_m3
#>  [1,]    2.174296   0.03666232   0.02600751        5.8577288
#>  [2,]    2.348877   0.03512673   0.03865637        3.8754194
#>  [3,]    3.728685   0.02684633   0.02352718        3.3839466
#>  [4,]    2.673095   0.03132827   0.03530750        4.5054260
#>  [5,]    2.428668   0.02869026   0.03904732        5.8687926
#>  [6,]    2.532555   0.02836074   0.03984487        5.4870627
#>  [7,]    3.365392   0.03453189   0.03196721        1.3571856
#>  [8,]    3.414770   0.02798328   0.02517617        3.9548506
#>  [9,]    2.662523   0.03083350   0.01351075        7.4760354
#> [10,]    4.003691   0.02205700   0.01803431        4.9523741
#> [11,]    3.710689   0.03125962   0.02404295        1.9174141
#> [12,]    4.981108   0.02473717   0.01879721        0.4111406
#> [13,]    2.469261   0.04323533   0.02750232        1.8133573
#> [14,]    3.410129   0.02709484   0.03146990        4.0970682
#> [15,]    1.376616   0.03524728   0.03919317        7.3807420
#> [16,]    2.878356   0.03337219   0.01996804        4.6149784
#> [17,]    3.865261   0.02962181   0.01399871        3.2184895
#> [18,]    2.960968   0.02860532   0.03599596        3.8471089
#> [19,]    3.347790   0.02847812   0.03997016        2.6161059
#> [20,]    3.218393   0.02145107   0.02744950        6.7344420
#> [21,]    2.289990   0.03135574   0.03408918        6.3143990
#> [22,]    3.350713   0.03651201   0.02047721        2.0151366
#> [23,]    2.796208   0.02922048   0.02480143        5.7808739
#> [24,]    2.831215   0.03044425   0.02027465        6.2890794
#> [25,]    4.235844   0.02995303   0.01837864        1.1444903
#> [26,]    3.028753   0.03549149   0.01708335        3.9952243
#> [27,]    2.683833   0.03405919   0.02254921        5.3171283
#> [28,]    3.236212   0.03122293   0.02325663        4.3686517
#> [29,]    2.898814   0.03352096   0.03746798        2.6817760
#> [30,]    2.785489   0.03399496   0.01227027        6.5379218
#> [31,]    3.269900   0.02533150   0.03929411        3.2184559
#> [32,]    1.435582   0.03375597   0.03603523        8.1150508
#> [33,]    2.842804   0.03673843   0.01916793        4.1631231
#> [34,]    3.156836   0.02862208   0.03263299        4.3114786
#> [35,]    2.948480   0.03276826   0.02121393        4.7342912
#> [36,]    1.953774   0.03606549   0.02643025        6.3490709
#> [37,]    4.867505   0.01767230   0.01662337        3.5857295
#> [38,]    3.169347   0.02388034   0.03382203        5.5842254
#> [39,]    3.379860   0.03072055   0.02213521        4.5165705
#> [40,]    3.093969   0.03005934   0.04080708        2.5931941
#> 
#> $original
#>      (Intercept)     N_rate_kg_ha     P_rate_kg_ha soil_water_m3_m3 
#>       3.05266424       0.02956894       0.02704581       4.82261205 
#> 
#> $intervals
#>                       lower     median      upper
#> (Intercept)      1.43410804 2.99486023 4.87034556
#> N_rate_kg_ha     0.02135660 0.03077703 0.03690086
#> P_rate_kg_ha     0.01347973 0.02559184 0.03999108
#> soil_water_m3_m3 1.12615653 4.34006516 7.49201076
#> 
#> $sign_stability
#>      (Intercept)     N_rate_kg_ha     P_rate_kg_ha soil_water_m3_m3 
#>                1                1                1                1 
#> 

## mr_validate(): three examples
mr_validate(fit_plant, v = 5, repeats = 2, seed = 2)
#> $engine
#> [1] "ols"
#> 
#> $metrics
#>       RMSE      MAE        R2 calibration_intercept calibration_slope
#> 1 1.536366 1.242532 0.6060566             0.3830175         0.9846067
#> 2 1.553873 1.244327 0.5970270             0.5427819         0.9767929
#> 
#> $summary
#>                  metric      mean          sd
#> 1                  RMSE 1.5451195 0.012379837
#> 2                   MAE 1.2434296 0.001269765
#> 3                    R2 0.6015418 0.006384865
#> 4 calibration_intercept 0.4628997 0.112970528
#> 5     calibration_slope 0.9806998 0.005525189
#> 
#> $predictions
#>     repeat_id row observed predicted fold
#> 1           1   1 22.41182  23.21080    5
#> 2           1   2 26.80686  27.83061    1
#> 3           1   3 25.07119  27.74792    1
#> 4           1   4 28.11724  25.61813    2
#> 5           1   5 23.60631  23.69381    3
#> 6           1   6 25.92997  24.49046    5
#> 7           1   7 25.77742  26.23370    1
#> 8           1   8 22.44699  25.65606    5
#> 9           1   9 20.79576  22.72127    1
#> 10          1  10 25.03119  22.49330    5
#> 11          1  11 23.77480  25.10858    5
#> 12          1  12 23.79652  23.59859    5
#> 13          1  13 24.17288  25.27748    3
#> 14          1  14 21.29441  20.80288    3
#> 15          1  15 28.86988  26.49764    3
#> 16          1  16 20.31914  22.52473    4
#> 17          1  17 22.64335  22.43778    5
#> 18          1  18 26.04337  26.46729    2
#> 19          1  19 28.87560  28.65647    3
#> 20          1  20 19.67847  21.94241    4
#> 21          1  21 19.24391  22.02125    5
#> 22          1  22 24.53155  24.10285    5
#> 23          1  23 25.63993  23.33738    4
#> 24          1  24 19.60559  20.97527    3
#> 25          1  25 22.71452  22.79896    4
#> 26          1  26 24.71388  23.02276    4
#> 27          1  27 21.68105  22.50664    5
#> 28          1  28 27.15096  24.96399    4
#> 29          1  29 24.34199  25.93029    5
#> 30          1  30 23.91962  24.41990    5
#> 31          1  31 18.05816  20.31523    3
#> 32          1  32 23.51181  23.90280    4
#> 33          1  33 17.55590  19.85300    2
#> 34          1  34 24.43231  24.90607    3
#> 35          1  35 25.90299  25.38462    4
#> 36          1  36 25.90478  24.30102    4
#> 37          1  37 25.96247  24.38303    4
#> 38          1  38 23.50240  24.91924    1
#> 39          1  39 24.28014  24.87863    3
#> 40          1  40 24.96532  23.88368    3
#> 41          1  41 26.22167  25.01783    1
#> 42          1  42 20.74047  20.09771    4
#> 43          1  43 25.15682  23.95796    3
#> 44          1  44 22.54454  20.96911    2
#> 45          1  45 24.14087  23.69373    3
#> 46          1  46 26.42844  25.60734    1
#> 47          1  47 26.53514  25.21225    2
#> 48          1  48 28.70370  25.85501    1
#> 49          1  49 21.19727  23.18433    2
#> 50          1  50 22.09439  23.40022    3
#> 51          1  51 23.11179  23.67281    4
#> 52          1  52 25.52051  24.88138    5
#> 53          1  53 24.86610  24.40124    3
#> 54          1  54 20.08671  20.89771    3
#> 55          1  55 26.41460  25.76319    2
#> 56          1  56 27.88381  26.41867    2
#> 57          1  57 24.43818  25.22289    1
#> 58          1  58 22.18398  22.66274    5
#> 59          1  59 21.60163  23.66972    5
#> 60          1  60 24.64768  23.94406    1
#> 61          1  61 19.27967  22.12120    1
#> 62          1  62 18.95690  20.02237    5
#> 63          1  63 26.89042  25.33853    3
#> 64          1  64 23.89414  23.94737    5
#> 65          1  65 26.62329  24.00389    2
#> 66          1  66 24.64524  24.06045    1
#> 67          1  67 22.63950  22.80164    4
#> 68          1  68 18.06853  20.94587    1
#> 69          1  69 20.63143  22.33813    5
#> 70          1  70 23.08025  23.00211    2
#> 71          1  71 22.99665  22.64779    1
#> 72          1  72 24.35237  24.80540    3
#> 73          1  73 23.75258  24.46802    4
#> 74          1  74 28.11860  31.17361    5
#> 75          1  75 24.68952  26.62517    2
#> 76          1  76 25.39659  23.20309    2
#> 77          1  77 22.20035  22.17868    5
#> 78          1  78 25.44187  25.40954    5
#> 79          1  79 26.66016  25.32296    1
#> 80          1  80 25.92727  24.46195    3
#> 81          1  81 23.33478  22.68993    4
#> 82          1  82 22.03760  22.30216    3
#> 83          1  83 23.08411  22.45350    3
#> 84          1  84 21.93572  24.96290    1
#> 85          1  85 25.22972  25.01943    5
#> 86          1  86 25.42363  22.59115    4
#> 87          1  87 23.65320  25.26774    4
#> 88          1  88 20.49997  21.19515    3
#> 89          1  89 24.00390  24.72112    3
#> 90          1  90 26.12961  26.92861    2
#> 91          1  91 25.36425  24.40961    1
#> 92          1  92 21.96269  20.44454    2
#> 93          1  93 30.28524  28.24580    2
#> 94          1  94 25.05258  24.94659    1
#> 95          1  95 24.18269  26.63163    2
#> 96          1  96 24.98005  24.30232    4
#> 97          1  97 21.48561  22.31445    2
#> 98          1  98 21.66926  21.53879    3
#> 99          1  99 23.98240  22.72530    2
#> 100         1 100 26.72208  25.16064    1
#> 101         1 101 24.19443  25.60732    1
#> 102         1 102 26.20054  24.67772    5
#> 103         1 103 24.04847  23.88516    2
#> 104         1 104 19.08342  22.19230    1
#> 105         1 105 22.79971  23.59431    2
#> 106         1 106 26.37800  23.97041    2
#> 107         1 107 28.34845  28.37247    2
#> 108         1 108 26.63972  25.65364    3
#> 109         1 109 29.57602  26.92475    4
#> 110         1 110 26.77669  25.36908    4
#> 111         1 111 22.57510  22.74919    3
#> 112         1 112 26.71122  25.72920    2
#> 113         1 113 29.17712  27.23243    3
#> 114         1 114 25.40770  25.29338    1
#> 115         1 115 23.97614  24.55771    2
#> 116         1 116 25.35321  23.62770    1
#> 117         1 117 23.97708  25.48441    3
#> 118         1 118 26.96643  23.80460    2
#> 119         1 119 22.52570  22.72848    3
#> 120         1 120 26.70791  26.49502    1
#> 121         1 121 22.96063  23.95820    1
#> 122         1 122 23.48409  25.34389    2
#> 123         1 123 21.93462  22.76999    1
#> 124         1 124 25.93696  25.56342    1
#> 125         1 125 26.56140  26.13579    4
#> 126         1 126 20.84851  23.65196    5
#> 127         1 127 25.67349  23.36594    4
#> 128         1 128 24.38638  24.40710    3
#> 129         1 129 23.50704  23.19646    5
#> 130         1 130 25.64396  24.17629    5
#> 131         1 131 26.84396  25.29379    3
#> 132         1 132 25.72286  25.46112    1
#> 133         1 133 24.23717  26.58657    3
#> 134         1 134 26.09437  26.37875    2
#> 135         1 135 23.80984  20.82190    4
#> 136         1 136 20.14092  22.49007    5
#> 137         1 137 18.85255  21.09908    4
#> 138         1 138 24.94896  27.54885    5
#> 139         1 139 26.75322  27.22441    1
#> 140         1 140 22.32229  22.96300    1
#> 141         1 141 25.86929  23.07774    5
#> 142         1 142 24.09914  23.44163    2
#> 143         1 143 22.83740  26.43087    2
#> 144         1 144 25.23536  24.78514    2
#> 145         1 145 21.18169  20.66120    5
#> 146         1 146 23.27709  24.18358    4
#> 147         1 147 22.09217  21.23253    4
#> 148         1 148 25.60137  24.21271    4
#> 149         1 149 22.87981  24.17266    2
#> 150         1 150 24.01264  23.49160    1
#> 151         1 151 26.84773  24.50124    5
#> 152         1 152 24.65142  23.85741    5
#> 153         1 153 26.49771  27.72820    4
#> 154         1 154 21.71253  22.09251    4
#> 155         1 155 23.49304  21.63904    4
#> 156         1 156 23.26232  21.90185    4
#> 157         1 157 23.49575  21.99130    2
#> 158         1 158 23.25563  23.48626    3
#> 159         1 159 22.44618  22.22835    4
#> 160         1 160 23.95583  24.14796    1
#> 161         2   1 22.41182  23.12519    5
#> 162         2   2 26.80686  27.85321    5
#> 163         2   3 25.07119  28.09695    1
#> 164         2   4 28.11724  25.40627    2
#> 165         2   5 23.60631  23.54404    1
#> 166         2   6 25.92997  24.44476    5
#> 167         2   7 25.77742  26.30513    4
#> 168         2   8 22.44699  26.02851    3
#> 169         2   9 20.79576  22.69669    4
#> 170         2  10 25.03119  22.45063    1
#> 171         2  11 23.77480  24.90576    2
#> 172         2  12 23.79652  24.01349    3
#> 173         2  13 24.17288  25.25856    5
#> 174         2  14 21.29441  20.79027    2
#> 175         2  15 28.86988  26.45876    2
#> 176         2  16 20.31914  22.65973    5
#> 177         2  17 22.64335  22.32959    3
#> 178         2  18 26.04337  26.65731    3
#> 179         2  19 28.87560  28.64205    2
#> 180         2  20 19.67847  22.15964    5
#> 181         2  21 19.24391  22.06355    2
#> 182         2  22 24.53155  24.09348    5
#> 183         2  23 25.63993  23.35164    1
#> 184         2  24 19.60559  21.00403    5
#> 185         2  25 22.71452  22.85696    4
#> 186         2  26 24.71388  23.20261    5
#> 187         2  27 21.68105  22.50491    4
#> 188         2  28 27.15096  25.11416    2
#> 189         2  29 24.34199  25.87914    1
#> 190         2  30 23.91962  23.88368    2
#> 191         2  31 18.05816  20.46238    2
#> 192         2  32 23.51181  24.11316    1
#> 193         2  33 17.55590  20.21210    4
#> 194         2  34 24.43231  24.81700    4
#> 195         2  35 25.90299  25.39224    3
#> 196         2  36 25.90478  24.39922    5
#> 197         2  37 25.96247  24.03282    3
#> 198         2  38 23.50240  24.87219    3
#> 199         2  39 24.28014  24.95473    4
#> 200         2  40 24.96532  24.02550    3
#> 201         2  41 26.22167  25.30756    1
#> 202         2  42 20.74047  20.20195    2
#> 203         2  43 25.15682  23.75882    1
#> 204         2  44 22.54454  21.01520    4
#> 205         2  45 24.14087  23.67857    4
#> 206         2  46 26.42844  25.74976    2
#> 207         2  47 26.53514  25.10434    3
#> 208         2  48 28.70370  25.83329    5
#> 209         2  49 21.19727  23.42195    4
#> 210         2  50 22.09439  23.41912    5
#> 211         2  51 23.11179  24.01565    4
#> 212         2  52 25.52051  24.90584    5
#> 213         2  53 24.86610  24.46927    4
#> 214         2  54 20.08671  20.62395    1
#> 215         2  55 26.41460  25.75941    5
#> 216         2  56 27.88381  26.35491    2
#> 217         2  57 24.43818  25.40790    3
#> 218         2  58 22.18398  22.59591    3
#> 219         2  59 21.60163  24.16803    3
#> 220         2  60 24.64768  24.14792    3
#> 221         2  61 19.27967  22.18092    2
#> 222         2  62 18.95690  20.44387    4
#> 223         2  63 26.89042  25.81515    1
#> 224         2  64 23.89414  24.01578    2
#> 225         2  65 26.62329  23.88129    2
#> 226         2  66 24.64524  23.97510    3
#> 227         2  67 22.63950  23.05793    3
#> 228         2  68 18.06853  20.11994    1
#> 229         2  69 20.63143  21.90010    2
#> 230         2  70 23.08025  23.35441    2
#> 231         2  71 22.99665  22.84751    1
#> 232         2  72 24.35237  24.78216    3
#> 233         2  73 23.75258  24.61870    1
#> 234         2  74 28.11860  30.90885    5
#> 235         2  75 24.68952  26.78338    1
#> 236         2  76 25.39659  23.26316    2
#> 237         2  77 22.20035  22.44843    2
#> 238         2  78 25.44187  25.38955    3
#> 239         2  79 26.66016  24.83262    3
#> 240         2  80 25.92727  24.27743    1
#> 241         2  81 23.33478  22.84394    4
#> 242         2  82 22.03760  22.06518    1
#> 243         2  83 23.08411  22.59372    2
#> 244         2  84 21.93572  25.08646    4
#> 245         2  85 25.22972  24.83818    3
#> 246         2  86 25.42363  22.58467    1
#> 247         2  87 23.65320  25.51730    1
#> 248         2  88 20.49997  21.11983    4
#> 249         2  89 24.00390  24.85727    5
#> 250         2  90 26.12961  26.89481    2
#> 251         2  91 25.36425  24.34193    2
#> 252         2  92 21.96269  20.56929    4
#> 253         2  93 30.28524  28.37109    1
#> 254         2  94 25.05258  24.91156    2
#> 255         2  95 24.18269  26.74337    1
#> 256         2  96 24.98005  24.46549    5
#> 257         2  97 21.48561  22.24490    5
#> 258         2  98 21.66926  21.77491    3
#> 259         2  99 23.98240  22.86164    3
#> 260         2 100 26.72208  25.00601    2
#> 261         2 101 24.19443  25.51043    2
#> 262         2 102 26.20054  24.57164    2
#> 263         2 103 24.04847  23.64802    4
#> 264         2 104 19.08342  22.21551    2
#> 265         2 105 22.79971  23.36648    3
#> 266         2 106 26.37800  23.94211    1
#> 267         2 107 28.34845  28.65371    1
#> 268         2 108 26.63972  25.70045    4
#> 269         2 109 29.57602  26.63947    3
#> 270         2 110 26.77669  25.38028    1
#> 271         2 111 22.57510  22.53886    5
#> 272         2 112 26.71122  25.93394    5
#> 273         2 113 29.17712  27.19697    3
#> 274         2 114 25.40770  25.65432    3
#> 275         2 115 23.97614  24.55319    4
#> 276         2 116 25.35321  23.77261    4
#> 277         2 117 23.97708  25.58132    5
#> 278         2 118 26.96643  23.75705    3
#> 279         2 119 22.52570  22.53651    4
#> 280         2 120 26.70791  26.57964    4
#> 281         2 121 22.96063  23.85762    1
#> 282         2 122 23.48409  25.52893    3
#> 283         2 123 21.93462  22.58870    4
#> 284         2 124 25.93696  25.59250    4
#> 285         2 125 26.56140  26.34541    3
#> 286         2 126 20.84851  23.52976    5
#> 287         2 127 25.67349  23.66096    4
#> 288         2 128 24.38638  24.45506    5
#> 289         2 129 23.50704  23.52922    4
#> 290         2 130 25.64396  24.26732    5
#> 291         2 131 26.84396  25.17155    3
#> 292         2 132 25.72286  25.28659    5
#> 293         2 133 24.23717  26.73537    1
#> 294         2 134 26.09437  26.37504    5
#> 295         2 135 23.80984  21.02081    2
#> 296         2 136 20.14092  22.27870    2
#> 297         2 137 18.85255  21.26959    5
#> 298         2 138 24.94896  27.48769    1
#> 299         2 139 26.75322  27.13911    2
#> 300         2 140 22.32229  22.87105    2
#> 301         2 141 25.86929  22.99611    1
#> 302         2 142 24.09914  23.34731    1
#> 303         2 143 22.83740  26.52708    4
#> 304         2 144 25.23536  24.89010    5
#> 305         2 145 21.18169  20.47008    1
#> 306         2 146 23.27709  24.15668    1
#> 307         2 147 22.09217  21.79761    3
#> 308         2 148 25.60137  24.33774    5
#> 309         2 149 22.87981  24.13872    1
#> 310         2 150 24.01264  23.29999    3
#> 311         2 151 26.84773  24.83462    4
#> 312         2 152 24.65142  23.64902    4
#> 313         2 153 26.49771  27.78429    2
#> 314         2 154 21.71253  22.24118    4
#> 315         2 155 23.49304  21.81579    1
#> 316         2 156 23.26232  22.08681    5
#> 317         2 157 23.49575  21.86013    3
#> 318         2 158 23.25563  23.35424    5
#> 319         2 159 22.44618  22.37410    5
#> 320         2 160 23.95583  24.12494    4
#> 
mr_validate(mr_fit(yield_t_ha ~ available_P_mg_dm3 + season_rain_mm,
                   soil, goal = "prediction"), v = 5, repeats = 2)
#> $engine
#> [1] "ols"
#> 
#> $metrics
#>        RMSE       MAE        R2 calibration_intercept calibration_slope
#> 1 0.6488352 0.5294399 0.2319821             0.4193648         0.9263472
#> 2 0.6524490 0.5278963 0.2234030             0.2719507         0.9530820
#> 
#> $summary
#>                  metric      mean          sd
#> 1                  RMSE 0.6506421 0.002555357
#> 2                   MAE 0.5286681 0.001091486
#> 3                    R2 0.2276926 0.006066334
#> 4 calibration_intercept 0.3456578 0.104237504
#> 5     calibration_slope 0.9397146 0.018904368
#> 
#> $predictions
#>     repeat_id row observed predicted fold
#> 1           1   1 4.939198  5.745473    4
#> 2           1   2 5.798104  5.930020    4
#> 3           1   3 5.602376  5.859625    4
#> 4           1   4 5.065433  5.601201    5
#> 5           1   5 5.871927  5.254714    5
#> 6           1   6 5.514284  5.717487    3
#> 7           1   7 5.851728  5.620760    3
#> 8           1   8 5.364920  5.484091    3
#> 9           1   9 5.852153  5.352072    5
#> 10          1  10 5.591235  5.180473    3
#> 11          1  11 6.605647  5.684829    5
#> 12          1  12 7.583648  6.453733    1
#> 13          1  13 4.662510  5.337272    4
#> 14          1  14 6.206253  5.485998    2
#> 15          1  15 5.316954  5.920406    2
#> 16          1  16 5.913828  5.353537    4
#> 17          1  17 4.046035  5.072099    2
#> 18          1  18 6.222517  5.822339    1
#> 19          1  19 4.658313  5.520372    2
#> 20          1  20 5.250913  5.508220    1
#> 21          1  21 5.670414  5.715034    3
#> 22          1  22 5.544096  5.624917    1
#> 23          1  23 6.114875  5.731096    4
#> 24          1  24 4.867752  5.651025    3
#> 25          1  25 5.096588  5.137396    2
#> 26          1  26 5.220699  5.734979    1
#> 27          1  27 5.346507  5.278852    3
#> 28          1  28 5.237903  5.665062    2
#> 29          1  29 6.236574  5.687152    4
#> 30          1  30 6.893790  5.341575    2
#> 31          1  31 6.434967  5.423030    1
#> 32          1  32 5.463787  5.364857    4
#> 33          1  33 6.408455  5.862491    3
#> 34          1  34 6.333603  5.905301    3
#> 35          1  35 6.248702  5.285603    5
#> 36          1  36 6.428993  5.998558    2
#> 37          1  37 5.475336  6.056397    4
#> 38          1  38 4.639346  5.852510    4
#> 39          1  39 5.832726  5.529845    4
#> 40          1  40 6.609886  6.095556    5
#> 41          1  41 5.930253  6.144517    3
#> 42          1  42 5.258983  5.839594    2
#> 43          1  43 6.536572  6.226781    3
#> 44          1  44 6.924322  6.016646    3
#> 45          1  45 6.121401  5.469016    1
#> 46          1  46 4.917306  5.964166    1
#> 47          1  47 5.427672  6.118115    2
#> 48          1  48 6.928071  6.049616    5
#> 49          1  49 5.653534  6.675731    1
#> 50          1  50 6.021198  6.336945    1
#> 51          1  51 5.913185  5.857854    4
#> 52          1  52 6.044798  6.219381    1
#> 53          1  53 6.113975  5.925397    2
#> 54          1  54 5.900847  5.340363    2
#> 55          1  55 5.030346  5.460551    1
#> 56          1  56 6.543253  6.461995    1
#> 57          1  57 6.795038  5.591829    4
#> 58          1  58 6.089722  5.360948    1
#> 59          1  59 6.355546  6.224681    2
#> 60          1  60 5.720449  5.464186    5
#> 61          1  61 5.944408  5.993996    2
#> 62          1  62 4.860117  5.202189    1
#> 63          1  63 5.431398  5.701035    3
#> 64          1  64 7.201589  6.046084    4
#> 65          1  65 4.815417  5.488083    4
#> 66          1  66 6.537757  5.660292    3
#> 67          1  67 4.988087  5.475138    4
#> 68          1  68 6.640067  5.676805    5
#> 69          1  69 5.981617  5.417230    2
#> 70          1  70 6.117960  5.330986    2
#> 71          1  71 6.336132  6.093642    4
#> 72          1  72 5.539478  5.477370    1
#> 73          1  73 4.754780  5.308068    5
#> 74          1  74 4.825065  5.663152    2
#> 75          1  75 3.476143  4.954801    5
#> 76          1  76 6.326056  5.803252    5
#> 77          1  77 4.502561  5.476068    5
#> 78          1  78 6.878785  5.728815    2
#> 79          1  79 5.030191  5.249224    3
#> 80          1  80 5.453428  5.584329    4
#> 81          1  81 5.638679  5.778754    4
#> 82          1  82 6.763106  5.297414    5
#> 83          1  83 6.402685  6.141162    3
#> 84          1  84 6.093523  5.820962    3
#> 85          1  85 5.898955  5.466657    1
#> 86          1  86 5.564612  5.096038    1
#> 87          1  87 5.816766  5.592864    2
#> 88          1  88 5.686574  5.992874    3
#> 89          1  89 5.841397  5.867143    4
#> 90          1  90 5.537686  5.401485    5
#> 91          1  91 7.090994  6.530063    2
#> 92          1  92 5.233623  5.250375    3
#> 93          1  93 5.292859  5.041539    1
#> 94          1  94 6.214618  5.784764    4
#> 95          1  95 4.911464  5.682631    4
#> 96          1  96 4.981423  5.786806    3
#> 97          1  97 5.461556  5.113821    1
#> 98          1  98 6.609792  6.345083    1
#> 99          1  99 6.000058  6.409888    2
#> 100         1 100 6.627055  6.030240    2
#> 101         1 101 5.758504  5.708396    3
#> 102         1 102 5.065547  5.933180    4
#> 103         1 103 5.151923  5.836070    1
#> 104         1 104 6.431169  5.936052    4
#> 105         1 105 6.001664  5.559024    1
#> 106         1 106 4.138091  5.902240    4
#> 107         1 107 4.884037  5.104034    3
#> 108         1 108 4.281146  5.310021    2
#> 109         1 109 5.536728  5.601732    4
#> 110         1 110 4.996235  5.628427    2
#> 111         1 111 4.994031  5.657590    2
#> 112         1 112 5.649955  5.690428    5
#> 113         1 113 5.638735  5.712208    2
#> 114         1 114 7.315040  5.969509    2
#> 115         1 115 4.019124  5.250791    3
#> 116         1 116 4.961592  4.555057    1
#> 117         1 117 6.830958  6.119776    5
#> 118         1 118 5.042938  4.696307    1
#> 119         1 119 5.044598  6.099771    1
#> 120         1 120 5.983188  5.594643    4
#> 121         1 121 5.231042  5.598521    5
#> 122         1 122 4.909280  6.128105    4
#> 123         1 123 6.310244  5.825287    3
#> 124         1 124 5.374605  5.964167    4
#> 125         1 125 5.523180  5.729091    2
#> 126         1 126 7.177627  6.411016    3
#> 127         1 127 4.782879  5.699148    4
#> 128         1 128 4.705411  6.155313    2
#> 129         1 129 4.881421  5.617742    1
#> 130         1 130 7.500817  6.242190    3
#> 131         1 131 5.395582  5.711131    5
#> 132         1 132 5.093581  6.318046    4
#> 133         1 133 6.360572  6.120618    2
#> 134         1 134 7.114395  6.217357    2
#> 135         1 135 5.175158  5.215338    1
#> 136         1 136 5.929238  5.209730    1
#> 137         1 137 5.924123  6.124922    5
#> 138         1 138 6.696935  7.319416    1
#> 139         1 139 6.040244  5.876306    3
#> 140         1 140 6.847536  6.216954    3
#> 141         1 141 6.056635  5.668284    3
#> 142         1 142 4.145973  4.861784    5
#> 143         1 143 5.152939  5.124100    5
#> 144         1 144 5.494881  5.763322    5
#> 145         1 145 5.288232  5.591966    3
#> 146         1 146 5.833346  5.728483    4
#> 147         1 147 5.676299  5.651492    1
#> 148         1 148 5.646776  5.919965    4
#> 149         1 149 6.577196  5.544722    5
#> 150         1 150 5.934330  5.655882    1
#> 151         1 151 4.898486  5.133084    5
#> 152         1 152 4.679498  5.630415    5
#> 153         1 153 6.015211  5.685874    3
#> 154         1 154 6.205859  5.240860    5
#> 155         1 155 6.049681  5.511223    5
#> 156         1 156 6.276490  5.590141    2
#> 157         1 157 5.799449  5.631854    1
#> 158         1 158 5.114991  5.121271    5
#> 159         1 159 5.675410  5.128781    3
#> 160         1 160 5.692827  5.660129    4
#> 161         1 161 5.618321  5.037977    5
#> 162         1 162 6.077596  5.601900    2
#> 163         1 163 5.584680  5.758536    3
#> 164         1 164 5.185227  5.655993    5
#> 165         1 165 5.686728  5.252320    2
#> 166         1 166 5.934752  5.998780    2
#> 167         1 167 5.245855  5.628711    4
#> 168         1 168 5.577539  5.951444    5
#> 169         1 169 4.510884  5.382797    5
#> 170         1 170 6.581184  6.209181    3
#> 171         1 171 4.385403  5.432438    3
#> 172         1 172 5.273457  5.700131    1
#> 173         1 173 5.262497  5.352598    5
#> 174         1 174 6.915840  5.878002    2
#> 175         1 175 4.999738  5.196569    5
#> 176         1 176 5.538645  5.528260    5
#> 177         1 177 5.149902  5.598888    4
#> 178         1 178 5.478543  5.997687    1
#> 179         1 179 4.305566  5.382685    3
#> 180         1 180 5.541663  5.891915    1
#> 181         2   1 4.939198  5.710539    5
#> 182         2   2 5.798104  5.857628    2
#> 183         2   3 5.602376  5.808472    5
#> 184         2   4 5.065433  5.636170    5
#> 185         2   5 5.871927  5.233659    4
#> 186         2   6 5.514284  5.560482    3
#> 187         2   7 5.851728  5.608236    4
#> 188         2   8 5.364920  5.518312    1
#> 189         2   9 5.852153  5.305376    3
#> 190         2  10 5.591235  5.136235    1
#> 191         2  11 6.605647  5.721032    5
#> 192         2  12 7.583648  6.135827    2
#> 193         2  13 4.662510  5.313319    5
#> 194         2  14 6.206253  5.527694    1
#> 195         2  15 5.316954  5.932743    5
#> 196         2  16 5.913828  5.248114    3
#> 197         2  17 4.046035  5.224371    2
#> 198         2  18 6.222517  5.807469    5
#> 199         2  19 4.658313  5.509566    4
#> 200         2  20 5.250913  5.545240    1
#> 201         2  21 5.670414  5.705778    5
#> 202         2  22 5.544096  5.654461    1
#> 203         2  23 6.114875  5.710742    1
#> 204         2  24 4.867752  5.637534    4
#> 205         2  25 5.096588  5.144991    1
#> 206         2  26 5.220699  5.697691    2
#> 207         2  27 5.346507  5.232788    2
#> 208         2  28 5.237903  5.689971    5
#> 209         2  29 6.236574  5.543109    3
#> 210         2  30 6.893790  5.306283    3
#> 211         2  31 6.434967  5.381014    3
#> 212         2  32 5.463787  5.449831    2
#> 213         2  33 6.408455  5.958292    1
#> 214         2  34 6.333603  5.926856    4
#> 215         2  35 6.248702  5.301206    1
#> 216         2  36 6.428993  6.030338    5
#> 217         2  37 5.475336  6.003915    2
#> 218         2  38 4.639346  5.811176    5
#> 219         2  39 5.832726  5.522542    1
#> 220         2  40 6.609886  5.969781    3
#> 221         2  41 5.930253  6.312438    1
#> 222         2  42 5.258983  5.872309    5
#> 223         2  43 6.536572  6.320314    2
#> 224         2  44 6.924322  5.926470    3
#> 225         2  45 6.121401  5.484567    4
#> 226         2  46 4.917306  5.862622    3
#> 227         2  47 5.427672  6.156002    5
#> 228         2  48 6.928071  6.074206    5
#> 229         2  49 5.653534  6.419050    2
#> 230         2  50 6.021198  6.229789    2
#> 231         2  51 5.913185  5.845572    1
#> 232         2  52 6.044798  6.162382    4
#> 233         2  53 6.113975  5.946901    4
#> 234         2  54 5.900847  5.356750    5
#> 235         2  55 5.030346  5.500332    1
#> 236         2  56 6.543253  6.199676    3
#> 237         2  57 6.795038  5.541820    4
#> 238         2  58 6.089722  5.338975    3
#> 239         2  59 6.355546  6.256980    5
#> 240         2  60 5.720449  5.499439    1
#> 241         2  61 5.944408  5.986988    2
#> 242         2  62 4.860117  5.350203    2
#> 243         2  63 5.431398  5.772777    2
#> 244         2  64 7.201589  5.971109    2
#> 245         2  65 4.815417  5.489437    1
#> 246         2  66 6.537757  5.516132    3
#> 247         2  67 4.988087  5.441996    3
#> 248         2  68 6.640067  5.757233    2
#> 249         2  69 5.981617  5.444962    1
#> 250         2  70 6.117960  5.331894    5
#> 251         2  71 6.336132  6.081466    3
#> 252         2  72 5.539478  5.501518    5
#> 253         2  73 4.754780  5.282488    4
#> 254         2  74 4.825065  5.667989    3
#> 255         2  75 3.476143  4.943448    1
#> 256         2  76 6.326056  5.820646    4
#> 257         2  77 4.502561  5.500103    1
#> 258         2  78 6.878785  5.749399    4
#> 259         2  79 5.030191  5.201741    1
#> 260         2  80 5.453428  5.626009    2
#> 261         2  81 5.638679  5.712855    2
#> 262         2  82 6.763106  5.312902    1
#> 263         2  83 6.402685  6.301227    5
#> 264         2  84 6.093523  5.836641    5
#> 265         2  85 5.898955  5.477158    3
#> 266         2  86 5.564612  5.162678    5
#> 267         2  87 5.816766  5.610196    5
#> 268         2  88 5.686574  6.022548    4
#> 269         2  89 5.841397  5.835648    5
#> 270         2  90 5.537686  5.422334    3
#> 271         2  91 7.090994  6.423874    3
#> 272         2  92 5.233623  5.179179    5
#> 273         2  93 5.292859  5.117038    5
#> 274         2  94 6.214618  5.734050    4
#> 275         2  95 4.911464  5.647234    5
#> 276         2  96 4.981423  5.824141    4
#> 277         2  97 5.461556  5.206020    1
#> 278         2  98 6.609792  6.290658    1
#> 279         2  99 6.000058  6.455446    4
#> 280         2 100 6.627055  6.045246    4
#> 281         2 101 5.758504  5.696081    5
#> 282         2 102 5.065547  5.988260    2
#> 283         2 103 5.151923  5.878050    2
#> 284         2 104 6.431169  5.879610    4
#> 285         2 105 6.001664  5.669925    2
#> 286         2 106 4.138091  5.853789    4
#> 287         2 107 4.884037  5.030571    1
#> 288         2 108 4.281146  5.380997    3
#> 289         2 109 5.536728  5.546843    4
#> 290         2 110 4.996235  5.640321    2
#> 291         2 111 4.994031  5.709214    1
#> 292         2 112 5.649955  5.713163    4
#> 293         2 113 5.638735  5.728727    4
#> 294         2 114 7.315040  6.015964    1
#> 295         2 115 4.019124  5.207216    1
#> 296         2 116 4.961592  4.715041    3
#> 297         2 117 6.830958  6.177844    4
#> 298         2 118 5.042938  4.877071    2
#> 299         2 119 5.044598  5.984927    3
#> 300         2 120 5.983188  5.602286    2
#> 301         2 121 5.231042  5.630507    5
#> 302         2 122 4.909280  6.098988    1
#> 303         2 123 6.310244  5.879244    3
#> 304         2 124 5.374605  5.942102    1
#> 305         2 125 5.523180  5.761306    5
#> 306         2 126 7.177627  6.345224    2
#> 307         2 127 4.782879  5.638429    4
#> 308         2 128 4.705411  6.229413    1
#> 309         2 129 4.881421  5.695900    3
#> 310         2 130 7.500817  6.269052    2
#> 311         2 131 5.395582  5.736901    4
#> 312         2 132 5.093581  6.270188    1
#> 313         2 133 6.360572  6.170293    4
#> 314         2 134 7.114395  6.263325    1
#> 315         2 135 5.175158  5.205147    3
#> 316         2 136 5.929238  5.196818    3
#> 317         2 137 5.924123  6.194015    4
#> 318         2 138 6.696935  6.872033    2
#> 319         2 139 6.040244  5.829283    3
#> 320         2 140 6.847536  6.519709    3
#> 321         2 141 6.056635  5.680854    2
#> 322         2 142 4.145973  4.937817    2
#> 323         2 143 5.152939  5.132486    1
#> 324         2 144 5.494881  5.795164    4
#> 325         2 145 5.288232  5.575334    2
#> 326         2 146 5.833346  5.696024    5
#> 327         2 147 5.676299  5.544977    3
#> 328         2 148 5.646776  5.873033    4
#> 329         2 149 6.577196  5.445530    3
#> 330         2 150 5.934330  5.652824    4
#> 331         2 151 4.898486  5.092841    3
#> 332         2 152 4.679498  5.674390    1
#> 333         2 153 6.015211  5.717633    5
#> 334         2 154 6.205859  5.207209    4
#> 335         2 155 6.049681  5.516237    2
#> 336         2 156 6.276490  5.550119    3
#> 337         2 157 5.799449  5.612440    3
#> 338         2 158 5.114991  5.107849    5
#> 339         2 159 5.675410  5.032798    4
#> 340         2 160 5.692827  5.610088    4
#> 341         2 161 5.618321  5.023181    5
#> 342         2 162 6.077596  5.634503    5
#> 343         2 163 5.584680  5.767461    5
#> 344         2 164 5.185227  5.678253    4
#> 345         2 165 5.686728  5.220456    4
#> 346         2 166 5.934752  6.044856    4
#> 347         2 167 5.245855  5.532164    3
#> 348         2 168 5.577539  5.985460    2
#> 349         2 169 4.510884  5.360747    2
#> 350         2 170 6.581184  6.256626    2
#> 351         2 171 4.385403  5.398492    5
#> 352         2 172 5.273457  5.720567    1
#> 353         2 173 5.262497  5.319872    3
#> 354         2 174 6.915840  5.819843    3
#> 355         2 175 4.999738  5.312687    2
#> 356         2 176 5.538645  5.562547    1
#> 357         2 177 5.149902  5.657210    2
#> 358         2 178 5.478543  5.950116    2
#> 359         2 179 4.305566  5.319733    3
#> 360         2 180 5.541663  5.896342    1
#> 
if (requireNamespace("robustbase", quietly = TRUE)) {
  vr <- mr_fit(yield_t_ha ~ N_rate_kg_ha + season_rain_mm,
               coll, engine = "robust", goal = "prediction")
  mr_validate(vr, v = 3, repeats = 1)
}
#> $engine
#> [1] "robust"
#> 
#> $metrics
#>        RMSE       MAE        R2 calibration_intercept calibration_slope
#> 1 0.9518309 0.7368161 0.4767287             0.2122867         0.9795862
#> 
#> $summary
#>                  metric      mean sd
#> 1                  RMSE 0.9518309 NA
#> 2                   MAE 0.7368161 NA
#> 3                    R2 0.4767287 NA
#> 4 calibration_intercept 0.2122867 NA
#> 5     calibration_slope 0.9795862 NA
#> 
#> $predictions
#>     repeat_id row  observed predicted fold
#> 1           1   1  9.063762  8.517530    2
#> 2           1   2  9.722673  9.504842    2
#> 3           1   3 12.446738 11.407450    1
#> 4           1   4  9.571229  9.370042    1
#> 5           1   5  9.941384 10.732663    3
#> 6           1   6  8.606517  8.529248    1
#> 7           1   7  9.992892 10.106743    3
#> 8           1   8 10.869668 10.402505    1
#> 9           1   9  8.573651  9.270185    2
#> 10          1  10 10.381474  9.357750    2
#> 11          1  11  9.245548  8.921132    2
#> 12          1  12 11.664292  8.995102    3
#> 13          1  13  6.092889  8.151153    3
#> 14          1  14  9.269161  9.305682    2
#> 15          1  15  9.822895  8.703322    1
#> 16          1  16  8.388862  9.977710    3
#> 17          1  17  9.667055 10.120518    3
#> 18          1  18  8.016590  9.628664    3
#> 19          1  19  9.327161  8.604535    1
#> 20          1  20  8.485270  9.734317    3
#> 21          1  21 12.578796 11.422601    1
#> 22          1  22  5.773736  8.200694    2
#> 23          1  23  8.983772  8.666071    1
#> 24          1  24  9.216065  8.641902    1
#> 25          1  25 10.442955  9.829976    1
#> 26          1  26  9.390940  8.904234    3
#> 27          1  27 10.563076  9.361054    2
#> 28          1  28 11.759544 10.682130    2
#> 29          1  29  9.301627  9.957890    2
#> 30          1  30  7.816353  8.078213    3
#> 31          1  31  9.324978  9.405917    3
#> 32          1  32  8.075430  8.183541    2
#> 33          1  33  9.030666  8.867442    3
#> 34          1  34  7.661134  8.715675    2
#> 35          1  35  9.782433 10.482362    1
#> 36          1  36  9.894744  9.781432    3
#> 37          1  37 10.530637 10.454291    2
#> 38          1  38 11.193345  9.994303    2
#> 39          1  39 10.469625 10.805500    1
#> 40          1  40 10.700707 10.247134    3
#> 41          1  41 10.339992  9.395320    3
#> 42          1  42  8.170086  9.856140    3
#> 43          1  43 11.061007 11.354401    1
#> 44          1  44  7.907381  8.665257    3
#> 45          1  45  9.417030  9.628671    1
#> 46          1  46  8.953100  9.291963    1
#> 47          1  47  9.212621  9.980593    1
#> 48          1  48  8.921403 10.666938    1
#> 49          1  49 10.402494 10.308671    1
#> 50          1  50 10.122007  9.681672    3
#> 51          1  51 13.087464 11.633026    3
#> 52          1  52 10.537626  9.830048    1
#> 53          1  53  9.757402  9.369294    1
#> 54          1  54  7.838517  8.331049    2
#> 55          1  55  9.796406 11.099188    3
#> 56          1  56  9.464009  9.716199    3
#> 57          1  57  9.432576  9.907167    1
#> 58          1  58  9.483275  9.502893    3
#> 59          1  59  5.990317  6.982737    1
#> 60          1  60 10.091715 10.207482    2
#> 61          1  61  9.426723  9.687022    3
#> 62          1  62  7.552128  8.919133    3
#> 63          1  63  9.993871 10.800278    1
#> 64          1  64  9.206698  9.472442    2
#> 65          1  65 11.042236  9.668086    2
#> 66          1  66 11.692700  9.570717    1
#> 67          1  67 10.311743 10.915346    1
#> 68          1  68 10.935288 10.740004    2
#> 69          1  69  9.987521 10.103741    2
#> 70          1  70  8.402286  7.587679    3
#> 71          1  71 11.101662 10.003708    1
#> 72          1  72  9.352184 10.633847    1
#> 73          1  73  9.149124 10.510240    3
#> 74          1  74 10.039400  9.116435    3
#> 75          1  75  8.954272  8.824488    2
#> 76          1  76  9.233475 10.018331    1
#> 77          1  77 10.170421 10.635067    3
#> 78          1  78 10.623938 10.320994    3
#> 79          1  79  7.090101  7.399564    1
#> 80          1  80 10.481266 10.741305    3
#> 81          1  81  8.020057  8.778211    1
#> 82          1  82  9.361504  8.883869    2
#> 83          1  83  9.672297  8.463707    1
#> 84          1  84  9.756618  9.046133    2
#> 85          1  85 10.170410  9.566411    1
#> 86          1  86 11.172952  9.123659    2
#> 87          1  87  9.528013  9.162708    3
#> 88          1  88  9.953472 10.718370    1
#> 89          1  89  6.787188  7.260634    1
#> 90          1  90  7.511849  8.839363    3
#> 91          1  91 10.410803  9.502783    2
#> 92          1  92 10.623078 10.223204    1
#> 93          1  93  8.824563  9.400855    2
#> 94          1  94  8.992127 10.096431    1
#> 95          1  95  9.188466 10.731067    1
#> 96          1  96  6.142903  7.233749    2
#> 97          1  97  9.886126  9.897852    1
#> 98          1  98 10.263136  9.212773    2
#> 99          1  99  9.964203 10.129227    3
#> 100         1 100 10.890724 10.488420    3
#> 101         1 101  7.867581  8.002929    3
#> 102         1 102  9.547936  9.353033    2
#> 103         1 103  9.170616  9.333091    2
#> 104         1 104  9.359516  9.393156    3
#> 105         1 105  6.815186  6.982422    3
#> 106         1 106 10.542688 10.590487    2
#> 107         1 107  8.371197  9.645938    1
#> 108         1 108  8.890077  9.894215    1
#> 109         1 109 10.230589 10.086953    2
#> 110         1 110  8.914594  9.199321    2
#> 111         1 111  9.479350  9.889908    3
#> 112         1 112  8.894967  9.243583    2
#> 113         1 113 11.968537 10.806255    2
#> 114         1 114  9.163850  9.167695    3
#> 115         1 115  9.657329  9.287237    2
#> 116         1 116 10.291382 10.273477    2
#> 117         1 117  7.808273  9.228618    2
#> 118         1 118  9.606813 10.853845    3
#> 119         1 119  9.276535  9.842876    1
#> 120         1 120  9.865378  9.709499    1
#> 121         1 121 10.566093  9.431247    1
#> 122         1 122  9.500442  8.867200    2
#> 123         1 123  9.949490  9.096363    2
#> 124         1 124  9.475805  9.052648    3
#> 125         1 125  8.973837  8.560822    2
#> 126         1 126  9.942124  9.930636    3
#> 127         1 127 10.223033  8.831533    1
#> 128         1 128 10.474325  9.789090    3
#> 129         1 129 11.153720 10.789923    3
#> 130         1 130  8.547044  8.563490    2
#> 131         1 131  8.471554  9.820839    1
#> 132         1 132  7.796136  9.181395    2
#> 133         1 133  8.749346  7.803753    3
#> 134         1 134 11.709176 10.293527    2
#> 135         1 135 11.691067  8.875438    3
#> 136         1 136 12.864925 10.315785    2
#> 137         1 137  8.872979  9.835064    1
#> 138         1 138  8.425055  8.221033    1
#> 139         1 139  9.953105  9.496790    2
#> 140         1 140  9.480671  8.307335    1
#> 141         1 141  9.961385 10.347429    2
#> 142         1 142  9.019054 10.745157    2
#> 143         1 143 12.362728  9.945949    1
#> 144         1 144  7.618998  8.582943    3
#> 145         1 145 10.301076 10.699453    3
#> 146         1 146 11.159087 10.498744    3
#> 147         1 147  8.911851  9.192654    2
#> 148         1 148 10.980733 10.432832    2
#> 149         1 149  9.340495  9.375180    1
#> 150         1 150 11.351483 10.954881    3
#> 

## mr_importance(): three core examples
mr_importance(fit_soil, "standardized")
#>                 term standardized_beta
#> 1            soil_pH       -0.02516237
#> 2 organic_matter_pct        0.16819109
#> 3 available_P_mg_dm3        0.35646302
#> 4     season_rain_mm        0.40153650
mr_importance(fit_soil, "partial_r2")
#>                 term   partial_R2
#> 1            soil_pH 0.0008743923
#> 2 organic_matter_pct 0.0381018560
#> 3 available_P_mg_dm3 0.1520657807
#> 4     season_rain_mm 0.1832806491
mr_importance(fit_soil, "semi_partial_r2")
#>                 term semi_partial_R2
#> 1            soil_pH    0.0006165954
#> 2 organic_matter_pct    0.0279081499
#> 3 available_P_mg_dm3    0.1263523534
#> 4     season_rain_mm    0.1581094290

## mr_inference(): three examples
mr_inference(fit_het, "classical")
#>               term   estimate   std_error statistic  df      p_value
#> 1      (Intercept) 3.05266424 0.768754537  3.970922 176 1.042091e-04
#> 2     N_rate_kg_ha 0.02956894 0.004509140  6.557556 176 5.865936e-10
#> 3     P_rate_kg_ha 0.02704581 0.009986986  2.708106 176 7.434635e-03
#> 4 soil_water_m3_m3 4.82261205 2.157881155  2.234883 176 2.668304e-02
#>      conf_low  conf_high covariance clusters
#> 1 1.535500728 4.56982776  classical       NA
#> 2 0.020669995 0.03846788  classical       NA
#> 3 0.007336151 0.04675547  classical       NA
#> 4 0.563959388 9.08126472  classical       NA
if (requireNamespace("sandwich", quietly = TRUE))
  mr_inference(fit_het, "HC3")
#>               term   estimate   std_error statistic  df      p_value
#> 1      (Intercept) 3.05266424 0.711992495  4.287495 176 2.972332e-05
#> 2     N_rate_kg_ha 0.02956894 0.004400595  6.719304 176 2.439879e-10
#> 3     P_rate_kg_ha 0.02704581 0.010447586  2.588714 176 1.043899e-02
#> 4 soil_water_m3_m3 4.82261205 2.117699423  2.277288 176 2.397224e-02
#>      conf_low  conf_high covariance clusters
#> 1 1.647522570 4.45780592        HC3       NA
#> 2 0.020884212 0.03825366        HC3       NA
#> 3 0.006427141 0.04766448        HC3       NA
#> 4 0.643259419 9.00196469        HC3       NA
if (requireNamespace("sandwich", quietly = TRUE)) {
  het$block <- rep(seq_len(18), length.out = nrow(het))
  fcl <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                  soil_water_m3_m3, het)
  mr_inference(fcl, "cluster", cluster = "block")
}
#>               term   estimate   std_error statistic df      p_value    conf_low
#> 1      (Intercept) 3.05266424 0.775273277  3.937533 17 1.061652e-03 1.416980605
#> 2     N_rate_kg_ha 0.02956894 0.004602735  6.424210 17 6.291320e-06 0.019858015
#> 3     P_rate_kg_ha 0.02704581 0.009549812  2.832078 17 1.150120e-02 0.006897469
#> 4 soil_water_m3_m3 4.82261205 2.227270972  2.165256 17 4.488207e-02 0.123481060
#>    conf_high covariance clusters
#> 1 4.68834788    cluster       18
#> 2 0.03927986    cluster       18
#> 3 0.04719415    cluster       18
#> 4 9.52174305    cluster       18

## mr_effects(): three examples
if (requireNamespace("marginaleffects", quietly = TRUE)) {
  mr_effects(fit_soil, variables = "available_P_mg_dm3")
  mr_effects(fit_soil, variables = "season_rain_mm")
  mr_effects(fit_plant, variables = "leaf_N_pct")
}
#> 
#>  Estimate Std. Error    z Pr(>|z|)    S 2.5 % 97.5 %
#>      1.39      0.265 5.25   <0.001 22.7 0.872   1.91
#> 
#> Term: leaf_N_pct
#> Type: response
#> Comparison: dY/dX
#> 

## mr_quantile(): three examples
if (requireNamespace("quantreg", quietly = TRUE)) {
  mr_quantile(fit_het, tau = 0.25)
  mr_quantile(fit_het, tau = 0.50)
  mr_quantile(fit_het, tau = 0.75)
}
#> multiRegFlow quantile sensitivity analysis
#>  Tau: 0.75 

## mr_kernel(): three documented examples
if (FALSE) { # \dontrun{
if (requireNamespace("np", quietly = TRUE)) {
  base1 <- mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha, nl)
  base2 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl)
  base3 <- mr_fit(yield_t_ha ~ N_rate_kg_ha + mean_temp_C, nl)
  mr_kernel(base1)
  mr_kernel(base2)
  mr_kernel(base3, bwmethod = "cv.aic")
}
} # }

## mr_compare(): three examples
small_soil <- mr_fit(yield_t_ha ~ available_P_mg_dm3 + season_rain_mm,
                     soil, goal = "prediction")
full_soil <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                      exchangeable_K_mg_dm3 + season_rain_mm,
                    soil, goal = "prediction")
mr_compare(full = full_soil, reduced = small_soil,
           v = 5, repeats = 1)
#> $inference
#>     model engine      AIC      BIC R2_or_gam_R2
#> 1    full    ols 323.6622 342.8199    0.3966208
#> 2 reduced    ols 355.0366 367.8085    0.2655878
#>   adjusted_R2_or_deviance_explained
#> 1                         0.3828293
#> 2                         0.2572894
#> 
#> $prediction
#>      model engine                metric      mean sd note
#> 1     full    ols                  RMSE 0.5844244 NA <NA>
#> 2     full    ols                   MAE 0.4770066 NA <NA>
#> 3     full    ols                    R2 0.3768978 NA <NA>
#> 4     full    ols calibration_intercept 0.2233090 NA <NA>
#> 5     full    ols     calibration_slope 0.9608809 NA <NA>
#> 6  reduced    ols                  RMSE 0.6488352 NA <NA>
#> 7  reduced    ols                   MAE 0.5294399 NA <NA>
#> 8  reduced    ols                    R2 0.2319821 NA <NA>
#> 9  reduced    ols calibration_intercept 0.4193648 NA <NA>
#> 10 reduced    ols     calibration_slope 0.9263472 NA <NA>
#> 
#> $note
#> [1] "AIC/BIC and in-sample fit describe fitted models; predictive metrics are computed from out-of-fold predictions and are reported separately."
#> 
mr_compare(full = full_soil, reduced = small_soil, validation = FALSE)
#> $inference
#>     model engine      AIC      BIC R2_or_gam_R2
#> 1    full    ols 323.6622 342.8199    0.3966208
#> 2 reduced    ols 355.0366 367.8085    0.2655878
#>   adjusted_R2_or_deviance_explained
#> 1                         0.3828293
#> 2                         0.2572894
#> 
#> $prediction
#> NULL
#> 
#> $note
#> [1] "AIC/BIC and in-sample fit describe fitted models; predictive metrics are computed from out-of-fold predictions and are reported separately."
#> 
mr_compare(model_a = fit_soil,
           model_b = mr_fit(yield_t_ha ~ available_P_mg_dm3 +
                              season_rain_mm, soil), validation = FALSE)
#> $inference
#>     model engine      AIC      BIC R2_or_gam_R2
#> 1 model_a    ols 351.5655 370.7233    0.2954465
#> 2 model_b    ols 355.0366 367.8085    0.2655878
#>   adjusted_R2_or_deviance_explained
#> 1                         0.2793424
#> 2                         0.2572894
#> 
#> $prediction
#> NULL
#> 
#> $note
#> [1] "AIC/BIC and in-sample fit describe fitted models; predictive metrics are computed from out-of-fold predictions and are reported separately."
#> 

## mr_recommend(): three examples
mr_recommend(fit_soil)
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence   11 observation(s) exceed Cook's 4/n screening value.
#> 3    selection            The declared goal is explanation/inference.
#>                                                                                                      recommendation
#> 1                                Still inspect correlated predictor groups when scientific redundancy is plausible.
#> 2                Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3 Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1      low
#> 2   medium
#> 3     high
mr_recommend(mr_fit(yield_t_ha ~ ., coll))
#>         domain                                              finding
#> 1 collinearity                                Maximum VIF is 11.45.
#> 2    influence 12 observation(s) exceed Cook's 4/n screening value.
#> 3    selection          The declared goal is explanation/inference.
#>                                                                                                                                 recommendation
#> 1 Inspect condition indices and variance decomposition; retain scientifically required terms and compare OLS with ridge coefficient stability.
#> 2                                           Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3                            Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1     high
#> 2   medium
#> 3     high
mr_recommend(mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha +
                      mean_temp_C, nl))
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence   10 observation(s) exceed Cook's 4/n screening value.
#> 3    selection            The declared goal is explanation/inference.
#>                                                                                                      recommendation
#> 1                                Still inspect correlated predictor groups when scientific redundancy is plausible.
#> 2                Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3 Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1      low
#> 2   medium
#> 3     high

## mr_capabilities(): three examples
mr_capabilities()
#>                         module                  backend         package
#> 1                          OLS                    stats            <NA>
#> 2                  diagnostics             multiRegFlow            <NA>
#> 3              influence flags             multiRegFlow            <NA>
#> 4        VIF/condition indices multiRegFlow/performance     performance
#> 5  robust covariance inference                 sandwich        sandwich
#> 6            AIC/BIC selection                    stats            <NA>
#> 7                 best subsets                    leaps           leaps
#> 8      ridge/lasso/elastic net                   glmnet          glmnet
#> 9          stability selection             stabs+glmnet           stabs
#> 10                   bootstrap             multiRegFlow                
#> 11     cross-engine validation             multiRegFlow                
#> 12           robust regression               robustbase      robustbase
#> 13         quantile regression                 quantreg        quantreg
#> 14           kernel regression                       np              np
#> 15                         GAM                     mgcv            mgcv
#> 16     partial/semi-partial R2             multiRegFlow                
#> 17              LMG importance                 relaimpo        relaimpo
#> 18                        SHAP               kernelshap      kernelshap
#> 19            marginal effects          marginaleffects marginaleffects
#>    available
#> 1       TRUE
#> 2       TRUE
#> 3       TRUE
#> 4       TRUE
#> 5       TRUE
#> 6       TRUE
#> 7       TRUE
#> 8       TRUE
#> 9       TRUE
#> 10      TRUE
#> 11      TRUE
#> 12      TRUE
#> 13      TRUE
#> 14      TRUE
#> 15      TRUE
#> 16      TRUE
#> 17      TRUE
#> 18      TRUE
#> 19      TRUE
subset(mr_capabilities(), available)
#>                         module                  backend         package
#> 1                          OLS                    stats            <NA>
#> 2                  diagnostics             multiRegFlow            <NA>
#> 3              influence flags             multiRegFlow            <NA>
#> 4        VIF/condition indices multiRegFlow/performance     performance
#> 5  robust covariance inference                 sandwich        sandwich
#> 6            AIC/BIC selection                    stats            <NA>
#> 7                 best subsets                    leaps           leaps
#> 8      ridge/lasso/elastic net                   glmnet          glmnet
#> 9          stability selection             stabs+glmnet           stabs
#> 10                   bootstrap             multiRegFlow                
#> 11     cross-engine validation             multiRegFlow                
#> 12           robust regression               robustbase      robustbase
#> 13         quantile regression                 quantreg        quantreg
#> 14           kernel regression                       np              np
#> 15                         GAM                     mgcv            mgcv
#> 16     partial/semi-partial R2             multiRegFlow                
#> 17              LMG importance                 relaimpo        relaimpo
#> 18                        SHAP               kernelshap      kernelshap
#> 19            marginal effects          marginaleffects marginaleffects
#>    available
#> 1       TRUE
#> 2       TRUE
#> 3       TRUE
#> 4       TRUE
#> 5       TRUE
#> 6       TRUE
#> 7       TRUE
#> 8       TRUE
#> 9       TRUE
#> 10      TRUE
#> 11      TRUE
#> 12      TRUE
#> 13      TRUE
#> 14      TRUE
#> 15      TRUE
#> 16      TRUE
#> 17      TRUE
#> 18      TRUE
#> 19      TRUE
subset(mr_capabilities(), !is.na(package) & package != "")
#>                         module                  backend         package
#> 4        VIF/condition indices multiRegFlow/performance     performance
#> 5  robust covariance inference                 sandwich        sandwich
#> 7                 best subsets                    leaps           leaps
#> 8      ridge/lasso/elastic net                   glmnet          glmnet
#> 9          stability selection             stabs+glmnet           stabs
#> 12           robust regression               robustbase      robustbase
#> 13         quantile regression                 quantreg        quantreg
#> 14           kernel regression                       np              np
#> 15                         GAM                     mgcv            mgcv
#> 17              LMG importance                 relaimpo        relaimpo
#> 18                        SHAP               kernelshap      kernelshap
#> 19            marginal effects          marginaleffects marginaleffects
#>    available
#> 4       TRUE
#> 5       TRUE
#> 7       TRUE
#> 8       TRUE
#> 9       TRUE
#> 12      TRUE
#> 13      TRUE
#> 14      TRUE
#> 15      TRUE
#> 17      TRUE
#> 18      TRUE
#> 19      TRUE

## mr_report(): three examples
txt <- mr_report(fit_soil)
cat(substr(txt, 1, 250))
#> # multiRegFlow analysis report
#> 
#> - Engine: `ols`
#> - Goal: `explanation`
#> - Formula: `yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +      season_rain_mm`
#> - Complete observations: 180
#> 
#> ## Model fit
#> 
#> - R-squared: 0.2954
#> - Adjusted R-squar
txt_classic <- mr_report(fit_soil, vcov = "classical")
cat(substr(txt_classic, 1, 250))
#> # multiRegFlow analysis report
#> 
#> - Engine: `ols`
#> - Goal: `explanation`
#> - Formula: `yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +      season_rain_mm`
#> - Complete observations: 180
#> 
#> ## Model fit
#> 
#> - R-squared: 0.2954
#> - Adjusted R-squar
tmp <- tempfile(fileext = ".md")
mr_report(fit_soil, file = tmp)
file.exists(tmp)
#> [1] TRUE
```
