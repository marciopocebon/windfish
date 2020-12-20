import XCTest
@testable import LR35902

class CPUStateTests: XCTestCase {

  // MARK: - 8-bit initialization

  func test_initializes_a() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.a = 1
    assertEqual(mutatedState, LR35902.CPUState(a: 1))
  }

  func test_initializes_b() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.b = 1
    assertEqual(mutatedState, LR35902.CPUState(b: 1))
  }

  func test_initializes_c() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.c = 1
    assertEqual(mutatedState, LR35902.CPUState(c: 1))
  }

  func test_initializes_d() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.d = 1
    assertEqual(mutatedState, LR35902.CPUState(d: 1))
  }

  func test_initializes_e() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.e = 1
    assertEqual(mutatedState, LR35902.CPUState(e: 1))
  }

  func test_initializes_h() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.h = 1
    assertEqual(mutatedState, LR35902.CPUState(h: 1))
  }

  func test_initializes_l() throws {
    var mutatedState = LR35902.CPUState()
    mutatedState.l = 1
    assertEqual(mutatedState, LR35902.CPUState(l: 1))
  }

  // MARK: - Wide registers

  func test_bc_is_b_and_c() throws {
    let state = LR35902.CPUState(b: 0x01, c: 0x20)
    XCTAssertEqual(state.bc, 0x0120)
  }

  func test_de_is_d_and_e() throws {
    let state = LR35902.CPUState(d: 0x01, e: 0x20)
    XCTAssertEqual(state.de, 0x0120)
  }

  func test_hl_is_h_and_l() throws {
    let state = LR35902.CPUState(h: 0x01, l: 0x20)
    XCTAssertEqual(state.hl, 0x0120)
  }

  // MARK: - 8-bit subscripts

  func test_a_subscript() throws {
    let state = LR35902.CPUState(a: 1)
    XCTAssertEqual(state[.a] as UInt8, 1)
  }

  func test_b_subscript() throws {
    let state = LR35902.CPUState(b: 1)
    XCTAssertEqual(state[.b] as UInt8, 1)
  }

  func test_c_subscript() throws {
    let state = LR35902.CPUState(c: 1)
    XCTAssertEqual(state[.c] as UInt8, 1)
  }

  func test_d_subscript() throws {
    let state = LR35902.CPUState(d: 1)
    XCTAssertEqual(state[.d] as UInt8, 1)
  }

  func test_e_subscript() throws {
    let state = LR35902.CPUState(e: 1)
    XCTAssertEqual(state[.e] as UInt8, 1)
  }

  func test_h_subscript() throws {
    let state = LR35902.CPUState(h: 1)
    XCTAssertEqual(state[.h] as UInt8, 1)
  }

  func test_l_subscript() throws {
    let state = LR35902.CPUState(l: 1)
    XCTAssertEqual(state[.l] as UInt8, 1)
  }

  func test_a_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.a] = 1 as UInt8
    XCTAssertEqual(state[.a] as UInt8, 1)
  }

  func test_b_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.b] = 1 as UInt8
    XCTAssertEqual(state[.b] as UInt8, 1)
  }

  func test_c_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.c] = 1 as UInt8
    XCTAssertEqual(state[.c] as UInt8, 1)
  }

  func test_d_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.d] = 1 as UInt8
    XCTAssertEqual(state[.d] as UInt8, 1)
  }

  func test_e_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.e] = 1 as UInt8
    XCTAssertEqual(state[.e] as UInt8, 1)
  }

  func test_h_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.h] = 1 as UInt8
    XCTAssertEqual(state[.h] as UInt8, 1)
  }

  func test_l_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.l] = 1 as UInt8
    XCTAssertEqual(state[.l] as UInt8, 1)
  }

  // MARK: - 16-bit subscripts

  func test_bc_subscript() throws {
    let state = LR35902.CPUState(b: 0x01, c: 0x20)
    XCTAssertEqual(state[.bc] as UInt16, 0x0120)
  }

  func test_de_subscript() throws {
    let state = LR35902.CPUState(d: 0x01, e: 0x20)
    XCTAssertEqual(state[.de] as UInt16, 0x0120)
  }

  func test_hl_subscript() throws {
    let state = LR35902.CPUState(h: 0x01, l: 0x20)
    XCTAssertEqual(state[.hl] as UInt16, 0x0120)
  }

  func test_bc_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.bc] = 0x0120 as UInt16
    XCTAssertEqual(state[.bc] as UInt16, 0x0120)
  }

  func test_de_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.de] = 0x0120 as UInt16
    XCTAssertEqual(state[.de] as UInt16, 0x0120)
  }

  func test_hl_subscript_setter() throws {
    var state = LR35902.CPUState()
    state[.hl] = 0x0120 as UInt16
    XCTAssertEqual(state[.hl] as UInt16, 0x0120)
  }
}
