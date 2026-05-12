let
  # put the machine you want to deploy to here
  systems = {
    fiona = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXvnCP0qkKcOivPdRmMTpBFS4PEMCbr3nrWyM+YiPgH root@nixos";
    pussinboots = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETLY0fsdcZblCwiJ6dp+oUivx+9gsUcKEW11XL04e+F root@nixos";
  };
  # put which users should also be able to decrypt the secret
  users = {
  };
  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
in {
  "cloudflare.age".publicKeys = allUsers ++ [systems.fiona systems.pussinboots];
  "wireguardConfig.age".publicKeys = allUsers ++ [systems.pussinboots];
}

