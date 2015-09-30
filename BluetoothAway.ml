open Yojson
open Getopt
open Getoptext

let prograname = "BluetoothAway" (* must executable module name *)
and version = "0.1"
and default_cfgfile  = "bluetooth-away.cfg"
and default_logfile  = "bluetooth-away.log"
       
and debug = ref false
and cfgfile  = ref ""
and logfile  = ref ""
and cfg = ref `Null

(* ping state *)
type pstate = OK | ERROR

let state_to_string = function
  | OK -> "Ok"
  | ERROR -> "Error"

let specs = 
[
  ( 'v', "version", Some (fun _ -> Printf.printf "%s %s\n" prograname version ; exit 0), None,
    "Show program version");
  ( 'h', "help", Some usage_action, None,
    "Show this help");
  ('c', "console",  Some (fun _ -> logfile := "<stderr>"), None,
   "Log to console instead of log file");
  ( 'd', "debug", (set debug true), None,
    "Debug");
  ( 'f', "config",  None, (atmost_once cfgfile (Error "only one config")),
    (Printf.sprintf "config file name. Default (%s)" default_cfgfile));
  ( 'l', "log",  None, (atmost_once logfile (Error "only one log")),
    (Printf.sprintf "log file name. Default (%s)" default_logfile))
]

let read_cfg () =
  LOG "Reading config from '%s'" !cfgfile LEVEL DEBUG;
  cfg := (Yojson.Basic.from_file !cfgfile)

let setup_log () =
  let seconds24h = 86400. in
  let dt_layout = Bolt.Layout.pattern
    [] [] "$(year)-$(month)-$(mday) $(hour):$(min):$(sec) $(level:5): $(message)" in
  Bolt.Layout.register "datetime" dt_layout ;
  Bolt.Logger.register
    prograname
    (if !debug then Bolt.Level.TRACE else Bolt.Level.INFO)
    "all"
    "datetime"
    (Bolt.Mode.direct ())    
    "file" (!logfile, ({Bolt.Output.seconds_elapsed=Some seconds24h; Bolt.Output.signal_caught=None}))

let parse_cmdline () =
  let ue _ = print_usage specs; exit 1 in
  (try ext_parse_cmdline specs ue print_usage_and_exit_action with
   | Getopt.Error s -> Printf.printf "Error:\n    %s\n" s; ue ());
  if !cfgfile = "" then cfgfile := default_cfgfile;
  if !logfile = "" then logfile := default_logfile

let _ =
  parse_cmdline ();
  setup_log ();
  LOG "Launched" LEVEL INFO;

  read_cfg () ;
  
  let open Yojson.Basic.Util in
  let c = !cfg in
  (* let addr = c |> member "Device" |> to_string in *)
  let interval = c |> member "Interval" |> to_int in
  (* let attempts = c |> member "Attempts" |> to_int in *)
  let rec mainloop state tries =
    LOG "State=%s, tries=%d'" (state_to_string state) tries LEVEL DEBUG;
    Unix.sleep interval;
    mainloop state tries
  in mainloop ERROR 0
  
