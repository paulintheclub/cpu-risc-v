//`include "defines.v"
`define isX(variable) (^variable === 1'bX)
`define isZ(variable) (^variable === 1'bZ)
`define isXorZ(variable) (`isX(variable) | `isZ(variable))

`define TEST_SIZE 50

module testbench();

logic [31:0] r_reference[0:`TEST_SIZE-1];
logic [31:0] instr_be;
logic r_clk, r_resetn;

logic [31:0] s_pmem_add, s_pmem_vali, s_pmem_valo,
            s_dmem_add, s_dmem_vali, s_dmem_valo;
logic s_pmem_write, s_dmem_write;
logic s_error;

initial begin
    $readmemh("D:/Study/SPRO/Projekt_CPU/test.vh", program_memory.r_buffer);
    for (int i=0;i<1024;i=i+1) begin
        instr_be = program_memory.r_buffer[i];
        program_memory.r_buffer[i] = {instr_be[7:0],instr_be[15:8],instr_be[23:16],instr_be[31:24]}; 
    end
    // $readmemh("D:/Study/SPRO/Projekt_CPU/reference.vh", data_memory.r_buffer);
    $readmemh("D:/Study/SPRO/Projekt_CPU/reference.vh", r_reference);
    r_clk = 1'b1; r_resetn = 1'b0; #25; r_resetn = 1'b1;
    #100000;

    $display("FAILED, execution lasts too long");
    $stop;
end

always #5 r_clk <= ~r_clk;

always_ff @(posedge s_error) begin
    for (int i=0;i<`TEST_SIZE;i=i+1) begin
        if((r_reference[i] != data_memory.r_buffer[i]) || `isXorZ(data_memory.r_buffer[i]))begin
            $display("FAILED, difference at dmem[%2d]", i);
            $stop;
        end
    end
    $display("PASSED"); 
    $stop;
end

cpu_top my_cpu
(
    .s_clk_i(r_clk),
    .s_resetn_i(r_resetn),
    .s_boot_add_i(32'h0),
    .s_error_o(s_error),

    .s_ibus_val_i(s_pmem_valo),
    .s_ibus_write_o(s_pmem_write),
    .s_ibus_add_o(s_pmem_add),
    .s_ibus_val_o(s_pmem_vali),

    .s_dbus_val_i(s_dmem_valo),
    .s_dbus_write_o(s_dmem_write),
    .s_dbus_add_o(s_dmem_add),
    .s_dbus_val_o(s_dmem_vali)
);

memory program_memory
(
    .s_clk_i(r_clk),
    .s_resetn_i(r_resetn),
    .s_add_i(s_pmem_add),
    .s_val_i(s_pmem_vali),
    .s_write_i(s_pmem_write),
    .s_val_o(s_pmem_valo)
);

memory data_memory
(
    .s_clk_i(r_clk),
    .s_resetn_i(r_resetn),
    .s_add_i(s_dmem_add),
    .s_val_i(s_dmem_vali),
    .s_write_i(s_dmem_write),
    .s_val_o(s_dmem_valo)
);

endmodule