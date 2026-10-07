// Stochastic dominance -- the same check as the Python, in Rust.  No crates.
// Three funds, one year, returns in percent, even odds.  The normal CDF, the
// integrator and the random numbers are written out below.
use std::f64::consts::PI;

type Fund = Vec<(f64, f64)>; // (return in percent, probability)
const KNOTS: [f64; 4] = [-2.0, 2.0, 6.0, 8.0];

fn mean(f: &Fund) -> f64 { f.iter().map(|&(x, p)| p * x).sum() }
fn spread(f: &Fund) -> f64 { let m = mean(f); f.iter().map(|&(x, p)| p * (x - m).powi(2)).sum::<f64>().sqrt() }
fn cdf(f: &Fund, t: f64) -> f64 { f.iter().filter(|&&(x, _)| x <= t).map(|&(_, p)| p).fold(0.0, |s, p| s + p) }
fn shortfall(f: &Fund, k: f64) -> f64 { f.iter().map(|&(x, p)| p * (k - x).max(0.0)).sum() } // road 1
fn area(f: &Fund, k: f64) -> f64 {                                   // road 2: area under the CDF
    let (lo, h) = (-10.0, 0.01);
    let n = ((k - lo) / h).round() as usize;
    (0..n).map(|i| cdf(f, lo + (i as f64 + 0.5) * h)).sum::<f64>() * h
}
fn quantile(f: &Fund, q: f64) -> f64 {
    f.iter().filter(|&&(x, _)| cdf(f, x) >= q).map(|&(x, _)| x).fold(f64::INFINITY, f64::min)
}
struct Lcg(u64);                                                     // 64-bit LCG, top 53 bits -> [0, 1)
impl Lcg {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / 9007199254740992.0
    }
}
fn search(a: &Fund, b: &Fund, concave: bool) -> usize {             // road 3: random utilities
    let mut r = Lcg(7);
    let mut bad = 0;
    for _ in 0..2000 {
        let mut s = [r.next(), r.next(), r.next()];                  // slopes on -2..2, 2..6, 6..8
        if concave { s.sort_by(|x, y| y.partial_cmp(x).unwrap()); }  // slopes that only fall
        let u = [0.0, 4.0 * s[0], 4.0 * s[0] + 4.0 * s[1], 4.0 * s[0] + 4.0 * s[1] + 2.0 * s[2]];
        let score = |f: &Fund| -> f64 {
            f.iter().map(|&(x, p)| p * u[KNOTS.iter().position(|&k| k == x).unwrap()]).sum()
        };
        if score(a) < score(b) - 1e-12 { bad += 1; }
    }
    bad
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no " } }
fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum();
    (g(a) + g(b) + inner) * h / 3.0
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_simpson(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 2000) }
fn n_series(x: f64) -> f64 {                                         // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut j) = (x, x, 1.0);
    while term.abs() > 1e-17 { term *= x * x / (2.0 * j + 1.0); total += term; j += 1.0; }
    0.5 + phi(x) * total
}
const MU: f64 = 8.0;
const SIG: f64 = 15.0;
const DEP: f64 = 4.0;
fn fund_short(k: f64, mu: f64, sig: f64) -> f64 { let z = (k - mu) / sig; sig * phi(z) + (k - mu) * n_series(z) }
fn fund_short_int(k: f64) -> f64 { simpson(|x| (k - x) * phi((x - MU) / SIG) / SIG, MU - 12.0 * SIG, k, 20000) }

