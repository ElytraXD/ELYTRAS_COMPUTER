#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#       assembly.as --> assembler.py --> mach.mc --> final_instruction.txt    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Opcode table — order matters, each value is the 4-bit opcode field
OPCODES = {
    "NOP": 0x0,  # 0000
    "HLT": 0x1,  # 0001
    "ADD": 0x2,  # 0010
    "SUB": 0x3,  # 0011
    "AND": 0x4,  # 0100
    "XOR": 0x5,  # 0101
    "LSL": 0x6,  # 0110
    "LSR": 0x7,  # 0111
    "LDI": 0x8,  # 1000
    "ADI": 0x9,  # 1001
    "JMP": 0xA,  # 1010  — unconditional jump
    "BRH": 0xB,  # 1011  — conditional branch
    "CAL": 0xC,  # 1100  — call subroutine
    "RET": 0xD,  # 1101  — return from subroutine
    "LOD": 0xE,  # 1110  — load from memory
    "STR": 0xF,  # 1111  — store to memory
}

# Instructions grouped by their operand format
THREE_REG_OPS = {"ADD", "SUB", "AND", "XOR", "LSL", "LSR"}  # format: OP R1 R2 W
IMM8_OPS      = {"LDI", "ADI"}                               # format: OP Rd imm8
NO_OP_OPS     = {"NOP", "HLT", "RET"}                        # no operands
JMP_OPS       = {"JMP", "CAL"}                               # format: OP 00 addr10
BRH_OPS       = {"BRH"}                                      # format: OP cond2 addr10
MEM_OPS       = {"LOD", "STR"}                               # format: OP R1 [offset4] R2 

# BRH condition codes  [bits 11:10]
# Accepts the mnemonic string OR a raw integer 0-3
CONDITIONS = {
    "Z":  0b00,  # zero flag set
    "NZ": 0b01,  # zero flag clear
    "C":  0b10,  # carry flag set
    "NC": 0b11,  # carry flag clear
    # symbol aliases
    "=":  0b00,  # same as Z
    "!=": 0b01,  # same as NZ
    ">=": 0b10,  # same as C
    "<":  0b11,  # same as NC
}

# Pseudo-instructions — expanded to real instructions before encoding
# Each entry: mnemonic -> function(operands, line_no) -> (new_mnemonic, new_operands)
# A pseudo can expand into ONE real instruction only.
PSEUDO_OPS = {
    "INC": lambda ops, ln: ("ADI", [_require_one_reg(ops, "INC", ln), "1"]),
    "DEC": lambda ops, ln: ("ADI", [_require_one_reg(ops, "DEC", ln), "-1"]),
    "CMP": lambda ops, ln: ("SUB", _require_two_regs(ops, "CMP", ln) + ["R0"]),
}

def _require_one_reg(operands, name, line_no):
    if len(operands) != 1:
        raise ValueError(f"Line {line_no}: '{name}' takes exactly one register")
    return operands[0]

def _require_two_regs(operands, name, line_no):
    if len(operands) != 2:
        raise ValueError(f"Line {line_no}: '{name}' takes exactly two registers")
    return operands

INPUT_FILE  = "assembly.as"
OUTPUT_MC   = "mach.mc"
OUTPUT_TXT  = "final_instruction.txt"


def parse_register(token, line_no):
    # Strips the leading 'R', converts to int, validates 0-15
    token = token.upper()
    if not token.startswith("R"):
        raise ValueError(f"Line {line_no}: Expected register, got '{token}'")
    try:
        num = int(token[1:])
    except ValueError:
        raise ValueError(f"Line {line_no}: Invalid register '{token}'")
    if num < 0 or num > 15:
        raise ValueError(f"Line {line_no}: '{token}' out of range, only R0-R15 allowed")
    return num


def parse_imm8(token, line_no):
    # Accepts decimal, 0x hex, or 0b binary literals
    # Signed -128..127 or unsigned 0..255 — both map to an 8-bit pattern
    token = token.strip()
    try:
        value = int(token, 0)
    except ValueError:
        raise ValueError(f"Line {line_no}: Cannot parse immediate '{token}'")
    if value < -128 or value > 255:
        raise ValueError(f"Line {line_no}: Immediate {value} out of 8-bit range")
    return value & 0xFF  # two's-complement mask


