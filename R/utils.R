.mr_assert_fit <- function(x) {
  if (!inherits(x, "mr_fit")) {
    stop("`x` must be an object created by mr_fit().", call. = FALSE)
  }
  invisible(TRUE)
}

.mr_require <- function(pkg, reason = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- paste0("Package '", pkg, "' is required")
    if (!is.null(reason)) msg <- paste0(msg, " ", reason)
    stop(paste0(msg, ". Install it with install.packages('", pkg, "')."), call. = FALSE)
  }
  invisible(TRUE)
}

.mr_model_frame <- function(x) {
  mf <- tryCatch(stats::model.frame(x$model), error = function(e) NULL)
  if (!is.null(mf) && is.data.frame(mf)) return(mf)
  stats::model.frame(x$formula, data = x$data, na.action = stats::na.omit)
}

.mr_xy <- function(x) {
  mf <- .mr_model_frame(x)
  y <- stats::model.response(mf)
  tt <- stats::terms(mf)
  X <- stats::model.matrix(tt, mf)
  if ("(Intercept)" %in% colnames(X)) {
    X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  }
  list(X = X, y = y, mf = mf, terms = tt)
}

.mr_metrics <- function(obs, pred) {
  ok <- stats::complete.cases(obs, pred)
  obs <- obs[ok]
  pred <- pred[ok]
  if (length(obs) < 2L) {
    return(c(RMSE = NA_real_, MAE = NA_real_, R2 = NA_real_,
             calibration_intercept = NA_real_, calibration_slope = NA_real_))
  }
  rmse <- sqrt(mean((obs - pred)^2))
  mae <- mean(abs(obs - pred))
  den <- sum((obs - mean(obs))^2)
  r2 <- if (den > 0) 1 - sum((obs - pred)^2) / den else NA_real_
  if (stats::sd(pred) > 0) {
    cal <- stats::lm(obs ~ pred)
    ci <- unname(stats::coef(cal)[1])
    cs <- unname(stats::coef(cal)[2])
  } else {
    ci <- NA_real_
    cs <- NA_real_
  }
  c(RMSE = rmse, MAE = mae, R2 = r2,
    calibration_intercept = ci, calibration_slope = cs)
}

.mr_fold_id <- function(n, v, seed) {
  set.seed(seed)
  sample(rep(seq_len(v), length.out = n))
}

.mr_bp_test <- function(model) {
  e2 <- stats::residuals(model)^2
  mm <- stats::model.matrix(model)
  if (ncol(mm) <= 1L) {
    return(c(statistic = NA_real_, df = 0, p.value = NA_real_))
  }
  z <- data.frame(e2 = e2, mm[, -1, drop = FALSE], check.names = TRUE)
  aux <- stats::lm(e2 ~ ., data = z)
  stat <- length(e2) * summary(aux)$r.squared
  df <- ncol(mm) - 1L
  c(statistic = stat, df = df,
    p.value = stats::pchisq(stat, df = df, lower.tail = FALSE))
}

.mr_reset_test <- function(model) {
  mf <- stats::model.frame(model)
  y <- stats::model.response(mf)
  X <- stats::model.matrix(model)
  fit0 <- stats::fitted(model)
  X1 <- cbind(X, fitted_sq = fit0^2, fitted_cu = fit0^3)
  aux <- stats::lm.fit(x = X1, y = y)
  rank0 <- qr(X)$rank
  q <- aux$rank - rank0
  if (q <= 0L) {
    return(c(statistic = NA_real_, df1 = 0, df2 = stats::df.residual(model),
             p.value = NA_real_))
  }
  rss0 <- sum(stats::residuals(model)^2)
  rss1 <- sum(aux$residuals^2)
  df2 <- length(y) - aux$rank
  fval <- ((rss0 - rss1) / q) / (rss1 / df2)
  if (!is.finite(fval) || fval < 0) fval <- 0
  c(statistic = fval, df1 = q, df2 = df2,
    p.value = stats::pf(fval, q, df2, lower.tail = FALSE))
}

