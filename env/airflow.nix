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
      chart = lib.helm.downloadHelmChart {
        repo = "https://airflow.apache.org/";
        chart = "airflow";
        version = "1.18.0";
        chartHash = "sha256-RpuMs61pTLPJ61Frzir0ob6vH9ixX2ceSKclFRfv5dI=";
      };

      values = {

        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}
