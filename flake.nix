{
  description = "zig-tracy development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    zig-overlay
  }:
  let
    # https://github.com/mitchellh/zig-overlay/blob/a13f8e3f83ce51411d079579f28acb20472443f8/flake.nix#L21
    systems = builtins.attrNames zig-overlay.packages;
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        zigpkgs = zig-overlay.packages.${system};
      in rec {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            zigpkgs."0.15.2"

            lldb
          ];
        };
      }
    );
}
