# Test Modules
# Verifies that all R modules can be sourced without syntax errors

message("Testing module loading...")

tryCatch(
    {
        source("R/utils.R")
        message("[PASS] R/utils.R")

        source("R/data.R")
        message("[PASS] R/data.R")

        source("R/analysis.R")
        message("[PASS] R/analysis.R")

        source("R/viz.R")
        message("[PASS] R/viz.R")

        source("R/reporting.R")
        message("[PASS] R/reporting.R")

        message("All modules loaded successfully.")
    },
    error = function(e) {
        message("Module load FAILED: ", conditionMessage(e))
        quit(status = 1)
    }
)
