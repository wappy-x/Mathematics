// Gamma-Poisson -- the same check as gamma_poisson_check.py, in Rust.  Std only,
// no crates.  Prior Gamma(shape 24, rate 2 hours); record: 28 emails in 2 hours,
// then 17 in 1 hour.  Road 1: the conjugate update and the negative binomial.
// Road 2: prior times likelihood on a grid (Simpson), no gamma algebra.  Road 3:
// seeded simulated desks (SplitMix64), kept only if 3 hours brought 45 emails.
// Compile: rustc --edition 2021 -O gamma_poisson_check.rs -o /tmp/gamma_poisson_check

const ALPHA: u32 = 24;
const BETA: f64 = 2.0;
const RECORD: [(f64, u32); 2] = [(2.0, 28), (1.0, 17)]; // (exposure in hours, emails seen)
const STAFF: usize = 20; // one person clears 20 emails an hour

fn update(a: u32, b: f64, record: &[(f64, u32)]) -> (u32, f64) { // counts add to the shape, hours to the rate
    (a + record.iter().map(|r| r.1).sum::<u32>(), b + record.iter().fold(0.0, |s, r| s + r.0))
}

fn negbin(a: f64, b: f64, t: f64, top: usize) -> Vec<f64> {
    let p = b / (b + t);
    let mut q = vec![p.powf(a)];
    for k in 0..top {
        q.push(q[k] * (a + k as f64) / (k as f64 + 1.0) * (1.0 - p));
    }
    q
}

fn poisson(mu: f64, top: usize) -> Vec<f64> {
    let mut p = vec![(-mu).exp()];
    for k in 0..top {
        p.push(p[k] * mu / (k as f64 + 1.0));
    }
    p
}

fn lfact(n: u32) -> f64 { (2..=n).fold(0.0, |s, j| s + (j as f64).ln()) }
fn gamma_cdf(x: f64, a: f64, b: f64) -> f64 { 1.0 - poisson(b * x, a as usize - 1).iter().sum::<f64>() } // whole a: at least a events by time x
fn bisect<F: Fn(f64) -> f64>(cdf: F, c: f64) -> f64 { // the x with cdf(x) = c, halving 0 to 40 fifty times
    let (mut lo, mut hi) = (0.0, 40.0);
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if cdf(mid) >= c { hi = mid } else { lo = mid } }
    (lo + hi) / 2.0
}

fn gamma_pdf(x: f64, a: u32, b: f64) -> f64 {
    // whole-number shape a: Gamma(a) = (a-1)!
    (a as f64 * b.ln() + (a as f64 - 1.0) * x.ln() - b * x - lfact(a - 1)).exp()
}

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64) -> f64 {
    let n = 4000;
    let h = (hi - lo) / n as f64;
    let inner = (1..n).fold(0.0, |s, i| s + if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h));
    (f(lo) + f(hi) + inner) * h / 3.0
}

fn row(label: &str, v: f64) { println!("{:<44}{:>12.6}", label, v); }

fn unnorm(lam: f64) -> f64 {
    let mut s = (ALPHA as f64 - 1.0) * lam.ln() - BETA * lam;
    for &(t, y) in RECORD.iter() {
        s += y as f64 * (t * lam).ln() - t * lam - lfact(y);
    }
    s.exp()
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn count(&mut self, mu: f64) -> usize {
        // multiply uniforms until below e^-mu
        let lim = (-mu).exp();
        let (mut prod, mut n) = (self.u01(), 0);
        while prod > lim { prod *= self.u01(); n += 1; }
        n
    }
}

