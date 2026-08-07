{
  lib,
  stdenv,
  fetchFromGitHub,
  autoPatchelfHook,
  expat,
  zlib,
}:

# IPU7-Firmware + proprietäre Intel-Bibliotheken (AIQ/IA-Imaging). Reine
# Binärauslieferung, deshalb nur entpacken und die RPATHs zurechtbiegen.
stdenv.mkDerivation {
  pname = "ipu7-camera-bins";
  version = "unstable-2026-02-09";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu7-camera-bins";
    rev = "403c67db6b279dd02752f11db6a34552f31a3ac5";
    hash = "sha256-Sj1jBOOegTk8tdmDN06MYEa7KmutnfSb5AEhXhoQkSc=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    expat
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp --no-preserve=mode --recursive lib include $out/

    runHook postInstall
  '';

  postFixup = ''
    # Die .so.<major> liegen ohne unversionierten Symlink daneben — den
    # braucht der Linker beim Bauen der HAL.
    for lib in $out/lib/lib*.so.*; do
      lib=''${lib##*/}
      target=$out/lib/''${lib%.*}
      if [ ! -e "$target" ]; then
        ln -s "$lib" "$target"
      fi
    done

    for pcfile in $out/lib/pkgconfig/*.pc; do
      substituteInPlace $pcfile --replace-quiet 'prefix=/usr' "prefix=$out"
    done
  '';

  meta = {
    description = "Intel IPU7 firmware and proprietary image processing libraries";
    homepage = "https://github.com/intel/ipu7-camera-bins";
    license = lib.licenses.issl;
    sourceProvenance = [ lib.sourceTypes.binaryFirmware ];
    platforms = [ "x86_64-linux" ];
  };
}
