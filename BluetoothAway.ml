open Yojson
open Getopt
open Getoptext

let prograname = "BluetoothAway"
and version = "0.1"
and default_cfgfile  = "bluetooth-away.cfg"
and default_logfile  = "bluetooth-away.log"
       
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
  ( 'c', "console",  Some (fun _ -> logfile := "<stderr>"; ()), None,
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

let setup_log () =
  let seconds24h = 86400. in
  Bolt.Logger.register
    "BLUETOOTHAWAY"
    Bolt.Level.TRACE
    "all"
    "default"
    (Bolt.Mode.direct ())    
    "file" (!logfile, ({Bolt.Output.seconds_elapsed=Some seconds24h; Bolt.Output.signal_caught=None}))

let _ =
  let ue _ = print_usage specs; exit 1 in
  (try ext_parse_cmdline specs ue print_usage_and_exit_action with
   | Getopt.Error s -> Printf.printf "Error:\n    %s\n" s; ue ());

  if !cfgfile = "" then cfgfile := default_cfgfile;
  if !logfile = "" then logfile := default_logfile;

  setup_log ();
  LOG "application start" LEVEL TRACE;

  read_cfg () ;
  let open Yojson.Basic.Util in
  let c = !cfg in
  let addr = c |> member "Device" |> to_string in
  Printf.printf "Device %s\n" addr;
  Printf.printf "log  = %s\n" !logfile;
  Printf.printf "config  = %s\n" !cfgfile
