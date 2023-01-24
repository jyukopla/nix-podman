{
  description = "Rootless Podman";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let pkgs = nixpkgs.legacyPackages.${system}; in {

    # users.extraUsers.myusername= {
    #   subUidRanges = [{ startUid = 100000; count = 65536; }];
    #   subGidRanges = [{ startGid = 100000; count = 65536; }];
    # };

    devShells.default = pkgs.mkShell {
      buildInputs = [
        pkgs.podman          # CLI
        pkgs.runc            # Container runtime
        pkgs.conmon          # Container runtime monitor
        pkgs.skopeo          # Interact with container registry
        pkgs.slirp4netns     # User-mode networking
      ];
      shellHook = let
        podmanSetupScript = let
          policyConf = pkgs.writeText "policy.conf" ''
            {"default":[{"type":"insecureAcceptAnything"}],"transports":{"docker-daemon":{"":[{"type":"insecureAcceptAnything"}]}}}
          '';
          registriesConf = pkgs.writeText "registries.conf" ''
            [registries]
            [registries.block]
            registries = []
            [registries.insecure]
            registries = []
            [registries.search]
            registries = ["docker.io", "quay.io"]
          '';
        in pkgs.writeScript "podman-setup" ''
          #!${pkgs.runtimeShell}
          if ! test -f ~/.config/containers/policy.json; then
            install -Dm555 ${policyConf} ~/.config/containers/policy.json
          fi
          if ! test -f ~/.config/containers/registries.conf; then
            install -Dm555 ${registriesConf} ~/.config/containers/registries.conf
          fi
        '';
      in ''
        ${podmanSetupScript}
      '';
    };
  });
}