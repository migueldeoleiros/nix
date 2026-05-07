{ config, pkgs, lib, ... }:

let
  cfg = config.miguel.emacs;

  emacsPackage = pkgs.emacs.pkgs.withPackages (epkgs: [ epkgs.jinx ]);

  tangleEmacsConfig = pkgs.writeShellApplication {
    name = "tangle-emacs-config";
    runtimeInputs = [ cfg.package ];
    text = ''
      set -euo pipefail

      org_file="$HOME/${cfg.configDir}/${cfg.orgFile}"

      if [ ! -f "$org_file" ]; then
        echo "Emacs config org file not found: $org_file" >&2
        exit 1
      fi

      emacs --batch \
        --eval "(require 'org)" \
        --eval "(org-babel-tangle-file \"$org_file\")"
    '';
  };
in
{
  options.miguel.emacs = {
    enable = lib.mkEnableOption "Miguel's Emacs setup" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = emacsPackage;
      description = "Emacs package used for launching and tangling the external config.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/migueldeoleiros/emacs-conf";
      description = "External Emacs config repository to clone when missing.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = ".emacs.d";
      description = "Home-relative directory where the external Emacs config repo lives.";
    };

    orgFile = lib.mkOption {
      type = lib.types.str;
      default = "emacsConf.org";
      description = "Org file inside the external repo to tangle.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cfg.package
      tangleEmacsConfig

      # Runtime helpers used by the Lisp config.
      emacs-all-the-icons-fonts
      enchant
      hunspell
      hunspellDicts.en_US
      hunspellDicts.es_ES
      hunspellDicts.pt_PT
      mupdf
      direnv
    ];

    home.activation.cloneEmacsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      target="$HOME/${cfg.configDir}"

      if [ ! -e "$target" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone ${lib.escapeShellArg cfg.repo} "$target"
      elif [ ! -d "$target/.git" ]; then
        echo "Emacs config target exists but is not a git repo: $target" >&2
        exit 1
      fi
    '';

    home.activation.tangleEmacsConfig = lib.hm.dag.entryAfter [ "cloneEmacsConfig" ] ''
      $DRY_RUN_CMD ${tangleEmacsConfig}/bin/tangle-emacs-config
    '';
  };
}
