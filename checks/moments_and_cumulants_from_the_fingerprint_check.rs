// Moments and cumulants -- the same check as the Python file, in Rust, std only.
// 1,000 insured homes, money in thousands of dollars ($k).  Each home, in a
// year: no claim (0.95), a $2k leak (0.04) or a $20k fire (0.01).  Three roads
// to the cumulants of the yearly total S: add the one-home cumulants; read
// derivatives of the log-fingerprint at zero; and the exact law by convolution.
const N: usize = 1000;
const VALS: [f64; 3] = [0.0, 2.0, 20.0];
const PROBS: [f64; 3] = [0.95, 0.04, 0.01];

fn sum<I: Iterator<Item = f64>>(xs: I) -> f64 {   // compensated sum, as Python's sum()
    let (mut s, mut c) = (0.0_f64, 0.0_f64);
    for x in xs {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn pw(x: f64, k: f64) -> f64 { x.powf(k) }

fn cumulants_from_moments(m: [f64; 4]) -> [f64; 4] {
    let (m1, m2, m3, m4) = (m[0], m[1], m[2], m[3]);
    [m1, m2 - pw(m1, 2.0), m3 - 3.0 * m2 * m1 + 2.0 * pw(m1, 3.0),
     m4 - 4.0 * m3 * m1 - 3.0 * pw(m2, 2.0) + 12.0 * m2 * pw(m1, 2.0) - 6.0 * pw(m1, 4.0)]
}

fn law_of_total(p_leak: f64, p_fire: f64, n: usize) -> Vec<f64> {   // chances of S = 0, 2, 4, ... $k
    let p0 = 1.0 - p_leak - p_fire;
    let mut law = vec![1.0_f64];
    for _ in 0..n {                                                  // add one home at a time
        let mut new = vec![0.0_f64; law.len() + 10];
        for (j, &a) in law.iter().enumerate() {
            new[j] += p0 * a; new[j + 1] += p_leak * a; new[j + 10] += p_fire * a;
        }
        law = new;
    }
    law
}

fn central(law: &[f64]) -> (f64, f64, f64, f64) {                    // mean and central moments 2, 3, 4
    let m = sum(law.iter().enumerate().map(|(j, &p)| p * 2.0 * j as f64));
    let c = |k: f64| sum(law.iter().enumerate().map(|(j, &p)| p * pw(2.0 * j as f64 - m, k)));
    (m, c(2.0), c(3.0), c(4.0))
}

type C = (f64, f64);
fn cmul(a: C, b: C) -> C { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn fingerprint_total(t: f64) -> C {                                  // phi_S(t) = phi_X(t)^1000, by squaring
    let mut base = (sum((0..3).map(|i| PROBS[i] * (t * VALS[i]).cos())),
                    sum((0..3).map(|i| PROBS[i] * (t * VALS[i]).sin())));
    let (mut out, mut k) = ((1.0, 0.0), N);
    while k > 0 {
        if k & 1 == 1 { out = cmul(out, base); }
        base = cmul(base, base); k >>= 1;
    }
    out
}
fn log_fingerprint(t: f64) -> C {
    let (re, im) = fingerprint_total(t);
    (0.5 * (re * re + im * im).ln(), im.atan2(re))
}

fn derivs(f: fn(f64) -> C, h: f64) -> [[f64; 2]; 4] {                // 1st to 4th derivatives at 0
    let (f2, f1, f0, g1, g2) = (f(2.0 * h), f(h), f(0.0), f(-h), f(-2.0 * h));
    let p = |c: C, i: usize| if i == 0 { c.0 } else { c.1 };
    let mut d = [[0.0; 2]; 4];
    for i in 0..2 {
        d[0][i] = (8.0 * (p(f1, i) - p(g1, i)) - (p(f2, i) - p(g2, i))) / (12.0 * h);
        d[1][i] = (-p(f2, i) + 16.0 * p(f1, i) - 30.0 * p(f0, i) + 16.0 * p(g1, i) - p(g2, i)) / (12.0 * h * h);
        d[2][i] = (p(f2, i) - 2.0 * p(f1, i) + 2.0 * p(g1, i) - p(g2, i)) / (2.0 * pw(h, 3.0));
        d[3][i] = (p(f2, i) - 4.0 * p(f1, i) + 6.0 * p(f0, i) - 4.0 * p(g1, i) + p(g2, i)) / pw(h, 4.0);
    }
    d
}

fn phi_cdf(z: f64) -> f64 {                                          // bell-curve area left of z, one series
    let (mut term, mut s, mut k) = (z, z, 0.0);
    while term.abs() > 1e-17 { k += 1.0; term *= z * z / (2.0 * k + 1.0); s += term; }
    0.5 + s * (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt()
}

fn main() {
    let mom: Vec<f64> = (1..=4).map(|k| sum((0..3).map(|i| PROBS[i] * pw(VALS[i], k as f64)))).collect();
    let k_home = cumulants_from_moments([mom[0], mom[1], mom[2], mom[3]]);
    let k_add: Vec<f64> = k_home.iter().map(|k| N as f64 * k).collect();
    let d = derivs(log_fingerprint, 5e-4);
    let k_fp = [d[0][1], -d[1][0], -d[2][1], d[3][0]];
    let e = derivs(fingerprint_total, 1e-5);
    let law = law_of_total(0.04, 0.01, N);
    let (m, c2, c3, c4) = central(&law);
    let k_law = [m, c2, c3, c4 - 3.0 * pw(c2, 2.0)];

    println!("one home: E[X^k], k = 1..4     {}", mom.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join("  "));
    println!("{:<9}{:>15}{:>17}{:>17}{:>17}", "cumulant", "one home", "1,000 added", "fingerprint", "exact law");
    for k in 0..4 {
        println!("k{:<8}{:>15.6}{:>17.4}{:>17.4}{:>17.4}", k + 1, k_home[k], k_add[k], k_fp[k], k_law[k]);
    }
    println!("from phi_S: E[S] = -i phi'(0)          {:.4}", e[0][1]);
    println!("from phi_S: E[S^2] = -phi''(0)         {:.4}", -e[1][0]);
    println!("  variance E[S^2] - E[S]^2             {:.4}", -e[1][0] - pw(e[0][1], 2.0));
    let sd = k_add[1].sqrt();
    let skew = |k: &[f64]| k[2] / pw(k[1], 1.5);
    let kurt = |k: &[f64]| k[3] / pw(k[1], 2.0);
    println!("standard deviation of S, $k            {:.4}", sd);
    println!("skewness: one home, 1,000 homes        {:.6}  {:.6}", skew(&k_home), skew(&k_law));
    println!("excess kurtosis: one home, 1,000 homes {:.6}  {:.6}", kurt(&k_home), kurt(&k_law));
    let ns = [1.0_f64, 10.0, 100.0, 1000.0];
    println!("skewness by homes n = 1, 10, 100, 1000 {}", ns.iter().map(|n| format!("{:.2}", skew(&k_home) / n.sqrt())).collect::<Vec<_>>().join(" "));
    println!("kurtosis by homes n = 1, 10, 100, 1000 {}", ns.iter().map(|n| format!("{:.4}", kurt(&k_home) / n)).collect::<Vec<_>>().join(" "));
    println!("in dollars: k2 / 1e9 $^2, k3 / 1e13 $^3 {:.6}  {:.6}", k_add[1] * 1e6 / 1e9, k_add[2] * 1e9 / 1e13);
    let prof: Vec<f64> = [2.0, 3.0, 4.0].iter().map(|&k| sum(law.iter().enumerate()
        .map(|(j, &p)| p * pw(350.0 - 2.0 * j as f64 - (350.0 - m), k)))).collect();
    println!("profit 350 - S: k1..k4 from the law    {:.4} {:.4} {:.4} {:.4}", 350.0 - m, prof[0], prof[1], prof[2] - 3.0 * pw(prof[0], 2.0));
    let (mut lo, mut hi) = (0.0_f64, 5.0_f64);                       // z with Phi(z) = 0.995, by bisection
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if phi_cdf(mid) < 0.995 { lo = mid; } else { hi = mid; } }
    let z = lo;
    let (g1, g2) = (skew(&k_add), kurt(&k_add));
    let w1 = z + (z * z - 1.0) / 6.0 * g1;
    let w2 = w1 + (pw(z, 3.0) - 3.0 * z) / 24.0 * g2 - (2.0 * pw(z, 3.0) - 5.0 * z) / 36.0 * pw(g1, 2.0);
    let (mut cum, mut j995) = (0.0_f64, 0usize);
    while cum + law[j995] < 0.995 { cum += law[j995]; j995 += 1; }
    println!("z for 99.5%, and Phi(z) by the series  {:.6}  {:.6}", z, phi_cdf(z));
    println!("99.5% reserve, $k: bell curve          {:.2}", m + z * sd);
    println!("  plus the skewness term               {:.2}", m + w1 * sd);
    println!("  plus the kurtosis terms              {:.2}", m + w2 * sd);
    println!("  exact, from the law; P(S <= it)      {:.2}  {:.6}", 2.0 * j995 as f64, cum + law[j995]);
    println!("  exact minus bell curve, minus skew   {:.2}  {:.2}", 2.0 * j995 as f64 - (m + z * sd), 2.0 * j995 as f64 - (m + w1 * sd));
    let xs: Vec<usize> = (380..=540).step_by(20).collect();
    println!("chart, total above x $k     {}", xs.iter().map(|x| format!("{:5}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, exact law, percent   {}", xs.iter().map(|x| format!("{:5.2}", 100.0 * sum(law[x / 2 + 1..].iter().copied()))).collect::<Vec<_>>().join(" "));
    println!("chart, bell curve, percent  {}", xs.iter().map(|&x| format!("{:5.2}", 100.0 * (1.0 - phi_cdf((x as f64 - m) / sd)))).collect::<Vec<_>>().join(" "));
    // what breaks
    let mu4_home = k_home[3] + 3.0 * pw(k_home[1], 2.0);
    println!("wrong: 4th central moments added       {:.2}  (true {:.2})", N as f64 * mu4_home, c4);
    let raw3 = sum(law.iter().enumerate().map(|(j, &p)| p * pw(2.0 * j as f64, 3.0)));
    println!("wrong: raw E[S^3] / sd^3 as skewness   {:.4}", raw3 / pw(sd, 3.0));
    println!("wrong: drop i^-k, 'variance' Re K''(0) {:.4}", d[1][0]);
    println!("wrong: k3 to dollars with x1,000       {:.1}", k_add[2] * 1e3);
    let (la, lb) = (law_of_total(0.03, 0.0075, N), law_of_total(0.13, 0.0325, N));
    let storm: Vec<f64> = la.iter().zip(lb.iter()).map(|(a, b)| 0.9 * a + 0.1 * b).collect();
    let (sm, s2, s3, _) = central(&storm);
    println!("wrong: storm year, k1 k2 k3 of S       {:.4} {:.4} {:.4}", sm, s2, s3);
    println!("  storm year skewness                  {:.6}", s3 / pw(s2, 1.5));
    for l in [1e3_f64, 1e5, 1e7] {                                   // Pareto claims, index 2.5, from $10k
        println!("Pareto 2.5: E[Y^3; Y <= {:>8.0} $k]   {:.1}", l, 2.5 * pw(10.0, 2.5) * (l.sqrt() - 10.0_f64.sqrt()) / 0.5);
    }
    let dm: Vec<f64> = (1..=4).map(|k| sum((1..=6).map(|f| pw(f as f64, k as f64))) / 6.0).collect();
    let die = cumulants_from_moments([dm[0], dm[1], dm[2], dm[3]]);
    println!("dice: standardised total, n = 1, 10, 100: k3, k4 {:.6} {}", die[2],
        [1.0_f64, 10.0, 100.0].iter().map(|n| format!("{:.6}", kurt(&die) / n)).collect::<Vec<_>>().join(" "));

    for k in 0..4 { assert!((k_add[k] - k_law[k]).abs() < 1e-9 * k_law[k].abs(), "cumulants add, against the exact law"); }
    for k in 0..4 { assert!((k_fp[k] - k_law[k]).abs() < 1e-4 * k_law[k].abs(), "log-fingerprint derivatives, against the law"); }
    assert!((e[0][1] - m).abs() < 1e-8 * m, "E[S] from phi_S'(0), against the law");
    assert!((-e[1][0] - (c2 + m * m)).abs() < 1e-7 * (c2 + m * m), "E[S^2] from phi_S''(0), against the law");
    assert!((prof[1] + c3).abs() < 1e-6 * c3, "flipping the sign flips k3");
    assert!((skew(&k_law) * (N as f64).sqrt() - skew(&k_home)).abs() < 1e-9, "skewness falls as 1/sqrt(n)");
    assert!((m + w1 * sd - 2.0 * j995 as f64).abs() < 1.0, "the skewness term lands within $1k of the exact reserve");
    assert!(2.0 * j995 as f64 - (m + z * sd) > 10.0, "the bell curve alone under-reserves by over $10k");
    assert!((sm - m).abs() < 1e-9 && s3 > 1.5 * c3, "storm year: same mean, cumulants no longer add");
    println!("ALL CHECKS PASS");
}
