// Vehicle equations of motion: a jumbo jet at Mach 0.8, 40,000 ft.  std only, no crates.
// Road 1: modes as eigenvalues of the published linear sets (characteristic polynomial, roots).
// Road 2: the nonlinear body-axis equations, linearised by finite differences: same matrices, zero coupling.
// Road 3: fly the nonlinear equations (RK4), then fit the modes to the recorded motion (Prony).
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn ln(self) -> C { C { re: self.abs().ln(), im: self.im.atan2(self.re) } }
}
const FT: f64 = 0.3048;
const XU: f64 = -0.006868; const XW: f64 = 0.01395; const ZU: f64 = -0.09055; const ZW: f64 = -0.3151;
const MQ: f64 = -0.4285; const A0: f64 = 0.0803;
fn v0() -> f64 { 773.98 * FT } fn g0() -> f64 { 32.2 * FT } // airspeed, m/s; gravity, m/s^2
fn mu() -> f64 { 0.0001187 / FT } fn mw() -> f64 { -0.001026 / FT }
fn alon(mwv: f64, vq: f64) -> Vec<Vec<f64>> {
    vec![vec![XU, XW, 0.0, -g0()], vec![ZU, ZW, vq, 0.0], vec![mu(), mwv, MQ, 0.0], vec![0.0, 0.0, 1.0, 0.0]] }
fn alat(nr: f64, lb: f64) -> Vec<Vec<f64>> {
    vec![vec![-0.0558, -0.9968, 0.0802, 0.0415], vec![0.598, nr, -0.0318, 0.0], vec![lb, 0.388, -0.4650, 0.0], vec![0.0, 0.0805, 1.0, 0.0]] }
