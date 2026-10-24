read_lef /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
read_lef /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
read_def /home/ubuntu/GitHub/sg13g2-fpga/.loom/worktrees/issue-14/flow/build/smoke/.klt/place-and-route/counter.def
read_liberty /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib
create_clock -name clk -period 10.0 [get_ports clk]
report_worst_slack_metric -setup
report_worst_slack_metric -hold
report_tns_metric -setup
report_tns_metric -hold
report_fmax_metric
report_power_metric
report_clock_skew_metric -setup
puts "===KLT_STA_SETUP_VIOLATIONS_BEGIN==="
report_check_types -max_delay -recovery -clock_gating_setup -violators -format end
puts "===KLT_STA_SETUP_VIOLATIONS_END==="
puts "===KLT_STA_HOLD_VIOLATIONS_BEGIN==="
report_check_types -min_delay -removal -clock_gating_hold -violators -format end
puts "===KLT_STA_HOLD_VIOLATIONS_END==="
puts "===KLT_STA_WORST_PATHS_BEGIN==="
if {[catch {
    foreach klt_path_side {max min} {
        foreach klt_pe [find_timing_paths -path_delay $klt_path_side -group_path_count 1 -endpoint_path_count 1] {
            puts "PATH\t$klt_path_side\t[$klt_pe check_role]\t[$klt_pe slack]\t[get_full_name [get_property $klt_pe startpoint]]\t[get_full_name [get_property $klt_pe endpoint]]"
        }
    }
} klt_worst_path_error]} {
    puts "ERROR\t[string map [list \n { } \t { }] $klt_worst_path_error]"
}
puts "===KLT_STA_WORST_PATHS_END==="
set_cmd_units -time ns -capacitance pF
puts "===KLT_STA_MAX_SLEW_BEGIN==="
set klt_elec_rep {}
if {[catch {
  sta::redirect_string_begin
  report_check_types -max_slew -violators -digits 5
  set klt_elec_rep [sta::redirect_string_end]
} klt_elec_msg]} {
  puts "KLT_ELECTRICAL_UNSUPPORTED"
} else {
  puts $klt_elec_rep
  foreach klt_elec_line [split $klt_elec_rep "\n"] {
    if {[string match "*(VIOLATED)*" $klt_elec_line]} {
      set klt_elec_pin [lindex $klt_elec_line 0]
      set klt_elec_obj [get_pins -quiet $klt_elec_pin]
      if {[llength $klt_elec_obj]} {
        set klt_elec_net [get_nets -quiet -of_objects $klt_elec_obj]
        set klt_elec_net_name [expr {[llength $klt_elec_net] ? [get_full_name $klt_elec_net] : $klt_elec_pin}]
      } else {
        set klt_elec_net_name $klt_elec_pin
      }
      puts "KLT_ELECTRICAL_NET $klt_elec_pin $klt_elec_net_name"
    }
  }
  puts "KLT_ELECTRICAL_OK"
}
puts "===KLT_STA_MAX_SLEW_END==="
puts "===KLT_STA_MAX_CAP_BEGIN==="
set klt_elec_rep {}
if {[catch {
  sta::redirect_string_begin
  report_check_types -max_capacitance -violators -digits 5
  set klt_elec_rep [sta::redirect_string_end]
} klt_elec_msg]} {
  puts "KLT_ELECTRICAL_UNSUPPORTED"
} else {
  puts $klt_elec_rep
  foreach klt_elec_line [split $klt_elec_rep "\n"] {
    if {[string match "*(VIOLATED)*" $klt_elec_line]} {
      set klt_elec_pin [lindex $klt_elec_line 0]
      set klt_elec_obj [get_pins -quiet $klt_elec_pin]
      if {[llength $klt_elec_obj]} {
        set klt_elec_net [get_nets -quiet -of_objects $klt_elec_obj]
        set klt_elec_net_name [expr {[llength $klt_elec_net] ? [get_full_name $klt_elec_net] : $klt_elec_pin}]
      } else {
        set klt_elec_net_name $klt_elec_pin
      }
      puts "KLT_ELECTRICAL_NET $klt_elec_pin $klt_elec_net_name"
    }
  }
  puts "KLT_ELECTRICAL_OK"
}
puts "===KLT_STA_MAX_CAP_END==="
puts "===KLT_STA_CONSTRAINT_COMPLETENESS_BEGIN==="
foreach {klt_cc_check klt_cc_flags} {unconstrained_endpoints {0 0 0 0 1 0 0} unclocked_registers {0 0 0 1 0 0 0}} {
    if {[catch {
        set klt_cc_pins {}
        foreach klt_cc_record [sta::check_timing_cmd {*}$klt_cc_flags] {
            lappend klt_cc_pins {*}[lrange $klt_cc_record 1 end]
        }
        puts "CHECK\t$klt_cc_check\t[llength $klt_cc_pins]"
        foreach klt_cc_pin [lrange $klt_cc_pins 0 19] {
            puts "ITEM\t$klt_cc_check\t[string map [list \n { } \t { }] $klt_cc_pin]"
        }
    } klt_cc_error]} {
        puts "ERROR\t$klt_cc_check\t[string map [list \n { } \t { }] $klt_cc_error]"
    }
}
puts "===KLT_STA_CONSTRAINT_COMPLETENESS_END==="
