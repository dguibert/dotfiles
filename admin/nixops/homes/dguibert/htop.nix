{ config, ... }:
{
  programs.htop.enable = true;
  # fields=0 48 17 18 38 39 40 2 46 47 49 109 110 1
  programs.htop.settings = {
    fields = with config.lib.htop.fields; [
      PID #= 0; #
      USER #= 48; #
      PRIORITY #= 17; #
      NICE #= 18; #
      M_SIZE #= 38; #
      M_RESIDENT #= 39; #
      M_SHARE #= 40; #
      STATE #= 2; #
      PERCENT_CPU #= 46; #
      PERCENT_MEM #= 47; #
      TIME #= 49; #
      IO_READ_RATE #= 109; #
      IO_WRITE_RATE #= 110; #
      COMM
    ];
    hide_threads = true;
    hide_userland_threads = true;
    tree_view = true;
    header_margin = false;
    cpu_count_from_zero = true;
    show_cpu_usage = true;
    color_scheme = 6;
  } // (with config.lib.htop; leftMeters [
    (bar "CPU")
    (bar "Memory")
    (bar "Swap")
  ]) // (with config.lib.htop; rightMeters [
    (text "Tasks")
    (text "LoadAverage")
    (text "Uptime")
  ]);


}
