defmodule Mix.Tasks.Nerves.Gen.Qemu do
  @moduledoc "Generate qemu command line for the current environment"
  @shortdoc "Generate qemu command line"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    fw_path = case args do
      [fw_path] -> fw_path
      _ ->
        Mix.shell().error("Command requires the firmware path as an input argument.")
        System.halt(1)
    end

    disk_path = "virtual-disk.img"
    File.rm(disk_path)

    Mix.shell().info("Creating disk image '#{disk_path}' from '#{fw_path}'...")
    {_, 0} = System.cmd("fwup", ["-a", "-i", fw_path, "-d", disk_path, "-t", "complete"], into: IO.stream())

    {machine, cpu} = get_machine_and_cpu()
    bootloader = Path.join(System.fetch_env!("NERVES_SDK_SYSROOT"), "little.elf")
    cmd = template_command(machine, cpu, bootloader, disk_path)
    Mix.shell().info("Command:\n#{cmd}")
  end

  defp template_command(machine, cpu, bootloader, disk) do
    """
    qemu-system-aarch64 \
      -machine #{machine} \
      -cpu #{cpu} \
      -smp 1 \
      -m 256M \
      -kernel #{bootloader} \
      -netdev user,id=eth0 \
      -device virtio-net-device,netdev=eth0,mac=fe:db:ed:de:d0:01 \
      -global virtio-mmio.force-legacy=false \
      -drive if=none,file=#{disk},format=raw,id=vdisk \
      -device virtio-blk-device,drive=vdisk,bus=virtio-mmio-bus.0 \
      -nographic
    """
  end

  defp get_machine_and_cpu() do
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
      "aarch64-" <> _ -> :aarch64
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
