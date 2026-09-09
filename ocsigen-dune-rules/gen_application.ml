open Sexpgen

let server_executable_stanza ~public_name ~name ~libraries ~preprocess =
  field "library"
    [
      field "public_name" [ atom public_name ];
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [ field "pps" (atoms (Gen_utils.server_pps preprocess)) ];
      field "libraries"
        (atoms (Gen_utils.server_default_libs @ libraries.Gen_utils.lib_server));
    ]

let client_executable_stanza ~name ~libraries ~preprocess ~wasm =
  let wasm = if wasm then [ atom "wasm" ] else [] in
  field "executable"
    [
      field "name" [ atom name ];
      field "modes" ([ atom "js" ] @ wasm @ [ atom "byte" ]);
      field "preprocess"
        [ field "pps" (atoms (Gen_utils.client_pps preprocess)) ];
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
        (atoms (Gen_utils.client_default_libs @ libraries.Gen_utils.lib_client));
    ]

let client_subdir_stanza ~name ~libraries ~preprocess ~wasm =
  field "subdir"
    [
      atom "client";
      client_executable_stanza ~name ~libraries ~preprocess ~wasm;
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

(** Directory containing the bytecode executable used by [check-modules]. *)
let check_modules_dir = "check_modules"

let check_modules_rules ~name =
  [
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
                atomf "%%{dep:%s/main.bc}" check_modules_dir;
              ];
          ];
      ];
    (* Define a bytecode executable for the server side to compare it with the
       client. *)
    field "subdir"
      [
        atom check_modules_dir;
        field "rule" [ field "write-file" [ atom "main.ml"; atom "" ] ];
        field "executable"
          [
            field "name" [ atom "main" ];
            field "modes" [ atom "byte" ];
            field "link_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
            field "libraries" [ atom name ];
          ];
      ];
  ]

let run name libraries preprocess wasm dune_file public_name =
  let name = Option.value name ~default:public_name in
  Gen_utils.check_duplicated_deps ~server_libs:Gen_utils.server_default_libs
    ~client_libs:Gen_utils.client_default_libs libraries preprocess;
  Gen_utils.gen_prelude ~dune_file
  @ [
      server_executable_stanza ~public_name ~name ~libraries ~preprocess;
      client_subdir_stanza ~name ~libraries ~preprocess ~wasm;
      gen_client_modules_rule ();
    ]
  @ check_modules_rules ~name
  |> pp_list Format.std_formatter
