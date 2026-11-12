// Runge's phenomenon and Chebyshev nodes -- the check behind the card.  Rust std only, no crates.
// A resonance peak f(x) = 1/(1 + 25 x^2), x = detuning in MHz from 100.0 MHz, read at 21 frequencies
// and joined by the one polynomial of degree 20 through them: once at equal spacing, once at Chebyshev nodes.
// Roads: Lagrange form; Newton divided differences; the exact error formula for this bell.
use std::f64::consts::PI;

fn e(x: f64, d: usize) -> String { format!("{:.*e}", d, x) } // e-notation, printed the same way in Python
fn f(x: f64) -> f64 { 1.0 / (1.0 + 25.0 * x * x) }
fn equal(n: usize) -> Vec<f64> { (0..=n).map(|j| -1.0 + 2.0 * j as f64 / n as f64).collect() }
fn cheb(n: usize) -> Vec<f64> { (0..=n).map(|j| ((2 * j + 1) as f64 * PI / (2 * n + 2) as f64).cos()).collect() }
fn lagrange(xs: &[f64], ys: &[f64], x: f64) -> f64 { // sum of y_j times the basis l_j(x)
    let mut s = 0.0;
    for j in 0..xs.len() {
        let mut l = 1.0;
        for k in 0..xs.len() { if k != j { l = l * (x - xs[k]) / (xs[j] - xs[k]); } }
        s = s + ys[j] * l;
    }
    s
}
fn newton_coef(xs: &[f64], ys: &[f64]) -> Vec<f64> { // divided differences
    let (mut c, n) = (ys.to_vec(), xs.len());
    for k in 1..n { for j in (k..n).rev() { c[j] = (c[j] - c[j - 1]) / (xs[j] - xs[j - k]); } }
    c
}
fn newton(xs: &[f64], c: &[f64], x: f64) -> f64 { // nested evaluation
    let n = xs.len();
    let mut v = c[n - 1];
    for j in (0..n - 1).rev() { v = v * (x - xs[j]) + c[j]; }
    v
}
fn omega(xs: &[f64], x: f64) -> f64 { xs.iter().fold(1.0, |w, xj| w * (x - xj)) } // product of (x - x_j)
fn big_p(xs: &[f64]) -> f64 { // P = product over positive nodes of (x_k^2 + 0.04) = 5 |omega(i/5)|
    let mut s = xs.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    s.iter().filter(|&&v| v > 1e-12).fold(1.0, |w, v| w * (v * v + 0.04))
}
fn exact_err(xs: &[f64], x: f64) -> f64 { -x * omega(xs, x) / (big_p(xs) * (x * x + 0.04)) } // f - p
fn grid() -> Vec<f64> { (0..2001).map(|i| -1.0 + i as f64 / 1000.0).collect() }
fn worst(xs: &[f64], g: &dyn Fn(f64) -> f64, lim: f64) -> (f64, f64) { // largest |g - p| with |x| <= lim, and where
    let ys: Vec<f64> = xs.iter().map(|&x| g(x)).collect();
    let mut best = (f64::MIN, 0.0);
    for x in grid() {
        if x.abs() > lim + 1e-12 { continue; }
        let c = ((g(x) - lagrange(xs, &ys, x)).abs(), x.abs());
        if c.0 > best.0 || (c.0 == best.0 && c.1 > best.1) { best = c; }
    }
    best
}
fn maxabs(v: impl Iterator<Item = f64>) -> f64 { v.fold(0.0, |m, a| if a.abs() > m { a.abs() } else { m }) }

