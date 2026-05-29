open Sexpgen

let server_executable_stanza ~name ~libraries_server =
  field "executable"
    [
      field "public_name" [ atom name ];
      field "name" [ atom name ];
      field "package" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "preprocess"
        [
          field "pps"
            (atoms [ "eliom.ppx.server"; "ocsigen-ppx-rpc"; "--rpc-raw" ]);
        ];
      field "libraries"
        (atoms
           ([
              "eliom.server";
              "ocsigenserver";
              "ocsigenserver.ext.staticmod";
              "ocsipersist-sqlite";
              "js_of_ocaml";
            ]
           @ libraries_server));
    ]

let client_executable_stanza ~name ~libraries_client =
  field "executable"
    [
      field "name" [ atom name ];
      field "modes" [ atom "js"; atom "byte" ];
      field "preprocess"
        [ field "pps" (atoms [ "eliom.ppx.client"; "js_of_ocaml-ppx" ]) ];
      field "js_of_ocaml"
        [
          field "build_runtime_flags"
            (atoms [ ":standard"; "--enable"; "use-js-string" ]);
          field "flags"
            (atoms
               [
                 ":standard";
                 "--enable";
                 "with-js-error";
                 "--enable";
                 "use-js-string";
               ]);
        ];
      field "libraries"
        (atoms
           ([ "eliom.client"; "js_of_ocaml"; "js_of_ocaml-lwt" ]
           @ libraries_client));
    ]

let client_subdir_stanza ~name ~libraries_client =
  field "subdir"
    [
      atom "client";
      client_executable_stanza ~name ~libraries_client;
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

let check_modules_rule ~name =
  field "rule"
    [
      field "alias" [ atom "runtest" ];
      field "action"
        [
          field "run"
            [
              atom "ocsigen-dune-rules";
              atom "check-modules";
              atom "--client";
              atomf "%%{dep:client/%s.bc}" name;
              atom "--server";
              atomf "%%{dep:%s.bc}" name;
            ];
        ];
    ]

let run ~libraries_server ~libraries_client ~libraries ~name =
  let libraries_server = libraries_server @ libraries
  and libraries_client = libraries_client @ libraries in
  Gen_utils.promote_rule ()
  @ [
      server_executable_stanza ~name ~libraries_server;
      client_subdir_stanza ~name ~libraries_client;
      gen_client_modules_rule ();
      check_modules_rule ~name;
    ]
  |> pp_list Format.std_formatter
