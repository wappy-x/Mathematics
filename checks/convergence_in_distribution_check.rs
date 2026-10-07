// Convergence in distribution -- the check behind the card.  Rust std only.
// Each number is found by two roads that share no arithmetic: die totals are
// counted by adding one die at a time and by inclusion-exclusion; the normal
// distribution function by its power series and by Simpson's rule; the discrete
// uniform's averages by a direct sum and by a closed form.  The code checks
// finite n only; every statement about the limit rests on the proofs.
use std::collections::BTreeMap;

fn choose(a: i128, b: i128) -> i128 {
    let mut r = 1;
    for i in 0..b {
        r = r * (a - i) / (i + 1);
    }
    r
}
fn counts_by_adding(n: usize) -> Vec<i128> {
    let mut w = vec![1i128];
    for _ in 0..n {
        let mut new = vec![0i128; w.len() + 6];
        for (s, &c) in w.iter().enumerate() {
            for face in 1..7 {
                new[s + face] += c;
            }
        }
        w = new;
    }
    w
}
fn counts_by_formula(n: i128) -> Vec<i128> {
    (0..6 * n + 1)
        .map(|s| (0..n + 1).filter(|&k| s - 6 * k >= n)
            .map(|k| (if k % 2 == 0 { 1 } else { -1 }) * choose(n, k) * choose(s - 6 * k - 1, n - 1)).sum())
        .collect()
}
fn probs(n: usize) -> Vec<f64> {
    let mut p = vec![1.0f64];
    for _ in 0..n {
        let mut pad = vec![0.0; 6];
        pad.extend(&p);
        pad.extend([0.0; 6]);
        p = (0..p.len() + 6).map(|s| pad[s..s + 6].iter().fold(0.0, |a, &b| a + b) / 6.0).collect();
    }
    p
}
fn phi_series(t: f64) -> f64 {
    let (mut term, mut total) = (t, 0.0);
    for k in 0..80 {
        total += term / (2 * k + 1) as f64;
        term *= -t * t / 2.0 / (k as f64 + 1.0);
    }
    0.5 + total / (2.0 * std::f64::consts::PI).sqrt()
}
fn phi(t: f64) -> f64 {
    let m = 2000;
    let (h, mut s) = (t / m as f64, 1.0 + (-t * t / 2.0).exp());
    for i in 1..m {
        let x = i as f64 * h;
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * (-x * x / 2.0).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}
fn cdf(p: &[f64], x: f64) -> f64 {
    p.iter().enumerate().filter(|&(s, _)| s as f64 <= x).fold(0.0, |a, (_, &v)| a + v)
}
fn gcd(a: i64, b: i64) -> i64 {
    if b == 0 { a.abs() } else { gcd(b, a % b) }
}
fn yes(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}
fn main() {
    let mut pr: BTreeMap<usize, Vec<f64>> = BTreeMap::new();
    for n in [1, 2, 10, 100, 1000] {
        pr.insert(n, probs(n));
    }
    let fz = |n: usize, t: f64| cdf(&pr[&n], 3.5 * n as f64 + t * ((35 * n) as f64 / 12.0).sqrt());
    let (a2, b2, a10, b10) = (counts_by_adding(2), counts_by_formula(2), counts_by_adding(10), counts_by_formula(10));
    println!("die: S_n = total of n rolls, Z_n = (S_n - 3.5 n) / sqrt(35 n / 12)");
    println!("counts by adding dice = counts by inclusion-exclusion: n=2 {} ({} outcomes), n=10 {} ({} outcomes)",
        yes(a2 == b2), a2.iter().sum::<i128>(), yes(a10 == b10), a10.iter().sum::<i128>());
    println!("n=2 counts of totals 2..12: {} ; {} of 36 at or below 7",
        a2[2..].iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "), a2[..8].iter().sum::<i128>());
    let float_err = a10.iter().enumerate().map(|(s, &c)| (pr[&10][s] - c as f64 / 60466176.0).abs()).fold(0.0, f64::max);
    println!("n=10 floating-point law against exact fractions, worst gap below 1e-15: {}", yes(float_err < 1e-15));
    let ts: Vec<f64> = (-5..6).map(|x| x as f64 / 2.0).collect();
    let ser: Vec<f64> = ts.iter().map(|&t| phi_series(t)).collect();
    let simp: Vec<f64> = ts.iter().map(|&t| phi(t)).collect();
    println!("Phi by series and by Simpson, t = 0.5, 1, 2: {:.6} {:.6}, {:.6} {:.6}, {:.6} {:.6}",
        ser[6], simp[6], ser[7], simp[7], ser[9], simp[9]);
    let row = |v: Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ");
    println!("chart t:    {}", ts.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(", "));
    for n in [2usize, 10] {
        println!("chart F_{}:{} {}", n, " ".repeat(3 - n.to_string().len()), row(ts.iter().map(|&t| fz(n, t)).collect()));
    }
    println!("chart Phi:  {}", row(simp.clone()));
    let mut gaps = Vec::new();
    for n in [1usize, 2, 10, 100] {
        let (sd, mut below, mut worst) = (((35 * n) as f64 / 12.0).sqrt(), 0.0f64, 0.0f64);
        let p = &pr[&n];
        for s in n..6 * n + 1 {
            let ph = phi((s as f64 - 3.5 * n as f64) / sd);
            worst = worst.max((below - ph).abs()).max((below + p[s] - ph).abs());
            below += p[s];
        }
        let jump = p.iter().cloned().fold(0.0, f64::max);
        gaps.push((worst, jump));
        println!("n={:3}: F_n(0) = {:.4}, largest jump {:.4}, sup |F_n - Phi| = {:.4}", n, fz(n, 0.0), jump, worst);
    }
    println!("discrete uniform U_n on {{1/n, ..., 1}}; for U uniform on (0, 1), F(1/3) = 1/3 and E[U^2] = 1/3");
    let mut unif_ok = true;
    for n in [10i128, 100, 1000] {
        let count = (1..n + 1).filter(|&k| 3 * k <= n).count() as i128;
        let (num, den) = ((1..n + 1).map(|k| k * k).sum::<i128>(), n * n * n);
        let (fnum, fden) = ((n + 1) * (2 * n + 1), 6 * n * n);
        unif_ok &= count == n / 3 && num * fden == fnum * den;
        println!("n={:4}: F_n(1/3) = {}/{} (formula floor(n/3)/n = {}/{}), E[U_n^2] = {:.7} (closed form {:.7})",
            n, count, n, n / 3, n, num as f64 / den as f64, fnum as f64 / fden as f64);
    }
    let point: Vec<(i32, i32, i32)> = [10, 100, 1000].iter()
        .map(|&n| (n, (1.0 / n as f64 <= 0.0) as i32, (1.0 / n as f64 <= 0.01) as i32)).collect();
    println!("X_n = 1/n: n, F_n(0), F_n(0.01): {} ; limit F(0) = 1, F(0.01) = 1",
        point.iter().map(|(a, b, c)| format!("{}, {}, {}", a, b, c)).collect::<Vec<_>>().join("; "));
    let ramp = |x: f64, t: f64, e: f64| ((t + e - x) / e).max(0.0).min(1.0); // Step 1's g: 1 up to t, 0 from t + e
    let mut squeeze = true;
    for n in [10.0f64, 100.0, 1000.0] { for t in [0.0, 0.02, 0.2] { for e in [0.001, 0.05] {
        let f = (1.0 / n <= t) as i32 as f64;
        squeeze &= ramp(1.0 / n + e, t, e) <= f && f <= ramp(1.0 / n, t, e);
    } } }
    println!("ramps h <= F_n(t) <= g for X_n = 1/n at t = 0, 0.02, 0.2: {}", yes(squeeze));
    let faces: Vec<i64> = (1..7).collect();
    let under: Vec<i64> = faces.iter().map(|d| 7 - d).collect(); // the face underneath, outcome by outcome
    let law = |xs: &[i64]| xs.iter().fold(BTreeMap::new(), |mut m, &v| { *m.entry(v).or_insert(0) += 1; m });
    let near = faces.iter().zip(&under).filter(|&(d, u)| (u - d).abs() < 1).count();
    println!("flip 7 - D: law equals D's law: {} ; |(7 - D) - D| for D = 1..6: {} ; P(|(7 - D) - D| < 1) = {}",
        yes(law(&under) == law(&faces)), faces.iter().zip(&under).map(|(d, u)| (u - d).abs().to_string()).collect::<Vec<_>>().join(" "), near);
    let frac = |a: i64, b: i64| if b / gcd(a, b) == 1 { (a / gcd(a, b)).to_string() } else { format!("{}/{}", a / gcd(a, b), b / gcd(a, b)) };
    let mut lump = Vec::new();
    for n in [10i64, 100, 1000] { // X_n = n with chance 1/n, else 0; chances as numerators over n
        let lw = [(0i64, n - 1), (n, 1)];
        let f_half: i64 = lw.iter().filter(|&&(x, _)| 2 * x <= 1).map(|&(_, p)| p).sum();
        lump.push((n, f_half, lw.iter().map(|&(x, p)| x * p).sum::<i64>(), lw.iter().map(|&(x, p)| x.min(1) * p).sum::<i64>()));
    }
    println!("X_n = n with chance 1/n, else 0: n, F_n(1/2), E[X_n], E[min(X_n, 1)]: {} ; limit 0: 1, 0, 0",
        lump.iter().map(|&(n, f, m, c)| format!("{}, {}, {}, {}", n, frac(f, n), frac(m, n), frac(c, n))).collect::<Vec<_>>().join("; "));
    println!("running average A_n = S_n / n against the constant 3.5, gap at least 0.1:");
    let mut far = Vec::new();
    for n in [10usize, 100, 1000] {
        let f = pr[&n].iter().enumerate().filter(|&(s, _)| 10 * (2 * s as i64 - 7 * n as i64).abs() >= 2 * n as i64)
            .fold(0.0, |a, (_, &v)| a + v);
        let cheb = 35.0 / ((12 * n) as f64 * 0.01);
        far.push((f, cheb));
        println!("n={:4}: P(|A_n - 3.5| >= 0.1) = {:.4}, Chebyshev bound 35/(12 n 0.01) = {:.4}", n, f, cheb);
    }
    let tight = pr[&1000].iter().enumerate().filter(|&(s, _)| 10 * (2 * s as i64 - 7000).abs() >= 1000).fold(0.0, |a, (_, &v)| a + v);
    println!("n=1000: P(|A_n - 3.5| < 0.1) = {:.4}; tolerance 0.05: P(|A_n - 3.5| >= 0.05) = {:.4}", 1.0 - far[2].0, tight);
    let nosc: Vec<f64> = [10usize, 100, 1000].iter().map(|&n| cdf(&pr[&n], 3.5 * n as f64 + 10.0)).collect();
    println!("centred, unscaled S_n - 3.5 n: F(10) at n = 10, 100, 1000: {}",
        nosc.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", "));

    assert!(a2 == b2 && a10 == b10 && float_err < 1e-15);
    assert!(ser.iter().zip(&simp).all(|(a, b)| (a - b).abs() < 1e-10)); // two roads to Phi
    assert!(unif_ok); // uniform: count and sum, two roads
    assert!(gaps[0].0 > gaps[1].0 && gaps[1].0 > gaps[2].0 && gaps[2].0 > gaps[3].0 && (gaps[3].0 - gaps[3].1 / 2.0).abs() < 1e-3);
    assert!(((1.0 - far[2].0) * 1e4).round() == 9346.0); // wing 09's exact count
    assert!(far.iter().all(|&(f, c)| f <= c)); // Chebyshev, a separate road
    assert!(squeeze); // Step 1's squeeze, at the jump and off it
    assert!(law(&under) == law(&faces) && near == 0); // same law, never close
    assert!(lump.iter().all(|&(n, _, m, c)| m == n && c == 1)); // law's mean against n * (1/n) = 1; capped mean against 1/n
    assert!(nosc[0] > nosc[1] && nosc[1] > nosc[2] && nosc[2] > 0.5);
}
