{...}: {
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "Abdennour Zahaf";
        email = "zfnori@gmail.com";
      };
      pull.rebase = true;
    };
    ignores = [".direnv/"];
  };
}
