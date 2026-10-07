// The Lebesgue-Stieltjes integral -- the same check as the Python, in Rust.
// No crates.  Exact fractions are a small struct written here.  The claim X:
// 0 with probability 0.3, otherwise spread evenly over (0, 1000].  E[X] is
// reached four ways: jump plus density (exact), the tail 1 - F (midpoint
// sums), Riemann-Stieltjes sums, and a SplitMix64 simulation.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                     // an exact fraction n / d, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn mono(k: u32, lo: i128, hi: i128) -> Q {        // exact integral of x^k from lo to hi
    q(hi.pow(k + 1) - lo.pow(k + 1), (k + 1) as i128)
}
fn f_cdf(x: f64) -> f64 {                         // distribution function, in floats
    if x < 0.0 { 0.0 } else if x < 1000.0 { 0.3 + 0.0007 * x } else { 1.0 }
}
fn rs_sums(g: &dyn Fn(f64) -> f64, n: usize) -> (f64, f64) {   // left and right tags
    let (a, b) = (-100.0, 1000.0);
    let h = (b - a) / n as f64;
    let (mut left, mut right) = (0.0, 0.0);
    for i in 0..n {
        let (x0, x1) = (a + i as f64 * h, a + (i + 1) as f64 * h);
        let rise = f_cdf(x1) - f_cdf(x0);
        left += g(x0) * rise;
        right += g(x1) * rise;
    }
    (left, right)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                // SplitMix64, top 53 bits in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn claim(&mut self) -> f64 {                  // inverse of F: a draw of X
        let u = self.uniform();
        if u < 0.3 { 0.0 } else { (u - 0.3) / 0.7 * 1000.0 }
    }
}
fn mid(fnc: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {  // midpoint sum
    let h = (hi - lo) / n as f64;
    let mut total = 0.0;
    for i in 0..n { total += fnc(lo + (i as f64 + 0.5) * h) * h; }
    total
}
fn mid_tail(lo: f64, hi: f64, n: usize) -> f64 { mid(&|x| 1.0 - f_cdf(x), lo, hi, n) }
fn main() {
    let (p0, dens, top) = (q(3, 10), q(7, 10000), 1000i128);
    // road 1: jump plus density, exact
    let (jump_x, spread_x) = (mul(p0, q(0, 1)), mul(dens, mono(1, 0, top)));
    let ex = add(jump_x, spread_x);
    let jump_fee = mul(p0, q(50, 1));
    let spread_fee = mul(dens, add(mul(q(50, 1), mono(0, 0, top)), mono(1, 0, top)));
    println!("claim law: P(X = 0) = 0.3; otherwise even on (0, 1000], density 0.0007");
    println!("road 1, jump plus density, exact: E[X] = {:.1} + {:.1} = {:.1}", fl(jump_x), fl(spread_x), fl(ex));
    println!("road 1, with a $50 fee on every policy: E[50 + X] = {:.1} + {:.1} = {:.1}",
             fl(jump_fee), fl(spread_fee), fl(add(jump_fee, spread_fee)));
    // road 2: the tail
    let tail = mid_tail(0.0, 1000.0, 1000);
    println!("road 2, area under the tail 1 - F on (0, 1000], 1000 midpoint slices: {:.6}", tail);
    let tl: Vec<String> = (0..11).map(|k| format!("{:.2}", 1.0 - f_cdf(100.0 * k as f64))).collect();
    println!("tail 1 - F(x) at x = 0, 100, ..., 1000: {}", tl.join(" "));
    let mut parts = Vec::new();
    for b in [250i128, 500, 1000] {
        let lhs = mul(dens, mono(1, 0, b));       // exact: integral of x dF over (0, b]
        let (area, edge) = (mid_tail(0.0, b as f64, b as usize), b as f64 * (1.0 - f_cdf(b as f64)));
        parts.push((b, lhs, area, edge));
        println!("by parts on (0, {}]: int x dF = {:.3}; tail area {:.3} - boundary {:.3} = {:.3}",
                 b, fl(lhs), area, edge, area - edge);
    }
    // road 3: Riemann-Stieltjes sums, g(x) = x, continuous
    println!("road 3, Riemann-Stieltjes sums for E[X] on (-100, 1000]:");
    let mut rs = Vec::new();
    for n in [11usize, 110, 1100] {
        let (l, r) = rs_sums(&|x| x, n);
        rs.push((l, r));
        println!("  n = {:<5} left tags {:.4}   right tags {:.4}", n, l, r);
    }
    // road 4: simulation
    let big_n = 100000usize;
    let mut rng = Rng(20260929);
    let draws: Vec<f64> = (0..big_n).map(|_| rng.claim()).collect();
    let mut total = 0.0;
    for d in &draws { total += d; }
    let mean = total / big_n as f64;
    let mut sq = 0.0;
    for d in &draws { sq += (d - mean) * (d - mean); }
    let se = (sq / (big_n - 1) as f64 / big_n as f64).sqrt();
    println!("road 4, {} simulated claims, SplitMix64 seed 20260929: mean {:.4}, standard error {:.4}", big_n, mean, se);
    // integration by parts: F against itself on (-100, 1000]
    let jumpsq = mul(p0, p0);                     // F(0) times the jump 0.3
    let strip = mul(mul(p0, dens), mono(0, 0, top));   // the constant 0.3 of F, against the spread
    let tri = mul(mul(dens, dens), mono(1, 0, top));   // the rising part of F, against the spread
    let direct = add(add(jumpsq, strip), tri);
    let (fa, fb) = (q(f_cdf(-100.0) as i128, 1), q(f_cdf(1000.0) as i128, 1));   // 0 and 1
    let formula = mul(add(sub(mul(fb, fb), mul(fa, fa)), mul(p0, p0)), q(1, 2));
    let leftlim = add(add(mul(q(0, 1), p0), strip), tri);   // F(0-) = 0 at the atom
    println!("integration by parts, F against itself on (-100, 1000]:");
    println!("  direct: jump {:.3} + strip {:.3} + triangle {:.3} = {:.3}", fl(jumpsq), fl(strip), fl(tri), fl(direct));
    println!("  by parts with the jump term: (1 - 0 + 0.3 x 0.3) / 2 = {:.3}", fl(formula));
    println!("  left-limit form: int F(x-) dF = {:.3}; sum with {:.3} = {:.3}", fl(leftlim), fl(direct), fl(add(leftlim, direct)));
    let mut hits = 0usize;
    for _ in 0..big_n { let a = rng.claim(); let b = rng.claim(); if a <= b { hits += 1; } }
    let pairs = hits as f64 / big_n as f64;
    let pse = (pairs * (1.0 - pairs) / big_n as f64).sqrt();
    println!("  simulation: share of {} pairs with X' <= X: {:.4}, standard error {:.4}", big_n, pairs, pse);
    // what breaks
    println!("mistakes:");
    println!("  density only, fee case: {:.1} (true {:.1})", fl(spread_fee), fl(add(jump_fee, spread_fee)));
    println!("  by parts without the jump term: {:.3} (true {:.3})", fl(q(1, 2)), fl(direct));
    let step = |x: f64| if x >= 0.0 { 1.0 } else { 0.0 };   // jumps where F jumps
    let bad: Vec<(f64, f64)> = [11usize, 110, 1100].iter().map(|&n| rs_sums(&step, n)).collect();
    let bl: Vec<String> = bad.iter().map(|p| format!("{:.4}", p.0)).collect();
    let br: Vec<String> = bad.iter().map(|p| format!("{:.4}", p.1)).collect();
    println!("  Riemann-Stieltjes, g = 1 on [0, inf), n = 11, 110, 1100: left {}, right {}; Lebesgue-Stieltjes 1.0",
             bl.join(" "), br.join(" "));
    println!("  F in place of 1 - F: {:.1} (true {:.1})", mid(&f_cdf, 0.0, 1000.0, 1000), fl(ex));
    println!("  density 0.001 with no 0.7 weight: {:.1}", fl(mul(q(1, 1000), mono(1, 0, top))));
    let (_, lhs, area, edge) = parts[1];
    println!("  boundary term dropped at b = 500: {:.1} (true {:.1})", area, fl(lhs));
    let cs: Vec<String> = [1, 5, 10, 20].iter().map(|&n| format!("{:.6}", (2.0f64 / 3.0).powi(n))).collect();
    println!("Cantor function: rise 1; length where it can rise, (2/3)^n at n = 1, 5, 10, 20: {}", cs.join(" "));
    let px = |u: f64| 50.0 + 180.0 * u;           // F-coordinates to drawing units
    let py = |v: f64| 200.0 - 180.0 * v;
    println!("figure, 180 units per unit of F, corner ({:.0}, {:.0}); atom block to ({:.0}, {:.0}); diagonal to ({:.0}, {:.0}); shaded area {:.3}, unshaded {:.3}",
             px(0.0), py(0.0), px(0.3), py(0.3), px(1.0), py(1.0), fl(direct), 1.0 - fl(direct));
    assert!((tail - fl(ex)).abs() < 1e-6);                        // tail road meets the exact road
    assert!(rs.iter().all(|&(l, r)| l < fl(ex) && fl(ex) < r));   // Stieltjes sums bracket 350
    assert!(rs[2].1 - rs[2].0 < 1.01);                            // and close in on it
    assert!(direct == formula);                                   // measure road = by-parts road
    assert!(add(leftlim, direct) == q(1, 1));                     // the square: s <= t plus s > t
    assert!((mean - fl(ex)).abs() < 4.0 * se);                    // simulation, within 4 errors
    assert!((pairs - fl(direct)).abs() < 4.0 * pse);
    assert!((fl(lhs) - (area - edge)).abs() < 1e-6);              // by parts with a boundary
    println!("ALL CHECKS PASS");
}
