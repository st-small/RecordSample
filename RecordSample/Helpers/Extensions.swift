import Foundation

extension Int {
    func toMinutesAndSeconds() -> String {
        let minutes = Int(self / 60).normalizeZero()
        let seconds = (self % 60).normalizeZero()
        
        return "\(minutes):\(seconds)"
    }
    
    func normalizeZero() -> String {
        self > 9 ? "\(self)" : "0\(self)"
    }
}
