// Recovery assumptions -- the same check as the Python, in Rust.  No crates.
// Northwind five-year CDS quoted at 300 bp a year: premiums at each quarter end,
// protection paid at default, flat hazard, r = 5% continuous.  Each assumed
// recovery is turned into a hazard three ways: the closed-form par equation,
// legs built by brute force (a quarterly sum and Simpson's rule), and a
// simulation of default times with a hand-written random number generator.
const S: f64 = 0.03; const R_: f64 = 0.05; const DQ: f64 = 0.25;       // quote, rate, quarter
const T: f64 = 5.0; const M: f64 = 10_000_000.0;                        // years, notional

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn par(lam: f64, rec: f64) -> f64 {                // road 1: s = (1 - R) lam F
    let x = (R_ + lam) * DQ;
    (1.0 - rec) * lam * (x.exp() - 1.0) / x
}

fn annuity(lam: f64) -> f64 {                      // road 2: premium leg, quarter by quarter
    (1..21).map(|j| DQ * (-(R_ + lam) * DQ * j as f64).exp()).sum()
}

fn protection(lam: f64, rec: f64) -> f64 {         // road 2: Simpson's rule
    let n = 4000;
    let f = |t: f64| (1.0 - rec) * lam * (-(R_ + lam) * t).exp();
    let h = T / n as f64;
    let inner: f64 = (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h)).sum();
    h / 3.0 * (f(0.0) + f(T) + inner)
}

fn secant<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {
    for _ in 0..60 {
        let (fa, fb) = (f(a), f(b));
        if fb == fa { break }
        let c = b - fb * (b - a) / (fb - fa); a = b; b = c;
    }
    b
}

fn closed(lam: f64, rec: f64) -> [f64; 3] {        // bond prices per $1: face, treasury, market value
    let k = R_ + lam;
    [(-k * T).exp() + rec * lam * (1.0 - (-k * T).exp()) / k,
     (-R_ * T).exp() * (rec + (1.0 - rec) * (-lam * T).exp()),
     (-(R_ + lam * (1.0 - rec)) * T).exp()]
}

fn backward(lam: f64, rec: f64) -> [f64; 3] {      // road 2: step back from maturity
    let n = 20000;
    let (h, k) = (T / n as f64, R_ + lam);
    let (stay, hit) = ((-k * h).exp(), lam / k * (1.0 - (-k * h).exp()));
    let (mut f, mut t, mut m) = (1.0, 1.0, 1.0);
    for i in (0..n).rev() {
        let mid = (i as f64 + 0.5) * h;
        f = stay * f + hit * rec;
        t = stay * t + hit * rec * (-R_ * (T - mid)).exp();
        m = stay * m + hit * rec * m;
    }
    [f, t, m]
}

fn curve(lam: f64) -> [f64; 3] { closed(lam, 1.0 - 0.03 / lam) }

fn commas(x: f64) -> String {
    let d = format!("{:.0}", x);
    let mut out = String::new();
    for (i, c) in d.chars().enumerate() {
        if i > 0 && (d.len() - i) % 3 == 0 { out.push(',') }
        out.push(c);
    }
    out
}

