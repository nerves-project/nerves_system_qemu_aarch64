# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0

defmodule Mix.Tasks.Nerves.Gen.Qemu do
  @moduledoc """
  Generate a qemu command line for the current environment.

  By default this prints a command equivalent to a plain `-nographic` boot. The
  options below expose the "outside" control surfaces used for resilience /
  fault-injection testing — they let a harness drive the virtual devices and
  network while the guest runs, without any in-guest agent:

    * `--qmp PORT`        Expose the QEMU Machine Protocol on a TCP port. QMP is
                          the control plane for live fault injection, e.g.
                          `block_set_io_throttle` (disk latency/bandwidth),
                          `object-add` of a `filter-buffer` (network latency),
                          `quit`/`system_reset` (power loss), `balloon`
                          (memory pressure), `device_del` (hot-unplug).
    * `--serial PORT`     Put the serial console on a TCP port instead of stdio,
                          so a harness can read boot logs and drive the IEx
                          prompt over a socket. Implies `-display none`.
    * `--data-disk SPEC`  Attach a secondary virtio-blk disk as a fault target so
                          disk faults don't take down the rootfs. SPEC is
                          `PATH[:SIZE]` (SIZE defaults to 256M, e.g.
                          `scratch.img:512M`). The image is created if missing.
    * `--ram SIZE`        Guest RAM (default 256M). Shrink to probe memory limits.
    * `--smp N`           Number of CPUs (default 1).
    * `--accel KIND`      Force acceleration: `auto` (default), `hvf`, `kvm` or
                          `tcg` (full emulation).

  The primary and secondary drives use stable backend ids (`vdisk`, `vdata`) so
  they can be addressed by QMP `block_set_io_throttle` at runtime. A
  `virtio-balloon` device is always included so guest memory can be reclaimed
  live via QMP `balloon`.
  """
  @shortdoc "Generate qemu command line"

  use Mix.Task

  @switches [
    qmp: :integer,
    serial: :integer,
    data_disk: :string,
    ram: :string,
    smp: :integer,
    accel: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, rest} = OptionParser.parse!(args, strict: @switches)

    fw_path =
      case rest do
        [fw_path] ->
          fw_path

        [] ->
          Nerves.Env.firmware_path()

        _ ->
          Mix.shell().error(
            "Multiple arguments provided. Task only accepts no arguments or the single firmware path as an argument."
          )

          System.halt(1)
      end

    disk_path = "virtual-disk.img"
    File.rm(disk_path)

    Mix.shell().info("Creating disk image '#{disk_path}' from '#{fw_path}'...")

    {_, 0} =
      System.cmd("fwup", ["-a", "-i", fw_path, "-d", disk_path, "-t", "complete"],
        into: IO.stream()
      )

    data_disk = maybe_create_data_disk(opts[:data_disk])

    {machine, cpu} = machine_and_cpu(opts[:accel])
    bootloader = Path.join(System.fetch_env!("NERVES_SDK_IMAGES"), "little_loader.elf")

    cmd =
      template_command(machine, cpu, bootloader, disk_path,
        ram: opts[:ram] || "256M",
        smp: opts[:smp] || 1,
        qmp: opts[:qmp],
        serial: opts[:serial],
        data_disk: data_disk
      )

    Mix.shell().info("Command:\n#{cmd}")
  end

  # Build the command as a list of args so the optional pieces compose cleanly.
  defp template_command(machine, cpu, bootloader, disk, opts) do
    base = [
      "qemu-system-aarch64",
      "-machine #{machine}",
      "-cpu #{cpu}",
      "-smp #{opts[:smp]}",
      "-m #{opts[:ram]}",
      "-kernel #{bootloader}",
      "-netdev user,id=eth0,hostfwd=tcp:127.0.0.1:10022-:22",
      "-device virtio-net-device,netdev=eth0,mac=fe:db:ed:de:d0:01",
      "-global virtio-mmio.force-legacy=false",
      # Stable backend id so QMP block_set_io_throttle can address it at runtime.
      "-drive if=none,file=#{disk},format=raw,id=vdisk",
      "-device virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0",
      # Always present so guest RAM can be reclaimed live via QMP `balloon`.
      "-device virtio-balloon-device"
    ]

    base
    |> maybe_add_data_disk(opts[:data_disk])
    |> maybe_add_qmp(opts[:qmp])
    |> maybe_add_serial(opts[:serial])
    |> Enum.join(" \\\n  ")
  end

  defp maybe_add_data_disk(args, nil), do: args

  defp maybe_add_data_disk(args, path) do
    args ++
      [
        "-drive if=none,file=#{path},format=raw,id=vdata",
        "-device virtio-blk-device,drive=vdata"
      ]
  end

  defp maybe_add_qmp(args, nil), do: args

  defp maybe_add_qmp(args, port) do
    args ++ ["-qmp tcp:127.0.0.1:#{port},server,nowait"]
  end

  # No --serial: keep the historical stdio console via -nographic.
  defp maybe_add_serial(args, nil), do: args ++ ["-nographic"]

  defp maybe_add_serial(args, port) do
    args ++ ["-display none", "-serial tcp:127.0.0.1:#{port},server,nowait"]
  end

  defp maybe_create_data_disk(nil), do: nil

  defp maybe_create_data_disk(spec) do
    {path, size} =
      case String.split(spec, ":", parts: 2) do
        [path] -> {path, "256M"}
        [path, size] -> {path, size}
      end

    Mix.shell().info("Creating data disk '#{path}' (#{size})...")
    {_, 0} = System.cmd("qemu-img", ["create", "-f", "raw", path, size], into: IO.stream())
    path
  end

  @doc """
  Determine the `{machine, cpu}` pair for the host, honouring an optional
  acceleration override (`"auto"`, `"hvf"`, `"kvm"`, `"tcg"`).
  """
  def machine_and_cpu(accel \\ nil)

  def machine_and_cpu("hvf"), do: {"virt,accel=hvf", "host"}
  def machine_and_cpu("kvm"), do: {"virt,accel=kvm", "host"}
  def machine_and_cpu("tcg"), do: {"virt", "cortex-a53"}

  def machine_and_cpu(accel) when accel in [nil, "auto"] do
    {a, o} = type = {arch(), os()}
    Mix.shell().info("Generating command line for arch '#{a}' on host OS '#{o}'.")

    case type do
      {:aarch64, :linux} ->
        if System.find_executable("kvm") != nil do
          Mix.shell().info("Detected KVM support.")
          {"virt,accel=kvm", "host"}
        else
          {"virt", "cortex-a53"}
        end

      {:aarch64, :macos} ->
        Mix.shell().info("Apple Silicon on MacOS, using HVF.")
        {"virt,accel=hvf", "host"}

      _ ->
        {"virt", "cortex-a53"}
    end
  end

  defp arch() do
    case to_string(:erlang.system_info(:system_architecture)) do
      "aarch64-" <> _ ->
        :aarch64

      a ->
        Mix.shell().info("Got arch #{a}, using 'other'.")
        :other
    end
  end

  defp os() do
    case :os.type() do
      {:unix, :linux} ->
        :linux

      {:unix, :darwin} ->
        :macos

      _ ->
        :other
    end
  end
end
