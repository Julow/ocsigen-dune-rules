Default invocation: emit one rule per .eliom/.eliomi, using
%{cmo:...} to locate the server-side .cmo and %{dep:...} for the
input file.

  $ ocsigen-dune-rules gen-client-modules .
  (rule
   (with-stdout-to
    a.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../a.eliom}
      --impl
      -server-cmo
      %{cmo:../a}
      %{dep:../a.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliom}
      --impl
      -server-cmo
      %{cmo:../b}
      %{dep:../b.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliomi
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliomi}
      --intf
      %{dep:../b.eliomi}))))

TODO: --internal-prefix forwards [-internal-prefix PREFIX] to
ocsigen-ppx-client. Unreleased: https://github.com/ocsigen/eliom/pull/855

  $ ocsigen-dune-rules gen-client-modules --internal-prefix Os .
  (rule
   (with-stdout-to
    a.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../a.eliom}
      --impl
      -server-cmo
      %{cmo:../a}
      %{dep:../a.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliom}
      --impl
      -server-cmo
      %{cmo:../b}
      %{dep:../b.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliomi
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliomi}
      --intf
      %{dep:../b.eliomi}))))
--subdir DIR wraps each generated rule in a (subdir DIR ...) stanza
so the preprocessed files land in DIR/.  The input paths still refer
to the original location relative to the workspace root, thanks to
the chdir wrapper.

  $ ocsigen-dune-rules gen-client-modules --subdir Os .
  (subdir
   Os
   (rule
    (with-stdout-to
     a.eliom
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../a.eliom}
       --impl
       -server-cmo
       %{cmo:../a}
       %{dep:../a.eliom})))))
  
  (subdir
   Os
   (rule
    (with-stdout-to
     b.eliom
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../b.eliom}
       --impl
       -server-cmo
       %{cmo:../b}
       %{dep:../b.eliom})))))
  
  (subdir
   Os
   (rule
    (with-stdout-to
     b.eliomi
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../b.eliomi}
       --intf
       %{dep:../b.eliomi})))))

--server-objs-dir DIR replaces %{cmo:Name} with an explicit
%{dep:DIR/Name.cmo} path so the server-side .cmo is located
unambiguously.  When used without --subdir the path has no prefix:

  $ ocsigen-dune-rules gen-client-modules --server-objs-dir ../.foo.objs/byte .
  (rule
   (with-stdout-to
    a.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../a.eliom}
      --impl
      -server-cmo
      %{dep:../.foo.objs/byte/A.cmo}
      %{dep:../a.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliom
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliom}
      --impl
      -server-cmo
      %{dep:../.foo.objs/byte/B.cmo}
      %{dep:../b.eliom}))))
  
  (rule
   (with-stdout-to
    b.eliomi
    (chdir
     %{workspace_root}
     (run
      ocsigen-ppx-client
      -as-pp
      -loc-filename
      %{dep:../b.eliomi}
      --intf
      %{dep:../b.eliomi}))))

When --server-objs-dir is combined with --subdir, the subdir name
(lowercased) is used as the wrapping prefix, matching dune's own
wrapping convention (e.g. --subdir Os yields os__Name.cmo).  The
generated path is also prefixed with ../ to escape the (subdir ...)
context.

  $ ocsigen-dune-rules gen-client-modules --subdir Os --server-objs-dir .foo.objs/byte .
  (subdir
   Os
   (rule
    (with-stdout-to
     a.eliom
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../a.eliom}
       --impl
       -server-cmo
       %{dep:../.foo.objs/byte/os__A.cmo}
       %{dep:../a.eliom})))))
  
  (subdir
   Os
   (rule
    (with-stdout-to
     b.eliom
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../b.eliom}
       --impl
       -server-cmo
       %{dep:../.foo.objs/byte/os__B.cmo}
       %{dep:../b.eliom})))))
  
  (subdir
   Os
   (rule
    (with-stdout-to
     b.eliomi
     (chdir
      %{workspace_root}
      (run
       ocsigen-ppx-client
       -as-pp
       -loc-filename
       %{dep:../b.eliomi}
       --intf
       %{dep:../b.eliomi})))))
