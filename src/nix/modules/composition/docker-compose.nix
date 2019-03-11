/*

   This is a composition-level module.

   It defines the low-level options that are read by arion, like
    - build.dockerComposeYaml

   It declares options like
    - docker-compose.services

 */
{ pkgs, lib, config, ... }:
let
  evalService = name: modules: (pkgs.callPackage ../../eval-service.nix {} { inherit name modules; inherit (config) host; }).config.build.service;

in
{
  options = {
    build.dockerComposeYaml = lib.mkOption {
      type = lib.types.package;
      description = "A derivation that produces a docker-compose.yaml file for this composition.";
    };
    build.dockerComposeYamlText = lib.mkOption {
      type = lib.types.string;
      description = "The text of build.dockerComposeYaml.";
    };
    docker-compose.raw = lib.mkOption {
      type = lib.types.attrs;
      description = "Nested attribute set that will be turned into the docker-compose.yaml file, using Nix's toJSON builtin.";
    };
    docker-compose.services = lib.mkOption {
      default = {};
      type = with lib.types; attrsOf (coercedTo unspecified (a: [a]) (listOf unspecified));
      description = "A attribute set of service configurations. A service specifies how to run an image. Each of these service configurations is specified using modules whose options are described in the Service Options section.";
    };
  };
  config = {
    build.dockerComposeYaml = pkgs.writeText "docker-compose.yaml" config.build.dockerComposeYamlText;
    build.dockerComposeYamlText = builtins.toJSON (config.docker-compose.raw);

    docker-compose.raw = {
      version = "3";
      services = lib.mapAttrs evalService config.docker-compose.services;
    };
  };
}
