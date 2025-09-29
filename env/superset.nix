{ lib, ... }:
{

  #

  applications.superset = {
    namespace = "superset";
    createNamespace = true;

    # helm install --create-namespace --namespace stackgres stackgres-operator --set-string adminui.service.type=LoadBalancer https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz

    yamls = [
      (builtins.readFile ../sops/superset.sops.yaml)
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: superset
          namespace: superset
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: superset
      ''
    ];

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
        # annotations = {
        #   "tailscale.com/expose" = "true";
        # };
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

  };
}
