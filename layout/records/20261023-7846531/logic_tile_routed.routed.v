module logic_tile_routed (clk,
    cfg,
    e_in,
    e_out,
    n_in,
    n_out,
    s_in,
    s_out,
    w_in,
    w_out);
 input clk;
 input [157:0] cfg;
 input [3:0] e_in;
 output [3:0] e_out;
 input [3:0] n_in;
 output [3:0] n_out;
 input [3:0] s_in;
 output [3:0] s_out;
 input [3:0] w_in;
 output [3:0] w_out;

 wire \g_slice[0].u_slice/_00_ ;
 wire \g_slice[0].u_slice/_01_ ;
 wire \g_slice[0].u_slice/_02_ ;
 wire \g_slice[0].u_slice/_03_ ;
 wire \g_slice[0].u_slice/_04_ ;
 wire \g_slice[0].u_slice/_05_ ;
 wire \g_slice[0].u_slice/_06_ ;
 wire \g_slice[0].u_slice/_07_ ;
 wire \g_slice[0].u_slice/_08_ ;
 wire \g_slice[0].u_slice/ff_q ;
 wire \g_slice[1].u_slice/_00_ ;
 wire \g_slice[1].u_slice/_01_ ;
 wire \g_slice[1].u_slice/_02_ ;
 wire \g_slice[1].u_slice/_03_ ;
 wire \g_slice[1].u_slice/_04_ ;
 wire \g_slice[1].u_slice/_05_ ;
 wire \g_slice[1].u_slice/_06_ ;
 wire \g_slice[1].u_slice/_07_ ;
 wire \g_slice[1].u_slice/_08_ ;
 wire \g_slice[1].u_slice/ff_q ;
 wire \g_slice[2].u_slice/_00_ ;
 wire \g_slice[2].u_slice/_01_ ;
 wire \g_slice[2].u_slice/_02_ ;
 wire \g_slice[2].u_slice/_03_ ;
 wire \g_slice[2].u_slice/_04_ ;
 wire \g_slice[2].u_slice/_05_ ;
 wire \g_slice[2].u_slice/_06_ ;
 wire \g_slice[2].u_slice/_07_ ;
 wire \g_slice[2].u_slice/_08_ ;
 wire \g_slice[2].u_slice/ff_q ;
 wire \g_slice[3].u_slice/_00_ ;
 wire \g_slice[3].u_slice/_01_ ;
 wire \g_slice[3].u_slice/_02_ ;
 wire \g_slice[3].u_slice/_03_ ;
 wire \g_slice[3].u_slice/_04_ ;
 wire \g_slice[3].u_slice/_05_ ;
 wire \g_slice[3].u_slice/_06_ ;
 wire \g_slice[3].u_slice/_07_ ;
 wire \g_slice[3].u_slice/_08_ ;
 wire \g_slice[3].u_slice/ff_q ;
 wire \u_sm/_000_ ;
 wire \u_sm/net15 ;
 wire \u_sm/_002_ ;
 wire \u_sm/_003_ ;
 wire \u_sm/net11 ;
 wire \u_sm/_005_ ;
 wire clknet_1_0__leaf_clk;
 wire \u_sm/net18 ;
 wire \u_sm/_008_ ;
 wire \u_sm/_009_ ;
 wire \u_sm/_010_ ;
 wire \u_sm/_011_ ;
 wire \u_sm/_012_ ;
 wire \u_sm/_013_ ;
 wire \u_sm/_014_ ;
 wire \u_sm/_015_ ;
 wire \u_sm/_016_ ;
 wire \u_sm/_017_ ;
 wire \u_sm/_018_ ;
 wire \u_sm/_019_ ;
 wire \u_sm/_020_ ;
 wire \u_sm/_021_ ;
 wire \u_sm/_022_ ;
 wire \u_sm/_023_ ;
 wire \u_sm/_024_ ;
 wire \u_sm/_025_ ;
 wire \u_sm/_026_ ;
 wire \u_sm/_027_ ;
 wire \u_sm/_028_ ;
 wire \u_sm/_029_ ;
 wire \u_sm/_030_ ;
 wire \u_sm/_031_ ;
 wire \u_sm/_032_ ;
 wire \u_sm/_033_ ;
 wire \u_sm/_034_ ;
 wire \u_sm/_035_ ;
 wire \u_sm/_036_ ;
 wire \u_sm/_037_ ;
 wire \u_sm/_038_ ;
 wire \u_sm/_039_ ;
 wire \u_sm/_040_ ;
 wire \u_sm/_041_ ;
 wire \u_sm/_042_ ;
 wire \u_sm/_043_ ;
 wire \u_sm/_044_ ;
 wire \u_sm/_045_ ;
 wire \u_sm/_046_ ;
 wire \u_sm/_047_ ;
 wire \u_sm/_048_ ;
 wire \u_sm/_049_ ;
 wire \u_sm/_050_ ;
 wire \u_sm/_051_ ;
 wire \u_sm/_052_ ;
 wire \u_sm/_053_ ;
 wire \u_sm/_054_ ;
 wire \u_sm/_055_ ;
 wire \u_sm/_056_ ;
 wire \u_sm/_057_ ;
 wire \u_sm/_058_ ;
 wire \u_sm/_059_ ;
 wire \u_sm/_060_ ;
 wire \u_sm/_061_ ;
 wire \u_sm/_062_ ;
 wire \u_sm/_063_ ;
 wire \u_sm/_064_ ;
 wire \u_sm/_065_ ;
 wire \u_sm/_066_ ;
 wire \u_sm/_067_ ;
 wire \u_sm/_068_ ;
 wire \u_sm/_069_ ;
 wire \u_sm/_070_ ;
 wire \u_sm/_071_ ;
 wire \u_sm/_072_ ;
 wire \u_sm/_073_ ;
 wire \u_sm/_074_ ;
 wire \u_sm/_075_ ;
 wire \u_sm/_076_ ;
 wire \u_sm/_077_ ;
 wire \u_sm/_078_ ;
 wire \u_sm/_079_ ;
 wire \u_sm/_080_ ;
 wire \u_sm/_081_ ;
 wire \u_sm/_082_ ;
 wire \u_sm/_083_ ;
 wire \u_sm/_084_ ;
 wire \u_sm/_085_ ;
 wire \u_sm/_086_ ;
 wire \u_sm/_087_ ;
 wire \u_sm/_088_ ;
 wire \u_sm/_089_ ;
 wire \u_sm/_090_ ;
 wire \u_sm/_091_ ;
 wire \u_sm/_092_ ;
 wire \u_sm/_093_ ;
 wire \u_sm/_094_ ;
 wire \u_sm/_095_ ;
 wire \u_sm/_096_ ;
 wire \u_sm/_097_ ;
 wire \u_sm/_098_ ;
 wire \u_sm/_099_ ;
 wire \u_sm/net17 ;
 wire clknet_0_clk;
 wire \u_sm/net14 ;
 wire \u_sm/net13 ;
 wire \u_sm/net16 ;
 wire \u_sm/net12 ;
 wire clknet_1_1__leaf_clk;
 wire [3:0] bel_en;
 wire [3:0] bel_o;
 wire [0:0] bel_sr;
 wire [15:0] lut_in;

 sg13g2_buf_16 clkbuf_0_clk (.X(clknet_0_clk),
    .A(clk));
 sg13g2_buf_16 clkbuf_1_0__f_clk (.X(clknet_1_0__leaf_clk),
    .A(clknet_0_clk));
 sg13g2_buf_16 clkbuf_1_1__f_clk (.X(clknet_1_1__leaf_clk),
    .A(clknet_0_clk));
 sg13g2_mux4_1 \g_slice[0].u_slice/_09_  (.S0(lut_in[0]),
    .A0(cfg[0]),
    .A1(cfg[1]),
    .A2(cfg[2]),
    .A3(cfg[3]),
    .S1(lut_in[1]),
    .X(\g_slice[0].u_slice/_01_ ));
 sg13g2_mux4_1 \g_slice[0].u_slice/_10_  (.S0(lut_in[0]),
    .A0(cfg[8]),
    .A1(cfg[9]),
    .A2(cfg[10]),
    .A3(cfg[11]),
    .S1(lut_in[1]),
    .X(\g_slice[0].u_slice/_02_ ));
 sg13g2_mux4_1 \g_slice[0].u_slice/_11_  (.S0(lut_in[0]),
    .A0(cfg[4]),
    .A1(cfg[5]),
    .A2(cfg[6]),
    .A3(cfg[7]),
    .S1(lut_in[1]),
    .X(\g_slice[0].u_slice/_03_ ));
 sg13g2_mux4_1 \g_slice[0].u_slice/_12_  (.S0(lut_in[0]),
    .A0(cfg[12]),
    .A1(cfg[13]),
    .A2(cfg[14]),
    .A3(cfg[15]),
    .S1(lut_in[1]),
    .X(\g_slice[0].u_slice/_04_ ));
 sg13g2_mux4_1 \g_slice[0].u_slice/_13_  (.S0(lut_in[3]),
    .A0(\g_slice[0].u_slice/_01_ ),
    .A1(\g_slice[0].u_slice/_02_ ),
    .A2(\g_slice[0].u_slice/_03_ ),
    .A3(\g_slice[0].u_slice/_04_ ),
    .S1(lut_in[2]),
    .X(\g_slice[0].u_slice/_05_ ));
 sg13g2_mux2_1 \g_slice[0].u_slice/_14_  (.A0(\g_slice[0].u_slice/_05_ ),
    .A1(\g_slice[0].u_slice/ff_q ),
    .S(cfg[16]),
    .X(bel_o[0]));
 sg13g2_nor2b_1 \g_slice[0].u_slice/_15_  (.A(\g_slice[0].u_slice/_05_ ),
    .B_N(bel_en[0]),
    .Y(\g_slice[0].u_slice/_06_ ));
 sg13g2_nor2_1 \g_slice[0].u_slice/_16_  (.A(\g_slice[0].u_slice/ff_q ),
    .B(bel_en[0]),
    .Y(\g_slice[0].u_slice/_07_ ));
 sg13g2_nor3_1 \g_slice[0].u_slice/_17_  (.A(bel_sr[0]),
    .B(\g_slice[0].u_slice/_06_ ),
    .C(\g_slice[0].u_slice/_07_ ),
    .Y(\g_slice[0].u_slice/_00_ ));
 sg13g2_dfrbpq_1 \g_slice[0].u_slice/_18_  (.RESET_B(\g_slice[0].u_slice/_08_ ),
    .D(\g_slice[0].u_slice/_00_ ),
    .Q(\g_slice[0].u_slice/ff_q ),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_tiehi \g_slice[0].u_slice/_19_  (.L_HI(\g_slice[0].u_slice/_08_ ));
 sg13g2_mux4_1 \g_slice[1].u_slice/_09_  (.S0(lut_in[4]),
    .A0(cfg[17]),
    .A1(cfg[18]),
    .A2(cfg[19]),
    .A3(cfg[20]),
    .S1(lut_in[5]),
    .X(\g_slice[1].u_slice/_01_ ));
 sg13g2_mux4_1 \g_slice[1].u_slice/_10_  (.S0(lut_in[4]),
    .A0(cfg[25]),
    .A1(cfg[26]),
    .A2(cfg[27]),
    .A3(cfg[28]),
    .S1(lut_in[5]),
    .X(\g_slice[1].u_slice/_02_ ));
 sg13g2_mux4_1 \g_slice[1].u_slice/_11_  (.S0(lut_in[4]),
    .A0(cfg[21]),
    .A1(cfg[22]),
    .A2(cfg[23]),
    .A3(cfg[24]),
    .S1(lut_in[5]),
    .X(\g_slice[1].u_slice/_03_ ));
 sg13g2_mux4_1 \g_slice[1].u_slice/_12_  (.S0(lut_in[4]),
    .A0(cfg[29]),
    .A1(cfg[30]),
    .A2(cfg[31]),
    .A3(cfg[32]),
    .S1(lut_in[5]),
    .X(\g_slice[1].u_slice/_04_ ));
 sg13g2_mux4_1 \g_slice[1].u_slice/_13_  (.S0(lut_in[7]),
    .A0(\g_slice[1].u_slice/_01_ ),
    .A1(\g_slice[1].u_slice/_02_ ),
    .A2(\g_slice[1].u_slice/_03_ ),
    .A3(\g_slice[1].u_slice/_04_ ),
    .S1(lut_in[6]),
    .X(\g_slice[1].u_slice/_05_ ));
 sg13g2_mux2_1 \g_slice[1].u_slice/_14_  (.A0(\g_slice[1].u_slice/_05_ ),
    .A1(\g_slice[1].u_slice/ff_q ),
    .S(cfg[33]),
    .X(bel_o[1]));
 sg13g2_nor2b_1 \g_slice[1].u_slice/_15_  (.A(\g_slice[1].u_slice/_05_ ),
    .B_N(bel_en[1]),
    .Y(\g_slice[1].u_slice/_06_ ));
 sg13g2_nor2_1 \g_slice[1].u_slice/_16_  (.A(\g_slice[1].u_slice/ff_q ),
    .B(bel_en[1]),
    .Y(\g_slice[1].u_slice/_07_ ));
 sg13g2_nor3_1 \g_slice[1].u_slice/_17_  (.A(bel_sr[0]),
    .B(\g_slice[1].u_slice/_06_ ),
    .C(\g_slice[1].u_slice/_07_ ),
    .Y(\g_slice[1].u_slice/_00_ ));
 sg13g2_dfrbpq_1 \g_slice[1].u_slice/_18_  (.RESET_B(\g_slice[1].u_slice/_08_ ),
    .D(\g_slice[1].u_slice/_00_ ),
    .Q(\g_slice[1].u_slice/ff_q ),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_tiehi \g_slice[1].u_slice/_19_  (.L_HI(\g_slice[1].u_slice/_08_ ));
 sg13g2_mux4_1 \g_slice[2].u_slice/_09_  (.S0(lut_in[8]),
    .A0(cfg[34]),
    .A1(cfg[35]),
    .A2(cfg[36]),
    .A3(cfg[37]),
    .S1(lut_in[9]),
    .X(\g_slice[2].u_slice/_01_ ));
 sg13g2_mux4_1 \g_slice[2].u_slice/_10_  (.S0(lut_in[8]),
    .A0(cfg[42]),
    .A1(cfg[43]),
    .A2(cfg[44]),
    .A3(cfg[45]),
    .S1(lut_in[9]),
    .X(\g_slice[2].u_slice/_02_ ));
 sg13g2_mux4_1 \g_slice[2].u_slice/_11_  (.S0(lut_in[8]),
    .A0(cfg[38]),
    .A1(cfg[39]),
    .A2(cfg[40]),
    .A3(cfg[41]),
    .S1(lut_in[9]),
    .X(\g_slice[2].u_slice/_03_ ));
 sg13g2_mux4_1 \g_slice[2].u_slice/_12_  (.S0(lut_in[8]),
    .A0(cfg[46]),
    .A1(cfg[47]),
    .A2(cfg[48]),
    .A3(cfg[49]),
    .S1(lut_in[9]),
    .X(\g_slice[2].u_slice/_04_ ));
 sg13g2_mux4_1 \g_slice[2].u_slice/_13_  (.S0(lut_in[11]),
    .A0(\g_slice[2].u_slice/_01_ ),
    .A1(\g_slice[2].u_slice/_02_ ),
    .A2(\g_slice[2].u_slice/_03_ ),
    .A3(\g_slice[2].u_slice/_04_ ),
    .S1(lut_in[10]),
    .X(\g_slice[2].u_slice/_05_ ));
 sg13g2_mux2_1 \g_slice[2].u_slice/_14_  (.A0(\g_slice[2].u_slice/_05_ ),
    .A1(\g_slice[2].u_slice/ff_q ),
    .S(cfg[50]),
    .X(bel_o[2]));
 sg13g2_nor2b_1 \g_slice[2].u_slice/_15_  (.A(\g_slice[2].u_slice/_05_ ),
    .B_N(bel_en[2]),
    .Y(\g_slice[2].u_slice/_06_ ));
 sg13g2_nor2_1 \g_slice[2].u_slice/_16_  (.A(\g_slice[2].u_slice/ff_q ),
    .B(bel_en[2]),
    .Y(\g_slice[2].u_slice/_07_ ));
 sg13g2_nor3_1 \g_slice[2].u_slice/_17_  (.A(bel_sr[0]),
    .B(\g_slice[2].u_slice/_06_ ),
    .C(\g_slice[2].u_slice/_07_ ),
    .Y(\g_slice[2].u_slice/_00_ ));
 sg13g2_dfrbpq_1 \g_slice[2].u_slice/_18_  (.RESET_B(\g_slice[2].u_slice/_08_ ),
    .D(\g_slice[2].u_slice/_00_ ),
    .Q(\g_slice[2].u_slice/ff_q ),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_tiehi \g_slice[2].u_slice/_19_  (.L_HI(\g_slice[2].u_slice/_08_ ));
 sg13g2_mux4_1 \g_slice[3].u_slice/_09_  (.S0(lut_in[12]),
    .A0(cfg[51]),
    .A1(cfg[52]),
    .A2(cfg[53]),
    .A3(cfg[54]),
    .S1(lut_in[13]),
    .X(\g_slice[3].u_slice/_01_ ));
 sg13g2_mux4_1 \g_slice[3].u_slice/_10_  (.S0(lut_in[12]),
    .A0(cfg[59]),
    .A1(cfg[60]),
    .A2(cfg[61]),
    .A3(cfg[62]),
    .S1(lut_in[13]),
    .X(\g_slice[3].u_slice/_02_ ));
 sg13g2_mux4_1 \g_slice[3].u_slice/_11_  (.S0(lut_in[12]),
    .A0(cfg[55]),
    .A1(cfg[56]),
    .A2(cfg[57]),
    .A3(cfg[58]),
    .S1(lut_in[13]),
    .X(\g_slice[3].u_slice/_03_ ));
 sg13g2_mux4_1 \g_slice[3].u_slice/_12_  (.S0(lut_in[12]),
    .A0(cfg[63]),
    .A1(cfg[64]),
    .A2(cfg[65]),
    .A3(cfg[66]),
    .S1(lut_in[13]),
    .X(\g_slice[3].u_slice/_04_ ));
 sg13g2_mux4_1 \g_slice[3].u_slice/_13_  (.S0(lut_in[15]),
    .A0(\g_slice[3].u_slice/_01_ ),
    .A1(\g_slice[3].u_slice/_02_ ),
    .A2(\g_slice[3].u_slice/_03_ ),
    .A3(\g_slice[3].u_slice/_04_ ),
    .S1(lut_in[14]),
    .X(\g_slice[3].u_slice/_05_ ));
 sg13g2_mux2_1 \g_slice[3].u_slice/_14_  (.A0(\g_slice[3].u_slice/_05_ ),
    .A1(\g_slice[3].u_slice/ff_q ),
    .S(cfg[67]),
    .X(bel_o[3]));
 sg13g2_nor2b_1 \g_slice[3].u_slice/_15_  (.A(\g_slice[3].u_slice/_05_ ),
    .B_N(bel_en[3]),
    .Y(\g_slice[3].u_slice/_06_ ));
 sg13g2_nor2_1 \g_slice[3].u_slice/_16_  (.A(\g_slice[3].u_slice/ff_q ),
    .B(bel_en[3]),
    .Y(\g_slice[3].u_slice/_07_ ));
 sg13g2_nor3_1 \g_slice[3].u_slice/_17_  (.A(bel_sr[0]),
    .B(\g_slice[3].u_slice/_06_ ),
    .C(\g_slice[3].u_slice/_07_ ),
    .Y(\g_slice[3].u_slice/_00_ ));
 sg13g2_dfrbpq_1 \g_slice[3].u_slice/_18_  (.RESET_B(\g_slice[3].u_slice/_08_ ),
    .D(\g_slice[3].u_slice/_00_ ),
    .Q(\g_slice[3].u_slice/ff_q ),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_tiehi \g_slice[3].u_slice/_19_  (.L_HI(\g_slice[3].u_slice/_08_ ));
 sg13g2_inv_1 \u_sm/_100_  (.Y(\u_sm/_000_ ),
    .A(cfg[74]));
 sg13g2_mux2_1 \u_sm/_102_  (.A0(w_in[2]),
    .A1(\u_sm/net11 ),
    .S(cfg[76]),
    .X(\u_sm/_002_ ));
 sg13g2_nor2b_1 \u_sm/_103_  (.A(cfg[76]),
    .B_N(cfg[74]),
    .Y(\u_sm/_003_ ));
 sg13g2_a22oi_1 \u_sm/_105_  (.Y(\u_sm/_005_ ),
    .B1(\u_sm/_003_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_002_ ),
    .A1(\u_sm/_000_ ));
 sg13g2_mux4_1 \u_sm/_108_  (.S0(cfg[76]),
    .A0(e_in[2]),
    .A1(\u_sm/net15 ),
    .A2(s_in[2]),
    .A3(\u_sm/net13 ),
    .S1(cfg[74]),
    .X(\u_sm/_008_ ));
 sg13g2_nor2_1 \u_sm/_109_  (.A(cfg[75]),
    .B(\u_sm/_008_ ),
    .Y(\u_sm/_009_ ));
 sg13g2_a21oi_1 \u_sm/_110_  (.A1(cfg[75]),
    .A2(\u_sm/_005_ ),
    .Y(n_out[2]),
    .B1(\u_sm/_009_ ));
 sg13g2_inv_1 \u_sm/_111_  (.Y(\u_sm/_010_ ),
    .A(cfg[77]));
 sg13g2_mux2_1 \u_sm/_112_  (.A0(w_in[3]),
    .A1(\u_sm/net11 ),
    .S(cfg[79]),
    .X(\u_sm/_011_ ));
 sg13g2_nor2b_1 \u_sm/_113_  (.A(cfg[79]),
    .B_N(cfg[77]),
    .Y(\u_sm/_012_ ));
 sg13g2_a22oi_1 \u_sm/_114_  (.Y(\u_sm/_013_ ),
    .B1(\u_sm/_012_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_011_ ),
    .A1(\u_sm/_010_ ));
 sg13g2_mux4_1 \u_sm/_115_  (.S0(cfg[77]),
    .A0(e_in[3]),
    .A1(s_in[3]),
    .A2(\u_sm/net15 ),
    .A3(\u_sm/net13 ),
    .S1(cfg[79]),
    .X(\u_sm/_014_ ));
 sg13g2_nor2_1 \u_sm/_116_  (.A(cfg[78]),
    .B(\u_sm/_014_ ),
    .Y(\u_sm/_015_ ));
 sg13g2_a21oi_1 \u_sm/_117_  (.A1(cfg[78]),
    .A2(\u_sm/_013_ ),
    .Y(n_out[3]),
    .B1(\u_sm/_015_ ));
 sg13g2_inv_1 \u_sm/_118_  (.Y(\u_sm/_016_ ),
    .A(cfg[80]));
 sg13g2_mux2_1 \u_sm/_119_  (.A0(w_in[0]),
    .A1(\u_sm/net11 ),
    .S(cfg[82]),
    .X(\u_sm/_017_ ));
 sg13g2_nor2b_1 \u_sm/_120_  (.A(cfg[82]),
    .B_N(cfg[80]),
    .Y(\u_sm/_018_ ));
 sg13g2_a22oi_1 \u_sm/_121_  (.Y(\u_sm/_019_ ),
    .B1(\u_sm/_018_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_017_ ),
    .A1(\u_sm/_016_ ));
 sg13g2_mux4_1 \u_sm/_122_  (.S0(cfg[80]),
    .A0(n_in[0]),
    .A1(s_in[0]),
    .A2(\u_sm/net15 ),
    .A3(\u_sm/net13 ),
    .S1(cfg[82]),
    .X(\u_sm/_020_ ));
 sg13g2_nor2_1 \u_sm/_123_  (.A(cfg[81]),
    .B(\u_sm/_020_ ),
    .Y(\u_sm/_021_ ));
 sg13g2_a21oi_1 \u_sm/_124_  (.A1(cfg[81]),
    .A2(\u_sm/_019_ ),
    .Y(e_out[0]),
    .B1(\u_sm/_021_ ));
 sg13g2_inv_1 \u_sm/_125_  (.Y(\u_sm/_022_ ),
    .A(cfg[83]));
 sg13g2_mux2_1 \u_sm/_126_  (.A0(w_in[1]),
    .A1(\u_sm/net12 ),
    .S(cfg[85]),
    .X(\u_sm/_023_ ));
 sg13g2_nor2b_1 \u_sm/_127_  (.A(cfg[85]),
    .B_N(cfg[83]),
    .Y(\u_sm/_024_ ));
 sg13g2_a22oi_1 \u_sm/_128_  (.Y(\u_sm/_025_ ),
    .B1(\u_sm/_024_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_023_ ),
    .A1(\u_sm/_022_ ));
 sg13g2_mux4_1 \u_sm/_129_  (.S0(cfg[83]),
    .A0(n_in[1]),
    .A1(s_in[1]),
    .A2(\u_sm/net16 ),
    .A3(\u_sm/net14 ),
    .S1(cfg[85]),
    .X(\u_sm/_026_ ));
 sg13g2_nor2_1 \u_sm/_130_  (.A(cfg[84]),
    .B(\u_sm/_026_ ),
    .Y(\u_sm/_027_ ));
 sg13g2_a21oi_1 \u_sm/_131_  (.A1(cfg[84]),
    .A2(\u_sm/_025_ ),
    .Y(e_out[1]),
    .B1(\u_sm/_027_ ));
 sg13g2_inv_1 \u_sm/_132_  (.Y(\u_sm/_028_ ),
    .A(cfg[86]));
 sg13g2_mux2_1 \u_sm/_133_  (.A0(w_in[2]),
    .A1(\u_sm/net11 ),
    .S(cfg[88]),
    .X(\u_sm/_029_ ));
 sg13g2_nor2b_1 \u_sm/_134_  (.A(cfg[88]),
    .B_N(cfg[86]),
    .Y(\u_sm/_030_ ));
 sg13g2_a22oi_1 \u_sm/_135_  (.Y(\u_sm/_031_ ),
    .B1(\u_sm/_030_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_029_ ),
    .A1(\u_sm/_028_ ));
 sg13g2_mux4_1 \u_sm/_136_  (.S0(cfg[88]),
    .A0(n_in[2]),
    .A1(\u_sm/net15 ),
    .A2(s_in[2]),
    .A3(\u_sm/net13 ),
    .S1(cfg[86]),
    .X(\u_sm/_032_ ));
 sg13g2_nor2_1 \u_sm/_137_  (.A(cfg[87]),
    .B(\u_sm/_032_ ),
    .Y(\u_sm/_033_ ));
 sg13g2_a21oi_1 \u_sm/_138_  (.A1(cfg[87]),
    .A2(\u_sm/_031_ ),
    .Y(e_out[2]),
    .B1(\u_sm/_033_ ));
 sg13g2_inv_1 \u_sm/_139_  (.Y(\u_sm/_034_ ),
    .A(cfg[89]));
 sg13g2_mux2_1 \u_sm/_140_  (.A0(w_in[3]),
    .A1(\u_sm/net11 ),
    .S(cfg[91]),
    .X(\u_sm/_035_ ));
 sg13g2_nor2b_1 \u_sm/_141_  (.A(cfg[91]),
    .B_N(cfg[89]),
    .Y(\u_sm/_036_ ));
 sg13g2_a22oi_1 \u_sm/_142_  (.Y(\u_sm/_037_ ),
    .B1(\u_sm/_036_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_035_ ),
    .A1(\u_sm/_034_ ));
 sg13g2_mux4_1 \u_sm/_143_  (.S0(cfg[89]),
    .A0(n_in[3]),
    .A1(s_in[3]),
    .A2(\u_sm/net15 ),
    .A3(\u_sm/net13 ),
    .S1(cfg[91]),
    .X(\u_sm/_038_ ));
 sg13g2_nor2_1 \u_sm/_144_  (.A(cfg[90]),
    .B(\u_sm/_038_ ),
    .Y(\u_sm/_039_ ));
 sg13g2_a21oi_1 \u_sm/_145_  (.A1(cfg[90]),
    .A2(\u_sm/_037_ ),
    .Y(e_out[3]),
    .B1(\u_sm/_039_ ));
 sg13g2_inv_1 \u_sm/_146_  (.Y(\u_sm/_040_ ),
    .A(cfg[92]));
 sg13g2_mux2_1 \u_sm/_147_  (.A0(w_in[0]),
    .A1(\u_sm/net11 ),
    .S(cfg[94]),
    .X(\u_sm/_041_ ));
 sg13g2_nor2b_1 \u_sm/_148_  (.A(cfg[94]),
    .B_N(cfg[92]),
    .Y(\u_sm/_042_ ));
 sg13g2_a22oi_1 \u_sm/_149_  (.Y(\u_sm/_043_ ),
    .B1(\u_sm/_042_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_041_ ),
    .A1(\u_sm/_040_ ));
 sg13g2_mux4_1 \u_sm/_150_  (.S0(cfg[92]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(\u_sm/net15 ),
    .A3(\u_sm/net13 ),
    .S1(cfg[94]),
    .X(\u_sm/_044_ ));
 sg13g2_nor2_1 \u_sm/_151_  (.A(cfg[93]),
    .B(\u_sm/_044_ ),
    .Y(\u_sm/_045_ ));
 sg13g2_a21oi_1 \u_sm/_152_  (.A1(cfg[93]),
    .A2(\u_sm/_043_ ),
    .Y(s_out[0]),
    .B1(\u_sm/_045_ ));
 sg13g2_inv_1 \u_sm/_153_  (.Y(\u_sm/_046_ ),
    .A(cfg[95]));
 sg13g2_mux2_1 \u_sm/_154_  (.A0(w_in[1]),
    .A1(\u_sm/net11 ),
    .S(cfg[97]),
    .X(\u_sm/_047_ ));
 sg13g2_nor2b_1 \u_sm/_155_  (.A(cfg[97]),
    .B_N(cfg[95]),
    .Y(\u_sm/_048_ ));
 sg13g2_a22oi_1 \u_sm/_156_  (.Y(\u_sm/_049_ ),
    .B1(\u_sm/_048_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_047_ ),
    .A1(\u_sm/_046_ ));
 sg13g2_mux4_1 \u_sm/_157_  (.S0(cfg[95]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(\u_sm/net15 ),
    .A3(\u_sm/net13 ),
    .S1(cfg[97]),
    .X(\u_sm/_050_ ));
 sg13g2_nor2_1 \u_sm/_158_  (.A(cfg[96]),
    .B(\u_sm/_050_ ),
    .Y(\u_sm/_051_ ));
 sg13g2_a21oi_1 \u_sm/_159_  (.A1(cfg[96]),
    .A2(\u_sm/_049_ ),
    .Y(s_out[1]),
    .B1(\u_sm/_051_ ));
 sg13g2_inv_1 \u_sm/_160_  (.Y(\u_sm/_052_ ),
    .A(cfg[98]));
 sg13g2_mux2_1 \u_sm/_161_  (.A0(w_in[2]),
    .A1(\u_sm/net11 ),
    .S(cfg[100]),
    .X(\u_sm/_053_ ));
 sg13g2_nor2b_1 \u_sm/_162_  (.A(cfg[100]),
    .B_N(cfg[98]),
    .Y(\u_sm/_054_ ));
 sg13g2_a22oi_1 \u_sm/_163_  (.Y(\u_sm/_055_ ),
    .B1(\u_sm/_054_ ),
    .B2(\u_sm/net17 ),
    .A2(\u_sm/_053_ ),
    .A1(\u_sm/_052_ ));
 sg13g2_mux4_1 \u_sm/_164_  (.S0(cfg[100]),
    .A0(n_in[2]),
    .A1(\u_sm/net15 ),
    .A2(e_in[2]),
    .A3(\u_sm/net13 ),
    .S1(cfg[98]),
    .X(\u_sm/_056_ ));
 sg13g2_nor2_1 \u_sm/_165_  (.A(cfg[99]),
    .B(\u_sm/_056_ ),
    .Y(\u_sm/_057_ ));
 sg13g2_a21oi_1 \u_sm/_166_  (.A1(cfg[99]),
    .A2(\u_sm/_055_ ),
    .Y(s_out[2]),
    .B1(\u_sm/_057_ ));
 sg13g2_inv_1 \u_sm/_167_  (.Y(\u_sm/_058_ ),
    .A(cfg[101]));
 sg13g2_mux2_1 \u_sm/_168_  (.A0(w_in[3]),
    .A1(\u_sm/net12 ),
    .S(cfg[103]),
    .X(\u_sm/_059_ ));
 sg13g2_nor2b_1 \u_sm/_169_  (.A(cfg[103]),
    .B_N(cfg[101]),
    .Y(\u_sm/_060_ ));
 sg13g2_a22oi_1 \u_sm/_170_  (.Y(\u_sm/_061_ ),
    .B1(\u_sm/_060_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_059_ ),
    .A1(\u_sm/_058_ ));
 sg13g2_mux4_1 \u_sm/_171_  (.S0(cfg[101]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(\u_sm/net16 ),
    .A3(\u_sm/net14 ),
    .S1(cfg[103]),
    .X(\u_sm/_062_ ));
 sg13g2_nor2_1 \u_sm/_172_  (.A(cfg[102]),
    .B(\u_sm/_062_ ),
    .Y(\u_sm/_063_ ));
 sg13g2_a21oi_1 \u_sm/_173_  (.A1(cfg[102]),
    .A2(\u_sm/_061_ ),
    .Y(s_out[3]),
    .B1(\u_sm/_063_ ));
 sg13g2_inv_1 \u_sm/_174_  (.Y(\u_sm/_064_ ),
    .A(cfg[104]));
 sg13g2_mux2_1 \u_sm/_175_  (.A0(s_in[0]),
    .A1(\u_sm/net12 ),
    .S(cfg[106]),
    .X(\u_sm/_065_ ));
 sg13g2_nor2b_1 \u_sm/_176_  (.A(cfg[106]),
    .B_N(cfg[104]),
    .Y(\u_sm/_066_ ));
 sg13g2_a22oi_1 \u_sm/_177_  (.Y(\u_sm/_067_ ),
    .B1(\u_sm/_066_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_065_ ),
    .A1(\u_sm/_064_ ));
 sg13g2_mux4_1 \u_sm/_178_  (.S0(cfg[104]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(\u_sm/net16 ),
    .A3(\u_sm/net14 ),
    .S1(cfg[106]),
    .X(\u_sm/_068_ ));
 sg13g2_nor2_1 \u_sm/_179_  (.A(cfg[105]),
    .B(\u_sm/_068_ ),
    .Y(\u_sm/_069_ ));
 sg13g2_a21oi_1 \u_sm/_180_  (.A1(cfg[105]),
    .A2(\u_sm/_067_ ),
    .Y(w_out[0]),
    .B1(\u_sm/_069_ ));
 sg13g2_inv_1 \u_sm/_181_  (.Y(\u_sm/_070_ ),
    .A(cfg[107]));
 sg13g2_mux2_1 \u_sm/_182_  (.A0(s_in[1]),
    .A1(\u_sm/net12 ),
    .S(cfg[109]),
    .X(\u_sm/_071_ ));
 sg13g2_nor2b_1 \u_sm/_183_  (.A(cfg[109]),
    .B_N(cfg[107]),
    .Y(\u_sm/_072_ ));
 sg13g2_a22oi_1 \u_sm/_184_  (.Y(\u_sm/_073_ ),
    .B1(\u_sm/_072_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_071_ ),
    .A1(\u_sm/_070_ ));
 sg13g2_mux4_1 \u_sm/_185_  (.S0(cfg[107]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(\u_sm/net16 ),
    .A3(\u_sm/net14 ),
    .S1(cfg[109]),
    .X(\u_sm/_074_ ));
 sg13g2_nor2_1 \u_sm/_186_  (.A(cfg[108]),
    .B(\u_sm/_074_ ),
    .Y(\u_sm/_075_ ));
 sg13g2_a21oi_1 \u_sm/_187_  (.A1(cfg[108]),
    .A2(\u_sm/_073_ ),
    .Y(w_out[1]),
    .B1(\u_sm/_075_ ));
 sg13g2_inv_1 \u_sm/_188_  (.Y(\u_sm/_076_ ),
    .A(cfg[110]));
 sg13g2_mux2_1 \u_sm/_189_  (.A0(s_in[2]),
    .A1(\u_sm/net12 ),
    .S(cfg[112]),
    .X(\u_sm/_077_ ));
 sg13g2_nor2b_1 \u_sm/_190_  (.A(cfg[112]),
    .B_N(cfg[110]),
    .Y(\u_sm/_078_ ));
 sg13g2_a22oi_1 \u_sm/_191_  (.Y(\u_sm/_079_ ),
    .B1(\u_sm/_078_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_077_ ),
    .A1(\u_sm/_076_ ));
 sg13g2_mux4_1 \u_sm/_192_  (.S0(cfg[112]),
    .A0(n_in[2]),
    .A1(\u_sm/net16 ),
    .A2(e_in[2]),
    .A3(\u_sm/net14 ),
    .S1(cfg[110]),
    .X(\u_sm/_080_ ));
 sg13g2_nor2_1 \u_sm/_193_  (.A(cfg[111]),
    .B(\u_sm/_080_ ),
    .Y(\u_sm/_081_ ));
 sg13g2_a21oi_1 \u_sm/_194_  (.A1(cfg[111]),
    .A2(\u_sm/_079_ ),
    .Y(w_out[2]),
    .B1(\u_sm/_081_ ));
 sg13g2_inv_1 \u_sm/_195_  (.Y(\u_sm/_082_ ),
    .A(cfg[113]));
 sg13g2_mux2_1 \u_sm/_196_  (.A0(s_in[3]),
    .A1(\u_sm/net12 ),
    .S(cfg[115]),
    .X(\u_sm/_083_ ));
 sg13g2_nor2b_1 \u_sm/_197_  (.A(cfg[115]),
    .B_N(cfg[113]),
    .Y(\u_sm/_084_ ));
 sg13g2_a22oi_1 \u_sm/_198_  (.Y(\u_sm/_085_ ),
    .B1(\u_sm/_084_ ),
    .B2(bel_o[0]),
    .A2(\u_sm/_083_ ),
    .A1(\u_sm/_082_ ));
 sg13g2_mux4_1 \u_sm/_199_  (.S0(cfg[113]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(bel_o[1]),
    .A3(bel_o[2]),
    .S1(cfg[115]),
    .X(\u_sm/_086_ ));
 sg13g2_nor2_1 \u_sm/_200_  (.A(cfg[114]),
    .B(\u_sm/_086_ ),
    .Y(\u_sm/_087_ ));
 sg13g2_a21oi_1 \u_sm/_201_  (.A1(cfg[114]),
    .A2(\u_sm/_085_ ),
    .Y(w_out[3]),
    .B1(\u_sm/_087_ ));
 sg13g2_mux4_1 \u_sm/_202_  (.S0(cfg[116]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[117]),
    .X(lut_in[0]));
 sg13g2_mux4_1 \u_sm/_203_  (.S0(cfg[118]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(s_in[1]),
    .A3(w_in[1]),
    .S1(cfg[119]),
    .X(lut_in[1]));
 sg13g2_mux4_1 \u_sm/_204_  (.S0(cfg[120]),
    .A0(n_in[2]),
    .A1(e_in[2]),
    .A2(s_in[2]),
    .A3(w_in[2]),
    .S1(cfg[121]),
    .X(lut_in[2]));
 sg13g2_mux4_1 \u_sm/_205_  (.S0(cfg[122]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(s_in[3]),
    .A3(w_in[3]),
    .S1(cfg[123]),
    .X(lut_in[3]));
 sg13g2_mux4_1 \u_sm/_206_  (.S0(cfg[124]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[125]),
    .X(lut_in[4]));
 sg13g2_mux4_1 \u_sm/_207_  (.S0(cfg[126]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(s_in[1]),
    .A3(w_in[1]),
    .S1(cfg[127]),
    .X(lut_in[5]));
 sg13g2_inv_1 \u_sm/_208_  (.Y(\u_sm/_088_ ),
    .A(cfg[72]));
 sg13g2_mux2_1 \u_sm/_209_  (.A0(s_in[1]),
    .A1(\u_sm/net14 ),
    .S(cfg[73]),
    .X(\u_sm/_089_ ));
 sg13g2_nor2b_1 \u_sm/_210_  (.A(cfg[73]),
    .B_N(cfg[72]),
    .Y(\u_sm/_090_ ));
 sg13g2_a22oi_1 \u_sm/_211_  (.Y(\u_sm/_091_ ),
    .B1(\u_sm/_090_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_089_ ),
    .A1(\u_sm/_088_ ));
 sg13g2_mux4_1 \u_sm/_212_  (.S0(cfg[72]),
    .A0(e_in[1]),
    .A1(w_in[1]),
    .A2(\u_sm/net16 ),
    .A3(bel_o[3]),
    .S1(cfg[73]),
    .X(\u_sm/_092_ ));
 sg13g2_nor2_1 \u_sm/_213_  (.A(cfg[71]),
    .B(\u_sm/_092_ ),
    .Y(\u_sm/_093_ ));
 sg13g2_a21oi_1 \u_sm/_214_  (.A1(cfg[71]),
    .A2(\u_sm/_091_ ),
    .Y(n_out[1]),
    .B1(\u_sm/_093_ ));
 sg13g2_mux4_1 \u_sm/_215_  (.S0(cfg[128]),
    .A0(n_in[2]),
    .A1(e_in[2]),
    .A2(s_in[2]),
    .A3(w_in[2]),
    .S1(cfg[129]),
    .X(lut_in[6]));
 sg13g2_mux4_1 \u_sm/_216_  (.S0(cfg[130]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(s_in[3]),
    .A3(w_in[3]),
    .S1(cfg[131]),
    .X(lut_in[7]));
 sg13g2_mux4_1 \u_sm/_217_  (.S0(cfg[132]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[133]),
    .X(lut_in[8]));
 sg13g2_mux4_1 \u_sm/_218_  (.S0(cfg[134]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(s_in[1]),
    .A3(w_in[1]),
    .S1(cfg[135]),
    .X(lut_in[9]));
 sg13g2_mux4_1 \u_sm/_219_  (.S0(cfg[136]),
    .A0(n_in[2]),
    .A1(e_in[2]),
    .A2(s_in[2]),
    .A3(w_in[2]),
    .S1(cfg[137]),
    .X(lut_in[10]));
 sg13g2_mux4_1 \u_sm/_220_  (.S0(cfg[138]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(s_in[3]),
    .A3(w_in[3]),
    .S1(cfg[139]),
    .X(lut_in[11]));
 sg13g2_mux4_1 \u_sm/_221_  (.S0(cfg[140]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[141]),
    .X(lut_in[12]));
 sg13g2_mux4_1 \u_sm/_222_  (.S0(cfg[142]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(s_in[1]),
    .A3(w_in[1]),
    .S1(cfg[143]),
    .X(lut_in[13]));
 sg13g2_inv_1 \u_sm/_223_  (.Y(\u_sm/_094_ ),
    .A(cfg[68]));
 sg13g2_mux2_1 \u_sm/_224_  (.A0(w_in[0]),
    .A1(\u_sm/net12 ),
    .S(cfg[70]),
    .X(\u_sm/_095_ ));
 sg13g2_nor2b_1 \u_sm/_225_  (.A(cfg[70]),
    .B_N(cfg[68]),
    .Y(\u_sm/_096_ ));
 sg13g2_a22oi_1 \u_sm/_226_  (.Y(\u_sm/_097_ ),
    .B1(\u_sm/_096_ ),
    .B2(\u_sm/net18 ),
    .A2(\u_sm/_095_ ),
    .A1(\u_sm/_094_ ));
 sg13g2_mux4_1 \u_sm/_227_  (.S0(cfg[68]),
    .A0(e_in[0]),
    .A1(s_in[0]),
    .A2(\u_sm/net16 ),
    .A3(\u_sm/net14 ),
    .S1(cfg[70]),
    .X(\u_sm/_098_ ));
 sg13g2_nor2_1 \u_sm/_228_  (.A(cfg[69]),
    .B(\u_sm/_098_ ),
    .Y(\u_sm/_099_ ));
 sg13g2_a21oi_1 \u_sm/_229_  (.A1(cfg[69]),
    .A2(\u_sm/_097_ ),
    .Y(n_out[0]),
    .B1(\u_sm/_099_ ));
 sg13g2_mux4_1 \u_sm/_230_  (.S0(cfg[144]),
    .A0(n_in[2]),
    .A1(e_in[2]),
    .A2(s_in[2]),
    .A3(w_in[2]),
    .S1(cfg[145]),
    .X(lut_in[14]));
 sg13g2_mux4_1 \u_sm/_231_  (.S0(cfg[146]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(s_in[3]),
    .A3(w_in[3]),
    .S1(cfg[147]),
    .X(lut_in[15]));
 sg13g2_mux4_1 \u_sm/_232_  (.S0(cfg[148]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[149]),
    .X(bel_sr[0]));
 sg13g2_mux4_1 \u_sm/_233_  (.S0(cfg[150]),
    .A0(n_in[0]),
    .A1(e_in[0]),
    .A2(s_in[0]),
    .A3(w_in[0]),
    .S1(cfg[151]),
    .X(bel_en[0]));
 sg13g2_mux4_1 \u_sm/_234_  (.S0(cfg[152]),
    .A0(n_in[1]),
    .A1(e_in[1]),
    .A2(s_in[1]),
    .A3(w_in[1]),
    .S1(cfg[153]),
    .X(bel_en[1]));
 sg13g2_mux4_1 \u_sm/_235_  (.S0(cfg[154]),
    .A0(n_in[2]),
    .A1(e_in[2]),
    .A2(s_in[2]),
    .A3(w_in[2]),
    .S1(cfg[155]),
    .X(bel_en[2]));
 sg13g2_mux4_1 \u_sm/_236_  (.S0(cfg[156]),
    .A0(n_in[3]),
    .A1(e_in[3]),
    .A2(s_in[3]),
    .A3(w_in[3]),
    .S1(cfg[157]),
    .X(bel_en[3]));
 sg13g2_buf_1 \u_sm/place11  (.A(bel_o[3]),
    .X(\u_sm/net11 ));
 sg13g2_buf_1 \u_sm/place12  (.A(bel_o[3]),
    .X(\u_sm/net12 ));
 sg13g2_buf_1 \u_sm/place13  (.A(\u_sm/net14 ),
    .X(\u_sm/net13 ));
 sg13g2_buf_1 \u_sm/place14  (.A(bel_o[2]),
    .X(\u_sm/net14 ));
 sg13g2_buf_1 \u_sm/place15  (.A(\u_sm/net16 ),
    .X(\u_sm/net15 ));
 sg13g2_buf_1 \u_sm/place16  (.A(bel_o[1]),
    .X(\u_sm/net16 ));
 sg13g2_buf_1 \u_sm/place17  (.A(\u_sm/net18 ),
    .X(\u_sm/net17 ));
 sg13g2_buf_1 \u_sm/place18  (.A(bel_o[0]),
    .X(\u_sm/net18 ));
endmodule
