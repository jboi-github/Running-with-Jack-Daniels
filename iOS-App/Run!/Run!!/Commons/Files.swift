//
//  Files.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation

enum Files {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "+inf",
            negativeInfinity: "-inf",
            nan: "nan")
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "+inf",
            negativeInfinity: "-inf",
            nan: "nan")
        return decoder
    }
    
    static func initDirectory() {
        func getUrl() throws -> URL? {
            return FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask).first
//  TODO:           if FileManager.default.ubiquityIdentityToken != nil {
//                return FileManager
//                    .default
//                    .url(forUbiquityContainerIdentifier: nil)?
//                    .appendingPathComponent("Run", isDirectory: true)
//            } else {
//                return try FileManager
//                    .default
//                    .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//            }
        }
        
        queue.async {
            do {
                if let url = try getUrl() {
                    log(url)
                    try FileManager
                        .default
                        .createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    directory = url
                }
            } catch {
                check(error)
                directory = nil
            }
        }
    }

    private static var directory: URL? = nil
    private static let queue = DispatchQueue(label: "run-files", qos: .utility)

    private static func url(for fileName: String) -> URL? {
        guard let directory = directory else {
            check("iCloud directory not set up. File \(fileName) not saved")
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    @discardableResult static func write<E: Encodable>(_ encodable: E, to: String) -> URL? {
        queue.sync {
            guard let url = url(for: to) else {return nil}
            
            do {
                let data = try encoder.encode(encodable) // TODO: (encoder.encode(encodable) as NSData).compressed(using: .zlib)
                try data.write(to: url, options: .atomic)
                return url
            } catch {
                check(error)
                return nil
            }
        }
    }
    
    static func read<D: Decodable>(_ decodable: D.Type, from fileName: String) -> D? {
        queue.sync {
            guard let url = url(for: fileName) else {return nil}
            
            do {
                let data = try Data(contentsOf: url) // TODO: (Data(contentsOf: url) as NSData).decompressed(using: .zlib)
                return try decoder.decode(decodable, from: data)
            } catch {
                check(error)
                return nil
            }
        }
    }
    
    @discardableResult static func append(_ msg: String, to: String) -> URL? {
        guard let url = url(for: to) else {return nil}
        guard let msg = msg.data(using: .utf8) else {return nil}
        
        guard let file = try? FileHandle(forWritingTo: url) else {
            do {
                try msg.write(to: url, options: .atomic)
                return url
            } catch {
                check(error)
                return nil
            }
        }
        defer {try? file.close()}
        
        do {
            try file.seekToEnd()
            file.write(msg)
            return url
        } catch {
            check(error)
            return nil
        }
    }
}
