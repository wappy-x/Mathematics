// Search without derivatives -- the check behind the card.  std only, no crates.
// Minimise a rough 10-D surface using only its values: Nelder-Mead, annealing, differential
// evolution, random search; 20,000 evaluations per run, 10 seeded runs each (SplitMix64 written out).
// Roads: every result against the proved floor f >= 0; a fixed-temperature walk against Simpson's
// rule on exp(-g/T); Nelder-Mead on McKinnon's function against its calculus minimum; a smooth bowl.
use std::f64::consts::PI;
struct Rng { s: u64 } fn rng(seed: u64) -> Rng { Rng { s: seed } }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn g(&mut self) -> f64 { let u1 = self.u(); let u2 = self.u(); (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos() }
}
fn tot<I: Iterator<Item = f64>>(v: I) -> f64 { let mut s = 0.0; for t in v { s += t; } s }
const N: usize = 10; const BOX: f64 = 5.12; const BUD: usize = 20000; const RUNS: usize = 10; const T0: f64 = 30.0; const TEND: f64 = 0.1;
fn ripple(t: f64) -> f64 { t * t - 10.0 * (2.0 * PI * t).cos() + 10.0 }
fn mck(x: &[f64]) -> f64 { (if x[0] <= 0.0 { 360.0 } else { 6.0 }) * x[0] * x[0] + x[1] + x[1] * x[1] }
fn bowl(x: &[f64]) -> f64 { tot(x.iter().map(|t| t * t)) }
struct St { n: usize, best: f64, hist: Vec<f64> }
impl St {
    fn reset(&mut self) { self.n = 0; self.best = f64::INFINITY; self.hist = vec![]; }
    fn ev(&mut self, f: &dyn Fn(&[f64]) -> f64, x: &[f64]) -> f64 {
        let v = f(x); self.n += 1; self.best = self.best.min(v);
        if self.n % 2000 == 0 { self.hist.push(self.best); } v
    }
}
fn simplex(x: &[f64], step: f64) -> Vec<Vec<f64>> {
    let mut p = vec![x.to_vec()]; for i in 0..x.len() { let mut y = x.to_vec(); y[i] += step; p.push(y); } p
}
fn argmin(v: &[f64]) -> usize { let mut b = 0; for i in 1..v.len() { if v[i] < v[b] { b = i; } } b }
fn nelder_mead(st: &mut St, f: &dyn Fn(&[f64]) -> f64, mut p: Vec<Vec<f64>>, budget: usize) -> (Vec<f64>, f64) {
    let n = p.len() - 1; let mut v: Vec<f64> = p.iter().map(|x| st.ev(f, x)).collect();
    while st.n + n + 2 <= budget {
        let mut o: Vec<usize> = (0..=n).collect(); o.sort_by(|&a, &b| v[a].partial_cmp(&v[b]).unwrap());
        p = o.iter().map(|&i| p[i].clone()).collect(); v = o.iter().map(|&i| v[i]).collect();
        let mut diam = 0.0f64; for q in &p { for j in 0..n { diam = diam.max((q[j] - p[0][j]).abs()); } }
        if v[n] - v[0] <= 1e-8 && diam <= 1e-6 { break; }
        let c: Vec<f64> = (0..n).map(|j| tot((0..n).map(|i| p[i][j])) / n as f64).collect();
        let pt = |t: f64, w: &Vec<f64>| -> Vec<f64> { (0..n).map(|j| c[j] + t * (w[j] - c[j])).collect() };
        let xr = pt(-1.0, &p[n]); let fr = st.ev(f, &xr);
        if fr < v[0] {
            let xe = pt(-2.0, &p[n]); let fe = st.ev(f, &xe);
            if fe < fr { p[n] = xe; v[n] = fe; } else { p[n] = xr; v[n] = fr; }
        } else if fr < v[n - 1] { p[n] = xr; v[n] = fr; } else {
            let xc = pt(if fr < v[n] { -0.5 } else { 0.5 }, &p[n]); let fc = st.ev(f, &xc);
            if fc < fr.min(v[n]) { p[n] = xc; v[n] = fc; } else {
                for i in 1..=n {
                    p[i] = (0..n).map(|j| p[0][j] + 0.5 * (p[i][j] - p[0][j])).collect(); v[i] = st.ev(f, &p[i]);
                }
            }
        }
    }
    let i = argmin(&v); (p[i].clone(), v[i])
}
fn anneal(st: &mut St, f: &dyn Fn(&[f64]) -> f64, mut x: Vec<f64>, temp: &dyn Fn(usize) -> f64, r: &mut Rng) -> f64 {
    let mut fx = st.ev(f, &x);
    while st.n < BUD {
        let t = temp(st.n); let mut y = x.clone(); let i = (r.u() * N as f64) as usize; y[i] += r.g();
        let fy = st.ev(f, &y); let d = fy - fx;
        if d <= 0.0 || (t > 0.0 && r.u() < (-d / t).exp()) { x = y; fx = fy; }
    } fx
}
fn evolve(st: &mut St, f: &dyn Fn(&[f64]) -> f64, r: &mut Rng) {
    let (np, fw, cr) = (40usize, 0.5, 0.9);
    let mut p: Vec<Vec<f64>> = (0..np).map(|_| (0..N).map(|_| BOX * (2.0 * r.u() - 1.0)).collect()).collect();
    let mut v: Vec<f64> = p.iter().map(|x| st.ev(f, x)).collect();
    while st.n + np <= BUD {
        for i in 0..np {
            let (mut a, mut b, mut c) = (i, i, i);
            while a == i { a = (r.u() * np as f64) as usize; }
            while b == i || b == a { b = (r.u() * np as f64) as usize; }
            while c == i || c == a || c == b { c = (r.u() * np as f64) as usize; }
            let jr = (r.u() * N as f64) as usize;
            let y: Vec<f64> = (0..N).map(|j| if r.u() < cr || j == jr { p[a][j] + fw * (p[b][j] - p[c][j]) } else { p[i][j] }).collect();
            let fy = st.ev(f, &y); if fy <= v[i] { p[i] = y; v[i] = fy; }
        }
    }
}
fn mean(v: &[f64]) -> f64 { tot(v.iter().cloned()) / v.len() as f64 }
fn minv(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) } fn maxv(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::NEG_INFINITY, f64::max) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let mut rq = rng(2026); let mut q: Vec<Vec<f64>> = vec![];   // a fixed random rotation, by Gram-Schmidt
    for _ in 0..N {
        let mut v: Vec<f64> = (0..N).map(|_| rq.g()).collect();
        for w in &q { let d = tot((0..N).map(|k| v[k] * w[k])); v = (0..N).map(|k| v[k] - d * w[k]).collect(); }
        let nv = tot(v.iter().map(|a| a * a)).sqrt(); q.push(v.iter().map(|a| a / nv).collect());
    }
    let rough = |x: &[f64]| -> f64 { tot((0..N).map(|i| ripple(tot((0..N).map(|j| q[i][j] * x[j]))))) };
    let mut st = St { n: 0, best: f64::INFINITY, hist: vec![] }; let qf = (TEND / T0).powf(1.0 / BUD as f64);
    let names = ["random search", "Nelder-Mead, one run", "Nelder-Mead, multistart", "anneal",
                 "cold, T = 0", "hot, T = 30 held", "log cooling", "differential evolution"];
    let temps: Vec<Box<dyn Fn(usize) -> f64>> = vec![Box::new(move |k| T0 * qf.powf(k as f64)), Box::new(|_| 0.0),
        Box::new(|_| T0), Box::new(|k| T0 / (k as f64 + 2.0).ln())];
    let mut res: Vec<Vec<f64>> = vec![vec![]; 8]; let mut ends: Vec<Vec<f64>> = vec![vec![]; 4];
    let mut hists: Vec<Vec<f64>> = vec![vec![]; 6]; let (mut one_evals, mut starts, mut x01) = (vec![], vec![], vec![]);
    for seed in 1..=RUNS {
        let mut r = rng(seed as u64); st.reset();
        let x0: Vec<f64> = (0..N).map(|_| BOX * (2.0 * r.u() - 1.0)).collect(); let mut x = x0.clone(); if x01.is_empty() { x01 = x0.clone(); }
        while st.n + 2 * N + 3 <= BUD {   // multistart: fresh random start each time a simplex collapses
            let (_, v) = nelder_mead(&mut st, &rough, simplex(&x, 1.0), BUD);
            if one_evals.len() < seed { res[1].push(v); one_evals.push(st.n as f64); }
            x = (0..N).map(|_| BOX * (2.0 * r.u() - 1.0)).collect();
        }
        while st.hist.len() < BUD / 2000 { st.hist.push(st.best); }
        res[2].push(st.best); if seed == 1 { hists[0] = st.hist.clone(); }
        for (m, temp) in temps.iter().enumerate() {
            st.reset(); let fend = anneal(&mut st, &rough, x0.clone(), temp.as_ref(), &mut rng(1000 + seed as u64));
            res[3 + m].push(st.best); ends[m].push(fend); if seed == 1 { hists[1 + m] = st.hist.clone(); }
        }
        st.reset(); evolve(&mut st, &rough, &mut rng(2000 + seed as u64)); res[7].push(st.best); if seed == 1 { hists[5] = st.hist.clone(); }
        st.reset(); let mut r = rng(3000 + seed as u64);
        for _ in 0..BUD { let y: Vec<f64> = (0..N).map(|_| BOX * (2.0 * r.u() - 1.0)).collect(); st.ev(&rough, &y); }
        res[0].push(st.best); starts.push(rough(&x0));
    }
    println!("n = {}, budget {}, {} runs, f(origin) = {:.2}; start, run 1: f = {:.2}; mean start {:.2}",
             N, BUD, RUNS, rough(&[0.0; N]), starts[0], mean(&starts));
    for (m, v) in names.iter().zip(&res) { println!("{:<26} mean {:6.2}  best {:6.2}  worst {:6.2}", m, mean(v), minv(v), maxv(v)); }
    println!("one Nelder-Mead run stops after {:.1} evaluations on average", mean(&one_evals));
    for m in [0usize, 2, 3] { println!("{}: mean value where the walk ends {:.2}", names[3 + m], mean(&ends[m])); }
    println!("cooling factor q = {:.6}; T at 10000 = {:.4}; log cooling T at 20000 = {:.4}", qf, T0 * qf.powf(10000.0), T0 / (BUD as f64 + 2.0).ln());
    for k in (0..=BUD).step_by(4000) {
        let t = T0 * qf.powf(k as f64); let b = if k > 0 { hists[1][k / 2000 - 1] } else { starts[0] };
        println!("trace k = {:5}: T = {:8.4}, accept +10 with {:.6}, best so far {:.2}", k, t, (-10.0 / t).exp(), b);
    }
    for (m, h) in [("nm", 0usize), ("anneal", 1), ("de", 5)] {
        let mut v = vec![starts[0]]; v.extend(&hists[h]); println!("chart {}: {}", m, join(&v, 2));
    }
    let rp: Vec<f64> = (0..25).map(|k| ripple(-3.0 + 0.25 * k as f64)).collect(); println!("chart ripple: {}", join(&rp, 2));
    let s33 = 33f64.sqrt(); let p = vec![vec![0.0, 0.0], vec![1.0, 1.0], vec![(1.0 + s33) / 8.0, (1.0 - s33) / 8.0]];
    let c: Vec<f64> = (0..2).map(|j| (p[0][j] + p[2][j]) / 2.0).collect(); let xr: Vec<f64> = (0..2).map(|j| 2.0 * c[j] - p[1][j]).collect();
    let xcc: Vec<f64> = (0..2).map(|j| c[j] + 0.5 * (p[1][j] - c[j])).collect();
    println!("McKinnon start: f = {}; third vertex ({:.4}, {:.4})", join(&p.iter().map(|x| mck(x)).collect::<Vec<_>>(), 4), p[2][0], p[2][1]);
    println!("McKinnon step: c = ({:.4}, {:.4}), reflect ({:.4}, {:.4}) f = {:.4}, inside ({:.4}, {:.4}) f = {:.4}",
             c[0], c[1], xr[0], xr[1], mck(&xr), xcc[0], xcc[1], mck(&xcc));
    st.reset(); let (xs, vs) = nelder_mead(&mut st, &mck, p.clone(), 5000); let n1 = st.n;
    let (xm, vm) = nelder_mead(&mut st, &mck, simplex(&xs, 1.0), 5000); let tm = mck(&[0.0, -0.5]);
    println!("McKinnon stall: ({:.6}, {:.6}) f = {:.6} after {}; restart: ({:.6}, {:.6}) f = {:.6} after {}; true minimum f(0, -0.5) = {:.6}",
             xs[0], xs[1], vs, n1, xm[0], xm[1], vm, st.n, tm);
    st.reset(); let (_, vb) = nelder_mead(&mut st, &bowl, simplex(&x01, 1.0), BUD);
    println!("smooth bowl, same start: Nelder-Mead reaches f = {:.2e} after {} evaluations", vb, st.n);
    let (mut r, mut y, mut fy, mut inside, t, batch) = (rng(4000), 0.0f64, ripple(0.0), [0usize; 20], 5.0, 10000usize);
    for k in 0..20 * batch {   // walk at a fixed T
        let z = y + r.g(); let fz = ripple(z);
        if fz <= fy || r.u() < (-(fz - fy) / t).exp() { y = z; fy = fz; }
        if y.abs() < 0.5 { inside[k / batch] += 1; }
    }
    let simpson = |a: f64, b: f64, m: usize| -> f64 { let h = (b - a) / m as f64;
        tot((0..=m).map(|k| (if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * (-ripple(a + k as f64 * h) / t).exp())) * h / 3.0
    };
    let share: Vec<f64> = inside.iter().map(|&i| i as f64 / batch as f64).collect(); let walk = mean(&share);
    let se = (tot(share.iter().map(|s| (s - walk) * (s - walk))) / (19.0 * 20.0)).sqrt(); let exact = simpson(-0.5, 0.5, 2000) / simpson(-10.0, 10.0, 2000);
    println!("fixed T = 5, one ripple: walk spends {:.4} of its time in |y| < 0.5 (se {:.4}); exp(-g/T) gives {:.4}", walk, se, exact);
    let nf = N as f64; let l = 2.0 * BOX * nf.sqrt() + 20.0 * PI * nf.sqrt();  let h = 2.0 * 1.0 / (l * nf.sqrt()); let m = (2.0 * BOX / h).ceil() + 1.0;
    println!("certificate by grid: L = {:.2}, spacing {:.6}, {} points per axis, 10^{:.2} points", l, h, m, nf * m.log10());
    let pr = PI.powf(5.0) / 120.0 * 0.5f64.powf(nf) / (2.0 * BOX).powf(nf);
    println!("random search: one draw lands within 0.5 of the origin with chance {:.4} in 10^13; expected draws {:.2} million million", pr * 1e13, 1.0 / pr / 1e12);
    let mut orth = 0.0f64; for i in 0..N { for j in 0..N { orth = orth.max((tot((0..N).map(|k| q[i][k] * q[j][k])) - if i == j { 1.0 } else { 0.0 }).abs()); } }
    assert!(orth < 1e-12, "the rotation is not orthogonal");
    assert!(res.iter().map(|v| minv(v)).fold(f64::INFINITY, f64::min) >= 0.0, "a best found below the proved floor f >= 0");
    assert!(vs > tm + 0.2 && (vm - tm).abs() < 1e-6, "McKinnon: stall, then restart");
    assert!(mck(&xr) >= mck(&p[1]) && mck(&xcc) < mck(&p[1]), "McKinnon's first step is an inside contraction");
    assert!(vb < 1e-8, "Nelder-Mead on a smooth bowl must reach 0"); assert!((walk - exact).abs() < 4.0 * se, "walk vs exp(-g/T)");
    assert!(mean(&res[3]) < mean(&res[4]) && mean(&res[3]) < mean(&res[2]));
    println!("ALL CHECKS PASS");
}
