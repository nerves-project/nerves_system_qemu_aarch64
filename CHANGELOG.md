# Changelog

## v0.3.1

This is a security/bug fix release.

* Changes
  * Enabled multipath TCP support in the Linux kernel

* Package updates
  * [nerves_system_br 1.33.2](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.33.2)
    * [Erlang/OTP 28.3.1](https://erlang.org/download/OTP-28.3.1.README.md)
    * [Buildroot 2025.11.1](https://lore.kernel.org/buildroot/f6496994-b279-46f4-b554-7dbe2df92782@rnout.be/T/)

## v0.3.0

This is a major Buildroot update. It should be a seamless update for most users.

* Fixes
  * Fix firmware path computation in `mix nerves.gen.qemu`
  * Support ssh via port 10022 in shown commandline

* Updated dependencies
  * [nerves_system_br 1.33.0](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.33.0)
    * [Buildroot 2025.11](https://lore.kernel.org/buildroot/87bjk439tj.fsf@dell.be.48ers.dk/T/)
    * [Erlang/OTP 28.3](https://erlang.org/download/OTP-28.3.README.md)
    * [fwup 1.15.0](https://github.com/fwup-home/fwup/releases/tag/v1.15.0)
    * [erlinit 1.15.1](https://github.com/nerves-project/erlinit/releases/tag/v1.15.1)
    * [nerves_heart 2.5.0](https://github.com/nerves-project/nerves_heart/releases/tag/v2.5.0)
    * [boardid 1.15.0](https://github.com/nerves-project/boardid/releases/tag/v1.15.0)

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
