{ config, pkgs, lib, ... }:

{
  home = {
    packages = with pkgs; [
      rustup
    ];

    sessionVariables = {
      RUSTUP_HOME = "$HOME/.rustup";
      CARGO_HOME = "$HOME/.cargo";
    };

    sessionPath = [
      "$HOME/.cargo/bin"
    ];
  };
}
