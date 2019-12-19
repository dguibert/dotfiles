{ pkgs, config, lib, ...}: {
  users.users.fvigilant = {
    isNormalUser = true;
    uid = 1502;
    group = "fvigilant";
    extraGroups [ "sftponly" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCr+IH7K9d0v/ralMa8j8DiitN+jNyMhgi11e9iFxWtRYXshwg3QiJZlTvUqdy4nsYWPlNqQ/8fsgQ8rXZWNNMG/sT2CBun3FgynrBEt8FrDwdnBv4tSLodPQUzX3EmqoMGAdcgtBm9l8EnlfuUdA1GiWg4StX7KvNxbzqo5nhSrkTirNxZ0dGU/N8HiBMojs91XOb3o0zv07gNGnfE3yo+cpeZYNA/6HzFyyxdiVMvEgTqtTjk7seHgA8FQm4OSL92jfC87YuPO7Yed/BQs0c76TkvPFcHMeCbyeOL5yjcDfvPoF1Xk4ICNf5U+Rp13hguOEjYHq75AI+2DINB8qfL A453204@DESKTOP-RHJT8PA"
      "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
    ];
    shell = "/run/current-system/sw/bin/nologin";
  };
  users.groups.fvigilant.gid = 1502;
  users.groups.sftponly = {};
}
