{ lib, config, pkgs, inputs, ... }:
{
  options.withEmacs.enable = lib.mkEnableOption "Enable emacs config";

  config = lib.mkIf config.withEmacs.enable {
    programs.bash.shellAliases.e = "emacsclient -s server -t -a \"\"";
    programs.bash.shellAliases.eg = "emacsclient -s server -n -c -a \"\"";
    home.sessionVariables.ALTERNATE_EDITOR = "";
    home.sessionVariables.EDITOR = "emacsclient -s server -t"; # $EDITOR opens in terminal
    home.sessionVariables.VISUAL = "emacsclient -s server -c -a emacs"; # $VISUAL opens in GUI mode

    home.file.".emacs.d".source = inputs.chemacs;
    home.file.".emacs.default/init.el".source = "${inputs.nixpkgs}/emacs/emacs.d/init.el";
    home.file.".emacs.default/site-lisp".source = "${inputs.nixpkgs}/emacs/emacs.d/site-lisp";
    home.file.".emacs-profiles.el".text = ''
      (("default" . ((user-emacs-directory . "~/.emacs.default")
                  (server-name . "server")
                  ))
      ("dev"     . ((user-emacs-directory . "~/nur-packages/emacs/emacs.d")
                  (server-name . "dev")
                  ))
      )
    '';
    programs.emacs.enable = true;
    # config = lib.mkIf config.withGui.enable {
    programs.emacs.package = pkgs.my-emacs;
    services.emacs.enable = true;
    services.emacs.socketActivation.enable = true;
    systemd.user.services.emacs.Service.Environment = [
      "COLORTERM=truecolor"
    ];
    home.packages = with pkgs; [
      # my-emacs # 20211026 installed via programs.emacs.package
      my-texlive
    ];
    #home.file.".emacs.d/private.el".source = pkgs.sopsDecrypt_ "${inputs.nur_dguibert}/emacs/private-sec.el" "data";
  };

}
