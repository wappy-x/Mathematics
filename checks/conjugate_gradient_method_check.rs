// Conjugate gradient -- the check behind the card.  Rust std only, no crates.
// Nothing imported solves anything: every product, step and elimination is written out.
use std::f64::consts::PI;
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut s = 0.0; for i in 0..u.len() { s += u[i] * v[i]; } s }
type Step = [f64; 9]; // p0, p1, pAp, alpha, x0, x1, r0, r1, beta
struct Run { x: Vec<f64>, steps: Vec<Step>, hist: Vec<f64>, dirs: Vec<(Vec<f64>, Vec<f64>)> }
// Solve A x = b, i.e. minimise f(x) = 1/2 x.Ax - b.x, knowing A only as the rule av(v).
fn cg(av: &dyn Fn(&[f64]) -> Vec<f64>, b: &[f64], x0: &[f64], tol: f64, bmul: f64, keep: usize) -> Run {
    let (mut x, ax) = (x0.to_vec(), av(x0));
    let mut r: Vec<f64> = (0..b.len()).map(|i| b[i] - ax[i]).collect(); // residual = minus the gradient
    let (mut p, mut rr) = (r.clone(), dot(&r, &r));
    let r0 = rr.sqrt();
    let (mut steps, mut hist, mut dirs) = (Vec::new(), vec![1.0], Vec::new());
    while rr.sqrt() / r0 > tol && steps.len() < 20000 {
        let ap = av(&p); let pap = dot(&p, &ap);
        if dirs.len() < keep { dirs.push((p.clone(), ap.clone())); } // kept only to test conjugacy
        let a = rr / pap; // exact step to the lowest point along p
        for i in 0..x.len() { x[i] += a * p[i]; r[i] -= a * ap[i]; }
        let rn = dot(&r, &r);
        let beta = bmul * rn / rr; // bmul = 0: gradient descent with exact steps
        steps.push([p[0], p[1], pap, a, x[0], x[1], r[0], r[1], beta]);
        for i in 0..p.len() { p[i] = r[i] + beta * p[i]; }
        rr = rn; hist.push(rr.sqrt() / r0);
    }
    Run { x, steps, hist, dirs }
}
fn f2(a: &[[f64; 2]; 2], b: &[f64], x: &[f64]) -> f64 {
    0.5 * dot(x, &[dot(&a[0], x), dot(&a[1], x)]) - dot(b, x)
}
fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn fr(x: f64, y: f64) -> f64 { 100.0 * (y - x * x) * (y - x * x) + (1.0 - x) * (1.0 - x) }
fn gr(x: f64, y: f64) -> (f64, f64) { (-400.0 * x * (y - x * x) - 2.0 * (1.0 - x), 200.0 * (y - x * x)) }
fn search(x: f64, y: f64, dx: f64, dy: f64, c2: f64) -> f64 { // bisection until the strong Wolfe tests pass
    let (f0, (gx, gy)) = (fr(x, y), gr(x, y));
    let (s0, mut lo, mut hi, mut a) = (gx * dx + gy * dy, 0.0, -1.0, 1.0);
    for _ in 0..60 {
        let (gx, gy) = gr(x + a * dx, y + a * dy); let s = gx * dx + gy * dy;
        if fr(x + a * dx, y + a * dy) > f0 + 1e-4 * a * s0 { hi = a; }
        else if s < c2 * s0 { lo = a; }
        else if s > -c2 * s0 { hi = a; }
        else { break; }
        a = if hi > 0.0 { (lo + hi) / 2.0 } else { 2.0 * a };
    }
    a
}
fn ncg(kind: &str, c2: f64) -> (usize, f64, f64, usize, Vec<(f64, f64)>) {
    let (mut x, mut y, mut k, mut restarts, mut path) = (-1.2, 1.0, 0, 0, Vec::new());
    let (mut gx, mut gy) = gr(x, y);
    let (mut dx, mut dy) = (-gx, -gy);
    while (gx * gx + gy * gy).sqrt() >= 1e-6 && k < 100000 {
        if gx * dx + gy * dy >= 0.0 { dx = -gx; dy = -gy; restarts += 1; } // not downhill: restart
        let a = search(x, y, dx, dy, c2);
        x += a * dx; y += a * dy; let (hx, hy) = gr(x, y);
        let mut b = if kind == "FR" { (hx * hx + hy * hy) / (gx * gx + gy * gy) } else { 0.0 }; // Fletcher-Reeves
        if kind == "PR+" { b = f64::max(0.0, (hx * (hx - gx) + hy * (hy - gy)) / (gx * gx + gy * gy)); } // Polak-Ribiere
        dx = -hx + b * dx; dy = -hy + b * dy; gx = hx; gy = hy; k += 1; path.push((x, y));
    }
    (k, x, y, restarts, path)
}
fn main() {
    // ---- by hand: two readings, 18 and 15 C, weight w = 1, start from a flat 15 C ----
    let (a2, y2) = ([[2.0, -1.0], [-1.0, 2.0]], [18.0, 15.0]);
    let mv2 = |v: &[f64]| vec![dot(&a2[0], v), dot(&a2[1], v)];
    let h = cg(&mv2, &y2, &[15.0, 15.0], 1e-12, 1.0, 0);
    let sd2 = cg(&mv2, &y2, &[15.0, 15.0], 1e-12, 0.0, 0).steps;
    let fstar = f2(&a2, &y2, &[17.0, 16.0]); // the answer from A's inverse, (1/3)[[2, 1], [1, 2]] y
    let (q0, q1) = (&h.steps[0], &h.steps[1]);
    println!("hand: start (15, 15), residual (3, 0), gap f - f* {:.4}, conjugacy d1.Ad0 {:.4}",
        f2(&a2, &y2, &[15.0, 15.0]) - fstar, dot(&q1[..2], &mv2(&q0[..2])));
    for (k, s) in h.steps.iter().enumerate() {
        let ap = mv2(&s[..2]);
        println!("hand cg k={}: r.r {:.4} p ({:.4}, {:.4}) Ap ({:.4}, {:.4}) pAp {:.4} alpha {:.4} -> x ({:.4}, {:.4}) r ({:.4}, {:.4}) beta {:.4}\n            gap {:.4}",
            k, s[3] * s[2], s[0], s[1], ap[0], ap[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], f2(&a2, &y2, &[s[4], s[5]]) - fstar);
    }
    let pts: Vec<String> = sd2[..5].iter().map(|s| format!("({:.4}, {:.4})", s[4], s[5])).collect();
    let gaps: Vec<String> = sd2[..5].iter().map(|s| format!("{:.4}", f2(&a2, &y2, &[s[4], s[5]]) - fstar)).collect();
    println!("hand gd: {} gaps {} steps to 1e-12: {}", pts.join(" "), gaps.join(" "), sd2.len());
    let lv: Vec<String> = [3.0f64, 0.75, 0.1875].iter().map(|c| format!("c={} {:.4} {:.4}", c, (2.0 * c).sqrt(), (2.0 * c / 3.0).sqrt())).collect();
    println!("figure, centre (17, 16), long axis along (1, 1); semi-axes sqrt(2c), sqrt(2c/3) at gap c: {}", lv.join(", "));
    assert!(h.steps.len() == 2 && (h.x[0] - 17.0).abs() < 1e-12 && (h.x[1] - 16.0).abs() < 1e-12); // exact in 2 steps
    assert!(dot(&q1[..2], &mv2(&q0[..2])).abs() < 1e-12); // the two moves are conjugate
    assert!(sd2.len() > 20); // gradient descent never lands
    // ---- the card's example: 1000 thermometer readings, smoothing weight w = 25 ----
    let (n, w) = (1000usize, 25.0f64);
    let (mut seed, mut y) = (2026u64, Vec::new());
    for i in 0..n { // true warming 15 -> 25 C, plus up to 1 C of noise
        let (s, z) = splitmix(seed); seed = s;
        y.push(15.0 + 0.01 * i as f64 + 2.0 * ((z >> 11) as f64 / 9007199254740992.0 - 0.5));
    }
    let av = |v: &[f64]| -> Vec<f64> { // (I + w L) v, without storing a 1000 by 1000 matrix
        (0..n).map(|i| v[i] + (if i > 0 { w * (v[i] - v[i - 1]) } else { 0.0 })
            + (if i < n - 1 { w * (v[i] - v[i + 1]) } else { 0.0 })).collect()
    };
    let fsm = |x: &[f64]| -> f64 { // misfit to the readings + w times the jumps
        let e: Vec<f64> = (0..n).map(|i| x[i] - y[i]).collect();
        let j: Vec<f64> = (0..n - 1).map(|i| x[i + 1] - x[i]).collect();
        0.5 * dot(&e, &e) + 0.5 * w * dot(&j, &j)
    };
    let start = vec![15.0; n];
    let (c, g) = (cg(&av, &y, &start, 1e-8, 1.0, n), cg(&av, &y, &start, 1e-8, 0.0, 0));
    let x = &c.x;
    // road 2: elimination on the three-diagonal system (forward sweep, then back substitution)
    let (mut cc, mut d, mut xe) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let cnt = (i > 0) as usize + (i < n - 1) as usize;
        let diag = 1.0 + w * cnt as f64 + (if i > 0 { w * cc[i - 1] } else { 0.0 });
        cc[i] = -w / diag;
        d[i] = (y[i] + (if i > 0 { w * d[i - 1] } else { 0.0 })) / diag;
    }
    for i in (0..n).rev() { xe[i] = d[i] - (if i < n - 1 { cc[i] * xe[i + 1] } else { 0.0 }); }
    let ax = av(x); let res: Vec<f64> = (0..n).map(|i| y[i] - ax[i]).collect();
    let gap_ce = (0..n).map(|i| (x[i] - xe[i]).abs()).fold(0.0, f64::max);
    let acos: Vec<f64> = (1..c.dirs.len()).map(|i| (0..i).map(|j| { let ((pi, api), (pj, apj)) = (&c.dirs[i], &c.dirs[j]);
        dot(pi, apj).abs() / (dot(pi, api) * dot(pj, apj)).sqrt() }).fold(0.0, f64::max)).collect(); // worst A-cosine with the earlier ones
    let kappa = 1.0 + w * (2.0 + 2.0 * (PI / n as f64).cos()); // largest eigenvalue L over smallest, mu = 1
    let (rate_cg, rate_gd) = ((kappa.sqrt() - 1.0) / (kappa.sqrt() + 1.0), (kappa - 1.0) / (kappa + 1.0));
    let ea = |u: &[f64]| { let e: Vec<f64> = (0..n).map(|i| u[i] - xe[i]).collect(); dot(&e, &av(&e)).sqrt() }; // error in the bowl's units
    let mcg = (ea(x) / ea(&start)).powf(1.0 / c.steps.len() as f64);
    let mgd = (ea(&g.x) / ea(&start)).powf(1.0 / g.steps.len() as f64);
    let rms = |u: &[f64]| { // root-mean-square distance from the true warming
        let e: Vec<f64> = (0..n).map(|i| u[i] - (15.0 + 0.01 * i as f64)).collect();
        (dot(&e, &e) / n as f64).sqrt()
    };
    println!("smoother: steps cg {}  gradient descent {}  numbers held {} vs matrix {}", c.steps.len(), g.steps.len(), 4 * n, n * n);
    println!("smoother: f start {:.4}  f cg {:.6}  f elimination {:.6}", fsm(&start), fsm(x), fsm(&xe));
    println!("smoother: minute 0 {:.3} -> {:.3}  minute 500 {:.3} -> {:.3}  minute 999 {:.3} -> {:.3}", y[0], x[0], y[500], x[500], y[999], x[999]);
    println!("smoother: rms error against the true warming, readings {:.3}  smoothed {:.3}", rms(&y), rms(x));
    println!("smoother: log10 |residual| {:.2}  log10 max |cg - elimination| {:.2}", dot(&res, &res).sqrt().log10(), gap_ce.log10());
    println!("smoother: log10 worst A-cosine, first 20 directions {:.2}, all {} {:.2}", acos[..19].iter().cloned().fold(0.0, f64::max).log10(), c.dirs.len(), acos.iter().cloned().fold(0.0, f64::max).log10());
    println!("smoother: kappa {:.2}  bound per step cg {:.4} gd {:.4}  measured cg {:.4} gd {:.4}", kappa, rate_cg, rate_gd, mcg, mgd);
    let ks: Vec<String> = (0..80).step_by(10).map(|k| format!("{:>6}", k)).collect();
    let hc: Vec<String> = (0..80).step_by(10).map(|k| format!("{:6.2}", c.hist[k].log10())).collect();
    let hg: Vec<String> = (0..80).step_by(10).map(|k| format!("{:6.2}", g.hist[k].log10())).collect();
    println!("chart, k   {}\nchart, cg  {}\nchart, gd  {}", ks.join(" "), hc.join(" "), hg.join(" "));
    assert!(gap_ce < 1e-6 && gap_ce <= dot(&res, &res).sqrt() && (fsm(x) - fsm(&xe)).abs() < 1e-9 * fsm(&xe)); // roads 1, 2, 3 agree
    assert!(c.steps.len() < n / 10 && g.steps.len() > 5 * c.steps.len()); // far fewer than n steps, and beats descent
    assert!(ea(x) <= 2.0 * rate_cg.powi(c.steps.len() as i32) * ea(&start) && ea(&g.x) <= rate_gd.powi(g.steps.len() as i32) * ea(&start) && rms(x) < rms(&y) / 3.0); // A-norm bounds; smoothing helps
    // ---- break: an indefinite matrix, a saddle instead of a bowl ----
    let (ai, bi) = ([[1.0, 2.0], [2.0, 1.0]], [3.0, 0.0]);
    let ind = cg(&|v: &[f64]| vec![dot(&ai[0], v), dot(&ai[1], v)], &bi, &[0.0, 0.0], 1e-12, 1.0, 0);
    let xi = &ind.x;
    println!("break: indefinite, pAp {:.1} then {:.1}, ends at ({:.4}, {:.4}) with f {:.4}; f(0, 0) 0.0000, f(10, -10) {:.1}",
        ind.steps[0][2], ind.steps[1][2], xi[0], xi[1], f2(&ai, &bi, xi), f2(&ai, &bi, &[10.0, -10.0]));
    assert!(ind.steps[1][2] < 0.0 && f2(&ai, &bi, xi) > 0.0); // it stops on a saddle, above the start
    // ---- the nonlinear version: the Rosenbrock banana valley, start (-1.2, 1), stop when |grad| < 1e-6 ----
    let runs: Vec<(&str, (usize, f64, f64, usize, Vec<(f64, f64)>))> =
        ["PR+", "FR", "GD"].iter().map(|k| (*k, ncg(k, 0.1))).collect();
    for (kind, (k, xr, yr, rs, _)) in &runs {
        println!("banana {:<3}: {:>5} iterations, ends ({:.6}, {:.6}), restarts {}", kind, k, xr, yr, rs);
    }
    let pp = &runs[0].1 .4;
    let pts: Vec<String> = [0usize, 4, 9, 14, 19].iter().map(|&j| format!("k={} ({:.3}, {:.3})", j + 1, pp[j].0, pp[j].1)).collect();
    println!("banana PR+ path: {}", pts.join(" "));
    let (ka, _, _, rsa, _) = ncg("PR+", 1e9);
    println!("break: PR+ with backtracking only, no curvature test: {} iterations, {} restarts", ka, rsa);
    for (_, (_, xr, yr, _, _)) in &runs { // certificate: f >= 0 everywhere, f(1, 1) = 0
        assert!((xr - 1.0).abs() < 1e-5 && (yr - 1.0).abs() < 1e-5 && fr(*xr, *yr) < 1e-10);
    }
    assert!(runs[2].1 .0 > 100 * runs[0].1 .0 && runs[2].1 .0 > 10 * runs[1].1 .0 && ka > 10 * runs[0].1 .0 && runs[0].1 .0 == 34);
    println!("ALL CHECKS PASS");
}
