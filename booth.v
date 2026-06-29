// ============================================================================
// Booth's Multiplier - Complete Implementation
// ============================================================================
// A 16-bit signed multiplier using Booth's algorithm. Combines a datapath
// (computational hardware) and a control path (FSM) to perform efficient
// binary multiplication through iterative add/subtract and shift operations.
// ============================================================================


// ============================================================================
// MODULE: datapath
// ============================================================================
// Datapath that implements the computational core of Booth's multiplier.
// Contains registers for accumulator (A), multiplier (Q), multiplicand (M),
// and control logic for shifting and arithmetic operations.
// ============================================================================
module datapath(q,eqz,qm1,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,data_in,ldcnt,decr,clk); 
    input lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,clk; 
    input [15:0]data_in; 
    output eqz,qm1; 
    wire [15:0]a,m,z; 
    wire [4:0]count;
    output [15:0]q;

    // Check if all iterations are complete (counter = 0)
    assign eqz=~|count; 

    // Accumulator shift register - performs arithmetic right shift with sign extension
    shift ar(a,a[15],lda,clra,z,sfta,clk); 
    
    // Multiplier shift register - shifts in LSB of accumulator
    shift qr(q,a[0],ldq,clrq,data_in,sftq,clk); 
    
    // Flip-flop storing Q[0] from previous cycle (needed for Booth's algorithm)
    ff d(qm1,q[0],clrff,clk); 
    
    // Register storing multiplicand value for repeated use
    pipo mr(m,data_in,ldm,clk); 
    
    // Arithmetic unit - adds or subtracts multiplicand from accumulator
    alu as(z,a,m,addsub); 
    
    // Iteration counter - counts down from 16 to 0
    counter cnt(count,decr,ldcnt,clk); 
endmodule 


// ============================================================================
// MODULE: shift
// ============================================================================
// 16-bit shift register with parallel load and arithmetic right shift.
// Used for both accumulator and multiplier registers.
// ============================================================================
module shift(out,s_in,ld,clr,in,sft,clk); 
    input s_in,ld,clr,sft,clk; 
    input [15:0]in; 
    output reg[15:0]out; 

    // Priority: Clear > Load > Shift > Hold
    always@(posedge clk) 
        if(clr) out<=0;                      // Clear register to zero
        else if(ld) out<=in;                 // Load parallel input data
        else if(sft) out<={s_in,out[15:1]}; // Arithmetic right shift: MSB = s_in, LSB dropped
endmodule 


// ============================================================================
// MODULE: ff (Flip-Flop)
// ============================================================================
// Single-bit D flip-flop with clear. Stores Q[0] from current cycle to
// provide Q[-1] for Booth's algorithm in next cycle.
// ============================================================================
module ff(dout,din,clrd,clk); 
    input din,clrd,clk; 
    output reg dout; 

    always@(posedge clk) 
        if(clrd) dout<=0;  // Clear flip-flop
        else dout<=din;    // Capture input bit
endmodule 


// ============================================================================
// MODULE: pipo (Parallel-In Parallel-Out)
// ============================================================================
// 16-bit register that stores and holds the multiplicand value
// throughout the multiplication process.
// ============================================================================
module pipo(pout,pin,ldp,clk); 
    input [15:0]pin; 
    input clk,ldp; 
    output reg [15:0]pout; 

    always@(posedge clk) 
        if(ldp) pout<=pin; // Load multiplicand when enabled
endmodule 


// ============================================================================
// MODULE: alu (Arithmetic Logic Unit)
// ============================================================================
// 16-bit arithmetic unit performing addition or subtraction.
// Booth's algorithm: ctrl=1 adds, ctrl=0 subtracts.
// ============================================================================
module alu(result,data1,data2,ctrl); 
    input [15:0]data1,data2; 
    input ctrl; 
    output reg[15:0]result; 

    always@(*) 
        if(ctrl) result=data1+data2;  // ADD operation
        else result=data1-data2;      // SUBTRACT operation
endmodule 


// ============================================================================
// MODULE: counter
// ============================================================================
// 5-bit down counter for tracking multiplication iterations.
// Loads with 16 at start and decrements until reaching 0 to signal completion.
// ============================================================================
module counter(ot,dec,ldcnt,clk); 
    input dec,ldcnt,clk; 
    output reg[4:0]ot; 

    // Priority: Load > Decrement > Hold
    always@(posedge clk) 
        if(ldcnt) ot<=5'b10000;  // Load counter with 16 (decimal)
        else if(dec) ot<=ot-1;   // Decrement each iteration
