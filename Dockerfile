# renovate: datasource=docker depName=hansohn/terraform
ARG TERRAFORM_VERSION=1.16.0


# builder
FROM hansohn/terraform:${TERRAFORM_VERSION} AS builder
ARG DEBIAN_FRONTEND=noninteractive
# renovate: datasource=github-releases depName=terraform-linters/tflint-ruleset-azurerm extractVersion=^v(?<version>.+)$
ARG TFLINT_AZURERM_VERSION=0.32.0
# The Azure CLI apt repository is signed by the Microsoft release key. Trust is
# pinned to this fingerprint; the armored key is fetched over HTTPS at build
# time and rejected unless it matches, so key rotation can't silently widen
# what the final image will install.
ARG MICROSOFT_GPG_FINGERPRINT=BC528686B50D79E339D3721CEB3E94ADBE1229CF
ENV CURL='curl -fsSL'
ENV CACHE_DIR='/var/cache/github-api'
COPY scripts/resolve-version.sh /opt/build/resolve-version
COPY config/.tflint.hcl /root/.tflint.hcl
RUN apt-get update && apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      gnupg \
      jq \
      unzip \
  && mkdir -p ${CACHE_DIR} \
  && rm -rf /var/lib/apt/lists/*

# tflint-ruleset-azurerm
# Installed directly as a manually-managed plugin (no `tflint --init`), so the
# build never reaches out to the GitHub API at lint time and the version is
# pinned and checksum-verified here.
RUN --mount=type=cache,target=/var/cache/github-api \
    --mount=type=cache,target=/var/cache/downloads \
    /bin/bash -c 'set -e; \
  TFLINT_AZURERM_VERSION=$(/opt/build/resolve-version tflint-ruleset-azurerm "${TFLINT_AZURERM_VERSION}"); \
  case "$(uname -m)" in \
    x86_64) ARCH=amd64 ;; \
    aarch64) ARCH=arm64 ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac; \
  ARCHIVE="tflint-ruleset-azurerm_linux_${ARCH}.zip"; \
  if [[ ! -f "/var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}-${ARCH}.zip" ]]; then \
  ${CURL} https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM_VERSION}/${ARCHIVE} -o /var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}-${ARCH}.zip; \
  fi; \
  if [[ ! -f "/var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}_checksums.txt" ]]; then \
  ${CURL} https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM_VERSION}/checksums.txt -o /var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}_checksums.txt; \
  fi; \
  EXPECTED_SHA=$(grep " ${ARCHIVE}\$" /var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}_checksums.txt | cut -d" " -f1); \
  ACTUAL_SHA=$(sha256sum /var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}-${ARCH}.zip | cut -d" " -f1); \
  if [[ -z "${EXPECTED_SHA}" ]] || [[ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]]; then \
  echo "Checksum verification failed for ${ARCHIVE}" >&2; exit 1; \
  fi; \
  mkdir -p /root/.tflint.d/plugins; \
  unzip -o /var/cache/downloads/tflint-ruleset-azurerm-${TFLINT_AZURERM_VERSION}-${ARCH}.zip -d /root/.tflint.d/plugins \
  && chmod +x /root/.tflint.d/plugins/tflint-ruleset-azurerm \
  && tflint --version'

# microsoft apt signing key
RUN /bin/bash -c 'set -e; \
  ${CURL} https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc; \
  export GNUPGHOME="$(mktemp -d)"; \
  ACTUAL_FINGERPRINT=$(gpg --batch --show-keys --with-colons /tmp/microsoft.asc | grep "^fpr:" | head -1 | cut -d: -f10); \
  if [[ "${ACTUAL_FINGERPRINT}" != "${MICROSOFT_GPG_FINGERPRINT}" ]]; then \
  echo "Microsoft signing key fingerprint mismatch: got ${ACTUAL_FINGERPRINT}" >&2; exit 1; \
  fi; \
  mkdir -p /etc/apt/keyrings; \
  gpg --batch --dearmor --output /etc/apt/keyrings/microsoft.gpg /tmp/microsoft.asc; \
  chmod go+r /etc/apt/keyrings/microsoft.gpg; \
  gpgconf --kill all || true; \
  rm -rf "${GNUPGHOME}" /tmp/microsoft.asc'


# main
FROM hansohn/terraform:${TERRAFORM_VERSION} AS main
ARG DEBIAN_FRONTEND=noninteractive
# renovate: datasource=github-releases depName=Azure/azure-cli extractVersion=^azure-cli-(?<version>.+)$
ARG AZURE_CLI_VERSION=2.89.1
COPY --from=builder /etc/apt/keyrings/microsoft.gpg /etc/apt/keyrings/microsoft.gpg
# The Azure CLI ships as a Debian package rather than a standalone archive, so
# it is installed here instead of being staged in the builder: apt resolves the
# shared libraries it links against and verifies the repository signature
# against the key pinned above. `latest` installs whatever the repo currently
# publishes; any other value pins the exact package revision.
RUN /bin/bash -c 'set -e; \
  . /etc/os-release; \
  printf "Types: deb\nURIs: https://packages.microsoft.com/repos/azure-cli/\nSuites: %s\nComponents: main\nArchitectures: %s\nSigned-by: /etc/apt/keyrings/microsoft.gpg\n" \
    "${VERSION_CODENAME}" "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/azure-cli.sources; \
  if [[ "${AZURE_CLI_VERSION}" == "latest" ]]; then \
  AZURE_CLI_PKG="azure-cli"; \
  else \
  AZURE_CLI_PKG="azure-cli=${AZURE_CLI_VERSION}-1~${VERSION_CODENAME}"; \
  fi; \
  apt-get update; \
  apt-get install --no-install-recommends -y "${AZURE_CLI_PKG}"; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*'
COPY --from=builder /root/.tflint.d/ /root/.tflint.d/
COPY --from=builder /root/.tflint.hcl /root/.tflint.hcl
RUN printf '\n[ -f /etc/bash_completion.d/azure-cli ] && source /etc/bash_completion.d/azure-cli\n' >> /root/.bashrc \
  && az version \
  && terraform --version

ENTRYPOINT []
