// Lebesgue's theorem on monotone functions -- the same check as the Python, in Rust.
// No crates: a hand-written exponential, Cantor staircase and Simpson rule; exact
// integer arithmetic for the Takagi counterexample.  Claims in thousands of dollars.

fn exp_pos(x: f64) -> f64 {                   // e^x for x >= 0, summed term by term
    let (mut total, mut term, mut k) = (1.0f64, 1.0f64, 0.0f64);
    while term > 1e-17 * total { k += 1.0; term *= x / k; total += term; }
    total
}
fn e_neg(x: f64) -> f64 { 1.0 / exp_pos(x) }  // e^(-x) for x >= 0

fn cantor(mut p: i64, q: i64) -> f64 {        // Cantor staircase C at p/q >= 0, base-3 digits
    if p >= q { return 1.0; }
    let (mut value, mut half) = (0.0f64, 0.5f64);
    for _ in 0..40 {
        p *= 3;
        let d = p / q; p %= q;
        if d == 1 { return value + half; }    // inside a removed middle third: C is flat there
        if d == 2 { value += half; }
        half /= 2.0;
    }
    value
}

fn self_similar(k: i64, n: u32) -> i64 {     // 2^n C(k / 3^n) by C(x) = C(3x)/2, 1/2, 1/2 + C(3x - 2)/2
    if k == 0 || k == 3i64.pow(n) { return if k == 0 { 0 } else { 1i64 << n }; }
    let third = 3i64.pow(n - 1);
    if k <= third { return self_similar(k, n - 1); }
    if k <= 2 * third { 1i64 << (n - 1) } else { (1i64 << (n - 1)) + self_similar(k - 2 * third, n - 1) }
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 6000 steps
    let m = 6000; let h = (b - a) / m as f64;
    (g(a) + g(b) + (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum::<f64>()) * h / 3.0
}

const N: u32 = 7;                             // road B grid: cells of width 3^-7, all points over Q = 4 * 3^8
const T: i64 = 2187;
const Q: i64 = 4 * 6561;
fn road_b(f: &dyn Fn(i64) -> f64, lo: i64, hi: i64) -> (f64, f64, i64) {   // integral of F' from F alone
    let (mut total, mut big, mut at) = (0.0f64, 0.0f64, i64::MIN);
    for j in lo * T..hi * T {                 // midpoint (2j+1)/(2T) = 6(2j+1)/Q; step 1/Q either side
        let m = 6 * (2 * j + 1);
        total += (f(m + 1) - f(m - 1)) * Q as f64 / 2.0 / T as f64;
        let rise = f(12 * (j + 1)) - f(12 * j);
        if rise > big { big = rise; at = j + 1; }
    }
    (total, big, at)
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> String { let g = gcd(n, d).max(1); if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn takagi(j: i64, n: u32) -> i64 {            // T(j / 2^n) * 2^(2n) exactly: terms k >= n vanish
    let d = 1i64 << n;
    (0..n).map(|k| { let r = (j << k) % d; r.min(d - r) << (n - k) }).sum()
}

fn main() {
    // ---- The Cantor staircase ----
    let c27: Vec<f64> = (0..28).map(|k| 100.0 * cantor(k, 27)).collect();
    println!("chart, Cantor staircase C at x = k/27, k = 0..27, in % of the climb: {}", join(&c27, 2));
    println!("road A, stages: cells of width 3^-n on [0, 1]; C rises on some and is flat on the rest");
    for n in [1u32, 2, 3, 4, 6, 8, 10] {
        let t = 3i64.pow(n);
        let rises: Vec<f64> = (0..t).map(|j| cantor(j + 1, t) - cantor(j, t)).collect();
        let up: Vec<f64> = rises.iter().cloned().filter(|&r| r > 0.0).collect();
        let (len_up, total) = (up.len() as f64 / t as f64, rises.iter().sum::<f64>());
        println!("  n = {:2}: rising {:4} of {:5}, slope there {:9.4}, their length {:.6}, flat length {:.6}, integral of stage slopes {:.6}",
                 n, up.len(), t, up[0] * t as f64, len_up, 1.0 - len_up, total);
        assert!(up.len() == 1usize << n && up.iter().all(|&r| r == 0.5f64.powi(n as i32)));   // count and size
        assert!((0..=t).all(|k| cantor(k, t) * (1i64 << n) as f64 == self_similar(k, n) as f64));   // digits agree with self-similarity
    }
    let flat = (0..T).filter(|&j| cantor(6 * (2 * j + 1) + 1, Q) == cantor(6 * (2 * j + 1) - 1, Q)).count();
    let (cb, _, _) = road_b(&|p| if p > 0 { cantor(p, Q) } else { 0.0 }, 0, 1);
    println!("road B, midpoints: C is flat around {} of {} midpoints of width-3^-{} cells; midpoint sum of C' = {:.6}", flat, T, N, cb);
    assert!(flat as i64 == T);
    println!("Cantor: C(1) - C(0) = {:.6}; integral of C' = {:.6}; shortfall {:.6}, all of it singular",
             cantor(1, 1) - cantor(0, 1), cb, cantor(1, 1) - cb);
    let at0: Vec<f64> = (1..7).map(|n| cantor(1, 3i64.pow(n)) * 3i64.pow(n) as f64).collect();
    println!("Cantor at x = 0: C(3^-n) / 3^-n for n = 1..6: {}", join(&at0, 6));
    assert!((1..7).all(|n| at0[n - 1] == 1.5f64.powi(n as i32)));

    // ---- The insurance claim: 0.3 chance of no claim, else exponential with mean 1 ----
    let fc = |x: f64| if x < 0.0 { 0.0 } else { 0.3 + 0.7 * (1.0 - e_neg(x)) };
    let dens = |x: f64| 0.7 * e_neg(x);       // F' away from 0, from the decomposition
    let pts = [-1.0, -0.5, -1e-9, 0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0];
    let lab = "at -1, -0.5, just below 0, 0, 0.5, 1, 2, 3, 4, 5";
    let line1: Vec<f64> = pts.iter().map(|&x| fc(x) - fc(-1.0)).collect();
    let line2: Vec<f64> = pts.iter().map(|&x| if x > 0.0 { simpson(&dens, 0.0, x) } else { 0.0 }).collect();
    println!("chart, claim F(x) - F(-1) {}: {}", lab, join(&line1, 2));
    println!("chart, claim integral of F' from -1 to x {}: {}", lab, join(&line2, 2));
    let ca = simpson(&dens, 0.0, 5.0);
    let (c_b, cjump, cat) = road_b(&|p| fc(p as f64 / Q as f64), -1, 5);
    let cgap = fc(5.0) - fc(-1.0);
    println!("claim, road A (density 0.7 e^(-x), Simpson over (0, 5]): {:.6}", ca);
    println!("claim, road B (F alone, {} midpoints): {:.6}; largest cell rise {:.6}, cell ending at {}", 6 * T, c_b, cjump, frac(cat, T));
    println!("claim: F(5) - F(-1) = {:.6}; shortfall {:.6}; F(1) = {:.6}", cgap, cgap - c_b, fc(1.0));
    assert!((c_b - ca).abs() < 1e-7 && (cgap - c_b - cjump).abs() < 1e-7 && cat == 0);

    // ---- Three pieces: 0.3 jump at 0, 0.5 exponential, 0.2 Cantor on [0, 1] ----
    let f3 = |p: i64| if p < 0 { 0.0 } else { 0.3 + 0.5 * (1.0 - e_neg(p as f64 / Q as f64)) + 0.2 * cantor(p, Q) };
    let ta = simpson(&|x| 0.5 * e_neg(x), 0.0, 1.0);
    let (t_b, tjump, tat) = road_b(&f3, -1, 1);
    let tgap = f3(Q) - f3(-Q);
    println!("three-piece on [-1, 1]: road A {:.6}, road B {:.6}; F(1) - F(-1) = {:.6}", ta, t_b, tgap);
    println!("three-piece: shortfall {:.6} = largest cell rise {:.6} (cell ending at {}) + staircase {:.6}",
             tgap - t_b, tjump, frac(tat, T), tgap - t_b - tjump);
    assert!((t_b - ta).abs() < 1e-7 && (tgap - t_b - tjump - 0.2).abs() < 1e-7);

    // ---- What breaks ----
    let (mut tq, mut walk) = (Vec::new(), Vec::new());   // cells [j/2^n, (j+1)/2^n] around 1/3
    for n in 1..13u32 {
        let j = (1i64 << n) / 3;
        tq.push((takagi(j + 1, n) - takagi(j, n)) >> n);
        walk.push((1..=n).map(|i| 1 - 2 * (((1i64 << i) / 3) % 2)).sum::<i64>());   // +1 per binary 0, -1 per 1
    }
    println!("Takagi T (not monotone): slope of T across the width-2^-n cell holding 1/3, n = 1..12: {}",
             tq.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "));
    assert!(tq == walk);                      // the zeros-minus-ones count of the binary digits
    println!("mistake 1, integral of F' taken as F(b) - F(a): Cantor {:.6} vs 1; claim {:.6} vs {:.6}", cb, c_b, cgap);
    println!("mistake 2, stage slopes integrate to 1 at every n; their a.e. limit integrates to {:.6}", cb);
    println!("mistake 3, slope expected everywhere: at 0, Cantor quotient {:.6} at h = 3^-6; claim quotient {:.1} at h = 10^-6",
             at0[5], fc(1e-6) / 1e-6);
    println!("ALL CHECKS PASS");
}
