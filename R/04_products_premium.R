# R/04_products_premium.R
# Product EPVs + net/gross premium calculation incl. expenses, bonus & inflation

source("R/03_actuarial_epv.R")

benefit_epv <- function(mort, product, x, sex, term, i, B,
                        timing = c("EOY", "Immediate"),
                        mort_type = "Ultimate",
                        select_years = 2, select_factor = 0.85,
                        claim_exp = 0,
                        bonus = 0, inflation = 0) {
  timing <- match.arg(timing)
  
  # Claim expense as benefit uplift
  B_adj <- B * (1 + claim_exp)
  
  if (product == "Pure Endowment") {
    return(nEx(mort, x, sex, term, i, B_adj, mort_type, select_years, select_factor))
  }
  
  if (product == "Term Assurance") {
    if (timing == "EOY") {
      return(Ax_term_eoy(mort, x, sex, term, i, B_adj,
                         mort_type, select_years, select_factor,
                         bonus, inflation, apply_increases = TRUE))
    } else {
      return(Ax_term_immediate_approx(mort, x, sex, term, i, B_adj,
                                      mort_type, select_years, select_factor,
                                      bonus, inflation, apply_increases = TRUE))
    }
  }
  
  if (product == "Endowment Assurance") {
    return(Ax_endowment(mort, x, sex, term, i, B_adj, timing,
                        mort_type, select_years, select_factor,
                        bonus, inflation, apply_increases = TRUE))
  }
  
  if (product == "Whole Life Assurance") {
    return(Ax_whole_life(mort, x, sex, i, max_age = 100, B = B_adj, timing = timing,
                         mort_type = mort_type, select_years = select_years, select_factor = select_factor,
                         bonus = bonus, inflation = inflation))
  }
  
  stop("Unknown product.")
}

calc_premium <- function(mort, product, premium_type, prem_freq,
                         x, sex, term, i, B,
                         timing = c("EOY", "Immediate"),
                         mort_type = "Ultimate",
                         select_years = 2, select_factor = 0.85,
                         initial_exp = 0, renewal_exp = 0, claim_exp = 0,
                         bonus = 0, inflation = 0) {
  
  timing <- match.arg(timing)
  
  # Whole life term = 100 - x
  if (product == "Whole Life Assurance") term <- 100 - x
  
  EB <- benefit_epv(mort, product, x, sex, term, i, B, timing,
                    mort_type, select_years, select_factor,
                    claim_exp, bonus, inflation)
  
  if (premium_type == "Single") {
    # (1 - initial_exp) * G = EB
    G <- EB / (1 - initial_exp)
    return(list(net = EB, gross = G))
  }
  
  # Level premiums (annuity-due)
  a <- a_due(mort, x, sex, term, i, mort_type, select_years, select_factor)
  
  # (1 - initial_exp)*G + (1 - renewal_exp)*G*(a - 1) = EB
  denom <- (1 - initial_exp) + (1 - renewal_exp) * (a - 1)
  G_annual <- EB / denom
  
  if (prem_freq == "Monthly") {
    # Allowed approximation: monthly from yearly
    G_monthly <- G_annual / 12
    return(list(net = EB, gross = G_monthly, gross_annual_equiv = G_annual))
  }
  
  list(net = EB, gross = G_annual)
}