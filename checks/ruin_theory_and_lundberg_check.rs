// Ruin and Lundberg's inequality -- the check behind the card.  Rust std only.
// Nothing imported knows the answer: the integrator, the root finder, the series
// and the random numbers are all written out below.

const LAM: f64 = 10.0; // claims a year
const B: f64 = 10_000.0; // mean claim, dollars
const THETA: f64 = 0.10; // safety loading
const U: f64 = 1_000_000.0; // starting surplus, dollars

// Road 2 for M_X(r) = E[e^{rX}]: Simpson's rule on e^{rx} times the exponential density.
fn mgf(r: f64, b: f64) -> f64 {
    let n = 20000;
    let k = 1.0 / b - r; // net decay rate of the integrand
    let top = 60.0 / k; // e^{-60} of the mass lies beyond
    let h = top / n as f64;
    let f = |x: f64| (r * x).exp() * (-x / b).exp() / b;
    let mut s = f(0.0) + f(top);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h);
    }
    s * h / 3.0
}

fn kappa(r: f64, lam: f64, b: f64, c: f64) -> f64 {
    lam * (mgf(r, b) - 1.0) - c * r // claims side minus premium side
}

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if g(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn psi_exact(u: f64, b: f64, theta: f64) -> f64 {
    (-theta * u / ((1.0 + theta) * b)).exp() / (1.0 + theta) // closed form, exponential claims
}

// Road 2 for psi: Pollaczek-Khinchine. Ruin = the record drops add past u.
// A record drop happens with chance p = 1/(1+theta); for exponential claims each
// drop is exponential with mean b, so n drops exceed u with an Erlang tail.
fn psi_series(u: f64, b: f64, theta: f64) -> f64 {
    let (p, x) = (1.0 / (1.0 + theta), u / b);
    let (mut pois, mut tail, mut pn, mut total) = ((-x).exp(), 0.0, 1.0, 0.0);
    for n in 1..=3000 {
        tail += pois; // P(n drops > u) = sum_{k<n} e^-x x^k/k!
        pois *= x / n as f64;
        pn *= p;
        total += (1.0 - p) * pn * tail;
    }
    total
}

struct Rng(u64); // xorshift64*, written out
impl Rng {
    fn next(&mut self) -> f64 {
        let mut s = self.0;
        s ^= s >> 12; s ^= s << 25; s ^= s >> 27;
        self.0 = s;
        (s.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
}

// Road 3: run surplus paths claim by claim; stop at ruin or once surplus passes cap.
fn psi_monte_carlo(u: f64, lam: f64, b: f64, c: f64, paths: u32, cap: f64) -> f64 {
    let mut g = Rng(20260928);
    let mut ruined = 0u32;
    for _ in 0..paths {
        let mut s = u;
        while s >= 0.0 && s < cap {
            let wait = -g.next().ln() / lam;
            s += c * wait + b * g.next().ln();
        }
        if s < 0.0 { ruined += 1; }
    }
    ruined as f64 / paths as f64
}

fn main() {
    let c = (1.0 + THETA) * LAM * B; // premium income, $ a year
    // ---- the adjustment coefficient, two roads ----
    let r1 = THETA / ((1.0 + THETA) * B); // closed form for exponential claims
    let r2 = bisect(|r| kappa(r, LAM, B, c), 1e-3 / B, 0.5 / B);
    let (bound, exact, series) = ((-r1 * U).exp(), psi_exact(U, B, THETA), psi_series(U, B, THETA));
    let cap_bound = 100.0_f64.ln() / r1;
    let cap_exact = (100.0 / (1.0 + THETA)).ln() / r1;
    let cap_series = bisect(|u| 0.01 - psi_series(u, B, THETA), 0.0, 2e6);

    // ---- same 10% loading, claims ten times bigger ----
    let b2 = 100_000.0;
    let c2 = (1.0 + THETA) * LAM * b2;
    let bound2 = (-THETA / ((1.0 + THETA) * b2) * U).exp();
    let (exact2, series2) = (psi_exact(U, b2, THETA), psi_series(U, b2, THETA));
    let n = 20000u32;
    let mc2 = psi_monte_carlo(U, LAM, b2, c2, n, U + 10e6);
    let se2 = (mc2 * (1.0 - mc2) / n as f64).sqrt();

    // ---- what breaks ----
    let r_diff = 2.0 * (c - LAM * B) / (LAM * 2.0 * B * B); // mean-and-variance only

    assert!((r2 / r1 - 1.0).abs() < 1e-9, "root finder disagrees with closed form");
    assert!((series / exact - 1.0).abs() < 1e-9 && (series2 / exact2 - 1.0).abs() < 1e-9, "series disagrees");
    assert!((mc2 - exact2).abs() < 4.0 * se2, "simulation disagrees with exact ruin chance");
    assert!(exact < bound && bound < 0.01 && exact2 < bound2, "Lundberg bound fails");
    assert!((cap_series / cap_exact - 1.0).abs() < 1e-9, "capital by series disagrees");

    let rows: Vec<(&str, f64)> = vec![
        ("R closed form, per $1M", r1 * 1e6), ("R bisection on Simpson MGF, per $1M", r2 * 1e6),
        ("1/R, dollars", 1.0 / r1), ("M_X(R)", mgf(r1, B)), ("R u", r1 * U),
        ("Lundberg bound e^-Ru", bound), ("exact psi, closed form", exact),
        ("exact psi, Pollaczek-Khinchine series", series), ("bound / exact", bound / exact),
        ("capital for 1%, by the bound $", cap_bound), ("capital for 1%, exact $", cap_exact),
        ("capital for 1%, series + bisection $", cap_series), ("extra capital, bound over exact $", cap_bound - cap_exact),
        ("mean $100k: R per $1M", THETA / ((1.0 + THETA) * b2) * 1e6), ("mean $100k: bound", bound2),
        ("mean $100k: exact, closed form", exact2), ("mean $100k: exact, series", series2),
        ("mean $100k: simulation, 20000 paths", mc2), ("mean $100k: simulation std error", se2),
        ("wrong: root R = 0, bound", (-0.0 * U).exp()), ("wrong: no loading, exact psi", psi_exact(U, B, 0.0)),
        ("wrong: mean-variance R, per $1M", r_diff * 1e6), ("wrong: mean-variance bound", (-r_diff * U).exp()),
        ("try: loading 20%, bound", (-0.2 / (1.2 * B) * U).exp()), ("try: surplus $500k, bound", (-r1 * 500_000.0).exp()),
        ("try: mean $50k, bound", (-THETA / ((1.0 + THETA) * 50_000.0) * U).exp()),
        ("try: 20 claims/yr, premium x2, R per $1M", 1e6 * bisect(|r| kappa(r, 20.0, B, 2.0 * c), 1e-3 / B, 0.5 / B)),
    ];
    for (name, v) in &rows {
        println!("{:<42} {:>16.9}", name, v);
    }

    println!();
    println!("chart: ruin chance in percent, surplus in $ thousands");
    println!("{:>6} {:>9} {:>9}", "u", "bound %", "exact %");
    for k in 0..11 {
        let u = 100_000.0 * k as f64;
        println!("{:>6} {:>9.2} {:>9.2}", 100 * k, 100.0 * (-r1 * u).exp(), 100.0 * psi_exact(u, B, THETA));
    }
    println!();
    println!("chart: two sides of the adjustment equation, per year; r per $1M");
    println!("{:>6} {:>9} {:>9}", "r", "claims", "premium");
    for r in (0..15).step_by(2) {
        let rr = r as f64 / 1e6;
        println!("{:>6} {:>9.2} {:>9.2}", r, LAM * (mgf(rr, B) - 1.0), c * rr);
    }
}
