{
  pkgs ? import <nixpkgs> { overlays = [ (import <bsuir-tex/nixpkgs>) ]; },
}:
with pkgs;
mkShell rec {
  name = "AnDS-2";

  vscode-settings = writeText "settings.json" (
    builtins.toJSON { "clangd.path" = "${pkgs.clang-tools}/bin/clangd"; }
  );

  packages = [
    zig
    zls
  ];

  shellHook = ''
    mkdir .vscode &>/dev/null
    cp ${vscode-settings} .vscode/settings.json
  '';
}
