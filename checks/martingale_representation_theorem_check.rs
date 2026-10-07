// Martingale representation -- the same check as martingale_representation_theorem_check.py.
// Std only, no crates.  Rust has no erf, so the bell-curve area N(x) is added up in thin
// slices (Simpson).  The digital pays $100 if S_T > 100, with S_t = 100 + 20 W_t, T = 1 year.
use std::collections::BTreeMap;
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const SIG: f64 = 20.0; const T: f64 = 1.0; const PAY: f64 = 100.0;

fn np(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } // bell-curve height at x
fn n_cdf(x: f64) -> f64 {                                           // area left of x, Simpson
    if x.abs() > 12.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (n, h) = (4000, x / 4000.0);
    let mut s = np(0.0) + np(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * np(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn value(t: f64, s: f64) -> f64 { PAY * n_cdf((s - K) / (SIG * (T - t).sqrt())) }
fn stake(t: f64, s: f64) -> f64 { let sd = SIG * (T - t).sqrt(); PAY * np((s - K) / sd) / sd }

fn above(n: usize, start: f64, k: f64, dlt: f64) -> f64 { // n-step fair walk ends above k
    let (mut lp, mut tot) = (-(n as f64) * 2.0_f64.ln(), 0.0);
    for j in 0..=n {
        if start + dlt * (2.0 * j as f64 - n as f64) > k { tot += lp.exp(); }
        if j < n { lp += ((n - j) as f64 / (j + 1) as f64).ln(); }
    }
    tot
}
fn tree(n: usize, k: f64) -> (f64, f64) {                 // root value and stake
    let dlt = SIG * (T / n as f64).sqrt();
    let (up, dn) = (PAY * above(n - 1, S0 + dlt, k, dlt), PAY * above(n - 1, S0 - dlt, k, dlt));
    ((up + dn) / 2.0, (up - dn) / (2.0 * dlt))
}

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {                             // SplitMix64, top 53 bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normals(&mut self, count: usize) -> Vec<f64> {      // Box-Muller, two at a time
        let mut out = Vec::with_capacity(count + 1);
        while out.len() < count {
            let r = (-2.0 * (1.0 - self.u01()).ln()).sqrt();
            let a = 2.0 * PI * self.u01();
            out.push(r * a.cos()); out.push(r * a.sin());
        }
        out
    }
}
fn mse(s: [f64; 2], n: f64) -> (f64, f64) { (s[0] / n, ((s[1] / n - (s[0] / n).powi(2)).max(0.0) / n).sqrt()) }

fn main() {
    println!("{:<36}{:>12.6}", "M_0, fair value at the start", value(0.0, S0));
    println!("{:<36}{:>12.6}", "H_0, shares at the start", stake(0.0, S0));
    println!("{:<36}{:>12.6}", "phi_0 = SIG * H_0, per unit of W", SIG * stake(0.0, S0));
    println!("{:<36}{:>12.6}", "N'(0), bell height at the centre", np(0.0));
    println!("{:<36}{:>12.6}", "cash at the start, M_0 - H_0 S_0", value(0.0, S0) - stake(0.0, S0) * S0);
    println!("{:<36}{:>12.6}", "stake one trading day out, S = 100", stake(T - 1.0 / 252.0, S0));
    let (t1, s1, h, e) = (0.5, 110.0, 1e-4, 0.01);
    let x1 = (s1 - K) / (SIG * (T - t1).sqrt());
    println!("{:<36}{:>12.6}", "t=0.5, S=110: x, distance in s.d.", x1);
    println!("{:<36}{:>12.6}", "t=0.5, S=110: N'(x)", np(x1));
    let fd = (value(t1, s1 + e) - value(t1, s1 - e)) / (2.0 * e);
    let ut = (value(t1 + h, s1) - value(t1 - h, s1)) / (2.0 * h);
    let uss = (value(t1, s1 + e) - 2.0 * value(t1, s1) + value(t1, s1 - e)) / (e * e);
    println!("{:<36}{:>12.6}", "t=0.5, S=110: stake by formula", stake(t1, s1));
    println!("{:<36}{:>12.6}", "t=0.5, S=110: slope of M by bumping", fd);
    println!("{:<36}{:>12.4}", "t=0.5, S=110: dM/dt", ut);
    println!("{:<36}{:>12.4}", "t=0.5, S=110: (1/2) SIG^2 d2M/dS2", 0.5 * SIG * SIG * uss);

    println!("tree steps         M_0         H_0   H_0 error  error * n");
    for n in [9usize, 99, 999, 9999, 99999] {
        let (m0, h0) = tree(n, K);
        let er = h0 - stake(0.0, S0);
        println!("{:>10}{:>12.6}{:>12.6}{:>12.6}{:>11.4}", n, m0, h0, er, er * n as f64);
    }

    const FINE: usize = 1280; const PATHS: usize = 4000; const CHART: usize = 7;
    let ms = [5usize, 20, 80, 320, 1280];
    let dt = T / FINE as f64;
    let mut rng = Rng(20260930);
    let (mut pay, mut iso, mut un) = ([0.0f64; 2], [0.0f64; 2], [0.0f64; 2]);
    let mut err: BTreeMap<usize, [f64; 2]> = ms.iter().map(|&m| (m, [0.0, 0.0])).collect();
    let mut dbl: BTreeMap<usize, (usize, f64)> = BTreeMap::from([(80, (0, 0.0)), (1280, (0, 0.0))]);
    let mut chart: [Vec<f64>; 3] = [vec![], vec![], vec![]];
    for p in 0..PATHS {
        let (zw, zb) = (rng.normals(FINE), rng.normals(FINE));
        let (mut s, mut b) = (vec![S0], vec![0.0]);
        for i in 0..FINE {
            s.push(s[i] + SIG * dt.sqrt() * zw[i]); b.push(b[i] + dt.sqrt() * zb[i]);
        }
        let v = if s[FINE] > K { PAY } else { 0.0 };
        pay[0] += v; pay[1] += v * v;
        let (mut acc, mut q) = (0.0, 0.0);
        for &m in &ms {
            let st = FINE / m;
            acc = PAY / 2.0; q = 0.0;
            for k in 0..m {
                if p == CHART && m == FINE && k % 64 == 0 {
                    chart[0].push(s[k]); chart[1].push(value(k as f64 * dt, s[k])); chart[2].push(acc);
                }
                let hk = stake(k as f64 * T / m as f64, s[k * st]);
                acc += hk * (s[(k + 1) * st] - s[k * st]); q += (SIG * hk).powi(2) * (T / m as f64);
            }
            let ee = err.get_mut(&m).unwrap(); ee[0] += acc - v; ee[1] += (acc - v).powi(2);
        }
        iso[0] += q; iso[1] += q * q;
        if p == CHART { chart[0].push(s[FINE]); chart[1].push(v); chart[2].push(acc); }
        let v2 = if (s[FINE] - S0) / SIG + b[FINE] > 0.0 { PAY } else { 0.0 };
        let mut acc2 = PAY / 2.0;
        for k in 0..FINE {
            let sd2 = (2.0 * (T - k as f64 * dt)).sqrt();
            acc2 += PAY * np(((s[k] - S0) / SIG + b[k]) / sd2) / (sd2 * SIG) * (s[k + 1] - s[k]);
        }
        un[0] += (acc2 - v2).powi(2); un[1] += (acc2 - v2).powi(4);
        for (&m, d) in dbl.iter_mut() {
            let (st, mut g) = (FINE / m, 0.0);
            for k in 0..m {
                if g < PAY / 2.0 { g += 2.5 / (T - k as f64 * T / m as f64) * (s[(k + 1) * st] - s[k * st]); }
            }
            if g >= PAY / 2.0 { d.0 += 1; } else { d.1 += g; }
        }
    }
    let np_ = PATHS as f64;
    let (pm, pse) = mse(pay, np_);
    println!("{:<36}{:>12.4} +- {:.4}", "simulated mean payoff, 4000 paths", pm, pse);
    println!("rebalances   mean error  +- s.e.    RMS error");
    let mut rms = BTreeMap::new();
    for &m in &ms {
        let (em, ese) = mse(err[&m], np_);
        rms.insert(m, (err[&m][1] / np_).sqrt());
        println!("{:>10}{:>13.4}{:>9.4}{:>12.2}", m, em, ese, rms[&m]);
    }
    let ratios: Vec<String> = (0..4).map(|i| format!("{:.3}", rms[&ms[i + 1]] / rms[&ms[i]])).collect();
    println!("{:<36}{}", "RMS ratio per 4x rebalances", ratios.join(" "));
    let grid: f64 = (0..FINE).map(|k| PAY * PAY / (2.0 * PI * (T * T - (k as f64 * dt).powi(2)).sqrt()) * dt).sum();
    let (im, ise) = mse(iso, np_);
    println!("{:<36}{:>12.4} +- {:.4}", "sum of phi^2 dt, simulated", im, ise);
    println!("{:<36}{:>12.4}", "sum of phi^2 dt, exact on the grid", grid);
    println!("{:<36}{:>12.4}", "limit 100^2/(2 pi) * pi/2 = Var(V)", PAY * PAY / 4.0);
    println!("{:<36}{:>12.4}", "simulated Var(V)", pay[1] / np_ - pm * pm);
    println!("{:<36}{:>12.4}", "unseen noise: RMS error, 1280 trades", (un[0] / np_).sqrt());
    println!("{:<36}{:>12.4}", "unseen noise: sqrt(2500 / 2)", (PAY * PAY / 8.0).sqrt());
    for (m, (hit, miss)) in &dbl {
        println!("{:<36}{:>12.4}", format!("doubling, {} trades: share at $50", m), *hit as f64 / np_);
        println!("{:<36}{:>12.2}", format!("doubling, {} trades: mean of misses", m), miss / (PATHS - hit) as f64);
    }
    let ts: Vec<String> = (0..21).map(|k| format!("{:.2}", k as f64 * 0.05)).collect();
    println!("chart, t        {}", ts.join(" "));
    for (lab, row) in ["chart, share", "chart, M_t", "chart, account"].iter().zip(chart.iter()) {
        let r: Vec<String> = row.iter().map(|v| format!("{:.2}", v)).collect();
        println!("{:<16}{}", lab, r.join(" "));
    }

    assert!((tree(99999, K).1 - stake(0.0, S0)).abs() < 1e-3, "tree stake vs Ito formula");
    assert!((fd - stake(t1, s1)).abs() < 1e-5, "stake = slope of the fair value");
    assert!((ut + 0.5 * SIG * SIG * uss).abs() < 1e-3, "drift term of Ito's lemma cancels");
    assert!((pm - 50.0).abs() < 4.0 * pse, "simulated payoff mean vs $50");
    let (em, ese) = mse(err[&1280], np_);
    assert!(em.abs() < 4.0 * ese, "hedge is fair");
    let nr: Vec<f64> = ms.iter().map(|&m| rms[&m] * (m as f64).powf(0.25)).collect();
    assert!(nr.iter().cloned().fold(0.0, f64::max) < 1.2 * nr.iter().cloned().fold(f64::MAX, f64::min), "miss falls like n^(-1/4)");
    assert!((im - grid).abs() < 4.0 * ise, "isometry on the grid");
    let (um, ue) = mse(un, np_); assert!((um - PAY * PAY / 8.0).abs() < 4.0 * ue, "unseen noise leaves half the variance");
    assert!(dbl[&1280].0 > dbl[&80].0 && dbl[&80].0 as f64 > 0.8 * np_, "doubling reaches $50 on more paths as trading refines");
    println!("ALL CHECKS PASS");
}
