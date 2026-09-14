open Sexpgen

type libraries = { lib_server : string list; lib_client : string list }

type preprocess = {
  pps_server : string list;
  pps_client : string list;
  rpc_raw : bool;
}

let server_default_pps =
  [ "eliom.ppx.server"; "ocsigen-ppx-rpc"; "js_of_ocaml-ppx_deriving_json" ]

let client_default_pps =
  [
    "eliom.ppx.client";
    "ocsigen-ppx-rpc";
    "js_of_ocaml-ppx";
    "js_of_ocaml-ppx_deriving_json";
  ]

let server_default_libs = [ "eliom.server" ]
let client_default_libs = [ "eliom.client"; "js_of_ocaml"; "js_of_ocaml-lwt" ]

let server_pps preprocess =
  let rpc_raw_flag = if preprocess.rpc_raw then [ "--rpc-raw" ] else [] in
  (server_default_pps @ rpc_raw_flag) @ preprocess.pps_server

let client_pps preprocess = client_default_pps @ preprocess.pps_client

(** A standalone Ppxlib driver linking every client PPX. Running them all in a
    single driver is what allows Ppxlib to order the transformations. *)
let ppx_client_stanza preprocess =
  field "subdir"
    [
      atom "client/ppx";
      field "rule"
        [
          field "write-file"
            [ atom "main.ml"; atom "let () = Ppxlib.Driver.standalone ()" ];
        ];
      field "executable"
        [
          field "name" [ atom "main" ];
          field "libraries" (atoms ("ppxlib" :: client_pps preprocess));
        ];
    ]

(** Stanzas building the client modules: the PPX driver and the rule generating
    the [dune.client] file, which contains a rule per module. *)
let gen_client_modules_stanzas preprocess =
  [
    ppx_client_stanza preprocess;
    field "rule"
      [
        field "deps"
          [
            field "glob_files" [ atom "*.eliom" ];
            field "glob_files" [ atom "*.eliomi" ];
          ];
        field "action"
          [
            field "with-stdout-to"
              [
                atom "dune.client";
                field "run"
                  (atoms [ "ocsigen-dune-rules"; "gen-client-modules"; "." ]);
              ];
          ];
      ];
  ]

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

let generated_start_marker = "; [ocsigen-dune-rules]"

let preserve_prelude dune_file =
  let rec loop acc inp =
    match In_channel.input_line inp with
    | Some l ->
        if String.starts_with ~prefix:generated_start_marker l then acc
        else loop (l :: acc) inp
    | None -> acc
  in
  List.rev (In_channel.with_open_text dune_file (loop []))

let gen_default_prelude () =
  let argv = List.tl (Array.to_list Sys.argv) in
  field "rule"
    [
      field "with-stdout-to"
        [
          atom "dune.corrected";
          field "run"
            (atoms
               (("ocsigen-dune-rules" :: argv) @ [ "--dune"; "%{dep:dune}" ]));
        ];
    ]

(** Output the top part of the dune file by reading the current dune file. If
    [--dune] is not passed, generate the rule calling ocsigen-dune-rules. *)
let gen_prelude ~dune_file =
  let prelude =
    match dune_file with
    | Some dune_file -> raw_sexp_lines (preserve_prelude dune_file)
    | None -> gen_default_prelude ()
  in
  [
    prelude;
    raw_sexp_lines [ generated_start_marker ^ " Do not remove this line." ];
    cmt
      {| Below this line, any changes will be overwritten.

 To update the rules below, modify the invocation of ocsigen-dune-rules above
 and run:

     dune runtest --auto-promote
|};
    field "rule"
      [
        field "alias" [ atom "runtest" ];
        field "action" [ field "diff" [ atom "dune"; atom "dune.corrected" ] ];
      ];
  ]
