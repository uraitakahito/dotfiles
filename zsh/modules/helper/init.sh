#
# logging functions
#
my_log() {
	local type="$1"; shift
	# accept argument string or stdin
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
	local dt; dt="$(date -R)"
	printf '%s [%s] [Entrypoint]: %s\n' "$dt" "$type" "$text"
}
my_note() {
	my_log Note "$@"
}
my_warn() {
	my_log Warn "$@" >&2
}
my_error() {
	my_log ERROR "$@" >&2
	exit 1
}

# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}

# Checks if running in a container.
function is-docker {
  [[ -e /.dockerenv ]]
}

# Checks if running on Visual Studio Code Terminal.
function is-vscode {
  [[ "$TERM_PROGRAM" == "vscode" ]]
}

# Checks if script is being executed by VS Code.
# NOTE:
#  1. After installation, this environment variable will be removed.
#  2. When install.sh is executed, the 'code' CLI is not yet installed.
function has-vscode-remote-containers {
  [[ -n "${VSCODE_REMOTE_CONTAINERS_SESSION:-}" ]]
}
