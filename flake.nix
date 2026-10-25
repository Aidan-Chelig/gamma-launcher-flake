{
  description = "S.T.A.L.K.E.R. GAMMA Launcher";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    gamma-launcher = {
      url = "github:Mord3rca/gamma-launcher/v3.1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, gamma-launcher }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f system
        );

      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            nixpkgs.lib.getName pkg == "unrar";
        };

      mkLauncher = pkgs:
        let
          py = pkgs.python312Packages;
        in
        py.buildPythonApplication {
          pname = "gamma-launcher";
          version = "3.1";
          src = gamma-launcher;

          pyproject = true;

          build-system = [
            py.setuptools
          ];

          dependencies = with py; [
            beautifulsoup4
            cloudscraper
            gitpython
            platformdirs
            py7zr
            requests
            tenacity
            tqdm
            unrar
          ];

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          # Upstream tests are not needed for the
          # initial packaging attempt.
          doCheck = false;

          postFixup = ''
            wrapProgram "$out/bin/gamma-launcher" \
              --set UNRAR_LIB_PATH \
                "${pkgs.unrar}/lib/libunrar.so" \
              --prefix PATH : \
                "${pkgs.lib.makeBinPath [
                  pkgs.git
                  pkgs.p7zip
                  pkgs.unrar
                ]}"
          '';

          meta = {
            description =
              "Linux launcher for STALKER GAMMA";
            homepage =
              "https://github.com/Mord3rca/gamma-launcher";
            license = pkgs.lib.licenses.gpl3Only;
            mainProgram = "gamma-launcher";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = mkPkgs system;
          launcher = mkLauncher pkgs;
        in
        {
          default = launcher;
          gamma-launcher = launcher;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program =
            "${self.packages.${system}.default}/bin/gamma-launcher";
        };
      });
    };
}
