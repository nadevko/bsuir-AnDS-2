with import <nixpkgs> { };
mkShell {
  NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [ stdenv.cc.cc ];
  NIX_LD = "${stdenv.cc.libc_bin}/bin/ld.so";
}
