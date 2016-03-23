#!/usr/bin/env julia

using BaseTestNext
using PortAudio
using SampleTypes

# these test are currently set up to run on OSX

@testset "PortAudio Tests" begin
    # @testset "Reports version" begin
    #     io = IOBuffer()
    #     PortAudio.versioninfo(io)
    #     result = takebuf_string(io)
    #     # make sure this is the same version I tested with
    #     @test result ==
    #         """PortAudio V19-devel (built Aug  6 2014 17:54:39)
    #         Version Number: 1899
    #         """
    # end
    @testset "PortAudio Callback works and doesn't allocate" begin
        inbuf = rand(Float32, 2, 8)
        outbuf = Array(Float32, 2, 8)
        sinkbuf = rand(Float32, 2, 8)
        sourcebuf = Array(Float32, 2, 8)
        state = Ref(PortAudio.PortAudioPending)
        work = Base.SingleAsyncWork(data -> nothing)

        info = PortAudio.CallbackInfo(2, pointer(sourcebuf),
                                      2, pointer(sinkbuf),
                                      work.handle,
                                      Ptr{PortAudio.BufferState}(pointer_from_objref(state)))

        # handle any conversions here so they don't mess with the allocation
        inptr = pointer(inbuf)
        outptr = pointer(outbuf)
        nframes = Culong(8)
        flags = Culong(0)
        infoptr = Ptr{PortAudio.CallbackInfo{Float32}}(pointer_from_objref(info))

        ret = PortAudio.portaudio_callback(inptr, outptr, nframes, C_NULL, flags, infoptr)
        @test isa(ret, Cint)
        @test ret == PortAudio.paContinue
        @test outbuf == sinkbuf
        @test inbuf == sourcebuf
        @test state[] == PortAudio.JuliaPending

        # call again (underrun)
        ret = PortAudio.portaudio_callback(inptr, outptr, nframes, C_NULL, flags, infoptr)
        @test isa(ret, Cint)
        @test ret == PortAudio.paContinue
        @test outbuf == zeros(Float32, 2, 8)

        # test allocation
        state[] = PortAudio.PortAudioPending
        alloc = @allocated PortAudio.portaudio_callback(inptr, outptr, nframes, C_NULL, flags, infoptr)
        @test alloc == 0
        # now test allocation in underrun state
        alloc = @allocated PortAudio.portaudio_callback(inptr, outptr, nframes, C_NULL, flags, infoptr)
        @test alloc == 0
    end

    # @testset "Open Default Device" begin
    #     devs = PortAudio.devices()
    #     source = PortAudioSource()
    #     sink = PortAudioSink()
    #     buf = read(source, 0.1s)
    #     @test size(buf) == (round(Int, 0.1s * samplerate(source)), nchannels(source))
    #     write(sink, buf)
    #     close(source)
    #     close(sink)
    # end
    # @testset "Open Device by name" begin
    #     devs = PortAudio.devices()
    #     source = PortAudioSource("Built-in Microph")
    #     sink = PortAudioSink("Built-in Output")
    #     buf = read(source, 0.1s)
    #     @test size(buf) == (round(Int, 0.1s * samplerate(source)), nchannels(source))
    #     write(sink, buf)
    #     io = IOBuffer()
    #     show(io, source)
    #     @test takebuf_string(io) ==
    #         """PortAudio.PortAudioSource{Float32,SIUnits.SIQuantity{Int64,0,0,-1,0,0,0,0,0,0}}("Built-in Microph")
    #            2 channels sampled at 48000 s⁻¹"""
    #     show(io, sink)
    #     @test takebuf_string(io) ==
    #         """PortAudio.PortAudioSink{Float32,SIUnits.SIQuantity{Int64,0,0,-1,0,0,0,0,0,0}}("Built-in Output")
    #         2 channels sampled at 48000 s⁻¹"""
    #     close(source)
    #     close(sink)
    # end
    # @testset "Error on wrong name" begin
    #     @test_throws ErrorException PortAudioSource("foobarbaz")
    #     @test_throws ErrorException PortAudioSink("foobarbaz")
    # end
    # # no way to check that the right data is actually getting read or written here,
    # # but at least it's not crashing.
    # @testset "Queued Writing" begin
    #     sink = PortAudioSink()
    #     buf = SampleBuf(rand(eltype(sink), 48000, nchannels(sink))*0.1, samplerate(sink))
    #     t1 = @async write(sink, buf)
    #     t2 = @async write(sink, buf)
    #     @test wait(t1) == 48000
    #     @test wait(t2) == 48000
    #     close(sink)
    # end
    # @testset "Queued Reading" begin
    #     source = PortAudioSource()
    #     buf = SampleBuf(rand(eltype(source), 48000, nchannels(source)), samplerate(source))
    #     t1 = @async read!(source, buf)
    #     t2 = @async read!(source, buf)
    #     @test wait(t1) == 48000
    #     @test wait(t2) == 48000
    #     close(source)
    # end
end
