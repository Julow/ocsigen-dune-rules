  $ dune build --profile release

  $ ls _build/default/app/my_app.bc _build/default/app/client/my_app.bc.js
  _build/default/app/client/my_app.bc.js
  _build/default/app/my_app.bc

  $ dune runtest

  $ ocsigen-dune-rules gen-library --public-name my_lib my_lib > lib/dune.gen
  $ diff lib/dune.gen lib/dune
