(* Extension of Getopt module *)

open Getopt
open List

type optext = char * string * ((unit -> unit) option) * ((string -> unit) option) * string

let optext2opt = function
  | (a,b,c,d,_) -> (a,b,c,d)

let ext_parse_cmdline eopts others =  parse_cmdline (map optext2opt eopts) others

let get_usage eopts =
  let eopt_descr = function
    | (s, l, _, _, _) when s=noshort && l=nolong -> "INVALID OPTION"
    | (s, l, _, None, d) when s=noshort -> Printf.sprintf "--%s :\t%s" l d
    | (s, l, _, None, d) when l=nolong -> Printf.sprintf "-%c :\t%s" s d
    | (s, l, _, None, d) -> Printf.sprintf "-%c, --%s :\t%s" s l d
    | (s, l, _, Some _, d) when s=noshort -> Printf.sprintf "--%s=<arg> :\t%s" l d
    | (s, l, _, Some _, d) when l=nolong -> Printf.sprintf "-%c <arg> :\t%s" s d
    | (s, l, _, Some _, d) -> Printf.sprintf "-%c <arg>, --%s=<arg> :\t%s" s l d
  in "Usage:\n\t" ^
  String.concat "\n\t" (map eopt_descr eopts)

let pring_usage eopts = print_endline (get_usage eopts)

