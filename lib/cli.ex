use Mix.Config
defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    IO.inspect args
    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    args |> parse_args |> process_options([node()|Node.list])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests],
                              strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], []} ->
        do_requests(n, url, nodes)

      _ ->
        do_help()

    end
  end

  defp do_requests(n_requests, url, nodes) do
    Logger.info "Blitzing #{url} with #{n_requests} requests"

    total_nodes = Enum.count(nodes)
    req_per_node = div(n_requests, total_nodes)

    nodes
    |> IO.inspect
    |> Enum.flat_map(fn node ->
      1..req_per_node |> Enum.map(fn _ ->
        Task.Supervisor.async({Blitzy.TasksSupervisor, node}, Blitzy.Worker, :start, [url])
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp do_help do
    IO.puts """
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n, [--requests]      # Number of requests (total)

    Example:
    ./blitzy -n 100 https://yahoo.com
    """
    System.halt(0)
  end

  @doc """
  Runs n_workers GET requests against url, returning a list of
  times to retrieve the page.
  """
  def run(n_workers, url) when n_workers > 0 do
    worker_fun = fn -> Blitzy.Worker.start(url) end

    1..n_workers
    |> Enum.map(fn _ -> Task.async(worker_fun) end)
    |> Enum.map(&Task.await(&1, :infinity))  # let HTTPoison.get handle timeout
  end

  defp parse_results(results) do
    {successes, _failures} =
      results
      |> Enum.split_with(fn x ->
        case x do
          {:ok, _} -> true
          _       -> false
        end
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    data = successes |> Enum.map(fn {:ok, time} -> time end)
    average_time = average(data)
    longest_time = Enum.max(data)
    shortest_time = Enum.min(data)

    IO.puts """
    Total workers     : #{total_workers}
    Successful reqs   : #{total_success}
    Failed reqs       : #{total_failure}

    Average (msecs)   : #{average_time}
    Longest (msecs)   : #{longest_time}
    Shortest (msecs)  : #{shortest_time}
    """
  end

  defp average(list) do
    sum = Enum.sum(list)
    if sum > 0 do
      sum / Enum.count(list)
    else
      0
    end
  end

end
