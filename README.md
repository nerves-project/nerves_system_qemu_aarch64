# Qemu ARM64/aarch64 system

**Warning: This system is new and undocumented. Details to come.**

This is the Nerves base system for the [Qemu ARM system emulator](https://www.qemu.org/docs/master/system/target-arm.html). It is focused on ARM64 and intended to be used with [Little Loader](https://github.com/fhunleth/little_loader).

| Feature        | Description                                                 |
| -------------- | ----------------------------------------------------------- |
| CPU            | Cortex-A53 or host CPU (64-bit)                             |
| Storage        | virt                                                        |
| Linux kernel   | 6.12                                                        |
| Ethernet       | Yes                                                         |
| RTC            | Yes                                                         |
| HW Watchdog    | No?                                                         |

## Prerequisites

- [fwup](https://github.com/fwup-home/fwup)

## Usage

When using this for your Nerves system the details of the qemu command-line args can vary a bit based on your environment. To help with this we provide a mix task to generate a command:

```
mix nerves.gen.qemu
```

If it can determine that you likely can support KVM acceleration or you are on Apple Silicon and can use HVF acceleration it will provide those. Otherwise it falls back to full emulation.


