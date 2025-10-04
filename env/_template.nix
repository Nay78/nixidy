{ lib, ... }:
{
  applications.template = {
    namespace = "template";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: template
          namespace: template
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: template
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];
    #
    #         Add repository
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    # Install chart
    # helm install my-flink bitnami/flink --version 2.0.7

    helm.releases.template = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.bitnami.com/bitnami";
        chart = "flink";
        version = "2.0.7";
        chartHash = "";
      };

      values = {
        service = {

        };

        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}
