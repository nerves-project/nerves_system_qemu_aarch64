defmodule ResilienceTesting.DiskCorruptionTest do
  @moduledoc """
  Verifies disk-corruption resilience: scribble over the application data
  partition's superblock in the image, reboot, and confirm the device recovers
  (boots and the partition is writable again) rather than bricking. This mirrors
  the "corrupt filesystem detection" behaviour described in fwup.conf.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.{Faults, Guest, VM}

  @moduletag :qemu
  @moduletag timeout: 300_000

  test "the device recovers after the data partition is corrupted" do
    vm = VM.boot()
    on_exit(fn -> VM.destroy(vm) end)

    mount = Guest.app_mount(vm)
    assert Guest.writable?(vm, mount)
    Guest.write_file(vm, Path.join(mount, "rt_canary"), "before-corruption")

    # Corrupt the app data partition in the host image (the VM must be stopped).
    vm = VM.shutdown(vm)
    :ok = Faults.corrupt_partition(vm.disk, 2)

    # boot_again/1 raises if the guest never comes back, so reaching the next line
    # is itself the resilience assertion.
    vm = VM.boot_again(vm)
    on_exit(fn -> VM.destroy(vm) end)

    mount = Guest.app_mount(vm)

    assert Guest.writable?(vm, mount),
           "application data partition did not recover to a writable state"
  end
end
