// Orthonormal bases and Parseval -- the same check as the Python, in Rust.  No crates.
// The clip: one second of a 100 Hz tone at full scale 1, its negative half cut off
// by a rectifier: f(t) = max(sin(2 pi 100 t), 0).  The basis on [0, 1): the constant
// 1, and sqrt2 cos(2 pi n t), sqrt2 sin(2 pi n t) for n = 1, 2, 3, ...  Every infinite
// sum here is cut at K terms; the integrals are Simpson's rule written out, with
// grid points on every corner of the clip, where the tone crosses zero.
use std::f64::consts::PI;
const F0: f64 = 100.0;
const CELLS: usize = 100000;                     // 1000 cells per 100 Hz cycle

fn clip(t: f64) -> f64 { (2.0 * PI * F0 * t).sin().max(0.0) }
fn other(t: f64) -> f64 { (-(2.0 * PI * F0 * t).sin()).max(0.0) }   // the cut-off half
fn integral(g: &dyn Fn(f64) -> f64) -> f64 {     // Simpson over one second
    let mut s = 0.0;
    for i in 0..=CELLS {
        let w = if i == 0 || i == CELLS { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * g(i as f64 / CELLS as f64);
    }
    s / (3 * CELLS) as f64
}
fn e(kind: &str, n: f64, t: f64) -> f64 {        // one member of the basis
    let r2 = 2f64.sqrt();
    match kind { "const" => 1.0, "cos" => r2 * (2.0 * PI * n * t).cos(), _ => r2 * (2.0 * PI * n * t).sin() }
}
fn coef(g: &dyn Fn(f64) -> f64, kind: &str, n: f64) -> f64 { integral(&|t| e(kind, n, t) * g(t)) }
fn show(label: &str, value: String) { println!("{:<52}{}", label, value); }
fn z(v: f64) -> f64 { if v.abs() > 5e-7 { v } else { 0.0 } }   // never -0.000000
fn exact(kind: &str, n: usize) -> f64 {          // closed-form coefficients of the clip
    let r2 = 2f64.sqrt();
    match kind {
        "const" => 1.0 / PI,
        "sin" => if n == 100 { r2 / 4.0 } else { 0.0 },
        _ => { let k = (n / 200) as f64;
               if n % 200 == 0 { -r2 / (PI * (4.0 * k * k - 1.0)) } else { 0.0 } }
    }
}
fn pair_sq(k: usize) -> f64 { let k = k as f64; 2.0 / (PI.powi(2) * (4.0 * k * k - 1.0).powi(2)) }
fn ledger(kk: usize, konst: bool) -> f64 {
    let mut s = (if konst { 1.0 / PI.powi(2) } else { 0.0 }) + 0.125;
    let mut tail = 0.0;
    for k in 1..=kk { tail += pair_sq(k); }
    s += tail; s
}
fn leftover(kk: usize) -> f64 {                  // energy of f - f_J, integrated directly
    integral(&|t| {
        let w = 2.0 * PI * F0 * t;
        let mut part = 0.0;
        for k in 1..=kk { let kf = k as f64; part += (2.0 * kf * w).cos() / (4.0 * kf * kf - 1.0); }
        let s = 1.0 / PI + 0.5 * w.sin() - (2.0 / PI) * part;
        (clip(t) - s).powi(2)
    })
}
fn main() {
    let r2 = 2f64.sqrt();
    // ---- 1. the finite rehearsal: 8 samples of one cycle, 8 perpendicular patterns ----
    let n = 8usize;
    let x: Vec<f64> = (0..n).map(|j| (2.0 * PI * j as f64 / n as f64).sin().max(0.0)).collect();
    let ip8 = |u: &Vec<f64>, v: &Vec<f64>| u.iter().zip(v).map(|(a, b)| a * b).sum::<f64>() / n as f64;
    let mut pats: Vec<(String, Vec<f64>)> = vec![("constant".to_string(), vec![1.0; n])];
    for k in 1..n / 2 {
        let a = 2.0 * PI * k as f64 / n as f64;
        pats.push((format!("cos {}", k), (0..n).map(|j| r2 * (a * j as f64).cos()).collect()));
        pats.push((format!("sin {}", k), (0..n).map(|j| r2 * (a * j as f64).sin()).collect()));
    }
    pats.push(("alternating".to_string(), (0..n).map(|j| if j % 2 == 0 { 1.0 } else { -1.0 }).collect()));
    let mut worst: f64 = 0.0;
    for (a, p) in &pats { for (b, q) in &pats {
        worst = worst.max((ip8(p, q) - if a == b { 1.0 } else { 0.0 }).abs()); } }
    let c8: Vec<f64> = pats.iter().map(|(_, p)| ip8(p, &x)).collect();
    let rebuilt: Vec<f64> = (0..n).map(|j| c8.iter().zip(&pats).map(|(c, (_, p))| c * p[j]).sum()).collect();
    println!("samples, one cycle   {}", x.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(" "));
    let nz: Vec<String> = pats.iter().zip(&c8).filter(|(_, c)| c.abs() > 1e-12)
        .map(|((nm, _), c)| format!("{} {:.6}", nm, c)).collect();
    println!("nonzero coefficients {}", nz.join(", "));
    let sq: Vec<String> = c8.iter().filter(|c| c.abs() > 1e-12).map(|c| format!("{:.6}", c * c)).collect();
    println!("their squares        {}", sq.join(", "));
    let led8: f64 = c8.iter().map(|c| c * c).sum();
    show("rehearsal: energy, mean of squared samples", format!("{:.6}", ip8(&x, &x)));
    show("rehearsal: ledger, sum of squared coefficients", format!("{:.6}", led8));
    assert!(worst < 1e-12);                                      // the 8 patterns are orthonormal
    assert!((led8 - 0.25).abs() < 1e-12);                        // Pythagoras in 8 dimensions
    assert!(rebuilt.iter().zip(&x).all(|(r, v)| (r - v).abs() < 1e-12));   // rebuild the samples

    // ---- 2. the whole clip: coefficients by integration against the closed form ----
    let energy = integral(&|t| clip(t).powi(2));
    show("energy of the clip, by integration", format!("{:.6}", energy));
    println!("basis member      by integration   closed form   share of energy");
    for (kind, hz) in [("const", 0usize), ("sin", 100), ("cos", 100), ("sin", 150),
                       ("cos", 200), ("cos", 400), ("cos", 600)] {
        let (num, ex) = (coef(&clip, kind, hz as f64), exact(kind, hz));
        println!("{:<18}{:>13.6}{:>14.6}{:>14.3} %", format!("{} {} Hz", kind, hz), z(num), ex, 100.0 * ex * ex / 0.25);
        assert!((num - ex).abs() < 1e-9);                        // integration agrees with closed form
    }
    assert!((energy - 0.25).abs() < 1e-9);

    // ---- 3. Bessel's ledger, cut after the cosine at 200J Hz, against the leftover ----
    for kk in [0usize, 1, 2] {
        let (gap, left) = (0.25 - ledger(kk, true), leftover(kk));
        show(&format!("J = {}: ledger, gap, leftover energy", kk), format!("{:.6}  {:.6}  {:.6}", ledger(kk, true), gap, left));
        assert!((gap - left).abs() < 1e-8);                      // energy = ledger + leftover
    }
    let ks = [1usize, 2, 4, 8, 16, 32, 64];
    println!("chart, highest Hz kept {}", ks.iter().map(|k| (200 * k).to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, log10 of gap    {}", ks.iter().map(|&k| format!("{:.2}", (0.25 - ledger(k, true)).log10())).collect::<Vec<_>>().join(", "));
    let g64 = 0.25 - ledger(64, true);
    show("J^3 x gap at J = 64; the rate 1/(24 pi^2)", format!("{:.6}  {:.6}", 64f64.powi(3) * g64, 1.0 / (24.0 * PI.powi(2))));
    let mut tail = 0.0;
    for k in 1..=100000u64 { let kf = k as f64; tail += 1.0 / (4.0 * kf * kf - 1.0).powi(2); }
    show("sum of 1/(4k^2-1)^2 to 100000; (pi^2-8)/16", format!("{:.12}  {:.12}", tail, (PI.powi(2) - 8.0) / 16.0));
    assert!((tail - (PI.powi(2) - 8.0) / 16.0).abs() < 1e-12);   // Parseval's equality, by series
    assert!((64f64.powi(3) * g64 * 24.0 * PI.powi(2) - 1.0).abs() < 0.05);

    // ---- 4. an incomplete set: drop the constant ----
    for kk in [1usize, 64] {
        show(&format!("constant dropped, J = {}: ledger, gap", kk), format!("{:.6}  {:.6}", ledger(kk, false), 0.25 - ledger(kk, false)));
    }
    let dc = |_t: f64| 1.0;
    show("steady level 1: <e, 1> for cos 200, sin 100", format!("{:.6}  {:.6}", z(coef(&dc, "cos", 200.0)), z(coef(&dc, "sin", 100.0))));
    assert!(0.25 - ledger(1, false) > 0.25 - ledger(64, false) && 0.25 - ledger(64, false) > 1.0 / PI.powi(2));   // never below
    assert!((0.25 - ledger(64, false) - 1.0 / PI.powi(2)).abs() < 1e-7);   // the steady part's energy

    // ---- 5. inner products survive: the two halves never overlap in time ----
    let ip_time = integral(&|t| clip(t) * other(t));
    let oth = (1.0 / PI) * (1.0 / PI) + (r2 / 4.0) * (-r2 / 4.0);   // constant, sin 100
    let ip_coef = |kk: usize| { let mut s = 0.0; for k in 1..=kk { s += pair_sq(k); } oth + s };
    show("<f, other half>: in time; by coefficients J=1, 64", format!("{:.6}  {:.6}  {:.6}", z(ip_time), z(ip_coef(1)), z(ip_coef(64))));
    assert!((coef(&other, "const", 0.0) - 1.0 / PI).abs() < 1e-6 && (coef(&other, "sin", 100.0) + r2 / 4.0).abs() < 1e-6);
    assert!(ip_coef(64).abs() < 1e-7);

    // ---- 6. Riesz-Fischer: which coefficient lists make a signal ----
    let (mut a, mut b) = (0.0, 0.0);
    for kk in [10usize, 100, 1000, 10000] {
        a = 0.0; b = 0.0;
        for m in 1..=kk { let mf = m as f64; a += 1.0 / mf.powi(2); b += 1.0 / mf; }
        show(&format!("energy of S_K, K = {}: list 1/n, list 1/sqrt n", kk), format!("{:.6}  {:.6}", a, b));
    }
    let (mut da, mut db) = (0.0, 0.0);
    for m in 1001..=2000 { let mf = m as f64; da += 1.0 / mf.powi(2); db += 1.0 / mf; }
    show("||S_2000 - S_1000||^2: list 1/n, list 1/sqrt n", format!("{:.6}  {:.6}", da, db));
    assert!((a - PI.powi(2) / 6.0).abs() < 1.0001e-4 && (db - 2f64.ln()).abs() < 1e-3);
    let _ = b;

    // ---- 7. what breaks ----
    let mut amps = 1.0 / PI + r2 / 4.0;
    for k in 1..=100000u64 { let kf = k as f64; amps += r2 / (PI * (4.0 * kf * kf - 1.0)); }
    let sizes = 1.0 / PI + r2 / 4.0 + r2 / (2.0 * PI);   // telescoping: sum of 1/(4k^2-1) is 1/2
    let mut plain = integral(&clip).powi(2) + integral(&|t| (2.0 * PI * F0 * t).sin() * clip(t)).powi(2);
    for n in (200..=12800).step_by(200) { plain += integral(&|t| (2.0 * PI * n as f64 * t).cos() * clip(t)).powi(2); }
    show("no sqrt2: ledger, plain cos and sin to 12800 Hz", format!("{:.6}", plain));
    show("adding coefficient sizes, not squares", format!("{:.6}", sizes));
    assert!((amps - sizes).abs() < 1e-5);
    assert!((plain - 1.0 / PI.powi(2) - 0.5 * (0.25 - 1.0 / PI.powi(2))).abs() < 1e-6);   // shares halved
    println!("ALL CHECKS PASS");
}
