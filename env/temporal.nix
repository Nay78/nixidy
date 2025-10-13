{ lib, ... }:
{
  applications.temporalio = {
    namespace = "temporal";
    createNamespace = true;

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
          config = {
            cluster_size = 1;
          };
        };
        elasticsearch = {
          replicas = 1;
        };
        prometheus = {
          enabled = false;
        };
        grafana = {
          enabled = false;
        };

      };
    };

  };
}
