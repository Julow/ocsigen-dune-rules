  $ ocsigen-dune-rules gen-application --server-libraries a --client-libraries b --libraries c --server-preprocess p1 --client-preprocess p2 --preprocess p3 my_app > dune

  $ dune format-dune-file dune > dune.fmt
  $ diff dune dune.fmt

  $ cat dune
  ;
  ; This Dune file was generated with ocsigen-dune-rules.
  ; To update it, modify the invocation below and run
  ;
  ;     dune runtest --auto-promote
  ;
  
  (rule
   (with-stdout-to
    dune.corrected
    (run
     ocsigen-dune-rules
     gen-application
     --server-libraries
     a
     --client-libraries
     b
     --libraries
     c
     --server-preprocess
     p1
     --client-preprocess
     p2
     --preprocess
     p3
     my_app)))
  
  ;
  ; Below this line, any changes will be overwritten.
  ;
  
  (rule
   (alias runtest)
   (action
    (diff dune dune.corrected)))
  
  (executable
   (public_name my_app)
   (name my_app)
   (package my_app)
   (modes byte native)
   (preprocess
    (pps
     eliom.ppx.server
     ocsigen-ppx-rpc
     js_of_ocaml-ppx_deriving_json
     --rpc-raw
     p1
     p3))
   (libraries eliom.server ocsigenserver js_of_ocaml a c))
  
  (subdir
   client
   (executable
    (name my_app)
    (modes js byte)
    (preprocess
     (pps js_of_ocaml-ppx js_of_ocaml-ppx_deriving_json p2 p3))
    (js_of_ocaml
     (build_runtime_flags :standard --enable use-js-string)
     (flags :standard --enable with-js-error --enable use-js-string))
    (libraries eliom.client js_of_ocaml js_of_ocaml-lwt b c))
   (dynamic_include ../dune.client))
  
  (rule
   (deps
    (glob_files *.eliom)
    (glob_files *.eliomi))
   (action
    (with-stdout-to
     dune.client
     (run ocsigen-dune-rules gen-client-modules .))))
  
  (rule
   (alias runtest)
   (action
    (run
     ocsigen-dune-rules
     check-modules
     --client
     %{dep:client/my_app.bc}
     --server
     %{dep:my_app.bc})))

Warns when passing a default library or preprocessor:

  $ ocsigen-dune-rules gen-application --libraries js_of_ocaml --server-preprocess eliom.ppx.server --client-preprocess js_of_ocaml-ppx my_app >/dev/null
  Error: client preprocess "js_of_ocaml-ppx" is already included by default.
  Error: server preprocess "eliom.ppx.server" is already included by default.
  Error: client library "js_of_ocaml" is already included by default.
  Error: server library "js_of_ocaml" is already included by default.
  [1]

The name can be changed:

  $ ocsigen-dune-rules gen-application my_app > dune.1
  $ ocsigen-dune-rules gen-application --name main my_app > dune.2
  $ diff dune.1 dune.2
  11c11
  <   (run ocsigen-dune-rules gen-application my_app)))
  ---
  >   (run ocsigen-dune-rules gen-application --name main my_app)))
  24c24
  <  (name my_app)
  ---
  >  (name main)
  38c38
  <   (name my_app)
  ---
  >   (name main)
  64c64
  <    %{dep:client/my_app.bc}
  ---
  >    %{dep:client/main.bc}
  66c66
  <    %{dep:my_app.bc})))
  ---
  >    %{dep:main.bc})))
  [1]

Flags:

  $ ocsigen-dune-rules gen-application --wasm my_app > dune.2
  $ diff dune.1 dune.2
  11c11
  <   (run ocsigen-dune-rules gen-application my_app)))
  ---
  >   (run ocsigen-dune-rules gen-application --wasm my_app)))
  39c39
  <   (modes js byte)
  ---
  >   (modes js wasm byte)
  [1]
