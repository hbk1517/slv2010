module fir #(parameter NrOfTaps = 10, 
	     parameter SampleWidth = 8, 
	     parameter CoeffWidth = 12,
	     parameter SumWidth = 23,
             parameter TruncatedMSBs = 4,
             parameter TruncatedLSBs = 11,
	     parameter AddrsWidth = 4,
	     parameter CoeffAddrsWidth = 3)
            (
	     input wire resetN,
	     input wire clk,
	     input wire sampleClk,
	     input wire [SampleWidth-1:0] sample,
	     output reg [SumWidth-TruncatedMSBs-TruncatedLSBs-1:0] sum,
	     output reg dav,

	     // RAM interface
	     output reg rwN1,
	     output reg rwN2,
	     output reg [AddrsWidth-1:0] sampleAddrs1,
	     output reg [AddrsWidth-1:0] sampleAddrs2,
	     output reg [SampleWidth-1:0] dataIn,
	     input wire [SampleWidth-1:0] dataOut1,
	     input wire [SampleWidth-1:0] dataOut2,

	     // ROM interface
	     output reg read,
	     output reg [CoeffAddrsWidth-1:0] coeffAddrs,
	     input wire [CoeffWidth-1:0] coeff);	     

   bit [AddrsWidth-1:0] x1Addrs;
   bit [AddrsWidth-1:0] xnAddrs;
   bit signed [SampleWidth-1:0] sampleHold;

   bit signed [SampleWidth-1:0] bitdataOut1;
   bit signed [SampleWidth-1:0] bitdataOut2;
   bit signed [CoeffWidth-1:0] bitcoeff;
   bit signed [SumWidth-1:0] convSum;

   bit signed [SumWidth-1:0] intSum;
   
