open Yojson
open Getopt
open Getoptext

let prograname = "BluetoothAway"
and version = "0.1"
and default_cfgfile  = "bluetooth-away.cfg"
and default_logfile  = "bluetooth-away.log"
       
let console = ref false
and debug = ref false
and cfgfile  = ref ""
and logfile  = ref ""
and cfg = ref `Null

let specs = 
[
  ( 'v', "version", Some (fun _ -> Printf.printf "%s %s\n" prograname version ; exit 0), None,
    "Show program version");
  ( 'h', "help", Some usage_action, None,
    "Show this help");
  ( 'c', "console", (set console true), None,
    "Log to console instead of log file");
  ( 'd', "debug", (set debug true), None,
    "Debug");
  ( 'f', "config",  None, (atmost_once cfgfile (Error "only one config")),
    (Printf.sprintf "config file name. Default (%s)" default_cfgfile));
  ( 'l', "log",  None, (atmost_once logfile (Error "only one log")),
    (Printf.sprintf "log file name. Default (%s)" default_logfile))
]

let read_cfg () =
  cfg := (Yojson.Basic.from_file !cfgfile)
  
let _ =
  (try ext_parse_cmdline specs print_endline print_usage_and_exit_action with
   | Getopt.Error s -> Printf.printf "Error:\n    %s\n" s; print_usage specs; exit 1);

  if !cfgfile = "" then cfgfile := default_cfgfile;
  if !logfile = "" then logfile := default_logfile;

  read_cfg() ;
  let open Yojson.Basic.Util in
  let c = !cfg in
  let addr = c |> member "Device" |> to_string in
  Printf.printf "Device %s\n" addr;
  Printf.printf "log  = %s\n" !logfile;
  Printf.printf "config  = %s\n" !cfgfile
