// Donsker's theorem: the gambler's best-so-far winnings against Brownian motion's reflection answer.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 {
    // standard normal CDF: 1/2 plus Simpson's rule on the bell curve from 0 to x
    if x < 0.0 {
        return 1.0 - phi(-x);
    }
    let (x, m) = (x.min(12.0), 2000usize);
    let h = x / m as f64;
    let mut s = 0.0;
    for i in 0..=m {
        let w = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * (-(i as f64 * h).powi(2) / 2.0).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}

fn phi_series(x: f64) -> f64 {
    // second road: Taylor series of the error function
    let z = x / 2f64.sqrt();
    let (mut term, mut s, mut k) = (z, 0.0, 0.0);
    while term.abs() > 1e-17 {
        s += term / (2.0 * k + 1.0);
        k += 1.0;
        term *= -z * z / k;
    }
    0.5 + s / PI.sqrt()
}

fn bin_tail(lnf: &[f64], n: usize, p: f64, k: usize) -> f64 {
    // P(Bin(n, p) >= k), each term from ln(n choose j)
    (k..=n)
        .map(|j| (lnf[n] - lnf[j] - lnf[n - j] + j as f64 * p.ln() + (n - j) as f64 * (1.0 - p).ln()).exp())
        .sum()
}

fn touch(n: usize, up: usize, down: usize, p: f64, l: usize, every: usize) -> f64 {
    // chance a walk (+up with chance p, -down otherwise, from 0) stands at L or above
    // at some checked round; rounds are checked every `every` rounds. No mirror used.
    let base = down * n;
    let w = base + l + up * every;
    let mut old = vec![0.0f64; w];
    old[base] = 1.0;
    let mut hit = 0.0;
    for k in 1..=n {
        let mut new = vec![0.0f64; w];
        for (i, &v) in old.iter().enumerate() {
            if v != 0.0 {
                if i + up < w {
                    new[i + up] += p * v;
                }
                if i >= down {
                    new[i - down] += (1.0 - p) * v;
                }
            }
        }
        if k % every == 0 {
            hit += new[base + l..].iter().sum::<f64>();
            new[base + l..].iter_mut().for_each(|v| *v = 0.0);
        }
        old = new;
    }
    hit
}

fn two_sided_walk(m: usize, lam: usize) -> f64 {
    // P(coin walk reaches +lam or -lam within m rounds); index i is position i - lam
    let mut old = vec![0.0f64; 2 * lam + 1];
    old[lam] = 1.0;
    let mut hit = 0.0;
    for _ in 0..m {
        let mut new = vec![0.0f64; 2 * lam + 1];
        for i in 1..2 * lam {
            for j in [i + 1, i - 1] {
                if j == 0 || j == 2 * lam { hit += old[i] / 2.0; } else { new[j] += old[i] / 2.0; }
            }
        }
        old = new;
    }
    hit
}

fn two_sided_bm(d: f64, e: f64) -> f64 {
    // P(max over [0, d] of |W| >= e), mirrors in both walls
    let mut stay = 0.0;
    for k in -20i32..=20 {
        let sg = if k % 2 == 0 { 1.0 } else { -1.0 };
        let k = k as f64;
        stay += sg * (phi((2.0 * k + 1.0) * e / d.sqrt()) - phi((2.0 * k - 1.0) * e / d.sqrt()));
    }
    1.0 - stay
}

fn isqrt(n: usize) -> usize { (n as f64).sqrt().round() as usize }