fn main() {
    let names = ["Steady", "Swing", "Upside"];
    let funds: Vec<Fund> = vec![vec![(2.0, 1.0)], vec![(-2.0, 0.5), (6.0, 0.5)], vec![(-2.0, 0.5), (8.0, 0.5)]];
    let pairs = [(2, 1), (1, 2), (0, 1), (1, 0), (0, 2), (2, 0)];
    println!("fund     outcomes        mean  spread");
    for (n, f) in names.iter().zip(&funds) {
        let outs: Vec<String> = f.iter().map(|&(x, _)| format!("{:+.0}", x)).collect();
        println!("{:<8} {:<14}{:6.2}{:8.2}", n, outs.join(" or "), mean(f), spread(f));
    }
    let row = |xs: &[f64]| -> String { xs.iter().map(|v| format!("{:7.2}", v)).collect() };
    println!("CDF F(t) at t =          {}", KNOTS.iter().map(|t| format!("{:7.0}", t)).collect::<String>());
    for (n, f) in names.iter().zip(&funds) {
        println!("  {:<22}{}", n, row(&KNOTS.iter().map(|&t| cdf(f, t)).collect::<Vec<_>>()));
    }
    let ch: Vec<f64> = (0..8).map(|i| -4.0 + 2.0 * i as f64).collect();
    println!("shortfall P(k) at k =    {}", ch.iter().map(|k| format!("{:7.0}", k)).collect::<String>());
    let mut worst: f64 = 0.0;
    for (n, f) in names.iter().zip(&funds) {
        println!("  {:<22}{}", n, row(&ch.iter().map(|&k| shortfall(f, k)).collect::<Vec<_>>()));
        for &k in &ch { worst = worst.max((shortfall(f, k) - area(f, k)).abs()); }
    }
    println!("largest gap, E[(k-X)+] vs area under CDF   {:.12}", worst);
    assert!(worst < 1e-9, "shortfall must equal the area under the CDF");

    println!("pair               | 1st: CDF  quantile  increasing u bad | 2nd: shortfall  concave u bad");
    let mut verdicts = Vec::new();
    for &(a, b) in &pairs {
        let (fa, fb) = (&funds[a], &funds[b]);
        let c1 = KNOTS.iter().all(|&t| cdf(fa, t) <= cdf(fb, t));
        let q1 = (0..100).all(|i| { let q = (i as f64 + 0.5) / 100.0; quantile(fa, q) >= quantile(fb, q) });
        let s1 = search(fa, fb, false);
        let c2 = KNOTS.iter().all(|&k| shortfall(fa, k) <= shortfall(fb, k) + 1e-12);
        let s2 = search(fa, fb, true);
        verdicts.push((c1, c2));
        println!("{:<19}|      {}  {}       {:5} of 2000 |           {}  {:5} of 2000",
                 format!("{} over {}", names[a], names[b]), yn(c1), yn(q1), s1, yn(c2), s2);
        assert!(c1 == q1 && q1 == (s1 == 0), "three first-order roads must agree");
        assert!(c2 == (s2 == 0), "shortfall test and concave search must agree");
    }

    let beat: f64 = funds[1].iter().map(|&(x, p)| funds[2].iter().filter(|&&(y, _)| x > y).map(|&(_, q)| p * q).sum::<f64>()).sum();
    println!("independent draws: chance Swing ends above Upside {:.2}", beat);

    let wit: [(&str, fn(f64) -> f64); 4] = [
        ("linear, u(r) = r", |r| r), ("capped, u(r) = min(r, 2)", |r| r.min(2.0)),
        ("log wealth, ln(100 + r)", |r| (100.0 + r).ln()), ("bet, 1 if r > 2", |r| if r > 2.0 { 1.0 } else { 0.0 })];
    println!("witness utility            Steady    Swing   Upside");
    for (n, u) in wit.iter() {
        let vals: String = funds.iter().map(|f| format!("{:9.4}", f.iter().map(|&(x, p)| p * u(x)).sum::<f64>())).collect();
        println!("{:<25}{}", n, vals);
    }
    // Road 4, the identity of Why it works, Step 3, with u = ln(100 + r) on [a, b] = [-2, 8]
    for &(a, b) in &[(0usize, 1usize), (2, 0)] {
        let (fa, fb) = (&funds[a], &funds[b]);
        let lu = |f: &Fund| -> f64 { f.iter().map(|&(x, p)| p * (100.0 + x).ln()).sum() };
        let direct = lu(fa) - lu(fb);
        let ident = (mean(fa) - mean(fb)) / 108.0
            + simpson(|k| (shortfall(fb, k) - shortfall(fa, k)) / (100.0 + k).powi(2), -2.0, 8.0, 2000);
        println!("Eu({}) - Eu({}): direct {:.9}  identity {:.9}", names[a], names[b], direct, ident);
        assert!((direct - ident).abs() < 1e-9, "the Step 3 identity must match the direct average");
    }

    let z4 = (DEP - MU) / SIG;
    println!("house: z = (4 - 8) / 15 = {:.4}", z4);
    println!("house: chance fund ends below 4%: Simpson {:.6}  series {:.6}", n_simpson(z4), n_series(z4));
    for &k in &[4.0f64, 30.0] {
        println!("house: shortfall at {:4.0}  deposit {:7.4}  fund {:7.4}  by integral {:7.4}",
                 k, (k - DEP).max(0.0), fund_short(k, MU, SIG), fund_short_int(k));
        assert!((fund_short(k, MU, SIG) - fund_short_int(k)).abs() < 1e-8, "closed form vs integral");
    }
    assert!((n_simpson(z4) - n_series(z4)).abs() < 1e-12, "two roads to N(z)");
    println!("house: capped at 4, E min(fund, 4) = {:.4} vs deposit 4.0000", DEP - fund_short(DEP, MU, SIG));

    let (st, sw, up) = (&funds[0], &funds[1], &funds[2]);
    let mis = [("means only: Steady vs Swing", mean(st) - mean(sw)),
        ("spreads only: Upside minus Steady", spread(up) - spread(st)),
        ("one cutoff, k = 8: P_Upside - P_Steady", shortfall(up, 8.0) - shortfall(st, 8.0)),
        ("same, k = 2: P_Upside - P_Steady", shortfall(up, 2.0) - shortfall(st, 2.0)),
        ("one threshold, t = -2: F_Steady - F_Swing", cdf(st, -2.0) - cdf(sw, -2.0)),
        ("same, t = 2: F_Steady - F_Swing", cdf(st, 2.0) - cdf(sw, 2.0))];
    for (n, v) in mis.iter() { println!("wrong: {:<42}{:7.2}", n, v); }
    let sw7: Fund = vec![(-2.0, 0.5), (7.0, 0.5)];
    let up3: Fund = vec![(-3.0, 0.5), (8.0, 0.5)];
    println!("try: Swing -2 or +7, shortfall at 8: Steady {:.2}, Swing {:.2}", shortfall(st, 8.0), shortfall(&sw7, 8.0));
    println!("try: Upside -3 or +8, CDF at -3: Upside {:.2}, Swing {:.2}; shortfall at -2: Upside {:.2}, Swing {:.2}",
             cdf(&up3, -3.0), cdf(sw, -3.0), shortfall(&up3, -2.0), shortfall(sw, -2.0));
    println!("try: fund spread 1%, chance below 4% per million {:.3}, shortfall at 4 per million {:.3}",
             1e6 * n_series(-4.0), 1e6 * fund_short(4.0, 8.0, 1.0));
    assert!(verdicts == vec![(true, true), (false, false), (false, true), (false, false), (false, false), (false, false)]);
    println!("ALL CHECKS PASS");
}
