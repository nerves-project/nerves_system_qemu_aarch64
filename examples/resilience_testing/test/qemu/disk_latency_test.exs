defmodule ResilienceTesting.DiskLatencyTest do
  @moduledoc """
  Verifies the disk-latency mechanism: QMP `block_set_io_throttle` on the
  secondary data disk should make reads measurably slower.
  """
  use ExUnit.Case, async: false

  alias ResilienceTesting.{Faults, VM}

  @moduletag :qemu
  # Throttled reads take ~8s; give the whole file room.
  @moduletag timeout: 300_000

  setup_all do
    vm = VM.boot(data_disk: %{size: "128M"})
    on_exit(fn -> VM.destroy(vm) end)
    %{vm: vm}
  end

  test "throttling the data disk slows reads", %{vm: vm} do
    baseline = timed_read(vm)

    # Limit reads on the data disk to 2 MB/s.
    Faults.disk_throttle(vm, device: "vdata", bps_rd: 2_097_152)
    throttled = timed_read(vm)
    Faults.disk_unthrottle(vm, "vdata")

    recovered = timed_read(vm)

    # 32 MiB at 2 MB/s is ~16s; the unthrottled reads are well under a second.
    assert throttled > baseline * 4,
           "expected throttled read (#{throttled}ms) to be much slower than baseline (#{baseline}ms)"

    assert throttled > 5_000,
           "expected throttled read to take several seconds, got #{throttled}ms"

    assert recovered < throttled / 2,
           "expected reads to speed up after unthrottling (#{recovered}ms vs #{throttled}ms)"
  end

  # Drop caches then time a raw read straight from the block device so the
  # throttle (which lives in QEMU's block backend) is actually exercised.
  defp timed_read(vm) do
    {us, {_out, 0}} =
      :timer.tc(fn ->
        VM.cmd(
          vm,
          "echo 3 > /proc/sys/vm/drop_caches; dd if=/dev/vdb of=/dev/null bs=1M count=32 2>/dev/null",
          120_000
        )
      end)

    div(us, 1000)
  end
end
