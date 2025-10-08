{
  lib,
  inputs,
  pkgs,
  ...
}: let
  walls = inputs.walls;
  
  # Helper function to get wallpapers from a category
  getWallpapersFromCategory = category: "${walls}/${category}";
  
  # Available wallpaper categories from dharmx/walls
  categories = [
    "abstract" "anime" "apocalypse" "centered" "chillop" "cold" "decay"
    "digital" "dreamcore" "flowers" "fogsmoke" "geometry" "gruvbox"
    "industrial" "lightbulb" "logo" "manga" "minimal" "monochrome"
    "mountain" "nature" "outrun" "painting" "paper" "pixel" "solarized"
  ];
  
  # Create wallpaper switching script
  wallpaper-switch = pkgs.writeShellScriptBin "wallpaper-switch" ''
    #!/usr/bin/env bash
    
    WALLS_DIR="${walls}"
    
    show_help() {
      echo "Usage: wallpaper-switch [OPTION] [CATEGORY/FILE]"
      echo ""
      echo "Options:"
      echo "  -l, --list          List available categories"
      echo "  -r, --random [CAT]  Set random wallpaper from category (or all if no category)"
      echo "  -s, --set FILE      Set specific wallpaper file"
      echo "  -c, --category CAT  Set random wallpaper from specific category"
      echo "  -h, --help          Show this help"
      echo ""
      echo "Available categories:"
      ${lib.concatStringsSep "\n" (map (cat: "echo \"  ${cat}\"") categories)}
    }
    
    list_categories() {
      echo "Available wallpaper categories:"
      ${lib.concatStringsSep "\n" (map (cat: "echo \"  ${cat}\"") categories)}
    }
    
    set_wallpaper() {
      local file="$1"
      if [[ -f "$file" ]]; then
        ${pkgs.swww}/bin/swww img "$file" --transition-type fade --transition-duration 1
        echo "Wallpaper set to: $file"
      else
        echo "Error: File not found: $file"
        exit 1
      fi
    }
    
    random_from_category() {
      local category="$1"
      local category_dir="$WALLS_DIR/$category"
      
      if [[ ! -d "$category_dir" ]]; then
        echo "Error: Category '$category' not found"
        exit 1
      fi
      
      local wallpaper=$(find "$category_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | shuf -n 1)
      
      if [[ -n "$wallpaper" ]]; then
        set_wallpaper "$wallpaper"
        echo "Category: $category"
      else
        echo "Error: No wallpapers found in category '$category'"
        exit 1
      fi
    }
    
    random_from_all() {
      local all_wallpapers=()
      ${lib.concatStringsSep "\n" (map (cat: ''
        while IFS= read -r -d "" file; do
          all_wallpapers+=("$file")
        done < <(find "$WALLS_DIR/${cat}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) -print0 2>/dev/null)
      '') categories)}
      
      if [[ ''${#all_wallpapers[@]} -eq 0 ]]; then
        echo "Error: No wallpapers found"
        exit 1
      fi
      
      local random_wallpaper="''${all_wallpapers[RANDOM % ''${#all_wallpapers[@]}]}"
      set_wallpaper "$random_wallpaper"
      
      # Show which category it's from
      local category=$(basename "$(dirname "$random_wallpaper")")
      echo "Category: $category"
    }
    
    case "$1" in
      -l|--list)
        list_categories
        ;;
      -r|--random)
        if [[ -n "$2" ]]; then
          random_from_category "$2"
        else
          random_from_all
        fi
        ;;
      -s|--set)
        if [[ -n "$2" ]]; then
          set_wallpaper "$2"
        else
          echo "Error: Please specify a wallpaper file"
          exit 1
        fi
        ;;
      -c|--category)
        if [[ -n "$2" ]]; then
          random_from_category "$2"
        else
          echo "Error: Please specify a category"
          exit 1
        fi
        ;;
      -h|--help|"")
        show_help
        ;;
      *)
        # If it's just a category name without flags
        if [[ -d "$WALLS_DIR/$1" ]]; then
          random_from_category "$1"
        else
          echo "Error: Unknown option or category '$1'"
          echo "Use 'wallpaper-switch --help' for usage information"
          exit 1
        fi
        ;;
    esac
  '';
in {
  options.wallpaper = {
    default = lib.mkOption {
      type = lib.types.path;
      default = ./wallpaper.jpg;
      description = "Path to default wallpaper";
    };
    
    categories = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = lib.listToAttrs (map (cat: lib.nameValuePair cat (getWallpapersFromCategory cat)) categories);
      readOnly = true;
      description = "Available wallpaper categories from dharmx/walls";
    };
  };
  
  config = {
    home.packages = [ wallpaper-switch ];
  };
}
