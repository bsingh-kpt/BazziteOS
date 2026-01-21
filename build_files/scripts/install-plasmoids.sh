#!/bin/bash

install_plasmoids() {
    log_info "--- Starting Plasmoid Installation ---"
	install_from_manifest "$1"
}
