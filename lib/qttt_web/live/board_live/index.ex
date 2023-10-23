defmodule QtttWeb.BoardLive do
  alias Qttt.GameBoard
  use QtttWeb, :live_view
  require Logger

  def render(assigns) do
    # ~H"""
    # <BoardComponent.greet name="Mary" list={[1, 2, 3]} />
    # """
    ~H"""
    <BoardComponent.render_board board={@board} selected={@selected} />
    """
  end

  def mount(_params, _session, socket) do
    board =
      GameBoard.new()
      # |> GameBoard.make_move(3, 4)
      # |> GameBoard.make_move(4, 1)
      # |> GameBoard.set_square(5, :o)

    {:ok, assign(socket, board: board, selected: nil)}
  end

  def handle_event("select", %{"sqr" => sqr}, socket) do
    Logger.info("Selected square #{sqr}")
    selected = socket.assigns[:selected]

    if selected == nil do
      {:noreply, assign(socket, selected: sqr)}
    else
      {:noreply,
       socket
       |> update(:board, fn board -> GameBoard.make_move(board, sqr, selected) end)
       |> assign(:selected, nil)}
    end
  end

  def handle_event(event, params, socket) do
    Logger.error("Unseen event \"#{event}\" with params \"#{inspect(params)}\"")
    {:noreply, socket}
  end
end
