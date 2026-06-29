module datapath(q,eqz,qm1,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,data_in,ldcnt,decr,clk); 
    input lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,clk; 
    input [15:0]data_in; 
    output eqz,qm1; 
    wire [15:0]a,m,z; 
    wire [4:0]count;
    output [15:0]q;

    assign eqz=~|count; 

    shift ar(a,a[15],lda,clra,z,sfta,clk); 
    shift qr(q,a[0],ldq,clrq,data_in,sftq,clk); 
    ff d(qm1,q[0],clrff,clk); 
    pipo mr(m,data_in,ldm,clk); 
    alu as(z,a,m,addsub); 
    counter cnt(count,decr,ldcnt,clk); 
endmodule 


module shift(out,s_in,ld,clr,in,sft,clk); 
    input s_in,ld,clr,sft,clk; 
    input [15:0]in; 
    output reg[15:0]out; 

    always@(posedge clk) 
        if(clr) out<=0; 
        else if(ld) out<=in; 
        else if(sft) out<={s_in,out[15:1]}; 
endmodule 


module ff(dout,din,clrd,clk); 
    input din,clrd,clk; 
    output reg dout; 

    always@(posedge clk) 
        if(clrd) dout<=0; 
        else dout<=din; 
endmodule 


module pipo(pout,pin,ldp,clk); 
    input [15:0]pin; 
    input clk,ldp; 
    output reg [15:0]pout; 

    always@(posedge clk) 
        if(ldp) pout<=pin; 
endmodule 


module alu(result,data1,data2,ctrl); 
    input [15:0]data1,data2; 
    input ctrl; 
    output reg[15:0]result; 

    always@(*) 
        if(ctrl) result=data1+data2; 
        else result=data1-data2; 
endmodule 


module counter(ot,dec,ldcnt,clk); 
    input dec,ldcnt,clk; 
    output reg[4:0]ot; 

    always@(posedge clk) 
        if(ldcnt) ot<=5'b10000; 
        else if(dec) ot<=ot-1; 
endmodule 


module controlpath(done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,q,eqz,qm1,start,clk); 
    input eqz,qm1,start,clk; 
    input [15:0] q;   
    output reg done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,decr,ldcnt; 

    reg [2:0]state=0; 
    parameter s0=3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100,s5=3'b101,s6=3'b110; 

    always@(posedge clk) begin 
        case(state) 
            s0:begin if(start) state<=s1; end 
            s1:begin state<=s2; end 
            s2:begin 
                if({q[0],qm1}==2'b01) state<=s3; 
                else if({q[0],qm1}==2'b10) state<=s4; 
                else state<=s5; 
            end 
            s3:begin state<=s5; end 
            s4:begin state<=s5; end 
            s5:begin 
                if(({q[0],qm1}==2'b01 && !eqz)) state<=s3; 
                else if(({q[0],qm1}==2'b10 && !eqz)) state<=s4; 
                else if(eqz) state<=s6; 
            end 
            s6:begin state<=s6; end 
            default state<=s0; 
        endcase 
    end 

    always@(state) begin 
        case(state) 
            s0:begin done=0; lda=0; clra=0; sfta=0; ldq=0; clrq=0; sftq=0; clrff=0; ldm=0; addsub=0; ldcnt=0; decr=0; end 
            s1:begin clra=1; clrff=1; ldm=1; ldcnt=1; end 
            s2:begin clra=0; ldq=1; clrff=0; ldm=0; ldcnt=0; end 
            s3:begin lda=1; clra=0; ldq=0; sfta=0; sftq=0; addsub=1; decr=0; end 
            s4:begin done=0; lda=1; clra=0; sfta=0; ldq=0; sftq=0; addsub=0; decr=0; end 
            s5:begin sfta=1; sftq=1; lda=0; ldq=0; decr=1; end 
            s6:begin done=1; end 
            default:begin clra=0; sfta=0; ldq=0; sftq=0; end 
        endcase 
    end 
endmodule

