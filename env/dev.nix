{
  pkgs,
  self,
  system,
  ...
}:
{
  nixidy.target.repository = "https://github.com/Nay78/nixidy";

  nixidy.chartsDir = ../charts;
  # Set the target branch the rendered manifests for _this_
  # environment should be pushed to in the repository defined
  # above.
  nixidy.target.branch = "main";

  # Set the target sub-directory to copy the generated
  # manifests to when running `nixidy switch .#dev`.
  nixidy.target.rootPath = "./manifests/dev";

  # generate = {
  #   type = "app";
  #   program =
  #     (pkgs.writeShellScript "generate-modules" ''
  #       set -eo pipefail
  #
  #       # echo "generate onepassword"
  #       # cat ${self.packages.${system}.generators.onepassword} > modules/1password-connect/generated.nix
  #
  #       echo "generate cilium"
  #       cat ${self.packages.${system}.generators.cilium} > ./generated/cilium.nix
  #
  #       # echo "generate tailscale"
  #       # cat ${self.packages.${system}.generators.tailscale} > modules/tailscale-operator/generated.nix
  #       #
  #       # echo "generate traefik"
  #       # cat ${self.packages.${system}.generators.traefik} > modules/traefik/generated.nix
  #     '').outPath;
  # };

  imports = [
    # ../modules/stackgres/default.nix
    # ../modules/cloudnativepg/default.nix
    ../modules/starrocks/default.nix

    # ../modules/flink/default.nix
    # ../modules/cert-manager/default.nix
    # ../modules/starrocks/default.nix

    ./superset.nix
    # ./metallb.nix
    # ./metallb-bitnami.nix
    # ./n8n.nix
    # ./n8n2.nix
    # ./sealed-secrets.nix
    ./sops-secrets-operator.nix
    # ./temporal.nix
    # ./druid.nix
    # ./airflow.nix
    ./tailscale.nix
    # ./stackgres/stackgres.nix
    # ./db/cloud-native-pg.nix

  ];
}
