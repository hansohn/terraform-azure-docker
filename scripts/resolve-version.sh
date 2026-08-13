#!/bin/bash
# resolve-version.sh TOOL VERSION
#
# Echoes the resolved release version for TOOL. If VERSION is anything other
# than "latest" it is echoed back unchanged (pinned versions pass through).
# Otherwise the latest release is looked up via the tool's release API and
# cached in ${CACHE_DIR} for one hour so repeated builds don't hammer the API.
#
# Only the Azure-specific tooling layered on top of the base terraform image is
# handled here; the base image resolves its own tool versions at build time.
# The Azure CLI is not listed because it is installed from the Microsoft apt
# repository, where "latest" is resolved by apt itself.
set -euo pipefail

TOOL="${1:?usage: resolve-version.sh TOOL VERSION}"
VERSION="${2:?usage: resolve-version.sh TOOL VERSION}"

CURL="${CURL:-curl -fsSL}"
CACHE_DIR="${CACHE_DIR:-/var/cache/github-api}"

if [[ "${VERSION}" != "latest" ]]; then
  echo "${VERSION}"
  exit 0
fi

mkdir -p "${CACHE_DIR}"
CACHE_FILE="${CACHE_DIR}/${TOOL}-version"
if [[ -f "${CACHE_FILE}" ]] && [[ $(($(date +%s) - $(stat -c %Y "${CACHE_FILE}" 2>/dev/null || echo 0))) -lt 3600 ]]; then
  cat "${CACHE_FILE}"
  exit 0
fi

case "${TOOL}" in
  tflint-ruleset-azurerm)
    VERSION=$(${CURL} "https://api.github.com/repos/terraform-linters/tflint-ruleset-azurerm/releases/latest" | jq -r .tag_name | sed -e "s:^v::") ;;
  *)
    echo "resolve-version.sh: unknown tool '${TOOL}'" >&2
    exit 1 ;;
esac

if [[ -z "${VERSION}" ]] || [[ "${VERSION}" == "null" ]]; then
  echo "resolve-version.sh: failed to resolve latest version for '${TOOL}'" >&2
  exit 1
fi

echo "${VERSION}" > "${CACHE_FILE}"
echo "${VERSION}"
