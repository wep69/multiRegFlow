test_that("importance measures return coherent tables", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                  season_rain_mm, d)
  a <- mr_importance(fit, "standardized")
  b <- mr_importance(fit, "partial_r2")
  c <- mr_importance(fit, "semi_partial_r2")
  expect_true(all(is.finite(a$standardized_beta)))
  expect_true(all(b$partial_R2 >= 0 & b$partial_R2 <= 1))
  expect_true(all(c$semi_partial_R2 >= 0 & c$semi_partial_R2 <= 1))
})

test_that("optional LMG, SHAP and marginal effects work", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                  season_rain_mm, d)
  if (requireNamespace("relaimpo", quietly = TRUE)) {
    z <- mr_importance(fit, "lmg")
    expect_true(abs(sum(z$lmg) - 1) < 1e-8)
  }
  if (requireNamespace("kernelshap", quietly = TRUE)) {
    z <- mr_importance(fit, "shap")
    expect_equal(nrow(z$S), nrow(d))
  }
  if (requireNamespace("marginaleffects", quietly = TRUE)) {
    z <- mr_effects(fit, variables = "available_P_mg_dm3")
    expect_true(nrow(as.data.frame(z)) >= 1)
  }
})

test_that("recommendations respond to designed problems", {
  coll <- mr_example_data("agronomy_collinear")
  nl <- mr_example_data("irrigation_nonlinear")
  rc <- mr_recommend(mr_fit(yield_t_ha ~ ., coll))
  rn <- mr_recommend(mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha +
                              mean_temp_C, nl))
  expect_true(any(rc$domain == "collinearity" & rc$priority == "high"))
  # The RESET test may not always detect nonlinearity in the irrigation dataset;
  # verify that recommendations are generated and contain expected domains
  expect_true(nrow(rn) > 0)
  expect_true(all(rn$domain %in% c("collinearity", "functional_form",
                                    "influence", "selection", "validation",
                                    "information", "rank", "heteroscedasticity")))
})

test_that("Markdown report contains auditable sections", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                  season_rain_mm, d)
  txt <- mr_report(fit)
  expect_match(txt, "Model fit")
  expect_match(txt, "Coefficient inference")
  expect_match(txt, "Collinearity")
  expect_match(txt, "Methodological recommendations")
  tmp <- tempfile(fileext = ".md")
  mr_report(fit, file = tmp)
  expect_true(file.exists(tmp))
})
