// Coordinate descent -- the check behind the card.  std only, no crates.
// A fund tilts two holdings by x and y percentage points and minimises
// f(x, y) = x^2 + xy + y^2 - 3x  (tracking risk minus forecast gain).
// Roads: exact coordinate steps (cyclic, greedy, random); the optimality equations
// solved by elimination; the random method's expected gap by enumerating every
// choice path, by a closed formula and by simulation; a stall on a kinked coupling;
// alternating least squares for a rank-1 fit against an angle enumeration.
use std::f64::consts::PI;

fn f(x: f64, y: f64) -> f64 { x * x + x * y + y * y - 3.0 * x }
fn grad(x: f64, y: f64) -> (f64, f64) { (2.0 * x + y - 3.0, x + 2.0 * y) }
fn step(x: f64, y: f64, i: u64) -> (f64, f64) { // exact minimisation along coordinate i
    if i == 0 { ((3.0 - y) / 2.0, y) } else { (x, -x / 2.0) }
}
fn expected_gap(k: u32, fs: f64) -> f64 { // average over all 2^k equally likely paths
    let mut tot = 0.0;
    for mask in 0u64..(1u64 << k) {
        let (mut x, mut y) = (0.0, 0.0);
        for t in 0..k { let p = step(x, y, (mask >> t) & 1); x = p.0; y = p.1; }
        tot += f(x, y) - fs;
    }
    tot / (1u64 << k) as f64
}
fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn argmin1(h: &dyn Fn(f64) -> f64) -> f64 { // golden-section search, convex in one variable
    let (mut lo, mut hi) = (-5.0f64, 5.0f64); let r = (5.0f64.sqrt() - 1.0) / 2.0;
    for _ in 0..120 {
        let (a, b) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if h(a) <= h(b) { hi = b; } else { lo = a; }
    }
    (lo + hi) / 2.0
}
fn cd(fun: &dyn Fn(f64, f64) -> f64, mut x: f64, mut y: f64, sweeps: usize) -> (f64, f64, f64) {
    for _ in 0..sweeps { x = argmin1(&|t| fun(t, y)); y = argmin1(&|t| fun(x, t)); }
    (x, y, fun(x, y))
}
fn main() {
    // road 1: grad f = 0 is 2x + y = 3, x + 2y = 0; eliminate x from the second row
    let m = 1.0 / 2.0;
    let ys = (0.0 - m * 3.0) / (2.0 - m * 1.0); let xs = (3.0 - ys) / 2.0; let fs = f(xs, ys);
    println!("optimality equations: x* = {:.4}, y* = {:.4}, f* = {:.4}", xs, ys, fs);
    let h = 1e-3; // curvatures by second differences
    let lx = (f(1.0 + h, 0.0) - 2.0 * f(1.0, 0.0) + f(1.0 - h, 0.0)) / (h * h);
    let ly = (f(0.0, 1.0 + h) - 2.0 * f(0.0, 1.0) + f(0.0, 1.0 - h)) / (h * h);
    let disc = ((2.0f64 - 2.0).powi(2) + 4.0 * 1.0f64.powi(2)).sqrt(); // eigenvalues of [[2,1],[1,2]]
    let (l, mu) = ((2.0 + 2.0 + disc) / 2.0, (2.0 + 2.0 - disc) / 2.0);
    println!("coordinate curvatures L_x = {:.4}, L_y = {:.4}; full L = {:.4}, mu = {:.4}", lx, ly, l, mu);

    // road 2: cyclic exact coordinate descent from (0, 0)
    let (mut x, mut y) = (0.0f64, 0.0f64); let mut path = vec![(x, y)]; let mut errs = vec![];
    for s in 1..7 {
        let p = step(x, y, 0); x = p.0; y = p.1; path.push((x, y));
        let p = step(x, y, 1); x = p.0; y = p.1; path.push((x, y));
        errs.push(x - xs);
        println!("sweep {}: x = {:.6}, y = {:.6}, x - x* = {:+.6}, gap {:.8}", s, x, y, x - xs, f(x, y) - fs);
    }
    let gaps: Vec<f64> = path.iter().map(|p| f(p.0, p.1) - fs).collect();
    let gs: Vec<String> = gaps[..7].iter().map(|g| format!("{:.6}", g)).collect();
    println!("gap after each step: {}", gs.join(" "));
    let (drop, bound) = (gaps[0] - gaps[1], grad(0.0, 0.0).0.powi(2) / (2.0 * lx));
    println!("first step: drop {:.4}; Step 1's bound slope^2 / (2 L_x) = {:.4}", drop, bound);
    assert!((drop - bound).abs() < 1e-6);
    for k in 0..5 {
        assert!((errs[k + 1] / errs[k] - 0.25).abs() < 1e-9); // 1/4 per sweep
        assert!((gaps[k + 1] / gaps[k] - 0.25).abs() < 1e-9); // 1/4 per step
    }
    let last = path[path.len() - 1];
    assert!((last.0 - xs).abs() < 1e-3 && grad(last.0, last.1).1.abs() < 1e-12);
    let fp: Vec<String> = path[..7].iter().map(|p| format!("({:.4},{:.4})", p.0, p.1)).collect();
    println!("figure, {} centre ({:.1},{:.1}) axes for gap c: sqrt(2c) along (1,-1), sqrt(2c/3) along (1,1)",
             fp.join(" "), xs, ys);

    // greedy (Gauss-Southwell): always the coordinate with the larger partial derivative
    let (mut x, mut y) = (0.0f64, 0.0f64); let mut order = String::new();
    for _ in 0..12 {
        let g = grad(x, y); let i = if g.0.abs() >= g.1.abs() { 0 } else { 1 };
        order.push(if i == 0 { 'x' } else { 'y' }); let p = step(x, y, i); x = p.0; y = p.1;
    }
    println!("greedy order: {}, gap after 12 steps {:.10} (cyclic {:.10})", order, f(x, y) - fs, gaps[12]);
    assert!(((f(x, y) - fs) - gaps[12]).abs() < 1e-15);

    // road 3: random order, each step picks x or y with probability 1/2
    let r2 = (0..40000).map(|j| { let t = j as f64 * PI / 20000.0; 3.0 / (1.0 + t.cos() * t.sin()) })
        .fold(f64::MIN, f64::max);
    let (n, lmax) = (2.0, lx.max(ly));
    println!("level set f <= f(0,0): R^2 = {:.4}; bound 2 n Lmax R^2 / k = {:.2}/k", r2, 2.0 * n * lmax * r2);
    assert!((r2 - 2.0 * gaps[0] / mu).abs() < 1e-9); // the farthest point lies along the gentlest curvature
    println!("k  enumerated  3(5/8)^k   1/k bound  3(3/4)^k bound");
    for k in [1u32, 2, 4, 6, 8, 10] {
        let e = expected_gap(k, fs);
        let b1 = 2.0 * n * lmax * r2 / k as f64; let b2 = 3.0 * (1.0 - mu / (n * lmax)).powi(k as i32);
        println!("{:<2} {:.6}    {:.6}  {:8.4}   {:.6}", k, e, 3.0 * 0.625f64.powi(k as i32), b1, b2);
        assert!((e - 3.0 * 0.625f64.powi(k as i32)).abs() < 1e-12 && e <= b1 && e <= b2);
    }
    let ks = [0u32, 2, 4, 6, 8, 10];
    let lg = |v: Vec<f64>| v.iter().map(|g| format!("{:.2}", g.log10())).collect::<Vec<_>>().join(" ");
    println!("chart, log10 gap at k = 0, 2, 4, 6, 8, 10: cyclic {}", lg(ks.iter().map(|&k| gaps[k as usize]).collect()));
    println!("chart, random {} ; bound 3(3/4)^k {}", lg(ks.iter().map(|&k| expected_gap(k, fs)).collect()),
             lg(ks.iter().map(|&k| 3.0 * 0.75f64.powi(k as i32)).collect()));
    let seed0 = 2024u64; let (mut seed, nruns) = (seed0, 20000); let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..nruns {
        let (mut x, mut y) = (0.0, 0.0);
        for _ in 0..10 { let (s, z) = splitmix(seed); seed = s; let p = step(x, y, z >> 63); x = p.0; y = p.1; }
        let g = f(x, y) - fs; tot += g; tot2 += g * g;
    }
    let mean = tot / nruns as f64; let se = ((tot2 / nruns as f64 - mean * mean) / nruns as f64).sqrt();
    println!("simulated, {} runs, seed {}: mean gap at k = 10 {:.6} (standard error {:.6})", nruns, seed0, mean, se);
    assert!((mean - expected_gap(10, fs)).abs() < 4.0 * se);

    // gradient descent at step 1/L for comparison: one gradient costs two partials
    let (mut x, mut y) = (0.0f64, 0.0f64);
    for _ in 0..6 { let g = grad(x, y); x -= g.0 / l; y -= g.1 / l; }
    println!("gradient descent, 6 steps at 1/L: gap {:.6}; cyclic, 6 sweeps: {:.8}", f(x, y) - fs, gaps[12]);
    println!("2,000 assets: full gradient {} multiply-adds, one coordinate step {}", 2000 * 2000, 2000);

    // what breaks: a kinked coupling |x - y| stalls; a smooth or separable one does not
    let kink = |x: f64, y: f64| (x - y).abs() + 0.1 * (x + y).powi(2);
    let smooth = |x: f64, y: f64| (x - y).powi(2) + 0.1 * (x + y).powi(2);
    let separable = |x: f64, y: f64| x.abs() + y.abs() + 0.1 * (x + y).powi(2);
    let e = 1e-6;
    println!("kinked coupling at (1, 1): f = {:.4}; slopes along x: right {:+.4}, left {:+.4}", kink(1.0, 1.0),
             (kink(1.0 + e, 1.0) - kink(1.0, 1.0)) / e, (kink(1.0, 1.0) - kink(1.0 - e, 1.0)) / e);
    let (xk, yk, vk) = cd(&kink, 1.0, 1.0, 20);
    println!("  20 sweeps from (1, 1): ({:.6}, {:.6}), f = {:.6}; but f(0, 0) = {:.4}, f(0.5, 0.5) = {:.4}",
             xk, yk, vk, kink(0.0, 0.0), kink(0.5, 0.5));
    assert!((vk - 0.4).abs() < 1e-8 && kink(0.0, 0.0) < vk - 0.39);
    let (_, _, v2) = cd(&smooth, 1.0, 1.0, 20);
    let (xs3, ys3, v3) = cd(&separable, 1.0, 1.0, 1);
    println!("smooth coupling (x-y)^2, 20 sweeps: f = {:.6}; separable |x|+|y|, 1 sweep: largest |coordinate| {:.6}, f = {:.6}",
             v2, xs3.abs().max(ys3.abs()), v3);
    assert!(v2 < 1e-6 && v3 < 1e-8);

    // alternating least squares: rank-1 fit to returns M (3 days by 2 assets, percent)
    let mm = [[3.0, 2.0], [1.0, 0.0], [0.0, 1.0f64]]; let mut v = [1.0f64, 0.0]; let mut u = [0.0f64; 3];
    let resid = |u: &[f64; 3], v: &[f64; 2]| -> f64 {
        let mut s = 0.0; for i in 0..3 { for j in 0..2 { s += (mm[i][j] - u[i] * v[j]).powi(2); } } s };
    for r in 1..6 {
        let vv = v[0] * v[0] + v[1] * v[1];
        for i in 0..3 { u[i] = (mm[i][0] * v[0] + mm[i][1] * v[1]) / vv; }
        let uu: f64 = u.iter().map(|t| t * t).sum();
        for j in 0..2 { v[j] = (0..3).map(|i| mm[i][j] * u[i]).sum::<f64>() / uu; }
        println!("ALS round {}: v = ({:.6}, {:.6}), squared misses {:.8}", r, v[0], v[1], resid(&u, &v));
    }
    let g = |a: usize, b: usize| -> f64 { (0..3).map(|i| mm[i][a] * mm[i][b]).sum() }; // M^T M
    let (tr, det) = (g(0, 0) + g(1, 1), g(0, 0) * g(1, 1) - g(0, 1).powi(2));
    let tot: f64 = mm.iter().flatten().map(|t| t * t).sum(); let lam1 = (tr + (tr * tr - 4.0 * det).sqrt()) / 2.0;
    let grid = (0..100000).map(|j| { let t = j as f64 * PI / 100000.0;
        tot - mm.iter().map(|row| (row[0] * t.cos() + row[1] * t.sin()).powi(2)).sum::<f64>() })
        .fold(f64::MAX, f64::min);
    println!("certificate: {:.0} - top eigenvalue {:.4} = {:.6}; angle enumeration {:.6}", tot, lam1, tot - lam1, grid);
    assert!((resid(&u, &v) - (tot - lam1)).abs() < 1e-6 && (grid - (tot - lam1)).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
