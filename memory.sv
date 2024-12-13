module memory #(
    parameter SIZE = 1024
)
(
    input logic s_clk_i,
    input logic s_resetn_i,

    input logic[31:0] s_add_i,
    input logic[31:0] s_val_i,
    input logic s_write_i,
    output logic [31:0]s_val_o
);

    logic[31:0] r_buffer[SIZE-1:0];
    logic[$clog2(SIZE)-1:0] r_add;
    logic r_write;

    assign s_val_o = r_buffer[r_add];

    always_ff @(posedge s_clk_i or negedge s_resetn_i) begin
        if(~s_resetn_i)begin
            r_add   <= {($clog2(SIZE)){1'b0}};
            r_write <= 1'b0;
        end else begin
            r_add   <= s_add_i[$clog2(SIZE)+1:2];
            r_write <= s_write_i & (s_add_i[$clog2(SIZE)+1:2] < SIZE);
        end
    end

    always_ff @(posedge s_clk_i) begin
        if(r_write) begin
            r_buffer[r_add] <= s_val_i;
            $display("Writing data 0x%x at adddress: 0x%x", s_val_i, {r_add,2'b0});
        end
    end

endmodule