def parse_addr10(token, line_no):
    # 10-bit address: 0 – 1023  (matches the 1024-word program memory)
    token = token.strip()
    try:
        value = int(token, 0)
    except ValueError:
        raise ValueError(f"Line {line_no}: Cannot parse address '{token}'")
    if value < 0 or value > 1023:
        raise ValueError(f"Line {line_no}: Address {value} out of range (0-1023)")
    return value & 0x3FF


def parse_offset4(token, line_no):
    # 4-bit signed offset: -8 to 7  (two's complement)
    token = token.strip()
    try:
        value = int(token, 0)
    except ValueError:
        raise ValueError(f"Line {line_no}: Cannot parse offset '{token}'")
    if value < -8 or value > 7:
        raise ValueError(f"Line {line_no}: Offset {value} out of range (-8 to 7)")
    return value & 0xF  # two's-complement mask


def parse_condition(token, line_no):
    # Accepts  Z / NZ / C / NC  or raw integers 0-3
    upper = token.strip().upper()
    if upper in CONDITIONS:
        return CONDITIONS[upper]
    try:
        val = int(upper, 0)
    except ValueError:
        raise ValueError(f"Line {line_no}: Unknown condition '{token}' — use Z, NZ, C, NC")
    if val < 0 or val > 3:
        raise ValueError(f"Line {line_no}: Condition code {val} out of range (0-3)")
    return val


def encode(mnemonic, operands, line_no):
    # Builds the 16-bit instruction word based on the operand format
    opcode = OPCODES[mnemonic]

    if mnemonic in NO_OP_OPS:
        if operands:
            raise ValueError(f"Line {line_no}: '{mnemonic}' takes no operands")
        # [opcode 4b][000000000000]  — lower 12 bits are zero
        return (opcode << 12) & 0xFFFF

    if mnemonic in THREE_REG_OPS:
        if len(operands) != 3:
            raise ValueError(f"Line {line_no}: '{mnemonic}' needs R1 R2 W")
        r1 = parse_register(operands[0], line_no)
        r2 = parse_register(operands[1], line_no)
        w  = parse_register(operands[2], line_no)
        # [opcode 4b][R1 4b][R2 4b][W 4b]
        return ((opcode << 12) | (r1 << 8) | (r2 << 4) | w) & 0xFFFF

    if mnemonic in IMM8_OPS:
        if len(operands) != 2:
            raise ValueError(f"Line {line_no}: '{mnemonic}' needs Rd imm8")
        rd  = parse_register(operands[0], line_no)
        imm = parse_imm8(operands[1], line_no)
        # [opcode 4b][Rd 4b][imm8 8b]
        return ((opcode << 12) | (rd << 8) | imm) & 0xFFFF

    if mnemonic in JMP_OPS:
        if len(operands) != 1:
            raise ValueError(f"Line {line_no}: 'JMP' needs an address")
        addr = parse_addr10(operands[0], line_no)
        # [opcode 4b][00 2b][addr 10b]
        return ((opcode << 12) | addr) & 0xFFFF

    if mnemonic in BRH_OPS:
        if len(operands) != 2:
            raise ValueError(f"Line {line_no}: 'BRH' needs condition and address")
        cond = parse_condition(operands[0], line_no)
        addr = parse_addr10(operands[1], line_no)
        # [opcode 4b][cond 2b][addr 10b]
        return ((opcode << 12) | (cond << 10) | addr) & 0xFFFF

    if mnemonic in MEM_OPS:
        if len(operands) == 2:
            # short form: OP R1 R2  →  offset = 0
            r1     = parse_register(operands[0], line_no)
            offset = 0
            r2     = parse_register(operands[1], line_no)
        elif len(operands) == 3:
            # full form: OP R1 offset R2
            r1     = parse_register(operands[0], line_no)
            offset = parse_offset4(operands[1], line_no)
            r2     = parse_register(operands[2], line_no)
        else:
            raise ValueError(f"Line {line_no}: '{mnemonic}' needs R1 [offset] R2")
        # LOD: R2 = memory[R1 + offset]
        # STR: memory[R1 + offset] = R2
        # [opcode 4b][R1 4b][offset 4b][R2 4b]
        return ((opcode << 12) | (r1 << 8) | (offset << 4) | r2) & 0xFFFF

    raise ValueError(f"Line {line_no}: Unknown mnemonic '{mnemonic}'")


