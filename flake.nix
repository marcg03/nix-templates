{
  description = "Project templates";

  outputs =
    { self }:
    {
      templates = {
        raylib = {
          path = ./raylib;
          description = "raylib game in C: desktop + web (WASM) builds, Makefile, dev shell";
          welcomeText = ''
            # raylib game
            - Set `name` in flake.nix (binary name, packages).
            - `git add -A`, then `direnv allow` (or `nix develop`).
            - `make run`: desktop. `make serve`: web on http://localhost:8000.
            - `nix build '.#web'`: `result/` is the folder to upload anywhere.
          '';
        };
        default = self.templates.raylib;
      };
    };
}
