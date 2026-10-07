// Direct products -- the same check as the Python, in Rust.  No crates.  A
// padlock with one 3-position dial and one 5-position dial: its group is the
// ordered pairs, each dial wrapping on its own.  Two roads: pairs are built and
// walked, and every return time is re-derived from a least common multiple.
const M: i32 = 3;
const N: i32 = 5;
fn gcd(mut a: i32, mut b: i32) -> i32 {      // Euclid, used only by the formula road
    while b != 0 { let t = a % b; a = b; b = t; }
    a
}
fn lcm(a: i32, b: i32) -> i32 { a * b / gcd(a, b) }
fn dial(a: i32, m: i32) -> i32 { m / gcd(a, m) }      // one dial's own return time
fn add(p: (i32, i32), q: (i32, i32), m: i32, n: i32) -> (i32, i32) {   // componentwise
    ((p.0 + q.0) % m, (p.1 + q.1) % n)
}
fn order(p: (i32, i32), m: i32, n: i32) -> i32 {      // road one: repeat until home
    let (mut x, mut k) = (p, 1);
    while x != (0, 0) { x = add(x, p, m, n); k += 1; }
    k
}
fn walk(p: (i32, i32), m: i32, n: i32) -> Vec<(i32, i32)> {    // settings reached
    let (mut out, mut x) = (Vec::new(), (0, 0));
    while !out.contains(&x) { out.push(x); x = add(x, p, m, n); }
    out
}
fn restore(a: i32, b: i32) -> i32 { (10 * a + 6 * b) % (M * N) }   // pair to reading
fn show(ps: &[(i32, i32)]) -> String {
    ps.iter().map(|p| format!("({},{})", p.0, p.1)).collect::<Vec<_>>().join(" ")
}
fn nums(vs: &[i32]) -> String {
    vs.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" ")
}
fn main() {
    let pairs: Vec<(i32, i32)> = (0..M).flat_map(|a| (0..N).map(move |b| (a, b))).collect();
    let reads: Vec<(i32, i32)> = (0..M * N).map(|k| (k % M, k % N)).collect();
    let cycle = walk((1, 1), M, N);
    let walked: Vec<i32> = reads.iter().map(|&p| order(p, M, N)).collect();
    let formula: Vec<i32> = reads.iter().map(|&(a, b)| lcm(dial(a, M), dial(b, N))).collect();
    let sums = pairs.iter().all(|&p| pairs.iter().all(|&q| {
        let s = add(p, q, M, N);
        restore(s.0, s.1) == (restore(p.0, p.1) + restore(q.0, q.1)) % (M * N)
    }));
    let sw: Vec<(i32, i32)> = (0..2).flat_map(|a| (0..2).map(move |b| (a, b))).collect();
    let sw_ord: Vec<i32> = sw.iter().map(|&p| order(p, 2, 2)).collect();
    let d4: Vec<i32> = (0..4).map(|a| order((a, 0), 4, 1)).collect();
    let big: Vec<i32> = (0..6).flat_map(|a| (0..4).map(move |b| order((a, b), 6, 4))).collect();
    println!("padlock: {} positions x {} positions = {} settings; pairs {}",
             M, N, M * N, pairs.len());
    println!("joint cycle from (1,1): {}", show(&cycle));
    println!("the grid, rows the {}-dial, columns the {}-dial, entries the reading:", M, N);
    for a in 0..M {
        let mut line = format!("  row {}", a);
        for b in 0..N { line.push_str(&format!("{:>5}", restore(a, b))); }
        println!("{}", line);
    }
    println!("order of (1,1): walked {}, lcm({},{}) = {}; settings reached {}",
             order((1, 1), M, N), M, N, lcm(M, N), cycle.len());
    println!("orders by reading 0 to {}: {}", M * N - 1, nums(&walked));
    println!("reading 14 is the pair ({},{}); the reverse (10 x {} + 6 x {}) mod {} gives {}",
             14 % M, 14 % N, 14 % M, 14 % N, M * N, restore(14 % M, 14 % N));
    println!("all {} pair sums match the {}-clock: {}", pairs.len() * pairs.len(), M * N, sums);
    println!("two switches {}: orders {}, largest {}",
             show(&sw), nums(&sw_ord), sw_ord.iter().max().unwrap());
    println!("one 4-dial, readings 0 1 2 3: orders {}, largest {}",
             nums(&d4), d4.iter().max().unwrap());
    println!("6 positions x 4 positions: {} settings, largest order {}, lcm(6,4) = {}, gcd(6,4) = {}",
             6 * 4, big.iter().max().unwrap(), lcm(6, 4), gcd(6, 4));
    println!("mistakes: adding the dials gives {} settings, not {}; multiplying the switch return times gives 4, not {}",
             M + N, M * N, order((1, 1), 2, 2));
    println!("the switches' joint step reaches only {}; gcd(2,2) = {} while gcd({},{}) = {}",
             show(&walk((1, 1), 2, 2)), gcd(2, 2), M, N, gcd(M, N));
    assert!(walked == formula && walked[1] == M * N && cycle.len() as i32 == M * N);
    assert!(walked == (0..M * N).map(|k| M * N / gcd(k, M * N)).collect::<Vec<i32>>());
    let mut sorted = reads.clone();
    sorted.sort();
    assert!(sums && sorted == pairs && (0..M * N).all(|k| restore(k % M, k % N) == k));
    assert!(sw_ord == vec![1, 2, 2, 2] && d4 == vec![1, 4, 2, 4]
            && *big.iter().max().unwrap() == lcm(6, 4));
    println!("ALL CHECKS PASS");
}
