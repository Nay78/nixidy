{ lib, ... }:
{
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;
    # yamls = [
    #   ''
    #     apiVersion: v1
    #     kind: Service
    #     metadata:
    #       name: cert-manager
    #       namespace: cert-manager
    #       annotations:
    #         tailscale.com/expose: "true"
    #     spec:
    #       selector:
    #         app: cert-manager
    #       # ports:
    #       #   - protocol: TCP
    #       #     port: 8888
    #       #     targetPort: 8888
    #   ''
    # ];
    #
    #         Add repository
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    # Install chart
    # helm install my-flink bitnami/flink --version 2.0.7

    # helm install \
    #   cert-manager oci://quay.io/jetstack/charts/cert-manager \
    #   --version v1.19.0 \
    #   --namespace cert-manager \
    #   --create-namespace \
    #   --set crds.enabled=true
    # oci://quay.io/jetstack/charts/cert-manager:v1.19.0

    helm.releases.cert-manager = {
      chart = lib.helm.downloadHelmChart {
        # repo = "oci://quay.io/jetstack/charts/cert-manager";
        repo = "https://charts.jetstack.io";
        chart = "cert-manager";
        version = "1.19.0";
        chartHash = "sha256-dWlWl/XTvegmfrgOTk2ZThKrQeQ8nYFiejnTcjhebhk=";
      };

    };

  };
}
