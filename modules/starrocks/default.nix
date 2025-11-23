{ lib, ... }:
let
  starrocksCRD = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/StarRocks/starrocks-kubernetes-operator/main/deploy/starrocks.com_starrocksclusters.yaml";
    sha256 = "sha256:0p34cprcyr8wgsh2n0glwkzrg1v7g39hbjxbglgqw8cjj9mnykbv"; # Replace with actual hash
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
          name: tailscale
          namespace: starrocks
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: starrocks
          ports:
            - protocol: TCP
              port: 80
              targetPort: 9030

      ''

    ];

    helm.releases.starrocks = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://starrocks.github.io/starrocks-kubernetes-operator";
        chart = "kube-starrocks";
        version = "1.11.3";
        chartHash = "sha256-Nf2NCwv2v2d7BVR7gQFzlaMxPptgiKTekFrRd02epRo=";
      };
      includeCRDs = true;

      # Example values to pass to the Helm Chart.
      values = {
        starrocksFESpec = {
          replicas = 3;
          service = {
            type = "NodePort";
            port = 80;
            targetPort = 8080;
            nodePort = {
              http = 8080;
            };
          };
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
