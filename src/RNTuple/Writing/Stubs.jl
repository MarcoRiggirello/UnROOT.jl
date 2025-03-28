module Stubs
using ..UnROOT

const HEADER_CHECKSUM = 0xf6633b32dc5e8345
const WRITE_TIME = 0x76DB5093
const WRITE_TIME_ary = reverse(reinterpret(UInt8, [WRITE_TIME]))

const file_preamble = [
    0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0xF8, 0x0D,
]

const fileheader = UnROOT.FileHeader32(100, 0x00000638, 0x000005F9, 63, 1, 84, 0x04, 0, 0x00000465, 0x0000018D, UInt8[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
const dummy_padding1 = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00,
]

const tkey32_tfile = UnROOT.TKey32(144, 4, 86, WRITE_TIME, 58, 1, 100, 0, "TFile", "test_ntuple_minimal.root", "")
const tfile = UnROOT.TFile_write("test_ntuple_minimal.root", "")
const tdirectory32 = UnROOT.ROOTDirectoryHeader32(5, WRITE_TIME, WRITE_TIME, 0x006B, 84, 100, 0, 0x000003ec)
const dummy_padding2 = [
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]


const RBlob1 = UnROOT.RBlob(; fNbytes = 0x00DC, fVersion = 0x0004, fObjLen = 0x000000BA, fDatime = WRITE_TIME, fKeyLen = 0x0022,
fCycle = 0x0001, fSeekKey = 244, fSeekPdir = 100, fClassName = "RBlob", fName = "", fTitle = "")
const rnt_header = UnROOT.RNTupleHeader(zero(UInt64), "myntuple", "", "ROOT v6.35.001", [
    UnROOT.FieldRecord(zero(UInt32), zero(UInt32), zero(UInt32), zero(UInt16), zero(UInt16), "one_uint", "std::uint32_t", "", "", 0, -1, -1),
], [UnROOT.ColumnRecord(0x08, 0x20, zero(UInt32), 0x00, 0x00, 0),], UnROOT.AliasRecord[], UnROOT.ExtraTypeInfo[])
    

const RBlob2 = UnROOT.RBlob(0x002e, 0x0004, 0x00000004, WRITE_TIME, 0x0022, 0x0001, 0x01D1, 100, "RBlob", "", "")
const page1 = [
    0xCE, 0xCE, 0xCE, 0xCE,
]

const RBlob3 = UnROOT.RBlob(0x009E, 0x0004, 0x0000007C, WRITE_TIME, 0x0022, 0x0001, 0x01FF, 100, "RBlob", "", "")
const cluster_summary = UnROOT.Write_RNTupleListFrame([UnROOT.ClusterSummary(0, 1)])
const nested_page_locations = 
UnROOT.RNTuplePageTopList([
    UnROOT.RNTuplePageOuterList([
        UnROOT.RNTuplePageInnerList([
            UnROOT.PageDescription(0x00000001, UnROOT.Locator(4, 0x00000000000001f2, )),
        ]),
    ]),
])
const pagelink = UnROOT.PageLink(HEADER_CHECKSUM, cluster_summary.payload, nested_page_locations)

const RBlob4 = UnROOT.RBlob(0x00B6, 0x0004, 0x00000094, WRITE_TIME, 0x0022, 0x0001, 0x029D, 100, "RBlob", "", "")
const rnt_footer = UnROOT.RNTupleFooter(0, HEADER_CHECKSUM, UnROOT.RNTupleSchemaExtension([], [], [], []), [
    UnROOT.ClusterGroupRecord(0, 1, 1, UnROOT.EnvLink(0x000000000000007c, UnROOT.Locator(124, 0x0000000000000221, ))),
])
const tkey32_anchor = UnROOT.TKey32(128, 4, 78, WRITE_TIME, 50, 1, 851, 100, "ROOT::RNTuple", "myntuple", "")
# these 6 bytes are between tkey32_anchor and the actual anchor
const magic_6bytes = [0x40, 0x00, 0x00, 0x42, 0x00, 0x02]

const rnt_anchor = UnROOT.ROOT_3a3a_RNTuple(0x0001, 0x0000, 0x0000, 0x0000, 0x0000000000000116, 0x00000000000000ba, 0x00000000000000ba, 0x00000000000002be, 0x00000000000000a0, 0x00000000000000a0, 0x0000000040000000, 0xdc495fd01479af1b)
const tkey32_TDirectory = UnROOT.TKey32(0x006B, 4, 0x0036, WRITE_TIME, 53, 1, 0x000003d3, 100, "", "test_ntuple_minimal.root", "")
# 1 key, and it is the RNTuple Anchor
const n_keys = [
    0x00, 0x00, 0x00, 0x01,
]


const tkey32_TStreamerInfo = UnROOT.TKey32(0x0000018d, 4, 0x000004e6, WRITE_TIME, 64, 1, 0x0000043e, 100, "TList", "StreamerInfo", "Doubly linked list")

const tsreamerinfo_compressed = [
    0x5A, 0x4C, 0x08, 0x44, 0x01, 0x00, 0xE6, 0x04, 0x00, 0x78, 0x01, 0xBD, 0x92, 0xC1, 0x4E, 0xC2, 
    0x40, 0x10, 0x86, 0x7F, 0x6A, 0x4D, 0x54, 0x84, 0xB3, 0xC6, 0x8B, 0x47, 0xCF, 0x1E, 0x39, 0x55, 
    0x12, 0x8D, 0x46, 0xA1, 0x48, 0x1B, 0x8C, 0x1E, 0x34, 0x0B, 0x4C, 0xA1, 0x88, 0xBB, 0x64, 0x5B, 
    0x82, 0xF5, 0xC4, 0xD5, 0x17, 0xF2, 0x1D, 0x4C, 0x7C, 0x0A, 0x0F, 0x9E, 0x7C, 0x07, 0x9D, 0x16, 
    0x82, 0x90, 0x48, 0x44, 0x1B, 0xFC, 0x93, 0x9D, 0xB6, 0xB3, 0xB3, 0xF3, 0xA5, 0xFF, 0xAC, 0x05, 
    0xF3, 0x15, 0xAB, 0xC8, 0x60, 0x4A, 0x19, 0x0B, 0xE6, 0xCB, 0x07, 0xCB, 0x75, 0x42, 0x4D, 0xE2, 
    0x8E, 0xF4, 0x89, 0xF4, 0x14, 0x38, 0xFB, 0x84, 0x75, 0x0B, 0xD8, 0xE1, 0xF2, 0xD1, 0x01, 0x8E, 
    0xB9, 0xAA, 0x6D, 0xBB, 0x85, 0x42, 0xB5, 0xEC, 0xF6, 0x7B, 0x5D, 0xC2, 0xDE, 0xDB, 0xFE, 0x3B, 
    0xB7, 0x32, 0xB8, 0xF8, 0x31, 0x69, 0x61, 0xD7, 0x3B, 0x07, 0x5A, 0x8B, 0x28, 0x3E, 0x3E, 0xC0, 
    0xCA, 0x2C, 0x29, 0xCB, 0xA5, 0xBC, 0x81, 0xFE, 0x0C, 0xAD, 0x28, 0x02, 0xBF, 0xE1, 0x46, 0x3D, 
    0x8A, 0xB7, 0xAE, 0x60, 0x70, 0x74, 0x61, 0x72, 0xFC, 0x02, 0x83, 0xC1, 0x5E, 0x8D, 0x74, 0xE0, 
    0x2B, 0x79, 0xD8, 0x53, 0x8D, 0x36, 0x27, 0xB0, 0xC9, 0xCB, 0x88, 0x5F, 0xE6, 0x29, 0xDF, 0x97, 
    0x81, 0xDF, 0x92, 0xD4, 0xDC, 0x0D, 0xDA, 0x4A, 0x87, 0x16, 0x50, 0x1F, 0x02, 0xCF, 0xFC, 0xFC, 
    0x99, 0x52, 0x12, 0x1D, 0xA5, 0xE3, 0xC6, 0xCB, 0xA5, 0xF8, 0xF2, 0x1F, 0x28, 0x15, 0x11, 0xFE, 
    0xD9, 0xB1, 0x9B, 0xB1, 0x63, 0x17, 0x30, 0x2C, 0xE0, 0x3C, 0x99, 0xCB, 0xF6, 0xE4, 0x42, 0x00, 
    0xC8, 0x7A, 0x0E, 0xD1, 0xED, 0x31, 0x89, 0x26, 0x25, 0x7E, 0xE5, 0x39, 0xB7, 0xC6, 0x6B, 0xAE, 
    0x72, 0x93, 0xA9, 0x74, 0x95, 0x6C, 0x59, 0x80, 0x18, 0x8E, 0x86, 0x72, 0x09, 0x83, 0xBF, 0x9C, 
    0xEF, 0x46, 0x5F, 0x2E, 0x46, 0x21, 0x05, 0x69, 0x20, 0xD7, 0x63, 0x48, 0x2D, 0x81, 0x54, 0x12, 
    0xC8, 0xD6, 0xF4, 0x7F, 0x6C, 0x78, 0x67, 0x24, 0xD3, 0x10, 0x16, 0x74, 0xEA, 0x48, 0xA9, 0x70, 
    0xE9, 0x4E, 0xA5, 0x81, 0x2C, 0xE6, 0x54, 0x1A, 0xC2, 0x02, 0x4E, 0x95, 0xC4, 0xFD, 0x29, 0x45, 
    0x8E, 0xFF, 0x40, 0x60, 0xFD, 0xF2, 0x4E, 0xE1, 0x13, 0xD4, 0x54, 0xBD, 0x04, 
]

const tfile_end = [
    0x00, 0x00, 0x00, 0x3F, 0x00, 0x04, 0x00, 0x00, 0x00, 0x0A, WRITE_TIME_ary..., 0x00, 0x35, 
    0x00, 0x01, 0x00, 0x00, 0x05, 0xCB, 0x00, 0x00, 0x00, 0x64, 0x00, 0x18, 0x74, 0x65, 0x73, 0x74, 
    0x5F, 0x6E, 0x74, 0x75, 0x70, 0x6C, 0x65, 0x5F, 0x6D, 0x69, 0x6E, 0x69, 0x6D, 0x61, 0x6C, 0x2E, 
    0x72, 0x6F, 0x6F, 0x74, 0x00, 0x00, 0x01, 0x00, 0x00, 0x06, 0x0A, 0x77, 0x35, 0x94, 0x00, 
]
end
