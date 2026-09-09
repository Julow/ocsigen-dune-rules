  $ ocsigen-dune-rules gen-application --server-libraries a --client-libraries b --libraries c --server-preprocess p1 --client-preprocess p2 --preprocess p3 my_app > dune

  $ dune format-dune-file dune > dune.fmt
  $ diff dune dune.fmt

  $ cat dune
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
     my_app
     --dune
     %{dep:dune})))
  
  ; [ocsigen-dune-rules] Do not remove this line.
  ; Below this line, any changes will be overwritten.
  ;
  ; To update the rules below, modify the invocation of ocsigen-dune-rules above
  ; and run:
  ;
  ;     dune runtest --auto-promote
  ;
  
  (rule
   (alias runtest)
   (action
    (diff dune dune.corrected)))
  
  (library
   (public_name my_app)
   (name my_app)
   (modes byte native)
   (library_flags
    (:standard -linkall))
   (preprocess
    (pps
     eliom.ppx.server
     ocsigen-ppx-rpc
     js_of_ocaml-ppx_deriving_json
     --rpc-raw
     p1
     p3))
   (libraries eliom.server a c))
  
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
     %{dep:check_modules/main.bc})))
  
  (subdir
   check_modules
   (rule
    (write-file main.ml ""))
   (executable
    (name main)
    (modes byte)
    (link_flags
     (:standard -linkall))
    (libraries my_app)))

Warns when passing a default library or preprocessor:

  $ ocsigen-dune-rules gen-application --libraries js_of_ocaml --server-preprocess eliom.ppx.server --client-preprocess js_of_ocaml-ppx my_app >/dev/null
  Error: client preprocess "js_of_ocaml-ppx" is already included by default.
  Error: server preprocess "eliom.ppx.server" is already included by default.
  Error: client library "js_of_ocaml" is already included by default.
  [1]

The name can be changed:

  $ ocsigen-dune-rules gen-application my_app > dune.1
  $ ocsigen-dune-rules gen-application --name main my_app > dune.2
  $ diff dune.1 dune.2
  4c4,11
  <   (run ocsigen-dune-rules gen-application my_app --dune %{dep:dune})))
  ---
  >   (run
  >    ocsigen-dune-rules
  >    gen-application
  >    --name
  >    main
  >    my_app
  >    --dune
  >    %{dep:dune})))
  22c29
  <  (name my_app)
  ---
  >  (name main)
  37c44
  <   (name my_app)
  ---
  >   (name main)
  63c70
  <    %{dep:client/my_app.bc}
  ---
  >    %{dep:client/main.bc}
  76c83
  <   (libraries my_app)))
  ---
  >   (libraries main)))
  [1]

Flags:

  $ ocsigen-dune-rules gen-application --wasm my_app > dune.2
  $ diff dune.1 dune.2
  4c4
  <   (run ocsigen-dune-rules gen-application my_app --dune %{dep:dune})))
  ---
  >   (run ocsigen-dune-rules gen-application --wasm my_app --dune %{dep:dune})))
  38c38
  <   (modes js byte)
  ---
  >   (modes js wasm byte)
  [1]
