// Forward CDS on Northwind: protection from year 1 to year 5, knocked out by an earlier default.
// Quarterly premiums paid while alive, protection paid at the default date. Rust std only.
const RATE: f64 = 0.05; // riskless rate
const DT: f64 = 0.25; // premium period
const NOTIONAL: f64 = 10_000_000.0;
const QUOTES: [(f64, f64); 3] = [(1.0, 0.0120), (3.0, 0.0200), (5.0, 0.0250)];
const T1: f64 = 1.0;
const T2: f64 = 5.0;
const K: f64 = 0.0250; // contract spread 250 bp
type Curve = Vec<(f64, f64, f64)>; // (start, end, flat hazard)

fn surv(t: f64, c: &Curve) -> f64 { // S(t) = exp(-area under the step hazard)
    (-c.iter().map(|&(a, b, h)| h * (t.min(b) - a).max(0.0)).sum::<f64>()).exp()
}
fn ann(a: f64, b: f64, c: &Curve) -> f64 { // premium-years paid on dates in (a, b]
    let (j0, j1) = ((a / DT).round() as i64 + 1, (b / DT).round() as i64);
    (j0..=j1).map(|j| { let t = j as f64 * DT; DT * (-RATE * t).exp() * surv(t, c) }).sum()
}
fn prot(a: f64, b: f64, c: &Curve, loss: f64) -> f64 { // closed form per piece
    let mut tot = 0.0;
    for &(p, q, h) in c {
        let (u0, u1) = (a.max(p), b.min(q));
        if u1 > u0 {
            let k = RATE + h;
            tot += loss * (-RATE * u0).exp() * surv(u0, c) * h / k * (1.0 - (-k * (u1 - u0)).exp());
        }
    }
    tot
}
fn prot_simpson(a: f64, b: f64, c: &Curve, loss: f64, n: usize) -> f64 { // road 2
    let mut tot = 0.0;
    for &(p, q, h) in c {
        let (u0, u1) = (a.max(p), b.min(q));
        if u1 <= u0 { continue; }
        let w = (u1 - u0) / n as f64;
        let f = |t: f64| loss * h * surv(t, c) * (-RATE * t).exp();
        let mut s = f(u0) + f(u1);
        for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(u0 + i as f64 * w); }
        tot += w / 3.0 * s;
    }
    tot
}
fn boot(quotes: &[(f64, f64)], loss: f64) -> Curve { // one flat piece per quote, bisection
    let (mut c, mut start): (Curve, f64) = (Vec::new(), 0.0);
    for &(t, s) in quotes {
        let (mut lo, mut hi) = (0.0, 5.0);
        for _ in 0..200 {
            let m = 0.5 * (lo + hi);
            let mut trial = c.clone(); trial.push((start, 1e9, m));
            if prot(0.0, t, &trial, loss) > s * ann(0.0, t, &trial) { hi = m } else { lo = m }
        }
        c.push((start, t, 0.5 * (lo + hi))); start = t;
    }
    let last = c.len() - 1; c[last].1 = 1e9; // last piece carried on
    c
}
fn fwd(a: f64, b: f64, c: &Curve, loss: f64) -> f64 {
    (prot(0.0, b, c, loss) - prot(0.0, a, c, loss)) / (ann(0.0, b, c) - ann(0.0, a, c))
}
fn fwd_value(c: &Curve, loss: f64, k: f64) -> f64 { // long T2 protection minus long T1 protection
    ((prot(0.0, T2, c, loss) - k * ann(0.0, T2, c)) - (prot(0.0, T1, c, loss) - k * ann(0.0, T1, c))) * NOTIONAL
}
struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn main() {
    let l = 0.60;
    let cv = boot(&QUOTES, l);
    let (a1, a2, p1, p2) = (ann(0.0, T1, &cv), ann(0.0, T2, &cv), prot(0.0, T1, &cv, l), prot(0.0, T2, &cv, l));
    let (af, pf) = (a2 - a1, p2 - p1);
    let f1 = pf / af;
    println!("Northwind: r 0.05, recovery 0.40, quarterly premiums, quotes 120/200/250 bp; forward window 1y to 5y");
    println!("curve: hazards {:.6} {:.6} {:.6}  S(1) {:.6}  S(5) {:.6}", cv[0].2, cv[1].2, cv[2].2, surv(1.0, &cv), surv(5.0, &cv));
    println!("spot legs: A(1) {:.6}  P(1) {:.6}  A(5) {:.6}  P(5) {:.6}", a1, p1, a2, p2);
    println!("road 1, legs subtracted: forward annuity {:.6}  forward protection {:.6}  forward spread {:.4} bp", af, pf, f1 * 1e4);
    let pf2 = prot_simpson(T1, T2, &cv, l, 2000);
    let f2 = pf2 / ann(T1, T2, &cv);
    println!("road 2, window priced directly (Simpson): forward protection {:.6}  forward spread {:.4} bp", pf2, f2 * 1e4);
    let (s1, s2) = (QUOTES[0].1, QUOTES[2].1);
    let f3 = s2 + (s2 - s1) * a1 / af;
    println!("road 3, annuity-weighted quotes: 250 + 130 x {:.6} = {:.4} bp", a1 / af, f3 * 1e4);
    // road 4: Monte Carlo default dates; a default before year 1 cancels the forward (both legs zero)
    let mut rng = Lcg(20260928);
    let paths = 400_000usize;
    let (mut sp, mut sa, mut spp, mut saa, mut spa, mut early) = (0.0, 0.0, 0.0, 0.0, 0.0, 0usize);
    for _ in 0..paths {
        let (mut e, mut tau) = (-rng.unif().ln(), 1e9);
        for &(a, b, h) in &cv {
            if e <= h * (b - a) { tau = a + e / h; break; }
            e -= h * (b - a);
        }
        if tau <= T1 { early += 1; continue; }
        let pr = if tau <= T2 { l * (-RATE * tau).exp() } else { 0.0 };
        let an: f64 = (5..21).filter(|&j| j as f64 * DT < tau).map(|j| DT * (-RATE * j as f64 * DT).exp()).sum();
        sp += pr; sa += an; spp += pr * pr; saa += an * an; spa += pr * an;
    }
    let n = paths as f64;
    let (mp, ma) = (sp / n, sa / n);
    let f4 = mp / ma;
    let var = (spp / n - mp * mp) - 2.0 * f4 * (spa / n - mp * ma) + f4 * f4 * (saa / n - ma * ma);
    let se = (var / n).sqrt() / ma;
    println!("road 4, Monte Carlo {} default dates: forward spread {:.2} bp (standard error {:.2})  knocked out {:.4}", paths, f4 * 1e4, se * 1e4, early as f64 / n);
    println!("  chance of default before year 1, 1 - S(1) = {:.4}", 1.0 - surv(1.0, &cv));
    let w = (-RATE * T1).exp() * surv(T1, &cv);
    println!("knock-out: D(1) {:.6}  weight D(1)S(1) {:.6}  annuity at year 1 if alive {:.6}  protection {:.6}  spread {:.4} bp", (-RATE * T1).exp(), w, af / w, pf / w, pf / af * 1e4);
    let avg = (2.0 * cv[1].2 + 2.0 * cv[2].2) / 4.0;
    println!("triangle on the window's average hazard: 0.60 x {:.6} = {:.2} bp", avg, l * avg * 1e4);
    let flat: Curve = vec![(0.0, 1e9, 0.02)];
    let (fs, ff) = (prot(0.0, 5.0, &flat, l) / ann(0.0, 5.0, &flat), fwd(1.0, 5.0, &flat, l));
    let kf = RATE + 0.02;
    let fc = l * 0.02 / kf * (1.0 - (-kf * DT).exp()) / (DT * (-kf * DT).exp());
    println!("flat 2% hazard: spot 5y {:.4} bp  forward 1y-5y {:.4} bp  tenor-free formula {:.4} bp", fs * 1e4, ff * 1e4, fc * 1e4);
    let v = fwd_value(&cv, l, K);
    println!("forward protection bought at 250 bp on $10m: value ${:.2}  = (F - K) x A_f x N ${:.2}", v, (f1 - K) * af * NOTIONAL);
    println!("  front-end protection P(1) x N, what a no-knock-out contract adds: ${:.2}", p1 * NOTIONAL);
    println!("risk, forward bought at 250 bp on $10m, each quote bumped 1 bp and the curve rebuilt");
    for (name, bmp) in [("1y", [1.0, 0.0, 0.0]), ("3y", [0.0, 1.0, 0.0]), ("5y", [0.0, 0.0, 1.0]), ("all", [1.0, 1.0, 1.0])] {
        let q: Vec<(f64, f64)> = QUOTES.iter().zip(bmp.iter()).map(|(&(t, s), d)| (t, s + 1e-4 * d)).collect();
        let cb = boot(&q, l);
        let dv = ((fwd_value(&cb, l, K) - v) * 100.0).round() / 100.0 + 0.0;
        println!("  {:>3} quote +1 bp: forward spread {:+.4} bp  value ${:+.2}", name, (fwd(T1, T2, &cb, l) - f1) * 1e4, dv);
    }
    println!("  annuity rule A_f x 1 bp x N: ${:.2}; default before year 1: value ${:+.2}", af * 1e-4 * NOTIONAL, -v);
    println!("what breaks");
    println!("  forward taken as the spot 5y quote: {:.2} bp; value at 250 bp read as $0.00", s2 * 1e4);
    println!("  time weights instead of annuity weights: (5 x 250 - 1 x 120) / 4 = {:.2} bp", (5.0 * s2 - s1) / 4.0 * 1e4);
    println!("  forward protection over the full A(5): {:.2} bp", pf / a2 * 1e4);
    println!("  today's protection over the year-1 annuity: {:.2} bp", pf / (af / w) * 1e4);
    println!("try");
    let ci = boot(&[(1.0, 0.0300), (3.0, 0.0250), (5.0, 0.0200)], l);
    println!("  inverted quotes 300/250/200: forward 1y-5y {:.2} bp", fwd(T1, T2, &ci, l) * 1e4);
    let c8 = boot(&QUOTES, 0.80);
    println!("  recovery 20%, same quotes: forward 1y-5y {:.2} bp", fwd(T1, T2, &c8, 0.80) * 1e4);
    let starts = [0.0, 1.0, 2.0, 3.0, 4.0];
    println!("chart, forward start (years) {}", starts.iter().map(|t| format!("{:7}", *t as i64)).collect::<Vec<_>>().join(" "));
    println!("chart, forward to 5y (bp)    {}", starts.iter().map(|&t| format!("{:7.2}", fwd(t, 5.0, &cv, l) * 1e4)).collect::<Vec<_>>().join(" "));
    println!("chart, flat 2% forward (bp)  {}", starts.iter().map(|&t| format!("{:7.2}", fwd(t, 5.0, &flat, l) * 1e4)).collect::<Vec<_>>().join(" "));
    let spreads = [100, 150, 200, 250, 300, 350, 400, 450, 500];
    let mut vals = Vec::new();
    for &sb in &spreads { // year-1 value if alive: flat curve fitted to a 4y quote
        let (mut lo, mut hi) = (0.0, 1.0);
        for _ in 0..100 {
            let m = 0.5 * (lo + hi);
            let cm: Curve = vec![(0.0, 1e9, m)];
            if prot(0.0, 4.0, &cm, l) > sb as f64 * 1e-4 * ann(0.0, 4.0, &cm) { hi = m } else { lo = m }
        }
        let cm: Curve = vec![(0.0, 1e9, 0.5 * (lo + hi))];
        vals.push((sb as f64 * 1e-4 - f1) * ann(0.0, 4.0, &cm) * NOTIONAL / 1000.0);
    }
    println!("chart, 4y spread at year 1   {}", spreads.iter().map(|s| format!("{:7}", s)).collect::<Vec<_>>().join(" "));
    println!("chart, value at year 1 ($k)  {}", vals.iter().map(|v| format!("{:7.2}", v)).collect::<Vec<_>>().join(" "));
    assert!((f2 - f1).abs() < 1e-9, "direct Simpson forward must match the subtracted legs");
    assert!((f3 - f1).abs() < 1e-9, "annuity-weighted quotes must match the forward legs");
    assert!((f4 - f1).abs() < 4.0 * se, "Monte Carlo with knock-out within four standard errors");
    assert!((v - (K - s1) * a1 * NOTIONAL).abs() < 1e-4, "at K = s2 the forward is worth the one-year leg alone");
    assert!((ff - fc).abs() < 1e-12 && (fs - fc).abs() < 1e-12, "flat curve: forward and spot equal the tenor-free formula");
    assert!(f1 > s2 && fwd(T1, T2, &ci, l) < QUOTES[2].1 - 0.0050, "rising curve lifts the forward, falling lowers it");
    println!("ALL CHECKS PASS");
}
