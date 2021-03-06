import Foundation

extension LR35902.Emulation {
  final class adc_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      guard case .adc(let register) = spec, registers8.contains(register) else {
        return nil
      }
      self.register = register
    }

    func advance(cpu: LR35902, memory: AddressableMemory, cycle: Int, sourceLocation: Gameboy.SourceLocation) -> LR35902.Emulation.EmulationResult {
      if cpu.fcarry {
        carryadd(cpu: cpu, value: cpu[register])
      } else {
        add(cpu: cpu, value: cpu[register] as UInt8)
      }
      return .fetchNext
    }

    private let register: LR35902.Instruction.Numeric
  }
}
