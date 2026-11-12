// Reverse mode -- the same check as the Python, in Rust.  No crates.  Same book, same
// 50-node curve (illustrative), same tape recorded by the arithmetic as the loop runs.
// Roads: one reverse sweep; 50 forward-mode runs; a closed form; 100 bumped prices.
const NODES: usize = 50; const STEPS: usize = 60; const C: usize = 8;
const CPN: [f64; 4] = [4.0, 3.5, 3.0, 4.5]; // % a year
const MAT: [usize; 4] = [60, 20, 10, 40]; // maturity in half-years
const HOLD: [f64; 4] = [500000.0, 300000.0, -400000.0, 200000.0]; // units of $100 face
fn flows(m: usize) -> Vec<f64> { (0..4).map(|b| if m <= MAT[b] { CPN[b] / 2.0 + if m == MAT[b] { 100.0 } else { 0.0 } } else { 0.0 }).collect() }
fn weights(m: usize) -> Vec<(usize, f64)> { // midpoint of period m, (2m-1)/4 years, read off the node grid
    let (k, r) = ((5 * (2 * m - 1)) / 12, (5 * (2 * m - 1)) % 12); // k = 0: flat before node 1
    if k == 0 { vec![(0, 1.0)] } else { vec![(k - 1, 1.0 - r as f64 / 12.0), (k, r as f64 / 12.0)] }
}
trait Alg { // the four operations the pricer uses, for plain, dual and taped numbers
    type N: Clone;
    fn add(&mut self, a: &Self::N, b: &Self::N) -> Self::N; fn mul(&mut self, a: &Self::N, b: &Self::N) -> Self::N;
    fn scale(&mut self, a: &Self::N, c: f64) -> Self::N; fn exp(&mut self, a: &Self::N) -> Self::N;
}
struct Plain;
impl Alg for Plain { type N = f64;
    fn add(&mut self, a: &f64, b: &f64) -> f64 { a + b } fn mul(&mut self, a: &f64, b: &f64) -> f64 { a * b }
    fn scale(&mut self, a: &f64, c: f64) -> f64 { a * c } fn exp(&mut self, a: &f64) -> f64 { a.exp() }
}
#[derive(Clone, Copy)] struct Du(f64, f64); // dual number a + b eps, eps^2 = 0
struct Dual;
impl Alg for Dual { type N = Du;
    fn add(&mut self, x: &Du, y: &Du) -> Du { Du(x.0 + y.0, x.1 + y.1) } fn scale(&mut self, x: &Du, c: f64) -> Du { Du(x.0 * c, x.1 * c) }
    fn mul(&mut self, x: &Du, y: &Du) -> Du { Du(x.0 * y.0, x.0 * y.1 + x.1 * y.0) } fn exp(&mut self, x: &Du) -> Du { let e = x.0.exp(); Du(e, e * x.1) }
}
struct Tape { par: Vec<Vec<(usize, f64)>>, val: Vec<f64> } // one entry per value: (parent, local slope)
impl Tape {
    fn push(&mut self, v: f64, p: Vec<(usize, f64)>) -> usize { self.val.push(v); self.par.push(p); self.val.len() - 1 }
    fn leaf(&mut self, v: f64) -> usize { self.push(v, vec![]) }
    fn sweep(&self, seed: &[(usize, f64)], backward: bool) -> Vec<f64> {
        let mut bar = vec![0.0; self.val.len()]; // backward = false is the mistake
        for &(i, s) in seed { bar[i] += s; }
        let order: Vec<usize> = if backward { (0..self.val.len()).rev().collect() } else { (0..self.val.len()).collect() };
        for i in order { for &(p, d) in &self.par[i] { bar[p] += bar[i] * d; } }
        bar
    }
}
impl Alg for Tape { type N = usize;
    fn add(&mut self, a: &usize, b: &usize) -> usize { let v = self.val[*a] + self.val[*b]; self.push(v, vec![(*a, 1.0), (*b, 1.0)]) }
    fn mul(&mut self, a: &usize, b: &usize) -> usize { let (x, y) = (self.val[*a], self.val[*b]); self.push(x * y, vec![(*a, y), (*b, x)]) }
    fn scale(&mut self, a: &usize, c: f64) -> usize { let v = self.val[*a] * c; self.push(v, vec![(*a, c)]) }
    fn exp(&mut self, a: &usize) -> usize { let e = self.val[*a].exp(); self.push(e, vec![(*a, e)]) }
}
// the pricer: one loop, one branch, no derivative code
fn run<A: Alg>(al: &mut A, f: &[A::N], d0: A::N, v0: Vec<A::N>, m0: usize, m1: usize) -> (A::N, Vec<A::N>) {
    let (mut d, mut vals) = (d0, v0);
    for m in m0..=m1 {
        let mut fr: Option<A::N> = None;
        for (j, w) in weights(m) {
            let t = al.scale(&f[j], w);
            fr = Some(match fr { None => t, Some(x) => al.add(&x, &t) });
        }
        let g = al.scale(&fr.unwrap(), -0.5); let e = al.exp(&g);
        d = al.mul(&d, &e); let cf = flows(m);
        for b in 0..4 { if cf[b] != 0.0 { let t = al.scale(&d, cf[b]); vals[b] = al.add(&vals[b], &t); } }
    }
    (d, vals)
}
fn tot(xs: &[f64]) -> f64 { let mut t = 0.0; for x in xs { t += x; } t }
fn sci(v: f64) -> String { format!("{:.1e}", v) }
fn price(f: &[f64]) -> f64 { let v = run(&mut Plain, f, 1.0, vec![0.0; 4], 1, STEPS).1; tot(&(0..4).map(|b| HOLD[b] * v[b]).collect::<Vec<_>>()) }
fn dv(g: &[f64]) -> String { g.iter().map(|x| format!("{:9.2}", x * 1e-4)).collect::<Vec<_>>().join(" ") }
fn gap(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) / b.iter().map(|y| y.abs()).fold(0.0, f64::max) }
fn bumped(f0: &[f64], h: f64) -> Vec<f64> {
    let sh = |k: usize, s: f64| -> Vec<f64> { f0.iter().enumerate().map(|(j, x)| x + s * h * ((j == k) as u8 as f64)).collect() };
    (0..NODES).map(|k| (price(&sh(k, 1.0)) - price(&sh(k, -1.0))) / (2.0 * h)).collect()
}
fn new_tape() -> Tape { Tape { par: vec![], val: vec![] } }
fn checkpointed(f0: &[f64], c: usize, keep_d: bool) -> (Vec<f64>, usize, usize) {
    let (mut cps, mut st) = (vec![], (1.0, vec![0.0; 4]));
    for m0 in (1..=STEPS).step_by(c) {
        cps.push((m0, st.clone())); st = run(&mut Plain, f0, st.0, st.1, m0, (m0 + c - 1).min(STEPS));
    }
    let (mut gf, mut dbar, mut vbar, mut peak) = (vec![0.0; NODES], 0.0, HOLD.to_vec(), 0);
    for (m0, (d, vs)) in cps.iter().rev() {
        let mut t = new_tape();
        let fs: Vec<usize> = f0.iter().map(|x| t.leaf(*x)).collect(); let ds = t.leaf(*d);
        let vsl: Vec<usize> = vs.iter().map(|x| t.leaf(*x)).collect();
        let (d1, v1) = run(&mut t, &fs, ds, vsl.clone(), *m0, (m0 + c - 1).min(STEPS));
        peak = peak.max(t.val.len()); let mut seed: Vec<(usize, f64)> = (0..4).map(|b| (v1[b], vbar[b])).collect();
        seed.push((d1, dbar)); let b = t.sweep(&seed, true);
        for j in 0..NODES { gf[j] += b[fs[j]]; }
        dbar = if keep_d { b[ds] } else { 0.0 };
        vbar = vsl.iter().map(|y| b[*y]).collect();
    }
    (gf, cps.len(), peak)
}
fn main() {
    let f0: Vec<f64> = (1..=NODES).map(|k| 0.03 + 0.015 * (1.0 - (-0.6 * k as f64 / 6.0).exp())).collect();
    // 1 reverse mode: record once, sweep once, seeded with the holdings vector q
    let mut t = new_tape();
    let fv: Vec<usize> = f0.iter().map(|x| t.leaf(*x)).collect(); let d0 = t.leaf(1.0);
    let z: Vec<usize> = (0..4).map(|_| t.leaf(0.0)).collect();
    let p = run(&mut t, &fv, d0, z, 1, STEPS).1;
    let (l, e) = (t.par.iter().filter(|e| !e.is_empty()).count(), t.par.iter().map(|e| e.len()).sum::<usize>());
    let (lf, ef) = (l as f64, e as f64);
    let pick = |bar: Vec<f64>| -> Vec<f64> { fv.iter().map(|i| bar[*i]).collect() };
    let qseed: Vec<(usize, f64)> = (0..4).map(|b| (p[b], HOLD[b])).collect();
    let g_rev = pick(t.sweep(&qseed, true));
    let rows: Vec<Vec<f64>> = (0..4).map(|b| pick(t.sweep(&[(p[b], 1.0)], true))).collect();
    let g_ones = pick(t.sweep(&(0..4).map(|b| (p[b], 1.0)).collect::<Vec<_>>(), true));
    let g_fwd_order = pick(t.sweep(&qseed, false));
    println!("bond prices per $100: {}", p.iter().map(|i| format!("{:.6}", t.val[*i])).collect::<Vec<_>>().join(" "));
    println!("book value ${:.2}; nodes F1 {:.6}, F49 {:.6}, F50 {:.6}", price(&f0), f0[0], f0[48], f0[49]);
    println!("tape: {} entries ({} inputs), {} operations, {} edges", t.val.len(), NODES + 5, l, e);
    println!("key-rate DV01, $ per bp, nodes 1..50 (10 a line):");
    for r in 0..5 { println!("{}", dv(&g_rev[10 * r..10 * r + 10])); }
    // 2 forward mode: 50 runs, each seeded on one node; each run gives a Jacobian column
    let cols: Vec<Vec<f64>> = (0..NODES).map(|k| {
        let fd: Vec<Du> = f0.iter().enumerate().map(|(j, x)| Du(*x, if j == k { 1.0 } else { 0.0 })).collect();
        run(&mut Dual, &fd, Du(1.0, 0.0), vec![Du(0.0, 0.0); 4], 1, STEPS).1.iter().map(|v| v.1).collect()
    }).collect();
    let g_fwd: Vec<f64> = cols.iter().map(|c| tot(&(0..4).map(|b| HOLD[b] * c[b]).collect::<Vec<_>>())).collect();
    // 3 closed form: dD_m/dF_j = -0.5 D_m (sum over periods i <= m of weight on node j)
    let (mut g_cf, mut acc, mut d) = (vec![0.0; NODES], vec![0.0; NODES], 1.0);
    for m in 1..=STEPS {
        for (j, w) in weights(m) { acc[j] += w; }
        d *= (-0.5 * tot(&weights(m).iter().map(|(j, w)| f0[*j] * w).collect::<Vec<_>>())).exp();
        let cf = flows(m);
        let cash = tot(&(0..4).map(|b| HOLD[b] * cf[b]).collect::<Vec<_>>());
        for j in 0..NODES { g_cf[j] += -0.5 * d * acc[j] * cash; }
    }
    // 4 bump and revalue, central, h = 1e-6 per node: 100 extra pricings
    let g_bump = bumped(&f0, 1e-6);
    println!("largest gap / largest DV01: forward mode {}, closed form {}, bump {}",
        sci(gap(&g_fwd, &g_rev)), sci(gap(&g_cf, &g_rev)), sci(gap(&g_bump, &g_rev)));
    let vjp: Vec<f64> = (0..NODES).map(|j| tot(&(0..4).map(|b| HOLD[b] * rows[b][j]).collect::<Vec<_>>())).collect();
    println!("q^T J from 4 row sweeps vs 1 seeded sweep: gap {}", sci(gap(&vjp, &g_rev)));
    println!("30-year bond row, node 50: reverse {:.6}, forward column {:.6} per $100 per bp", rows[0][49] * 1e-4, cols[49][0] * 1e-4);
    // house example: the whole curve up 1 bp, by repricing, against the sum of 50 sensitivities
    let up = price(&f0.iter().map(|x| x + 1e-4).collect::<Vec<_>>());
    let dn = price(&f0.iter().map(|x| x - 1e-4).collect::<Vec<_>>());
    let (par, s, cvx) = (up - price(&f0), tot(&g_rev) * 1e-4, (up + dn - 2.0 * price(&f0)) / 2.0);
    println!("parallel +1bp: repriced change {:.2}, sum of 50 DV01s {:.2}, gap {:.2}, convexity term {:.2}", par, s, par - s, cvx);
    // by hand: node 50 enters only period 60, weight 7/12; only the 30-year bond pays then (102)
    let (d59, f60) = (run(&mut Plain, &f0, 1.0, vec![0.0; 4], 1, 59).0, 5.0 / 12.0 * f0[48] + 7.0 / 12.0 * f0[49]);
    let (e60, db) = ((-0.5 * f60).exp(), HOLD[0] * 102.0);
    let gb = e60 * d59 * db; let fb = 7.0 / 12.0 * -0.5 * gb;
    println!("hand, period 60: f {:.6}, e {:.6}, D59 {:.6}, D60 {:.6}, Dbar {:.0}, gbar {:.2}, fbar {:.2}, F50bar {:.2}, DV01 {:.2}, D59bar from here {:.2}",
        f60, e60, d59, d59 * e60, db, gb, -0.5 * gb, fb, fb * 1e-4, e60 * db);
    // checkpointing: keep the 5-number state every C steps, re-record one segment at a time
    for c in [60, 15, C, 4, 1] {
        let (gc, ncp, peak) = checkpointed(&f0, c, true);
        println!("checkpoint every {:2} steps: {:2} stored states, peak tape {:4} entries, gap {}", c, ncp, peak, sci(gap(&gc, &g_rev)));
    }
    let (g_drop, g_drop1) = (checkpointed(&f0, C, false).0, checkpointed(&f0, 1, false).0);
    println!("cost in pricings: record + 1 sweep {:.2}, record + 4 sweeps {:.2}, forward mode {:.1}, bumps {}; edges per operation {:.2}",
        (lf + 2.0 * ef) / lf, (lf + 8.0 * ef) / lf, NODES as f64 * (lf + 2.0 * ef) / lf, 2 * NODES + 1, ef / lf);
    let g_tiny = bumped(&f0, 1e-12);
    println!("wrong: seed 1 on every bond: {:.2}; sweep in recording order: {:.2}; drop D-bar at checkpoints: {:.2}; at every step: {:.2}",
        tot(&g_ones) * 1e-4, tot(&g_fwd_order) * 1e-4, tot(&g_drop) * 1e-4, tot(&g_drop1) * 1e-4);
    println!("trap: per unit rate {:.2}; bump h = 1e-12, total {:.2}, worst gap {}", tot(&g_rev), tot(&g_tiny) * 1e-4, sci(gap(&g_tiny, &g_rev)));
    assert!(gap(&g_cf, &g_rev) < 1e-12, "closed form");
    assert!(gap(&g_fwd, &g_rev) < 1e-12, "forward mode");
    assert!(gap(&g_bump, &g_rev) < 1e-6, "bump and revalue");
    assert!(gap(&vjp, &g_rev) < 1e-12, "one seeded sweep = q^T J");
    assert!((par - s - cvx).abs() < 0.01 * cvx.abs(), "parallel bp: first order plus convexity");
    assert!((fb - g_rev[49]).abs() < 1e-9 * fb.abs(), "hand sweep for node 50");
    assert!(gap(&checkpointed(&f0, C, true).0, &g_rev) < 1e-12, "checkpointed sweep");
    assert!(gap(&g_drop, &g_rev) > 0.01, "the state's adjoint must cross segment boundaries");
    println!("ALL CHECKS PASS");
}
