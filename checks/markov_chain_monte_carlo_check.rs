// MCMC check: a seedling's start height a and weekly growth b, posterior sampled three ways.
// Roads: 1 the exact normal posterior by formula; 2 an exact grid, chains pushed with no randomness;
// 3 seeded simulation (SplitMix64, Box-Muller), every simulated number with a batch-means standard error.
use std::f64::consts::PI;
struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn n(&mut self) -> f64 { let u1 = self.u(); let u2 = self.u(); (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos() }
}
const X: [f64; 5] = [1.0, 2.0, 3.0, 4.0, 5.0];
const Y: [f64; 5] = [2.1, 2.9, 4.2, 4.8, 6.0];
const SIG: f64 = 0.5;
const N_: f64 = 5.0; const SX: f64 = 15.0; const SXX: f64 = 55.0;
fn sy() -> f64 { Y.iter().sum() }
fn sxy() -> f64 { X.iter().zip(Y.iter()).map(|(x, y)| x * y).sum() }
fn logf(a: f64, b: f64) -> f64 { -X.iter().zip(Y.iter()).map(|(x, y)| (y - a - b * x).powi(2)).sum::<f64>() / (2.0 * SIG * SIG) }
fn phi(z: f64) -> f64 {
    let m = 400; let h = z.abs() / m as f64;
    let s: f64 = (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * (-0.5 * (i as f64 * h).powi(2)).exp()).sum();
    let v = 0.5 + s * h / 3.0 / (2.0 * PI).sqrt();
    if z >= 0.0 { v } else { 1.0 - v }
}
fn out(k: &str, v: &[f64], d: usize) { let mut s = format!("{:<38}", k); for x in v { s += &format!(" {:.*}", d, x); } println!("{}", s); }
fn bm(xs: &[f64]) -> (f64, f64, f64) {
    let k = 100; let l = xs.len() / k; let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n; let v = xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / n;
    let bs: Vec<f64> = (0..k).map(|q| xs[q * l..(q + 1) * l].iter().sum::<f64>() / l as f64).collect();
    let se = (bs.iter().map(|c| (c - m).powi(2)).sum::<f64>() / (k - 1) as f64 / k as f64).sqrt(); (m, se, v / (se * se))
}
// standard error of any statistic f(start, end) from its spread over 100 batches of a run of length n
fn bse(n: usize, f: &dyn Fn(usize, usize) -> f64) -> f64 {
    let k = 100; let l = n / k; let s: Vec<f64> = (0..k).map(|q| f(q * l, (q + 1) * l)).collect(); let m = s.iter().sum::<f64>() / k as f64;
    (s.iter().map(|c| (c - m).powi(2)).sum::<f64>() / (k - 1) as f64 / k as f64).sqrt()
}
fn mean(xs: &[f64]) -> f64 { xs.iter().sum::<f64>() / xs.len() as f64 }
fn corr(a: &[f64], b: &[f64]) -> f64 {
    let (ma, mb) = (mean(a), mean(b)); let sab: f64 = a.iter().zip(b.iter()).map(|(x, y)| (x - ma) * (y - mb)).sum();
    sab / (a.iter().map(|x| (x - ma).powi(2)).sum::<f64>() * b.iter().map(|y| (y - mb).powi(2)).sum::<f64>()).sqrt()
}
fn lag1(b: &[f64]) -> f64 { let mb = mean(b); (0..b.len() - 1).map(|t| (b[t] - mb) * (b[t + 1] - mb)).sum::<f64>() / b.iter().map(|y| (y - mb).powi(2)).sum::<f64>() }
fn gibbs(r: &mut Rng, b: f64) -> (f64, f64) {
    let a = (sy() - b * SX) / N_ + r.n() * SIG / N_.sqrt();
    (a, (sxy() - a * SX) / SXX + r.n() * SIG / SXX.sqrt())
}
// kind: 0 Gibbs, 1 Metropolis; mode: 0 additive, 1 multiplicative on b with Hastings factor, 2 without, 3 move a only
fn run(kind: u8, seed: u64, mut a: f64, mut b: f64, sa: f64, sb: f64, mode: u8) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (nn, burn) = (100000usize, 1000usize);
    let mut r = Rng(seed); let (mut aa, mut bb, mut acc) = (Vec::new(), Vec::new(), Vec::new());
    for t in 0..burn + nn {
        let k;
        if kind == 0 { let g = gibbs(&mut r, b); a = g.0; b = g.1; k = 1.0; } else {
            let a2 = a + sa * r.n();
            let b2 = if mode == 3 { b } else if mode == 1 || mode == 2 { b * (sb * r.n()).exp() } else { b + sb * r.n() };
            let lr = logf(a2, b2) - logf(a, b) + if mode == 1 { (b2 / b).ln() } else { 0.0 };
            if (1.0 - r.u()).ln() < lr { a = a2; b = b2; k = 1.0; } else { k = 0.0; }
        }
        if t >= burn { aa.push(a); bb.push(b); acc.push(k); }
    }
    (aa, bb, acc)
}
fn main() {
    let (sy, sxy) = (sy(), sxy()); let nf = 100000.0;
    let d = N_ * SXX - SX * SX; let bh = (N_ * sxy - SX * sy) / d; let ah = (sy - bh * SX) / N_;
    let va = SIG * SIG * SXX / d; let vb = SIG * SIG * N_ / d; let cab = -SIG * SIG * SX / d;
    let rho = cab / (va * vb).sqrt(); let r2 = rho * rho; let tau = (1.0 + r2) / (1.0 - r2);
    let pb1 = 1.0 - phi((1.0 - bh) / vb.sqrt());
    out("sums w, w^2, h, wh; D", &[SX, SXX, sy, sxy, d], 4); out("var a, var b, cov(a,b)", &[va, vb, cab], 4);
    out("Gibbs conditional sd, a|b and b|a", &[SIG / N_.sqrt(), SIG / SXX.sqrt()], 4);
    for (k, v) in [("formula mean a", ah), ("formula mean b", bh), ("formula sd a", va.sqrt()), ("formula sd b", vb.sqrt()), ("formula corr(a,b)", rho),
                   ("formula P(b>1)", pb1), ("Gibbs lag-1 autocorr rho^2", r2), ("Gibbs tau = N/ESS", tau)] { out(k, &[v], 4); }
    // ---- road 2: exact grid ----
    let (na, nb) = (141usize, 121usize);
    let ga: Vec<f64> = (0..na).map(|i| -2.0 + 0.05 * i as f64).collect(); let gb: Vec<f64> = (0..nb).map(|j| -0.5 + 0.025 * j as f64).collect();
    let lw: Vec<Vec<f64>> = (0..na).map(|i| (0..nb).map(|j| logf(ga[i], gb[j])).collect()).collect();
    let mut w: Vec<Vec<f64>> = lw.iter().map(|r| r.iter().map(|v| v.exp()).collect()).collect();
    let t: f64 = w.iter().map(|r| r.iter().sum::<f64>()).sum(); for r in w.iter_mut() { for x in r.iter_mut() { *x /= t; } }
    let (mut gma, mut gmb, mut gp) = (0.0, 0.0, 0.0);
    for i in 0..na { for j in 0..nb { gma += w[i][j] * ga[i]; gmb += w[i][j] * gb[j]; gp += w[i][j] * if j > 60 { 1.0 } else if j == 60 { 0.5 } else { 0.0 }; } }
    out("grid mean a", &[gma], 4); out("grid mean b", &[gmb], 4); out("grid P(b>1)", &[gp], 4);
    let ok = |k: i64, l: i64| k >= 0 && k < na as i64 && l >= 0 && l < nb as i64;
    let mv = |i: usize, j: usize, k: i64, l: i64| if !ok(k, l) { 0.0 } else { (lw[k as usize][l as usize] - lw[i][j]).exp().min(1.0) / 24.0 };
    let nbr: Vec<(i64, i64)> = (-2..3).flat_map(|di| (-2..3).map(move |dj| (di, dj))).filter(|&p| p != (0, 0)).collect();
    let (mut imb, mut newm) = (0.0f64, vec![vec![0.0; nb]; na]);
    for i in 0..na { for j in 0..nb {
        let mut stay = 1.0;
        for &(di, dj) in &nbr { let (k, l) = (i as i64 + di, j as i64 + dj); stay -= mv(i, j, k, l); if ok(k, l) {
            let f = w[i][j] * mv(i, j, k, l); newm[k as usize][l as usize] += f;
            imb = imb.max((f - w[k as usize][l as usize] * mv(k as usize, l as usize, i as i64, j as i64)).abs()); } }
        newm[i][j] += w[i][j] * stay;
    } }
    let mut mstat = 0.0f64; for i in 0..na { for j in 0..nb { mstat = mstat.max((newm[i][j] - w[i][j]).abs()); } }
    let bl = |x: f64| if x < 1e-15 { "below 1e-15".to_string() } else { format!("{}", x) };
    println!("{:<38} {}", "grid Metropolis balance, max gap", bl(imb)); println!("{:<38} {}", "grid Metropolis one step, max change", bl(mstat));
    let cola: Vec<f64> = (0..nb).map(|j| (0..na).map(|i| w[i][j]).sum()).collect(); let rowb: Vec<f64> = w.iter().map(|r| r.iter().sum()).collect();
    let sweep = |mu: &Vec<Vec<f64>>| -> Vec<Vec<f64>> {
        let cm: Vec<f64> = (0..nb).map(|j| (0..na).map(|i| mu[i][j]).sum()).collect();
        let m1: Vec<Vec<f64>> = (0..na).map(|i| (0..nb).map(|j| cm[j] * w[i][j] / cola[j]).collect()).collect();
        let rm: Vec<f64> = m1.iter().map(|r| r.iter().sum()).collect();
        (0..na).map(|i| (0..nb).map(|j| rm[i] * w[i][j] / rowb[i]).collect()).collect()
    };
    let g1 = sweep(&w); let mut gs = 0.0f64; for i in 0..na { for j in 0..nb { gs = gs.max((g1[i][j] - w[i][j]).abs()); } }
    println!("{:<38} {}", "grid Gibbs sweep, max change", bl(gs));
    let mut mu = vec![vec![0.0; nb]; na]; mu[0][20] = 1.0; let (mut eb, mut tv) = (vec![0.0; 41], vec![0.0; 41]);
    for s in 0..41 {
        let (mut e, mut tt) = (0.0, 0.0); for i in 0..na { for j in 0..nb { e += mu[i][j] * gb[j]; tt += (mu[i][j] - w[i][j]).abs(); } }
        eb[s] = e; tv[s] = 0.5 * tt; mu = sweep(&mu);
    }
    for s in [1usize, 5, 10, 20, 40] { out(&format!("sweep {}: E[b] grid, formula; TV", s), &[eb[s], bh * (1.0 - r2.powi(s as i32)), tv[s]], 4); }
    let (mut n1, mut d1) = (0.0, 0.0); for i in 0..na { for j in 0..nb { if gb[j] > 0.0 { n1 += w[i][j]; d1 += w[i][j] / gb[j]; } } }
    let wr = n1 / d1; out("grid mean b, no Hastings factor", &[wr], 4);
    // ---- road 3: simulation ----
    for (name, (aa, bb, kk)) in [("Gibbs", run(0, 7, 1.0, 1.0, 0.0, 0.0, 0)), ("Metropolis", run(1, 11, 1.0, 1.0, 0.3, 0.09, 0))] {
        let (ma, sea, _) = bm(&aa); let (mb, seb, essb) = bm(&bb);
        let (p1, sep, _) = bm(&bb.iter().map(|&x| if x > 1.0 { 1.0 } else { 0.0 }).collect::<Vec<f64>>());
        let sbb: f64 = bb.iter().map(|y| (y - mb).powi(2)).sum();
        let (c, l1, ac, nt) = (corr(&aa, &bb), lag1(&bb), mean(&kk), nf / essb);
        let (sc, sl, sac) = (bse(aa.len(), &|s, e| corr(&aa[s..e], &bb[s..e])), bse(bb.len(), &|s, e| lag1(&bb[s..e])), bse(kk.len(), &|s, e| mean(&kk[s..e])));
        let snt = nt * (2.0f64 / 99.0).sqrt(); // N / ESS is read off 100 batch averages: relative SE sqrt(2/99)
        for (k, v) in [("mean a, SE", vec![ma, sea]), ("mean b, SE", vec![mb, seb]), ("P(b>1), SE", vec![p1, sep]), ("corr(a,b), SE", vec![c, sc]), ("acceptance rate, SE", vec![ac, sac]),
                       ("lag-1 autocorr of b, SE", vec![l1, sl]), ("N / ESS, SE", vec![nt, snt]), ("naive SE of b, sd/sqrt(N)", vec![(sbb / nf / nf).sqrt()])] {
            out(&format!("{} {}", name, k), &v, 4);
        }
        out(&format!("{} ESS of b", name), &[essb], 0);
        assert!((c - rho).abs() < 4.0 * sc); assert!((mb - bh).abs() < 4.0 * seb); assert!((p1 - pb1).abs() < 4.0 * sep);
        if name == "Gibbs" { assert!((ma - ah).abs() < 4.0 * sea); assert!((l1 - r2).abs() < 4.0 * sl); assert!((nt - tau).abs() < 4.0 * snt); }
    }
    let mut r = Rng(5); let mut b10 = Vec::new();
    for _ in 0..4000 { let mut b = 0.0; for _ in 0..10 { b = gibbs(&mut r, b).1; } b10.push(b); }
    let m10 = b10.iter().sum::<f64>() / 4000.0; let se10 = (b10.iter().map(|x| (x - m10).powi(2)).sum::<f64>() / 3999.0 / 4000.0).sqrt();
    out("sweep 10: E[b] from 4000 chains, SE", &[m10, se10], 4);
    for (name, mode) in [("no Hastings factor", 2u8), ("with Hastings factor", 1u8)] {
        let (_, bb, _) = run(1, 13, 1.0, 1.0, 0.3, 0.1, mode); let (mb, seb, _) = bm(&bb);
        out(&format!("{}: mean b, SE", name), &[mb, seb], 4); assert!((mb - if mode == 2 { wr } else { bh }).abs() < 4.0 * seb);
    }
    let (aa, _, _) = run(1, 17, 1.0, 0.5, 0.3, 0.0, 3); let (ma, sea, _) = bm(&aa);
    out("a-only from b=0.5: mean a, SE; exact", &[ma, sea, (sy - 0.5 * SX) / N_], 4);
    let mut r = Rng(3); let mut b = 0.0; let mut tr = vec![b];
    for _ in 0..30 { b = gibbs(&mut r, b).1; tr.push(b); }
    println!("trace b, sweeps 0,2,..,30: {}", (0..31).step_by(2).map(|s| format!("{:.2}", tr[s])).collect::<Vec<_>>().join(", "));
    println!("E[b],  sweeps 0,2,..,30: {}", (0..31).step_by(2).map(|s| format!("{:.2}", bh * (1.0 - r2.powi(s as i32)))).collect::<Vec<_>>().join(", "));
    let mut r = Rng(2); let mut b = 0.6; let mut pts = Vec::new();
    for _ in 0..4 { let (a, b2) = gibbs(&mut r, b); pts.push((a, b)); pts.push((a, b2)); b = b2; }
    let px = |a: f64, b: f64| (40.0 + 100.0 * (a + 0.4), 220.0 - 200.0 * (b - 0.45));
    let l11 = va.sqrt(); let l21 = cab / l11; let l22 = (vb - l21 * l21).sqrt(); let rr = (-2.0 * 0.05f64.ln()).sqrt();
    let ell: Vec<String> = (0..24).map(|k| { let th = 2.0 * PI * k as f64 / 24.0;
        let (x, y) = px(ah + rr * l11 * th.cos(), bh + rr * (l21 * th.cos() + l22 * th.sin())); format!("{:.1},{:.1}", x, y) }).collect();
    println!("figure, ellipse: {}", ell.join(" ")); let c = px(ah, bh); println!("figure, centre: {:.1},{:.1}", c.0, c.1);
    println!("figure, ticks: a=0,1,2 at x={:.0},{:.0},{:.0}; b=0.6,1.0,1.4 at y={:.0},{:.0},{:.0}", px(0.0, 0.0).0, px(1.0, 0.0).0, px(2.0, 0.0).0, px(0.0, 0.6).1, px(0.0, 1.0).1, px(0.0, 1.4).1);
    println!("figure, staircase from b=0.6: {}", pts.iter().map(|&(a, b)| { let (x, y) = px(a, b); format!("{:.1},{:.1}", x, y) }).collect::<Vec<_>>().join(" "));
    let rho2 = |xs: &[f64]| xs.iter().sum::<f64>().powi(2) / (xs.len() as f64 * xs.iter().map(|x| x * x).sum::<f64>());
    let c0 = rho2(&X.map(|x| x - 3.0)); out("try: centred weeks, rho^2 and tau", &[c0, (1.0 + c0) / (1.0 - c0)], 4); let r7 = rho2(&[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
    out("try: 7 weeks, rho^2 and tau", &[r7, (1.0 + r7) / (1.0 - r7)], 4);
    assert!((gmb - bh).abs() < 1e-6); assert!((gma - ah).abs() < 1e-6); assert!((gp - pb1).abs() < 5e-4);
    assert!(imb < 1e-15); assert!(mstat < 1e-15); assert!(gs < 1e-15);
    assert!((eb[10] - bh * (1.0 - r2.powi(10))).abs() < 1e-3); assert!(tv[40] < 0.01 && tv[10] > 0.01);
    assert!((m10 - bh * (1.0 - r2.powi(10))).abs() < 4.0 * se10); assert!((ma - (sy - 0.5 * SX) / N_).abs() < 4.0 * sea);
    println!("all asserts passed");
}
