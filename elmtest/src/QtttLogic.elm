module QtttLogic exposing (..)

import Array exposing (Array)


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
