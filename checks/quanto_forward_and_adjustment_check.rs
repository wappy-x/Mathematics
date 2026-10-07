// The quanto adjustment -- the same check as quanto_forward_and_adjustment_check.py.
// Standard library only, no crates.  Roads: 1 the formula; 2 a 2-D Simpson integral
// in the euro world; 3 a Monte Carlo of the pair in the euro world; 4 a Monte Carlo
// of the pair in the dollar world.  splitmix64 + Box-Muller written out below.
use std::f64::consts::PI;

const S: f64 = 100.0; const XBAR: f64 = 1.10; const X0: f64 = 1.10;
const RD: f64 = 0.05; const RF: f64 = 0.03; const Q: f64 = 0.01; const T: f64 = 1.0;
const SS: f64 = 0.20; const SX: f64 = 0.10; const RHO: f64 = 0.30;

fn quanto_fwd(rho: f64, t: f64) -> f64 { S * ((RF - Q - rho * SS * SX) * t).exp() } // road 1
fn euro_fwd(t: f64) -> f64 { S * ((RF - Q) * t).exp() }

fn euro_world_integral(rho: f64, x0: f64, n: usize) -> f64 {
    // Road 2.  Euro world: share drifts at rf - q, a dollar (Y = 1/X euros) at rf - rd.
    let (a, h) = (-8.0, 16.0 / n as f64);
    let w = |i: usize| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    let (mut num, mut den) = (0.0, 0.0);
    for i in 0..=n {
        let z1 = a + i as f64 * h;
        let st = S * ((RF - Q - 0.5 * SS * SS) * T + SS * T.sqrt() * z1).exp();
        for j in 0..=n {
            let z2 = a + j as f64 * h;
            let wx = rho * z1 + (1.0 - rho * rho).sqrt() * z2;
            let yt = (1.0 / x0) * ((RF - RD - 0.5 * SX * SX) * T - SX * T.sqrt() * wx).exp();
            let wt = w(i) * w(j) * (-0.5 * (z1 * z1 + z2 * z2)).exp();
            num += wt * st * yt;
            den += wt * yt;
        }
    }
    num / den
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                    // splitmix64, top 53 bits, never 0
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) + 1) as f64 / 9007199254740992.0
    }
}

