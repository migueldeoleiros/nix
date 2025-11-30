{ config, pkgs, vars, ... }:

{
  home.shellAliases = {
    #basic aliases
    tmux="tmux -2";
    sudosu="sudo -Es";
    sudo="sudo ";
    poweroff="sudo poweroff";
    mv="mv -i";
    #rm="rm -i";
    cp="cp -i";
    df="df -h";
    ".."="cd ..";
    "..."="cd ../..";
    vim="nvim";
    diff="diff --color";
    e="emacsclient --tty";
    
    #use trash-cli instead of rm
    rm="trash-put";
    
    #improved find
    find="fd";
    
    #use ranger to move around directories
    rn=". ranger";
    
    #process check
    psuser="ps -u miguel";
    
    # eza instead of ls
    ls="eza -s extension --group-directories-first";
    ll="eza -ls extension --group-directories-first";
    lla="eza -las extension --group-directories-first";
    la="eza -as extension --group-directories-first";
    
    #open programs
    op="xdg-open";
    
    #git aliases
    gitlog="git log --decorate --color=always --pretty=tformat:\"%C(auto)%h %ce %s %d\" --graph";
    
    #check the weather in Coruna
    weather="curl wttr.in/Coruna";

    #arch linux
    pin="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S" ;
    pre="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns";
    parus="paru -Slq | fzf --multi --preview 'paru -Si {1}' | xargs -ro paru -S" ;
    parur="paru -Qq | fzf --multi --preview 'paru -Qi {1}' | xargs -ro sudo paru -Rns";
  };
}
