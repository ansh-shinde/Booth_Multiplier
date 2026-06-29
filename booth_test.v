module booth_test;
reg [15:0]data_in;
reg start,clk;
wire done;
wire [15:0] q; 
wire [31:0]product;

datapath dp(q,eqz,qm1,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,data_in,ldcnt,decr,clk); 
controlpath cp(done,lda,clra,sfta,ldq,clrq,sftq,clrff,ldm,addsub,ldcnt,decr,q,eqz,qm1,start,clk); 
assign product={dp.a, dp.q};

initial 
begin
clk=0;
#3 start=1;
#300 $finish;
end
always #5 clk=~clk;
initial 
begin
    #6 data_in = 7;   // put m first
    #10 data_in = 3; // q
end
initial 
begin
$dumpfile("booth.vcd");
$dumpvars(0,booth_test);
 $monitor("t=%0t  A=%0d  Q=%0d  product=%0d  count=%0d done=%b", $time, dp.a, dp.q,product, dp.count, done);
end
endmodule
