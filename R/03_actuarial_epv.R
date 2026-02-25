# R/03_actuarial_epv.R
# EPV building blocks (discrete yearly model)

source("R/02_helpers.R")

benefit_at_time <- function(B, t, bonus = 0, inflation = 0) {
  # Increases apply from year 2 onward (t >= 1)
  if (t == 0) return(B)
  B * ((1 + inflation)^t) * (1 + t * bonus)
}

Ax_term_eoy <- function(mort, x, sex, n, i,
                        B = 1,
                        mort_type = "Ultimate",
                        select_years = 2, select_factor = 0.85,
                        bonus = 0, inflation = 0,
                        apply_increases = TRUE) {
  vv <- v(i)
  s <- 0
  for (t in 0:(n - 1)) {
    surv <- tpx(mort, x, sex, t, mort_type, select_years, select_factor)
    qxt  <- get_qx_selectable(mort, x, sex, t, mort_type, select_years, select_factor)
    Bt <- if (apply_increases) benefit_at_time(B, t, bonus, inflation) else B
    s <- s + (vv^(t + 1)) * surv * qxt * Bt
  }
  s
}

Ax_term_immediate_approx <- function(...) {
  args <- list(...)
  i <- args$i
  A <- do.call(Ax_term_eoy, args)
  ((1 + i)^(0.5)) * A
}

nEx <- function(mort, x, sex, n, i,
                B = 1,
                mort_type = "Ultimate",
                select_years = 2, select_factor = 0.85) {
  (v(i)^n) * tpx(mort, x, sex, n, mort_type, select_years, select_factor) * B
}

Ax_endowment <- function(mort, x, sex, n, i,
                         B = 1,
                         timing = c("EOY", "Immediate"),
                         mort_type = "Ultimate",
                         select_years = 2, select_factor = 0.85,
                         bonus = 0, inflation = 0,
                         apply_increases = TRUE) {
  timing <- match.arg(timing)
  
  term_part <- if (timing == "EOY") {
    Ax_term_eoy(mort, x, sex, n, i, B, mort_type, select_years, select_factor,
                bonus, inflation, apply_increases)
  } else {
    Ax_term_immediate_approx(mort, x, sex, n, i, B, mort_type, select_years, select_factor,
                             bonus, inflation, apply_increases)
  }
  
  pe_part <- nEx(mort, x, sex, n, i, B, mort_type, select_years, select_factor)
  term_part + pe_part
}

Ax_whole_life <- function(mort, x, sex, i,
                          max_age = 100,
                          B = 1,
                          timing = c("EOY", "Immediate"),
                          mort_type = "Ultimate",
                          select_years = 2, select_factor = 0.85,
                          bonus = 0, inflation = 0) {
  timing <- match.arg(timing)
  n <- max_age - x
  
  # Whole life assurance = endowment - pure endowment at max_age
  Ax_endowment(mort, x, sex, n, i, B, timing,
               mort_type, select_years, select_factor,
               bonus, inflation, apply_increases = TRUE) -
    nEx(mort, x, sex, n, i, B, mort_type, select_years, select_factor)
}

a_due <- function(mort, x, sex, n, i,
                  mort_type = "Ultimate",
                  select_years = 2, select_factor = 0.85) {
  vv <- v(i)
  s <- 0
  for (t in 0:(n - 1)) {
    s <- s + (vv^t) * tpx(mort, x, sex, t, mort_type, select_years, select_factor)
  }
  s
}