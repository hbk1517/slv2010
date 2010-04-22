module rom #(parameter NrOfWords = 5, 
	     parameter WordSize = 12, 
	     parameter AddrsSize = 3,
             parameter [0:NrOfWords-1][WordSize-1:0]  coeffs  = {12'h8,12'hfe7,12'hfac,12'heb,12'h37a}
             ) // C-style comment. Casting to 12 bits
            (
	     input wire resetN,
	     input wire clk,
	     input wire read,
	     input wire [AddrsSize-1:0] addrs,
	     output reg [WordSize-1:0] dataOut
	     );//input-output list
   

 reg [WordSize-1:0] romArray [0:NrOfWords-1];
   int i;

  
   always @(posedge clk, negedge resetN)//sensitivinty list?????
     begin
	if (!resetN)
	  begin
	     i <= 0;
	     dataOut <= 0;
	     repeat (NrOfWords)
	       begin 
		  romArray[i] <= coeffs[i][WordSize-1:0];//this will take individual bit
		  //romArray[i] <= i+1;
		  i = i + 1;
	       end
	  end
	else if (read == 1)
	  dataOut <= romArray[addrs];
     end // begin  
         
endmodule // rom

