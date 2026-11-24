// TARF and knock-out accumulator on the house FX market: Monte Carlo against a grid.
// No crates. Every number on the card is printed here.
const S0: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const SIG: f64 = 0.10;
const N: usize = 12; const K0: f64 = 1.08; const LEV: f64 = 2.0; const TGT: f64 = 0.10;
const H: f64 = 1.13; const NOT: f64 = 1_000_000.0; const PATHS: usize = 100000;
const M: usize = 167; const L: usize = 48; const DR: f64 = 0.000625;
type Row = [f64; N];
fn ncdf(x: f64) -> f64 { // bell-curve area left of x (erfc, 1.2e-7)
    let z = x.abs() / 2f64.sqrt(); let t = 1.0 / (1.0 + 0.5 * z);
    let p = t * (-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418
        + t * (-0.18628806 + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587
        + t * (-0.82215223 + t * 0.17087277))))))))).exp();
    if x >= 0.0 { 1.0 - 0.5 * p } else { 0.5 * p }
}
struct Mk { dt: f64, df: Vec<f64>, fwd: Vec<f64>, grow: Vec<Row> }
impl Mk {
    fn tarf_path(&self, row: &Row, s0: f64, k: f64, mut rem: f64, lev: f64, full: bool) -> (f64, f64) {
        let (mut v, mut paid) = (0.0, 0.0);
        for i in 0..N {
            let s = s0 * row[i];
            if s > k {
                let g = s - k;
                if g >= rem { let pay = if full { g } else { rem }; return (v + self.df[i] * pay, paid + pay); }
                v += self.df[i] * g; rem -= g; paid += g;
            } else { v -= lev * self.df[i] * (k - s); }
        }
        (v, paid)
    }
    fn accum_path(&self, row: &Row, s0: f64, k: f64) -> f64 {
        let mut v = 0.0;
        for i in 0..N {
            let s = s0 * row[i];
            if s >= H { return v; } // knocked out: this fixing does not trade
            v += self.df[i] * (if s > k { s - k } else { -LEV * (k - s) });
        }
        v
    }
    fn tarf(&self, s0: f64, k: f64, rem: f64, lev: f64, rows: &[Row], full: bool) -> (f64, f64) {
        mc(rows, |r| self.tarf_path(r, s0, k, rem, lev, full).0)
    }
    fn strip(&self, k: f64, lev: f64) -> f64 { // no target: 12 forwards minus (lev-1) x 12 puts
        let mut out = 0.0;
        for i in 0..N {
            let t = self.dt * (i + 1) as f64;
            let d1 = ((self.fwd[i] / k).ln() + 0.5 * SIG * SIG * t) / (SIG * t.sqrt());
            let put = self.df[i] * (k * ncdf(-(d1 - SIG * t.sqrt())) - self.fwd[i] * ncdf(-d1));
            out += self.df[i] * (self.fwd[i] - k) - (lev - 1.0) * put;
        }
        out
    }
    // ---- road 2: backward induction on a grid of log-spot and remaining target ----
    fn grid(&self, k: f64, acc: bool, w: &[f64], sp: &[f64]) -> Vec<Vec<f64>> {
        let n = sp.len(); let nrt = (TGT / DR).round() as usize + 1; let nr = if acc { 1 } else { nrt };
        let mut v = vec![vec![0.0; nr]; n];
        for i in (0..N).rev() {
            let df = self.df[i]; let mut c = vec![vec![0.0; nr]; n];
            for (kk, &s) in sp.iter().enumerate() {
                for m in 0..nr {
                    c[kk][m] = if acc { if s >= H { 0.0 } else { df * (if s > k { s - k } else { -LEV * (k - s) }) + v[kk][m] } }
                    else if m == 0 { 0.0 }
                    else if s <= k { -LEV * df * (k - s) + v[kk][m] }
                    else if s - k >= m as f64 * DR { df * m as f64 * DR }
                    else {
                        let q = (m as f64 * DR - (s - k)) / DR; let a = q as usize; let f = q - a as f64;
                        df * (s - k) + (1.0 - f) * v[kk][a] + f * v[kk][(a + 1).min(nr - 1)]
                    };
                }
            }
            let mut nv = vec![vec![0.0; nr]; n];
            for j in 0..n { for m in 0..nr {
                let mut acc_v = 0.0;
                for o in 0..(2 * L + 1) {
                    let idx = (j as i64 + o as i64 - L as i64).max(0).min(n as i64 - 1) as usize;
                    acc_v += w[o] * c[idx][m];
                }
                nv[j][m] = acc_v;
            } }
            v = nv;
        }
        v
    }
}
fn mc<F: Fn(&Row) -> f64>(rows: &[Row], f: F) -> (f64, f64) {
    let (mut m, mut q) = (0.0, 0.0);
    for r in rows { let x = f(r); m += x; q += x * x; }
    let n = rows.len() as f64; m /= n; (m, ((q / n - m * m) / (n - 1.0)).sqrt())
}
fn d(x: f64) -> String { format!("{:.0}", x * NOT) }
fn main() {
    let dt = 1.0 / 12.0; let mu = (RD - RF - 0.5 * SIG * SIG) * dt; let sd = SIG * dt.sqrt();
    let df: Vec<f64> = (0..N).map(|i| (-RD * dt * (i + 1) as f64).exp()).collect();
    let fwd: Vec<f64> = (0..N).map(|i| S0 * ((RD - RF) * dt * (i + 1) as f64).exp()).collect();
    let mut st: u64 = 0x2545F4914F6CDD1D; // xorshift64 random bits, same in Python
    let mut unif = || { st ^= st << 13; st ^= st >> 7; st ^= st << 17; ((st >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let mut grow: Vec<Row> = Vec::with_capacity(PATHS);
    for _ in 0..PATHS {
        let (mut g, mut row, mut c) = (1.0, [0.0; N], 0);
        for _ in 0..N / 2 {
            let u1 = unif(); let u2 = unif(); let r = (-2.0 * u1.ln()).sqrt();
            for z in [r * (2.0 * std::f64::consts::PI * u2).cos(), r * (2.0 * std::f64::consts::PI * u2).sin()] {
                g *= (mu + sd * z).exp(); row[c] = g; c += 1;
            }
        }
        grow.push(row);
    }
    let mk = Mk { dt, df, fwd, grow };
    let hx = sd / 8.0; let nr = (TGT / DR).round() as usize + 1;
    let w: Vec<f64> = (0..2 * L + 1).map(|o| { let o = o as f64 - L as f64;
        ncdf(((o + 0.5) * hx - mu) / sd) - ncdf(((o - 0.5) * hx - mu) / sd) }).collect();
    let sp: Vec<f64> = (0..2 * M + 1).map(|j| S0 * ((j as f64 - M as f64) * hx).exp()).collect();
    let all = &mk.grow[..];
    println!("house: spot {:.2}, rates {:.2}/{:.2}, vol {:.2}, {} fixings, strike {:.2}, leverage {:.0}x, target {:.2}, {} paths",
        S0, RD, RF, SIG, N, K0, LEV, TGT, PATHS);
    println!("forwards: first fixing {:.6}, last {:.6}; most the client can gain: {}", mk.fwd[0], mk.fwd[N - 1], d(TGT));
    println!("grid: {} spot levels, {} remaining-target levels, {} weights per step", sp.len(), nr, w.len());
    let (fw1, fw2) = (mk.strip(K0, 1.0), mk.strip(K0, 2.0));
    let s1 = mk.tarf(S0, K0, 1e9, 1.0, all, false); let s2 = mk.tarf(S0, K0, 1e9, LEV, all, false);
    println!("no target, 1x: strip of forwards {}  MC {} +- {}", d(fw1), d(s1.0), d(s1.1));
    println!("no target, 2x: {} - 12 puts {} = {}  MC {} +- {}", d(fw1), d(fw1 - fw2), d(fw2), d(s2.0), d(s2.1));
    let t0 = mk.tarf(S0, K0, TGT, LEV, all, false); let v = mk.grid(K0, false, &w, &sp);
    let (i5, i1) = ((0.05 / DR).round() as usize, (0.01 / DR).round() as usize);
    println!("TARF, client view: MC {} +- {}  grid {}", d(t0.0), d(t0.1), d(v[M][nr - 1]));
    println!("what the target takes away: {} - ({}) = {}", d(fw2), d(v[M][nr - 1]), d(fw2 - v[M][nr - 1]));
    let runs: Vec<(f64, f64)> = all.iter().map(|r| mk.tarf_path(r, S0, K0, TGT, LEV, false)).collect();
    let hit = runs.iter().filter(|x| x.1 >= TGT - 1e-12).count() as f64 / PATHS as f64; let top = runs.iter().map(|x| x.1).fold(f64::MIN, f64::max);
    println!("chance the target is hit: {:.4}  largest total gain paid on a path: {:.6}", hit, top);
    let (mut lo, mut hi, mut mids) = (1.00f64, 1.10f64, Vec::new());
    for it in 0..40 { // bisection on the same draws every time
        let mid = 0.5 * (lo + hi); let vv = mk.tarf(S0, mid, TGT, LEV, all, false).0;
        if it < 5 { mids.push(format!("{:.6} -> {}", mid, d(vv))); }
        if vv > 0.0 { lo = mid; } else { hi = mid; }
    }
    let kz = 0.5 * (lo + hi); let vz = mk.grid(kz, false, &w, &sp)[M][nr - 1];
    let sez = mk.tarf(S0, kz, TGT, LEV, all, false).1; let slope = (mk.tarf(S0, kz + 0.001, TGT, LEV, all, false).0 - mk.tarf(S0, kz - 0.001, TGT, LEV, all, false).0) / 0.002;
    println!("bisection: {}", mids.join("; "));
    println!("zero-cost strike {:.6}  grid value there {}  MC SE {}, so strike SE {:.4}", kz, d(vz), d(sez), sez / -slope);
    let kfwd = (0..N).map(|i| mk.df[i] * mk.fwd[i]).sum::<f64>() / mk.df.iter().sum::<f64>();
    println!("zero-cost strike of the plain strip of forwards: {:.6}  gap {:.6}", kfwd, kfwd - kz);
    let h = 0.001; let mut deltas = Vec::new(); let mut vals = Vec::new();
    for (name, m, rem) in [("0.00", nr - 1, TGT), ("0.05", i5, 0.05), ("0.09", i1, 0.01)] {
        let dm = (mk.tarf(S0 + h, K0, rem, LEV, all, false).0 - mk.tarf(S0 - h, K0, rem, LEV, all, false).0) / (2.0 * h);
        let dg = (v[M + 1][m] - v[M - 1][m]) / (sp[M + 1] - sp[M - 1]); deltas.push((dm, dg));
        let vm = mk.tarf(S0, K0, rem, LEV, all, false); vals.push((vm, v[M][m]));
        println!("accrued {}: value MC {} grid {}  delta EUR MC {} grid {}", name, d(vm.0), d(v[M][m]), d(dm), d(dg));
    }
    let pend = ncdf(((mk.fwd[0] / (K0 + 0.01)).ln() - 0.5 * sd * sd) / sd);
    let mend = all.iter().filter(|r| S0 * r[0] >= K0 + 0.01).count() as f64 / PATHS as f64;
    println!("accrued 0.09: chance the first fixing ends the trade: formula {:.4}  MC {:.4}", pend, mend);
    let a0 = mc(all, |r| mk.accum_path(r, S0, K0)); let va = mk.grid(K0, true, &w, &sp)[M][0];
    println!("accumulator, wall {:.2}: MC {} +- {}  grid {}", H, d(a0.0), d(a0.1), d(va));
    let half = PATHS / 2;
    let dfresh = (mk.tarf(S0 + h, K0, TGT, LEV, &all[..half], false).0 - mk.tarf(S0 - h, K0, TGT, LEV, &all[half..], false).0) / (2.0 * h);
    println!("mistake, ignore the target: {}", d(fw2));
    println!("mistake, ignore the doubling: {}", d(mk.tarf(S0, K0, TGT, 1.0, all, false).0));
    println!("mistake, pay the full last gain: {}", d(mk.tarf(S0, K0, TGT, LEV, all, true).0));
    println!("mistake, fresh draws for the bump: delta {}", d(dfresh));
    let xs = [1.00, 1.02, 1.04, 1.06, 1.08, 1.10];
    println!("chart, thousands of dollars, strikes 1.00 to 1.10:");
    let ct: Vec<String> = xs.iter().map(|&x| format!("{:.0}", mk.tarf(S0, x, TGT, LEV, all, false).0 * 1000.0)).collect();
    let cs: Vec<String> = xs.iter().map(|&x| format!("{:.0}", mk.strip(x, 2.0) * 1000.0)).collect();
    println!("  TARF  {}\n  strip {}", ct.join(" "), cs.join(" "));
    assert!((s1.0 - fw1).abs() < 4.0 * s1.1 && (s2.0 - fw2).abs() < 4.0 * s2.1);
    assert!(vals.iter().all(|(vm, vg)| (vm.0 - vg).abs() < 4.0 * vm.1));
    assert!(vz.abs() < 4.0 * sez);
    assert!(deltas.iter().all(|(dm, dg)| (dm - dg).abs() < 0.03 * dg));
    assert!((a0.0 - va).abs() < 4.0 * a0.1);
    assert!(top <= TGT + 1e-12);
    assert!((pend - mend).abs() < 0.005);
    println!("ALL CHECKS PASS");
}
