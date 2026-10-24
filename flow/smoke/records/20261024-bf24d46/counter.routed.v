module counter (clk,
    rst,
    q);
 input clk;
 input rst;
 output [7:0] q;

 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _07_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
 wire _15_;
 wire _16_;
 wire _17_;
 wire _18_;
 wire _19_;
 wire _20_;
 wire _21_;
 wire _22_;
 wire _23_;
 wire _24_;
 wire _25_;
 wire _26_;
 wire _27_;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sg13g2_and4_1 _28_ (.A(q[0]),
    .B(q[1]),
    .C(q[2]),
    .D(q[3]),
    .X(_08_));
 sg13g2_and3_1 _29_ (.X(_09_),
    .A(q[4]),
    .B(q[5]),
    .C(_08_));
 sg13g2_inv_1 _30_ (.Y(_10_),
    .A(rst));
 sg13g2_o21ai_1 _31_ (.B1(_10_),
    .Y(_11_),
    .A1(q[6]),
    .A2(_09_));
 sg13g2_nand4_1 _32_ (.B(q[5]),
    .C(q[6]),
    .A(q[4]),
    .Y(_12_),
    .D(_08_));
 sg13g2_nor2b_1 _33_ (.A(_11_),
    .B_N(_12_),
    .Y(_00_));
 sg13g2_a21oi_1 _34_ (.A1(q[4]),
    .A2(_08_),
    .Y(_13_),
    .B1(q[5]));
 sg13g2_nor3_1 _35_ (.A(rst),
    .B(_09_),
    .C(_13_),
    .Y(_01_));
 sg13g2_o21ai_1 _36_ (.B1(_10_),
    .Y(_14_),
    .A1(q[4]),
    .A2(_08_));
 sg13g2_a21oi_1 _37_ (.A1(q[4]),
    .A2(_08_),
    .Y(_02_),
    .B1(_14_));
 sg13g2_and3_1 _38_ (.X(_15_),
    .A(q[0]),
    .B(q[1]),
    .C(q[2]));
 sg13g2_o21ai_1 _39_ (.B1(_10_),
    .Y(_16_),
    .A1(q[3]),
    .A2(_15_));
 sg13g2_nor2_1 _40_ (.A(_08_),
    .B(_16_),
    .Y(_03_));
 sg13g2_a21oi_1 _41_ (.A1(q[0]),
    .A2(q[1]),
    .Y(_17_),
    .B1(q[2]));
 sg13g2_nor3_1 _42_ (.A(rst),
    .B(_15_),
    .C(_17_),
    .Y(_04_));
 sg13g2_o21ai_1 _43_ (.B1(_10_),
    .Y(_18_),
    .A1(q[0]),
    .A2(q[1]));
 sg13g2_a21oi_1 _44_ (.A1(q[0]),
    .A2(q[1]),
    .Y(_05_),
    .B1(_18_));
 sg13g2_xor2_1 _45_ (.B(_12_),
    .A(q[7]),
    .X(_19_));
 sg13g2_nor2_1 _46_ (.A(rst),
    .B(_19_),
    .Y(_06_));
 sg13g2_nor2_1 _47_ (.A(q[0]),
    .B(rst),
    .Y(_07_));
 sg13g2_dfrbpq_1 _48_ (.RESET_B(_23_),
    .D(_07_),
    .Q(q[0]),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_dfrbpq_1 _49_ (.RESET_B(_25_),
    .D(_05_),
    .Q(q[1]),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_dfrbpq_1 _50_ (.RESET_B(_26_),
    .D(_04_),
    .Q(q[2]),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_dfrbpq_1 _51_ (.RESET_B(_27_),
    .D(_03_),
    .Q(q[3]),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_dfrbpq_1 _52_ (.RESET_B(_20_),
    .D(_02_),
    .Q(q[4]),
    .CLK(clknet_1_1__leaf_clk));
 sg13g2_dfrbpq_1 _53_ (.RESET_B(_21_),
    .D(_01_),
    .Q(q[5]),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_dfrbpq_1 _54_ (.RESET_B(_22_),
    .D(_00_),
    .Q(q[6]),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_dfrbpq_1 _55_ (.RESET_B(_24_),
    .D(_06_),
    .Q(q[7]),
    .CLK(clknet_1_0__leaf_clk));
 sg13g2_tiehi _56_ (.L_HI(_20_));
 sg13g2_tiehi _57_ (.L_HI(_21_));
 sg13g2_tiehi _58_ (.L_HI(_22_));
 sg13g2_tiehi _59_ (.L_HI(_23_));
 sg13g2_tiehi _60_ (.L_HI(_24_));
 sg13g2_tiehi _61_ (.L_HI(_25_));
 sg13g2_tiehi _62_ (.L_HI(_26_));
 sg13g2_tiehi _63_ (.L_HI(_27_));
 sg13g2_buf_16 clkbuf_0_clk (.X(clknet_0_clk),
    .A(clk));
 sg13g2_buf_16 clkbuf_1_0__f_clk (.X(clknet_1_0__leaf_clk),
    .A(clknet_0_clk));
 sg13g2_buf_16 clkbuf_1_1__f_clk (.X(clknet_1_1__leaf_clk),
    .A(clknet_0_clk));
endmodule
