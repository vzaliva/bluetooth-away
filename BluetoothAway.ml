open Getopt
open Yojson

let prograname = "BluetoothAway"
and version = "0.1"
and default_cfgfile  = "bluetooth-away.cfg"
and default_logfile  = "bluetooth-away.log"
       
let console = ref false
and debug = ref false
and cfgfile  = ref ""
and logfile  = ref ""
and cfg = ref `Null

let usage () =
  Printf.printf  "Usage:\n";
  Printf.printf "    bluetooth-away [-f <cfg file>] [-l <log file>] [-c] [-d] [-h] [-v]\n";
  Printf.printf "        -h, --help : show this help\n";
  Printf.printf "        -v, --verbose : show program version\n";
  Printf.printf "        -c, --console : log to console instead of log file\n";
  Printf.printf "        -d, --debug : debug\n";
  Printf.printf "        -f <cfg file>, --config <cfg file> : config file name. Default (%s)\n" default_cfgfile;
  Printf.printf "        -l <log file>, --log <log file> : log file name. Default (%s)\n" default_logfile

let specs = 
[
  ( 'v', "version", Some (fun _ -> Printf.printf "%s %s\n" prograname version ; exit 0), None);
  ( 'h', "help", Some (fun _ -> usage() ; exit 0), None);
  ( 'c', "console", (set console true), None);
  ( 'd', "debug", (set debug true), None);
  ( 'f', "config",  None, (atmost_once cfgfile (Error "only one config")));
  ( 'l', "log",  None, (atmost_once logfile (Error "only one log")))
]

let read_cfg () =
  cfg := (Yojson.Basic.from_file !cfgfile)
  
let _ =
  (try parse_cmdline specs print_endline with
   | Getopt.Error s -> Printf.printf "Error:\n    %s\n" s; usage (); (exit 1));

  if String.length !cfgfile == 0 then cfgfile := default_cfgfile;
  if String.length !logfile == 0 then logfile := default_logfile;

  read_cfg() ;
  let open Yojson.Basic.Util in
  let c = !cfg in
  let addr = c |> member "Device" |> to_string in
  Printf.printf "Device %s\n" addr;
  Printf.printf "log  = %s\n" !logfile;
  Printf.printf "config  = %s\n" !cfgfile