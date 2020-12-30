import Foundation

// References:
// - https://www.youtube.com/watch?v=HyzD8pNlpwI&t=29m19s
// - https://gbdev.gg8.se/wiki/articles/Video_Display#FF41_-_STAT_-_LCDC_Status_.28R.2FW.29
// - https://realboyemulator.files.wordpress.com/2013/01/gbcpuman.pdf
// - http://gameboy.mongenel.com/dmg/asmmemmap.html
// - https://hacktix.github.io/GBEDG/ppu/#the-concept-of-scanlines

public final class LCDController {
  static let tileMapRegion: ClosedRange<LR35902.Address> = 0x9800...0x9FFF
  static let tileDataRegion: ClosedRange<LR35902.Address> = 0x8000...0x97FF
  static let registerRegion1: ClosedRange<LR35902.Address> = 0xFF40...0xFF45
  static let registerRegion2: ClosedRange<LR35902.Address> = 0xFF47...0xFF4B

  init(oam: OAM) {
    self.oam = oam
  }

  let oam: OAM

  var tileMap: [LR35902.Address: UInt8] = [:]
  var tileData = Data(count: tileDataRegion.count)

  var bufferToggle = false
  static let screenSize = (width: 160, height: 144)
  private var screenData = Data(count: LCDController.screenSize.width * LCDController.screenSize.height)

  enum Addresses: LR35902.Address {
    case LCDC = 0xFF40
    case STAT = 0xFF41
    case SCY  = 0xFF42
    case SCX  = 0xFF43
    case LY   = 0xFF44
    case LYC  = 0xFF45
    case DMA  = 0xFF46
    case BGP  = 0xFF47
    case OBP0 = 0xFF48
    case OBP1 = 0xFF49
    case WY   = 0xFF4A
    case WX   = 0xFF4B
  }
  var values: [Addresses: UInt8] = [
    .SCY:  0x00,
    .SCX:  0x00,
  ]

  // MARK: LCDC bits (0xFF40)

  enum TileMapAddress {
    case x9800 // 0
    case x9C00 // 1
  }
  enum TileDataAddress {
    case x8800 // 0
    case x8000 // 1
  }
  enum SpriteSize {
    case x8x8  // 0
    case x8x16 // 1

    func height() -> UInt8 {
      switch self {
      case .x8x8:  return 8
      case .x8x16: return 16
      }
    }
  }
  /**
   Whether the display is turned on or not.

   Can only be disabled during V-blank.
   */
  var lcdDisplayEnable = true {                       // bit 7
    willSet {
      precondition(
        (lcdDisplayEnable && !newValue) && ly >= 144  // Can only change during v-blank
          || lcdDisplayEnable == newValue             // No change
          || !lcdDisplayEnable && newValue            // Can always enable.
      )
    }
    didSet {
      if !lcdDisplayEnable {
        ly = 0
        lcdMode = .searchingOAM
      }
    }
  }
  var windowTileMapAddress = TileMapAddress.x9800      // bit 6
  var windowEnable = false                             // bit 5
  var tileDataAddress = TileDataAddress.x8000          // bit 4
  var backgroundTileMapAddress = TileMapAddress.x9800  // bit 3
  var spriteSize = SpriteSize.x8x8                     // bit 2
  var objEnable = false                                // bit 1
  var backgroundEnable = true                          // bit 0

  // MARK: STAT bits (0xFF41)

  enum LCDCMode {
    case hblank
    case vblank

    // TODO: Not able to read oamram during this mode
    case searchingOAM

    // TODO: Any reads of vram or oamram during this mode should return 0xff; writes are ignored
    case transferringToLCDDriver

    var bits: UInt8 {
      switch self {
      case .hblank:                   return 0b0000_0000
      case .vblank:                   return 0b0000_0001
      case .searchingOAM:             return 0b0000_0010
      case .transferringToLCDDriver:  return 0b0000_0011
      }
    }
  }
  var enableCoincidenceInterrupt = false          // bit 6
  var enableOAMInterrupt = false                  // bit 5
  var enableVBlankInterrupt = false               // bit 4
  var enableHBlankInterrupt = false               // bit 3
  var coincidence: Bool {                         // bit 2
    return ly == lyc
  }
  private var lcdMode = LCDCMode.searchingOAM {   // bits 1 and 0
    didSet {
      if lcdMode == .searchingOAM {
        intersectedOAMs = []
        oamIndex = 0
      }
    }
  }

  // MARK: LY (0xFF44)

  /** The vertical line to which data is transferred to the display. */
  var ly: UInt8 = 0

  // MARK: LYC (0xFF45)

