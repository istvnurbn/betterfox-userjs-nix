{
  description = "yokoffing/Betterfox prefs as Nix";

  inputs = {};

  outputs = {self}: let
    # auto-discover every .json in the prefs dir
    jsonNames =
      builtins.filter
      (n: builtins.match ".+\\.json" n != null)
      (builtins.attrNames (builtins.readDir ./prefs));
    stripExt = n: builtins.substring 0 ((builtins.stringLength n) - 5) n;
  in {
    lib = rec {
      # e.g. betterfox.securefox, betterfox.smoothfox-smooth-scrolling, ...
      betterfox = builtins.listToAttrs (map
        (n: {
          name = stripExt n;
          value = builtins.fromJSON (builtins.readFile (./prefs + "/${n}"));
        })
        jsonNames);

      # later modules win, overrides win last;
      # pick exactly ONE smoothfox-* option -- they are alternatives
      mkSettings = {
        enable ? ["securefox" "peskyfox"],
        overrides ? {},
      }:
        builtins.foldl' (acc: name: acc // betterfox.${name}) {} enable
        // overrides;
    };
  };
}
