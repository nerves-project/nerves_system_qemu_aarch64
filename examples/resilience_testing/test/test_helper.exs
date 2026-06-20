# The `:qemu` tests boot a real QEMU VM and inject faults from the outside. They
# are slow and require a built firmware (see bin/build), so they are excluded by
# default. Run them with `bin/qemu-test` or `mix test --only qemu`.
ExUnit.start(exclude: [:qemu])
