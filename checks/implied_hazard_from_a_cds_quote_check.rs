// Implied hazard from one CDS quote -- the same check as the Python, in Rust.
// Standard library only, no crates.  A festival promoter's five-year CDS is
// quoted at 300 bp, recovery 40%, riskless rate 5% (flat, continuous),
// premiums quarterly in arrears, no accrual on default.  Three roads to the
// flat hazard: bisection on legs priced by Simpson's rule, Newton on the
// closed form, and a Monte Carlo that reprices at the answer.
const QUOTE: f64 = 0.0300;
const REC: f64 = 0.40;
const RATE: f64 = 0.05;
const T: f64 = 5.0;
const DT: f64 = 0.25;

fn flat(t: f64) -> f64 { (-RATE * t).exp() }                 // discount factor D(t)
fn sloped(t: f64) -> f64 { (-(0.02 + 0.01 * t) * t).exp() }  // a rising curve

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn quarters(t: f64) -> usize { (t / DT).round() as usize }

fn annuity(lam: f64, d: fn(f64) -> f64, t: f64) -> f64 {    // risky annuity
    (1..=quarters(t)).map(|j| DT * d(j as f64 * DT) * (-lam * j as f64 * DT).exp()).sum()
}

fn protection(lam: f64, d: fn(f64) -> f64, t: f64, rec: f64) -> f64 {
    let f = |u: f64| lam * (-lam * u).exp() * d(u);
    (1.0 - rec) * (1..=quarters(t)).map(|j| simpson(&f, (j - 1) as f64 * DT, j as f64 * DT, 20)).sum::<f64>()
}

fn par(lam: f64, d: fn(f64) -> f64, t: f64, rec: f64) -> f64 { protection(lam, d, t, rec) / annuity(lam, d, t) }
fn par0(lam: f64) -> f64 { par(lam, flat, T, REC) }

fn g(x: f64) -> f64 { (x.exp() - 1.0) / x }                  // (e^x - 1)/x
fn par_closed(lam: f64, r: f64, rec: f64) -> f64 { (1.0 - rec) * lam * g((r + lam) * DT) }

fn bisect(quote: f64, mut lo: f64, mut hi: f64, halvings: usize, d: fn(f64) -> f64, t: f64) -> (f64, Vec<f64>) {
    let mut mids = Vec::new();
    for _ in 0..halvings {
        let m = (lo + hi) / 2.0;
        mids.push(m);
        if par(m, d, t, REC) > quote { hi = m; } else { lo = m; }
    }
    ((lo + hi) / 2.0, mids)
}

fn newton(quote: f64, mut lam: f64, r: f64, rec: f64) -> (f64, Vec<f64>) {
    let mut path = vec![lam];
    for _ in 0..50 {
        let x = (r + lam) * DT;
        let gp = (x * x.exp() - x.exp() + 1.0) / (x * x);
        let step = (par_closed(lam, r, rec) - quote) / ((1.0 - rec) * (g(x) + lam * DT * gp));
        lam -= step;
        path.push(lam);
        if step.abs() < 1e-15 { break; }
    }
    (lam, path)
}

