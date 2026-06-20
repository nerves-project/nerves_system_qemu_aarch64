defmodule ResilienceTesting.PowerLossTest do
  @moduledoc """
  Verifies power-loss resilience: hard-kill QEMU (modelling a yanked power cord)
  and confirm the device boots again and data that was fsynced before the cut
  survived. Reaching the guest on the second boot is itself proof the writable
  filesystem recovered.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.{Guest, VM}

  @moduletag :qemu
  @moduletag timeout: 300_000

  test "fsynced data survives sudden power loss" do
    vm = VM.boot()
    on_exit(fn -> VM.destroy(vm) end)

    mount = Guest.app_mount(vm)
    canary = Path.join(mount, "rt_canary")
    Guest.write_file(vm, canary, "survive-the-power-loss")

    # Sanity: it's there before we pull the plug.
    assert Guest.read_file(vm, canary) == "survive-the-power-loss"

    # Pull the plug: SIGKILL loses QEMU's volatile caches, like power loss.
    vm = VM.power_off(vm)
    vm = VM.boot_again(vm)
    on_exit(fn -> VM.destroy(vm) end)

    mount = Guest.app_mount(vm)

    assert Guest.read_file(vm, Path.join(mount, "rt_canary")) == "survive-the-power-loss",
           "fsynced data did not survive the power loss"
  end
end
