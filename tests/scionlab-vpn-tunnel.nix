with nixpkgsFor.${system};
with self.packages.${system};
with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
{

  scionlab-vpn-tunnel = makeTest {
    nodes.machine = { pkgs, ... }: {
      imports = builtins.attrValues self.nixosModules;
      nixpkgs.overlays = [ self.overlay ];

      environment.systemPackages = [ pkgs.iproute ];

      services.scionlab.enable = true;
      services.scionlab.configTarball = ./18-ffaa.tar.gz;
      services.scionlab.v = "18-ffaa_1_d91-1";
    };

    testScript = ''
      start_all()

      machine.wait_for_unit("openvpn-scionlab")
      machine.succeed("[[ $(systemctl is-failed openvpn-scionlab.service) == active ]]")
      machine.succeed("ip address show dev tun0")
      machine.succeed("scmp echo -c 4 -remote '20-ffaa:0:1404,[0.0.0.0]'")

      machine.shutdown()
    '';
  };

}