// b+a	
   bit sign;
   bit round;

   const byte N = NrOfTaps-2;
   const byte M = ((NrOfTaps % 2)==0) ? (NrOfTaps/2)-1 : ((NrOfTaps-1)/2);
   const bit oddMac = ((NrOfTaps % 2) == 0) ? 0 : 1;
   
   typedef enum {ramInit, idle, firstMac, middleMacs, lastMac} State_ty;
   
   State_ty state;

   function logic abs(bit [AddrsWidth-1:0] value);      
     abs = value;
   endfunction // abs

   always @(posedge clk, negedge resetN)
     if (!resetN)       
       begin	  
	  state <= ramInit;
	  x1Addrs <= 0;
	  xnAddrs <= N;
	  sampleAddrs1 <= 0;
	  sampleAddrs2 <= N;
	  rwN1 <= 0; // we begin with writing/initializing the RAM
	  rwN2 <= 1; 
	  dataIn <= 0;
	  coeffAddrs <= 0;
	  read <= 1;
	  sampleHold <= 0;	  
       end
     else
       case (state)
	 ramInit:
	   if (sampleAddrs1 == N)
	     state <= idle;
	   else
	     begin
		sampleAddrs1 <= sampleAddrs1 + 1;
		dataIn <= 0;
	     end
	 			 
	 idle:
	   //when we enter idle from ramInit both adresses are set
	   //to N. coeffAddr is 0 and we should set up next data
	   //Next data adress is shown by the pointers x1Addrs and x2Addrs 
	   
	   //problem : sampleAddrs2 is no decremented on next stage-fixed
	   //addresses we see on this state were set by raminit or lastmac
	   //data on this stage maybe on the addresses from raminit or lastmac
           begin
           dav<=0;
           sum<=0;
	   if (sampleClk == 1)
	     begin
		state <= firstMac;
		sampleHold <= sample;
		sampleAddrs1 <=x1Addrs;
	        if (xnAddrs == 0)
	         begin
		  sampleAddrs2 <= N;
		 end
	        else
		 begin
		  sampleAddrs2 <= xnAddrs - 1;
	         end//we already read xnAddrs
		
		coeffAddrs <= coeffAddrs + 1;
		rwN1 <= 1;
		rwN2 <= 1;

		//coeffAddrs <= 1;
		read <= 1;
             end
	     end // case: idle
	 
	 firstMac:
	   begin
	      //idle sets the addresses we see here
	      //data are from addresses that appered on idle state
              bitdataOut2 = dataOut2;
              bitcoeff = coeff;
	      convSum <=(sampleHold + bitdataOut2)*bitcoeff;
	      state <= middleMacs;

	      if (sampleAddrs2 == 0)
		sampleAddrs2 <= N;
	      else
		sampleAddrs2 <=sampleAddrs2 - 1;//sampleAddrs2++;
	      //only addrs2 was changing, FIXED	
	      if (sampleAddrs1 == N)
		sampleAddrs1 <= 0;
	      else
		sampleAddrs1 <= sampleAddrs1 + 1;//sampleAddrs1++;

	      coeffAddrs <= coeffAddrs + 1;
	   end

	 middleMacs:
	   begin
	   //addresses we see on this state were set by firstmac
	   //data on this stage maybe on the addresses firstmac
	   //which were set by idle
              bitdataOut1 = dataOut1;
              bitdataOut2 = dataOut2;
              bitcoeff = coeff;
	      convSum <= convSum + ((bitdataOut1 + bitdataOut2)*(bitcoeff));

	      if (sampleAddrs1 == N)
		sampleAddrs1 <= 0;
	      else
		sampleAddrs1 <= sampleAddrs1 + 1;
	 
	      if (sampleAddrs2 == 0)
		sampleAddrs2 <= N;
	      else
		sampleAddrs2 <= sampleAddrs2 - 1;

	      coeffAddrs <= coeffAddrs + 1;

              if (coeffAddrs == M)
		begin
		   state <= lastMac;
		   coeffAddrs <= 0;
		end
	      else
		coeffAddrs <= coeffAddrs + 1;
	      
	   end // case: middleMacs
	 
	 lastMac:
	   begin
	   //addresses we see on this state were set by middlemac
	   //data on this stage based on the addresses middlemac
	   //which were set by firstmac or middlemac
              bitcoeff = coeff;
              bitdataOut1 = dataOut1;
              bitdataOut2 = dataOut2;
	      intSum = convSum + (bitdataOut1 + bitdataOut2) * bitcoeff;
              
		sum=intSum[SumWidth-TruncatedMSBs-1:TruncatedLSBs]+intSum[TruncatedLSBs-1];
		//fixed      
		/*	
		sign = intSum[[SumWidth-1];	
	      round = intSum[[TruncatedLSBs-1];		
	      if (sign == 0 && round == 0)
		begin 
			sum = sum + ; 
		end else if (sign == 0 && round == 0)
		begin 
			sum = sum + ; 
		end else if (sign == 1 && round == 0)
		begin
			sum = sum + 1; 
		end else if (sign == 0 && round == 0)
		begin
			sum = sum + ;
		end
		*/
              if((intSum[SumWidth-1:SumWidth-TruncatedMSBs-1]!=0) && (intSum[SumWidth-1]==0)) //positive value
                begin
                sum=-1;
                sum[SumWidth-TruncatedMSBs-TruncatedLSBs-1]=0;
                end
              if(!(&(intSum[SumWidth-1:SumWidth-TruncatedMSBs-1])) && (intSum[SumWidth-1])) //negative value 
                begin
                sum=0;
                sum[SumWidth-TruncatedMSBs-TruncatedLSBs-1]=1;
                end
 
              dav<=1;

	      // write the sample to the buffer
	      rwN1 <= 0;
	      dataIn <= sampleHold;	      
	      sampleAddrs1 <=xnAddrs;


	      // rotation logic
	      if (x1Addrs == 0)
		x1Addrs <= N;
	      else
		x1Addrs <= x1Addrs - 1;

	      //sampleAddrs2 should point to xnAddrs-1 for us to see this
	      //address on the port when we land to idle state	
	      
	      if (xnAddrs == 0)
	        begin
		 xnAddrs <= N;
		 sampleAddrs2 <= N;
		end
	      else
		begin
 		 xnAddrs <= xnAddrs - 1;
		 sampleAddrs2 <= xnAddrs - 1;
	        end

	      coeffAddrs <= 0;	      
	      state <= idle;
	   end
	 
       endcase
   
endmodule // fir

