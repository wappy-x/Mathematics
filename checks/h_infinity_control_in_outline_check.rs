// H-infinity design in outline -- the same check as h_infinity_control_in_outline_check.py.
// Standard library only, no crates.  Complex numbers are a small struct written out.
// Conveyor: drive torque u (N m) -> roller speed v (rad/s).  P(s) = 1/((J s + b)(tau s + 1)).
// A load bump d = 0.5 sin(2 pi 2 t) N m acts on the belt, so it reaches the speed through 1/(J s + b) times S.
// Controller family: K(s) = Kp + Ki/s + Kr s/(s^2 + w0^2), with w0 the bump's 2 Hz in rad/s.
use std::f64::consts::PI;
const J0: f64 = 0.20; const JH: f64 = 0.30; const JF: f64 = 0.40; const B: f64 = 0.40; const TAU: f64 = 0.02; const D0: f64 = 0.5;
const W0: f64 = 4.0 * PI; const WB: f64 = 4.0; const M: f64 = 2.0; const A: f64 = 0.01;
type Sp = (f64, f64, f64); // (zd, wt, wu): peak damping (0 = no peak), model-error weight on or off, torque weight
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn ab(a: C) -> f64 { a.re.hypot(a.im) }
fn wp(w: f64, zd: f64) -> f64 {
    let v = WB.hypot(w / M) / (WB * A).hypot(w);
    if zd != 0.0 { v * (W0 * W0 - w * w).hypot(2.0 * 0.5 * W0 * w) / (W0 * W0 - w * w).hypot(2.0 * zd * W0 * w) } else { v }
}
fn wm(w: f64) -> f64 { 0.5 * w / w.hypot(1.0) }
fn lp(w: f64, k: &[f64; 3], j: f64) -> [f64; 4] {
    let (kp, ki, kr) = (k[0], k[1], k[2]);
    let q = if kr != 0.0 { W0 * W0 - w * w } else { 1.0 };
    let dp = mul(c(B, j * w), c(1.0, TAU * w));
    let (nk, dk) = (c(ki * q - kr * w * w, kp * w * q), c(0.0, w * q));
    let dd = ab(add(mul(dk, dp), nk));
    [ab(mul(dk, dp)) / dd, ab(nk) / dd, ab(mul(nk, dp)) / dd, ab(mul(dk, c(1.0, TAU * w))) / dd]
}
fn stack(w: f64, k: &[f64; 3], sp: Sp) -> f64 {
    let l = lp(w, k, J0);
    let (a, b, cc) = (wp(w, sp.0) * l[0], sp.2 * l[2], sp.1 * wm(w) * l[1]);
    (a * a + b * b + cc * cc).sqrt()
}
fn norm(k: &[f64; 3], sp: Sp, grid: &[f64]) -> (f64, f64) { peak(grid, |w| stack(w, k, sp)) }
fn design(sp: Sp, res: bool, fine: &[f64], coarse: &[f64]) -> [f64; 3] {
    let (mut g, mut k) = (f64::MAX, [0.0; 3]);
    for a in 0..13 { for b in 0..13 { for cc in 0..(if res { 11 } else { 1 }) {
        let t = [a as f64, b as f64, cc as f64 * 4.0];
        let v = norm(&t, sp, coarse).0;
        if v < g { g = v; k = t; }
    } } }
    g = norm(&k, sp, fine).0;
    let mut step = 0.5;
    while step > 1e-3 {
        let mut moved = false;
        for i in 0..(if res { 3 } else { 2 }) {
            for d in [step, -step] {
                let mut y = k; y[i] = (y[i] + d).max(0.0);
                let gy = norm(&y, sp, fine).0;
                if gy < g { g = gy; k = y; moved = true; }
            }
        }
        if !moved { step /= 2.0; }
    }
    k
}
fn floor(w: f64, sp: Sp) -> f64 { // Step 3: the least the stack can be at w over every complex S, since S + T = 1 and K S = T/P
    let (a, ct, cu) = (wp(w, sp.0), sp.1 * wm(w), sp.2 * ab(mul(c(B, J0 * w), c(1.0, TAU * w))));
    let cc = (cu * cu + ct * ct).sqrt();
    a * cc / (a * a + cc * cc).sqrt()
}
fn brute(w: f64, sp: Sp) -> f64 { // the same least value by brute force: the stack at each S on a grid, then a 100x finer grid
    let pinv = mul(c(B, J0 * w), c(1.0, TAU * w)); // 1/P at jw, so K S = T/P = (1 - S)/P
    let f = |x: f64, y: f64| { let (a, b, cc) = (wp(w, sp.0) * x.hypot(y), sp.2 * ab(mul(c(1.0 - x, -y), pinv)), sp.1 * wm(w) * (1.0 - x).hypot(y)); (a * a + b * b + cc * cc).sqrt() };
    let (mut v, mut x, mut y) = (f64::MAX, 0.5, 0.0);
    for h in [0.01, 1e-4] { let (x0, y0) = (x, y); v = f64::MAX; for i in -100..=100 { for k in -100..=100 {
        let (xi, yk) = (x0 + i as f64 * h, y0 + k as f64 * h); let u = f(xi, yk); if u < v { v = u; x = xi; y = yk; } } } }
    v
}
fn simulate(k: &[f64; 3], j: f64, wd: f64) -> f64 {
    let (kp, ki, kr) = (k[0], k[1], k[2]);
    let (t_end, dt) = (30.0f64, 1e-3);
    let f = |t: f64, x: [f64; 5]| -> [f64; 5] {
        [(kp * -x[1] + ki * x[2] + kr * x[4] - x[0]) / TAU, (x[0] - B * x[1] - D0 * (wd * t).sin()) / j, -x[1], x[4], -W0 * W0 * x[3] - x[1]]
    };
    let mv = |x: [f64; 5], k: [f64; 5], h: f64| -> [f64; 5] { let mut y = x; for i in 0..5 { y[i] = x[i] + h * k[i]; } y };
    let (mut x, mut lo, mut hi, n) = ([0.0f64; 5], 0.0f64, 0.0f64, (t_end / dt).round() as usize);
    for i in 0..n {
        let t = i as f64 * dt;
        let k1 = f(t, x); let k2 = f(t + dt / 2.0, mv(x, k1, dt / 2.0));
        let k3 = f(t + dt / 2.0, mv(x, k2, dt / 2.0)); let k4 = f(t + dt, mv(x, k3, dt));
        for m in 0..5 { x[m] = x[m] + dt / 6.0 * (k1[m] + 2.0 * k2[m] + 2.0 * k3[m] + k4[m]); }
        if i >= n - 5000 { lo = lo.min(x[1]); hi = hi.max(x[1]); }
    }
    (hi - lo) / 2.0
}
fn routh(k: &[f64; 3], j: f64) -> f64 {
    let (kp, ki, kr) = (k[0], k[1], k[2]);
    let a = [j * TAU, j + B * TAU, B + j * TAU * W0 * W0 + kp, (j + B * TAU) * W0 * W0 + ki + kr, (B + kp) * W0 * W0, ki * W0 * W0];
    let mut rows: Vec<Vec<f64>> = vec![vec![a[0], a[2], a[4]], vec![a[1], a[3], a[5]]];
    while rows.len() < a.len() {
        let r0 = rows[rows.len() - 2].clone();
        let mut r1 = rows[rows.len() - 1].clone(); r1.push(0.0);
        rows.push((0..r0.len() - 1).map(|i| (r1[0] * r0[i + 1] - r0[0] * r1[i + 1]) / r1[0]).collect());
    }
    rows.iter().map(|r| r[0]).fold(f64::MAX, f64::min)
}
fn peak<F: Fn(f64) -> f64>(fine: &[f64], f: F) -> (f64, f64) {
    let mut best = (f64::MIN, 0.0);
    for &w in fine { let v = f(w); if v >= best.0 { best = (v, w); } }
    best
}
fn main() {
    let fine: Vec<f64> = (0..=2000).map(|i| 10f64.powf(-2.0 + (5 * i) as f64 / 2000.0)).collect();
    let coarse: Vec<f64> = fine.iter().step_by(8).cloned().collect();
    let (flat, pk): (Sp, Sp) = ((0.0, 1.0, 0.05), (0.1, 1.0, 0.05));
    println!("conveyor: J = {:.2} to {:.2} kg m^2, b = {:.2} N m s/rad, tau = {:.2} s; bump {:.1} N m at 2 Hz = {:.4} rad/s", J0, JF, B, TAU, D0, W0);
    let ga = B.hypot(J0 * W0);
    println!("no control: |{:.2} + {:.4}j| = {:.4}; ripple = {:.1}/{:.4} = {:.4} rad/s", B, J0 * W0, ga, D0, ga, D0 / ga);
    println!("weights: M = {:.0}, wB = {:.0} rad/s, A = {:.2}; 2 Hz peak {:.0}x (zn = 0.5, zd = 0.1); W_U = 0.05, 1/W_U = {:.0} N m per rad/s", M, WB, A, 0.5 / 0.1, 1.0 / 0.05);
    let (ka, kb) = (design(flat, true, &fine, &coarse), design(pk, true, &fine, &coarse));
    let dense: Vec<f64> = (0..=8000).map(|i| 10f64.powf(-2.0 + (5 * i) as f64 / 8000.0)).collect();
    for (name, k, sp) in [("A, flat weight ", ka, flat), ("B, 2 Hz peak   ", kb, pk)] {
        let ((g, wg), (fl, wf)) = (norm(&k, sp, &fine), peak(&fine, |w| floor(w, sp)));
        println!("design {}: Kp = {:.3}, Ki = {:.3}, Kr = {:.3}; gamma = {:.4} at {:.2} rad/s; floor {:.4} at {:.2} rad/s", name, k[0], k[1], k[2], g, wg, fl, wf);
        let (gd, bf) = (norm(&k, sp, &dense).0, brute(wf, sp));
        println!("  floor at {:.2} rad/s: formula {:.4}, brute force over complex S {:.4}", wf, fl, bf);
        assert!(fl <= g && g < 1.0 && (gd - g).abs() < 1e-3 && (bf - fl).abs() < 1e-5);
    }
    assert!((peak(&fine, |w| floor(w, flat)).0 - 1.0 / M).abs() < 1e-3);
    let l = lp(W0, &ka, J0);
    let (kac, da) = (c(ka[0], -ka[1] / W0), mul(c(B, J0 * W0), c(1.0, TAU * W0))); let (p, n2) = (mul(kac, c(da.re, -da.im)), da.re * da.re + da.im * da.im); let la = c(p.re / n2, p.im / n2);
    println!("hand A at 2 Hz: K = {:.4} {:+.4}j, bottom = {:.4} {:+.4}j, L = K/bottom = {:.5} {:+.5}j, |L| = {:.4}, |K| = {:.4}, |1 + L| = {:.5}", kac.re, kac.im, da.re, da.im, la.re, la.im, ab(la), ab(kac), ab(add(c(1.0, 0.0), la)));
    println!("hand A at 2 Hz: |S| = {:.4}, |T| = {:.4}, |K S| = {:.4}, |W_P| = {:.4}, |W| = {:.4}", l[0], l[1], l[2], wp(W0, 0.0), wm(W0));
    let (a2, b2, c2) = (wp(W0, 0.0) * l[0] * (wp(W0, 0.0) * l[0]), 0.05 * l[2] * (0.05 * l[2]), wm(W0) * l[1] * (wm(W0) * l[1]));
    println!("hand A at 2 Hz: stack = sqrt({:.4} + {:.4} + {:.4}) = {:.4}; ripple = {:.1} x {:.4}/{:.4} = {:.4} rad/s", a2, b2, c2, (a2 + b2 + c2).sqrt(), D0, l[0], ga, D0 * l[3]);
    assert!((l[0] / ga - l[3]).abs() < 1e-12 && ((a2 + b2 + c2).sqrt() - stack(W0, &ka, flat)).abs() < 1e-12 && (ab(add(c(1.0, 0.0), la)) * l[0] - 1.0).abs() < 1e-12 && ab(add(mul(la, da), c(-kac.re, -kac.im))) < 1e-12);
    let l = lp(W0, &kb, J0);
    println!("hand B at 2 Hz: |S| = {:.4}, |T| = {:.4}, |K S| = {:.4}, |W_P| = {:.4}; stack = {:.4}", l[0], l[1], l[2], wp(W0, 0.1), stack(W0, &kb, pk));
    println!("chart: w (rad/s), allowed 1/|W_P|, |S| A, |S| B empty, |S| B full");
    for w in [1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 11.0, W0, 14.0, 16.0, 20.0, 40.0, 100.0] {
        println!("chart, {:7.3}, {:.3}, {:.3}, {:.3}, {:.3}", w, 1.0 / wp(w, 0.1), lp(w, &ka, J0)[0], lp(w, &kb, J0)[0], lp(w, &kb, JF)[0]);
    }
    for (name, k) in [("A", ka), ("B", kb)] {
        for j in [J0, JF] {
            let (rf, rt) = (D0 * lp(W0, &k, j)[3], simulate(&k, j, W0));
            println!("ripple {}, J = {:.2}: formula {:.4} rad/s, RK4 after 30 s {:.4} rad/s", name, j, rf, rt);
            assert!((rf - rt).abs() < 1e-4);
        }
    }
    let rt: Vec<String> = [J0, JH, JF].iter().map(|&j| format!("J = {:.2}: {:.4}", j, routh(&kb, j))).collect();
    println!("Routh, design B, lowest first-column entry: {}", rt.join(", "));
    assert!([J0, JH, JF].iter().all(|&j| routh(&kb, j) > 0.0));
    let rs = peak(&fine, |w| wm(w) * lp(w, &kb, J0)[1]);
    let rp = peak(&fine, |w| wp(w, 0.1) * lp(w, &kb, J0)[0] + wm(w) * lp(w, &kb, J0)[1]);
    let real: Vec<(f64, f64)> = [J0, JH, JF].iter().map(|&j| peak(&fine, |w| wp(w, 0.1) * lp(w, &kb, j)[0])).collect();
    println!("design B: peak |W T| = {:.4} at {:.2} rad/s; peak |W_P S| + |W T| = {:.4} at {:.2} rad/s; sqrt(2) x gamma = {:.4}", rs.0, rs.1, rp.0, rp.1, 2f64.sqrt() * norm(&kb, pk, &fine).0);
    let rl: Vec<String> = real.iter().map(|p| format!("{:.4} at {:.2} rad/s", p.0, p.1)).collect();
    println!("design B, real belts, peak |W_P S_J|: {}", rl.join(", "));
    assert!(rs.0 < norm(&kb, pk, &fine).0 && norm(&kb, pk, &fine).0 < 1.0 && 1.0 < rp.0 && rp.0 < 2f64.sqrt() && real[2].0 > 1.0);
    let g11: Vec<f64> = fine.iter().step_by(200).cloned().collect();
    println!("wrong: 11-point grid gives gamma = {:.4}", norm(&kb, pk, &g11).0);
    let kpi = design(pk, false, &fine, &coarse); let (gpi, wpi) = norm(&kpi, pk, &fine);
    let hi: Vec<f64> = fine.iter().cloned().filter(|&w| w > 30.0).collect(); let hump = peak(&hi, |w| stack(w, &kpi, pk));
    println!("wrong: peaked weight, plain PI: Kp = {:.3}, Ki = {:.3}; gamma = {:.4} at {:.2} rad/s, {:.4} at {:.2} rad/s; at 2 Hz |S| = {:.4}, stack {:.4}", kpi[0], kpi[1], gpi, wpi, hump.0, hump.1, lp(W0, &kpi, J0)[0], stack(W0, &kpi, pk));
    let now: Sp = (0.1, 0.0, 0.05);
    let kw = design(now, true, &fine, &coarse);
    println!("wrong: no model-error weight: Kp = {:.3}, Ki = {:.3}, Kr = {:.3}; gamma {:.4}, with W restored {:.4}", kw[0], kw[1], kw[2], norm(&kw, now, &fine).0, norm(&kw, pk, &fine).0);
    assert!(hump.0 > 1.0 && 1.0 > lp(W0, &kpi, J0)[0] * wp(W0, 0.1) && norm(&kw, pk, &fine).0 > 1.0 && 1.0 > norm(&kw, now, &fine).0);
    let w24 = 2.0 * PI * 2.4;
    let r24: Vec<f64> = [(ka, J0), (ka, JF), (kb, J0), (kb, JF)].iter().map(|(k, j)| D0 * lp(w24, k, *j)[3]).collect();
    println!("wrong: bump at 2.4 Hz: A {:.4}, {:.4}; B {:.4}, {:.4} rad/s (empty, full); no control {:.4}", r24[0], r24[1], r24[2], r24[3], D0 / B.hypot(J0 * w24));
    assert!((simulate(&kb, JF, w24) - r24[3]).abs() < 1e-4 && r24[3] > r24[1]);
    println!("outside the range: a 3 rad/s speed step asks Kp x 3 = {:.1} N m at once, over a 20 N m drive", kb[0] * 3.0);
    for (label, sp) in [("peak 2.5x (zd = 0.2)", (0.2, 1.0, 0.05)), ("peak 10x (zd = 0.05)", (0.05, 1.0, 0.05)), ("torque weight 0.1", (0.1, 1.0, 0.1))] {
        let k = design(sp, true, &fine, &coarse);
        println!("try: {}: Kp = {:.3}, Ki = {:.3}, Kr = {:.3}; gamma = {:.4}", label, k[0], k[1], k[2], norm(&k, sp, &fine).0);
    }
    println!("ALL CHECKS PASS");
}
