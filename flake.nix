{
  description = "Hyprkool: Fixed glaze dependency and pkg-config paths";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      stdenv = pkgs.gcc13Stdenv;

      pname = "hyprkool";
      allDeps = with pkgs;
        [
          libdrm
          tomlplusplus
          pixman
          hyprland
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
        ]);
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
          cargo build --release
          make plugin
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
          make plugin
        '';
      };
    });
}
