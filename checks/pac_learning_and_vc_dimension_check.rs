// PAC learning and VC dimension: how many labelled sales pin down a hidden price cap.
// Standard library only, no crates. The same roads as the Python check: closed-form bounds,
// brute-force labelling counts, exact failure chances, and a seeded SplitMix64 simulation.
use std::collections::{BTreeSet, HashSet};

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unit(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}

fn pw(b: f64, n: u64) -> f64 { let mut r = 1.0; for _ in 0..n { r *= b; } r }

const LO: f64 = 2000.0; const HI: f64 = 4000.0; const CAP: f64 = 3150.0;
const EPS: f64 = 0.05; const DELTA: f64 = 0.01; const W: f64 = HI - LO;

fn cands(pts: &[i64]) -> Vec<i64> {
    let mut s = pts.to_vec(); s.sort();
    let mut c = vec![s[0] - 1]; c.extend(s); c
}
fn caps(pts: &[i64]) -> usize {
    let c = cands(pts);
    c.iter().map(|&t| pts.iter().map(|&p| (p <= t) as u8).collect::<Vec<u8>>()).collect::<BTreeSet<_>>().len()
}
fn intervals(pts: &[i64]) -> usize {
    let c = cands(pts);
    let mut out = BTreeSet::new();
    for &a in &c { for &b in &c { out.insert(pts.iter().map(|&p| (a < p && p <= b) as u8).collect::<Vec<u8>>()); } }
    out.len()
}
fn subsets(n: usize, k: usize, start: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == k { out.push(cur.clone()); return; }
    for i in start..n { cur.push(i); subsets(n, k, i + 1, cur, out); cur.pop(); }
}
fn vc(family: fn(&[i64]) -> usize, pts: &[i64]) -> usize {
    let mut d = 0;
    for k in 1..5 {
        let mut all = Vec::new(); subsets(pts.len(), k, 0, &mut Vec::new(), &mut all);
        if all.iter().any(|s| family(&s.iter().map(|&i| pts[i]).collect::<Vec<i64>>()) == 1 << k) { d = k; }
    }
    d
}
fn comb(n: u64, k: u64) -> u64 { let mut r = 1u64; for i in 0..k { r = r * (n - i) / (i + 1); } r }
fn sauer(n: u64, d: u64) -> u64 { (0..=d).map(|i| comb(n, i)).sum() }
fn finite(size: f64) -> u64 { ((size.ln() + (1.0 / DELTA).ln()) / EPS).ceil() as u64 }
fn fail_any(m: u64) -> f64 { 2.0 * pw(1.0 - EPS, m) - pw(1.0 - 2.0 * EPS, m) }
fn vc_m(growth: &dyn Fn(u64) -> f64) -> u64 {
    let mut m = (8.0 / EPS).ceil() as u64;
    while 2.0 * growth(2 * m) * (-EPS * m as f64 / 2.0 * (2.0f64).ln()).exp() > DELTA { m += 1; }
    m
}

