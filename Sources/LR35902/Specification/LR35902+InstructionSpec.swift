import Foundation
import CPU

extension LR35902 {
  /// The specification for an LR35902's instruction set.
  public indirect enum InstructionSpec: CPUInstructionSpec {
    // Loads
    case ld(Operand, Operand), ldi(Operand, Operand), ldd(Operand, Operand)

    // Stack manipulation
    case push(Operand), pop(Operand)

    // 8- and 16-bit arithmetic
    case add(Operand), add(Operand, Operand), adc(Operand)
    case sub(Operand), sub(Operand, Operand), sbc(Operand)
    case and(Operand), or(Operand), xor(Operand)
    case cp(Operand)
    case inc(Operand), dec(Operand)

    // Carry flag
    case ccf, scf

    // Program execution
    case nop, stop(Operand), halt

    // Interrupts
    case di, ei

    // Rotates and shifts
    case rla, rlca
    case rra, rrca

    // Jumps
    case jr(Condition? = nil, Operand)
    case jp(Condition? = nil, Operand)

    // Calls and returns
    case call(Condition? = nil, Operand)
    case ret(Condition? = nil), reti

    // Restarts
    case rst(RestartAddress)

    // Decimal adjust
    case daa

    // Complement
    case cpl

    // 0xCB prefix
    case cb(InstructionSpec)
    case rlc(Operand), rrc(Operand)
    case rl(Operand), rr(Operand)
    case sla(Operand), sra(Operand)
    case swap(Operand), srl(Operand)
    case bit(Bit, Operand), res(Bit, Operand), set(Bit, Operand)

    // Invalid opcode
    case invalid
  }

  /// Possible operands in LR35902's instruction set.
  public enum Operand: Hashable {
    case a, af
    case b, c, bc, bcaddr
    case d, e, de, deaddr
    case h, l, hl, hladdr

    case sp, sp_plus_simm8

    case imm8, simm8, imm16
    case imm16addr

    case ffimm8addr, ffccaddr

    case zeroimm8

     // For macro use only
    case macro(String)
    case arg(Int)
  }

  /// Possible conditions in LR35902's instruction set.
  public enum Condition {
    case nz
    case z
    case nc
    case c
  }

  /// Possible rst addresses in LR35902's instruction set.
  public enum RestartAddress: UInt8 {
    case x00 = 0x00
    case x08 = 0x08
    case x10 = 0x10
    case x18 = 0x18
    case x20 = 0x20
    case x28 = 0x28
    case x30 = 0x30
    case x38 = 0x38
  }

  /// Possible bits in LR35902's instruction set.
  public enum Bit: UInt8 {
    case b0 = 0
    case b1 = 1
    case b2 = 2
    case b3 = 3
    case b4 = 4
    case b5 = 5
    case b6 = 6
    case b7 = 7
  }
}