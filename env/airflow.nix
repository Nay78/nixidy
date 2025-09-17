{ lib, ... }:
{
  applications.airflow = {
    namespace = "airflow";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: airflow
          namespace: airflow
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: airflow
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];

    helm.releases.airflow = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://airflow.apache.org/";
        chart = "airflow";
        version = "1.18.1";
        chartHash = "";
      };

      values = {

        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}
