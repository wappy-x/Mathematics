// Rank tests -- the same check as the Python, in Rust.  No crates.  Two coffee
// shops, 8 waits each; a before/after pair; the 3/pi efficiency against the t-test.
// Normal and t tail areas are Simpson integrals written out; the random numbers
// come from a hand-written generator, so both checks draw the same numbers.
use std::f64::consts::PI;
const M: usize = 8;
const N: usize = 16;
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (k, mut s) = (2000, 0.0);
    let h = (b - a) / k as f64;
    for i in 0..=k { s += (if i == 0 || i == k { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn norm_tail(z: f64) -> f64 { 0.5 - simpson(&|x: f64| (-x * x / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, z.abs()) }
fn norm_cdf(z: f64) -> f64 { if z > 0.0 { 1.0 - norm_tail(z) } else { norm_tail(z) } }
fn t_tail(t: f64, df: f64) -> f64 {
    let g = |th: f64| th.cos().powf(df - 1.0);
    simpson(&g, (t.abs() / df.sqrt()).atan(), PI / 2.0) / (2.0 * simpson(&g, 0.0, PI / 2.0))
}
fn midranks(xs: &[f64]) -> Vec<f64> {          // ranks 1..len; tied values share the average rank
    let below = |x: f64, eq: bool| xs.iter().filter(|&&y| y < x || (eq && y == x)).count() as f64;
    xs.iter().map(|&x| (below(x, false) + 1.0 + below(x, true)) / 2.0).collect()
}
fn mean_var(xs: &[f64]) -> (f64, f64) {
    let mu = xs.iter().sum::<f64>() / xs.len() as f64;
    (mu, xs.iter().map(|x| (x - mu).powi(2)).sum::<f64>() / (xs.len() as f64 - 1.0))
}
fn welch(x: &[f64], y: &[f64]) -> (f64, f64) {
    let ((mx, vx), (my, vy)) = (mean_var(x), mean_var(y));
    let (nx, ny) = (x.len() as f64, y.len() as f64);
    let se2 = vx / nx + vy / ny;
    let df = se2.powi(2) / ((vx / nx).powi(2) / (nx - 1.0) + (vy / ny).powi(2) / (ny - 1.0));
    ((mx - my) / se2.sqrt(), df)
}
fn u_pairs(x: &[f64], y: &[f64]) -> f64 {
    x.iter().map(|a| y.iter().map(|b| if a > b { 1.0 } else if a == b { 0.5 } else { 0.0 }).sum::<f64>()).sum()
}
fn exact_p(x: &[f64], y: &[f64]) -> f64 {     // road 2: list all C(16,8) splits of the pooled ranks
    let r = midranks(&[x, y].concat());
    let dev = |mask: u32| ((0..N).filter(|i| mask >> i & 1 == 1).map(|i| r[i]).sum::<f64>() - 36.0 - 32.0).abs();
    let splits: Vec<u32> = (0u32..1 << N).filter(|mk| mk.count_ones() as usize == M).collect();
    splits.iter().filter(|&&mk| dev(mk) >= dev(0xFF) - 1e-9).count() as f64 / splits.len() as f64   // 0xFF: A's 8 places
}
fn show(label: &str, v: String) { println!("{:<50}{}", label, v); }
fn join(xs: &[f64]) -> String { xs.iter().map(|x| format!("{}", x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let a = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0];
    let b = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0];
    let r = midranks(&[&a[..], &b[..]].concat());
    let ra: f64 = r[..M].iter().sum();
    let ua = ra - (M * (M + 1) / 2) as f64;
    show("shop A ranks among all 16", join(&r[..M]));
    show("rank sums A, B; all 16", format!("{}, {}; {}", ra, r[M..].iter().sum::<f64>(), r.iter().sum::<f64>()));
    show("U = rank sum - 36; pairs where A waited longer", format!("{}; {} of {} = {:.4}", ua, u_pairs(&a, &b), M * M, ua / (M * M) as f64));
    let (mu, sd) = ((M * M) as f64 / 2.0, ((M * M * (N + 1)) as f64 / 12.0).sqrt());
    show("null mean, variance, spread of U", format!("{}, {:.3}, {:.2}", mu, sd * sd, sd));
    let (z, zc) = ((ua - mu) / sd, (ua + 0.5 - mu) / sd);
    show("z plain, z with half-step", format!("{:.2}, {:.3}", z, zc));
    show("mistake: rank sum 48 used as U, z", format!("{:+.2}", (ra - mu) / sd));
    show("bell p two-sided: plain, half-step", format!("{:.4}, {:.4}", 2.0 * norm_tail(z), 2.0 * norm_tail(zc)));
    let smax = N * (N + 1) / 2;
    let mut ways = vec![vec![0u64; smax + 1]; M + 1];
    ways[0][0] = 1;
    for k in 1..=N {                           // road 1: count rank sets by size and sum
        for j in (1..=k.min(M)).rev() { for s in (k..=smax).rev() { ways[j][s] += ways[j - 1][s - k]; } }
    }
    let cu: Vec<u64> = (0..=M * M).map(|u| ways[M][u + 36]).collect();   // rank sum = U + 36
    let total: u64 = cu.iter().sum();
    let low: u64 = cu[..=ua as usize].iter().sum();
    show("rank sets in all; with U <= 12", format!("{}; {}", total, low));
    let p_exact = 2.0 * low as f64 / total as f64;
    show("exact p one-sided, two-sided", format!("{:.4}, {:.4}", low as f64 / total as f64, p_exact));
    show("two-sided p by listing every split", format!("{:.4}", exact_p(&a, &b)));
    let emu = cu.iter().enumerate().map(|(u, &c)| u as f64 * c as f64).sum::<f64>() / total as f64;
    let evar = cu.iter().enumerate().map(|(u, &c)| (u as f64 - emu).powi(2) * c as f64).sum::<f64>() / total as f64;
    show("mean and variance of U over all sets", format!("{}, {:.3}", emu, evar));
    let (tw, dfw) = welch(&a, &b);
    show("Welch t, df, p on the raw minutes", format!("{:.3}, {:.2}, {:.4}", tw, dfw, 2.0 * t_tail(tw, dfw)));
    let bins: Vec<String> = (0..13).map(|i| cu[5 * i..5 * i + 5].iter().sum::<u64>().to_string()).collect();
    let bell: Vec<String> = (0..13).map(|i| {
        let (lo, hi) = ((5 * i) as f64 - 0.5, (5 * i) as f64 + 4.5);
        format!("{}", (total as f64 * (norm_cdf((hi - mu) / sd) - norm_cdf((lo - mu) / sd))).round())
    }).collect();
    println!("chart, U in 0-4 ... 60-64, exact: [{}]", bins.join(", "));
    println!("chart, same bins, bell: [{}]", bell.join(", "));
    let lvl = |u: usize| 2.0 * cu[..=u].iter().sum::<u64>() as f64 / total as f64;
    let crit = (0..33).filter(|&u| lvl(u) <= 0.05).max().unwrap();
    show("5% cut-off: reject when U <=, exact level", format!("{}, {:.4}", crit, lvl(crit)));
    let mut a2 = a; a2[7] = 50.0;
    let (t2, df2) = welch(&a2, &b);
    show("A's 5.0 typed as 50.0: U, exact p, Welch p", format!("{}, {:.4}, {:.4}", u_pairs(&a2, &b), exact_p(&a2, &b), 2.0 * t_tail(t2, df2)));
    let after = [2.9, 2.5, 3.4, 3.2, 4.0, 3.9, 3.8, 5.1];   // shop B's 8 regulars, after a second barista
    let d: Vec<f64> = (0..8).map(|i| ((b[i] - after[i]) * 100.0).round() / 100.0).collect();
    let rd = midranks(&d.iter().map(|x| x.abs()).collect::<Vec<_>>());
    let wp: f64 = (0..8).filter(|&i| d[i] > 0.0).map(|i| rd[i]).sum();
    let wm: f64 = (0..8).filter(|&i| d[i] < 0.0).map(|i| rd[i]).sum();
    show("paired drops, before - after", join(&d));
    show("ranks of the sizes (ties share 3.5)", join(&rd));
    show("W+ and W-", format!("{}, {}", wp, wm));
    let pats: Vec<f64> = (0..256u32).map(|mk| (0..8).filter(|i| mk >> i & 1 == 1).map(|i| rd[i]).sum()).collect();
    let k = pats.iter().filter(|&&w| w <= wm).count();
    show("sign patterns in all; with W- <= 1", format!("{}; {}", pats.len(), k));
    show("exact signed-rank p two-sided", format!("{:.4}", 2.0 * k as f64 / 256.0));
    let (wmu, wv): (f64, f64) = (8.0 * 9.0 / 4.0, 8.0 * 9.0 * 17.0 / 24.0);
    let wvt = wv - (8.0 - 2.0) / 48.0;
    let evw = pats.iter().map(|w| (w - wmu).powi(2)).sum::<f64>() / 256.0;
    show("W null mean, variance, tie-corrected", format!("{}, {}, {:.3}", wmu, wv, wvt));
    let zw = (wp - 0.5 - wmu) / wvt.sqrt();
    show("signed-rank z with half-step, bell p", format!("{:.3}, {:.4}", zw, 2.0 * norm_tail(zw)));
    let (md, vd) = mean_var(&d);
    let tp = md / (vd / 8.0).sqrt();
    show("paired t, p (7 df)", format!("{:.3}, {:.4}", tp, 2.0 * t_tail(tp, 7.0)));
    show("pairing ignored: U after vs before, exact p", format!("{}, {:.4}", u_pairs(&after, &b), exact_p(&after, &b)));
    let shapes: Vec<(&str, Box<dyn Fn(f64) -> f64>, f64, f64)> = vec![
        ("normal", Box::new(|x: f64| (-x * x / 2.0).exp() / (2.0 * PI).sqrt()), 1.0, 12.0),
        ("logistic", Box::new(|x: f64| (-x).exp() / (1.0 + (-x).exp()).powi(2)), PI * PI / 3.0, 40.0),
        ("Laplace", Box::new(|x: f64| 0.5 * (-x.abs()).exp()), 2.0, 40.0),
        ("uniform", Box::new(|_x: f64| 1.0), 1.0 / 12.0, 0.5)];
    let are: Vec<f64> = shapes.iter().map(|(_, f, var, l)| 12.0 * var * simpson(&|x: f64| f(x).powi(2), -l, *l).powi(2)).collect();
    let parts: Vec<String> = shapes.iter().zip(&are).map(|(s, v)| format!("{} {:.3}", s.0, v)).collect();
    println!("efficiency of rank test vs t: {}", parts.join(", "));
    show("3/pi; rank-test sample matching t-test's 100", format!("{:.4}; {:.1}", 3.0 / PI, 100.0 / are[0]));
    let mut tcut = 2.0;
    for i in 0..60 { tcut += 2f64.powi(-(i + 1)) * if t_tail(tcut, 14.0) > 0.025 { 1.0 } else { -1.0 }; }   // bisect the t cut-off, 14 df
    show("lowest efficiency over all shapes, 108/125", format!("{:.3}", 108.0 / 125.0));
    show("t cut-off, 14 df", format!("{:.4}", tcut));
    let chi14 = |v: f64| v.powi(6) * (-v / 2.0).exp() / (128.0 * 720.0);   // chi-square density, 14 df
    let nc = 1.0 / (2.0f64 / 8.0).sqrt();     // a shift of one spread over its standard error
    let exact_pow = simpson(&|v: f64| chi14(v) * (norm_cdf(nc - tcut * (v / 14.0).sqrt()) + norm_cdf(-nc - tcut * (v / 14.0).sqrt())), 0.0, 100.0);
    show("t-test power at 1 spread, exact (noncentral t)", format!("{:.3}", exact_pow));
    let mut power_t = 0.0;
    for shift in [1.0, 0.0] {
        let mut s: u64 = 20261123;             // each pass reruns the same random stream
        let mut unif = || {                    // 64-bit linear congruential generator
            s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            ((s >> 11) + 1) as f64 / 2f64.powi(53)
        };
        for kind in ["normal", "Laplace"] {
            let (mut hits_t, mut hits_u) = (0, 0);
            let mut draw = || if kind == "normal" { let u1 = unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * unif()).cos() }
                              else { let u1 = unif(); (u1 / unif()).ln() / 2f64.sqrt() };
            for _ in 0..20000 {                // 8 waits per shop, B slower by the shift, in spreads
                let x: Vec<f64> = (0..8).map(|_| draw()).collect();
                let y: Vec<f64> = (0..8).map(|_| draw() + shift).collect();
                let t = (y.iter().sum::<f64>() - x.iter().sum::<f64>()) / 8.0 / ((mean_var(&x).1 + mean_var(&y).1) / 8.0).sqrt();
                let u = u_pairs(&x, &y);
                if t.abs() > tcut { hits_t += 1; }
                if u <= crit as f64 || u >= (M * M - crit) as f64 { hits_u += 1; }
            }
            if shift == 1.0 && kind == "normal" { power_t = hits_t as f64 / 20000.0; }
            show(&format!("power at {} spread, {}: t-test, rank test", shift, kind), format!("{:.3}, {:.3}", hits_t as f64 / 20000.0, hits_u as f64 / 20000.0));
        }
    }
    let mut b70 = b; b70[7] = 70.0;
    let (t3, df3) = welch(&a, &b70);
    show("try: B's 7.0 typed as 70.0: U, exact p, Welch p", format!("{}, {:.4}, {:.4}", u_pairs(&a, &b70), exact_p(&a, &b70), 2.0 * t_tail(t3, df3)));
    let d3: Vec<f64> = (0..8).map(|i| ((b[i] - if i == 0 { 2.3 } else { after[i] }) * 100.0).round() / 100.0).collect();
    let r3 = midranks(&d3.iter().map(|x| x.abs()).collect::<Vec<_>>());
    let w3 = (0..8).filter(|&i| d3[i] < 0.0).fold(0.0, |t, i| t + r3[i]);   // fold from +0.0: an empty sum prints 0
    let k3 = (0..256u32).filter(|&mk| (0..8).filter(|i| mk >> i & 1 == 1).map(|i| r3[i]).sum::<f64>() <= w3).count();
    show("try: first after-wait 2.3: W-, patterns, p", format!("{}, {}, {:.4}", w3, k3, 2.0 * k3 as f64 / 256.0));
    assert!(cu.iter().rev().eq(cu.iter()) && total == (1..=8u64).fold(1u64, |c, i| c * (8 + i) / i) && u_pairs(&a, &b) == ua);   // symmetry; pairs = ranks
    assert!((exact_p(&a, &b) - p_exact).abs() < 1e-12);   // DP count against the full list of splits
    assert!((emu - mu).abs() < 1e-9 && (evar - sd * sd).abs() < 1e-9);   // null mean and variance
    assert!(k == 2 && (pats.iter().sum::<f64>() / 256.0 - wmu).abs() < 1e-9 && (evw - wvt).abs() < 1e-9);
    assert!((are[0] - 3.0 / PI).abs() < 1e-6 && (are[2] - 1.5).abs() < 1e-6);
    assert!((2.0 * norm_tail(zc) - p_exact).abs() < 0.01 && (tcut - 2.144787).abs() < 1e-5);
    assert!((power_t - exact_pow).abs() < 0.02);   // simulated t-test power against the noncentral t law
    println!("ALL CHECKS PASS");
}
