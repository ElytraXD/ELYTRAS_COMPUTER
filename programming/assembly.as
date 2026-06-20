// =======================================================
// Bouncing Ball - DRAW FIRST, ERASE BEHIND
// =======================================================

DEFINE X_START 20
DEFINE Y_START 10
DEFINE COLOR 15
DEFINE WE_BIT 4
DEFINE MAX_COORD 63
DEFINE MMIO_BASE 252

// --- Initialization ---
LDI R1 X_START      // R1 = Current X
LDI R2 Y_START      // R2 = Current Y
LDI R3 1            // R3 = Vx
LDI R4 1            // R4 = Vy
LDI R5 COLOR        // R5 = Draw Color (White)
LDI R6 0            // R6 = Erase Color (Black)
LDI R7 WE_BIT       // R7 = WE trigger mask
LDI R8 0            // R8 = WE clear mask
LDI R10 MAX_COORD   // R10 = Boundary limit (63)
LDI R11 1           // R11 = Positive velocity
LDI R12 -1          // R12 = Negative velocity
LDI R15 MMIO_BASE   // R15 = M252 Base Pointer

// --- Draw the very first starting pixel ---
STR R15 1 R1        // M253 = X
STR R15 0 R2        // M252 = Y
STR R15 -1 R5       // M251 = Color
STR R15 3 R7        // M255 = Trigger WE
STR R15 3 R8        // M255 = Clear WE

.MAIN_LOOP
    // --- 1. SAVE OLD POSITION ---
    // We add 0 to the current coords to copy them into R13 and R14
    ADD R1 R0 R13   // OLD_X (R13) = X + 0
    ADD R2 R0 R14   // OLD_Y (R14) = Y + 0

    // --- 2. UPDATE POSITION ---
    ADD R1 R3 R1    // X = X + Vx
    ADD R2 R4 R2    // Y = Y + Vy

    // --- 3. CHECK X BOUNDARIES ---
    CMP R1 R0       // Does X == 0? 
    BRH Z .BOUNCE_X_POS
    CMP R1 R10      // Does X == 63?
    BRH Z .BOUNCE_X_NEG
    JMP .CHECK_Y

.BOUNCE_X_POS
    ADD R11 R0 R3   // Vx = 1
    JMP .CHECK_Y

.BOUNCE_X_NEG
    ADD R12 R0 R3   // Vx = -1

.CHECK_Y
    // --- 4. CHECK Y BOUNDARIES ---
    CMP R2 R0       // Does Y == 0?
    BRH Z .BOUNCE_Y_POS
    CMP R2 R10      // Does Y == 63?
    BRH Z .BOUNCE_Y_NEG
    JMP .DRAW

.BOUNCE_Y_POS
    ADD R11 R0 R4   // Vy = 1
    JMP .DRAW

.BOUNCE_Y_NEG
    ADD R12 R0 R4   // Vy = -1

.DRAW
    // --- 5. DRAW NEW PIXEL FIRST ---
    STR R15 1 R1    // M253 = NEW X
    STR R15 0 R2    // M252 = NEW Y
    STR R15 -1 R5   // M251 = Ball color (draw)
    STR R15 3 R7    // M255 = Trigger WE
    STR R15 3 R8    // M255 = Clear WE

    // --- 6. ERASE OLD PIXEL BEHIND IT ---
    STR R15 1 R13   // M253 = OLD X
    STR R15 0 R14   // M252 = OLD Y
    STR R15 -1 R6   // M251 = Black color (erase)
    STR R15 3 R7    // M255 = Trigger WE
    STR R15 3 R8    // M255 = Clear WE

    // --- 7. IMMEDIATE REPEAT ---
    JMP .MAIN_LOOP