// Hardy-Littlewood maximal function -- the Rust twin of the Python check.  std only.
// A rain gauge's record for one day, illustrative: rate in mm per hour, t in hours.
// Mf(x) is the biggest average rate over windows (x - h, x + h).  Same roads, same
// labels, same output as the Python.
type Rec = [(f64, f64, f64)];
const RAIN: [(f64, f64, f64); 4] = [(2.0, 8.0, 1.0), (14.0, 14.1, 60.0), (15.0, 15.1, 60.0), (17.0, 18.0, 10.0)];
const ALPHA: f64 = 8.0;

fn rain(rec: &Rec, a: f64, b: f64) -> f64 {
    let mut s = 0.0;
    for &(st, e, r) in rec { s += r * f64::max(0.0, f64::min(b, e) - f64::max(a, st)); }
    s
}
fn rate(rec: &Rec, x: f64) -> f64 {
    let mut s = 0.0;
    for &(st, e, r) in rec { if st <= x && x < e { s += r; } }
    s
}
fn avg(rec: &Rec, x: f64, h: f64) -> f64 { rain(rec, x - h, x + h) / (2.0 * h) }

fn m(rec: &Rec, x: f64) -> f64 {
    // road 1: between edge distances the average is monotone in h
    let mut left = 0.0;
    for &(st, e, r) in rec { if st < x && x <= e { left += r; } }
    let mut best = (rate(rec, x) + left) / 2.0;
    for &(st, e, _) in rec {
        for h in [(x - st).abs(), (x - e).abs()] {
            if h > 0.0 { best = best.max(avg(rec, x, h)); }
        }
    }
    best
}
fn m_sweep(rec: &Rec, x: f64) -> f64 {
    // road 2: try every h = 0.0005, 0.001, ..., 20 hours
    let mut best = f64::MIN;
    for k in 1..=40000 { best = best.max(avg(rec, x, k as f64 * 0.0005)); }
    best
}
fn tent_area(u: f64) -> f64 {
    let u = u.min(1.0).max(-1.0);
    if u <= 0.0 { (1.0 + u) * (1.0 + u) / 2.0 } else { 1.0 - (1.0 - u) * (1.0 - u) / 2.0 }
}
fn tent(rec: &Rec, x: f64, eps: f64) -> f64 {
    let mut s = 0.0;
    for &(st, e, r) in rec { s += r * (tent_area((x - st) / eps) - tent_area((x - e) / eps)); }
    s
}
fn tent_blend(rec: &Rec, x: f64, eps: f64) -> f64 {
    let n = 4000.0;
    let mut s = 0.0;
    for i in 0..4000 {
        let r = (i as f64 + 0.5) / n;
        s += 2.0 * r * avg(rec, x, eps * (i as f64 + 0.5) / n) / n;
    }
    s
}
fn level_length(rec: &Rec, a: f64, b: f64, alpha: f64) -> f64 {
    let step = 0.001;
    let n = ((b - a) / step).round() as usize;
    let mut c = 0.0;
    for k in 0..n { if m(rec, a + (k as f64 + 0.5) * step) > alpha { c += 1.0; } }
    step * c
}
fn integral(g: &dyn Fn(f64) -> f64, a: f64, b: f64, step: f64) -> f64 {
    let n = ((b - a) / step).round() as usize;
    let mut s = 0.0;
    for k in 0..n { s += g(a + (k as f64 + 0.5) * step); }
    step * s
}
fn lineint(g: &dyn Fn(f64) -> f64, a: f64, b: f64, step: f64) -> f64 {
    // midpoint rule: cells of step on [-6, 30], edges on the jumps; 250 x step beyond
    integral(g, -6.0, 30.0, step) + integral(g, a, -6.0, 250.0 * step) + integral(g, 30.0, b, 250.0 * step)
}
fn cp(p: f64) -> f64 { 2.0 * (3.0 * p / (p - 1.0)).powf(1.0 / p) }
fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let storm = &RAIN[1..3];
    let total = rain(&RAIN, -1e9, 1e9);
    let mut f2 = 0.0;
    for &(s, e, r) in RAIN.iter() { f2 += r * r * (e - s); }
    println!("record: rain {:.4} mm; integral of f^2 {:.4}; ||f||_2 {:.6}", total, f2, f2.sqrt());
    for (x, want) in [(5.0, 28.0 / 26.0), (12.0, 2.0), (14.0, 30.0), (14.05, 60.0), (14.5, 10.0), (17.5, 10.0)] {
        let (mx, sw) = (m(&RAIN, x), m_sweep(&RAIN, x));
        assert!((mx - want).abs() < 1e-9 && -1e-9 < mx - sw && mx - sw < 0.01);
        println!("Mf({}) exact {:.6}, sweep {:.6}, by hand {:.6}", x, mx, sw, want);
    }
    println!("Mf(12): window [6, 18] holds {:.4} mm over 12 h", rain(&RAIN, 6.0, 18.0));
    let w: Vec<f64> = [0.4, 0.5, 0.6, 1.0, 6.0].iter().map(|&h| avg(&RAIN, 14.5, h)).collect();
    println!("Mf(14.5), windows h 0.4 0.5 0.6 1 6: {}", join(&w, 4));
    let xs: Vec<f64> = (0..30).map(|k| 13.05 + 0.1 * k as f64).collect();
    println!("chart, f: {}", join(&xs.iter().map(|&x| rate(&RAIN, x)).collect::<Vec<_>>(), 0));
    println!("chart, Mf: {}", join(&xs.iter().map(|&x| m(&RAIN, x)).collect::<Vec<_>>(), 1));

    let l = level_length(&RAIN, -2.0, 26.0, ALPHA);
    let bound = 3.0 * total / ALPHA;
    assert!(l <= bound && (l - 2.65).abs() < 0.002);
    println!("weak bound, alpha {}: length of Mf > alpha {:.3} h; 3||f||_1/alpha {:.3} h; ratio {:.4}", ALPHA, l, bound, l / bound);
    let (ls, st) = (level_length(storm, 12.0, 17.0, ALPHA), rain(storm, 0.0, 24.0));
    assert!((ls - (1.1 + 2.0 * (6.0 / (2.0 * ALPHA) - 0.1))).abs() < 0.002 && ls > st / ALPHA);
    println!("storm alone: length of Mf > alpha {:.3} h; ||f||_1/alpha {:.3} h; 3||f||_1/alpha {:.3} h", ls, st / ALPHA, 3.0 * st / ALPHA);
    let dmax = 6.0 / (2.0 * ALPHA) - 0.1;
    println!("storm alone, by hand: d < 6/(2 alpha) - 0.1 = {:.3}; set ({:.3}, {:.3}), length {:.3} h", dmax, 14.0 - dmax, 15.1 + dmax, 1.1 + 2.0 * dmax);
    let hb = st / (2.0 * ALPHA);
    println!("storm alone: rain {:.4} mm; windows holding both bursts beat alpha when h < {:.3}: ({:.3}, {:.3})", st, hb, 15.1 - hb, 14.0 + hb);
    println!("storm alone: needed constant at least {:.4}; best possible (11 + sqrt 61)/12 = {:.6}", ls * ALPHA / st, (11.0 + 61f64.sqrt()) / 12.0);

    let msq = |x: f64| { let v = m(&RAIN, x); v * v };
    let norm2sq = |a: f64, b: f64, step: f64| -> f64 {
        // beyond a and b Mf is 14/(18 - x) and 14/(x - 2): exact tails
        assert!((m(&RAIN, b) - 14.0 / (b - 2.0)).abs() < 1e-15 && (m(&RAIN, a) - 14.0 / (18.0 - a)).abs() < 1e-15);
        lineint(&msq, a, b, step) + 196.0 / (b - 2.0) + 196.0 / (18.0 - a)
    };
    let (a, b) = (-980.0, 1000.0);
    let (mf2, mf2b, mf2c) = (norm2sq(a, b, 1e-4), norm2sq(-480.0, 500.0, 1e-4), norm2sq(a, b, 2e-4));
    assert!((mf2 - mf2b).abs() < 1e-5 && (mf2 - mf2c).abs() < 3e-4); // a second cut-off and a doubled step must agree
    println!("integral of Mf^2: step 0.0001 h, cut-off 1000 h {:.4}, cut-off 500 h {:.4}; step 0.0002 h {:.4}", mf2, mf2b, mf2c);
    assert!(mf2.sqrt() <= cp(2.0) * f2.sqrt() && mf2 > f2);
    println!("strong bound, p 2: ||Mf||_2 {:.3}; C_2 ||f||_2 {:.3}; ratio ||Mf||_2/||f||_2 {:.4}; C_2 {:.6}",
             mf2.sqrt(), cp(2.0) * f2.sqrt(), (mf2 / f2).sqrt(), cp(2.0));

    let m1 = |x: f64| m(&RAIN, x);
    let i1 = lineint(&m1, a, b, 1e-4);
    for s in [990.0f64, 4380.0, 438000.0] {
        println!("p 1: integral of Mf over {:.0} h = {:.2} mm; rain {:.0} mm", 2.0 * s, i1 + 28.0 * ((s + 8.0) / 998.0).ln(), total);
    }
    let burst = &RAIN[1..2];
    let grid = integral(&|x: f64| m(burst, x) * m(burst, x), 13.1, 15.0, 0.0005) + 2.0 * 9.0 / 1.0;
    assert!((grid / 360.0 - 1.5).abs() < 1e-4);
    println!("single burst, p 2: ratio^2 grid {:.6}, closed form 1 + 2^(1-p)/(p-1) = 1.500000", grid / 360.0);
    for p in [2.0f64, 1.5, 1.1, 1.01] {
        assert!((cp(p).powf(p) / (6.0 * p * 2f64.powf(p - 1.0) / (p - 1.0)) - 1.0).abs() < 1e-12); // the fold's sum over levels
        println!("single burst, p {}: ||Mf||_p/||f||_p {:.4}; C_p {:.4}", p, (1.0 + 2f64.powf(1.0 - p) / (p - 1.0)).powf(1.0 / p), cp(p));
    }

    let eps_list = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 4.0, 8.0];
    let vals: Vec<f64> = eps_list.iter().map(|&e| tent(&RAIN, 14.5, e)).collect();
    for (&e, &v) in eps_list.iter().zip(vals.iter()) {
        assert!((v - tent_blend(&RAIN, 14.5, e)).abs() < 1e-5 && v <= m(&RAIN, 14.5));
    }
    let mut sup = f64::MIN;
    for k in 1..=2000 { sup = sup.max(tent(&RAIN, 14.5, 0.01 * k as f64)); }
    assert!(sup <= m(&RAIN, 14.5));
    let el: Vec<String> = eps_list.iter().map(|e| format!("{}", e)).collect();
    println!("tent at 14.5, eps {} : {}", el.join(" "), join(&vals, 4));
    println!("tent at 14.5: largest over eps = 0.01..20 {:.4}; Mf(14.5) {:.4}", sup, m(&RAIN, 14.5));
    for x in [5.0, 14.0, 14.05, 14.5] {
        let row: Vec<f64> = [1.0, 0.3, 0.1, 0.03, 0.01].iter().map(|&e| tent(&RAIN, x, e)).collect();
        println!("tent at {}, eps 1 0.3 0.1 0.03 0.01: {}", x, join(&row, 4));
    }
    assert!((tent(&RAIN, 14.0, 0.01) - 30.0).abs() < 1e-9 && (tent(&RAIN, 14.05, 0.01) - 60.0).abs() < 1e-9);

    let mut jumps = 0.0;
    for &(_, _, r) in RAIN.iter() { jumps += r.abs() * 2.0; }
    println!("jumps in the record add up to {:.0} mm/h", jumps);
    for d in [0.01, 0.001] {
        let phi = |x: f64| rain(&RAIN, x - d / 2.0, x + d / 2.0) / d;
        let mut b1 = 0.0;
        for &(s, e, _) in RAIN.iter() {
            for j in [s, e] { b1 += integral(&|x: f64| (rate(&RAIN, x) - phi(x)).abs(), j - d, j + d, d / 200.0); }
        }
        assert!((b1 - jumps * d / 4.0).abs() < 1e-6);
        println!("ramps {} h: ||f - phi||_1 sampled {:.6}, sum of jumps x d/4 {:.6}; bad-set bound at alpha 1: {:.6} h", d, b1, jumps * d / 4.0, 4.0 * b1);
    }
    println!("ALL CHECKS PASS");
}
