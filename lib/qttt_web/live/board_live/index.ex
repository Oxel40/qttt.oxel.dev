defmodule QtttWeb.BoardLive do
  use QtttWeb, :live_view
  require Logger

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>
    <button phx-click="inc_temperature">+</button>
    <BoardComponent.greet name="Mary" />
    """
  end

  def mount(_params, _session, socket) do
    temperature = 0
    {:ok, assign(socket, :temperature, temperature)}
  end

  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  def handle_event(event, _params, socket) do
    Logger.info("Unseen event", IO.inspect(event))
    {:noreply, socket}
  end
end
