# R/02_helpers.R
# Core probability helpers + select mortality adjustment

library(dplyr)

clamp <- function(x, lo, hi) pmin(pmax(x, lo), hi)
v <- function(i) 1 / (1 + i)

validate_inputs <- function(age, term, i, max_age = 100) {
  stopifnot(age >= 20, age <= 80)     # assignment range
  stopifnot(i >= 0, i <= 0.10)        # 0% to 10%
  stopifnot(term >= 1)
  stopifnot(age + term <= max_age)    # max age 100
  invisible(TRUE)
}

get_qx <- function(mort, age, sex) {
  out <- mort %>% filter(sex == !!sex, age == !!age) %>% pull(qx)
  if (length(out) != 1 || is.na(out)) stop("qx not found for given age/sex.")
  out
}

# Select mortality: apply factor to qx for first select_years durations
get_qx_selectable <- function(mort, x, sex, d = 0,
                              mort_type = "Ultimate",
                              select_years = 2,
                              select_factor = 0.85) {
  q <- get_qx(mort, x + d, sex)
  if (mort_type == "Select" && d < select_years) {
    q <- clamp(select_factor * q, 0, 1)
  }
  q
}

tpx <- function(mort, x, sex, t,
                mort_type = "Ultimate",
                select_years = 2,
                select_factor = 0.85) {
  if (t == 0) return(1)
  
  p <- 1
  for (d in 0:(t - 1)) {
    qd <- get_qx_selectable(mort, x, sex, d, mort_type, select_years, select_factor)
    p <- p * (1 - qd)
  }
  p
}

tqx <- function(mort, x, sex, t, mort_type = "Ultimate",
                select_years = 2, select_factor = 0.85) {
  1 - tpx(mort, x, sex, t, mort_type, select_years, select_factor)
}