// SABR from three quotes -- the same check as the Python, in Rust.  No crates.  Nothing
// imported knows the answer: the normal CDF is Marsaglia's series, the roots come from the
// quadratic formula, Newton and bisection, the integrals from Simpson.  Every card number prints.
use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T1: f64 = 1.0;   // house market
const QUOTES: [f64; 5] = [92.15, 0.24, 0.20, 119.93, 0.18];   // low wing, ATM at the forward, high wing
const HOUSE: (f64, f64) = (-0.3, 0.4);                        // the shelf's house SABR: rho, nu (beta = 1)
type P3 = (f64, f64, f64);                                    // alpha, rho, nu
fn fwd(t: f64) -> f64 { S * ((R - Q) * t).exp() }
fn ncdf(x: f64) -> f64 {                                      // bell-curve area left of x, Marsaglia's series
    if x < 0.0 { return 1.0 - ncdf(-x); } else if x > 12.0 { return 1.0; }
    let (mut term, mut total, mut n) = (x, x, 1.0);
    while term > 1e-17 * total { term *= x * x / (2.0 * n + 1.0); total += term; n += 1.0; }
    0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, h) = (400, (b - a) / 400.0);
    (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>() * h / 3.0
}
fn chi(z: f64, rho: f64) -> f64 { (((1.0 - 2.0 * rho * z + z * z).sqrt() + z - rho) / (1.0 - rho)).ln() }
fn hagan(k: f64, f: f64, a: f64, rho: f64, nu: f64, t: f64) -> f64 {   // Hagan's implied vol, beta = 1
    let z = nu / a * (f / k).ln();
    let zx = if z.abs() < 1e-7 { 1.0 - rho * z / 2.0 } else { z / chi(z, rho) };
    a * zx * (1.0 + (rho * nu * a / 4.0 + (2.0 - 3.0 * rho * rho) * nu * nu / 24.0) * t)
}
fn hp(k: f64, f: f64, p: P3, t: f64) -> f64 { hagan(k, f, p.0, p.1, p.2, t) }
fn coeffs(rho: f64, nu: f64, t: f64) -> (f64, f64) { (rho * nu * t / 4.0, 1.0 + (2.0 - 3.0 * rho * rho) * nu * nu * t / 24.0) }
fn alpha_quad(atm: f64, rho: f64, nu: f64, t: f64) -> f64 {   // road 1 to alpha: quadratic formula, small root
    let (c2, c1) = coeffs(rho, nu, t); let disc = c1 * c1 + 4.0 * c2 * atm;
    if disc < 0.0 { f64::NAN } else { 2.0 * atm / (c1 + disc.sqrt()) }
}
fn alpha_newton(atm: f64, f: f64, rho: f64, nu: f64, t: f64, mut a: f64) -> f64 {   // road 2: Newton
    for _ in 0..100 {
        let g = hagan(f, f, a, rho, nu, t) - atm;
        a -= g / ((hagan(f, f, a + 1e-6, rho, nu, t) - hagan(f, f, a - 1e-6, rho, nu, t)) / 2e-6);
        if g.abs() < 1e-15 { break; }
    }
    a
}
fn fit_newton(q: [f64; 5], f: f64, t: f64, r0: f64, n0: f64) -> (f64, f64, f64, usize, f64) {   // road 1: 2-D Newton
    let gaps = |r: f64, n: f64| {
        let a = alpha_quad(q[2], r, n, t);
        (hagan(q[0], f, a, r, n, t) - q[1], hagan(q[3], f, a, r, n, t) - q[4])
    };
    let (mut rho, mut nu, mut it, mut dt) = (r0, n0, 0, 0.0);
    for i in 1..100 {
        it = i; let ((g1, g2), (a1, a2), (b1, b2)) = (gaps(rho, nu), gaps(rho + 1e-7, nu), gaps(rho, nu + 1e-7));
        let (j11, j21, j12, j22) = ((a1 - g1) / 1e-7, (a2 - g2) / 1e-7, (b1 - g1) / 1e-7, (b2 - g2) / 1e-7);
        let det = j11 * j22 - j12 * j21; dt = det; let (mut dr, mut dn) = ((j22 * g1 - j12 * g2) / det, (j11 * g2 - j21 * g1) / det);
        while (rho - dr).abs() >= 0.999 || nu - dn <= 0.01 { dr /= 2.0; dn /= 2.0; }   // stay legal
        rho -= dr; nu -= dn;
        if dr.abs() + dn.abs() < 1e-14 { break; }
    }
    (alpha_quad(q[2], rho, nu, t), rho, nu, it, dt)
}
fn fit_bisect(q: [f64; 5], f: f64, t: f64) -> P3 {             // road 2: rho for the tilt inside nu for the curve
    let vols = |r: f64, n: f64| {
        let a = alpha_newton(q[2], f, r, n, t, q[2]);
        (a, hagan(q[0], f, a, r, n, t), hagan(q[3], f, a, r, n, t))
    };
    let rho_for = |n: f64| {                                  // the tilt steepens as rho falls
        let (mut rl, mut rh) = (-0.999, 0.999);
        for _ in 0..60 {
            let m = (rl + rh) / 2.0; let (_, v1, v2) = vols(m, n); if v1 - v2 > q[1] - q[4] { rl = m } else { rh = m }
        }
        (rl + rh) / 2.0
    };
    let (mut lo, mut hi) = (0.6, 2.5);
    for _ in 0..60 {                                          // the curvature grows with nu
        let n = (lo + hi) / 2.0; let (_, v1, v2) = vols(rho_for(n), n);
        if v1 + v2 > q[1] + q[4] { hi = n } else { lo = n }
    }
    let n = (lo + hi) / 2.0; let r = rho_for(n); (vols(r, n).0, r, n)
}
fn black(f: f64, k: f64, vol: f64, t: f64) -> f64 {           // undiscounted Black-76 call
    let v = vol * t.sqrt(); let d1 = (f / k).ln() / v + v / 2.0;
    f * ncdf(d1) - k * ncdf(d1 - v)
}
fn call(k: f64, f: f64, p: P3, t: f64) -> f64 { black(f, k, hp(k, f, p, t), t) }   // ... at the smile's vol
fn density_prices(k: f64, f: f64, p: P3, t: f64) -> f64 {   // density road 1: butterfly on prices / h^2
    let h = 0.05; (call(k - h, f, p, t) - 2.0 * call(k, f, p, t) + call(k + h, f, p, t)) / (h * h)
}
fn density_g(kk: f64, f: f64, p: P3, t: f64) -> f64 {       // density road 2: Durrleman's g, no prices
    let (k, e) = ((kk / f).ln(), 1e-3);
    let w = |x: f64| hp(f * x.exp(), f, p, t).powi(2) * t;
    let (w0, wp, wm) = (w(k), w(k + e), w(k - e));
    let (w1, w2) = ((wp - wm) / (2.0 * e), (wp - 2.0 * w0 + wm) / (e * e));
    let g = (1.0 - k * w1 / (2.0 * w0)).powi(2) - w1 * w1 / 4.0 * (1.0 / w0 + 0.25) + w2 / 2.0;
    let d2 = -k / w0.sqrt() - w0.sqrt() / 2.0; (-d2 * d2 / 2.0).exp() / (2.0 * PI).sqrt() / (kk * w0.sqrt()) * g
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // where f changes sign
    for _ in 0..80 { let m = (lo + hi) / 2.0; if (f(m) > 0.0) == (f(lo) > 0.0) { lo = m } else { hi = m } }
    (lo + hi) / 2.0
}
fn row(label: &str, vals: &[f64], d: usize) { println!("{:<46}{}", label, vals.iter().map(|v| format!("{:>12.*}", d, v)).collect::<String>()); }
fn chart(label: &str, vals: Vec<String>) { println!("{}{}", label, vals.join(" ")); }
fn main() {
    let (f, f10) = (fwd(T1), fwd(10.0));
    let (k1, s1, s0, k2, s2) = (QUOTES[0], QUOTES[1], QUOTES[2], QUOTES[3], QUOTES[4]);
    let (a1, r1, n1, its, det) = fit_newton(QUOTES, f, T1, 0.0, 0.5);
    let (a2, r2, n2) = fit_bisect(QUOTES, f, T1);
    let p: P3 = (a1, r1, n1); let (c2, c1) = coeffs(r1, n1, T1); let root = (c1 * c1 + 4.0 * c2 * s0).sqrt();
    let big = (-c1 - root) / (2.0 * c2); let z = n1 / a1 * (f / k1).ln();
    let chi_s = simpson(&|s: f64| 1.0 / (1.0 - 2.0 * r1 * s + s * s).sqrt(), 0.0, z);   // chi' = 1/sqrt(...)
    println!("quotes: {} at {:.0}%, forward {:.6} at {:.0}%, {} at {:.0}%; T = 1", k1, 100.0 * s1, f, 100.0 * s0, k2, 100.0 * s2);
    row("risk reversal, butterfly (vol points)", &[100.0 * (s2 - s1), 100.0 * ((s1 + s2) / 2.0 - s0)], 4);
    row(&format!("road 1, 2-D Newton, {} steps: a, rho, nu, det", its), &[a1, r1, n1, det], 6);
    row("road 2, nested bisection: a, rho, nu", &[a2, r2, n2], 6);
    let strays = [-0.9, -0.6, -0.3, 0.0, 0.3, 0.6, 0.9].iter().flat_map(|&r| [0.2, 0.5, 1.0, 2.0, 3.0].map(|n| fit_newton(QUOTES, f, T1, r, n)))
        .filter(|g| (g.1 - r1).abs() + (g.2 - n1).abs() > 1e-9).count();
    row("road 1 from 35 starts: fits found elsewhere", &[strays as f64], 0);
    row("ATM equation: c2, c1, root of c1^2 + 4 c2 s", &[c2, c1, root], 6);
    row("alpha: quadratic, Newton from 0.20, large root", &[alpha_quad(s0, r1, n1, T1), alpha_newton(s0, f, r1, n1, T1, s0), big], 6);
    row("vertex alpha, peak ATM vol it allows", &[-c1 / (2.0 * c2), c1 * c1 / (-4.0 * c2)], 6);
    row("edges: alpha at nu = 0, alpha at rho = 0", &[alpha_quad(s0, r1, 0.0, T1), alpha_quad(s0, 0.0, n1, T1)], 6);
    let aw = alpha_quad(s0, -0.999, 0.4, T1); let tilt = hagan(k2, f, aw, -0.999, 0.4, T1) - hagan(k1, f, aw, -0.999, 0.4, T1);
    row("widest tilt, nu 0.40, rho -0.999 (vol points)", &[100.0 * tilt], 4);
    row("by hand at 92.15: ln(F/K), nu/alpha, z", &[(f / k1).ln(), n1 / a1, z], 6);
    row("by hand at 92.15: chi, by Simpson, z/chi", &[chi(z, r1), chi_s, z / chi(z, r1)], 6);
    row("by hand at 92.15: time factor, fitted vol", &[c1 + c2 * a1, hp(k1, f, p, T1)], 6);
    for (kind, k, q) in [("put ", k1, s1), ("call", f, s0), ("call", k2, s2)] {
        let (par, disc) = (if kind == "put " { f - k } else { 0.0 }, (-R * T1).exp());   // put = call - (F - K)
        row(&format!("{} {:6.2}: fitted vol %, $ at fit, at quote", kind, k),
            &[100.0 * hp(k, f, p, T1), disc * (call(k, f, p, T1) - par), disc * (black(f, k, q, T1) - par)], 6);
    }
    let ph: P3 = (alpha_quad(s0, HOUSE.0, HOUSE.1, T1), HOUSE.0, HOUSE.1); let (ah, hv) = (ph.0, [hp(k1, f, ph, T1), hp(k2, f, ph, T1)]);
    let (h_a, h_r, h_n, _, _) = fit_newton([k1, hv[0], s0, k2, hv[1]], f, T1, 0.0, 0.5);
    row("house SABR: a, rho, nu, vols at the wings", &[ah, HOUSE.0, HOUSE.1, 100.0 * hv[0], 100.0 * hv[1]], 4);
    row("house round trip: a, rho, nu recovered", &[h_a, h_r, h_n], 6);
    row("wrong: large root, vols at 92.15, 119.93 (%)", &[100.0 * hagan(k1, f, big, r1, n1, T1), 100.0 * hagan(k2, f, big, r1, n1, T1)], 4);
    row("wrong: alpha = 0.20, ATM vol comes out (%)", &[100.0 * hagan(f, f, s0, r1, n1, T1)], 4);
    row("wrong: ATM read as $100, fitted vol there (%)", &[100.0 * hp(100.0, f, p, T1)], 4);
    let dd = |fw: f64, t: f64| (density_prices(40.0, fw, p, t), density_g(40.0, fw, p, t)); let ((d1p, d1g), (d10p, d10g)) = (dd(f, T1), dd(f10, 10.0));
    row("nu^2 T at 1 year and at 10 years", &[n1 * n1, 10.0 * n1 * n1], 4);
    row("density at $40 x100, 1 year: prices, g", &[100.0 * d1p, 100.0 * d1g], 6);
    row("density at $40 x100, 10 years: prices, g", &[100.0 * d10p, 100.0 * d10g], 6);
    row("density at $40 x100, T = 1, 2, 3, 5, 10", &[1.0, 2.0, 3.0, 5.0, 10.0].map(|t| 100.0 * density_prices(40.0, fwd(t), p, t)), 4);
    row("10-year forward, fitted vol at $40 (%)", &[f10, 100.0 * hp(40.0, f10, p, 10.0)], 4);
    let c10 = [30.0, 40.0, 50.0].map(|k| call(k, f10, p, 10.0));
    row("10 years: D, calls at 30, 40, 50 (undiscounted)", &[(-R * 10.0).exp(), c10[0], c10[1], c10[2]], 6);
    let fly = |t: f64, fw: f64| (-R * t).exp() * (call(30.0, fw, p, t) - 2.0 * call(40.0, fw, p, t) + call(50.0, fw, p, t));
    let simp = (-R * 10.0).exp() * simpson(&|x: f64| (10.0 - (x - 40.0).abs()) * density_g(x, f10, p, 10.0), 30.0, 50.0);
    row("butterfly 30/40/50 today ($): 1 year, 10 years", &[fly(T1, f), fly(10.0, f10)], 6);
    row("  10 years again, Simpson on tent x density", &[simp], 6);
    let d10 = |k: f64| density_prices(k, f10, p, 10.0);
    row("10 years: density changes sign at strikes", &[bisect(&d10, 60.0, 130.0), bisect(&d10, 150.0, 300.0)], 4);
    row("at $40 density turns negative past T (years)", &[bisect(&|t: f64| density_prices(40.0, fwd(t), p, t), 1.0, 10.0)], 4);
    row("try: Newton on the ATM vol from alpha = 10", &[alpha_newton(s0, f, r1, n1, T1, 10.0)], 6);
    let dh = |k: f64| density_prices(k, f10, ph, 10.0); row("try: house, 10 years: x100 at $40, < 0 below", &[100.0 * dh(40.0), bisect(&dh, 1.0, 40.0)], 6);
    let (sa, sr, sn, _, _) = fit_newton([k1, s2, s0, k2, s1], f, T1, 0.0, 0.5);
    row("try: wings swapped (18% low, 24% high)", &[sa, sr, sn], 6);
    let (grid, dg): (Vec<i32>, Vec<i32>) = ((80..=130).step_by(5).collect(), (20..=200).step_by(20).collect());
    chart("chart strikes ", grid.iter().map(|k| format!("{:6}", k)).collect());
    chart("chart fitted  ", grid.iter().map(|&k| format!("{:6.2}", 100.0 * hp(k as f64, f, p, T1))).collect());
    chart("chart house   ", grid.iter().map(|&k| format!("{:6.2}", 100.0 * hagan(k as f64, f, ah, HOUSE.0, HOUSE.1, T1))).collect());
    chart("chart K       ", dg.iter().map(|k| format!("{:6}", k)).collect());
    chart("chart 1y x100 ", dg.iter().map(|&k| format!("{:6.2}", 100.0 * density_prices(k as f64, f, p, T1))).collect());
    chart("chart 10y x100", dg.iter().map(|&k| format!("{:6.2}", 100.0 * density_prices(k as f64, f10, p, 10.0))).collect());
    assert!((a1 - a2).abs().max((r1 - r2).abs()).max((n1 - n2).abs()) < 1e-9, "two roads to alpha, rho, nu");
    assert!([(k1, s1), (f, s0), (k2, s2)].iter().all(|&(k, s)| (hp(k, f, p, T1) - s).abs() < 1e-12), "fit reprices the quotes");
    assert!((chi_s - chi(z, r1)).abs() < 1e-10, "chi in closed form = its integral");
    assert!((h_a - ah).abs().max((h_r - HOUSE.0).abs()).max((h_n - HOUSE.1).abs()) < 1e-9, "house parameters recovered");
    assert!((d10p - d10g).abs() < 1e-6 && (d1p - d1g).abs() < 1e-6, "two density roads agree");
    assert!(d10p < 0.0 && 0.0 < d1p, "negative at ten years, positive at one");
    assert!((simp - fly(10.0, f10)).abs() < 1e-6, "butterfly price = discounted tent x density");
    assert!(det.abs() > 1e-3 && strays == 0, "the fit is locally unique and every start finds it");
    assert!((alpha_newton(s0, f, r1, n1, T1, 10.0) - big).abs() < 1e-9 && (hagan(f, f, big, r1, n1, T1) - s0).abs() < 1e-12, "large root fits ATM too");
    assert!(s2 - s1 < tilt && tilt < 0.0, "at nu = 0.4 even rho = -0.999 falls short of the quoted tilt");
    println!("ALL CHECKS PASS");
}
