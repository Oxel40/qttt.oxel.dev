defmodule BoardComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def render_board(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-screen">
      <div class="grow shrink max-w-3xl max-h-3xl grid grid-cols-3 gap-4 p-3">
        <%= for i <- 1..9 do %>
          <div
            class={"#{cell_color(i, @selected, length(@board.moves))} aspect-square p-3 rounded-lg"}
            phx-click={if !is_integer(@board.squares[i]), do: JS.push("select", value: %{"sqr" => i})}
          >
            <.render_cell i={i} board={@board} ) />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_cell(assigns) do
    ~H"""
    <%= if is_integer(@board.squares[@i]) do %>
      <.render_piece piece={@board.squares[@i]} />
    <% else %>
      <.render_sub_board moves={@board.squares[@i]} />
    <% end %>
    """
  end

  defp render_sub_board(assigns) do
    ~H"""
    <div class="grow shrink grid grid-cols-3">
      <%= for i <- 0..8 do %>
        <div class="aspect-square md:p-1">
          <%= if i in @moves do %>
            <.render_piece piece={i} />
          <% else %>
            <div />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_piece(assigns) do
    case rem(assigns.piece, 2) do
      0 ->
        ~H"""
        <svg viewBox="0 0 100 100" class={piece_color(@piece)}>
          <line x1="20" y1="20" x2="80" y2="80" stroke-linecap="round" />
          <line x1="20" y1="80" x2="80" y2="20" stroke-linecap="round" />
          <text x="0" y="50" class="font-mono text-sm stroke-1 stroke-slate-800"><%= @piece %></text>
        </svg>
        """

      1 ->
        ~H"""
        <svg viewBox="0 0 100 100" class={piece_color(@piece)}>
          <circle cx="50" cy="50" r="35" strokeWidth="20" fill="none" />
          <text x="0" y="50" class="font-mono text-sm stroke-1 stroke-slate-800"><%= @piece %></text>
        </svg>
        """

      other ->
        raise "Invalid piece #{inspect(other)}"
    end
  end

  defp piece_color(p) do
    case rem(p, 2) do
      0 ->
        "stroke-cyan-500 stroke-[25px]"

      1 ->
        "stroke-rose-500 stroke-[20px]"

      other ->
        raise "Invalid piece #{inspect(other)}"
    end
  end

  defp cell_color(cell, selected, turn) do
    if cell == selected do
      case rem(turn, 2) do
        0 ->
          "bg-cyan-300 hover:bg-cyan-400"

        1 ->
          "bg-rose-300 hover:bg-rose-400"
      end
    else
      "bg-slate-300 hover:bg-slate-400"
    end
  end
end
