module jt03 (
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, it not needed leave as 1'b1
    input   [7:0]   din,
    input           addr,
    input           cs_n,
    input           wr_n,
    
    output  [7:0]   dout,
    output          irq_n,
    // combined output
    output  signed  [15:0]  snd,
    output          snd_sample
);

assign dout=8'd0, irq_n = 1'b1;
assign snd=16'd0;
assign snd_sample=1'b0;

reg last_wr_n;
reg [7:0] selection;

always @(posedge clk) if(cen) begin
    last_wr_n <= wr_n;
    if( !wr_n && last_wr_n && !cs_n ) begin
        if( !addr ) selection <= din;
        if(  addr && selection>=8'h20 ) $display("%X, %X", selection, din );
    end
end

endmodule // jt12