  var lyc: UInt8 = 0

  // MARK: BGP (0xFF47)

  typealias Palette = [UInt8: UInt8]

  private func bitsForPalette(_ palette: Palette) -> UInt8 {
    return (palette[0]! & UInt8(0b0000_0011))
        | ((palette[1]! & UInt8(0b0000_0011)) << 2)
        | ((palette[2]! & UInt8(0b0000_0011)) << 4)
        | ((palette[3]! & UInt8(0b0000_0011)) << 6)
  }

  private func paletteFromBits(_ bits: UInt8) -> Palette {
    return [
      0: bits & 0b0000_0011,
      1: (bits >> 2) & 0b0000_0011,
      2: (bits >> 4) & 0b0000_0011,
      3: (bits >> 6) & 0b0000_0011,
    ]
  }

  /** Shade values for background and window tiles. */
  var backgroundPalette: Palette = [
    0: 0,
    1: 1,
    2: 2,
    3: 3,
  ]

  // MARK: OBP0 and OBP1 (0xFF48 and 0xFF49)

  /** Shade values for background and window tiles. */
  var objectPallete0: Palette = [
    0: 0,
    1: 1,
    2: 2,
    3: 3,
  ]

  /** Shade values for background and window tiles. */
  var objectPallete1: Palette = [
    0: 0,
    1: 1,
    2: 2,
    3: 3,
  ]

  // MARK: WY and WX (0xFF4A and 0xFF4B)

  var wy: UInt8 = 0
  var wx: UInt8 = 0

  // MARK: .searchingOAM state

  /** How many cycles have been advanced for the current lcdMode. */
  private var lcdModeCycle: Int = 0
  private var intersectedOAMs: [OAM.Sprite] = []
  private var oamIndex = 0

  // MARK: .transferringToLCDDriver state
  private struct Pixel {
    let color: UInt8
    let palette: UInt8
    let spritePriority: UInt8
    let bgPriority: UInt8
  }
  private var bgfifo: [Pixel] = []
  private var spritefifo: [Pixel] = []
  private var transferringToLCDDriverCycle: Int = 0
  private var scanlineX: Int = 0
}

// MARK: - Emulation

extension LCDController {
  static let searchingOAMLength = 20
  static let scanlineCycleLength = 114

  private func plot(x: Int, y: Int, byte: UInt8) {
    screenData[LCDController.screenSize.width * y + x] = byte
  }

  /** Takes 2 machine cycles to conclude. */
  private func getTile() {
    if windowEnable && wx <= scanlineX && wy <= ly {
      // TODO: Implement pixel fifo.
    }
  }

  /** Executes a single machine cycle.  */
  public func advance(memory: AddressableMemory) {
    guard lcdDisplayEnable else {
      return
    }

    lcdModeCycle += 1

    switch lcdMode {
    case .searchingOAM:
      // One OAM search takes two T-cycles, so we can perform two per machine cycle.
      searchNextOAM()
      searchNextOAM()

      if lcdModeCycle >= LCDController.searchingOAMLength {
//        precondition(intersectedOAMs.count == 0, "Sprites not handled yet.")
        lcdMode = .transferringToLCDDriver
        transferringToLCDDriverCycle = 0
        scanlineX = 0
        bgfifo.removeAll()
        spritefifo.removeAll()
      }
      break
    case .transferringToLCDDriver:
      transferringToLCDDriverCycle += 1

      getTile()

      if lcdModeCycle >= 63 {
        lcdMode = .hblank
        // Don't reset lcdModeCycle yet, as this mode can actually end early.
      }
      break
    case .hblank:
      if lcdModeCycle >= LCDController.scanlineCycleLength {
        ly += 1
        if ly < 144 {
          lcdMode = .searchingOAM
        } else {
          // No more lines to draw.
          lcdMode = .vblank

          var interruptFlag = LR35902.Instruction.Interrupt(rawValue: memory.read(from: LR35902.interruptFlagAddress))
          interruptFlag.insert(.vBlank)
          memory.write(interruptFlag.rawValue, to: LR35902.interruptFlagAddress)
        }
      }
      break
    case .vblank:
      if lcdModeCycle % LCDController.scanlineCycleLength == 0 {
        ly += 1

        if ly >= 154 {
          ly = 0
          lcdMode = .searchingOAM
        }
      }
      break
    }
  }

  // MARK: OAM search

  private func searchNextOAM() {
    if intersectedOAMs.count < 10 {
      let sprite = oam.sprites[oamIndex]
      oamIndex += 1
      if sprite.x > 0
          && ly + 16 >= sprite.y
          && ly + 16 < sprite.y + spriteSize.height() {
        intersectedOAMs.append(sprite)
      }
    }
  }
}

