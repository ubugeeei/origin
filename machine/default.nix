let
  envOr = name: default:
    let
      value = builtins.getEnv name;
    in
    if value != "" then value else default;

  optionalEnv = name:
    let
      value = builtins.getEnv name;
    in
    if value == "" then null else value;

  envBoolOr = name: default:
    let
      value = builtins.getEnv name;
    in
    if value == "" then
      default
    else if builtins.elem value [
      "1"
      "true"
      "yes"
      "on"
    ] then
      true
    else if builtins.elem value [
      "0"
      "false"
      "no"
      "off"
    ] then
      false
    else
      default;

  username = envOr "ORIGIN_USERNAME" "localuser";
  homeDirectory = envOr "ORIGIN_HOME" "/Users/${username}";
  localHostName = envOr "ORIGIN_LOCAL_HOSTNAME" "workstation";
in
{
  system = envOr "ORIGIN_SYSTEM" "aarch64-darwin";
  username = username;
  homeDirectory = homeDirectory;
  workspaceRoot = envOr "ORIGIN_WORKSPACE_ROOT" "${homeDirectory}/Source";
  appNamespace = envOr "ORIGIN_APP_NAMESPACE" "dev.origin";

  networking = {
    computerName = envOr "ORIGIN_COMPUTER_NAME" "Managed Mac";
    hostName = envOr "ORIGIN_HOSTNAME" localHostName;
    localHostName = localHostName;
  };

  git = {
    userName = optionalEnv "ORIGIN_GIT_USER_NAME";
    userEmail = optionalEnv "ORIGIN_GIT_USER_EMAIL";
    githubUser = optionalEnv "ORIGIN_GITHUB_USER";
  };

  security = {
    touchIdSudoAuth = envBoolOr "ORIGIN_TOUCH_ID_SUDO_AUTH" false;
  };
}
