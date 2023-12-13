defmodule Qttt.GameMaster do
  use GenServer
  require Logger
  alias Qttt.GameBoard
  alias Qttt.Python, as: PY

  defmacro nil_player do
    quote do
      %{pid: nil, ref: nil}
    end
  end

  defp broadcast_msg(msg, state) do
    Enum.map([:p1, :p2], fn p ->
      pid = state.players[p].pid
      send(pid, msg)
    end)
  end

  defp broadcast_board(state) do
    broadcast_msg({:board_update, state.board}, state)
  end

  defp broadcast_turn(state) do
    Enum.map([:p1, :p2], fn p ->
      pid = state.players[p].pid
      send(pid, {:turn_update, p == state.turn})
    end)
  end

  ## Server Backend

  @impl true
  def init(_) do
    state = %{
      board: GameBoard.new(),
      players: %{p1: nil_player(), p2: nil_player()},
      turn: :p1
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    {:stop, "Recieved :stop msg", state}
  end
  
  @impl true
  def handle_call(:join, {pid, _mid}, state) do
    case state.players do
      %{p1: nil_player()} ->
        ref = Process.monitor(pid)
        {:reply, {:ok, state.board}, put_in(state.players.p1, %{pid: pid, ref: ref})}

      %{p2: nil_player()} ->
        ref = Process.monitor(pid)
        {:reply, {:ok, state.board}, put_in(state.players.p2, %{pid: pid, ref: ref})}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:make_move, {m1, m2}}, {pid, _mid}, state) do
    if pid != state.players[state.turn].pid do
      Logger.error(
        "Pid not in turn tried to make a move, #{inspect(pid)} != #{inspect(state.players[state.turn].pid)}"
      )

      {:reply, :error, state}
    else
      state =
        state
        |> update_in([:board], fn board ->
          board
          |> GameBoard.make_move(m1, m2)
          |> GameBoard.evaluate_qevents()
          |> GameBoard.fill_in_empty_square()
          |> GameBoard.check_win()
        end)
        |> update_in([:turn], fn turn ->
          case turn do
            :p1 -> :p2
            :p2 -> :p1
          end
        end)

      broadcast_board(state)
      broadcast_turn(state)

      {:reply, state.board, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, object, reason}, state) do
    p1ref = state.players.p1.ref
    p2ref = state.players.p2.ref

    case ref do
      ^p1ref ->
        Logger.error("Player 1 disconnected, reason: #{reason}")
        {:noreply, put_in(state.players.p1, nil_player())}

      ^p2ref ->
        Logger.error("Player 2 disconnected, reason: #{reason}")
        {:noreply, put_in(state.players.p2, nil_player())}

      _ ->
        Logger.error("Unknown DOWN message, ref: #{inspect(ref)}, object: #{inspect(object)}, reason: #{reason}")
        {:noreply, state}
    end
  end

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def join(server) do
    GenServer.call(server, :join)
  end

  def make_move(server, move) do
    GenServer.call(server, {:make_move, move})
  end

  def stop(server) do
    GenServer.cast(server, :stop)
  end
end
