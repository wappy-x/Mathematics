// Line search, Armijo and Wolfe -- the same check as the Python, in Rust.  No
// crates.  The cost is the Rosenbrock banana f(x, y) = (1 - x)^2 + 100 (y - x^2)^2,
// minimised; the start is (-1.2, 1); the direction is straight downhill, d = -grad f.
const C1: f64 = 1e-4; // sufficient-decrease constant
const C2: f64 = 0.9; // curvature constant
type P = (f64, f64);

fn f(p: P) -> f64 { let (x, y) = p; (1.0 - x) * (1.0 - x) + 100.0 * (y - x * x) * (y - x * x) }
fn grad(p: P) -> P {                       // the slope in x and in y, by hand
    let (x, y) = p;
    (-2.0 * (1.0 - x) - 400.0 * x * (y - x * x), 200.0 * (y - x * x))
}
fn dot(a: P, b: P) -> f64 { a.0 * b.0 + a.1 * b.1 }
fn mv(p: P, a: f64, d: P) -> P { (p.0 + a * d.0, p.1 + a * d.1) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn norm(p: P) -> f64 { dot(p, p).sqrt() }

fn checks_with(p: P, d: P, a: f64, c1: f64, c2: f64) -> (bool, bool, f64) { // Armijo, curvature, new slope
    let (s0, q) = (dot(grad(p), d), mv(p, a, d));
    let s1 = dot(grad(q), d);
    (f(q) <= f(p) + c1 * a * s0, s1 >= c2 * s0, s1)
}
fn checks(p: P, d: P, a: f64) -> (bool, bool, f64) { checks_with(p, d, a, C1, C2) }
fn backtrack_with(p: P, d: P, c1: f64, cut: f64) -> (f64, u32) { // halve (or cut) until the Armijo test passes
    let (mut a, mut n) = (1.0, 0);
    while !checks_with(p, d, a, c1, C2).0 { a /= cut; n += 1; }
    (a, n)
}
fn backtrack(p: P, d: P) -> (f64, u32) { backtrack_with(p, d, C1, 2.0) }
fn wolfe(p: P, d: P, c2: f64) -> (f64, Vec<f64>) { // bisection search for both Wolfe tests
    let (mut lo, mut hi, mut a, mut trials) = (0.0, f64::INFINITY, 1.0, Vec::new());
    loop {
        let (arm, cur, _) = checks_with(p, d, a, C1, c2);
        trials.push(a);
        if !arm { hi = a } else if !cur { lo = a } else { return (a, trials) }
        a = if hi.is_finite() { (lo + hi) / 2.0 } else { 2.0 * lo };
    }
}
fn descend(x0: P, c1: f64, cut: f64) -> (P, usize, u32, Vec<usize>) { // gradient descent with backtracking, to |grad| < 1e-4; watch the sign of s.y
    let (mut p, mut k, mut evals, mut bad) = (x0, 0usize, 0u32, Vec::new());
    while norm(grad(p)) >= 1e-4 {
        let g = grad(p);
        let d = (-g.0, -g.1);
        let (a, n) = backtrack_with(p, d, c1, cut);
        evals += n + 1;
        let q = mv(p, a, d);
        if a * (dot(grad(q), d) - dot(g, d)) <= 0.0 { bad.push(k) }
        p = q; k += 1;
    }
    (p, k, evals, bad)
}
fn pmul(p: &[f64], q: &[f64]) -> Vec<f64> {
    let mut out = vec![0.0; p.len() + q.len() - 1];
    for (i, pi) in p.iter().enumerate() { for (k, qk) in q.iter().enumerate() { out[i + k] += pi * qk } }
    out
}

fn main() {
    let x0: P = (-1.2, 1.0);
    let g0 = grad(x0);
    let d0 = (-g0.0, -g0.1);
    let slope0 = dot(g0, d0);
    let h = 1e-6;                          // road 2 for the slope: central differences
    let cd = ((f((x0.0 + h, x0.1)) - f((x0.0 - h, x0.1))) / (2.0 * h),
              (f((x0.0, x0.1 + h)) - f((x0.0, x0.1 - h))) / (2.0 * h));
    println!("start (-1.2, 1), cost {:.4}; gradient ({:.2}, {:.2}); by central differences ({:.2}, {:.2})",
             f(x0), g0.0, g0.1, cd.0, cd.1);
    println!("direction d = ({:.2}, {:.2}); slope along d at step 0: {:.2}", d0.0, d0.1, slope0);
    println!("halvings  step              cost after   Armijo bar  Armijo  curvature");
    for j in 0..16 {
        let a = 0.5f64.powi(j);
        let (arm, cur, _) = checks(x0, d0, a);
        println!("{:>8}  1/{:<6} {:>22.4} {:>11.4}  {:>6}  {:>9}", j, 1u64 << j, f(mv(x0, a, d0)),
                 f(x0) + C1 * a * slope0, yn(arm), yn(cur));
    }
    let (a0, n0) = backtrack(x0, d0);
    let x1 = mv(x0, a0, d0);
    println!("backtracking: {} halvings, step 1/{}, lands at ({:.4}, {:.4}), cost {:.4}",
             n0, (1.0 / a0).round(), x1.0, x1.1, f(x1));
    // Road 2: phi(a) = f(x0 + a d0) as a quartic, coefficients built by polynomial algebra
    let u = [1.0 - x0.0, -d0.0];
    let v = [x0.1 - x0.0 * x0.0, d0.1 - 2.0 * x0.0 * d0.0, -d0.0 * d0.0];
    let (uu, vv) = (pmul(&u, &u), pmul(&v, &v));
    let phi: Vec<f64> = (0..5).map(|i| vv[i] * 100.0 + if i < 3 { uu[i] } else { 0.0 }).collect();
    let pval = |a: f64| -> f64 { phi.iter().enumerate().map(|(i, c)| c * a.powi(i as i32)).sum() };
    let cs: Vec<String> = phi.iter().map(|c| format!("{:.1}", c)).collect();
    println!("phi(a) coefficients, a^0..a^4: {}", cs.join(", "));
    let (mut lo, mut hi) = (0.5f64.powi(12), 0.5f64.powi(6));
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if pval(mid) <= phi[0] + C1 * mid * phi[1] { lo = mid } else { hi = mid }
    }
    let gap = (0..16).map(|j| { let a = 0.5f64.powi(j); let t = f(mv(x0, a, d0)); (pval(a) - t).abs() / t })
        .fold(0.0, f64::max);
    println!("phi'(0) = {:.2}; Armijo holds up to a = {:.7} = 1/{:.1}; quartic matches f to 1e-9: {}",
             phi[1], lo, 1.0 / lo, yn(gap < 1e-9));
    let (p, k, evals, bad) = descend(x0, C1, 2.0);
    println!("descent + backtracking: {} iterations, {} cost evaluations, ends at ({:.4}, {:.4}), cost {:.11}; steps with s.y <= 0: {:?}",
             k, evals, p.0, p.1, f(p), bad);
    let mut p = x0;
    for _ in 0..bad[0] { let g = grad(p); let d = (-g.0, -g.1); p = mv(p, backtrack(p, d).0, d); }
    let g = grad(p);
    let d = (-g.0, -g.1);
    let sl = dot(g, d);
    let (a, _) = backtrack(p, d);
    let (_, cur, s1) = checks(p, d, a);
    let s = [a * d.0, a * d.1];
    let q = mv(p, a, d);
    let gq = grad(q);
    let yv = [gq.0 - g.0, gq.1 - g.1];
    let (sy, ss) = (s[0] * yv[0] + s[1] * yv[1], s[0] * s[0] + s[1] * s[1]);
    println!("step {}: at ({:.4}, {:.4}), cost {:.4}, slope {:.2}", bad[0], p.0, p.1, f(p), sl);
    println!("  Armijo step 1/{}: cost {:.4}, new slope {:.2}, curvature {}, s.y = {:.2}",
             (1.0 / a).round(), f(q), s1, yn(cur), sy);
    let mut b = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 {
        b[i][j] = (if i == j { 1.0 } else { 0.0 }) - s[i] * s[j] / ss + yv[i] * yv[j] / sy;
    } }
    let mut sbs = 0.0;
    for i in 0..2 { for j in 0..2 { sbs += s[i] * b[i][j] * s[j] } }
    let det = b[0][0] * b[1][1] - b[0][1] * b[1][0];
    let dn = (-(b[1][1] * gq.0 - b[0][1] * gq.1) / det, -(b[0][0] * gq.1 - b[1][0] * gq.0) / det);
    println!("  BFGS update from B = I: s.B.s = {:.2}; next direction ({:.4}, {:.4}), slope {:.2} (uphill)",
             sbs, dn.0, dn.1, dot(gq, dn));
    let (aw, tr) = wolfe(p, d, C2);
    let qw = mv(p, aw, d);
    let syw = aw * (dot(grad(qw), d) - sl);
    let ts: Vec<String> = tr.iter().map(|t| format!("{:.5}", t)).collect();
    println!("  Wolfe trials: {}; accepted {:.5}, cost {:.4}, s.y = {:.2}, floor (1 - c2) a |slope| = {:.4}",
             ts.join(", "), aw, f(qw), syw, (1.0 - C2) * aw * -sl);
    // The three mistakes, and the fixed step for comparison
    let tiny = mv(x0, 1e-6, d0);
    let (arm_t, cur_t, s_t) = checks(x0, d0, 1e-6);
    let (mut pf, mut kf) = (x0, 0usize);
    while norm(grad(pf)) >= 1e-4 { let g = grad(pf); pf = mv(pf, -a0, g); kf += 1; }
    println!("mistake 1, no search, step 1: lands at ({:.1}, {:.1}), cost {:.1}",
             x0.0 + d0.0, x0.1 + d0.1, f(mv(x0, 1.0, d0)));
    println!("mistake 2, start at step 1e-6: cost {:.4}; Armijo {}, curvature {} (slope {:.2} against bar {:.2})",
             f(tiny), yn(arm_t), yn(cur_t), s_t, C2 * slope0);
    println!("mistake 3, fixed step 1/1024 throughout: {} iterations, against {} with backtracking", kf, k);
    // Try changing: c1 = 0.5; cutting the step by 10; c2 = 0.1 (the run above is unchanged)
    let (a5, n5) = backtrack_with(x0, d0, 0.5, 2.0);
    println!("try c1 = 0.5: first search {} halvings, step 1/{}, cost {:.4}; {} iterations",
             n5, (1.0 / a5).round(), f(mv(x0, a5, d0)), descend(x0, 0.5, 2.0).1);
    let a10 = backtrack_with(x0, d0, C1, 10.0).0;
    let (_, k10, _, bad10) = descend(x0, C1, 10.0);
    println!("try cut by 10: first step 1/{}, cost {:.4}; {} iterations; steps with s.y <= 0: {:?}",
             (1.0 / a10).round(), f(mv(x0, a10, d0)), k10, bad10);
    let fails: Vec<i32> = (0..16).filter(|&j| !checks_with(x0, d0, 0.5f64.powi(j), C1, 0.1).1).collect();
    let both: Vec<i32> = (0..16).filter(|&j| { let (a, c, _) = checks_with(x0, d0, 0.5f64.powi(j), C1, 0.1); a && c }).collect();
    let aw1 = wolfe(p, d, 0.1).0;
    println!("try c2 = 0.1: curvature fails after halvings {:?}, both pass only after {:?}; step {} Wolfe accepts {:.5}, floor {:.4}",
             fails, both, bad[0], aw1, (1.0 - 0.1) * aw1 * -sl);
    let pts: Vec<String> = (7..11).map(|j| { let t = mv(x0, 0.5f64.powi(j), d0); format!("({:.3}, {:.3})", t.0, t.1) }).collect();
    println!("figure, start (-1.2, 1); trials 7-10 at {}; minimum (1, 1)", pts.join("; "));
    assert!((cd.0 - g0.0).abs() < 1e-4 && (cd.1 - g0.1).abs() < 1e-4); // slope: formula vs differences
    assert!(n0 == 10 && 2.0 * a0 > lo && lo >= a0);                    // backtracking vs quartic boundary
    assert!(gap < 1e-9 && (phi[1] - slope0).abs() < 1e-6);             // quartic vs direct cost
    assert!(checks(x0, d0, lo * (1.0 - 1e-6)).0 && !checks(x0, d0, hi * (1.0 + 1e-6)).0); // direct test vs quartic
    assert!(sy < 0.0 && (sbs - sy).abs() < 1e-6 * sy.abs() && dot(gq, dn) > 0.0); // secant: s.B.s = s.y
    assert!(syw >= (1.0 - C2) * aw * -sl && (1.0 - C2) * aw * -sl > 0.0 && f(qw) < f(q));
    assert!(arm_t && !cur_t && kf > 2 * k);
    println!("ALL CHECKS PASS");
}
