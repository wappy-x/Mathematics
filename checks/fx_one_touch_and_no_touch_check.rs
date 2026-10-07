// One-touch and no-touch on EURUSD -- the check behind the card.  Rust std only.
// Same four roads as the Python: the mirror formula, the first-passage-time
// integral, the bridge integral over the end point, a simulation.
use std::f64::consts::PI;

const S: f64 = 1.10; const H: f64 = 1.20; const RD: f64 = 0.05; const RF: f64 = 0.03;
const SIG: f64 = 0.10; const T: f64 = 1.0;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    let half = simpson(&|z: f64| (-0.5 * z * z).exp(), 0.0, x.abs(), 2000) / (2.0 * PI).sqrt();
    if x >= 0.0 { 0.5 + half } else { 0.5 - half }
}

// road 1: the mirror formula; chance log EURUSD, drift nu, reaches ln(h/s) by t
fn touch(s: f64, h: f64, nu: f64, sig: f64, t: f64) -> f64 {
    let (b, v) = ((h / s).ln(), sig * t.sqrt());
    n_cdf((nu * t - b) / v) + (2.0 * nu * b / (sig * sig)).exp() * n_cdf((-b - nu * t) / v)
}

fn at_hit(s: f64, h: f64, nu: f64, r: f64, sig: f64, t: f64) -> f64 {
    let nu2 = (nu * nu + 2.0 * r * sig * sig).sqrt();
    ((h / s).ln() * (nu - nu2) / (sig * sig)).exp() * touch(s, h, nu2, sig, t)
}

