// Solving a 1-into-5 payer swaption backwards: vol from price, strike from price, strike from delta.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } // bell-curve height
fn n_cdf(x: f64) -> f64 { // bell-curve area left of x, Simpson's rule from 0 to x
    if x.abs() > 12.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let n = 400; let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // g(lo), g(hi) of opposite signs
    let mut glo = g(lo);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi); let gm = g(mid);
        if (gm < 0.0) == (glo < 0.0) { lo = mid; glo = gm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
// Newton inside a bracket; a step that leaves it is replaced by the midpoint
fn newton(g: &dyn Fn(f64) -> f64, dg: &dyn Fn(f64) -> f64, mut x: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 {
        let gx = g(x);
        if gx == 0.0 { return x; }
        if (gx > 0.0) == (g(hi) > 0.0) { hi = x; } else { lo = x; }
        let xn = x - gx / dg(x);
        x = if lo < xn && xn < hi { xn } else { 0.5 * (lo + hi) };
    }
    x
}
fn n_inv(p: f64) -> f64 { bisect(&|x| n_cdf(x) - p, -10.0, 10.0) }

struct Mkt { a: f64, f: f64, t: f64 }
impl Mkt {
    fn black(&self, sig: f64, k: f64, a: f64, t: f64) -> f64 { // payer per unit notional, lognormal
        if sig <= 0.0 { return a * (self.f - k).max(0.0); }
        let w = sig * t.sqrt(); let d1 = (self.f / k).ln() / w + 0.5 * w;
        a * (self.f * n_cdf(d1) - k * n_cdf(d1 - w))
    }
    fn bl(&self, sig: f64, k: f64) -> f64 { self.black(sig, k, self.a, self.t) }
    fn bach(&self, sn: f64, k: f64) -> f64 { // payer per unit notional, normal
        let w = sn * self.t.sqrt(); let d = (self.f - k) / w;
        self.a * ((self.f - k) * n_cdf(d) + w * phi(d))
    }
    fn vega(&self, s: f64, k: f64) -> f64 {
        let w = s * self.t.sqrt();
        self.a * self.f * phi((self.f / k).ln() / w + 0.5 * w) * self.t.sqrt()
    }
    // Simpson over z from the strike's z to 10: A * E[rate - k]
    fn integral(&self, rate_at: &dyn Fn(f64) -> f64, z_k: f64, k: f64) -> f64 {
        let n = 2000; let h = (10.0 - z_k) / n as f64; let mut s = 0.0;
        for i in 0..=n {
            let z = z_k + i as f64 * h;
            let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            s += c * phi(z) * (rate_at(z) - k);
        }
        self.a * s * h / 3.0
    }
    fn normal_vol(&self, quote: f64, k: f64) -> f64 { // no ceiling: grow the bracket until it holds the quote
        let mut hi = 1e-4;
        while self.bach(hi, k) < quote { hi *= 2.0; }
        bisect(&|s| self.bach(s, k) - quote, 1e-12, hi)
    }
}

fn main() {
    let (r, t, notional) = (0.036_f64, 1.0_f64, 10_000_000.0_f64); // flat 3.6% curve, 1-year expiry, $10m
    let d = |x: f64| (-r * x).exp();
    let a: f64 = [2.0, 3.0, 4.0, 5.0, 6.0].iter().map(|&x| d(x)).sum(); // annuity
    let f = (d(1.0) - d(6.0)) / a; // forward swap rate
    let k = f; // at the money
    let m = Mkt { a, f, t };
    let logn = |sig: f64| move |z: f64| f * (-0.5 * sig * sig * t + sig * t.sqrt() * z).exp();
    let z_logn = |sig: f64, kk: f64| ((kk / f).ln() + 0.5 * sig * sig * t) / (sig * t.sqrt());

    let sig0 = 0.30;
    let p = m.bl(sig0, k); // the quote
    // implied lognormal vol, three roads
    let guess = (2.0 * PI / t).sqrt() * p / (a * f); // Brenner-Subrahmanyam first guess
    let v_bis = bisect(&|s| m.bl(s, k) - p, 1e-9, 5.0);
    let v_newt = newton(&|s| m.bl(s, k) - p, &|s| m.vega(s, k), guess, 1e-9, 5.0);
    let v_atm = 2.0 / t.sqrt() * n_inv((p / (a * f) + 1.0) / 2.0); // exact at the money
    let p_int = m.integral(&logn(v_bis), z_logn(v_bis, k), k);
    // implied normal vol
    let n_bis = m.normal_vol(p, k);
    let n_atm = p * (2.0 * PI).sqrt() / (a * t.sqrt());
    let n_hagan = v_bis * f * (1.0 - v_bis * v_bis * t / 24.0); // Hagan's expansion, leading terms
    let pn_int = m.integral(&|z| f + n_bis * t.sqrt() * z, 0.0, k);
    let k2 = f + 0.01; let p2 = m.bl(sig0, k2); // one percent out of the money
    let n2_bis = bisect(&|s| m.bach(s, k2) - p2, 1e-12, 0.1);
    let n2_hagan = sig0 * (f - k2) / (f / k2).ln() * (1.0 - sig0 * sig0 * t / 24.0);
    let v2_newt = newton(&|s| m.bl(s, k2) - p2, &|s| m.vega(s, k2), 0.05, 1e-9, 5.0);
    let wild_low = 0.05 - (m.bl(0.05, k2) - p2) / m.vega(0.05, k2); // one unbracketed Newton step
    let wild_high = 2.0 - (m.bl(2.0, k2) - p2) / m.vega(2.0, k2);
    // existence and its edges
    let ceiling = a * f;
    let big_quote = 1.1 * ceiling;
    let black_at_500 = m.bl(5.0, k); let v_fooled = bisect(&|s| m.bl(s, k) - big_quote, 1e-9, 5.0);
    let n_big = m.normal_vol(big_quote, k);
    // strike from a target premium: 1.00% of notional
    let target = 0.01;
    let k_bis = bisect(&|kk| m.bl(sig0, kk) - target, 1e-6, 0.5);
    let dpdk = |kk: f64| -a * n_cdf((f / kk).ln() / (sig0 * t.sqrt()) - 0.5 * sig0 * t.sqrt());
    let k_newt = newton(&|kk| m.bl(sig0, kk) - target, &dpdk, f, 1e-6, 0.5);
    let pk_int = m.integral(&logn(sig0), z_logn(sig0, k_bis), k_bis);
    // strike from delta: a 25-delta payer
    let w = sig0 * t.sqrt();
    let k_delta = f * (-w * n_inv(0.25) + 0.5 * w * w).exp();
    let k_delta_bis = bisect(&|kk| n_cdf((f / kk).ln() / w + 0.5 * w) - 0.25, 1e-4, 0.5);
    // what breaks
    let v_no_annuity = bisect(&|s| m.black(s, k, 1.0, t) - p, 1e-9, 5.0);
    let v_six_years = bisect(&|s| m.black(s, k, a, 6.0) - p, 1e-9, 5.0);
    // try changing
    let p_vol20 = m.bl(0.20, k);
    let v_quote25 = bisect(&|s| m.bl(s, k) - 0.025, 1e-9, 5.0);
    let k_half = bisect(&|kk| m.bl(sig0, kk) - 0.005, 1e-6, 0.5);

    let rows: Vec<(&str, f64)> = vec![("D(1)", d(1.0)), ("D(6)", d(6.0)), ("annuity A", a), ("forward swap rate F", f), ("ceiling A*F", ceiling),
        ("quote P at 30%", p), ("  in dollars on $10m", p * notional), ("P/(A*F)", p / (a * f)),
        ("N inverse of (1 + P/(A*F))/2", n_inv((p / (a * f) + 1.0) / 2.0)), ("vega at 30%", m.vega(sig0, k)),
        ("1 lognormal vol, bisection", v_bis), ("2 lognormal vol, guarded Newton", v_newt),
        ("3 lognormal vol, closed form at the money", v_atm), ("  first guess, Brenner-Subrahmanyam", guess),
        ("4 reprice by integral at vol 1", p_int),
        ("5 normal vol, bisection", n_bis), ("6 normal vol, closed form", n_atm),
        ("  Hagan expansion", n_hagan), ("  Hagan gap, basis points", 1e4 * (n_hagan - n_atm)), ("7 reprice by integral at vol 5", pn_int),
        ("K2 = F + 1%", k2), ("  quote at K2", p2), ("  normal vol at K2, bisection", n2_bis),
        ("  normal vol at K2, Hagan", n2_hagan), ("  Hagan gap at K2, basis points", 1e4 * (n2_hagan - n2_bis)), ("  lognormal vol at K2, guarded Newton from 5%", v2_newt),
        ("quote 110% of ceiling", big_quote), ("  Black price at 500% vol", black_at_500), ("  bisection on (0, 500%) returns anyway", v_fooled),
        ("  normal vol for that quote", n_big),
        ("8 strike for 1.00%, bisection", k_bis), ("9 strike for 1.00%, Newton", k_newt),
        ("  reprice by integral at that strike", pk_int),
        ("ATM delta N(d1)", n_cdf(0.5 * w)), ("N inverse of 0.25", n_inv(0.25)),
        ("10 strike for 25 delta, closed form", k_delta), ("11 strike for 25 delta, bisection", k_delta_bis),
        ("wrong: annuity left out", v_no_annuity), ("wrong: T = 6, the swap's end", v_six_years),
        ("wrong: normal vol / F, the first guess", n_bis / f),
        ("wrong: unguarded Newton step from 5%", wild_low), ("wrong: unguarded Newton step from 200%", wild_high),
        ("try: premium at 20% vol", p_vol20), ("try: vol for a 2.50% quote", v_quote25),
        ("try: strike for 0.50%", k_half)];
    for (name, v) in &rows { println!("{:<46} {:>16.9}", name, v); }
    println!();
    let vols: Vec<f64> = (0..11).map(|i| 0.2 * i as f64).collect();
    let line = |v: &Vec<f64>, fmt0: bool| v.iter().map(|x| if fmt0 { format!("{:6.0}", x) } else { format!("{:6.2}", x) }).collect::<Vec<_>>().join(" ");
    println!("{:<16}{}", "chart, vol %", line(&vols.iter().map(|s| 100.0 * s).collect(), true));
    println!("{:<16}{}", "chart, premium %", line(&vols.iter().map(|&s| 100.0 * m.bl(s, k)).collect(), false));
    let strikes: Vec<f64> = (0..9).map(|i| 0.02 + 0.005 * i as f64).collect();
    println!("{:<16}{}", "chart, strike %", line(&strikes.iter().map(|x| 100.0 * x).collect(), false));
    println!("{:<16}{}", "chart, premium %", line(&strikes.iter().map(|&kk| 100.0 * m.bl(sig0, kk)).collect(), false));
    println!("chart lines, %: quote {:.2}, ceiling {:.2}, target {:.2}", 100.0 * p, 100.0 * ceiling, 100.0 * target);

    assert!((f - (r.exp() - 1.0)).abs() < 1e-15, "flat curve: forward swap rate is one year of compounding, e^r - 1");
    assert!((v_bis - sig0).abs() < 1e-10, "bisection must return the 30% that made the quote");
    assert!((v_atm - v_newt).abs() < 1e-9, "closed form at the money vs guarded Newton");
    assert!((p_int - p).abs() < 1e-9, "integral reprice at the solved vol vs the quote");
    assert!((n_bis - n_atm).abs() < 1e-12, "normal vol: bisection vs closed form");
    assert!((pn_int - p).abs() < 1e-9, "normal vol: integral reprice");
    assert!((n_hagan - n_atm).abs() < 1e-6, "Hagan within 0.01 basis points at the money");
    assert!((n2_hagan - n2_bis).abs() < 1e-6, "Hagan within 0.01 basis points out of the money");
    assert!((v2_newt - sig0).abs() < 1e-10, "guarded Newton from a bad start still lands on 30%");
    assert!(black_at_500 < big_quote, "no lognormal vol reaches a quote above the ceiling");
    assert!((k_bis - k_newt).abs() < 1e-12, "strike from premium: bisection vs Newton");
    assert!((pk_int - target).abs() < 1e-9, "strike from premium: integral reprice");
    assert!((k_delta - k_delta_bis).abs() < 1e-10, "strike from delta: closed form vs bisection");
    println!("ALL CHECKS PASS");
}
