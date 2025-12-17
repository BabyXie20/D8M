module RAW2RGB_J(
//---ccd
   input          [9:0]  mCCD_DATA,
   input                            CCD_PIXCLK ,
   input                            RST,
   input           VGA_CLK,
   input           READ_Request ,
   input           VGA_VS ,
   input           VGA_HS ,
   output        [7:0] oRed,
   output        [7:0] oGreen,
   output        [7:0] oBlue

);
//=======================================================
//  REG/WIRE declarations
//=======================================================
  wire [9:0]    mDAT0_0;
  wire [9:0]    mDAT0_1;
  wire [9:0]    mCCD_R;
  wire [9:0]    mCCD_G;
  wire [9:0]    mCCD_B;
  reg                      mDVAL;
  localparam integer SRC_WIDTH   = 640;
  localparam integer SRC_HEIGHT  = 480;
  localparam integer DISP_WIDTH  = 200;
  localparam integer DISP_HEIGHT = 150;
  localparam integer X_INT_STEP  = SRC_WIDTH  / DISP_WIDTH;
  localparam integer X_REM_STEP  = SRC_WIDTH  % DISP_WIDTH;
  localparam integer Y_INT_STEP  = SRC_HEIGHT / DISP_HEIGHT;
  localparam integer Y_REM_STEP  = SRC_HEIGHT % DISP_HEIGHT;

  reg    [8:0]  x_remain;
  reg    [8:0]  y_remain;

  reg         [10:0] src_x;
  reg         [10:0] src_y;
  reg          [8:0] dst_x;
  reg          [8:0] dst_y;
  reg          rDVAL ;
//=======================================================
// Structural coding
//=======================================================
//-------- RGB OUT ----
assign   oRed    =  (dst_y > 1)? mCCD_R[9:2]:0;
assign  oGreen  =  (dst_y > 1)? mCCD_G[9:2]:0 ;
assign  oBlue    =  (dst_y > 1)? mCCD_B[9:2]:0;


//-----COUNTER ----
always @(negedge VGA_VS or posedge VGA_CLK )begin
  if ( !VGA_VS ) begin
    src_x<=0;
    src_y<=0;
    dst_x<=0;
    dst_y<=0;
    x_remain<=0;
    y_remain<=0;
  end
  else
  begin
    rDVAL <= READ_Request   ;
    if ( !rDVAL)    begin
      src_x<=0;
      dst_x<=0;
      x_remain<=0;
    end else if (READ_Request) begin
      dst_x <= dst_x + 1'b1;
      if (x_remain + X_REM_STEP >= DISP_WIDTH) begin
        src_x <= src_x + X_INT_STEP + 1;
        x_remain <= x_remain + X_REM_STEP - DISP_WIDTH;
      end else begin
        src_x <= src_x + X_INT_STEP;
        x_remain <= x_remain + X_REM_STEP;
      end
    end
    if (  rDVAL  && !READ_Request)  begin
      dst_x <= 0;
      dst_y <= dst_y + 1'b1;
      if (y_remain + Y_REM_STEP >= DISP_HEIGHT) begin
        src_y <= src_y + Y_INT_STEP + 1;
        y_remain <= y_remain + Y_REM_STEP - DISP_HEIGHT;
      end else begin
        src_y <= src_y + Y_INT_STEP;
        y_remain <= y_remain + Y_REM_STEP;
      end
    end
  end
end
//--------

//----3 2-PORT-LINE-BUFFER----
Line_Buffer_J   u0      (
                                                .CCD_PIXCLK( VGA_CLK ),
                                                .mCCD_FVAL ( VGA_VS) ,
                  .mCCD_LVAL ( VGA_HS) ,
                                                .X_Cont    ( dst_x) ,
                                                .mCCD_DATA ( mCCD_DATA),
                                                .VGA_CLK   ( VGA_CLK),
                  .READ_Request (READ_Request),
                  .VGA_VS    ( VGA_VS),
                  .READ_Cont ( dst_x ),
                  .V_Cont    ( dst_y ),

                                                .taps0x    ( mDAT0_1),
                                                .taps1x    ( mDAT0_0)
                                                );

//---- BIN GEN ---
RAW_RGB_BIN  bin(
                  .CLK       ( VGA_CLK ),
                  .RST_N     ( RST ) ,
                  .D0        ( mDAT0_0),
                  .D1        ( mDAT0_1),
                  .X         ( src_x [0] ),
                  .Y         ( src_y [0] ),

                  .B         ( mCCD_R),
                  .G         ( mCCD_G),
                  .R         ( mCCD_B)
 );


endmodule
