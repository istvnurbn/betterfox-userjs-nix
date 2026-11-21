# betterfox-userjs-nix

Use [Betterfox](https://github.com/yokoffing/Betterfox) in your Nix-managed Firefox.

Betterfox is a popular `user.js` that makes Firefox faster, more private and less
annoying. This flake turns its preferences into Nix attribute sets you can drop
straight into home-manager's `programs.firefox.profiles.<name>.settings`.

- **Always current:** a GitHub Action pulls the latest Betterfox every day.
- **Pick what you want:** enable whole Betterfox modules, then override single prefs.
- **No dependencies:** the flake has no inputs of its own.

## Quick start (home-manager)

**1. Add the flake input** in your `flake.nix`:

```nix
inputs.betterfox-userjs.url = "github:istvnurbn/betterfox-userjs-nix";
```

**2. Make `inputs` available to your modules**, e.g. via `extraSpecialArgs`:

```nix
homeConfigurations.my-user = home-manager.lib.homeManagerConfiguration {
  # ...
  extraSpecialArgs = { inherit inputs; };
};
```

**3. Use it in your Firefox profile:**

```nix
{ inputs, ... }: {
  programs.firefox = {
    enable = true;
    profiles.myprofile.settings = inputs.betterfox-userjs.lib.mkSettings { };
  };
}
```

That's it. `mkSettings { }` applies Fastfox, Securefox and Peskyfox — the same
prefs as Betterfox's `user.js`.

<details>
<summary>Full <code>flake.nix</code> example</summary>

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
              enable = [ "fastfox" "securefox" "peskyfox" "smoothfox-smooth-scrolling" ];
              overrides = {
                "browser.startup.page" = 3; # restore previous session
              };
            };
          };
        })
      ];
    };
  };
}
```

</details>

## Customizing

`mkSettings` takes two optional arguments:

| Argument    | Default                                  | What it does                                    |
| ----------- | ---------------------------------------- | ----------------------------------------------- |
| `enable`    | `[ "fastfox" "securefox" "peskyfox" ]`   | Betterfox modules to apply, in order.           |
| `overrides` | `{ }`                                    | Your own prefs. These always win.               |

If two modules set the same pref, the one later in `enable` wins.

```nix
inputs.betterfox-userjs.lib.mkSettings {
  enable = [ "fastfox" "securefox" "peskyfox" "smoothfox-smooth-scrolling" ];
  overrides = {
    "browser.startup.page" = 3;                 # restore previous session
    "browser.download.useDownloadDir" = true;   # don't ask where to save
  };
}
```

### Available modules

| Module                                            | What it does                                     |
| ------------------------------------------------- | ------------------------------------------------ |
| `fastfox`                                         | Speed and rendering tweaks.                      |
| `securefox`                                       | Privacy and security hardening.                  |
| `peskyfox`                                        | Removes annoyances and clutter.                  |
| `user`                                            | Betterfox's all-in-one file (the three above).   |
| `smoothfox-smooth-scrolling`                      | Scrolling preset (Smoothfox).                    |
| `smoothfox-natural-smooth-scrolling-v3-modified`  | Scrolling preset (Smoothfox).                    |
| `smoothfox-sharpen-scrolling`                     | Scrolling preset (Smoothfox).                    |
| `smoothfox-instant-scrolling-simple-adjustment`   | Scrolling preset (Smoothfox).                    |
| `smoothfox-zen-smooth-scrolling`                  | Scrolling preset (Smoothfox).                    |

Not sure which scrolling preset suits your screen? See upstream
[Smoothfox.js](https://github.com/yokoffing/Betterfox/blob/main/Smoothfox.js).
For what each pref does, see the [Betterfox wiki](https://github.com/yokoffing/Betterfox/wiki).

> [!NOTE]
> - **Pick at most one `smoothfox-*` module.** They are alternatives;
>   `mkSettings` fails if you enable more than one.
> - **`user` already includes Fastfox, Securefox and Peskyfox.** Use either
>   `enable = [ "user" ]` _or_ the individual modules, not both.

### Raw prefs

Each module is also exposed as a plain attribute set, if you want to merge it
yourself:

```nix
inputs.betterfox-userjs.lib.betterfox.securefox
```

## Updating

Prefs are synced from upstream Betterfox daily. To pick up the latest:

```sh
nix flake update betterfox-userjs
```

## License

[MIT](LICENSE). Betterfox itself is by [yokoffing](https://github.com/yokoffing/Betterfox).
