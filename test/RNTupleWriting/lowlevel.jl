using UnROOT: rnt_write, RNTupleFrame, ClusterSummary, PageDescription, Write_RNTupleListFrame, RBlob
using XXHashNative: xxh3_64
using Tables: columntable

const REFERENCE_BYTES = [
    0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0xF7, 0x45, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x06, 0x43,
    0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x54,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x61, 0x00, 0x00, 0x01, 0xA3, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x00, 0x04, 0x00, 0x00, 0x00, 0x56, 0x75, 0x67,
    0x17, 0x6D, 0x00, 0x3A, 0x00, 0x01, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x05, 0x54,
    0x46, 0x69, 0x6C, 0x65, 0x18, 0x74, 0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65,
    0x5F, 0x6D, 0x69, 0x6E, 0x69, 0x6D, 0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00, 0x18, 0x74,
    0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E, 0x69, 0x6D,
    0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0x05, 0x75, 0x67, 0x17, 0x6D, 0x75, 0x67,
    0x17, 0x6D, 0x00, 0x00, 0x00, 0x79, 0x00, 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x03, 0xE8, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xDC, 0x00, 0x04, 0x00, 0x00, 0x00, 0xBA, 0x75, 0x67,
    0x17, 0x6D, 0x00, 0x22, 0x00, 0x01, 0x00, 0x00, 0x00, 0xF4, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52,
    0x42, 0x6C, 0x6F, 0x62, 0x00, 0x00, 0x01, 0x00, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x6D, 0x79, 0x6E, 0x74, 0x75, 0x70,
    0x6C, 0x65, 0x00, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x52, 0x4F, 0x4F, 0x54, 0x20, 0x76,
    0x36, 0x2E, 0x33, 0x33, 0x2E, 0x30, 0x31, 0xB7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,
    0x00, 0x00, 0x00, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x6F,
    0x6E, 0x65, 0x5F, 0x75, 0x69, 0x6E, 0x74, 0x0D, 0x00, 0x00, 0x00, 0x73, 0x74, 0x64, 0x3A, 0x3A,
    0x75, 0x69, 0x6E, 0x74, 0x33, 0x32, 0x5F, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xE0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x14, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D,
    0x00, 0x00, 0x00, 0x26, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x22,
    0x00, 0x01, 0x00, 0x00, 0x01, 0xD0, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62,
    0x00, 0x00, 0xCE, 0xCE, 0xCE, 0xCE, 0x00, 0x00, 0x00, 0x9E, 0x00, 0x04, 0x00, 0x00, 0x00, 0x7C,
    0x75, 0x67, 0x17, 0x6D, 0x00, 0x22, 0x00, 0x01, 0x00, 0x00, 0x01, 0xF6, 0x00, 0x00, 0x00, 0x64,
    0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62, 0x00, 0x00, 0x03, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D, 0xDC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x01, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0xCC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x01, 0x00, 0x00, 0x00, 0xD8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xF2, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1C, 0xA0, 0xDF, 0x2E,
    0x25, 0x1E, 0x55, 0x4C, 0x00, 0x00, 0x00, 0xCE, 0x00, 0x04, 0x00, 0x00, 0x00, 0xAC, 0x75, 0x67,
    0x17, 0x6D, 0x00, 0x22, 0x00, 0x01, 0x00, 0x00, 0x02, 0x94, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52,
    0x42, 0x6C, 0x6F, 0x62, 0x00, 0x00, 0x02, 0x00, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D, 0x38, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
    0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00,
    0x00, 0x00, 0xC4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x30, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x18, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xA1, 0xD9, 0x13, 0x0B, 0x80, 0xBB,
    0xFE, 0x3C, 0x00, 0x00, 0x00, 0x86, 0x00, 0x04, 0x00, 0x00, 0x00, 0x46, 0x75, 0x67, 0x17, 0x6D,
    0x00, 0x40, 0x00, 0x01, 0x00, 0x00, 0x03, 0x62, 0x00, 0x00, 0x00, 0x64, 0x1B, 0x52, 0x4F, 0x4F,
    0x54, 0x3A, 0x3A, 0x45, 0x78, 0x70, 0x65, 0x72, 0x69, 0x6D, 0x65, 0x6E, 0x74, 0x61, 0x6C, 0x3A,
    0x3A, 0x52, 0x4E, 0x54, 0x75, 0x70, 0x6C, 0x65, 0x08, 0x6D, 0x79, 0x6E, 0x74, 0x75, 0x70, 0x6C,
    0x65, 0x00, 0x40, 0x00, 0x00, 0x42, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBA,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xB6,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC,
    0xDC, 0x49, 0x5F, 0xD0, 0x14, 0x79, 0xAF, 0x1B, 0x00, 0x00, 0x00, 0x79, 0x00, 0x04, 0x00, 0x00,
    0x00, 0x44, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x35, 0x00, 0x01, 0x00, 0x00, 0x03, 0xE8, 0x00, 0x00,
    0x00, 0x64, 0x00, 0x18, 0x74, 0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F,
    0x6D, 0x69, 0x6E, 0x69, 0x6D, 0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x86, 0x00, 0x04, 0x00, 0x00, 0x00, 0x46, 0x75, 0x67, 0x17, 0x6D, 0x00,
    0x40, 0x00, 0x01, 0x00, 0x00, 0x03, 0x62, 0x00, 0x00, 0x00, 0x64, 0x1B, 0x52, 0x4F, 0x4F, 0x54,
    0x3A, 0x3A, 0x45, 0x78, 0x70, 0x65, 0x72, 0x69, 0x6D, 0x65, 0x6E, 0x74, 0x61, 0x6C, 0x3A, 0x3A,
    0x52, 0x4E, 0x54, 0x75, 0x70, 0x6C, 0x65, 0x08, 0x6D, 0x79, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65,
    0x00, 0x00, 0x00, 0x01, 0xA3, 0x00, 0x04, 0x00, 0x00, 0x04, 0xF2, 0x75, 0x67, 0x17, 0x6D, 0x00,
    0x40, 0x00, 0x01, 0x00, 0x00, 0x04, 0x61, 0x00, 0x00, 0x00, 0x64, 0x05, 0x54, 0x4C, 0x69, 0x73,
    0x74, 0x0C, 0x53, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x65, 0x72, 0x49, 0x6E, 0x66, 0x6F, 0x12, 0x44,
    0x6F, 0x75, 0x62, 0x6C, 0x79, 0x20, 0x6C, 0x69, 0x6E, 0x6B, 0x65, 0x64, 0x20, 0x6C, 0x69, 0x73,
    0x74, 0x5A, 0x4C, 0x08, 0x5A, 0x01, 0x00, 0xF2, 0x04, 0x00, 0x78, 0x01, 0xBD, 0x92, 0x4D, 0x4E,
    0xC2, 0x40, 0x1C, 0xC5, 0x1F, 0x05, 0x13, 0x91, 0x8F, 0xAD, 0x1A, 0x36, 0x6E, 0xBD, 0x42, 0x57,
    0x15, 0x83, 0x91, 0x44, 0x29, 0x42, 0xC5, 0x68, 0x82, 0x66, 0x80, 0x29, 0x94, 0x8F, 0x99, 0x66,
    0xDA, 0x26, 0xB2, 0x63, 0xE7, 0x69, 0xBC, 0x84, 0x97, 0xD0, 0x53, 0x78, 0x05, 0xFD, 0x77, 0x24,
    0x04, 0x12, 0x89, 0x68, 0x83, 0x2F, 0x99, 0x69, 0x3B, 0xED, 0xBC, 0x5F, 0xFB, 0x5E, 0x2D, 0x64,
    0xDE, 0xB1, 0x83, 0x14, 0x48, 0x46, 0x3C, 0x91, 0x52, 0x16, 0x32, 0x6F, 0x1F, 0x24, 0xA7, 0x19,
    0x2A, 0xCE, 0x26, 0x5C, 0x55, 0x85, 0x2B, 0x41, 0xAB, 0x2F, 0xC8, 0x5A, 0xC0, 0x31, 0x3D, 0xAE,
    0x37, 0xA4, 0x69, 0x2E, 0x35, 0x6C, 0xDB, 0x31, 0xCD, 0xCA, 0xA3, 0xCF, 0x95, 0x37, 0xE1, 0x22,
    0x64, 0x63, 0xD3, 0x6C, 0xD4, 0x9C, 0xC8, 0x1F, 0x73, 0xB4, 0xF3, 0xCF, 0x55, 0x32, 0xCC, 0xD0,
    0xD6, 0x27, 0x6D, 0x68, 0x77, 0x86, 0x27, 0x4A, 0xB1, 0x69, 0x6C, 0x16, 0x21, 0xBD, 0xCA, 0xCD,
    0xC5, 0x70, 0xF2, 0x8F, 0x56, 0xD8, 0x65, 0x16, 0x78, 0x5D, 0x67, 0xEA, 0xF3, 0xF8, 0xD6, 0x1D,
    0x0C, 0x9A, 0x9D, 0xD8, 0x11, 0xA5, 0xC5, 0x6B, 0x00, 0x28, 0xB8, 0x2D, 0xAE, 0x02, 0x4F, 0x8A,
    0x8A, 0x2F, 0xBB, 0x03, 0x5A, 0x40, 0x9E, 0x86, 0x11, 0x9F, 0xAC, 0x53, 0x31, 0x12, 0x81, 0xD7,
    0x17, 0xBC, 0x77, 0x14, 0x0C, 0xA4, 0x0A, 0x2D, 0xA0, 0x33, 0x03, 0x5E, 0xE9, 0xF8, 0x33, 0xE5,
    0x92, 0x0D, 0xA5, 0x8A, 0x8D, 0xB7, 0x4B, 0xF1, 0xC4, 0x3F, 0x50, 0xEA, 0x2C, 0xFC, 0x73, 0x62,
    0x0F, 0xF3, 0xC4, 0x6E, 0x60, 0x58, 0xC0, 0x95, 0xEE, 0xE5, 0x70, 0xB9, 0x97, 0x9C, 0xDB, 0xE4,
    0x7C, 0x74, 0xCE, 0x59, 0x8F, 0xEB, 0xBC, 0x8A, 0x00, 0x76, 0x69, 0xAC, 0x55, 0x61, 0xD1, 0xCA,
    0x58, 0x8A, 0xBE, 0x05, 0xB0, 0xD9, 0x57, 0x29, 0xB7, 0x30, 0xE8, 0xAA, 0xF9, 0x5D, 0xF5, 0xB5,
    0xF2, 0x34, 0xE4, 0x41, 0x12, 0xC8, 0xFD, 0x1C, 0xD2, 0xD2, 0x90, 0xBA, 0x86, 0x1C, 0x2C, 0x7F,
    0xC7, 0x9E, 0x7B, 0xC1, 0x45, 0x12, 0xC2, 0x86, 0x49, 0x9D, 0x49, 0x19, 0x6E, 0x3D, 0xA9, 0x24,
    0x90, 0xCD, 0x92, 0x4A, 0x42, 0x68, 0xCF, 0xBB, 0xB8, 0xD6, 0x5D, 0xD8, 0xBA, 0x8B, 0xFD, 0xE5,
    0x2E, 0xB2, 0xEE, 0xE9, 0x80, 0x77, 0x47, 0x41, 0x34, 0x01, 0xE9, 0x97, 0x7F, 0x14, 0x3E, 0x01,
    0x15, 0x3D, 0xC1, 0xCA, 0x00, 0x00, 0x00, 0x3F, 0x00, 0x04, 0x00, 0x00, 0x00, 0x0A, 0x75, 0x67,
    0x17, 0x6D, 0x00, 0x35, 0x00, 0x01, 0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x64, 0x00, 0x18,
    0x74, 0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E, 0x69,
    0x6D, 0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0x01, 0x00, 0x00, 0x06, 0x43, 0x77,
    0x35, 0x94, 0x00,
]

