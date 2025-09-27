{ lib, ... }:
{
  # --set-string adminui.service.type=LoadBalancer https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
  applications.stackgres = {
    namespace = "stackgres";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: stackgres
          namespace: stackgres
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: stackgres
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];

    helm.releases.stackgres = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz";
        chart = "stackgres-operator";
        version = "1.17.2";
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
