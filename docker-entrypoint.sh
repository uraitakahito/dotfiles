#!/bin/bash
set -eo pipefail
shopt -s nullglob

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_main() {
	# If the docker-outside-of-docker feature is installed, delegate to its
	# init script. docker-init.sh syncs the docker group GID with the mounted
	# host socket (or falls back to a socat proxy when GID sync isn't viable)
	# and then `exec "$@"` to start the container's CMD.
	if [ -x /usr/local/share/docker-init.sh ]; then
		exec /usr/local/share/docker-init.sh "$@"
	fi
	exec "$@"
}

# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
