{ lib, ... }:
{
  applications.flink = {
    namespace = "flink";
    createNamespace = true;
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

    #
    #         Add repository
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    # Install chart
    # helm install my-flink bitnami/flink --version 2.0.7

    # helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.13.0/
    # helm install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator
    helm.releases.flink-kubernetes-operator = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://downloads.apache.org/flink/flink-kubernetes-operator-1.13.0/";
        # repo = "https://downloads.apache.org/flink";
        chart = "flink-kubernetes-operator";
        version = "1.13.0";
        chartHash = "sha256-961lpFE8b7imiKkarJ5d2+GBttvB2lj3PehbeYOjgvs=";
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
