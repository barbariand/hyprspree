{
  description = "Hyprkool: Fixed glaze dependency and pkg-config paths";

  inputs = {
    hyprland.url = "github:hyprwm/Hyprland/v0.52.1";
    nixpkgs.follows = "hyprland/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    hyprland,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      stdenv = pkgs.gcc13Stdenv;
      hyprlandPkg = hyprland.packages.${system}.hyprland;

      pname = "hyprkool";
      allDeps = with pkgs;
        [
          libdrm
          tomlplusplus
          pixman
          hyprutils
          wayland-protocols
          hyprgraphics.dev
          wayland-utils
          wayland
          libinput
          libxkbcommon
          libGL
          hyprlang
          hyprland-protocols
          cairo
          aquamarine
        ]
        ++ (with pkgs.xorg; [
          libXcursor
          libxcb
          libXdmcp
        ])
        ++ [hyprlandPkg];
    in {
      packages.default = stdenv.mkDerivation rec {
        pname = "hyprkool";
        version = "0.9.2";
        src = pkgs.lib.cleanSource ./.;

        nativeBuildInputs = with pkgs; [
          pkg-config
          cmake
        ];

        buildInputs = allDeps;

        dontUseMesonConfigure = true;
        dontUseCmakeConfigure = true;

        buildPhase = ''
          export CARGO_HOME=$TMPDIR/cargo
          cargo build --release

          # Ensure the plugin build has the hash
          make plugin GIT_COMMIT_HASH="\"${hyprland.rev}\""

          # Move the compiled library so installPhase can find it
          mv ./plugin/build/lib${pname}.so .
        '';

        installPhase = ''
          mkdir -p $out/lib
          mkdir -p $out/bin
          mv ./lib${pname}.so $out/lib/lib${pname}.so
          mv ./target/release/${pname} $out/bin/${pname}
        '';
      };

      devShells.default = pkgs.mkShell.override {inherit stdenv;} {
        name = "hyprkool-dev";

        nativeBuildInputs = with pkgs; [
          pkg-config
          cmake
          ninja
          meson
          just
        ];

        buildInputs = allDeps;

        shellHook = ''
          export PROJECT_ROOT="$(pwd)"
          cargo build --release
            make plugin GIT_COMMIT_HASH="\"${hyprland.rev}\""
            echo "${hyprland.rev}"
        '';
      };
    });
}
