{ pkgs, config, lib, ... }: {
  users.users.rdolbeau = {
    isNormalUser = true;
    uid = 1501;
    group = "rdolbeau";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZMjCvizoNrDojOFOMazBBgFfyFrBieu5DFiiFgY4VJHPtOchSPAF4K+Q8hgbFU1cP8q4NoncPSS2BEp3FAtiuUZyHRV72yUlx12BOdlVpAtpjtphr2CZMPhzo89k1yQ6W2sHP52igF9DWeMTj9lLgpjjsCbA8qjT3cdLUiDh0anrFQjzgGRemhuxxsUV8L0XB4TDfg0/qSOrrKNLX5NnuEghpJOak3NS/2WDz6QGQbqdUKlKxDcHuaLK1FJRSvJIUFk23EUv8TfwL3B8u9FMblFFM5BUHelNpNNobI7LfTJB/Qv2YVEWjFXirSJEf7U0MCeLDu9hrKPGu1X8kmWc7 dolbeau@c2sbe"
      "cert-authority ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCT6I73vMHeTX7X990bcK+RKC8aqFYOLZz5uZhwy8jtx/xEEbKJFT/hggKADaBDNkJl/5141VUJ+HmMEUMu+OznK2gE8IfTNOP1zLXD6SjOxCa55MvnyIiXVMAr7R0uxZWy28IrmcmSx1LY5Mx8V13mjY3mp3LVemAy9im+vj6FymjQqgPMg6dHq+aQCeHpx22GWHYEq2ghqEsRpmIBBwwaVaEH8YIjcqZwDcp273SzBrgMEW44ndul5bvh85c71vjm7kblU/BxwBeLFMJFnXYTPxF2JjxhCSMlHBH9hqQjQ8vwaQev6XaJ5TpHgiT3nLAxCyBBgvnfwM7oq6bjHjuyToKFzUsFH6YVsK+/NjagZ5YKlV7vK0o2oF12GrQvwWwa6DUM+LdUNmSX4l4Xq8lB5YbJ5NK0pHRRdzCZL5kPuV+CkXRAHoUSj/pLUqkqGRL70NMtLIYmQbj/l7BZ4PQNP9zKLB4f5pk02A25DbPVfoW2DFL0DRfSF1L8ZDsAVhzUaRKSBZZ4wG231gvB6pCMTpeuvC9+Z/OmYkiXEOn34Qdjx8Bfi7XWKm/PnSgP7dM9Tcf3I0hvymvP6eZ8BjeriKHUE7b3s1aMQz9I4ctpbCNT5S16XMQZtdO0HZ+nn4Exhy0FHmdCwPXu/VBEBYcy7UpI4vyb1xiz13KVX/5/oQ== CA key for my accounts at home"
    ];
  };
  users.groups.rdolbeau.gid = 1501;
}
