{ lib, ... }:
{
  #        error: The option `applications.seatunnel.resources.core.v1.Service.seatunnel.metadata.namespace` is defined both null and not null, in `/nix/store/5n18yk7slwnnw3yfq6di7fq761irnjk2-source/modules/applicati
  # ons/yamls.nix' and `/nix/store/5n18yk7slwnnw3yfq6di7fq761irnjk2-source/modules/applications/helm.nix'.
  # make: *** [makefile:8: p] Error 1

  applications.seatunnel = {
    namespace = "seatunnel";
    createNamespace = true;
    yamls = [
      # ''
      #   apiVersion: v1
      #   kind: Service
      #   metadata:
      #     name: tailscale
      #     namespace: seatunnel
      #     annotations:
      #       tailscale.com/hostname: seatunnel
      #       tailscale.com/expose: "true"
      #   spec:
      #     selector:
      #       app: seatunnel
      #     ports:
      #       - protocol: TCP
      #         port: 80
      #         targetPort: 5801
      # ''
      ''
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: seatunnel
          namespace: seatunnel
          annotations:
            # Optional: customize the device name in your tailnet
            tailscale.com/hostname: seatunnel
            # Optional: tag the Tailscale device
            # tailscale.com/tags: tag:k8s
            # Optional: set to "true" to expose publicly via Funnel
            # tailscale.com/funnel: "false"
        spec:
          ingressClassName: tailscale
          rules:
            - http:
                paths:
                  - path: /
                    pathType: Prefix
                    backend:
                      service:
                        # Point to your existing Service
                        name: tailscale
                        port:
                          number: 80

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
