open State
open Command
open Gui
open Elements
open Player
open Ai

let roll_dice () =
  let i1 = 1 + Random.int 6 in
  let i2 = 1 + Random.int 6 in
  (i1, i2), (i1 + i2)

let setup s =
  let rec settlement s =
    ANSITerminal.(print_string [cyan] "Please pick a settlement.");
    print_newline ();
    match () |> parse_mouse_click |> nearby_intersection s.canvas.tiles with
    | None -> print_endline "I am afraid I cannot do that.\n"; settlement s
    | Some i ->
      let sx = do_move (InitSettlement i) None s in
      if s = sx then
        begin
          print_endline "I am afraid I cannot do that.\n";
          settlement s
        end
      else let _ = print_endline "Ok.\n" in sx
  in
  let rec road s =
    ANSITerminal.(print_string [cyan] "Please pick a road.");
    print_newline ();
    match () |> parse_mouse_click |> nearby_edge s.canvas.tiles with
    | None -> print_endline "I am afraid I cannot do that.\n"; road s
    | Some i ->
      let sx = do_move (InitRoad i) None s in
      if s = sx then
        begin
          print_endline "I am afraid I cannot do that.\n";
          road s
        end
      else let _ = print_endline "Ok.\n" in sx
  in
  let rec helper n s =
    let _ = update_canvas s in
    if n = 8 then s
    else if n < 4 then
      let sx =
        if s.turn = Red then
          let temp = settlement s in
          let _ = update_canvas temp in
          temp |> road
        else
          let i = first_settlement s s.turn in
          let temp = s |> do_move (InitSettlement i) None in
          let r = init_road temp s.turn i in
          temp |> do_move (InitRoad r) None
      in
      if n <> 3 then sx |> end_turn true |> helper (n + 1)
      else sx |> helper (n + 1)
    else
      let sx =
        begin
          if s.turn = Red then
            let temp = settlement s in
            let _ = update_canvas temp in
            temp |> road
          else
            let i = second_settlement s s.turn in
            let temp = s |> do_move (InitSettlement i) None in
            let r = init_road temp s.turn i in
            temp |> do_move (InitRoad r) None
        end
        |> init_generate_resources s.turn
      in
      sx |> end_turn false |> helper (n + 1)
  in
  s |> helper 0

let trade s = failwith ""

let rec repl (cmd : command) (clr_opt : color option) (s : state) =
  let temp = do_move cmd clr_opt s in
  let sx =
    if s.turn <> temp.turn then (roll_dice () |> snd |> generate_resource) temp
    else temp
  in
  let _ = update_canvas sx in
  if sx.turn <> Red then repl (choose sx.turn sx) None sx
  else begin
    begin
      match cmd with
      | Start -> ()
      | BuyCard ->
        let string_of_card = function
          | Knight -> "knight"
          | RoadBuilding -> "road building"
          | YearOfPlenty -> "year of plenty"
          | Monopoly -> "monopoly"
          | VictoryPoint -> "victory point"
        in
        if s <> sx then print_endline ("Ok. You have received a "
                                       ^ (s.deck |> List.hd |> string_of_card)
                                       ^ " card.")
        else print_endline "I am afraid I cannot do that."
      | DomesticTrade (approved, lst0, lst1) ->
        if s <> sx then print_endline "Ok."
        else failwith "Unimplemented"
      | Quit -> print_endline "Goodbye."; raise Exit
      | Invalid -> print_endline "I do not understand."
      | _ ->
        if s <> sx then print_endline "Ok."
        else print_endline "I am afraid I cannot do that."
    end;
    print_newline ();
    let prompt = "Please enter a command.\n" in
    ANSITerminal.(print_string [cyan] prompt);
    print_string  "> ";
    let cmdx =
      match read_line () with
      | exception End_of_file -> Invalid
      | str -> Command.parse_text s.canvas.tiles str
    in
    repl cmdx None sx end

let main () =
  let _ = Random.self_init () in
  let s = init_state () in
  Graphics.open_graph " 1000x750";
  Graphics.set_window_title "Settlers of Clarktan by Yuchen Shen, Yishu Zhang, \
                             Esther Jun";
  draw_canvas s;
  let _ = Sys.command("clear") in
  ANSITerminal.(print_string [red] "Welcome to the Settlers of Clarktan.");
  print_newline ();
  match s |> setup |> repl Start None with
  | exception Exit -> Graphics.close_graph ()
  | _ -> print_endline "Oh no! Something went wrong."

let () = main ()
