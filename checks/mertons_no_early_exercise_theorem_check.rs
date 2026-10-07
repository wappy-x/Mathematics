// Merton's no-early-exercise theorem -- the same check as the Python, in Rust.  Std
// only, no crates.  The bell-curve area is thin slices under the curve (Simpson),
// every average is Simpson written out, the trees are loops, the exercise boundary
// comes from bisection.  Acme: S = K = 100, r = 5%, sigma = 20%, one year, no
// dividend yield; then one cash dividend D at six months, escrowed; then the put.
use std::collections::BTreeSet;
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const SIG: f64 = 0.20;
const T: f64 = 1.0; const T1: f64 = 0.5; const STEPS: usize = 2000;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }       // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {  // add up thin slices under f
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (f(a) + f(b) + acc) * h / 3.0
}
fn ncdf(x: f64) -> f64 {                                                 // bell-curve area left of x
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 400)
}
fn bs_call(s: f64, k: f64, t: f64) -> f64 {                              // road 1: the formula, no yield
    if t <= 0.0 { return (s - k).max(0.0); }
    let d1 = ((s / k).ln() + (R + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    s * ncdf(d1) - k * (-R * t).exp() * ncdf(d1 - SIG * t.sqrt())
}
fn grow(s: f64, t: f64, z: f64) -> f64 { s * ((R - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp() }
fn by_integral<F: Fn(f64) -> f64>(payoff: F, s: f64, t: f64) -> f64 {  // road 2: average the payoff
    (-R * t).exp() * simpson(|z| payoff(grow(s, t, z)) * phi(z), -10.0, 10.0, 4000)
}

// road 3: CRR tree on the escrowed share; returns price, exercise count, steps, lowest exercised share
fn tree(d: f64, sign: f64, american: bool, steps: usize, s: f64) -> (f64, usize, Vec<usize>, Option<f64>) {
    let dt = T / steps as f64;
    let u = (SIG * dt.sqrt()).exp();
    let p = ((R * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let disc = (-R * dt).exp();
    let (s0, m) = (s - d * (-R * T1).exp(), (T1 / dt).round() as usize);   // step m: just before ex-date
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (sign * (s0 * u.powf(2.0 * j as f64 - steps as f64) - K)).max(0.0)).collect();
    let (mut count, mut when, mut lowest) = (0usize, BTreeSet::new(), None::<f64>);
    for n in (0..steps).rev() {
        let cash = if n <= m { d * (-R * (T1 - n as f64 * dt)).exp() } else { 0.0 };  // dividend still inside
        for j in 0..=n {
            let mut keep = disc * (p * v[j + 1] + (1.0 - p) * v[j]);
            let share = s0 * u.powf(2.0 * j as f64 - n as f64) + cash;
            if american && sign * (share - K) > keep + 1e-12 {
                keep = sign * (share - K); count += 1; when.insert(n);
                if n == m && lowest.map_or(true, |l| share < l) { lowest = Some(share); }
            }
            v[j] = keep;
        }
    }
    (v[0], count, when.into_iter().collect(), lowest)
}
fn threshold() -> f64 { K * (1.0 - (-R * (T - T1)).exp()) }             // interest saved by waiting after ex-date
fn boundary(d: f64) -> Option<f64> {                                     // cum-dividend price where exercise = holding
    if d <= threshold() { return None; }
    let (mut lo, mut hi) = (K - d, 10.0 * K);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if mid + d - K > bs_call(mid, K, T - T1) { hi = mid; } else { lo = mid; }
    }
    Some(0.5 * (lo + hi) + d)
}
fn exact_american(d: f64, s: f64) -> f64 {                               // road 4: decide once, at the ex-date
    let s0 = s - d * (-R * T1).exp();
    let f = |z: f64| (grow(s0, T1, z) + d - K).max(bs_call(grow(s0, T1, z), K, T - T1)) * phi(z);
    match boundary(d) {
        None => (-R * T1).exp() * simpson(f, -10.0, 10.0, 2000),
        Some(b) => {
            let zb = (((b - d) / s0).ln() - (R - 0.5 * SIG * SIG) * T1) / (SIG * T1.sqrt());
            (-R * T1).exp() * (simpson(&f, -10.0, zb, 1000) + simpson(&f, zb, 10.0, 1000))
        }
    }
}
fn black(d: f64, s: f64) -> (f64, f64, f64) {                            // the better of two Europeans
    let s0 = s - d * (-R * T1).exp();
    let (e1, e2) = (bs_call(s0, K, T), bs_call(s0, K - d, T1));
    (e1.max(e2), e1, e2)
}
fn row(label: &str, v: f64) { println!("{:<40} {:>12.6}", label, v); }
fn rowi(label: &str, v: &str) { println!("{:<40} {:>12}", label, v); }
fn line(label: &str, xs: &[f64], dec: usize) {
    let cells: Vec<String> = xs.iter().map(|x| format!("{:6.*}", dec, x)).collect();
    println!("{}{}", label, cells.join(" "));
}

fn main() {
    println!("no dividend, house call");
    let c_f = bs_call(S, K, T);
    let c_i = by_integral(|x| (x - K).max(0.0), S, T);
    let (c_e, _, _, _) = tree(0.0, 1.0, false, STEPS, S);
    let (c_a, n0, _, _) = tree(0.0, 1.0, true, STEPS, S);
    let p_i = by_integral(|x| (K - x).max(0.0), S, T);
    row("1 formula", c_f); row("2 Simpson average", c_i); row("3 tree, European", c_e);
    row("  tree, American", c_a); rowi("  nodes where exercise wins", &n0.to_string());
    rowi("  nodes checked", &(STEPS * (STEPS + 1) / 2).to_string());
    row("floor S - K e^-rT", S - K * (-R * T).exp()); row("at S=120: live call", bs_call(120.0, K, T));
    row("  thrown away by exercising", bs_call(120.0, K, T) - 20.0);
    println!("one cash dividend at six months");
    row("threshold K(1 - e^-r(T-t1))", threshold());
    let mut res = Vec::new();
    for d in [2.0_f64, 5.0] {
        let (am, cnt, when, low) = tree(d, 1.0, true, STEPS, S);
        let (bl, e1, e2) = black(d, S);
        let ex = exact_american(d, S);
        row(&format!("D={:.0}: escrowed spot S*", d), S - d * (-R * T1).exp());
        row("  European to expiry", e1); row("  European to ex-date, strike K-D", e2);
        row("  Black: the larger", bl); row("  tree, American", am);
        row("  decide-at-ex-date integral", ex); rowi("  nodes where exercise wins", &cnt.to_string());
        if !when.is_empty() {
            rowi("  steps holding them", &format!("{}..{}", when[0], when[when.len() - 1]));
            row("  lowest exercised share", low.unwrap());
        }
        if let Some(b) = boundary(d) { row("  boundary by bisection", b); }
        res.push((am, cnt, when, low, bl, ex));
    }
    row("textbook Black leg, S not S*", bs_call(S, K, T1));
    println!("dividend   European      Black   American    premium");
    for d in [0.0_f64, 2.0, 3.0, 5.0, 8.0] {
        let (bl, e1, _) = black(d, S);
        let am = exact_american(d, S);
        println!("{:8.2} {:10.4} {:10.4} {:10.4} {:10.4}", d, e1, bl, am, ((am - e1) * 1e4).round() / 1e4 + 0.0);
    }
    let (bl120, e120, _) = black(5.0, 120.0);
    let ex120 = exact_american(5.0, 120.0);
    println!("try S=120, D=5: European {:.4}, Black {:.4}, American {:.4}", e120, bl120, ex120);
    println!("the put, no dividend");
    let (pa, pn, _, _) = tree(0.0, -1.0, true, STEPS, S);
    let (pa80, _, pw80, _) = tree(0.0, -1.0, true, 400, 80.0);
    row("European put, Simpson average", p_i); row("  parity: C - P", c_f - p_i);
    row("American put, tree", pa); row("  early-exercise premium", pa - p_i);
    rowi("  nodes where exercise wins", &pn.to_string()); row("floor K e^-rT - S at S=80", K * (-R * T).exp() - 80.0);
    row("American put at S=80, 400 steps", pa80);
    rowi("  exercised at step 0", if pw80.contains(&0) { "yes" } else { "no" });
    let xs = [80.0_f64, 90.0, 100.0, 110.0, 120.0, 130.0];
    line("chart S       ", &xs, 0);
    line("chart live    ", &xs.map(|x| bs_call(x, K, T)), 2);
    line("chart floor   ", &xs.map(|x| (x - K * (-R * T).exp()).max(0.0)), 2);
    line("chart exercise", &xs.map(|x| (x - K).max(0.0)), 2);
    let ys = [95.0_f64, 100.0, 105.0, 110.0, 115.0, 120.0, 125.0];
    line("chart cum     ", &ys, 0);
    line("chart exer D5 ", &ys.map(|y| (y - K).max(0.0)), 2);
    line("chart hold D5 ", &ys.map(|y| bs_call(y - 5.0, K, T - T1)), 2);

    let (a2, a5) = (&res[0], &res[1]);
    assert!((c_i - c_f).abs() < 1e-6 && (c_e - c_f).abs() < 0.005, "three roads to the no-dividend call");
    assert!(n0 == 0 && (c_a - c_e).abs() < 1e-12, "no node exercises; American equals European");
    assert!(a2.1 == 0 && (a2.0 - a2.5).abs() < 0.005, "a 2.00 dividend is below the threshold");
    assert!(a5.1 > 0 && a5.2 == vec![STEPS / 2] && (a5.0 - a5.5).abs() < 0.005, "5.00: exercise only just before ex-date");
    assert!((a5.3.unwrap() - boundary(5.0).unwrap()).abs() < 0.5, "tree's lowest exercise node sits on the boundary");
    assert!(a5.4 <= a5.5 && bl120 <= ex120, "Black is a lower bound");
    assert!(pa > p_i + 0.4 && pn > 0 && (pa80 - 20.0).abs() < 1e-9, "the put carries a premium");
    println!("ALL CHECKS PASS");
}
