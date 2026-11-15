// Similarity solutions -- the same check in Rust, std only.  Two 1 m copper rods, one at
// 100 C and one at 20 C, joined end to end at t = 0.  kappa = 1.11e-4 m^2/s.  Roads: the
// similarity formula 60 - 40 erf(eta) with erf summed by hand; the reduced ODE
// F'' + 2 eta F' = 0 shot by RK4; a grid on both rods that knows no similarity; the PDE
// residual by centred differences.  Rust has no erf, so it is written out here too.
use std::f64::consts::PI;
const K: f64 = 1.11e-4; // copper diffusivity, m^2/s
const TH: f64 = 100.0; // hot rod, C
const TC: f64 = 20.0; // cold rod, C
const L: f64 = 1.0; // rod length, m
const TJ: f64 = (TH + TC) / 2.0; // the joint, held by symmetry

fn erfc(z: f64) -> f64 { // 1 - erf: continued fraction beyond 3, series below
    if z <= 3.0 { return 1.0 - erf(z); }
    let mut c = z;
    for k in (1..=60).rev() { c = z + k as f64 / 2.0 / c; }
    (-z * z).exp() / PI.sqrt() / c
}
fn erf(z: f64) -> f64 { // Maclaurin series, summed to the last term
    if z > 3.0 { return 1.0 - erfc(z); }
    let (mut s, mut term, mut n) = (0.0f64, z, 0.0f64);
    while term.abs() > 1e-17 * s.abs().max(1.0) {
        s += term / (2.0 * n + 1.0); n += 1.0; term *= -z * z / n;
    }
    2.0 / PI.sqrt() * s
}
fn eta(x: f64, t: f64) -> f64 { x / (2.0 * (K * t).sqrt()) } // the similarity variable
fn temp(x: f64, t: f64) -> f64 { TJ - (TJ - TC) * erf(eta(x, t)) } // cold rod, x >= 0 m from the joint

fn shoot(slope: f64) -> Vec<f64> { // road 2: RK4 on F' = G, G' = -2 eta G, F(0) = 60
    let h = 1e-3;
    let (mut f, mut g, mut e, mut out) = (TJ, slope, 0.0, vec![TJ]);
    for i in 0..6000 {
        let (k1f, k1g) = (g, -2.0 * e * g);
        let (k2f, k2g) = (g + h / 2.0 * k1g, -2.0 * (e + h / 2.0) * (g + h / 2.0 * k1g));
        let (k3f, k3g) = (g + h / 2.0 * k2g, -2.0 * (e + h / 2.0) * (g + h / 2.0 * k2g));
        let (k4f, k4g) = (g + h * k3g, -2.0 * (e + h) * (g + h * k3g));
        f += h / 6.0 * (k1f + 2.0 * k2f + 2.0 * k3f + k4f);
        g += h / 6.0 * (k1g + 2.0 * k2g + 2.0 * k3g + k4g);
        e = (i + 1) as f64 * h;
        out.push(f);
    }
    out
}

fn grid(h: f64, times: &[f64], flux: f64) -> Vec<Vec<f64>> { // road 3: explicit steps on [-1, 1] m, insulated ends
    let n = (2.0 * L / h).round() as usize;
    let mut r = 0.4; // r = kappa dt / h^2, inside the limit 1/2
    let mut u: Vec<f64> = (0..=n).map(|i| if i < n / 2 { TH } else if i > n / 2 { TC } else { TJ }).collect();
    if flux > 0.0 { u = vec![TC; n / 2 + 1]; } // or: one rod on [0, 1] m, heated at x = 0
    let n1 = (times[0] / (r * h * h / K)).ceil();
    let dt = times[0] / n1;
    r = K * dt / (h * h);
    let (mut out, mut done) = (vec![], 0i64);
    for &tt in times {
        for _ in 0..((tt / dt).round() as i64 - done) {
            let g0 = if flux > 0.0 { u[1] + 2.0 * h * flux / 401.0 } else { u[1] }; // ghost node: the end condition
            let m = u.len();
            let mut v = vec![u[0] + r * (g0 - 2.0 * u[0] + u[1])];
            for i in 1..m - 1 { v.push(u[i] + r * (u[i - 1] - 2.0 * u[i] + u[i + 1])); }
            v.push(u[m - 1] + 2.0 * r * (u[m - 2] - u[m - 1]));
            u = v;
        }
        out.push(u.clone());
        done = (tt / dt).round() as i64;
    }
    out
}
fn at(u: &[f64], h: f64, x: f64, flux: bool) -> f64 {
    u[(x / h).round() as usize + if flux { 0 } else { (L / h).round() as usize }]
}
fn pye(x: f64, d: usize) -> String { // e-notation with a two-digit exponent, as Python prints it
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}

