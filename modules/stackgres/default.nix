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
    # ./generated.nix
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
          ports:
            - protocol: TCP
              port: 80
              targetPort: 8443
      ''
    ];

    # allowVolumeExpansion = true;

    helm.releases.stackgres = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/";
        chart = "stackgres-operator";
        version = "1.17.4";
        # version = "1.3.2";
        chartHash = "sha256-AYww0r1vAvTIe3SAdO7Q17iqJNFGX9zx0Sd93bcmmRQ=";
        # chartHash = "sha256-1JGlhcAWGtssal7Pixqx8XOIVmPs0FAFIRbOOwEPlgQ=";

      };

      values = {

      };
    };

  };
}
