import Foundation
import Combine
import Cocoa

import LR35902

extension NSUserInterfaceItemIdentifier {
  static let programCounter = NSUserInterfaceItemIdentifier("pc")
  static let register = NSUserInterfaceItemIdentifier("name")
  static let registerState = NSUserInterfaceItemIdentifier("state")
  static let registerValue = NSUserInterfaceItemIdentifier("value")
}

private final class CPURegister: NSObject {
  init(name: String, state: String, value: UInt16) {
    self.name = name
    self.state = state
    self.value = value
  }

  @objc dynamic var name: String
  @objc dynamic var state: String
  @objc dynamic var value: UInt16
}

final class EmulatorViewController: NSViewController, TabSelectable {
  let deselectedTabImage = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)!
  let selectedTabImage = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)!

  let document: ProjectDocument
  let cpuController = NSArrayController()
  let registerStateController = NSArrayController()
  var tableView: NSTableView?
  let programCounterTextField = NSTextField()
  let instructionAssemblyLabel = CreateLabel()

  var cpuState = LR35902.CPUState(pc: 0x100, bank: 0x00)

  init(document: ProjectDocument) {
    self.document = document

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct Column {
    let name: String
    let identifier: NSUserInterfaceItemIdentifier
    let width: CGFloat
  }

  private var programCounterObserver: NSKeyValueObservation?
  private var disassembledSubscriber: AnyCancellable?

  override func loadView() {
    view = NSView()

    let controls = NSSegmentedControl()
    controls.translatesAutoresizingMaskIntoConstraints = false
    controls.trackingMode = .momentary
    controls.segmentStyle = .smallSquare
    controls.segmentCount = 2
    controls.setImage(NSImage(systemSymbolName: "arrowshape.bounce.forward.fill", accessibilityDescription: nil)!, forSegment: 0)
    controls.setWidth(40, forSegment: 0)
    controls.setEnabled(true, forSegment: 0)
    controls.target = self
    controls.action = #selector(performControlAction(_:))
    view.addSubview(controls)

    let programCounterLabel = CreateLabel()
    programCounterLabel.translatesAutoresizingMaskIntoConstraints = false
    programCounterLabel.stringValue = "Program counter:"
    programCounterLabel.alignment = .right
    view.addSubview(programCounterLabel)

    programCounterTextField.translatesAutoresizingMaskIntoConstraints = false
    programCounterTextField.formatter = LR35902AddressFormatter()
    programCounterTextField.stringValue = programCounterTextField.formatter!.string(for: cpuState.pc)!
    programCounterTextField.identifier = .programCounter
    programCounterTextField.delegate = self
    view.addSubview(programCounterTextField)

    let bankLabel = CreateLabel()
    bankLabel.translatesAutoresizingMaskIntoConstraints = false
    bankLabel.stringValue = "Bank:"
    bankLabel.alignment = .right
    view.addSubview(bankLabel)

    let bankTextField = NSTextField()
    bankTextField.translatesAutoresizingMaskIntoConstraints = false
    bankTextField.formatter = UInt8HexFormatter()
    bankTextField.stringValue = programCounterTextField.formatter!.string(for: cpuState.bank)!
    bankTextField.identifier = .bank
    bankTextField.delegate = self
    view.addSubview(bankTextField)

    let instructionLabel = CreateLabel()
    instructionLabel.translatesAutoresizingMaskIntoConstraints = false
    instructionLabel.stringValue = "Instruction:"
    view.addSubview(instructionLabel)

    instructionAssemblyLabel.translatesAutoresizingMaskIntoConstraints = false
    instructionAssemblyLabel.stringValue = "Waiting for disassembly results..."
    instructionAssemblyLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    view.addSubview(instructionAssemblyLabel)

    let containerView = NSScrollView()
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.hasVerticalScroller = true

    let tableView = NSTableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.style = .fullWidth
    tableView.selectionHighlightStyle = .regular
    tableView.delegate = self
    containerView.documentView = tableView
    view.addSubview(containerView)
    self.tableView = tableView

    let textFieldAlignmentGuide = NSLayoutGuide()
    view.addLayoutGuide(textFieldAlignmentGuide)

    let columns = [
      Column(name: "Register", identifier: .register, width: 100),
      Column(name: "State", identifier: .registerState, width: 100),
      Column(name: "Value", identifier: .registerValue, width: 50),
    ]

    for columnInfo in columns {
      let column = NSTableColumn(identifier: columnInfo.identifier)
      column.isEditable = false
      column.headerCell.stringValue = columnInfo.name
      column.width = columnInfo.width
      tableView.addTableColumn(column)
    }

    cpuController.add(contentsOf: [
      CPURegister(name: "a", state: "Unknown", value: 0),
      CPURegister(name: "b", state: "Unknown", value: 0),
      CPURegister(name: "c", state: "Unknown", value: 0),
      CPURegister(name: "d", state: "Unknown", value: 0),
      CPURegister(name: "e", state: "Unknown", value: 0),
      CPURegister(name: "h", state: "Unknown", value: 0),
      CPURegister(name: "l", state: "Unknown", value: 0),
    ])
    cpuController.setSelectionIndexes(IndexSet())

    registerStateController.addObject("Unknown")
    registerStateController.addObject("Literal")
    registerStateController.addObject("Address")

    NSLayoutConstraint.activate([
      controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

      programCounterLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4),
      programCounterLabel.topAnchor.constraint(equalToSystemSpacingBelow: controls.bottomAnchor, multiplier: 1),

      bankLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4),
      bankLabel.topAnchor.constraint(equalTo: programCounterLabel.bottomAnchor),

      textFieldAlignmentGuide.leadingAnchor.constraint(equalTo: programCounterLabel.trailingAnchor),
      textFieldAlignmentGuide.leadingAnchor.constraint(equalTo: bankLabel.trailingAnchor),
      textFieldAlignmentGuide.widthAnchor.constraint(equalToConstant: 8),

      programCounterTextField.leadingAnchor.constraint(equalTo: textFieldAlignmentGuide.trailingAnchor),
      programCounterTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      programCounterTextField.topAnchor.constraint(equalTo: programCounterLabel.topAnchor),
      bankLabel.topAnchor.constraint(equalTo: programCounterTextField.bottomAnchor),

      bankTextField.leadingAnchor.constraint(equalTo: textFieldAlignmentGuide.trailingAnchor),
      bankTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      bankTextField.topAnchor.constraint(equalTo: bankLabel.topAnchor),

      instructionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4),
      instructionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -4),
      instructionLabel.topAnchor.constraint(equalTo: bankLabel.bottomAnchor),
      instructionLabel.topAnchor.constraint(equalTo: bankTextField.bottomAnchor),

      instructionAssemblyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4),
      instructionAssemblyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -4),
      instructionAssemblyLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor),

      containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      containerView.topAnchor.constraint(equalToSystemSpacingBelow: instructionAssemblyLabel.bottomAnchor, multiplier: 1),
      containerView.heightAnchor.constraint(equalToConstant: 200),
    ])

    tableView.bind(.content, to: cpuController, withKeyPath: "arrangedObjects", options: nil)
    tableView.bind(.selectionIndexes, to: cpuController, withKeyPath:"selectionIndexes", options: nil)
    tableView.bind(.sortDescriptors, to: cpuController, withKeyPath: "sortDescriptors", options: nil)

    updateInstructionAssembly()

    disassembledSubscriber = NotificationCenter.default.publisher(for: .disassembled, object: document)
      .receive(on: RunLoop.main)
      .sink(receiveValue: { notification in
        self.updateInstructionAssembly()
      })
  }

  @objc func performControlAction(_ sender: NSSegmentedControl) {
    if sender.selectedSegment == 0 {
      guard let instruction = currentInstruction() else {
        return
      }
      cpuState = cpuState.emulate(instruction: instruction)
      programCounterTextField.objectValue = cpuState.pc
      updateInstructionAssembly()
    }
  }
}