function test_io(obj, expected; kw...)
    a = IOBuffer()
    rnt_write(a, obj; kw...)
    ours = take!(a)
    @test ours == expected
end

@testset "RNTuple Writing - Internal" begin

dummy_FileHeader = [
    0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x06, 0x43, 0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x3F,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x54, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04,
    0x61, 0x00, 0x00, 0x01, 0xA3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]
test_io(UnROOT.Stubs.fileheader, dummy_FileHeader)

dummy_tkey32_tfile = [
    0x00, 0x00, 0x00, 0x90, 0x00, 0x04, 0x00, 0x00, 0x00, 0x56, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x3A,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x05, 0x54, 0x46, 0x69, 0x6C, 0x65,
    0x18, 0x74, 0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E,
    0x69, 0x6D, 0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00,
]
test_io(UnROOT.Stubs.tkey32_tfile, dummy_tkey32_tfile)

dummy_tfile = [
    0x18, 0x74, 0x65, 0x73, 0x74, 0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E,
    0x69, 0x6D, 0x61, 0x6C, 0x2E, 0x72, 0x6F, 0x6F, 0x74, 0x00,
]
test_io(UnROOT.Stubs.tfile, dummy_tfile)

dummy_tdirectory32 = [
    0x00, 0x05, 0x75, 0x67, 0x17, 0x6D, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x00, 0x00, 0x79, 0x00, 0x00,
    0x00, 0x54, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xE8,
]
test_io(UnROOT.Stubs.tdirectory32, dummy_tdirectory32)

