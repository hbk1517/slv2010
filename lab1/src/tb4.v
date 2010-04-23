module tb4 #(	//FIR parameters
		parameter
		NrOfTaps = 10, 
	     	SampleWidth = 8, 
	     	CoeffWidth = 12,
	     	SumWidth = 23,
             	TruncatedMSBs = 4,
             	TruncatedLSBs = 11,
	     	AddrsWidth = 4,
	     	CoeffAddrsWidth = 3,
		// RAM parameters
		RAMNrOfWords = 9, 
 		RAMWordSize = 8, 
 		RAMAddrsSize = 4,
		// ROM parameters
		ROMNrOfWords = 5, 
	     	ROMWordSize = 12, 
	     	ROMAddrsSize = 3,
             	coeffs  = {12'h7ff,12'h7ff,12'h7ff,12'h7ff,12'h7ff}
             )
		(
		// no inputs/outputs		
		);

reg resetN;
reg clk;

//FIR wires
reg sampleClk;
reg [SampleWidth-1:0] sample;
logic [SumWidth-TruncatedMSBs-TruncatedLSBs-1:0] sum;
logic dav;

//RAM wires
logic rwN1;
logic rwN2;
logic [RAMAddrsSize-1:0] addrs1;
logic [RAMAddrsSize-1:0] addrs2;
logic [RAMWordSize-1:0] dataIn1;
logic [RAMWordSize-1:0] dataIn2;
logic [RAMWordSize-1:0] dataOut1;
logic [RAMWordSize-1:0] dataOut2;

//ROM wires
logic read;
logic [ROMAddrsSize-1:0] addrs;
logic [ROMWordSize-1:0] dataOut;

fir #(NrOfTaps, SampleWidth, CoeffWidth, SumWidth, TruncatedMSBs, TruncatedLSBs, AddrsWidth, CoeffAddrsWidth) fir0
            (.resetN(resetN),
	     .clk(clk),
	     .sampleClk(sampleClk),
	     .sample(sample),
	     .sum(sum),
	     .dav(dav),
	     // RAM interface
	     .rwN1(rwN1),
	     .rwN2(rwN2),
	     .sampleAddrs1(addrs1),
	     .sampleAddrs2(addrs2),
	     .dataIn(dataIn1),
	     .dataOut1(dataOut1),
	     .dataOut2(dataOut2),
	     // ROM interface
	     .read(read),
	     .coeffAddrs(addrs),
	     .coeff(dataOut));

ram #(RAMNrOfWords,RAMWordSize,RAMAddrsSize)
ram0 (
.resetN(resetN),
.clk(clk),
.rwN1(rwN1),
.rwN2(rwN2),
.addrs1(addrs1),
.addrs2(addrs2),
.dataIn1(dataIn1),
.dataIn2(dataIn2),
.dataOut1(dataOut1),
.dataOut2(dataOut2)
);

rom #(ROMNrOfWords, ROMWordSize, ROMAddrsSize, coeffs)
rom0 (	     .resetN(resetN),
	     .clk(clk),
	     .read(read),
	     .addrs(addrs),
	     .dataOut(dataOut)
	     );

TB_PROG #(
	.SampleWidth(SampleWidth),
	.SumWidth(SumWidth),
	.TruncatedMSBs(TruncatedMSBs),
	.TruncatedLSBs(TruncatedLSBs),
	.ROMNrOfWords(ROMNrOfWords),
	.ROMWordSize(ROMWordSize), 
	.ROMAddrsSize(ROMAddrsSize)
) TB_PROG_inst (
	.sum(sum),
	.dav(dav),
	.clk(clk),
	.resetN(resetN),
	.sampleClk(sampleClk),
	.sample(sample),
	.read(read),
	.addrs(addrs),
	.dataOut(dataOut)
);

initial begin
clk=1'b0;
resetN=1'b0;
#30 resetN=1'b1;
//#1000 $stop;
end

always #10 clk=~clk;
endmodule

program TB_PROG #(parameter
	int NrOfTaps = 10, 
	int SampleWidth = 8,
	int SumWidth = 23,
	int TruncatedMSBs = 4,
       	int TruncatedLSBs = 11,
	int ROMNrOfWords = 5, 
	int ROMWordSize = 12, 
	int ROMAddrsSize = 3
)
(
	input logic [SumWidth-TruncatedMSBs-TruncatedLSBs-1:0] sum,
	input bit dav,
	input logic clk,
	input logic resetN,
	output logic sampleClk,
	output logic [SampleWidth-1:0] sample,
	input logic read,
	input logic [ROMAddrsSize-1:0] addrs,
	input logic [ROMWordSize-1:0] dataOut
);

bit local_clk;
assign local_clk = clk;

default clocking c1 @(posedge clk);
   default input #(1ns) output #(1ns);
	input sum;
	input dav;
	output sampleClk;
	output sample;
endclocking


logic [15:0] tabs;
integer t0;
integer report_file;
logic [31:0] golden;
initial begin
	
	//Task1
	report_file = $fopen("reports/task4.txt","w");
	$fdisplay(report_file, "Impulse response Test");   

	tabs = 0;
	c1.sampleClk	<= 0;
	c1.sample 	<= 0;
	golden = 0;
	##(20);
	c1.sample	<= 8'b01111111;//'h7f;//
	c1.sampleClk	<= 1'b1;
	while (tabs <= NrOfTaps)
	begin
		c1.sampleClk	<= 1'b1;
		##(1);
		c1.sampleClk	<= 1'b0;
		//c1.sample 	<= 0;	
		while (c1.dav != 1) 
		begin
			##(1);
		end
		// dav == 1
		tabs++;
		$display("%t: Sum is : %x", $time, c1.sum);
		$fdisplay(report_file, "%t: Sum is : %x", $time, c1.sum);    
		while (c1.dav != 0)
		begin
			##(1);
			if (tb4.fir0.intSum != 259969 * tabs && tabs <= NrOfTaps)
			begin
				$display("Overflow happens at tab: %d", tabs);
			end	
		end
		if (c1.dav == 1)
			begin
			golden = 259969 * NrOfTaps;
	if ( golden[7:0] != c1.sum)
	begin
		$display("Not right answer  %b     %b",golden, sum);
	end
			
			end
	end
	
	$fclose(report_file); 	
	$finish;
end




endprogram
