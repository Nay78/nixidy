{ lib, ... }:
{

  applications.secrets = {
    namespace = "sealed-secrets";
    createNamespace = true;

    helm.releases.sealed-secrets = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://bitnami-labs.github.io/sealed-secrets";
        chart = "sealed-secrets";
        version = "2.17.4";
        chartHash = "sha256-ypiHZaiy9WAiIslG0UsPgSLIDqx/KPyud78hFvQFOy4=";
      };

      # Example values to pass to the Helm Chart.
      values = {
      };
    };
  };
}