fn main() {
    println!("copper, kappa = {:.2}e-4 m^2/s; hot rod {:.0} C joined to cold rod {:.0} C; each {:.0} m long", K * 1e4, TH, TC, L);
    println!("joint at once and for good: ({:.0} + {:.0})/2 = {:.0} C; cold rod T = 60 - 40 erf(x / (2 sqrt(kappa t)))", TH, TC, TJ);
    for t in [15.0f64, 60.0, 240.0] { println!("t = {:3} s: 2 sqrt(kappa t) = {:.2} cm", t as i64, 200.0 * (K * t).sqrt()); }
    let e5 = eta(0.05, 60.0);
    println!("at 5 cm, 60 s: eta = {:.4}, erf(eta) = {:.4}, T = 60 - 40 x {:.4} = {:.2} C", e5, erf(e5), erf(e5), temp(0.05, 60.0));
    let (mut lo, mut hi) = (0.0f64, 3.0f64);
    for _ in 0..60 { let m = (lo + hi) / 2.0; if erf(m) < 0.9 { lo = m } else { hi = m } }
    let _ = hi;
    println!("heat's reach (rise of 4 C, a tenth of 40): erf(eta) = 0.9 at eta = {:.4}; depth {:.1} cm at 60 s, {:.1} cm at 240 s",
        lo, 200.0 * lo * (K * 60.0).sqrt(), 200.0 * lo * (K * 240.0).sqrt());
    let (a, b) = (shoot(-40.0), shoot(-50.0)); // linear ODE: two shots fix the slope that ends at 20 C
    let s = -40.0 + (TC - a[6000]) / (b[6000] - a[6000]) * (-10.0);
    let ode = shoot(s);
    let gap = (0..31).map(|i| (ode[100 * i] - (TJ - (TJ - TC) * erf(0.1 * i as f64))).abs()).fold(0.0, f64::max);
    println!("road 2, RK4 shooting: slope F'(0) = {:.6} C, by formula -80/sqrt(pi) = {:.6}; largest gap on 0..3 = {} C", s, -80.0 / PI.sqrt(), pye(gap, 1));
    let mut res = vec![];
    for d in [1e-3f64, 5e-4] { // residual T_t - kappa T_xx at (5 cm, 60 s); dx = d m, dt = 1000 d s
        let tt = (temp(0.05, 60.0 + 1000.0 * d) - temp(0.05, 60.0 - 1000.0 * d)) / (2000.0 * d);
        let xx = K * (temp(0.05 + d, 60.0) - 2.0 * temp(0.05, 60.0) + temp(0.05 - d, 60.0)) / d.powi(2);
        res.push(tt - xx);
        println!("road 4, residual at 5 cm, 60 s, dx = {} mm: T_t = {:.6}, kappa T_xx = {:.6}, gap {} C/s", 1000.0 * d, tt, xx, pye(tt - xx, 2));
    }
    let mut errs = vec![];
    for h in [0.01f64, 0.005, 0.0025] {
        let g = grid(h, &[15.0, 60.0], 0.0);
        errs.push((at(&g[1], h, 0.05, false) - temp(0.05, 60.0)).abs());
        println!("road 3, grid h = {} mm: T(5 cm, 60 s) = {:.4} C, error {:.4}; joint {:.4} C",
            1000.0 * h, at(&g[1], h, 0.05, false), errs[errs.len() - 1], at(&g[1], h, 0.0, false));
    }
    println!("error ratios as h halves: {:.2}, {:.2} (order 2)", errs[0] / errs[1], errs[1] / errs[2]);
    let g = grid(0.0025, &[15.0, 60.0, 240.0], 0.0);
    let trio = [at(&g[0], 0.0025, 0.025, false), at(&g[1], 0.0025, 0.05, false), at(&g[2], 0.0025, 0.10, false)];
    println!("collapse on the grid: T(2.5 cm, 15 s) = {:.4}, T(5 cm, 60 s) = {:.4}, T(10 cm, 240 s) = {:.4} C", trio[0], trio[1], trio[2]);
    let img = (TJ - TC) * erfc((2.0 * L - 0.10) / (2.0 * (K * 240.0).sqrt()));
    println!("first omitted image term (insulated far end) at 10 cm, 240 s: {} C", pye(img, 1));
    let q = 1e5;
    let fl = grid(0.0025, &[60.0, 240.0], q);
    let (f60, f240) = (fl[0][0], fl[1][0]);
    let ex = |t: f64| 2.0 * q * (K * t / PI).sqrt() / 401.0;
    println!("flux start, 100 kW/m^2 into a 20 C rod, k = 401 W/(m K): end rises {:.2} C by 60 s, {:.2} C by 240 s; ratio {:.3}",
        f60 - TC, f240 - TC, (f240 - TC) / (f60 - TC));
    println!("  exact end rise 2 q sqrt(kappa t / pi) / k: {:.2} and {:.2} C", ex(60.0), ex(240.0));
    let (es, ec) = (14.9 / 3.95e-6f64.sqrt(), 401.0 / K.sqrt());
    println!("copper at 100 C on stainless steel at 20 C: effusivities {:.0} and {:.0}; joint {:.1} C", ec, es, (ec * TH + es * TC) / (ec + es));
    let far = grid(0.01, &[3600.0], 0.0).remove(0);
    let pair = |m: f64, x: f64, t: f64| (TJ - TC) * (erfc(eta(2.0 * m * L - x, t)) - erfc(eta(2.0 * m * L + x, t))); // images at +-2mL
    let fix = temp(1.0, 3600.0) + pair(1.0, 1.0, 3600.0) - pair(2.0, 1.0, 3600.0);
    let gf = at(&far, 0.01, 1.0, false);
    println!("breaks, finite rods at 3600 s, far end of cold rod: half-line formula {:.1} C, with four images {:.2} C, grid {:.2} C; first omitted image pair {} C",
        temp(1.0, 3600.0), fix, gf, pye(pair(3.0, 1.0, 3600.0), 1));
    println!("mistake, eta without the 2: T(5 cm, 60 s) = {:.2} C, not {:.2}", TJ - (TJ - TC) * erf(2.0 * e5), temp(0.05, 60.0));
    println!("mistake, twice the distance in twice the time: T(10 cm, 120 s) = {:.2} C, not {:.2}", temp(0.10, 120.0), temp(0.05, 60.0));
    println!("mistake, erf where erfc belongs, 20 + 40 erf(eta): {:.2} C", TC + (TJ - TC) * erf(e5));
    for t in [15.0f64, 60.0, 240.0] {
        let row: Vec<String> = (0..11).map(|i| format!("{:.1}", temp(0.05 * i as f64, t))).collect();
        println!("chart, t = {} s: {}", t as i64, row.join(", "));
    }
    println!("try, hot rod at 200 C: joint 110 C, T(5 cm, 60 s) = {:.2} C", 110.0 - 90.0 * erf(e5));
    println!("try, both rods stainless steel: {:.2} C at 5 cm after {:.0} s = {:.1} min", temp(0.05, 60.0), 60.0 * K / 3.95e-6, K / 3.95e-6);
    assert!((s + 80.0 / PI.sqrt()).abs() < 1e-6 && gap < 1e-6); // ODE shooting meets the erf formula
    assert!(res[1].abs() < 1e-5 && res[0].abs() > 3.5 * res[1].abs()); // formula obeys the PDE, gap shrinks as h^2
    assert!(errs[2] < 5e-3 && errs[1] / errs[2] > 3.5 && errs[1] / errs[2] < 4.5); // grid meets the formula at order 2
    let spread = trio.iter().cloned().fold(f64::MIN, f64::max) - trio.iter().cloned().fold(f64::MAX, f64::min);
    assert!(spread < 1e-2 && (trio[1] - temp(0.05, 60.0)).abs() < 1e-2); // grid collapses onto eta
    assert!(((f240 - TC) / (f60 - TC) - 2.0).abs() < 5e-3); // flux start: rise grows as sqrt(t)
    assert!((f60 - TC - ex(60.0)).abs() < 1e-2); // flux start meets the exact end rise
    assert!((fix - gf).abs() < 0.01 && gf - temp(1.0, 3600.0) > 5.0); // images fix the finite rod
    println!("ALL CHECKS PASS");
}
