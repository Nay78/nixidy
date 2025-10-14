{ charts, lib, ... }:

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
          ports:
            - protocol: TCP
              port: 8888
              targetPort: 8888
      ''
    ];

    # allowVolumeExpansion = true;

    # helm repo add cloudnative-pg https://cloudnative-pg.io/charts/
    helm.releases.cnpg = {
      # chart = charts.stackgres.stackgres;
      chart = lib.helm.downloadHelmChart {
        repo = "https://cloudnative-pg.github.io/charts";
        chart = "cloudnative-pg";
        version = "0.26.0";
        chartHash = "sha256-8VgcvZqJS/jts2TJJjaj6V4BRDy56phyd0gwPs0bhnI=";
      };
      values = {
        # TODO: make this command declarative
        # helm template cnpg cnpg/cloudnative-pg --version 0.26.0 --include-crds | kubectl apply -f -
        # instances = 3;
        #
        # storage = {
        #   size = "1Gi";
        # };

      };
    };

  };
}
