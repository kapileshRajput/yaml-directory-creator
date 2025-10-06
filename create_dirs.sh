#!/usr/bin/env bash

#######################################################################
# YAML Directory Structure Creator
# 
# This script reads a YAML file describing a directory structure with
# metadata and creates the directories accordingly with permissions,
# ownership, and default files.
#
# Usage: ./create_dirs.sh <yaml_file> [base_directory]
#######################################################################

set -euo pipefail

#######################################################################
# Configuration & Constants
#######################################################################

readonly SCRIPT_NAME=$(basename "$0")
readonly YQ_MIN_VERSION="4"

#######################################################################
# Color codes for output
#######################################################################

if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

#######################################################################
# Helper Functions
#######################################################################

# Print error message and exit
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Print warning message
warn() {
    echo -e "${YELLOW}WARNING: $1${NC}" >&2
}

# Print info message
info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

# Print success message
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Display usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <yaml_file> [base_directory]

Arguments:
    yaml_file         Path to YAML file describing directory structure
    base_directory    Optional base directory for creation (default: current directory)

Example YAML structure:
    project:
      permissions: "755"
      owner: "username"
      default_files:
        - README.md
        - .gitignore
      subdirs:
        src:
          permissions: "755"
          default_files:
            - main.py
        docs:
          permissions: "755"

Requirements:
    - yq v4+ must be installed (https://github.com/mikefarah/yq)

EOF
    exit 1
}

#######################################################################
# Validation Functions
#######################################################################

# Check if yq is installed and meets version requirements
check_yq() {
    if ! command -v yq &> /dev/null; then
        error_exit "yq is not installed. Please install yq v4+ from https://github.com/mikefarah/yq"
    fi
    
    local yq_version
    yq_version=$(yq --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    
    if [[ -z "$yq_version" ]] || [[ "$yq_version" -lt "$YQ_MIN_VERSION" ]]; then
        error_exit "yq version 4 or higher is required. Please upgrade yq."
    fi
    
    info "Using yq version: $(yq --version)"
}

# Validate YAML file
validate_yaml_file() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        error_exit "YAML file not found: $yaml_file"
    fi
    
    if [[ ! -r "$yaml_file" ]]; then
        error_exit "YAML file is not readable: $yaml_file"
    fi
    
    # Test if file is valid YAML
    if ! yq eval '.' "$yaml_file" &> /dev/null; then
        error_exit "Invalid YAML syntax in file: $yaml_file"
    fi
}

# Validate base directory
validate_base_dir() {
    local base_dir="$1"
    
    if [[ ! -d "$base_dir" ]]; then
        error_exit "Base directory does not exist: $base_dir"
    fi
    
    if [[ ! -w "$base_dir" ]]; then
        error_exit "Base directory is not writable: $base_dir"
    fi
}

#######################################################################
# Core Functions
#######################################################################

# Create a single directory with metadata
create_directory() {
    local dir_path="$1"
    local yaml_path="$2"
    local yaml_file="$3"
    
    info "Creating directory: $dir_path"
    
    # Create the directory if it doesn't exist
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path" || error_exit "Failed to create directory: $dir_path"
    fi
    
    # Apply permissions if specified
    local permissions
    permissions=$(yq eval "${yaml_path}.permissions // \"\"" "$yaml_file")
    if [[ -n "$permissions" ]]; then
        info "  Setting permissions: $permissions"
        chmod "$permissions" "$dir_path" || warn "Failed to set permissions on: $dir_path"
    fi
    
    # Apply ownership if specified
    local owner
    owner=$(yq eval "${yaml_path}.owner // \"\"" "$yaml_file")
    if [[ -n "$owner" ]]; then
        info "  Setting owner: $owner"
        if [[ "$EUID" -eq 0 ]]; then
            chown "$owner" "$dir_path" || warn "Failed to set owner on: $dir_path"
        else
            warn "Cannot set owner (not root). Skipping chown for: $dir_path"
        fi
    fi
    
    # Create default files if specified
    local default_files_length
    default_files_length=$(yq eval "${yaml_path}.default_files // [] | length" "$yaml_file")
    
    if [[ "$default_files_length" -gt 0 ]]; then
        info "  Creating default files..."
        local i
        for ((i=0; i<default_files_length; i++)); do
            local filename
            filename=$(yq eval "${yaml_path}.default_files[$i]" "$yaml_file")
            local filepath="$dir_path/$filename"
            
            if [[ ! -f "$filepath" ]]; then
                touch "$filepath" || warn "Failed to create file: $filepath"
                info "    Created: $filename"
            else
                info "    Skipped (exists): $filename"
            fi
        done
    fi
}

# Recursively process directory structure
process_directory() {
    local base_path="$1"
    local yaml_path="$2"
    local yaml_file="$3"
    
    # Create the current directory
    create_directory "$base_path" "$yaml_path" "$yaml_file"
    
    # Check for subdirectories
    local subdirs_path="${yaml_path}.subdirs"
    local has_subdirs
    has_subdirs=$(yq eval "$subdirs_path // null" "$yaml_file")
    
    if [[ "$has_subdirs" != "null" ]]; then
        # Get all subdirectory keys
        local subdir_keys
        subdir_keys=$(yq eval "${subdirs_path} | keys | .[]" "$yaml_file")
        
        if [[ -n "$subdir_keys" ]]; then
            while IFS= read -r subdir_name; do
                if [[ -n "$subdir_name" ]]; then
                    local new_base_path="$base_path/$subdir_name"
                    local new_yaml_path="${subdirs_path}.${subdir_name}"
                    
                    # Recursively process subdirectory
                    process_directory "$new_base_path" "$new_yaml_path" "$yaml_file"
                fi
            done <<< "$subdir_keys"
        fi
    fi
}

# Main processing function
process_yaml_structure() {
    local yaml_file="$1"
    local base_dir="$2"
    
    # Get all top-level directory keys
    local root_keys
    root_keys=$(yq eval 'keys | .[]' "$yaml_file")
    
    if [[ -z "$root_keys" ]]; then
        warn "No directories found in YAML file"
        return
    fi
    
    # Process each root directory
    while IFS= read -r dir_name; do
        if [[ -n "$dir_name" ]]; then
            local dir_path="$base_dir/$dir_name"
            local yaml_path=".${dir_name}"
            
            process_directory "$dir_path" "$yaml_path" "$yaml_file"
        fi
    done <<< "$root_keys"
}

#######################################################################
# Main Script Logic
#######################################################################

main() {
    # Parse arguments
    if [[ $# -lt 1 ]]; then
        usage
    fi
    
    local yaml_file="$1"
    local base_dir="${2:-.}"
    
    # Convert to absolute paths
    yaml_file=$(cd "$(dirname "$yaml_file")" && pwd)/$(basename "$yaml_file")
    base_dir=$(cd "$base_dir" && pwd)
    
    info "Starting directory structure creation..."
    info "YAML file: $yaml_file"
    info "Base directory: $base_dir"
    echo
    
    # Perform validation checks
    check_yq
    validate_yaml_file "$yaml_file"
    validate_base_dir "$base_dir"
    
    echo
    
    # Process the YAML structure
    process_yaml_structure "$yaml_file" "$base_dir"
    
    echo
    success "Directory structure created under: $base_dir"
}

# Execute main function
main "$@"
