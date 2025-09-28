{ lib, ... }:

# let
#   stackgres-crd = builtins.fetchurl {
#     url = "https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/stackgres-operator/crds/";
#     sha256 = "";
#   };
# in
{
  # applications.k8s-gw-api-crds = {
  #   yamls = [
  #     (builtins.readFile stackgres-crd)
  #   ];
  # };
  # --set-string adminui.service.type=LoadBalancer https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
  nixidy.applicationImports = [
    # ../../generated/stackgres.nix
    ./generated.nix
  ];
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

    # allowVolumeExpansion = true;

    helm.releases.stackgres = {
      chart = lib.helm.downloadHelmChart {

        repo = "https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/";
        chart = "stackgres-operator";
        version = "1.17.2";
        chartHash = "sha256-Y9LAvUwQsFCsqcGpv4g1vZYOZGfgpUykQ8H3Ez22zOQ=";
      };

      values = {

      };
    };

  };
}
