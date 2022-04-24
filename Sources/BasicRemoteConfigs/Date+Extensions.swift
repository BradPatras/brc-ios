import Foundation

extension Date {
	func isBefore(date: Date) -> Bool {
		return self.timeIntervalSinceReferenceDate < date.timeIntervalSinceReferenceDate
	}

	func adding(hours: Int) -> Date {
		guard let newDate = Calendar.current.date(byAdding: .hour, value: hours, to: self) else {
			let hoursToAddTimeInterval = TimeInterval(hours * 3600)
			return Date(timeInterval: hoursToAddTimeInterval, since: self)
		}
		
		return newDate
	}
}