extension EmulatorViewController: NSTextFieldDelegate {
  func controlTextDidEndEditing(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField,
          let identifier = textField.identifier else {
      preconditionFailure()
    }
    switch identifier {
    case .bank:
      cpuState.bank = textField.objectValue as! LR35902.Bank
    case .programCounter:
      cpuState.pc = textField.objectValue as! LR35902.Address
    default:
      preconditionFailure()
    }

    updateInstructionAssembly()
  }

  private func currentInstruction() -> LR35902.Instruction? {
    return document.disassemblyResults?.disassembly?.instruction(at: cpuState.pc, in: cpuState.bank)
  }

  private func updateInstructionAssembly() {
    guard let disassembly = document.disassemblyResults?.disassembly else {
      return
    }
    guard let instruction = currentInstruction() else {
      instructionAssemblyLabel.stringValue = "No instruction detected"
      return
    }

    let context = RGBDSDisassembler.Context(
      address: cpuState.pc,
      bank: cpuState.bank,
      disassembly: disassembly,
      argumentString: nil
    )
    let statement = RGBDSDisassembler.statement(for: instruction, with: context)
    instructionAssemblyLabel.stringValue = statement.formattedString
  }
}

extension EmulatorViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn = tableColumn else {
      preconditionFailure()
    }

    switch tableColumn.identifier {
    case .register:
      let identifier = NSUserInterfaceItemIdentifier.textCell
      let view: TextTableCellView
      if let recycledView = tableView.makeView(withIdentifier: identifier, owner: self) as? TextTableCellView {
        view = recycledView
      } else {
        view = TextTableCellView()
        view.identifier = identifier
      }
      view.textField?.bind(.value, to: view, withKeyPath: "objectValue.\(tableColumn.identifier.rawValue)", options: nil)
      return view
    case .registerState:
      let identifier = NSUserInterfaceItemIdentifier.typeCell
      let view: TypeTableCellView
      if let recycledView = tableView.makeView(withIdentifier: identifier, owner: self) as? TypeTableCellView {
        view = recycledView
      } else {
        view = TypeTableCellView()
        view.identifier = identifier
      }
      view.popupButton.bind(.content, to: registerStateController, withKeyPath: "arrangedObjects", options: nil)
      view.popupButton.bind(.selectedObject, to: view, withKeyPath: "objectValue.\(tableColumn.identifier.rawValue)", options: nil)
      return view
    case .registerValue:
      let identifier = NSUserInterfaceItemIdentifier.addressCell
      let view: TextTableCellView
      if let recycledView = tableView.makeView(withIdentifier: identifier, owner: self) as? TextTableCellView {
        view = recycledView
      } else {
        view = TextTableCellView()
        view.identifier = identifier
        view.textField?.formatter = LR35902AddressFormatter()
      }
      view.textField?.bind(.value, to: view, withKeyPath: "objectValue.\(tableColumn.identifier.rawValue)", options: nil)
      return view
    default:
      preconditionFailure()
    }
  }
}