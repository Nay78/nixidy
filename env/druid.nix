{ lib, ... }:
{
  applications.druid = {
    namespace = "druid";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: tailscale
          namespace: druid
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: druid
          ports:
            - protocol: TCP
              port: 80
              targetPort: 8888
        # spec:
        #   selector:
        #     app: n8n
        #   ports: 
        #   - name: http-port
        #     protocol: TCP
        #     port: 80       # Port the K8s Service listens on (the "external" port within the cluster)
        #     targetPort: 5678 # Port the n8n Pod is listening on (the "internal" port of the application)
      ''
    ];

    helm.releases.druid = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://asdf2014.github.io/druid-helm/";
        chart = "druid";
        version = "31.0.5";
        chartHash = "sha256-FcE6hnPH/eVpc4uuvvKNp3KTNaBgQs9REVWtpfM6vB4=";
      };

      values = {
        # service = {
        #   type = "NodePort";
        #   port = 8888;
        #   targetPort = 8888;
        #   nodePort = {
        #     http = 8888;
        #   };
        # };
        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
      };
    };

  };
}

# error: hash mismatch in fixed-output derivation '/nix/store/2b2kpi3i7n0dy77n1djlrjy5lydkmnjc-helm-chart-https-asdf2014.github.io-druid-helm--druid-31.0.5.drv':
#          specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
#             got:    sha256-FcE6hnPH/eVpc4uuvvKNp3KTNaBgQs9REVWtpfM6vB4=
#
#error: hash mismatch in fixed-output derivation '/nix/store/yh2d1p3qv6n0b344j2w260dqqvlk7iia-helm-chart-https-asdf2014.github.io-druid-helm--druid-31.0.5.drv':
# specified: sha256-zXXHMny0h6hd4563oho5gtTvDb/QnTATtRs0XSlX6g4=
#    got:    sha256-FcE6hnPH/eVpc4uuvvKNp3KTNaBgQs9REVWtpfM6vB4=
