{ config, pkgs, ... }: {
    home.file = {
        ".1password/agent.sock".source = config.lib.file.mkOutOfStoreSymlink "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };
}