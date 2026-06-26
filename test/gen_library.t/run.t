  $ ocsigen-dune-rules gen-library --server-libraries a --client-libraries b --libraries c --server-preprocess p1 --client-preprocess p2 --preprocess p3 my_lib > dune

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
    (pps eliom.ppx.server ocsigen-ppx-rpc --rpc-raw p1 p3))
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
     (pps js_of_ocaml-ppx p2 p3))
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

  $ ocsigen-dune-rules gen-library --no-rpc-raw my_lib | grep pps
    (pps eliom.ppx.server ocsigen-ppx-rpc))
     (pps js_of_ocaml-ppx))

Warns when passing a default library or preprocessor:

  $ ocsigen-dune-rules gen-library --server-libraries eliom.server --libraries js_of_ocaml --server-preprocess eliom.ppx.server --client-preprocess js_of_ocaml-ppx my_lib >/dev/null
  Error: client preprocess "js_of_ocaml-ppx" is already included by default.
  Error: server preprocess "eliom.ppx.server" is already included by default.
  Error: client library "js_of_ocaml" is already included by default.
  Error: server library "eliom.server" is already included by default.
  [1]
