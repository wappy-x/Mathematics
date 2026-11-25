// P/poly -- the same check as the Python, in Rust.  No crates.  Four constructions: a circuit
// family (one adder per input length), a unary set given by one advice bit per length, Adleman's
// step on a real coin-flipping test (one coin string right on every input), and the
// self-reduction inside Karp-Lipton.  Nothing here decides halting; capped runs say so.
use std::collections::HashSet;

// ripple-carry adder, as built on the Boolean circuits card; op 0 NOT, 1 AND, 2 OR
fn adder(k: usize) -> (Vec<(u8, usize, usize)>, Vec<usize>) {
    let mut gates: Vec<(u8, usize, usize)> = Vec::new();
    fn g(gates: &mut Vec<(u8, usize, usize)>, k: usize, op: u8, x: usize, y: usize) -> usize {
        gates.push((op, x, y)); 2 * k + gates.len() - 1 }
    fn xor(gates: &mut Vec<(u8, usize, usize)>, k: usize, x: usize, y: usize) -> (usize, usize) {
        let both = g(gates, k, 1, x, y); let o = g(gates, k, 2, x, y); let nb = g(gates, k, 0, both, 0);
        (g(gates, k, 1, o, nb), both) }
    let (s, mut c) = xor(&mut gates, k, 0, k);
    let mut out = vec![s];
    for i in 1..k {
        let (t, h) = xor(&mut gates, k, i, k + i); let (s, u) = xor(&mut gates, k, t, c);
        out.push(s); c = g(&mut gates, k, 2, h, u);
    }
    out.push(c); (gates, out)
}
fn run(gates: &[(u8, usize, usize)], outs: &[usize], bits: &[u32]) -> u32 {
    let mut v: Vec<u32> = bits.to_vec();
    for &(op, x, y) in gates { let w = match op { 0 => 1 - v[x], 1 => v[x] & v[y], _ => v[x] | v[y] }; v.push(w); }
    outs.iter().enumerate().map(|(i, &o)| v[o] << i).sum()
}
fn bits(a: u32, b: u32, k: usize) -> Vec<u32> { (0..k).map(|i| a >> i & 1).chain((0..k).map(|i| b >> i & 1)).collect() }

fn program(mut n: u32) -> Vec<u32> { let mut p = Vec::new(); while n > 0 { p.push(n % 4); n /= 4; } p }
const NAME: [&str; 4] = ["INC", "DEC", "JNZ", "JMP"];
const CAP: usize = 1000;                                   // step cap for the runs below
fn status(p: &[u32], cap: usize) -> (char, usize, u64) {   // '1' halted, '0' a configuration repeated, '?' still running
    let (mut pc, mut c, mut seen) = (0usize, 0u64, HashSet::new());
    for step in 0..cap {
        if pc == p.len() { return ('1', step, c); }
        if !seen.insert((pc, c)) { return ('0', step, c); }
        match p[pc] { 0 => { c += 1; pc += 1 } 1 => { c = c.saturating_sub(1); pc += 1 }
                      2 => { pc = if c > 0 { pc.saturating_sub(1) } else { pc + 1 } } _ => { pc = 0 } }
    }
    ('?', cap, c)
}

fn ones(x: u32) -> u32 { x.count_ones() }
fn mv(m: u32, r: u32) -> u32 { (ones(m & 3 & r) & 1) | (ones(m >> 2 & r) & 1) << 1 }   // 2x2 table mod 2 times column r
fn mm(a: u32, b: u32) -> u32 {
    let c0 = mv(a, (b & 1) | (b >> 2 & 1) << 1); let c1 = mv(a, (b >> 1 & 1) | (b >> 3 & 1) << 1);
    (c0 & 1) | (c1 & 1) << 1 | (c0 >> 1) << 2 | (c1 >> 1) << 3
}
fn tab(m: u32) -> String { format!("{}{}/{}{}", m & 1, m >> 1 & 1, m >> 2 & 1, m >> 3 & 1) }
fn good(seed: u64, k: usize, passes: &[u32], no: &[usize]) -> bool {   // a wrong C escapes only if every r_i passes it
    let mut used = 0u32; for i in 0..k { used |= 1 << (seed >> (2 * i) & 3); }
    no.iter().all(|&x| used & !passes[x] != 0)
}

