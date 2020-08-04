{ stdenv
, fetchurl
, python
}:

stdenv.mkDerivation {
  pname = "scionlab";
  version = "2.0.5";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/netsec-ethz/scionlab/86ddeaac6ac9039f6d209276f65675de418898a6/scionlab/hostfiles/scionlab-config";
    sha256 = "04nqyvk1ds5vfjdgyj43s9g6z1pgk6bjkrjmxa7saafgfjyvarjn";
  };

  unpackPhase = ''
    runHook preUnpack
    cp $src scionlab-config
    runHook postUnpack
  '';

  prePatch = ''
    sed -i 's@/usr/bin/env.*@${python}/bin/python@' scionlab-config
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp scionlab-config $out/bin
    runHook postInstall
  '';
}
