`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.02.2019 16:52:47
// Design Name: 
// Module Name: Convolution
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Convolution #(parameter NBits = 16, entero  = 4, fraccion =12, per_bits = 9)
    (
    input [31:0] frame,
    input clk,
    input rst,
    input arrived,
    output valid_posttrain,
    output [per_bits-1:0] period, //simul steps
    output reg ready,
    output [15:0] info_out
    );
   
   
// ------------------ FSM  pixel and information obtaining ------------------------

    reg [255:0] pixels [31:0]; // 256 = 28 +2 +2 (esquinas) * 8bits columnas, 32 = 28 + 2 +2 filas
    reg [63:0] info; //reg where we will store the first arriving value (containing info about image)
    integer fila;
    integer i; // only used in resetting
    parameter idle = 3'b000, prezero_info = 3'b001, zero = 3'b010, one = 3'b011, two = 3'b100, three = 3'b101, four = 3'b110, five = 3'b111;
    reg [2:0] currentstate;
    reg send2conv_finished;
    reg [7:0] image_counter; //We've got info of n.images processed. Small info.
    //wire clk;
    
//    always @(rst or posedge clk) begin
//        if (rst)
//            currentstate = zero;
//        else
//            currentstate = nextstate;
//    end
    
   // assign conv_frame = pixels[20][207:0];
 assign info_out[7:0] = info[5:0];
 assign info_out[15:8] = image_counter;
    always @(posedge clk, negedge rst) begin
        if(!rst) begin
            currentstate <= idle;
            fila <= 2;
            // resetear bpixels
            for (i=0;i<32;i=i+1) begin
                pixels[i] <= {256{1'b0}};
            end
            ready <= 1'b0;
            info <= 32'hABABABAB;
            image_counter <= 8'b00000000;
        end
        else begin
            case(currentstate)
                idle:begin    
                    ready <= 1'b1;             
                    if(arrived) begin
                        currentstate <= prezero_info;
                        fila <= 2;
                        info <= frame;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        image_counter <= image_counter + 1;
                    end
                    else begin
                        currentstate <= idle;
                        fila <= 2;
                        // resetear bpixels
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= {256{1'b0}};
                        end
                        info <= info;
                    end
                end
                prezero_info:begin
                    info <= info;
                    ready <= 1'b1;             
                    if(arrived) begin
                        currentstate <= zero;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][239:208] <= frame;//[239:184] <= frame [55:0];
                    end
                    else begin
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= {256{1'b0}};
                        end
                        currentstate <= prezero_info;
                    end 
                end                   
                zero:begin
                    info <= info;
                    ready <= 1'b1;
                    if(arrived) begin
                        currentstate <= one;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][207:176] <= frame;//[183:128] <= frame [55:0];
                    end
                    else begin
                        currentstate <= zero;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                    end
                end
                one:begin
                    info <= info;
                    ready <= 1'b1;
                    if(arrived) begin
                        currentstate <= two;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][175:144] <= frame;//[127:72] <= frame [55:0];
                    end
                    else begin
                        currentstate <= one;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                    end
                end
                two:begin
                    info <= info;
                    ready <= 1'b1;
                    if(arrived) begin
                        currentstate <= three;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][143:112] <= frame;
                    end
                    else begin
                        currentstate <= two;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                    end
                end
                three:begin
                    info <= info;
                    ready <= 1'b1;
                    if(arrived) begin
                        currentstate <= four;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][111:80] <= frame;
                    end
                    else begin
                        currentstate <= three;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                    end
                end
                four:begin
                    info <= info;
                    ready <= 1'b1;
                    if(arrived) begin
                        currentstate <= five;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                        pixels[fila][79:48] <= frame;
                    end
                    else begin
                        currentstate <= four;
                        fila <= fila;
                        for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                        end
                    end
                end
                five:begin
                   info <= info;
                   if(arrived && (fila<30) && fila!=29) begin
                       currentstate <= prezero_info;
                       for (i=0;i<32;i=i+1) begin
                           pixels[i] <= pixels[i];
                       end
                       pixels[fila][47:16] <= frame;
                       fila <= fila + 1;
                       ready <= 1'b1;
                   end
                   else if(arrived && fila == 29) begin
                      currentstate <= five;
                      for (i=0;i<32;i=i+1) begin
                          pixels[i] <= pixels[i];
                      end
                      pixels[fila][47:16] <= frame;
        
                      fila <= 30; //this way we will be sure that all pixels are received, send to conv will be able to send everything with no problem.
                      ready <= 1'b0;
                   end
                   else if((fila == 30) && send2conv_finished == 1'b1) begin
                      currentstate <= idle;
                      for (i=0;i<32;i=i+1) begin
                          pixels[i] <= pixels[i];
                      end
                      //pixels[fila][71:16] <= frame [55:0];
                      
                      fila <= 2;
                      ready <= 1'b1;
                   end
                   else begin
                       currentstate <= five;
                       fila <= fila;
                       for (i=0;i<32;i=i+1) begin
                            pixels[i] <= pixels[i];
                       end
                       ready <= ready;
                   end
                end
            endcase
        end
    end
        
        
        
//    always @(rst or currentstate) begin //posedge arrived, si va a funcionar con el empty del fifo, no va a ser necesario.
//        if (rst) begin
//            fila <= 2;
//            // resetear bpixels
//            for (i=0;i<32;i=i+1) begin
//                pixels[i] <= {256{1'b0}};
//            end
//        end
//        else begin
//            case(currentstate)
//                idle:begin
//                        fila <= 2;
//                        // resetear bpixels
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= {256{1'b0}};
//                        end
//                        info <= {64{1'b0}};
//                     end
//                information:begin
//                        fila <= fila;
//                        if(arrived) 
//                            info <= frame;
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        end
//                zero:begin
//                        fila <= fila;
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        if(arrived)
//                            pixels[fila][239:184] <= frame [55:0];
//                        end
//                one:begin
                        
//                        fila <= fila;
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        if(arrived)
//                            pixels[fila][183:128] <= frame [55:0];
//                        end
//                two:begin    
//                        fila <= fila;
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        if(arrived)
//                            pixels[fila][127:72] <= frame [55:0];
                        
//                        end
//                three:begin
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        if(arrived) pixels[fila][71:16] <= frame [55:0];
                        
//                        if(arrived) fila <= fila +1;
//                        else fila <= fila;
                        
//                      end
//                default:begin
//                        for (i=0;i<32;i=i+1) begin
//                            pixels[i] <= pixels[i];
//                        end
//                        fila <= fila;
//                        end
//            endcase
//        end
//    end        
//    always @(posedge clk) begin
//        if(rst) begin
//            currentstate <= idle;
//        end
//        else begin
//            case(currentstate)
//                idle:begin
//                    if(arrived)
//                        currentstate <= information;
//                    else
//                        currentstate <= idle;
//                    end
//                information:begin
//                        if(arrived)
//                            currentstate <= zero;
//                        else
//                            currentstate <= information;
//                        end                    
//                zero:begin
//                    if(arrived)
//                        currentstate <= one;
//                    else
//                        currentstate <= zero;
//                end
//                one:begin
//                    if(arrived)
//                        currentstate <= two;
//                    else
//                        currentstate <= one;
//                end
//                two:begin
//                   if(arrived)
//                       currentstate <= three;
//                   else
//                       currentstate <= two;
//                end
//                three:begin
//                      if(arrived && (fila<30))
//                          currentstate <= zero;
//                      else if((fila == 30) && conv_finished == 1'b1)
//                          currentstate <= idle;
//                      else
//                          currentstate <= three;
//                end
//            endcase
//        end
//    end
        
    
//-------------------- End of pixel and information obtaining ---------------------------

//-------------------- FSM of convolution -------------------------------
// it sends received pixels to convolution pipeline

    reg [1:0] currentstate_conv;
    parameter idle_conv = 2'b00, empieza_conv = 2'b01, espera_fila = 2'b10;
    reg pixels_valid; //The 25 pixels we send to the convolution pipeline are valid.
    integer fila_counter;
    integer x;
    reg [199:0] pixels2conv; //the 25 (5x5)pixels we send to convolution pipeline
    always @(posedge clk, negedge rst) begin
        if(!rst) begin
            currentstate_conv <= idle_conv;
            pixels_valid <= 1'b0;
            fila_counter <= 2;
            pixels2conv <= {200{1'b0}};
            x<= 0;
            send2conv_finished <= 1'b0;
        end
        else begin
            send2conv_finished <= 1'b0;
            case(currentstate_conv)
                idle_conv:begin
                    if(fila==5) begin // we make sure that first 4 rows have been received
                        currentstate_conv <= empieza_conv;
                        pixels_valid <= 1'b1;
                        fila_counter <= 2;
                        pixels2conv[199:160] <= pixels[fila_counter-2][(255-(x*8))-39 +:40]; //0 row, first 5 pixels
                        pixels2conv[159:120] <= pixels[fila_counter-1][(255-(x*8))-39 +:40]; //1 row, first 5 pixels
                        pixels2conv[119:80] <= pixels[fila_counter][(255-(x*8))-39 +:40]; //2 row, first 5 pixels
                        pixels2conv[79:40] <= pixels[fila_counter+1][(255-(x*8))-39 +:40]; //3 row, first 5 pixels
                        pixels2conv[39:0] <= pixels[fila_counter+2][(255-(x*8))-39 +:40]; //4 row, first 5 pixels
                        x <= x + 1;
                        send2conv_finished <= 1'b0;
                    end
                    else begin
                        currentstate_conv <= idle_conv;
                        pixels_valid <= 1'b0;
                        fila_counter <= 2;
                        pixels2conv <= {200{1'b0}};
                        x <= x;
                        send2conv_finished <= 1'b0;
                    end
                end
                empieza_conv:begin
                    if(x<28) begin
                        currentstate_conv <= empieza_conv;
                        pixels_valid <= 1'b1;
                        //fila_counter <= 2;
                        pixels2conv[199:160] <= pixels[fila_counter-2][(255-(x*8))-39 +:40]; //0 row, first 5 pixels
                        pixels2conv[159:120] <= pixels[fila_counter-1][(255-(x*8))-39 +:40]; //1 row, first 5 pixels
                        pixels2conv[119:80] <= pixels[fila_counter][(255-(x*8))-39 +:40]; //2 row, first 5 pixels
                        pixels2conv[79:40] <= pixels[fila_counter+1][(255-(x*8))-39 +:40]; //3 row, first 5 pixels
                        pixels2conv[39:0] <= pixels[fila_counter+2][(255-(x*8))-39 +:40]; //4 row, first 5 pixels
                        x <= x + 1;
                    end
                    else if ((x==28 && (fila > (fila_counter+3) && fila_counter!=29))) begin //we make wure that we have computed all 28 of a row, and that there is a new row received
                                                                //when it jumps to a new row, doesn't mean that we've got this new row, but that we've got the previous one (+3)
                        currentstate_conv <= empieza_conv;
                        pixels_valid <= 1'b1;
                        fila_counter <= fila_counter + 1;
                        pixels2conv[199:160] <= pixels[fila_counter + 1-2][(255-(0)):(255-(0)-39)]; //fila_counter +1 as we will be sending the first pixels of the row already
                        pixels2conv[159:120] <= pixels[fila_counter + 1-1][(255-(0)):(255-(0)-39)]; //1 row, first 5 pixels
                        pixels2conv[119:80] <= pixels[fila_counter + 1][(255-(0)):(255-(0)-39)]; //2 row, first 5 pixels
                        pixels2conv[79:40] <= pixels[fila_counter + 1+1][(255-(0)):(255-(0)-39)]; //3 row, first 5 pixels
                        pixels2conv[39:0] <= pixels[fila_counter + 1+2][(255-(0)):(255-(0)-39)]; //4 row, first 5 pixels
                        x <= 1; //We do the 0 at this clock!
                    end
                    else if ((x==28 && ((fila_counter==26) || (fila_counter==27) || (fila_counter==28)) && fila==30)) begin
                        currentstate_conv <= empieza_conv;
                        pixels_valid <= 1'b1;
                        fila_counter <= fila_counter + 1;
                        pixels2conv[199:160] <= pixels[fila_counter + 1-2][(255-(0)):(255-(0)-39)]; //fila_counter +1 as we will be sending the first pixels of the row already
                        pixels2conv[159:120] <= pixels[fila_counter + 1-1][(255-(0)):(255-(0)-39)]; //1 row, first 5 pixels
                        pixels2conv[119:80] <= pixels[fila_counter + 1][(255-(0)):(255-(0)-39)]; //2 row, first 5 pixels
                        pixels2conv[79:40] <= pixels[fila_counter + 1+1][(255-(0)):(255-(0)-39)]; //3 row, first 5 pixels
                        pixels2conv[39:0] <= pixels[fila_counter + 1+2][(255-(0)):(255-(0)-39)]; //4 row, first 5 pixels
                        x <= 1; //We do the 0 at this clock!
                    end
                    else if (x==28 && fila_counter==29) begin
                        currentstate_conv <= idle_conv;
                        pixels_valid <= 1'b0;
                        fila_counter <= 2;
                        pixels2conv[199:0] <= {200{1'b0}};
                        x <= 0;
                        //sending to conv has finished
                        send2conv_finished <= 1'b1;
                    end   
                    else begin //Espera aqui
                        currentstate_conv <= empieza_conv;
                        pixels_valid <= 1'b0;
                        fila_counter <= fila_counter;
                        x <= x;
                        pixels2conv <= {200{1'b0}};
                    end
                end    
            endcase
        end
    end
    
// ----------- End of FSM for sending data frames to convolution pipeline ----------

// ----------- Convolution ----------------

wire valid_postmult;
wire valid_postsum;
wire valid_postinter;
wire [399:0] multiplied;
wire [15:0] pixel_result;
wire [15:0] inter_result;
//wire [15:0] pixel_result; in output
kernel_mult #(.entero(entero),.fraccion(fraccion)) k_mult (.clk(clk),.rst(rst),.pixels25(pixels2conv),.valid_in(pixels_valid),.valid_prop(valid_postmult),.multiplied(multiplied));
sum_conv_pipeline #(.entero(entero),.fraccion(fraccion),.NBits(NBits)) conv_sum (.clk(clk),.rst(rst),.multiplied(multiplied),.valid_in(valid_postmult),.valid_prop(valid_postsum),.pixel_result(pixel_result));
interpolation #(.entero(entero),.fraccion(fraccion)) interpolation (.clk(clk),.rst(rst),.valid_in(valid_postsum),.valid_prop(valid_postinter),.pot(pixel_result),.inter_result(inter_result));
spike_train #(.entero(entero),.fraccion(fraccion)) spike_train (.clk(clk),.rst(rst),.valid_in(valid_postinter),.valid_out(valid_posttrain),.intensity(inter_result),.period(period));
//freq_spike_train #(.entero(entero),.fraccion(fraccion)) freq_spike_train (.clk(clk),.rst(rst),.valid_in(valid_postinter),.valid_out(valid_posttrain),.intensity(inter_result),.frequency(period));

//-----------------
//----------------- clock

//clk_wiz_0 erlojua (.clk_out1(clk),.reset(rst),.clk_in1(clk_in));

endmodule
