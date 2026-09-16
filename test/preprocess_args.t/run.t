Arguments passed to PPXes are handled specifically.

  $ ocsigen-dune-rules gen-application --preprocess ocsigen-i18n,--,--default-module,I18n my_app > dune

  $ grep -A 9 '[(]preprocess' dune
   (preprocess
    (pps
     eliom.ppx.server
     ocsigen-ppx-rpc
     js_of_ocaml-ppx_deriving_json
     --rpc-raw
     ocsigen-i18n
     --
     --default-module
     I18n))

  $ grep -A 10 Ppxlib.Driver.standalone dune
    (write-file main.ml "let () = Ppxlib.Driver.standalone ()"))
   (executable
    (name main)
    (libraries
     ppxlib
     eliom.ppx.client
     ocsigen-ppx-rpc
     js_of_ocaml-ppx
     js_of_ocaml-ppx_deriving_json
     ocsigen-i18n)))
  

  $ grep -A 1 gen-client-modules dune
     (run ocsigen-dune-rules gen-client-modules . -- --default-module I18n))))
  

  $ ocsigen-dune-rules gen-library --wrapped false --client-preprocess ocsigen-i18n,--,--default-module,I18n my_lib | grep gen-client-modules
     (run ocsigen-dune-rules gen-client-modules . -- --default-module I18n))))

  $ ocsigen-dune-rules gen-library --wrapped false --server-preprocess ocsigen-i18n,--,--default-module,I18n my_lib | grep gen-client-modules
     (run ocsigen-dune-rules gen-client-modules .))))
