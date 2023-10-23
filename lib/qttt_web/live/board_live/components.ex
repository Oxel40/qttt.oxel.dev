defmodule BoardComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def render_board(assigns) do
    ~H"""
    <button phx-click={JS.push("clicked")}>click me!</button>
    <%= for {k, v} <- @board.squares do %>
      <div phx-click={JS.push("select", value: %{sqr: k})}>
        <%= if is_atom(v) do %>
          <p>Pie: <%= v %></p>
          <.render_piece piece={v} />
        <% else %>
          <p>Sub: <%= Enum.join(v, ",") %></p>
          <.render_sub_board moves={v} />
        <% end %>
      </div>
    <% end %>
    """
  end

  defp render_sub_board(assigns) do
    IO.inspect(assigns.moves)

    ~H"""
    <%= for i <- 0..8 do %>
      <%= if i in @moves do %>
        <.render_piece piece={if rem(i, 2) == 0, do: :o, else: :x} />
      <% else %>
        _
      <% end %>
    <% end %>
    """
  end

  defp render_piece(assigns) do
    case assigns.piece do
      :x ->
        ~H"X"

      :o ->
        ~H"O"

      other ->
        raise "Invalid piece #{IO.inspect(other)}"
    end
  end
end
