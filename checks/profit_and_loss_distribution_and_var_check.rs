// Value at risk from the profit-and-loss distribution -- the same check in Rust.
// Standard library only, no crates.  Same three roads: the formula with z from a
// series-built normal CDF, bisection on a Simpson tail integral, and 1,000,000
// simulated days from the same random-number generator as the Python check.
// Compile: rustc --edition 2021 -O profit_and_loss_distribution_and_var_check.rs
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 {                   // normal CDF from the Taylor series of the error function
    let t = x / 2.0_f64.sqrt();
    let (mut term, mut s, mut n) = (t, t, 0.0_f64);
    while term.abs() > 1e-17 * s.abs().max(1.0) {
        n += 1.0;
        term *= -t * t / n;
        s += term / (2.0 * n + 1.0);
    }
    0.5 + s / PI.sqrt()
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn z_of(alpha: f64) -> f64 { bisect(|x| n_cdf(x) - alpha, -10.0, 10.0) }

fn var_formula(mu: f64, sigma: f64, alpha: f64) -> f64 { -mu + z_of(alpha) * sigma }

fn tail_area(ell: f64, mu: f64, sigma: f64) -> f64 {   // P(loss > ell), Simpson on the P&L density
    let n = 4000;
    let (a, b) = (mu - 12.0 * sigma, -ell);
    let h = (b - a) / n as f64;
    let f = |x: f64| { let u = (x - mu) / sigma; (-0.5 * u * u).exp() / (sigma * (2.0 * PI).sqrt()) };
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn var_by_tail(mu: f64, sigma: f64, alpha: f64) -> f64 {
    bisect(|ell| (1.0 - alpha) - tail_area(ell, mu, sigma), -mu - 8.0 * sigma, -mu + 8.0 * sigma)
}

struct Rng { x: u64 }                       // 64-bit linear congruential generator, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.x >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { let r = (-2.0 * self.u().ln()).sqrt(); r * (2.0 * PI * self.u()).cos() }
}

fn var_sorted(losses: &[f64], alpha: f64) -> f64 {     // smallest level with share at or below >= alpha
    let mut s = losses.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let k = (alpha * s.len() as f64 - 1e-6) as usize + 1;
    s[k - 1]
}

fn var_lumpy(alpha: f64) -> f64 { if alpha <= 0.995 + 1e-12 { 0.0 } else { 1000000.0 } }

fn main() {
    let (mu, sig, a) = (0.0_f64, 180000.0_f64, 0.99_f64);
    let z99 = z_of(a);
    let v1 = var_formula(mu, sig, a);
    let v2 = var_by_tail(mu, sig, a);
    let mut rng = Rng { x: 20260928 };
    let days: Vec<f64> = (0..1000000).map(|_| -(mu + sig * rng.normal())).collect();
    let v3 = var_sorted(&days, a);
    let dens = (-0.5 * z99 * z99).exp() / (2.0 * PI).sqrt() / sig;
    let se3 = (a * (1.0 - a) / days.len() as f64).sqrt() / dens;
    let exceed = days.iter().filter(|&&x| x > v1).count() as f64 / days.len() as f64;

    let ten: Vec<f64> = (0..200000).map(|_| -(0..10).map(|_| sig * rng.normal()).sum::<f64>()).collect();
    let (v10_sim, v10_rule) = (var_sorted(&ten, a), v1 * 10.0_f64.sqrt());
    let lumpy: Vec<f64> = (0..200000).map(|_| if rng.u() < 0.005 { 1000000.0 } else { 0.0 }).collect();

    let rows: Vec<(&str, f64)> = vec![
        ("z, 99%", z99), ("  N(z)", n_cdf(z99)),
        ("1 VaR 99% 1-day, formula", v1), ("2 VaR 99% 1-day, tail integral", v2),
        ("3 VaR 99% 1-day, 1e6 sim days", v3), ("  standard error of road 3", se3),
        ("  share of sim days past VaR", exceed), ("  tail area at road-1 VaR", tail_area(v1, mu, sig)),
        ("  road 1 minus road 3", v1 - v3), ("1% quantile of the P&L", mu - z99 * sig),
        ("sqrt(10)", 10.0_f64.sqrt()), ("sqrt(20)", 20.0_f64.sqrt()),
        ("VaR 99% / VaR 95%", v1 / var_formula(mu, sig, 0.95)),
        ("VaR 99.9% / VaR 99%", var_formula(mu, sig, 0.999) / v1),
        ("VaR 99% 10-day, sqrt rule", v10_rule), ("VaR 99% 10-day, 2e5 sim paths", v10_sim),
        ("mean loss beyond 99% VaR", sig * (-0.5 * z99 * z99).exp() / (2.0 * PI).sqrt() / (1.0 - a)),
        ("exceedances per 250 days", 250.0 * (1.0 - a)),
        ("lumpy: VaR 99%", var_lumpy(0.99)), ("  sim 99%", var_sorted(&lumpy, 0.99)),
        ("lumpy: VaR 99.6%", var_lumpy(0.996)), ("  sim 99.6%", var_sorted(&lumpy, 0.996)),
        ("wrong: 95% z used", var_formula(mu, sig, 0.95)),
        ("wrong: 10-day scaled by 10", 10.0 * v1),
        ("wrong: annual sd, 1-day z", v1 * 252.0_f64.sqrt()),
        ("try: mean +5000 a day", var_formula(5000.0, sig, a)),
        ("try: sd 90000", var_formula(mu, 90000.0, a)),
        ("try: 99.9% 1-day", var_formula(mu, sig, 0.999)),
    ];
    for (name, v) in &rows { println!("{:<32} {:>16.6}", name, v); }

    println!();
    println!("VaR by confidence, 1 day");
    for al in [0.90_f64, 0.95, 0.975, 0.99, 0.995, 0.999] {
        println!("  {:5.1}%  z {:.6}   VaR {:12.2}", 100.0 * al, z_of(al), var_formula(mu, sig, al));
    }
    println!("VaR 99% by horizon, sqrt rule");
    for h in [1u32, 5, 10, 20] { println!("  {:>3} days   VaR {:12.2}", h, v1 * (h as f64).sqrt()); }
    let xs: Vec<i32> = (-6..=6).map(|i| 100 * i).collect();
    let head: Vec<String> = xs.iter().map(|x| format!("{:6}", x)).collect();
    println!("chart, P&L ($000)    {}", head.join(" "));
    let vals: Vec<String> = xs.iter().map(|&x| {
        let u = 1000.0 * x as f64 / sig;
        format!("{:6.2}", 1000.0 * 1e4 * (-0.5 * u * u).exp() / (sig * (2.0 * PI).sqrt()))
    }).collect();
    println!("chart, days/1000/$10k{}", vals.join(" "));

    assert!((z99 - 2.3263478740).abs() < 1e-9, "z against the printed normal table");
    assert!((v2 - v1).abs() < 1e-4, "tail-integral road vs formula road");
    assert!((v3 - v1).abs() < 4.0 * se3, "simulated quantile within four standard errors");
    assert!((v10_sim - v10_rule).abs() < 0.01 * v10_rule, "ten summed days vs the square-root rule");
    assert!((var_formula(5000.0, sig, a) - var_by_tail(5000.0, sig, a)).abs() < 1e-4, "nonzero mean: formula vs tail integral");
    assert!([0.99_f64, 0.996].iter().all(|&al| var_sorted(&lumpy, al) == var_lumpy(al)), "lumpy: both sides of the jump");
    println!("ALL CHECKS PASS");
}
