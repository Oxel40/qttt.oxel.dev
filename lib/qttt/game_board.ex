defmodule Qttt.GameBoard do
  require Logger

  @typedoc """
  A representation of the game board state
  """
  @type board :: %{
          moves: [{integer(), integer()}],
          squares: %{integer() => [integer()] | integer()},
          done: :false | integer(),
          disable: boolean()
        }

  @spec new() :: board
  def new() do
    %{moves: [],
    squares: Map.new(1..9, fn k -> {k, []} end),
    done: false,
    disable: false}
  end

  @spec set_disable(board, boolean()) ::board
  def set_disable(board, val) do
    %{board | disable: val}
  end

  @spec set_square(board, integer(), integer()) :: board
  def set_square(board, a, p) when a in 1..9 and is_integer(p) do
    updated_squares =
      board.squares
      |> Map.put(a, p)

    Map.put(board, :squares, updated_squares)
  end

  @spec make_move(board, integer(), integer()) :: board
  def make_move(board, a, b) when a != b and a in 1..9 and b in 1..9 do
    if is_integer(board.squares[a]) do
      raise "Square #{a} is aleardy populated by piece #{board.squares[a]}"
    end

    if is_integer(board.squares[b]) do
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

    board
    |> Map.put(:moves, updated_moves)
    |> Map.put(:squares, updated_squares)
  end

  @spec fill_in_empty_square(board) :: board
  def fill_in_empty_square(board) do
    turn = length(board.moves)

    empty_sqrs =
      Enum.filter(
        Map.keys(board.squares),
        &(is_list(board.squares[&1]) && Enum.empty?(board.squares[&1]))
      )

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
        Map.put(board.squares, empty_sqr, turn)
      else
        board.squares
      end

    board
    |> Map.put(:moves, updated_moves)
    |> Map.put(:squares, updated_squares)
  end

  @spec evaluate_qevents(board) :: board
  def evaluate_qevents(board) do
    starters = find_cycle(board)

    Enum.reduce(starters, board, fn mv, b -> collapse_cycle(b, mv) end)
  end

  @spec check_win(board) :: board
  def check_win(board) do
    win_sequences = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [1, 4, 7],
      [2, 5, 8],
      [3, 6, 9],
      [1, 5, 9],
      [3, 5, 7]
    ]

    win_at =
      win_sequences
      |> Enum.map(fn seq ->
        {Enum.reduce(
           seq,
           {true, true},
           fn e, {even, odd} ->
             sqr = board.squares[e]

             if is_integer(sqr) do
               {even and rem(sqr, 2) == 0, odd and rem(sqr, 2) != 0}
             else
               {false, false}
             end
           end
         ), seq}
      end)
      |> Enum.map(fn {{even, odd}, seq} ->
        if even or odd do
          {Enum.max(Enum.map(seq, fn e -> board.squares[e] end)), seq}
        else
          {false, seq}
        end
      end)
      |> Enum.filter(fn {a, _} -> a end)
      |> Enum.min(fn -> false end)

    if win_at do
      %{board | done: win_at}
    else
      %{board | done: :no}
    end
  end

  @spec find_cycle(board) :: [{integer(), integer()}]
  defp find_cycle(board) do
    Logger.info(inspect(board))

    {_, _, starters} =
      board.moves
      |> Enum.zip(0..9)
      |> Enum.reduce({%{}, 0, []}, &cycle_reduction(board, &1, &2))

    starters
  end

  @spec collapse_cycle(board, integer()) :: board
  defp collapse_cycle(board, start_turn) do
    {m1, m2} = Enum.at(board.moves, start_turn)
    pos = Enum.random([m1, m2])
    collapse_cycle(board, pos, [start_turn])
  end

  @spec collapse_cycle(board, integer(), [integer()]) :: board
  defp collapse_cycle(board, _ocu, []) do
    board
  end

  defp collapse_cycle(board, ocu, [turn | rest]) do
    {m1, m2} = Enum.at(board.moves, turn)
    pos = if(m1 == ocu, do: m2, else: m1)

    if !is_list(board.squares[pos]) do
      collapse_cycle(board, ocu, rest)
    else
      affected = Enum.filter(board.squares[pos], &(turn != &1))

      board
      |> set_square(pos, turn)
      |> collapse_cycle(pos, affected)
      |> collapse_cycle(ocu, rest)
    end
  end

  defp cycle_reduction(board, mv, {ents, counter, closers}) do
    {{sqr1, sqr2}, turn} = mv

    if is_integer(board.squares[sqr1]) or is_integer(board.squares[sqr2]) do
      {ents, counter, closers}
    else
      match1 =
        ents
        |> Map.filter(fn {_k, v} ->
          MapSet.member?(v, sqr1)
        end)
        |> Map.to_list()

      match2 =
        ents
        |> Map.filter(fn {_k, v} ->
          MapSet.member?(v, sqr2)
        end)
        |> Map.to_list()

      new_counter =
        if length(match1) <= 0 and length(match2) <= 0 do
          counter + 1
        else
          counter
        end

      {new_ents, new_closers} =
        case {match1, match2} do
          {[], []} ->
            {Map.put(ents, counter, MapSet.new([sqr1, sqr2])), closers}

          {[{k, _v1}], [{k, _v2}]} ->
            {ents, [turn | closers]}

          {[{k, v}], []} ->
            {Map.put(ents, k, MapSet.put(v, sqr2)), closers}

          {[], [{k, v}]} ->
            {Map.put(ents, k, MapSet.put(v, sqr1)), closers}

          {[{k1, v1}], [{k2, v2}]} ->
            ne =
              ents
              |> Map.put(k1, MapSet.union(v1, v2))
              |> Map.delete(k2)

            {ne, closers}

          other ->
            raise "Unexpected match in find_cycle, #{board} -> #{other}"
        end

      {new_ents, new_counter, new_closers}
    end
  end
end
