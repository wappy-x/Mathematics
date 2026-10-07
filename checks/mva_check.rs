// MVA -- the same check as mva_check.py, in Rust.  Standard library only, no crates.
// The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind
// (hazard 2% a year, recovery 40%), now with two-way initial margin sized as a 99% ten-day
// move and funded at 50 bp over what the margin earns.  The normal CDF is a series, the
// percentile is bisection, the integrals are Simpson's rule, the random numbers are
// splitmix64 plus Box-Muller.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const RATE: f64 = 0.05;
const QD: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const LAM: f64 = 0.02;
const REC: f64 = 0.40;
const S_IM: f64 = 0.005;
const S_F: f64 = 0.01;
const H: f64 = 10.0 / 252.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                     // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term; }
    0.5 + phi(x) * total
}
fn d1(s: f64, left: f64) -> f64 { ((s / K).ln() + (RATE - QD + 0.5 * SIG * SIG) * left) / (SIG * left.sqrt()) }
fn call(s: f64, left: f64) -> f64 {
    let d = d1(s, left);
    s * (-QD * left).exp() * n_cdf(d) - K * (-RATE * left).exp() * n_cdf(d - SIG * left.sqrt())
}
fn delta(s: f64, left: f64) -> f64 {
    if left > 1e-12 { (-QD * left).exp() * n_cdf(d1(s, left)) } else if s >= K { 1.0 } else { 0.0 }
}
fn z99() -> f64 {                                             // N(z) = 0.99, by bisection
    let (mut lo, mut hi) = (0.0, 8.0);
    for _ in 0..200 { let m = 0.5 * (lo + hi); if n_cdf(m) < 0.99 { lo = m } else { hi = m } }
    0.5 * (lo + hi)
}
fn im(z: f64, s: f64, left: f64) -> f64 { z * delta(s, left) * s * SIG * H.sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn deim(z: f64, t: f64) -> f64 {                              // D(t) E[IM(t)] over Acme's price at t
    if t < 1e-12 { return im(z, S, T); }
    let (drift, vol) = ((RATE - QD - 0.5 * SIG * SIG) * t, SIG * t.sqrt());
    let a = if t < T { -8.0 } else { ((K / S).ln() - drift) / vol };
    (-RATE * t).exp() * simpson(|x| im(z, S * (drift + vol * x).exp(), T - t) * phi(x), a, 8.0, 2000)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                            // splitmix64, a number in (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u = self.uniform(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.uniform()).cos() }
}
fn annuity(lam: f64, t: f64) -> f64 { if lam > 0.0 { (1.0 - (-lam * t).exp()) / lam } else { t } }
fn im0(z: f64, t: f64) -> f64 { z * delta(S, t) * S * SIG * H.sqrt() }
fn mva(z: f64, t: f64, lam: f64, s: f64) -> f64 { s * im0(z, t) * annuity(lam, t) }
fn cva(t: f64, lam: f64) -> f64 { (1.0 - REC) * call(S, t) * (1.0 - (-lam * t).exp()) }
fn fva(t: f64, lam: f64) -> f64 { S_F * call(S, t) * annuity(lam, t) }

fn main() {
    let z = z99();
    let (c0, d0) = (call(S, T), delta(S, T));
    let sd = d0 * S * SIG * H.sqrt();                         // one standard deviation of the ten-day P&L
    let im_0 = im0(z, T);
    let im_spec = 2.33 * 0.587 * S * SIG * H.sqrt();
    let m = 200000usize;
    let mut rng = Rng(20260928);
    let mut pnl: Vec<f64> = (0..m).map(|_| sd * rng.gauss()).collect();
    pnl.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let im_sim = pnl[(0.99 * m as f64) as usize];
    let up = (SIG * H.sqrt() * z).exp();
    let (im_up, im_dn) = (call(S * up, T) - c0, c0 - call(S / up, T));

    let mva1 = mva(z, T, LAM, S_IM);                          // road 1: closed form
    let n = 12;                                               // road 2: monthly integrated profile
    let mva2: f64 = (0..n).map(|i| { let t = (i as f64 + 0.5) / n as f64; S_IM * deim(z, t) * (-LAM * t).exp() / n as f64 }).sum();
    let (mut acc, mut acc2) = (0.0, 0.0);                     // road 3: simulate date, price, default
    for _ in 0..m {
        let t = T * rng.uniform();
        let tau = -rng.uniform().ln() / LAM;
        let st = S * ((RATE - QD - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * rng.gauss()).exp();
        let x = if t < tau { T * S_IM * (-RATE * t).exp() * im(z, st, T - t) } else { 0.0 };
        acc += x; acc2 += x * x;
    }
    let mva3 = acc / m as f64;
    let se3 = ((acc2 / m as f64 - mva3 * mva3) / m as f64).sqrt();

    let (cva1, fva1) = (cva(T, LAM), fva(T, LAM));
    let lam_star = S_IM * im_0 / ((1.0 - REC) * c0);
    let (mut a, mut b) = (1e-6, 0.5);
    for _ in 0..200 { let mm = 0.5 * (a + b); if cva(T, mm) < mva(z, T, mm, S_IM) { a = mm } else { b = mm } }
    let lam_bis = 0.5 * (a + b);
    let sf_star = S_IM * im_0 / c0;
    let tail = sd * (phi(z) - z * (1.0 - n_cdf(z)));
    let tail_int = simpson(|x| (x - im_0) * phi(x / sd) / sd, im_0, 10.0 * sd, 4000);
    let cva_coll = (1.0 - REC) * tail * (1.0 - (-LAM * T).exp());

    let rows: Vec<(&str, f64)> = vec![
        ("clean call C0", c0), ("delta e^-qT N(d1)", d0), ("z, 99th percentile", z),
        ("ten-day P&L sd, D S sig sqrt(h)", sd), ("IM, delta-normal z x sd", im_0),
        ("IM, rounded 2.33 x 0.587", im_spec), ("IM, simulated 99% quantile", im_sim),
        ("IM, full repricing, Acme up", im_up), ("IM, full repricing, Acme down", im_dn),
        ("survival annuity (1-e^-lam T)/lam", annuity(LAM, T)),
        ("1 MVA closed form", mva1), ("2 MVA monthly integrated profile", mva2),
        ("3 MVA simulated", mva3), ("  standard error", se3),
        ("CVA (1-R) C0 PD", cva1), ("FVA s_F C0 annuity", fva1),
        ("MVA / CVA", mva1 / cva1), ("MVA / FVA", mva1 / fva1),
        ("hazard where CVA = MVA, algebra", lam_star), ("  by bisection", lam_bis),
        ("funding spread where FVA = MVA", sf_star),
        ("tail beyond IM, E[(X-IM)+]", tail), ("  by integration", tail_int),
        ("CVA with VM and IM held", cva_coll),
        ("wrong: no survival weight", S_IM * im_0 * T),
        ("wrong: margin discounted twice", S_IM * im_0 * annuity(LAM + RATE, T)),
        ("wrong: one-day horizon", mva1 * (1.0f64 / 10.0).sqrt()),
        ("wrong: whole 5.5% funding rate", (RATE + S_IM) * im_0 * annuity(LAM, T)),
        ("try: spread 100 bp", mva(z, T, LAM, 0.01)), ("try: hazard 10%", mva(z, T, 0.10, S_IM)),
    ];
    for (name, v) in &rows { println!("{:<36}{:12.6}", name, v); }
    println!();
    let ts = [0.0, 0.25, 0.5, 0.75, 1.0];
    let prof: Vec<f64> = ts.iter().map(|&t| deim(z, t)).collect();
    let line = |v: Vec<f64>| v.iter().map(|x| format!("{:6.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, years       {}", line(ts.to_vec()));
    println!("chart, E[IM]       {}", line(ts.iter().zip(&prof).map(|(t, p)| (RATE * t).exp() * p).collect()));
    println!("chart, D E[IM]     {}", line(prof.clone()));
    println!("maturity   IM0    C0      MVA      FVA      CVA   MVA/CVA");
    for tm in [1.0, 2.0, 3.0, 5.0, 10.0] {
        println!("{:6.0} {:6.3} {:6.3} {:8.5} {:8.5} {:8.5} {:7.3}", tm, im0(z, tm), call(S, tm),
                 mva(z, tm, LAM, S_IM), fva(tm, LAM), cva(tm, LAM), mva(z, tm, LAM, S_IM) / cva(tm, LAM));
    }
    println!("chart, MVA cents by maturity {}", [1.0, 2.0, 3.0, 5.0, 10.0].iter()
             .map(|&tm| format!("{:.2}", 100.0 * mva(z, tm, LAM, S_IM))).collect::<Vec<_>>().join(" "));
    println!("bars, cents: CVA MVA uncollateralised, CVA MVA collateralised {}",
             [cva1, mva1, cva_coll, mva1].iter().map(|v| format!("{:.3}", 100.0 * v)).collect::<Vec<_>>().join(" "));

    assert!((c0 - 9.227005508154).abs() < 1e-9, "own normal CDF reproduces the house call");
    assert!((mva2 - mva1).abs() < 1e-6, "monthly integrated margin profile lands on the closed form");
    assert!((mva3 - mva1).abs() < 4.0 * se3, "simulation within four standard errors");
    assert!((im_sim - im_0).abs() < 0.06, "simulated 99% quantile of the ten-day P&L near z x sd");
    assert!((lam_bis - lam_star).abs() < 1e-9, "bisection finds the algebraic crossover");
    assert!((tail_int - tail).abs() < 1e-7, "tail beyond the margin: formula vs integral");
    println!("ALL CHECKS PASS");
}
