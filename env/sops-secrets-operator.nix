{ lib, ... }:
{
  applications.sops = {
    namespace = "sops";
    createNamespace = true;

    helm.releases.sops = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://isindir.github.io/sops-secrets-operator/";
        chart = "sops-secrets-operator";
        version = "0.23.0";
        chartHash = "sha256-8bHfQe4AClYIX0jxCQ7defVtgNMplQuPEZV4uLJqR/I=";
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
      };

    };

  };
}
