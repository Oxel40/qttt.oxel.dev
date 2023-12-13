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

  defp is_nil_player(player) do
    case player do
      nil_player() -> true
      _ -> false
    end
  end

  defp broadcast_msg(msg, state) do
    [:p1, :p2]
    |> Enum.filter(fn p -> !is_nil(state.players[p].pid) end)
    |> Enum.map(fn p ->
      pid = state.players[p].pid
      Logger.debug("Msg: #{inspect(pid)}, #{inspect(p)} -> #{inspect(msg)}")
      send(pid, msg)
    end)
  end

  defp broadcast_board(state) do
    broadcast_msg({:board_update, state.board}, state)
  end

  defp broadcast_turn(state) do
    [:p1, :p2]
    |> Enum.filter(fn p -> !is_nil(state.players[p].pid) end)
    |> Enum.map(fn p ->
      pid = state.players[p].pid

      Logger.debug(
        "Turn: #{inspect(pid)}, #{inspect(p)} == #{inspect(state.turn)} -> p == state.turn"
      )

      send(pid, {:turn_update, p == state.turn})
    end)
  end

  defp handle_move({m1, m2}, state) do
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
        if state.mode != :local do
          case turn do
            :p1 -> :p2
            :p2 -> :p1
          end
        else
          turn
        end
      end)

    broadcast_board(state)
    broadcast_turn(state)

    state
  end

  ## Server Backend

  @impl true
  def init(mode) do
    if mode not in [:local, :online, :ai] do
      {:stop, "Mode #{inspect(mode)} is not valid"}
    else
      state = %{
        mode: mode,
        board: GameBoard.new(),
        players: %{p1: nil_player(), p2: nil_player()},
        turn: :p1
      }

      {:ok, state}
    end
  end

  @impl true
  def handle_cast(:stop, state) do
    {:stop, "Recieved :stop msg", state}
  end

  @impl true
  def handle_call(:join, {pid, _mid}, state) do
    case {state.players, state.mode} do
      {%{p1: nil_player()}, _} ->
        ref = Process.monitor(pid)
        {:reply, {:ok, state.board}, put_in(state.players.p1, %{pid: pid, ref: ref})}

      {%{p2: nil_player()}, :online} ->
        ref = Process.monitor(pid)
        {:reply, {:ok, state.board}, put_in(state.players.p2, %{pid: pid, ref: ref})}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:make_move, move}, {pid, _mid}, state) do
    if pid != state.players[state.turn].pid do
      Logger.error(
        "Pid not in turn tried to make a move, #{inspect(pid)} != #{inspect(state.players[state.turn].pid)}"
      )

      {:reply, :error, state}
    else
      state = handle_move(move, state)

      # TODO make nicer
      if state.mode == :ai and state.turn == :p2 and !state.board.done do
        send(self(), :_internal_ai_move)
      end

      {:reply, {:ok, state.board}, state}
    end
  end

  def handle_info(:_internal_ai_move, state) do
    move = PY.ai_move(state.board)
    state = handle_move(move, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, object, reason}, state) do
    p1ref = state.players.p1.ref
    p2ref = state.players.p2.ref

    {msg, state} =
      case ref do
        ^p1ref ->
          Logger.error("Player 1 disconnected, reason: #{inspect(reason)}")
          {:noreply, put_in(state.players.p1, nil_player())}

        ^p2ref ->
          Logger.error("Player 2 disconnected, reason: #{inspect(reason)}")
          {:noreply, put_in(state.players.p2, nil_player())}

        _ ->
          Logger.error(
            "Unknown DOWN message, ref: #{inspect(ref)}, object: #{inspect(object)}, reason: #{inspect(reason)}"
          )

          {:noreply, state}
      end

    if is_nil_player(state.players.p1) and is_nil_player(state.players.p2) do
      Process.send_after(self(), :shutdown_if_idle, 5000)
      {msg, state}
    else
      {msg, state}
    end
  end

  @impl true
  def handle_info(:shutdown_if_idle, state) do
    if is_nil_player(state.players.p1) and is_nil_player(state.players.p2) do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  ## Client API

  def start_link_in_mode(mode, opts \\ []) do
    GenServer.start_link(__MODULE__, mode, opts)
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