dummy_padding2 = [
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]

dummy_RBlob1 = [
    0x00, 0x00, 0x00, 0xDC, 0x00, 0x04, 0x00, 0x00, 0x00, 0xBA, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x22,
    0x00, 0x01, 0x00, 0x00, 0x00, 0xF4, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62,
    0x00, 0x00,
]
test_io(UnROOT.Stubs.RBlob1, dummy_RBlob1)

# ==================================== side tests begin ====================================
    
field_record = UnROOT.FieldRecord(zero(UInt32), zero(UInt32), zero(UInt32), zero(UInt16), zero(UInt16), 0, "one_uint", "std::uint32_t", "", "")
dummy_field_record = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x08, 0x00, 0x00, 0x00, 0x6F, 0x6E, 0x65, 0x5F, 0x75, 0x69, 0x6E, 0x74, 0x0D, 0x00, 0x00, 0x00, 
    0x73, 0x74, 0x64, 0x3A, 0x3A, 0x75, 0x69, 0x6E, 0x74, 0x33, 0x32, 0x5F, 0x74, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 
]
test_io(field_record, dummy_field_record)

column_record = UnROOT.ColumnRecord(0x14, 0x20, zero(UInt32), zero(UInt32), 0)
dummy_column_record = [
    0x14, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
]
test_io(column_record, dummy_column_record)

