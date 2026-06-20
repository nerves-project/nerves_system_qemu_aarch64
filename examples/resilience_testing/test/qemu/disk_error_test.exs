defmodule ResilienceTesting.DiskErrorTest do
  @moduledoc """
  Verifies the disk-error mechanism: a `blkdebug`-wrapped data disk injects EIO
  on every I/O (the config has both `read_aio` and `write_aio` rules), so reads
  and writes to `/dev/vdb` fail in the guest.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.VM

  @moduletag :qemu
  @moduletag timeout: 180_000

  setup_all do
    vm = VM.boot(data_disk: %{size: "64M", fault: :blkdebug})
    on_exit(fn -> VM.destroy(vm) end)
    %{vm: vm}
  end

  test "reads from a failing disk return I/O errors", %{vm: vm} do
    # Bypass any page cache so the read actually reaches the (failing) backend.
    VM.cmd(vm, "echo 3 > /proc/sys/vm/drop_caches")
    {output, status} = VM.cmd(vm, "dd if=/dev/vdb of=/dev/null bs=4k count=1 2>&1")

    assert status != 0,
           "expected a read from the failing disk to fail, got success.\nOutput: #{output}"

    # The rootfs (vda) must be unaffected — the guest is still responsive.
    assert {_, 0} = VM.cmd(vm, "true")
  end

  test "writes to a failing disk return I/O errors", %{vm: vm} do
    # An O_SYNC write surfaces the backend error synchronously (a buffered write
    # would only fail later on writeback). `:file.write_file/3` does it in one RPC.
    block = :binary.copy(<<0>>, 4096)
    result = VM.call(vm, :file, :write_file, ["/dev/vdb", block, [:sync]])

    assert match?({:error, _}, result),
           "expected a write to the failing disk to fail, got: #{inspect(result)}"

    # The rootfs (vda) must be unaffected — the guest is still responsive.
    assert {_, 0} = VM.cmd(vm, "true")
  end

  test "the kernel logs I/O errors for the failing disk", %{vm: vm} do
    # Trigger some I/O, then check the kernel ring buffer.
    VM.cmd(vm, "dd if=/dev/vdb of=/dev/null bs=4k count=1 2>/dev/null")
    {dmesg, _} = VM.cmd(vm, "dmesg | tail -n 50")

    assert dmesg =~ ~r/(I\/O error|Buffer I\/O|blk_update_request|critical (target|medium) error)/i,
           "expected an I/O error in dmesg, got:\n#{dmesg}"
  end
end
