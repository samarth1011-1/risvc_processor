module instruction_memory #(
    parameter DEPTH = 12, // this depends on the size of the program we are going to run
    parameter IN_FILE = "final_test.hex"
)(
    input [31:0] addr_i,                 // this is the output from PC
    input enable,                        // we can use this to stop fetching instructions when needed
    output reg [31:0] instr_o            // output
);
reg [31:0] mem[0:DEPTH-1];               // this stores the hexadecimal instructions from the file which are used to execute the program
wire [31:0] word_addr = addr_i >> 2;

initial begin
    $readmemh(IN_FILE, mem);             //  read the hex file and store it in the mem variable
end
    
    always@(*)begin
        if (enable && (word_addr < DEPTH))
            instr_o = mem[word_addr];
        else
            instr_o = 32'h00000013;
    end
endmodule

/* 
we are ignoring the last 2 bits -> mem[1:0] because all the instructions
 are 4 bytes long and the address is ONLY byte addressable
 since the instrctions are 4 bytes long, the last 2 will be 00
 in case of 2 bytes long instructions the last byte will be 0 and so on
 */
