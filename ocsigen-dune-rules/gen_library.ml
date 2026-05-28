open Sexpgen

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

let server_library_stanza ~name ~libraries_server =
  field "library"
    [
      field "public_name" [ atomf "%s.server" name ];
      field "name" [ atom name ];
      field "modes" [ atom "byte"; atom "native" ];
      field "wrapped" [ atom "false" ];
      field "preprocess"
        [
          field "pps"
            (atoms [ "eliom.ppx.server"; "ocsigen-ppx-rpc"; "--rpc-raw" ]);
        ];
      field "libraries" (atoms ("eliom.server" :: libraries_server));
    ]

let client_library_stanza ~name ~libraries_client =
  field "library"
    [
      field "public_name" [ atomf "%s.client" name ];
      field "name" [ atom name ];
      field "modes" [ atom "byte" ];
      field "wrapped" [ atom "false" ];
      field "library_flags" [ list (atoms [ ":standard"; "-linkall" ]) ];
      field "preprocess"
        [ field "pps" (atoms [ "eliom.ppx.client"; "js_of_ocaml-ppx" ]) ];
      field "libraries"
        (atoms
           ("eliom.client" :: "js_of_ocaml" :: "js_of_ocaml-lwt"
          :: libraries_client));
    ]

let client_subdir_stanza ~name ~libraries_client =
  field "subdir"
    [
      atom "client";
      client_library_stanza ~name ~libraries_client;
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

let run ~libraries_server ~libraries_client ~libraries ~name =
  let libraries_server = libraries_server @ libraries
  and libraries_client = libraries_client @ libraries in
  promote_rule ()
  @ [
      server_library_stanza ~name ~libraries_server;
      client_subdir_stanza ~name ~libraries_client;
      gen_client_modules_rule ();
    ]
  |> pp_list Format.std_formatter
