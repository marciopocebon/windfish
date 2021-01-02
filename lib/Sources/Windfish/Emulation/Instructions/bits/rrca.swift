import Foundation

extension LR35902.Emulation {
  final class rrca: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .rrca = spec else {
        return nil
      }
    }

    func advance(cpu: LR35902, memory: AddressableMemory, cycle: Int, sourceLocation: Disassembler.SourceLocation) -> LR35902.Emulation.EmulationResult {
      let carry = (cpu.a & 0x01) != 0
      let result = (cpu.a &>> 1) | (carry ? 0b1000_0000 : 0)
      cpu.a = result
      cpu.fzero = result == 0
      cpu.fsubtract = false
      cpu.fcarry = carry
      cpu.fhalfcarry = false
      return .fetchNext
    }
  }
}