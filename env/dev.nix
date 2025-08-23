{
  nixidy.target.repository = "https://github.com/Nay78/nixidy";

  # Set the target branch the rendered manifests for _this_
  # environment should be pushed to in the repository defined
  # above.
  nixidy.target.branch = "main";

  # Set the target sub-directory to copy the generated
  # manifests to when running `nixidy switch .#dev`.
  nixidy.target.rootPath = "./manifests/dev";

  imports = [
    ./x.nix
    # ./metallb.nix
    ./metallb-bitnami.nix
    ./n8n.nix
  ];
}
