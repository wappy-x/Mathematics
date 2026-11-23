// Random projection card check: 30 songs with 10,000 features squashed to 100 by a
// matrix of normal draws. Roads: the real projection, the exact chi-square law of one
// squared length, Chernoff's bound above it, and a seeded simulation. std only.
use std::f64::consts::PI;

struct SplitMix64 { s: u64 } // small seeded generator, explained on wing 09's simulation cards
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 9007199254740992.0 }
    fn normal(&mut self) -> f64 { // Box-Muller: two uniforms make one standard normal draw
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn sqdist(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y) * (x - y)).sum() }

fn chi2_cdf(x: f64, k: usize) -> f64 { // Pr[sum of k squared normals <= x], k even: a Poisson sum
    let (mut term, mut total) = ((-x / 2.0).exp(), 0.0);
    for j in 0..k / 2 {
        total += term;
        term *= (x / 2.0) / (j as f64 + 1.0);
    }
    1.0 - total
}
fn tail_exact(e: f64, k: usize) -> f64 { chi2_cdf(k as f64 * (1.0 - e), k) + 1.0 - chi2_cdf(k as f64 * (1.0 + e), k) }
fn tail_chernoff(e: f64, k: usize) -> f64 {
    let h = k as f64 / 2.0;
    ((1.0 + e) * (-e).exp()).powf(h) + ((1.0 - e) * e.exp()).powf(h)
}
fn nearest(v: &[Vec<f64>], s: usize) -> usize { // first song at the smallest distance
    (0..v.len()).filter(|&t| t != s).fold(usize::MAX, |b, t| if b == usize::MAX || sqdist(&v[s], &v[t]) < sqdist(&v[s], &v[b]) { t } else { b })
}

