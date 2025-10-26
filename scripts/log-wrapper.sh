#!/bin/bash
# Structured logging wrapper for GitHub Actions Runner
# Converts plain text logs to structured JSON format
# Usage: log-wrapper.sh <level> <message> [context...]

set -euo pipefail

# Log levels (numeric for comparison)
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["FATAL"]=4
)

# Default log level from environment or INFO
DEFAULT_LEVEL="${LOG_LEVEL:-INFO}"
DEFAULT_LEVEL_NUM="${LOG_LEVELS[$DEFAULT_LEVEL]:-1}"

# Function to log structured JSON
log_json() {
    local level="$1"
    local message="$2"
    shift 2

    # Check if we should log this level
    local level_num="${LOG_LEVELS[$level]:-1}"
    if [ "$level_num" -lt "$DEFAULT_LEVEL_NUM" ]; then
        return 0
    fi

    # Build context object from remaining arguments
    local context="{"
    local first=true

    while [ $# -gt 0 ]; do
        if [ "$first" = false ]; then
            context="${context},"
        fi
        first=false

        # Parse key=value pairs
        if [[ "$1" =~ ^([^=]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Escape quotes in value
            value="${value//\"/\\\"}"

            # Check if value is numeric
            if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                context="${context}\"${key}\": ${value}"
            else
                context="${context}\"${key}\": \"${value}\""
            fi
        fi
        shift
    done
    context="${context}}"

    # Escape message quotes
    message="${message//\"/\\\"}"
    message="${message//$'\n'/\\n}"

    # Build JSON log entry
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    local json_log
    json_log=$(cat <<EOF
{"timestamp":"${timestamp}","level":"${level}","message":"${message}","context":${context},"service":"github-actions-runner","host":"$(hostname)"}
EOF
)

    echo "$json_log"
}

# Main function
main() {
    if [ $# -lt 2 ]; then
        log_json "ERROR" "log-wrapper.sh requires at least 2 arguments: <level> <message>"
        exit 1
    fi

    local level="$1"
    local message="$2"
    shift 2

    # Validate log level
    if [ -z "${LOG_LEVELS[$level]:-}" ]; then
        log_json "ERROR" "Invalid log level: ${level}. Valid levels: DEBUG, INFO, WARN, ERROR, FATAL"
        exit 1
    fi

    # Log the message
    log_json "$level" "$message" "$@"

    # Exit with error code for FATAL
    if [ "$level" = "FATAL" ]; then
        exit 1
    fi
}

# Convenience functions for different log levels
log_debug() {
    log_json "DEBUG" "$@"
}

log_info() {
    log_json "INFO" "$@"
}

log_warn() {
    log_json "WARN" "$@"
}

log_error() {
    log_json "ERROR" "$@"
}

log_fatal() {
    log_json "FATAL" "$@"
    exit 1
}

# If sourced, export functions; if executed, run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
else
    export -f log_json log_debug log_info log_warn log_error log_fatal
fi
