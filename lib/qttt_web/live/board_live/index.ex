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

  def mount(params, _session, socket) do
    mode =
      if params["mode"] do
        case params["mode"] do
          "ai" -> :ai
          _ -> nil
        end
      else
        :local
      end

    socket =
      if mode do
        assign(socket, mode: mode)
      else
        redirect(socket, to: ~p"/")
      end

    board =
      GameBoard.new()

    socket =
      socket
      |> assign(board: board, selected: nil, mode: mode, turn: :local)

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
         |> handle_turn(sqr, snd_sqr)
         |> (fn skt ->
               if skt.assigns[:mode] == :ai and !skt.assigns[:done] do
                 send(self(), "ai move")
                 put_flash(skt, :info, "AI is making a move...")
               else
                 skt
               end
             end).()
         |> disable_board(socket.assigns[:mode] != :local)
         |> assign(:selected, nil)}
    end
  end

  def handle_event(event, params, socket) do
    Logger.error("Unseen event \"#{event}\" with params \"#{inspect(params)}\"")
    {:noreply, socket}
  end

  def handle_info("ai move", socket) do
    {ai_sqr1, ai_sqr2} = PY.ai_move(socket.assigns[:board])

    {:noreply,
     socket
     |> clear_flash()
     |> handle_turn(ai_sqr1, ai_sqr2)
     |> disable_board(false)}
  end

  defp handle_turn(socket, sqr1, sqr2) do
    socket
    |> update(:board, fn board ->
      board
      |> GameBoard.make_move(sqr1, sqr2)
      |> GameBoard.evaluate_qevents()
      |> GameBoard.fill_in_empty_square()
      |> GameBoard.check_win()

      # |> (fn board ->
      #       is_done? = socket.assigns[:done]
      #       is_ai? = socket.assigns[:mode] == :ai
      #       is_disabled? = socket.assigns[:disable]

      #       if is_ai? and !is_disabled? and !is_done? do
      #         send(self(), "ai move")
      #         %{board | disable: true}
      #       else
      #         %{board | disable: false}
      #       end
      #     end).()
    end)
  end

  defp disable_board(socket, val) do
    socket
    |> update(:board, fn board ->
      GameBoard.set_disable(board, val)
    end)
  end
end
