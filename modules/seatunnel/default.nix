{ lib, ... }:
let
  starrocksConf = builtins.readFile /home/alejg/projects/nixidy/jobs/seatunnel/starrocks/job.conf;
  # confHash = builtins.hashString "sha256" starrocksConf;
in

{
  #        error: The option `applications.seatunnel.resources.core.v1.Service.seatunnel.metadata.namespace` is defined both null and not null, in `/nix/store/5n18yk7slwnnw3yfq6di7fq761irnjk2-source/modules/applicati
  # ons/yamls.nix' and `/nix/store/5n18yk7slwnnw3yfq6di7fq761irnjk2-source/modules/applications/helm.nix'.
  # make: *** [makefile:8: p] Error 1

  applications.seatunnel = {
    namespace = "seatunnel";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: seatunnel-http
        spec:
          selector:
            # app: seatunnel
            app.kubernetes.io/instance: seatunnel
            app.kubernetes.io/managed-by: Helm
            app.kubernetes.io/version: "2.3.10"
          ports:
            - protocol: TCP
              # name: http
              port: 5801
              targetPort: 5801
      ''
      ''
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: seatunnel
          annotations:
            tailscale.com/hostname: seatunnel
        spec:
          ingressClassName: tailscale

          rules:
            - http:
                paths:
                  - path: /
                    pathType: Prefix
                    backend:
                      service:
                        name: seatunnel-http
                        port:
                          number: 5801
      ''
    ];

    # allowVolumeExpansion = true;

    helm.releases.seatunnel = {
      # helm pull oci://registry-1.docker.io/apache/seatunnel-helm --version ${VERSION}
      chart = lib.helm.downloadHelmChart {
        repo = "oci://registry-1.docker.io/apache";
        chart = "seatunnel-helm";
        version = "2.3.10";
        chartHash = "sha256-wKSaQMnENRFRY90INmsE0WlLOBIR1ehZCsiA5H+C1pY=";
      };

      # values = {
      # };
    };

  };
}
