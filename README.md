# Qemu ARM64/aarch64 system

[![Hex version](https://img.shields.io/hexpm/v/nerves_system_qemu_aarch64.svg "Hex version")](https://hex.pm/packages/nerves_system_qemu_aarch64)
[![CI](https://github.com/nerves-project/nerves_system_qemu_aarch64/actions/workflows/ci.yml/badge.svg)](https://github.com/nerves-project/nerves_system_qemu_aarch64/actions/workflows/ci.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-project/nerves_system_qemu_aarch64)](https://api.reuse.software/info/github.com/nerves-project/nerves_system_qemu_aarch64)

**Warning: This system is new and undocumented. Details to come.**

This is the Nerves base system for the [Qemu ARM system emulator](https://www.qemu.org/docs/master/system/target-arm.html). It is focused on ARM64 and intended to be used with [Little Loader](https://github.com/fhunleth/little_loader).

| Feature        | Description                                                 |
| -------------- | ----------------------------------------------------------- |
| CPU            | Cortex-A53 or host CPU (64-bit)                             |
| Storage        | virt                                                        |
| Linux kernel   | 6.18                                                        |
| Ethernet       | Yes                                                         |
| RTC            | Yes                                                         |
| HW Watchdog    | Software watchdog                                           |

## Prerequisites

- [fwup](https://github.com/fwup-home/fwup)

## Usage

When using this for your Nerves system the details of the qemu command-line args can vary a bit based on your environment. To help with this we provide a mix task to generate a command:

```
mix nerves.gen.qemu
```

If it can determine that you likely can support KVM acceleration or you are on Apple Silicon and can use HVF acceleration it will provide those. Otherwise it falls back to full emulation.

The guest Nerves device can be accessed via the console or by SSH via port 10022.
