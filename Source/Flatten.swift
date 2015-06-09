func flatten<A>(sequence: [[A]]) -> [A] {
    return sequence.reduce([], combine: +)
}
