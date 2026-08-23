#' Load teaching datasets
#'
#' Frozen synthetic datasets illustrate common agricultural regression
#' situations. They are explicitly synthetic and must not be presented as
#' measurements from real experiments.
#'
#' @param name One of "soil_fertility", "plant_growth", "agronomy_collinear",
#'   "irrigation_nonlinear", or "agronomy_heteroskedastic".
#' @return A data frame.
#' @export
mr_example_data <- function(name = c("soil_fertility", "plant_growth",
                                     "agronomy_collinear", "irrigation_nonlinear",
                                     "agronomy_heteroskedastic")) {
  name <- match.arg(name)
  path <- system.file("extdata", paste0(name, ".csv"), package = "multiRegFlow")
  if (!nzchar(path)) {
    dev <- file.path("inst", "extdata", paste0(name, ".csv"))
    if (file.exists(dev)) path <- dev
  }
  if (!nzchar(path) || !file.exists(path)) stop("Teaching dataset was not found.", call. = FALSE)
  utils::read.csv(path, check.names = FALSE)
}

#' Write an auditable Markdown analysis report
#'
#' The report records the declared goal, model specification, fit diagnostics,
#' coefficient inference, collinearity diagnostics, influential observations,
#' methodological recommendations and, optionally, out-of-fold validation.
#'
#' @param x An OLS `mr_fit` object.
#' @param file Output Markdown file. If NULL, the Markdown text is returned.
#' @param vcov Covariance estimator passed to `mr_inference()`. The default
#'   `"auto"` uses HC3 when heteroscedasticity is screened at p < 0.05 and
#'   package `sandwich` is available; otherwise classical covariance is used.
#' @param validation Logical; if NULL, validation is run when `goal = "prediction"`.
#' @param v Number of CV folds when validation is requested.
#' @param repeats Number of CV repetitions.
#' @param seed Random seed.
#' @return Invisibly, the Markdown text.
#' @export
mr_report <- function(x, file = NULL, vcov = c("auto", "classical", "HC3"),
                      validation = NULL, v = 5, repeats = 3, seed = 123) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_report() currently starts from an OLS reference fit.", call. = FALSE)
  vcov <- match.arg(vcov)
  dg <- mr_diagnose(x)
  rec <- mr_recommend(x)
  co <- mr_collinearity(x)
  if (vcov == "auto") {
    bp_p <- unname(dg$heteroscedasticity["p.value"])
    vcov_use <- if (!is.na(bp_p) && bp_p < 0.05 && requireNamespace("sandwich", quietly = TRUE)) "HC3" else "classical"
  } else vcov_use <- vcov
  inf <- mr_inference(x, vcov = vcov_use)
  infl <- mr_influence(x)
  infl <- infl[order(-infl$cooks_distance), , drop = FALSE]
  infl_show <- utils::head(infl[, c("row", "leverage", "cooks_distance", "dffits",
                                    "max_abs_dfbeta", "flag_leverage", "flag_cook")], 8)
  vif_show <- co$VIF[order(-co$VIF$VIF), , drop = FALSE]
  do_val <- if (is.null(validation)) identical(x$goal, "prediction") else isTRUE(validation)

  lines <- c(
    "# multiRegFlow analysis report", "",
    paste0("- Engine: `", x$engine, "`"),
    paste0("- Goal: `", x$goal, "`"),
    paste0("- Formula: `", paste(deparse(x$formula), collapse = " "), "`"),
    paste0("- Complete observations: ", x$n), "",
    "## Model fit", "",
    paste0("- R-squared: ", round(dg$fit["R2"], 4)),
    paste0("- Adjusted R-squared: ", round(dg$fit["adjusted_R2"], 4)),
    paste0("- Residual sigma: ", round(dg$fit["sigma"], 4)),
    paste0("- AIC: ", round(dg$fit["AIC"], 2)),
    paste0("- BIC: ", round(dg$fit["BIC"], 2)), "",
    "## Diagnostic screens", "",
    paste0("- Breusch-Pagan p-value: ", signif(dg$heteroscedasticity["p.value"], 4)),
    paste0("- Fitted-value-power specification p-value: ", signif(dg$specification["p.value"], 4)),
    paste0("- Shapiro-Wilk p-value: ", signif(dg$residuals["shapiro_p"], 4)),
    "",
    paste0("## Coefficient inference (", vcov_use, ")"), "",
    .mr_md_table(inf[, c("term", "estimate", "std_error", "p_value", "conf_low", "conf_high")]), "",
    "## Collinearity", "",
    .mr_md_table(vif_show), "",
    "## Most influential observations for inspection", "",
    .mr_md_table(infl_show), "",
    "## Methodological recommendations", ""
  )
  for (i in seq_len(nrow(rec))) {
    lines <- c(lines,
               paste0("### ", rec$domain[i], " [", rec$priority[i], "]"), "",
               rec$finding[i], "", rec$recommendation[i], "")
  }
  if (do_val) {
    val <- mr_validate(x, v = v, repeats = repeats, seed = seed)
    lines <- c(lines, "## Out-of-fold validation", "", .mr_md_table(val$summary), "")
  }
  lines <- c(lines,
             "## Interpretation note", "",
             paste("Associations are conditional on the fitted specification and",
                   "do not by themselves establish causality. Final interpretation",
                   "must consider design, measurement process, agronomic plausibility",
                   "and uncertainty."), "")
  txt <- paste(lines, collapse = "\n")
  if (!is.null(file)) writeLines(txt, con = file, useBytes = TRUE)
  invisible(txt)
}