envelope_frame_field_record = Write_RNTupleListFrame([field_record])
dummy_envelope_frame_field_record = [
    0xB7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x3D, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x6F, 0x6E, 0x65, 0x5F, 0x75, 0x69, 0x6E, 0x74, 
    0x0D, 0x00, 0x00, 0x00, 0x73, 0x74, 0x64, 0x3A, 0x3A, 0x75, 0x69, 0x6E, 0x74, 0x33, 0x32, 0x5F, 
    0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
]
test_io(envelope_frame_field_record, dummy_envelope_frame_field_record)

dummy_rnt_header_payload = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x6D, 0x79, 0x6E, 0x74, 
    0x75, 0x70, 0x6C, 0x65, 0x00, 0x00, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x52, 0x4F, 0x4F, 0x54, 
    0x20, 0x76, 0x36, 0x2E, 0x33, 0x33, 0x2E, 0x30, 0x31, 0xB7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 
    0xFF, 0x01, 0x00, 0x00, 0x00, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 
    0x00, 0x6F, 0x6E, 0x65, 0x5F, 0x75, 0x69, 0x6E, 0x74, 0x0D, 0x00, 0x00, 0x00, 0x73, 0x74, 0x64, 
    0x3A, 0x3A, 0x75, 0x69, 0x6E, 0x74, 0x33, 0x32, 0x5F, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0xE0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x14, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 
]
test_io(UnROOT.Stubs.rnt_header, dummy_rnt_header_payload; envelope=false)

