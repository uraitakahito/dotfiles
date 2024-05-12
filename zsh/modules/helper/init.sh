# Checks if running on MacOS Darwin.
function is-darwin {
  [[ "$OSTYPE" == darwin* ]]
}
