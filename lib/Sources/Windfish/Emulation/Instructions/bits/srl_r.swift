import Foundation

extension LR35902.Emulation {
  final class srl_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      guard case .cb(.srl(let register)) = spec, registers8.contains(register) else {
        return nil
      }
      self.register = register
    }

    func advance(cpu: LR35902, memory: AddressableMemory, cycle: Int, sourceLocation: Gameboy.SourceLocation) -> LR35902.Emulation.EmulationResult {
      cpu.fsubtract = false
      cpu.fhalfcarry = false

      let value = cpu[register] as UInt8
      let carry = (value & 1) != 0
      let result = value &>> 1
      cpu[register] = result
      cpu.fzero = result == 0
      cpu.fcarry = carry
      return .fetchNext
    }

    private let register: LR35902.Instruction.Numeric
  }
}
