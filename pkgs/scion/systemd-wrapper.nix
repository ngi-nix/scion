{ stdenv
, fetchurl
, bash
}:

stdenv.mkDerivation {
  pname = "scion-systemd-wrapper";
  version = "2.0.0";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/netsec-ethz/scion-builder/18fdc761ead022db0db3ef79d80b3741fb96cf35/scion-systemd-wrapper";
    sha256 = "063q5mzyis26lgaqqnyn90w5dm9b2k0i8pdb5m0cqmf7lpp32wqh";
  };

  unpackPhase = ''
    runHook preUnpack
    cp $src scion-systemd-wrapper
    runHook postUnpack
  '';

  prePatch = ''
    sed -i 's@/bin/bash@${bash}/bin/bash@' scion-systemd-wrapper
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp scion-systemd-wrapper $out/bin
    runHook postInstall
  '';
}
