open Sexpgen

let public_name_field ~public_name ~name suffix =
  let n = Option.value public_name ~default:name in
  field "public_name" [ atom (n ^ suffix) ]

let server_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~public_name ~name ".server";
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "wrapped" [ atom (string_of_bool wrapped) ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [
          field "pps"
            (atoms
               ("eliom.ppx.server" :: "ocsigen-ppx-rpc" :: "--rpc-raw"
              :: preprocess.Gen_utils.pps_server));
        ];
      field "libraries"
        (atoms ("eliom.server" :: libraries.Gen_utils.lib_server));
    ]

let client_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~public_name ~name ".client";
      field "name" [ atom name ];
      field "modes" [ atom "byte" ];
      field "wrapped" [ atom (string_of_bool wrapped) ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [
          field "pps"
            (atoms ("js_of_ocaml-ppx" :: preprocess.Gen_utils.pps_client));
        ];
      field "libraries"
        (atoms
           ("eliom.client" :: "js_of_ocaml" :: "js_of_ocaml-lwt"
          :: libraries.Gen_utils.lib_client));
    ]

let client_subdir_stanza ~public_name ~name ~wrapped ~libraries ~preprocess =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess;
      field "dynamic_include" [ atom "../dune.client" ];
    ]

let gen_client_modules_rule ~name ~wrapped =
  let wrapped_args =
    (* gen-client-modules needs to construct wrapped names and to locate the
       server library objects. *)
    if wrapped then
      [
        "--internal-prefix";
        name;
        "--server-objs-dir";
        Printf.sprintf "../.%s.objs/byte" name;
      ]
    else []
  in
  let cmd =
    ("ocsigen-dune-rules" :: "gen-client-modules" :: wrapped_args) @ [ "." ]
  in
  field "rule"
    [
      field "deps"
        [
          field "glob_files" [ atom "*.eliom" ];
          field "glob_files" [ atom "*.eliomi" ];
        ];
      field "action"
        [
          field "with-stdout-to" [ atom "dune.client"; field "run" (atoms cmd) ];
        ];
    ]

let run public_name wrapped libraries preprocess name =
  Gen_utils.promote_rule ()
  @ [
      server_library_stanza ~public_name ~name ~wrapped ~libraries ~preprocess;
      client_subdir_stanza ~public_name ~name ~wrapped ~libraries ~preprocess;
      gen_client_modules_rule ~name ~wrapped;
    ]
  |> pp_list Format.std_formatter
