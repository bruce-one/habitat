#!/bin/bash

set -euo pipefail

shellcheck --version

# Exclude the handlebars template files since their syntax confuses shellcheck
# There's not much bash in them anyway.
#
# Exclude the bats submodules since we don't own that code.
#
# Exclude the following shellcheck issues since they're pervasive and innocuous:
# https://github.com/koalaman/shellcheck/wiki/SC1090
# https://github.com/koalaman/shellcheck/wiki/SC1091
# https://github.com/koalaman/shellcheck/wiki/SC1117
# https://github.com/koalaman/shellcheck/wiki/SC2148
# https://github.com/koalaman/shellcheck/wiki/SC2034
find . -name "*.*sh" \
	-a \! -path "*_template_plan.sh" \
	-a \! -path "./test/integration/helpers.bash" \
	-a \! -path "./test/integration/test_helper/bats-assert/*" \
	-a \! -path "./test/integration/test_helper/bats-file/*" \
	-a \! -path "./test/integration/test_helper/bats-support/*" \
	| xargs shellcheck --external-sources --exclude=1090,1091,1117,2148,2034

# This is a BATS file, so we need to override the interpreter
# See: https://github.com/koalaman/shellcheck/issues/709
shellcheck --shell=bash --exclude=1008 test/integration/helpers.bash

echo "shellcheck found no errors"
