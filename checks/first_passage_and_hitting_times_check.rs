// Hitting times of the simple random walk -- the same check as first_passage_and_hitting_times_check.py.
// Std only, no crates.  Roads: the formula; every path of 16 rounds enumerated; probability pushed
// along every path round by round; first-step equations solved by elimination; a seeded simulation
// with its standard error.  Exact fractions are kept as u128 numerator over a power of 4.
// Compile: rustc --edition 2021 -O first_passage_and_hitting_times_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

struct SplitMix64 { s: u64 }                       // the small generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn step(&mut self) -> i64 { if self.next() >> 63 == 1 { 1 } else { -1 } }
}

fn u(two_n: usize) -> f64 {                        // formula: P(S_2n = 0) = C(2n, n) / 2^(2n), as a product
    let mut x = 1.0;
    for k in 1..=two_n / 2 { x = x * (2 * k - 1) as f64 / (2 * k) as f64; }
    x
}
fn central(two_n: u128) -> u128 {                  // C(2n, n) exactly
    let mut c: u128 = 1;
    for k in 0..two_n / 2 { c = c * (two_n - k) / (k + 1); }
    c
}
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(num: u128, den: u128) -> String { let g = gcd(num, den); format!("{}/{}", num / g, den / g) }

fn first_step(lo: i64, hi: i64, p: f64, start: i64, top: f64, bottom: f64, cost: f64) -> f64 {
    // h_k = cost + p h_(k+1) + (1 - p) h_(k-1) for lo < k < hi, h_lo = bottom, h_hi = top.
    let (q, n) = (1.0 - p, (hi - lo - 1) as usize);
    let (mut b, c, mut d) = (vec![1.0; n], vec![-p; n], vec![cost; n]);
    d[0] += q * bottom; d[n - 1] += p * top;
    for i in 1..n {                                // eliminate downwards
        let m = -q / b[i - 1]; b[i] -= m * c[i - 1]; d[i] -= m * d[i - 1];
    }
    let mut h = vec![0.0; n]; h[n - 1] = d[n - 1] / b[n - 1];   // then substitute back upwards
    for i in (0..n - 1).rev() { h[i] = (d[i] - c[i] * h[i + 1]) / b[i]; }
    h[(start - lo - 1) as usize]
}

fn row(name: &str, vals: &[f64]) { println!("{:<40}{}", name, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>()); }
fn row_eq(name: &str, got: f64, want: f64) { row(name, &[got, want]); assert!((got - want).abs() < 1e-9, "{}", name); }

