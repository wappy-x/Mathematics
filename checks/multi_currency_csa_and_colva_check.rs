// Multi-currency CSA and ColVA -- the check behind the card.  std only, no crates.
// A 5-year USD swap whose CSA lets the poster deliver USD cash (earns SOFR) or EUR cash
// (earns ESTR, worth SOFR + s in dollars).  The spread s is normal: today 10 bp, vol 15 bp a year.
// Road 1: Bachelier on each instant, integrated by Simpson.  Road 2: quadrature over the bell
// curve.  Road 3: Monte Carlo spread paths.  Same numbers and labels as the Python check.
use std::f64::consts::PI;

const SOFR: f64 = 0.04; const ESTR: f64 = 0.02; const Y: f64 = 0.019;
const SIG: f64 = 0.0015; const NOT: f64 = 100e6; const K: f64 = 0.05; const T: usize = 5;
const BP: f64 = 1e-4;

fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 { // normal CDF, Hart's rational approximation (double precision)
    let a = x.abs(); let e = (-a * a / 2.0).exp();
    let c = if a > 37.0 { 0.0 } else if a < 7.07106781186547 {
        let p = (((((0.0352624965998911 * a + 0.700383064443688) * a + 6.37396220353165) * a + 33.912866078383) * a + 112.079291497871) * a + 221.213596169931) * a + 220.206867912376;
        let s = ((((((0.0883883476483184 * a + 1.75566716318264) * a + 16.064177579207) * a + 86.7807322029461) * a + 296.564248779674) * a + 637.333633378831) * a + 793.826512519948) * a + 440.413735824752;
        e * p / s
    } else { e / (a + 1.0 / (a + 2.0 / (a + 3.0 / (a + 4.0 / (a + 0.65))))) / 2.506628274631 };
    if x > 0.0 { 1.0 - c } else { c }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + i as f64 * h);
    }
    h / 3.0 * s
}
// Bachelier: E[max(s_t, 0)], the switch option's rate at date t
fn call(t: f64, s0: f64, sig: f64) -> f64 {
    let sd = sig * t.sqrt();
    if sd == 0.0 { return s0.max(0.0); }
    s0 * ncdf(s0 / sd) + sd * phi(s0 / sd)
}
// integral of the switch rate from 0 to t: the CTD curve's extra yield,
// over w = sqrt(u), which smooths the sqrt(u) kink at the start: du = 2w dw
fn mm(t: f64, s0: f64, sig: f64) -> f64 {
    if t > 0.0 { simpson(|w| 2.0 * w * call(w * w, s0, sig), 0.0, t.sqrt(), 2000) } else { 0.0 }
}
fn d(i: usize) -> f64 { (-SOFR * i as f64).exp() }
fn cflow() -> f64 { NOT * (K - (SOFR.exp() - 1.0)) }
fn value<F: Fn(usize) -> f64>(extra: F) -> f64 {
    let mut s = 0.0;
    for i in 1..=T { s += cflow() * d(i) * (-extra(i)).exp(); }
    s
}
fn colva(s0: f64, sig: f64) -> f64 { value(|i| mm(i as f64, s0, sig)) - value(|_| 0.0) }

