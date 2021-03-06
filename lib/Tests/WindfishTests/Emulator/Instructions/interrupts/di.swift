import XCTest
@testable import Windfish

extension InstructionEmulatorTests {
  func test_di() {
    for spec in LR35902.InstructionSet.allSpecs() {
      guard let emulator = LR35902.Emulation.di(spec: spec) else { continue }
      InstructionEmulatorTests.testedSpecs.insert(spec)
      let memory = TestMemory()

      let cpu = LR35902.zeroed()
      cpu.ime = false

      let mutations = cpu.copy()
      mutations.ime = false

      var cycle = 0
      repeat {
        cycle += 1
      } while emulator.advance(cpu: cpu, memory: memory, cycle: cycle, sourceLocation: .memory(0)) == .continueExecution

      InstructionEmulatorTests.timings[spec, default: Set()].insert(cycle)
      XCTAssertEqual(cycle, 1)
      assertEqual(cpu, mutations)
    }
  }
}
