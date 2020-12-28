import Foundation
import CPU

extension LR35902 {
  public struct InstructionSet: CPU.InstructionSet {
    public typealias InstructionType = LR35902.Instruction

    public static var widths: [Instruction.Spec: InstructionWidth<UInt16>] = {
      return computeAllWidths()
    }()

    public static var opcodeBytes: [Instruction.Spec : [UInt8]] = {
      return computeAllOpcodeBytes()
    }()

    public static var opcodeStrings: [SpecType : String] = {
      return computeAllOpcodeStrings()
    }()

    public static let table: [Instruction.Spec] = [
      /* 0x00 */ .nop,
      /* 0x01 */ .ld(.bc, .imm16),
      /* 0x02 */ .ld(.bcaddr, .a),
      /* 0x03 */ .inc(.bc),
      /* 0x04 */ .inc(.b),
      /* 0x05 */ .dec(.b),
      /* 0x06 */ .ld(.b, .imm8),
      /* 0x07 */ .rlca,
      /* 0x08 */ .ld(.imm16addr, .sp),
      /* 0x09 */ .add(.hl, .bc),
      /* 0x0a */ .ld(.a, .bcaddr),
      /* 0x0b */ .dec(.bc),
      /* 0x0c */ .inc(.c),
      /* 0x0d */ .dec(.c),
      /* 0x0e */ .ld(.c, .imm8),
      /* 0x0f */ .rrca,

      /* 0x10 */ .stop(.zeroimm8),
      /* 0x11 */ .ld(.de, .imm16),
      /* 0x12 */ .ld(.deaddr, .a),
      /* 0x13 */ .inc(.de),
      /* 0x14 */ .inc(.d),
      /* 0x15 */ .dec(.d),
      /* 0x16 */ .ld(.d, .imm8),
      /* 0x17 */ .rla,
      /* 0x18 */ .jr(nil, .simm8),
      /* 0x19 */ .add(.hl, .de),
      /* 0x1a */ .ld(.a, .deaddr),
      /* 0x1b */ .dec(.de),
      /* 0x1c */ .inc(.e),
      /* 0x1d */ .dec(.e),
      /* 0x1e */ .ld(.e, .imm8),
      /* 0x1f */ .rra,

      /* 0x20 */ .jr(.nz, .simm8),
      /* 0x21 */ .ld(.hl, .imm16),
      /* 0x22 */ .ldi(.hladdr, .a),
      /* 0x23 */ .inc(.hl),
      /* 0x24 */ .inc(.h),
      /* 0x25 */ .dec(.h),
      /* 0x26 */ .ld(.h, .imm8),
      /* 0x27 */ .daa,
      /* 0x28 */ .jr(.z, .simm8),
      /* 0x29 */ .add(.hl, .hl),
      /* 0x2a */ .ldi(.a, .hladdr),
      /* 0x2b */ .dec(.hl),
      /* 0x2c */ .inc(.l),
      /* 0x2d */ .dec(.l),
      /* 0x2e */ .ld(.l, .imm8),
      /* 0x2f */ .cpl,

      /* 0x30 */ .jr(.nc, .simm8),
      /* 0x31 */ .ld(.sp, .imm16),
      /* 0x32 */ .ldd(.hladdr, .a),
      /* 0x33 */ .inc(.sp),
      /* 0x34 */ .inc(.hladdr),
      /* 0x35 */ .dec(.hladdr),
      /* 0x36 */ .ld(.hladdr, .imm8),
      /* 0x37 */ .scf,
      /* 0x38 */ .jr(.c, .simm8),
      /* 0x39 */ .add(.hl, .sp),
      /* 0x3a */ .ldd(.a, .hladdr),
      /* 0x3b */ .dec(.sp),
      /* 0x3c */ .inc(.a),
      /* 0x3d */ .dec(.a),
      /* 0x3e */ .ld(.a, .imm8),
      /* 0x3f */ .ccf,

      /* 0x40 */ .ld(.b, .b),
      /* 0x41 */ .ld(.b, .c),
      /* 0x42 */ .ld(.b, .d),
      /* 0x43 */ .ld(.b, .e),
      /* 0x44 */ .ld(.b, .h),
      /* 0x45 */ .ld(.b, .l),
      /* 0x46 */ .ld(.b, .hladdr),
      /* 0x47 */ .ld(.b, .a),
      /* 0x48 */ .ld(.c, .b),
      /* 0x49 */ .ld(.c, .c),
      /* 0x4a */ .ld(.c, .d),
      /* 0x4b */ .ld(.c, .e),
      /* 0x4c */ .ld(.c, .h),
      /* 0x4d */ .ld(.c, .l),
      /* 0x4e */ .ld(.c, .hladdr),
      /* 0x4f */ .ld(.c, .a),

      /* 0x50 */ .ld(.d, .b),
      /* 0x51 */ .ld(.d, .c),
      /* 0x52 */ .ld(.d, .d),
      /* 0x53 */ .ld(.d, .e),
      /* 0x54 */ .ld(.d, .h),
      /* 0x55 */ .ld(.d, .l),
      /* 0x56 */ .ld(.d, .hladdr),
      /* 0x57 */ .ld(.d, .a),
      /* 0x58 */ .ld(.e, .b),
      /* 0x59 */ .ld(.e, .c),
      /* 0x5a */ .ld(.e, .d),
      /* 0x5b */ .ld(.e, .e),
      /* 0x5c */ .ld(.e, .h),
      /* 0x5d */ .ld(.e, .l),
      /* 0x5e */ .ld(.e, .hladdr),
      /* 0x5f */ .ld(.e, .a),

      /* 0x60 */ .ld(.h, .b),
      /* 0x61 */ .ld(.h, .c),
      /* 0x62 */ .ld(.h, .d),
      /* 0x63 */ .ld(.h, .e),
      /* 0x64 */ .ld(.h, .h),
      /* 0x65 */ .ld(.h, .l),
      /* 0x66 */ .ld(.h, .hladdr),
      /* 0x67 */ .ld(.h, .a),
      /* 0x68 */ .ld(.l, .b),
      /* 0x69 */ .ld(.l, .c),
      /* 0x6a */ .ld(.l, .d),
      /* 0x6b */ .ld(.l, .e),
      /* 0x6c */ .ld(.l, .h),
      /* 0x6d */ .ld(.l, .l),
      /* 0x6e */ .ld(.l, .hladdr),
      /* 0x6f */ .ld(.l, .a),

      /* 0x70 */ .ld(.hladdr, .b),
      /* 0x71 */ .ld(.hladdr, .c),
      /* 0x72 */ .ld(.hladdr, .d),
      /* 0x73 */ .ld(.hladdr, .e),
      /* 0x74 */ .ld(.hladdr, .h),
      /* 0x75 */ .ld(.hladdr, .l),
      /* 0x76 */ .halt,
      /* 0x77 */ .ld(.hladdr, .a),
      /* 0x78 */ .ld(.a, .b),
      /* 0x79 */ .ld(.a, .c),
      /* 0x7a */ .ld(.a, .d),
      /* 0x7b */ .ld(.a, .e),
      /* 0x7c */ .ld(.a, .h),
      /* 0x7d */ .ld(.a, .l),
      /* 0x7e */ .ld(.a, .hladdr),
      /* 0x7f */ .ld(.a, .a),

      /* 0x80 */ .add(.a, .b),
      /* 0x81 */ .add(.a, .c),
      /* 0x82 */ .add(.a, .d),
      /* 0x83 */ .add(.a, .e),
      /* 0x84 */ .add(.a, .h),
      /* 0x85 */ .add(.a, .l),
      /* 0x86 */ .add(.a, .hladdr),
      /* 0x87 */ .add(.a, .a),
      /* 0x88 */ .adc(.b),
      /* 0x89 */ .adc(.c),
      /* 0x8a */ .adc(.d),
      /* 0x8b */ .adc(.e),
      /* 0x8c */ .adc(.h),
      /* 0x8d */ .adc(.l),
      /* 0x8e */ .adc(.hladdr),
      /* 0x8f */ .adc(.a),

      /* 0x90 */ .sub(.a, .b),
      /* 0x91 */ .sub(.a, .c),
      /* 0x92 */ .sub(.a, .d),
      /* 0x93 */ .sub(.a, .e),
      /* 0x94 */ .sub(.a, .h),
      /* 0x95 */ .sub(.a, .l),
      /* 0x96 */ .sub(.a, .hladdr),
      /* 0x97 */ .sub(.a, .a),
      /* 0x98 */ .sbc(.b),
      /* 0x99 */ .sbc(.c),
      /* 0x9a */ .sbc(.d),
      /* 0x9b */ .sbc(.e),
      /* 0x9c */ .sbc(.h),
      /* 0x9d */ .sbc(.l),
      /* 0x9e */ .sbc(.hladdr),
      /* 0x9f */ .sbc(.a),

      /* 0xa0 */ .and(.b),
      /* 0xa1 */ .and(.c),
      /* 0xa2 */ .and(.d),
      /* 0xa3 */ .and(.e),
      /* 0xa4 */ .and(.h),
      /* 0xa5 */ .and(.l),
      /* 0xa6 */ .and(.hladdr),
      /* 0xa7 */ .and(.a),
      /* 0xa8 */ .xor(.b),
      /* 0xa9 */ .xor(.c),
      /* 0xaa */ .xor(.d),
      /* 0xab */ .xor(.e),
      /* 0xac */ .xor(.h),
      /* 0xad */ .xor(.l),
      /* 0xae */ .xor(.hladdr),
      /* 0xaf */ .xor(.a),

      /* 0xb0 */ .or(.b),
      /* 0xb1 */ .or(.c),
      /* 0xb2 */ .or(.d),
      /* 0xb3 */ .or(.e),
      /* 0xb4 */ .or(.h),
      /* 0xb5 */ .or(.l),
      /* 0xb6 */ .or(.hladdr),
      /* 0xb7 */ .or(.a),
      /* 0xb8 */ .cp(.b),
      /* 0xb9 */ .cp(.c),
      /* 0xba */ .cp(.d),
      /* 0xbb */ .cp(.e),
      /* 0xbc */ .cp(.h),
      /* 0xbd */ .cp(.l),
      /* 0xbe */ .cp(.hladdr),
      /* 0xbf */ .cp(.a),

      /* 0xc0 */ .ret(.nz),
      /* 0xc1 */ .pop(.bc),
      /* 0xc2 */ .jp(.nz, .imm16),
      /* 0xc3 */ .jp(nil, .imm16),
      /* 0xc4 */ .call(.nz, .imm16),
      /* 0xc5 */ .push(.bc),
      /* 0xc6 */ .add(.a, .imm8),
      /* 0xc7 */ .rst(.x00),
      /* 0xc8 */ .ret(.z),
      /* 0xc9 */ .ret(),
      /* 0xca */ .jp(.z, .imm16),
      /* 0xcb */ .prefix(.cb),
      /* 0xcc */ .call(.z, .imm16),
      /* 0xcd */ .call(nil, .imm16),
      /* 0xce */ .adc(.imm8),
      /* 0xcf */ .rst(.x08),

      /* 0xd0 */ .ret(.nc),
      /* 0xd1 */ .pop(.de),
      /* 0xd2 */ .jp(.nc, .imm16),
      /* 0xd3 */ .invalid,
      /* 0xd4 */ .call(.nc, .imm16),
      /* 0xd5 */ .push(.de),
      /* 0xd6 */ .sub(.a, .imm8),
      /* 0xd7 */ .rst(.x10),
      /* 0xd8 */ .ret(.c),
      /* 0xd9 */ .reti,
      /* 0xda */ .jp(.c, .imm16),
      /* 0xdb */ .invalid,
      /* 0xdc */ .call(.c, .imm16),
      /* 0xdd */ .invalid,
      /* 0xde */ .sbc(.imm8),
      /* 0xdf */ .rst(.x18),

      /* 0xe0 */ .ld(.ffimm8addr, .a),
      /* 0xe1 */ .pop(.hl),
      /* 0xe2 */ .ld(.ffccaddr, .a),
      /* 0xe3 */ .invalid,
      /* 0xe4 */ .invalid,
      /* 0xe5 */ .push(.hl),
      /* 0xe6 */ .and(.imm8),
      /* 0xe7 */ .rst(.x20),
      /* 0xe8 */ .add(.sp, .imm8),
      /* 0xe9 */ .jp(nil, .hl),
      /* 0xea */ .ld(.imm16addr, .a),
      /* 0xeb */ .invalid,
      /* 0xec */ .invalid,
      /* 0xed */ .invalid,
      /* 0xee */ .xor(.imm8),
      /* 0xef */ .rst(.x28),

      /* 0xf0 */ .ld(.a, .ffimm8addr),
      /* 0xf1 */ .pop(.af),
      /* 0xf2 */ .ld(.a, .ffccaddr),
      /* 0xf3 */ .di,
      /* 0xf4 */ .invalid,
      /* 0xf5 */ .push(.af),
      /* 0xf6 */ .or(.imm8),
      /* 0xf7 */ .rst(.x30),
      /* 0xf8 */ .ld(.hl, .sp_plus_simm8),
      /* 0xf9 */ .ld(.sp, .hl),
      /* 0xfa */ .ld(.a, .imm16addr),
      /* 0xfb */ .ei,
      /* 0xfc */ .invalid,
      /* 0xfd */ .invalid,
      /* 0xfe */ .cp(.imm8),
      /* 0xff */ .rst(.x38),
    ]
    public static let prefixTables: [Instruction.Spec: [Instruction.Spec]] = [
      .prefix(.cb): tableCB
    ]
  }
}
