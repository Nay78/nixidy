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
          config = {
            persistence = {
              enabled = true;
              default = {
                driver = "sql";
                sql = {
                  driver = "postgres12";
                  host = "temporal-postgresql"; # internal Postgres (see postgresql.fullnameOverride)
                  port = 5432;
                  database = "temporal";
                  user = "_USERNAME_";
                  password = "_PASSWORD_";
                  # for production use an existing secret instead of `password`
                  # existingSecret = "temporal-default-store";
                  maxConns = 20;
                  maxIdleConns = 20;
                  maxConnLifetime = "1h";
                  # tls = {
                  #   enabled = true;
                  #   enableHostVerification = true;
                  #   serverName = "temporal-postgresql";
                  #   caFile = "/path/to/certs/<CA-file>";
                  #   certFile = "/path/to/certs/<client-cert-file>";
                  #   keyFile = "/path/to/certs/<client-key-file>";
                  # };
                };
              };
              visibility = {
                driver = "sql";
                sql = {
                  driver = "postgres12";
                  host = "temporal-postgresql"; # internal Postgres
                  port = 5432;
                  database = "temporal_visibility";
                  user = "_USERNAME_";
                  password = "_PASSWORD_";
                  # for production use an existing secret instead of `password`
                  # existingSecret = "temporal-visibility-store";
                  maxConns = 20;
                  maxIdleConns = 20;
                  maxConnLifetime = "1h";
                  # tls = {
                  #   enabled = true;
                  #   enableHostVerification = true;
                  #   serverName = "temporal-postgresql";
                  #   caFile = "/path/to/certs/<CA-file>";
                  #   certFile = "/path/to/certs/<client-cert-file>";
                  #   keyFile = "/path/to/certs/<client-key-file>";
                  # };
                };
              };
            };
          };
        };
        cassandra = {
          enabled = false;
        };
        mysql = {
          enabled = false;
        };
        postgresql = {
          enabled = true;

          # Fix the service name so we can reference it from server.config.persistence.sql.host
          fullnameOverride = "temporal-postgresql";

          # Auth must match the credentials used above
          auth = {
            username = "_USERNAME_";
            password = "_PASSWORD_";
            database = "temporal";
          };

          # Create the visibility database alongside the main one
          primary = {
            persistence = {
              enabled = true;
            };
            initdb = {
              scripts = {
                createVisibilityDB = ''
                  CREATE DATABASE temporal_visibility;
                '';
              };
            };
          };
        };
        elasticsearch = {
          enabled = false;
        };
        prometheus = {
          enabled = false;
        };
        grafana = {
          enabled = false;
        };
        schema = {
          createDatabase = {
            enabled = true;
          };
          setup = {
            enabled = false;
          };
          update = {
            enabled = false;
          };
        };

      };
    };

  };
}
