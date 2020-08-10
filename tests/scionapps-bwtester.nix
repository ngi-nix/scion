with nixpkgsFor.${system};
with self.packages.${system};
with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
{

  scionapps-bwtester = makeTest {
    nodes.server = { ... }: {
      imports = builtins.attrValues self.nixosModules;
      nixpkgs.overlays = [ self.overlay ];

      services.scionlab.enable = true;
      services.scionlab.configTarball = ./18-ffaa.tar.gz;
      services.scionlab.v = "18-ffaa_1_d91-1";

      services.scion.apps.bwtester.enable = true;
    };

    testScript = ''
      start_all()

      server.wait_for_unit("sicon-dispatcher")
      server.wait_for_unit("scion-bwtester")
      # server.wait_for_file("/run/shm/dispatcher/scion")
      server.wait_for_open_port(30100)
      server.succeed("[[ $(systemctl is-failed scion-bwtester.service) == active ]]")

      server.shutdown()
    '';
  };

}
