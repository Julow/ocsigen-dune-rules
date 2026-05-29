  $ ocsigen-dune-rules gen-library --server-libraries a --client-libraries b --libraries c my_lib > dune

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
     my_lib)))
  
  ;
  ; Below this line, any changes will be overwritten.
  ;
  
  (rule
   (alias runtest)
   (action
    (diff dune dune.corrected)))
  
  (library
   (name my_lib)
   (modes byte native)
   (wrapped false)
   (preprocess
    (pps eliom.ppx.server ocsigen-ppx-rpc --rpc-raw))
   (libraries eliom.server a c))
  
  (subdir
   client
   (library
    (name my_lib)
    (modes byte)
    (wrapped false)
    (library_flags
     (:standard -linkall))
    (preprocess
     (pps eliom.ppx.client js_of_ocaml-ppx))
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
