{ lib, ... }:
{
  applications.tailscale = {
    namespace = "tailscale";
    createNamespace = true;
    yamls = [ (builtins.readFile ../sops/tailscale.sops.yaml) ];

    helm.releases.tailscale = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://pkgs.tailscale.com/helmcharts";
        chart = "tailscale-operator";
        version = "1.90.8";
        chartHash = "sha256-orJdAcLRUKrxBKbG3JZr7L390+A1tCgAchDzdUlyT+o=";
      };

      values = {
        # service = {
        #   type = "NodePort";
        #   port = 8888;
        #   targetPort = 8888;
        #   nodePort = {
        #     http = 8888;
        #   };
        # };
      };

    };

  };
}