# ==================================== side tests end ====================================

dummy_rnt_header = [
    0x01, 0x00, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, dummy_rnt_header_payload..., 0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D,
]
test_io(UnROOT.Stubs.rnt_header, dummy_rnt_header; envelope=true)

dummy_RBlob2 = [
    0x00, 0x00, 0x00, 0x26, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x22,
    0x00, 0x01, 0x00, 0x00, 0x01, 0xD0, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62,
    0x00, 0x00,
]
test_io(UnROOT.Stubs.RBlob2, dummy_RBlob2)

dummy_RBlob3 = [
    0x00, 0x00, 0x00, 0x9E, 0x00, 0x04, 0x00, 0x00, 0x00, 0x7C, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x22,
    0x00, 0x01, 0x00, 0x00, 0x01, 0xF6, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62,
    0x00, 0x00,
]
test_io(UnROOT.Stubs.RBlob3, dummy_RBlob3)

# ================= side tests begin =================
dummy_cluster_summary = [
    0xDC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 
]
test_io(UnROOT.Stubs.cluster_summary, dummy_cluster_summary)

# > https://github.com/root-project/root/blob/1a854602e42d4493f56a26e35e19bdf23b7d0933/tree/ntuple/v7/doc/specifications.md?plain=1#L672
# > The inner list is followed by a 64bit unsigned integer element offset and the 32bit compression settings
dummy_inner_list_frame = [
    0xD8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 
    0x04, 0x00, 0x00, 0x00, 0xF2, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
]

inner_list_frame = UnROOT.RNTuplePageInnerList([
    PageDescription(0x00000001, UnROOT.Locator(4, 0x00000000000001f2, )),
])
test_io(inner_list_frame, dummy_inner_list_frame)

dummy_pagelink_noenvelope = [
    0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D,
    0xDC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xC0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00,
    0xCC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0xD8, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
    0xF2, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
]
test_io(UnROOT.Stubs.pagelink, dummy_pagelink_noenvelope; envelope=false)
# ================= side tests end =================


dummy_pagelink = [
    0x03, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D,
    0xDC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xC0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00,
    0xCC, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0xD8, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
    0xF2, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x1C, 0xA0, 0xDF, 0x2E, 0x25, 0x1E, 0x55, 0x4C,
]
test_io(UnROOT.Stubs.pagelink, dummy_pagelink)

dummy_RBlob4 = [
    0x00, 0x00, 0x00, 0xCE, 0x00, 0x04, 0x00, 0x00, 0x00, 0xAC, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x22,
    0x00, 0x01, 0x00, 0x00, 0x02, 0x94, 0x00, 0x00, 0x00, 0x64, 0x05, 0x52, 0x42, 0x6C, 0x6F, 0x62,
    0x00, 0x00,
]
test_io(UnROOT.Stubs.RBlob4, dummy_RBlob4)

dummy_rnt_footer = [
    0x02, 0x00, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x28, 0x7E, 0xC6, 0x09, 0xC0, 0x59, 0xEC, 0x3D, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
    0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xC4, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7C, 0x00, 0x00, 0x00,
    0x18, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF4, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x00, 0x00, 0x00, 0x00, 0xA1, 0xD9, 0x13, 0x0B, 0x80, 0xBB, 0xFE, 0x3C,
]
test_io(UnROOT.Stubs.rnt_footer, dummy_rnt_footer)