fn main() {
    let (d, k, n) = (10000usize, 100usize, 30usize);
    let (g, sk) = (["folk", "rock", "dance"], (k as f64).sqrt());
    let mut rng = SplitMix64 { s: 2026 };
    let centres: Vec<Vec<f64>> = (0..3).map(|_| (0..d).map(|_| rng.normal()).collect()).collect();
    let songs: Vec<Vec<f64>> = (0..n).map(|s| centres[s / 10].iter().map(|c| c + rng.normal()).collect()).collect();
    let genre: Vec<usize> = (0..n).map(|s| s / 10).collect();
    let mut pairs = vec![];
    for a in 0..n { for b in a + 1..n { pairs.push((a, b)); } }
    let true2: Vec<f64> = pairs.iter().map(|&(a, b)| sqdist(&songs[a], &songs[b])).collect();
    let diff01: Vec<f64> = songs[0].iter().zip(&songs[1]).map(|(x, y)| x - y).collect();
    let (mut proj, mut pdiff) = (vec![vec![0.0; k]; n], vec![0.0; k]);
    let (mut col7000, mut first101) = (vec![], vec![]);
    for i in 0..k {
        let row: Vec<f64> = (0..d).map(|_| rng.normal()).collect();
        for s in 0..n { proj[s][i] = dot(&row, &songs[s]) / sk; }
        pdiff[i] = dot(&row, &diff01) / sk;
        col7000.push(row[6999]);
        first101.push(row[..101].to_vec());
    }
    println!("songs {} in 3 genres, features d = {}, kept k = {}, pairs {}, seed 2026", n, d, k, pairs.len());
    let lin = (0..k).map(|i| (proj[0][i] - proj[1][i] - pdiff[i]).abs()).fold(0.0, f64::max);
    println!("linearity: f(u) - f(v) against f(u - v), largest gap below 1e-9: {}", if lin < 1e-9 { "True" } else { "False" });
    assert!(lin < 1e-9);
    let ys: Vec<f64> = pairs.iter().enumerate().map(|(p, &(a, b))| sqdist(&proj[a], &proj[b]) / true2[p]).collect();
    for &(a, b) in &[(0usize, 1usize), (0, 10), (10, 20)] {
        let p = pairs.iter().position(|&q| q == (a, b)).unwrap();
        let (t, q) = (true2[p].sqrt(), sqdist(&proj[a], &proj[b]).sqrt());
        println!("song {} ({}) to song {} ({}): distance {:.2}, projected {:.2}, squared ratio {:.4}",
            a + 1, g[genre[a]], b + 1, g[genre[b]], t, q, q * q / (t * t));
    }
    let np = ys.len() as f64;
    let m = ys.iter().sum::<f64>() / np;
    let sd = (ys.iter().map(|y| (y - m) * (y - m)).sum::<f64>() / (np - 1.0)).sqrt();
    let (ymin, ymax) = (ys.iter().cloned().fold(f64::MAX, f64::min), ys.iter().cloned().fold(0.0, f64::max));
    println!("squared ratio over {} pairs: mean {:.4} sd {:.4} min {:.4} max {:.4}", ys.len(), m, sd, ymin, ymax);
    println!("distance ratio over {} pairs: min {:.4} max {:.4}", ys.len(), ymin.sqrt(), ymax.sqrt());
    let th = (2.0 / k as f64).sqrt();
    println!("theory: mean 1, sd sqrt(2/k) = {:.4}", th);
    let mut parts = vec![];
    for (gg, hh) in [(0, 0), (0, 1), (0, 2), (1, 1), (1, 2), (2, 2)] {
        let v: Vec<f64> = (0..pairs.len()).filter(|&p| (genre[pairs[p].0], genre[pairs[p].1]) == (gg, hh)).map(|p| ys[p]).collect();
        parts.push(format!("{}-{} {:.4}", g[gg], g[hh], v.iter().sum::<f64>() / v.len() as f64));
    }
    println!("mean squared ratio by genre pair: {}", parts.join(", "));
    assert!((m - 1.0).abs() < 0.05 && (sd - th).abs() < 0.25 * th);
    let mut edges = vec![0.0]; for j in 0..10 { edges.push(0.6 + 0.1 * j as f64); } edges.push(99.0);
    for w in edges.windows(2) {
        let (lo, hi) = (w[0], w[1]);
        let obs = ys.iter().filter(|&&y| lo <= y && y < hi).count();
        let en = np * (chi2_cdf(k as f64 * hi, k) - chi2_cdf(k as f64 * lo, k));
        println!("bin {:.1}-{:.1}: {:25} observed {:3} expected {:6.1}", lo, hi.min(9.0), "#".repeat((obs + 2) / 4), obs, en);
    }
    let (mut sim, tt) = (SplitMix64 { s: 7 }, 20000usize);
    let simy: Vec<f64> = (0..tt).map(|_| (0..k).map(|_| { let z = sim.normal(); z * z }).sum::<f64>() / k as f64).collect();
    for &e in &[0.2f64, 0.5] {
        let (ex, ch) = (tail_exact(e, k), tail_chernoff(e, k));
        let obs = ys.iter().filter(|&&y| (y - 1.0).abs() > e).count() as f64 / np;
        let sf = simy.iter().filter(|&&y| (y - 1.0).abs() > e).count() as f64 / tt as f64;
        println!("outside 1 +/- {}: pairs {:.4}, exact {:.6}, Chernoff bound {:.6}, simulated {} {:.5}", e, obs, ex, ch, tt, sf);
        assert!(ex <= ch, "the bound must sit above the exact tail");
        assert!((sf - ex).abs() <= 4.0 * (ex * (1.0 - ex) / tt as f64).sqrt() + 1e-4);
        let (lw, lf) = (chi2_cdf(k as f64 * (1.0 - e), k), simy.iter().filter(|&&y| y < 1.0 - e).count() as f64 / tt as f64); // lower side alone
        assert!((lf - lw).abs() <= 4.0 * (lw * (1.0 - lw) / tt as f64).sqrt() + 1e-4);
    }
    let (mut lo_e, mut hi_e) = (0.01f64, 0.99f64); // smallest eps whose union bound over 435 pairs is <= 0.1
    for _ in 0..60 {
        let mid = (lo_e + hi_e) / 2.0;
        if np * tail_chernoff(mid, k) <= 0.1 { hi_e = mid; } else { lo_e = mid; }
    }
    let worst = ys.iter().map(|y| (y - 1.0).abs()).fold(0.0, f64::max);
    let (ub, lb) = (1.5 * (-0.5f64).exp(), 0.5 * 0.5f64.exp());
    println!("hand, eps 0.5: upper base {:.6}, to the 50th {:.6}; lower base {:.6}, to the 50th {:.6}; {} pairs x {:.6} = {:.4}",
        ub, ub.powf(50.0), lb, lb.powf(50.0), pairs.len(), tail_chernoff(0.5, k), np * tail_chernoff(0.5, k));
    let (l30, c5) = ((30.0 * 29.0 / 0.1f64).ln(), 0.5f64.powi(2) / 2.0 - 0.5f64.powi(3) / 3.0);
    println!("hand, n = 30: ln(870/0.1) = {:.4}, c(0.5) = {:.6}, k = {}", l30, c5, (2.0 * l30 / c5).ceil());
    println!("union bound, k = {}, {} pairs, failure 0.1: eps {:.4}; run's worst {:.4}", k, pairs.len(), hi_e, worst);
    assert!(worst <= hi_e);
    let p4: Vec<Vec<f64>> = (0..n).map(|s| (0..4).map(|i| proj[s][i] * sk / 2.0).collect()).collect();
    let nn0: Vec<usize> = (0..n).map(|s| nearest(&songs, s)).collect();
    println!("before: nearest song in own genre {}/{}", (0..n).filter(|&s| genre[nn0[s]] == genre[s]).count(), n);
    for (name, vecs) in [("k = 100", &proj), ("k = 4", &p4)] {
        let nn: Vec<usize> = (0..n).map(|s| nearest(vecs, s)).collect();
        let same_g = (0..n).filter(|&s| genre[nn[s]] == genre[s]).count();
        let same_s = (0..n).filter(|&s| nn[s] == nn0[s]).count();
        println!("{}: nearest song in own genre {}/{}, same nearest song as before {}/{}", name, same_g, n, same_s, n);
        if name == "k = 100" { assert!(same_g == n); }
    }
    let r4: Vec<f64> = pairs.iter().enumerate().map(|(p, &(a, b))| sqdist(&p4[a], &p4[b]) / true2[p]).collect();
    println!("k = 4: squared ratio min {:.4} max {:.4}", r4.iter().cloned().fold(f64::MAX, f64::min), r4.iter().cloned().fold(0.0, f64::max));
    println!("no 1/sqrt(k) scale: mean squared ratio {:.2}", m * k as f64);
    let mut e = vec![0.0f64; d]; e[6999] = 10.0; // two versions of one song, 10 apart in feature 7000 only
    let keep100 = e[..k].iter().map(|x| ((d as f64 / k as f64).sqrt() * x).powi(2)).sum::<f64>().sqrt();
    let jump = col7000.iter().map(|c| (10.0 * c / sk).powi(2)).sum::<f64>().sqrt();
    println!("pair 10 apart in feature 7000 only: first 100 features keep {:.2}, random keeps {:.2}", keep100, jump);
    for &nn in &[30u64, 1000, 1000000] { // counted multiply-adds for every pair's distance
        let (direct, viaproj) = (nn * (nn - 1) / 2 * d as u64, nn * (k * d) as u64 + nn * (nn - 1) / 2 * k as u64);
        println!("cost, n = {}: all pairs directly {}, project then compare {}", nn, direct, viaproj);
    }
    println!("dims needed, failure 0.1: n eps=0.5 eps=0.2");
    for e10 in 1..10 {
        let nf = 10f64.powi(e10);
        let ks: Vec<f64> = [0.5f64, 0.2].iter().map(|&e| (2.0 * (nf * (nf - 1.0) / 0.1).ln() / (e * e / 2.0 - e.powi(3) / 3.0)).ceil()).collect();
        println!("n=1e{} {} {}", e10, ks[0], ks[1]);
    }
    let mut a: Vec<Vec<f64>> = first101.iter().map(|r| r[..100].to_vec()).collect();
    let mut bv: Vec<f64> = first101.iter().map(|r| -r[100]).collect();
    for c in 0..100 { // Gaussian elimination: a pair chosen after seeing the matrix
        let mut piv = c;
        for r in c + 1..100 { if a[r][c].abs() > a[piv][c].abs() { piv = r; } }
        a.swap(c, piv);
        bv.swap(c, piv);
        for r in c + 1..100 {
            let f = a[r][c] / a[c][c];
            for j in c..100 { a[r][j] -= f * a[c][j]; }
            bv[r] -= f * bv[c];
        }
    }
    let mut z = vec![0.0f64; 101]; z[100] = 1.0;
    for c in (0..100).rev() {
        z[c] = (bv[c] - (c + 1..100).map(|j| a[c][j] * z[j]).sum::<f64>()) / a[c][c];
    }
    let fz = ((0..k).map(|i| dot(&first101[i], &z).powi(2)).sum::<f64>() / k as f64).sqrt();
    let nz = z.iter().map(|v| v * v).sum::<f64>().sqrt();
    println!("pair chosen after the matrix: distance {:.2}, projected below 1e-9: {}", nz, if fz < 1e-9 { "True" } else { "False" });
    assert!(fz < 1e-9);
    println!("ALL CHECKS PASS");
}