endmodule 


// ============================================================================
// MODULE: controlpath (Control FSM)
// ============================================================================
// Finite state machine implementing Booth's algorithm.
// Examines Q[0] and Q[-1] bits to determine add, subtract, or shift operations.
//
// State Flow: s0(IDLE) -> s1(INIT) -> s2(DECODE) -> s3/s4(ADD/SUB) -> 
//            s5(SHIFT) -> s6(DONE)
//
// Booth Recoding Rules: 
//   {Q[0], Q[-1]} = 01 -> SUBTRACT M from A
//   {Q[0], Q[-1]} = 10 -> ADD M to A
//   {Q[0], Q[-1]} = 00 or 11 -> SHIFT only (no add/subtract)
// ============================================================================
module controlpath(done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,q,eqz,qm1,start,clk); 
    input eqz,qm1,start,clk; 
    input [15:0] q;   
    output reg done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,decr,ldcnt; 

    reg [2:0]state=0; 
    parameter s0=3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100,s5=3'b101,s6=3'b110; 

    // ========================================================================
    // STATE TRANSITION LOGIC
    // ========================================================================
    always@(posedge clk) begin 
        case(state) 
            s0:begin 
                // IDLE: Wait for start signal
                if(start) state<=s1; 
            end 
            
            s1:begin 
                // INIT: Move to Booth bit decoding after initialization
                state<=s2; 
            end 
            
            s2:begin 
                // DECODE: Check Booth bit pattern {Q[0], Q[-1]} to determine next operation
                if({q[0],qm1}==2'b01) state<=s3;        // Pattern 01: SUBTRACT operation
                else if({q[0],qm1}==2'b10) state<=s4;   // Pattern 10: ADD operation
                else state<=s5;                          // Pattern 00/11: SHIFT only
            end 
            
            s3:begin 
                // ADD: After add completes, move to shift
                state<=s5; 
            end 
            
            s4:begin 
                // SUB: After subtract completes, move to shift
                state<=s5; 
            end 
            
            s5:begin 
                // SHIFT: After shift, check if more iterations needed
                if(({q[0],qm1}==2'b01 && !eqz)) state<=s3;      // Need subtract and iterations remain
                else if(({q[0],qm1}==2'b10 && !eqz)) state<=s4; // Need add and iterations remain
                else if(eqz) state<=s6;                          // Counter = 0, multiplication complete
            end 
            
            s6:begin 
                // DONE: Stay in done state
                state<=s6; 
            end 
            
            default state<=s0; 
        endcase 
    end 

    // ========================================================================
    // CONTROL OUTPUT GENERATION - Datapath control signals per state
    // ========================================================================
    always@(state) begin 
        case(state) 
            s0:begin 
                // IDLE: Disable all operations
                done=0; lda=0; clra=0; sfta=0; ldq=0; clrq=0; sftq=0; clrff=0; ldm=0; addsub=0; ldcnt=0; decr=0; 
            end 
            
            s1:begin 
                // INIT: Clear accumulator A, flip-flop, load multiplicand M and counter
                clra=1; clrff=1; ldm=1; ldcnt=1; 
            end 
            
            s2:begin 
                // DECODE: Load multiplier Q with input data
                clra=0; ldq=1; clrff=0; ldm=0; ldcnt=0; 
            end 
            
            s3:begin 
                // ADD: Accumulator = A + M (addsub=1 means ADD)
                lda=1; clra=0; ldq=0; sfta=0; sftq=0; addsub=1; decr=0; 
            end 
            
            s4:begin 
                // SUB: Accumulator = A - M (addsub=0 means SUBTRACT)
                done=0; lda=1; clra=0; sfta=0; ldq=0; sftq=0; addsub=0; decr=0; 
            end 
            
            s5:begin 
                // SHIFT: Arithmetic right shift A and Q, decrement counter
                sfta=1; sftq=1; lda=0; ldq=0; decr=1; 
            end 
            
            s6:begin 
                // DONE: Multiplication complete - assert done signal
                done=1; 
            end 
            
            default:begin 
                clra=0; sfta=0; ldq=0; sftq=0; 
            end 
        endcase 
    end 
endmodule
