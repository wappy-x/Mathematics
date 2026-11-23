// The September 2026 Navier-Stokes claim: which Clay version it addresses, and the
// scalings of its collapsing vortex core, on a model swirl with the same scalings.
// std only.  Units are normalised: viscosity nu = 1, blow-up at t = 1.
use std::f64::consts::PI;

const DELTA: f64 = 1.0 / 200.0; // the papers' parameter: 0 < delta < 1/200; the edge value, for illustration
const NU: f64 = 1.0;
const TAUS: [f64; 3] = [1e-2, 1e-4, 1e-6]; // tau = 1 - t, the time left before the blow-up

fn sci(x: f64, p: usize) -> String {
    // Python-style e-notation: 3.7155e+09
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn scales(tau: f64, d: f64) -> (f64, f64, f64) {
    (tau.powf(-(1.0 + d) / 2.0), tau.powf(0.5), tau.powf((1.0 - d) / 2.0))
}

fn swirl(r: f64, z: f64, tau: f64, d: f64) -> f64 {
    let (a_, a, b) = scales(tau, d);
    let s = r / a;
    a_ * s * (-s * s).exp() * (-(z / b).powi(2)).exp()
}

fn energy_numeric(tau: f64, d: f64, n: usize) -> f64 {
    // road 1: Simpson's rule over r and z
    let (_, a, b) = scales(tau, d);
    let (rr, zz) = (8.0 * a, 8.0 * b);
    let (hr, hz) = (rr / n as f64, 2.0 * zz / n as f64);
    let w: Vec<f64> = (0..=n).map(|i| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).collect();
    let mut total = 0.0;
    for i in 0..=n {
        let r = i as f64 * hr;
        let mut row = 0.0;
        for j in 0..=n {
            let u = swirl(r, -zz + j as f64 * hz, tau, d);
            row += w[j] * u * u;
        }
        total += w[i] * row * 2.0 * PI * r;
    }
    0.5 * total * hr * hz / 9.0
}

fn energy_closed(tau: f64, d: f64) -> f64 {
    0.5 * tau.powf((1.0 - 3.0 * d) / 2.0) * (PI / 4.0) * (PI / 2.0).sqrt()
}

fn peak_grid(tau: f64, d: f64, n: usize) -> f64 {
    let (_, a, _) = scales(tau, d);
    (0..=n).map(|i| swirl(8.0 * a * i as f64 / n as f64, 0.0, tau, d)).fold(f64::MIN, f64::max)
}

fn peak_closed(tau: f64, d: f64) -> f64 {
    scales(tau, d).0 * (-0.5f64).exp() / 2f64.sqrt()
}

fn residual_fd(tau: f64, d: f64) -> f64 {
    // road 1: force needed = time change - friction, by differences
    let (_, a, b) = scales(tau, d);
    let (r, ht, hr, hz) = (a / 2f64.sqrt(), tau * 1e-4, a * 1e-3, b * 1e-3);
    let u = |rr: f64, zz: f64, tt: f64| swirl(rr, zz, tt, d);
    let dt = -(u(r, 0.0, tau + ht) - u(r, 0.0, tau - ht)) / (2.0 * ht);
    let urr = (u(r + hr, 0.0, tau) - 2.0 * u(r, 0.0, tau) + u(r - hr, 0.0, tau)) / hr.powi(2);
    let ur = (u(r + hr, 0.0, tau) - u(r - hr, 0.0, tau)) / (2.0 * hr);
    let uzz = (u(r, hz, tau) - 2.0 * u(r, 0.0, tau) + u(r, -hz, tau)) / hz.powi(2);
    dt - NU * (urr + ur / r - u(r, 0.0, tau) / r.powi(2) + uzz)
}

fn residual_closed(tau: f64, d: f64) -> f64 {
    let c = (-0.5f64).exp();
    c * (1.0 + d) / (2.0 * 2f64.sqrt()) * tau.powf(-(3.0 + d) / 2.0)
        + NU * (3.0 * 2f64.sqrt() * c * tau.powf(-(3.0 + d) / 2.0) + 2f64.sqrt() * c * tau.powf(-(3.0 - d) / 2.0))
}

fn main() {
    println!("ledger,1934,Leray: a blow-up is never slower than c sqrt(nu/(T - t))");
    println!("ledger,2000,Clay names seven prize problems, 1,000,000 US dollars each");
    println!("ledger,2026-09-08,announced by an AI lab: manuscript (166 pages) and Lean files");
    println!("ledger,2026-09-28,first exposition on arXiv (Part I)");
    println!("ledger,2026-10-06,critique on arXiv: Lean uses m+5 derivatives where the paper uses m+4");
    println!("ledger,2026-11-04,second exposition on arXiv (Part II)");
    println!("ledger,2026-11-23,Clay page lists the problem as 'Active'; status: claimed");
    // Which version the claim addresses is read from Clay's statement and Part II, Theorem 1.1.
    // No program can compute it, so these rows are a typed record and nothing is asserted about them.
    let no = "not addressed: needs f = 0, claim uses a force";
    let versions = [("A", "R3", "zero", "smooth forever", no), ("B", "torus", "zero", "smooth forever", no),
                    ("C", "R3", "allowed", "breakdown", "addressed: Part II, Theorem 1.1, all of space"),
                    ("D", "torus", "allowed", "breakdown", "addressed: from C by rescaling and copying")];
    for (name, space, force, asks, why) in versions {
        println!("version {}: {:<5} force {:<7} asks {:<14} -> {}", name, space, force, asks, why);
    }

    println!("tau      energy(Simpson)   energy(by hand)   peak(grid)     peak(by hand)  Reynolds  speed*sqrt(tau)");
    let mut e = Vec::new();
    for &tau in TAUS.iter() {
        let (en, ec) = (energy_numeric(tau, DELTA, 400), energy_closed(tau, DELTA));
        let (pg, pc) = (peak_grid(tau, DELTA, 20000), peak_closed(tau, DELTA));
        assert!((en - ec).abs() < 1e-7 * ec && (pg - pc).abs() < 1e-7 * pc);
        let (re, ler) = (pc * (tau.sqrt() / 2f64.sqrt()) / NU, pc * (tau / NU).sqrt());
        e.push(en);
        println!("{}  {:.10}  {:.10}  {}  {}  {:.4}    {:.4}", sci(tau, 0), en, ec, sci(pg, 6), sci(pc, 6), re, ler);
    }
    let slope = (e[2] / e[0]).ln() / (1e-6f64 / 1e-2).ln();
    assert!((slope - (1.0 - 3.0 * DELTA) / 2.0).abs() < 1e-9);
    println!("energy exponent fitted {:.6}, by hand (1 - 3 delta)/2 = {:.6}", slope, (1.0 - 3.0 * DELTA) / 2.0);
    for &tau in TAUS.iter() {
        let (fd, fc) = (residual_fd(tau, DELTA), residual_closed(tau, DELTA));
        assert!((fd - fc).abs() < 1e-5 * fc);
        println!("swirl component of the force a naive swirl needs at tau {}: {} (by hand {})", sci(tau, 0), sci(fd, 4), sci(fc, 4));
    }
    println!("Leray floor factor tau^(-delta/2) at 1e-6: {:.4}", 1e-6f64.powf(-DELTA / 2.0));

    // what breaks
    println!("break: speed ~ tau^-0.4, ratio to Leray floor at 1e-6: {:.4} (must stay above a constant)", 1e-6f64.powf(0.1));
    println!("break: delta = 0.4, energy factor at 1e-6: {:.4} (energy grows)", 1e-6f64.powf((1.0 - 3.0 * 0.4) / 2.0));
    assert!(energy_closed(1e-6, 0.4) > energy_closed(1e-2, 0.4) && energy_closed(1e-2, 0.4) > energy_closed(1.0, 0.4));
    // try changing
    println!("try: delta = 0, Reynolds at 1e-2 and 1e-12: {:.4} {:.4}", peak_closed(1e-2, 0.0) * (1e-2f64 / 2.0).sqrt(), peak_closed(1e-12, 0.0) * (1e-12f64 / 2.0).sqrt());
    println!("try: delta = 1/3, energy at 1e-2 and 1e-12: {:.6} {:.6}", energy_closed(1e-2, 1.0 / 3.0), energy_closed(1e-12, 1.0 / 3.0));
    println!("try: tau = 1e-12, speed*sqrt(tau): {:.4}", peak_closed(1e-12, DELTA) * 1e-12f64.sqrt());
    println!("try: tau = 1e-12, swirl component of the naive force: {}", sci(residual_closed(1e-12, DELTA), 4));
    println!("ALL CHECKS PASS");
}
