{ lib, ... }:
{
  applications.temporalio = {
    namespace = "temporal";
    createNamespace = true;
    yamls = [
      (builtins.readFile ./tailscale.yaml)
    ];

    # helm install \
    #     --repo https://go.temporal.io/helm-charts \
    #     --set server.replicaCount=1 \
    #     --set cassandra.config.cluster_size=1 \
    #     --set elasticsearch.replicas=1 \
    #     --set prometheus.enabled=false \
    #     --set grafana.enabled=false \
    #     temporaltest temporal \
    #     --timeout 15m

    helm.releases.temporalio = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://temporalio.github.io/helm-charts";
        chart = "temporal";
        version = "0.68.1";
        chartHash = "sha256-OmBIGdbJkGnpsmbT2mbZcBmg4vfyaCSN9hTuTCjftRQ=";
      };

      values = {
        server = {
          replicaCount = 1;
          config = {
            persistence = {
              default = {
                driver = "sql";
                sql = {
                  driver = "postgres12";
                  host = "temporal-postgresql";
                  port = 5432;
                  database = "temporal";
                  user = "temporal";
                  password = "temporal";
                  maxConns = 20;
                  maxIdleConns = 20;
                  maxConnLifetime = "1h";
                };
              };
              visibility = {
                driver = "sql";
                sql = {
                  driver = "postgres12";
                  host = "temporal-postgresql";
                  port = 5432;
                  database = "temporal_visibility";
                  user = "temporal";
                  password = "temporal";
                  maxConns = 20;
                  maxIdleConns = 20;
                  maxConnLifetime = "1h";
                };
              };
            };
          };
        };

        cassandra = {
          enabled = false;
        };
        postgresql = {
          enabled = true;

          fullnameOverride = "temporal-postgresql";
          postgresqlDatabase = "temporal";
          postgresqlUsername = "temporal";
          postgresqlPassword = "temporal";
        };

        elasticsearch.enable = false;

        prometheus = {
          enabled = false;
        };
        grafana = {
          enabled = false;
        };
        web = {
          additionalEnv = [
            # {
            #   name = "TEMPORAL_CORS_ORIGINS";
            #   value = "http://temporal-ui:8080";
            # }
            {
              name = "TEMPORAL_UI_PORT";
              value = "8080";
            }
            {
              name = "TEMPORAL_CSRF_COOKIE_INSECURE";
              value = "true";
            }
          ];
        };
        schema = {
          createDatabase = {
            enabled = true;
          };
          setup = {
            enabled = true;
          };
          update = {
            enabled = true;
          };
        };

      };
    };

  };
}
