(* Extension of Getopt module *)

open Getopt
open List

type optext = char * string * ((unit -> unit) option) * ((string -> unit) option) * string

let optext2opt = function
  | (a,b,c,d,_) -> (a,b,c,d)

let ext_parse_cmdline eopts others =  parse_cmdline (map optext2opt eopts) others
                
