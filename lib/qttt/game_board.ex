defmodule Qttt.GameBoard do
  require Logger

  @typedoc """
  The posible piece representations
  """
  @type piece :: :x | :o

  @typedoc """
  A representation of the game board state
  """
  @type board :: %{
          moves: [{integer(), integer()}],
          squares: %{integer() => [integer()] | piece},
          turn: piece
        }

  @spec new() :: board
  def new() do
    %{moves: [], squares: Map.new(1..9, fn k -> {k, []} end), turn: :x}
  end

  @spec set_square(board, integer(), piece) :: board
  def set_square(board, a, p) when a in 1..9 and is_atom(p) do
    updated_squares =
      board.squares
      |> Map.put(a, p)

    Map.put(board, :squares, updated_squares)
  end

  @spec make_move(board, integer(), integer()) :: board
  def make_move(board, a, b) when a != b and a in 1..9 and b in 1..9 do
    if is_atom(board.squares[a]) do
      raise "Square #{a} is aleardy populated by piece #{board.squares[a]}"
    end

    if is_atom(board.squares[b]) do
      raise "Square #{b} is aleardy populated by piece #{board.squares[b]}"
    end

    turn = length(board.moves)

    if turn >= 9 do
      raise "Tried to make a move on turn #{turn}"
    end

    updated_moves =
      board.moves ++ [{a, b}]

    updated_squares =
      board.squares
      |> Map.update!(a, fn t -> [turn | t] end)
      |> Map.update!(b, fn t -> [turn | t] end)

    updated_turn =
      case board.turn do
        :x -> :o
        :o -> :x
      end

    board
    |> Map.put(:moves, updated_moves)
    |> Map.put(:squares, updated_squares)
    |> Map.put(:turn, updated_turn)
  end

  @spec fill_in_empty_square(board) :: board
  def fill_in_empty_square(board) do
    turn = length(board.moves)
    empty_sqrs = Enum.filter(Map.keys(board.squares), &Enum.empty?(board.squares[&1]))

    updated_moves =
      if turn == 8 and length(empty_sqrs) == 1 do
        [empty_sqr] = empty_sqrs
        board.moves ++ [{empty_sqr, empty_sqr}]
      else
        board.moves
      end

    updated_squares =
      if turn == 8 and length(empty_sqrs) == 1 do
        [empty_sqr] = empty_sqrs
        Map.put(board.squares, empty_sqr, [turn, turn])
      else
        board.squares
      end

    updated_turn =
      case board.turn do
        :x -> :o
        :o -> :x
      end

    board
    |> Map.put(:moves, updated_moves)
    |> Map.put(:squares, updated_squares)
    |> Map.put(:turn, updated_turn)
  end

  @spec evaluate_qevents(board) :: board
  def evaluate_qevents(board) do
    case find_cycle(board) do
      {true, cycle} ->
        board

      false ->
        board
    end
  end

  @spec find_cycle(board) :: {true, [integer()]} | false
  def find_cycle(board) do
    false
  end
end
