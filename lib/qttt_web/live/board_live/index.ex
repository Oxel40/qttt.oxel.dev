defmodule QtttWeb.BoardLive do
  alias Qttt.GameBoard
  alias Qttt.Python, as: PY
  use QtttWeb, :live_view
  require Logger

  def render(assigns) do
    ~H"""
    <BoardComponent.render_board board={@board} selected={@selected} />
    """
  end

  def mount(_params, _session, socket) do
    board =
      GameBoard.new()

    socket =
      socket
      |> assign(board: board, selected: nil)

    {:ok, socket, layout: {QtttWeb.Layouts, :blank}}
  end

  def handle_event("select", %{"sqr" => sqr}, socket) do
    Logger.info("Selected square #{sqr}")
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
         |> update(:board, fn board ->
           board
           |> GameBoard.make_move(sqr, snd_sqr)
           |> GameBoard.evaluate_qevents()
           |> GameBoard.fill_in_empty_square()
           |> GameBoard.check_win()
           |> (fn board ->
                 {ai_sqr1, ai_sqr2} = PY.ai_move(board)
                 GameBoard.make_move(board, ai_sqr1, ai_sqr2)
               end).()
         end)
         |> assign(:selected, nil)}
    end
  end

  def handle_event(event, params, socket) do
    Logger.error("Unseen event \"#{event}\" with params \"#{inspect(params)}\"")
    {:noreply, socket}
  end
end
