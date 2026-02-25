# R/05_reserves.R
# Prospective reserves and endpoint conventions

source("R/04_products_premium.R")

calc_reserves <- function(mort, product, premium_type, prem_freq,
                          x, sex, term, i, B,
                          timing = c("EOY", "Immediate"),
                          mort_type = "Ultimate",
                          select_years = 2, select_factor = 0.85,
                          initial_exp = 0, renewal_exp = 0, claim_exp = 0,
                          bonus = 0, inflation = 0) {
  
  timing <- match.arg(timing)
  
  if (product == "Whole Life Assurance") term <- 100 - x
  
  prem <- calc_premium(mort, product, premium_type, prem_freq,
                       x, sex, term, i, B, timing,
                       mort_type, select_years, select_factor,
                       initial_exp, renewal_exp, claim_exp,
                       bonus, inflation)
  
  G <- prem$gross
  
  reserves <- data.frame(t = 0:term, V = NA_real_)
  
  for (t in 0:term) {
    
    # Endpoint rules
    if (t == term) {
      if (product %in% c("Pure Endowment", "Endowment Assurance")) {
        # Reserve at T before survival benefit payment is B
        reserves$V[reserves$t == t] <- B
      } else {
        # After death benefit payment, term/whole life reserve is 0
        reserves$V[reserves$t == t] <- 0
      }
      next
    }
    
    rem <- term - t
    xt <- x + t
    
    EB_t <- benefit_epv(
      mort, product, xt, sex, rem, i, B, timing,
      mort_type, select_years, select_factor,
      claim_exp, bonus, inflation
    )
    
    if (premium_type == "Single") {
      EPVprem_t <- 0
    } else {
      a_t <- a_due(mort, xt, sex, rem, i, mort_type, select_years, select_factor)
      
      # After issue (t>0), treat remaining premiums as renewal-expensed
      if (t == 0) {
        EPVprem_t <- G * ((1 - initial_exp) + (1 - renewal_exp) * (a_t - 1))
      } else {
        EPVprem_t <- G * (1 - renewal_exp) * a_t
      }
    }
    
    reserves$V[reserves$t == t] <- EB_t - EPVprem_t
  }
  
  reserves
}