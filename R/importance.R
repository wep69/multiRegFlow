#' Variable importance for multiple regression
#'
#' Provides standardized coefficients, coefficient-level partial R-squared and
#' term-level semi-partial R-squared without optional packages. LMG relative
#' importance and additive SHAP are delegated to specialized packages.
#'
#' @param x An OLS `mr_fit` object.
#' @param method "standardized", "partial_r2", "semi_partial_r2", "lmg", or "shap".
#' @param ... Additional arguments passed to the backend.
#' @return A method-specific importance object.
#' @export
mr_importance <- function(x,
                          method = c("standardized", "partial_r2",
                                     "semi_partial_r2", "lmg", "shap"), ...) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_importance() currently targets OLS fits.", call. = FALSE)
  method <- match.arg(method)
  m <- x$model
  if (method == "standardized") {
    mf <- stats::model.frame(m)
    y <- stats::model.response(mf)
    X <- mf[-1]
    ok <- vapply(X, is.numeric, logical(1))
    if (!any(ok)) stop("No numeric predictors available for standardized coefficients.", call. = FALSE)
    sdy <- stats::sd(y)
    cf <- stats::coef(m)
    ans <- lapply(names(X)[ok], function(nm) {
      if (!nm %in% names(cf)) return(NULL)
      data.frame(term = nm,
                 standardized_beta = unname(cf[nm]) * stats::sd(X[[nm]]) / sdy)
    })
    return(do.call(rbind, ans))
  }
  if (method == "partial_r2") {
    tab <- summary(m)$coefficients
    tab <- tab[rownames(tab) != "(Intercept)", , drop = FALSE]
    tval <- tab[, "t value"]
    df <- stats::df.residual(m)
    return(data.frame(term = rownames(tab),
                      partial_R2 = tval^2 / (tval^2 + df),
                      row.names = NULL))
  }
  if (method == "semi_partial_r2") {
    dr <- stats::drop1(m, test = "none")
    dr <- dr[rownames(dr) != "<none>", , drop = FALSE]
    rss_full <- sum(stats::residuals(m)^2)
    y <- stats::model.response(stats::model.frame(m))
    sst <- sum((y - mean(y))^2)
    rss_col <- if ("RSS" %in% names(dr)) "RSS" else stop("Could not obtain reduced-model RSS.", call. = FALSE)
    sr2 <- (dr[[rss_col]] - rss_full) / sst
    return(data.frame(term = rownames(dr), semi_partial_R2 = pmax(sr2, 0),
                      row.names = NULL))
  }
  if (method == "lmg") {
    .mr_require("relaimpo", "for LMG relative importance")
    return(relaimpo::calc.relimp(m, type = "lmg", rela = TRUE, ...))
  }
  .mr_require("kernelshap", "for SHAP values")
  X <- stats::model.frame(m)[-1]
  kernelshap::additive_shap(m, X = X, ...)
}

#' Average marginal effects or slopes
#'
#' Uses `marginaleffects` when available. Effects are intentionally kept
#' separate from coefficient tables because the two answer different questions,
#' particularly for interactions and nonlinear specifications.
#'
#' @param x An `mr_fit` object.
#' @param variables Optional variables passed to `marginaleffects::avg_slopes()`.
#' @param ... Additional arguments.
#' @return A marginaleffects object.
#' @export
mr_effects <- function(x, variables = NULL, ...) {
  .mr_assert_fit(x)
  .mr_require("marginaleffects", "for average slopes")
  marginaleffects::avg_slopes(x$model, variables = variables, ...)
}
