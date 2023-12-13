defmodule QtttWeb.BoardLive do
  alias Qttt.GameBoard
  # alias Qttt.Python, as: PY
  use QtttWeb, :live_view
  require Logger

  def render(assigns) do
    ~H"""
    <BoardComponent.render_board board={@board} selected={@selected} />
    """
  end

  def mount(%{"mode" => "online", "uid" => uid}, _session, socket) do
    {:ok, pid} = Qttt.GameBroker.lookup(uid)
    {:ok, board} = Qttt.GameMaster.join(pid)

    socket =
      socket
      |> assign(board: board, selected: nil, mode: :online, turn: :local, gm: pid)

    {:ok, socket, layout: {QtttWeb.Layouts, :blank}}
  end

  # TODO make an actual interface from this
  def mount(%{"mode" => "online"}, _session, socket) do
    {:ok, uid, _pid} = Qttt.GameBroker.open(:online)
    {:ok, redirect(socket, to: ~p"/online/#{uid}"), layout: {QtttWeb.Layouts, :blank}}
  end

  def mount(%{"mode" => mode}, _session, socket) do
    mode =
      case mode do
        "ai" -> :ai
        "local" -> :local
        _ -> nil
      end

    if is_nil(mode) do
      {:ok, redirect(socket, to: ~p"/"), layout: {QtttWeb.Layouts, :blank}}
    else
      {:ok, _uid, pid} = Qttt.GameBroker.open(mode)
      {:ok, board} = Qttt.GameMaster.join(pid)

      socket =
        socket
        |> assign(board: board, selected: nil, mode: mode, turn: :local, gm: pid)

      {:ok, socket, layout: {QtttWeb.Layouts, :blank}}
    end
  end

  def mount(_params, _session, socket) do
    socket =
      redirect(socket, to: ~p"/")

    {:ok, socket, layout: {QtttWeb.Layouts, :blank}}
  end

  def handle_event("select", %{"sqr" => sqr}, socket) do
    selected = socket.assigns[:selected]

    case selected do
      nil ->
        {:noreply, assign(socket, selected: sqr)}

      ^sqr ->
        {:noreply,
         socket
         |> assign(:selected, nil)}

      snd_sqr ->
        {:noreply,
         socket
         |> handle_turn(sqr, snd_sqr)
         |> assign(:selected, nil)}
    end
  end

  def handle_event(event, params, socket) do
    Logger.error("Unseen event \"#{event}\" with params \"#{inspect(params)}\"")
    {:noreply, socket}
  end

  def handle_info({:board_update, board}, socket) do
    {:noreply, assign(socket, :board, board)}
  end

  def handle_info({:turn_update, turn}, socket) do
    {:noreply, disable_board(socket, !turn)}
  end

  defp handle_turn(socket, sqr1, sqr2) do
    {:ok, board} = Qttt.GameMaster.make_move(socket.assigns.gm, {sqr1, sqr2})
    assign(socket, :board, board)
  end

  defp disable_board(socket, val) do
    socket
    |> update(:board, fn board ->
      GameBoard.set_disable(board, val)
    end)
  end
end
