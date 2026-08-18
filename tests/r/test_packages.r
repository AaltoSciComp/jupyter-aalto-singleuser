# Check and update Bayesian R packages
#
# Packages:
#   brms, rstanarm, cmdstanr, loo, rstan, posterior, bayesplot, priorsense

cran_packages <- c(
  "brms",
  "rstanarm",
  "loo",
  "rstan",
  "posterior",
  "bayesplot",
  "priorsense"
)

cmdstanr_repo <- "https://stan-dev.r-universe.dev"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

check_cran_packages <- function(packages) {
  cat("\n=== CRAN packages ===\n\n")

  installed <- rownames(installed.packages())

  for (pkg in packages) {
    if (!(pkg %in% installed)) {
      cat(sprintf("%-12s NOT INSTALLED\n", pkg))
      next
    }

    installed_version <- packageVersion(pkg)

    available <- tryCatch(
      as.character(available.packages()[pkg, "Version"]),
      error = function(e) NA_character_
    )

    if (is.na(available)) {
      cat(sprintf(
        "%-12s installed: %-12s latest: UNKNOWN\n",
        pkg, installed_version
      ))
    } else if (package_version(installed_version) < package_version(available)) {
      cat(sprintf(
        "%-12s installed: %-12s latest: %-12s OUTDATED\n",
        pkg, installed_version, available
      ))
    } else {
      cat(sprintf(
        "%-12s installed: %-12s latest: %-12s OK\n",
        pkg, installed_version, available
      ))
    }
  }
}


check_cmdstanr <- function() {
  cat("\n=== cmdstanr ===\n\n")

  if (!requireNamespace("cmdstanr", quietly = TRUE)) {
    cat("cmdstanr     NOT INSTALLED\n")
    return(invisible(FALSE))
  }

  installed <- packageVersion("cmdstanr")

  repo_packages <- tryCatch(
    available.packages(
      repos = cmdstanr_repo
    ),
    error = function(e) NULL
  )

  if (is.null(repo_packages) || !("cmdstanr" %in% rownames(repo_packages))) {
    cat(sprintf(
      "cmdstanr     installed: %-12s latest: UNKNOWN\n",
      installed
    ))
    return(invisible(TRUE))
  }

  latest <- package_version(repo_packages["cmdstanr", "Version"])

  if (installed < latest) {
    cat(sprintf(
      "cmdstanr     installed: %-12s latest: %-12s OUTDATED\n",
      installed, latest
    ))
  } else {
    cat(sprintf(
      "cmdstanr     installed: %-12s latest: %-12s OK\n",
      installed, latest
    ))
  }

  invisible(TRUE)
}


# ---------------------------------------------------------------------------
# Check current versions
# ---------------------------------------------------------------------------

check_cran_packages(cran_packages)
check_cmdstanr()


# ---------------------------------------------------------------------------
# Update packages
# ---------------------------------------------------------------------------

#cat("\n=== Updating packages ===\n\n")
#
## Update CRAN packages.
#update.packages(
#  pkgs = cran_packages,
#  repos = c(CRAN = "https://cloud.r-project.org"),
#  ask = FALSE,
#  checkBuilt = TRUE
#)
#
## Install/update cmdstanr from the Stan r-universe.
#if (requireNamespace("cmdstanr", quietly = TRUE)) {
#  install.packages(
#    "cmdstanr",
#    repos = c(
#      cmdstanr_repo,
#      "https://cloud.r-project.org"
#    )
#  )
#} else {
#  install.packages(
#    "cmdstanr",
#    repos = c(
#      cmdstanr_repo,
#      "https://cloud.r-project.org"
#    )
#  )
#}
#
#
## ---------------------------------------------------------------------------
## Final verification
## ---------------------------------------------------------------------------
#
#cat("\n=== Final versions ===\n\n")
#
#all_packages <- c(cran_packages, "cmdstanr")
#
#for (pkg in all_packages) {
#  if (requireNamespace(pkg, quietly = TRUE)) {
#    cat(sprintf(
#      "%-12s %s\n",
#      pkg,
#      packageVersion(pkg)
#    ))
#  } else {
#    cat(sprintf(
#      "%-12s NOT INSTALLED\n",
#      pkg
#    ))
#  }
#}

cat("\nDone.\n")
