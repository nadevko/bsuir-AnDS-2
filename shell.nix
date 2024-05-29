with import <nixpkgs> { };
mkShell {
  nativeBuildInputs = [ clang-tools ];
  NIX_LD = "${stdenv.cc.libc_bin}/bin/ld.so";
}
