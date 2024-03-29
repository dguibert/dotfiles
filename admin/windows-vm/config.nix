{ config, lib, pkgs, ... }:
let

  disk_fun =
    { volume_id ? null
    , block_device ? null
    , file ? null
    , scsi ? null
    , url ? null
    , wwn ? null
    }: {
      inherit volume_id block_device file scsi url wwn;
    };

in
{
  terraform.required_providers.libvirt.source = "dmacvicar/libvirt";
  # Configure the Libvirt provider
  provider.libvirt.uri = "qemu:///system";

  resource.libvirt_volume.win1-qcow2 = {
    name = "win1.qcow2";
    format = "qcow2";
    size = 40 * 1000 * 1000 * 1000;
  };
  # Create a new domain
  resource.libvirt_domain.win1 = rec {
    name = "win1";
    memory = "8192";
    vcpu = 4;

    # This file is usually present as part of the ovmf firmware package in many
    # Linux distributions.
    #firmware = "/usr/share/OVMF/OVMF_CODE.fd"
    firmware = "/run/libvirt/nix-ovmf/OVMF_CODE.secboot.fd";
    nvram = {
      file = "/var/lib/libvirt/qemu/nvram/${name}_VARS.fd";
      template = "/run/libvirt/nix-ovmf/OVMF_VARS.secboot.fd";
      #template = "/tmp/keys/OVMFKeys/OVMF_VARS.fd";
    };
    network_interface = {
      network_name = "default";
      wait_for_lease = true;
    };
    cpu.mode = "host-passthrough";
    machine = "pc-q35-6.1";
    #machine="q35";

    # IMPORTANT
    # Ubuntu can hang if an isa-serial is not present at boot time.
    # If you find your CPU 100% and never is available this is why
    console = [
      {
        type = "pty";
        target_port = "0";
        target_type = "serial";
      }
      {
        type = "pty";
        target_type = "virtio";
        target_port = "1";
      }
    ];
    graphics = {
      type = "spice";
      listen_type = "address";
      autoport = true;
    };
    boot_device = {
      dev = [ "cdrom" "hd" ];
    };
    video.type = "qxl";

    disk = [
      #{ volume_id = "${"$"}{libvirt_volume.win1-qcow2.id}"; } # known only after apply
      (disk_fun {
        #     #   file="/tmp/SW_DVD9_Win_Pro_10_20H2.12_64BIT_French_Pro_Ent_EDU_N_MLF_X22-87968.ISO";
        file = "/tmp/Win10_21H2_French_x64.iso";
      })
      (disk_fun {
        #url="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso";
        url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso";
      })
      (disk_fun {
        volume_id = "\${ libvirt_volume.win1-qcow2.id }";
      })
    ];
    tpm = {
      backend_type = "emulator";
      backend_version = "2.0";
    };
  };
}
