// Greeks under jumps -- the same check as the Python, in Rust.  No crates; the normal CDF, random
// numbers, integrator and root finder are written here.  House market: Acme $100, strike $100, rate 5%,
// dividends 2%, one year, diffusion vol 20%; jumps 0.5 a year, log-size mean -0.10, log-size spread 0.15.
use std::f64::consts::PI;
const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const LAM: f64 = 0.5; const MU: f64 = -0.10; const DL: f64 = 0.15;
const HP: [f64; 7] = [0.0352624965998911, 0.700383064443688, 6.37396220353165, 33.912866078383,
    112.079291497871, 221.213596169931, 220.206867912376];
const HQ: [f64; 8] = [0.0883883476483184, 1.75566716318264, 16.064177579207, 86.7807322029461,
    296.564248779674, 637.333633378831, 793.826512519948, 440.413735824752];

fn n_cdf(x: f64) -> f64 {                   // normal CDF: Hart's 1968 rational form
    let a = x.abs();
    let c = if a < 7.07106781186547 {
        let (mut b, mut d) = (0.0, 0.0);
        for c in HP { b = b * a + c; }
        for c in HQ { d = d * a + c; }
        (-a * a / 2.0).exp() * b / d
    } else { (-a * a / 2.0).exp() / (a + 1.0 / (a + 2.0 / (a + 3.0 / (a + 4.0 / (a + 0.65))))) / 2.506628274631 };
    if x > 0.0 { 1.0 - c } else { c }
}
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
// price, delta, gamma, vega: one Black-Scholes term per jump count n
fn merton(s: f64, k: f64, tau: f64, lam: f64, mu: f64, dl: f64, sg: f64, m: usize) -> [f64; 4] {
    let (kk, mut w, mut out) = ((mu + dl * dl / 2.0).exp() - 1.0, (-lam * tau).exp(), [0.0; 4]);
    for n in 0..m {
        let nf = n as f64;
        let vt = (sg * sg * tau + nf * dl * dl).sqrt();                 // sigma_n times root tau
        let qn = Q + lam * kk - nf * (mu + dl * dl / 2.0) / tau;        // compensator and recentring
        let d1 = ((s / k).ln() + (R - qn) * tau) / vt + vt / 2.0;
        let a = w * (-qn * tau).exp();
        out[0] += a * s * n_cdf(d1) - w * k * (-R * tau).exp() * n_cdf(d1 - vt); out[1] += a * n_cdf(d1);
        out[2] += a * phi(d1) / (s * vt); out[3] += a * s * phi(d1) * sg * tau / vt;
        w *= lam * tau / (nf + 1.0);
    }
    out
}
fn house(s: f64, k: f64, tau: f64) -> [f64; 4] { merton(s, k, tau, LAM, MU, DL, SIG, 12) }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>() * h / 3.0
}
fn u(s: &mut u64) -> f64 {                  // splitmix64: a uniform number in (0, 1)
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
}
fn g(s: &mut u64) -> f64 { let u1 = u(s); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u(s)).cos() }   // Box-Muller
fn hedge(path: &[f64], lam: f64, f: usize) -> f64 {   // seller's book at expiry, rebalanced f times
    let (step, h, cd) = ((path.len() - 1) / f, 1.0 / f as f64, merton(100.0, 100.0, 1.0, lam, MU, DL, SIG, 12));
    let (mut bank, mut sh, mut s) = (cd[0] - cd[1] * 100.0, cd[1], 100.0);
    for j in 1..=f {
        s = path[j * step]; bank *= (R * h).exp(); sh *= (Q * h).exp();   // dividends buy shares
        if j < f { let dn = merton(s, 100.0, 1.0 - j as f64 * h, lam, MU, DL, SIG, if lam > 0.0 { 6 } else { 1 })[1]; bank -= (dn - sh) * s; sh = dn; }
    }
    sh * s + bank - (s - 100.0).max(0.0)
}
fn show(label: &str, v: &[f64]) { println!("{:<36}{}", label, v.iter().map(|x| format!("{:>12.6}", x)).collect::<String>()); }
fn iv(price: f64, k: f64) -> f64 {          // implied vol by bisection
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if merton(100.0, k, 1.0, 0.0, MU, DL, mid, 1)[0] < price { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn ms(v: &[f64]) -> (f64, f64) { let m = v.iter().sum::<f64>() / v.len() as f64;   // mean and spread
    (m, (v.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (v.len() - 1) as f64).sqrt()) }
const KS: [f64; 3] = [92.15, 100.0, 119.93];
fn prices(p: &[f64]) -> Vec<f64> { KS.iter().map(|&k| merton(100.0, k, 1.0, p[0], p[1], p[2], SIG, 12)[0]).collect() }
fn miss(p: &[f64], target: &[f64]) -> Vec<f64> { prices(p).iter().zip(target).map(|(a, b)| a - b).collect() }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn det(a: &[Vec<f64>]) -> f64 {             // determinant by expansion along the top row
    if a.len() == 1 { return a[0][0]; }
    (0..a.len()).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) * a[0][j]
        * det(&a[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect::<Vec<_>>())).sum()
}
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {   // Cramer's rule
    (0..b.len()).map(|j| det(&a.iter().zip(b).map(|(r, &v)| { let mut c = r.clone(); c[j] = v; c }).collect::<Vec<_>>()) / det(a)).collect()
}
fn fit(mut p: Vec<f64>, free: &[usize], target: &[f64]) -> Vec<f64> {   // damped Gauss-Newton
    for _ in 0..40 {
        let f = miss(&p, target);
        let cols: Vec<Vec<f64>> = free.iter().map(|&j| {            // columns by bump-and-revalue
            let (mut up, mut dn) = (p.clone(), p.clone()); up[j] += 1e-5; dn[j] -= 1e-5;
            prices(&up).iter().zip(prices(&dn)).map(|(a, b)| (a - b) / 2e-5).collect() }).collect();
        let a: Vec<Vec<f64>> = cols.iter().map(|x| cols.iter().map(|y| dot(x, y)).collect()).collect();
        let (dx, mut t) = (solve(&a, &cols.iter().map(|x| -dot(x, &f)).collect::<Vec<_>>()), 1.0);
        while t > 1e-6 {                    // halve the step until the misfit falls
            let mut c = p.clone();
            for (&j, d) in free.iter().zip(&dx) { c[j] += t * d; }
            let m = miss(&c, target);
            if c[0] > 0.0 && c[2] > 0.0 && dot(&m, &m) <= dot(&f, &f) { p = c; break; }
            t /= 2.0;
        }
    }
    p
}
fn main() {
    let [c, d, gm, v] = house(100.0, 100.0, 1.0);
    let db = (house(100.01, 100.0, 1.0)[0] - house(99.99, 100.0, 1.0)[0]) / 0.02;   // bump S by a cent
    let gb = (house(100.01, 100.0, 1.0)[0] - 2.0 * c + house(99.99, 100.0, 1.0)[0]) / 0.0001;
    let vb = (merton(100.0, 100.0, 1.0, LAM, MU, DL, SIG + 1e-4, 12)[0] - merton(100.0, 100.0, 1.0, LAM, MU, DL, SIG - 1e-4, 12)[0]) / 2e-4;
    show("price, delta, gamma, vega: series", &[c, d, gm, v]);
    show("gaps: k, e^mu_J, P(0 gaps), P(1 gap)", &[(MU + DL * DL / 2.0).exp() - 1.0, MU.exp(), (-LAM).exp(), LAM * (-LAM).exp()]);
    show("  by bumping; vega as S^2 sigma T G", &[db, gb, vb, 100.0 * 100.0 * SIG * gm]);
    show("Black-Scholes at 20%: same four", &merton(100.0, 100.0, 1.0, 0.0, MU, DL, SIG, 1));
    let ivc = iv(c, 100.0); let bi = merton(100.0, 100.0, 1.0, 0.0, MU, DL, ivc, 1);
    show("Black-Scholes at implied vol", &[ivc, bi[1], bi[2], bi[3]]); let mut gaps_ok = true;
    for jm in [0.8, 0.9, 1.1, 1.2] { let z = 100.0 * (jm - 1.0);   // jump residual two ways: prices, curvature integral
        let (a, b) = (house(100.0 * jm, 100.0, 1.0)[0] - c - z * d, z * z * simpson(|t| (1.0 - t) * house(100.0 + t * z, 100.0, 1.0)[2], 0.0, 1.0, 64));
        show(&format!("gap J={}: by prices, by curvature", jm), &[a, b]);
        gaps_ok &= 0.0 < a && (a - b).abs() < 1e-6;
    }
    let er = simpson(|y| phi(y) * (house(100.0 * (MU + DL * y).exp(), 100.0, 1.0)[0] - c
                                   - 100.0 * ((MU + DL * y).exp() - 1.0) * d), -8.0, 8.0, 96);
    let th = (house(100.0, 100.0, 1.0 - 1e-4)[0] - house(100.0, 100.0, 1.0 + 1e-4)[0]) / 2e-4;
    let drift_book = -th - SIG * SIG * 100.0 * 100.0 * gm / 2.0 - (R - Q) * 100.0 * d + R * c;
    show("jump rent: lambda E[R], book drift", &[LAM * er, drift_book]);
    let (paths, nf, freqs, kk) = (1000usize, 1024usize, [16usize, 64, 256, 1024], (MU + DL * DL / 2.0).exp() - 1.0);
    let (mut book, mut count, mut seed, mut st) = (vec![Vec::new(); 8], Vec::new(), 20260924u64, Vec::new());
    for _ in 0..paths {
        let (x, mut n, mut pr, mut cum) = (u(&mut seed), 0usize, (-LAM).exp(), (-LAM).exp());   // jump count
        while x > cum { n += 1; pr *= LAM / n as f64; cum += pr; }
        let mut gaps = vec![0.0; nf];
        for _ in 0..n { let i = (u(&mut seed) * nf as f64) as usize; gaps[i] += MU + DL * g(&mut seed); }
        count.push(n); let z: Vec<f64> = (0..nf).map(|_| g(&mut seed)).collect();
        for (wi, lam) in [0.0, LAM].into_iter().enumerate() {
            let drift = (R - Q - lam * kk - SIG * SIG / 2.0) / nf as f64;   // log-drift per step
            let mut path = vec![100.0];
            for i in 0..nf { path.push(path[i] * (drift + SIG * z[i] / (nf as f64).sqrt() + if lam > 0.0 { gaps[i] } else { 0.0 }).exp()); }
            for (fi, &f) in freqs.iter().enumerate() { book[wi * 4 + fi].push(hedge(&path, lam, f)); }
            if lam > 0.0 { st.push(path[nf]); }   // the jump world's price at expiry
        }
    }
    println!("seller's book at expiry, 1000 paths   BS mean   BS sd     MJ mean   MJ sd");
    for (fi, f) in freqs.iter().enumerate() { let ((a, b), (e, h)) = (ms(&book[fi]), ms(&book[4 + fi]));
        println!("{:<36}{:>10.2}{:>10.2}{:>10.2}{:>10.2}", format!("  rebalanced {} times a year", f), a, b, e, h); }
    for (bk, lab) in [(0, "0 jumps"), (1, "1 jump"), (2, "2 or more")] {
        let sel: Vec<f64> = book[6].iter().zip(&count).filter(|(_, &n)| n.min(2) == bk).map(|(x, _)| *x).collect();
        println!("  daily MJ book, {:<9}: {:>4} paths, mean {:6.2}", lab, sel.len(), sel.iter().sum::<f64>() / sel.len() as f64);
    }
    let tenth = |v: &Vec<f64>| { let mut s = v.clone(); s.sort_by(|a, b| a.total_cmp(b)); s[9] };
    println!("{:<36}{:>10.2}{:>10.2}", "  10th worst daily book: BS, MJ", tenth(&book[2]), tenth(&book[6]));
    let pay = ms(&st.iter().map(|x| (-R).exp() * (x - 100.0).max(0.0)).collect::<Vec<_>>());
    show("MJ price by simulation; std error", &[pay.0, pay.1 / (paths as f64).sqrt()]);
    let quote = prices(&[LAM, MU, DL]); show("quotes at 92.15, 100, 119.93", &quote);
    let fits: Vec<Vec<f64>> = [vec![1.0, -0.05, 0.10], vec![0.25, -0.20, 0.25]].into_iter().map(|s| fit(s, &[0, 1, 2], &quote)).collect();
    for (s, p) in ["(1.00, -0.05, 0.10)", "(0.25, -0.20, 0.25)"].iter().zip(&fits) { show(&format!("fit from {}", s), p); }
    let cent = fit(vec![LAM, MU, DL], &[0, 1, 2], &[quote[0], quote[1] + 0.01, quote[2]]); show("one cent added at the 100 strike", &cent);
    let mut ridge: Vec<Vec<f64>> = Vec::new();
    for lam in [0.25, 0.375, 0.5, 0.625, 0.75] {
        let p = fit(vec![lam, MU, DL], &[1, 2], &quote); let m = miss(&p, &quote);
        show(&format!("rate {:.3}: mean, spread, misses", lam), &[p[1], p[2], m[0], m[1], m[2]]); ridge.push(p);
    }
    let smk = [60.0, 70.0, 80.0, 92.15, 100.0, 110.0, 119.93, 130.0, 140.0];
    let sm: Vec<Vec<f64>> = [vec![LAM, MU, DL], ridge[4].clone()].iter()
        .map(|p| smk.iter().map(|&k| 100.0 * iv(merton(100.0, k, 1.0, p[0], p[1], p[2], SIG, 12)[0], k)).collect()).collect();
    println!("smile at strikes    {}", smk.iter().map(|k| format!("{:>7}", k)).collect::<String>());
    for (lab, row) in ["  house  0.50 a year", "  other  0.75 a year"].iter().zip(&sm) { println!("{}{}", lab, row.iter().map(|v| format!("{:>7.2}", v)).collect::<String>()); }
    assert!((db - d).abs() < 1e-7 && (gb - gm).abs() < 1e-6 && (vb - v).abs() < 1e-5, "series Greeks vs bumps");
    assert!(gaps_ok, "gap residual: prices vs curvature");
    assert!((LAM * er - drift_book).abs() < 1e-5, "no-jump drift of the book equals the jump rent");
    let sd: Vec<f64> = book.iter().map(|b| ms(b).1).collect();
    assert!(0.2 < sd[2] / sd[0] && sd[2] / sd[0] < 0.3, "Black-Scholes error falls like one over root N");
    assert!(sd[7] / sd[6] > 0.9 && sd[7] > 10.0 * sd[3], "jump error plateaus");
    assert!(ms(&book[7]).0.abs() < 3.0 * sd[7] / (paths as f64).sqrt(), "hedged book averages zero");
    assert!((pay.0 - c).abs() < 3.0 * pay.1 / (paths as f64).sqrt(), "series price vs average simulated payoff");
    assert!(fits.iter().all(|p| p.iter().zip([LAM, MU, DL]).all(|(a, b)| (a - b).abs() < 1e-8)), "fit recovers inputs");
    assert!(ridge.windows(2).all(|w| w[0][2] > w[1][2]), "spread falls as rate rises along the ridge");
    assert!((3..7).all(|i| (sm[0][i] - sm[1][i]).abs() < 0.1) && (sm[0][0] - sm[1][0]).abs() > 0.1, "wing tells");
    println!("ALL CHECKS PASS");
}
