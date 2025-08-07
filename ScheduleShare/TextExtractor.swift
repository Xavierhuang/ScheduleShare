//
//  TextExtractor.swift
//  ScheduleShare
//
//  AI-powered OCR and event information extraction
//

import SwiftUI
import Vision
import VisionKit

class TextExtractor: ObservableObject {
    private let aiExtractor = AITextExtractor()
    
    // MARK: - OCR Text Recognition
    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(TextExtractionError.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(TextExtractionError.noTextFound))
                return
            }
            
            print("📝 TextExtractor: Found \(observations.count) text observations")
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            if recognizedText.isEmpty {
                print("❌ TextExtractor: No confident text found")
                completion(.failure(TextExtractionError.noTextFound))
                return
            }
            
            print("✅ TextExtractor: Successfully extracted \(recognizedText.count) characters")
            completion(.success(recognizedText))
        }
        
        // Enhanced OCR settings for better recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - AI Event Parsing
    func parseEventInfo(from text: String, completion: @escaping (ExtractedEventInfo) -> Void) {
        print("🤖 Using AI-ONLY event extraction...")
        
        aiExtractor.extractEventInfo(from: text) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let aiInfo):
                    print("✅ AI extraction successful with confidence: \(aiInfo.confidence)")
                    completion(aiInfo)
                    
                case .failure(let error):
                    print("❌ AI extraction failed: \(error.localizedDescription)")
                    
                    // For AI-only extraction, we don't provide fallback - let user try again
                    let errorInfo = ExtractedEventInfo(
                        rawText: text,
                        title: "AI Extraction Failed",
                        startDateTime: Date(),
                        endDateTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
                        location: nil,
                        description: "Please check your API key and try again. Error: \(error.localizedDescription)",
                        confidence: 0.0
                    )
                    completion(errorInfo)
                }
            }
        }
    }
}

// MARK: - Error Types
enum TextExtractionError: Error, LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        }
    }
} 