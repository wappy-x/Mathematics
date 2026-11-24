// Multigrid: smooth on the fine grid, correct on the coarse grid -- the same check in Rust.
// std only, no crates.  Part 1: the bar, -u'' = f on (0, 1) with u = 0 at both ends.  Part 2: the
// 1 m plate, -(u_xx + u_yy) = f with 0 C edges, heated so the exact answer is 100 sin(pi x) sin(pi y) C.
use std::f64::consts::PI;
type G = Vec<Vec<f64>>;
fn splitmix(s: u64) -> (u64, f64) {                      // SplitMix64: new state and a value in [-1, 1)
    let s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(52) - 1.0) }
fn norm(v: &[f64]) -> f64 { v.iter().map(|x| x * x).sum::<f64>().sqrt() }
fn mc(x: f64) -> String { format!("{:10.5}", 1000.0 * x) }   // an error in C, printed in thousandths
fn pad(u: &[f64]) -> Vec<f64> { let mut p = vec![0.0]; p.extend_from_slice(u); p.push(0.0); p }
// ---- the bar: u holds the inside values; both ends are 0 ----
fn jacobi1(u: &[f64], f: &[f64], h: f64, w: f64) -> Vec<f64> {      // one weighted-Jacobi sweep
    let p = pad(u); (0..u.len()).map(|i| p[i + 1] + w * 0.5 * (h * h * f[i] + p[i] + p[i + 2] - 2.0 * p[i + 1])).collect() }
fn resid1(u: &[f64], f: &[f64], h: f64) -> Vec<f64> {               // residual r = f - A u
    let p = pad(u); (0..u.len()).map(|i| f[i] - (2.0 * p[i + 1] - p[i] - p[i + 2]) / (h * h)).collect() }
fn restrict1(r: &[f64], inject: bool) -> Vec<f64> {      // coarse point j sits on fine point 2j+1
    (0..r.len() / 2).map(|j| if inject { r[2 * j + 1] } else { 0.25 * (r[2 * j] + 2.0 * r[2 * j + 1] + r[2 * j + 2]) }).collect() }
fn prolong1(e: &[f64]) -> Vec<f64> {                      // linear interpolation, coarse to fine
    let (p, mut out) = (pad(e), Vec::new());
    for j in 0..e.len() + 1 { out.push(0.5 * (p[j] + p[j + 1])); out.push(p[j + 1]); }
    out.pop(); out }
#[derive(Clone, Copy)] struct Kw { w: f64, nu: (usize, usize), gamma: usize, inject: bool, cycles: usize }
const BASE: Kw = Kw { w: 2.0 / 3.0, nu: (1, 1), gamma: 1, inject: false, cycles: 10 };
fn cycle1(mut u: Vec<f64>, f: &[f64], h: f64, k: Kw) -> Vec<f64> {
    if u.len() == 1 { return vec![0.5 * h * h * f[0]]; }          // one unknown: solve it exactly
    for _ in 0..k.nu.0 { u = jacobi1(&u, f, h, k.w); }             // pre-smooth
    let rc = restrict1(&resid1(&u, f, h), k.inject); let mut ec = vec![0.0; rc.len()];
    for _ in 0..k.gamma { ec = cycle1(ec, &rc, 2.0 * h, k); }     // coarse correction
    let p = prolong1(&ec); u = u.iter().zip(p.iter()).map(|(a, b)| a + b).collect();
    for _ in 0..k.nu.1 { u = jacobi1(&u, f, h, k.w); }             // post-smooth
    u }
fn rate1(n: usize, k: Kw) -> (Vec<f64>, f64) {           // k.cycles cycles from a random start, f = 0
    let (mut s, mut u) = (2026u64, Vec::new());
    for _ in 0..n { let (s2, x) = splitmix(s); s = s2; u.push(x); }
    let (mut hist, zero) = (vec![norm(&u)], vec![0.0; n]);
    for _ in 0..k.cycles { u = cycle1(u, &zero, 1.0 / (n as f64 + 1.0), k); hist.push(norm(&u)); }
    let r = (hist[k.cycles] / hist[k.cycles - 5]).powf(0.2); (hist, r) }     // mean factor over the last 5 cycles
