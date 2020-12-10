import Foundation

extension InstructionSpec {
  /**
   Invokes a visitor for each operand of the subspec.

   Assumes the following:

   - Self is an enum where each case is an opcode with zero or more associated operands.
   - Operands are only associated with the leaf node of a nested specification.

   nil operands are skipped.

   - parameter visitor: Invoked for each non-nil operand of the specification.
   */
  public func visit(visitor: ((value: Any, index: Int)?) -> Void) {
    guard let operands = Mirror(reflecting: self).children.first else {
      visitor(nil)
      return
    }
    if let subSpec = operands.value as? Self {
      subSpec.visit(visitor: visitor)
      return
    }

    let children: Mirror.Children
    let reflectedChildren = Mirror(reflecting: operands.value).children
    if reflectedChildren.count > 1 {
      children = reflectedChildren
    } else {
      // If there is only a single operand then reflectedChildren will not enumerate, so we fake it being enumerable
      // by populating a list with the sole operand value.
      children = Mirror.Children([(label: nil, value: operands.value)])
    }
    var index = 0
    for child in children {
      // Any isn't nullable, even though it might represent a null value (e.g. a .jr(nil, .imm8) spec with an
      // optional first argument), so we need to use Optional<Any>.none to represent an optional argument in this case.
      if case Optional<Any>.none = child.value {
        continue
      }
      visitor((value: child.value, index: index))
      index += 1
    }
  }
}