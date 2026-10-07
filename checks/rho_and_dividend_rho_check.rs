// Rho and dividend rho -- the check behind the card.  Rust std only, no crates.
// Same roads as the Python: formula, bumped formula, bumped Simpson integral,
// pathwise integral.  Normal CDF, bisection and Simpson are written out here.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut n) = (x, x, 1.0_f64);
    while s + t * x * x / (2.0 * n + 1.0) != s {        // x + x^3/3 + x^5/(3*5) + ...
        t *= x * x / (2.0 * n + 1.0); s += t; n += 1.0;
    }
    0.5 + s * phi(x)
}
fn d1d2(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let v = sig * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / v;
    (d1, d1 - v)
}
fn call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, r, q, sig, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn rho_c(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 { k * t * (-r * t).exp() * n_cdf(d1d2(s, k, r, q, sig, t).1) }
fn rho_p(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 { -k * t * (-r * t).exp() * n_cdf(-d1d2(s, k, r, q, sig, t).1) }
fn qrho_c(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 { -t * s * (-q * t).exp() * n_cdf(d1d2(s, k, r, q, sig, t).0) }
fn qrho_p(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 { t * s * (-q * t).exp() * n_cdf(-d1d2(s, k, r, q, sig, t).0) }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 20000;
    let h = (b - a) / n as f64;
    let mut tot = f(a) + f(b);
    for i in 1..n { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    tot * h / 3.0
}
// Road 3 (kind 0 call, 1 put) and road 4 (kind 2, pathwise): the average done by brute force.
fn by_integral(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, kind: u8) -> f64 {
    let st = |z: f64| s * ((r - q - 0.5 * sig * sig) * t + sig * t.sqrt() * z).exp();
    let (mut lo, mut hi) = (-10.0_f64, 10.0_f64);      // bisection: where does S_T cross K?
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if st(mid) > k { hi = mid; } else { lo = mid; }
    }
    let zc = 0.5 * (lo + hi);
    let v = match kind {
        0 => simpson(|z| (st(z) - k) * phi(z), zc, 10.0),
        1 => simpson(|z| (k - st(z)) * phi(z), -10.0, zc),
        _ => simpson(|z| (t * st(z) - t * (st(z) - k)) * phi(z), zc, 10.0),
    };
    (-r * t).exp() * v
}

fn main() {
    let (s, k, r, q, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d1, d2) = d1d2(s, k, r, q, sig, t);
    let (c, h) = (call(s, k, r, q, sig, t), 1e-4);
    let (ci, pi_) = (by_integral(s, k, r, q, sig, t, 0), by_integral(s, k, r, q, sig, t, 1));
    let (rho, rho_put) = (rho_c(s, k, r, q, sig, t), rho_p(s, k, r, q, sig, t));
    let (qrho, qrho_put) = (qrho_c(s, k, r, q, sig, t), qrho_p(s, k, r, q, sig, t));
    let bump = |f: &dyn Fn(f64, f64) -> f64, dr: f64, dq: f64| (f(r + dr, q + dq) - f(r - dr, q - dq)) / (2.0 * h);
    let rho_bump = bump(&|rr, qq| call(s, k, rr, qq, sig, t), h, 0.0);
    let rho_int = bump(&|rr, qq| by_integral(s, k, rr, qq, sig, t, 0), h, 0.0);
    let rho_path = by_integral(s, k, r, q, sig, t, 2);
    let rho_put_int = bump(&|rr, qq| by_integral(s, k, rr, qq, sig, t, 1), h, 0.0);
    let qrho_int = bump(&|rr, qq| by_integral(s, k, rr, qq, sig, t, 0), 0.0, h);
    let qrho_put_int = bump(&|rr, qq| by_integral(s, k, rr, qq, sig, t, 1), 0.0, h);
    let dens = s * (-q * t).exp() * phi(d1) * t.sqrt() / sig;   // the two terms that cancel
    let dens2 = k * (-r * t).exp() * phi(d2) * t.sqrt() / sig;
    let up1pc = call(s, k, r + 0.01, q, sig, t) - c;
    let kte = k * t * (-r * t).exp();

    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("N(-d1)", n_cdf(-d1)), ("N(-d2)", n_cdf(-d2)), ("e^-rT", (-r * t).exp()), ("e^-qT", (-q * t).exp()),
        ("share half  S e^-qT N(d1)", s * (-q * t).exp() * n_cdf(d1)), ("cash half   K e^-rT N(d2)", k * (-r * t).exp() * n_cdf(d2)),
        ("call, formula", c), ("call, Simpson integral", ci), ("put, Simpson integral", pi_),
        ("d1 and d2 move per unit r", t.sqrt() / sig), ("density term, share side", dens), ("density term, cash side", -dens2),
        ("rho 1 formula K T e^-rT N(d2)", rho), ("rho 2 bump the formula", rho_bump),
        ("rho 3 bump the integral", rho_int), ("rho 4 pathwise integral", rho_path),
        ("rho per basis point", rho / 1e4),
        ("rho per 1 percent", rho / 100.0), ("reprice, r up 1 percent", up1pc),
        ("put rho, formula", rho_put), ("put rho, bump the integral", rho_put_int),
        ("rho call - rho put", rho - rho_put_int), ("K T e^-rT", kte),
        ("dividend rho call, formula", qrho), ("dividend rho call, bump", qrho_int),
        ("dividend rho put, formula", qrho_put), ("dividend rho put, bump", qrho_put_int),
        ("div rho call - div rho put", qrho - qrho_put_int), ("-T S e^-qT", -t * s * (-q * t).exp()),
        ("call: rho + dividend rho", rho + qrho), ("put: rho + dividend rho", rho_put + qrho_put),
        ("wrong: N(d1) for N(d2)", kte * n_cdf(d1)), ("wrong: no e^-rT", k * t * n_cdf(d2)),
        ("wrong: put rho = -call rho", -rho),
        ("wrong: no T, 5-year option", k * (-r * 5.0).exp() * n_cdf(d1d2(s, k, r, q, sig, 5.0).1)),
        ("  right, 5-year option", rho_c(s, k, r, q, sig, 5.0)),
        ("try: K = 130", rho_c(s, 130.0, r, q, sig, t)),
        ("try: T = 20", rho_c(s, k, r, q, sig, 20.0)),
    ];
    for (name, v) in &rows { println!("{:<31} {:>13.6}", name, v); }

    println!("maturity  call   rho  put rho  per 1%  % of call");
    for tt in [1.0 / 12.0, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0] {
        let (cc, rc, rp) = (call(s, k, r, q, sig, tt), rho_c(s, k, r, q, sig, tt), rho_p(s, k, r, q, sig, tt));
        println!("{:8.2} {:6.2} {:6.2} {:8.2} {:7.2} {:9.2}", tt, cc, rc, rp, rc / 100.0, rc / cc);
    }
    let rates: Vec<f64> = (0..11).map(|i| 0.01 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64, w: &str| -> String {
        format!("{}{}", w, rates.iter().map(|x| format!("{:5.2}", f(*x))).collect::<Vec<_>>().join(" "))
    };
    println!("chart, rate %  {}", rates.iter().map(|x| format!("{:5.0}", 100.0 * x)).collect::<Vec<_>>().join(" "));
    println!("{}", line(&|x| call(s, k, x, q, sig, t), "chart, call    "));
    println!("{}", line(&|x| c + rho * (x - r), "chart, tangent "));

    assert!((rho - 49.458109105322).abs() < 1e-9, "formula vs the house number");
    assert!((rho_bump - rho).abs() < 1e-5, "bumped formula price");
    assert!((rho_int - rho).abs() < 1e-5, "bumped integral price: no d1, d2 or N used");
    assert!((rho_path - rho).abs() < 1e-8, "pathwise integral");
    assert!(((rho - rho_put_int) - kte).abs() < 1e-5, "parity in r, put from the integral");
    assert!((qrho_int - qrho).abs() < 1e-5, "dividend rho, call, by bump");
    assert!((qrho_put_int - qrho_put).abs() < 1e-5, "dividend rho, put, by bump");
    assert!(((rho + qrho) + t * ci).abs() < 1e-8, "parallel move: rho + dividend rho = -T C");
    assert!((dens - dens2).abs() < 1e-9, "the two density terms cancel");
    assert!(((rho_put + qrho_put) + t * pi_).abs() < 1e-8, "parallel move for the put");
    println!("ALL CHECKS PASS");
}
