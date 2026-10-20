let pp_string_list =
  Format.(pp_print_list ~pp_sep:pp_print_space pp_print_string)

module S = Set.Make (String)

(** Extract source file names from the [DBUG] section. See [Bytelink]. *)
let extract_source_files toc ic =
  let locs = ref S.empty in
  let record_events _ evl =
    List.iter
      (fun (ev : Instruct.debug_event) ->
        locs := S.add ev.ev_loc.Location.loc_start.Lexing.pos_fname !locs)
      evl
  in
  (* Code taken from [tools/dumpobj.ml]. *)
  begin match Compat.Bytesections.seek_dbug_section toc ic with
  | exception Not_found -> ()
  | (_ : int) ->
      let num_eventlists = input_binary_int ic in
      for _i = 1 to num_eventlists do
        let orig = input_binary_int ic in
        let evl = (input_value ic : Instruct.debug_event list) in
        (* Skip the list of absolute directory names *)
        ignore (input_value ic);
        record_events orig evl
      done
  end;
  !locs

(** Module name after the last [__] in lowercase. *)
let unit_basename name =
  let rec last_sep i =
    if i < 2 then 0
    else if name.[i - 1] = '_' && name.[i - 2] = '_' then i
    else last_sep (i - 1)
  in
  let i = last_sep (String.length name) in
  String.lowercase_ascii (String.sub name i (String.length name - i))

(** Extract the unit names from the [CRCS] section. See [Bytelink]. *)
let extract_unit_names toc ic =
  match Compat.Bytesections.seek_crcs_section toc ic with
  | exception Not_found -> S.empty
  | (_ : int) ->
      let crcs = (input_value ic : (string * Digest.t option) list) in
      List.fold_left
        (fun acc (unit, _) -> S.add (unit_basename unit) acc)
        S.empty crcs

type sections = {
  sources : S.t;  (** Paths to sources extracted from the DBUG section. *)
  units : S.t;  (** Unit names extracted from the CRCS section. *)
}

let read_program path =
  In_channel.with_open_bin path (fun ic ->
      let toc = Compat.Bytesections.read_toc ic in
      let sources = extract_source_files toc ic in
      let units = extract_unit_names toc ic in
      { sources; units })

let eliom_sources prog =
  S.filter (fun f -> Filename.check_suffix f ".eliom") prog.sources

(** Whether [source] made it into [prog].

    A module that compiles to no code at all (a module of aliases, say) has no
    debug event, so it is absent from [sources] even when it is linked. Fall
    back on the unit names, which [CRCS] lists whether or not the unit has code.
    A unit missing from the link is not referenced by any other unit either, so
    it is missing from [CRCS] too. *)
let has_source prog source =
  S.mem source prog.sources
  || S.mem
       (String.lowercase_ascii
          (Filename.remove_extension (Filename.basename source)))
       prog.units

let run ~server_bytecode ~client_bytecode =
  let server = read_program server_bytecode
  and client = read_program client_bytecode in
  let sources = S.union (eliom_sources server) (eliom_sources client) in
  let missing prog = S.filter (Fun.negate (has_source prog)) sources in
  let missing_on_server = S.elements (missing server)
  and missing_on_client = S.elements (missing client) in
  if missing_on_server <> [] || missing_on_client <> [] then (
    Format.(
      eprintf
        "Some modules are missing. Make sure to build with [(library_flags \
         (:standard -linkall))].@.@.@[<hv>Missing on the server:@ \
         @[<hov>%a@]@]@.@[<hv>Missing on the client:@ @[<hov>%a@]@]@."
        pp_string_list missing_on_server pp_string_list missing_on_client);
    exit 1)
