// tb_blinky.v (issue #138): the self-checking simulation behind
// verification/blinky.sh -- the example a newcomer runs to see a freshly
// built bitstream blink. The stream mapped and assembled by blinky.sh from
// verification/blinky/blinky.v is loaded through a sim-only model of the
// FABulous frame interface into the 158-bit `cfg` of
// rtl/common/rtl/logic_tile_routed.v (the same loader contract as
// tb_logic_tile_bitstream.v: +bin= +map= +wiring=, no hand-written
// configuration), then the harness drives rst/en and samples the routed q
// pad: after reset 0, then 1, 0, 1, 0 on four enabled clock edges. A stuck,
// unknown or mistimed sample is a FAIL; blinky.sh fails the command on the
// FAIL line.
//
// Scope: the single-LOGIC4 harness exactly as tb_logic_tile_bitstream.v
// describes it (same-index stand-in switch matrix, CAP loopbacks -- here
// carrying the design's own feedback net --, scratch pad overlay). No
// timing, no inter-tile routing; the frame interface is a model, not the
// generated ConfigMem.
`timescale 1ns/1ps

module tb_blinky;

    // ---------------------------------------------------------------- DUT
    reg          clk = 1'b0;
    reg  [157:0] cfg = 158'b0;
    reg  [15:0]  tin;           // tin[4*dir + idx], dir: 0=N 1=E 2=S 3=W
    wire [15:0]  tout;

    logic_tile_routed dut (
        .clk(clk), .cfg(cfg),
        .n_in(tin[3:0]),  .e_in(tin[7:4]),  .s_in(tin[11:8]),  .w_in(tin[15:12]),
        .n_out(tout[3:0]), .e_out(tout[7:4]), .s_out(tout[11:8]), .w_out(tout[15:12])
    );

    // ----------------------------------------------------------- checks
    integer checks = 0;
    integer fails  = 0;

    task chk(input cond, input [8*48-1:0] what);
        begin
            checks = checks + 1;
            if (!cond) fails = fails + 1;
        end
    endtask

    // ------------------------------------------------------------- plusargs
    reg [8*256-1:0] f_bin, f_map, f_wire;

    // ------------------------------------------------- FABulous stream format
    // Same constants as tb_logic_tile_bitstream.v (the loader contract).
    localparam CFG_N = 158;
    localparam FBITS = 32, NFR = 20, SELW = 5, DESYNC_BIT = 20;
    localparam [159:0] SYNC = 160'h00AAFF01000000010000000000000000FAB0FAB1;

    // ------------------------------------------------- manifest / wiring state
    integer grid_cols, grid_rows, lx, ly;
    // input-track source: 0 = unused, 1 = pad slot, 2 = CAP loopback from an
    // output track (the routed feedback net of the divider closes here)
    integer tin_kind [0:15];
    integer tin_arg  [0:15];
    integer out_track [0:7];      // output slot -> logic output track (-1 = unwired)
    reg [7:0] slot_wired_in;
    reg [7:0] slot_wired_out;

    // input pad slots / output pad slots (same slots as tb_logic_tile_bitstream)
    function integer in_slot(input [8*8-1:0] nm);
        begin
            in_slot = (nm == "a") ? 0 : (nm == "b") ? 1 : (nm == "c") ? 2 :
                      (nm == "d") ? 3 : (nm == "en") ? 4 : (nm == "rst") ? 5 :
                      (nm == "e") ? 6 : (nm == "f") ? 7 : -1;
        end
    endfunction
    function integer out_slot(input [8*8-1:0] nm);
        begin
            out_slot = (nm == "y") ? 0 : (nm == "w") ? 1 : (nm == "q") ? 2 :
                       (nm == "v") ? 3 : (nm == "z") ? 4 : -1;
        end
    endfunction

    reg [7:0] pad_in;             // harness values driven on the input pads
    reg [15:0] unused;            // harness value on input tracks nothing is routed to

    integer t;
    // The CAP loopback carries a 100 ps transport delay (same as
    // tb_logic_tile_bitstream.v): the divider's feedback cycle must advance
    // in simulated time, and a stale X must not survive a flush unnoticed.
    reg flush = 1'b0;
    always @(pad_in or tout or unused or flush) begin
        for (t = 0; t < 16; t = t + 1)
            case (tin_kind[t])
                1:       tin[t] = pad_in[tin_arg[t]];
                2:       tin[t] <= #0.1 (flush ? 1'b0 : tout[tin_arg[t]]);
                default: tin[t] = unused[t];
            endcase
    end

    function pad_out(input integer slot);
        begin pad_out = tout[out_track[slot]]; end
    endfunction

    // ------------------------------------------------------------ the loader
    reg [8*80-1:0] reject_reason;
    reg            load_ok;
    integer cb_pos [0:CFG_N-1];
    reg [31:0] mapped_mask [0:NFR-1];
    reg [31:0] logic_frame [0:NFR-1];
    reg        seen_frame  [0:(8*NFR)-1];
    integer    fd;

    task rd_word(output [31:0] w, output ok);
        integer i, b;
        begin
            w = 0; ok = 1'b1;
            for (i = 0; i < FBITS/8; i = i + 1) begin
                b = $fgetc(fd);
                if (b < 0) ok = 1'b0;
                else w = {w[23:0], b[7:0]};
            end
        end
    endtask

    task reject(input [8*80-1:0] why);
        begin
            if (load_ok) reject_reason = why;
            load_ok = 1'b0;
        end
    endtask

    task load_bitstream;
        reg [31:0] w, fw;
        reg ok;
        integer i, col, frame, nframes, row, strobe_pop, done;
        reg [FBITS-NFR-SELW-1:0] reserved;
        reg [NFR-1:0] strobe;
        reg [159:0] hdr;
        integer b;
        begin
            load_ok = 1'b1; reject_reason = "";
            for (i = 0; i < NFR; i = i + 1) logic_frame[i] = 32'b0;
            for (i = 0; i < 8*NFR; i = i + 1) seen_frame[i] = 1'b0;
            fd = $fopen(f_bin, "rb");
            if (fd == 0) begin reject("cannot open bitstream"); disable load_bitstream; end
            hdr = 0;
            for (i = 0; i < 20; i = i + 1) begin
                b = $fgetc(fd);
                if (b < 0) begin reject("truncated sync header"); i = 99; end
                else hdr = {hdr[151:0], b[7:0]};
            end
            if (load_ok && hdr !== SYNC) reject("bad sync header");
            nframes = 0; done = 0;
            while (load_ok && !done) begin
                rd_word(w, ok);
                if (!ok) reject("truncated: no desync word");
                else if (w[DESYNC_BIT] && w[FBITS-1:FBITS-SELW] == 0 && w[NFR-1:0] == 0) begin
                    if (w !== (32'b1 << DESYNC_BIT)) reject("malformed desync word");
                    done = 1;
                end else begin
                    col = w[FBITS-1:FBITS-SELW];
                    reserved = w[FBITS-SELW-1:NFR];
                    strobe = w[NFR-1:0];
                    strobe_pop = 0;
                    for (i = 0; i < NFR; i = i + 1) if (strobe[i]) begin strobe_pop = strobe_pop + 1; frame = i; end
                    if (reserved != 0 || strobe_pop != 1 || col >= grid_cols) begin
                        reject("invalid frame-select word");
                    end else if (seen_frame[col*NFR + frame]) begin
                        reject("duplicate frame");
                    end else begin
                        seen_frame[col*NFR + frame] = 1'b1;
                        nframes = nframes + 1;
                        // interior rows, Y descending: row index grid_rows-2 .. 1
                        for (row = 0; row < grid_rows - 2; row = row + 1) begin
                            rd_word(fw, ok);
                            if (!ok) reject("truncated frame data");
                            else if (col == lx && (grid_rows - 2 - row) == ly) begin
                                logic_frame[frame] = fw;
                            end else if (fw != 0) begin
                                reject("data for a tile without config bits");
                            end
                        end
                    end
                end
            end
            if (load_ok) begin
                if ($fgetc(fd) >= 0) reject("trailing data after desync");
                if (nframes != grid_cols * NFR) reject("incomplete frame set");
            end
            $fclose(fd);
            // frame bits -> cfg through the generated ConfigMem map
            if (load_ok) begin
                for (i = 0; i < NFR; i = i + 1)
                    if ((logic_frame[i] & ~mapped_mask[i]) != 0) reject("set bit at an unmapped frame position");
            end
            if (load_ok)
                for (i = 0; i < CFG_N; i = i + 1)
                    cfg[i] = logic_frame[cb_pos[i] / FBITS][cb_pos[i] % FBITS];
        end
    endtask

    // -------------------------------------------------- manifest / map readers
    task read_map;
        integer i, cb, pos, r;
        begin
            for (i = 0; i < NFR; i = i + 1) mapped_mask[i] = 32'b0;
            for (i = 0; i < CFG_N; i = i + 1) cb_pos[i] = -1;
            fd = $fopen(f_map, "r");
            if (fd == 0) begin $display("FAIL: tb_blinky: cannot open map"); $finish; end
            r = $fscanf(fd, "%d %d", cb, pos);
            while (r == 2) begin
                cb_pos[cb] = pos;
                mapped_mask[pos / FBITS][pos % FBITS] = 1'b1;
                r = $fscanf(fd, "%d %d", cb, pos);
            end
            $fclose(fd);
            for (i = 0; i < CFG_N; i = i + 1)
                if (cb_pos[i] < 0) begin $display("FAIL: tb_blinky: map misses cfg bit %0d", i); $finish; end
        end
    endtask

    task read_manifest;
        reg [8*8-1:0] kw, nm;
        integer d, k, a, b, s, r, ok_all, i, end_seen;
        begin
            for (i = 0; i < 16; i = i + 1) begin tin_kind[i] = 0; tin_arg[i] = 0; end
            for (i = 0; i < 8; i = i + 1) out_track[i] = -1;
            slot_wired_in = 0; slot_wired_out = 0;
            ok_all = 1; end_seen = 0;
            fd = $fopen(f_wire, "r");
            if (fd == 0) begin $display("FAIL: tb_blinky: cannot open wiring manifest"); $finish; end
            r = $fscanf(fd, "%s", kw);
            while (r == 1 && !end_seen) begin
                if (kw == "GRID") r = $fscanf(fd, "%d %d", grid_cols, grid_rows);
                else if (kw == "TILE") r = $fscanf(fd, "%d %d", lx, ly);
                else if (kw == "IN") begin
                    r = $fscanf(fd, "%s %d %d", nm, d, k);
                    s = in_slot(nm);
                    if (s < 0 || tin_kind[4*d + k] != 0) ok_all = 0;
                    else begin tin_kind[4*d + k] = 1; tin_arg[4*d + k] = s; slot_wired_in[s] = 1'b1; end
                end else if (kw == "OUT") begin
                    r = $fscanf(fd, "%s %d %d", nm, d, k);
                    s = out_slot(nm);
                    if (s < 0) ok_all = 0;
                    else begin out_track[s] = 4*d + k; slot_wired_out[s] = 1'b1; end
                end else if (kw == "LOOP") begin
                    // logic output track (a,b) -> CAP loopback -> logic input track (c,d);
                    // for blinky this is the divider's own feedback net
                    r = $fscanf(fd, "%d %d %d %d", a, b, d, k);
                    if (tin_kind[4*d + k] != 0) ok_all = 0;
                    else begin tin_kind[4*d + k] = 2; tin_arg[4*d + k] = 4*a + b; end
                end else if (kw == "BEL" || kw == "SEL") begin
                    // recorded for provenance; blinky's check is directed, not exhaustive
                    r = $fscanf(fd, "%d", a);
                end else if (kw == "END") end_seen = 1;
                else ok_all = 0;
                if (!end_seen) r = $fscanf(fd, "%s", kw);
            end
            $fclose(fd);
            if (!ok_all || !end_seen) begin $display("FAIL: tb_blinky: bad wiring manifest"); $finish; end
        end
    endtask

    // ------------------------------------------------------ harness utilities
    task pulse;
        begin clk = 1'b1; #5; clk = 1'b0; #5; end
    endtask

    // ------------------------------------------------------------------ main
    // The example's claim, checked against the routed pad: after reset the
    // output reads 0 and then toggles on every enabled clock edge. The
    // expected sequence is the example's spec (verification/blinky/):
    //   0, 1, 0, 1, 0
    localparam NSAMPLE = 5;
    localparam [NSAMPLE-1:0] EXP = 5'b01010;    // EXP[i]: expected i-th sample
    localparam [8*16-1:0] EXP_TXT = "0, 1, 0, 1, 0";

    integer s, oc;
    reg v;
    reg [8*32-1:0] observed;

    // The observed sequence is accumulated by hand (part-select appends) rather
    // than with $sformatf: Icarus 13.0 aborts at compile time on $sformatf
    // inside a concatenation (ivl draw_eval_vec4 assertion, issue #138).
    task append_sample(input bitval, input integer first);
        begin
            if (!first) begin observed[oc*8 +: 16] = ", "; oc = oc + 2; end
            observed[oc*8 +: 8] = bitval ? "1" : "0";
            oc = oc + 1;
        end
    endtask

    initial begin
        pad_in = 8'b0; unused = 16'b0;
        tin = 16'b0;
        if (!$value$plusargs("bin=%s", f_bin) || !$value$plusargs("map=%s", f_map) ||
            !$value$plusargs("wiring=%s", f_wire)) begin
            $display("FAIL: tb_blinky: need +bin= +map= +wiring=");
            $finish;
        end

        read_map;
        read_manifest;
        // the divider needs en, rst wired to pads and q routed out
        if (!slot_wired_in[4] || !slot_wired_in[5] || !slot_wired_out[2]) begin
            $display("FAIL: tb_blinky: manifest lacks en/rst/q"); $finish;
        end
        if (out_track[2] < 0) begin $display("FAIL: tb_blinky: q is not routed to a pad"); $finish; end

        load_bitstream;
        if (!load_ok) begin
            $display("FAIL: tb_blinky: loader rejected the stream: %0s", reject_reason);
            $finish;
        end

        // defined reset state through the programmed fabric: one edge with
        // rst asserted (reset over enable), then sample
        pad_in[4] = 1'b1;  // en, asserted for the whole trace
        pad_in[5] = 1'b1;  // rst
        flush = 1'b1; #1; flush = 1'b0; #1;
        #1; pulse;
        pad_in[5] = 1'b0;  // rst released; en stays asserted
        #1;
        observed = "";
        oc = 0;
        v = pad_out(2);    // sample 0: right after the reset edge
        chk(v === EXP[0], "sampled q pad");
        append_sample(v, 1);
        for (s = 1; s < NSAMPLE; s = s + 1) begin
            #4;
            chk(pad_out(2) === v, "q holds until the next edge");
            pulse;             // enabled edge: the divider toggles
            #1;
            v = pad_out(2);
            chk(v === EXP[s], "sampled q pad");
            append_sample(v, 0);
        end
        $display("blinky q = %0s", observed);
        if (fails == 0)
            $display("PASS: tb_blinky q = %0s (%0d checks, 0 failures)", EXP_TXT, checks);
        else
            $display("FAIL: tb_blinky q = %0s, expected %0s (%0d checks, %0d failures)",
                     observed, EXP_TXT, checks, fails);
        $finish;
    end

endmodule
