{ lib, ... }:
{
  applications.superset = {
    namespace = "superset";
    createNamespace = true;

    helm.releases.superset = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://apache.github.io/superset";
        chart = "superset";
        version = "0.15.0";
        chartHash = "";
      };

      # Example values to pass to the Helm Chart.
      values = {
        # ingressClass.enabled = true;
      };
    };
  };
}
