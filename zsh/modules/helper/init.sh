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

# usage: zshrc_process_init_files [file [file [...]]]
#    ie: zshrc_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions
zshrc_process_init_files() {
	echo
	local f
	for f; do
		case "$f" in
			*.sh)
				# https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
				# https://github.com/docker-library/postgres/pull/452
				if [ -x "$f" ]; then
					my_note "$0: running $f"
					"$f"
				else
					my_note "$0: sourcing $f"
					. "$f"
				fi
				;;
			*)  my_warn "$0: ignoring $f" ;;
		esac
		echo
	done
}