struct Rng(u64);
impl Rng { // xorshift64*, top 53 bits, never 0
    fn unif(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        ((self.0.wrapping_mul(2685821657736338717) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let s0 = ESTR - Y; let g = SOFR.exp() - 1.0; let cf = cflow();
    let m = |t: f64| mm(t, s0, SIG);
    let c = |t: f64| call(t, s0, SIG);
    println!("EUR collateral in dollars: ESTR + (SOFR - implied) {:.4}%", 100.0 * (ESTR + SOFR - Y));
    println!("  FX swap pickup, SOFR - implied euro rate, % {:.4}", 100.0 * (SOFR - Y));
    println!("spread over SOFR today, bp                    {:.2}", s0 / BP);
    println!("floating forecast g, %                        {:.4}", 100.0 * g);
    println!("net cash flow a year, dollars                 {:.2}", cf);

    // One period: the poster of collateral against the first cash flow picks the higher rate
    let usd1 = cf * (-SOFR).exp(); let eur1 = cf * (-(SOFR + s0)).exp();
    println!("first cash flow valued with USD collateral    {:.2}", usd1);
    println!("first cash flow valued with EUR collateral    {:.2}", eur1);
    println!("  poster's saving by delivering EUR           {:.2}", usd1 - eur1);

    println!("sigma sqrt(t), bp, and d at 1 and 5 years    {:.2} {:.4}  {:.2} {:.4}", SIG / BP, s0 / SIG, SIG * 5f64.sqrt() / BP, s0 / (SIG * 5f64.sqrt()));
    // Road 2: E[max(s_t, 0)] by Simpson over the spread's bell curve, no Bachelier formula
    println!("year  switch rate bp: Bachelier  quadrature  intrinsic   time value");
    for t in 1..=T {
        let tf = t as f64; let sd = SIG * tf.sqrt();
        let q = simpson(|x| x * phi((x - s0) / sd) / sd, 0.0, s0 + 12.0 * sd, 4000);
        assert!((q - c(tf)).abs() < 1e-12);
        println!("  {}       {:10.4}  {:10.4}  {:9.4}  {:9.4}", t, c(tf) / BP, q / BP, s0.max(0.0) / BP, (c(tf) - s0.max(0.0)) / BP);
    }

    // Road 3: Monte Carlo spread paths, weekly, antithetic pairs
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let steps = 52usize; let pairs = 10000usize; let dt = 1.0 / steps as f64; let sq = SIG * dt.sqrt();
    let mut sumf = [0.0f64; T + 1]; let mut sumf2 = [0.0f64; T + 1];
    let (mut sum_i, mut sum_i2, mut sum_e) = (0.0f64, 0.0f64, 0.0f64);
    let mut sum_y = [0.0f64; T + 1]; let mut sum_y2 = [0.0f64; T + 1]; // each path's extra yield I to year i, and I^2
    for _ in 0..pairs {
        let (mut a, mut b) = (s0, s0);
        let (mut ia, mut ib, mut ea, mut eb) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
        for k in 1..=steps * T {
            let u1 = rng.unif(); let u2 = rng.unif();
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            let (a2, b2) = (a + sq * z, b - sq * z);
            ia += (a.max(0.0) + a2.max(0.0)) * dt / 2.0; ib += (b.max(0.0) + b2.max(0.0)) * dt / 2.0;
            ea += (a + a2) * dt / 2.0; eb += (b + b2) * dt / 2.0;
            a = a2; b = b2;
            if k % steps == 0 {
                let i = k / steps; let f = ((-ia).exp() + (-ib).exp()) / 2.0;
                sumf[i] += f; sumf2[i] += f * f; sum_y[i] += ia + ib; sum_y2[i] += ia * ia + ib * ib;
            }
        }
        let x = (ia + ib) / 2.0; sum_i += x; sum_i2 += x * x; sum_e += ((-ea).exp() + (-eb).exp()) / 2.0;
    }
    let pf = pairs as f64;
    let mut mc = [0.0f64; T + 1]; let mut se = [0.0f64; T + 1];
    for i in 1..=T { mc[i] = sumf[i] / pf; se[i] = ((sumf2[i] / pf - mc[i] * mc[i]) / pf).sqrt(); }
    let m_i = sum_i / pf; let se_i = ((sum_i2 / pf - m_i * m_i) / pf).sqrt();
    let mut cvx = [0.0f64; T + 1];
    for i in 1..=T { cvx[i] = (-m(i as f64)).exp() * (sum_y2[i] / (2.0 * pf) - (sum_y[i] / (2.0 * pf)).powi(2)) / 2.0; }

    println!("year  period avg bp   D SOFR      D CTD      MC factor  first order  MC s.e.");
    for i in 1..=T {
        let f1 = (-m(i as f64)).exp();
        assert!((mc[i] - f1).abs() < 4.0 * se[i] + 2e-6); // convexity is about one standard error
        println!("  {}      {:7.4}   {:.8} {:.8}  {:.8} {:.8}  {:.8}", i, (m(i as f64) - m((i - 1) as f64)) / BP, d(i), d(i) * f1, mc[i], f1, se[i]);
    }
    println!("convexity Var(I)/2 x factor, 5 years, MC     {:.8}", cvx[T]);
    println!("5-year extra yield, integral, bp-years        {:.4}", m(T as f64) / BP);
    println!("  Monte Carlo average, s.e.                   {:.4}  {:.4}", m_i / BP, se_i / BP);
    assert!((m_i - m(T as f64)).abs() < 4.0 * se_i + 2e-7); // weekly trapezoid bias is tiny
    let eur_exact = (-s0 * T as f64 + SIG * SIG * 125.0 / 6.0).exp(); // EUR-only CSA, closed form
    println!("EUR-only factor at 5 years: closed, MC        {:.8}  {:.8}", eur_exact, sum_e / pf);
    assert!((sum_e / pf - eur_exact).abs() < 1e-5);

    let v_usd = value(|_| 0.0);
    let v_frozen = value(|i| s0.max(0.0) * i as f64);
    let v_ctd = value(|i| m(i as f64));
    let mut v_mc = 0.0; for i in 1..=T { v_mc += cf * d(i) * mc[i]; }
    let v_eur = value(|i| s0 * i as f64 - SIG * SIG * (i * i * i) as f64 / 6.0);
    let v_recv = value(|i| s0 * i as f64 - m(i as f64)); // wrong: receiver picks, so min(s, 0)
    let mut ann = 0.0; for i in 1..=T { ann += d(i); }
    let annuity_check = NOT * (K - g) * ann;
    assert!((annuity_check - v_usd).abs() < 1e-6);
    println!("swap, USD-only CSA (SOFR)                     {:.2}", v_usd);
    println!("swap, EUR-only CSA                            {:.2}", v_eur);
    println!("swap, choice frozen at today's spread         {:.2}", v_frozen);
    println!("swap, choice with the switch option           {:.2}", v_ctd);
    println!("  same, Monte Carlo factors                   {:.2}", v_mc);
    println!("ColVA = choice minus USD-only                 {:.2}", v_ctd - v_usd);
    println!("  intrinsic part (10 bp frozen)               {:.2}", v_frozen - v_usd);
    println!("  switch option part (time value)             {:.2}", v_ctd - v_frozen);
    println!("  ColVA as running bp on notional             {:.4}", (v_ctd - v_usd) / (NOT * ann) / BP);
    let mut cvx_usd = 0.0; for i in 1..=T { cvx_usd += cf * d(i) * cvx[i]; }
    println!("  convexity's effect on ColVA, MC Var(I)      {:.2}", cvx_usd);
    assert!(v_ctd < v_frozen && v_frozen < v_usd && v_ctd < v_eur);
    let mut tol = 50.0; for i in 1..=T { tol += 4.0 * cf.abs() * d(i) * se[i]; }
    assert!((v_mc - v_ctd).abs() < tol);
    println!("wrong: receiver chooses (min)                 {:.2}", v_recv);
    println!("  its ColVA                                   {:.2}", v_recv - v_usd);
    println!("wrong: compare raw ESTR with SOFR, ColVA      {:.2}", value(|i| (ESTR - SOFR).max(0.0) * i as f64) - v_usd);
    println!("wrong: 5-year rate for every year, ColVA      {:.2}", value(|i| c(T as f64) * i as f64) - v_usd);
    for (a, b) in [(0.0010, 0.0), (0.0010, 0.0030), (0.0, 0.0015), (-0.0010, 0.0015)] {
        println!("try: spread {:+3.0} bp, vol {:2.0} bp, ColVA          {:.2}", a / BP, b / BP, colva(a, b));
    }
    assert!((colva(0.0010, 0.0) - (v_frozen - v_usd)).abs() < 1e-6);
    assert!((mm(T as f64, 0.0, SIG) - SIG / (2.0 * PI).sqrt() * 2.0 / 3.0 * (T as f64).powf(1.5)).abs() < 1e-13); // spread 0: closed form
    println!("chart, switch rate bp at t = 0, 0.5, ..., 5:");
    let pts: Vec<String> = (0..11).map(|j| format!("{:.2}", c(j as f64 / 2.0) / BP)).collect();
    println!("  {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
