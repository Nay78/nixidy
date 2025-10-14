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
        };
        cassandra = {
          enabled = true;
          config = {
            cluster_size = 1;
          };

        };
        elasticsearch = {

          enabled = true;
          replicaCount = 1;
          replicas = 1;
          # imageTag = "8.19.5";
          imageTag = "7.17.29";
          # 7.17.3
          # external = true;
          host = "elasticsearch-master-headless";
          port = "9200";
          version = "v7";
          scheme = "http";
          logLevel = "error";
          username = "elastic";
          password = "elasticsearch";

        };
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
            #   value = "temporal-ui:8080";
            # }
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
