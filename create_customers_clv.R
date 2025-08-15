# Customers: Cohorts, RFM, and CLV (Templates)

suppressPackageStartupMessages({
  pkgs <- c("tidyverse","lubridate")
  for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE)))
})

# Placeholder synthetic transactions
set.seed(7)
n <- 2000
tx <- tibble::tibble(
  customer_id = sample(sprintf("C%04d", 1:400), n, TRUE),
  date = sample(seq.Date(Sys.Date()-365, Sys.Date(), by = "day"), n, TRUE),
  amount = round(rexp(n, 1/50), 2)
)

# RFM
ref_date <- max(tx$date)
rfm <- tx %>%
  group_by(customer_id) %>%
  summarise(
    recency = as.numeric(ref_date - max(date)),
    frequency = n(),
    monetary = sum(amount), .groups = "drop"
  ) %>%
  mutate(
    r_score = ntile(-recency, 5),
    f_score = ntile(frequency, 5),
    m_score = ntile(monetary, 5),
    rfm = paste0(r_score, f_score, m_score)
  )

md <- c(
  "# Customers: RFM and CLV",
  "",
  "## RFM Summary",
  sprintf("- Customers scored across Recency/Frequency/Monetary (N=%d).", nrow(rfm)),
  "- Use top RFM groups for retention and loyalty offers.",
  "",
  "## CLV",
  "- For production, fit BG/NBD + Gamma-Gamma models (BTYD/CLVTools packages).",
  "- Use cohort curves and churn rates to project lifetime value.",
  "",
  "## Plain-English Summary",
  "- RFM scores help spot your best customers (recent, frequent, high spend).",
  "- CLV estimates long-term value so you can decide how much to invest in keeping them."
)
writeLines(md, "CUSTOMERS_CLV_REPORT.md")
cat("Created CUSTOMERS_CLV_REPORT.md (placeholder content)\n")


