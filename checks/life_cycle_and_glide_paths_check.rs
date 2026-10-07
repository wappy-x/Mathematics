// Retirement pot: $1,000,000, $40,000 a year in today's dollars, 30 withdrawals, real returns.
// Road 1: simulate 50,000 pots year by year.  Road 2: the realised-discount sum S on the same paths.
// Road 3: no randomness at all, the survival probability carried backwards on a wealth grid.
use std::f64::consts::PI;

const W0: f64 = 1_000_000.0; const C: f64 = 40_000.0; const N_YEARS: usize = 30; const N_PATHS: usize = 50_000;
const A_S: f64 = 0.08; const SIG_S: f64 = 0.20; const A_B: f64 = 0.03; const SIG_B: f64 = 0.08;
const H: f64 = 0.1; const XMAX: f64 = 100.0; const DZ: f64 = 0.25;

fn ms(p: f64) -> (f64, f64) { // yearly log-growth: mean m, spread s, share p in stocks
    let (a, v) = (p * A_S + (1.0 - p) * A_B, (p * SIG_S).powi(2) + ((1.0 - p) * SIG_B).powi(2));
    (a - 0.5 * v, v.sqrt())
}

fn phi(x: f64) -> f64 { // normal CDF, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() + 1e-300 { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // splitmix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normals(&mut self, k: usize) -> Vec<f64> { // Box-Muller, two draws per pair of uniforms
        let mut out = Vec::new();
        while out.len() < k {
            let (r, t) = ((-2.0 * (1.0 - self.uniform()).ln()).sqrt(), 2.0 * PI * self.uniform());
            out.push(r * t.cos()); out.push(r * t.sin());
        }
        out.truncate(k); out
    }
}

fn glide(a: f64, b: f64) -> Vec<f64> { (0..N_YEARS).map(|t| a + (b - a) * t as f64 / (N_YEARS - 1) as f64).collect() }

fn survival_grid(ws: &[f64]) -> Vec<f64> { // V_k(x): chance of k more withdrawals from x
    let nx = (XMAX / H) as usize + 1;
    let xs: Vec<f64> = (0..nx).map(|i| i as f64 * H).collect();
    let zs: Vec<f64> = (0..(16.0 / DZ) as usize + 1).map(|i| -8.0 + DZ * i as f64).collect();
    let pz: Vec<f64> = zs.iter().map(|z| (-0.5 * z * z).exp() * DZ / (2.0 * PI).sqrt()).collect();
    let (m, s) = ms(ws[ws.len() - 2]);
    let mut v: Vec<f64> = xs.iter().map(|&x| if x > 1.0 { phi(((x - 1.0).ln() + m) / s) } else { 0.0 }).collect();
    for k in 3..=ws.len() {
        let (m, s) = ms(ws[ws.len() - k]);
        let gs: Vec<f64> = zs.iter().map(|z| (m + s * z).exp() / H).collect();
        let mut new = Vec::with_capacity(nx);
        for &x in &xs {
            let mut acc = 0.0;
            for (g, p) in gs.iter().zip(&pz).filter(|_| x >= 1.0) {
                let y = (x - 1.0) * g; let j = y as usize;
                acc += p * if j >= nx - 1 { v[nx - 1] } else { v[j] + (y - j as f64) * (v[j + 1] - v[j]) };
            }
            new.push(acc);
        }
        v = new;
    }
    v
}

fn at(v: &[f64], x: f64) -> f64 {
    if x >= XMAX { return v[v.len() - 1]; } let i = (x / H) as usize; v[i] + (x / H - i as f64) * (v[i + 1] - v[i])
}

fn swr(v: &[f64], target: f64) -> f64 { // bisection: the x where V(x) = 1 - target
    let (mut lo, mut hi) = (1.0, 99.0);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if 1.0 - at(v, mid) > target { lo = mid } else { hi = mid } }
    1.0 / hi
}

fn story(rets: &[f64], draw: f64) -> (Vec<f64>, usize) { // pot at the start of each year; year it runs dry
    let (mut w, mut path, mut dry) = (W0, vec![W0], 0);
    for (t, r) in rets.iter().enumerate() {
        if w < draw && dry == 0 { dry = t + 1; }
        w = if dry > 0 { 0.0 } else { (w - draw) * (1.0 + r) }; path.push(w);
    }
    (path, dry)
}

