{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "rains";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "netsec-ethz";
    repo = "rains";
    rev = "v${version}";
    sha256 = "1r6126y7fps0358irf6fq0h6bjd9535mxc931d36pxg0xmqfj39v";
  };

  goPackagePath = "github.com/netsec-ethz/rains";
  vendorSha256 = "18r123rc3zz9x86s5savngg5g33y4lzwvfpdx4cskydavl2vk7sf";
}