fn main() {
    let mut lnf = vec![0.0f64];
    for i in 1..=6400 {
        let last = lnf[lnf.len() - 1];
        lnf.push(last + (i as f64).ln()); // ln(i!) as a running sum of logs
    }
    let bm = 2.0 * (1.0 - phi(1.5));
    assert!((phi(1.5) - phi_series(1.5)).abs() < 1e-10);
    println!("Gambler: fair coin, +1 or -1 chip a round, 100 rounds, level 15 chips");
    println!("1 spread = sqrt(100) = 10 chips, so the level is 1.5 spreads");
    let end = bin_tail(&lnf, 100, 0.5, 58);
    let refl = 2.0 * end;
    let dp = touch(100, 1, 1, 0.5, 15, 1);
    println!("P(end >= 15) = P(Bin(100,1/2) >= 58) = {:.4}", end);
    println!("walk reflection 2 P(Bin >= 58)       = {:.4}", refl);
    println!("step-by-step, no mirror              = {:.4}", dp);
    println!("Phi(1.5) by Simpson = {:.6} by series = {:.6}", phi(1.5), phi_series(1.5));
    println!("Brownian 2(1 - Phi(1.5))             = {:.4}", bm);
    println!("gap walk - Brownian                  = {:+.4}", refl - bm);
    assert!((refl - dp).abs() < 1e-12 && (refl - bm).abs() < 0.001);
    println!("joined-up minus step path, at most 1/sqrt(n) = {:.4}", 1.0 / 10f64);
    println!("convergence, level 1.5 sqrt(n) chips:");
    println!("n | coin exact | long-shot exact | Brownian");
    let mut gaps = Vec::new();
    for n in [100usize, 400, 1600, 6400] {
        let r = isqrt(n);
        let a = 3 * r / 2;
        let coin = if a % 2 == 1 {
            bin_tail(&lnf, n, 0.5, (n + a) / 2 + 1) * 2.0
        } else {
            bin_tail(&lnf, n, 0.5, (n + a) / 2) + bin_tail(&lnf, n, 0.5, (n + a) / 2 + 1)
        };
        let coin_dp = touch(n, 1, 1, 0.5, a, 1);
        let shot = touch(n, 4, 1, 0.2, 3 * r, 1); // half-chip units: +2 chips = +4, -1/2 chip = -1
        assert!((coin - coin_dp).abs() < 1e-10);
        gaps.push(((coin - bm).abs(), (shot - bm).abs()));
        println!("{} | {:.4} | {:.4} | {:.4}", n, coin, shot, bm);
    }
    assert!(gaps[3].0 < gaps[0].0 && gaps[3].1 < gaps[0].1 / 3.0 && gaps[3].1 < 0.01);
    println!("mistakes, 100 rounds:");
    println!("end position only, P(end >= 15)      = {:.4}", end);
    println!("normal tail only, 1 - Phi(1.5)       = {:.4}", 1.0 - phi(1.5));
    let chk = touch(100, 1, 1, 0.5, 15, 10);
    println!("checked every 10 rounds only         = {:.4}", chk);
    let shot_end = bin_tail(&lnf, 100, 0.2, 26); // 2.5 wins - 50 >= 15 needs 26 wins
    let shot100 = touch(100, 4, 1, 0.2, 30, 1);
    println!("long-shot, doubled end tail          = {:.4}", 2.0 * shot_end);
    println!("long-shot, exact                     = {:.4}", shot100);
    let ok = |x: f64| if x >= 1.5 { 1.0 } else { 0.0 };
    let spike = 0.5 * ok(0.1 + 2.0) + 0.5 * ok(-0.1 + 2.0);
    println!("walk plus a spike of 2 at t=1/n, P(max >= 1.5) = {:.4}", spike);
    assert!(chk < dp && (2.0 * shot_end - shot100).abs() > 0.02);
    println!("tightness: P(some block of length d has |swing from its start| >= 1)");
    println!("d | n | blocks x walk block chance | Brownian limit | bound 3d");
    for d in [0.2f64, 0.1] {
        let lim = two_sided_bm(d, 1.0) / d;
        let mut u = 0.0;
        for n in [100usize, 400, 1600, 6400] {
            let m = (d * n as f64).round() as usize;
            u = two_sided_walk(m, isqrt(n)) / d;
            assert!(u <= 3.0 * d);
            println!("{} | {} | {:.4} | {:.4} | {:.4}", d, n, u, lim, 3.0 * d);
        }
        assert!((u - lim).abs() < 0.1 * lim);
    }
    println!("0.05 | Brownian limit only | {:.6}", two_sided_bm(0.05, 1.0) / 0.05);
    println!("try: level 2 spreads, Brownian = {:.4} coin n=100 = {:.4}", 2.0 * (1.0 - phi(2.0)),
             bin_tail(&lnf, 100, 0.5, 60) + bin_tail(&lnf, 100, 0.5, 61));
    println!("try: 400 rounds, level 15 chips, coin = {:.4} Brownian = {:.4}",
             2.0 * bin_tail(&lnf, 400, 0.5, 208), 2.0 * (1.0 - phi(0.75)));
    println!("ALL CHECKS PASS");
}