struct Lcg(u64);
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let seed = QUOTE / (1.0 - REC);
    let (lam_b, mids) = bisect(QUOTE, 0.0, seed, 60, flat, T);
    let (lam_n, npath) = newton(QUOTE, seed, RATE, REC);
    let mut fp = vec![seed];
    for _ in 0..3 { let l = *fp.last().unwrap(); fp.push(QUOTE / ((1.0 - REC) * g((RATE + l) * DT))); }

    let mut rng = Lcg(20260928);
    let (n, nq) = (1000000usize, quarters(T));
    let mut cum = vec![0.0f64];
    for j in 1..=nq { let c = cum[j - 1] + DT * flat(j as f64 * DT); cum.push(c); }
    let (mut sp, mut sa, mut szz, mut spa, mut saa, mut dead) = (0.0, 0.0, 0.0, 0.0, 0.0, 0usize);
    for _ in 0..n {
        let tau = -rng.uniform().ln() / lam_b;
        let p = if tau <= T { (1.0 - REC) * flat(tau) } else { 0.0 };
        let a = cum[((tau / DT) as usize).min(nq)];
        sp += p; sa += a; spa += p * a; saa += a * a; szz += p * p;
        if tau <= T { dead += 1; }
    }
    let nf = n as f64;
    let (mp, ma) = (sp / nf, sa / nf);
    let s_mc = mp / ma;
    let var_z = (szz - 2.0 * s_mc * spa + s_mc * s_mc * saa) / nf - (mp - s_mc * ma).powi(2);
    let se_mc = (var_z / nf).sqrt() / ma;
    let pd5 = 1.0 - (-lam_b * T).exp();
    let se_pd = (pd5 * (1.0 - pd5) / nf).sqrt();
    let frac = dead as f64 / nf;

    println!("quote {:.0} bp, recovery {:.2}, r {:.2}, {:.0} years, quarterly", QUOTE * 1e4, REC, RATE, T);
    println!("seed s/(1-R)                    {:.6}", seed);
    println!("par spread at the seed, bp      {:.4}", par0(seed) * 1e4);
    println!("bisection on [0, seed]: step, midpoint, spread bp");
    for k in 0..12 { println!("  {:>2}  {:.6}  {:9.4}", k + 1, mids[k], par0(mids[k]) * 1e4); }
    println!("bracket width after 12 halvings {:.7}", seed / 4096.0);
    println!("road 1 bisection, 60 halvings   {:.10}", lam_b);
    println!("road 2 Newton from the seed     {:.10}  in {} steps", lam_n, npath.len() - 1);
    println!("  Newton path   {}", npath[..4].iter().map(|x| format!("{:.8}", x)).collect::<Vec<_>>().join("  "));
    println!("  fixed point   {}", fp.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join("  "));
    println!("  its x and g   {}", fp[..2].iter().map(|l| format!("{:.7} {:.7}", (RATE + l) * DT, g((RATE + l) * DT))).collect::<Vec<_>>().join("  "));
    println!("road 3 Monte Carlo spread, bp   {:.4}  (std error {:.4})", s_mc * 1e4, se_mc * 1e4);
    println!("  MC 5y default fraction        {:.6}  (std error {:.6})", frac, se_pd);
    println!("five-year default chance        {:.6}", pd5);
    println!("risky annuity                   {:.6}", annuity(lam_b, flat, T));
    println!("protection leg per $1           {:.6}", protection(lam_b, flat, T, REC));
    println!("on $10m: protection PV $        {:.2}", 1e7 * protection(lam_b, flat, T, REC));
    println!("house check, 2% hazard: par bp  {:.4}  annuity {:.4}", par0(0.02) * 1e4, annuity(0.02, flat, T));
    println!("maturity drops out: implied hazard at T = 1, 3, 10");
    for tt in [1.0f64, 3.0, 10.0] { println!("  T = {:>4.0}                     {:.10}", tt, bisect(QUOTE, 0.0, seed, 60, flat, tt).0); }
    let flat_up = (0..200).all(|i| par0(i as f64 * 0.005) < par0((i + 1) as f64 * 0.005));
    let slope_up = (0..200).all(|i| par(i as f64 * 0.005, sloped, T, REC) < par((i + 1) as f64 * 0.005, sloped, T, REC));
    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("spread rises on 0..100%: flat {}, sloped {}", yn(flat_up), yn(slope_up));
    println!("sloped curve implied hazard     {:.6}", bisect(QUOTE, 0.0, seed, 60, sloped, T).0);
    println!("R = 1: spread at 5% and 50%     {:.6}  {:.6}", par(0.05, flat, T, 1.0), par(0.5, flat, T, 1.0));
    println!("what breaks:");
    println!("  no recovery, hazard = s       {:.6}  5y default {:.6}", QUOTE, 1.0 - (-QUOTE * T).exp());
    println!("  triangle seed kept            {:.6}  5y default {:.6}", seed, 1.0 - (-seed * T).exp());
    println!("  default chance as 5 x hazard  {:.6}", T * lam_b);
    println!("try: R = 0.25, R = 0.60, 600 bp, r = 0");
    println!("  {:.6}  {:.6}  {:.6}  {:.6}", newton(QUOTE, QUOTE / 0.75, RATE, 0.25).0,
             newton(QUOTE, QUOTE / 0.4, RATE, 0.60).0, newton(0.06, 0.1, RATE, REC).0, newton(QUOTE, seed, 0.0, REC).0);
    println!("chart, hazard %   {}", (0..11).map(|i| format!("{:6}", i)).collect::<Vec<_>>().join(" "));
    println!("chart, par bp     {}", (0..11).map(|i| format!("{:6.2}", par0(i as f64 / 100.0) * 1e4)).collect::<Vec<_>>().join(" "));
    println!("chart, triangle bp{}", (0..11).map(|i| format!("{:6.2}", (1.0 - REC) * i as f64 / 100.0 * 1e4)).collect::<Vec<_>>().join(" "));

    assert!((lam_b - lam_n).abs() < 1e-10, "bisection on Simpson legs vs Newton on the closed form");
    assert!((s_mc - QUOTE).abs() < 4.0 * se_mc, "simulated defaults reprice the quote within 4 standard errors");
    assert!((frac - pd5).abs() < 4.0 * se_pd, "simulated default fraction vs 1 - e^(-lam T)");
    assert!((fp[3] - lam_n).abs() < 1e-6, "the by-hand fixed point lands on Newton's answer");
    assert!(flat_up, "par spread strictly rising in the hazard, flat curve");
    assert!(slope_up, "par spread strictly rising in the hazard, sloped curve");
    println!("ALL CHECKS PASS");
}
