(* Printer for S-expressions. *)

type t =
  | List of t list
  | Atom of string
  | Comment of string
  | Raw_sexp_lines of string list

let atom s = Atom s
let list l = List l
let atoms = List.map atom
let cmt s = Comment s
let raw_sexp_lines l = Raw_sexp_lines l

(** Construct an [Atom] using printf syntax. *)
let atomf fmt = Printf.ksprintf (fun s -> Atom s) fmt

(** Generate [(name args...)] *)
let field name args = List (Atom name :: args)

let need_escaping = function
  | '\x00' .. '\x20' | '\x7F' .. '\xFF' | '(' | ')' | ';' | '\\' -> true
  | _ -> false

open Format

let rec pp ppf = function
  | List ts ->
      let fmt : (_, _, _) format =
        if List.exists (function List _ -> true | _ -> false) ts then
          "@[<v 1>(%a)@]"
        else "@[<hv 1>(%a)@]"
      in
      fprintf ppf fmt _pp_list ts
  | Atom s when String.exists need_escaping s -> fprintf ppf "%S" s
  | Atom s -> fprintf ppf "%s" s
  | Comment s -> List.iter (fprintf ppf ";%s@,") (String.split_on_char '\n' s)
  | Raw_sexp_lines l -> pp_print_list pp_print_string ppf l

and _pp_list ppf lst = pp_print_list ~pp_sep:pp_print_space pp ppf lst

let pp_top_level ppf t =
  pp ppf t;
  (* A cut break is already printed for comments. *)
  match t with
  | Comment _ | Raw_sexp_lines _ -> ()
  | _ -> fprintf ppf "@,"

(** Output S-expressions following Dune's formatting. *)
let pp_list ppf lst =
  fprintf ppf "@[<v 0>%a@]@?"
    (pp_print_list ~pp_sep:pp_print_cut pp_top_level)
    lst
