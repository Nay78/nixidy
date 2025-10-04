{ lib, ... }:
{
  applications.flink = {
    namespace = "flink";
    createNamespace = true;
    yamls = [
      # ''
      #   apiVersion: v1
      #   kind: Service
      #   metadata:
      #     name: flink
      #     namespace: flink
      #     annotations:
      #       tailscale.com/expose: "true"
      #   spec:
      #     selector:
      #       app: flink
      #     # ports:
      #     #   - protocol: TCP
      #     #     port: 8888
      #     #     targetPort: 8888
      # ''
    ];

    #
    #         Add repository
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    # Install chart
    # helm install my-flink bitnami/flink --version 2.0.7

    helm.releases.flink = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.bitnami.com/bitnami";
        chart = "flink";
        version = "2.0.7";
        chartHash = "sha256-6KEDONfzN6P+XqZrbSLShJpHtA6waJka3ytLYyH4iCc=";
      };

      values = {

        service = {
          type = "ClusterIP";
          annotations = {
            "tailscale.com/expose" = "true";
          };
          port = 80;
          targetPort = 5678;
          # nodePort = {
          #   http = 5678;
          # };
        };

        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}
