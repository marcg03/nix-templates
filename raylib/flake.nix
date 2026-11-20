{
  description = "A raylib game (desktop + web)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        name = "my-game"; # the one place to name the project (binary, packages, make's NAME)
        version = "0.1.0";

        # Only what the Makefile uses, so other files (README, ...) don't trigger rebuilds.
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./Makefile
            ./src
            ./assets
            ./web
          ];
        };

        # emcc needs a writable cache; start from nixpkgs' prebuilt one (precompiled libc etc.).
        useEmscriptenCache = dir: ''
          export EM_CACHE="${dir}"
          if [ ! -d "$EM_CACHE" ]; then
            mkdir -p "$(dirname "$EM_CACHE")"
            cp -r ${pkgs.emscripten}/share/emscripten/cache "$EM_CACHE"
            chmod -R u+w "$EM_CACHE"
          fi
        '';

        # `make` + `make install`, linked against nixpkgs' raylib.
        desktop = pkgs.stdenv.mkDerivation {
          pname = name;
          inherit version src;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.raylib ];
          makeFlags = [
            "NAME=${name}"
            "PREFIX=${placeholder "out"}"
            "ASSETS_DIR=${placeholder "out"}/share/${name}/assets"
          ];
          enableParallelBuilding = true;
          meta.mainProgram = name;
        };

        # `make web`: the folder of static files (index.html .js .wasm .data).
        web = pkgs.stdenvNoCC.mkDerivation {
          pname = "${name}-web";
          inherit version src;
          nativeBuildInputs = [ pkgs.emscripten ];
          env.RAYLIB_SRC = "${pkgs.raylib.src}"; # same raylib version as the desktop build
          preBuild = useEmscriptenCache "$TMPDIR/emcache";
          makeFlags = [ "NAME=${name}" ];
          buildFlags = [ "web" ];
          enableParallelBuilding = true;
          installPhase = ''
            runHook preInstall
            cp -r build/web $out
            runHook postInstall
          '';
          allowedReferences = [ ]; # the site must not depend on anything in the store
        };

        # `nix run '.#web'`: serve the web build on http://localhost:8000
        serveWeb = pkgs.writeShellApplication {
          name = "${name}-serve";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            echo "Serving on http://localhost:8000"
            exec python3 -m http.server 8000 -d ${web}
          '';
        };
      in
      {
        packages = {
          default = desktop;
          inherit desktop web;
        };

        apps.web = flake-utils.lib.mkApp { drv = serveWeb; } // {
          meta.description = "Serve the web build on http://localhost:8000";
        };

        # Everything both builds need, for fast incremental `make` / `make web` / `make serve`.
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            desktop
            web
          ];
          packages = [
            pkgs.python3
            pkgs.clang-tools
          ]
          ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.gdb;
          NAME = name;
          RAYLIB_SRC = "${pkgs.raylib.src}";
          shellHook = useEmscriptenCache "\${XDG_CACHE_HOME:-$HOME/.cache}/emscripten-${pkgs.emscripten.version}";
        };
      }
    );
}
