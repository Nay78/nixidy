{ lib, ... }:
{
  applications.template = {
    namespace = "template";
    createNamespace = true;
    yamls = [
      # ''
      #   apiVersion: v1
      #   kind: Service
      #   metadata:
      #     name: template
      #     namespace: template
      #     annotations:
      #       tailscale.com/expose: "true"
      #   spec:
      #     selector:
      #       app: template
      #     # ports:
      #     #   - protocol: TCP
      #     #     port: 8888
      #     #     targetPort: 8888
      # ''
    ];

    helm.releases.template = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://template.apache.orgqq/";
        chart = "template";
        version = "1.18.0";
        chartHash = "sha256-RpuMs61pTLPJ61Frzir0ob6vH9ixX2ceSKclFRfv5dI=";
      };

      values = {

        service = {
          type = "ClusterIP";
          annotations = {
            "tailscale.com/expose" = "true";
          };
          port = 80;
          targetPort = 5678;
          # nodePort = {
          #   http = 5678;
          # };
        };

        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}
