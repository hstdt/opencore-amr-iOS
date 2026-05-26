//
//  OpenCoreAMRCodecTests.swift
//  OpenCoreAMR
//
//  Created by tdt on 2026/5/26.
//

import XCTest
@testable import OpenCoreAMRCodec

final class OpenCoreAMRCodecTests: XCTestCase {
    func testDetectsNarrowbandHeader() {
        let data = Data("#!AMR\n".utf8)
        XCTAssertEqual(OpenCoreAMRCodec.format(of: data), .narrowband)
    }

    func testDetectsWidebandHeader() {
        let data = Data("#!AMR-WB\n".utf8)
        XCTAssertEqual(OpenCoreAMRCodec.format(of: data), .wideband)
    }

    func testRejectsUnsupportedData() {
        XCTAssertFalse(OpenCoreAMRCodec.isAMR(Data("not-amr".utf8)))
        XCTAssertThrowsError(try OpenCoreAMRCodec.decodeToWAVData(Data("not-amr".utf8)))
    }

    func testEmptyAMRThrows() {
        XCTAssertThrowsError(try OpenCoreAMRCodec.decodeToWAVData(Data("#!AMR\n".utf8))) { error in
            guard let error = error as? OpenCoreAMRCodecError,
                  case .emptyAudio(.narrowband) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