// ---- the plate: grids are rows with a border of zeros; FL counts + - * / kernel by kernel ----
fn grid(m: usize) -> G { vec![vec![0.0; m + 2]; m + 2] }
fn smooth2(u: &G, f: &G, h: f64, w: f64, fl: &mut u64) -> G {     // weighted Jacobi, 9 flops a point
    let (m, h2, w4, mut out) = (u.len() - 2, h * h, 0.25 * w, grid(u.len() - 2));
    for i in 1..=m { for j in 1..=m {
        let (a, b, c) = (&u[i - 1], &u[i], &u[i + 1]); out[i][j] = b[j] + w4 * (h2 * f[i][j] + a[j] + c[j] + b[j - 1] + b[j + 1] - 4.0 * b[j]);
    } } *fl += 9 * (m * m) as u64; out
}
fn resid2(u: &G, f: &G, h: f64, fl: &mut u64) -> G {              // r = f - A u, 7 flops a point
    let (m, q, mut out) = (u.len() - 2, 1.0 / (h * h), grid(u.len() - 2));
    for i in 1..=m { for j in 1..=m {
        let (a, b, c) = (&u[i - 1], &u[i], &u[i + 1]); out[i][j] = f[i][j] - q * (4.0 * b[j] - a[j] - c[j] - b[j - 1] - b[j + 1]);
    } } *fl += 7 * (m * m) as u64; out
}
fn restrict2(r: &G, fl: &mut u64) -> G {                           // full weighting, 11 flops a point
    let mc = (r.len() - 3) / 2; let mut out = grid(mc);
    for i in 1..=mc { for j in 1..=mc {
        let (a, b, c, k) = (&r[2 * i - 1], &r[2 * i], &r[2 * i + 1], 2 * j); out[i][j] = 0.0625 * (a[k - 1] + a[k + 1] + c[k - 1] + c[k + 1] + 2.0 * (a[k] + c[k] + b[k - 1] + b[k + 1]) + 4.0 * b[k]);
    } } *fl += 11 * (mc * mc) as u64; out
}
fn prolong_add(mut u: G, e: &G, fl: &mut u64) -> G {               // bilinear interpolation of e, added into u
    let (mc, m) = (e.len() - 2, 2 * e.len() - 3);
    for i in 0..=mc {
        let (e0, e1, mut ra, mut rb) = (&e[i], &e[i + 1], vec![0.0; m + 2], vec![0.0; m + 2]);
        for j in 0..=mc {
            ra[2 * j] = e0[j]; ra[2 * j + 1] = 0.5 * (e0[j] + e0[j + 1]);
            rb[2 * j] = 0.5 * (e0[j] + e1[j]); rb[2 * j + 1] = 0.25 * (e0[j] + e0[j + 1] + e1[j] + e1[j + 1]);
        }
        for x in 0..m + 2 { if i > 0 { u[2 * i][x] += ra[x]; } u[2 * i + 1][x] += rb[x]; }
    }
    *fl += (8 * (mc + 1) * (mc + 1) + m * m) as u64; u
}
fn vcycle2(u: G, f: &G, h: f64, w: f64, fl: &mut u64) -> G {
    if u.len() == 3 { let mut g = grid(1); g[1][1] = 0.25 * h * h * f[1][1]; return g; }
    let u = smooth2(&u, f, h, w, fl); let rc = restrict2(&resid2(&u, f, h, fl), fl);
    let ec = vcycle2(grid(rc.len() - 2), &rc, 2.0 * h, w, fl); smooth2(&prolong_add(u, &ec, fl), f, h, w, fl)
}
fn heat(m: usize) -> (Vec<f64>, G) {                      // sin(pi x) at the grid lines, f = 200 pi^2 sin sin
    let s: Vec<f64> = (0..m + 2).map(|i| (PI * i as f64 / (m as f64 + 1.0)).sin()).collect();
    let f = s.iter().map(|a| s.iter().map(|b| 200.0 * PI * PI * a * b).collect()).collect(); (s, f)
}
fn fmg(m: usize, per_level: usize, fl: &mut u64) -> (G, Vec<f64>) {   // solve coarse, interpolate, cycle, repeat
    let (mut u, mut mm, mut s) = (grid(1), 1usize, Vec::new());
    while mm <= m {
        let (s2, f) = heat(mm); s = s2; if mm > 1 { u = prolong_add(grid(mm), &u, fl); }
        for _ in 0..per_level { u = vcycle2(u, &f, 1.0 / (mm as f64 + 1.0), 0.8, fl); } mm = 2 * mm + 1;
    } (u, s) }
