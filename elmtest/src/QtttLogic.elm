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


updateBoard : GameState -> GameState
updateBoard gs =
    let
        pot_moves =
            log "pot_moves" (List.filter (moveFilter gs.board) gs.moves)

        new_board =
            List.foldl (\( i, p ) b -> Array.set i p b) gs.board (qCollapse pot_moves)
    in
    { gs | board = new_board }


qCollapse : List Move -> List ( Int, Piece )
qCollapse moves =
    []


getPiece : Int -> Array Piece -> Piece
getPiece i arr =
    case Array.get i arr of
        Just v ->
            v

        Nothing ->
            Empty