fn main() {
    let log: Vec<i64> = vec![2240, 3895, 2710, 3320, 3085, 2475, 3605, 2960, 3210, 2150];
    let lab: Vec<bool> = log.iter().map(|&p| p as f64 <= CAP).collect();
    let a10 = log.iter().zip(&lab).filter(|x| *x.1).map(|x| *x.0).max().unwrap();
    let r10 = log.iter().zip(&lab).filter(|x| !*x.1).map(|x| *x.0).min().unwrap();
    println!("log: {} of {} approved; highest approved {}p, lowest refused {}p", lab.iter().filter(|&&l| l).count(), log.len(), a10, r10);
    println!("learned cap error {:.4}; error at top of fitting range {:.4}", (CAP - a10 as f64) / W, (r10 as f64 - CAP) / W);

    let (vc_c, vc_i) = (vc(caps, &log), vc(intervals, &log));
    println!("VC dimension by brute force: caps {}, price bands {}", vc_c, vc_i);
    for n in [3usize, 10] {
        println!("labellings of {} quotes: caps {} (Sauer {}), bands {} (Sauer {}), all {}",
                 n, caps(&log[..n]), sauer(n as u64, 1), intervals(&log[..n]), sauer(n as u64, 2), 1u64 << n);
    }
    assert!(vc_c == 1 && vc_i == 2);
    for n in 1..=10usize {
        assert!(caps(&log[..n]) == n + 1 && (n + 1) as u64 == sauer(n as u64, 1));
        assert!(intervals(&log[..n]) as u64 == sauer(n as u64, 2));
    }

    let (m_fin, m_tenth, m_hund) = (finite(2001.0), finite(20001.0), finite(200001.0));
    let m_dir = ((2.0 / DELTA).ln() / EPS).ceil() as u64;
    let m_one = ((1.0 / DELTA).ln() / EPS).ceil() as u64;
    let m_ex = (1..1000u64).find(|&m| fail_any(m) <= DELTA).unwrap();
    let m_vc = vc_m(&|n| (n + 1) as f64);
    let m_vcs = vc_m(&|n| std::f64::consts::E * n as f64);
    let m_vci = vc_m(&|n| sauer(n, 2) as f64);
    let m_ag = ((2.0 * 2001.0 / DELTA).ln() / (2.0 * EPS * EPS)).ceil() as u64;
    let m_ag2 = ((2.0 * 2001.0 / DELTA).ln() / (2.0 * (EPS / 2.0) * (EPS / 2.0))).ceil() as u64;
    println!("union bound, 2,001 penny caps: {}; tenth-penny caps: {}; hundredth: {}", m_fin, m_tenth, m_hund);
    println!("VC bound, d = 1, exact growth 2m + 1: {}; Sauer growth 2em: {}; bands d = 2: {}", m_vc, m_vcs, m_vci);
    println!("direct two-sided bound: {}; exact smallest m: {}; one side only: {}", m_dir, m_ex, m_one);
    println!("failure chance at {}: {:.5}; at {}: {:.5}", m_ex, fail_any(m_ex), m_ex - 1, fail_any(m_ex - 1));
    println!("failure chance at {}, guarding one side: {:.5}", m_one, fail_any(m_one));
    println!("noisy labels, finite caps, 1/eps^2 bound: {} (every log error within eps, so chosen cap within 2 eps of best), {} (chosen cap within eps of best)", m_ag, m_ag2);
    let vcv = |m: u64| (2 * (2 * m + 1)) as f64 * (-EPS * m as f64 / 2.0 * (2.0f64).ln()).exp();
    println!("hand: ln 2001 = {:.4}, ln 100 = {:.4}, ln 200 = {:.4}, 5% = {:.0}p, 8/eps = {}", (2001.0f64).ln(), (100.0f64).ln(), (200.0f64).ln(), EPS * W, (8.0 / EPS).ceil() as u64);
    println!("hand: 0.95^{} = {:.5}, 0.90^{} = {:.7}", m_ex, pw(1.0 - EPS, m_ex), m_ex, pw(1.0 - 2.0 * EPS, m_ex));
    println!("hand: VC bound at {}: growth {}, power of 2 {:.3}, value {:.5}; at {}: {:.5}", m_vc, 2 * m_vc + 1, -EPS * m_vc as f64 / 2.0, vcv(m_vc), m_vc - 1, vcv(m_vc - 1));
    for (e, dl) in [(0.05f64, 0.001f64), (0.01, 0.01)] {
        let ex = (1..10000u64).find(|&k| 2.0 * pw(1.0 - e, k) - pw(1.0 - 2.0 * e, k) <= dl).unwrap();
        println!("try eps {}, delta {}: direct {}, exact {}", e, dl, ((2.0 / dl).ln() / e).ceil() as u64, ex);
    }
    assert!(m_ex <= m_dir && m_dir <= m_fin && m_fin < m_vc && fail_any(m_dir) <= 2.0 * (-EPS * m_dir as f64).exp());
    assert!(fail_any(m_one) > DELTA && m_tenth > m_fin);

    let mut rng = SplitMix64 { s: 20261119 };
    let (n_logs, m) = (20000u64, m_dir);
    let (mut bad1, mut bad2, mut tot, mut sq) = (0u64, 0u64, 0.0f64, 0.0f64);
    for _ in 0..n_logs {
        let (mut a, mut r) = (LO, HI);
        for _ in 0..m {
            let p = LO + W * rng.unit();
            if p <= CAP { if p > a { a = p; } } else if p < r { r = p; }
        }
        let (e1, e2) = ((CAP - a) / W, (r - CAP) / W);
        tot += e1; sq += e1 * e1;
        if e1 > EPS { bad1 += 1; }
        if e1 > EPS || e2 > EPS { bad2 += 1; }
    }
    let nf = n_logs as f64;
    let (f1, f2, mean) = (bad1 as f64 / nf, bad2 as f64 / nf, tot / nf);
    let (x1, x2) = (pw(1.0 - EPS, m), fail_any(m));
    let xmean = (1.0 - pw(1.0 - (CAP - LO) / W, m + 1)) / (m + 1) as f64;
    println!("simulated {} logs of {}: learned cap bad {:.5} (exact {:.5}), some consistent cap bad {:.5} (exact {:.5})", n_logs, m, f1, x1, f2, x2);
    println!("mean error of learned cap {:.5} (exact {:.5})", mean, xmean);
    assert!((f1 - x1).abs() < 4.0 * (x1 * (1.0 - x1) / nf).sqrt());
    assert!((f2 - x2).abs() < 4.0 * (x2 * (1.0 - x2) / nf).sqrt());
    assert!((mean - xmean).abs() < 4.0 * ((sq / nf - mean * mean) / nf).sqrt());

    let train: Vec<f64> = (0..m).map(|_| LO + W * rng.unit()).collect();
    let seen: HashSet<u64> = train.iter().filter(|&&p| p <= CAP).map(|p| p.to_bits()).collect();
    let trn = train.iter().filter(|&&p| seen.contains(&p.to_bits()) != (p <= CAP)).count() as f64 / m as f64;
    let t = 10000u64;
    let mut wrong = 0u64;
    for _ in 0..t { let p = LO + W * rng.unit(); if seen.contains(&p.to_bits()) != (p <= CAP) { wrong += 1; } }
    let mem = wrong as f64 / t as f64;
    println!("memoriser: training error {:.4}, test error {:.4} (exact {:.4})", trn, mem, (CAP - LO) / W);
    assert!((mem - 0.575).abs() < 4.0 * (0.575f64 * 0.425 / t as f64).sqrt());
    let mut a = LO;
    for _ in 0..m { let p = LO + 500.0 * rng.unit(); if p > a { a = p; } }
    println!("promotion log, all quotes under 2500p: learned cap {:.0}p, error {:.4}", a, (CAP - a) / W);
    assert!(0.325 < (CAP - a) / W && (CAP - a) / W < 0.33);

    let mut bad = 0u64;
    for _ in 0..n_logs {
        let xs: Vec<f64> = (0..20).map(|_| LO + W * rng.unit()).collect();
        if xs.iter().all(|&p| !(CAP - EPS * W < p && p <= CAP)) || xs.iter().all(|&p| !(CAP < p && p <= CAP + EPS * W)) { bad += 1; }
    }
    let (fb, x20) = (bad as f64 / nf, fail_any(20));
    println!("simulated {} logs of 20, strips checked directly: some consistent cap bad {:.5} (exact {:.5}, overlap term dropped {:.5})", n_logs, fb, x20, 2.0 * pw(1.0 - EPS, 20));
    assert!((fb - x20).abs() < 4.0 * (x20 * (1.0 - x20) / nf).sqrt());

    let ms: Vec<u64> = (0..=200).step_by(20).collect();
    println!("chart, sales {}", ms.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, exact {}", ms.iter().map(|&k| format!("{:.3}", fail_any(k))).collect::<Vec<_>>().join(" "));
    println!("chart, bound {}", ms.iter().map(|&k| format!("{:.3}", (2.0 * (-EPS * k as f64).exp()).min(1.0))).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
