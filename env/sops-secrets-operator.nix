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
        secretsAsFiles = [
          {
            mountPath = "/etc/sops-age-private-key";
            name = "sops-age-private-key";
            secretName = "sops-age-private-key";
          }
        ];
      };

    };

  };
}
