{ lib, ... }:

{
  #   helm repo add cnpg https://cloudnative-pg.github.io/charts
  # helm upgrade --install cnpg \
  #   --namespace cnpg-system \
  #   --create-namespace \
  #   cnpg/cloudnative-pg
  # --set-string adminui.service.type=LoadBalancer https://cnpg.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
  applications.cnpg = {
    namespace = "cnpg";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: cnpg
          namespace: cnpg
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: cnpg
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];

    # allowVolumeExpansion = true;
    crds = [ ];

    helm.releases.cnpg = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://cloudnative-pg.github.io/charts";
        chart = "cloudnative-pg";
        version = "0.26.0";
        chartHash = "";
      };

      values = {

      };
    };

  };
}