dummy_tkey32_anchor = [
    0x00, 0x00, 0x00, 0x86, 0x00, 0x04, 0x00, 0x00, 0x00, 0x46, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x40,
    0x00, 0x01, 0x00, 0x00, 0x03, 0x62, 0x00, 0x00, 0x00, 0x64, 0x1B, 0x52, 0x4F, 0x4F, 0x54, 0x3A,
    0x3A, 0x45, 0x78, 0x70, 0x65, 0x72, 0x69, 0x6D, 0x65, 0x6E, 0x74, 0x61, 0x6C, 0x3A, 0x3A, 0x52,
    0x4E, 0x54, 0x75, 0x70, 0x6C, 0x65, 0x08, 0x6D, 0x79, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x00,
]

dummy_rnt_anchor = [
    0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x16,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xBA,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xB6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC, 0xDC, 0x49, 0x5F, 0xD0, 0x14, 0x79, 0xAF, 0x1B,
]
test_io(UnROOT.Stubs.rnt_anchor, dummy_rnt_anchor)

dummy_tkey32_TDirectory = [
    0x00, 0x00, 0x00, 0x79, 0x00, 0x04, 0x00, 0x00, 0x00, 0x44, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x35,
    0x00, 0x01, 0x00, 0x00, 0x03, 0xE8, 0x00, 0x00, 0x00, 0x64, 0x00, 0x18, 0x74, 0x65, 0x73, 0x74,
    0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E, 0x69, 0x6D, 0x61, 0x6C, 0x2E,
    0x72, 0x6F, 0x6F, 0x74, 0x00,
]
test_io(UnROOT.Stubs.tkey32_TDirectory, dummy_tkey32_TDirectory)

dummy_tkey32_TStreamerInfo = [
    0x00, 0x00, 0x01, 0xA3, 0x00, 0x04, 0x00, 0x00, 0x04, 0xF2, 0x75, 0x67, 0x17, 0x6D, 0x00, 0x40,
    0x00, 0x01, 0x00, 0x00, 0x04, 0x61, 0x00, 0x00, 0x00, 0x64, 0x05, 0x54, 0x4C, 0x69, 0x73, 0x74,
    0x0C, 0x53, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x65, 0x72, 0x49, 0x6E, 0x66, 0x6F, 0x12, 0x44, 0x6F,
    0x75, 0x62, 0x6C, 0x79, 0x20, 0x6C, 0x69, 0x6E, 0x6B, 0x65, 0x64, 0x20, 0x6C, 0x69, 0x73, 0x74,
]
test_io(UnROOT.Stubs.tkey32_TStreamerInfo, dummy_tkey32_TStreamerInfo)


MINE = [
    UnROOT.Stubs.file_preamble;
    dummy_FileHeader; UnROOT.Stubs.dummy_padding1;
    dummy_tkey32_tfile; dummy_tfile;
    dummy_tdirectory32; UnROOT.Stubs.dummy_padding2;
    dummy_RBlob1; dummy_rnt_header;
    dummy_RBlob2; UnROOT.Stubs.page1;
    dummy_RBlob3; dummy_pagelink;
    dummy_RBlob4; dummy_rnt_footer;
    dummy_tkey32_anchor; UnROOT.Stubs.magic_6bytes; dummy_rnt_anchor;
    dummy_tkey32_TDirectory; UnROOT.Stubs.n_keys; dummy_tkey32_anchor;
    dummy_tkey32_TStreamerInfo; UnROOT.Stubs.tsreamerinfo_compressed;
    UnROOT.Stubs.tfile_end
]

mytable = Dict("a" => UInt32[0xcececece])
myio = IOBuffer()
UnROOT.write_rntuple(myio, mytable)
@test MINE == REFERENCE_BYTES
mio = take!(myio)
@test MINE == mio

for _ = 1:100
    newtable = Dict("a" => rand(UInt32, rand(1:1000)))
    newio = IOBuffer()
    UnROOT.write_rntuple(newio, newtable)
    nio = take!(newio)

    if isfile("a.root")
        rm("a.root")
    end

    open("a.root", "w") do f
        write(f, nio)
    end

    t = LazyTree("a.root", "myntuple")
    @test only(columntable(t)) == only(columntable(newtable))

end
end
