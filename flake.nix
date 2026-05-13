{
  description = "My NixOS config";


  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    #homemanager for reproducable configs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #qylock lockscreen/sddm
    qylock = {
      url = "github:Darkkal44/qylock";
      flake = false;
    };

    #my neovim config
    nvim-config = {
      url = "github:Benjabeans/nvim";
      flake = false;
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };



  };



  outputs = inputs@{ self, nixpkgs, home-manager, qylock, nvim-config, caelestia-shell,... }:
  let
    username = "benjabeans";
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit qylock username;
      };

      modules = [
        ./configuration.nix

	home-manager.nixosModules.home-manager
	{
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

	  home-manager.extraSpecialArgs = {
  	    inherit inputs nvim-config username;
 	  };

          home-manager.users.${username} ={
            imports = [
	       caelestia-shell.homeManagerModules.default
              ./home.nix
            ];        
	  };
        }
      ];
    };
  };
}
