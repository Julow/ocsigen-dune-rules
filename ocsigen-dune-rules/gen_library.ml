open Sexpgen

let public_name_field suffix = function
  | Some n -> [ field "public_name" [ atom (n ^ suffix) ] ]
  | None -> []

let server_library_stanza ~public_name ~name ~libraries =
  field "library"
    (public_name_field ".server" public_name
    @ [
        field "name" [ atom name ];
        field "modes" [ atom "byte"; atom "native" ];
        field "wrapped" [ atom "false" ];
        field "preprocess"
          [
            field "pps"
              (atoms [ "eliom.ppx.server"; "ocsigen-ppx-rpc"; "--rpc-raw" ]);
          ];
        field "libraries" (atoms ("eliom.server" :: libraries.Gen_utils.server));
      ])

let client_library_stanza ~public_name ~name ~libraries =
  field "library"
    (public_name_field ".client" public_name
    @ [
        field "name" [ atom name ];
        field "modes" [ atom "byte" ];
        field "wrapped" [ atom "false" ];
        field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
        field "preprocess"
          [ field "pps" (atoms [ "eliom.ppx.client"; "js_of_ocaml-ppx" ]) ];
        field "libraries"
          (atoms
             ("eliom.client" :: "js_of_ocaml" :: "js_of_ocaml-lwt"
            :: libraries.Gen_utils.client));
      ])

let client_subdir_stanza ~public_name ~name ~libraries =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~public_name ~name ~libraries;
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

let run public_name libraries name =
  Gen_utils.promote_rule ()
  @ [
      server_library_stanza ~public_name ~name ~libraries;
      client_subdir_stanza ~public_name ~name ~libraries;
      gen_client_modules_rule ();
    ]
  |> pp_list Format.std_formatter
