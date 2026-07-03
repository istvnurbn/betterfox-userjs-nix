# betterfox-userjs-nix

The daily auto updated nix version of [yokoffing/Betterfox](https://github.com/yokoffing/Betterfox).

## Usage with home-manager

1. Set up home-manager with flakes
1. Add flake input
1. Pass flake input to `extraSpecialArgs`
1. Add settings to Firefox profile(s)

flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    betterfox-userjs.url = "github:istvnurbn/betterfox-userjs-nix";
  };
  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    homeConfigurations.my-user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ({ inputs, ... }: {
          programs.firefox = {
            enable = true;
            profiles.myprofile.settings = inputs.betterfox-userjs.lib.mkSettings {
              enable = [ "securefox" "peskyfox" "smoothfox-smooth-scrolling" ];
              overrides = {
                "browser.startup.page" = 3; # restore session
              };
            };
          };
        })
      ];
    };
  };
}
```

> [!NOTE]
> The `smoothfox-*` options are **mutually exclusive** — enable exactly one.
>
> `user` is Betterfox's combined file: it already contains the Securefox
> and Peskyfox settings. Use either `enable = [ "user" ]` _or_ a selection
> of the individual modules — combining `user` with the others is redundant.