fn main() {
    // ---- road 2: every one of the 2^16 paths of 16 rounds, first return to level recorded ----
    const L: usize = 16;
    let (mut first, mut hit1, mut never) = ([0u128; L + 1], [0u128; L + 1], 0u128);
    for w in 0u32..(1 << L) {
        let (mut s, mut back, mut up) = (0i64, false, false);
        for i in 0..L {
            s += if (w >> i) & 1 == 1 { 1 } else { -1 };
            if s == 0 && !back { first[i + 1] += 1; back = true; }
            if s == 1 && !up { hit1[i + 1] += 1; up = true; }
        }
        if !back { never += 1; }
    }
    println!("{:<40}{:>12}{:>12}", "first return T, all 65536 paths of 16", "enumerated", "formula");
    for t in [2u128, 4, 6, 8] {
        let den = 1u128 << t;                      // u(t-2) - u(t) over the common denominator 2^t
        let f_num = 4 * central(t - 2) - central(t);
        println!("{:<40}{:>12}{:>12}", format!("  P(T = {})", t), frac(first[t as usize], 1 << L), frac(f_num, den));
        assert!(first[t as usize] * den == f_num * (1u128 << L), "enumerated first-return law vs u(2n-2) - u(2n)");
    }
    println!("{:<40}{:>12}{:>12}", "  P(T > 16)", frac(never, 1 << L), frac(central(16), 1 << 16));
    assert!(never == central(16), "no return in 16 rounds vs P(S_16 = 0)");
    for t in [1u128, 3, 5, 7] {                    // first passage to +1 at round t = 2n - 1 has P(T = 2n)
        let (den, f_num) = (1u128 << (t + 1), 4 * central(t - 1) - central(t + 1));
        println!("{:<40}{:>12}{:>12}", format!("  P(tau_1 = {})", t), frac(hit1[t as usize], 1 << L), frac(f_num, den));
        assert!(hit1[t as usize] * den == f_num * (1u128 << L), "enumerated first passage to +1 vs P(T = t + 1)");
    }

    // ---- road 3: push probability along every path, level absorbs; survival to 1000 rounds ----
    const N: usize = 1000;
    let off = N + 1;
    let (mut dist, mut surv) = (vec![0.0f64; 2 * off + 1], vec![1.0f64]); dist[off] = 1.0;
    for _ in 1..=N {
        let mut new = vec![0.0f64; dist.len()];
        for i in 1..dist.len() - 1 {
            if dist[i] != 0.0 { new[i - 1] += dist[i] / 2.0; new[i + 1] += dist[i] / 2.0; }
        }
        new[off] = 0.0; surv.push(new.iter().sum()); dist = new;
    }
    println!("{:<40}{:>12}{:>12}", "still waiting, P(T > n)", "pushed", "formula");
    for n in 0..=N {                               // every n checked; a few printed
        if [0, 2, 4, 6, 8, 10, 20, 40, 60, 80, 100, 1000].contains(&n) { row(&format!("  n = {}", n), &[surv[n], u(n)]); }
        assert!((surv[n] - u(n)).abs() < 1e-12, "pushed survival vs C(n, n/2) / 2^n");
    }
    row("  1 / sqrt(pi * 500), estimate at 1000", &[1.0 / (PI * 500.0).sqrt()]);
    let pts: Vec<String> = (0..=100).step_by(10).map(|n| format!("{:.2}", surv[n])).collect();
    println!("chart, P(T > n), n = 0 to 100 by 10: {}", pts.join(" "));

    // ---- the mean: capped averages E[min(T, cap)] grow without limit ----
    println!("{:<40}{:>12}{:>12}{:>12}", "capped mean E[min(T, cap)]", "tail sum", "closed", "sqrt(cap/2)");
    let (mut run, mut tail) = (1.0f64, 0.0f64);
    let mut capped: Vec<f64> = Vec::new();
    for n in 0..50000usize {                       // tail sum: E[min(T, 2N)] = 2 * sum of u(2n), n < N
        tail += 2.0 * run;
        let cap = 2 * (n + 1);
        if [10, 100, 1000, 10000, 100000].contains(&cap) {
            let closed = 2.0 * (cap - 1) as f64 * u(cap - 2);
            row(&format!("  cap = {}", cap), &[tail, closed, (cap as f64 / 2.0).sqrt()]);
            assert!((tail - closed).abs() < 1e-9 * cap as f64, "tail sum vs closed form");
            assert!(tail >= (cap as f64 / 2.0).sqrt(), "capped mean at least sqrt(cap/2)");
            capped.push(tail);
        }
        run *= (2 * n + 1) as f64 / (2 * n + 2) as f64;
    }
    let pts: Vec<String> = capped.iter().map(|c| format!("{:.2}", c)).collect();
    println!("chart, capped mean, caps 10 to 100000: {}", pts.join(" "));
    assert!((surv[..1000].iter().sum::<f64>() - capped[2]).abs() < 1e-9, "pushed survival summed vs formula tail sum");

    // ---- road 4: first-step equations with a floor at -b; the wait for +1 is at least b ----
    println!("{:<40}{:>12}{:>12}", "first-step equations", "solved", "formula");
    row_eq("  10 chips, stop at 0 or 11: P(reach 11)", first_step(-10, 1, 0.5, 0, 1.0, 0.0, 0.0), 10.0 / 11.0);
    for b in [10i64, 100, 1000] {
        let m = first_step(-b, 1, 0.5, 0, 0.0, 0.0, 1.0);
        row(&format!("  fair, mean rounds to +1 or -{}", b), &[m, b as f64]);
        assert!((m - b as f64).abs() < 1e-6 * b as f64, "first-step duration vs b * 1 from gambler's ruin");
    }
    for b in [10i64, 100, 1000] {
        row_eq(&format!("  fair, P(level again before +-{})", b), first_step(0, b, 0.5, 1, 0.0, 1.0, 0.0), 1.0 - 1.0 / b as f64);
    }
    for p in [0.4f64, 0.6] {
        let q = 1.0 - p;
        let up = first_step(-400, 1, p, 0, 1.0, 0.0, 0.0);
        let back = p * first_step(0, 400, p, 1, 0.0, 1.0, 0.0) + q * first_step(-400, 0, p, -1, 1.0, 0.0, 0.0);
        row_eq(&format!("  p = {}: P(ever reach +1)", p), up, (p / q).min(1.0));
        row_eq(&format!("  p = {}: P(ever level again)", p), back, 1.0 - (p - q).abs());
    }
    row_eq("  p = 0.4: P(ever reach +3)", first_step(-400, 3, 0.4, 0, 1.0, 0.0, 0.0), (0.4f64 / 0.6).powi(3));
    row_eq("  p = 0.6: mean rounds to reach +1", first_step(-400, 1, 0.6, 0, 0.0, 0.0, 1.0), 1.0 / (0.6 - 0.4));

    // ---- road 5: seeded simulation, 20000 matches, each capped at 10000 rounds ----
    let (mut rng, ns, cap) = (SplitMix64 { s: 20260929 }, 20000usize, 10000u64);
    let (mut t2, mut over100, mut tot, mut tot2) = (0usize, 0usize, 0.0f64, 0.0f64);
    for _ in 0..ns {
        let (mut s, mut t) = (rng.step(), 1u64);
        while s != 0 && t < cap { s += rng.step(); t += 1; }
        if t == 2 { t2 += 1; } else if t > 100 { over100 += 1; }
        tot += t as f64; tot2 += (t * t) as f64;
    }
    let nsf = ns as f64; let mean = tot / nsf; let se = ((tot2 / nsf - mean * mean) / nsf).sqrt();
    for (name, k, f) in [("P(T = 2)", t2, 0.5), ("P(T > 100)", over100, u(100))] {
        let ph = k as f64 / nsf; let sep = (ph * (1.0 - ph) / nsf).sqrt();
        println!("sim {:<36}{:>12.6} +- {:.6}  formula {:.6}", name, ph, sep, f);
        assert!((ph - f).abs() < 4.0 * sep, "simulated chance within 4 standard errors");
    }
    println!("sim E[min(T, 10000)]{:<20}{:>12.6} +- {:.6}  formula {:.6}", "", mean, se, capped[3]);
    assert!((mean - capped[3]).abs() < 4.0 * se, "simulated capped mean within 4 standard errors");

    // ---- the picture: one sample match, seed 7, the first whose return comes in rounds 10 to 24 ----
    let mut g = SplitMix64 { s: 7 };
    let path = loop {
        let mut path = vec![0i64];
        while path.len() < 25 && (path.len() == 1 || *path.last().unwrap() != 0) {
            let next = path.last().unwrap() + g.step(); path.push(next);
        }
        if *path.last().unwrap() == 0 && path.len() >= 11 { break path; }
    };
    println!("figure, T = {} scores: {}", path.len() - 1, path.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "));
    let pts: Vec<String> = path.iter().enumerate().map(|(i, x)| format!("{},{}", 30 + 18 * i as i64, 50 - 20 * x)).collect();
    println!("figure, svg points: {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