// MARK: - AddressableMemory

extension LCDController: AddressableMemory {
  public func read(from address: LR35902.Address) -> UInt8 {
    if LCDController.tileMapRegion.contains(address) {
      return tileMap[address]!
    }
    if LCDController.tileDataRegion.contains(address) {
      return tileData[Int(address - LCDController.tileDataRegion.lowerBound)]
    }
    if OAM.addressableRange.contains(address) {
      guard lcdMode == .hblank || lcdMode == .vblank else {
        return 0xFF  // OAM are only accessible during hblank and vblank
      }
      return oam.read(from: address)
    }

    guard let lcdAddress = Addresses(rawValue: address) else {
      preconditionFailure("Invalid address")
    }
    switch lcdAddress {
    case .LCDC:
      return (
        (lcdDisplayEnable                       ? 0b1000_0000 : 0)
          | (windowTileMapAddress == .x9C00     ? 0b0100_0000 : 0)
          | (windowEnable                       ? 0b0010_0000 : 0)
          | (tileDataAddress == .x8000          ? 0b0001_0000 : 0)
          | (backgroundTileMapAddress == .x9C00 ? 0b0000_1000 : 0)
          | (spriteSize == .x8x16               ? 0b0000_0100 : 0)
          | (objEnable                          ? 0b0000_0010 : 0)
          | (backgroundEnable                   ? 0b0000_0001 : 0)
      )

    case .LY:   return ly
    case .LYC:  return lyc

    case .WY:   return wy
    case .WX:   return wx

    case .BGP:  return bitsForPalette(backgroundPalette)
    case .OBP0: return bitsForPalette(objectPallete0)
    case .OBP1: return bitsForPalette(objectPallete1)

    case .STAT:
      return (
        (enableCoincidenceInterrupt   ? 0b0100_0000 : 0)
          | (enableOAMInterrupt       ? 0b0010_0000 : 0)
          | (enableVBlankInterrupt    ? 0b0001_0000 : 0)
          | (enableHBlankInterrupt    ? 0b0000_1000 : 0)
          | (coincidence              ? 0b0000_0100 : 0)
          | lcdMode.bits
      )

    default:
      return values[lcdAddress]!
    }
  }

  public func write(_ byte: UInt8, to address: LR35902.Address) {
    if LCDController.tileMapRegion.contains(address) {
      tileMap[address] = byte
      return
    }
    if LCDController.tileDataRegion.contains(address) {
      tileData[Int(address - LCDController.tileDataRegion.lowerBound)] = byte
      return
    }
    if OAM.addressableRange.contains(address) {
      guard lcdMode == .hblank || lcdMode == .vblank else {
        // OAM are only accessible during hblank and vblank.
        // Note that DMAController has direct write access and circumvents this check when running.
        return
      }
      oam.write(byte, to: address)
      return
    }
    guard let lcdAddress = Addresses(rawValue: address) else {
      preconditionFailure("Invalid address")
    }
    switch lcdAddress {
    case .LCDC:
      lcdDisplayEnable          = (byte & 0b1000_0000) > 0
      windowTileMapAddress      = (byte & 0b0100_0000) > 0 ? .x9C00 : .x9800
      windowEnable              = (byte & 0b0010_0000) > 0
      tileDataAddress           = (byte & 0b0001_0000) > 0 ? .x8000 : .x8800
      backgroundTileMapAddress  = (byte & 0b0000_1000) > 0 ? .x9C00 : .x9800
      spriteSize                = (byte & 0b0000_0100) > 0 ? .x8x16 : .x8x8
      objEnable                 = (byte & 0b0000_0010) > 0
      backgroundEnable          = (byte & 0b0000_0001) > 0

    case .LY:  ly = 0
    case .LYC: lyc = 0

    case .WY:   wy = byte
    case .WX:   wx = byte

    case .BGP:  backgroundPalette = paletteFromBits(byte)
    case .OBP0: objectPallete0 = paletteFromBits(byte)
    case .OBP1: objectPallete1 = paletteFromBits(byte)

    case .STAT:
      enableCoincidenceInterrupt  = (byte & 0b0100_0000) > 0
      enableOAMInterrupt          = (byte & 0b0010_0000) > 0
      enableVBlankInterrupt       = (byte & 0b0001_0000) > 0
      enableHBlankInterrupt       = (byte & 0b0000_1000) > 0

    default:
      values[lcdAddress] = byte
    }
  }

  public func sourceLocation(from address: LR35902.Address) -> Disassembler.SourceLocation {
    return .memory(address)
  }
}
