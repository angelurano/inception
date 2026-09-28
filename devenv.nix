{ pkgs, config, ... }:
{
  packages = with pkgs; [
    hadolint
  ];

  env = {
    DATA_PATH = "${config.env.DEVENV_ROOT}/.data";
  };

  enterShell = "";
}
