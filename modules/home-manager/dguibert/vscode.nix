{ lib, config, pkgs, inputs, ... }:
{
  options.withVSCode.enable = (lib.mkEnableOption "Enable VSCode config"); # // { default = true; };

  config = lib.mkIf config.withVSCode.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      #mutableExtensionsDir = false;

      # Extensions
      extensions = (with pkgs.vscode-extensions; [
        # Stable
        ms-vscode-remote.remote-ssh
        mhutchie.git-graph
        pkief.material-icon-theme
        oderwat.indent-rainbow
        bierner.markdown-emoji
        bierner.emojisense
        jnoortheen.nix-ide
        vscodevim.vim
        seatonjiang.gitmoji-vscode
      ]);

      # Settings
      userSettings = {
        # General
        "editor.fontSize" = 16;
        "editor.fontFamily" = "'Jetbrains Mono', 'monospace', monospace";
        "terminal.integrated.fontSize" = 14;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace', monospace";
        "window.zoomLevel" = 1;
        "editor.multiCursorModifier" = "ctrlCmd";
        "workbench.startupEditor" = "none";
        "explorer.compactFolders" = false;
        # Whitespace
        "files.trimTrailingWhitespace" = true;
        "files.trimFinalNewlines" = true;
        "files.insertFinalNewline" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        ## Git
        #"git.enableCommitSigning" = true;
        #"git-graph.repository.sign.commits" = true;
        #"git-graph.repository.sign.tags" = true;
        #"git-graph.repository.commits.showSignatureStatus" = true;
        ## Styling
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" = "Default Dark Modern";
        "workbench.preferredLightColorTheme" = "Default Light Modern";
        "workbench.iconTheme" = "material-icon-theme";
        "material-icon-theme.activeIconPack" = "none";
        "material-icon-theme.folders.theme" = "classic";
        # Other
        "telemetry.telemetryLevel" = "off";
        "update.showReleaseNotes" = false;
        # Gitmoji
        "gitmoji.onlyUseCustomEmoji" = true;
        "gitmoji.addCustomEmoji" = [
          {
            "emoji" = "📦 NEW:";
            "code" = ":package: NEW:";
            "description" = "... Add new code/feature";
          }
          {
            "emoji" = "👌 IMPROVE:";
            "code" = ":ok_hand: IMPROVE:";
            "description" = "... Improve existing code/feature";
          }
          {
            "emoji" = "❌ REMOVE:";
            "code" = ":x: REMOVE:";
            "description" = "... Remove existing code/feature";
          }
          {
            "emoji" = "🐛 FIX:";
            "code" = ":bug: FIX:";
            "description" = "... Fix a bug";
          }
          {
            "emoji" = "📑 DOC:";
            "code" = ":bookmark_tabs: DOC:";
            "description" = "... Anything related to documentation";
          }
          {
            "emoji" = "🤖 TEST:";
            "code" = ":robot: TEST:";
            "description" = "... Anything realted to tests";
          }
        ];
      };

      # Keybindings
      keybindings = [
        {
          key = "ctrl+y";
          command = "editor.action.commentLine";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "ctrl+shift+7";
          command = "-editor.action.commentLine";
          when = "editorTextFocus && !editorReadonly";
        }
        {
          key = "ctrl+d";
          command = "workbench.action.toggleSidebarVisibility";
        }
        {
          key = "ctrl+b";
          command = "-workbench.action.toggleSidebarVisibility";
        }
      ];
    };
  };
}
