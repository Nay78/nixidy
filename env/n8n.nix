{ lib, ... }:

{

  applications.n8n = {
    namespace = "n8n";
    createNamespace = true;

    helm.releases.n8n = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://community-charts.github.io/helm-charts";
        chart = "n8n";
        version = "1.14.3";
        chartHash = "sha256-bheYf18VYnwDL6TdxWDRVgGc6SQp9Q1wC6zbEBMrruU=";
      };

      # Example values to pass to the Helm Chart.
      values = {
        # externalPostgresql = {
        #   host = "postgresql-instance1.ab012cdefghi.eu-central-1.rds.amazonaws.com";
        #   username = "n8nuser";
        #   password = "Pa33w0rd!";
        #   database = "n8n";
        # };
        db = {
          type = "postgresdb";
        };

        postgresql = {
          enabled = true;

          primary = {
            persistence = {
              existingClaim = "my-n8n-claim";
            };
          };
        };

      };
    };
  };
}