def assemble():
    with open(INPUT_FILE, "r") as f:
        raw_lines = f.readlines()

    # ── PASS 1: collect labels and build flat instruction list ─────────────
    # parsed = list of (line_no, mnemonic, operands) after pseudo expansion
    # labels  = { ".LABELNAME": instruction_index }
    # defines = { "NAME": "value_string" }  — assembler constants
    parsed  = []
    labels  = {}
    defines = {}
    errors  = []

    for line_no, raw in enumerate(raw_lines, start=1):
        # strip comments  (// or ; or #)
        idx = raw.find("//")
        if idx != -1:
            raw = raw[:idx]
        for ch in (";", "#"):
            idx = raw.find(ch)
            if idx != -1:
                raw = raw[:idx]
        line = raw.strip()
        if not line:
            continue

        tokens = line.split()

        # A label is the first token if it starts with '.'
        if tokens[0].startswith("."):
            lbl = tokens[0].upper()
            if lbl in labels:
                errors.append(f"Line {line_no}: Duplicate label '{lbl}'")
            else:
                labels[lbl] = len(parsed)  # address = current instruction count
            tokens = tokens[1:]            # remaining tokens are the instruction

        if not tokens:
            continue  # label-only line, nothing to encode

        mnemonic = tokens[0].upper()
        operands = [t.rstrip(",") for t in tokens[1:]]

        # handle define directive — no instruction produced
        if mnemonic == "DEFINE":
            if len(operands) != 2:
                errors.append(f"Line {line_no}: 'define' needs a name and a value")
            else:
                defines[operands[0].upper()] = operands[1]
            continue

        # substitute defined names in operands
        operands = [defines.get(op.upper(), op) for op in operands]

        # expand pseudo-instructions
        if mnemonic in PSEUDO_OPS:
            try:
                mnemonic, operands = PSEUDO_OPS[mnemonic](operands, line_no)
            except ValueError as e:
                errors.append(str(e))
                continue

        if mnemonic not in OPCODES:
            errors.append(f"Line {line_no}: Unknown instruction '{tokens[0]}'")
            continue

        parsed.append((line_no, mnemonic, operands))

    # ── PASS 2: encode, resolving label references to addresses ───────────
    words = []
    for line_no, mnemonic, operands in parsed:
        resolved = []
        for op in operands:
            if op.startswith("."):          # label reference
                lbl = op.upper()
                if lbl not in labels:
                    errors.append(f"Line {line_no}: Undefined label '{op}'")
                    resolved.append("0")
                else:
                    resolved.append(str(labels[lbl]))
            else:
                resolved.append(op)
        try:
            words.append(encode(mnemonic, resolved, line_no))
        except ValueError as e:
            errors.append(str(e))

    if errors:
        print("\n[ERRORS]")
        for e in errors:
            print(f"  {e}")
        print(f"\nFailed: {len(errors)} error(s). Nothing written.\n")
        return

    # mach.mc — raw 16-bit binary, one instruction per line
    with open(OUTPUT_MC, "w") as f:
        for w in words:
            f.write(f"{w:016b}\n")

    # final_instruction.txt — Logisim v3.0 ROM format
    # 1024 words total, padded with 0000, 16 words per row, addresses in hex
    mem = words + [0] * (1024 - len(words))
    rows = ["v3.0 hex words addressed"]
    for row in range(64):
        addr  = row * 16
        cells = " ".join(f"{mem[addr + col]:04x}" for col in range(16))
        rows.append(f"{addr:03x}: {cells}")

    with open(OUTPUT_TXT, "w") as f:
        f.write("\n".join(rows) + "\n")

    print(f"[OK] {len(words)} instruction(s) assembled.")
    if defines:
        print(f"[OK] {len(defines)} define(s): {', '.join(f'{k}={v}' for k,v in defines.items())}")
    if labels:
        print(f"[OK] {len(labels)} label(s) resolved: {', '.join(f'{k}={v}' for k,v in labels.items())}")
    print(f"[OK] {OUTPUT_MC} written.")
    print(f"[OK] {OUTPUT_TXT} written.")



assemble()

