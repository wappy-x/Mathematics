// Action-angle variables and KAM -- the same check as the Python, in Rust.  No crates.
// Oscillator H = p^2/2 + 2 q^2 (omega = 2) at E = 1; the 1 m pendulum; the standard map p' = p + K sin t, t' = t + p'.
use std::f64::consts::PI;
const W: f64 = 2.0; const E: f64 = 1.0; const N: usize = 2000; const G: f64 = 9.81;
fn f(q: f64, p: f64) -> (f64, f64) { (p, -W * W * q) }   // Hamilton's equations: q' = p, p' = -4 q
fn simpson(g: &dyn Fn(f64) -> f64) -> f64 {
    let n = 200; let s: f64 = (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * PI / 2.0 / n as f64)).sum();
    PI / 6.0 / n as f64 * s
}
fn act(k: f64) -> f64 { 8.0 / PI * G.sqrt() * k * k * simpson(&|u: f64| u.cos() * u.cos() / (1.0 - k * k * u.sin() * u.sin()).sqrt()) }
fn pend(deg: f64) -> (f64, f64, f64, f64) {              // k = sin(amplitude / 2); returns J, dE/dJ, 2 pi / T, T
    let (k, dk) = ((deg * PI / 360.0).sin(), 1e-5);
    let t = 4.0 / G.sqrt() * simpson(&|u: f64| 1.0 / (1.0 - k * k * u.sin() * u.sin()).sqrt());
    (act(k), 2.0 * G * (4.0 * k * dk) / (act(k + dk) - act(k - dk)), 2.0 * PI / t, t)
}
fn run(kk: f64, mut x: f64, mut y: f64, n: usize) -> (f64, f64, f64, f64, f64) {   // map steps with tangent matrix
    let (mut a, mut b, mut c, mut d) = (1.0, 0.0, 0.0, 1.0);
    for _ in 0..n { let kc = kk * x.cos(); y += kk * x.sin(); x += y; c += kc * a; d += kc * b; a += c; b += d; }
    (x, y, a, b, d)
}
fn residue(kk: f64, m: f64, n: usize, mut p: f64) -> (f64, f64, f64) {   // symmetric orbit through t = pi
    for _ in 0..40 {
        let (x, y, _a, b, d) = run(kk, PI, p, (n + 1) / 2);
        let (r, s) = if n % 2 == 0 { (x - PI - PI * m, b) } else { (2.0 * x - y - 2.0 * PI * (1.0 + m), 2.0 * b - d) };
        p -= (r / s).clamp(-0.02, 0.02);
    }
    let (x, y, a, _b, d) = run(kk, PI, p, n); (p, (2.0 - a - d) / 4.0, (x - PI - 2.0 * PI * m).abs() + (y - p).abs())
}
fn critical(m: f64, n: usize) -> (f64, f64) {             // follow the orbit up to K = 0.95, then bisect on R = 1/4
    let (mut p, mut lo, mut hi) = (0.0f64, 0.95, 1.0);
    for i in 0..96 { p = residue(i as f64 / 100.0, m, n, if p == 0.0 { 2.0 * PI * m / n as f64 } else { p }).0; }
    for _ in 0..40 { let mid = (lo + hi) / 2.0; let r = residue(mid, m, n, p).1; if 0.0 <= r && r < 0.25 { lo = mid } else { hi = mid } }
    (lo, p)
}
fn drift(kk: f64, mut t: f64, mut p: f64) -> (usize, f64, f64) {   // stop if |p| passes 2 pi
    let (steps, mut lo, mut hi) = (100000, 9.0f64, -9.0f64);
    for i in 0..steps {
        p += kk * t.sin(); t = (t + p).rem_euclid(2.0 * PI); lo = lo.min(p); hi = hi.max(p); if p.abs() > 2.0 * PI { return (i + 1, lo, hi); }
    }
    (steps, lo, hi)
}
fn main() {
    let (h, qm, pm) = (PI / N as f64, (2.0 * E).sqrt() / W, (2.0 * E).sqrt());
    let (mut q, mut p, mut lp, mut gap, mut th_q) = (0.0, pm, 0.0, 0.0f64, 0.0);
    for i in 1..=N {                                     // RK4 round one orbit, tracking the loop and the angle
        let (a1, b1) = f(q, p); let (a2, b2) = f(q + h / 2.0 * a1, p + h / 2.0 * b1); let (a3, b3) = f(q + h / 2.0 * a2, p + h / 2.0 * b2);
        let (a4, b4) = f(q + h * a3, p + h * b3); let q2 = q + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4);
        let p2 = p + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4); lp += h * p2 * p2; q = q2; p = p2;
        let th = (W * q).atan2(p).rem_euclid(2.0 * PI); gap = gap.max(((th - W * i as f64 * h + PI).rem_euclid(2.0 * PI) - PI).abs()); if i == N / 4 { th_q = th; }
    }
    let j = lp / (2.0 * PI); println!("oscillator, mass 1 kg, stiffness {} N/m, omega = 2, E = {}: q_max = {:.4}, p_max = {:.4}, period {:.4} s", W * W, E, qm, pm, 2.0 * PI / W);
    println!("area: ellipse pi q_max p_max = {:.6}, RK4 loop sum of p dq = {:.6}; J = {:.6}, omega J = {:.6}", PI * qm * pm, lp, j, W * j);
    println!("angle atan2(omega q, p): at a quarter period {:.6} rad, largest gap from 2 t over the orbit {:.1e} rad", th_q, gap);
    println!("mistakes: no 2 pi, J = {:.4}, omega J = {:.4}; omega^2 = 2, E/omega = {:.4}; half loop, J = {:.4}", lp, W * lp, E / 2f64.sqrt(), j / 2.0);
    let pd: Vec<(f64, f64, f64, f64)> = [20.0, 60.0, 120.0].iter().map(|&d| pend(d)).collect();
    for (d, &(jj, de, wt, t)) in [20, 60, 120].iter().zip(pd.iter()) {
        println!("pendulum 1 m, {} deg: J = {:.4}, omega = dE/dJ = {:.4}, 2 pi/T = {:.4} rad/s, T = {:.3} s", d, jj, de, wt, t);
    }
    println!("small swings: omega = sqrt(g/l) = {:.4} rad/s, T = {:.3} s", G.sqrt(), 2.0 * PI / G.sqrt());
    let (fib, gold) = ([(5, 8), (8, 13), (13, 21), (21, 34), (34, 55), (55, 89)], (5f64.sqrt() - 1.0) / 2.0);
    let gs: Vec<String> = fib[3..].iter().map(|&(m, n)| format!("{}/{} {:.4}", m, n, (n * n) as f64 * (gold - m as f64 / n as f64).abs())).collect();
    println!("golden mean {:.6}: n^2 |gold - m/n| = {} (1/sqrt5 = {:.4})", gold, gs.join(" "), 1.0 / 5f64.sqrt());
    let crit: Vec<(f64, f64)> = fib.iter().map(|&(m, n)| critical(m as f64, n)).collect();
    let cs: Vec<String> = fib.iter().zip(crit.iter()).map(|(&(m, n), c)| format!("{}/{} {:.6}", m, n, c.0)).collect();
    println!("K where the residue reaches 1/4: {}", cs.join(" "));
    for (&(m, n), &(_, p0)) in fib.iter().zip(crit.iter()).skip(3) {
        let rs: Vec<String> = (0..9).map(|i| format!("{:.3}", residue(0.9 + i as f64 / 100.0, m as f64, n, p0).1)).collect();
        println!("chart, residue {}/{} at K = 0.90..0.98: {}", m, n, rs.join(" "));
    }
    for &(lab, kk, t0, p0) in &[("0.5, start (0.0, 1.0)", 0.5, 0.0, 1.0), ("0.9, start (0.001, 0.0)", 0.9, 0.001, 0.0), ("1.0, start (0.001, 0.0)", 1.0, 0.001, 0.0), ("1.2, start (0.001, 0.0)", 1.2, 0.001, 0.0)] {
        let (s, lo, hi) = drift(kk, t0, p0); println!("standard map K = {}: {} steps, p from {:.4} to {:.4}", lab, s, lo, hi);
    }
    let es: Vec<String> = [1.0, 1.1, 1.2].iter().map(|&kk| format!("K = {:.1}: {}", kk, (0..20).filter(|&i| drift(kk, 0.001 + i as f64 * 1e-13, 0.0).0 < 100000).count())).collect();
    println!("of 20 starts 1e-13 apart from (0.001, 0.0), passing |p| = 2 pi in 100000 kicks: {}", es.join(", "));
    assert!((lp - PI * qm * pm).abs() < 1e-9 && (j - E / W).abs() < 1e-9 && gap < 1e-9);   // loop area = 2 pi E / omega; angle turns at omega
    assert!(pd.iter().all(|x| (x.1 / x.2 - 1.0).abs() < 1e-6) && pd[0].1 > pd[1].1 && pd[1].1 > pd[2].1);   // dE/dJ = 2 pi/T
    assert!(crit[2..].iter().all(|c| (c.0 - 0.9716).abs() < 0.0015) && (crit[4].0 - crit[5].0).abs() < 1e-4);   // orders agree
    assert!(drift(0.9, 0.001, 0.0).2 < PI && PI < drift(1.2, 0.001, 0.0).2);   // fenced in below K_c, escapes above
    println!("ALL CHECKS PASS");
}
