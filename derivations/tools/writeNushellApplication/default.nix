{ lib
, unstable
, writeTextFile
, linkFarm
}:

let
  # It might be nicer to write a nix function that translates nix expressions directly to nushell
  # expressions. But since nix and nu both understand json, using that as an intermediary format is
  # way easier.
  toNu = v: "(\"${lib.escape ["\"" "\\"] (builtins.toJSON v)}\" | from json)";

  makeBinPathArray = pkgs: lib.pipe pkgs [
    (map (lib.getOutput "bin"))
    (builtins.filter (x: x != null))
    (map (output: output + "/bin"))
  ];

  makeNuLibPathArray = pkgs: lib.pipe pkgs [
    (builtins.filter (drv: drv ? nuModule))
    (map (lib.getOutput "out"))
    (builtins.filter (x: x != null))
    (map (output: output + "/lib"))
  ];
in

{
  /*
    The name of the script to write.
    Type: String
   */
  name
, /*
  The shell script's text, not including a shebang.
  Type: String
   */
  text
, /*
  Inputs to add to the nu script's `$env.PATH` at runtime.
  Type: [String|Derivation]
   */
  runtimeInputs ? [ ]
, /*
  Extra environment variables to set at runtime.
  Type: AttrSet
   */
  runtimeEnv ? null
, /*
  `stdenv.mkDerivation`'s `meta` argument.
  Type: AttrSet
   */
  meta ? { }
, /*
  `stdenv.mkDerivation`'s `passthru` argument.
  Type: AttrSet
   */
  passthru ? { }
, /*
  The `checkPhase` to run. Defaults to `nu-check`.

  The script path will be given as `$target` in the `checkPhase`.

  Type: String
   */
  checkPhase ? null
, /*
   Extra arguments to pass to `stdenv.mkDerivation`.

   :::{.caution}
   Certain derivation attributes are used internally,
   overriding those could cause problems.
   :::

   Type: AttrSet
   */
  derivationArgs ? { }
,
}:
writeTextFile {
  inherit name meta passthru derivationArgs;
  executable = true;
  destination = "/bin/${name}";
  allowSubstitutes = true;
  preferLocalBuild = false;
  text = ''
    #!${unstable.nushell}/bin/nu -n
  '' + lib.optionalString (runtimeEnv != null) ''

    load-env ${toNu runtimeEnv}
  '' + lib.optionalString (runtimeInputs != [ ]) ''

    $env.PATH = ${toNu (makeBinPathArray runtimeInputs)} ++ $env.PATH

    const NU_LIB_DIRS = [ ${builtins.concatStringsSep " " (
      builtins.map (s: "'${s}'") (makeNuLibPathArray runtimeInputs)
    )} ]
  '' + ''

    ${text}
  '';

  checkPhase =
    if checkPhase == null then ''
      runHook preCheck
      ${unstable.nushell}/bin/nu --commands "nu-check --debug '$target'"
      runHook postCheck
    ''
    else checkPhase;
}
