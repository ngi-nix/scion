A basic overview of the what should be reviewed.

### Prerequisites
- Setup an AS on SCIONLab (https://www.scionlab.org/)
  - Instructions are outlined on SCIONLab (https://docs.scionlab.org/content/config/create_as.html)

### Notes
- `identifier` is just an identifier, I haven't found the naming for it officially if there even is one
  - To determine the value of `identifier`, unpack the configuration tarball and look under `gen/ISD*/AS*/`
  - There should be a border router (`br*`) and control service directory (`cs*`) with the same suffix
  - The suffix is the value for `identifier`
- Webapp [tests] are broken due to local IA detection so the functionality of the webapp is heavily compromised
- Most commands for SCION use the dispatcher socket to communicate which owned by the `scionlab` user.
  - So in order to run any of the commands, it's recommended to run them under a superuser or via `sudo[ -i]`

### Sample Commands
See SCIONLab website (https://docs.scionlab.org/content/apps/)

### Sample Test Workflow
```bash
#! /usr/bin/env bash

git clone https://github.com/ngi-nix/scion
cd scion
# edit flake.nix to change configTarball and identifier
nix build -L .#nixosConfigurations.scionlab.config.system.build.vm
result/bin/run-scionlab-vm

# login with scionlab as both the username and password into i3 (not pantheon)
# verify a network connection exists
ping -c 3 https://google.com

# check that scionapps-webapp works (hosted at 127.0.0.1:8000)
# check that scionapps-bwtester works (journalctl -r -u scion-bwtester)
## Note that the service is expected to fail at least once due to timing problems waiting for the dispatcher (manually restart if it doesn't automatically do so)

# Verify connection works
sudo scmp echo -c 4 -remote '20-ffaa:0:1404,[0.0.0.0]'
# Test some apps
sudo scion-imagefetcher -s '17-ffaa:0:1102,[192.33.93.166]:42002' -output imagefetcher.jpg
sudo feh imagefetcher.jpg # check image
sudo scion-sensorfetcher -s '17-ffaa:0:1102,[192.33.93.177]:42003'

# For more commands see the SCIONLab website referred under `Sample Commands`
```
