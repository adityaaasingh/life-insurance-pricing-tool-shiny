# R/01_mortality_build.R
# Build a clean mortality dataset from the AGA ALT workbook.
# Output: data_processed/mortality_ultimate.rds with columns: sex, age, qx, px

library(readxl)
library(dplyr)

RAW_PATH <- "data_raw/aga_alt_2020_22.xlsx"
OUT_PATH <- "data_processed/mortality_ultimate.rds"

read_sheet <- function(sheet_name, sex_label) {
  df <- read_xlsx(RAW_PATH, sheet = sheet_name)
  
  # Keep only what we need (avoids lx vs Lx duplication issues)
  # Assumes columns are named exactly: Age, qx (and optionally px)
  out <- df %>%
    select(Age, qx, px) %>%            
    rename(age = Age) %>%
    mutate(
      sex = sex_label,
      px = ifelse(is.na(px), 1 - qx, px) # just in case px has blanks
    ) %>%
    select(sex, age, qx, px)
  
  out
}


male <- tryCatch(
  read_sheet("SHEET_MALE", "Male"),
  error = function(e) read_sheet_no_px("SHEET_MALE", "Male")
)

female <- tryCatch(
  read_sheet("SHEET_FEMALE", "Female"),
  error = function(e) read_sheet_no_px("SHEET_FEMALE", "Female")
)

mort <- bind_rows(male, female) %>%
  mutate(
    age = as.integer(age),
    qx = as.numeric(qx),
    px = as.numeric(px)
  ) %>%
  arrange(sex, age)

# basic checks
stopifnot(all(mort$qx >= 0 & mort$qx <= 1, na.rm = TRUE))
stopifnot(all(mort$px >= 0 & mort$px <= 1, na.rm = TRUE))

dir.create("data_processed", showWarnings = FALSE)
saveRDS(mort, OUT_PATH)
cat("Mortality table saved to:", OUT_PATH, "\n")