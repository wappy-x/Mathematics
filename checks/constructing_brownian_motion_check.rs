// Building Brownian motion on [0, 1] by Levy's midpoint construction -- the check behind the card.
// Standard library only.  The grain: W(0) = 0, W(1) = 1.2 um.  Level n fills the midpoints of the 2^(n-1) gaps,
// each the average of its two ends plus a normal kick of variance 2^-(n+1).
// Road 1: the kick variance against the bridge formula.  Road 2: the Schauder series' covariance, summed exactly.
// Road 3: one path built by midpoints and again by the tent series.  Road 4: 1000 seeded paths to level 12.
use std::f64::consts::PI;
const W1: f64 = 1.2; const L: usize = 12; const M: usize = 1000;
fn nsum<I: Iterator<Item = f64>>(it: I) -> f64 { // compensated sum, the rule Python's sum() uses for floats
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s } s = t; }
    s + c
}
fn wt(i: usize, m: usize) -> f64 { if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }
fn tail(x: f64) -> f64 { // P(Z > x) for a standard normal Z, Simpson's rule on [x, x + 12]
    let m = 4000; let h = 12.0 / m as f64;
    h / 3.0 * nsum((0..=m).map(|i| wt(i, m) * (-(x + i as f64 * h).powf(2.0) / 2.0).exp())) / (2.0 * PI).sqrt()
}
fn cf(x: f64) -> f64 { // P(Z > x) a second way: Laplace's continued fraction, 200 levels deep
    let mut f = x; for k in (1..=200).rev() { f = x + k as f64 / f } (-x * x / 2.0).exp() / (2.0 * PI).sqrt() / f
}
fn moment(p: f64) -> f64 { // E[Z^p] by Simpson's rule on [-12, 12]
    let m = 4000; let h = 24.0 / m as f64;
    h / 3.0 * nsum((0..=m).map(|i| { let x = i as f64 * h - 12.0; wt(i, m) * x.powf(p) * (-x.powf(2.0) / 2.0).exp() })) / (2.0 * PI).sqrt()
}
fn tent(n: usize, k: usize, t: f64) -> f64 { // Schauder tent of level n, gap k: peak 2^-(n+1)/2 mid-gap
    let w = 2f64.powf(1.0 - n as f64); let u = (t - k as f64 * w) / w;
    if (0.0..=1.0).contains(&u) { 2f64.powf(-(n as f64 + 1.0) / 2.0) * (1.0 - (2.0 * u - 1.0).abs()) } else { 0.0 }
}
fn gap(n: usize, t: f64) -> usize { ((t * 2f64.powf(n as f64 - 1.0)) as usize).min((1 << (n - 1)) - 1) }
fn tent_cov(s: f64, t: f64, nn: usize) -> f64 { nsum((1..=nn).map(|n| tent(n, gap(n, s), s) * tent(n, gap(n, s), t))) }
fn qv_exact(var: &dyn Fn(usize) -> f64, q0: f64) -> f64 { // mean sum of squared steps: q -> q/2 + 2^(n-1) * 2 * var(n)
    let mut q = q0; for n in 1..=L { q = q / 2.0 + (1u64 << n) as f64 * var(n) } q
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // SplitMix64, top 53 bits, never exactly 0 or 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powf(53.0)
    }
    fn normal(&mut self) -> f64 { let r = (-2.0 * self.unif().ln()).sqrt(); r * (2.0 * PI * self.unif()).cos() }
}
fn build(g: &mut Rng) -> (Vec<f64>, Vec<Vec<f64>>) { // levels 1..L of midpoint kicks: path at k/2^L, kicks
    let (mut p, mut zz) = (vec![0.0, W1], Vec::new());
    for n in 1..=L {
        let sd = 2f64.powf(-(n as f64 + 1.0) / 2.0);
        let (mut q, mut zn) = (vec![0.0], Vec::new());
        for w in p.windows(2) { let z = g.normal(); zn.push(z); q.push((w[0] + w[1]) / 2.0 + sd * z); q.push(w[1]); }
        p = q; zz.push(zn);
    }
    (p, zz)
}
fn coarse(p: &[f64], nn: usize, i: usize) -> f64 { // the level-N picture (straight lines) at grid point i
    let s = 1 << (L - nn); let j = i / s; let f = (i - j * s) as f64 / s as f64;
    if f == 0.0 { p[j * s] } else { p[j * s] * (1.0 - f) + p[(j + 1) * s] * f }
}
fn sci(x: f64, d: usize) -> String { // Python's e-format: two-digit exponent with its sign
    let s = format!("{:.*e}", d, x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join(v: &[String]) -> String { v.join(", ") }
fn main() {
    println!("level | gap      | kick variance | bridge formula | kick spread");
    for n in [1usize, 2, 3, 10] {
        let g = 2f64.powf(1.0 - n as f64); let v = 2f64.powf(-(n as f64 + 1.0)); let bv = g / 2.0 * (g / 2.0) / g;
        assert!((v - bv).abs() < 1e-15);
        println!("{:5} | {:.6} | {:.6}      | {:.6}       | {:.4}", n, g, v, bv, v.sqrt());
    }
    let pz = tail(1.2); assert!((pz - cf(1.2)).abs() < 1e-9);
    println!("W(1/2) = 0.6 + 0.5 Z; P(W(1/2) > 1.2) = P(Z > 1.2) = {:.4}", pz);
    println!("Schauder series at s = 0.3, t = 0.4: levels N | Cov st + tents | Var at 0.3 | pinned Var, tents only");
    for nn in [1usize, 2, 4, 8, 16, 30] {
        let (c, v) = (tent_cov(0.3, 0.4, nn), tent_cov(0.3, 0.3, nn));
        println!("  N = {:2} | {:.6} | {:.6} | {:.6}", nn, 0.12 + c, 0.09 + v, v);
    }
    assert!((0.12 + tent_cov(0.3, 0.4, 30) - 0.3).abs() < 1e-8 && (tent_cov(0.3, 0.3, 30) - 0.3 * 0.7).abs() < 1e-8);
    assert!((0.09 + tent_cov(0.3, 0.3, 8) - 0.3).abs() > 1e-4);
    println!("  limits: min(s, t) = 0.300000, Var W(0.3) = 0.300000, pinned 0.3 x 0.7 = 0.210000");
    let (m4, m8) = (moment(4.0), moment(8.0));
    assert!((m4 - 3.0).abs() < 1e-9 && (m8 - 105.0).abs() < 1e-7);
    println!("E[Z^4] = {:.6}, E[Z^8] = {:.6}: E|W(t)-W(s)|^(2p) = (2p-1)!! h^p, Kolmogorov exponent < (p-1)/(2p)", m4, m8);
    for p in [2usize, 4, 10] { println!("  p = {:2}: alpha = {}, beta = {}, paths Holder of every order below {:.4}", p, 2 * p, p - 1, (p - 1) as f64 / (2 * p) as f64) }
    let h = 2f64.powf(-10.0);
    let pm = nsum((1..30).map(|k: i32| (k as f64).powf(4.0) * (-h).exp() * h.powf(k as f64) / nsum((1..=k).map(|j| (j as f64).ln())).exp()));
    assert!((pm - (h + 7.0 * h.powf(2.0) + 6.0 * h.powf(3.0) + h.powf(4.0))).abs() < 1e-15);
    println!("Poisson rate 1, h = 2^-10: E[N_h^4] / h = {:.6}, never below C h^(1+beta)", pm / h);
    let fails: Vec<f64> = (1..=60).map(|n| 2.0 * tail(2.0 * (n as f64).sqrt())).collect();
    assert!((1..=60).all(|n| (fails[n - 1] / (2.0 * cf(2.0 * (n as f64).sqrt())) - 1.0).abs() < 1e-6));
    let pw = |n: usize| 2f64.powf(n as f64 - 1.0);
    let union = nsum((1..=60).map(|n| pw(n) * fails[n - 1]));
    let pfail = 1.0 - nsum((1..=L).map(|n| pw(n) * (1.0 - fails[n - 1]).ln())).exp();
    for n in [1usize, 2, 3, 11] { println!("  level {:2}: {:4} kicks, P(|Z| > 2 sqrt n) = {} <= exp(-2n) = {}", n, 1 << (n - 1), sci(fails[n - 1], 3), sci((-2.0 * n as f64).exp(), 3)) }
    assert!((1..=60).all(|n| fails[n - 1] <= (-2.0 * n as f64).exp()) && pfail <= union);
    println!("Borel-Cantelli sum over all levels {:.4}; exact P(some level 1..{} breaks the cap) {:.4}", union, L, pfail);
    println!("P(a level after 10 breaks it) <= {}", sci(nsum((11..=60).map(|n| pw(n) * fails[n - 1])), 3));
    println!("2/e^2 = {:.4}; 2 sqrt 11 = {:.3}; points after level 10: {}", 2.0 / 2f64.exp(), 2.0 * 11f64.sqrt(), (1 << 10) + 1);
    let caps: Vec<(usize, f64)> = [4usize, 8, 10, 20].iter()
        .map(|&nn| (nn, nsum((nn + 1..200).map(|n| 2.0 * (n as f64).sqrt() * 2f64.powf(-(n as f64 + 1.0) / 2.0))))).collect();
    let bound = |nn: usize| caps.iter().find(|c| c.0 == nn).unwrap().1;
    for &(nn, b) in &caps { // ratio test: after the first cap left, each next one is 1/sqrt 2 to sqrt((N+2)/(N+1)/2) times the last
        let first = 2.0 * ((nn + 1) as f64).sqrt() * (2f64.powf(-(nn as f64)) / 4.0).sqrt(); // 2 sqrt n times the kick spread on a gap 2^-N
        assert!(first / (1.0 - 0.5f64.sqrt()) < b && b < first / (1.0 - ((nn + 2) as f64 / (nn + 1) as f64 / 2.0).sqrt()));
    }
    println!("cap on how far levels after N can move the path: {}", join(&caps.iter().map(|(nn, b)| format!("N = {}: {:.4}", nn, b)).collect::<Vec<_>>()));

    let mut g = Rng(20261123);
    let (mut sh, mut sh2, mut sf, mut sf2, mut sab, mut sqv, mut sq4) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    let mut brk = 0usize; let supn = [4usize, 8]; let mut sup: Vec<Vec<f64>> = vec![Vec::new(), Vec::new()];
    let hn = [4usize, 8, 12]; let hg = [0.25f64, 0.6]; let mut hol = [[0.0f64; 2]; 3];
    let npt = 1usize << L;
    for k in 0..M {
        let (p, zz) = build(&mut g);
        if k == 0 {
            let diff = (0..=npt).step_by(37).map(|i| {
                let t = i as f64 / npt as f64;
                (p[i] - (t * W1 + nsum((1..=L).map(|n| zz[n - 1][gap(n, t)] * tent(n, gap(n, t), t))))).abs()
            }).fold(0.0f64, f64::max);
            assert!(diff < 1e-12);
            println!("path 1: kick at 1/2 = {:.4}, W(1/2) = {:.4}; midpoints vs tent series at {} times, largest gap {}", zz[0][0], p[2048], (0..=npt).step_by(37).count(), sci(diff, 1));
            for nn in [1usize, 2, 4] { println!("chart, level {}: {}", nn, join(&(0..17).map(|i| format!("{:.2}", coarse(&p, nn, i * 256))).collect::<Vec<_>>())) }
        }
        let bad = (1..=L).any(|n| zz[n - 1].iter().fold(0.0f64, |a, z| a.max(z.abs())) > 2.0 * (n as f64).sqrt());
        brk += bad as usize;
        sh += p[2048]; sh2 += p[2048].powf(2.0); sf += p[1280]; sf2 += p[1280].powf(2.0); sab += (p[2048] > 1.2) as u8 as f64;
        let d: Vec<f64> = p.windows(2).map(|w| w[1] - w[0]).collect();
        sqv += nsum(d.iter().map(|x| x * x)); sq4 += nsum(d.iter().map(|x| x.powf(4.0))) * npt as f64;
        for (j, &nn) in supn.iter().enumerate() {
            let s = (0..=npt).map(|i| (p[i] - coarse(&p, nn, i)).abs()).fold(0.0f64, f64::max);
            sup[j].push(s); assert!(bad || s <= bound(nn));
        }
        for (a, &n) in hn.iter().enumerate() { for (b, &gm) in hg.iter().enumerate() { let s = 1 << (L - n);
            hol[a][b] += (0..npt).step_by(s).map(|i| (p[i + s] - p[i]).abs()).fold(0.0f64, f64::max) * 2f64.powf(n as f64 * gm) / M as f64;
        } }
    }
    let mf_ = M as f64;
    let se = |m: f64, m2: f64| ((m2 / mf_ - (m / mf_).powf(2.0)) / mf_).sqrt();
    let (mh, vh) = (sh / mf_, sh2 / mf_ - (sh / mf_).powf(2.0)); let (mf, vf) = (sf / mf_, sf2 / mf_ - (sf / mf_).powf(2.0));
    let pa = sab / mf_; let sa = (pa * (1.0 - pa) / mf_).sqrt();
    println!("{} paths to level {} ({} steps): W(1/2) mean {:.4} (0.6), variance {:.4} (0.25); W(5/16) mean {:.4} (0.375), variance {:.4} (0.2148)", M, L, npt, mh, vh, mf, vf);
    println!("  P(W(1/2) > 1.2) {:.4}, standard error {:.4} (exact {:.4})", pa, sa, pz);
    assert!((mh - 0.6).abs() < 4.0 * se(sh, sh2) && (pa - pz).abs() < 4.0 * sa && (vh - 0.25).abs() < 4.0 * 0.25 * (2.0 / mf_).sqrt());
    let hs = 2f64.powf(-(L as f64)); let v = hs * (1.0 - hs); let mu = W1 * hs;
    let q4 = (3.0 * v * v + 6.0 * v * mu * mu + mu.powf(4.0)) / hs.powf(2.0);
    let qr = qv_exact(&|n| 2f64.powf(-(n as f64 + 1.0)), W1.powf(2.0));
    println!("  sum of squared steps {:.6} (exact mean {:.6}); mean step^4 / h^2 {:.4} (exact {:.4})", sqv / mf_, qr, sq4 / mf_, q4);
    assert!((sqv / mf_ - qr).abs() < 4.0 * (2.0 / npt as f64 / mf_).sqrt() && (sq4 / mf_ - q4).abs() < 4.0 * (96.0 / npt as f64 / mf_).sqrt());
    let bf = brk as f64 / mf_; let sb = (bf * (1.0 - bf) / mf_).sqrt();
    println!("  paths where some level broke the cap: {} of {} = {:.4}, standard error {:.4} (exact {:.4})", brk, M, bf, sb, pfail);
    assert!((bf - pfail).abs() < 4.0 * sb);
    for (j, &nn) in supn.iter().enumerate() {
        let mean = nsum(sup[j].iter().copied()) / mf_; let worst = sup[j].iter().fold(0.0f64, |a, &b| a.max(b));
        println!("  level {} to level {}: largest move, mean over paths {:.4}, worst {:.4}, cap {:.4}", nn, L, mean, worst, bound(nn));
    }
    for (b, &gm) in hg.iter().enumerate() { println!("  largest step / h^{}: {}", gm, join(&hn.iter().enumerate().map(|(a, &n)| format!("level {}: {:.3}", n, hol[a][b])).collect::<Vec<_>>())) }
    assert!(hol[2][0] < hol[0][0] && hol[2][1] > hol[0][1]);
    let wrong: [(&str, &dyn Fn(usize) -> f64); 2] = [
        ("free variance h/2 for the kick", &|n| 2f64.powf(-(n as f64))),
        ("spread halving, not variance", &|n| 0.25 * 4f64.powf(1.0 - n as f64)),
    ];
    for (name, f) in wrong.iter() { println!("wrong: {}: sum of squared steps at level {} = {:.6} (right {:.6})", name, L, qv_exact(*f, W1.powf(2.0)), qr) }
    let c4 = 2.0 * tail(4.0); // a fixed cap of 4 at every level: the draws double, the cap does not grow
    println!("wrong: fixed cap 4: P(|Z| > 4) = {}; level 20 breaks it with chance {:.4}; Borel-Cantelli sum to level 20 {:.1}", sci(c4, 3), 1.0 - (1.0 - c4).powf(2f64.powf(19.0)), c4 * (2f64.powf(20.0) - 1.0));
    let f3: Vec<f64> = (1..=L).map(|n| 2.0 * tail(3.0 * (n as f64).sqrt())).collect();
    println!("try: W1 = 0: squared steps {:.6}; W1 drawn N(0, 1): Var W(1/2) = {:.6}", qv_exact(&|n| 2f64.powf(-(n as f64 + 1.0)), 0.0), 0.25 + tent_cov(0.5, 0.5, 30));
    println!("try: cap 3 sqrt n: level 1 breaks it {:.4}, some level {:.4}, caps after level 10 {:.4}", f3[0], 1.0 - nsum((1..=L).map(|n| pw(n) * (1.0 - f3[n - 1]).ln())).exp(),
        nsum((11..200).map(|n| 3.0 * (n as f64).sqrt() * 2f64.powf(-(n as f64 + 1.0) / 2.0))));
    println!("ALL CHECKS PASS");
}
