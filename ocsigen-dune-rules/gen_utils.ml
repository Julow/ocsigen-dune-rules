open Sexpgen

type libraries = { lib_server : string list; lib_client : string list }

type preprocess = {
  pps_server : string list;
  pps_client : string list;
  rpc_raw : bool;
}

let server_pps preprocess =
  let rpc_raw_flag = if preprocess.rpc_raw then [ "--rpc-raw" ] else [] in
  ("eliom.ppx.server" :: "ocsigen-ppx-rpc" :: rpc_raw_flag)
  @ preprocess.pps_server

let client_pps preprocess = "js_of_ocaml-ppx" :: preprocess.pps_client

let promote_rule () =
  let argv = List.tl (Array.to_list Sys.argv) in
  [
    cmt
      {|
 This Dune file was generated with ocsigen-dune-rules.
 To update it, modify the invocation below and run

     dune runtest --auto-promote
|};
    field "rule"
      [
        field "with-stdout-to"
          [
            atom "dune.corrected";
            field "run" (atoms ("ocsigen-dune-rules" :: argv));
          ];
      ];
    cmt {|
 Below this line, any changes will be overwritten.
|};
    field "rule"
      [
        field "alias" [ atom "runtest" ];
        field "action" [ field "diff" [ atom "dune"; atom "dune.corrected" ] ];
      ];
  ]
