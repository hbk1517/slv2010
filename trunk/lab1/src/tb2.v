module tb2 #(	//FIR parameters
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
             	coeffs  = {12'h8,12'hfe7,12'hfac,12'heb,12'h37a}
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

integer t0;
integer sample_file, output_golden_file, output_file, report_file;
reg [7:0] sample_memory [0:40000];
reg [7:0] sample_golden_memory [0:40000];

integer input_index;
integer output_index;

initial begin
	
	//Task2
	output_file = $fopen("/home/boris/il2450/lab1_local/reports/sampleout.hex","w");
	report_file = $fopen("/home/boris/il2450/lab1_local/reports/task2.txt","w");
	
	$readmemh("/home/boris/il2450/lab1_local/data/sample.hex", sample_memory);
	$readmemh("/home/boris/il2450/lab1_local/data/sampleoutgolden.hex", sample_golden_memory);
	
	input_index = 0;
	output_index = 0;

	$fdisplay(report_file, "Comparison to golden model");
 
	c1.sampleClk	<= 0;
	c1.sample 	<= 0;
	##(20);
	while (output_index < 40000)
	begin
		c1.sample	<= sample_memory[input_index];
		c1.sampleClk	<= 1'b1;
		input_index++;
		if (c1.dav == 1)
		begin
			$fdisplay(output_file, "Time: %t, OutputNo: %5d is : %2x", $time, output_index, c1.sum);
			if (c1.sum != sample_golden_memory[output_index])
			begin			
				$fdisplay(report_file, "OutputNo: %5d differs: HW: %2x, ML: %2x", output_index, c1.sum, sample_golden_memory[output_index]);
			end	
		output_index++;
		end
		##(1);
		c1.sample 	<= 0;	
		c1.sampleClk	<= 1'b0;
		if (c1.dav == 1)
		begin
			$fdisplay(output_file, "Time: %t, OutputNo: %5d is : %2x", $time, output_index, c1.sum);
			if (c1.sum != sample_golden_memory[output_index])
			begin			
				$fdisplay(report_file, "OutputNo: %5d differs: HW: %2x, ML: %2x", output_index, c1.sum, sample_golden_memory[output_index]);
			end	
		output_index++;
		end
		##(1);

	end
	$fclose(output_file); 
	$fclose(report_file); 	
	$finish;
end

endprogram
