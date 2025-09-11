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
        chartHash = "sha256-CX/cY/c5gmrcyE4jIjotLxThNi0Rt2Rb7gfakBqfmME=";
      };

      # Example values to pass to the Helm Chart.
      values = {
        # configOverrides = {
        #   # secret = "SECRET_KEY = 'IGMETYkv0SY7B8Kocw5xtm93bM6lhXxIyaQ9uGzALn+nhm0VFyvm2mBu'";
        #   secret = "SECRET_KEY = env('SECRET_KEY')";
        # };
        bootstrapScript = ''
          bootstrapScript: |
            #!/bin/bash
            
            # Install system-level dependencies
            apt-get update && apt-get install -y \
              python3-dev \
              default-libmysqlclient-dev \
              build-essential \
              pkg-config

            # Install required Python packages
            uv pip install \
              authlib \
              psycopg2-binary \
              mysqlclient \
              pymssql \

            # Create bootstrap file if it doesn't exist
            if [ ! -f ~/bootstrap ]; then
              echo "Running Superset with uid {{ .Values.runAsUser }}" > ~/bootstrap
            fi'';
        service = {
          type = "NodePort";
          port = 8088;
          targetPort = 8088;
          nodePort = {
            http = 30088;
          };
        };
        # extraSecretEnv = {
        #   SUPERSET_SECRET_KEY = "helloworld";
        # };
        secretEnv = {
          create = false;
        };
        # extraEnv = {
        #   key = "helloworlde";
        #
        # };
        # extraEnv = [
        #   {
        #     name = "SECRET_KEY";
        #     valueFrom.secretKeyRef = {
        #       name = "superset-secret";
        #       key = "SECRET_KEY";
        #     };
        #   }
        # ];

        # ingressClass.enabled = true;
      };
    };
    # resources = [
    #   {
    #     apiVersion = "v1";
    #     kind = "Secret";
    #     metadata = {
    #       name = "superset-env";
    #       namespace = "superset";
    #       labels = {
    #         app = "superset";
    #         chart = "superset-0.15.0";
    #         heritage = "Helm";
    #         release = "superset";
    #       };
    #     };
    #     stringData = {
    #       DB_HOST = "superset-postgresql";
    #       DB_NAME = "superset";
    #       DB_PASS = "superset";
    #       DB_PORT = "5432";
    #       DB_USER = "superset";
    #       REDIS_CELERY_DB = "0";
    #       REDIS_DB = "1";
    #       REDIS_HOST = "superset-redis-headless";
    #       REDIS_PORT = "6379";
    #       REDIS_PROTO = "redis";
    #       REDIS_USER = "";
    #     };
    #     type = "Opaque";
    #   }
    # ];

  };
}
