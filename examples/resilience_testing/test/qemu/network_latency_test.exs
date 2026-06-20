defmodule ResilienceTesting.NetworkLatencyTest do
  @moduledoc """
  Verifies the network-latency mechanism: a QMP `filter-buffer` on the `eth0`
  netdev should add measurable latency. We measure the time to receive the SSH
  banner from the guest's forwarded SSH port before and after applying it.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.{Faults, VM}

  @moduletag :qemu
  @moduletag timeout: 240_000

  setup_all do
    vm = VM.boot()
    on_exit(fn -> VM.destroy(vm) end)
    # nerves_ssh may come up a moment after the guest becomes reachable.
    wait_for_ssh(vm.ssh_port)
    %{vm: vm}
  end

  test "filter-buffer adds network latency", %{vm: vm} do
    baseline = best_banner_ms(vm.ssh_port, 5)

    Faults.net_latency(vm, 300)
    delayed = best_banner_ms(vm.ssh_port, 5)
    Faults.net_clear(vm)

    recovered = best_banner_ms(vm.ssh_port, 5)

    assert delayed > baseline + 100,
           "expected latency to increase by >100ms (baseline #{baseline}ms, delayed #{delayed}ms)"

    assert recovered < delayed - 50,
           "expected latency to drop after clearing the filter (#{recovered}ms vs #{delayed}ms)"
  end

  # Best (minimum) of several samples to suppress scheduling noise.
  defp best_banner_ms(port, samples) do
    1..samples
    |> Enum.map(fn _ -> banner_ms(port) end)
    |> Enum.min()
  end

  defp banner_ms(port) do
    {us, :ok} =
      :timer.tc(fn ->
        {:ok, socket} =
          :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 10_000)

        {:ok, _banner} = :gen_tcp.recv(socket, 0, 10_000)
        :gen_tcp.close(socket)
        :ok
      end)

    div(us, 1000)
  end

  defp wait_for_ssh(port, timeout \\ 60_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_for_ssh(port, deadline)
  end

  defp do_wait_for_ssh(port, deadline) do
    result =
      case :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 2_000) do
        {:ok, socket} ->
          banner = :gen_tcp.recv(socket, 0, 2_000)
          :gen_tcp.close(socket)
          banner

        error ->
          error
      end

    case result do
      {:ok, _banner} ->
        :ok

      _ ->
        if System.monotonic_time(:millisecond) >= deadline do
          raise "guest SSH (port #{port}) never became reachable"
        else
          Process.sleep(500)
          do_wait_for_ssh(port, deadline)
        end
    end
  end
end
