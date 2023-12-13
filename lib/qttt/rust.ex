defmodule Qttt.Rust do
  use Rustler, otp_app: :qttt, crate: "qttt_rust"
  #use GenServer
  require Logger

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  def len(_a), do: :erlang.nif_error(:nif_not_loaded)

  def ai_move(_moves, _squares), do: :erlang.nif_error(:nif_not_loaded)

  def move2idx(_move), do: :erlang.nif_error(:nif_not_loaded)

  def idx2move(_idx), do: :erlang.nif_error(:nif_not_loaded)

  ### Server Backend

  #@impl true
  #def init(_) do
  #  {:ok, {}}
  #end

  #@impl true
  #def handle_call(msg, _from, state) do
  #  {:reply, msg, state}
  #end

  ### Client API

  #def start_link(opts) do
  #  GenServer.start_link(__MODULE__, :ok, [name: :_qttt_rust] ++ opts)
  #end

  #def add(a, b) do
  #  GenServer.call(:_qttt_python, {:add, a, b})
  #end

end
