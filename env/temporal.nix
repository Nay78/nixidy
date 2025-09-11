{ lib, ... }:
{
  applications.temporalio = {
    namespace = "temporal";
    createNamespace = true;

    helm.releases.temporalio = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://temporalio.github.io/helm-charts";
        chart = "temporal";
        version = "0.65.0";
        chartHash = "sha256-L664DQpVHdpCoiHCWAVd3/ySPW3/afG4L4ojPLOvYEI=";
      };

      values = {
      };
    };

  };
}
