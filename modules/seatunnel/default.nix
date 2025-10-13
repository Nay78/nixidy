{ lib, ... }:
{
  # applications.k8s-gw-api-crds = {
  #   yamls = [
  #     (builtins.readFile seatunnel-crd)
  #   ];
  # };
  # --set-string adminui.service.type=LoadBalancer https://seatunnel.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz
  applications.seatunnel = {
    namespace = "seatunnel";
    createNamespace = true;
    # yamls = [
    #   ''
    #     apiVersion: v1
    #     kind: Service
    #     metadata:
    #       name: seatunnel
    #       namespace: seatunnel
    #       annotations:
    #         tailscale.com/expose: "true"
    #     spec:
    #       selector:
    #         app: seatunnel
    #       ports:
    #         - protocol: TCP
    #           port: 80
    #           targetPort: 8443
    #   ''
    # ];

    # allowVolumeExpansion = true;

    helm.releases.seatunnel = {

      # helm pull oci://registry-1.docker.io/apache/seatunnel-helm --version ${VERSION}
      chart = lib.helm.downloadHelmChart {
        repo = "oci://registry-1.docker.io/apache";
        chart = "seatunnel-helm";
        version = "2.3.10";
        chartHash = "sha256-wKSaQMnENRFRY90INmsE0WlLOBIR1ehZCsiA5H+C1pY=";
      };

      values = {

      };
    };

  };
}
