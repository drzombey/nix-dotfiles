{
  lib,
  stdenv,
  fetchFromGitHub,

  cmake,
  pkg-config,

  expat,
  ipu7-camera-bins,
  jsoncpp,
  libtool,
  gst_all_1,
  libdrm,

  # ipu7x = Lunar Lake, ipu75xa = Panther Lake, ipu8 = Wildcat Lake
  ipuVersion ? "ipu75xa",
}:

# libcamhal: übernimmt die Bayer-Frames von ISYS und lässt sie über PSYS durch
# die Hardware-ISP laufen (Debayer, AE/AWB/AF, Denoise) — das, was bei einer
# USB-Webcam die Firmware in der Kamera selbst macht.
stdenv.mkDerivation {
  pname = "${ipuVersion}-camera-hal";
  version = "unstable-2026-02-09";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu7-camera-hal";
    rev = "b1f6ebef12111fb5da0133b144d69dd9b001836c";
    hash = "sha256-fz3ALh2F57NWYU6D1XuKfAzES2754GfZr1xQBwfkG3U=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    expat
    ipu7-camera-bins
    jsoncpp
    libtool
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libdrm
  ];

  postPatch = ''
    substituteInPlace src/platformdata/JsonParserBase.h \
      --replace-fail '<jsoncpp/json/json.h>' '<json/json.h>'
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    # CAMERA_DEFAULT_CFG_PATH wird daraus abgeleitet: die Tuning-Dateien
    # (.aiqb, gcss, sensors/*.json) landen unter $out/etc/camera/${ipuVersion}.
    "-DCMAKE_INSTALL_SYSCONFDIR=etc"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DBUILD_CAMHAL_ADAPTOR=ON"
    "-DBUILD_CAMHAL_PLUGIN=ON"
    "-DIPU_VERSIONS=${ipuVersion}"
    "-DUSE_STATIC_GRAPH=ON"
    "-DUSE_STATIC_GRAPH_AUTOGEN=ON"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  enableParallelBuilding = true;

  postFixup = ''
    for lib in $out/lib/*.so; do
      patchelf --add-rpath "${ipu7-camera-bins}/lib" $lib
    done
  '';

  passthru = { inherit ipuVersion; };

  meta = {
    description = "Intel IPU7 camera HAL (userspace ISP)";
    homepage = "https://github.com/intel/ipu7-camera-hal";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
