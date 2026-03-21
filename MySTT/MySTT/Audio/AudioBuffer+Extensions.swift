import AVFoundation

extension AVAudioPCMBuffer {
    /// Convert buffer to Float array (for Whisper)
    var floatArray: [Float] {
        guard let channelData = floatChannelData else { return [] }
        let channelPointer = channelData[0]
        return Array(UnsafeBufferPointer(start: channelPointer, count: Int(frameLength)))
    }

    /// Convert to WAV Data with proper header
    func toWAVData() -> Data {
        let numChannels: UInt16 = UInt16(format.channelCount)
        let sampleRate: UInt32 = UInt32(format.sampleRate)
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = bitsPerSample / 8
        let blockAlign = numChannels * bytesPerSample
        let byteRate = sampleRate * UInt32(blockAlign)

        // Convert float samples to Int16
        let floats = floatArray
        var int16Samples = [Int16](repeating: 0, count: floats.count)
        for i in 0..<floats.count {
            let clamped = max(-1.0, min(1.0, floats[i]))
            int16Samples[i] = Int16(clamped * Float(Int16.max))
        }

        let dataSize = UInt32(int16Samples.count * Int(bytesPerSample))
        let fileSize = 36 + dataSize

        var data = Data()
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        int16Samples.withUnsafeBufferPointer { ptr in
            data.append(UnsafeBufferPointer(start: UnsafeRawPointer(ptr.baseAddress!).assumingMemoryBound(to: UInt8.self), count: Int(dataSize)))
        }
        return data
    }
}
