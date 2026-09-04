  $ ocsigen-dune-rules gen-library --server-libraries a --client-libraries b --libraries c --server-preprocess p1 --client-preprocess p2 --preprocess p3 --wrapped false my_lib > dune

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
     gen-library
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
     --wrapped
     false
     my_lib)))
  
  ;
  ; Below this line, any changes will be overwritten.
  ;
  
  (rule
   (alias runtest)
   (action
    (diff dune dune.corrected)))
  
  (library
   (public_name my_lib.server)
   (name my_lib)
   (modes byte native)
   (wrapped false)
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
   (library
    (public_name my_lib.client)
    (name my_lib)
    (modes byte)
    (wrapped false)
    (library_flags
     (:standard -linkall))
    (preprocess
     (pps js_of_ocaml-ppx js_of_ocaml-ppx_deriving_json p2 p3))
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

Remove the --rpc-raw flag:

  $ ocsigen-dune-rules gen-library --no-rpc-raw --wrapped false my_lib | grep pps
    (pps eliom.ppx.server ocsigen-ppx-rpc js_of_ocaml-ppx_deriving_json))
     (pps js_of_ocaml-ppx js_of_ocaml-ppx_deriving_json))

Warns when passing a default library or preprocessor:

  $ ocsigen-dune-rules gen-library --server-libraries eliom.server --libraries js_of_ocaml --server-preprocess eliom.ppx.server --client-preprocess js_of_ocaml-ppx --wrapped false my_lib >/dev/null
  Error: client preprocess "js_of_ocaml-ppx" is already included by default.
  Error: server preprocess "eliom.ppx.server" is already included by default.
  Error: client library "js_of_ocaml" is already included by default.
  Error: server library "eliom.server" is already included by default.
  [1]

--wrapped true generates an error for now.

  $ ocsigen-dune-rules gen-library --wrapped true my_lib
  Error: Wrapped libraries are not supported.
  [1]
