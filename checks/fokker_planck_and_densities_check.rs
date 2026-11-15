// Fokker-Planck with edges -- the check behind the card.  Rust std only.
// Roads: (1) the closed-form bell; (2) the sum of decaying modes (Mehler's series);
// (3) a Crank-Nicolson finite-volume grid with a zero-flux, zero-value or wrong edge;
// (4) eigenvalues by shooting with RK4; plus residuals and the semigroup rule.
// Units: the rate in percentage points ("points"), time in years.
use std::f64::consts::PI;
const K: f64 = 0.5; const TH: f64 = 4.0; const SG: f64 = 2.0; const X0: f64 = 6.0;
const S2: f64 = SG * SG / (2.0 * K); // long-run variance, points squared
fn mu(y: f64) -> f64 { K * (TH - y) }
fn kern(t: f64, x: f64, y: f64) -> f64 { // road 1: the transition density
    let m = TH + (x - TH) * (-K * t).exp(); let v = S2 * (1.0 - (-2.0 * K * t).exp());
    (-(y - m).powi(2) / (2.0 * v)).exp() / (2.0 * PI * v).sqrt()
}
fn pinf(y: f64) -> f64 { (-(y - TH).powi(2) / (2.0 * S2)).exp() / (2.0 * PI * S2).sqrt() }
fn modes(t: f64, x: f64, y: f64, n: usize) -> (f64, f64) { // road 2: decaying modes
    let (a, b) = ((x - TH) / S2.sqrt(), (y - TH) / S2.sqrt());
    let (mut ha0, mut ha1, mut hb0, mut hb1, mut tot, mut fact) = (1.0, a, 1.0, b, 1.0, 1.0);
    let mut term = 0.0;
    for k in 1..n + 2 { // He_k by its recurrence
        let kf = k as f64; fact *= kf; term = (-kf * K * t).exp() * ha1 * hb1 / fact;
        if k <= n { tot += term; }
        let na = a * ha1 - kf * ha0; ha0 = ha1; ha1 = na;
        let nb = b * hb1 - kf * hb0; hb0 = hb1; hb1 = nb;
    }
    (pinf(y) * tot, pinf(y) * term)
}
fn phi_cdf(z: f64) -> f64 { // normal CDF by Simpson's rule
    let n = 2000; let h = z / n as f64; let mut s = 1.0 + (-z * z / 2.0).exp();
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * (-(i as f64 * h).powi(2) / 2.0).exp(); }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}
struct Snap { mass: f64, mean: f64, ys: Vec<f64>, p: Vec<f64> }
fn grid(lo: f64, hi: f64, h: f64, dt: f64, edge: &str, times: &[f64]) -> Vec<Snap> { // road 3
    let n = ((hi - lo) / h).round() as usize;
    let ys: Vec<f64> = (0..n).map(|i| lo + (i as f64 + 0.5) * h).collect();
    let mut p: Vec<f64> = ys.iter().map(|&y| kern(0.1, X0, y)).collect();
    let d = 0.5 * SG * SG / h;
    let (mut a, mut b, mut c) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
    for i in 0..n - 1 { // current through the face between i and i+1
        let m = mu(lo + (i as f64 + 1.0) * h); let (u, w) = ((m / 2.0 + d) / h, (m / 2.0 - d) / h);
        b[i] -= u; c[i] -= w; a[i + 1] += u; b[i + 1] += w;
    }
    if edge == "absorb" { b[0] -= 2.0 * d / h; } // p = 0 on the wall (mirror cell -p)
    if edge == "flat" { b[0] += mu(lo) / h; }   // wrong: p_y = 0, so J = mu p at the wall
    let (mut out, mut t, q) = (Vec::new(), 0.1, dt / 2.0);
    for &tt in times {
        while t < tt - 1e-9 {
            let r: Vec<f64> = (0..n).map(|i| p[i] + q * (b[i] * p[i]
                + if i > 0 { a[i] * p[i - 1] } else { 0.0 } + if i < n - 1 { c[i] * p[i + 1] } else { 0.0 })).collect();
            let (mut cc, mut dd) = (vec![0.0; n], vec![0.0; n]); // Thomas solve of (I - q A) p = r
            for i in 0..n {
                let den = 1.0 - q * b[i] + if i > 0 { q * a[i] * cc[i - 1] } else { 0.0 };
                cc[i] = -q * c[i] / den;
                dd[i] = (r[i] + if i > 0 { q * a[i] * dd[i - 1] } else { 0.0 }) / den;
            }
            for i in (0..n - 1).rev() { dd[i] -= cc[i] * dd[i + 1]; }
            p = dd; t += dt;
        }
        let mass = p.iter().sum::<f64>() * h;
        let mean = ys.iter().zip(&p).map(|(y, v)| y * v).sum::<f64>() * h;
        out.push(Snap { mass, mean, ys: ys.clone(), p: p.clone() });
    }
    out
}
fn shoot(nu: f64, f0: f64, d0: f64) -> f64 { // road 4: f'' - z f' + nu f = 0
    let (zw, zmax, n) = (-2.0, 6.0, 8000); let h = (zmax - zw) / n as f64;
    let (mut z, mut f, mut d) = (zw, f0, d0);
    let fd = |z: f64, f: f64, d: f64| (d, z * d - nu * f);
    for _ in 0..n {
        let k1 = fd(z, f, d); let k2 = fd(z + h / 2.0, f + h / 2.0 * k1.0, d + h / 2.0 * k1.1);
        let k3 = fd(z + h / 2.0, f + h / 2.0 * k2.0, d + h / 2.0 * k2.1); let k4 = fd(z + h, f + h * k3.0, d + h * k3.1);
        f += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        d += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1); z += h;
    }
    f
}
fn eigen(mut lo: f64, mut hi: f64, f: f64, d: f64) -> f64 { // bisect on the far-out sign
    let slo = shoot(lo, f, d);
    for _ in 0..40 {
        let mid = (lo + hi) / 2.0;
        if (shoot(mid, f, d) > 0.0) == (slo > 0.0) { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}
fn tv(t: f64) -> f64 {
    let h = 0.01;
    0.5 * h * (0..3200).map(|i| { let y = -12.0 + (i as f64 + 0.5) * h; (kern(t, X0, y) - pinf(y)).abs() }).sum::<f64>()
}
fn row(label: &str, v: f64, d: usize) { println!("{:<44}{:.*}", label, d, v); }
fn maxerr(s: &Snap) -> f64 { s.ys.iter().zip(&s.p).map(|(&y, &v)| (v - kern(1.0, X0, y)).abs()).fold(0.0, f64::max) }
fn main() {
    let m1 = TH + (X0 - TH) * (-K).exp(); let v1 = S2 * (1.0 - (-2.0 * K).exp());
    println!("1. One year, no edge (closed form, modes, grid)");
    row("fading factor e^(-kappa t)", (-K).exp(), 5); row("mean m, points", m1, 5); row("variance v, points^2", v1, 5); row("standard deviation", v1.sqrt(), 5);
    let pk = kern(1.0, X0, m1); let (pm, om) = modes(1.0, X0, m1, 30); row("peak density, bell, per point", pk, 5);
    row("peak density, 30 modes", pm, 5); row("  first omitted mode", om, 9);
    let fine = &grid(-8.0, 16.0, 0.05, 0.01, "reflect", &[1.0])[0]; let crs = &grid(-8.0, 16.0, 0.1, 0.02, "reflect", &[1.0])[0];
    let (e1, e2) = (maxerr(fine), maxerr(crs));
    row("grid max error, h = 0.1", e2, 7); row("grid max error, h = 0.05", e1, 7);
    for y in [2, 4, 6, 8] { row(&format!("density at {} points", y), kern(1.0, X0, y as f64), 5); }
    let sg = (0..2400).map(|i| { let z = -8.0 + (i as f64 + 0.5) * 0.01; kern(0.5, X0, z) * kern(0.5, z, m1) }).sum::<f64>() * 0.01;
    row("half a year twice, at the peak", sg, 5); let mut res = Vec::new();
    for h in [0.1, 0.05] { // p_t against L* in y and against L in x, at y = 5
        let pt = (kern(1.0 + h, X0, 5.0) - kern(1.0 - h, X0, 5.0)) / (2.0 * h);
        let fw = -(mu(5.0 + h) * kern(1.0, X0, 5.0 + h) - mu(5.0 - h) * kern(1.0, X0, 5.0 - h)) / (2.0 * h)
            + SG * SG / 2.0 * (kern(1.0, X0, 5.0 + h) - 2.0 * kern(1.0, X0, 5.0) + kern(1.0, X0, 5.0 - h)) / (h * h);
        let bw = mu(X0) * (kern(1.0, X0 + h, 5.0) - kern(1.0, X0 - h, 5.0)) / (2.0 * h)
            + SG * SG / 2.0 * (kern(1.0, X0 + h, 5.0) - 2.0 * kern(1.0, X0, 5.0) + kern(1.0, X0 - h, 5.0)) / (h * h);
        println!("{:<44}{:.7} {:.7}", format!("forward, backward residual, h = {}", h), pt - fw, pt - bw);
        res.push((pt - fw, pt - bw));
    }
    row("zero, in standard deviations from m", -m1 / v1.sqrt(), 4); row("free mass below 0 after one year", phi_cdf(-m1 / v1.sqrt()), 5);
    println!("2. A wall at zero");
    let belinf = phi_cdf(-2.0); let fl_mean = TH + S2.sqrt() * (-2.0f64).exp() / (2.0 * PI).sqrt() / (1.0 - belinf);
    row("free long-run mass below 0", belinf, 5); row("free long run: height at 4", pinf(4.0), 5);
    row("floor long run: height at 4, exact", pinf(4.0) / (1.0 - belinf), 5);
    row("floor long run: mean, exact", fl_mean, 5);
    let times = [0.5, 1.0, 2.0, 4.0, 8.0, 10.0, 12.0, 20.0, 30.0];
    let r = grid(0.0, 16.0, 0.05, 0.01, "reflect", &times); let a = grid(0.0, 16.0, 0.05, 0.01, "absorb", &times);
    let a2 = grid(0.0, 16.0, 0.1, 0.02, "absorb", &[10.0]); let w = grid(0.0, 16.0, 0.05, 0.01, "flat", &[1.0, 10.0]);
    let i4 = ((4.0 - 0.025) / 0.05f64).round() as usize;
    row("reflect: mass after 30 years", r[8].mass, 9); row("reflect: mean after 30 years", r[8].mean, 5);
    row("reflect: height at 4 after 30 years", r[8].p[i4] / 2.0 + r[8].p[i4 + 1] / 2.0, 5);
    row("reflect: mean after one year", r[1].mean, 5);
    row("absorb: survival 10 years, h = 0.1", a2[0].mass, 5); row("absorb: survival 10 years, h = 0.05", a[5].mass, 5);
    row("absorb: survival after 20 years", a[7].mass, 5);
    println!("3. How fast it settles (decay rate per year)");
    let nua = eigen(0.0, 1.0, 0.0, 1.0); let nur = eigen(0.5, 1.5, 1.0, 0.0);
    let ga = (a[5].mass / a[7].mass).ln() / 10.0; let gr = ((r[4].mean - r[8].mean) / (r[6].mean - r[8].mean)).ln() / 4.0;
    row("no edge: kappa, exact", K, 5); row("reflect: shooting", K * nur, 5); row("reflect: grid mean, 8 to 12 years", gr, 5);
    row("absorb: shooting", K * nua, 5); row("absorb: grid survival, 10 to 20 years", ga, 5);
    row("reflect minus absorb, shooting", K * (nur - nua), 5); row("half-life of the gap, ln 2 / kappa", 2f64.ln() / K, 4);
    println!("t, mean, sd, distance, leading mode, survival:");
    for (j, t) in [0.5, 1.0, 2.0, 4.0, 8.0].iter().enumerate() {
        println!("{:4.1} {:.4} {:.4} {:.5} {:.5} {:.5}", t, TH + (X0 - TH) * (-K * t).exp(), (S2 * (1.0 - (-2.0 * K * t).exp())).sqrt(),
            tv(*t), (2.0 / PI).sqrt() / 2.0 * (-K * t).exp(), a[j].mass);
    }
    println!("4. What breaks");
    row("p_y = 0 at the wall: mass after one year", w[0].mass, 4); row("p_y = 0 at the wall: mass after 10 years", w[1].mass, 2);
    row("absorbing used as a floor: mass, 10 years", a[5].mass, 4);
    row("settling at 2 kappa: distance at 4 years", (2.0 / PI).sqrt() / 2.0 * (-4.0f64).exp(), 5); row("  true distance at 4 years", tv(4.0), 5);
    let line = |f: &dyn Fn(f64) -> f64| (-2..11).map(|y| format!("{:.3}", f(y as f64))).collect::<Vec<_>>().join(" ");
    for t in [1.0, 4.0] { println!("chart t={:.0}: {}", t, line(&|y| kern(t, X0, y))); }
    println!("chart long run: {}", line(&|y| pinf(y)));
    assert!((pm - pk).abs() < 1e-6 && om.abs() < 1e-6);         // modes against the bell
    assert!(e1 < 1e-4 && 3.0 < e2 / e1 && e2 / e1 < 5.0);        // grid against the bell, second order
    assert!((sg - pk).abs() < 1e-8);                              // semigroup rule: half a year twice
    assert!([res[0].0 / res[1].0, res[0].1 / res[1].1].iter().all(|&q| 3.5 < q && q < 4.5)); // forward and backward residuals fall as h^2
    assert!((r[8].mass - 1.0).abs() < 1e-9 && (r[8].mean - fl_mean).abs() < 1e-4); // zero flux keeps mass
    assert!((ga - K * nua).abs() < 1e-4 && (gr - K * nur).abs() < 2e-3);          // grid against shooting
    assert!((nur - nua - 1.0).abs() < 1e-5);                     // the derivative identity
    assert!((tv(8.0) / ((2.0 / PI).sqrt() / 2.0 * (-4.0f64).exp()) - 1.0).abs() < 1e-3);
    assert!(w[1].mass > 2.0 && a[5].mass < 0.9);                 // wrong edges fail visibly
    println!("ALL CHECKS PASS");
}
