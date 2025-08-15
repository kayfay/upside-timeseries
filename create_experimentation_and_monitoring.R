# Experimentation and Monitoring (Templates)

suppressPackageStartupMessages({
  pkgs <- c("tidyverse")
  for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE)))
})

# Power analysis (simplified)
power_calc <- function(effect_sd = 1, effect_size = 0.3, alpha = 0.05, power = 0.8) {
  # Cohen's d based sample size per group for two-sample t-test
  d <- effect_size
  z_alpha <- qnorm(1 - alpha/2)
  z_beta <- qnorm(power)
  n <- 2 * (effect_sd^2) * (z_alpha + z_beta)^2 / (effect_sd^2 * d^2)
  ceiling(n)
}

md <- c(
  "# Experimentation & Monitoring",
  "",
  "## Power Planning",
  sprintf("- Sample size per group for d=0.3 at 80%% power: %d.", power_calc()),
  "",
  "## Monitoring",
  "- Track forecast error (MASE/MAPE), residual drift, and stability weekly; add retraining triggers.",
  "- Log model cards and decision logs for governance.",
  "",
  "## Plain-English Summary",
  "- Power planning tells you how many samples you need so tests have a good chance to see real effects.",
  "- Monitoring is a weekly health check for your models to catch issues early and keep accuracy high."
)
writeLines(md, "EXPERIMENTATION_MONITORING_REPORT.md")
cat("Created EXPERIMENTATION_MONITORING_REPORT.md (placeholder content)\n")


