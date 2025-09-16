{ lib, ... }:
{
  applications.druid = {
    namespace = "druid";
    createNamespace = true;

    helm.releases.druid = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://wiremind.github.io/wiremind-helm-charts";
        chart = "druid";
        version = "1.22.1";
        chartHash = "sha256-zXXHMny0h6hd4563oho5gtTvDb/QnTATtRs0XSlX6g4=";
      };

      values = { };
    };

  };
}
