open Sexpgen

let public_name_field ~public_name ~name suffix =
  let n = Option.value public_name ~default:name in
  field "public_name" [ atom (n ^ suffix) ]

let server_library_stanza ~public_name ~name ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~public_name ~name ".server";
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "wrapped" [ atom "false" ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [ field "pps" (atoms (Gen_utils.server_pps preprocess)) ];
      field "libraries"
        (atoms ("eliom.server" :: libraries.Gen_utils.lib_server));
    ]

let client_library_stanza ~public_name ~name ~libraries ~preprocess =
  field "library"
    [
      public_name_field ~public_name ~name ".client";
      field "name" [ atom name ];
      field "modes" [ atom "byte" ];
      field "wrapped" [ atom "false" ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [ field "pps" (atoms (Gen_utils.client_pps preprocess)) ];
      field "libraries"
        (atoms
           ("eliom.client" :: "js_of_ocaml" :: "js_of_ocaml-lwt"
          :: libraries.Gen_utils.lib_client));
    ]

let client_subdir_stanza ~public_name ~name ~libraries ~preprocess =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~public_name ~name ~libraries ~preprocess;
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

let run public_name libraries preprocess name =
  Gen_utils.promote_rule ()
  @ [
      server_library_stanza ~public_name ~name ~libraries ~preprocess;
      client_subdir_stanza ~public_name ~name ~libraries ~preprocess;
      gen_client_modules_rule ();
    ]
  |> pp_list Format.std_formatter
