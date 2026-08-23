#' Variable selection
#'
#' Implements AIC/BIC stepwise selection directly and delegates best-subset,
#' lasso/elastic-net and stability selection to established backends. Selection
#' is treated as exploratory unless the scientific design and inferential method
#' justify stronger claims.
#'
#' @param x An OLS `mr_fit` object.
#' @param method Selection method.
#' @param alpha Elastic-net alpha when relevant.
#' @param keep Optional character vector of terms that must remain in stepwise models.
#' @param seed Random seed.
#' @param lambda Penalized-selection rule, either "1se" or "min".
#' @param ... Additional backend arguments.
#' @return A method-specific selection object.
#' @export
mr_select <- function(x, method = c("aic", "bic", "best_subset", "lasso",
                                    "elastic_net", "stability"),
                      alpha = 0.5, keep = NULL, seed = 123,
                      lambda = c("1se", "min"), ...) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_select() currently starts from an OLS reference fit.", call. = FALSE)
  method <- match.arg(method)
  lambda <- match.arg(lambda)
  if (method %in% c("aic", "bic")) {
    d_step <- x$data
    f_step <- x$formula
    environment(f_step) <- environment()
    m <- stats::lm(f_step, data = d_step)
    lower <- if (is.null(keep) || length(keep) == 0L) {
      stats::as.formula(paste(x$response, "~ 1"))
    } else {
      missing_keep <- setdiff(keep, attr(stats::terms(m), "term.labels"))
      if (length(missing_keep)) {
        stop("Terms in `keep` were not found in the fitted model: ",
             paste(missing_keep, collapse = ", "), call. = FALSE)
      }
      stats::reformulate(keep, response = x$response)
    }
    upper <- f_step
    k <- if (method == "aic") 2 else log(stats::nobs(m))
    fit <- stats::step(m, scope = list(lower = lower, upper = upper),
                       direction = "both", k = k, trace = 0)
    return(structure(
      list(method = method, model = fit,
           selected = attr(stats::terms(fit), "term.labels"),
           criterion = if (method == "aic") stats::AIC(fit) else stats::BIC(fit),
           trace = fit$anova, keep = keep),
      class = "mr_selection"
    ))
  }
  if (method == "best_subset") {
    .mr_require("leaps", "for best-subset selection")
    rs <- leaps::regsubsets(x$formula, data = x$data,
                            nvmax = length(x$predictors), ...)
    ss <- summary(rs)
    best_bic <- which.min(ss$bic)
    best_adj <- which.max(ss$adjr2)
    return(structure(
      list(method = method, model = rs, summary = ss,
           best_by_bic = best_bic, best_by_adjr2 = best_adj,
           variables_by_bic = names(stats::coef(rs, id = best_bic))[-1],
           variables_by_adjr2 = names(stats::coef(rs, id = best_adj))[-1]),
      class = "mr_selection"
    ))
  }
  xy <- .mr_xy(x)
  if (method %in% c("lasso", "elastic_net")) {
    .mr_require("glmnet", "for penalized selection")
    set.seed(seed)
    a <- if (method == "lasso") 1 else alpha
    cv <- glmnet::cv.glmnet(xy$X, xy$y, family = "gaussian", alpha = a, ...)
    s <- if (lambda == "min") "lambda.min" else "lambda.1se"
    cf <- as.matrix(stats::coef(cv, s = s))
    selected <- rownames(cf)[cf[, 1] != 0]
    selected <- setdiff(selected, "(Intercept)")
    return(structure(
      list(method = method, model = cv, alpha = a, lambda_rule = lambda,
           lambda_min = cv$lambda.min, lambda_1se = cv$lambda.1se,
           selected = selected, coefficients = cf),
      class = "mr_selection"
    ))
  }
  .mr_require("stabs", "for stability selection")
  .mr_require("glmnet", "for stability-selection lasso")
  set.seed(seed)
  args <- list(x = xy$X, y = xy$y, fitfun = stabs::glmnet.lasso,
               cutoff = 0.75, PFER = 1)
  args <- c(args, list(...))
  fit <- do.call(stabs::stabsel, args)
  structure(
    list(method = method, model = fit,
         selected = names(which(fit$max > fit$cutoff)),
         selection_probabilities = fit$max,
         cutoff = fit$cutoff, PFER = fit$PFER),
    class = "mr_selection"
  )
}

#' Ridge, lasso and elastic-net regularization
#'
#' @param x An OLS `mr_fit` object used to define response and predictors.
#' @param method "ridge", "lasso", or "elastic_net".
#' @param alpha Elastic-net mixing parameter when `method = "elastic_net"`.
#' @param lambda Either "min" or "1se".
#' @param nfolds Number of CV folds.
#' @param seed Random seed.
#' @param ... Additional arguments passed to `glmnet::cv.glmnet()`.
#' @return An `mr_regularization` object with selected coefficients and the
#'   cross-validation curve.
#' @export
mr_regularize <- function(x, method = c("ridge", "lasso", "elastic_net"),
                          alpha = 0.5, lambda = c("1se", "min"),
                          nfolds = 10, seed = 123, ...) {
  .mr_assert_fit(x)
  .mr_require("glmnet", "for regularization")
  method <- match.arg(method)
  lambda <- match.arg(lambda)
  xy <- .mr_xy(x)
  a <- switch(method, ridge = 0, lasso = 1, elastic_net = alpha)
  set.seed(seed)
  cv <- glmnet::cv.glmnet(xy$X, xy$y, family = "gaussian",
                          alpha = a, nfolds = nfolds, ...)
  s <- if (lambda == "min") "lambda.min" else "lambda.1se"
  cf <- as.matrix(stats::coef(cv, s = s))
  selected <- setdiff(rownames(cf)[cf[, 1] != 0], "(Intercept)")
  cv_table <- data.frame(lambda = cv$lambda, mean_loss = cv$cvm,
                         se_loss = cv$cvsd, nzero = cv$nzero)
  structure(
    list(method = method, alpha = a, lambda_rule = lambda,
         model = cv, coefficients = cf, selected = selected,
         lambda_min = cv$lambda.min, lambda_1se = cv$lambda.1se,
         cv = cv_table),
    class = "mr_regularization"
  )
}

#' @export
print.mr_selection <- function(x, ...) {
  cat("multiRegFlow selection\n Method:", x$method, "\n")
  if (!is.null(x$selected)) cat(" Selected:", paste(x$selected, collapse = ", "), "\n")
  invisible(x)
}

#' @export
print.mr_regularization <- function(x, ...) {
  cat("multiRegFlow regularization\n Method:", x$method,
      "\n Lambda rule:", x$lambda_rule,
      "\n Selected/nonzero predictors:", length(x$selected), "\n")
  invisible(x)
}
