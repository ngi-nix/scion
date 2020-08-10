{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "scion";
  version = "2020-03";

  src = fetchFromGitHub {
    owner = "netsec-ethz";
    repo = "scion";
    rev = "v2020.03";
    sha256 = "03g2b11kvb1dnp2z5py7r6j7jz97hvmla5qk7z8l52msx4z45azf";
  };

  goPackagePath = "github.com/netsec-ethz/scion";
  vendorSha256 = "06vr6920n4461xzam4xgry26k2s71lihlb22ngm13mrf1i26bwg4";

  doCheck = false;
}
