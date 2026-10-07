// Mean reversion -- the same check as the Python, in Rust.  No crates.
// A spread between two petrol retailers is simulated from a known Ornstein-
// Uhlenbeck model, then fitted blind.  The random numbers, the bell-curve area
// and both integrals are written here; nothing imported knows the answer.
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {              // splitmix64, top 53 bits into (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {               // Box-Muller: two uniforms, one bell-curve draw
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn psum(v: impl Iterator<Item = f64>) -> f64 { // compensated sum, as Python's sum() adds floats
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in v {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s }
        s = t;
    }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn ncdf(x: f64) -> f64 {                        // bell-curve area left of x, by its power series
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * (1.0 + total.abs()) {
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * total
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    (f(a) + f(b) + psum((1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)))) * h / 3.0
}
fn slope(a: &[f64], b: &[f64]) -> (f64, f64) { // least-squares slope and intercept of b on a
    let n = a.len() as f64;
    let (ma, mb) = (psum(a.iter().copied()) / n, psum(b.iter().copied()) / n);
    let sab = psum(a.iter().zip(b).map(|(p, q)| (p - ma) * (q - mb)));
    let saa = psum(a.iter().map(|p| (p - ma) * (p - ma)));
    (sab / saa, mb - sab / saa * ma)
}
fn fit(xs: &[f64]) -> (f64, f64, f64, f64, f64, f64, f64) { // road 1: tomorrow on today, then map to OU
    let (b, a) = slope(&xs[..xs.len() - 1], &xs[1..]);
    let q = psum(xs.windows(2).map(|w| (w[1] - a - b * w[0]) * (w[1] - a - b * w[0]))) / (xs.len() - 1) as f64;
    let k = -b.ln();
    (b, a, q.sqrt(), k, 2f64.ln() / k, a / (1.0 - b), (q / (1.0 - b * b)).sqrt())
}
fn trade(xs: &[f64], th: f64, s: f64, enter: f64) -> (Vec<f64>, Vec<usize>) {
    let (mut pos, mut x0, mut t0, mut gains, mut holds) = (0.0f64, 0.0, 0usize, vec![], vec![]);
    for (t, &x) in xs.iter().enumerate() {      // short at z >= +enter, long at z <= -enter, out at 0
        let z = (x - th) / s;
        if pos == 0.0 && z.abs() >= enter {
            pos = if z > 0.0 { -1.0 } else { 1.0 }; x0 = x; t0 = t;
        } else if pos != 0.0 && pos * z >= 0.0 {
            gains.push(pos * (x - x0)); holds.push(t - t0); pos = 0.0;
        }
    }
    (gains, holds)
}
fn main() {
    let mut rng = Rng(20260928);
    let (theta, sd, half) = (10.0f64, 2.0f64, 12.0f64);
    let kappa = 2f64.ln() / half;
    let beta = (-kappa).exp();
    let alpha = (1.0 - beta) * theta;
    let eps_sd = sd * (1.0 - beta * beta).sqrt();
    let sigma = (2.0 * kappa).sqrt() * sd;
    let step = |x: f64, r: &mut Rng| alpha + beta * x + eps_sd * r.normal();
    println!("hand: beta {:.6}  alpha {:.6}  one-day noise {:.6}  ln 2 {:.6}", beta, alpha, eps_sd, 2f64.ln());
    println!("hand: 1 - beta {:.6}  -ln beta {:.6}  1 - beta^2 {:.6}", 1.0 - beta, kappa, 1.0 - beta * beta);
    println!("hand: half-life {:.4}  mean {:.4}  long-run sd {:.4}  sigma {:.6}",
             2f64.ln() / -beta.ln(), alpha / (1.0 - beta), eps_sd / (1.0 - beta * beta).sqrt(), sigma);
    println!("hand: enter short at {:.2}  enter long at {:.2}  exit at {:.2}  gain to the mean {:.2}", theta + 2.0 * sd, theta - 2.0 * sd, theta, 2.0 * sd);
    let e12 = (-12.0 * kappa).exp();
    println!("hand: from 14, day 12 mean {:.4}  sd {:.4}", theta + 4.0 * e12, sd * (1.0 - e12 * e12).sqrt());
    let mean_t = |t: f64| theta + 4.0 * (-kappa * t).exp();
    let sd_t = |t: f64| sd * (1.0 - (-2.0 * kappa * t).exp()).sqrt();
    let rows: [(&str, Box<dyn Fn(f64) -> f64>); 4] = [("day", Box::new(|t| t)), ("expected", Box::new(mean_t)),
        ("plus one sd", Box::new(move |t| mean_t(t) + sd_t(t))), ("minus one sd", Box::new(move |t| mean_t(t) - sd_t(t)))];
    for (name, f) in rows.iter() {
        let cells: String = (0..7).map(|i| format!("{:7.2}", f(6.0 * i as f64))).collect();
        println!("chart, {:<12}{}", name, cells);
    }
    // ---- road 1 and road 2 on one ten-year record, fitted on the first five ----
    let mut xs = vec![theta + sd * rng.normal()];
    for _ in 0..2520 { let x = step(*xs.last().unwrap(), &mut rng); xs.push(x) }
    let (train, test) = (&xs[..1261], &xs[1260..]);
    let (bh, ah, qh, kh, hh, th, sdh) = fit(train);
    println!("record: {} days; fitted on the first {}, traded on the last {}", xs.len() - 1, train.len() - 1, test.len() - 1);
    let (b12, _) = slope(&train[..train.len() - 12], &train[12..]);
    let h12 = 12.0 * 2f64.ln() / -b12.ln();
    println!("fit, 1260 days: beta {:.6}  alpha {:.6}  one-day noise {:.6}  kappa {:.6}", bh, ah, qh, kh);
    println!("fit, 1260 days: half-life {:.2} d  mean {:.4}  long-run sd {:.4}", hh, th, sdh);
    println!("road 2, 12-day slope {:.4}  half-life from it {:.2} d", b12, h12);
    let mut hs = vec![];
    for _ in 0..300 {
        let mut ys = vec![theta + sd * rng.normal()];
        for _ in 0..1260 { let y = step(*ys.last().unwrap(), &mut rng); ys.push(y) }
        hs.push(fit(&ys).4);
    }
    hs.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!("300 records of 1260 days: fitted half-life 5th pct {:.2}  median {:.2}  95th pct {:.2}", hs[14], hs[149], hs[284]);
    // ---- the model's promises, checked against simulation ----
    let mut ends = vec![];
    for _ in 0..20000 {
        let mut x = 14.0;
        for _ in 0..12 { x = step(x, &mut rng) }
        ends.push(x);
    }
    let mc_mean = psum(ends.iter().copied()) / 20000.0;
    let mc_sd = (psum(ends.iter().map(|e| (e - mc_mean) * (e - mc_mean))) / 19999.0).sqrt();
    println!("from 14, day 12, 20000 paths: mean {:.4}  sd {:.4}", mc_mean, mc_sd);
    let tail = 2.0 * (1.0 - ncdf(2.0));
    let tail_int = 1.0 - simpson(&|u: f64| (-0.5 * u * u).exp() / (2.0 * PI).sqrt(), -2.0, 2.0, 2000);
    let (mut x, mut far) = (theta + sd * rng.normal(), 0u32);
    for _ in 0..200000 { x = step(x, &mut rng); if (x - theta).abs() >= 2.0 * sd { far += 1 } }
    let frac = far as f64 / 200000.0;
    println!("share of days |z| >= 2: series {:.6}  integral {:.6}  200000 days {:.4}", tail, tail_int, frac);
    let mills = |s: f64| (1.0 - ncdf(s)) * (2.0 * PI).sqrt() * (0.5 * s * s).exp();
    let wait = simpson(&mills, 0.0, 2.0, 400) / kappa;  // mean wait from z = 2 down to 0, watched always
    let mut sim_wait = |sub: f64, trials: usize, bridge: bool| {
        let bs = (-kappa / sub).exp();
        let es = sd * (1.0 - bs * bs).sqrt();
        let mut tot = 0.0;
        for _ in 0..trials {
            let (mut x, mut k) = (14.0f64, 0.0f64);
            loop {
                let y = theta + bs * (x - theta) + es * rng.normal(); k += 1.0;
                if y <= theta { break }
                if bridge && rng.uniform() < (-2.0 * (x - theta) * (y - theta) / (es * es)).exp() { break }
                x = y;
            }
            tot += k - if bridge { 0.5 } else { 0.0 };
        }
        tot / trials as f64 / sub
    };
    let (w4, w1) = (sim_wait(4.0, 10000, true), sim_wait(1.0, 20000, false));
    println!("wait z 2 -> 0: formula {:.2} d  simulated, watched always {:.2} d  checked at each close {:.2} d", wait, w4, w1);
    let mut xs = vec![theta + sd * rng.normal()];   // one long record: both roads should land on 12
    for _ in 0..1000000 { let x = step(*xs.last().unwrap(), &mut rng); xs.push(x) }
    let (r1, r2) = (fit(&xs).4, 12.0 * 2f64.ln() / -slope(&xs[..xs.len() - 12], &xs[12..]).0.ln());
    println!("1000000 days: half-life by road 1 {:.2} d  by road 2 {:.2} d", r1, r2);
    // ---- thresholds: fitted on years 1-5, traded on years 6-10, $1.00 cost a round trip ----
    println!("enter  trades  hold d  gain/trade $  total $  after 1.00 a trade $");
    for e in [1.0, 1.5, 2.0, 2.5, 3.0] {
        let (g, hd) = trade(test, th, sdh, e);
        let (n, tg) = (g.len(), psum(g.iter().copied()));
        println!("{:5.1}  {:6}  {:6.2}  {:12.2}  {:7.2}  {:20.2}", e, n,
                 hd.iter().sum::<usize>() as f64 / n as f64, tg / n as f64, tg, tg - n as f64);
    }
    // ---- what breaks ----
    println!("wrong: half-life from the Euler slope, ln 2 / (1 - beta) = {:.2} d", 2f64.ln() / (1.0 - beta));
    println!("wrong: z from one-day noise, 4 / {:.4} = {:.2}", eps_sd, 4.0 / eps_sd);
    assert!((mc_mean - (theta + 4.0 * e12)).abs() < 0.05);         // simulated mean vs the transition formula
    assert!((mc_sd - sd * (1.0 - e12 * e12).sqrt()).abs() < 0.04); // simulated spread vs the transition formula
    assert!((tail - tail_int).abs() < 1e-9);                       // series vs integral for the bell-curve tail
    assert!((frac - tail).abs() < 0.01);                           // time beyond 2 sd vs the long-run bell curve
    assert!((w4 - wait).abs() < 1.0);                              // simulated wait vs the Mills-ratio integral
    assert!(hs[14] < half && half < hs[284] && (hs[149] - half).abs() < 1.5); // the regression recovers 12 days
    assert!((r1 - half).abs() < 0.2 && (r2 - half).abs() < 0.2 && (r1 - r2).abs() < 0.15); // two roads, one answer
    println!("ALL CHECKS PASS");
}
