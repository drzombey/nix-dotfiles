{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  gst_all_1,
  ipu7-camera-hal,
  libdrm,
  libva,
}:

# GStreamer-Source, die auf libcamhal aufsetzt. Das ist das Element, das
# v4l2-relayd in seine Pipeline steckt.
stdenv.mkDerivation {
  pname = "icamerasrc-${ipu7-camera-hal.ipuVersion}";
  version = "unstable-2025-12-26";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "icamerasrc";
    rev = "4fb31db76b618aae72184c59314b839dedb42689"; # tag 20251226_1140_191_PTL_PV_IoT
    hash = "sha256-BYURJfNz4D8bXbSeuWyUYnoifozFOq6rSfG9GBKVoHo=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    ipu7-camera-hal
    libdrm
    libva
  ];

  preConfigure = ''
    export CHROME_SLIM_CAMHAL=ON
  '';

  # Ohne gstdrmformat kompiliert das gegen Kernel >= 6.18 nicht.
  configureFlags = [ "--enable-gstdrmformat=yes" ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-error"
    # gstcameradeinterlace.cpp findet gst/video/video.h sonst nicht
    "-I${gst_all_1.gst-plugins-base.dev}/include/gstreamer-1.0"
  ];

  enableParallelBuilding = true;

  passthru = { inherit (ipu7-camera-hal) ipuVersion; };

  meta = {
    description = "GStreamer plugin for MIPI cameras behind the Intel IPU7";
    homepage = "https://github.com/intel/icamerasrc";
    license = lib.licenses.lgpl21Plus;
    platforms = [ "x86_64-linux" ];
  };
}
