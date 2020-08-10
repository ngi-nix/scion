with nixpkgsFor.${system};
with self.packages.${system};
with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
{

  scionapps-webapp = makeTest {
    nodes.webapp = { ... }: {
      imports = builtins.attrValues self.nixosModules;
      nixpkgs.overlays = [ self.overlay ];

      services.scionlab.enable = true;
      services.scionlab.configTarball = ./18-ffaa.tar.gz;
      services.scionlab.v = "18-ffaa_1_d91-1";

      services.scion.apps.webapp.enable = true;
    };

    testScript = ''
      start_all()

      webapp.wait_for_unit("scion-dispatcher")
      webapp.wait_for_unit("scion-webapp")
      webapp.wait_for_open_port(8000)
      webapp.succeed("[[ $(systemctl is-failed scion-webapp.service) == active ]]")

      webapp.shutdown()
    '';
  };

}
