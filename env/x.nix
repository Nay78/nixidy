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
        configOverrides = {
          secret = "SECRET_KEY = 'IGMETYkv0SY7B8Kocw5xtm93bM6lhXxIyaQ9uGzALn+nhm0VFyvm2mBu'";
        };
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

            # Create bootstrap file if it doesn't exist
            if [ ! -f ~/bootstrap ]; then
              echo "Running Superset with uid {{ .Values.runAsUser }}" > ~/bootstrap
            fi'';
        testing = "WHAT IS THIS";
        # ingressClass.enabled = true;
      };
    };
  };
}