fn main() {
    let mut rng = Rng(20260927);
    let n = 200000;
    let (mut sy, mut sy1, mut sy2, mut sxy, mut sxx) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let (mut sa, mut sa2, mut su, mut su2) = (0.0, 0.0, 0.0, 0.0);
    let mu = RF - Q - RHO * SS * SX;
    for _ in 0..n {
        let r_ = (-2.0 * rng.uniform().ln()).sqrt();
        let t_ = 2.0 * PI * rng.uniform();
        let (z1, z2) = (r_ * t_.cos(), r_ * t_.sin());
        let wx = RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2;
        // road 3: euro world, no adjusted drift anywhere
        let st = S * ((RF - Q - 0.5 * SS * SS) * T + SS * T.sqrt() * z1).exp();
        let yt = (1.0 / X0) * ((RF - RD - 0.5 * SX * SX) * T - SX * T.sqrt() * wx).exp();
        sy += st * yt; sy1 += yt; sy2 += st * yt * st * yt; sxy += yt * yt; sxx += st * yt * yt;
        // road 4: dollar world, share at the adjusted drift, rate at rd - rf
        let xt = X0 * ((RD - RF - 0.5 * SX * SX) * T + SX * T.sqrt() * wx).exp();
        let s_a = S * ((mu - 0.5 * SS * SS) * T + SS * T.sqrt() * z1).exp();
        let s_u = S * ((RF - Q - 0.5 * SS * SS) * T + SS * T.sqrt() * z1).exp();
        sa += s_a * xt; sa2 += s_a * xt * s_a * xt; su += s_u * xt; su2 += s_u * xt * s_u * xt;
    }
    let nf = n as f64;
    let f_mc = sy / sy1;
    let var_r = (sy2 - 2.0 * f_mc * sxx + f_mc * f_mc * sxy) / nf;
    let se_f = (var_r / nf).sqrt() / (sy1 / nf);
    let (d_a, d_u) = (sa / nf, su / nf);
    let se_a = ((sa2 / nf - d_a * d_a) / nf).sqrt();
    let se_u = ((su2 / nf - d_u * d_u) / nf).sqrt();
    let fair = S * X0 * ((RD - Q) * T).exp();

    // two-state story: euro-world odds 1/2 each; dollar-world odds proportional to (1/2) / X_T
    let (up, dn, xs, xw) = (120.0, 84.0, 1.21, 0.99);
    let w_s = (0.5 / xs) / (0.5 / xs + 0.5 / xw);
    let together = w_s * up + (1.0 - w_s) * dn;
    let opposite = (1.0 - w_s) * up + w_s * dn;

    let (fq, fe) = (quanto_fwd(RHO, T), euro_fwd(T));
    let fi = euro_world_integral(RHO, X0, 160);
    let fi_130 = euro_world_integral(RHO, 1.30, 160);
    let rows: Vec<(&str, f64)> = vec![
        ("adjustment rho sS sX", RHO * SS * SX), ("quanto drift rf - q - rho sS sX", mu),
        ("euro carry rf - q", RF - Q), ("rate drift rd - rf", RD - RF), ("adjustment at rho = 1", SS * SX),
        ("1 formula: quanto forward", fq), ("2 euro-world integral", fi),
        ("3 euro-world Monte Carlo", f_mc), ("  its standard error", se_f),
        ("euro forward S e^(rf-q)T", fe), ("gap, euro forward - quanto", fe - fq),
        ("gap as ln(FE / FQ)", (fe / fq).ln()),
        ("4 dollar share E[S X], adjusted", d_a), ("  its standard error", se_a),
        ("  required S X0 e^(rd-q)T", fair),
        ("  dollar share E[S X], unadjusted", d_u), ("  unadjusted, exact", fair * (RHO * SS * SX * T).exp()),
        ("  growth required, ln(fair / S X0)", (fair / (S * X0)).ln() / T), ("  growth unadjusted, exact", (fair * (RHO * SS * SX * T).exp() / (S * X0)).ln() / T),
        ("one day: 1.01 x 1.01", 1.01 * 1.01), ("one day: 1.01 x 0.99", 1.01 * 0.99),
        ("story: dollar weight, strong euro", w_s), ("story: euro-world mean", 0.5 * up + 0.5 * dn),
        ("story: together, dollar mean", together), ("story: opposite, dollar mean", opposite),
        ("story: ln(102 / together)", (102.0 / together).ln()),
        ("rho = -0.30: quanto forward", quanto_fwd(-0.30, T)), ("rho = 0: quanto forward", quanto_fwd(0.0, T)),
        ("wrong: domestic rate for the share", S * ((RD - Q - RHO * SS * SX) * T).exp()),
        ("contract struck at FE, USD value", XBAR * (-RD * T).exp() * (fq - fe)),
        ("try: spot 1.30, integral", fi_130),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    let ks: Vec<f64> = (0..9).map(|k| -1.0 + 0.25 * k as f64).collect();
    println!("chart, rho      {}", ks.iter().map(|r| format!("{:6.2}", r)).collect::<Vec<_>>().join(" "));
    println!("chart, forward  {}", ks.iter().map(|r| format!("{:6.2}", quanto_fwd(*r, T))).collect::<Vec<_>>().join(" "));
    for tm in [1u32, 2, 5, 10] {
        let t = tm as f64;
        println!("bars, T = {:>2}: euro {:7.2}  quanto {:7.2}  gap {:5.2}", tm, euro_fwd(t), quanto_fwd(RHO, t), euro_fwd(t) - quanto_fwd(RHO, t));
    }

    assert!((fi - fq).abs() < 1e-8, "euro-world integral must land on the formula");
    assert!((fi_130 - fq).abs() < 1e-8, "today's spot rate must not matter");
    assert!((f_mc - fq).abs() < 4.0 * se_f, "euro-world Monte Carlo within 4 standard errors");
    assert!((d_a - fair).abs() < 4.0 * se_a, "adjusted drift makes the dollar share fair");
    assert!((d_u - fair).abs() > 4.0 * se_u, "unadjusted drift leaves a detectable free lunch");
    assert!((together < 0.5 * up + 0.5 * dn) == (quanto_fwd(1.0, T) < fe), "story and model agree: moving together lowers it");
    assert!((opposite > 0.5 * up + 0.5 * dn) == (quanto_fwd(-1.0, T) > fe), "story and model agree: moving apart raises it");
    println!("ALL CHECKS PASS");
}
