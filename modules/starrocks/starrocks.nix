{ lib, ... }:
let
  starrocksCRD = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/StarRocks/starrocks-kubernetes-operator/main/deploy/starrocks.com_starrocksclusters.yaml";
    sha256 = "sha256:0w951fmby5jharfhgv542k9hhbnxavnapwrz80h146fk2k5x4jjc"; # Replace with actual hash
  };
in

{
  applications.starrocks = {
    namespace = "starrocks";
    createNamespace = true;

    yamls = [
      (builtins.readFile ../../sops/starrocks.sops.yaml)
      (builtins.readFile starrocksCRD)
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: starrocks
          namespace: starrocks
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: starrocks
      ''

    ];

    helm.releases.starrocks = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://starrocks.github.io/starrocks-kubernetes-operator";
        chart = "kube-starrocks";
        version = "1.11.2";
        chartHash = "sha256-u8Sz6LXInhpP7/0xLb8iaRPutb8F4OxibV/wsJAEdYw=";
      };
      includeCRDs = true;

      # Example values to pass to the Helm Chart.
      values = {
        starrocksFESpec = {
          replicas = 3;
          # service = {
          #   type = "ClusterIP";
          #   annotations = {
          #     "tailscale.com/expose" = "true";
          #   };
          # };
          resources = {
            requests = {
              cpu = 1;
              memory = "1Gi";
            };
          };
          storageSpec = {
            name = "fe";
          };
        };

        starrocksBeSpec = {
          replicas = 3;
          resources = {
            requests = {
              cpu = 1;
              memory = "2Gi";
            };
          };
          storageSpec = {
            name = "be";
            storageSize = "15Gi";
          };
        };

        # starrocksFeProxySpec = {
        #   enabled = true;
        #   service = {
        #     type = "LoadBalancer";
        #   };
        # };
      };
    };

  };
}
