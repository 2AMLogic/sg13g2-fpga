read_lef /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
read_lef /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
read_def /home/ubuntu/GitHub/sg13g2-fpga/.loom/worktrees/issue-14/flow/build/tile/.klt/place-and-route/logic_tile_routed.def
read_liberty /home/ubuntu/share/pdk/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib
create_clock -name clk -period 20.0 [get_ports clk]
set_propagated_clock [get_clocks clk]
set klt_clock_port [get_ports clk]
set klt_non_clock_inputs [lsearch -inline -all -not -exact [all_inputs] $klt_clock_port]
set_input_delay 0.0 -clock clk $klt_non_clock_inputs
set_output_delay 0.0 -clock clk [all_outputs]
set klt_spef_nets [list {VDD} {VSS} {bel_en[0]} {bel_en[1]} {bel_en[2]} {bel_en[3]} {bel_o[0]} {bel_o[1]} {bel_o[2]} {bel_o[3]} {bel_sr[0]} {cfg[0]} {cfg[100]} {cfg[101]} {cfg[102]} {cfg[103]} {cfg[104]} {cfg[105]} {cfg[106]} {cfg[107]} {cfg[108]} {cfg[109]} {cfg[10]} {cfg[110]} {cfg[111]} {cfg[112]} {cfg[113]} {cfg[114]} {cfg[115]} {cfg[116]} {cfg[117]} {cfg[118]} {cfg[119]} {cfg[11]} {cfg[120]} {cfg[121]} {cfg[122]} {cfg[123]} {cfg[124]} {cfg[125]} {cfg[126]} {cfg[127]} {cfg[128]} {cfg[129]} {cfg[12]} {cfg[130]} {cfg[131]} {cfg[132]} {cfg[133]} {cfg[134]} {cfg[135]} {cfg[136]} {cfg[137]} {cfg[138]} {cfg[139]} {cfg[13]} {cfg[140]} {cfg[141]} {cfg[142]} {cfg[143]} {cfg[144]} {cfg[145]} {cfg[146]} {cfg[147]} {cfg[148]} {cfg[149]} {cfg[14]} {cfg[150]} {cfg[151]} {cfg[152]} {cfg[153]} {cfg[154]} {cfg[155]} {cfg[156]} {cfg[157]} {cfg[15]} {cfg[16]} {cfg[17]} {cfg[18]} {cfg[19]} {cfg[1]} {cfg[20]} {cfg[21]} {cfg[22]} {cfg[23]} {cfg[24]} {cfg[25]} {cfg[26]} {cfg[27]} {cfg[28]} {cfg[29]} {cfg[2]} {cfg[30]} {cfg[31]} {cfg[32]} {cfg[33]} {cfg[34]} {cfg[35]} {cfg[36]} {cfg[37]} {cfg[38]} {cfg[39]} {cfg[3]} {cfg[40]} {cfg[41]} {cfg[42]} {cfg[43]} {cfg[44]} {cfg[45]} {cfg[46]} {cfg[47]} {cfg[48]} {cfg[49]} {cfg[4]} {cfg[50]} {cfg[51]} {cfg[52]} {cfg[53]} {cfg[54]} {cfg[55]} {cfg[56]} {cfg[57]} {cfg[58]} {cfg[59]} {cfg[5]} {cfg[60]} {cfg[61]} {cfg[62]} {cfg[63]} {cfg[64]} {cfg[65]} {cfg[66]} {cfg[67]} {cfg[68]} {cfg[69]} {cfg[6]} {cfg[70]} {cfg[71]} {cfg[72]} {cfg[73]} {cfg[74]} {cfg[75]} {cfg[76]} {cfg[77]} {cfg[78]} {cfg[79]} {cfg[7]} {cfg[80]} {cfg[81]} {cfg[82]} {cfg[83]} {cfg[84]} {cfg[85]} {cfg[86]} {cfg[87]} {cfg[88]} {cfg[89]} {cfg[8]} {cfg[90]} {cfg[91]} {cfg[92]} {cfg[93]} {cfg[94]} {cfg[95]} {cfg[96]} {cfg[97]} {cfg[98]} {cfg[99]} {cfg[9]} {clk} {clknet_0_clk} {clknet_1_0__leaf_clk} {clknet_1_1__leaf_clk} {e_in[0]} {e_in[1]} {e_in[2]} {e_in[3]} {e_out[0]} {e_out[1]} {e_out[2]} {e_out[3]} {g_slice[0].u_slice/_00_} {g_slice[0].u_slice/_01_} {g_slice[0].u_slice/_02_} {g_slice[0].u_slice/_03_} {g_slice[0].u_slice/_04_} {g_slice[0].u_slice/_05_} {g_slice[0].u_slice/_06_} {g_slice[0].u_slice/_07_} {g_slice[0].u_slice/_08_} {g_slice[0].u_slice/ff_q} {g_slice[1].u_slice/_00_} {g_slice[1].u_slice/_01_} {g_slice[1].u_slice/_02_} {g_slice[1].u_slice/_03_} {g_slice[1].u_slice/_04_} {g_slice[1].u_slice/_05_} {g_slice[1].u_slice/_06_} {g_slice[1].u_slice/_07_} {g_slice[1].u_slice/_08_} {g_slice[1].u_slice/ff_q} {g_slice[2].u_slice/_00_} {g_slice[2].u_slice/_01_} {g_slice[2].u_slice/_02_} {g_slice[2].u_slice/_03_} {g_slice[2].u_slice/_04_} {g_slice[2].u_slice/_05_} {g_slice[2].u_slice/_06_} {g_slice[2].u_slice/_07_} {g_slice[2].u_slice/_08_} {g_slice[2].u_slice/ff_q} {g_slice[3].u_slice/_00_} {g_slice[3].u_slice/_01_} {g_slice[3].u_slice/_02_} {g_slice[3].u_slice/_03_} {g_slice[3].u_slice/_04_} {g_slice[3].u_slice/_05_} {g_slice[3].u_slice/_06_} {g_slice[3].u_slice/_07_} {g_slice[3].u_slice/_08_} {g_slice[3].u_slice/ff_q} {lut_in[0]} {lut_in[10]} {lut_in[11]} {lut_in[12]} {lut_in[13]} {lut_in[14]} {lut_in[15]} {lut_in[1]} {lut_in[2]} {lut_in[3]} {lut_in[4]} {lut_in[5]} {lut_in[6]} {lut_in[7]} {lut_in[8]} {lut_in[9]} {n_in[0]} {n_in[1]} {n_in[2]} {n_in[3]} {n_out[0]} {n_out[1]} {n_out[2]} {n_out[3]} {s_in[0]} {s_in[1]} {s_in[2]} {s_in[3]} {s_out[0]} {s_out[1]} {s_out[2]} {s_out[3]} {u_sm/_000_} {u_sm/_002_} {u_sm/_003_} {u_sm/_005_} {u_sm/_008_} {u_sm/_009_} {u_sm/_010_} {u_sm/_011_} {u_sm/_012_} {u_sm/_013_} {u_sm/_014_} {u_sm/_015_} {u_sm/_016_} {u_sm/_017_} {u_sm/_018_} {u_sm/_019_} {u_sm/_020_} {u_sm/_021_} {u_sm/_022_} {u_sm/_023_} {u_sm/_024_} {u_sm/_025_} {u_sm/_026_} {u_sm/_027_} {u_sm/_028_} {u_sm/_029_} {u_sm/_030_} {u_sm/_031_} {u_sm/_032_} {u_sm/_033_} {u_sm/_034_} {u_sm/_035_} {u_sm/_036_} {u_sm/_037_} {u_sm/_038_} {u_sm/_039_} {u_sm/_040_} {u_sm/_041_} {u_sm/_042_} {u_sm/_043_} {u_sm/_044_} {u_sm/_045_} {u_sm/_046_} {u_sm/_047_} {u_sm/_048_} {u_sm/_049_} {u_sm/_050_} {u_sm/_051_} {u_sm/_052_} {u_sm/_053_} {u_sm/_054_} {u_sm/_055_} {u_sm/_056_} {u_sm/_057_} {u_sm/_058_} {u_sm/_059_} {u_sm/_060_} {u_sm/_061_} {u_sm/_062_} {u_sm/_063_} {u_sm/_064_} {u_sm/_065_} {u_sm/_066_} {u_sm/_067_} {u_sm/_068_} {u_sm/_069_} {u_sm/_070_} {u_sm/_071_} {u_sm/_072_} {u_sm/_073_} {u_sm/_074_} {u_sm/_075_} {u_sm/_076_} {u_sm/_077_} {u_sm/_078_} {u_sm/_079_} {u_sm/_080_} {u_sm/_081_} {u_sm/_082_} {u_sm/_083_} {u_sm/_084_} {u_sm/_085_} {u_sm/_086_} {u_sm/_087_} {u_sm/_088_} {u_sm/_089_} {u_sm/_090_} {u_sm/_091_} {u_sm/_092_} {u_sm/_093_} {u_sm/_094_} {u_sm/_095_} {u_sm/_096_} {u_sm/_097_} {u_sm/_098_} {u_sm/_099_} {u_sm/net13} {u_sm/net14} {u_sm/net15} {u_sm/net16} {u_sm/net17} {u_sm/net18} {u_sm/net19} {u_sm/net20} {w_in[0]} {w_in[1]} {w_in[2]} {w_in[3]} {w_out[0]} {w_out[1]} {w_out[2]} {w_out[3]}]
set klt_spef_annotated 0
foreach klt_spef_net $klt_spef_nets {
    set klt_spef_have($klt_spef_net) 1
    if {[llength [get_nets -quiet $klt_spef_net]] > 0} {
        incr klt_spef_annotated
    }
}
set klt_design_total 0
set klt_design_annotated 0
set klt_design_missing {}
set klt_design_missing_limit 20
foreach klt_design_net [get_nets -quiet *] {
    incr klt_design_total
    if {[info exists klt_spef_have([get_full_name $klt_design_net])]} {
        incr klt_design_annotated
    } elseif {[llength $klt_design_missing] < $klt_design_missing_limit} {
        lappend klt_design_missing [get_full_name $klt_design_net]
    }
}
puts "===KLT_STA_SPEF_NET_CHECK_BEGIN==="
puts "$klt_spef_annotated [llength $klt_spef_nets]"
puts "$klt_design_annotated $klt_design_total"
puts "===KLT_STA_SPEF_NET_CHECK_END==="
puts "===KLT_STA_SPEF_MISSING_NETS_BEGIN==="
foreach klt_missing_net $klt_design_missing {
    puts $klt_missing_net
}
puts "===KLT_STA_SPEF_MISSING_NETS_END==="
puts "===KLT_STA_DELAY_PRE_BEGIN==="
report_checks -path_delay min_max -digits 6 -unconstrained
puts "===KLT_STA_DELAY_PRE_END==="
puts "===KLT_STA_SPEF_READ_BEGIN==="
read_spef /home/ubuntu/GitHub/sg13g2-fpga/.loom/worktrees/issue-14/flow/build/tile/logic_tile_routed.spef
puts "===KLT_STA_SPEF_READ_END==="
write_sdf -divider . -include_typ /home/ubuntu/GitHub/sg13g2-fpga/.loom/worktrees/issue-14/flow/build/tile/.klt/sta/logic_tile_routed.typ_1p20V_25C.sdf
puts "===KLT_STA_DELAY_POST_BEGIN==="
report_checks -path_delay min_max -digits 6 -unconstrained
puts "===KLT_STA_DELAY_POST_END==="
puts "===KLT_STA_PARASITIC_ANNOTATION_BEGIN==="
if {[catch {report_parasitic_annotation -report_unannotated} klt_parasitic_annotation_msg]} {
  catch {report_parasitic_annotation} klt_parasitic_annotation_msg
}
puts "===KLT_STA_PARASITIC_ANNOTATION_END==="
puts "===KLT_STA_FLOATING_DRIVERS_BEGIN==="
catch {
  foreach klt_pin [get_pins -hierarchical *] {
    if {[get_property $klt_pin direction] ne "output"} {continue}
    set klt_nets [get_nets -quiet -of_objects $klt_pin]
    set klt_floating [expr {[llength $klt_nets] == 0}]
    if {!$klt_floating} {
      set klt_net [lindex $klt_nets 0]
      set klt_floating [expr {[llength [get_pins -quiet -of_objects $klt_net]] <= 1 && [llength [get_ports -quiet -of_objects $klt_net]] == 0}]
    }
    if {$klt_floating} {
      puts "KLT_FLOATING_DRIVER [get_full_name $klt_pin]"
    }
  }
} klt_floating_drivers_msg
puts "===KLT_STA_FLOATING_DRIVERS_END==="
puts "===KLT_STA_DRIVER_NETS_BEGIN==="
foreach klt_pin [get_pins -hierarchical *] {
  catch {
    if {[get_property $klt_pin direction] eq "output"} {
      set klt_nets [get_nets -quiet -of_objects $klt_pin]
      if {[llength $klt_nets] == 1} {
        set klt_n [llength [get_pins -quiet -of_objects $klt_nets]]
        if {$klt_n <= 1} {
          puts "KLT_DRIVER_NET [get_full_name $klt_pin] $klt_n [get_full_name $klt_nets]"
        }
      }
    }
  } klt_driver_nets_msg
}
puts "===KLT_STA_DRIVER_NETS_END==="
puts "===KLT_STA_CLOCK_LATENCY_BEGIN==="
catch {report_clock_latency -digits 6} klt_clock_latency_msg
puts "===KLT_STA_CLOCK_LATENCY_END==="
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
