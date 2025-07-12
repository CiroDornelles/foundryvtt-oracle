#!/bin/bash
# Makes the script exit immediately if a command exits with a non-zero status.
set -euo pipefail

# Get the directory where the script is located to build relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Remove scripts from the project root (if they were created there)
rm -f "${SCRIPT_DIR}/diagnose_oci_auth.py"
rm -f "${SCRIPT_DIR}/run_oci_diagnosis.sh"
rm -f "${SCRIPT_DIR}/run_oci_debug_command.sh"

# Remove all scripts from the /tmp directory within the project
rm -f "${SCRIPT_DIR}/tmp/clean_oci_keys.sh"
rm -f "${SCRIPT_DIR}/tmp/display_oci_key_info.sh"
rm -f "${SCRIPT_DIR}/tmp/generate_oci_key.sh"
rm -f "${SCRIPT_DIR}/tmp/generate_primary_oci_key.sh"
rm -f "${SCRIPT_DIR}/tmp/get_id_rsa_fingerprint.sh"
rm -f "${SCRIPT_DIR}/tmp/get_id_rsa_info.sh"
rm -f "${SCRIPT_DIR}/tmp/get_oci_api_key_fingerprint.sh"
rm -f "${SCRIPT_DIR}/tmp/test_oci_auth.sh"

# Finally, remove the /tmp directory if it's empty
# Use rmdir for safety, it will only remove empty directories
rmdir "${SCRIPT_DIR}/tmp" || echo "Directory 'tmp' not empty or does not exist. Skipping removal."
