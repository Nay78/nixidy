{ lib, ... }:
{
  applications.druid = {
    namespace = "druid";
    createNamespace = true;

    # helm.releases.druid = {
    #   #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
    #   chart = lib.helm.downloadHelmChart {
    #     repo = "https://wiremind.github.io/wiremind-helm-charts";
    #     chart = "druid";
    #     version = "1.22.1";
    #     chartHash = "sha256-zXXHMny0h6hd4563oho5gtTvDb/QnTATtRs0XSlX6g4=";
    #   };
    #
    #   values = { };
    # };

    helm.releases.druid = {
      #helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
      chart = lib.helm.downloadHelmChart {
        repo = "https://asdf2014.github.io/druid-helm/";
        chart = "druid";
        version = "31.0.5";
        chartHash = "sha256-FcE6hnPH/eVpc4uuvvKNp3KTNaBgQs9REVWtpfM6vB4=";
      };

      values = { };
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
