defmodule ResilienceTesting.PeerRpcTest do
  @moduledoc """
  Verifies the control channel itself: Erlang `:peer` RPC into the guest over the
  serial link (peer_bridge), returning real terms — no text scraping, no guest
  networking involved.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.VM

  @moduletag :qemu
  @moduletag timeout: 180_000

  setup_all do
    vm = VM.boot()
    on_exit(fn -> VM.destroy(vm) end)
    %{vm: vm}
  end

  test "RPC evaluates in the guest and returns terms", %{vm: vm} do
    assert VM.call(vm, :erlang, :+, [40, 2]) == 42
    assert VM.call(vm, :os, :type, []) == {:unix, :linux}
    assert VM.call(vm, :erlang, :system_info, [:system_architecture]) |> to_string() =~ "aarch64"
  end

  test "RPC can call the firmware's own application code", %{vm: vm} do
    assert VM.call(vm, ResilienceTesting, :hello, []) == :world
  end

  test "the OTP applications are running in the guest", %{vm: vm} do
    started = VM.call(vm, Application, :started_applications, [])
    names = for {app, _desc, _vsn} <- started, do: app

    assert :resilience_testing in names
    assert :nerves_runtime in names
  end

  test "shell commands run in the guest with real exit status", %{vm: vm} do
    assert {output, 0} = VM.cmd(vm, "echo hello")
    assert String.trim(output) == "hello"

    assert {_, status} = VM.cmd(vm, "exit 3")
    assert status == 3
  end
end
