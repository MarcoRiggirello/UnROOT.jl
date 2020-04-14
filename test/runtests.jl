using ROOTIO
using StaticArrays
using Test


@testset "io" begin
    ROOTIO.@io struct Foo
        a::Int32
        b::Int64
        c::Float32
        d::SVector{5, UInt8}
    end

    d = SA{UInt8}[1, 2, 3, 4, 5]

    foo = Foo(1, 2, 3, d)

    @test foo.a == 1
    @test foo.b == 2
    @test foo.c ≈ 3
    @test d == foo.d

    @test 21 == sizeof(Foo)

    buf = IOBuffer(Vector{UInt8}(1:sizeof(Foo)))
    foo = ROOTIO.unpack(buf, Foo)

    @test foo.a == 16909060
    @test foo.b == 361984551142689548
    @test foo.c ≈ 4.377526f-31
    @test foo.d == UInt8[0x11, 0x12, 0x13, 0x14, 0x15]
end


@testset "Header and Preamble" begin
    fobj = open(joinpath("test", "samples", "raw.root"))
    file_preamble = ROOTIO.unpack(fobj, ROOTIO.FilePreamble)
    @test "root" == String(file_preamble.identifier)

    file_header = ROOTIO.unpack(fobj, ROOTIO.FileHeader32)
    @test 100 == file_header.fBEGIN
end


@testset "Opening files" begin
    rootfile = ROOTIO.open(joinpath("test", "samples", "raw.root"))
    @test 100 == rootfile.header.fBEGIN
end
