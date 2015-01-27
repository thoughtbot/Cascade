func flatten<A>(sequence: [[A]]) -> [A] {
    return reduce(sequence, [], +)
}
