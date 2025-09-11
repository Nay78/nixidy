{ lib, ... }:
{

  # applications.external-secrets = {
  #   namespace = "external-secrets";
  #   createNamespace = true;
  #
  #   helm.releases.external-secrets = {
  #     # Use `lib.helm.downloadHelmChart` to fetch
  #     # the Helm Chart to use.
  #     chart = lib.helm.downloadHelmChart {
  #       repo = "https://charts.external-secrets.io/";
  #       chart = "external-secrets-operator";
  #       version = "0.19.2";
  #       chartHash = "";
  #     };
  #
  #     # Example values to pass to the Helm Chart.
  #     values = {
  #     };
  #   };
  # };
}
