//
//  OpenCoreAMRCodec.swift
//  OpenCoreAMR
//
//  Created by tdt on 2026/5/26.
//

import Foundation
import OpenCoreAMRNB
import OpenCoreAMRWB

public enum OpenCoreAMRFormat: String, Equatable, Sendable {
    case narrowband
    case wideband

    var header: [UInt8] {
        switch self {
        case .narrowband:
            Array("#!AMR\n".utf8)
        case .wideband:
            Array("#!AMR-WB\n".utf8)
        }
    }

    var sampleRate: Int {
        switch self {
        case .narrowband:
            8_000
        case .wideband:
            16_000
        }
    }

    var samplesPerFrame: Int {
        switch self {
        case .narrowband:
            160
        case .wideband:
            320
        }
    }

    var framePayloadSizes: [Int] {
        switch self {
        case .narrowband:
            [12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0]
        case .wideband:
            [17, 23, 32, 36, 40, 46, 50, 58, 60, 5, -1, -1, -1, -1, -1, 0]
        }
    }
}

public enum OpenCoreAMRCodecError: Error, LocalizedError, Sendable {
    case unsupportedFormat
    case decoderInitializationFailed(OpenCoreAMRFormat)
    case invalidFrame(format: OpenCoreAMRFormat, offset: Int)
    case truncatedFrame(format: OpenCoreAMRFormat, offset: Int)
    case emptyAudio(OpenCoreAMRFormat)
    case audioTooLarge

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Unsupported AMR audio format."
        case .decoderInitializationFailed(let format):
            "AMR decoder initialization failed: \(format.rawValue)."
        case .invalidFrame(let format, let offset):
            "Invalid AMR frame: \(format.rawValue), offset \(offset)."
        case .truncatedFrame(let format, let offset):
            "Truncated AMR frame: \(format.rawValue), offset \(offset)."
        case .emptyAudio(let format):
            "Empty AMR audio: \(format.rawValue)."
        case .audioTooLarge:
            "Decoded AMR audio is too large."
        }
    }
}

public enum OpenCoreAMRCodec {

    public static func format(of data: Data) -> OpenCoreAMRFormat? {
        if data.hasPrefix(OpenCoreAMRFormat.wideband.header) {
            return .wideband
        }
        if data.hasPrefix(OpenCoreAMRFormat.narrowband.header) {
            return .narrowband
        }
        return nil
    }

    public static func isAMR(_ data: Data) -> Bool {
        format(of: data) != nil
    }

    public static func decodeToWAVData(_ data: Data) throws -> Data {
        guard let format = format(of: data) else {
            throw OpenCoreAMRCodecError.unsupportedFormat
        }

        let pcmData = try decodeToPCMData(data, format: format)
        return try WAVContainer.makeData(
            pcmData: pcmData,
            sampleRate: format.sampleRate,
            bitsPerSample: 16,
            channels: 1
        )
    }

    @discardableResult
    public static func decodeToWAVFile(_ data: Data, destinationURL: URL) throws -> URL {
        let wavData = try decodeToWAVData(data)
        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try wavData.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
}

private extension OpenCoreAMRCodec {

    static func decodeToPCMData(_ data: Data, format: OpenCoreAMRFormat) throws -> Data {
        switch format {
        case .narrowband:
            try decodeNarrowband(data, format: format)
        case .wideband:
            try decodeWideband(data, format: format)
        }
    }

    static func decodeNarrowband(_ data: Data, format: OpenCoreAMRFormat) throws -> Data {
        guard let decoder = Decoder_Interface_init() else {
            throw OpenCoreAMRCodecError.decoderInitializationFailed(format)
        }
        defer { Decoder_Interface_exit(decoder) }

        return try decodeFrames(data, format: format) { frame, output in
            frame.withUnsafeBufferPointer { framePointer in
                output.withUnsafeMutableBufferPointer { outputPointer in
                    Decoder_Interface_Decode(decoder, framePointer.baseAddress, outputPointer.baseAddress, 0)
                }
            }
        }
    }

