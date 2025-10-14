{ lib, ... }:
{
  applications.temporalio = {
    namespace = "temporal";
    createNamespace = true;
    yamls = [
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: temporal-frontend-tailscale
          namespace: temporal
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app.kubernetes.io/instance: temporalio
            app.kubernetes.io/name: temporal
            app.kubernetes.io/component: frontend
          ports:
            - protocol: TCP
              port: 7233
              targetPort: 7233
      ''
      # ''
      #   apiVersion: v1
      #   kind: Service
      #   metadata:
      #     name: temporalio
      #     namespace: temporalio
      #     annotations:
      #       tailscale.com/expose: "true"
      #   spec:
      #     selector:
      #       app: temporalio
      #     ports:
      #       - protocol: TCP
      #         port: 8233
      #         targetPort: 8233
      # ''
      #
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
        };
        elasticsearch = {

          enabled = true;
          replicaCount = 1;
          # imageTag = "8.19.5";
          imageTag = "7.17.29";
          # 7.17.3
          # external = true;
          # host = "elasticsearch-master-headless";
          # port = "9200";
          # version = "v8";
          # scheme = "http";
          # logLevel = "error";
        };
        prometheus = {
          enabled = false;
        };
        grafana = {
          enabled = false;
        };
        # schema = {
        #   createDatabase = {
        #     enabled = true;
        #   };
        #   setup = {
        #     enabled = true;
        #   };
        #   update = {
        #     enabled = true;
        #   };
        # };

      };
    };

  };
}
