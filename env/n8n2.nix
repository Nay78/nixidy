{ lib, ... }:

{

  applications.n8n = {
    namespace = "n8n";
    createNamespace = true;
    yamls = [
      # (builtins.readFile ../sops/superset.sops.yaml)
      ''
        apiVersion: v1
        kind: Service
        metadata:
          name: n8n
          namespace: n8n
          annotations:
            tailscale.com/expose: "true"
        spec:
          selector:
            app: n8n
          # ports:
          #   - protocol: TCP
          #     port: 8888
          #     targetPort: 8888
      ''
    ];

    helm.releases.n8n = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      #helm install my-n8n oci://8gears.container-registry.com/library/n8n --version 1.0.10
      chart = lib.helm.downloadHelmChart {
        repo = "oci://8gears.container-registry.com/library";
        chart = "n8n";
        version = "1.0.14";
        chartHash = "sha256-0rkHS4WGL8AKp1VcU2AcWNwpuOlv5kuVT6pTEbHo9LY=";
      };
      values = {
        N8N_RUNNERS_ENABLED = true;
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

    # environment.variables.MY_SECRET = secrets.my-secret-key;
    # resources = {
    #   services.x.spec = {
    #     apiVersion = "external-secrets.io/v1";
    #     kind = "SecretStore";
    #     metadata = {
    #       name = "test";
    #     };
    #     spec = {
    #       provider = {
    #         aws = {
    #           service = "SecretsManager";
    #           region = "us-east-1";
    #           auth = {
    #             secretRef = {
    #               accessKeyIDSecretRef = {
    #                 name = "awssm-secret";
    #                 key = "access-key";
    #               };
    #               secretAccessKeySecretRef = {
    #                 name = "awssm-secret";
    #                 key = "secret-access-key";
    #               };
    #             };
    #           };
    #         };
    #       };
    #     };
    #   };
    # };
  };
}
