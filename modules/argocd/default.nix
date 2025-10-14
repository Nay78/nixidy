{
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    yamls = [
      (builtins.readFile ./tailscale.yaml)
    ];
  };

}
