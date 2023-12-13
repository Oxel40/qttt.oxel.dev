defmodule Qttt.GameBroker do
  use GenServer
  require Logger

  ## Server Backend

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  @impl true
  def handle_call(:open, _from, games) do
    uid = generate_uid(games)

    if is_nil(uid) or Map.has_key?(games, uid) do
      {:reply, :error, games}
    else
      {:ok, pid} = Qttt.GameMaster.start_link()
      Logger.info("Started GameMaster at #{inspect(pid)}")

      new_games =
        games
        |> Map.put(uid, pid)
        |> Map.put(pid, uid)

      {:reply, {:ok, uid, pid}, new_games}
    end
  end

  @impl true
  def handle_call({:lookup, uid}, _from, games) do
    if Map.has_key?(games, uid) do
      val = games[uid]
      {:reply, {:ok, val}, games}
    else
      {:reply, :error, games}
    end
  end

  @impl true
  def handle_info({:EXIT, from, reason}, games) do
    if Map.has_key?(games, from) do
      Logger.error("GameMaster #{inspect(from)} down, #{inspect(reason)}")
      uid = games[from]
      games = Map.drop(games, [uid, from])
      {:noreply, games}
    else
      {:stop, "Got EXIT signal with reason: #{inspect(reason)}"}
    end
  end

  defp generate_uid(games, reties \\ 10) do
    uid = for _ <- 1..4, into: "", do: <<Enum.random(~c"ABCDEFGHIJKLMNOPQRSTUVWXY")>>

    if Map.has_key?(games, uid) do
      if reties > 0 do
        generate_uid(games, reties - 1)
      else
        nil
      end
    else
      uid
    end
  end

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  def open() do
    GenServer.call(__MODULE__, :open)
  end

  def lookup(uid) do
    GenServer.call(__MODULE__, {:lookup, uid})
  end
end
