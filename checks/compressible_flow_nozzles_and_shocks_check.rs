// Compressible flow -- the check behind the card.  std only.  A Mach 2 wind-tunnel nozzle,
// 20 C chamber air, 100 mm x 100 mm test section, room at 101.325 kPa.  Roads: closed forms; Simpson on
// dA/A; a search for the biggest mass flux; the shock from raw conservation laws; the entropy rise.
use std::f64::consts::PI;

const G: f64 = 1.4; const T0: f64 = 293.15; const P0: f64 = 300e3; const PB: f64 = 101325.0; // gamma; K; Pa; Pa
const W: f64 = 0.100; const HE: f64 = 0.100; const HIN: f64 = 0.180; // span, exit and inlet heights, m

fn r_air() -> f64 { 8314.32 / 28.9644 } // J/(kg K): US Standard Atmosphere 1976, R* / M0
fn cp() -> f64 { G * r_air() / (G - 1.0) }
fn ht() -> f64 { 0.100 / 1.6875 } // throat height, m

fn out(label: &str, v: f64, d: usize, unit: &str) {
    println!("{:<44}{:>11.*} {}", label, d, v, unit);
}

fn tt(m: f64, g: f64) -> f64 { 1.0 + (g - 1.0) / 2.0 * m * m } // T0/T
fn pr(m: f64, g: f64) -> f64 { tt(m, g).powf(-g / (g - 1.0)) } // p/p0
fn area(m: f64, g: f64) -> f64 { (2.0 / (g + 1.0) * tt(m, g)).powf((g + 1.0) / (2.0 * (g - 1.0))) / m }

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let mut flo = f(lo);
    for _ in 0..200 {
        let (mid, fm) = ((lo + hi) / 2.0, f((lo + hi) / 2.0));
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn mach(ar: f64, sup: bool, g: f64) -> f64 { let (lo, hi) = if sup { (1.0, 50.0) } else { (1e-9, 1.0) }; bisect(|m| area(m, g) - ar, lo, hi) }

// closed forms: M2, p2/p1, rho2/rho1, T2/T1, p02/p01
fn shock(m: f64, g: f64) -> (f64, f64, f64, f64, f64) {
    let m2 = (tt(m, g) / (g * m * m - (g - 1.0) / 2.0)).sqrt();
    let pp = 1.0 + 2.0 * g / (g + 1.0) * (m * m - 1.0);
    let rr = (g + 1.0) * m * m / ((g - 1.0) * m * m + 2.0);
    (m2, pp, rr, pp / rr, pp * (tt(m2, g) / tt(m, g)).powf(g / (g - 1.0)))
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * s
}

fn height(x: f64) -> f64 { // nozzle wall, x in m: converge 0-80 mm, diverge 80-280 mm
    if x <= 0.08 { return ht() + (HIN - ht()) * (1.0 + (PI * x / 0.08).cos()) / 2.0; }
    ht() + (HE - ht()) * (1.0 - (PI * (x.min(0.28) - 0.08) / 0.2).cos()) / 2.0
}

fn shock_place(p0: f64) -> (f64, f64) { // area ratio and x where the shock stands
    let exit_gap = |a: f64| { let r = shock(mach(a, true, G), G).4; r * p0 * pr(mach(1.6875 * r, false, G), G) - PB };
    let a = bisect(exit_gap, 1.0 + 1e-9, 1.6875);
    (a, bisect(|x| height(x) / ht() - a, 0.08, 0.28))
}

fn main() {
    let (r, cpa, hta) = (r_air(), cp(), ht());
    // ---- the nozzle at its design Mach 2 ----
    let ar = area(2.0, G);
    let ar_int = simpson(|m| (m * m - 1.0) / (m * tt(m, G)), 1.0, 2.0, 2000).exp(); // road 2
    assert!((ar - 0.5 * 1.5f64.powi(3)).abs() < 1e-12 && (ar_int - ar).abs() < 1e-9);
    let (t1, p1) = (T0 / tt(2.0, G), P0 * pr(2.0, G));
    let a1 = (G * r * t1).sqrt(); let u1 = 2.0 * a1;
    let astar = (G * r * T0 / tt(1.0, G)).sqrt();
    for (lab, v, d, u) in [("gas constant of air", r, 2, "J/(kg K)"), ("area ratio A/A* at Mach 2", ar, 4, ""),
        ("area ratio, Simpson on (M^2-1)/(M(1+0.2M^2))", ar_int, 4, ""),
        ("throat area, 100 mm span", hta * W * 1e4, 2, "cm^2"),
        ("T0/T at Mach 2", tt(2.0, G), 4, ""), ("p0/p at Mach 2", 1.0 / pr(2.0, G), 4, ""),
        ("test section: static temperature", t1, 2, "K"), ("test section: static temperature", t1 - 273.15, 2, "C"),
        ("test section: static pressure", p1 / 1e3, 2, "kPa"), ("test section: speed of sound", a1, 1, "m/s"),
        ("test section: air speed", u1, 1, "m/s"), ("throat: air speed = sound speed", astar, 1, "m/s")] {
        out(lab, v, d, u);
    }

    // ---- choking: the formula against a golden-section search over throat pressure ----
    let mdot = hta * W * P0 * (G / (r * T0)).sqrt() * (2.0 / (G + 1.0)).powf((G + 1.0) / (2.0 * (G - 1.0)));
    let flux = |p: f64| { let t = T0 * (p / P0).powf((G - 1.0) / G); p / (r * t) * (2.0 * cpa * (T0 - t)).sqrt() };
    let (mut lo, mut hi) = (0.01 * P0, 0.99 * P0); // golden-section search for the biggest flux
    for _ in 0..200 {
        let (c, d) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if flux(c) > flux(d) { hi = d; } else { lo = c; }
    }
    let pst = (lo + hi) / 2.0; let tst = T0 * (pst / P0).powf((G - 1.0) / G);
    assert!((flux(pst) * hta * W - mdot).abs() < 1e-6 * mdot && (pst / P0 - pr(1.0, G)).abs() < 1e-6);
    assert!(((2.0 * cpa * (T0 - tst)).sqrt() / (G * r * tst).sqrt() - 1.0).abs() < 1e-5); // peak at Mach 1
    for (lab, v, d, u) in [("mass flow, choked formula", mdot, 3, "kg/s"), ("mass flow, search for biggest flux", flux(pst) * hta * W, 3, "kg/s"),
        ("pressure at the peak, p*/p0", pst / P0, 4, ""), ("Mach number at the peak", (2.0 * cpa * (T0 - tst) / (G * r * tst)).sqrt(), 4, "")] {
        out(lab, v, d, u);
    }

    // ---- the normal shock at Mach 2: closed form, raw conservation laws, entropy ----
    let (m2, pp, rr, tr, keep) = shock(2.0, G);
    let (j, h) = (p1 / (r * t1) * u1, cpa * t1 + u1 * u1 / 2.0); // mass flux, total enthalpy
    let energy_gap = |u: f64| { let p2 = p1 + j * (u1 - u); G / (G - 1.0) * p2 * u / j + u * u / 2.0 - h };
    let u2 = bisect(energy_gap, 1e-6, 0.999 * u1);
    let p2 = p1 + j * (u1 - u2); let t2 = p2 * u2 / (j * r); let m2c = u2 / (G * r * t2).sqrt();
    let keep_c = p2 * tt(m2c, G).powf(G / (G - 1.0)) / P0;
    let ds = cpa * (t2 / t1).ln() - r * (p2 / p1).ln();
    assert!((m2c - m2).abs() < 1e-9 && (p2 / p1 - pp).abs() < 1e-9 && (keep_c - keep).abs() < 1e-9);
    assert!(((-ds / r).exp() - keep).abs() < 1e-9 && (u1 * u2 - astar * astar).abs() < 1e-6 * u1 * u2); // Prandtl
    for (lab, v, d, u) in [("shock: Mach after, formula", m2, 4, ""), ("shock: Mach after, conservation", m2c, 4, ""),
        ("shock: p2/p1", pp, 4, ""), ("shock: rho2/rho1", rr, 4, ""), ("shock: T2/T1", tr, 4, ""),
        ("shock: stagnation pressure kept, formula", 100.0 * keep, 2, "%"),
        ("shock: kept, conservation", 100.0 * keep_c, 2, "%"), ("shock: kept, exp(-ds/R)", 100.0 * (-ds / r).exp(), 2, "%"),
        ("shock: entropy rise", ds, 2, "J/(kg K)"), ("after shock: pressure", p2 / 1e3, 2, "kPa"),
        ("after shock: temperature", t2, 2, "K"), ("after shock: speed", u2, 1, "m/s"),
        ("diffuser second throat, A*/kept", hta * W * 1e4 / keep, 2, "cm^2"),
        ("lowest p0 to start, diffuser after shock", PB / keep / 1e3, 2, "kPa")] {
        out(lab, v, d, u);
    }

    // ---- start-up: the chamber pressure climbs and the shock walks down the nozzle ----
    let msub = mach(ar, false, G);
    let (p0c1, p0c2, p0d) = (PB / pr(msub, G), PB / (pr(2.0, G) * pp), PB / pr(2.0, G));
    assert!(0.0 < p0c1 && p0c1 < 120e3 && 160e3 < p0c2 && p0c2 < p0d && (msub - 0.3722).abs() < 1e-4);
    let flow = |p: f64, m: f64, h: f64| p * m * (G * tt(m, G) / (r * T0)).sqrt() * h * W; // mass flow, kg/s, from static p, Mach, height
    println!("start-up: p0 kPa, throat Mach, mass flow kg/s, shock x mm, exit Mach");
    for p0 in [105e3, p0c1, 120e3, 140e3, 160e3, p0c2, 300e3, p0d] {
        let (mt, mf, xs, me_s);
        if p0 < p0c1 + 1e-6 { // not choked: exit at room pressure, subsonic all through
            let me = (((p0 / PB).powf((G - 1.0) / G) - 1.0) / (G / 2.0 - 0.5)).sqrt();
            mt = mach(area(me, G) / ar, false, G);
            mf = PB / (r * T0 / tt(me, G)) * me * (G * r * T0 / tt(me, G)).sqrt() * HE * W;
            xs = "none".to_string(); me_s = me;
        } else {
            mt = 1.0; mf = mdot * p0 / P0;
            if p0 < p0c2 - 1e-6 {
                let (a, x) = shock_place(p0); let rk = shock(mach(a, true, G), G).4;
                xs = format!("{:.1}", x * 1e3); me_s = mach(ar * rk, false, G);
            } else { xs = (if p0 < p0c2 + 1.0 { "280.0" } else { "none" }).to_string(); me_s = 2.0; }
        }
        assert!((flow(p0 * pr(mt, G), mt, hta) / mf - 1.0).abs() < 1e-9 && (flow(if me_s < 1.0 { PB } else { p0 * pr(me_s, G) }, me_s, HE) / mf - 1.0).abs() < 1e-9);
        println!("  {:7.2} {:9.4} {:9.3} {:>8} {:9.4}", p0 / 1e3, mt, mf, xs, me_s);
    }

    // ---- chart: static pressure along the nozzle, running and with the shock standing at p0 = 140 kPa ----
    let (a140, x140) = shock_place(140e3); let r140 = shock(mach(a140, true, G), G).4;
    let p_at = |x: f64, p0: f64, xsh: f64, rk: f64| -> f64 {
        let arx = height(x) / hta;
        if x <= 0.08 { return p0 * pr(mach(arx, false, G), G); }
        if x < xsh { return p0 * pr(mach(arx, true, G), G); }
        rk * p0 * pr(mach(arx * rk, false, G), G)
    };
    assert!((p_at(0.28, 140e3, x140, r140) / PB - 1.0).abs() < 1e-9 && (height(x140) / hta - a140).abs() < 1e-9); // leaves at room pressure
    let xs: Vec<f64> = (0..15).map(|i| i as f64 * 0.02).collect();
    let row = |f: &dyn Fn(f64) -> String| xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ");
    println!("chart, x mm      {}", row(&|x| format!("{:5.0}", x * 1e3)));
    println!("chart, 300 kPa   {}", row(&|x| format!("{:5.1}", p_at(x, 300e3, 9.0, 1.0) / 1e3)));
    println!("chart, 140 kPa   {}", row(&|x| format!("{:5.1}", p_at(x, 140e3, x140, r140) / 1e3)));
    println!("figure, throat x 80 h {:.2}; exit x 280 h 100.00; inlet h 180.00; shock at 140 kPa x {:.1} h {:.2}",
        hta * 1e3, x140 * 1e3, height(x140) * 1e3);

    // ---- what breaks, honesty numbers, try changing ----
    let rho0 = P0 / (r * T0);
    for (lab, v, d, u) in [("wrong: A V constant, speed at the exit", astar / ar, 1, "m/s"),
        ("wrong: Bernoulli, fixed density, exit p", (P0 - rho0 * u1 * u1 / 2.0) / 1e3, 1, "kPa"),
        ("wrong: loss-free shock, second throat", hta * W * 1e4, 2, "cm^2"),
        ("wrong: static p in choked formula", mdot * p1 / P0, 3, "kg/s"),
        ("density drop at Mach 0.3", 100.0 * (1.0 - tt(0.3, G).powf(-1.0 / (G - 1.0))), 2, "%"),
        ("Mach 5 from 20 C: static temperature", T0 / tt(5.0, G), 2, "K"),
        ("try: Mach 3, throat area", W * HE * 1e4 / area(3.0, G), 2, "cm^2"), ("try: Mach 3, design p0", PB / pr(3.0, G) / 1e6, 3, "MPa"),
        ("try: helium, area ratio at Mach 2", area(2.0, 5.0 / 3.0), 4, ""),
        ("try: helium, stagnation pressure kept", 100.0 * shock(2.0, 5.0 / 3.0).4, 2, "%"),
        ("try: shock at Mach 1.2, kept", 100.0 * shock(1.2, G).4, 2, "%")] {
        out(lab, v, d, u);
    }
    println!("ALL CHECKS PASS");
}
