defmodule ResilienceTesting.MixProject do
  use Mix.Project

  @app :resilience_testing
  @version "0.1.0"
  # This example targets only this repo's QEMU system. It is wired by path to the
  # system source one directory up so changes to the system (kernel options,
  # qemu launcher, etc.) flow straight into the firmware build.
  @all_targets [:qemu_aarch64]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.19",
      archives: [nerves_bootstrap: "~> 1.15"],
      elixirc_paths: elixirc_paths(Mix.env()),
      listeners: listeners(Mix.target(), Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {ResilienceTesting.Application, []}
    ]
  end

  def cli do
    # Tests run on the host (they orchestrate QEMU from the outside).
    [preferred_targets: [test: :host]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Build tooling (needed on the host to run mix nerves tasks).
      {:nerves, "~> 1.13", runtime: false},

      # Firmware dependencies. Scoped to the target so the host (which only runs
      # the test harness, not the firmware) stays minimal.
      {:shoehorn, "~> 0.9.1", targets: @all_targets},
      {:ring_logger, "~> 0.11.0", targets: @all_targets},
      {:toolshed, "~> 0.4.0", targets: @all_targets},
      {:nerves_runtime, "~> 0.13.12", targets: @all_targets},
      {:nerves_pack, "~> 0.7.1", targets: @all_targets},

      # This repo's system, by path. `nerves: [compile: true]` builds it from
      # source (via Docker on macOS) rather than fetching a prebuilt artifact.
      {:nerves_system_qemu_aarch64,
       path: "../..", runtime: false, targets: :qemu_aarch64, nerves: [compile: true]},

      # The :peer RPC control channel over the serial console. Pinned because it
      # is experimental and moving.
      {:peer_bridge, github: "fhunleth/peer_bridge", ref: "84cedb60ca74a965081c4c13a0499c7e0c6e5979"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, &install_peer_bridge/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  # Symlink the versioned peer_bridge binary to a fixed path so erlinit's
  # alternate_exec (see config/target.exs) can launch it. Adapted from the
  # peer_bridge README.
  defp install_peer_bridge(release) do
    peer_bridge_app = release.applications[:peer_bridge]

    bin_dir = Path.join(release.path, "bin")
    File.mkdir_p!(bin_dir)

    target = Path.join(bin_dir, "peer_bridge")
    source = Path.join(["..", "lib", "peer_bridge-#{peer_bridge_app[:vsn]}", "priv", "peer_bridge"])

    _ = File.rm(target)
    File.ln_s!(source, target)

    release
  end

  # Uncomment the following line if using Phoenix > 1.8.
  # defp listeners(:host, :dev), do: [Phoenix.CodeReloader]
  defp listeners(_, _), do: []
end
