# Headless Rice Module
#
# A minimal server configuration with no desktop environment.
# Provides essential CLI tools for server management and development.
#
# Features:
# - No GUI/compositor
# - Tmux for terminal multiplexing
# - Neovim for editing
# - Zsh with Starship prompt
# - Essential CLI utilities
# - Optimized for SSH access

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  
in {
  config = mkIf (cfg.enable && cfg.rice == "headless") {
    
    # System-level packages for headless server
    environment.systemPackages = with pkgs; [
      # Essential CLI tools
      tmux
      screen
      
      # Editors
      neovim
      vim
      nano
      
      # Shell utilities
      zsh
      starship
      fzf
      ripgrep
      fd
      bat
      exa
      
      # System monitoring
      htop
      btop
      iotop
      nethogs
      
      # Network tools
      curl
      wget
      rsync
      openssh
      
      # Development tools
      git
      gh  # GitHub CLI
      
      # File management
      ranger  # Terminal file manager
      mc      # Midnight Commander
      
      # Compression
      zip
      unzip
      gzip
      bzip2
      xz
      
      # Text processing
      jq
      yq
      
      # Misc utilities
      tree
      ncdu
      tldr
    ];
    
    # Home-manager configuration for headless user
    home-manager.users.${cfg.user} = { pkgs, ... }: {
      
      # Tmux configuration
      programs.tmux = {
        enable = true;
        terminal = "screen-256color";
        historyLimit = 10000;
        keyMode = "vi";
        mouse = true;
        
        extraConfig = ''
          # Set prefix to Ctrl-a (like screen)
          unbind C-b
          set -g prefix C-a
          bind C-a send-prefix
          
          # Split panes using | and -
          bind | split-window -h
          bind - split-window -v
          unbind '"'
          unbind %
          
          # Reload config
          bind r source-file ~/.tmux.conf \; display "Config reloaded!"
          
          # Switch panes using Alt-arrow without prefix
          bind -n M-Left select-pane -L
          bind -n M-Right select-pane -R
          bind -n M-Up select-pane -U
          bind -n M-Down select-pane -D
          
          # Status bar
          set -g status-style 'bg=#1a1b26 fg=#7aa2f7'
          set -g status-left '[#S] '
          set -g status-right '%Y-%m-%d %H:%M '
          
          # Pane borders
          set -g pane-border-style 'fg=#414868'
          set -g pane-active-border-style 'fg=#7aa2f7'
        '';
      };
      
      # Neovim configuration
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        
        extraConfig = ''
          " Basic settings
          set number
          set relativenumber
          set expandtab
          set tabstop=2
          set shiftwidth=2
          set smartindent
          set mouse=a
          
          " Search settings
          set ignorecase
          set smartcase
          set hlsearch
          set incsearch
          
          " UI settings
          set termguicolors
          set cursorline
          set signcolumn=yes
          
          " Clipboard
          set clipboard=unnamedplus
          
          " Color scheme (Tokyo Night inspired)
          colorscheme desert
        '';
      };
      
      # Zsh shell configuration
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        
        shellAliases = {
          # Modern replacements
          ls = "exa --icons";
          ll = "exa -l --icons";
          la = "exa -la --icons";
          cat = "bat";
          
          # Git shortcuts
          gs = "git status";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git log --oneline --graph";
          
          # System shortcuts
          ".." = "cd ..";
          "..." = "cd ../..";
          
          # Tmux shortcuts
          ta = "tmux attach";
          tl = "tmux list-sessions";
          
          # NixOS shortcuts
          rebuild = "sudo nixos-rebuild switch";
          update = "sudo nixos-rebuild switch --upgrade";
        };
        
        initExtra = ''
          # FZF integration
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          
          # Better history
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_FIND_NO_DUPS
          setopt HIST_SAVE_NO_DUPS
        '';
      };
      
      # Starship prompt
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        
        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_status"
            "$nix_shell"
            "$line_break"
            "$character"
          ];
          
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };
          
          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
          };
          
          git_branch = {
            symbol = " ";
          };
          
          nix_shell = {
            symbol = " ";
          };
        };
      };
      
      # Git configuration
      programs.git = {
        enable = true;
        userName = "Bastion User";
        userEmail = "user@bastion.local";
        
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          core.editor = "nvim";
        };
      };
      
      # FZF fuzzy finder
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      
      # Bat (better cat)
      programs.bat = {
        enable = true;
        config = {
          theme = "TwoDark";
        };
      };
      
      # Ranger file manager
      programs.ranger = {
        enable = true;
      };
    };
    
    # Set default shell to zsh
    users.users.${cfg.user}.shell = pkgs.zsh;
    programs.zsh.enable = true;
    
    # Enable SSH server for remote access
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;  # Can be disabled for key-only auth
      };
    };
  };
}
