open Getopt
open Getoptext
open Yojson.Basic.Util

let prograname = "BluetoothAway" (* must match executable module name *)
and version = "0.1"
and default_cfgfile  = "bluetooth-away.cfg"
and default_logfile  = "bluetooth-away.log"
                         
and debug = ref false
and cfgfile  = ref ""
and logfile  = ref ""

(* ping state *)
type pstate = OK | ERROR

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
  (* Check for presence of required fields *)
  let c = Yojson.Basic.from_file !cfgfile in
  match
    (c |> member "Device" |> to_option to_string),
    (c |> member "Interval" |> to_option to_int),
    (c |> member "Attempts" |> to_option to_int),
    (c |> member "Triggers")
  with
  | Some _, Some _, Some _, `Assoc _ -> c
  | None, _, _ , _ -> LOG "Missing 'Device' config value" LEVEL ERROR; exit 1
  | _, None, _ , _ -> LOG "Missing 'Interval' config value" LEVEL ERROR; exit 1
  | _, _, None, _ -> LOG "Missing 'Attempts' config value" LEVEL ERROR; exit 1
  | _, _, _, _ -> LOG "Missing 'Trigger' config section" LEVEL ERROR; exit 1
                                                                           

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

  let c = read_cfg () in
  let addr = c |> member "Device" |> to_string in
  let interval = c |> member "Interval" |> to_int in
  let attempts = c |> member "Attempts" |> to_int in
  let rec mainloop state =
    let rec try_ping a =
      let cmd = "sudo /usr/bin/l2ping " ^ addr ^ " -t1 -c1" in
      let rc = Sys.command cmd in
      if rc=0 then
        (LOG "Ping OK" LEVEL DEBUG; rc)
      else
        (LOG "Ping attempt %d failed with code %d" (attempts-a+2) rc LEVEL DEBUG;
         if a=0 then rc else try_ping (a-1))
    in
    let rc = try_ping (attempts+1) in
    let (cmd, newstate) =
      let get_trigger n = c |> member "Triggers"  |> member n |> to_option to_string in
      match rc, state with
      | 0, OK -> (get_trigger "available", OK)
      | 0, ERROR -> (get_trigger "found", OK)
      | _, OK -> (get_trigger "lost", ERROR)
      | _, ERROR -> (get_trigger "not_available", ERROR)
    in
    (match cmd with
     | Some cmds ->
        (LOG "Executing %s" cmds LEVEL INFO;
         ignore (Sys.command cmds))
     | None ->
        (LOG "No command to execute" LEVEL DEBUG));
    Unix.sleep interval;
    mainloop newstate
  in mainloop ERROR
