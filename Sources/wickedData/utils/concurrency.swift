import Foundation

extension DispatchGroup {
    public func enter(_ nWorkers: Int) {
        for i in 0..<nWorkers {
            self.enter()
        }
    }
}

public func BlockingTask(apply closure: @escaping () async -> Void) -> Void {
    let group = DispatchGroup()
    group.enter(1)

    Task {
        await closure()
        group.leave()
    }

    group.wait()
}
