// Expectation as an integral -- the same check as the Python, in Rust.  No
// crates.  A boat is moored at a uniformly random point w of a 1 km river; the
// depth there is X(w) = 4w(1 - w) metres.  Exact fractions are pairs of i128
// kept in lowest terms by hand; the float roads repeat the Python's steps.
type Q = (i128, i128);

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); (n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { add(a, (-b.0, b.1)) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn fl(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
fn depth(w: f64) -> f64 { 4.0 * w * (1.0 - w) }

fn pmul(p: &[Q], r: &[Q]) -> Vec<Q> {            // multiply polynomials, lowest power first
    let mut out = vec![(0, 1); p.len() + r.len() - 1];
    for (i, &a) in p.iter().enumerate() {
        for (j, &b) in r.iter().enumerate() { out[i + j] = add(out[i + j], mul(a, b)); }
    }
    out
}
fn integral01(p: &[Q]) -> Q {                      // integral from 0 to 1: w^m gives 1/(m + 1)
    p.iter().enumerate().fold((0, 1), |s, (m, &c)| add(s, mul(c, (1, m as i128 + 1))))
}
fn power(p: &[Q], k: usize) -> Vec<Q> { (0..k).fold(vec![(1, 1)], |acc, _| pmul(&acc, p)) }

fn root(t: f64, mut lo: f64, mut hi: f64) -> f64 { // where the depth equals t, by bisection
    let up = depth(lo) < depth(hi);
    for _ in 0..80 {
        let mid = (lo + hi) / 2.0;
        if (depth(mid) < t) == up { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn river_tail(t: f64) -> f64 { root(t, 0.5, 1.0) - root(t, 0.0, 0.5) } // length at least t deep
fn law_tail(t: f64) -> f64 { (1.0 - t).sqrt() }                        // read off the law
fn isqrt(n: i128) -> i128 { let mut r = 0; while (r + 1) * (r + 1) <= n { r += 1 } r }
fn fsqrt(a: Q) -> Q { q(isqrt(a.0), isqrt(a.1)) }  // exact root of a square fraction

fn main() {
    // road 1, on the river: integrate (4w - 4w^2)^k over [0, 1]; road 2, on the line:
    // the law's density integral of t^k becomes, with u = sqrt(1 - t), (1 - u^2)^k
    let river: Vec<Q> = (1..5).map(|k| integral01(&power(&[(0, 1), (4, 1), (-4, 1)], k))).collect();
    let line: Vec<Q> = (1..5).map(|k| integral01(&power(&[(1, 1), (0, 1), (-1, 1)], k))).collect();
    let mean = river[0];
    let var_river = integral01(&power(&[(-mean.0, mean.1), (4, 1), (-4, 1)], 2));
    let var_line = sub(line[1], mul(line[0], line[0]));
    println!("moment k | on the river | on the line | decimal");
    for k in 0..4 {
        println!("E[X^{}]   | {:>12} | {:>11} | {:.4}", k + 1, show(river[k]), show(line[k]), fl(line[k]));
    }
    println!("variance: river E[(X - 2/3)^2] = {}, line E[X^2] - E[X]^2 = {}; = {:.4} m^2, sd {:.4} m",
             show(var_river), show(var_line), fl(var_line), fl(var_line).sqrt());
    println!("cross-section area: mean depth x 1000 m = {:.2} m^2", fl(mul(mean, (1000, 1))));
    println!("cdf, t | law 1 - sqrt(1 - t) | river 1 - length | uniform t");
    for i in 0..11 {
        let t = i as f64 / 10.0;
        println!("cdf, {:.1} | {:.4} | {:.4} | {:.4}", t, 1.0 - law_tail(t), 1.0 - river_tail(t), t);
    }
    println!("chart, law at t = 0.0 to 1.0, two decimals: {}",
             (0..11).map(|i| format!("{:.2}", 1.0 - law_tail(i as f64 / 10.0))).collect::<Vec<_>>().join(", "));
    println!("gauge floor(2^n X)/2^n | integral on the river | against the law | gap to 2/3");
    let mut sums: Vec<(i32, f64, f64)> = Vec::new();
    for n in [1, 2, 3, 4, 6, 8, 10] {
        let h = 2f64.powi(-n);
        let (mut on_river, mut on_line) = (0.0, 0.0);
        for k in 1..(1 << n) { on_river += h * river_tail(k as f64 * h); on_line += h * law_tail(k as f64 * h); }
        sums.push((n, on_river, on_line));
        println!("n = {:2} | {:.6} | {:.6} | {:.6}", n, on_river, on_line, 2.0 / 3.0 - on_line);
    }
    let probs: Vec<f64> = (0..4).map(|v| law_tail(v as f64 / 4.0) - law_tail((v + 1) as f64 / 4.0)).collect();
    let e_r = probs.iter().enumerate().fold(0.0, |s, (v, p)| s + v as f64 / 4.0 * p);
    println!("quarter-metre gauge R, sum formula: P(R = 0, 0.25, 0.5, 0.75) = {}; E[R] = {:.4}",
             probs.iter().map(|p| format!("{:.4}", p)).collect::<Vec<_>>().join(", "), e_r);
    println!("density f(t) = 1/(2 sqrt(1 - t)): f(0.5) = {:.4}, f(0.99) = {:.4}",
             1.0 / (2.0 * law_tail(0.5)), 1.0 / (2.0 * law_tail(0.99)));
    let (mut state, mut s1, mut s2, n) = (2026u64, 0.0f64, 0.0f64, 100000); // SplitMix64, seed 2026
    for _ in 0..n {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (state ^ (state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        let x = depth(((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0);
        s1 += x;
        s2 += x * x;
    }
    let (sim_mean, sim_var) = (s1 / n as f64, s2 / n as f64 - (s1 / n as f64).powi(2));
    let se = (4.0 / 45.0 / n as f64).sqrt();
    println!("simulation, {} boats: mean {:.4} m, variance {:.4} m^2, standard error {:.4} m", n, sim_mean, sim_var, se);
    let (mut total_line, mut total_river, mut cuts, mut size) = ((0, 1), 0.0, Vec::new(), (0, 1));
    for k in 0..6u32 {                             // band k: 1 - 4^-k <= X < 1 - 4^-(k+1), payout (-2)^k
        let (a, b) = (sub((1, 1), (1, 4i128.pow(k))), sub((1, 1), (1, 4i128.pow(k + 1))));
        size = mul((2i128.pow(k), 1), sub(fsqrt(sub((1, 1), a)), fsqrt(sub((1, 1), b))));
        total_line = add(total_line, mul(((-1i128).pow(k), 1), size));
        total_river += (-2f64).powi(k as i32) * (river_tail(fl(a)) - river_tail(fl(b)));
        cuts.push((total_line, total_river));
    }
    println!("break, payout (-2)^k on depth band k: |payout| x probability per band {}; totals after 1..6 bands {}",
             show(size), cuts.iter().map(|c| show(c.0)).collect::<Vec<_>>().join(", "));
    println!("break, depth read as uniform on [0, 1] m: integral of t dt = {}, not {}", show(integral01(&[(0, 1), (1, 1)])), show(mean));
    println!("break, (E[X])^2 = {} = {:.4} for E[X^2] = {} = {:.4}", show(mul(mean, mean)), fl(mul(mean, mean)), show(river[1]), fl(river[1]));
    println!("figure, x = 40 + 280 w, y = 40 + 160 d; bed M 40 40 Q {:.0} {:.0} 320 40; deepest ({:.0}, {:.0}); depth 0.75 at y {:.0}, from x {:.0} to {:.0}; \
              boat at w = 0.3: depth {:.2} m, x {:.0}, bed y {:.0}",
             40.0 + 280.0 * 0.5, 40.0 + 160.0 * 2.0 * depth(0.5), 40.0 + 280.0 * 0.5, 40.0 + 160.0 * depth(0.5),
             40.0 + 160.0 * 0.75, 40.0 + 280.0 * root(0.75, 0.0, 0.5), 40.0 + 280.0 * root(0.75, 0.5, 1.0),
             depth(0.3), 40.0 + 280.0 * 0.3, 40.0 + 160.0 * depth(0.3));
    assert!(river == line && mean == (2, 3));                       // two exact roads, four moments
    assert!(var_river == var_line && var_line == (4, 45));          // variance two ways
    assert!(sums.iter().all(|&(_, r, l)| (r - l).abs() < 1e-12));   // simple functions transfer
    assert!(sums.iter().all(|&(n, _, l)| 0.0 < 2.0 / 3.0 - l && 2.0 / 3.0 - l <= 2f64.powi(-n)));
    assert!((sim_mean - 2.0 / 3.0).abs() < 4.0 * se && (sim_var - 4.0 / 45.0).abs() < 0.0012);
    assert!(cuts.iter().all(|c| (fl(c.0) - c.1).abs() < 1e-9));
    assert!(cuts.iter().enumerate().all(|(i, c)| c.0 == if i % 2 == 0 { (1, 2) } else { (0, 1) }));
    println!("ALL CHECKS PASS");
}
