{
  description = "My zsh flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    dotacat = {
      url = "git+https://gitlab.scd31.com/stephen/dotacat.git";
      flake = false;
    };
    naersk = {
      url = "github:nix-community/naersk";
    };
    fast-syntax-highlighting = {
      url = "github:z-shell/fast-syntax-highlighting";
      flake = false;
    };
    zsh-nix-shell = {
      url = "github:chisui/zsh-nix-shell";
      flake = false;
    };
    nix-zsh-completions = {
      url = "github:spwhitt/nix-zsh-completions";
      flake = false;
    };
    powerlevel10k = {
      url = "github:romkatv/powerlevel10k";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: flake-utils.lib.eachDefaultSystem (system: {
    home-managerModule = { config, lib, pkgs, ... }:
      let
        naersk-lib = inputs.naersk.lib."${system}";
        dotacat = naersk-lib.buildPackage {
          pname = "dotacat";
          root = inputs.dotacat;
        };
      in
      {
        programs.zsh = {
          enable = true;
          enableCompletion = true;
          oh-my-zsh = {
            enable = true;
            plugins = [ "git" "wd" "rust" ];
          };
          plugins = [
            {
              name = "fast-syntax-highlighting";
              file = "fast-syntax-highlighting.plugin.zsh";
              src = inputs.fast-syntax-highlighting;
            }
            {
              name = "zsh-nix-shell";
              file = "nix-shell.plugin.zsh";
              src = inputs.zsh-nix-shell;
            }
            {
              name = "nix-zsh-completions";
              file = "nix-zsh-completions.plugin.zsh ";
              src = inputs.nix-zsh-completions;
            }
          ];
          initExtra =
            ''
              export PATH="$PATH:$HOME/bin"
              source ~/.p10k.zsh
              source ~/.powerlevel10k/powerlevel10k.zsh-theme
              eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
              if [ -f "$HOME/.zvars" ]; then
                source "$HOME/.zvars"
              fi

              if [ -f "$HOME/.localrc.sh" ]; then
                source "$HOME/.localrc.sh"
              fi

              export PATH="${config.home.homeDirectory}/bin:$PATH"

              ${pkgs.fortune}/bin/fortune \
                | ${pkgs.cowsay}/bin/cowsay \
                | ${dotacat}/bin/dotacat
            '';
          shellAliases = {
            cat = "${pkgs.bat}/bin/bat -p";
            ls = "${pkgs.exa}/bin/exa --icons";
            py3 = "nix-shell -p python3 python3.pkgs.matplotlib --run python3";
          };
        };

        home.file = {
          ".powerlevel10k".source = inputs.powerlevel10k;
          ".zprofile".source = ./zprofile;
          ".p10k.zsh".source = ./p10k.zsh;
          "bin/ns" = {
            text = ''
              #!/usr/bin/env bash

              set -- "$\{@/#/nixpkgs#}"
              nix shell "$@"
            '';
            executable = true;
          };
        };
      };
  });
}