fn main() {
    let n = 20;
    let (xe, xc) = (equal(n), cheb(n));
    let ye: Vec<f64> = xe.iter().map(|&x| f(x)).collect();
    let yc: Vec<f64> = xc.iter().map(|&x| f(x)).collect();
    println!("degree {}, {} readings; equal gap h {:.6}", n, n + 1, xe[1] - xe[0]);
    println!("Chebyshev nodes: outer {:.6} {:.6} {:.6}, middle {:.6} {:.6}; gap at end {:.6}, in middle {:.6}",
             xc[0], xc[1], xc[2], xc[10], xc[9], xc[0] - xc[1], xc[9] - xc[10]);
    let (we, wc) = (worst(&xe, &f, 1.0), worst(&xc, &f, 1.0));
    println!("worst error on grid: equal {} at |x| {:.3} | Chebyshev {} at |x| {:.3}", e(we.0, 3), we.1, e(wc.0, 3), wc.1);
    assert!(we.0 > 50.0 && wc.0 < 0.02); // the blow-up, and the repair
    let x = 0.975;
    let (pe, pc) = (lagrange(&xe, &ye, x), lagrange(&xc, &yc, x));
    println!("at x 0.975: f {:.6} | equal p {:.6} | Chebyshev p {:.6}", f(x), pe, pc);
    let (mut dn, mut dx) = (0.0f64, 0.0f64);
    for (xs, ys) in [(&xe, &ye), (&xc, &yc)] {
        let c = newton_coef(xs, ys);
        dn = dn.max(maxabs(grid().into_iter().map(|t| lagrange(xs, ys, t) - newton(xs, &c, t))));
        dx = dx.max(maxabs(grid().into_iter().map(|t| f(t) - lagrange(xs, ys, t) - exact_err(xs, t))));
    }
    println!("roads agree on grid: Lagrange vs Newton {} | Lagrange vs exact error formula {}", e(dn, 3), e(dx, 3));
    assert!(dn < 1e-9 && dx < 1e-9);
    for (name, xs, p) in [("equal", &xe, pe), ("Chebyshev", &xc, pc)] {
        let (w, bp, r) = (omega(xs, x), big_p(xs), x / (x * x + 0.04));
        println!("hand, {}: omega(x) {} P {} x/(x^2+0.04) {:.6} error {} | f - p {}", name, e(w, 6), e(bp, 6), r, e(-r * w / bp, 7), e(f(x) - p, 7));
    }
    let mut oe = (0.0, 0.0);
    for t in grid() { let c = (omega(&xe, t).abs(), t.abs()); if c.0 > oe.0 || (c.0 == oe.0 && c.1 > oe.1) { oe = c; } }
    let oc = maxabs(grid().into_iter().map(|t| omega(&xc, t)));
    let two20 = 1.0 / 1048576.0;
    println!("max |omega|: equal {} at |x| {:.3}, |omega(0.05)| {} ratio {:.0} | Chebyshev {} | 2^-20 {}",
             e(oe.0, 3), oe.1, e(omega(&xe, 0.05).abs(), 3), oe.0 / omega(&xe, 0.05).abs(), e(oc, 3), e(two20, 3));
    assert!((oc / two20 - 1.0).abs() < 1e-9 && oe.0 > 100.0 * oc);
    let mut dt = 0.0f64;
    for t in grid() { // T_21 by the recurrence T_(k+1) = 2x T_k - T_(k-1), against 2^20 omega
        let (mut a, mut b) = (1.0, t);
        for _ in 1..=n { let c = 2.0 * t * b - a; a = b; b = c; }
        dt = dt.max((b - omega(&xc, t) / two20).abs());
    }
    println!("T_21 by recurrence vs 2^20 omega_Chebyshev, max diff {}", e(dt, 3));
    assert!(dt < 1e-12);
    let rho = 0.2 + 1.04f64.sqrt(); // pole at i/5: rho = 1/5 + sqrt(1 + 1/25)
    let (mut a, mut b) = (1.0, 0.2); // T_k(i/5) = i^k t_k with t_(k+1) = 0.4 t_k + t_(k-1)
    for _ in 1..=n { let c = 0.4 * b + a; a = b; b = c; }
    println!("rho {:.6}; |T_21(i/5)| {:.6} = (rho^21 - rho^-21)/2 {:.6} | 2^20 P/5 {:.6} | equal P {}",
             rho, b, (rho.powi(21) - rho.powi(-21)) / 2.0, big_p(&xc) / two20 / 5.0, e(big_p(&xe), 3));
    assert!((b / (big_p(&xc) / two20 / 5.0) - 1.0).abs() < 1e-12);
    assert!(((rho.powi(21) - rho.powi(-21)) / 2.0 / b - 1.0).abs() < 1e-12);
    for (name, xs, wo) in [("equal", &xe, we.0), ("Chebyshev", &xc, wc.0)] {
        let bound = 2.5 * maxabs(grid().into_iter().map(|t| omega(xs, t))) / big_p(xs); // max |x|/(x^2+0.04) = 2.5
        println!("bound {}: 2.5 max|omega|/P {}, true {}, ratio true/bound {:.3}", name, e(bound, 3), e(wo, 3), wo / bound);
        assert!(wo <= bound);
    }
    println!("chart, log10 worst error, n = 4, 8, ..., 40: equal | Chebyshev | equal, |x| <= 0.5 only");
    let ns: Vec<usize> = (1..=10).map(|k| 4 * k).collect();
    let ce: Vec<f64> = ns.iter().map(|&m| worst(&equal(m), &f, 1.0).0).collect();
    let cc: Vec<f64> = ns.iter().map(|&m| worst(&cheb(m), &f, 1.0).0).collect();
    let cm: Vec<f64> = ns.iter().map(|&m| worst(&equal(m), &f, 0.5).0).collect();
    for row in [&ce, &cc, &cm] {
        println!("   {}", row.iter().map(|v| format!("{:.2}", v.log10())).collect::<Vec<_>>().join(" "));
    }
    assert!(ce[9] > 1e4 && cc[9] < 1e-3 && cm[9] < cm[0]);
    let obs = (cc[9] / cc[4]).powf(1.0 / 20.0); // error shrink per degree, n = 20 to 40
    println!("Chebyshev shrink per degree, n 20 to 40: observed {:.4}, theory 1/rho {:.4}", obs, 1.0 / rho);
    assert!((obs * rho - 1.0).abs() < 0.01);
    let lebesgue = |xs: &[f64]| -> f64 {
        let mut m = 0.0f64;
        for t in grid() {
            let mut s = 0.0;
            for j in 0..xs.len() {
                let unit: Vec<f64> = (0..xs.len()).map(|k| if k == j { 1.0 } else { 0.0 }).collect();
                s = s + lagrange(xs, &unit, t).abs();
            }
            m = m.max(s);
        }
        m
    };
    let (le, lc, lb) = (lebesgue(&xe), lebesgue(&xc), 2.0 / PI * 21f64.ln() + 1.0);
    println!("Lebesgue constant on grid, n=20: equal {:.1} | Chebyshev {:.4}, bound 2/pi log 21 + 1 {:.4}", le, lc, lb);
    assert!(le > 1000.0 && lc < lb);
    println!("flops per point, n={}: Lagrange form (n+1)(4n+2) {} | Newton 3n {}, after 3n(n+1)/2 {} once | barycentric 5(n+1)+1 {}",
             n, (n + 1) * (4 * n + 2), 3 * n, 3 * n * (n + 1) / 2, 5 * (n + 1) + 1);
    let nz: Vec<f64> = (0..=n).map(|j| if j % 2 == 0 { 0.001 } else { -0.001 }).collect(); // alternating reading errors
    println!("noise +-0.001, change in p at x 0.975: equal {:.6} | Chebyshev {:.6}", lagrange(&xe, &nz, x), lagrange(&xc, &nz, x));
    println!("n=40 worst: equal {} | Chebyshev {}", e(worst(&equal(40), &f, 1.0).0, 3), e(cc[9], 3));
    for m in [20, 40] {
        println!("break: kink |x| on Chebyshev nodes, n={} worst {}", m, e(worst(&cheb(m), &|t: f64| t.abs(), 1.0).0, 3));
    }
    println!("try: wide bell 1/(1 + x^2), equal nodes n=20 worst {}", e(worst(&xe, &|t: f64| 1.0 / (1.0 + t * t), 1.0).0, 3));
    let dots: Vec<String> = (0..21).map(|j| { let th = (2 * j + 1) as f64 * PI / 42.0; // x = 180 + 150 cos, y = 175 - 150 sin
        format!("{:.1},{:.1}", 180.0 + 150.0 * th.cos(), 175.0 - 150.0 * th.sin()) }).collect();
    println!("figure, circle centre (180, 175) radius 150, Chebyshev dots (x, y): {}", dots.join(" "));
    println!("ALL CHECKS PASS");
}
