// Cost in practice -- the same check as the Python, in Rust.  No crates.  The
// instruction table runs on u128 with explicit masks, exactly as Python's
// integers do; the plain loop uses u64, whose arithmetic wraps at 64 bits.
// A cost here is a count, never a time: element operations, and interpreter
// steps (instructions the table runner has to read and launch).
const M64: u128 = (1u128 << 64) - 1;
const GAMMA: u64 = 0x9E3779B97F4A7C15;
const C1: u64 = 0xBF58476D1CE4E5B9;
const C2: u64 = 0x94D049BB133111EB;
const SEED: u64 = 2026;
const N: u64 = 1000000;
const LEVEL: u32 = 40;

#[derive(Clone, Copy)]
enum Arg { Reg(usize), K(u128), Nothing }
use Arg::*;
type Ins = (&'static str, usize, usize, Arg);       // (operation, destination, a, b)
const Z: usize = 0;
const T: usize = 1;

fn program(seed: u64, mask: bool, upto: usize) -> Vec<Ins> { // one path's work
    let p: Vec<Ins> = vec![("mul", Z, Z, K(GAMMA as u128)), ("add", Z, Z, K(seed as u128)),
        ("and", Z, Z, K(M64)), ("shr", T, Z, K(30)), ("xor", Z, Z, Reg(T)),
        ("mul", Z, Z, K(C1 as u128)), ("and", Z, Z, K(M64)), ("shr", T, Z, K(27)),
        ("xor", Z, Z, Reg(T)), ("mul", Z, Z, K(C2 as u128)), ("and", Z, Z, K(M64)),
        ("shr", T, Z, K(31)), ("xor", Z, Z, Reg(T)), ("pop", Z, Z, Nothing),
        ("ge", Z, Z, K(LEVEL as u128))];
    p.into_iter().enumerate().filter(|(k, _)| mask || *k != 10)  // 10: the last mask
        .map(|(_, s)| s).take(upto).collect()
}

fn apply(name: &str, x: u128, y: u128) -> u128 {    // one element operation
    match name {
        "mul" => x.wrapping_mul(y), "add" => x + y, "and" => x & y, "shr" => x >> y,
        "xor" => x ^ y, "pop" => x.count_ones() as u128, "ge" => (x >= y) as u128,
        _ => panic!("unknown operation"),
    }
}

fn run_loop(n: u64, prog: &[Ins]) -> (u128, u64, u64) { // for each path: each instruction
    let (mut steps, mut elems, mut total) = (0u64, 0u64, 0u128);
    for i in 1..=n {
        let mut reg = [i as u128, 0];
        for &(name, dst, a, b) in prog {
            let y = match b { Reg(r) => reg[r], K(k) => k, Nothing => 0 };
            reg[dst] = apply(name, reg[a], y);
            steps += 1;
            elems += 1;
        }
        total += reg[Z];
        steps += 1;
        elems += 1;
    }
    (total, steps, elems)
}

// for each instruction: every path in the chunk at once
fn run_arrays(n: u64, prog: &[Ins], chunk: u64) -> (u128, u64, u64, u64, Vec<u128>) {
    let (mut steps, mut elems, mut total, mut peak) = (0u64, 0u64, 0u128, 0u64);
    let mut last = Vec::new();
    let mut lo = 1;
    while lo <= n {
        let hi = (lo + chunk).min(n + 1);
        let mut reg: [Vec<u128>; 2] = [(lo..hi).map(|i| i as u128).collect(), Vec::new()];
        let size = hi - lo;
        peak = peak.max(size);
        for &(name, dst, a, b) in prog {
            let out: Vec<u128> = (0..size as usize).map(|j| {
                let y = match b { Reg(r) => reg[r][j], K(k) => k, Nothing => 0 };
                apply(name, reg[a][j], y)
            }).collect();
            reg[dst] = out;
            steps += 1;                              // one step launches a whole array
            elems += size;
        }
        total += reg[Z].iter().sum::<u128>();
        steps += 1;
        elems += size;
        last = reg[Z].clone();
        lo = hi;
    }
    (total, steps, elems, peak, last)
}

fn plain_loop(n: u64) -> u64 {                       // the loop as a person writes it
    let mut hits = 0;
    for i in 1..=n {
        let mut z = i.wrapping_mul(GAMMA).wrapping_add(SEED);
        z = (z ^ (z >> 30)).wrapping_mul(C1);
        z = (z ^ (z >> 27)).wrapping_mul(C2);
        hits += ((z ^ (z >> 31)).count_ones() >= LEVEL) as u64;
    }
    hits
}

fn main() {
    // Road 1: the exact answer, from a row of Pascal's triangle.
    let mut row: Vec<u128> = vec![1];
    for _ in 0..64 {
        let mut next = vec![1u128; row.len() + 1];
        for k in 1..row.len() { next[k] = row[k - 1] + row[k] }
        row = next;
    }
    let ways: u128 = row[LEVEL as usize..].iter().sum();
    let p = ways as f64 / 2f64.powi(64);
    let nf = N as f64;
    let se = (p * (1.0 - p) / nf).sqrt();
    println!("paths n = {}, seed {}; 64 bets of £1 each; question: share ending >= £16 up (>= {} heads)",
             N, SEED, LEVEL);
    println!("exact: {} of 2^64 coin sequences, p = {:.6}; expected paths {:.1}", ways, p, nf * p);
    let vec5 = run_arrays(5, &program(1234567, true, 13), 5).4;
    println!("SplitMix64 seed 1234567, first output {}", vec5[0]);
    // Road 2: the same program run three ways, each counting its own operations.
    let prog = program(SEED, true, 99);
    let lp = run_loop(N, &prog);
    let arr = run_arrays(N, &prog, N);
    let plain = plain_loop(N);
    println!("per path: {} instructions + 1 add to the total = {} element ops", prog.len(), lp.2 / N);
    println!("loop, path by path:     hits {}, element ops {}, interpreter steps {}", lp.0, lp.2, lp.1);
    println!("arrays, all paths a step: hits {}, element ops {}, interpreter steps {}", arr.0, arr.2, arr.1);
    println!("plain loop, no table: hits {}; per path 16 element ops with masks, \
              13 where numbers wrap at 64 bits (13 x n = {}); in Rust it is compiled, 0 interpreter steps", plain, 13 * N);
    let est = lp.0 as f64 / nf;
    println!("estimate {:.6}; standard error {:.6}; off by {:.2} SE (allowed: under 4)", est, se, (est - p) / se);
    println!("steps saved: loop / arrays = {}", lp.1 / arr.1);
    println!("doubling test, counted:");
    for n in [1000u64, 2000] {
        println!("  n = {}: loop steps {}, array steps {}", n, run_loop(n, &prog).1, run_arrays(n, &prog, n).1);
    }
    println!("chunks of b paths at a time, n = 1000000:");
    let chunks: Vec<(u64, (u128, u64, u64, u64, Vec<u128>))> =
        [100u64, 10000, N].iter().map(|&b| (b, run_arrays(N, &prog, b))).collect();
    for (b, r) in &chunks {
        println!("  b = {}: steps {} (formula 16 n / b = {}), numbers held {}, hits {}",
                 b, r.1, 16 * N / b, r.3, r.0);
    }
    // What breaks.
    let nomask = run_arrays(N, &program(SEED, false, 99), N);
    let mut forced: Vec<Ins> = vec![("add", Z, Z, K(0)), ("mul", Z, Z, K(0)), ("add", Z, Z, K(1))];
    forced.extend(prog.iter().cloned());             // every path's counter forced to 1
    let same = run_arrays(N, &forced, N);
    println!("mistake, last mask dropped (Python ints never wrap): hits {} (steps {}, element ops {})",
             nomask.0, nomask.1, nomask.2);
    println!("mistake, every path given the same counter: hits {}", same.0);
    println!("mistake, quoting the array version's cost as its steps: {} against {} element ops",
             arr.1, arr.2);
    assert!(vec5 == vec![6457827717110365317, 3203168211198807973, 9817491932198370423,
                         4593380528125082431, 16408922859458223821]);
    assert!(lp.0 == arr.0 && lp.0 == plain as u128 && lp.0 == chunks[0].1 .0 && lp.0 == chunks[1].1 .0);
    assert!((est - p).abs() < 4.0 * se);
    assert!(lp.1 == 16 * N && lp.2 == 16 * N && arr.2 == 16 * N && arr.1 == 16);
    assert!(chunks.iter().all(|(b, r)| r.1 == 16 * N / b));
    assert!(nomask.0 as f64 > nf * p + 10.0 * nf * se && (same.0 == 0 || same.0 == N as u128));
    println!("ALL CHECKS PASS");
}
