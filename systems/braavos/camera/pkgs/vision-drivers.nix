{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

# intel_cvs — die "Camera Vision Sensing"-Firmware-Schnittstelle. Auf Panther
# Lake hängt der ov08x40 hinter usbio-i2c und seine Stromversorgung an einer
# USBIO-GPIO, die von der CVS-Firmware verwaltet wird. Ohne dieses Modul
# bekommt der Sensor nie Strom, das I2C-Probe läuft in -ETIMEDOUT und
# ov08x40 bindet an kein Gerät.
stdenv.mkDerivation {
  pname = "intel-vision-drivers";
  version = "unstable-2026-05-07";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "vision-drivers";
    rev = "a8d772f261bc90376944956b7bfd49b325ffa2f2";
    hash = "sha256-zOvCZKGwOGT9kcJiefzx/duHqR0V8PYhNbqsMHkH1r4=";
  };

  # Default ist rgbcamera_pwrup_host=1, d.h. der Host macht das Power-Sequencing
  # selbst. Auf PTL ist das falsch — dort muss die CVS-Firmware die USBIO-GPIO
  # schalten, sonst bleibt der Sensor dunkel.
  postPatch = ''
    substituteInPlace drivers/misc/icvs/intel_cvs_update.c \
      --replace-fail \
        'host_identifiers.field.rgbcamera_pwrup_host = 1;' \
        'host_identifiers.field.rgbcamera_pwrup_host = 0;'
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  enableParallelBuilding = true;

  preInstall = ''
    sed -i -e "s,INSTALL_MOD_DIR=,INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=," Makefile
  '';

  installTargets = [ "modules_install" ];

  meta = {
    description = "Intel Camera Vision Sensing (intel_cvs) kernel driver";
    homepage = "https://github.com/intel/vision-drivers";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
