// Bond options and Jamshidian's trick -- the same check as the Python, in Rust.
// No crates; the normal CDF, root finder, integrator and PDE solver are written
// here.  Hull-White fitted to the shelf's curve (Vasicek: reversion a = 0.3 to
// b = 5%, volatility 1%, short rate today 4%).  Money per 100 face.
const A: f64 = 0.3; const BL: f64 = 0.05; const SIG: f64 = 0.01; const R0: f64 = 0.04;
const T: f64 = 1.0; const S: f64 = 5.0; const K: f64 = 83.0; const X: f64 = 101.0;
const FLOWS: [(f64, f64); 4] = [(2.0, 5.0), (3.0, 5.0), (4.0, 5.0), (5.0, 105.0)];
const PI: f64 = std::f64::consts::PI;

fn n(x: f64) -> f64 {                           // bell-curve area left of x, by its series
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() + 1e-300 { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * total
}
fn bf(tau: f64) -> f64 { (1.0 - (-A * tau).exp()) / A }
fn vas(tau: f64, r: f64) -> f64 {               // Vasicek bond price, tau years left, short rate r
    let bt = bf(tau);
    let ln_a = (BL - SIG * SIG / (2.0 * A * A)) * (bt - tau) - SIG * SIG * bt * bt / (4.0 * A);
    (ln_a - bt * r).exp()
}
fn p0(t: f64, shift: f64) -> f64 { vas(t, R0) * (-shift * t).exp() }        // today's curve
fn fwd(t: f64, shift: f64) -> f64 { let h = 1e-4; -((p0(t + h, shift)).ln() - (p0(t - h, shift)).ln()) / (2.0 * h) }
fn hw_bond(t: f64, u: f64, r: f64, shift: f64, s: f64) -> f64 {   // Hull-White bond price at t
    let bu = bf(u - t);
    p0(u, shift) / p0(t, shift) * (bu * fwd(t, shift) - s * s / (4.0 * A) * (1.0 - (-2.0 * A * t).exp()) * bu * bu - bu * r).exp()
}
fn sigma_p(t: f64, u: f64, s: f64) -> f64 { s * bf(u - t) * ((1.0 - (-2.0 * A * t).exp()) / (2.0 * A)).sqrt() }
fn zbc(t: f64, u: f64, k: f64, shift: f64, s: f64) -> f64 {       // ROAD 1: the closed form
    let (pt, pu, sp) = (p0(t, shift), p0(u, shift), sigma_p(t, u, s));
    let h = (pu / (pt * k)).ln() / sp + sp / 2.0;
    pu * n(h) - k * pt * n(h - sp)
}
fn zbp(t: f64, u: f64, k: f64) -> f64 {
    let (pt, pu, sp) = (p0(t, 0.0), p0(u, 0.0), sigma_p(t, u, SIG));
    let h = (pu / (pt * k)).ln() / sp + sp / 2.0;
    k * pt * n(sp - h) - pu * n(-h)
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn jamshidian(shift: f64, s: f64) -> (f64, Vec<f64>, f64) {      // coupon call as zero calls
    let g = |r: f64| FLOWS.iter().map(|&(u, c)| c * hw_bond(T, u, r, shift, s)).sum::<f64>() - X;
    let rstar = bisect(&g, -0.5, 0.5);
    let ks: Vec<f64> = FLOWS.iter().map(|&(u, _)| hw_bond(T, u, rstar, shift, s)).collect();
    let v = FLOWS.iter().zip(&ks).map(|(&(u, c), &k)| c * zbc(T, u, k, shift, s)).sum();
    (rstar, ks, v)
}
struct Mom { m_r: f64, v_r: f64, m_i: f64, v_i: f64, cov: f64 }
fn by_integral(mo: &Mom, payoff: &dyn Fn(f64) -> f64) -> f64 {    // ROAD 2
    let nn = 20000;
    let (lo, hi) = (mo.m_r - 10.0 * mo.v_r.sqrt(), mo.m_r + 10.0 * mo.v_r.sqrt());
    let h = (hi - lo) / nn as f64;
    let mut tot = 0.0;
    for i in 0..=nn {
        let x = lo + i as f64 * h;
        let dens = (-(x - mo.m_r).powi(2) / (2.0 * mo.v_r)).exp() / (2.0 * PI * mo.v_r).sqrt();
        let disc = (-(mo.m_i + mo.cov / mo.v_r * (x - mo.m_r)) + 0.5 * (mo.v_i - mo.cov * mo.cov / mo.v_r)).exp();
        let w = if i == 0 || i == nn { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * dens * disc * payoff(x);
    }
    tot * h / 3.0
}
fn by_pde(payoff: &dyn Fn(f64) -> f64) -> f64 {                  // ROAD 3: Crank-Nicolson
    let (m, steps, h) = (400usize, 200, 0.0005);
    let dt = T / steps as f64;
    let rs: Vec<f64> = (0..=m).map(|i| R0 - 0.1 + i as f64 * h).collect();
    let mut v: Vec<f64> = rs.iter().map(|&r| payoff(r)).collect();
    let lo: Vec<f64> = rs.iter().map(|&r| 0.5 * SIG * SIG / (h * h) - A * (BL - r) / (2.0 * h)).collect();
    let di: Vec<f64> = rs.iter().map(|&r| -SIG * SIG / (h * h) - r).collect();
    let up: Vec<f64> = rs.iter().map(|&r| 0.5 * SIG * SIG / (h * h) + A * (BL - r) / (2.0 * h)).collect();
    for _ in 0..steps {
        let mut rhs: Vec<f64> = (1..m).map(|i| v[i] + 0.5 * dt * (lo[i] * v[i - 1] + di[i] * v[i] + up[i] * v[i + 1])).collect();
        let a_: Vec<f64> = (1..m).map(|i| -0.5 * dt * lo[i]).collect();
        let mut b_: Vec<f64> = (1..m).map(|i| 1.0 - 0.5 * dt * di[i]).collect();
        let c_: Vec<f64> = (1..m).map(|i| -0.5 * dt * up[i]).collect();
        for j in 1..m - 1 { let w = a_[j] / b_[j - 1]; b_[j] -= w * c_[j - 1]; rhs[j] -= w * rhs[j - 1]; }
        let mut x = vec![0.0; m - 1];
        x[m - 2] = rhs[m - 2] / b_[m - 2];
        for j in (0..m - 2).rev() { x[j] = (rhs[j] - c_[j] * x[j + 1]) / b_[j]; }
        let mut nv = vec![2.0 * x[0] - x[1]];
        nv.extend_from_slice(&x);
        nv.push(2.0 * x[m - 2] - x[m - 3]);
        v = nv;
    }
    v[200]
}
fn legs(ps: &[((f64, f64), f64)], r: f64) -> f64 { ps.iter().map(|&((u, c), k)| c * (vas(u - T, r) - k).max(0.0)).sum() }
fn row(name: &str, v: f64) { println!("{:<38} {:>12.6}", name, v); }
fn main() {
    let (e1, e2) = ((-A * T).exp(), (-2.0 * A * T).exp());
    let mo = Mom { m_r: BL + (R0 - BL) * e1, v_r: SIG * SIG * (1.0 - e2) / (2.0 * A), m_i: BL * T + (R0 - BL) * (1.0 - e1) / A,
        v_i: SIG * SIG / (A * A) * (T - 2.0 * (1.0 - e1) / A + (1.0 - e2) / (2.0 * A)), cov: SIG * SIG / (2.0 * A * A) * (1.0 - e1).powi(2) };
    let zpay = |r: f64| (100.0 * vas(S - T, r) - K).max(0.0);
    let cpay = |r: f64| (FLOWS.iter().map(|&(u, c)| c * vas(u - T, r)).sum::<f64>() - X).max(0.0);
    let (c1, c2, c3) = (100.0 * zbc(T, S, K / 100.0, 0.0, SIG), by_integral(&mo, &zpay), by_pde(&zpay));
    let (p1, p2) = (100.0 * zbp(T, S, K / 100.0), by_integral(&mo, &|r: f64| (K - 100.0 * vas(S - T, r)).max(0.0)));
    let (rstar, ks, j1) = jamshidian(0.0, SIG);
    let (j2, j3) = (by_integral(&mo, &cpay), by_pde(&cpay));
    let fwd_cb = FLOWS.iter().map(|&(u, c)| c * p0(u, 0.0)).sum::<f64>() / p0(T, 0.0);
    let prorata: f64 = FLOWS.iter().map(|&(u, c)| c * zbc(T, u, X / fwd_cb * p0(u, 0.0) / p0(T, 0.0), 0.0, SIG)).sum();
    let theta: Vec<f64> = [0.5, 1.0, 3.0].iter().map(|&t| (fwd(t + 1e-3, 0.0) - fwd(t - 1e-3, 0.0)) / 2e-3
        + A * fwd(t, 0.0) + SIG * SIG / (2.0 * A) * (1.0 - (-2.0 * A * t).exp())).collect();
    let black = |sp: f64, f: f64, k: f64| { let h = (f / k).ln() / sp + sp / 2.0; 100.0 * p0(T, 0.0) * (f * n(h) - k * n(h - sp)) };
    let (fz, kz) = (p0(S, 0.0) / p0(T, 0.0), K / 100.0);
    let path_disc = (-mo.m_i + 0.5 * mo.v_i).exp();
    row("P(0,1)  curve today", p0(T, 0.0)); row("P(0,5)", p0(S, 0.0)); row("  E[exp(-integral of r)] to year 1", path_disc);
    row("theta(0.5) read off the curve", theta[0]); row("theta(3)", theta[2]);
    row("forward price of the zero at year 1", 100.0 * fz); row("B(1,5)", bf(S - T));
    row("P(1,5) at r = 5%, Hull-White fitted", hw_bond(T, S, 0.05, 0.0, SIG)); row("P(1,5) at r = 5%, Vasicek direct", vas(S - T, 0.05)); let (sp, hh) = (sigma_p(T, S, SIG), (fz / kz).ln() / sigma_p(T, S, SIG) + sigma_p(T, S, SIG) / 2.0);
    row("damping sqrt((1-e^-2aT)/2a)", ((1.0 - e2) / (2.0 * A)).sqrt()); row("sigma_P", sp);
    row("ln(forward / strike)", (fz / kz).ln()); row("h", hh); row("N(h)", n(hh)); row("N(h - sigma_P)", n(hh - sp));
    row("bond leg   100 P(0,5) N(h)", 100.0 * p0(S, 0.0) * n(hh)); row("strike leg K P(0,1) N(h - sigma_P)", K * p0(T, 0.0) * n(hh - sp));
    row("zero call 1 formula", c1); row("zero call 2 integral", c2); row("zero call 3 PDE", c3);
    row("zero put formula", p1); row("zero put integral", p2); row("  C - P", c1 - p1);
    row("  P(0,5)*100 - K P(0,1)", 100.0 * p0(S, 0.0) - K * p0(T, 0.0));
    row("forward price of the coupon bond", fwd_cb); row("r* where the bond is worth 101", rstar);
    for (&(u, _), &k) in FLOWS.iter().zip(&ks) { row(&format!("  strike K_{} (per 100 face)", u as i32), 100.0 * k); }
    for (&(u, c), &k) in FLOWS.iter().zip(&ks) { row(&format!("  leg {}: {} x call on $1 due yr {}", u as i32, c, u as i32), c * zbc(T, u, k, 0.0, SIG)); }
    row("  sum c_i K_i", FLOWS.iter().zip(&ks).map(|(&(_, c), &k)| c * k).sum());
    row("coupon call 1 Jamshidian", j1); row("coupon call 2 integral", j2); row("coupon call 3 PDE", j3);
    row("wrong: sigma*sqrt(T) as bond vol", black(SIG * T.sqrt(), fz, kz));
    row("wrong: B(0,5) not B(1,5)", black(SIG * bf(S) * ((1.0 - e2) / (2.0 * A)).sqrt(), fz, kz));
    row("wrong: sqrt(T), no damping", black(SIG * bf(S - T) * T.sqrt(), fz, kz));
    row("wrong: coupon bond at the zero's vol", black(sigma_p(T, S, SIG), fwd_cb / 100.0, X / 100.0));
    row("wrong: pro-rata strikes, coupon", prorata);
    row("greek: zero call, +1bp curve", 100.0 * (zbc(T, S, kz, 1e-4, SIG) - zbc(T, S, kz, 0.0, SIG)));
    row("greek: coupon call, +1bp curve", jamshidian(1e-4, SIG).2 - j1);
    row("greek: zero call, sigma +0.1pt", 100.0 * (zbc(T, S, kz, 0.0, SIG + 0.001) - zbc(T, S, kz, 0.0, SIG)));
    row("greek: coupon call, sigma +0.1pt", jamshidian(0.0, SIG + 0.001).2 - j1);
    let rgrid: Vec<f64> = (0..9).map(|i| 0.02 + 0.005 * i as f64).collect();
    let pairs: Vec<((f64, f64), f64)> = FLOWS.iter().cloned().zip(ks.iter().cloned()).collect();
    let line = |label: &str, vals: Vec<String>| println!("{}{}", label, vals.join(" "));
    line("chart, r at expiry %  ", rgrid.iter().map(|r| format!("{:6.1}", 100.0 * r)).collect());
    line("chart, coupon payoff  ", rgrid.iter().map(|&r| format!("{:6.2}", cpay(r))).collect());
    line("chart, Jamshidian sum ", rgrid.iter().map(|&r| format!("{:6.2}", legs(&pairs, r))).collect());
    line("chart, final-year leg ", rgrid.iter().map(|&r| format!("{:6.2}", legs(&pairs[3..], r))).collect());
    line("chart, 3 coupon legs  ", rgrid.iter().map(|&r| format!("{:6.2}", legs(&pairs[..3], r))).collect());
    line("chart, expiry (years) ", (0..11).map(|i| format!("{:6.1}", 0.5 * i as f64)).collect());
    line("chart, sigma_P %      ", (0..11).map(|i| format!("{:6.2}", 100.0 * sigma_p(0.5 * i as f64, S, SIG))).collect());
    assert!((path_disc - p0(T, 0.0)).abs() < 1e-12, "path discount must rebuild the curve");
    assert!(theta.iter().all(|t| (t - A * BL).abs() < 1e-6), "fitted drift must be a*b on a Vasicek curve");
    assert!((hw_bond(T, S, 0.05, 0.0, SIG) - vas(S - T, 0.05)).abs() < 1e-9, "fitted Hull-White bond vs Vasicek bond");
    assert!((c1 - c2).abs() < 1e-6, "zero call: formula vs integral");
    assert!((c1 - c3).abs() < 2e-4, "zero call: formula vs PDE");
    assert!(((c1 - p2) - (100.0 * p0(S, 0.0) - K * p0(T, 0.0))).abs() < 1e-6, "parity with the integral's put");
    assert!((j1 - j2).abs() < 1e-6, "coupon call: Jamshidian vs integral");
    assert!((j1 - j3).abs() < 2e-4, "coupon call: Jamshidian vs PDE");
    assert!(prorata > j1 + 1e-4, "a sum of options beats an option on the sum unless strikes line up");
    println!("ALL CHECKS PASS");
}
