module Test exposing (..)

import Array exposing (Array)
import Browser
import Debug exposing (log)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import PieceSvg exposing (pieceSvg)
import QtttLogic exposing (..)
import Random


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    GameState


init : () -> ( Model, Cmd Msg )
init _ =
    ( initGameState
    , Cmd.none
    )


type Msg
    = Clicked Int
    | Collapse Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Clicked i ->
            let
                next_turn p =
                    case p of
                        X ->
                            O

                        _ ->
                            X

                ( new_moves, new_selection, new_turn ) =
                    case model.selection of
                        Just s ->
                            if s /= i then
                                ( model.moves ++ [ Move s i model.turn ]
                                , Nothing
                                , next_turn model.turn
                                )

                            else
                                ( model.moves
                                , Nothing
                                , model.turn
                                )

                        Nothing ->
                            ( model.moves
                            , Just i
                            , model.turn
                            )

                tmp_model =
                    { model
                        | moves = new_moves
                        , selection = new_selection
                        , turn = new_turn
                    }

                cmd =
                    if new_turn /= model.turn then
                        Random.generate Collapse (Random.int 0 1)

                    else
                        Cmd.none
            in
            ( tmp_model
            , cmd
            )

        Collapse i ->
            ( updateBoard i model
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ div [ class "flex items-center justify-center h-screen" ]
            [ div [ class "grow shrink max-w-3xl max-h-3xl grid grid-cols-3 gap-4 p-3" ]
                (List.map (\i -> cell i model) (List.range 0 8))
            ]
        ]


cell : Int -> Model -> Html Msg
cell i model =
    let
        p =
            getPiece i model.board

        content : Html Msg
        content =
            case p of
                Empty ->
                    div [ class "grow shrink max-w-3xl max-h-3xl grid grid-cols-3" ]
                        (List.map (\si -> subCell i si model) (List.range 0 8))

                _ ->
                    pieceSvg p

        clickEvents =
            if getPiece i model.board == Empty then
                [ onClick (Clicked i) ]

            else
                []
    in
    div
        (class (pieceColor p ++ " aspect-square p-3 rounded-lg " ++ cellColor i model)
            :: clickEvents
        )
        [ content
        ]


subCell : Int -> Int -> Model -> Html Msg
subCell i si model =
    let
        p =
            case List.head (List.drop si model.moves) of
                Just m ->
                    if m.s1 == i || m.s2 == i then
                        m.p

                    else
                        Empty

                _ ->
                    Empty
    in
    div
        [ class (pieceColor p ++ " aspect-square p-1")
        ]
        [ pieceSvg p
        ]


pieceColor : Piece -> String
pieceColor p =
    if p == X then
        "stroke-cyan-500"

    else
        "stroke-rose-500"


cellColor : Int -> Model -> String
cellColor i model =
    if model.selection == Just i then
        if model.turn == X then
            "bg-cyan-300 hover:bg-cyan-400"

        else
            "bg-rose-300 hover:bg-rose-400"

    else
        "bg-slate-300 hover:bg-slate-400"
