#!/bin/bash
#
# Usage:
#   ./typed.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

deps() {
  set -x
  #pip install typing pyannotate

  # got error with 0.67.0
  pip3 install 'mypy==0.660'
}

mypy() { ~/.local/bin/mypy "$@"; }
#pyannotate() { ~/.local/bin/pyannotate "$@"; }

readonly PYANN_REPO=~/git/oilshell/pyannotate/

pyann-patched() {
  local tool=$PYANN_REPO/pyannotate_tools/annotations
  export PYTHONPATH=$PYANN_REPO
  # --dump can help
  python $tool "$@"
}

typecheck() {
  mypy --py2 "$@"
}

check-arith() {
  local strict='--strict'
  MYPYPATH=. PYTHONPATH=. typecheck $strict \
    asdl/typed_arith_parse.py asdl/typed_arith_parse_test.py asdl/tdop.py
}

iter-arith() {
  asdl/run.sh gen-typed-arith-asdl
  check-arith

  export PYTHONPATH=. 
  asdl/typed_arith_parse_test.py

  echo '---'
  asdl/typed_arith_parse.py parse '40+2'
  echo

  echo '---'
  asdl/typed_arith_parse.py eval '40+2+5'
  echo
}

# --no-strict-optional issues
# - simple sum type might be None, but generated PrettyTree() method uses
#   obj.name

iter-demo() {
  asdl/run.sh gen-typed-demo-asdl
  typecheck --strict \
    _devbuild/gen/typed_demo_asdl.py asdl/typed_demo.py

  PYTHONPATH=. asdl/typed_demo.py "$@"
}

collect-types() {
  export PYTHONPATH=".:$PYANN_REPO"
  asdl/pyann_driver.py "$@"

  ls -l type_info.json
  wc -l type_info.json
}

apply-types() {
  #local -a files=( asdl/tdop.py asdl/typed_arith_parse*.py )
  #local -a files=( asdl/unit_test_types.py )
  #local -a files=( unit_test_types.py )

  #local -a files=( core/util.py asdl/runtime.py )
  local -a files=(asdl/format.py )
  pyann-patched --type-info type_info.json "${files[@]}" "$@"
}

apply2() {
  pyann-patched --verbose --type-info type_info.json asdl/unit_test_types.py "$@"
}


"$@"
