module ram #(parameter NrOfWords = 9, 
	     parameter WordSize = 8, 
	     parameter AddrsSize = 4)
            (
	    input bit resetN,
	    input bit clk,
	    input bit rwN1,
	    input bit rwN2,
	    input wire [AddrsSize-1:0] addrs1,
	    input wire [AddrsSize-1:0] addrs2,
	    input wire [WordSize-1:0] dataIn1,
	    input wire [WordSize-1:0] dataIn2,
	    output reg [WordSize-1:0] dataOut1,
	    output reg [WordSize-1:0] dataOut2);

 reg [WordSize-1:0] regArray [0:NrOfWords-1];
   
   always @(posedge clk, negedge resetN)
     begin
	if (!resetN)
	  begin
	     dataOut1 <= 0;
	     dataOut2 <= 0;
	  end
	else 
	  begin
	     if (rwN1 == 1)
	       dataOut1 <= regArray[addrs1];
	     else if (rwN1 == 0)
	       regArray[addrs1] <= dataIn1;

	     if (rwN2 == 1)
	       dataOut2 <= regArray[addrs2];
	     else if (rwN2 == 0)
	       regArray[addrs2] <= dataIn2;
	     
	  end
     end // begin  
         
endmodule // ram

