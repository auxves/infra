{ ... }: {
  _module.args.lib'.mkPostgres =
    { image ? "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065"
    , data
    , user ? "postgres"
    , db
    }: {
      image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

      volumes = [
        "${data}:/var/lib/postgresql/data"
      ];

      environment = {
        POSTGRES_USER = user;
        POSTGRES_DB = db;
        POSTGRES_HOST_AUTH_METHOD = "trust";
      };
    };
}
