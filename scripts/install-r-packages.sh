#!/bin/bash
set -euo pipefail

_url="https://cran.r-project.org"
_install_source=default
_jobs=1

PACKAGES=()

# https://stackoverflow.com/a/14203146
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--bioconductor)
      _install_source=bioconductor
      shift
      ;;
    -u|--url)
      if [[ $# -lt 2 ]]; then
        echo "Error: --url requires an argument" >&2
        exit 1
      fi
      _url="$2"
      shift
      shift
      ;;
    -j|--jobs)
      if [[ $# -lt 2 ]]; then
        echo "Error: --jobs requires an argument" >&2
        exit 1
      fi
      _jobs="$2"
      shift
      shift
      ;;
    *)
      PACKAGES+=("$1")
      shift
      ;;
  esac
done

set -- "${PACKAGES[@]}"

if [ $# -eq 0 ]; then
  {
    echo "Usage: $0 [-b|--bioconductor] [-u|--url CRAN_URL] <package>" \
        "[<package> ...]"
    echo
    echo "Install R packages and return an error if an installation fails."
    echo
    echo "Options:"
    echo "  -b, --bioconductor  Install packages using Bioconductor instead" \
        "of the default installer."
    echo "  -u, --url           Use a custom CRAN mirror."
  } >&2
  exit 1
fi

if [ "$_install_source" = "bioconductor" ]; then
  _install_cmd="BiocManager::install"
  _opts=""
else
  _install_cmd="install.packages"
  _opts=", clean = TRUE, repos = '$_url', Ncpus = $_jobs"
fi

# https://stackoverflow.com/a/52638148
Rscript -e " \
  for (pkg in commandArgs(TRUE)) { \
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) { \
      $_install_cmd(pkg$_opts); \
      library(pkg, character.only = TRUE) \
    } \
  }" "$@"