fn main() {
    for k in 1..=4usize {
        let (gates, outs) = adder(k);
        let mut right = 0;
        for a in 0..1u32 << k { for b in 0..1u32 << k { if run(&gates, &outs, &bits(a, b, k)) == a + b { right += 1; } } }
        println!("adder family: n={} input bits, {} gates, right on {} of {} inputs", 2 * k, gates.len(), right, 1 << (2 * k));
        assert!(right == 1 << (2 * k) && gates.len() == if k == 1 { 4 } else { 9 * k - 5 });
    }

    let advice: String = (0..64).map(|n| status(&program(n), CAP).0).collect();
    let cnt = |ch: char| advice.chars().filter(|&c| c == ch).count();
    println!("advice bits a_0..a_63: {}", advice);
    println!("  {} halt, {} loop (a configuration repeats), {} still running after {} steps", cnt('1'), cnt('0'), cnt('?'), CAP);
    for n in [3u32, 12, 36] {
        let (s, t, c) = status(&program(n), CAP);
        let names: Vec<&str> = program(n).iter().map(|&d| NAME[d as usize]).collect();
        let what = match s { '1' => format!("halts after {} steps", t), '0' => format!("repeats a configuration at step {}", t),
                             _ => format!("still running after {} steps, counter {}", t, c) };
        println!("  program {} = {}: {}", n, names.join(" "), what);
    }
    let mut checked = 0u64;
    for n in 1..=12u32 {                                    // both circuits for length n
        for bit in [0u32, 1] {
            let mut acc: Vec<u32> = Vec::new();
            for x in 0..1u32 << n {
                let mut v = x & 1; for i in 1..n { v &= x >> i & 1; }
                if (if bit == 1 { v } else { (x & 1) & (1 - (x & 1)) }) == 1 { acc.push(x); }
            }
            assert!(acc == if bit == 1 { vec![(1u32 << n) - 1] } else { vec![] }); checked += 1 << n;
        }
    }
    println!("unary circuits, n=1..12: AND of the n inputs accepts only 1^n, the 0-circuit accepts nothing; {} runs checked; gates n-1 = 11 at n=12", checked);
    assert!((cnt('1'), cnt('0'), cnt('?')) == (21, 31, 12) && &advice[..4] == "1110");
    assert!([3u32, 12, 36].map(|n| status(&program(n), 1000)) == [('0', 1, 0), ('?', 1000, 500), ('1', 3, 0)]);   // traced by hand

    const N: usize = 12;                                    // input: A, B, C, 4 bits each; is AB = C?
    let truth: Vec<bool> = (0..1u32 << N).map(|x| mm(x & 15, x >> 4 & 15) == x >> 8).collect();
    let passes: Vec<u32> = (0..1u32 << N).map(|x| (0..4u32).filter(|&r| mv(x & 15, mv(x >> 4 & 15, r)) == mv(x >> 8, r)).map(|r| 1 << r).sum()).collect();
    let no: Vec<usize> = (0..1usize << N).filter(|&x| !truth[x]).collect();
    let worst = no.iter().map(|&x| ones(passes[x])).max().unwrap() as f64 / 4.0;
    let half = no.iter().filter(|&&x| ones(passes[x]) == 2).count();
    println!("Freivalds test mod 2: {} inputs, {} with AB = C, {} without; one run wrongly passes a wrong C with chance at most {:.2}; {} wrong inputs reach it, {} sit at 0.25",
             1 << N, (1 << N) - no.len(), no.len(), worst, half, no.len() - half);
    for k in 1..=3usize {
        let g = (0..1u64 << (2 * k)).filter(|&s| good(s, k, &passes, &no)).count();
        let f = ((1usize << k) - 1) * ((1usize << k) - 2);
        println!("k={} runs: {} of {} coin strings right on all {} inputs; formula (2^k-1)(2^k-2) = {}", k, g, 1 << (2 * k), 1 << N, f);
        assert!(g == f);
    }
    for k in [2i32, 12, 13] {
        let bad = 3 * (1u64 << k) - 2; let all = 1u64 << (2 * k);
        let sum: f64 = no.iter().map(|&x| (ones(passes[x]) as f64).powi(k)).sum::<f64>() / (all as f64);
        println!("k={}: union bound {} x 2^-{} = {:.1}; sum of per-input errors {:.6}; exact bad share {}/{} = {:.6}",
                 k, 1 << N, k, (1u64 << N) as f64 / (1u64 << k) as f64, sum, bad, all, bad as f64 / all as f64);
        assert!(bad as f64 / all as f64 <= sum && sum <= (1u64 << N) as f64 * worst.powi(k));   // exact share <= summed errors <= union bound
    }
    assert!(worst == 0.5 && half == 2304);

    let mut state: u64 = 2026;                              // SplitMix64, seed 2026: 26-bit coin strings
    let mut splitmix = || -> u64 { state = state.wrapping_add(0x9E3779B97F4A7C15); let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) };
    let draws: Vec<u64> = (0..2000).map(|_| splitmix() & ((1 << 26) - 1)).collect();
    let first = draws[0];
    let right = (0..1usize << N).filter(|&x| (0..13).all(|i| passes[x] >> (first >> (2 * i) & 3) & 1 == 1) == truth[x]).count();
    let cols: Vec<String> = (0..13).map(|i| format!("{}{}", first >> (2 * i) & 1, first >> (2 * i + 1) & 1)).collect();
    println!("advice for n=12: first drawn coin string, columns r_1..r_13 = {}", cols.join(" "));
    println!("  {} advice bits, right on {} of {} inputs; one bit per input would need {}", 2 * 13, right, 1 << N, 1 << N);
    println!("  {} of {} drawn coin strings fail some input", draws.iter().filter(|&&s| !good(s, 13, &passes, &no)).count(), draws.len());
    let lame: u64 = (1 << 26) - 1;                          // every r_i = 11: a bad coin string, built on purpose
    let x = *no.iter().find(|&&x| passes[x] >> 3 & 1 == 1).unwrap() as u32;
    println!("mistake, every column r = 11: passes A={} B={} C={}, though AB = {}", tab(x & 15), tab(x >> 4 & 15), tab(x >> 8), tab(mm(x & 15, x >> 4 & 15)));
    let vec = |v: u32| format!("{}{}", v & 1, v >> 1 & 1);    // top entry, bottom entry
    let tr: Vec<String> = [1u32, 3].iter().map(|&r| format!("r={}: Br={} A(Br)={} Cr={} {}", vec(r), vec(mv(x >> 4 & 15, r)),
        vec(mv(x & 15, mv(x >> 4 & 15, r))), vec(mv(x >> 8, r)), if passes[x as usize] >> r & 1 == 1 { "passes" } else { "caught" })).collect();
    println!("hand trace: {}", tr.join("; "));
    assert!(right == 1 << N && !good(lame, 13, &passes, &no) && good(first, 13, &passes, &no) && passes[x as usize] == 0b1001);

    let (g2, o2) = adder(2);                                // Karp-Lipton's inner step: a yes/no box for SAT gives the answer
    let honest = |fixed: &[u32], target: u32| -> bool {
        let free = 4 - fixed.len();
        (0..1u32 << free).any(|r| { let mut b = fixed.to_vec(); b.extend((0..free).map(|i| r >> i & 1)); run(&g2, &o2, &b) == target })
    };
    let liar = |_: &[u32], _: u32| -> bool { true };
    let self_reduce = |boxf: &dyn Fn(&[u32], u32) -> bool, target: u32| -> (Option<Vec<u32>>, usize) {
        let mut calls = 1;
        if !boxf(&[], target) { return (None, calls); }
        let mut fixed: Vec<u32> = Vec::new();
        for _ in 0..4 { calls += 1; let mut t = fixed.clone(); t.push(1); fixed.push(if boxf(&t, target) { 1 } else { 0 }); }
        (Some(fixed), calls)
    };
    let cases: [(&str, &dyn Fn(&[u32], u32) -> bool, u32); 3] = [("honest box", &honest, 4), ("honest box", &honest, 7), ("liar box", &liar, 7)];
    for (name, boxf, target) in cases {
        let (w, calls) = self_reduce(boxf, target);
        let tail = match w { None => "says no".to_string(), Some(w) => { let got = run(&g2, &o2, &w);
            format!("a={} b={}, adder gives {}: {}", w[0] + 2 * w[1], w[2] + 2 * w[3], got,
                    if got == target { "checks" } else { "caught, the answer fails the check" }) } };
        println!("self-reduction, {}, a + b = {}: questions asked {}; {}", name, target, calls, tail);
    }
    let sols: Vec<(u32, u32)> = (0..16u32).map(|i| (i / 4, i % 4)).filter(|&(a, b)| a + b == 4).collect();
    let none7 = (0..16u32).all(|i| i / 4 + i % 4 != 7);
    println!("brute force: {} of 16 pairs give 4, none gives 7", sols.len());
    let w = self_reduce(&honest, 4).0.unwrap();             // the answers must agree with the brute force
    assert!(sols.contains(&(w[0] + 2 * w[1], w[2] + 2 * w[3])) && sols.len() == 3 && self_reduce(&honest, 7).0.is_none() == none7);
    println!("ALL CHECKS PASS");
}