fn main() {
    // ---- road 1: the formula ----
    let (a, b) = update(ALPHA, BETA, &RECORD);
    let (af, kk, hh) = (a as f64, a - ALPHA, b - BETA); // kk emails in hh hours
    let (mean, sd) = (af / b, af.sqrt() / b);
    let q = negbin(af, b, 1.0, 200);
    let tail = 1.0 - q[..=STAFF].iter().sum::<f64>();
    let plug = poisson(mean, 200);
    println!("posterior Gamma(shape {}, rate {:.0} hours)", a, b);
    row("prior mean, emails per hour", ALPHA as f64 / BETA); row("prior sd", (ALPHA as f64).sqrt() / BETA);
    row("record rate K / H", kk as f64 / hh);
    row("prior weight beta / B", BETA / b); row("record weight H / B", hh / b);
    row("1 posterior mean A / B", mean);
    row("1 posterior sd sqrt(A) / B", sd);
    let ci: Vec<f64> = [0.025, 0.975].iter().map(|&c| bisect(|x| gamma_cdf(x, af, b), c)).collect();
    row("1 rate 95% interval, lower end", ci[0]); row("  upper end", ci[1]);
    row("1 next hour P(N = 14)", q[14]);
    row("1 next hour variance tA/B + t^2 A/B^2", af / b + af / b.powf(2.0)); row("  of which t^2 A/B^2", af / b.powf(2.0));
    row("  plug-in Poisson(13.8) variance", mean);
    let pt = 1.0 - plug[..=STAFF].iter().sum::<f64>();
    println!("1 next hour P(N > 20) {:.6} (1 hour in {:.1}); plug-in {:.6} (1 in {:.1})", tail, 1.0 / tail, pt, 1.0 / pt);
    let m0 = update(ALPHA, BETA, &RECORD[..1]);
    let m1 = update(m0.0, m0.1, &RECORD[1..]);
    let r1 = update(ALPHA, BETA, &RECORD[1..]);
    let m2 = update(r1.0, r1.1, &RECORD[..1]);
    println!("sequential: after morning {}/{:.0}, then {}; other order {}/{:.0}", m0.0, m0.1, m1.0, m2.0, m2.1);

    // ---- road 2: prior times likelihood on a grid, windows kept separate ----
    let (lo, hi) = (1e-9, 40.0);
    let z = simpson(unnorm, lo, hi);
    let g_mean = simpson(|x| x * unnorm(x), lo, hi) / z;
    let g_var = simpson(|x| x * x * unnorm(x), lo, hi) / z - g_mean.powf(2.0);
    let g_q: Vec<f64> = (0..=STAFF as u32)
        .map(|k| simpson(|x| (-x + k as f64 * x.ln() - lfact(k)).exp() * unnorm(x), lo, hi) / z)
        .collect();
    row("2 grid posterior mean", g_mean); row("2 grid posterior sd", g_var.sqrt());
    let g_ci: Vec<f64> = [0.025, 0.975].iter().map(|&c| bisect(|x| simpson(unnorm, lo, x) / z, c)).collect();
    row("2 grid rate 95% interval, lower end", g_ci[0]); row("  upper end", g_ci[1]);
    row("2 grid P(N = 14)", g_q[14]); row("2 grid P(N > 20)", 1.0 - g_q.iter().sum::<f64>());
    let pmf_mean = q.iter().enumerate().fold(0.0, |s, (k, x)| s + k as f64 * x);
    let pmf_var = q.iter().enumerate().fold(0.0, |s, (k, x)| s + (k * k) as f64 * x) - pmf_mean.powf(2.0);
    row("  masses 0..200 sum", q.iter().sum::<f64>()); row("  variance read off the masses", pmf_var);

    // ---- road 3: simulated desks (SplitMix64, seed 20260929) ----
    let mut rng = SplitMix64(20260929);
    let worlds = 200000;
    let mut kept: Vec<(f64, usize)> = Vec::new();
    for _ in 0..worlds {
        let mut prod = 1.0;
        for _ in 0..ALPHA { prod *= rng.u01(); } // 24 exponential waits of rate 2 add to a Gamma(24, 2)
        let lam = -prod.ln() / BETA;
        if rng.count(hh * lam) == kk as usize { // hh hours of this desk; keep it if kk emails came
            kept.push((lam, rng.count(lam)));
        }
    }
    let n = kept.len() as f64;
    let s_mean = kept.iter().fold(0.0, |s, k| s + k.0) / n;
    let s_sd = (kept.iter().fold(0.0, |s, k| s + (k.0 - s_mean).powf(2.0)) / (n - 1.0)).sqrt();
    let s_tail = kept.iter().filter(|k| k.1 > STAFF).count() as f64 / n;
    println!("3 simulated desks {}, kept {}", worlds, kept.len());
    row("3 sim posterior mean", s_mean); row("  standard error", s_sd / n.sqrt());
    row("3 sim posterior sd", s_sd);
    row("3 sim next hour P(N > 20)", s_tail); row("  standard error", (s_tail * (1.0 - s_tail) / n).sqrt());

    // ---- what breaks, and try changing ----
    row("wrong: count windows, not hours: mean", af / (BETA + RECORD.len() as f64)); row("wrong: rate 2 read as scale 2: mean", af / (0.5 + hh));
    row("wrong: morning entered twice: mean", (af + 28.0) / (b + 2.0)); row("  its sd", (af + 28.0).sqrt() / (b + 2.0));
    row("try: prior Gamma(2.4, 0.2): mean", (2.4 + 45.0) / 3.2);
    row("try: six hours, 90 emails: mean", (24.0 + 90.0) / 8.0); row("try: six hours, 90 emails: sd", 114f64.sqrt() / 8.0);
    row("try: half-hour window: mean", 0.5 * af / b); row("try: half-hour window: variance", 0.5 * af / b + 0.25 * af / b.powf(2.0));
    row("try: a fourth hour with no email: mean", af / (b + 1.0));

    // ---- chart points ----
    let line = |label: &str, v: Vec<String>| println!("{:<17}{}", label, v.join(" "));
    line("chart, rate", (6..23).map(|x| format!("{:>6}", x)).collect());
    line("chart, prior", (6..23).map(|x| format!("{:6.4}", gamma_pdf(x as f64, ALPHA, BETA))).collect());
    line("chart, posterior", (6..23).map(|x| format!("{:6.4}", gamma_pdf(x as f64, a, b))).collect());
    line("chart, count", (4..27).map(|k| format!("{:>6}", k)).collect());
    line("chart, predict", (4..27).map(|k| format!("{:6.4}", q[k])).collect());
    line("chart, plug-in", (4..27).map(|k| format!("{:6.4}", plug[k])).collect());

    assert!((g_mean - mean).abs() < 1e-9, "grid posterior mean vs A/B");
    assert!((0..=STAFF).all(|k| (g_q[k] - q[k]).abs() < 1e-9), "grid predictive vs negative binomial");
    assert!((pmf_var - (af / b + af / b.powf(2.0))).abs() < 1e-9, "variance from the masses vs the formula");
    assert!((0..2).all(|i| (g_ci[i] - ci[i]).abs() < 1e-8), "grid interval vs the gamma's Poisson sum");
    assert!((s_mean - mean).abs() < 4.0 * s_sd / n.sqrt(), "simulated posterior mean within 4 se");
    assert!((s_tail - tail).abs() < 4.0 * (s_tail * (1.0 - s_tail) / n).sqrt(), "simulated tail within 4 se");
    println!("ALL CHECKS PASS");
}
