{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.bastion.services.ollama.enable {
    services.ollama = {
      enable = true;
      acceleration = if config.bastion.services.ollama.enableGPU then "cuda" else null;
      host = "127.0.0.1";
      port = 11434;
    };

    # Pre-pull configured models
    systemd.services.ollama-pull-models = {
      description = "Pull Ollama models";
      after = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      script = ''
        # Wait for Ollama to be ready
        sleep 10
        
        ${concatMapStringsSep "\n" (model: ''
          ${pkgs.ollama}/bin/ollama pull ${model} || true
        '') config.bastion.services.ollama.models}
      '';
    };

    # NVIDIA GPU support if enabled
    hardware.nvidia-container-toolkit.enable = mkIf config.bastion.services.ollama.enableGPU true;
  };
}
