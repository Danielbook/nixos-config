# shells/web.nix
{pkgs}:
pkgs.mkShell {
  packages = [
    pkgs.nodejs_22
    pkgs.pnpm_10
  ];

  shellHook = ''
    export PATH=./node_modules/.bin:$PATH
    echo "🧪 Web dev shell active"
  '';
}
