open Sexpgen

type libraries = { lib_server : string list; lib_client : string list }

type preprocess = {
  pps_server : string list;
  pps_client : string list;
  rpc_raw : bool;
}

let server_default_pps = [ "eliom.ppx.server"; "ocsigen-ppx-rpc" ]
let client_default_pps = [ "js_of_ocaml-ppx" ]

let server_pps preprocess =
  let rpc_raw_flag = if preprocess.rpc_raw then [ "--rpc-raw" ] else [] in
  (server_default_pps @ rpc_raw_flag) @ preprocess.pps_server

let client_pps preprocess = client_default_pps @ preprocess.pps_client

(** Generate a warning when a default library or preprocessor is passed. *)
let check_duplicated_deps ~server_libs ~client_libs libraries preprocess =
  (* non short-circuiting to print all the errors at once. *)
  let ( ||| ) = ( || ) in
  let check what defaults items =
    List.fold_left
      (fun acc item ->
        if List.mem item defaults then (
          Printf.eprintf "Error: %s %S is already included by default.\n" what
            item;
          true)
        else acc)
      false items
  in
  if
    check "server library" server_libs libraries.lib_server
    ||| check "client library" client_libs libraries.lib_client
    ||| check "server preprocess" server_default_pps preprocess.pps_server
    ||| check "client preprocess" client_default_pps preprocess.pps_client
  then exit 1

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
