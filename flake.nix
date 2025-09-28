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
          # inherit self;

          envs = {
            # Currently we only have the one dev env.
            dev.modules = [ ./env/dev.nix ];
          };
        };

        # Handy to have nixidy cli available in the local
        # flake too.
        packages = {
          nixidy = nixidy.packages.${system}.default;
          generators = {

            # NOTE: CILLIUM EXAMPLE
            cilium = nixidy.packages.${system}.generators.fromCRD {
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
            tailscale = nixidy.packages.${system}.generators.fromCRD {
              name = "tailscale";
              src = pkgs.fetchFromGitHub {
                owner = "tailscale";
                repo = "tailscale";
                rev = "v1.88.2";
                hash = "sha256-pVigC0C6skzO65sx+QO7Rz/p7Q1FTO0Bw4TIwFPG1yY=";
              };
              crds = [ "cmd/k8s-operator/deploy/crds/tailscale.com_proxyclasses.yaml" ];
            };
            stackgres = nixidy.packages.${system}.generators.fromCRD {
              name = "stackgres";
              src = pkgs.fetchFromGitHub {
                owner = "ongres";
                repo = "stackgres";
                rev = "1.17.2";
                hash = "sha256-87zTaHXpNMp7zMHEGrEIq41XpIAK0uu25SX4f2jOswM=";
              };
              crds = [
                "stackgres-k8s/src/common/src/main/resources/crds/SGConfig.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGInstanceProfile.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGPostgresConfig.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGBackup.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGDistributedLogs.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGDbOps.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGObjectStorage.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGScript.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGShardedBackup.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGShardedDbOps.yaml"
                "stackgres-k8s/src/common/src/main/resources/crds/SGStream.yaml"

                # "stackgres-k8s/src/common/src/main/resources/crds/SGCluster.yaml"
                # "stackgres-k8s/src/common/src/main/resources/crds/SGPoolingConfig.yaml"
                # "stackgres-k8s/src/common/src/main/resources/crds/SGShardedCluster.yaml"
              ];
            };

          };

          # generate = {
          #   type = "app";
          #   program =
          #     (pkgs.writeShellScript "generate-modules" ''
          #       set -eo pipefail
          #
          #       # echo "generate onepassword"
          #       # cat ${self.packages.${system}.generators.onepassword} > modules/1password-connect/generated.nix
          #       # echo "generate cilium"
          #       # cat ${self.packages.${system}.generators.cilium} > modules/cilium/generated.nix
          #
          #       echo "generate stackgres"
          #       cat ${self.packages.${system}.generators.stackgres} > env/stackgres/generated.nix
          #
          #       # echo "generate traefik"
          #       # cat ${self.packages.${system}.generators.traefik} > modules/traefik/generated.nix
          #     '').outPath;
          # };

        };

        # Useful development shell with nixidy in path.
        # Run `nix develop` to enter.
        devShells.default = pkgs.mkShell {
          buildInputs = [ nixidy.packages.${system}.default ];
        };
      }
    ));
}
