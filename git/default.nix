{...}: {
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "tigheni ";
        email = "oussama.adame12@gmail.com";
      };
      pull.rebase = true;
    };
    ignores = [".direnv/"];
  };
}