{ config, pkgs, ... }:
{
  programs.git.enable = true;
  programs.git.package = if pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform then pkgs.gitFull else pkgs.gitMinimal;
  programs.git.userName = "David Guibert";
  programs.git.userEmail = "david.guibert@gmail.com";
  programs.git.aliases.files = "ls-files -v --deleted --modified --others --directory --no-empty-directory --exclude-standard";
  programs.git.aliases.wdiff = "diff --word-diff=color --unified=1";
  programs.git.aliases.bd = "!git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:iso8601)%09%(refname)'";
  programs.git.aliases.bdr = "!git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:iso8601)%09%(refname)' refs/remotes/$1";
  programs.git.aliases.bs = "branch -v -v";
  programs.git.aliases.df = "diff";
  programs.git.aliases.dn = "diff --name-only";
  programs.git.aliases.dp = "diff --no-ext-diff";
  programs.git.aliases.ds = "diff --stat -w";
  programs.git.aliases.dt = "difftool";
  #programs.git.ignores
  programs.git.iniContent.clean.requireForce = true;
  programs.git.iniContent.rerere.enabled = true;
  programs.git.iniContent.rerere.autoupdate = true;
  programs.git.iniContent.rebase.autosquash = true;
  programs.git.iniContent.credential.helper = [
    # https://github.com/languitar/pass-git-helper
    # maybe neetd to define ~/.config/pass-git-helper/git-pass-mapping.ini
    "!type pass-git-helper >/dev/null && pass-git-helper $@"
    "store"
    "cache --timeout 86400"
  ];
  programs.git.iniContent."url \"software.ecmwf.int\"".insteadOf = "ssh://git@software.ecmwf.int:7999";
  programs.git.iniContent.color.branch = "auto";
  programs.git.iniContent.color.diff = "auto";
  programs.git.iniContent.color.interactive = "auto";
  programs.git.iniContent.color.status = "auto";
  programs.git.iniContent.color.ui = "auto";
  programs.git.iniContent.diff.tool = "vimdiff";
  programs.git.iniContent.diff.renames = "copies";
  programs.git.iniContent.merge.tool = "vimdiff";
  programs.git.iniContent.pull.ff = "only"; # fast-forward only

  programs.git.iniContent.notes.rewrite.amend = true;
  programs.git.iniContent.notes.rewrite.rebase = true;
  programs.git.iniContent.notes.rewriteRefs = "refs/notes/commits";

  #home.packages = with pkgs; [
  #  gitAndTools.git-remote-gcrypt
  #  (gitAndTools.git-crypt.override { git = config.programs.git.package; })
  #];


}
