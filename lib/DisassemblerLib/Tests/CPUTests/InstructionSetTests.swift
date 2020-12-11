import XCTest
@testable import CPU

class InstructionSetTests: XCTestCase {
  func testWidths() {
    XCTAssertEqual(SimpleCPU.InstructionSet.widths, [
      .nop: InstructionWidth(opcode: 1, operand: 0),
      .ld(.a, .imm8): InstructionWidth(opcode: 1, operand: 1),
      .ld(.a, .imm16): InstructionWidth(opcode: 1, operand: 2),
      .call(.nz, .imm16): InstructionWidth(opcode: 1, operand: 2),
      .call(nil, .imm16): InstructionWidth(opcode: 1, operand: 2),
      .prefix(.sub): InstructionWidth(opcode: 1, operand: 0),
      .sub(.cp(.imm8)): InstructionWidth(opcode: 2, operand: 1),
    ])
  }

  func testOpcodeBytes() {
    let opcodes: [SimpleCPU.Instruction.Spec : [UInt8]] = [
      .nop: [0],
      .ld(.a, .imm8): [1],
      .ld(.a, .imm16): [2],
      .call(.nz, .imm16): [3],
      .call(nil, .imm16): [4],
      .sub(.cp(.imm8)): [5, 0],
    ]
    for (key, value) in SimpleCPU.InstructionSet.opcodeBytes {
      XCTAssertEqual(value, opcodes[key], "\(key) mismatched")
    }
  }

  func testOpcodeData() {
    let opcodeData: [SimpleCPU.Instruction.Spec : Data?] = [
      .nop: Data([0]),
      .ld(.a, .imm8): Data([1]),
      .ld(.a, .imm16): Data([2]),
      .call(.nz, .imm16): Data([3]),
      .call(nil, .imm16): Data([4]),
      .prefix(.sub): nil,
      .sub(.cp(.imm8)): Data([5, 0]),
    ]
    for spec in SimpleCPU.InstructionSet.allSpecs() {
      let value = SimpleCPU.InstructionSet.data(for: spec)
      XCTAssertEqual(value, opcodeData[spec], "\(spec) mismatched")
    }
  }
}
