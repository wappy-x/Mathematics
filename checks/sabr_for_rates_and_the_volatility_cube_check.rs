// SABR for rates -- the same check as the Python, in Rust.  No crates: the normal CDF, root finders,
// integrator and the solvers are written here.  A 1-into-5 swaption smile, shifted SABR, and a small cube.
use std::f64::consts::PI;
const NOTIONAL: f64 = 1e6; const ANN: f64 = 4.40; const T: f64 = 1.0; const SHIFT: f64 = 0.02;
const S: f64 = 0.025; const QL: f64 = 0.22625; const QA: f64 = 0.22; const QH: f64 = 0.22375;

fn ncdf(x: f64) -> f64 {                   // Marsaglia: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { t = s; i += 2.0; b *= x * x / i; s = t + b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn payer(s: f64, k: f64, vol: f64, t: f64) -> f64 {   // shifted Black: N A [f N(d1) - k N(d2)]
    let (f, kk, v) = (s + SHIFT, k + SHIFT, vol * t.sqrt());
    let d1 = ((f / kk).ln() + 0.5 * v * v) / v;
    NOTIONAL * ANN * (f * ncdf(d1) - kk * ncdf(d1 - v))
}
fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64, n: usize) -> f64 {   // increasing function
    for _ in 0..n { let mid = 0.5 * (lo + hi); if g(mid) < 0.0 { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn chi(z: f64, rho: f64) -> f64 { (((1.0 - 2.0 * rho * z + z * z).sqrt() + z - rho) / (1.0 - rho)).ln() }
fn hagan(f: f64, k: f64, a: f64, beta: f64, rho: f64, nu: f64, t: f64) -> f64 {   // Hagan et al. (2002)
    let (e, lf) = (1.0 - beta, (f / k).ln());
    let fk = (f * k).powf(e / 2.0);
    let z = nu / a * fk * lf;
    let zx = if z.abs() < 1e-12 { 1.0 } else { z / chi(z, rho) };
    let back = fk * (1.0 + e * e / 24.0 * lf * lf + e * e * e * e / 1920.0 * (lf * lf * lf * lf));
    let corr = e * e * a * a / (24.0 * fk * fk) + rho * beta * nu * a / (4.0 * fk) + (2.0 - 3.0 * rho * rho) * nu * nu / 24.0;
    a / back * zx * (1.0 + corr * t)
}
fn alpha(s: f64, beta: f64, rho: f64, nu: f64, atm: f64, t: f64) -> f64 {   // ATM quote met
    let f = s + SHIFT;
    bisect(|x| hagan(f, f, x, beta, rho, nu, t) - atm, 1e-6, 1.0, 100)
}
fn vol_at(s: f64, k: f64, a: f64, beta: f64, rho: f64, nu: f64, t: f64) -> f64 { hagan(s + SHIFT, k + SHIFT, a, beta, rho, nu, t) }
fn wings(s: f64, beta: f64, rho: f64, nu: f64, q: [f64; 3], t: f64) -> (f64, f64) {
    let a = alpha(s, beta, rho, nu, q[1], t);
    (vol_at(s, s - 0.005, a, beta, rho, nu, t), vol_at(s, s + 0.005, a, beta, rho, nu, t))
}
fn read(s: f64, beta: f64, q: [f64; 3]) -> (f64, f64, f64, f64) {   // road 3: near-money reading
    let (yl, yh) = (((s - 0.005 + SHIFT) / (s + SHIFT)).ln(), ((s + 0.005 + SHIFT) / (s + SHIFT)).ln());
    let (rl, rh) = (q[0] / q[1] - 1.0, q[2] / q[1] - 1.0);
    let curve = (rl / yl - rh / yh) / (yl - yh);
    let slope = rl / yl - curve * yl;
    let m = 2.0 * slope + (1.0 - beta);
    let lam = ((12.0 * curve - (1.0 - beta) * (1.0 - beta) + 3.0 * m * m) / 2.0).sqrt();
    (slope, curve, m / lam, lam * q[1])
}
fn newton(s: f64, beta: f64, q: [f64; 3], t: f64, mut rho: f64, mut nu: f64) -> (f64, f64) {   // road 1
    for _ in 0..40 {
        let (lo, hi) = wings(s, beta, rho, nu, q, t);
        let (r1, r2, h) = (lo - q[0], hi - q[2], 1e-6);
        let (a1, a2) = wings(s, beta, rho + h, nu, q, t); let (b1, b2) = wings(s, beta, rho, nu + h, q, t);
        let (j11, j21, j12, j22) = ((a1 - lo) / h, (a2 - hi) / h, (b1 - lo) / h, (b2 - hi) / h);
        let det = j11 * j22 - j12 * j21;
        let (nr, nn) = (rho - (j22 * r1 - j12 * r2) / det, nu - (j11 * r2 - j21 * r1) / det);
        rho = nr; nu = nn;
    }
    (rho, nu)
}
fn nested(s: f64, beta: f64, q: [f64; 3], t: f64) -> (f64, f64) {   // road 2: nu for the fly, rho for the RR
    let (rr, bf) = (q[2] - q[0], 0.5 * (q[0] + q[2]) - q[1]);
    let rho_for = |nu: f64| bisect(|r| { let w = wings(s, beta, r, nu, q, t); w.1 - w.0 - rr }, -0.99, 0.99, 60);
    let nu = bisect(|nu| { let w = wings(s, beta, rho_for(nu), nu, q, t); 0.5 * (w.0 + w.1) - q[1] - bf }, 0.05, 2.0, 60);
    (rho_for(nu), nu)
}
fn show(rows: &[(&str, f64)]) { for (label, v) in rows { println!("{:<44}{:>14.6}", label, v); } }
fn main() {
    let q = [QL, QA, QH];
    let (f, rrbp, bfbp) = (S + SHIFT, 1e4 * (QH - QL), 1e4 * (0.5 * (QL + QH) - QA));
    let (slope, curve, rho3, nu3) = read(S, 0.5, q);
    let (rho1, nu1) = newton(S, 0.5, q, T, rho3, nu3);
    let (rho2, nu2) = nested(S, 0.5, q, T);
    let al = alpha(S, 0.5, rho1, nu1, QA, T);
    let vol = |k: f64| vol_at(S, k, al, 0.5, rho1, nu1, T);
    let (lf, akk) = ((f / (S - 0.005 + SHIFT)).ln(), al / (f * (S - 0.005 + SHIFT)).powf(0.25));
    let z = nu1 / akk * lf;
    let corr = akk * akk / 96.0 + rho1 * nu1 * akk / 8.0 + (2.0 - 3.0 * rho1 * rho1) * nu1 * nu1 / 24.0;
    show(&[("shifted forward f = F + shift", f), ("risk reversal, vol bp (high - low)", rrbp),
        ("butterfly, vol bp (mean wing - ATM)", bfbp), ("road 3: slope of vol ratio in log-strike", slope),
        ("road 3: curvature of vol ratio", curve), ("road 3: rho, read", rho3), ("road 3: nu, read", nu3),
        ("road 1: rho, Newton", rho1), ("road 1: nu, Newton", nu1), ("road 2: rho, nested bisection", rho2),
        ("road 2: nu, nested bisection", nu2), ("alpha from the ATM quote", al), ("alpha / f^(1-beta)", al / f.sqrt()),
        ("lambda = nu f^(1-beta) / alpha", nu1 * f.sqrt() / al),
        ("K = 2.00%: ln(f / k)", lf), ("K = 2.00%: level alpha / (f k)^(1/4)", akk), ("K = 2.00%: z", z),
        ("K = 2.00%: chi(z)", chi(z, rho1)), ("K = 2.00%: z / chi(z)", z / chi(z, rho1)),
        ("K = 2.00%: divisor 1 + l^2/96 + l^4/30720", 1.0 + lf * lf / 96.0 + (lf * lf * lf * lf) / 30720.0),
        ("K = 2.00%: time factor", 1.0 + corr * T), ("K = 2.00%: fitted vol", vol(S - 0.005)),
        ("K = 3.00%: fitted vol", vol(S + 0.005))]);
    let ks: Vec<f64> = (-4..=4).map(|i| S + 0.0025 * i as f64).collect();
    let betas = [0.0, 0.5, 1.0];
    let fits: Vec<(f64, f64)> = betas.iter().map(|&b| { let r = read(S, b, q); newton(S, b, q, T, r.2, r.3) }).collect();
    let alphas: Vec<f64> = betas.iter().zip(&fits).map(|(&b, &(r, n))| alpha(S, b, r, n, QA, T)).collect();
    println!("beta     rho       nu      alpha  {}", ks.iter().map(|k| format!("{:7.2}", 100.0 * k)).collect::<String>());
    for i in 0..3 {
        let (b, (r, n), a) = (betas[i], fits[i], alphas[i]);
        println!("{:4.1}{:9.4}{:9.4}{:11.6}  {}", b, r, n, a, ks.iter().map(|&k| format!("{:7.2}", 100.0 * vol_at(S, k, a, b, r, n, T))).collect::<String>());
    }
    let ds = [-0.005, -0.0025, 0.0, 0.0025, 0.005];
    println!("backbone: ATM vol % as F moves, dials held {}", ds.iter().map(|d| format!("{:+7.0}", 1e4 * d)).collect::<String>());
    for i in 0..3 {
        let (b, (r, n), a) = (betas[i], fits[i], alphas[i]);
        println!("  beta {:3.1}{:34}{}", b, "", ds.iter().map(|d| format!("{:7.2}", 100.0 * hagan(S + d + SHIFT, S + d + SHIFT, a, b, r, n, T))).collect::<String>());
    }
    let prem: Vec<f64> = ks.iter().map(|&k| payer(S, k, vol(k), T)).collect();
    let (v0, n_int) = (QA * T.sqrt(), 4000);
    let x0 = 0.5 * v0;                          // at the money the payoff starts where x = v0 / 2
    let hh = (10.0 - x0) / n_int as f64;        // second road for the premium: Simpson on E[(F_T - k)^+], x normal
    let atm_int = NOTIONAL * ANN * hh / 3.0 * (0..=n_int).map(|i| {
        let x = x0 + i as f64 * hh;
        let y = (f * (v0 * x - 0.5 * v0 * v0).exp() - f) * (-0.5 * x * x).exp() / (2.0 * PI).sqrt();
        y * if i == 0 || i == n_int { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }
    }).sum::<f64>();
    let flies: Vec<f64> = (1..8).map(|i| prem[i - 1] - 2.0 * prem[i] + prem[i + 1]).collect();
    let min_fly = flies.iter().cloned().fold(f64::INFINITY, f64::min);
    let up: Vec<f64> = (0..3).map(|i| hagan(S + 0.0025 + SHIFT, S + 0.0025 + SHIFT, alphas[i], betas[i], fits[i].0, fits[i].1, T)).collect();
    show(&[("payer K = 2.00%, dollars", prem[2]), ("payer K = 2.50% (ATM), Black, dollars", prem[4]),
        ("payer K = 2.50% (ATM), Simpson integral", atm_int), ("payer K = 3.00%, dollars", prem[6]),
        ("ATM normal vol, bp, from the premium", 1e4 * prem[4] / (NOTIONAL * ANN) * (2.0 * PI / T).sqrt()),
        ("smallest 25bp butterfly on the grid, dollars", min_fly),
        ("wrong: shift dropped, ATM payer at 22%", NOTIONAL * ANN * S * (2.0 * ncdf(0.5 * QA * T.sqrt()) - 1.0)),
        ("wrong: alpha set to 0.22, ATM vol", hagan(f, f, 0.22, 0.5, rho1, nu1, T)),
        ("beta 0 fit: ATM vol after +25bp", up[0]), ("beta 1 fit: ATM vol after +25bp", up[2]),
        ("ATM payer after +25bp, beta 0, dollars", payer(S + 0.0025, S + 0.0025, up[0], T)),
        ("ATM payer after +25bp, beta 0.5, dollars", payer(S + 0.0025, S + 0.0025, up[1], T)),
        ("ATM payer after +25bp, beta 1, dollars", payer(S + 0.0025, S + 0.0025, up[2], T))]);
    let cube = [("1y into 2y", 1.0, 0.015, [0.225, 0.200, 0.190]), ("1y into 5y", 1.0, 0.025, q),
        ("2y into 2y", 2.0, -0.005, [0.275, 0.240, 0.225]), ("2y into 5y", 2.0, 0.010, [0.245, 0.210, 0.190])];
    println!("cube node     F %   ATM %  RR bp  BF bp    alpha      rho       nu   miss bp");
    let mut miss: Vec<f64> = Vec::new();
    for (name, t, s, qq) in cube {
        let rd = read(s, 0.5, qq);
        let (r, n) = newton(s, 0.5, qq, t, rd.2, rd.3);
        let (w, a) = (wings(s, 0.5, r, n, qq, t), alpha(s, 0.5, r, n, qq[1], t));
        miss.push(1e4 * (w.0 - qq[0]).abs().max((w.1 - qq[2]).abs()));
        println!("{}{:7.2}{:8.2}{:7.1}{:7.1}{:9.5}{:9.4}{:9.4}{:10.6}", name, 100.0 * s, 100.0 * qq[1], 1e4 * (qq[2] - qq[0]),
            1e4 * (0.5 * (qq[0] + qq[2]) - qq[1]), a, r, n, miss[miss.len() - 1]);
    }
    assert!((rho1 - rho2).abs() < 1e-8 && (nu1 - nu2).abs() < 1e-8, "Newton and nested bisection land on the same dials");
    assert!((vol(S - 0.005) - QL).abs() < 1e-10 && (vol(S + 0.005) - QH).abs() < 1e-10, "fitted smile meets both wing quotes");
    assert!((akk * z / chi(z, rho1) * (1.0 + corr * T) / (1.0 + lf * lf / 96.0 + lf.powi(4) / 30720.0) - vol(S - 0.005)).abs() < 1e-12, "beta-1/2 hand formula = general Hagan");
    assert!((rho3 - rho1).abs() < 0.05 && (nu3 / nu1 - 1.0).abs() < 0.05, "the read-off dials sit near the exact fit");
    assert!((atm_int - prem[4]).abs() < 1e-6 * prem[4], "Black formula vs Simpson integral at the money");
    assert!(min_fly > 0.0, "no negative butterfly on the grid");
    assert!(up[0] < up[1] && up[1] < up[2], "the lower the beta, the more the ATM vol falls as rates rise");
    assert!(miss.iter().cloned().fold(0.0, f64::max) < 1e-6, "every cube node fits its three quotes");
    println!("ALL CHECKS PASS");
}
