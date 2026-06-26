{ pkgs, host, ... }:

let
  hasNvidia = host.hasNvidia or false;

  btopWithGpuLibraries = pkgs.btop.override {
    rocmSupport = true;
    cudaSupport = hasNvidia;
  };

  gpuTools = [
    pkgs.rocmPackages.rocm-smi
    pkgs.nvtopPackages.amd
  ] ++ pkgs.lib.optionals hasNvidia [
    pkgs.nvtopPackages.nvidia
  ];
in

{
  # Intel GPU support and CPU wattage in btop need extra privileges.
  # Nix store binaries cannot be mutated with setcap, so expose btop through
  # the standard NixOS wrapper path instead.
  security.wrappers.btop = {
    source = "${btopWithGpuLibraries}/bin/btop";
    capabilities = "cap_perfmon,cap_dac_read_search+ep";
    owner = "root";
    group = "root";
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
  ] ++ gpuTools;
}
