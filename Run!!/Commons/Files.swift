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
        // encoder.keyEncodingStrategy = .convertToSnakeCase -> Does not work with enums and parameters
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
        // decoder.keyDecodingStrategy = .convertFromSnakeCase -> Does not work with enums and parameters
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "+inf",
            negativeInfinity: "-inf",
            nan: "nan")
        return decoder
    }
    
    static func initDirectory() {
        func getUrl() throws -> URL? {
            if FileManager.default.ubiquityIdentityToken != nil {
                return FileManager
                    .default
                    .url(forUbiquityContainerIdentifier: nil)?
                    .appendingPathComponent("Run", isDirectory: true)
            } else {
                return FileManager
                    .default
                    .urls(for: .documentDirectory, in: .userDomainMask)
                    .first?
                    .appendingPathComponent("Run", isDirectory: true)
            }
        }
        
        do {
            if let url = try getUrl() {
                try FileManager
                    .default
                    .createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                directory = url
            }
        } catch {
            check(error)
            directory = nil
        }
        log(directory?.absoluteString ?? "not set!")
    }

    private static var directory: URL?

    private static func url(for fileName: String) -> URL? {
        // Check if initDirectory did finish
        guard let directory = directory else {
            check("iCloud directory not set up. File \(fileName) not saved")
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    static func write<E: Encodable>(_ encodable: E, to: String) {
        guard let url = url(for: to) else {return}
        
        do {
            let data = try encoder.encode(encodable)
            try data.write(to: url, options: .atomic)
        } catch {
            log(to)
            check(error)
        }
    }
    
    static func read<D: Decodable>(from: String) -> D? {
        guard let url = url(for: from) else {return nil}
        
        do {
            return try decoder.decode(D.self, from: try Data(contentsOf: url))
        } catch {
            log(from)
            check(error)
            return nil
        }
    }
    
    static func append(_ msg: String, to: String) {
        guard let url = url(for: to) else {return}
        guard let msg = msg.data(using: .utf8) else {return}
        
        guard let file = try? FileHandle(forWritingTo: url) else {
            // First time write
            do {
                try msg.write(to: url, options: .atomic)
            } catch {
                log(to)
                check(error)
            }
            return
        }
        defer {try? file.close()}

        // Seek to end and append
        do {
            try file.seekToEnd()
            file.write(msg)
        } catch {
            log(to)
            check(error)
        }
    }
}
