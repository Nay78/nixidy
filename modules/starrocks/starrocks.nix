{ lib, ... }:
{
  applications.starrocks = {
    namespace = "starrocks";
    createNamespace = true;

    yamls = [
      (builtins.readFile ../../sops/starrocks.sops.yaml)
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
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];

    helm.releases.starrocks = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://starrocks.github.io/starrocks-kubernetes-operator";
        chart = "kube-starrocks";
        version = "1.9.7";
        chartHash = "sha256-7aEkuabKDDYfkkIm4insyFp+E0b7acUF7QBM3VWqJWw=";
      };

      # Example values to pass to the Helm Chart.
      values = {
        starrocksFESpec = {
          replicas = 3;
          service = {
            type = "ClusterIP";
            annotations = {
              "tailscale.com/expose" = "true";
            };
          };
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
