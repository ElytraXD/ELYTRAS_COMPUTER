// =======================================================
// Screen 1 (RGB888 256x256) - Pure Red to Blue Gradient
// Red = 255 - X, Green = 0, Blue = X
// =======================================================

DEFINE WE_BIT 2       // Bit 1 for Screen 1 WE
DEFINE MMIO_BASE 252  // Base address pointer

// --- Initialization ---
LDI R1 0            // R1 = X Coordinate
LDI R2 0            // R2 = Y Coordinate
LDI R3 255          // R3 = 255 (Constant used to invert X)
LDI R7 WE_BIT       // R7 = WE trigger (2)
LDI R15 MMIO_BASE   // R15 = MMIO Base Pointer (252)

.DRAW_Y
    LDI R1 0        // Reset X to 0 at the start of each row

.DRAW_X
    // --- 1. SET COORDINATES ---
    STR R15 1 R1    // M253 = X
    STR R15 0 R2    // M252 = Y
    
    // --- 2. CALCULATE AND SET COLORS ---
    XOR R1 R3 R4    // INVERT X: R4 = X ^ 255 (This makes Red go 255 -> 0)
    
    STR R15 -1 R4   // M251 = Red Channel   (Fading out)
    STR R15 -2 R0   // M250 = Green Channel (Forced to 0 using R0)
    STR R15 -3 R1   // M249 = Blue Channel  (Fading in with X)

    // --- 3. TRIGGER WRITE ---
    STR R15 3 R7    // M255 = Trigger WE
    STR R15 3 R0    // M255 = Clear WE (using hardwired R0)

    // --- 4. X LOOP ---
    INC R1
    CMP R1 R0       // Did X roll over to 0?
    BRH != .DRAW_X  // If not, keep drawing pixels in this row

    // --- 5. Y LOOP ---
    INC R2
    CMP R2 R0       // Did Y roll over to 0?
    BRH != .DRAW_Y  // If not, move down to the next row

// --- 6. FINISH ---
HLT                 // Screen is done! Halt CPU.