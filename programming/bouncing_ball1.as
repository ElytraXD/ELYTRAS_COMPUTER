// ==========================================
// CONSTANT DEFINITIONS (16x16 FLICKER-FREE)
// ==========================================
define ADDR_MODE  255
define ADDR_COORD 253    
define ADDR_COLOR 252    

define MODE_16X16 8      // WE = ON
define MODE_OFF   0      // WE = OFF
define COLOR_PNK  28     
define COLOR_BLK  0      

define VEL_X_POS  1      
define VEL_X_NEG  255    
define VEL_Y_POS  16     
define VEL_Y_NEG  240    

define BOUND_X_MAX 15    
define BOUND_Y_MAX 240   

// ==========================================
// INITIALIZATION
// ==========================================
LDI R15 ADDR_COORD
LDI R14 ADDR_COLOR
LDI R13 ADDR_MODE
LDI R0  0           // Guarantee R0 is zero for comparisons

// Set Initial Ball State
LDI R1 2            // Initial X 
LDI R2 224          // Initial Y 
LDI R4 VEL_X_POS    
LDI R5 VEL_Y_NEG    

// Calculate and memorize the very first coordinate into R9
ADD R1 R2 R9        // R9 NOW HOLDS THE "OLD" COORDINATE

// Draw the initial ball so it exists before the loop starts
LDI R6 COLOR_PNK
STR R14 0 R6
STR R15 0 R9
LDI R7 MODE_16X16
STR R13 0 R7        // STAMP INITIAL BALL
LDI R7 MODE_OFF
STR R13 0 R7

// ==========================================
// MAIN GAME LOOP (INSTANT SWAP METHOD)
// ==========================================
.MAIN_LOOP

// --- 1. UPDATE PHYSICS FIRST (Behind the scenes) ---
ADD R1 R4 R1        // X = X + VX
ADD R2 R5 R2        // Y = Y + VY
ADD R1 R2 R3        // R3 NOW HOLDS THE "NEW" COORDINATE

// --- 2. INSTANT SWAP (Lightning fast Erase & Draw) ---
// From here to the end of this block, the ball is swapped instantly!

// Erase Old Pixel
LDI R6 COLOR_BLK
STR R14 0 R6        // Load Black
STR R15 0 R9        // Load Old Coord (from R9)
LDI R7 MODE_16X16
STR R13 0 R7        // SHUTTER ON (Erased!)
LDI R7 MODE_OFF
STR R13 0 R7        // SHUTTER OFF

// Draw New Pixel
LDI R6 COLOR_PNK
STR R14 0 R6        // Load Pink
STR R15 0 R3        // Load New Coord (from R3)
LDI R7 MODE_16X16
STR R13 0 R7        // SHUTTER ON (Drawn!)
LDI R7 MODE_OFF
STR R13 0 R7        // SHUTTER OFF

// Update R9 for the next frame
ADD R3 R0 R9        // Copy New Coord (R3) into Old Coord (R9)

// --- 3. COLLISION CHECKS ---
.CHECK_X
CMP R0 R1           
BRH = .FLIP_X_POS
LDI R8 BOUND_X_MAX
CMP R8 R1           
BRH = .FLIP_X_NEG

.CHECK_Y
CMP R0 R2           
BRH = .FLIP_Y_POS
LDI R8 BOUND_Y_MAX
CMP R8 R2           
BRH = .FLIP_Y_NEG

.DONE_CHECKS
JMP .MAIN_LOOP

// ==========================================
// VELOCITY HANDLERS
// ==========================================
.FLIP_X_POS
LDI R4 VEL_X_POS
JMP .CHECK_Y

.FLIP_X_NEG
LDI R4 VEL_X_NEG
JMP .CHECK_Y

.FLIP_Y_POS
LDI R5 VEL_Y_POS
JMP .DONE_CHECKS

.FLIP_Y_NEG
LDI R5 VEL_Y_NEG
JMP .DONE_CHECKS