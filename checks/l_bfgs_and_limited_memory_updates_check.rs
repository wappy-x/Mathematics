// L-BFGS -- the check behind the card.  std only.  A weather station logs air
// temperature every ten minutes: 50,000 readings d.  The smoothed curve c has one
// coefficient per reading and minimises f(c) = sum (c_i - d_i)^2 + LAM sum (c_{i+1} - c_i)^2.
// L-BFGS keeps the last M step pairs (s, y) and rebuilds each direction by the two-loop
// recursion.  Roads: the run; the gradient certificate; elimination; the dense update.
const N: usize = 50000; const LAM: f64 = 100.0; const M: usize = 10;
const TOL: f64 = 0.002; // on |g|: every value within 0.001 C
type V = Vec<f64>;
struct Run { x: V, k: usize, ev: usize, hist: V, probe: Option<(V, V, Vec<V>, Vec<V>)>, uphill: Option<f64> }

fn rnd(state: &mut u64) -> f64 { // SplitMix64
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}
fn dot(a: &[f64], b: &[f64]) -> f64 { // compensated, to match the Python sumprod
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for (x, y) in a.iter().zip(b) {
        let (p, t) = (x * y, s + x * y);
        let pe = x.mul_add(*y, -p);
        c += if s.abs() >= p.abs() { (s - t) + p } else { (p - t) + s } + pe;
        s = t;
    }
    s + c
}
fn norm(v: &[f64]) -> f64 { dot(v, v).sqrt() }
fn sub(a: &[f64], b: &[f64]) -> V { a.iter().zip(b).map(|(x, y)| x - y).collect() }
fn sci(x: f64, p: usize) -> String { // Python-style exponent: 3.2e-08
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn fg(c: &[f64], d: &[f64]) -> (f64, V) {
    let r = sub(c, d);
    let df: V = (0..c.len() - 1).map(|i| c[i + 1] - c[i]).collect();
    let mut g: V = r.iter().map(|x| 2.0 * x).collect();
    for (i, x) in df.iter().enumerate() { g[i] -= 2.0 * LAM * x; g[i + 1] += 2.0 * LAM * x; }
    (dot(&r, &r) + LAM * dot(&df, &df), g)
}
fn solve(b: &[f64]) -> V { // A x = b by elimination; A = 2(I + LAM D^T D)
    let (off, mut cp, mut bp) = (-2.0 * LAM, vec![0.0; N], vec![0.0; N]);
    for i in 0..N {
        let dg = if i == 0 || i == N - 1 { 2.0 * (1.0 + LAM) } else { 2.0 * (1.0 + 2.0 * LAM) };
        let den = dg - if i > 0 { off * cp[i - 1] } else { 0.0 };
        (cp[i], bp[i]) = (off / den, (b[i] - if i > 0 { off * bp[i - 1] } else { 0.0 }) / den);
    }
    for i in (0..N - 1).rev() { bp[i] -= cp[i] * bp[i + 1]; }
    bp
}
fn two_loop(g: &[f64], s: &[V], y: &[V], order: i32, gam: Option<f64>) -> V {
    let n = s.len();
    let idx: Vec<usize> = if order == 1 { (0..n).rev().collect() } else { (0..n).collect() };
    let (mut q, mut al) = (g.to_vec(), vec![0.0; n]);
    for &i in &idx { // newest pair first
        al[i] = dot(&s[i], &q) / dot(&y[i], &s[i]);
        for j in 0..q.len() { q[j] -= al[i] * y[i][j]; } }
    let gam = gam.unwrap_or(if n > 0 { dot(&s[n - 1], &y[n - 1]) / dot(&y[n - 1], &y[n - 1]) } else { 1.0 / norm(g) });
    let mut r: V = q.iter().map(|u| gam * u).collect();
    for &i in idx.iter().rev() { // oldest pair first
        let b = dot(&y[i], &r) / dot(&y[i], &s[i]);
        for j in 0..r.len() { r[j] += (al[i] - b) * s[i][j]; } }
    r.iter().map(|u| -u).collect()
}
fn lbfgs(f_g: &dyn Fn(&[f64]) -> (f64, V), x0: V, m: usize, tol: f64, keep: usize, probe: Option<usize>, skip: bool, order: i32) -> Run {
    let (mut x, (mut f, mut g)) = (x0.clone(), f_g(&x0));
    let (mut s, mut y, mut k, mut ev, mut hist, mut pr): (Vec<V>, Vec<V>, usize, usize, V, _) = (vec![], vec![], 0, 1, vec![], None);
    while norm(&g) > tol && k < 400 {
        hist.push(norm(&g));
        if probe == Some(k) { pr = Some((x.clone(), g.clone(), s.clone(), y.clone())); }
        let lo = s.len().saturating_sub(m);
        let dd = if m > 0 { two_loop(&g, &s[lo..], &y[lo..], order, None) } else { two_loop(&g, &[], &[], 1, None) };
        let (slope, mut t) = (dot(&g, &dd), 1.0);
        if slope >= 0.0 { return Run { x, k, ev, hist, probe: None, uphill: Some(slope) }; }
        let (xn, fn_, gn) = loop { // backtrack until the cost falls enough
            let xn: V = x.iter().zip(&dd).map(|(a, b)| a + t * b).collect();
            let (fn_, gn) = f_g(&xn);
            ev += 1;
            if fn_ <= f + 1e-4 * t * slope || t < 1e-12 { break (xn, fn_, gn); } else { t *= 0.5; } // floor
        };
        let (sk, yk) = (sub(&xn, &x), sub(&gn, &g));
        if dot(&sk, &yk) > 0.0 || !skip { s.push(sk); y.push(yk); } // curvature test
        let cap = m.max(keep);
        if s.len() > cap { s.drain(..s.len() - cap); y.drain(..y.len() - cap); }
        (x, f, g, k) = (xn, fn_, gn, k + 1);
    }
    Run { x, k, ev, hist, probe: pr, uphill: None }
}
fn banana(v: &[f64]) -> (f64, V) { // the house example, minimised at (1, 1)
    let (a, b) = (v[0], v[1]);
    (100.0 * (b - a * a).powi(2) + (1.0 - a).powi(2), vec![-400.0 * a * (b - a * a) - 2.0 * (1.0 - a), 200.0 * (b - a * a)])
}
fn main() {
    let (mut st, pi) = (2026u64, std::f64::consts::PI);
    let d: V = (0..N).map(|i| { let i = i as f64; 11.0 - 7.0 * (2.0 * pi * i / 52560.0).cos() + 4.0 * (2.0 * pi * i / 144.0).sin() + 3.0 * (rnd(&mut st) - 0.5) }).collect();
    let fit = |c: &[f64]| fg(c, &d);
    let cs = solve(&d.iter().map(|v| 2.0 * v).collect::<V>());
    let (fs, gs) = fit(&cs);
    println!("readings {}, {:.1} days; LAM {:.0}; exact fit cost {:.4}, |g| {}", N, N as f64 * 10.0 / 1440.0, LAM, fs, sci(norm(&gs), 1));
    let h = 0.01; // nudge the raw readings and the exact fit, where c - d is not zero
    let fd = [&d, &cs].iter().flat_map(|p| [0, 25000, N - 1].map(|i| { let (mut up, mut dn) = (p.to_vec(), p.to_vec()); (up[i], dn[i]) = (up[i] + h, dn[i] - h);
        ((fit(&up).0 - fit(&dn).0) / (2.0 * h) - fit(&p[..]).1[i]).abs() })).fold(0.0, f64::max);
    println!("gradient vs central difference at values 0, 25000, 49999 of the readings and the exact fit: largest gap {}", sci(fd, 1));
    let run = lbfgs(&fit, d.clone(), M, TOL, 20, Some(40), true, 1);
    assert!(run.uphill.is_none(), "every direction on the fit points downhill");
    let (xp, gp, sp, yp) = run.probe.clone().unwrap();
    let (f, g) = fit(&run.x);
    let (gap, h0) = (run.x.iter().zip(&cs).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max), run.hist[0]);
    println!("L-BFGS, m={}, from k=0 at the raw readings (|g| {:.1}): {} iterations, {} cost evaluations", M, h0, run.k, run.ev);
    println!("cost {:.4}; certificate: |g| {:.6}, so every value within |g|/2 = {:.6} C", f, norm(&g), norm(&g) / 2.0);
    println!("largest gap to the exact fit: {} C", sci(gap, 2));
    println!("reading 25000 (day {:.1}): raw {:.3} C, smoothed {:.3} C", 25000.0 * 10.0 / 1440.0, d[25000], run.x[25000]);
    println!("dense matrix: {} numbers = {:.1} GB; {} pairs: {} numbers = {:.1} MB", N * N, (N * N * 8) as f64 / 1e9, M, 2 * M * N, (2 * M * N * 8) as f64 / 1e6);
    println!("multiply-adds per direction: dense {}, two-loop 4mn + n = {}", N * N, 4 * M * N + N);
    let lip = 2.0 + 8.0 * LAM; // L, the steepest curvature
    println!("gradient descent, step 1/L: L = {:.0}, mu = 2, needs about {} iterations (estimate)", lip, ((h0 / TOL).ln() / -(1.0 - 2.0 / lip).ln()).ceil());
    println!("chart, log10 bound every 10 iterations: {}", run.hist.iter().step_by(10).map(|v| format!("{:.2}", (v / 2.0).log10())).collect::<Vec<_>>().join(" "));
    let mut sweep: Vec<(usize, usize, usize)> = [1, 3, 5, 20].iter().map(|&m| { let r = lbfgs(&fit, d.clone(), m, TOL, 0, None, true, 1); (m, r.k, r.ev) }).collect();
    sweep.push((M, run.k, run.ev)); sweep.sort();
    for (m, k, ev) in &sweep { println!("sweep m={:<2}: {:3} iterations, {:3} evaluations, {:4.1} MB", m, k, ev, (2 * m * N * 8) as f64 / 1e6); }
    let (newton, g40) = (solve(&gp.iter().map(|v| -v).collect::<V>()), dot(&sp[sp.len() - 1], &yp[yp.len() - 1]) / dot(&yp[yp.len() - 1], &yp[yp.len() - 1])); // Newton's step at k = 40
    let dirs: Vec<V> = [0usize, 10, 20].iter().map(|&m| two_loop(&gp, &sp[sp.len() - m..], &yp[yp.len() - m..], 1, if m > 0 { None } else { Some(g40) })).collect();
    let show = |f: &dyn Fn(&V) -> f64| dirs.iter().map(|v| format!("{:.3}", f(v))).collect::<Vec<_>>().join(" ");
    println!("at k=40 vs Newton's step, m = 0 10 20: cosine {}; length ratio {}", show(&|v| dot(v, &newton) / norm(v) / norm(&newton)), show(&|v| norm(v) / norm(&newton)));
    let lo = sp.len() - M;
    let (right, ones) = (two_loop(&gp, &sp[lo..], &yp[lo..], 1, None), two_loop(&gp, &sp[lo..], &yp[lo..], 1, Some(1.0)));
    let (mut t, fp) = (1.0f64, fit(&xp).0);
    let step = |dd: &V, t: f64| xp.iter().zip(dd).map(|(a, b)| a + t * b).collect::<V>();
    while fit(&step(&ones, t)).0 > fp + 1e-4 * t * dot(&gp, &ones) { t *= 0.5; }
    println!("break, no scaling: step {:.1} long (right {:.3}); cost at t=1 {:.0} (right {:.1}); halvings {}",
             norm(&ones), norm(&right), fit(&step(&ones, 1.0)).0, fit(&step(&right, 1.0)).0, (-t.log2()).round());
    let b1 = lbfgs(&banana, vec![-1.2, 1.0], 1, 1e-6, 0, Some(1), true, 1);
    let (x1, g1, s1, y1) = b1.probe.unwrap();
    let (s0, y0) = (&s1[0], &y1[0]);
    let (sy, yy, sg) = (dot(s0, y0), dot(y0, y0), dot(s0, &g1));
    println!("banana, x1 = ({:.4}, {:.4}), g1 = ({:.4}, {:.4})", x1[0], x1[1], g1[0], g1[1]);
    println!("  s0 = ({:.5}, {:.5}), y0 = ({:.4}, {:.4}), s.y {:.4}, y.y {:.2}, s.g1 {:.4}", s0[0], s0[1], y0[0], y0[1], sy, yy, sg);
    let al = sg / sy; // the two-loop with one pair, by hand
    let (q, dh): (V, V) = (g1.iter().zip(y0).map(|(u, v)| u - al * v).collect(), two_loop(&g1, &s1, &y1, 1, None));
    let be = dot(y0, &q.iter().map(|u| sy / yy * u).collect::<V>()) / sy;
    println!("  alpha {:.6}, q = ({:.4}, {:.4}), gamma {:.7}, beta {:.6}, d1 = ({:.6}, {:.6})", al, q[0], q[1], sy / yy, be, dh[0], dh[1]);
    let (_, g6, s6, y6) = lbfgs(&banana, vec![-1.2, 1.0], 10, 1e-6, 0, Some(6), true, 1).probe.unwrap();
    let n6 = s6.len();
    let gm = dot(&s6[n6 - 1], &y6[n6 - 1]) / dot(&y6[n6 - 1], &y6[n6 - 1]);
    let mut bi = [[gm, 0.0], [0.0, gm]];
    for (s, y) in s6.iter().zip(&y6) { // road 4: the dense inverse update, pair by pair
        let p = 1.0 / dot(s, y);
        let v = |i: usize, j: usize| (i == j) as i32 as f64 - p * y[i] * s[j];
        let e = |i: usize, j: usize| (0..4).map(|ab| v(ab / 2, i) * bi[ab / 2][ab % 2] * v(ab % 2, j)).sum::<f64>() + p * s[i] * s[j];
        bi = [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]];
    }
    let (dd6, tl6): (V, V) = (bi.iter().map(|row| -dot(row, &g6)).collect(), two_loop(&g6, &s6, &y6, 1, None));
    println!("banana k=6, {} pairs: two-loop ({:.6}, {:.6}), dense ({:.6}, {:.6})", n6, tl6[0], tl6[1], dd6[0], dd6[1]);
    let bad = lbfgs(&banana, vec![-1.2, 1.0], 10, 1e-6, 0, None, false, 1);
    let good = lbfgs(&banana, vec![-1.2, 1.0], 10, 1e-6, 0, None, true, 1);
    let rev = lbfgs(&banana, vec![-1.2, 1.0], 10, 1e-6, 0, None, true, -1); // break: each loop in reverse order
    println!("banana, no curvature test: stuck at k={}, slope {:+.4} (uphill), cost {:.4}", bad.k, bad.uphill.unwrap(), banana(&bad.x).0);
    println!("banana, with the test: ({:.6}, {:.6}) after {} iterations, {} evaluations", good.x[0], good.x[1], good.k, good.ev);
    println!("banana, each loop reversed: {} iterations, {} evaluations", rev.k, rev.ev);
    assert!(norm(&gs) < 1e-8 && fd < 1e-4, "elimination solves A c = 2d; gradient matches differences");
    assert!(gap <= norm(&g) / 2.0 && gap < 1e-3, "the certificate bounds the true gap to the exact fit");
    assert!((f - fs).abs() < 1e-6 * fs, "L-BFGS reaches the exact fit's cost");
    assert!(tl6.iter().zip(&dd6).all(|(a, b)| (a - b).abs() < 1e-9), "two-loop equals the dense inverse update");
    assert!(bad.uphill.is_some() && good.x.iter().all(|v| (v - 1.0).abs() < 1e-6), "s.y > 0 is needed and enough");
    assert!(sweep.iter().find(|r| r.0 == M).unwrap().1 < sweep[0].1 && rev.ev > good.ev, "ten pairs beat one; loop order matters");
    println!("ALL CHECKS PASS");
}
