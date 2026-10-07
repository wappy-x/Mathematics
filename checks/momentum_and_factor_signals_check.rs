// Momentum 12-1 decile sort, spread and Newey-West error -- the check behind the card.
// Rust std only. The market is invented, so its hidden drifts are known.
use std::collections::BTreeSet;
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // splitmix64 -> a number in (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 { // Box-Muller, one draw per pair
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

const N: usize = 300;
const TT: usize = 252;

struct Mkt { r: Vec<Vec<f64>>, drift: Vec<Vec<f64>>, p: Vec<Vec<f64>> }
type Sig<'a> = &'a dyn Fn(usize) -> Vec<f64>;

fn avg(rets: &[f64], grp: &[usize]) -> f64 { grp.iter().map(|&i| rets[i]).sum::<f64>() / grp.len() as f64 }

fn cut(s: &[f64], n: usize, top: bool) -> BTreeSet<usize> { // road B: decile edge by bisection
    let inside = |v: f64, mid: f64| if top { v >= mid } else { v <= mid };
    let mut lo = s.iter().cloned().fold(f64::INFINITY, f64::min) - 1.0;
    let mut hi = s.iter().cloned().fold(f64::NEG_INFINITY, f64::max) + 1.0;
    loop {
        let mid = 0.5 * (lo + hi);
        let k = s.iter().filter(|&&v| inside(v, mid)).count();
        if k == n { return (0..s.len()).filter(|&i| inside(s[i], mid)).collect(); }
        if (k > n) == top { lo = mid } else { hi = mid }
    }
}

// road A: sort, cut into nd groups, hold next month
fn sorts(mk: &Mkt, sig: Sig, nd: usize, check: bool) -> (Vec<Vec<f64>>, Vec<f64>, Vec<f64>, usize, Vec<f64>) {
    let (mut d, mut x, mut xd, mut bad, mut xb) = (vec![vec![]; nd], vec![], vec![], 0usize, vec![]);
    for t in 11..TT - 1 {
        let s = sig(t);
        let n = N / nd;
        let mut order: Vec<usize> = (0..N).collect();
        order.sort_by(|&a, &b| s[a].partial_cmp(&s[b]).unwrap());
        for k in 0..nd { d[k].push(avg(&mk.r[t + 1], &order[k * n..(k + 1) * n])); }
        x.push(d[nd - 1].last().unwrap() - d[0].last().unwrap());
        xd.push(avg(&mk.drift[t + 1], &order[N - n..]) - avg(&mk.drift[t + 1], &order[..n]));
        if check {
            let (hi, lo) = (cut(&s, n, true), cut(&s, n, false));
            let a: BTreeSet<usize> = order[N - n..].iter().cloned().collect();
            let c: BTreeSet<usize> = order[..n].iter().cloned().collect();
            bad += hi.symmetric_difference(&a).count() + lo.symmetric_difference(&c).count();
            let hv: Vec<usize> = hi.into_iter().collect();
            let lv: Vec<usize> = lo.into_iter().collect();
            xb.push(avg(&mk.r[t + 1], &hv) - avg(&mk.r[t + 1], &lv));
        }
    }
    (d, x, xd, bad, xb)
}