fn commas(v: f64) -> String {
    let (s, mut out) = (format!("{:.2}", v), String::new()); let (int, dec) = s.split_at(s.len() - 3);
    for (i, ch) in int.chars().enumerate() { if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out + dec
}

fn main() {
    let paths = [("flat 60% stocks", glide(0.6, 0.6)), ("flat 30% stocks", glide(0.3, 0.3)),
                 ("flat 90% stocks", glide(0.9, 0.9)), ("falling 80% to 40%", glide(0.8, 0.4)),
                 ("rising 40% to 80%", glide(0.4, 0.8))];
    let (x0, np, mut rng) = (W0 / C, N_PATHS as f64, Rng(20260928));
    let (mut fails, mut s_list, mut finals, mut end_fail, mut z1) = (vec![0usize; paths.len()], Vec::new(), Vec::new(), 0usize, Vec::new());
    let (m6, s6) = ms(0.6);
    for _ in 0..N_PATHS {
        let z = rng.normals(N_YEARS);
        for (i, (_, ws)) in paths.iter().enumerate() {
            let mut x = x0;
            for t in 0..N_YEARS {
                if x < 1.0 { fails[i] += 1; x = 0.0; break; }
                let (m, s) = ms(ws[t]); x = (x - 1.0) * (m + s * z[t]).exp();
            }
            if i == 0 { finals.push(x * C); }
        }
        let (mut p, mut s_sum, mut xe, mut dead) = (1.0, 0.0, x0, false);
        for t in 0..N_YEARS {
            s_sum += 1.0 / p; let g = (m6 + s6 * z[t]).exp(); p *= g;
            xe = xe * g - 1.0; dead = dead || xe < 0.0;
        }
        s_list.push(s_sum); if dead { end_fail += 1; } z1.push(z[0]);
    }
    s_list.sort_by(|a, b| a.partial_cmp(b).unwrap()); finals.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let count_above = |lim: f64| s_list.iter().filter(|&&s| s > lim).count();

    let grids: Vec<Vec<f64>> = paths.iter().map(|(_, ws)| survival_grid(ws)).collect();
    let (v60, p_mc) = (&grids[0], fails[0] as f64 / np); let p_dp = 1.0 - at(v60, x0);
    let (se, p_s) = ((p_mc * (1.0 - p_mc) / np).sqrt(), count_above(x0) as f64 / np);
    println!("4% of $1,000,000 = $40,000 a year, 30 years, 60/40");
    println!("{:<36}{:>10.2} %  (one standard error {:.2})", "  1 simulate 50,000 pots", 100.0 * p_mc, 100.0 * se);
    println!("{:<36}{:>10.2} %", "  2 sum S > 25, same paths", 100.0 * p_s);
    println!("{:<36}{:>10.2} %", "  3 survival grid, no randomness", 100.0 * p_dp);
    println!("{:<36}{:>10.6}{:>10.6}", "  yearly log-growth m, spread s", m6, s6);
    println!("{:<36}{:>10.0}  median {:.0}", "  pot at 30 years ($000), mean", finals.iter().sum::<f64>() / np / 1000.0, finals[N_PATHS / 2] / 1000.0);

    let (swr_dp, swr_mc) = (swr(v60, 0.05), 1.0 / s_list[(0.95 * np) as usize]);
    println!("{:<36}{:>10.2} %  95th percentile of S {:.2} %", "safe rate at 5% failure: grid", 100.0 * swr_dp, 100.0 * swr_mc);
    println!("failure by withdrawal rate: rate, grid %, simulated %");
    for w in [0.03, 0.035, 0.04, 0.045, 0.05, 0.055, 0.06] { println!("  {:4.1}  {:8.2}  {:8.2}", 100.0 * w, 100.0 * (1.0 - at(v60, 1.0 / w)), 100.0 * count_above(1.0 / w) as f64 / np); }
    println!("glide paths at 4%: grid %, simulated %");
    for (((name, _), v), f) in paths.iter().zip(&grids).zip(&fails) { println!("  {:<22}{:8.2}{:8.2}", name, 100.0 * (1.0 - at(v, x0)), 100.0 * *f as f64 / np); }

    let (early, late) = ([vec![-0.15; 3], vec![0.06; 27]].concat(), [vec![0.06; 27], vec![-0.15; 3]].concat());
    let ((pe, de), (pl, dl)) = (story(&early, C), story(&late, C));
    let row = |p: &Vec<f64>| (0..=30).step_by(3).map(|t| format!("{:5.0}", p[t] / 1000.0)).collect::<Vec<_>>().join(" ");
    println!("same 30 returns, crash first vs crash last: pot ($000) every 3 years");
    println!("  year  {}", (0..=30).step_by(3).map(|t| format!("{:5}", t)).collect::<Vec<_>>().join(" "));
    println!("  first {}   runs dry in year {}", row(&pe), de);
    println!("  last  {}   ends at ${}", row(&pl), commas(pl[30]));
    let dsum = |rets: &Vec<f64>| { let mut pk = vec![1.0f64]; for r in rets { pk.push(pk[pk.len() - 1] * (1.0 + r)); } let s: f64 = pk[..30].iter().map(|q| 1.0 / q).sum(); (pk, s) }; // P_0 .. P_30
    let ((pe_k, se_), (pl_k, sl_)) = (dsum(&early), dsum(&late));
    println!("  by hand, crash first: {}  {}  {}", commas(pe[1]), commas(pe[2]), commas(pe[3]));
    println!("  discount sum S: first {:.4}  last {:.4}  P_30 {:.6}", se_, sl_, pe_k[30]);
    let (ne, nl) = (story(&early, 0.0).0[30], story(&late, 0.0).0[30]);
    println!("  no withdrawals: first ${}  last ${}  average return {:.2} %", commas(ne), commas(nl), 100.0 * early.iter().sum::<f64>() / 30.0);

    let annuity = |g: f64| 1.0 / (0..N_YEARS).map(|j| g.powf(-(j as f64))).sum::<f64>();
    let (r_avg, r_med) = (annuity(1.0 + 0.6 * A_S + 0.4 * A_B), annuity(m6.exp()));
    println!("what breaks");
    println!("  plan at the 6% average: rate {:.2} %, true failure {:.2} %", 100.0 * r_avg, 100.0 * (1.0 - at(v60, 1.0 / r_avg)));
    println!("  plan at the median growth {:.2} %: rate {:.2} %, true failure {:.2} %", 100.0 * (m6.exp() - 1.0), 100.0 * r_med, 100.0 * (1.0 - at(v60, 1.0 / r_med)));
    println!("  withdraw at year end, not start: failure {:.2} %", 100.0 * end_fail as f64 / np);

    let g1: Vec<f64> = z1.iter().map(|z| (m6 + s6 * z).exp()).collect(); let mg = g1.iter().sum::<f64>() / np; let q = g1.iter().filter(|&&g| g >= 1.0).count() as f64 / np;
    assert!((mg - (0.6 * A_S + 0.4 * A_B).exp()).abs() < 4.0 * g1.iter().map(|g| (g - mg).powi(2)).sum::<f64>().sqrt() / np, "yearly growth factor has mean e^a");
    assert!((at(&survival_grid(&[0.6, 0.6]), 2.0) - q).abs() < 4.0 * (q * (1.0 - q) / np).sqrt(), "grid's last two years vs the draws");
    assert!(fails[0] == count_above(x0), "pot-by-pot count must equal the discount-sum count");
    assert!((p_mc - p_dp).abs() < 4.0 * se, "simulation and grid must agree within four standard errors");
    for (f, v) in fails.iter().zip(&grids) {
        let pm = *f as f64 / np;
        assert!((pm - (1.0 - at(v, x0))).abs() < 4.0 * (pm * (1.0 - pm) / np).sqrt(), "each glide path, two roads");
    }
    assert!((swr_dp - swr_mc).abs() < 0.001, "safe rate: grid root vs sample quantile");
    let closed = W0 * 0.85f64.powf(3.0) * 1.06f64.powf(27.0); assert!((ne - closed).abs() < 1e-6 && (nl - closed).abs() < 1e-6, "order is irrelevant without withdrawals");
    assert!(de > 0 && dl == 0, "order decides whether the pot lasts once withdrawals start");
    assert!((pl[30] - pl_k[30] * (W0 - C * sl_)).abs() < 1e-6 && (se_ > x0) == (de > 0), "the formula on two paths");
    println!("ALL CHECKS PASS");
}
