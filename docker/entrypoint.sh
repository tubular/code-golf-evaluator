#! /usr/bin/env bash

#
# Copyright 2022-2026 Chartbeat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
