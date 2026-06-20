# ResilienceTesting

An example Nerves firmware and test harness for **resilience / chaos testing**
under QEMU. It boots a real firmware image in `qemu-system-aarch64`, injects
faults from the outside — disk latency, disk I/O errors, disk corruption, sudden
power loss, network latency — and asserts the device reacted as expected.

It is wired by path to the `nerves_system_qemu_aarch64` system one directory up
(`../..`) and builds it from source, so it doubles as the place to exercise new
fault-injection capabilities as they are added to the system.

The guest is driven over an Erlang `:peer` RPC channel carried on the serial
console by [`peer_bridge`](https://github.com/fhunleth/peer_bridge): a test calls
`VM.call(vm, Mod, Fun, Args)` to run code in the guest and gets real terms back,
with no dependency on guest networking. Because the serial is the RPC link, this
firmware boots as a peer node and has **no interactive IEx prompt** on the
console.

## Requirements

- `qemu-system-aarch64` and `fwup` on the host (`brew install qemu fwup` on macOS).
- The usual Nerves toolchain. On macOS the system build runs in the Nerves Docker
  container automatically; on Linux it builds natively.

## Operating it

Build the firmware (the first run is slow — it compiles the system from source):

```sh
export MIX_TARGET=qemu_aarch64
mix deps.get
mix firmware
```

Run the fault-injection suite (on the host; it boots QEMU and drives the guest).
The harness finds the built `.fw` and the system's `little_loader.elf`
automatically:

```sh
mix test --only qemu                              # the whole suite
mix test --only qemu test/qemu/disk_latency_test.exs   # a single scenario
```

Plain `mix test` runs nothing — the QEMU suite is excluded by default.

To poke at a VM by hand, start IEx with the harness loaded:

```sh
MIX_ENV=test iex -S mix
```

```elixir
alias ResilienceTesting.{VM, Faults}
vm = VM.boot()
VM.call(vm, ResilienceTesting, :hello, [])   # => :world  (RPC into the guest)
Faults.disk_throttle(vm, bps_rd: 1_048_576)  # inject a fault via QMP
VM.power_off(vm); vm = VM.boot_again(vm)      # pull the plug, reboot
VM.destroy(vm)
```

## What's tested

| Scenario | Fault injected from outside | Assertion |
|---|---|---|
| `peer_rpc_test` | — (exercises the control channel) | RPC returns real terms; the app's own code runs in the guest |
| `disk_latency_test` | QMP `block_set_io_throttle` on `/dev/vdb` | reads get much slower, then recover |
| `disk_error_test` | `blkdebug` injects EIO on `/dev/vdb` | guest reads and writes fail; kernel logs I/O errors; rootfs unaffected |
| `disk_corruption_test` | scribble the app-data partition in the image | device reboots and the partition is writable again |
| `power_loss_test` | SIGKILL QEMU mid-life | device reboots; fsynced data survived |
| `network_latency_test` | QMP `filter-buffer` on `eth0` | round-trip latency increases, then recovers |

## How it works

The harness lives in `test/support/`:

- `VM` — boots QEMU from the `.fw` (via `fwup`), launches it through `:peer.start`
  so the guest is reachable by RPC, and exposes `call/4`, `cmd/3`, `qmp/3`,
  `power_off/1`, `shutdown/1` and `boot_again/1`. An optional secondary data disk
  (`/dev/vdb`) is the target for disk faults so they don't disturb the rootfs.
- `QMP` — a small QEMU Machine Protocol client for live device/network control.
- `Faults` — high-level fault API (disk throttle, network latency, image
  corruption) built on QMP and host-side image manipulation.
- `Guest` — helpers that inspect/manipulate the guest over RPC.

All faults here are injected from outside the VM (hypervisor, image, or process),
so they work regardless of the guest kernel. To add a scenario, drop a
`@moduletag :qemu` test in `test/qemu/`, `VM.boot/1` a VM (attach a `data_disk:`
to target storage), inject the fault, then assert via `VM.call/4` / `VM.cmd/3`.

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
