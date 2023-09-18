/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-10-2017 */

// Ghosts'n Goblins: Main CPU

module jtgng_main(
    input              clk,
    input              clk_dma,
    input              cen6,
    output             cpu_cen,
    input              rst,
    input              LVBL,   // vertical blanking when 0
    input              block_flash,
    output  reg        blue_cs,
    output  reg        redgreen_cs,
    output  reg        flip,
    // Sound
    output  reg        sres_b, // Z80 reset
    output  reg [7:0]  snd_latch,
    // Characters
    input       [7:0]  char_dout,
    output      [7:0]  cpu_dout,
    output  reg        char_cs,
    input              char_busy,
    // scroll
    input       [7:0]  scr_dout,
    output  reg        scr_cs,
    input              scr_busy,
    output  reg [8:0]  scr_hpos,
    output  reg [8:0]  scr_vpos,
    input              scr_holdn,
    // cabinet I/O
    input       [1:0]  start_button,
    input       [1:0]  coin_input,
    input       [5:0]  joystick1,
    input       [5:0]  joystick2,
    // BUS sharing
    output             bus_ack,
    input              bus_req,
    input              blcnten,
    input   [ 8:0]     obj_AB,
    output  [12:0]     cpu_AB,
    output             RnW,
    output reg         OKOUT,
    output  [7:0]      dma_dout,
    // ROM access
    output  reg        rom_cs,
    output  reg [16:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,
    // DIP switches
    input              service,
    input              dip_pause,
    input  [7:0]       dipsw_a,
    input  [7:0]       dipsw_b
);

wire [15:0] A;
wire [ 7:0] ram_dout;
wire        nRESET, bus_busy, nIRQ, irq_ack;
reg         sound_cs, scrpos_cs, in_cs, flip_cs, ram_cs, bank_cs;
reg  [ 7:0] cpu_din, cabinet_input;

assign bus_busy = scr_busy | char_busy;
assign bus_ack  = 1;
assign cpu_AB   = A[12:0];

always @(*) begin
    sound_cs    = 1'b0;
    OKOUT       = 1'b0;
    scrpos_cs   = 1'b0;
    scr_cs      = 1'b0;
    in_cs       = 1'b0;
    blue_cs     = 1'b0;
    redgreen_cs = 1'b0;
    flip_cs     = 1'b0;
    ram_cs      = 1'b0;
    char_cs     = 1'b0;
    bank_cs     = 1'b0;
    rom_cs      = 1'b0;
    if( nRESET ) case(A[15:13])
        3'b000: ram_cs = 1'b1;
        3'b001: case( A[12:11])
                2'd0: char_cs = 1'b1;
                2'd1: scr_cs  = 1'b1;
                2'd2: in_cs   = 1'b1;
                2'd3: case( A[10:8] )
                    3'd0: redgreen_cs = block_flash ? ~LVBL : 1'b1;
                    3'd1: blue_cs     = block_flash ? ~LVBL : 1'b1;
                    3'd2: sound_cs    = 1'b1;
                    3'd3: scrpos_cs   = 1'b1;
                    3'd4: OKOUT       = 1'b1;
                    3'd5: flip_cs     = 1'b1;
                    3'd6: bank_cs     = 1'b1;
                    default:;
                endcase
            endcase
        default: rom_cs = 1'b1;
    endcase
end

// SCROLL H/V POSITION
always @(posedge clk or negedge nRESET)
    if( !nRESET ) begin
        scr_hpos <= 0;
        scr_vpos <= 0;
    end else if( cpu_cen ) begin
        if( scrpos_cs && A[3] && scr_holdn)
        case(A[1:0])
            2'd0: scr_hpos[7:0] <= cpu_dout;
            2'd1: scr_hpos[8]   <= cpu_dout[0];
            2'd2: scr_vpos[7:0] <= cpu_dout;
            2'd3: scr_vpos[8]   <= cpu_dout[0];
        endcase
    end

// special registers
reg [2:0] bank;
always @(posedge clk or negedge nRESET)
    if( !nRESET ) begin
        bank   <= 3'd0;
    end
    else if( cpu_cen ) begin
        if( bank_cs && !RnW ) begin
            bank <= cpu_dout[2:0];
        end
    end

// CPU reset
jt12_rst u_rst(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .rst_n  ( nRESET    )
);

always @(posedge clk) begin
    if( rst ) begin
        flip <= 1'b0;
        sres_b <= 1'b1;
    end else if( cpu_cen ) begin
        if( flip_cs )
            case(A[2:0])
                3'd0: flip <= ~cpu_dout[0];
                3'd1: sres_b <= cpu_dout[0];
                // 2,3: coin counters
                default:;
            endcase
    end
end

always @(posedge clk) begin
    if( rst )
        snd_latch <= 8'd0;
    else if( cpu_cen ) begin
        if( sound_cs ) snd_latch <= cpu_dout;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cabinet_input <= 0;
    end else begin
        case( cpu_AB[3:0])
            0: cabinet_input <= { coin_input, // COINS
                         service,
                         1'b1, // tilt?
                         2'h3, // undocumented. The game start screen has background when set to 0!
                         start_button }; // START
            1: cabinet_input <= { 2'b11, joystick1 };
            2: cabinet_input <= { 2'b11, joystick2 };
            3: cabinet_input <= dipsw_a;
            4: cabinet_input <= dipsw_b;
            default: cabinet_input <= 8'hff;
        endcase
    end
end

always @(*) begin
    case( {ram_cs, char_cs, scr_cs, rom_cs, in_cs} )
        5'b10_000: cpu_din =  ram_dout;
        5'b01_000: cpu_din =  char_dout;
        5'b00_100: cpu_din =  scr_dout;
        5'b00_010: cpu_din =  rom_data;
        5'b00_001: cpu_din =  cabinet_input;
        default:   cpu_din =  rom_data;
    endcase
end

always @(A,bank) begin
    rom_addr[12:0] = A[12:0];
    casez( A[15:13] )
        3'b1??: rom_addr[16:13] = { 2'h0, A[14:13] }; // 8N, 9N (32kB) 0x8000-0xFFFF
        3'b011: rom_addr[16:13] = 4'b101; // 10N - 0x6000-0x7FFF (8kB)
        3'b010:  // 0x4000-0x5FFF
          rom_addr[16:13] = bank==3'd4 ? 4'b100 : {2'd0,bank[1:0]}+4'b110; // 13N
        default: rom_addr[16:13] = 4'd0;
    endcase
end

jtframe_ff u_ff (
    .clk    ( clk       ),
    .rst    ( rst       ),
    .cen    ( cen6      ),
    .din    ( dip_pause ),
    .q      (           ),
    .qn     ( nIRQ      ),
    .set    (           ),
    .clr    ( irq_ack   ),
    .sigedge( ~LVBL     )
);

jtframe_sys6809_dma #(
    .RAM_AW     ( 13        )
) u_sys6809(
    .rstn       ( nRESET    ),
    .clk        ( clk       ),
    .cen        ( cen6      ),   // This is normally the input clock to the CPU
    .cpu_cen    ( cpu_cen   ),   // 1/4th of cen

    // Interrupts
    .nIRQ       ( nIRQ      ),
    .nFIRQ      ( 1'b1      ),
    .nNMI       ( 1'b1      ),
    .irq_ack    ( irq_ack   ),
    // Bus sharing
    .bus_busy   ( bus_busy  ),
    // memory interface
    .A          ( A         ),
    .RnW        ( RnW       ),
    .VMA        (           ),
    .ram_cs     ( ram_cs    ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    ),
    // Bus multiplexer is external
    .ram_dout   ( ram_dout  ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_din    ( cpu_din   ),
    // DMA access to RAM
    .dma_clk    ( clk_dma   ),
    .dma_we     ( 1'b0      ),
    .dma_addr   ({ 4'hf,obj_AB }),
    .dma_din    ( 8'd0      ),
    .dma_dout   ( dma_dout  )
);

endmodule