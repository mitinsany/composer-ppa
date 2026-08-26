#!/usr/bin/env bash

set -euo pipefail

package_version="$(jq -r '.version' packages/latest/composer/package.json)"
deb_file="deb/pool/main/c/composer/composer_${package_version}_amd64.deb"
work_dir="$(mktemp -d)"
install_dir="${work_dir}/install"
fake_bin="${work_dir}/bin"
postinstall_script="${work_dir}/postinst"
payload='verified composer payload'
payload_sha256="$(printf '%s' "${payload}" | sha256sum | awk '{print $1}')"

cleanup() {
    rm -rf "${work_dir}"
}
trap cleanup EXIT

mkdir -p "${install_dir}" "${fake_bin}"
dpkg-deb --ctrl-tarfile "${deb_file}" | tar -xOf - ./postinst > "${postinstall_script}"
sed -i "s/^COMPOSER_DOWNLOAD_SHA256=.*/COMPOSER_DOWNLOAD_SHA256='${payload_sha256}'/" "${postinstall_script}"
chmod 0755 "${postinstall_script}"

cat > "${fake_bin}/curl" <<EOF
#!/usr/bin/env bash
printf '%s' '${payload}' > "\${!#}"
EOF
cat > "${fake_bin}/chown" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 0755 "${fake_bin}/curl" "${fake_bin}/chown"

printf '%s' 'old composer' > "${install_dir}/composer"
COMPOSER_INSTALL_DIR="${install_dir}" PATH="${fake_bin}:${PATH}" "${postinstall_script}"
test "$(cat "${install_dir}/composer")" = "${payload}"
test -x "${install_dir}/composer"

sed -i "s/^COMPOSER_DOWNLOAD_SHA256=.*/COMPOSER_DOWNLOAD_SHA256='$(printf '0%.0s' {1..64})'/" "${postinstall_script}"
printf '%s' 'preserve me' > "${install_dir}/composer"
if COMPOSER_INSTALL_DIR="${install_dir}" PATH="${fake_bin}:${PATH}" "${postinstall_script}"; then
    echo 'postinstall unexpectedly accepted an invalid checksum' >&2
    exit 1
fi
test "$(cat "${install_dir}/composer")" = 'preserve me'
if find "${install_dir}" -maxdepth 1 -name '.composer-install.*' | grep -q .; then
    echo 'postinstall left a staging file behind' >&2
    exit 1
fi
