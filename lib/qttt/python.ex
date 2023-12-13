defmodule Qttt.Python do
  use GenServer
  require Logger

  ## Server Backend

  @impl true
  def init(_) do
    path_candidates =
      ["python3", "python"]
      |> Enum.map(&System.find_executable/1)
      |> Enum.filter(fn e -> !is_nil(e) end)

    python_path =
      case path_candidates do
        [p | _] ->
          Logger.info("Python found at #{p}")
          p

        _ ->
          backup_path = "/usr/bin/python3"
          Logger.warning("No python or python3 found, using #{backup_path}")
          backup_path
      end

    script_path = Path.join([:code.priv_dir(:qttt), "python", "qttt_new.py"])

    port = Port.open({:spawn_executable, python_path}, [:binary, args: [script_path]])
    Port.monitor(port)

    {:ok, port}
  end

  @impl true
  def handle_call(msg, _from, port) do
    true = Port.command(port, msg)

    receive do
      {^port, {:data, val}} ->
        {:reply, val, port}

      {:DOWN, _ref, :port, _object, _reason} ->
        {:stop, "port down", port}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :port, _object, _reason}, port) do
    {:stop, "port down", port}
  end

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__] ++ opts)
  end

  def add(a, b) do
    GenServer.call(__MODULE__, "#{a} #{b}\n")
    |> String.trim_trailing()
    |> String.to_integer()
  end

  def ai_move(board) do
    conv_moves =
      board.moves
      |> Enum.map(&Tuple.to_list/1)
      |> Enum.map(fn t -> Enum.map(t, &(&1 - 1)) end)

    conv_squares =
      board.squares
      # |> Enum.map(fn {k,v} -> {k, v} end)
      |> Enum.sort()
      |> Enum.map(fn {_k, v} -> if(is_integer(v), do: v, else: -1) end)

    json = Jason.encode!(%{"moves" => conv_moves, "squares" => conv_squares})

    res =
      GenServer.call(__MODULE__, "#{json}\n", 40000)
      |> IO.inspect(label: "from python")
      |> Jason.decode!()
      |> IO.inspect(label: "from python decoded")

    res["move"]
    |> Enum.map(&(&1 + 1))
    |> List.to_tuple()
  end
end
