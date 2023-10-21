module QtttLogic exposing (..)

import Array exposing (Array)
import Debug exposing (log)


type Piece
    = X
    | O
    | Empty


type alias Move =
    { s1 : Int
    , s2 : Int
    , p : Piece
    }


type alias GameState =
    { board : Array Piece
    , moves : List Move
    , selection : Maybe Int
    , turn : Piece
    }


type alias QStructs =
    Array ( List Move, List Int )


initGameState : GameState
initGameState =
    GameState (Array.repeat 9 Empty) [] Nothing X


initDebugGameState : GameState
initDebugGameState =
    GameState (Array.fromList [ Empty, Empty, X, O, Empty, Empty, Empty, Empty, Empty ])
        [ Move 0 1 X, Move 1 5 O ]
        Nothing
        X


moveFilter : Array Piece -> Move -> Bool
moveFilter board move =
    case ( getPiece move.s1 board, getPiece move.s2 board ) of
        ( Empty, Empty ) ->
            True

        _ ->
            False


updateBoard : Int -> GameState -> GameState
updateBoard collapse_res gs =
    let
        pot_moves =
            log "pot_moves" (List.filter (moveFilter gs.board) gs.moves)

        ent_moves =
            log "ent_moves" (filterCyclicallyEntangledMoves pot_moves Array.empty)

        new_board =
            List.foldl (\( i, p ) b -> Array.set i p b) gs.board (qCollapse collapse_res ent_moves)
    in
    { gs | board = new_board }


qCollapse : Int -> List Move -> List ( Int, Piece )
qCollapse collapse_res moves =
    case moves of
        move :: rest_moves ->
            if collapse_res == 0 then
                qCollapsePropegate rest_moves [] [ ( move.s1, move.p ) ]

            else
                qCollapsePropegate rest_moves [] [ ( move.s2, move.p ) ]

        [] ->
            log "No moves provided to qCollapse" []


qCollapsePropegate : List Move -> List Move -> List ( Int, Piece ) -> List ( Int, Piece )
qCollapsePropegate moves checked_moves out =
    case moves of
        move :: rest_moves ->
            if List.member move.s1 (List.map (\( i, _ ) -> i) out) then
                qCollapsePropegate rest_moves checked_moves (( move.s2, move.p ) :: out)

            else if List.member move.s2 (List.map (\( i, _ ) -> i) out) then
                qCollapsePropegate rest_moves checked_moves (( move.s1, move.p ) :: out)

            else
                qCollapsePropegate rest_moves (move :: checked_moves) out

        [] ->
            if List.length checked_moves == 0 then
                out

            else
                qCollapsePropegate checked_moves [] out


filterCyclicallyEntangledMoves : List Move -> QStructs -> List Move
filterCyclicallyEntangledMoves moves structs =
    case moves of
        move :: rest_moves ->
            let
                -- get all indecies where structs exists that contains move.sX
                pot =
                    log "- pot indexes"
                        (Array.map
                            (\( i, _ ) -> i)
                            (Array.filter
                                (\( _, ( _, s ) ) -> List.member move.s1 s || List.member move.s2 s)
                                (Array.indexedMap Tuple.pair structs)
                            )
                        )

                new_structs =
                    if Array.isEmpty pot then
                        Array.fromList [ ( [ move ], [ move.s1, move.s2 ] ) ]

                    else
                        Array.foldl
                            (addMoveToStruct move)
                            structs
                            pot
            in
            filterCyclicallyEntangledMoves rest_moves new_structs

        [] ->
            []


addMoveToStruct : Move -> Int -> QStructs -> QStructs
addMoveToStruct move idx struct =
    let
        ( moves, squares ) =
            case Array.get idx struct of
                Just ( a, b ) ->
                    ( a, b )

                Nothing ->
                    log "This should not be posible (in addMoveToStruct)" ( [], [] )

        new_moves =
            move :: moves

        new_squares =
            move.s2 :: move.s1 :: squares

        new_struct =
            Array.set idx ( new_moves, new_squares ) struct
    in
    new_struct


getPiece : Int -> Array Piece -> Piece
getPiece i arr =
    case Array.get i arr of
        Just v ->
            v

        Nothing ->
            Empty
