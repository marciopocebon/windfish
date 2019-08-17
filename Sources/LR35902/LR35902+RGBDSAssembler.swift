import Foundation

import FixedWidthInteger

extension StringProtocol {
  fileprivate func trimmed() -> String {
    return self.trimmingCharacters(in: .whitespaces)
  }
}

private func codeAndComments(from line: String) -> (code: String?, comment: String?) {
  let parts = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
  return (code: parts.first?.trimmed(), comment: parts.last?.trimmed())
}

private func createStatement(from code: String) -> RGBDSAssembly.Statement {
  let opcodeAndOperands = code.split(separator: " ", maxSplits: 1)

  let opcode = opcodeAndOperands[0].lowercased()

  if opcodeAndOperands.count > 1 {
    let operands: [String] = opcodeAndOperands[1].components(separatedBy: ",").map { $0.trimmed() }
    return RGBDSAssembly.Statement(opcode: opcode, operands: operands)
  } else {
    return RGBDSAssembly.Statement(opcode: opcode)
  }
}

private func createRepresentation(from statement: RGBDSAssembly.Statement) -> String {
  if let operands: [String] = statement.operands?.map({ operand in
    if operand.starts(with: "$") || operand.starts(with: "0x") || Int(operand) != nil {
      return "#"
    }
    return operand
  }) {
    return "\(statement.opcode) \(operands.joined(separator: ", "))"
  } else {
    return statement.opcode
  }
}

private func extractOperandsAsBinary(from statement: RGBDSAssembly.Statement, using spec: LR35902.InstructionSpec) throws -> [UInt8] {
  guard let operands = Mirror(reflecting: spec).children.first else {
    return []
  }
  var binaryOperands: [UInt8] = []
  for (index, child) in Mirror(reflecting: operands.value).children.enumerated() {
    switch child.value {
    case LR35902.Operand.immediate16:
      if let value = Mirror(reflecting: statement).descendant(1, 0, index) as? String,
        value.starts(with: "$") {
        guard var numericValue = UInt16(value.dropFirst(), radix: 16) else {
          throw RGBDSAssembler.Error(lineNumber: nil, error: "Unable to represent \(value) as a UInt16")
        }
        withUnsafeBytes(of: &numericValue) { buffer in
          binaryOperands.append(contentsOf: Data(buffer))
        }
      }
    default:
      break
    }
  }
  return binaryOperands
}

public final class RGBDSAssembler {

  public init() {
  }

  public var buffer = Data()

  public struct Error: Swift.Error, Equatable {
    let lineNumber: Int?
    let error: String
  }

  public func assemble(assembly: String) -> [Error] {
    var lineNumber = 1
    var errors: [Error] = []

    assembly.enumerateLines { (line, stop) in
      defer {
        lineNumber += 1
      }

      guard let code = codeAndComments(from: line).code, code.count > 0 else {
        return
      }

      let statement = createStatement(from: code)
      let representation = createRepresentation(from: statement)

      guard let spec = RGBDSAssembler.representations[representation] else {
        errors.append(Error(lineNumber: lineNumber, error: "Invalid instruction: \(code)"))
        return
      }

      do {
        let operandsAsBinary = try extractOperandsAsBinary(from: statement, using: spec)
        self.buffer.append(contentsOf: RGBDSAssembler.instructionOpcodeBinary[spec]!)
        self.buffer.append(contentsOf: operandsAsBinary)

      } catch let error as RGBDSAssembler.Error {
        if error.lineNumber == nil {
          errors.append(.init(lineNumber: lineNumber, error: error.error))
        } else {
          errors.append(error)
        }
        return
      } catch {
        return
      }
    }
    return errors
  }

  static var representations: [String: LR35902.InstructionSpec] = {
    var representations: [String: LR35902.InstructionSpec] = [:]
    LR35902.instructionTable.forEach { spec in
      if case .invalid = spec {
        return
      }
      assert(representations[spec.representation] == nil, "Unexpected collision.")
      representations[spec.representation] = spec
    }
    LR35902.instructionTableCB.forEach { spec in
      if case .invalid = spec {
        return
      }
      assert(representations[spec.representation] == nil, "Unexpected collision.")
      representations[spec.representation] = spec
    }
    return representations
  }()

  static var instructionOpcodeBinary: [LR35902.InstructionSpec: [UInt8]] = {
    var binary: [LR35902.InstructionSpec: [UInt8]] = [:]
    for (byteRepresentation, spec) in LR35902.instructionTable.enumerated() {
      binary[spec] = [UInt8(byteRepresentation)]
    }
    for (byteRepresentation, spec) in LR35902.instructionTableCB.enumerated() {
      binary[spec] = [0xCB, UInt8(byteRepresentation)]
    }
    return binary
  }()

}
