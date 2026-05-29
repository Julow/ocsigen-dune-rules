open Sexpgen

let public_name_field ~package ~name suffix =
  match package with
  | Some pkg -> field "public_name" [ atomf "%s.%s.%s" pkg name suffix ]
  | None -> field "public_name" [ atomf "%s.%s" name suffix ]

let server_library_stanza ~package ~name ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~package ~name "server";
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "wrapped" [ atom "false" ];
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

let client_library_stanza ~package ~name ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~package ~name "client";
      field "name" [ atom name ];
      field "modes" [ atom "byte" ];
      field "wrapped" [ atom "false" ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [
          field "pps"
            (atoms
               ("eliom.ppx.client" :: "js_of_ocaml-ppx"
              :: preprocess.Gen_utils.pps_client));
        ];
      field "libraries"
        (atoms
           ("eliom.client" :: "js_of_ocaml" :: "js_of_ocaml-lwt"
          :: libraries.Gen_utils.lib_client));
    ]

let client_subdir_stanza ~package ~name ~libraries ~preprocess =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~package ~name ~libraries ~preprocess;
      field "dynamic_include" [ atom "../dune.client" ];
    ]

let gen_client_modules_rule () =
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
    ]

let run package libraries preprocess name =
  Gen_utils.promote_rule ()
  @ [
      server_library_stanza ~package ~name ~libraries ~preprocess;
      client_subdir_stanza ~package ~name ~libraries ~preprocess;
      gen_client_modules_rule ();
    ]
  |> pp_list Format.std_formatter
