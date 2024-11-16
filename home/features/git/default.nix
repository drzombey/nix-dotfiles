{ pkgs, ... }: {

  home.packages = with pkgs; [
    delta
  ];

  home.file = {
    "projects/.gitconfig".text = ''
      [user]
        name = Tim Lange
        email = odysnutzer@googlemail.com
    '';
  };

  home.file = {
    "work/.gitconfig".text = ''
      [user]
        name = Tim Lange
        email = t.lange@shopware.com
    '';
  };

  home.file = {
    ".ssh/allowed_signers".text = ''
      * namespaces=\"git\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCYPCL4vzkj8saRLC3MRgUrZGpKU3I2Po6XK0V6NsBS4RIb0HauOlinZEdCEdbFqGsCEpOZqIsjyiZmcecyTyK4Y6xeDFAyyatW6GV2wyQFdWJw/q6jWU+QCgWtG3SgfE4gKIKWZNbFB1L+g5PLkclLHy1s8AqauJUcxBnu1wdW/SlBl/HLuzKlEcXmRswv2esV1WVh3WJyNJCKhGL4qnfDS+BwRMCNfqsYzoY8xQdNT+SgmoM+rHiotEW8Tyy0MNLSrzk+QPZuHgNBWJHnc4j2Fv0s52CLRK34UFogDFrYutBEiCNpj4E8ABsSr/Ji4M5Jp+Hx11+kE7e/JctNSN28J4DGkVyDRjxINb5jmIbTEzYDcJKge3xPAH8lMEqCIYuFw4MSvwk8ptnbOPf113YVUMYSxeB1PcaLDp+vD6pjCcA3WwB19djdZH2iVOULWZYzkIl60qu0n322ZcAv2Ek0v+aMjpovRrC9Y/DsM2S08I7YtSN5Fs8CcNkimJQ/rs=
    '';
  };

  programs.git = {
    enable = true;
    package = pkgs.git;

    userName = "Tim Lange";
    userEmail = "t.lange@shopware.com";

    signing.key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCYPCL4vzkj8saRLC3MRgUrZGpKU3I2Po6XK0V6NsBS4RIb0HauOlinZEdCEdbFqGsCEpOZqIsjyiZmcecyTyK4Y6xeDFAyyatW6GV2wyQFdWJw/q6jWU+QCgWtG3SgfE4gKIKWZNbFB1L+g5PLkclLHy1s8AqauJUcxBnu1wdW/SlBl/HLuzKlEcXmRswv2esV1WVh3WJyNJCKhGL4qnfDS+BwRMCNfqsYzoY8xQdNT+SgmoM+rHiotEW8Tyy0MNLSrzk+QPZuHgNBWJHnc4j2Fv0s52CLRK34UFogDFrYutBEiCNpj4E8ABsSr/Ji4M5Jp+Hx11+kE7e/JctNSN28J4DGkVyDRjxINb5jmIbTEzYDcJKge3xPAH8lMEqCIYuFw4MSvwk8ptnbOPf113YVUMYSxeB1PcaLDp+vD6pjCcA3WwB19djdZH2iVOULWZYzkIl60qu0n322ZcAv2Ek0v+aMjpovRrC9Y/DsM2S08I7YtSN5Fs8CcNkimJQ/rs=";
    signing.signByDefault = true;

    includes = [
      { 
        path = "~/projects/.gitconfig";
        condition = "gitdir:~/projects/";
      }
      { 
        path = "~/work/.gitconfig";
        condition = "gitdir:~/work/";
      }
    ];

    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.default = "simple";
      fetch.prune = true;

      gpg.format = "ssh";
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      promptToReturnFromSubprocess = false;
      git = {
        overrideGpg = true;
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };
}
