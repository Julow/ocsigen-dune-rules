# ocsigen-dune-rules

[![OCaml-CI Build Status](https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/ocsigen/ocsigen-dune-rules/main&logo=ocaml)](https://ocaml.ci.dev/github/ocsigen/ocsigen-dune-rules)

Generate Dune rules for building a client/server application or library.

## Usage

Use this command to generate the dune rules for an Ocsigen application:

```
ocsigen-dune-rules gen-application my_app \
  --libraries lwt,logs \
  --server-libraries ocsipersist-sqlite \
  --eliom-libraries ocsigen-toolkit > app/dune
```

The libraries are provided as an example. Change `app/dune` if your application
code is not in `app/`.

To update the generated rules later, modify the `ocsigen-dune-rules` command in
the generated `dune` file and run `dune runtest --auto-promote`.

You must also tell Dune that `*.eliom` files contain source code by adding this
to your `dune-project` file:

`dune-project`:
```dune
(dialect
 (name "eliom-server")
 (implementation
  (extension "eliom"))
 (interface
  (extension "eliomi")))
```

See [`test/app.t`](test/app.t) for both application and library examples.
See [ocsigen-toolkit](https://github.com/ocsigen/ocsigen-toolkit/tree/master) for a real world example.
