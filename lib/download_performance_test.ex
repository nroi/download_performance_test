defmodule DownloadPerformanceTest do
  # @host 'repo.helios.click'
  @host 'speed.hetzner.de'
  @resource '100MB.bin'
  @filesize 104857600
  @save_to '/dev/null'

  def test_all() do
    funs = [:download_http, :download_ibrowse, :download_hackney, :download_tcp]
    Enum.each(funs, fn fun ->
      {microsecs, _} = :timer.tc(__MODULE__, fun, [])
      bw = bandwidth_to_human_readable(@filesize, microsecs)
      IO.puts "#{fun}: download took #{:erlang.trunc(microsecs / 1_000_000)} seconds, average speed: #{bw}"
    end)
  end

  def download_http() do
    {:ok, :saved_to_file} = :httpc.request(:get, {url(), []}, [], [{:stream, @save_to}])
  end

  def download_ibrowse() do
    opts = [save_response_to_file: {:append, @save_to}, stream_to: {self(), :once}]
    {:ibrowse_req_id, req_id} = :ibrowse.send_req(url(), [], :get, [], opts, :infinity)
    receive do
      {:ibrowse_async_headers, _id, '200', _} -> :ok
    end
    :ok = :ibrowse.stream_next(req_id)
    receive do
      {:ibrowse_async_response_end, _} -> :ok
    end
  end

  def download_hackney() do
    headers = []
    opts = []
    {:ok, 200, _headers, client} = :hackney.request(:get, url(), headers, "", opts)
    # Delayed write option improves performance a good bit.
    {:ok, file} = File.open(@save_to, [:append, :raw, :delayed_write])
    download_loop_hackney(client, file)
  end

  defp download_loop_hackney(client, file) do
    case :hackney.stream_body(client) do
      {:ok, result} ->
        IO.binwrite(file, result)
        download_loop_hackney(client, file)
      :done ->
        :ok = File.close(file)
    end
  end

  def download_tcp() do
    msg = 'GET /#{@resource} HTTP/1.1\r\nHost: #{@host}\r\n\r\n'
    {:ok, sock} = :gen_tcp.connect(@host, 80, [:binary, {:packet, 0}, {:active, false}])
    :ok = :gen_tcp.send(sock, msg)
    download_loop(sock, 0)
  end

  defp download_loop(_sock, size) when size >= @filesize, do: :ok
  defp download_loop(sock, size) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, data} ->
        download_loop(sock, size + byte_size(data))
      {:error, :closed} -> :ok
    end
  end

  defp url, do: 'http://#{@host}/#{@resource}'

  defp bandwidth_to_human_readable(bytes, microseconds) do
    bytes_per_second = bytes / (microseconds / 1000000)
    exponent = :erlang.trunc(:math.log2(bytes_per_second) / :math.log2(1024))
    prefix = case exponent do
               0 -> {:ok, ""}
               1 -> {:ok, "Ki"}
               2 -> {:ok, "Mi"}
               3 -> {:ok, "Gi"}
               4 -> {:ok, "Ti"}
               5 -> {:ok, "Pi"}
               6 -> {:ok, "Ei"}
               7 -> {:ok, "Zi"}
               8 -> {:ok, "Yi"}
               _ -> {:error, :too_large}
             end
    case prefix do
      {:ok, prefix} ->
        quantity = Float.round(bytes_per_second / :math.pow(1024, exponent), 2)
        unit = "#{prefix}B/s"
        "#{quantity} #{unit}"
      {:error, :too_large} ->
        "#{bytes_per_second} B/s"
    end
  end

end