    static func decodeWideband(_ data: Data, format: OpenCoreAMRFormat) throws -> Data {
        guard let decoder = D_IF_init() else {
            throw OpenCoreAMRCodecError.decoderInitializationFailed(format)
        }
        defer { D_IF_exit(decoder) }

        return try decodeFrames(data, format: format) { frame, output in
            frame.withUnsafeBufferPointer { framePointer in
                output.withUnsafeMutableBufferPointer { outputPointer in
                    D_IF_decode(decoder, framePointer.baseAddress, outputPointer.baseAddress, 0)
                }
            }
        }
    }

    static func decodeFrames(
        _ data: Data,
        format: OpenCoreAMRFormat,
        decode: (_ frame: [UInt8], _ output: inout [Int16]) -> Void
    ) throws -> Data {
        let bytes = [UInt8](data)
        var offset = format.header.count
        var pcmData = Data()
        pcmData.reserveCapacity(max(0, bytes.count - offset) * 16)

        while offset < bytes.count {
            let frameOffset = offset
            let modeByte = bytes[offset]
            offset += 1

            let frameType = Int((modeByte >> 3) & 0x0f)
            let payloadSize = format.framePayloadSizes[frameType]
            guard payloadSize >= 0 else {
                throw OpenCoreAMRCodecError.invalidFrame(format: format, offset: frameOffset)
            }
            guard offset + payloadSize <= bytes.count else {
                throw OpenCoreAMRCodecError.truncatedFrame(format: format, offset: frameOffset)
            }

            var frame = [UInt8](repeating: 0, count: payloadSize + 1)
            frame[0] = modeByte
            if payloadSize > 0 {
                frame.replaceSubrange(1 ..< 1 + payloadSize, with: bytes[offset ..< offset + payloadSize])
            }
            offset += payloadSize

            var output = [Int16](repeating: 0, count: format.samplesPerFrame)
            decode(frame, &output)
            pcmData.appendLittleEndian(samples: output)
        }

        guard pcmData.isEmpty == false else {
            throw OpenCoreAMRCodecError.emptyAudio(format)
        }
        return pcmData
    }
}

private enum WAVContainer {
    static func makeData(
        pcmData: Data,
        sampleRate: Int,
        bitsPerSample: Int,
        channels: Int
    ) throws -> Data {
        guard pcmData.count <= Int(UInt32.max) - 36 else {
            throw OpenCoreAMRCodecError.audioTooLarge
        }

        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8

        var wavData = Data()
        wavData.reserveCapacity(44 + pcmData.count)
        wavData.appendASCII("RIFF")
        wavData.appendLittleEndian(UInt32(36 + pcmData.count))
        wavData.appendASCII("WAVE")
        wavData.appendASCII("fmt ")
        wavData.appendLittleEndian(UInt32(16))
        wavData.appendLittleEndian(UInt16(1))
        wavData.appendLittleEndian(UInt16(channels))
        wavData.appendLittleEndian(UInt32(sampleRate))
        wavData.appendLittleEndian(UInt32(byteRate))
        wavData.appendLittleEndian(UInt16(blockAlign))
        wavData.appendLittleEndian(UInt16(bitsPerSample))
        wavData.appendASCII("data")
        wavData.appendLittleEndian(UInt32(pcmData.count))
        wavData.append(pcmData)
        return wavData
    }
}

private extension Data {
    func hasPrefix(_ bytes: [UInt8]) -> Bool {
        count >= bytes.count && prefix(bytes.count).elementsEqual(bytes)
    }

    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) {
            append(contentsOf: $0)
        }
    }

    mutating func appendLittleEndian(samples: [Int16]) {
        samples.forEach { sample in
            appendLittleEndian(sample)
        }
    }
}
