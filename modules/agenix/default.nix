{
  inputs,
  ...
}:
{
  age = {
    secrets = {
      cloudflare.file = ./../../secrets/cloudflare.age;
      wireguardCredentials.file = ./../../secrets/wireguardConfig.age;
    };
  };
}

