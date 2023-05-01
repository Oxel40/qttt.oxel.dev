module PieceSvg exposing (o, pieceSvg, x)

import Html exposing (Html)
import QtttLogic exposing (..)
import Svg exposing (..)
import Svg.Attributes exposing (..)


x : Html msg
x =
    svg
        [ viewBox "0 0 100 100"
        ]
        [ line
            [ x1 "20"
            , y1 "20"
            , x2 "80"
            , y2 "80"
            , strokeWidth "25"
            , strokeLinecap "round"
            ]
            []
        , line
            [ x1 "20"
            , y1 "80"
            , x2 "80"
            , y2 "20"
            , strokeWidth "25"
            , strokeLinecap "round"
            ]
            []
        ]


o : Html msg
o =
    svg
        [ viewBox "0 0 100 100"
        ]
        [ circle
            [ cx "50"
            , cy "50"
            , r "35"
            , strokeWidth "20"
            , fill "none"
            ]
            []
        ]


pieceSvg : Piece -> Html msg
pieceSvg p =
    case p of
        X ->
            x

        O ->
            o

        _ ->
            svg [ width "0", height "0" ] []
