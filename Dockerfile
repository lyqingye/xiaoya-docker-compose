FROM ghcr.io/nixos/nix

ENV LANG=C.UTF-8

RUN nix-env -iA nixpkgs.yq nixpkgs.jq nixpkgs.curl nixpkgs.docker nixpkgs.p7zip nixpkgs.aria2 nixpkgs.supercronic nixpkgs.tzdata nixpkgs.python3 && \
    ln -s /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
