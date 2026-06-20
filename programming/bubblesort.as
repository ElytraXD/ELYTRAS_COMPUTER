
// =======================================================
//user need to add the list of all 100 number to the rom data or data memory 
// or u can just 
//LDI R1 0      // R1 = Address Pointer starting at 0

// Load 1st number
//LDI R2 45     The arbitrary number
//STR R1 0 R2   Store it at current address
//INC R1        Move address pointer to 1

// Load 2nd number
//LDI R2 12
//STR R1 0 R2
//INC R1         Move address pointer to 2

// Load 3rd number
//LDI R2 88
//STR R1 0 R2
//INC R1         Move address pointer to 3

// ... repeat 97 more times ...

// =======================================================


// =======================================================
// Bubble Sort - Data Memory (Addresses 0 to 99)
// =======================================================

DEFINE ARRAY_LEN 100
DEFINE START_ADDR 0

// -------------------------------------------------------
// OPTIONAL: Seed Memory (Fills 0-99 with reverse order 99 -> 0)
// -------------------------------------------------------
LDI R1 START_ADDR   // R1 = Address Pointer
LDI R2 99           // R2 = Value to write (Starts at 99)
LDI R3 ARRAY_LEN    // R3 = Limit

.SEED_LOOP
    STR R1 0 R2     // MEM[R1 + 0] = R2
    DEC R2          // Value--
    INC R1          // Address++
    CMP R1 R3       // Reached 100?
    BRH != .SEED_LOOP // If not, keep seeding

// -------------------------------------------------------
// THE BUBBLE SORT ALGORITHM
// -------------------------------------------------------
// Register Map:
// R1 = Current index pointer (i)
// R2 = A[i]
// R3 = A[i+1]
// R4 = Swapped flag (0 = false, 1 = true)
// R5 = Inner loop boundary (Starts at 99, decreases per pass)
// R6 = Constant 1 (Used to set the swapped flag)

LDI R5 99           // Set initial check boundary (n - 1)
LDI R6 1            // Constant 1 for setting our swapped flag

.OUTER_LOOP
    LDI R4 0        // swapped = false
    LDI R1 0        // i = 0 (Reset pointer to start of memory)

.INNER_LOOP
    // --- 1. LOAD ADJACENT VALUES ---
    LOD R1 0 R2     // R2 = MEM[i]
    LOD R1 1 R3     // R3 = MEM[i + 1]

    // --- 2. COMPARE A[i+1] to A[i] ---
    CMP R3 R2       // Computes (R3 - R2). 
    // If R3 (A[i+1]) >= R2 (A[i]), the Carry flag will be SET.
    // If Carry is set, the elements are already sorted. Skip the swap!
    BRH >= .NO_SWAP

.SWAP
    // --- 3. SWAP VALUES IN MEMORY ---
    STR R1 0 R3     // MEM[i] = A[i+1]
    STR R1 1 R2     // MEM[i+1] = A[i]
    ADD R6 R0 R4    // swapped = 1 (R4 = 1 + 0)

.NO_SWAP
    // --- 4. ADVANCE POINTER ---
    INC R1          // i++
    CMP R1 R5       // Did we hit the boundary for this pass?
    BRH != .INNER_LOOP // If not, keep going

    // --- 5. CHECK OUTER LOOP CONDITIONS ---
    CMP R4 R0       // Did we make ANY swaps during this pass?
    BRH Z .DONE     // If swapped == 0, the array is perfectly sorted!

    // Optimize: After every full pass, the largest number bubbles to the top.
    // Therefore, we don't need to check the last element again next time.
    DEC R5          // Decrease boundary (n = n - 1)
    
    CMP R5 R0       // If boundary reaches 0, we are done
    BRH Z .DONE
    JMP .OUTER_LOOP // Otherwise, run the next pass

.DONE
    HLT             // Sort complete. Halt CPU.