public extension Double {
    static func random<GeneratorType: RandomNumberGenerator>(in interval: Range<Double>, using generator: inout GeneratorType, n: Int) -> [Double] {
        return (0..<n).map{ _ in
            Double.random(in: interval, using: &generator)
        }
    }
}

