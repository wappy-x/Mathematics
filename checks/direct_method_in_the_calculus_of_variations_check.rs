// The direct method -- the check behind the card.  std only, no crates.
// A shear-thickening liquid (power-law index 3) flows between two plates 5 cm
// apart, pushed by 1600 Pa/m; consistency 0.01 Pa s^3 (illustrative).  Scaled
// (x by the gap, u by the speed scale) the flow minimises
// J(u) = int_0^1 (u'^4/4 - u) dx with u(0) = u(1) = 0.  Then Bolza's energy
// B(u) = int_0^1 ((u'^2 - 1)^2 + u^2) dx, which has no minimiser.
use std::f64::consts::PI;

fn cbrt(t: f64) -> f64 { t.abs().powf(1.0 / 3.0).copysign(t) }
fn sci(v: f64) -> String { // 1.234e-05 in both languages
    if v == 0.0 { return "0.000e+00".to_string(); }
    let mut e = v.abs().log10().floor() as i32;
    let mut m = v / 10f64.powf(e as f64);
    if m.abs() >= 9.9995 { m /= 10.0; e += 1; }
    format!("{:.3}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn cc() -> f64 { 2f64.powf(-4.0 / 3.0) }
fn u(x: f64) -> f64 { 0.75 * (cc() - (x - 0.5).abs().powf(4.0 / 3.0)) }
fn up(x: f64) -> f64 { cbrt(0.5 - x) } // u' ; u'^3 = 1/2 - x
fn energy(v: &[f64], h: f64) -> f64 {
    let mut s = 0.0;
    for i in 0..v.len() - 1 { s += h * ((v[i + 1] - v[i]) / h).powf(4.0) / 4.0 - h * v[i + 1]; }
    s
}
fn grid(n: usize) -> (Vec<f64>, Vec<f64>) { // direct method: Newton steps that only lower the energy
    let h = 1.0 / n as f64;
    let mut v: Vec<f64> = (0..=n).map(|i| (i as f64 * h) * (1.0 - i as f64 * h)).collect();
    let mut hist = vec![energy(&v, h)];
    for _ in 0..200 {
        let s: Vec<f64> = (0..n).map(|i| (v[i + 1] - v[i]) / h).collect();
        let g: Vec<f64> = (1..n).map(|j| s[j - 1].powf(3.0) - s[j].powf(3.0) - h).collect();
        let a: Vec<f64> = (1..n).map(|j| 3.0 * (s[j - 1].powf(2.0) + s[j].powf(2.0)) / h).collect();
        let b: Vec<f64> = (1..n - 1).map(|j| -3.0 * s[j].powf(2.0) / h).collect();
        let (mut cp, mut dp) = (vec![0.0; n - 1], vec![0.0; n - 1]); // Thomas solve of H d = g
        for j in 0..n - 1 {
            let den = a[j] - if j > 0 { b[j - 1] * cp[j - 1] } else { 0.0 };
            cp[j] = if j < n - 2 { b[j] / den } else { 0.0 };
            dp[j] = (g[j] - if j > 0 { b[j - 1] * dp[j - 1] } else { 0.0 }) / den;
        }
        let mut d = dp.clone();
        for j in (0..n - 2).rev() { d[j] -= cp[j] * d[j + 1]; }
        let (mut t, e0) = (1.0, *hist.last().unwrap());
        let mut w;
        loop {
            w = vec![0.0];
            for j in 0..n - 1 { w.push(v[j + 1] - t * d[j]); }
            w.push(0.0);
            if energy(&w, h) <= e0 || t < 1e-12 { break; }
            t /= 2.0;
        }
        v = w;
        hist.push(energy(&v, h));
        assert!(hist[hist.len() - 1] <= hist[hist.len() - 2] + 1e-15); // the energy never rises
        if d.iter().fold(0.0f64, |m, x| m.max(x.abs())) * t < 1e-13 { break; }
    }
    (v, hist)
}
fn exact_grid(n: usize) -> Vec<f64> { // discrete Euler-Lagrange, solved by hand
    let h = 1.0 / n as f64;
    let mut v = vec![0.0];
    for i in 0..n { let last = v[v.len() - 1]; v.push(last + h * cbrt(0.5 - (i as f64 + 0.5) * h)); }
    v
}
fn bolza(s: f64, w: f64) -> f64 { (s * s - 1.0).powf(2.0) + w * w }
fn line(v: Vec<f64>) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (dg, mc, f) = (0.05f64, 0.01f64, 1600.0f64); // gap m, consistency Pa s^3, push Pa/m
    let uu = (f * dg.powf(4.0) / mc).powf(1.0 / 3.0); // speed scale, m/s
    let c = cc();
    let (peak, area, jmin) = (0.75 * c, 3.0 / 7.0 * c, -9.0 / 28.0 * c);
    println!("speed scale U = {:.4} m/s; peak {:.6} -> {:.4} m/s at mid-gap", uu, peak, peak * uu);
    println!("(1/2)^(4/3) = {:.6}; slope at the plates u'(0) = {:.6}; int u'^2 = {:.6}", c, up(0.0), 1.2 * 2f64.powf(-5.0 / 3.0));
    let q4 = simpson(&|x| up(x).powf(4.0), 0.0, 0.5, 2000) * 2.0;
    let qa = simpson(&u, 0.0, 0.5, 2000) * 2.0;
    println!("int u = {:.6} (quadrature {:.6}); int u'^4 = {:.6}; flow {:.3} L/s per m", area, qa, q4, area * dg * uu * 1000.0);
    println!("J(min) = {:.6} (quadrature {:.6}); norm of u' in L^4 = {:.5}", jmin, q4 / 4.0 - qa, area.powf(0.25));
    assert!((qa - area).abs() < 1e-9 && (q4 - area).abs() < 1e-6 && (q4 / 4.0 - qa - jmin).abs() < 1e-6);
    println!("coercivity: J >= t^4/4 - t >= {:.4}; J <= 0 forces t <= {:.4}", -0.75, 4f64.powf(1.0 / 3.0));
    assert!(q4.powf(0.25) <= 4f64.powf(1.0 / 3.0) && q4 / 4.0 - qa >= -0.75);

    let (_, hist) = grid(16);
    let first: Vec<String> = hist.iter().take(7).map(|e| format!("{:.6}", e)).collect();
    println!("grid N=16, energy by Newton step: {} ... {} steps", first.join(" "), hist.len() - 1);
    let mut errs = vec![];
    for n in [16usize, 32, 64] {
        let (v, _) = grid(n);
        let ve = exact_grid(n);
        let gap = v.iter().zip(ve.iter()).fold(0.0f64, |m, (p, q)| m.max((p - q).abs()));
        errs.push((v[n / 2] - peak).abs());
        println!("grid N={}: peak {:.6}, energy {:.6}, peak error {}, Newton = exact grid to 1e-12", n, v[n / 2], energy(&v, 1.0 / n as f64), sci(errs[errs.len() - 1]));
        assert!(gap < 1e-12 && errs[errs.len() - 1] < 0.01);
    }
    println!("observed order: {:.3}, {:.3}", (errs[0] / errs[1]).log2(), (errs[1] / errs[2]).log2());
    assert!(errs[2] < errs[1] && errs[1] < errs[0]);

    for k in [1.0f64, 3.0] { // the Euler-Lagrange equation, weakly
        let g = |x: f64| up(x).powf(3.0) * (k * PI * (k * PI * x).cos()) - (k * PI * x).sin();
        let r = simpson(&g, 0.0, 0.5, 2000) + simpson(&g, 0.5, 1.0, 2000);
        println!("weak form with v = sin({} pi x): |int (u'^3 v' - v)| below 1e-10", k);
        assert!(r.abs() < 1e-10);
    }
    for hd in [0.01f64, 0.005] { // and by differences
        let x = 0.25;
        let fl = |y: f64| ((u(y + hd / 2.0) - u(y - hd / 2.0)) / hd).powf(3.0);
        let res = -(fl(x + hd / 2.0) - fl(x - hd / 2.0)) / hd - 1.0;
        println!("-(u'^3)' - 1 at x = 0.25 by differences, step {}: {}", hd, sci(res));
        assert!(res.abs() < 1e-3);
    }
    for t in [0.1f64, -0.1] { // rivals cost more
        let g = |x: f64| (up(x) + t * PI * (PI * x).cos()).powf(4.0) / 4.0 - (u(x) + t * (PI * x).sin());
        let gp = simpson(&g, 0.0, 0.5, 2000) + simpson(&g, 0.5, 1.0, 2000) - jmin;
        println!("rival u + ({:+.1}) sin(pi x): energy higher by {:.6}", t, gp);
        assert!(gp > 0.0);
    }
    for dd in [0.01f64, 0.0001] { // u'' = -(1/3)|x - 1/2|^(-2/3) blows up at the middle
        let fd = (up(0.5 - dd + dd / 100.0) - up(0.5 - dd - dd / 100.0)) / (dd / 50.0);
        println!("u'' at {} from the middle: {:.3} by differences, {:.3} by formula", dd, fd, -(dd.powf(-2.0 / 3.0)) / 3.0);
        assert!((fd + dd.powf(-2.0 / 3.0) / 3.0).abs() < 1e-3 * dd.powf(-2.0 / 3.0));
    }

    let a = 0.5f64; // weak lower semicontinuity: wiggles shrink to nothing, energy drops
    let lim = jmin + 1.5 * a * a * 1.2 * 2f64.powf(-5.0 / 3.0) + a.powf(4.0) / 4.0;
    let mut tot = 0.0;
    for n in [4usize, 16, 64] {
        tot = 0.0;
        for i in 0..2 * n { // exact: int_a^b u'^k = 3/(k+3) (u'(a)^(k+3) - u'(b)^(k+3)); u = (3/4)(C - u'^4)
            let (a0, b0, sg) = (i as f64 / (2 * n) as f64, (i + 1) as f64 / (2 * n) as f64, if i % 2 == 0 { 1.0 } else { -1.0 });
            let ii: Vec<f64> = (0..5).map(|k| 3.0 / (k as f64 + 3.0) * (up(a0).powf(k as f64 + 3.0) - up(b0).powf(k as f64 + 3.0))).collect();
            let e4: f64 = (0..5).map(|k| [1.0, 4.0, 6.0, 4.0, 1.0][k] * (sg * a).powf(4.0 - k as f64) * ii[k]).sum();
            tot += e4 / 4.0 - 0.75 * (c * ii[0] - ii[4]) - a * ii[0].powf(2.0) / 2.0;
        }
        println!("u + zigzag, slope +-{}, {} teeth: energy {:.6}", a, n, tot);
    }
    println!("limit of those energies {:.6} >= energy of the limit {:.6}", lim, jmin);
    assert!((tot - lim).abs() < 0.01 * a && tot > jmin);

    for n in [1usize, 10, 100] { // Bolza: zigzags of slope +-1, B = 1/(12 n^2) -> 0
        let mut bq = 0.0;
        for i in 0..2 * n {
            let (lo, hi) = (i as f64 / (2 * n) as f64, (i + 1) as f64 / (2 * n) as f64);
            bq += simpson(&|x| bolza(1.0, if i % 2 == 0 { x - lo } else { hi - x }), lo, hi, 2);
        }
        let nf = n as f64;
        println!("Bolza zigzag n={}: B = {} (formula {}); measurement int u' x dx = {:.4}", n, sci(bq), sci(1.0 / (12.0 * nf * nf)), -1.0 / (4.0 * nf));
        assert!((bq - 1.0 / (12.0 * nf * nf)).abs() < 1e-12);
    }
    println!("Bolza at the limit u = 0: B = {:.4}; convexified integrand at slope 0: {:.4}", simpson(&|_| bolza(0.0, 0.0), 0.0, 1.0, 2000), (0.0f64).max(0.0 - 1.0).powf(2.0));
    for e in [0.1f64, 0.01, 0.001] { // slopes cost only |u'|: ramp of width e to u(1) = 1
        let r = simpson(&|x| 1.0 / e + ((x - 1.0 + e) / e).powf(2.0), 1.0 - e, 1.0, 2);
        println!("p = 1, int (|u'| + u^2), ramp width {}: {:.6} (formula {:.6})", e, r, 1.0 + e / 3.0);
        assert!((r - 1.0 - e / 3.0).abs() < 1e-12);
    }
    println!("no fixed ends, J(constant 10) = {:.4}", simpson(&|_| 0f64.powf(4.0) / 4.0 - 10.0, 0.0, 1.0, 2000));
    let pk = |f: f64, d: f64| 0.75 * c * (f * d.powf(4.0) / mc).powf(1.0 / 3.0);
    println!("try: push 3200 Pa/m -> peak {:.4} m/s; gap 10 cm -> peak {:.4} m/s; grid N=128 peak error {}; wiggle slope 1 -> limit {:.6}",
             pk(3200.0, dg), pk(f, 0.1), sci((grid(128).0[64] - peak).abs()), jmin + 1.5 * 1.2 * 2f64.powf(-5.0 / 3.0) + 0.25);
    println!("chart, minimiser: {}", line((0..11).map(|i| u(i as f64 / 10.0)).collect()));
    println!("chart, parabola of equal peak: {}", line((0..11).map(|i| 4.0 * peak * (i as f64 / 10.0) * (1.0 - i as f64 / 10.0)).collect()));
    println!("chart, zigzag n=2: {}", line((0..9).map(|i: i32| (i % 4).min(4 - i % 4) as f64 / 8.0).collect()));
    println!("chart, zigzag n=4: {}", line((0..9).map(|i: i32| (i % 2) as f64 / 8.0).collect()));
    println!("ALL CHECKS PASS");
}
