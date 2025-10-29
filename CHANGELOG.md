# Changelog

## v0.2.0

This is a major Erlang and Buildroot update. This updates from Erlang/OTP 27 to
Erlang/OTP 28.

* Changes
  * Do not require firmware path for nerves.gen.qemu
  * Switch fwup upgrade validation to use upgrade_available
  * Remove unneeded call to `rngd` and the `rng-tools` package. This was
    formerly needed to provide entropy to Linux during initialization.

* Package updates
  * [nerves_system_br v1.32.3 release notes](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.32.3)

* Updated dependencies
  * [Erlang/OTP 28.1.1](https://erlang.org/download/OTP-28.1.1.README.md)
  * [Buildroot 2025.05.2](https://lore.kernel.org/buildroot/7bed9b2e-a9d3-476b-84d6-61134e2f726f@rnout.be/T/)

## v0.1.1

This is an important security/bug fix that addresses Erlang CVEs for the ssh
module (see Erlang release notes).

* Changes
  * Build `libnl` to avoid compile error with `vintage_net_wifi`. Note that it's
    not possible to use WiFi, but `mix nerves.new` includes it by default for everyone.

* Package updates
  * [nerves_system_br v1.31.7](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.31.7). Also
    see [nerves_system_br v1.31.6](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.31.6)

* Important derived package updates
  * [Erlang/OTP 27.3.4.3](https://erlang.org/download/OTP-27.3.4.3.README.md)
  * [Buildroot 2025.02.6](https://lore.kernel.org/buildroot/b051d400-debc-4269-975a-b2992eed8d61@rnout.be/T/)

## v0.1.0

Initial release
