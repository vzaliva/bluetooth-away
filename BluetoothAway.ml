open Getopt
open Yojson

let console = ref false
and debug = ref false
and cfgfile  = ref ""
and cfg = ref `Null

let specs = 
[
  ( 'c', "console", (set console true), None);
  ( 'd', "debug", (set debug true), None);
  ( 'f', "config",  None, (atmost_once cfgfile (Error "only one config")))
]

let usage () =
  Printf.printf  "Usage:\n";
  Printf.printf "    bluetooth-away [-f <cfg file>] [-c] [-d]\n";
  Printf.printf "        -c : log to console instead of log file\n";
  Printf.printf "        -d : debug\n";
  Printf.printf "        -f <cfg file> : config file name\n"

let read_cfg () =
  cfg := (Yojson.Basic.from_file !cfgfile)
  
let _ =
  (try parse_cmdline specs print_endline with
  | Getopt.Error s -> Printf.printf "Error:\n    %s\n" s; usage ());

  read_cfg() ;
  let open Yojson.Basic.Util in
  let c = !cfg in
  let addr = c |> member "Device" |> to_string in
  Printf.printf "Device %s\n" addr;
  
  Printf.printf "console = %b\n" !console;
  Printf.printf "debug  = %b\n" !debug;
  Printf.printf "config  = %s\n" !cfgfile
