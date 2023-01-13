{ config, lib, inputs, outputs, ... }:

let
  cfg = config.server-3Dprinting;
in
{
  options.server-3Dprinting.enable = lib.mkOption {
    default = false;
    description = "Whether to enable services for 3D printing";
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    services.klipper = {
      enable = true;
      firmwares = {
        mcu = {
          enable = true;
          # Run klipper-genconf to generate this
          configFile = ./server-3Dprinting/config;
          # Serial port connected to the microcontroller
          serial = "/dev/serial/by-id/usb-Klipper_stm32f401xc_0E004A000851383531393138-if00";
        };
      };
      settings = {
        printer = {
          kinematics = "corexy";
          max_velocity = 300;
          max_accel = 3500;
          max_z_velocity = 15;
          max_z_accel = 45;
          square_corner_velocity = 5.0;
        };
        mcu.serial = "/dev/serial/by-id/usb-Klipper_stm32f401xc_0E004A000851383531393138-if00";
        # https://docs.fluidd.xyz/configuration/initial_setup
        virtual_sdcard.path = "/gcodes";
        display_status = { };
        pause_resume = { };
        stepper_x = {
          step_pin = "PC0";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "PC1";
          enable_pin = "!PA8";
          rotation_distance = 40;
          microsteps = 128;
          endstop_pin = "^PB4";
          #full_steps_per_rotation = 200; # 1.8 stepper motor
          position_endstop = 120;
          position_max = 120;
          homing_speed = 20;
          homing_retract_dist = 5;
          homing_positive_dir = true;
        };
        "tmc2209 stepper_x" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 0;
          interpolate = true;
          run_current = 0.85;
          hold_current = 0.5;
          sense_resistor = 0.110;
          stealthchop_threshold = 999999; #250            # Set to 999999 to turn stealthchop on, and 0 to use spreadcycle
        };
        stepper_y = {
          step_pin = "PC14";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "PC13";
          enable_pin = "!PC15";
          rotation_distance = 40;
          microsteps = 128;
          endstop_pin = "^PC8";
          #full_steps_per_rotation = 200; # 1.8 stepper motor
          position_endstop = 120;
          position_max = 120;
          homing_speed = 20;
          homing_retract_dist = 5;
          homing_positive_dir = true;
        };
        "tmc2209 stepper_y" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 2;
          interpolate = true;
          run_current = 0.85;
          hold_current = 0.5;
          sense_resistor = 0.110;
          stealthchop_threshold = 999999; #250            # Set to 999999 to turn stealthchop on, and 0 to use spreadcycle
        };
        stepper_z = {
          step_pin = "PB9";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "!PB8";
          enable_pin = "!PC2";
          rotation_distance = 8; # for T8x8 lead screan
          #rotation_distance = 2; # for T8x2 lead screan
          microsteps = 64;
          endstop_pin = "^PB1";
          position_endstop = -0.225; # must be defined?
          position_max = 120;
          position_min = -1.5;
          homing_speed = 10; # max 100
          second_homing_speed = 10; # max 100
          homing_retract_dist = 3.0;
        };
        "tmc2209 stepper_z" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 1;
          interpolate = false;
          run_current = 0.37; # For V0.1 spec NEMA17 w/ integrated lead screw
          hold_current = 0.35;
          sense_resistor = 0.110;
          #stealthchop_threshold = 500; #250            # Set to 999999 to turn stealthchop on, and 0 to use spreadcycle
        };
        extruder = {
          step_pin = "PB2";
          dir_pin = "PA15"; # Add ! if moving opposite direction
          enable_pin = "!PD2";
          full_steps_per_rotation = 200; # 1.8 degree motor
          # See calibrating rotation_distance on extruders doc
          #rotation_distance = 21.54087; # abs black
          rotation_distance = 22.18709; # pla dark grau esun
          gear_ratio = "50:10"; # For Mini Afterburner
          microsteps = 16;
          nozzle_diameter = 0.400;
          filament_diameter = 1.750;
          heater_pin = "PC6";
          sensor_type = "Generic 3950";
          sensor_pin = "PC4";
          control = "pid"; # Do PID calibration
          # M106 S64
          # PID_CALIBRATE HEATER=extruder TARGET=245
          # pid_Kp=20.292 pid_Ki=1.313 pid_Kd=78.378
          # pid_Kp=20.431 pid_Ki=1.273 pid_Kd=81.977
          pid_Kp = 20.292;
          pid_Ki = 1.313;
          pid_Kd = 78.378;
          min_temp = 0;
          max_temp = 270;
          min_extrude_temp = 170;
          max_extrude_only_distance = 780.0;
          max_extrude_cross_section = 0.8;
          pressure_advance = 0.075; # For ABS 15*0.005 See tuning pressure advance doc
          pressure_advance_smooth_time = 0.040;
        };
        "tmc2209 extruder" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 3;
          interpolate = false;
          run_current = 0.35;
          hold_current = 0.2;
          sense_resistor = 0.110;
          stealthchop_threshold = 0;
        };
        heater_bed = {
          heater_pin = "PC7";
          ### Sensor Types
          ###   "EPCOS 100K B57560G104F"
          ###   "ATC Semitec 104GT-2"
          ###   "NTC 100K beta 3950" (Keenovo Heater Pad)
          ###   "Honeywell 100K 135-104LAG-J01"
          ###   "NTC 100K MGB18-104F39050L32"
          ###   "AD595"
          ###   "PT100 INA826"
          sensor_type = "Generic 3950";
          sensor_pin = "PC5";
          smooth_time = 3.0;
          #max_power=0.6;                         # Only need this for 100w pads
          min_temp = 0;
          max_temp = 120;
          control = "pid"; # Do PID calibration
          # PID_CALIBRATE HEATER=heater_bed TARGET=100
          # pid_Kp=50.563 pid_Ki=2.654 pid_Kd=240.808
          # pid_Kp=50.657 pid_Ki=2.502 pid_Kd=256.449
          pid_kp = 50.563;
          pid_ki = 2.654;
          pid_kd = 240.808;
        };
        "heater_fan hotend_fan" = {
          # FAN1 Connector
          pin = "PA13";
          max_power = 1.0;
          kick_start_time = 0.5;
          heater = "extruder";
          heater_temp = 50.0;
          ###fan_speed: 1.0                         # You can't PWM the delta fan unless using blue wire
        };

        fan = {
          # Print Cooling Fan: FAN0 Connector
          pin = "PA14";
          max_power = 1.0;
          kick_start_time = 0.5;
          ###depending on your fan, you may need to increase or reduce this value
          ###if your fan will not start
          #off_below="0";.13
          cycle_time = 0.010;
        };
        idle_timeout.timeout = 1800;

        input_shaper.shaper_freq_x = 72.972972; #90*3/3.7;
        input_shaper.shaper_freq_y = 90; #90*3/3;
        input_shaper.shaper_type = "ei";

        board_pins.aliases =
          "    # EXP1 header
             EXP1_1=<5V>,  EXP1_3=<RST>, EXP1_5=PA7,  EXP1_7=PA4,  EXP1_9=PA5,
             EXP1_2=<GND>, EXP1_4=PC3,   EXP1_6=PC11, EXP1_8=PC10, EXP1_10=PA6,

             # EXP2 header
             EXP2_1=<5V>,  EXP2_3=PB7, EXP2_5=PB14, EXP2_7=PB12, EXP2_9=PC12,
             EXP2_2=<GND>, EXP2_4=PB6, EXP2_6=PB13, EXP2_8=PB15, EXP2_10=PC9,

             # EXP3 header
             EXP3_1=PC9,  EXP3_3=PC10, EXP3_5=PC11, EXP3_7=PB12, EXP3_9=<GND>,
             EXP3_2=PC12, EXP3_4=PB14, EXP3_6=PB13, EXP3_8=PB15, EXP3_10=<5V>
             # Pins EXP3_4, EXP3_8, EXP3_6 are also MISO, MOSI, SCK of bus \"spi2\"
        ";

        safe_z_home = {
          home_xy_position = "120,120";
          speed = 50.0;
          z_hop = 5;
        };
        ### Tool to help adjust bed leveling screws. One may define a
        ### [bed_screws] config section to enable a BED_SCREWS_ADJUST g-code
        ### command.
        bed_screws = {
          screw1 = "60,5";
          screw1_name = "front screw";
          screw2 = "5,115";
          screw2_name = "back left";
          screw3 = "115,115";
          screw3_name = "back right";
        };
        #######################################################################
        ###	Macros
        #######################################################################
        "gcode_macro PAUSE" = {
          description = "Pause the actual running print";
          rename_existing = "PAUSE_BASE";
          # change this if you need more or less extrusion
          variable_extrude = 1.0;
          gcode =
            ''    ##### read E from pause macro #####
              {% set E = printer["gcode_macro PAUSE"].extrude|float %}
              ##### set park positon for x and y #####
              # default is your max posion from your printer.cfg
              {% set x_park = printer.toolhead.axis_maximum.x|float - 5.0 %}
              {% set y_park = printer.toolhead.axis_maximum.y|float - 5.0 %}
              ##### calculate save lift position #####
              {% set max_z = printer.toolhead.axis_maximum.z|float %}
              {% set act_z = printer.toolhead.position.z|float %}
              {% if act_z < (max_z - 2.0) %}
                  {% set z_safe = 2.0 %}
              {% else %}
                  {% set z_safe = max_z - act_z %}
              {% endif %}
              ##### end of definitions #####
              PAUSE_BASE
              G91
              {% if printer.extruder.can_extrude|lower == 'true' %}
                G1 E-{E} F2100
              {% else %}
                {action_respond_info("Extruder not hot enough")}
              {% endif %}
              {% if "xyz" in printer.toolhead.homed_axes %}
                G1 Z{z_safe} F900
                G90
                G1 X{x_park} Y{y_park} F6000
              {% else %}
                {action_respond_info("Printer not homed")}
              {% endif %}
        '';
        };
        "gcode_macro RESUME" = {
          description = "Resume the actual running print";
          rename_existing = "RESUME_BASE";
          gcode =
            ''    ##### read E from pause macro #####
             {% set E = printer["gcode_macro PAUSE"].extrude|float %}
             #### get VELOCITY parameter if specified ####
             {% if 'VELOCITY' in params|upper %}
               {% set get_params = ('VELOCITY=' + params.VELOCITY)  %}
             {%else %}
               {% set get_params = "" %}
             {% endif %}
             ##### end of definitions #####
             {% if printer.extruder.can_extrude|lower == 'true' %}
               G91
               G1 E{E} F2100
             {% else %}
               {action_respond_info("Extruder not hot enough")}
             {% endif %}
             RESUME_BASE {get_params}
        '';
        };

        "gcode_macro CANCEL_PRINT" = {
          description = "Cancel the actual running print";
          rename_existing = "CANCEL_PRINT_BASE";
          gcode = ''   TURN_OFF_HEATERS
            CANCEL_PRINT_BASE
         '';
        };

        ###   Use PRINT_START for the slicer starting script - please customize for your slicer of choice
        # https://github.com/Klipper3d/klipper/blob/master/config/sample-macros.cfg
        "gcode_macro PRINT_START".gcode =
          "    # Use absolute coordinates
             G90
             # Reset the G-Code Z offset (adjust Z offset if needed)
             # https://www.klipper3d.org/Bed_Level.html
             SET_GCODE_OFFSET Z=-0.025
             # Home the printer
             G28
        ";
        ###   Use PRINT_END for the slicer ending script - please customize for your slicer of choice
        "gcode_macro PRINT_END".gcode =
          ''    M400                           ; wait for buffer to clear
              G92 E0                         ; zero the extruder
              G1 E-4.0 F3600                 ; retract filament
              G91                            ; relative positioning

              #   Get Boundaries
              {% set max_x = printer.configfile.config["stepper_x"]["position_max"]|float %}
              {% set max_y = printer.configfile.config["stepper_y"]["position_max"]|float %}
              {% set max_z = printer.configfile.config["stepper_z"]["position_max"]|float %}

              #   Check end position to determine safe direction to move
              {% if printer.toolhead.position.x < (max_x - 20) %}
                  {% set x_safe = 20.0 %}
              {% else %}
                  {% set x_safe = -20.0 %}
              {% endif %}

              {% if printer.toolhead.position.y < (max_y - 20) %}
                  {% set y_safe = 20.0 %}
              {% else %}
                  {% set y_safe = -20.0 %}
              {% endif %}

              {% if printer.toolhead.position.z < (max_z - 2) %}
                  {% set z_safe = 2.0 %}
              {% else %}
                  {% set z_safe = max_z - printer.toolhead.position.z %}
              {% endif %}

              G0 Z{z_safe} F3600    ; move nozzle up
              G0 X{x_safe} Y{y_safe} F20000    ; move nozzle to remove stringing
              TURN_OFF_HEATERS
              # Turn off bed, extruder, and fan
              M140 S0
              M104 S0
              M106 S0
              M107                           ; turn off fan
              G90                            ; absolute positioning
              G0 X60 Y{max_y} F3600          ; park nozzle at rear
              # Disable steppers
              M84
        '';

        "gcode_macro LOAD_FILAMENT".gcode =
          "    M83                            ; set extruder to relative
             G1 E30 F300                    ; load
             G1 E15 F150                    ; prime nozzle with filament
             M82                            ; set extruder to absolute
        ";

        "gcode_macro UNLOAD_FILAMENT".gcode =
          "    M83                            ; set extruder to relative
             G1 E10 F300                    ; extrude a little to soften tip
             G1 E-40 F1800                  ; retract some, but not too much or it will jam
             M82                            ; set extruder to absolute
        ";
        ##
        ###[include v0_display.cfg]
        ###[include bedScrewMenu.cfg]
        ##

      };
    };
    services.moonraker = {
      user = "root";
      enable = true;
      address = "0.0.0.0";
      settings = {
        octoprint_compat = { };
        history = { };
        authorization = {
          force_logins = true;
          cors_domains = [
            "*.local"
            "*.lan"
            "*://app.fluidd.xyz"
            "*://my.mainsail.xyz"
          ];
          trusted_clients = [
            "10.147.27.0/24"
            "127.0.0.0/8"
            "192.168.1.0/24"
            "FE80::/10"
            "::1/128"
          ];
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 80 ];
    services.fluidd.enable = true;
    security.polkit.enable = true;
    ##services.fluidd.nginx.locations."/webcam".proxyPass = "http://127.0.0.1:8080/stream";
    ### Increase max upload size for uploading .gcode files from PrusaSlicer
    services.nginx.clientMaxBodySize = "1000m";

    ##systemd.services.ustreamer = {
    ##  wantedBy = [ "multi-user.target" ];
    ##  description = "uStreamer for video0";
    ##  serviceConfig = {
    ##    Type = "simple";
    ##    ExecStart = ''${pkgs.ustreamer}/bin/ustreamer --encoder=HW --persistent --drop-same-frames=30'';
    ##  };
    ##};
  };

}
