// Electricity and the spark spread -- the same check as the Python, in Rust.
// No crates: the normal CDF, the integrator and the random numbers are all
// written here.  One gas plant's July: power forward 50 USD/MWh, gas 3.00
// USD/MMBtu, heat rate 7.5 MMBtu/MWh, variable cost 5 USD/MWh, six months out.
use std::f64::consts::PI;

const R: f64 = 0.05; const HR: f64 = 7.5; const VOM: f64 = 5.0; const MW: f64 = 400.0;
const SP: f64 = 0.50; const SG: f64 = 0.40; const RHO: f64 = 0.70;
const KAP: f64 = 0.5; const SDD: f64 = 0.08; const PJ: f64 = 0.04;

fn n(x: f64) -> f64 {                       // normal CDF, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 } }
    let (mut s, mut t, mut b, q, mut i) = (x, 0.0, x, x * x, 1.0);
    while s != t { t = s; i += 2.0; b *= q / i; s = t + b; }
    0.5 + s * (-0.5 * q - 0.91893853320467274).exp()
}
fn black(f: f64, k: f64, vol: f64, t: f64) -> f64 {   // undiscounted call on a forward
    let sd = vol * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * sd * sd) / sd;
    f * n(d1) - k * n(d1 - sd)
}
fn kirk(p: f64, f2: f64, k: f64, sp: f64, sg: f64, rho: f64, t: f64) -> f64 {  // road 1
    let b = f2 / (f2 + k);
    let v = (sp * sp - 2.0 * rho * sp * sg * b + sg * sg * b * b).sqrt();
    (-R * t).exp() * black(p, f2 + k, v, t)
}
fn exact(p: f64, f2: f64, k: f64, sp: f64, sg: f64, rho: f64, t: f64) -> f64 { // road 2
    let (nn, rt) = (600, t.sqrt());
    let (h, mut tot) = (18.0 / nn as f64, 0.0);
    for i in 0..=nn {                       // fix gas, Black on power, Simpson across gas
        let z = -9.0 + i as f64 * h;
        let fuel = f2 * (-0.5 * sg * sg * t + sg * rt * z).exp();
        let pw = p * (-0.5 * rho * rho * sp * sp * t + rho * sp * rt * z).exp();
        let w = if i == 0 || i == nn { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * (-0.5 * z * z).exp() * black(pw, fuel + k, sp * (1.0 - rho * rho).sqrt(), t);
    }
    (-R * t).exp() * tot * h / 3.0 / (2.0 * PI).sqrt()
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {          // xorshift64: own random numbers
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {            // Box-Muller, one normal per call
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn mc(g: &mut Rng, p: f64, f2: f64, k: f64, t: f64, pairs: usize) -> (f64, f64) { // road 3
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..pairs {
        let (a, c) = (g.gauss(), g.gauss());
        let zg = RHO * a + (1.0 - RHO * RHO).sqrt() * c;
        let mut pay = 0.0;
        for s in [1.0, -1.0] {              // antithetic pair: z and -z
            let pw = p * (-0.5 * SP * SP * t + SP * t.sqrt() * s * a).exp();
            let fuel = f2 * (-0.5 * SG * SG * t + SG * t.sqrt() * s * zg).exp();
            pay += 0.5 * f64::max(pw - fuel - k, 0.0);
        }
        tot += pay; tot2 += pay * pay;
    }
    let m = tot / pairs as f64;
    ((-R * t).exp() * m, (-R * t).exp() * ((tot2 / pairs as f64 - m * m) / pairs as f64).sqrt())
}
fn row(label: &str, v: f64, d: usize) { println!("{:<40}{:>14.*}", label, d, v); }
fn july(k: f64, f2: f64, sp: f64, rho: f64, p: f64) -> f64 { kirk(p, f2, k, sp, SG, rho, 0.5) }
fn mean_mult(t: i32, pj: f64) -> f64 {      // E[e^x_t], exactly, day by day
    let mut m = 1.0;
    for s in 0..t {
        let c = (1.0 - KAP).powi(t - 1 - s);
        m *= (0.5 * c * c * SDD * SDD).exp() * (1.0 - pj + pj * (c * 5f64.ln()).exp());
    }
    m
}
fn month(g: &mut Rng, level: f64) -> Vec<f64> {
    let (mut x, mut path) = (0.0, Vec::new());
    for _ in 0..31 {
        x = (1.0 - KAP) * x + SDD * g.gauss() + if g.uniform() < PJ { 5f64.ln() } else { 0.0 };
        path.push(level * f64::exp(x));
    }
    path
}
fn main() {
    let mut g = Rng(88172645463325252);
    // 1. no carry: July power priced off today's spot by storage arithmetic
    println!("carry: spot today 30.00, spot x e^(rT) at T = 0.5 {:.4}", 30.0 * (R * 0.5).exp());
    // 2. the July shape: 31 days from Thursday 1 July 2027, peak = weekdays HE7-HE22
    let wd = (2027 + 2027 / 4 - 2027 / 100 + 2027 / 400 + 5 + 1 + 6) % 7;   // Sakamoto's rule, Mon = 0
    let is_peak = |d: i32, hr: i32| (wd + d) % 7 < 5 && (6..=21).contains(&hr);
    let peak_h = (0..31).flat_map(|d| (0..24).map(move |hr| (d, hr))).filter(|&(d, hr)| is_peak(d, hr)).count() as f64;
    let off_px = (50.0 * 744.0 - 60.0 * peak_h) / (744.0 - peak_h);
    println!("shape: 1 July 2027 weekday {} (Mon = 0), peak hours {}, off-peak hours {}", wd, peak_h, 744.0 - peak_h);
    row("shape: off-peak price", off_px, 4);
    // 3. spikes as jumps: daily log price reverts half-way each day, 4% chance of x5
    let level = 50.0 / ((1..32).map(|t| mean_mult(t, PJ)).sum::<f64>() / 31.0);
    let calm = level * (1..32).map(|t| mean_mult(t, 0.0)).sum::<f64>() / 31.0;
    let sims: Vec<f64> = (0..20000).map(|_| month(&mut g, level).iter().sum::<f64>() / 31.0).collect();
    let sm = sims.iter().sum::<f64>() / sims.len() as f64;
    let sse = sims.iter().map(|v| (v - sm) * (v - sm)).sum::<f64>().sqrt() / sims.len() as f64;
    row("spikes: calm-day level", level, 4); row("spikes: forward with no spikes", calm, 4);
    row("spikes: premium in the forward", 50.0 - calm, 4);
    row("spikes: forward, simulated", sm, 4); row("spikes: simulation standard error", sse, 4);
    let path: Vec<String> = month(&mut g, level).iter().map(|v| format!("{:.2}", v)).collect();
    println!("chart, one July of daily prices {}", path.join(" "));
    // 4. July, six months out, three roads
    let (kj, ej) = (july(VOM, 22.5, SP, RHO, 50.0), exact(50.0, 22.5, VOM, SP, SG, RHO, 0.5));
    let (mj, mse) = mc(&mut g, 50.0, 22.5, VOM, 0.5, 100000);
    row("July spark spread, P - HR x G", 50.0 - HR * 3.0, 2);
    row("July 1 Kirk", kj, 4); row("July 2 exact integral", ej, 4); row("July 3 simulation", mj, 4);
    row("July   simulation standard error", mse, 4);
    row("July intrinsic e^(-rT)(27.50 - 5)", (-0.5 * R).exp() * 22.5, 4);
    row("July time value, Kirk - intrinsic", kj - (-0.5 * R).exp() * 22.5, 4);
    let b = 22.5 / 27.5; let v = (SP * SP - 2.0 * RHO * SP * SG * b + SG * SG * b * b).sqrt();
    let (sd, ln) = (v * 0.5f64.sqrt(), (50.0f64 / 27.5).ln()); let d1 = (ln + 0.25 * v * v) / sd;
    let hand = (-0.5 * R).exp() * (50.0 * n(d1) - 27.5 * n(d1 - sd));
    println!("Kirk by hand: b {:.4} vol {:.4} vol*sqrtT {:.4} ln {:.4} d1 {:.4} d2 {:.4} N {:.5} {:.5} disc {:.5}",
             b, v, sd, ln, d1, d1 - sd, n(d1), n(d1 - sd), (-0.5 * R).exp());
    println!("July zero cost: Kirk {:.4}, exact {:.4}", july(0.0, 22.5, SP, RHO, 50.0), exact(50.0, 22.5, 0.0, SP, SG, RHO, 0.5));
    let (pk, pe) = (july(VOM, 45.0, SP, RHO, 50.0), exact(50.0, 45.0, VOM, SP, SG, RHO, 0.5));
    println!("peaker, heat rate 15, spread 5.00 = cost: Kirk {:.4}, exact {:.4}", pk, pe);
    let house = |k: f64| {                  // the spread-option card's crack spread
        let b = 90.0 / (90.0 + k); let v = (0.09 - 2.0 * 0.5 * 0.3 * 0.25 * b + 0.0625 * b * b).sqrt();
        (-R * 0.5).exp() * black(100.0, 90.0 + k, v, 0.5)
    };
    row("house: Margrabe crack, strike 0", house(0.0), 4); row("house: Kirk crack, strike 10", house(10.0), 4);
    // 5. blocks: peak and off-peak priced apart, then hour-weighted
    let (kp, ko) = (july(VOM, 22.5, SP, RHO, 60.0), july(VOM, 22.5, SP, RHO, off_px));
    row("blocks: peak option", kp, 4); row("blocks: off-peak option", ko, 4);
    row("blocks: hour-weighted", (peak_h * kp + (744.0 - peak_h) * ko) / 744.0, 4);
    // 6. Greeks of the July option by bumping, both roads
    let roads: [(&str, fn(f64, f64, f64, f64, f64, f64, f64) -> f64); 2] = [("Kirk", kirk), ("exact", exact)];
    for (lab, f) in roads {
        let dp = (f(50.01, 22.5, VOM, SP, SG, RHO, 0.5) - f(49.99, 22.5, VOM, SP, SG, RHO, 0.5)) / 0.02;
        let dg = (f(50.0, 22.5075, VOM, SP, SG, RHO, 0.5) - f(50.0, 22.4925, VOM, SP, SG, RHO, 0.5)) / 0.002;
        let dr = f(50.0, 22.5, VOM, SP, SG, 0.8, 0.5) - f(50.0, 22.5, VOM, SP, SG, 0.6, 0.5);
        println!("greeks {:<6} power {:.4}  gas {:.4}  corr 0.6->0.8 {:.4}", lab, dp, dg, dr);
    }
    // 7. the plant: a strip of monthly options, Feb 2027 to Jan 2028
    let strip = [("Feb", 52.0, 4.10, 672.0), ("Mar", 45.0, 3.60, 744.0), ("Apr", 40.0, 3.10, 720.0),
                 ("May", 41.0, 2.90, 744.0), ("Jun", 46.0, 2.90, 720.0), ("Jul", 50.0, 3.00, 744.0),
                 ("Aug", 52.0, 3.05, 744.0), ("Sep", 43.0, 2.95, 720.0), ("Oct", 40.0, 3.00, 744.0),
                 ("Nov", 44.0, 3.40, 720.0), ("Dec", 55.0, 4.00, 744.0), ("Jan", 60.0, 4.40, 744.0)];
    let (mut tk, mut te) = (0.0, 0.0);
    for (k, &(mon, p, gas, hrs)) in strip.iter().enumerate() {
        let t = (k + 1) as f64 / 12.0;
        let (a, b) = (kirk(p, HR * gas, VOM, SP, SG, RHO, t), exact(p, HR * gas, VOM, SP, SG, RHO, t));
        tk += a * hrs * MW / 1e6; te += b * hrs * MW / 1e6;
        println!("strip {} T={:>2}/12 P {:5.2} G {:4.2} spread {:6.2}  Kirk {:7.4} exact {:7.4}  USD m {:6.3}",
                 mon, k + 1, p, gas, p - HR * gas, a, b, a * hrs * MW / 1e6);
    }
    row("plant, 400 MW, one year, USD m, Kirk", tk, 4); row("plant, 400 MW, one year, USD m, exact", te, 4);
    // 8. what breaks, and try-changing
    row("wrong: July off carry forward", july(VOM, 22.5, SP, RHO, 30.0 * (R * 0.5).exp()), 4);
    row("wrong: correlation set to 0", july(VOM, 22.5, SP, 0.0, 50.0), 4);
    row("try: gas 4.00, fuel 30", july(VOM, 30.0, SP, RHO, 50.0), 4); row("try: power vol 0.80", july(VOM, 22.5, 0.80, RHO, 50.0), 4);
    row("try: peaker, correlation 0.9", july(VOM, 45.0, SP, 0.9, 50.0), 4);
    let grid: Vec<f64> = (0..13).map(|i| 20.0 + 5.0 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> String| grid.iter().map(|&p| f(p)).collect::<Vec<_>>().join(" ");
    println!("chart, power at expiry  {}", line(&|p| format!("{:6.0}", p)));
    println!("chart, payoff at expiry {}", line(&|p| format!("{:6.2}", f64::max(p - 27.5, 0.0))));
    println!("chart, value 6 m out    {}", line(&|p| format!("{:6.2}", july(VOM, 22.5, SP, RHO, p))));
    assert!((kj - ej).abs() < 0.001 && (pk - pe).abs() < 0.01 && (hand - kj).abs() < 1e-9, "Kirk by hand = code = integral");
    assert!((mj - ej).abs() < 4.0 * mse, "simulation within four standard errors of the integral");
    assert!((house(0.0) - 13.15).abs() < 0.005 && (house(10.0) - 7.43).abs() < 0.005, "sibling card's numbers");
    assert!((sm - 50.0).abs() < 4.0 * sse, "simulated spiky month averages to the exact forward");
    assert!(wd == 3 && peak_h == 22.0 * 16.0, "1 July 2027 is a Thursday; 22 weekdays of 16 peak hours");
    println!("ALL CHECKS PASS");
}
