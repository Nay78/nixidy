{ lib, ... }:

{

  applications.metallb = {
    namespace = "metallb";
    createNamespace = true;

    helm.releases.metallb = {
      # Use `lib.helm.downloadHelmChart` to fetch
      # the Helm Chart to use.
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.bitnami.com/bitnami";
        chart = "metallb";
        version = "6.4.22";
        chartHash = "sha256-JM2GKb9RZD4eGSnovHN2TRXpbWC4O8YghXp+fEAooPo=";
      };

      # Example values to pass to the Helm Chart.
      values = {
        # Define a custom resource for MetalLB's IPAddressPool
        apiServer = {
          extraManifests = [
            {
              apiVersion = "metallb.io/v1beta1";
              kind = "IPAddressPool";
              metadata = {
                # A name for the address pool. Services can request allocation
                # from a specific address pool using this name.
                name = "first-pool";
                namespace = "metallb-system";
              };
              spec = {
                # A list of IP address ranges over which MetalLB has
                # authority. You can list multiple ranges in a single pool, they
                # will all share the same settings. Each range can be either a
                # CIDR prefix, or an explicit start-end range of IPs.
                addresses = [
                  "192.168.1.240-192.168.1.255"
                ];
              };
            }
          ];
        };

      };
    };
  };
}
