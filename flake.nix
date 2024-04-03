{
  description = "zig-tracy development environment";

  inputs = {
    zig-source = {
      url = "https://ziglang.org/builds/zig-linux-x86_64-0.12.0-dev.3522+b88ae8dbd.tar.xz";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    zig-source
  }:
  let
    default_system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${default_system};
    zig_0_12_0_rc = pkgs.stdenv.mkDerivation rec {
      pname = "zig";
      version = "0.12.0-dev.3522+b88ae8dbd";
      src = zig-source.outPath;

      installPhase = ''
        mkdir -p "$out/bin"
        cp zig "$out/bin"
        cp -r lib "$out"
        cp -r doc "$out"
      '';

      meta = with pkgs.lib; {
        homepage = "https://ziglang.org/";
        description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
        license = licenses.mit;
        platforms = platforms.unix;
      };
    };
  in {
    devShell.${default_system} = pkgs.mkShell {
      nativeBuildInputs = [
        zig_0_12_0_rc
        pkgs.lldb_16
      ];
    };
  };
}

