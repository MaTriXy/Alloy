//
//  EuclideanDistanceTests.swift
//  Demo
//
//  Created by Eugene Bokhan on 04/09/2019.
//  Copyright © 2019 avolodin. All rights reserved.
//

import XCTest
import Alloy
import MetalKit

final class EuclideanDistanceTests: XCTestCase {

    // MARK: - Errors

    enum Error: Swift.Error {
        case cgImageCreationFailed
    }

    // MARK: - Properties

    public var context: MTLContext!
    public var euclideanDistanceFloat: EuclideanDistance!
    public var textureAddConstantFloat: TextureAddConstant!

    // MARK: - Setup

    override func setUp() {
        do {
            self.context = try .init()
            self.euclideanDistanceFloat = try .init(context: self.context,
                                                    scalarType: .float)
            self.textureAddConstantFloat = try .init(context: self.context,
                                                     scalarType: .float)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Testing

    func testEuclideanDistance() {
        do {
            let resultBuffer = try self.context
                                       .buffer(for: Float.self,
                                               options: .storageModeShared)

            guard let cgImage = UIImage(named: "255")?.cgImage
            else { throw Error.cgImageCreationFailed }
            
            let originalTexture = try self.context
                                          .texture(from: cgImage,
                                                   usage: [.shaderRead, .shaderWrite])
            let modifiedTexture = try originalTexture.matchingTexture()

            let constant = Float(-0.1)
            let originalTextureArea = Float(originalTexture.width * originalTexture.height)
            let euclideanDistance = originalTextureArea * sqrt(4 * (pow(constant, 2)))

            try self.context
                    .scheduleAndWait { commandBuffer in
                self.textureAddConstantFloat
                    .encode(sourceTexture: originalTexture,
                            destinationTexture: modifiedTexture,
                            constant: .init(repeating: -0.1),
                            in: commandBuffer)

                self.euclideanDistanceFloat
                    .encode(textureOne: originalTexture,
                            textureTwo: modifiedTexture,
                            resultBuffer: resultBuffer,
                            in: commandBuffer)
            }

            let result = resultBuffer.pointer(of: Float.self)!.pointee
            let diff = abs(result - euclideanDistance)

            XCTAssert(diff < 40)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