fn main() {
    // ---- 1. one sweep on the mode sin(k pi x): measured shrink against 1 - 2w sin^2(theta/2) ----
    let (n, h, w, mut worst) = (63usize, 1.0 / 64.0, 2.0 / 3.0, 0.0f64);
    println!("mode k  theta/pi  formula   measured   (one sweep, w = 2/3, n = 63)");
    for k in [1usize, 8, 16, 32, 48, 63] {
        let v: Vec<f64> = (0..n).map(|i| (k as f64 * PI * (i + 1) as f64 * h).sin()).collect();
        let g = 1.0 - 2.0 * w * (k as f64 * PI * h / 2.0).sin().powi(2);
        let meas = norm(&jacobi1(&v, &vec![0.0; n], h, w)) / norm(&v); worst = worst.max((meas - g.abs()).abs());
        println!("{:6} {:9.4} {:9.5} {:9.5}", k, k as f64 * h, g, meas);
    }
    let hi = (32..64).map(|k| (1.0 - 2.0 * w * (k as f64 * PI * h / 2.0).sin().powi(2)).abs()).fold(0.0f64, f64::max);
    println!("largest high-mode factor, k = 32..63     {:.6}", hi);
    let row = |vals: Vec<String>| vals.join(" ");
    println!("chart theta/pi     {}", row((0..11).map(|t| format!("{:4.1}", t as f64 / 10.0)).collect()));
    for ww in [2.0 / 3.0, 1.0f64] {
        println!("chart |g|, w = {:.2} {}", ww, row((0..11).map(|t| format!("{:4.2}", (1.0 - 2.0 * ww * (t as f64 * PI / 20.0).sin().powi(2)).abs())).collect()));
    }
    for ww in [2.0 / 3.0, 0.8f64] {                       // plate: g = 1 - w (s1 + s2); high = some angle >= pi/2
        let mut sm = 0.0f64; for a in 0..41 { for b in 0..41 { if a.max(b) >= 20 {
            sm = sm.max((1.0 - ww * ((a as f64 * PI / 80.0).sin().powi(2) + (b as f64 * PI / 80.0).sin().powi(2))).abs()); } } }
        println!("plate smoothing factor, w = {:.2}        {:.6}", ww, sm);
    }
    // ---- 2. Galerkin coarse operator R A P on 7 points, against the 3-point grid's own matrix ----
    let ah = |v: &[f64]| -> Vec<f64> { resid1(v, &[0.0; 7], 0.125).iter().map(|x| -x / 64.0).collect() };
    let rap: Vec<Vec<f64>> = (0..3).map(|j| { let e: Vec<f64> = (0..3).map(|i| if i == j { 1.0 } else { 0.0 }).collect();
        restrict1(&ah(&prolong1(&e)), false).iter().map(|x| 4.0 * x).collect() }).collect();
    println!("(2h)^2 R A P, middle column:   {}", row(rap[1].iter().map(|x| format!("{:5.2}", x)).collect()));
    // ---- 3. two-grid factor by Fourier analysis against measured cycles ----
    let tg = |w: f64| (1..1024).map(|k| (k as f64 * PI / 2048.0).sin().powi(2))
        .map(|s| s * (1.0 - 2.0 * w * s).powi(2) + (1.0 - s) * (1.0 - 2.0 * w * (1.0 - s)).powi(2)).fold(0.0f64, f64::max);
    let fourier = tg(w); println!("two-grid factor, Fourier, w = 2/3        {:.6}", fourier);
    let mut rates = Vec::new();
    for n in [63usize, 255, 1023] {
        let (hist, r) = rate1(n, BASE); rates.push(r);
        println!("V(1,1) factor per cycle, n = {:4}        {:.6}", n, r);
        println!("chart log10 error, n = {:4}{}", n, hist.iter().step_by(2).map(|e| format!("{:6.2}", (e / hist[0]).log10())).collect::<Vec<_>>().join(" "));
    }
    let other = [("V(2,1) factor, n = 1023", Kw { nu: (2, 1), ..BASE }), ("W(1,1) factor, n = 1023", Kw { gamma: 2, ..BASE }),
                 ("wrong: plain Jacobi, w = 1", Kw { w: 1.0, ..BASE }), ("wrong: injection, not full weighting", Kw { inject: true, ..BASE }),
                 ("wrong: no smoothing at all", Kw { nu: (0, 0), ..BASE }), ("long run: injection, cycles 146 to 150", Kw { inject: true, cycles: 150, ..BASE })];
    let res: Vec<f64> = other.iter().map(|(_, k)| rate1(1023, *k).1).collect();
    for (i, (label, _)) in other.iter().enumerate() { println!("{:<40} {:.6}", label, res[i]); }
    let slow: Vec<f64> = (0..1023).map(|i| (PI * (i + 1) as f64 / 1024.0).sin() - (1023.0 * PI * (i + 1) as f64 / 1024.0).sin()).collect(); // waves k = 1 and k = 1023 together
    let lr1 = norm(&cycle1(slow.clone(), &vec![0.0; 1023], 1.0 / 1024.0, Kw { w: 1.0, ..BASE })) / norm(&slow); println!("long run: plain Jacobi, slowest pair     {:.6}, two-grid {:.6}", lr1, tg(1.0));
    println!("Jacobi alone, n = 1023, factor per sweep {:.9}", 1.0 - 2.0 * w * (PI / 2048.0).sin().powi(2));
    // ---- 4. the plate ----
    println!("plate     N    V flops/N  V/finest  FMG flops/N  alg err mC disc err mC total err mC");
    let mut plate = Vec::new();
    for m in [63usize, 255, 1023] {
        let mut fl = 0u64; let (_, f) = heat(m);
        vcycle2(grid(m), &f, 1.0 / (m as f64 + 1.0), 0.8, &mut fl); let vflops = fl;
        let mut fc = 0u64; let (_, fcoarse) = heat((m - 1) / 2);
        vcycle2(grid((m - 1) / 2), &fcoarse, 2.0 / (m as f64 + 1.0), 0.8, &mut fc);
        let vratio = vflops as f64 / (vflops - fc) as f64;
        let mut ff = 0u64; let (u, s) = fmg(m, 2, &mut ff); let nn = (m * m) as f64;
        let x = PI / (2 * m + 2) as f64; let beta = x * x / x.sin().powi(2);  // closed form: u_h = 100 beta sin sin
        let (mut alg, mut tot) = (0.0f64, 0.0f64);
        for i in 0..m + 2 { for j in 0..m + 2 {
            alg = alg.max((u[i][j] - 100.0 * beta * s[i] * s[j]).abs()); tot = tot.max((u[i][j] - 100.0 * s[i] * s[j]).abs()); } }
        println!("{:5} {:8} {:9.3} {:9.4} {:11.3}{} {}  {}", m, m * m, vflops as f64 / nn, vratio, ff as f64 / nn, mc(alg), mc(100.0 * (beta - 1.0)), mc(tot));
        plate.push((vratio, alg, 100.0 * (beta - 1.0), ff, u[(m + 1) / 2][(m + 1) / 2], vflops as f64 / nn));
    }
    let (mut f1, x) = (0u64, PI / 2048.0); let (u1, _) = fmg(1023, 1, &mut f1); let one = (u1[512][512] - 100.0 * x * x / x.sin().powi(2)).abs();
    println!("plate centre after FMG, 1023^2           {:.6} C (exact 100)", plate[2].4);
    println!("FMG flops for 1,046,529 unknowns         {}", plate[2].3);
    let wf = 2.0 * 9.0 + 7.0 + 11.0 / 4.0 + 8.0 / 4.0 + 1.0;      // finest-level flops a point: 2 smooths, residual, restrict, interpolate
    println!("work model: finest {:.2}, V x4/3 {:.2}, FMG {:.2}, Cholesky/FMG {:.0}", wf, 4.0 / 3.0 * wf, 4.0 / 3.0 * (2.0 * 4.0 / 3.0 * wf + 3.0), (1046529u64 * 1023 * 1023) as f64 / plate[2].3 as f64);
    println!("wrong: one V-cycle per level, centre err{} mC", mc(one));
    println!("estimate: band Cholesky, N m^2 flops     {:.1}e12", (1046529u64 * 1023 * 1023) as f64 / 1e12);
    println!("estimate: plate Jacobi sweeps per digit  {:.0}", 10f64.ln() / -(1.0 - 2.0 * (PI / 2048.0).sin().powi(2)).ln());
    assert!(worst < 1e-12, "measured shrink of each mode equals 1 - 2w sin^2(theta/2)");
    assert!((hi - 1.0 / 3.0).abs() < 1e-12, "every high mode shrinks by at least 1/3");
    assert!(rap[1] == vec![-1.0, 2.0, -1.0], "Galerkin R A P equals the coarse grid's own matrix");
    assert!((fourier - 1.0 / 9.0).abs() < 1e-12, "two-grid factor is exactly 1/9 for every mode pair");
    assert!((res[1] - 1.0 / 9.0).abs() < 0.01, "W-cycle measures the two-grid factor");
    let (rmax, rmin) = (rates.iter().cloned().fold(0.0, f64::max), rates.iter().cloned().fold(1.0, f64::min));
    assert!(rmax - rmin < 0.02 && rmax < 0.25, "V rate free of n");
    assert!(res[2] > 0.9 && (lr1 - tg(1.0)).abs() < 1e-9, "w = 1: the slowest pair keeps (1 - 2s)^2 a cycle");
    assert!(res[5] > 0.7 && 0.7 > res[3], "injection's early average flatters it");
    assert!(plate.iter().all(|p| p.0 < 4.0 / 3.0 + 0.01 && p.5 <= 4.0 / 3.0 * wf), "counted V work within 4/3 of finest level");
    assert!(plate[2].1 < plate[2].2, "FMG algebraic error below the closed-form discretisation error");
    assert!(one > 10.0 * plate[2].2, "one V-cycle per level stops short of discretisation accuracy");
    println!("ALL CHECKS PASS");
}