fn main() {
    let mut g = Rng(20260928);
    let smu = 0.0063;
    let mut mu: Vec<f64> = (0..N).map(|_| smu * g.gauss()).collect();
    let b: Vec<f64> = (0..N).map(|_| g.gauss()).collect();
    let (mut eprev, mut f) = (vec![0.0f64; N], 0.0f64);
    let (mut r, mut drift) = (vec![], vec![]);
    for _t in 0..TT {
        let m = 0.005 + 0.045 * g.gauss();
        let fold = f;
        f = 0.7 * f + (1.0f64 - 0.49).sqrt() * 0.015 * g.gauss();
        let (mut row, mut dr) = (vec![], vec![]);
        for i in 0..N {
            mu[i] = 0.97 * mu[i] + (1.0 - 0.97 * 0.97f64).sqrt() * smu * g.gauss();
            let e = 0.08 * g.gauss();
            dr.push(mu[i] + b[i] * 0.7 * fold - 0.05 * eprev[i]);
            row.push(m + mu[i] + b[i] * f - 0.05 * eprev[i] + e);
            eprev[i] = e;
        }
        r.push(row); drift.push(dr);
    }
    let mut p = vec![vec![100.0f64; N]];
    for row in &r {
        let next: Vec<f64> = p.last().unwrap().iter().zip(row).map(|(q, x)| q * (1.0 + x)).collect();
        p.push(next);
    }
    let mk = Mkt { r, drift, p };
    let (pp, rr) = (&mk.p, &mk.r);
    let mom = |t: usize| (0..N).map(|i| pp[t][i] / pp[t - 11][i] - 1.0).collect::<Vec<f64>>();
    let mut sgap = 0.0f64; // road 2 for the signal: chain the monthly returns
    for t in 11..TT - 1 {
        let s = mom(t);
        for i in 0..N {
            let mut c = 1.0;
            for k in t - 11..t { c *= 1.0 + rr[k][i]; }
            sgap = sgap.max((s[i] - (c - 1.0)).abs());
        }
    }
    let (d, x, xd, bad, xb) = sorts(&mk, &mom, 10, true);
    let tn = x.len();
    let tf = tn as f64;
    let xbar = x.iter().sum::<f64>() / tf;
    let gam = |j: usize| (j..tn).map(|k| (x[k] - xbar) * (x[k - j] - xbar)).sum::<f64>() / tf;
    let nw = |l: usize| gam(0) + 2.0 * (1..=l).map(|j| (1.0 - j as f64 / (l as f64 + 1.0)) * gam(j)).sum::<f64>();
    let l = 4usize; assert_eq!(l, (4.0 * (tf / 100.0).powf(2.0 / 9.0)) as usize); // NW 1994 lag rule
    let dev: Vec<f64> = x.iter().map(|v| v - xbar).collect(); // road 2: squared window sums
    let mut win = 0.0;
    for s in -(l as i64)..tn as i64 {
        let (a, e) = (s.max(0) as usize, ((s + l as i64 + 1) as usize).min(tn));
        win += dev[a..e].iter().sum::<f64>().powi(2);
    }
    win /= (l as f64 + 1.0) * tf;
    let mut reps = vec![]; // road 3: moving-block bootstrap, blocks of 12
    for _ in 0..2000 {
        let mut tot = 0.0;
        for _ in 0..tn / 12 {
            let s0 = (g.unif() * (tn - 11) as f64) as usize;
            tot += x[s0..s0 + 12].iter().sum::<f64>();
        }
        reps.push(tot / tf);
    }
    let rbar = reps.iter().sum::<f64>() / reps.len() as f64;
    let se_boot = (reps.iter().map(|v| (v - rbar).powi(2)).sum::<f64>() / reps.len() as f64).sqrt();
    let (se_plain, se_nw) = ((gam(0) / tf).sqrt(), (nw(l) / tf).sqrt());
    let noise: Vec<f64> = x.iter().zip(&xd).map(|(a, c)| a - c).collect();
    let nbar = noise.iter().sum::<f64>() / tf;
    let se_noise = (noise.iter().map(|v| (v - nbar).powi(2)).sum::<f64>() / tf / tf).sqrt();

    let ann = |v: f64| 1200.0 * v; // monthly decimal -> percent a year (x 12)
    let spread = |sig: Sig, nd: usize| ann(sorts(&mk, sig, nd, false).1.iter().sum::<f64>() / tf);
    let mut ts = 0.0;
    for t in 11..TT - 1 {
        ts += (0..N).map(|i| (if pp[t][i] > pp[t - 11][i] { 1.0 } else { -1.0 }) * rr[t + 1][i]).sum::<f64>() / N as f64;
    }
    ts /= tf;
    let xdm = xd.iter().sum::<f64>() / tf;
    let xbm = xb.iter().sum::<f64>() / tf;
    let mut rows: Vec<(String, f64)> = vec![
        ("example: signal 61/50 - 1".into(), 61.0 / 50.0 - 1.0), ("example: skipped month 58/61 - 1".into(), 58.0 / 61.0 - 1.0),
        ("signal roads, largest gap".into(), sgap), ("decile roads, stocks disagreeing".into(), bad as f64),
        ("holding months T".into(), tf), ("spread, percent a month".into(), 100.0 * xbar), ("spread, percent a year".into(), ann(xbar)),
        ("spread road B, percent a year".into(), ann(xbm)), ("drift-part spread, percent a year".into(), ann(xdm)),
        ("sd of monthly spread, percent".into(), 100.0 * gam(0).sqrt())];
    for j in 1..=l { rows.push((format!("autocorrelation lag {}", j), gam(j) / gam(0))); }
    let rows2: Vec<(&str, f64)> = vec![
        ("plain SE, percent a month", 100.0 * se_plain), ("plain t", xbar / se_plain),
        ("NW long-run var / plain var", nw(l) / gam(0)), ("NW SE (L=4), percent a month", 100.0 * se_nw),
        ("NW SE by window sums", 100.0 * (win / tf).sqrt()), ("NW SE by block bootstrap", 100.0 * se_boot),
        ("NW t (L=4)", xbar / se_nw), ("NW t (L=12)", xbar / (nw(12) / tf).sqrt()),
        ("wrong: no skip (12-0), percent a year", spread(&|t| (0..N).map(|i| pp[t + 1][i] / pp[t - 11][i] - 1.0).collect(), 10)),
        ("wrong: peeks at holding month", spread(&|t| (0..N).map(|i| pp[t + 2][i] / pp[t - 10][i] - 1.0).collect(), 10)),
        ("try: last month only (1-0)", spread(&|t| (0..N).map(|i| pp[t + 1][i] / pp[t][i] - 1.0).collect(), 10)),
        ("try: quintiles, top minus bottom", spread(&mom, 5)), ("try: time-series momentum", ann(ts))];
    for (n, v) in rows2 { rows.push((n.to_string(), v)); }
    for (name, v) in &rows { println!("{:<38} {:>12.6}", name, v); }
    let dec: Vec<String> = d.iter().map(|c| format!("{:.2}", ann(c.iter().sum::<f64>() / tf))).collect();
    println!("decile, percent a year: {}", dec.join(", "));
    let cum: Vec<String> = (0..21).map(|y| format!("{:.2}", 100.0 * x[..12 * y].iter().sum::<f64>() + 0.0)).collect();
    println!("cumulative spread by year, percent: {}", cum.join(", "));

    assert!(sgap < 1e-9); // price ratio == chained monthly returns
    assert!(bad == 0 && (ann(xbm) - ann(xbar)).abs() < 1e-9); // bisection cut == sorted cut
    assert!(((win / tf).sqrt() - se_nw).abs() < 1e-12 * se_nw + 1e-15); // autocovariances == window sums
    assert!((se_boot / se_nw - 1.0).abs() < 0.25); // resampling agrees with the formula
    assert!((xbar - xdm).abs() < 2.0 * se_noise); // the sort found the hidden drift
}
