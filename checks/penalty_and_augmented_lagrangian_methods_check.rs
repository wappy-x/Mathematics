// Penalties and augmented Lagrangians -- the same check as the Python, in Rust.  No crates.
// Three pumps feed one town.  Choose flows x = (x1, x2, x3) in L/s to MINIMISE the power drawn,
// f(x) = 0.02 x1^2 + 0.03 x2^2 + 0.05 x3^2 (kW), subject to two rules:
//   demand   h(x) = 150 - x1 - x2 - x3 = 0       (shortfall in L/s)
//   pressure g(x) = 0.5 x1 - 25 <= 0             (head over the low district's 25 m cap, in m)
// Road 1: the KKT equations, solved by elimination.  Road 2: a scan of every plan on a 0.5 L/s grid.
// Road 3: penalty and augmented-Lagrangian loops (sub-problems by elimination), rate checked against the proof.
const A: [f64; 3] = [0.02, 0.03, 0.05]; const K: f64 = 0.5; const CAP: f64 = 25.0; const DEM: f64 = 150.0; const KWH: f64 = 0.20;
type V = Vec<f64>;

fn f(x: &[f64]) -> f64 { A.iter().zip(x).fold(0.0, |s, (a, v)| s + a * v * v) }
fn h(x: &[f64]) -> f64 { DEM - x.iter().fold(0.0, |s, v| s + v) }
fn g(x: &[f64], cap: f64) -> f64 { K * x[0] - cap }
fn dist(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).fold(0.0, |s, (p, q)| s + (p - q) * (p - q)).sqrt() }
fn f4(v: &[f64]) -> String { v.iter().map(|u| format!("{:.4}", u)).collect::<Vec<_>>().join(", ") }
fn sci(v: f64, d: usize) -> String { // 1.23e-04 style, the same in both languages
    let s = format!("{:.*e}", d, v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn gauss(m0: &[V], r: &[f64]) -> V { // solve M z = r by elimination with row swaps
    let n = r.len();
    let mut m: Vec<V> = m0.iter().zip(r).map(|(row, v)| { let mut t = row.clone(); t.push(*v); t }).collect();
    for c in 0..n {
        let mut p = c; for i in c + 1..n { if m[i][c].abs() > m[p][c].abs() { p = i; } } m.swap(c, p);
        for i in 0..n {
            if i != c { let k = m[i][c] / m[c][c]; let rc = m[c].clone(); for (u, v) in m[i].iter_mut().zip(&rc) { *u -= k * v; } }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}

fn hess(rho: f64, act: bool) -> Vec<V> { // Hessian of the sub-problem: diag(2a) + rho J^T J
    (0..3).map(|i| (0..3).map(|j| (if i == j { 2.0 * A[i] } else { 0.0 }) + rho
        + (if act && i == 0 && j == 0 { rho * K * K } else { 0.0 })).collect()).collect()
}

fn sub(rho: f64, lam: f64, nu: f64, cap: f64, clamp: bool) -> V { // minimise the augmented Lagrangian exactly
    for act in [true, false] { // cap term switched on, then off; keep the consistent one
        let b: V = (0..3).map(|i| nu + rho * DEM - (if act && i == 0 { K * (lam - rho * cap) } else { 0.0 })).collect();
        let x = gauss(&hess(rho, act), &b);
        if !clamp || act == (lam + rho * g(&x, cap) >= 0.0) { return x; }
    }
    panic!("no consistent piece")
}

fn grad(x: &[f64], rho: f64, lam: f64, nu: f64) -> V { // gradient of the augmented Lagrangian
    let w = (lam + rho * g(x, CAP)).max(0.0);
    (0..3).map(|i| 2.0 * A[i] * x[i] - nu - rho * h(x) + (if i == 0 { K * w } else { 0.0 })).collect()
}

fn extremes(hm: &[V]) -> (f64, f64) { // largest and smallest eigenvalue, by power iteration
    let (mut v, mut w) = (vec![1.0, 0.3, 0.2], vec![1.0, 0.3, 0.2]);
    let (mut big, mut small) = (0.0, 0.0);
    for _ in 0..300 {
        let u: V = (0..3).map(|i| (0..3).fold(0.0, |s, j| s + hm[i][j] * v[j])).collect();
        big = u.iter().fold(0.0, |s, t| s + t * t).sqrt(); v = u.iter().map(|t| t / big).collect();
        let u = gauss(hm, &w);
        small = u.iter().fold(0.0, |s, t| s + t * t).sqrt(); w = u.iter().map(|t| t / small).collect();
    }
    (big, 1.0 / small)
}

fn gd_steps(rho: f64, lam: f64, nu: f64, x0: &[f64], tol: f64) -> (usize, V) { // step 1/L, counted to tol
    let (target, (l, _)) = (sub(rho, lam, nu, CAP, true), extremes(&hess(rho, true)));
    let (mut x, mut n) = (x0.to_vec(), 0);
    while dist(&x, &target) > tol && n < 1_000_000 { let gr = grad(&x, rho, lam, nu); x = x.iter().zip(&gr).map(|(p, q)| p - q / l).collect(); n += 1; }
    (n, x)
}

fn aug_lag(rho: f64, rounds: usize, cap: f64, clamp: bool, sign: f64) -> Vec<(V, f64, f64)> {
    let (mut lam, mut nu, mut path) = (0.0f64, 0.0f64, vec![]);
    for _ in 0..rounds {
        let x = sub(rho, lam, nu, cap, clamp);
        nu += sign * rho * h(&x);
        lam = if clamp { (lam + rho * g(&x, cap)).max(0.0) } else { lam + rho * g(&x, cap) };
        path.push((x, lam, nu));
    }
    path
}

fn main() {
    // ---- road 1: KKT with the cap binding.  Unknowns x1, x2, x3, nu, lam ----
    let m: Vec<V> = vec![vec![2.0 * A[0], 0.0, 0.0, -1.0, K], vec![0.0, 2.0 * A[1], 0.0, -1.0, 0.0],
        vec![0.0, 0.0, 2.0 * A[2], -1.0, 0.0], vec![1.0, 1.0, 1.0, 0.0, 0.0], vec![K, 0.0, 0.0, 0.0, 0.0]];
    let z = gauss(&m, &[0.0, 0.0, 0.0, DEM, CAP]);
    let (xs, nu_s, lam_s) = (z[..3].to_vec(), z[3], z[4]);
    let inv = A.iter().fold(0.0, |s, a| s + 1.0 / a);
    let free: V = (0..3).map(|i| DEM / A[i] / inv).collect(); // demand only: x_i in proportion to 1/a_i
    println!("no cap: flows {} L/s, power {:.4} kW, head {:.4} m, {:.4} m over", f4(&free), f(&free), K * free[0], g(&free, CAP));
    println!("KKT: flows {} L/s, pump powers {} kW", f4(&xs), f4(&(0..3).map(|i| A[i] * xs[i] * xs[i]).collect::<V>()));
    println!("KKT: power {:.4} kW, {:.4} pounds an hour; the cap costs {:.4} kW", f(&xs), KWH * f(&xs), f(&xs) - f(&free));
    println!("KKT: nu {:.4} kW per L/s ({:.4} pounds an hour), lam {:.4} kW per m ({:.4})", nu_s, KWH * nu_s, lam_s, KWH * lam_s);
    let stat = grad(&xs, 0.0, lam_s, nu_s).iter().fold(0.0f64, |s, t| s.max(t.abs()));
    println!("KKT residuals: stationarity {}, shortfall {}, lam*g {}", sci(stat, 1), sci(h(&xs).abs(), 1), sci((lam_s * g(&xs, CAP)).abs(), 1));
    assert!(stat < 1e-12 && h(&xs).abs() < 1e-12 && lam_s > 0.0 && g(&xs, CAP).abs() < 1e-12);

    // ---- road 2: scan every plan on a 0.5 L/s grid that meets demand and the cap ----
    let mut best = (f64::INFINITY, 0.0, 0.0);
    for p in 0..101 { for q in 0..(301 - p) {
        let (a, b) = (p as f64 / 2.0, q as f64 / 2.0); let v = f(&[a, b, DEM - a - b]); if v < best.0 { best = (v, a, b); }
    } }
    println!("grid scan: best flows {} L/s, power {:.4} kW", f4(&[best.1, best.2, DEM - best.1 - best.2]), best.0);
    assert!(dist(&[best.1, best.2, DEM - best.1 - best.2], &xs) < 1e-9);

    // ---- road 3a: quadratic penalty, rho = 1, 10, ..., 10^6 (no prices kept) ----
    let s = [[A.iter().fold(0.0, |s, a| s + 1.0 / (2.0 * a)), -K / (2.0 * A[0])], [-K / (2.0 * A[0]), K * K / (2.0 * A[0])]]; // J (grad^2 f)^-1 J^T
    println!("penalty  rho    flows (L/s)                 power   short   over    rho*h   rho*g   error    kappa");
    let mut pen: V = vec![];
    for e in 0..7 {
        let rho = 10f64.powi(e); let x = sub(rho, 0.0, 0.0, CAP, true); let (big, small) = extremes(&hess(rho, true)); pen.push(dist(&x, &xs));
        println!("penalty 1e{}  {:26}  {:8.4} {:7.5} {:7.5} {:7.4} {:7.4} {} {:9.0}", e, f4(&x), f(&x), h(&x), g(&x, CAP),
            rho * h(&x), rho * g(&x, CAP), sci(pen[pen.len() - 1], 2), big / small);
        let gap = gauss(&[vec![1.0 + rho * s[0][0], rho * s[0][1]], vec![rho * s[1][0], 1.0 + rho * s[1][1]]], &[nu_s, lam_s]);
        assert!((nu_s - rho * h(&x) - gap[0]).abs() < 1e-8 * rho && (lam_s - rho * g(&x, CAP) - gap[1]).abs() < 1e-8 * rho);
    }
    assert!(pen[3] * 1000.0 > 1.0 && pen[6] < 2e-5 && (pen[5] / pen[6] - 10.0).abs() < 0.05);
    for e in 0..4 {
        let (n, _) = gd_steps(10f64.powi(e), 0.0, 0.0, &[50.0, 50.0, 50.0], 1e-3);
        println!("gradient descent on the penalty at rho 1e{}: {} steps to 0.001 L/s", e, n);
    }

    // ---- road 3b: augmented Lagrangian, prices updated, rho held at 1 and at 10 ----
    let (tr, det) = (s[0][0] + s[1][1], s[0][0] * s[1][1] - s[0][1] * s[0][1]);
    let sig = (tr - (tr * tr - 4.0 * det).sqrt()) / 2.0;
    println!("S = J (grad^2 f)^-1 J^T = [[{}], [{}]], smallest eigenvalue sigma {:.4}", f4(&s[0]), f4(&s[1]), sig);
    println!("predicted ratio 1/(1+rho sigma): rho 1 -> {:.4}, rho 10 -> {:.4}", 1.0 / (1.0 + sig), 1.0 / (1.0 + 10.0 * sig));
    for rho in [1.0f64, 10.0] {
        let (path, mut prev, mut errs) = (aug_lag(rho, 10, CAP, true, 1.0), None::<f64>, vec![]);
        for (k, (x, lam, nu)) in path.iter().enumerate() {
            errs.push(dist(x, &xs)); let e = errs[errs.len() - 1];
            let ratio = match prev { Some(p) => format!("{:.4}", e / p), None => "  -   ".to_string() };
            if rho == 1.0 { println!("AL rho 1, k={}: flows {}  error {}  ratio {}  lam {:.4}  nu {:.4}", k, f4(x), sci(e, 2), ratio, lam, nu); }
            prev = Some(e);
        }
        let (big, small) = extremes(&hess(rho, true));
        println!("AL rho {}: kappa {:.1}, chart log10 error k=0..6: {}", rho, big / small,
            errs[..7].iter().map(|t| format!("{:.2}", t.log10())).collect::<Vec<_>>().join(" "));
        assert!((errs[4] / errs[3] - 1.0 / (1.0 + rho * sig)).abs() < 1e-3);
    }
    println!("chart penalty log10 error k=0..6: {}", pen.iter().map(|t| format!("{:.2}", t.log10())).collect::<Vec<_>>().join(" "));
    let (n, x) = gd_steps(1.0, 3.5, 3.75, &[50.0, 50.0, 50.0], 1e-3);
    println!("gradient descent on the AL at rho 1 with the true prices: {} steps, lands {:.4} L/s from x*", n, dist(&x, &xs));

    // ---- what breaks ----
    let x = sub(1.0, 0.0, 0.0, CAP, true);
    println!("stop at rho 1: head {:.4} m, {:.4} m over; {:.4} L/s short; power {:.4} kW", K * x[0], g(&x, CAP), h(&x), f(&x));
    let (x, lam, _) = aug_lag(1.0, 60, 40.0, false, 1.0).pop().unwrap();
    let (y, lam2, _) = aug_lag(1.0, 60, 40.0, true, 1.0).pop().unwrap();
    println!("cap 40 m, no clamp: lam {:.4}, head {:.4} m, power {:.4} kW; with clamp: lam {:.4}, head {:.4} m, power {:.4} kW",
        lam, K * x[0], f(&x), lam2, K * y[0], f(&y));
    assert!(lam < 0.0 && (K * x[0] - 40.0).abs() < 1e-6 && (f(&y) - f(&free)).abs() < 1e-9 && lam2 == 0.0);
    let x = aug_lag(1.0, 10, CAP, true, -1.0).pop().unwrap().0; assert!(dist(&x, &xs) > 100.0);
    println!("price update with the wrong sign, 10 rounds: error {:.4} L/s", dist(&x, &xs));
    let l1 = extremes(&hess(1.0, true)).0; let mut x = vec![50.0, 50.0, 50.0];
    for _ in 0..50 { let gr = grad(&x, 10.0, 0.0, 0.0); x = x.iter().zip(&gr).map(|(p, q)| p - q / l1).collect(); }
    assert!(dist(&x, &xs) > 1e6);
    println!("rho 10 with the rho-1 step 1/L = {:.4}: error after 50 steps {} L/s", 1.0 / l1, sci(dist(&x, &xs), 3));
    for c in [4.0f64, 3.0] {
        let ex = |y: &[f64]| f(y) + c * (h(y).abs() + g(y, CAP).max(0.0));
        let mut low = f64::INFINITY; for i in -10..11 { for j in -10..11 { for l in -10..11 {
            low = low.min(ex(&[xs[0] + i as f64 / 10.0, xs[1] + j as f64 / 10.0, xs[2] + l as f64 / 10.0]));
        } } }
        println!("exact penalty, rate {}: value at x* {:.4} kW, lowest within 1 L/s {:.4} kW", c, ex(&xs), low);
        assert!(if c > nu_s.max(lam_s) { low > ex(&xs) - 1e-9 } else { low < ex(&xs) - 1.0 });
    }
    println!("ALL CHECKS PASS");
}