fn ot(s: f64, h: f64, sig: f64, t: f64) -> f64 {
    (-RD * t).exp() * touch(s, h, RD - RF - 0.5 * sig * sig, sig, t)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // splitmix64, top 53 bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn main() {
    let nu_d = RD - RF - 0.5 * SIG * SIG;
    let nu_f = RD - RF + 0.5 * SIG * SIG;
    let b = (H / S).ln();
    let (p_d, p_f) = (touch(S, H, nu_d, SIG, T), touch(S, H, nu_f, SIG, T));
    let (ot_usd, ot_eur) = ((-RD * T).exp() * p_d, (-RF * T).exp() * p_f);
    let hit_usd = at_hit(S, H, nu_d, RD, SIG, T);
    let hit_eur = H / S * hit_usd;
    let nt_usd = (-RD * T).exp() - ot_usd;

    // road 2: first-passage-time density integrated over the year
    let by_time = |nu: f64, r: f64| -> f64 {
        let f = |t: f64| -> f64 {
            if t <= 0.0 { return 0.0; }
            let fpt = b / (SIG * (2.0 * PI * t.powi(3)).sqrt())
                * (-(b - nu * t).powi(2) / (2.0 * SIG * SIG * t)).exp();
            (-r * t).exp() * fpt
        };
        simpson(&f, 0.0, T, 20000)
    };
    let (p_d2, p_f2) = (by_time(nu_d, 0.0), by_time(nu_f, 0.0));
    let (hit_usd2, hit_eur2) = (by_time(nu_d, RD), by_time(nu_f, RF));

    // road 3: end points below the wall, times the bridge's chance of never crossing
    let v2 = SIG * SIG * T;
    let end_no_touch = |x: f64| -> f64 {
        let dens = (-(x - nu_d * T).powi(2) / (2.0 * v2)).exp() / (2.0 * PI * v2).sqrt();
        dens * (1.0 - (-2.0 * b * (b - x) / v2).exp())
    };
    let nt_usd3 = (-RD * T).exp() * simpson(&end_no_touch, -1.0, b, 20000);

    // road 4: 50,000 simulated years of daily EURUSD, bridge between days
    let mut rng = Rng(20260927);
    let (paths, n) = (50000usize, 252usize);
    let dt = T / n as f64;
    let (mut cont, mut disc, mut cont_sq) = (0.0f64, 0.0f64, 0.0f64);
    for _ in 0..paths {
        let (mut x, mut surv, mut hit) = (0.0f64, 1.0f64, 0.0f64);
        for _ in 0..n {
            let y = x + nu_d * dt + SIG * dt.sqrt() * rng.gauss();
            if y >= b { hit = 1.0; surv = 0.0; break; }
            surv *= 1.0 - (-2.0 * (b - x) * (b - y) / (SIG * SIG * dt)).exp();
            x = y;
        }
        disc += hit;
        cont += 1.0 - surv;
        cont_sq += (1.0 - surv).powi(2);
    }
    let (p_mc, p_daily) = (cont / paths as f64, disc / paths as f64);
    let se = ((cont_sq / paths as f64 - p_mc * p_mc) / paths as f64).sqrt();
    let beta = 0.5826;
    let h_shift = H * (beta * SIG * dt.sqrt()).exp();
    let ot_bgk = (-RD * T).exp() * touch(S, h_shift, nu_d, SIG, T);

    let delta = (ot(S + 1e-4, H, SIG, T) - ot(S - 1e-4, H, SIG, T)) / 2e-4 * 0.01;
    let vega = (ot(S, H, SIG + 1e-4, T) - ot(S, H, SIG - 1e-4, T)) / 2e-4 * 0.01;
    let v = SIG * T.sqrt();
    let dig = (-RD * T).exp() * n_cdf((nu_d * T - b) / v);
    let weight = (H / S).powf(2.0 * nu_d / (SIG * SIG));
    let mirror = (-RD * T).exp() * weight * n_cdf((-b - nu_d * T) / v);

    let rows: Vec<(&str, f64)> = vec![
        ("ln(H/S)", b), ("drift in dollars nu_d", nu_d), ("drift in euros nu_f", nu_f),
        ("lambda = nu_d / sig^2", nu_d / (SIG * SIG)), ("tilted drift for pay-at-hit", (nu_d * nu_d + 2.0 * RD * SIG * SIG).sqrt()),
        ("argument, finish above", (nu_d * T - b) / v), ("argument, mirror", (-b - nu_d * T) / v),
        ("chance: finish above 1.20", n_cdf((nu_d * T - b) / v)),
        ("chance: touch and come back", weight * n_cdf((-b - nu_d * T) / v)),
        ("1 touch chance, dollars, mirror", p_d), ("2 touch chance, dollars, time integral", p_d2),
        ("4 touch chance, simulation", p_mc), ("  simulation standard error", se),
        ("one-touch USD at expiry", ot_usd), ("no-touch USD, discount minus one-touch", nt_usd),
        ("3 no-touch USD, end-point integral", nt_usd3), ("discount factor e^-rdT", (-RD * T).exp()),
        ("1 one-touch USD at hit, tilted mirror", hit_usd), ("2 one-touch USD at hit, time integral", hit_usd2),
        ("1 touch chance, euros, mirror", p_f), ("2 touch chance, euros, time integral", p_f2),
        ("one-touch EUR at expiry, in EUR", ot_eur),
        ("1 one-touch EUR at hit, H/S x USD at hit", hit_eur), ("2 one-touch EUR at hit, time integral", hit_eur2),
        ("digital USD above 1.20", dig), ("mirror weight (H/S)^(2 lambda)", weight),
        ("mirror digital, weighted", mirror),
        ("daily: simulated touch chance", p_daily), ("daily: simulated one-touch USD", (-RD * T).exp() * p_daily),
        ("daily: shifted wall", h_shift), ("daily: one-touch USD, shifted wall", ot_bgk),
        ("delta per 0.01 rise in EURUSD", delta), ("vega per 1 vol point", vega),
        ("wrong: drift dropped", (-RD * T).exp() * 2.0 * n_cdf(-b / v)),
        ("wrong: twice the digital", 2.0 * dig), ("wrong: no-touch as 1 - one-touch", 1.0 - ot_usd),
        ("wrong: euro drift for a dollar payout", (-RD * T).exp() * p_f),
        ("try: vol 15%", ot(S, H, 0.15, T)), ("try: wall 1.15", ot(S, 1.15, SIG, T)),
        ("try: three months", ot(S, H, SIG, 0.25)),
    ];
    for (name, val) in &rows {
        println!("{:<42} {:>10.6}", name, val);
    }
    println!("ladder: EURUSD today, one-touch USD, no-touch USD");
    for k in 0..11 {
        let s = 1.00 + 0.02 * k as f64;
        println!("  {:.2} {:>6.2} {:>6.2}", s, ot(s, H, SIG, T), (-RD * T).exp() - ot(s, H, SIG, T));
    }

    assert!((p_d - p_d2).abs() < 1e-7);
    assert!((p_f - p_f2).abs() < 1e-7);
    assert!((hit_usd - hit_usd2).abs() < 1e-7);
    assert!((hit_eur - hit_eur2).abs() < 1e-7);
    assert!((nt_usd - nt_usd3).abs() < 1e-7);
    assert!((p_mc - p_d).abs() < 3.0 * se);
    assert!(((-RD * T).exp() * p_daily - ot_bgk).abs() < 0.004);
    println!("all checks passed");
}
