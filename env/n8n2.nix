{ lib, ... }:

{

  applications.n8n = {
    namespace = "n8n";
    createNamespace = true;

    helm.releases.n8n = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      #helm install my-n8n oci://8gears.container-registry.com/library/n8n --version 1.0.10
      chart = lib.helm.downloadHelmChart {
        repo = "oci://8gears.container-registry.com/library";
        chart = "n8n";
        version = "1.0.10";
        chartHash = "sha256-0rkHS4WGL8AKp1VcU2AcWNwpuOlv5kuVT6pTEbHo9LY=";
      };

      # Example values to pass to the Helm Chart.
      # values = {
      #   db = {
      #     type = "postgresdb";
      #   };
      #
      #   postgresql = {
      #     enabled = true;
      #
      #     primary = {
      #       persistence = {
      #         existingClaim = "my-n8n-claim";
      #       };
      #     };
      #   };
      #
      # };
    };
  };
}
