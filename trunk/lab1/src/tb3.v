module tb3 #(	//FIR parameters
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

logic lsc;
default clocking c1 @(posedge clk);
   default input #(1ns) output #(1ns);
	input sum;
	input dav;
	input addrs;
	output sampleClk;
	output sample;
endclocking

clocking c2 @(sum);
   default input #(1ps) output #(1ps) ;
	input sum;
	input dav;
	input clk;
endclocking


logic [15:0] tabs;
integer t0;
integer report_file;
logic [SumWidth-TruncatedMSBs-TruncatedLSBs-1:0] sum_old;
bit dav_old;



initial begin
	
	//Task1
	report_file = $fopen("reports/task1.txt","w");
	$fdisplay(report_file, "Impulse response Test");   

	tabs = 0;
	c1.sampleClk	<= 1'b0;
	lsc = #1ns 1'b0;
	c1.sample 	<= 0;
	##(20);
	c1.sample	<= 8'b01111111;
	c1.sampleClk	<= 1'b1;
	lsc = #1ns 1'b1;
	while (tabs <= NrOfTaps)
	begin
		c1.sampleClk	<= 1'b1;
		lsc = #1ns 1'b1;
		##(1);
		c1.sampleClk	<= 1'b0;
		lsc = #1ns 1'b0;
		c1.sample 	<= 0;	
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
		end
	end
	$fclose(report_file); 	
	$finish;
end

// Test 1
initial begin
	forever
	begin
		dav_old = c1.dav;
		##1	
		if((dav_old == c1.dav) && (c1.dav == 1))
		begin
			$display("%t: Violation 1 - Dav is 1 for longer than 1 Period", $time);
		end
	end
end


//Test 2
initial begin
	forever
	begin
		@(c2.sum);
		if(dav == 0 || clk == 0)
		begin
			$display("%t: Violation 2 - Sum changes", $time);
		end

	end
end

//logic [2:0] tabc;
integer tabc;
bit flag;
//Test 3
initial begin
	tabc = 0;
	flag = 0;
	//add = 1;
	forever
	begin
		if (lsc != 0) 
		begin
			//$display("%t: LSC != 0", $time);	
			tabc = 0;
			flag = 0;
			//add = 1:
			//##(1);
			while (c1.dav != 1)
			begin	
				//#2ns;			
				if(tabc != c1.addrs)
				begin
					$display("%t: Violation 3 - Incorrect order, addrs is %d , tabc is %d", $time, addrs, tabc);	
				end
				
				//tabc++;// = add + tabc;
				if (tabc >= ((NrOfTaps/2)-1) && (flag == 0))
				begin
					flag = 1;
					tabc = 0;
				end
				if (flag == 0)
				begin
					tabc++;
				end					
				##(1);	
			end	
		end else
		begin
			tabc = 0;
			##(1);
			
		end
	end
end
/*
//Test 3 b)
integer tab_count;
initial begin
	tab_count = 0;
	//add = 1;
	forever
	begin
	##(1);
		if(lsc == 1)
		begin
			tab_count = 0;
			while (tab_count <= (NrOfTaps-1)/2)		
			begin
				if(tab_count == c1.addrs)
				begin
					$display("%t: Violation 3 - Incorrect order", $time);	
				end
				tab_count++;
			end
			
		
		if (lsc != 0) 
		begin
			tabc = 0;
			//add = 1:
			while (c1.dav != 1)
			begin	
				#1ns;			
				if(tabc == addrs)
				begin
					$display("%t: Violation 3 - Incorrect order", $time);	
				end
				
				//tabc++;// = add + tabc;
				if (tabc >= (NrOfTaps/2))
				begin
					tabc = 0;
				end
				else
				begin
					tabc++;
				end					
				##(1);	
			end	
		end else
		begin
			tabc = 0;
			##(1);
			
		end
	end
end
*/
integer tabd;
//Test 4
initial begin
	tabd = 0;
	forever
	begin
		if (lsc != 0)
		begin
			tabd = 0;
			//add = 1:
			while (c1.dav != 1)
			begin		
				
				##1;					
				tabd++;
			end
			tabd--;
			if (tabd != (NrOfTaps/2))
			begin
				$display("%t: Violation 4 - Incorrect Number of Tabs", $time);	
			end
		end else
		begin
			tabd = 0;
			##(1);
		end
	end
end
endprogram
