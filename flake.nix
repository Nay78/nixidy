{
  description = "My ArgoCD configuration with nixidy.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # inputs.nixidy.url = "github:arnarg/nixidy";
  inputs.nixidy = {
    url = "github:arnarg/nixidy";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixidy,
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        # This declares the available nixidy envs.
        nixidyEnvs = nixidy.lib.mkEnvs {
          inherit pkgs;

          envs = {
            # Currently we only have the one dev env.
            dev.modules = [ ./env/dev.nix ];
          };
        };

        # Handy to have nixidy cli available in the local
        # flake too.
        packages = {
          nixidy = nixidy.packages.${system}.default;
          generators.cilium = nixidy.packages.${system}.generators.fromCRD {
            name = "cilium";
            src = pkgs.fetchFromGitHub {
              owner = "cilium";
              repo = "cilium";
              rev = "v1.15.6";
              hash = "sha256-oC6pjtiS8HvqzzRQsE+2bm6JP7Y3cbupXxCKSvP6/kU=";
            };
            crds = [
              "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumnetworkpolicies.yaml"
              "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumclusterwidenetworkpolicies.yaml"
            ];
          };
        };

        # Useful development shell with nixidy in path.
        # Run `nix develop` to enter.
        devShells.default = pkgs.mkShell {
          buildInputs = [ nixidy.packages.${system}.default ];
        };
      }
    ));
}
