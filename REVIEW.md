A basic overview of the what should be reviewed.

### Prerequisites
- Setup an AS on SCIONLab (https://www.scionlab.org/)
  - Instructions are outlined on SCIONLab (https://docs.scionlab.org/content/config/create_as.html)

### Notes
- `identifier` is just an identifier, I haven't found the naming for it officially if there even is one
  - To determine the value of `identifier`, unpack the configuration tarball and look under `gen/ISD*/AS*/`
  - There should be a border router (`br*`) and control service directory (`cs*`) with the same suffix
  - The suffix is the value for `identifier`
- Webapp [tests] are broken due to local IA detection

### Sample Commands
See `tests/` (`scionlab-*` files) and the SCIONLab website (https://www.scionlab.org/)

### Sample Configuration
```nix
{
  ...
  inputs.scion = { type = "github"; owner = "ngi-nix"; repo = "scion"; };
  ...
  imports = [
    inputs.scion.nixosModules.scionlab
    inputs.scion.nixosModules.scion-apps
  ];

  nixpkgs.overlays = [ inputs.scion.overlay ];
  services.scionlab = {
    enable = true;

    configTarball = inputs.scion + "/18-ffaa.tar.gz";
    identifier = "18-ffaa_1_d91-1";
  };
  services.scion.apps = {
    webapp.enable = true;
    bwtester.enable = true;
  };
}
```
