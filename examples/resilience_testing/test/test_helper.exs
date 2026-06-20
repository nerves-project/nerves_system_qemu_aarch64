# The `:qemu` tests boot a real QEMU VM and inject faults from the outside. They
# are slow and require a built firmware (MIX_TARGET=qemu_aarch64 mix firmware), so
# they are excluded by default. Run them with `mix test --only qemu`.
unless System.find_executable("qemu-system-aarch64") do
  IO.puts(:stderr, "warning: qemu-system-aarch64 not found on PATH; the :qemu tests need it.")
end

ExUnit.start(exclude: [:qemu])
