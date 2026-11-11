// Nonlinear least squares -- the same check as the Python, in Rust.  No crates.
// A pan cools from about 200 C; 40 probe readings, one every 30 s.  Fit the
// decay T(t) = c + a exp(-b t) by Gauss-Newton and Levenberg-Marquardt.
// Sums use the same compensated adding as Python's sum, so the digits agree.
type M = Vec<Vec<f64>>;
fn sum(xs: impl Iterator<Item = f64>) -> f64 {
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in xs { let t = s + x; c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn sci(x: f64, p: usize) -> String {                // Python's e-format: two-digit exponent with sign
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn readings(sd: f64) -> Vec<f64> {                  // SplitMix64; 12 uniforms - 6 ~ bell curve
    let mut s: u64 = 2026;
    (1..=40).map(|i| {
        let mut u = 0.0;
        for _ in 0..12 {
            s = s.wrapping_add(0x9E3779B97F4A7C15);
            let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            u += ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0;
        }
        21.0 + 180.0 * (-0.15 * 0.5 * i as f64).exp() + sd * (u - 6.0)
    }).collect()
}
fn ts() -> Vec<f64> { (1..=40).map(|i| 0.5 * i as f64).collect() }
fn misses(th: &[f64], ys: &[f64], wrong: bool) -> (Vec<f64>, M) {   // misses r_i and slope table J
    let (c, a, b) = (th[0], th[1], th[2]);
    let r = ts().iter().zip(ys).map(|(t, y)| c + a * (-b * t).exp() - y).collect();
    let j = ts().iter().map(|t| vec![1.0, (-b * t).exp(), -(if wrong { 1.0 } else { a }) * t * (-b * t).exp()]).collect();
    (r, j)
}
fn loss(th: &[f64], ys: &[f64]) -> f64 { 0.5 * sum(misses(th, ys, false).0.iter().map(|x| x * x)) }
fn solve(a: &M, b: &[f64]) -> Vec<f64> {            // Gaussian elimination with row swaps
    let n = b.len();
    let mut m: M = (0..n).map(|i| { let mut row = a[i].clone(); row.push(b[i]); row }).collect();
    for col in 0..n {
        let mut p = col;
        for q in col + 1..n { if m[q][col].abs() > m[p][col].abs() { p = q } }; m.swap(col, p);
        for q in col + 1..n { let f = m[q][col] / m[col][col]; for j in col..=n { m[q][j] -= f * m[col][j] } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - sum((i + 1..n).map(|j| m[i][j] * x[j]))) / m[i][i] }
    x
}
fn dot(p: &[f64], q: &[f64]) -> f64 { sum(p.iter().zip(q).map(|(x, y)| x * y)) }
fn normal(j: &M, r: &[f64]) -> (M, Vec<f64>) {      // J^T J, and the gradient g = J^T r
    let n = j[0].len();
    let cols: M = (0..n).map(|i| j.iter().map(|w| w[i]).collect()).collect();
    ((0..n).map(|i| (0..n).map(|q| dot(&cols[i], &cols[q])).collect()).collect(), (0..n).map(|i| dot(&cols[i], r)).collect())
}
fn model(r: &[f64], j: &M, d: &[f64]) -> f64 { 0.5 * sum(r.iter().zip(j).map(|(x, w)| { let e = x + dot(w, d); e * e })) }
struct Step { new: Vec<f64>, pred: f64, size: f64, r: Vec<f64>, j: M, a: M, d: Vec<f64> }
fn step(th: &[f64], ys: &[f64], lam: f64, wrong: bool) -> Step {   // damped; lam = 0 is plain Gauss-Newton
    let (r, j) = misses(th, ys, wrong); let (a, g) = normal(&j, &r);
    let damped: M = (0..3).map(|i| (0..3).map(|q| a[i][q] + if i == q { lam * a[i][i] } else { 0.0 }).collect()).collect();
    let d = solve(&damped, &g.iter().map(|x| -x).collect::<Vec<_>>());
    let pred = -dot(&g, &d) - 0.5 * sum(j.iter().map(|w| dot(w, &d) * dot(w, &d)));
    let size = sum((0..3).map(|i| a[i][i] * d[i] * d[i])).sqrt();
    Step { new: th.iter().zip(&d).map(|(p, q)| p + q).collect(), pred, size, r, j, a, d }
}
fn lm(th0: &[f64], ys: &[f64], show: bool) -> Vec<f64> {   // accept if F falls: lam / 3; refuse: lam x 3
    let (mut th, mut lam, mut steps) = (th0.to_vec(), 1e-3, 0);
    while steps < 200 {
        let mut refused = 0;
        let (new, rho) = loop {
            let s = step(&th, ys, lam, false);
            if s.size < 1e-7 { return th }
            let drop = loss(&th, ys) - loss(&s.new, ys);
            if drop > 0.0 { break (s.new, if s.pred > 0.0 { drop / s.pred } else { 0.0 }) }
            lam *= 3.0; refused += 1;
        };
        if show { println!("LM step {} lambda {:8.6} refused {}  c {:8.4}  a {:8.4}  b {:7.5}  F {:13.6}  rho {:4.2}", steps + 1, lam, refused, new[0], new[1], new[2], loss(&new, ys), rho) }
        th = new; lam /= 3.0; steps += 1;
    }
    th
}
fn profile(b: f64, ys: &[f64]) -> (f64, f64, f64) {        // road 2: fix b; c, a are a straight-line fit
    let (a, g) = normal(&ts().iter().map(|t| vec![1.0, (-b * t).exp()]).collect(), ys);
    let x = solve(&a, &g); (x[0], x[1], loss(&[x[0], x[1], b], ys))
}
fn dropped(th: &[f64], ys: &[f64]) -> (f64, M) {   // S = sum r_i (Hessian of r_i): what Gauss-Newton leaves out
    let (r, j) = misses(th, ys, false); let a = normal(&j, &r).0;
    let mut s = vec![vec![0.0; 3]; 3];
    for (t, x) in ts().iter().zip(&r) {
        let e = (-th[2] * t).exp(); s[1][2] -= x * t * e; s[2][1] -= x * t * e; s[2][2] += x * th[1] * t * t * e;
    }
    let (mut v, mut big) = (vec![1.0; 3], 0.0);
    for _ in 0..300 {                                // power iteration: biggest stretch of (J^T J)^-1 S
        let w = solve(&a, &(0..3).map(|i| sum((0..3).map(|q| s[i][q] * v[q]))).collect::<Vec<_>>());
        big = w.iter().fold(0.0f64, |m, x| m.max(x.abs())); v = w.iter().map(|x| x / big).collect();
    }
    (big, (0..3).map(|i| (0..3).map(|q| a[i][q] + s[i][q]).collect()).collect())
}
fn main() {
    let ys = readings(1.5);
    for row in 0..4 {
        println!("readings {:2}-{:2} (C){}", 10 * row + 1, 10 * row + 10, ys[10 * row..10 * row + 10].iter().map(|y| format!("{:7.2}", y)).collect::<String>());
    }
    let start = vec![30.0, 160.0, 0.6]; let f0 = loss(&start, &ys);
    println!("start c {:.1}  a {:.1}  b {:.1}  F {:.4}", start[0], start[1], start[2], f0);
    let gn1 = step(&start, &ys, 0.0, false).new; let gn2 = step(&gn1, &ys, 0.0, false).new;
    for (n, th) in [(1, &gn1), (2, &gn2)] {
        println!("pure Gauss-Newton step {}: c {:.4}  a {:.4}  b {:.5}  F {}", n, th[0], th[1], th[2], sci(loss(th, &ys), 4));
    }
    for lam in [0.0, 0.01, 0.1, 1.0, 10.0] {
        let s = step(&start, &ys, lam, false);
        println!("first step, lambda {:5.2}: scaled length {:7.3}  b {:8.5}  F {}  predicted drop {}  rho {:.3}", lam, s.size, s.new[2],
                 sci(loss(&s.new, &ys), 4), sci(s.pred, 4), (f0 - loss(&s.new, &ys)) / s.pred);
    }
    let (s1, mut best) = (step(&start, &ys, 1.0, false), f64::INFINITY);
    for p in 0..61 { for q in 0..120 { for f in [0.25, 0.5, 0.75, 1.0] {
        let (pa, qa) = (p as f64 * std::f64::consts::PI / 60.0, q as f64 * std::f64::consts::PI / 60.0);
        let z = [pa.sin() * qa.cos(), pa.sin() * qa.sin(), pa.cos()];
        let dd: Vec<f64> = (0..3).map(|j| z[j] * f * s1.size / s1.a[j][j].sqrt()).collect();
        best = best.min(model(&s1.r, &s1.j, &dd));
    }}}
    let m1 = model(&s1.r, &s1.j, &s1.d);
    println!("trust region, lambda 1: model at the step {:.4}; best of 29280 points in the same ball {:.4}", m1, best);
    let fit = lm(&start, &ys, true); let f = loss(&fit, &ys);
    println!("fit: c {:.6} C  a {:.6} C  b {:.6} per min  F {:.6}  rms miss {:.4} C", fit[0], fit[1], fit[2], f, (2.0 * f / 40.0).sqrt());
    println!("half-life of the heat above room: ln 2 / b = {:.4} min; T(0) = c + a = {:.4} C", 2.0f64.ln() / fit[2], fit[0] + fit[1]);
    let (mut lo, mut hi, phi) = (0.05f64, 0.5f64, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..80 {                                 // golden-section search on the profile
        let (m1, m2) = (hi - phi * (hi - lo), lo + phi * (hi - lo));
        if profile(m1, &ys).2 < profile(m2, &ys).2 { hi = m2 } else { lo = m1 }
    }
    let bp = 0.5 * (lo + hi); let (cp, ap, fp) = profile(bp, &ys); let mut gj = 1;
    for j in 2..=100 { if profile(0.01 * j as f64, &ys).2 < profile(0.01 * gj as f64, &ys).2 { gj = j } }
    let grid = 0.01 * gj as f64;
    println!("road 2, profile in b: c {:.6}  a {:.6}  b {:.6}  F {:.6}; best b on the grid 0.01..1.00: {:.2}", cp, ap, bp, fp, grid);
    let (rf, jf) = misses(&fit, &ys, false); let (g, h) = (normal(&jf, &rf).1, dropped(&fit, &ys).1);
    let minors = [h[0][0], h[0][0] * h[1][1] - h[0][1] * h[0][1],
        sum((0..3).map(|j| h[0][j] * (h[1][(j + 1) % 3] * h[2][(j + 2) % 3] - h[1][(j + 2) % 3] * h[2][(j + 1) % 3])))];
    println!("road 3, gradient at the fit: {}; Hessian minors {}", g.iter().map(|x| sci(*x, 1)).collect::<Vec<_>>().join("  "), minors.iter().map(|x| sci(*x, 4)).collect::<Vec<_>>().join("  "));
    let mut rates = vec![];
    for sd in [1.5, 15.0, 30.0] {
        let y2 = readings(sd); let f2 = lm(&[30.0, 160.0, 0.1], &y2, false);
        let th1 = step(&[f2[0], f2[1], f2[2] + 0.001], &y2, 0.0, false).new;
        let th2 = step(&th1, &y2, 0.0, false).new; rates.push((dropped(&f2, &y2).0, (th2[2] - f2[2]).abs() / (th1[2] - f2[2]).abs()));
        let (p, m) = rates[rates.len() - 1];
        println!("probe sd {:4.1} C: rms miss {:6.3} C  Gauss-Newton rate, predicted {:.4}  measured {:.4}", sd, (2.0 * loss(&f2, &y2) / 40.0).sqrt(), p, m);
    }
    let w = step(&[fit[0], fit[1], fit[2] + 0.001], &ys, 0.0, true).new;
    println!("wrong slope column (a left out), one step from b = fit + 0.001: b {:.5}  F {:.1}", w[2], loss(&w, &ys));
    let t = ts(); let lx: Vec<f64> = ys.iter().map(|y| (y - 30.0).ln()).collect();
    let (mt, ml) = (sum(t.iter().copied()) / 40.0, sum(lx.iter().copied()) / 40.0);
    let bl = -sum(t.iter().zip(&lx).map(|(t, x)| (t - mt) * (x - ml))) / sum(t.iter().map(|t| (t - mt) * (t - mt)));
    println!("log-line shortcut, room guessed 30 C: b {:.5}  a {:.4}", bl, (ml + bl * mt).exp());
    let (mut rb, mut path) = ([-1.2f64, 1.0], vec![]);   // Rosenbrock: misses 10(y - x^2) and 1 - x
    let d0 = solve(&vec![vec![-20.0 * rb[0], 10.0], vec![-1.0, 0.0]], &[-10.0 * (rb[1] - rb[0] * rb[0]), -(1.0 - rb[0])]);   // J d = -r by elimination
    for n in 1..=2 {                                 // closed form: dx = 1 - x, then dy from the first row
        let (x, y, dx) = (rb[0], rb[1], 1.0 - rb[0]);
        rb = [x + dx, y + (-10.0 * (y - x * x) + 20.0 * x * dx) / 10.0]; path.push(rb);
        println!("Rosenbrock as two misses, Gauss-Newton step {}: ({:.4}, {:.4})", n, rb[0], rb[1]);
    }
    println!("figure, fit at t = 0, 5, 10, 15, 20 min: {}", [0.0, 5.0, 10.0, 15.0, 20.0].iter().map(|t| format!("{:.2}", fit[0] + fit[1] * (-fit[2] * t).exp())).collect::<Vec<_>>().join("  "));
    println!("figure, start at t = 0, 1, 2, 4, 20 min: {}", [0.0, 1.0, 2.0, 4.0, 20.0].iter().map(|t| format!("{:.2}", 30.0 + 160.0 * (-0.6f64 * t).exp())).collect::<Vec<_>>().join("  "));
    assert!(loss(&gn1, &ys) > 1e6 * f0 && gn1[2] < 0.0);   // undamped step from the poor start overshoots
    assert!((bp - fit[2]).abs() < 1e-6 && (cp - fit[0]).abs() < 1e-4 && (grid - fit[2]).abs() < 0.01);
    assert!(g.iter().all(|x| x.abs() < 1e-4) && minors.iter().all(|&x| x > 0.0));   // a local minimum
    assert!(m1 <= best + 1e-9 && best - m1 < 1e-2 * m1 && (f0 - m1 - s1.pred).abs() < 1e-9 * f0);  // ball's best; predicted drop
    assert!(rates.iter().all(|(p, m)| (p - m).abs() < 0.02 * p) && rates[0].0 < rates[1].0 && rates[1].0 < rates[2].0);
    assert!((path[0][0] - (-1.2 + d0[0])).abs() < 1e-12 && (path[0][1] - (1.0 + d0[1])).abs() < 1e-12 && (rb[0] - 1.0).abs() < 1e-9 && (rb[1] - 1.0).abs() < 1e-9 && w[2] < 0.0 && bl > fit[2] + 0.05);
    println!("ALL CHECKS PASS");
}
