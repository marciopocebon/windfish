import Foundation

extension LR35902.Emulation {
  final class dec_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      guard case .dec(let register) = spec, registers8.contains(register) else {
        return nil
      }
      self.register = register
    }

    func advance(cpu: LR35902, memory: AddressableMemory, cycle: Int, sourceLocation: Gameboy.SourceLocation) -> LR35902.Emulation.EmulationResult {
      cpu.fsubtract = true
      // fcarry not affected
      let result = (cpu[register] as UInt8) &- 1
      cpu[register] = result
      cpu.fzero = result == 0
      cpu.fhalfcarry = (result & 0xf) == 0xf
      return .fetchNext
    }

    private let register: LR35902.Instruction.Numeric
  }
}