fn row(label: &str, v: &[f64], p: usize) -> String {
    format!("{:<23}", label) + &v.iter().map(|x| format!("{:6.*}", p, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut state: u64 = 20260928;                 // road 3: a 64-bit linear congruential generator
    let u: Vec<f64> = (0..200_000).map(|_| {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0
    }).collect();
    let mut disc = vec![0.0];
    for j in 1..21 { let last = disc[j - 1]; disc.push(last + DQ * (-R_ * DQ * j as f64).exp()) }
    let simulate = |lam: f64, rec: f64| {
        let (mut prot, mut prem, mut died) = (0.0, 0.0, 0.0);
        for &x in &u {
            let tau = -x.ln() / lam;
            if tau < T { died += 1.0; prot += (1.0 - rec) * (-R_ * tau).exp(); prem += disc[(tau / DQ) as usize] }
            else { prem += disc[20] }
        }
        (died / u.len() as f64, 1e4 * prot / prem)
    };

    println!("Northwind 5y CDS at 300 bp; r = 5%; quarterly premiums; notional $10m; premium ${} a year", commas(S * M));
    println!("R     hazard:formula  hazard:legs  triangle  5y default  simulated  sim spread bp  loss $m");
    let mut rows = Vec::new();
    for rec in [0.0, 0.4, 0.7] {
        let lam = bisect(|l| par(l, rec) - S, 0.0, 1.0);
        let lam2 = secant(|l| protection(l, rec) - S * annuity(l), 0.01, 0.2);
        let (pd, sim) = simulate(lam, rec);
        println!("{:<5} {:14.6} {:12.6} {:9.4} {:11.4} {:10.4} {:14.1} {:8.1}", format!("{:.0}%", 100.0 * rec),
                 lam, lam2, S / (1.0 - rec), 1.0 - (-lam * T).exp(), pd, sim, (1.0 - rec) * M / 1e6);
        rows.push((rec, lam, lam2, 1.0 - (-lam * T).exp(), pd, sim));
    }
    println!("house check, hazard 2%, R 40%: par {:.2} bp  legs {:.2} bp  annuity {:.4}", 1e4 * par(0.02, 0.4), 1e4 * protection(0.02, 0.4) / annuity(0.02), annuity(0.02));
    let seed = S / 0.6;
    let f1 = ((R_ + seed) * DQ).exp_m1() / ((R_ + seed) * DQ);
    let h1 = seed / f1;
    let f2 = ((R_ + h1) * DQ).exp_m1() / ((R_ + h1) * DQ);
    println!("by hand, R 40%: seed {:.6}  F {:.6}  hazard {:.6}  F again {:.6}  hazard {:.6}", seed, f1, h1, f2, seed / f2);
    println!("{:<23}{}", "chart, recovery %", (0..10).map(|i| format!("{:6}", 10 * i)).collect::<Vec<_>>().join(" "));
    let dated: Vec<f64> = (0..10).map(|i| 100.0 * bisect(|l| par(l, i as f64 / 10.0) - S, 0.0, 5.0)).collect();
    let tri: Vec<f64> = (0..10).map(|i| 100.0 * S / (1.0 - i as f64 / 10.0)).collect();
    println!("{}", row("chart, hazard % dated", &dated, 2));
    println!("{}", row("chart, hazard % triang", &tri, 2));
    let up: Vec<f64> = rows.iter().map(|r| (S - 0.01) * annuity(r.1) * M).collect();
    println!("upfront at a 100 bp coupon, $: R 0% {}  R 40% {}  R 70% {}", commas(up[0]), commas(up[1]), commas(up[2]));

    for lam in [0.05, 0.025] {
        println!("known hazard {:.3}: triangle R {:.4}  dated R {:.4}  legs R {:.4}", lam, 1.0 - S / lam,
                 1.0 - S / par(lam, 0.0), 1.0 - S * annuity(lam) / protection(lam, 0.0));
    }

    let (lam0, r0) = (0.05, 0.40);
    let (c, b) = (closed(lam0, r0), backward(lam0, r0));
    println!("bond at hazard 5%, R 40%, per $100: face / treasury / market value");
    println!("  closed form    {:.4}  {:.4}  {:.4}", 100.0 * c[0], 100.0 * c[1], 100.0 * c[2]);
    println!("  backward steps {:.4}  {:.4}  {:.4}", 100.0 * b[0], 100.0 * b[1], 100.0 * b[2]);
    let v2 = (-(R_ + lam0 * (1.0 - r0)) * 3.0).exp();
    println!("paid on default at year 2: face {:.2}  treasury {:.2}  market value {:.2}",
             100.0 * r0, 100.0 * r0 * (-R_ * 3.0).exp(), 100.0 * r0 * v2);
    println!("{:<23}{}", "chart, hazard %", (3..16).step_by(2).map(|h| format!("{:6}", h)).collect::<Vec<_>>().join(" "));
    for (j, name) in ["face", "treasury", "market value"].iter().enumerate() {
        let v: Vec<f64> = (3..16).step_by(2).map(|h| 100.0 * curve(h as f64 / 100.0)[j]).collect();
        println!("{}", row(&format!("chart, {}", name), &v, 2));
    }
    let p0 = c[0];
    let prices = [p0, p0 - 0.005, p0 + 0.005];
    let fits: Vec<f64> = prices.iter().map(|&p| bisect(|l| curve(l)[0] - p, 0.03, 5.0)).collect();
    for (p, l) in prices.iter().zip(&fits) {
        println!("joint fit, price {:.2}: hazard {:.4}  recovery {:.4}", 100.0 * p, l, 1.0 - 0.03 / l);
    }
    let k = R_ + lam0;
    let slope = (R_ + 0.03) * (1.0 - (1.0 + k * T) * (-k * T).exp()) / (k * k);
    println!("face price slope along the CDS curve at 5%: {:.4} per unit hazard", slope);

    println!("wrong: triangle at R 70%: hazard {:.4}  5y default {:.4}", S / 0.3, 1.0 - (-T * S / 0.3).exp());
    println!("wrong: spread read as the hazard: 5y default {:.4}", 1.0 - (-T * S).exp());
    println!("wrong: face bond priced with treasury rule: {:.2} not {:.2}", 100.0 * c[1], 100.0 * p0);

    for &(_, lam, lam2, pd, pds, sim) in &rows {
        assert!((lam - lam2).abs() < 1e-9, "closed-form hazard vs brute-force legs");
        assert!((pd - pds).abs() < 0.005 && (sim - 300.0).abs() < 6.0, "simulation vs formula");
    }
    assert!((0..3).all(|j| (c[j] - b[j]).abs() < 1e-5), "bond prices, two roads");
    assert!((fits[0] - lam0).abs() < 1e-9 && ((1.0 - 0.03 / fits[0]) - r0).abs() < 1e-8, "joint fit returns the pair");
    let flat: Vec<f64> = [3.0, 5.0, 10.0, 15.0].iter().map(|h| backward(h / 100.0, 1.0 - 0.03 / (h / 100.0))[2]).collect();
    let spread = flat.iter().cloned().fold(f64::MIN, f64::max) - flat.iter().cloned().fold(f64::MAX, f64::min);
    assert!(spread < 1e-5 && (curve(0.15)[0] - curve(0.05)[0]).abs() > 0.03, "only face recovery separates");
    assert!((par(0.02, 0.4) - protection(0.02, 0.4) / annuity(0.02)).abs() < 1e-9 && (1e4 * par(0.02, 0.4) - 121.06).abs() < 0.005 && (annuity(0.02) - 4.1819).abs() < 5e-5, "house contract: 121.06 bp, annuity 4.1819");
    assert!([0.05, 0.025].iter().all(|&l| (S / par(l, 0.0) - S * annuity(l) / protection(l, 0.0)).abs() < 1e-9), "known-hazard recovery, two roads");
    assert!(((curve(lam0 + 1e-5)[0] - curve(lam0 - 1e-5)[0]) / 2e-5 - slope).abs() < 1e-6, "slope formula vs finite difference");
    println!("ALL CHECKS PASS");
}
