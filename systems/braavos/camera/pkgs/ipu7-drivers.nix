{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

# Out-of-tree IPU7-Treiber von Intel. Der Kernel bringt in
# drivers/staging/media/ipu7 zwar intel-ipu7 und intel-ipu7-isys mit, aber
# *kein* PSYS — und ohne /dev/ipu7-psys0 hat die Userspace-HAL keinen Zugriff
# auf die Hardware-ISP. Dieses Paket installiert nach updates/, was depmod
# gegenüber kernel/ bevorzugt, ersetzt die Staging-Module also mit.
#
# Gebaut wird mit BUILD_INTEL_IPU_ACPI=1. Das zieht drivers/media/platform/intel
# mit hinein (ipu-acpi, ipu-acpi-pdata, ipu-acpi-common) und ist auf dieser
# Maschine nicht optional:
#
# Ohne diesen Pfad ermittelt ISYS seine Sensoren über ipu_bridge. Die trägt bei
# Panther Lake aber einen IVSC-Knoten (ACPI INTC10E1) zwischen Sensor und IPU in
# den fwnode-Graph ein, und für dieses Gerät registriert kein Treiber ein
# v4l2-Subdevice — intel_cvs macht ausschließlich Power und Ownership. Der
# Async-Notifier von ISYS wartet dann ewig, der Sensor taucht nie im Media-Graph
# auf, und die HAL meldet "No sensors available".
#
# Mit den ACPI-Modulen bekommt ISYS stattdessen statische Plattformdaten und
# instanziiert den Sensor direkt — der IVSC-Umweg entfällt.
stdenv.mkDerivation {
  pname = "ipu7-drivers";
  version = "unstable-2026-02-09";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu7-drivers";
    rev = "a88b19096a738d0708742a78d6540d6d4a3021ff";
    hash = "sha256-ggtTkirwGItAuywxCsawmbVLRnW9F4JmqQn3rXlTzSQ=";
  };

  # Seit Linux 7.1 lehnt bus_add_device() Geräte auf einem nicht registrierten
  # Bus ab. Der PSYS-Treiber registriert seinen "intel-ipu7-psys"-Bus aber nie,
  # deshalb schlägt das Probe mit -22 fehl und /dev/ipu7-psys0 entsteht nicht.
  # Upstream: https://github.com/intel/ipu7-drivers/pull/87 (noch offen)
  patches = [ ./0001-ipu7-psys-register-bus.patch ];

  # Der NixOS-Kernel setzt CONFIG_VIDEO_LT6911UXE=m (der Treiber ist inzwischen
  # mainline), womit die IS_ENABLED-Guards hier greifen — der zugehörige
  # pdata-Header existiert aber nur in Intels eigenem Kernel-Tree. Der Chip ist
  # eine HDMI-nach-CSI-Bridge und für eine Laptop-Webcam ohne Belang.
  postPatch = ''
    substituteInPlace \
      include/media/serdes-pdata.h \
      drivers/media/platform/intel/ipu-acpi.c \
      drivers/media/platform/intel/ipu-acpi-pdata.c \
      --replace-fail 'IS_ENABLED(CONFIG_VIDEO_LT6911UXE)' '0'
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Als Kommandozeilen-Variable gesetzt, damit make sie über MAKEFLAGS auch an
  # das Sub-Make weiterreicht — sowohl beim Bauen als auch bei modules_install,
  # sonst würden die ipu-acpi-Module gar nicht erst installiert.
  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "BUILD_INTEL_IPU_ACPI=1"
  ];

  enableParallelBuilding = true;

  preInstall = ''
    sed -i -e "s,INSTALL_MOD_DIR=,INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=," Makefile
  '';

  installTargets = [ "modules_install" ];

  meta = {
    description = "Intel IPU7 kernel drivers (ISYS + PSYS)";
    homepage = "https://github.com/intel/ipu7-drivers";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
