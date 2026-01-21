#!/bin/bash

post_install_yubico_authenticator() {
    # shellcheck disable=SC2034
	local version=$1
	local dest_path=$2

	# Fix .desktop launcher
	sed -e "s|@EXEC_PATH|$dest_path|g" \
		<"$dest_path/linux_support/com.yubico.yubioath.desktop" \
		>"/usr/share/applications/com.yubico.yubioath.desktop"
}

install_thirdpartysw() {
	log_info "--- Starting Third-Party Software Installation ---"
	install_from_manifest "$1"
}
