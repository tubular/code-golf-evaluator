#! /usr/bin/env bash

BINDIR=$(dirname $0)
APPPATH=$(readlink -f "$BINDIR/..")
source "/app/.sdkman/bin/sdkman-init.sh"
source "/app/.nvm/nvm.sh"

CMD="$1"
shift

case "$CMD" in
    test)
	prove -e "raku -I${APPPATH}/lib" --ext rakutest ${APPPATH}/t
	;;
    code-golf)
	raku -I"${APPPATH}/lib" "${APPPATH}/bin/code-golf" "$@"
	;;
    versions)
	echo "=== Language Versions ==="
	echo "Node.js: $(node --version)"
	echo "npm: $(npm --version)"
	echo "Raku: $(raku --version | head -1)"
	echo "Scala: $(scala -version 2>&1)"
	echo "Java: $(java -version 2>&1 | head -1)"
	echo "Perl: $(perl --version | grep 'This is perl' | head -1)"
	echo "Python: $(python3 --version)"
	echo "pip: $(pip --version | head -1)"
	;;
    *)
	echo "Unknown option: $CMD"
	echo "Usage: $0 <test|code-golf|versions>"
	exit 1
	;;
esac
