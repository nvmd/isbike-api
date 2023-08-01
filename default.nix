{ nixpkgs ? <nixpkgs>
, compilerVersion ? "ghc928"
}:
let
  pkgs = import nixpkgs {};
  forCompiler = pkgs.haskell.packages.${compilerVersion};
in
forCompiler.developPackage {
  root = ./.;
  modifier = drv:
    pkgs.haskell.lib.addBuildTools drv (with forCompiler; [
      cabal-install
      cabal2nix
      hoogle
      hspec-discover
      haskell-language-server
    ] ++ (with pkgs; [
      rnix-lsp
      nixpkgs-fmt
    ]));
}
