defmodule Qttt.Python do
  use GenServer

  ## Server Backend

  @impl true
  def init(_) do
    [python_path | _] =
      ["python3", "python"]
      |> Enum.map(&System.find_executable/1)
      |> Enum.filter(fn e -> !is_nil(e) end)

    script_path = Path.join([:code.priv_dir(:qttt), "python", "test.py"])

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

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [name: :_qttt_python] ++ opts)
  end

  def add(a, b) do
    GenServer.call(:_qttt_python, "#{a} #{b}\n")
    |> String.trim_trailing()
    |> String.to_integer()
  end
end