.mr_vif_numeric <- function(X) {
  X <- as.data.frame(X)
  keep <- vapply(X, is.numeric, logical(1))
  X <- X[, keep, drop = FALSE]
  if (ncol(X) < 2L) {
    return(data.frame(term = names(X), VIF = NA_real_, tolerance = NA_real_,
                      flag_vif5 = FALSE, flag_vif10 = FALSE))
  }
  ans <- lapply(names(X), function(nm) {
    others <- setdiff(names(X), nm)
    f <- stats::reformulate(others, response = nm)
    mod <- stats::lm(f, data = X)
    r2 <- summary(mod)$r.squared
    tol <- max(1 - r2, .Machine$double.eps)
    vif <- 1 / tol
    data.frame(term = nm, VIF = vif, tolerance = tol,
               flag_vif5 = vif >= 5, flag_vif10 = vif >= 10)
  })
  do.call(rbind, ans)
}

.mr_condition <- function(X) {
  X <- as.matrix(X)
  if (ncol(X) < 2L) {
    return(list(condition_index = stats::setNames(1, colnames(X)),
                variance_decomposition = matrix(
                  1, nrow = ncol(X), ncol = 1,
                  dimnames = list(colnames(X), "Dim1")
                ),
                singular_values = 1))
  }
  Xs <- scale(X)
  keep <- apply(Xs, 2, function(z) stats::sd(z, na.rm = TRUE) > 0)
  Xs <- Xs[, keep, drop = FALSE]
  sv <- svd(Xs)
  d <- pmax(sv$d, .Machine$double.eps)
  ci <- max(d) / d
  phi <- sweep(sv$v^2, 2, d^2, "/")
  prop <- phi / rowSums(phi)
  rownames(prop) <- colnames(Xs)
  colnames(prop) <- paste0("Dim", seq_len(ncol(prop)))
  list(
    condition_index = stats::setNames(ci, paste0("Dim", seq_along(ci))),
    variance_decomposition = prop,
    singular_values = d
  )
}

.mr_cor_pairs <- function(X) {
  X <- as.data.frame(X)
  keep <- vapply(X, is.numeric, logical(1))
  X <- X[, keep, drop = FALSE]
  if (ncol(X) < 2L) {
    return(data.frame(term1 = character(), term2 = character(),
                      correlation = numeric(), abs_correlation = numeric()))
  }
  C <- stats::cor(X, use = "pairwise.complete.obs")
  idx <- which(upper.tri(C), arr.ind = TRUE)
  out <- data.frame(
    term1 = rownames(C)[idx[, 1]],
    term2 = colnames(C)[idx[, 2]],
    correlation = C[idx],
    abs_correlation = abs(C[idx]),
    row.names = NULL
  )
  out[order(-out$abs_correlation), , drop = FALSE]
}

.mr_engine_predict <- function(object, newdata, ...) {
  eng <- object$engine
  if (eng %in% c("ols", "robust", "gam")) {
    return(as.numeric(stats::predict(object$model, newdata = newdata, ...)))
  }
  if (eng == "quantile") {
    pr <- stats::predict(object$model, newdata = newdata, ...)
    if (is.matrix(pr) && ncol(pr) == 1L) pr <- pr[, 1]
    return(pr)
  }
  if (eng == "kernel") {
    return(as.numeric(stats::predict(object$model, newdata = newdata, ...)))
  }
  stop("Prediction is not implemented for this engine.", call. = FALSE)
}

.mr_refit <- function(x, data) {
  args <- c(
    list(formula = x$formula, data = data, goal = x$goal,
         engine = x$engine, tau = x$tau),
    x$backend_args
  )
  do.call(mr_fit, args)
}

.mr_md_table <- function(x, digits = 4) {
  if (!is.data.frame(x)) x <- as.data.frame(x)
  if (nrow(x) == 0L) return(character())
  y <- x
  y[] <- lapply(y, function(z) {
    if (is.numeric(z)) format(round(z, digits), trim = TRUE, scientific = FALSE) else as.character(z)
  })
  header <- paste0("| ", paste(names(y), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(y)), collapse = " | "), " |")
  body <- apply(y, 1, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  c(header, sep, body)
}