fn f(x: &[f64], pv: f64) -> Vec<f64> { // body-axis equations: x = u, w, q, theta, v, r, p, phi; pv 0 drops p v from heave
    let (u, w, q, th, v, r, p, ph) = (x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]);
    let (c, s, vv, g) = (A0.cos(), A0.sin(), v0(), g0());
    let (us, ws) = (c * u + s * w, -s * u + c * w);
    let (xs, zs) = (XU * (us - vv) + XW * ws, ZU * (us - vv) + ZW * ws - g);
    let b = (v / (u * u + v * v + w * w).sqrt()).asin();
    vec![r * v - q * w - g * th.sin() + c * xs - s * zs,
         q * u - pv * p * v + g * th.cos() * ph.cos() + s * xs + c * zs,
         mu() * (us - vv) + mw() * ws + MQ * q,
         q * ph.cos() - r * ph.sin(),
         p * w - r * u + g * th.cos() * ph.sin() - 0.0558 * vv * b,
         0.598 * b - 0.115 * r - 0.0318 * p,
         -3.05 * b + 0.388 * r - 0.465 * p,
         p + (q * ph.sin() + r * ph.cos()) * th.tan()]
}
fn mm(a: &[Vec<f64>], b: &[Vec<f64>]) -> Vec<Vec<f64>> {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect() }
fn key(z: &C, d: f64) -> (f64, f64) { ((z.re * d).round(), (z.im * d).round()) }
fn roots(cf: &[f64]) -> Vec<C> { // Durand-Kerner
    let n = cf.len() - 1;
    let (mut z, mut pw): (Vec<C>, C) = (Vec::new(), C { re: 1.0, im: 0.0 });
    for _ in 0..n { z.push(pw); pw = pw.mul(C { re: 0.4, im: 0.9 }); }
    for _ in 0..500 { for i in 0..n {
        let (mut pv, mut d) = (C { re: 0.0, im: 0.0 }, C { re: 1.0, im: 0.0 });
        for k in 0..=n { pv = pv.mul(z[i]).add(C { re: cf[k], im: 0.0 }); }
        for j in 0..n { if j != i { d = d.mul(z[i].sub(z[j])); } }
        z[i] = z[i].sub(pv.div(d));
    } }
    z.sort_by(|a, b| key(a, 1e9).partial_cmp(&key(b, 1e9)).unwrap());
    z
}
fn eig(a: &[Vec<f64>]) -> Vec<C> { // Faddeev-LeVerrier, then roots
    let n = a.len();
    let (mut m, mut cf) = (vec![vec![0.0; n]; n], vec![1.0]);
    for k in 1..=n {
        let am = mm(a, &m);
        m = (0..n).map(|i| (0..n).map(|j| am[i][j] + if i == j { cf[k - 1] } else { 0.0 }).collect()).collect();
        let am = mm(a, &m); cf.push(-(0..n).map(|i| am[i][i]).sum::<f64>() / k as f64);
    }
    roots(&cf)
}
fn show(tag: &str, lam: &[C], lo: f64) {
    for z in lam {
        if z.im < -1e-6 || !(lo < z.abs() && z.abs() < 9.0) { continue; }
        let tail = if z.re < 0.0 { format!("half-life {:7.2} s", 2f64.ln() / -z.re) } else { format!("doubles in {:5.2} s", 2f64.ln() / z.re) };
        if z.im.abs() < 1e-6 {
            println!("{:<9} real {:9.5} /s  time constant {:8.2} s  {}", tag, z.re, 1.0 / z.re.abs(), tail);
        } else {
            println!("{:<9} {:8.5} +/- {:7.5}j  wn {:7.4} rad/s  zeta {:7.4}  period {:6.2} s  {}",
                     tag, z.re, z.im, z.abs(), -z.re / z.abs(), 2.0 * PI / z.im, tail);
        }
    }
}
fn two(tag: &str, a: f64, b: f64, cc: f64, d: f64) -> (f64, f64) {
    let (tr, de) = (a + d, a * d - b * cc);
    println!("{:<20} trace {:8.4}  det {:7.4}  wn {:6.4} rad/s  zeta {:6.4}  period {:5.2} s",
             tag, tr, de, de.sqrt(), -tr / (2.0 * de.sqrt()), 2.0 * PI / (de - tr * tr / 4.0).sqrt());
    (de.sqrt(), -tr / (2.0 * de.sqrt()))
}
fn axpy(x: &[f64], h: f64, k: &[f64]) -> Vec<f64> { x.iter().zip(k).map(|(a, b)| a + h * b).collect() }
fn rk4(x: &[f64], dt: f64, pv: f64) -> Vec<f64> {
    let k1 = f(x, pv); let k2 = f(&axpy(x, dt / 2.0, &k1), pv);
    let k3 = f(&axpy(x, dt / 2.0, &k2), pv); let k4 = f(&axpy(x, dt, &k3), pv);
    (0..8).map(|i| x[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect()
}
fn fly(da: f64, db: f64, tend: f64, pv: f64) -> Vec<Vec<f64>> {
    let v = v0();
    let mut x = vec![v * db.cos() * (A0 + da).cos(), v * db.cos() * (A0 + da).sin(), 0.0, A0, v * db.sin(), 0.0, 0.0, 0.0];
    let mut rec = vec![x.clone()];
    for _ in 0..(tend / 0.02).round() as usize { x = rk4(&x, 0.02, pv); rec.push(x.clone()); }
    rec
}
fn prony(y: &[f64], dt: f64) -> Vec<C> {
    let rows: Vec<[f64; 5]> = (0..y.len() - 4).map(|k| [y[k + 3], y[k + 2], y[k + 1], y[k], -y[k + 4]]).collect();
    let mut m: Vec<Vec<f64>> = (0..4).map(|i| (0..5).map(|j| rows.iter().map(|r| r[i] * r[j]).sum()).collect()).collect();
    for i in 0..4 { for k in i + 1..4 { let fk = m[k][i] / m[i][i]; m[k] = (0..5).map(|j| m[k][j] - fk * m[i][j]).collect(); } }
    let mut a = [0.0; 4];
    for i in (0..4).rev() { a[i] = (m[i][4] - (i + 1..4).map(|j| m[i][j] * a[j]).sum::<f64>()) / m[i][i]; }
    let mut z: Vec<C> = roots(&[1.0, a[0], a[1], a[2], a[3]]).iter().map(|r| { let l = r.ln(); C { re: l.re / dt, im: l.im / dt } }).collect();
    z.sort_by(|a, b| key(a, 1e6).partial_cmp(&key(b, 1e6)).unwrap());
    z
}
fn alpha(x: &[f64]) -> f64 { x[1].atan2(x[0]) - A0 }
fn main() {
    let (v, g, c, s) = (v0(), g0(), A0.cos(), A0.sin());
    let x0 = vec![v * c, v * s, 0.0, A0, 0.0, 0.0, 0.0, 0.0];
    let mut jac = vec![vec![0.0; 8]; 8];
    for j in 0..8 {
        let h = 1e-6 * x0[j].abs().max(1.0);
        let (mut xp, mut xm) = (x0.clone(), x0.clone());
        xp[j] += h; xm[j] -= h; let (fp, fm) = (f(&xp, 1.0), f(&xm, 1.0));
        for i in 0..8 { jac[i][j] = (fp[i] - fm[i]) / (2.0 * h); }
    }
    let rot = vec![vec![c, s, 0.0, 0.0], vec![-s, c, 0.0, 0.0], vec![0.0, 0.0, 1.0, 0.0], vec![0.0, 0.0, 0.0, 1.0]];
    let back = vec![vec![c, -s, 0.0, 0.0], vec![s, c, 0.0, 0.0], vec![0.0, 0.0, 1.0, 0.0], vec![0.0, 0.0, 0.0, 1.0]];
    let jlon = mm(&mm(&rot, &(0..4).map(|i| jac[i][..4].to_vec()).collect::<Vec<_>>()), &back);
    let jlat: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j| jac[4 + i][4 + j] * (if j == 0 { v } else { 1.0 }) / (if i == 0 { v } else { 1.0 })).collect()).collect();
    let (pl, pa) = (alon(mw(), v), alat(-0.115, -3.05));
    let (mut dlon, mut dlat, mut cross) = (0.0f64, 0.0f64, 0.0f64);
    for i in 0..4 { for j in 0..4 { dlon = dlon.max((jlon[i][j] - pl[i][j]).abs()); dlat = dlat.max((jlat[i][j] - pa[i][j]).abs()); } }
    for i in 0..8 { for j in 0..8 { if (i < 4) != (j < 4) { cross = cross.max(jac[i][j].abs()); } } }
    println!("trim: altitude {:.0} m, V {:.3} m/s, g {:.4} m/s^2, alpha = theta = {} rad = {:.2} deg, Mw {:.6} /(m s)", 40000.0 * FT, v, g, A0, A0.to_degrees(), mw());
    println!("jacobian vs published: longitudinal max diff {:.6}, lateral max diff {:.6}", dlon, dlat);
    println!("jacobian coupling blocks, largest entry {:.6}", cross);
    println!("lateral kinematics: -cos a0 {:.5}, sin a0 {:.5}, g cos a0 / V {:.5}, tan a0 {:.5}", jlat[0][1], jlat[0][2], jlat[0][3], jlat[3][1]);
    let (lon, lat) = (eig(&pl), eig(&pa));
    show("lon", &lon, 0.0); show("lat", &lat, 0.0);
    let plon = prony(&fly(0.1f64.to_radians(), 0.0, 300.0, 1.0).iter().step_by(50).map(|x| x[2]).collect::<Vec<f64>>(), 1.0);
    let plat = prony(&fly(0.0, 0.1f64.to_radians(), 300.0, 1.0).iter().step_by(50).map(|x| x[6]).collect::<Vec<f64>>(), 1.0);
    show("fit lon", &plon, 0.0); show("fit lat", &plat, 0.0);
    let (wsp, _) = two("short period 2x2", ZW, v, mw(), MQ);
    let (_, zdr) = two("dutch roll 2x2", -0.0558, -0.9968, 0.598, -0.115);
    show("no V*q", &eig(&alon(mw(), 0.0)), 0.0);
    println!("dutch roll {:.4} rad/s read as Hz: period {:.2} s (right {:.2} s)", lat[2].abs(), 1.0 / lat[2].abs(), 2.0 * PI / lat[2].im);
    let mut amp: Vec<f64> = Vec::new();
    for b0 in [1.0f64, 5.0, 15.0] {
        let rec = fly(0.0, b0.to_radians(), 40.0, 1.0);
        let da = rec.iter().map(|x| alpha(x).abs()).fold(0.0, f64::max); amp.push(da);
        let bank = rec.iter().map(|x| x[7].to_degrees().abs()).fold(0.0, f64::max);
        println!("sideslip {:2} deg: linear says alpha moves 0; nonlinear peak alpha change {:6.3} deg, peak bank {:5.2} deg, x{:6.1} the 1 deg case",
                 b0 as i32, da.to_degrees(), bank, da / amp[0]);
    }
    let npv = fly(0.0, 5f64.to_radians(), 40.0, 0.0).iter().map(|x| alpha(x).abs()).fold(0.0, f64::max); // roll-times-sideslip p v dropped
    println!("sideslip  5 deg, p v dropped from heave: peak alpha change {:6.3} deg", npv.to_degrees());
    let osc = |l: Vec<C>| -> Vec<C> { l.into_iter().filter(|z| z.im.abs() > 0.1).collect() };
    show("Mw/2", &eig(&alon(mw() / 2.0, v)), 0.3); show("Mw flip", &eig(&alon(-mw(), v)), 0.3);
    show("Nr -0.6", &osc(eig(&alat(-0.6, -3.05))), 0.0); show("Lb 0", &osc(eig(&alat(-0.115, 0.0))), 0.0);
    let ra: Vec<String> = fly(1f64.to_radians(), 0.0, 20.0, 1.0).iter().step_by(50).map(|x| format!("{:.2}", alpha(x).to_degrees())).collect();
    let rb: Vec<String> = fly(0.0, 1f64.to_radians(), 20.0, 1.0).iter().step_by(50)
        .map(|x| format!("{:.2}", (x[4] / (x[0].powi(2) + x[1].powi(2) + x[4].powi(2)).sqrt()).asin().to_degrees())).collect();
    println!("chart alpha change, deg: {}", ra.join(" "));
    println!("chart sideslip, deg:     {}", rb.join(" "));
    assert!(dlon < 1e-6, "linearised body-axis equations must reproduce the published longitudinal set");
    assert!(dlat < 1e-4, "... and the published lateral set, to its 3-4 figure rounding");
    assert!(cross < 1e-9, "turning-axes and gravity terms must not couple the two sets to first order");
    for (a, b) in lon.iter().chain(lat.iter()).zip(plon.iter().chain(plat.iter())) {
        assert!(a.sub(*b).abs() < 0.01 * a.abs() + 1e-4, "modes fitted to the flight record must match the eigenvalues");
    }
    assert!((wsp - eig(&vec![vec![ZW, v], vec![mw(), MQ]])[0].abs()).abs() < 1e-9, "trace-determinant formula must match the 2x2 eigenvalues");
    assert!((wsp / lon[0].abs() - 1.0).abs() < 0.01, "2x2 short period within 1% of the full set");
    assert!(zdr / (-lat[2].re / lat[2].abs()) > 2.0, "2x2 dutch roll over-states the damping");
    assert!((amp[1] / amp[0] - 25.0).abs() < 2.5, "coupling grows as the square of the disturbance");
    assert!(npv < amp[1] / 2.0, "the roll-times-sideslip product p v carries most of the coupling");
    println!("ALL CHECKS PASS");
}
