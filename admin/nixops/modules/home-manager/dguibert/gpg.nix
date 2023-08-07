{ lib, config, ... }:
{
  services.gpg-agent.pinentryFlavor =
    if config.withGui.enable
    #then "gnome3" # No Gcr System Prompter available : Gnome Key Ring prompter tool ?
    then "curses"
    else "curses";

  services.gpg-agent.enable = true;
  services.gpg-agent.enableSshSupport = true;
  # https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/
  home.file.".gnupg/gpg.conf".text = ''
    # Avoid information leaked
    no-emit-version
    no-comments
    export-options export-minimal

    # Displays the long format of the ID of the keys and their fingerprints
    keyid-format 0xlong
    with-fingerprint

    # Displays the validity of the keys
    list-options show-uid-validity
    verify-options show-uid-validity

    # Limits the algorithms used
    personal-cipher-preferences AES256
    personal-digest-preferences SHA512
    default-preference-list SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed

    cipher-algo AES256
    digest-algo SHA512
    cert-digest-algo SHA512
    compress-algo ZLIB

    disable-cipher-algo 3DES
    weak-digest SHA1

    s2k-cipher-algo AES256
    s2k-digest-algo SHA512
    s2k-mode 3
    s2k-count 65011712
  '';
}
