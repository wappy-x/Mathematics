// Commodity implied vol and the call skew -- the same check as the Python file, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built
// by adding thin slices under the curve (Simpson's rule).  Every other tool is written out too.
use std::f64::consts::PI;
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(&phi, 0.0, x, 4000)
}
fn n_inv(p: f64) -> f64 {                                                // inverse CDF by halving
    let (mut lo, mut hi) = (-12.0, 12.0);
    for _ in 0..80 { let mid = 0.5 * (lo + hi); if n_cdf(mid) < p { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
fn d1(f: f64, k: f64, s: f64, t: f64) -> f64 { ((f / k).ln() + 0.5 * s * s * t) / (s * t.sqrt()) }
fn black_call(f: f64, k: f64, r: f64, s: f64, t: f64) -> f64 {        // Black-76 call on a futures price
    let a = d1(f, k, s, t); (-r * t).exp() * (f * n_cdf(a) - k * n_cdf(a - s * t.sqrt()))
}
fn black_put(f: f64, k: f64, r: f64, s: f64, t: f64) -> f64 {         // Black-76 put, written separately
    let a = d1(f, k, s, t); (-r * t).exp() * (k * n_cdf(s * t.sqrt() - a) - f * n_cdf(-a))
}
fn vega(f: f64, k: f64, r: f64, s: f64, t: f64) -> f64 { (-r * t).exp() * f * phi(d1(f, k, s, t)) * t.sqrt() }
fn call_by_simpson(f: f64, k: f64, r: f64, s: f64, t: f64) -> f64 { // average the payoff: no d1, no d2
    let g = |z: f64| (f * (-0.5 * s * s * t + s * t.sqrt() * z).exp() - k).max(0.0) * phi(z);
    (-r * t).exp() * simpson(&g, -10.0, 10.0, 20000)
}
fn bisect(price: &dyn Fn(f64) -> f64, quote: f64, mut lo: f64, mut hi: f64, steps: usize) -> f64 {
    for _ in 0..steps { let mid = 0.5 * (lo + hi); if price(mid) < quote { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
fn implied(quote: f64, f: f64, k: f64, r: f64, t: f64, put: bool) -> Option<f64> {
    let d = (-r * t).exp();
    let (floor, ceil) = if put { (d * (k - f).max(0.0), d * k) } else { (d * (f - k).max(0.0), d * f) };
    if !(floor < quote && quote < ceil) { return None; }                 // outside the range: no vol
    Some(if put { bisect(&|s| black_put(f, k, r, s, t), quote, 1e-6, 10.0, 60) }
         else { bisect(&|s| black_call(f, k, r, s, t), quote, 1e-6, 10.0, 60) })
}
fn newton(quote: f64, f: f64, k: f64, r: f64, t: f64) -> (f64, usize) {
    let mut s = 0.5;
    for i in 1..50 {
        let step = (black_call(f, k, r, s, t) - quote) / vega(f, k, r, s, t); s -= step;
        if step.abs() < 1e-13 { return (s, i); }
    }
    (s, 50)
}
fn main() {
    let (f, k, r, t) = (85.0_f64, 85.0_f64, 0.05_f64, 0.5_f64);         // house Brent
    let d = (-r * t).exp(); let q = 7.002679_f64;
    let iv1 = implied(q, f, k, r, t, false).unwrap();
    let (iv2, its) = newton(q, f, k, r, t);
    let iv3 = bisect(&|s| call_by_simpson(f, k, r, s, t), q, 0.1, 0.6, 40);
    let a0 = d1(f, k, 0.30, t);
    println!("house Brent: F 85, K 85, r 5%, T 0.5");
    let rows: Vec<(&str, f64)> = vec![("discount D = e^-rT", d), ("floor D(F-K)+", d * (f - k).max(0.0)), ("ceiling D F", d * f),
        ("d1 at 0.30", a0), ("N(d1)", n_cdf(a0)), ("N(d2)", n_cdf(a0 - 0.30 * t.sqrt())),
        ("call at 0.30", black_call(f, k, r, 0.30, t)), ("vega at 0.30", vega(f, k, r, 0.30, t)),
        ("1 implied vol, bisection", iv1), ("2 implied vol, Newton", iv2), ("  Newton steps from 0.5", its as f64),
        ("3 implied vol, Simpson price", iv3)];
    for (name, v) in &rows { println!("  {:<30} {:>11.6}", name, v); }
    // The smile: vol as a quadratic in call delta x = N(d1), pinned at 30% where K = F.
    let xa = n_cdf(0.5 * 0.30 * t.sqrt());
    let (u, v) = (0.15 - xa, 0.85 - xa);
    let det = u * v * v - v * u * u;
    let b = (0.04 * v * v - (-0.02) * u * u) / det;
    let c = (u * (-0.02) - v * 0.04) / det;
    let vol_at = |x: f64| 0.30 + b * (x - xa) + c * (x - xa).powi(2);
    println!("\nsmile in delta: xa {:.6}  b {:.6}  c {:.6}", xa, b, c);
    println!("  label  strike    vol%   quote (OTM side)  implied%  put-via-parity%");
    let labels = [("10p", 0.90), ("15p", 0.85), ("25p", 0.75), ("35p", 0.65), ("ATMF", xa),
                  ("35c", 0.35), ("25c", 0.25), ("15c", 0.15), ("10c", 0.10)];
    let mut smile: Vec<(&str, f64, f64, f64, f64)> = Vec::new();         // label, strike, vol, implied, via parity
    for &(lab, x) in &labels {
        let s = vol_at(x); let kx = f * (-n_inv(x) * s * t.sqrt() + 0.5 * s * s * t).exp();
        let put = x > xa + 1e-12;
        let qt = if put { black_put(f, kx, r, s, t) } else { black_call(f, kx, r, s, t) };
        let iv = implied(qt, f, kx, r, t, put).unwrap();
        let ivp = if put { implied(qt + d * (f - kx), f, kx, r, t, false) } else { implied(qt - d * (f - kx), f, kx, r, t, true) }.unwrap();
        println!("  {:<5} {:7.2}  {:6.2}  {:10.6} {}      {:7.4}   {:7.4}", lab, kx, 100.0 * s, qt, if put { "P" } else { "C" }, 100.0 * iv, 100.0 * ivp);
        smile.push((lab, kx, s, iv, ivp));
    }
    let get = |l: &str| *smile.iter().find(|e| e.0 == l).unwrap();
    let rr = get("15c").3 - get("15p").3; let fly = 0.5 * (get("15c").3 + get("15p").3) - get("ATMF").3;
    let k15 = get("15c").1;
    let (c34, c30) = (black_call(f, k15, r, 0.34, t), black_call(f, k15, r, 0.30, t));
    println!("  risk reversal 15c - 15p {:.4}   butterfly {:.4} vol points", 100.0 * rr, 100.0 * fly);
    println!("  15c at 34% {:.6}, at flat 30% {:.6}, richer by {:.6}", c34, c30, c34 - c30);
    // Samuelson: option expiring with its contract at T; spot log-vol sig, pull-back kappa.
    let kap = 1.2_f64;
    let fr = |tt: f64, kk: f64| (1.0 - (-2.0 * kk * tt).exp()) / (2.0 * kk * tt);
    let sig = 0.30 / fr(0.5, kap).sqrt();
    let samuel_simpson = |tt: f64| (simpson(&|x: f64| sig * sig * (-2.0 * kap * (tt - x)).exp(), 0.0, tt, 2000) / tt).sqrt();
    println!("\nSamuelson: kappa {}, spot vol {:.6}, half-life {:.4} y", kap, sig, 2.0_f64.ln() / kap);
    println!("  by hand: e^-1.2 {:.6}  f(0.5) {:.6}  e^-4.8 {:.6}  f(2) {:.6}  sqrt f(2) {:.6}", (-1.2_f64).exp(), fr(0.5, kap), (-4.8_f64).exp(), fr(2.0, kap), fr(2.0, kap).sqrt());
    let months = [1, 3, 6, 9, 12, 15, 18, 21, 24];
    let line = |g: &dyn Fn(f64) -> f64| months.iter().map(|&m| format!("{:6.2}", 100.0 * g(m as f64 / 12.0))).collect::<Vec<_>>().join(" ");
    println!("  month   {}", months.iter().map(|m| format!("{:6}", m)).collect::<Vec<_>>().join(" "));
    println!("  vol %   {}", line(&|tt| sig * fr(tt, kap).sqrt()));
    println!("  simpson {}", line(&|tt| samuel_simpson(tt)));
    println!("  k=0.3 % {}", line(&|tt| 0.30 / fr(0.5, 0.3).sqrt() * fr(tt, 0.3).sqrt()));
    // Road 3: simulate the mean-reverting log spot weekly for two years, price the ATM call, invert.
    let mut state: u64 = 20260927;
    let mut unif = || { state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
                        ((state >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let (paths, steps, t2) = (40000usize, 104usize, 2.0_f64);
    let dt = t2 / steps as f64; let mut ends = Vec::with_capacity(paths);
    for _ in 0..paths {
        let mut y = 0.0_f64;
        for _ in 0..steps / 2 {                                          // Box-Muller: two normals per pair
            let (u1, u2) = (unif(), unif()); let rad = (-2.0 * u1.ln()).sqrt();
            for z in [rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2).sin()] { y += -kap * y * dt + sig * dt.sqrt() * z; }
        }
        ends.push(y.exp());
    }
    let m2 = ends.iter().sum::<f64>() / paths as f64;                    // the 24-month futures: average spot, scaled to 85
    let c2 = (-r * t2).exp() * ends.iter().map(|e| (85.0 * e / m2 - 85.0).max(0.0)).sum::<f64>() / paths as f64;
    let iv_mc = implied(c2, 85.0, 85.0, r, t2, false).unwrap();
    println!("  24m by simulation: raw mean {:.6}, ATM call {:.6}, implied {:.4}%, gap {:.4} pts", m2, c2, 100.0 * iv_mc, 100.0 * (iv_mc - sig * fr(2.0, kap).sqrt()));
    println!("\nwhat breaks (house quote 7.002679 unless stated)");
    let bs_spot = |s: f64| 85.0 * n_cdf((r + 0.5 * s * s) * t / (s * t.sqrt())) - 85.0 * d * n_cdf((r - 0.5 * s * s) * t / (s * t.sqrt()));
    let wrong: Vec<(&str, f64)> = vec![("85 as spot, Black-Scholes, no yield", bisect(&bs_spot, q, 1e-6, 10.0, 60)),
        ("forgot the discount D", bisect(&|s| f * n_cdf(d1(f, k, s, t)) - k * n_cdf(d1(f, k, s, t) - s * t.sqrt()), q, 1e-6, 10.0, 60)),
        ("T = 1 year, not 6 months", implied(q, f, k, r, 1.0, false).unwrap()),
        ("quote 83.00, bare solver", bisect(&|s| black_call(f, k, r, s, t), 83.0, 1e-6, 10.0, 60))];
    for (name, v) in &wrong { println!("  {:<40} {:>10.6}", name, v); }
    let v24 = sig * fr(2.0, kap).sqrt();
    let over = black_call(f, k, r, 0.30, 2.0) - black_call(f, k, r, v24, 2.0);
    println!("  24m ATM call at 30% {:.6}, at {:.2}% {:.6}: overpays {:.6}", black_call(f, k, r, 0.30, 2.0), 100.0 * v24, black_call(f, k, r, v24, 2.0), over);
    assert!((iv1 - 0.30).abs() < 1e-6 && (iv2 - iv1).abs() < 1e-9, "7.002679 was made at 30%: both solvers recover it");
    assert!((iv3 - iv1).abs() < 1e-6, "a price built by Simpson averaging gives the same vol");
    assert!(smile.iter().all(|e| (e.3 - e.2).abs() < 1e-9 && (e.4 - e.2).abs() < 1e-9), "every quote inverts to its smile vol, both sides of parity");
    assert!((get("15c").2 - 0.34).abs() < 1e-12 && (get("15p").2 - 0.28).abs() < 1e-12 && (get("ATMF").1 - f).abs() < 1e-9, "smile pinned");
    assert!(months.iter().all(|&m| (sig * fr(m as f64 / 12.0, kap).sqrt() - samuel_simpson(m as f64 / 12.0)).abs() < 1e-7), "closed form vs integral");
    assert!((iv_mc - v24).abs() < 0.006, "simulated spot gives the 24-month vol within noise");
    assert!(implied(83.0, f, k, r, t, false).is_none() && wrong[3].1 > 9.99, "83 is above the ceiling: no vol, bare solver hits its edge");
    println!("ALL CHECKS PASS");
}
