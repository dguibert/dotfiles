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
    services.klipper = rec {
      enable = true;
      firmwares = {
        mcu = {
          enable = true;
          # Run klipper-genconf to generate this
          configFile = ./server-3Dprinting/config;
          # Serial port connected to the microcontroller
          serial = "/dev/serial/by-id/usb-Klipper_stm32f401xc_2E0028000851383531393138-if00";
        };
        "mcu display" = {
          enable = true;
          # Run klipper-genconf to generate this
          configFile = ./server-3Dprinting/display.config;
          # Serial port connected to the microcontroller
          serial = "/dev/serial/by-id/usb-Klipper_stm32f042x6_05000B000543303848373220-if00";
        };
      };
      settings = {
        "temperature_sensor raspberry_pi" = {
          sensor_type = "temperature_host";
          min_temp = 0;
          max_temp = 100;
        };
        printer = {
          kinematics = "corexy";
          max_velocity = 300;
          max_accel = 3500;
          max_z_velocity = 15;
          max_z_accel = 45;
          square_corner_velocity = 6.0;
        };
        mcu.serial = firmwares.mcu.serial;
        mcu.restart_method = "command";

        # https://docs.fluidd.xyz/configuration/initial_setup
        virtual_sdcard.path = "/gcodes";
        display_status = { };
        #####################################################################
        #   V0 Display
        #####################################################################
        # https://github.com/VoronDesign/Voron-0/blob/Voron0.2r1/Firmware/fysetc-cheetah-v2.0.cfg
        "mcu display".serial = firmwares."mcu display".serial;
        "mcu display".restart_method = "command";

        display = {
          lcd_type = "sh1106";
          i2c_mcu = "display";
          i2c_bus = "i2c1a";
          # Set the direction of the encoder wheel
          #   Standard: Right (clockwise) scrolls down or increases values. Left (counter-clockwise scrolls up or decreases values.
          encoder_pins = "^display:PA3, ^display:PA4";
          #   Reversed: Right (clockwise) scrolls up or decreases values. Left (counter-clockwise scrolls down or increases values.
          #encoder_pins: ^display:PA4, ^display:PA3
          click_pin = "^!display:PA1";
          kill_pin = "^!display:PA5";
          x_offset = 2;
          #   Use X offset to shift the display towards the right. Value can be 0 to 3
          vcomh = 31;
          #   Set the Vcomh value on SSD1306/SH1106 displays. This value is
          #   associated with a "smearing" effect on some OLED displays. The
          #   value may range from 0 to 63. Default is 0.
          #   Adjust this value if you get some vertical stripes on your display. (31 seems to be a good value)
        };
        pause_resume = { };
        ## fysetc-cheetah-v2.0i
        # https://github.com/VoronDesign/Voron-0/blob/Voron0.2/Firmware/fysetc-cheetah-v2.0.cfg
        #####################################################################
        #      X/Y Stepper Settings
        #####################################################################
        stepper_x = {
          step_pin = "PC0";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "PC1";
          enable_pin = "!PA8";
          rotation_distance = 40;
          microsteps = 32;
          full_steps_per_rotation = 200;
          endstop_pin = "tmc2209_stepper_x:virtual_endstop";
          #full_steps_per_rotation = 200; # 1.8 stepper motor
          position_endstop = 120;
          position_max = 120;
          homing_speed = 40;
          homing_retract_dist = 0;
          homing_positive_dir = true;
        };
        "tmc2209 stepper_x" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 0;
          interpolate = false;
          run_current = 0.85;
          sense_resistor = 0.110;
          stealthchop_threshold = 0;
          diag_pin = "^PB4";
          driver_SGTHRS = 120;
        };
        stepper_y = {
          step_pin = "PC14";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "PC13";
          enable_pin = "!PC15";
          rotation_distance = 40;
          microsteps = 32;
          full_steps_per_rotation = 200;
          endstop_pin = "tmc2209_stepper_y:virtual_endstop";
          #full_steps_per_rotation = 200; # 1.8 stepper motor
          position_endstop = 120;
          position_max = 120;
          homing_speed = 40;
          homing_retract_dist = 0;
          homing_positive_dir = true;
        };
        "tmc2209 stepper_y" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 2;
          interpolate = false;
          run_current = 0.85;
          sense_resistor = 0.110;
          stealthchop_threshold = 0;
          diag_pin = "^PC8";
          driver_SGTHRS = 120;
        };
        stepper_z = {
          step_pin = "PB9";
          ## Refer to https://docs.vorondesign.com/build/startup/#v0
          dir_pin = "!PB8";
          enable_pin = "!PC2";
          rotation_distance = 8; # for T8x8 lead screan
          #rotation_distance = 2; # for T8x2 lead screan
          microsteps = 32;
          endstop_pin = "^PB1";
          position_endstop = 120;
          position_max = 120;
          position_min = -1.5;
          homing_speed = 20; # max 100
          second_homing_speed = 3.0; # max 100
          homing_retract_dist = 3.0;
        };
        "tmc2209 stepper_z" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 1;
          interpolate = false;
          run_current = 0.3; # For FYSETC 42HSC1404B-200N8
          sense_resistor = 0.110;
          stealthchop_threshold = 0;
        };
        extruder = {
          step_pin = "PB2";
          dir_pin = "PA15"; # Add ! if moving opposite direction
          enable_pin = "!PD2";
          full_steps_per_rotation = 200; # 1.8 degree motor
          # See calibrating rotation_distance on extruders doc
          #rotation_distance = 21.54087;
          rotation_distance = 22.251425904873;
          gear_ratio = "50:10"; # For Mini Afterburner
          microsteps = 32;
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
          #pid_Kp=20.040 pid_Ki=0.961 pid_Kd=104.459 # 20230418 V0.2
          pid_Kp = 20.040;
          pid_Ki = 0.961;
          pid_Kd = 104.459;
          min_temp = 0;
          max_temp = 270;
          min_extrude_temp = 0;
          max_extrude_only_distance = 150.0;
          max_extrude_cross_section = 0.8;
          pressure_advance = 0.04; # For ABS 15*0.005 See tuning pressure advance doc
          pressure_advance_smooth_time = 0.040;
        };
        "tmc2209 extruder" = {
          uart_pin = "PA3";
          tx_pin = "PA2";
          uart_address = 3;
          interpolate = false;
          run_current = 0.7;
          sense_resistor = 0.110;
          stealthchop_threshold = 0; # Set to 0 for spreadcycle, avoid using stealthchop on extruder
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
          # pid_Kp=51.159 pid_Ki=2.624 pid_Kd=249.400 # 20230418 V0.2
          # pid_Kp=51.007 pid_Ki=2.538 pid_Kd=256.311 # 20230418 V0.2
          pid_kp = 51.159;
          pid_ki = 2.624;
          pid_kd = 249.400;
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

        # SET_FAN_SPEED fan=exhaust_fan SPEED="number between 0 and 1"
        #  For example, to put the fan speed at 30% use,
        #
        #  SET_FAN_SPEED fan=exhaust_fan SPEED=0.3
        #
        #  Running the fan at 30% speed during a print has lead to a dramatic decrease in ABS fumes and pretty much made them unnoticeable. I also run the fan at 100% speed at the end of a print to fully exhaust the print chamber. Adding foam tape to seal up any gaps between panels and the top-hat will also greatly increase the reduction of fumes.
        "fan_generic exhaust_fan" = {
          # Exhaust Fan
          pin = "PA1";
          max_power = 1.0;
          shutdown_speed = 0;
          kick_start_time = 0.5;
          off_below = 0.4;
        };

        fan = {
          # Print Cooling Fan: FAN0 Connector
          pin = "PA14";
          max_power = 1.0;
          kick_start_time = 0.5;
          ###depending on your fan, you may need to increase or reduce this value
          ###if your fan will not start
          #off_below = "0.4";
          cycle_time = 0.010;
        };
        idle_timeout.timeout = 1800;

        #input_shaper.shaper_freq_x = 72.972972; #90*3/3.7;
        #input_shaper.shaper_freq_y = 90; #90*3/3;
        #input_shaper.shaper_type = "ei";

        homing_override = {
          axes = "xyz";
          set_position_z = 0;
          gcode =
            ''   G90
              G0 Z5 F600
              {% set home_all = 'X' not in params and 'Y' not in params and 'Z' not in params %}

              {% if home_all or 'X' in params %}
                _HOME_X
              {% endif %}

              {% if home_all or 'Y' in params %}
                _HOME_Y
              {% endif %}

              {% if home_all or 'Z' in params %}
                _HOME_Z
              {% endif %}
        '';
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
        "gcode_macro PRINT_START".gcode = "
             # Parameters
             {% set BED_TEMP = params.BED|float %}
             {% set EXTRUDER_TEMP = params.EXTRUDER|float %}
             # Reset the G-Code Z offset (adjust Z offset if needed)
             # https://www.klipper3d.org/Bed_Level.html
             SET_GCODE_OFFSET Z=+.010
             M140 S{BED_TEMP}       ; set for bed to reach temp
             M104 S{EXTRUDER_TEMP}  ; set for hot end to reach temp
             # Home the printer
             G28
             # Use absolute coordinates
             G90
             M190 S{BED_TEMP}            ; set and wait for bed to reach temp
             M109 S{EXTRUDER_TEMP}       ; set and wait for hot end to reach temp
             ; start exhaust fan
             SET_FAN_SPEED FAN=exhaust_fan SPEED=0.5

             G0 Y5 X5             ;
             G1 Z0.2 F500.0       ; move bed to nozzle
             G92 E0.0             ; reset extruder
             G1 E4.0 F500.0       ; pre-purge prime LENGTH SHOULD MATCH YOUR PRINT_END RETRACT
             G1 Z2 E10.0 F500.0     ;
             G1 Z5 E20.0 F500.0     ;
             G92 E0.0             ; reset extruder
             G1 Z2.0              ; move nozzle to prevent scratch
             ### Move the nozzle near the bed
             G1 Z20 F3000
             ### Move the nozzle very close to the bed
             ##G1 Z0.15 F300
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
              G0 X60 Y{max_y-10} F3600          ; park nozzle at rear
              ; runs the exhaust fan for 3 minutes on full speed
              SET_FAN_SPEED FAN=exhaust_fan SPEED=1.0
              G4 S180
              SET_FAN_SPEED FAN=exhaust_fan SPEED=0.0
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
        "gcode_macro _HOME_X".gcode =
          "    # Always use consistent run_current on A/B steppers during sensorless homing
             {% set RUN_CURRENT_X = printer.configfile.settings['tmc2209 stepper_x'].run_current|float %}
             {% set RUN_CURRENT_Y = printer.configfile.settings['tmc2209 stepper_y'].run_current|float %}
             {% set HOME_CURRENT_RATIO = 0.7 %} # by default we are dropping the motor current during homing. you can adjust this value if you are having trouble with skipping while homing
             SET_TMC_CURRENT STEPPER=stepper_x CURRENT={HOME_CURRENT_RATIO * RUN_CURRENT_X}
             SET_TMC_CURRENT STEPPER=stepper_y CURRENT={HOME_CURRENT_RATIO * RUN_CURRENT_Y}

             # Home
             G28 X
             # Move away
             G91
             G1 X-10 F1200

             # Wait just a second… (give StallGuard registers time to clear)
             G4 P1000
             G90
             # Set current during print
             SET_TMC_CURRENT STEPPER=stepper_x CURRENT={RUN_CURRENT_X}
             SET_TMC_CURRENT STEPPER=stepper_y CURRENT={RUN_CURRENT_Y}
        ";

        "gcode_macro _HOME_Y".gcode =
          "     # Set current for sensorless homing
             {% set RUN_CURRENT_X = printer.configfile.settings['tmc2209 stepper_x'].run_current|float %}
             {% set RUN_CURRENT_Y = printer.configfile.settings['tmc2209 stepper_y'].run_current|float %}
             {% set HOME_CURRENT_RATIO = 0.7 %} # by default we are dropping the motor current during homing. you can adjust this value if you are having trouble with skipping while homing
             SET_TMC_CURRENT STEPPER=stepper_x CURRENT={HOME_CURRENT_RATIO * RUN_CURRENT_X}
             SET_TMC_CURRENT STEPPER=stepper_y CURRENT={HOME_CURRENT_RATIO * RUN_CURRENT_Y}

             # Home
             G28 Y
             # Move away
             G91
             G1 Y-10 F1200

             # Wait just a second… (give StallGuard registers time to clear)
             G4 P1000
             G90
             # Set current during print
             SET_TMC_CURRENT STEPPER=stepper_x CURRENT={RUN_CURRENT_X}
             SET_TMC_CURRENT STEPPER=stepper_y CURRENT={RUN_CURRENT_Y}
        ";

        "gcode_macro _HOME_Z".gcode =
          "    G90
             G28 Z
             G1 Z30
        ";
        ##
        ###[include v0_display.cfg]
        ###[include bedScrewMenu.cfg]
        ##
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

        # https://www.klipper3d.org/Exclude_Object.html
        exclude_object = { };
        # https://github.com/Klipper3d/klipper/blob/master/config/sample-macros.cfg
        "gcode_macro M486".gcode =
          "      # Parameters known to M486 are as follows:
               #   [C<flag>] Cancel the current object
               #   [P<index>] Cancel the object with the given index
               #   [S<index>] Set the index of the current object.
               #       If the object with the given index has been canceled, this will cause
               #       the firmware to skip to the next object. The value -1 is used to
               #       indicate something that isn’t an object and shouldn’t be skipped.
               #   [T<count>] Reset the state and set the number of objects
               #   [U<index>] Un-cancel the object with the given index. This command will be
               #       ignored if the object has already been skipped

               {% if 'exclude_object' not in printer %}
                 {action_raise_error(\"[exclude_object] is not enabled\")}
               {% endif %}

               {% if 'T' in params %}
                 EXCLUDE_OBJECT RESET=1

                 {% for i in range(params.T | int) %}
                   EXCLUDE_OBJECT_DEFINE NAME={i}
                 {% endfor %}
               {% endif %}

               {% if 'C' in params %}
                 EXCLUDE_OBJECT CURRENT=1
               {% endif %}

               {% if 'P' in params %}
                 EXCLUDE_OBJECT NAME={params.P}
               {% endif %}

               {% if 'S' in params %}
                 {% if params.S == '-1' %}
                   {% if printer.exclude_object.current_object %}
                     EXCLUDE_OBJECT_END NAME={printer.exclude_object.current_object}
                   {% endif %}
                 {% else %}
                   EXCLUDE_OBJECT_START NAME={params.S}
                 {% endif %}
               {% endif %}

               {% if 'U' in params %}
                 EXCLUDE_OBJECT RESET=1 NAME={params.U}
               {% endif %}
        ";
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
