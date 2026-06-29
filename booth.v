// DATAPATH - Contains all registers and arithmetic elements for Booth multiplication
module datapath(q,eqz,qm1,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,data_in,ldcnt,decr,clk); 
    input lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,clk; 
    input [15:0]data_in; 
    output eqz,qm1; 
    wire [15:0]a,m,z; 
    wire [4:0]count;
    output [15:0]q;

    // Counter equal-to-zero flag (signals completion when count reaches 0)
    assign eqz=~|count; 

    shift ar(a,a[15],lda,clra,z,sfta,clk); 
    shift qr(q,a[0],ldq,clrq,data_in,sftq,clk); 
    ff d(qm1,q[0],clrff,clk); 
    pipo mr(m,data_in,ldm,clk); 
    alu as(z,a,m,addsub); 
    counter cnt(count,decr,ldcnt,clk); 
endmodule 


// SHIFT REGISTER - Supports load, clear, and arithmetic right shift operations
module shift(out,s_in,ld,clr,in,sft,clk); 
    input s_in,ld,clr,sft,clk; 
    input [15:0]in; 
    output reg[15:0]out; 

    // Priority: Clear > Load > Shift > Hold
    always@(posedge clk) 
        if(clr) out<=0; 
        else if(ld) out<=in; 
        else if(sft) out<={s_in,out[15:1]}; // Right shift: fill MSB with s_in, discard LSB
endmodule 


// FLIP-FLOP - Stores Q[0] from previous cycle for Booth algorithm bit pattern detection
module ff(dout,din,clrd,clk); 
    input din,clrd,clk; 
    output reg dout; 

    always@(posedge clk) 
        if(clrd) dout<=0; 
        else dout<=din; 
endmodule 


// PIPO REGISTER - Parallel-in parallel-out register for storing multiplicand
module pipo(pout,pin,ldp,clk); 
    input [15:0]pin; 
    input clk,ldp; 
    output reg [15:0]pout; 

    always@(posedge clk) 
        if(ldp) pout<=pin; 
endmodule 


// ALU - Performs add/subtract operations on 16-bit operands
module alu(result,data1,data2,ctrl); 
    input [15:0]data1,data2; 
    input ctrl; 
    output reg[15:0]result; 

    // ctrl=1: Add, ctrl=0: Subtract
    always@(*) 
        if(ctrl) result=data1+data2; 
        else result=data1-data2; 
endmodule 


// COUNTER - 5-bit down counter for tracking multiplication iterations
module counter(ot,dec,ldcnt,clk); 
    input dec,ldcnt,clk; 
    output reg[4:0]ot; 

    // Priority: Load > Decrement > Hold
    always@(posedge clk) 
        if(ldcnt) ot<=5'b10000; // Load counter with 16
        else if(dec) ot<=ot-1;  // Decrement for next iteration
endmodule 


// CONTROL PATH - Finite state machine implementing Booth algorithm
// States: S0(IDLE)->S1(INIT)->S2(DECODE)->S3/S4(ADD/SUB)->S5(SHIFT)->S6(DONE)
// Booth Rule: {Q[0],QM1}=01->subtract, 10->add, 00/11->shift only
module controlpath(done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,q,eqz,qm1,start,clk); 
    input eqz,qm1,start,clk; 
    input [15:0] q;   
    output reg done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,decr,ldcnt; 

    reg [2:0]state=0; 
    parameter s0=3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100,s5=3'b101,s6=3'b110; 

    // STATE TRANSITIONS
    always@(posedge clk) begin 
        case(state) 
            s0:begin if(start) state<=s1; end 
            s1:begin state<=s2; end 
            s2:begin 
                // Detect Booth bit patterns to determine next operation
                if({q[0],qm1}==2'b01) state<=s3;        // Pattern 01: subtract
                else if({q[0],qm1}==2'b10) state<=s4;   // Pattern 10: add
                else state<=s5;                          // Pattern 00/11: shift only
            end 
            s3:begin state<=s5; end 
            s4:begin state<=s5; end 
            s5:begin 
                // Check if more iterations needed or if done
                if(({q[0],qm1}==2'b01 && !eqz)) state<=s3; 
                else if(({q[0],qm1}==2'b10 && !eqz)) state<=s4; 
                else if(eqz) state<=s6;                  // Counter = 0, multiplication complete
            end 
            s6:begin state<=s6; end 
            default state<=s0; 
        endcase 
    end 

    // CONTROL OUTPUT GENERATION
    always@(state) begin 
        case(state) 
            s0:begin done=0; lda=0; clra=0; sfta=0; ldq=0; clrq=0; sftq=0; clrff=0; ldm=0; addsub=0; ldcnt=0; decr=0; end 
            s1:begin clra=1; clrff=1; ldm=1; ldcnt=1; end                    // Initialize: clear A, load M and counter
            s2:begin clra=0; ldq=1; clrff=0; ldm=0; ldcnt=0; end             // Load multiplier Q
            s3:begin lda=1; clra=0; ldq=0; sfta=0; sftq=0; addsub=1; decr=0; end // Add M to A
            s4:begin done=0; lda=1; clra=0; sfta=0; ldq=0; sftq=0; addsub=0; decr=0; end // Subtract M from A
            s5:begin sfta=1; sftq=1; lda=0; ldq=0; decr=1; end               // Shift A and Q right, decrement counter
            s6:begin done=1; end                                             // Multiplication done
            default:begin clra=0; sfta=0; ldq=0; sftq=0; end 
        endcase 
    end 
endmodule
