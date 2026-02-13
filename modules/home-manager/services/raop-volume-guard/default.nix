{ pkgs, ... }:
let
  # Maximum initial volume (%) for RAOP/AirPlay sinks when they connect.
  # Sinks that initialize above this threshold get capped automatically.
  maxVolume = 40;

  raopVolumeGuard = pkgs.writeShellScript "raop-volume-guard" ''
    pactl="${pkgs.pulseaudio}/bin/pactl"

    # Cap any existing RAOP sinks on startup
    $pactl list short sinks 2>/dev/null | while IFS=$'\t' read -r index name _rest; do
      [[ "$name" == raop_sink.* ]] && $pactl set-sink-volume "$index" ${toString maxVolume}%
    done

    # Watch for new sinks and cap RAOP ones
    $pactl subscribe | while read -r line; do
      if [[ "$line" == *"'new'"* && "$line" == *"sink"* ]]; then
        sleep 0.5
        # Extract sink index from "Event 'new' on sink #175"
        if [[ "$line" =~ \#([0-9]+) ]]; then
          sink_index="''${BASH_REMATCH[1]}"
          sink_name=$($pactl list short sinks | while IFS=$'\t' read -r i n _r; do
            [[ "$i" == "$sink_index" ]] && echo "$n" && break
          done)
          [[ "$sink_name" == raop_sink.* ]] && $pactl set-sink-volume "$sink_index" ${toString maxVolume}%
        fi
      fi
    done
  '';
in
{
  systemd.user.services.raop-volume-guard = {
    Unit = {
      Description = "Cap RAOP/AirPlay sink volume on connection";
      After = [ "pipewire-pulse.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = toString raopVolumeGuard;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "pipewire-pulse.service" ];
    };
  };
}
