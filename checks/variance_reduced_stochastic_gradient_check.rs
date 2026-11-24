// SVRG and SAGA -- the check behind the card.  std only.
// A 10-stock index tracker refit on 250 daily returns (synthetic, SplitMix64 seed 2026).
// The card MINIMISES f(w) = average over days of (1/2)(tracker return - index return)^2,
// in percent squared, with the weights summing to 1.  Put w10 = 1 - (w1 + ... + w9): the
// free variables are v = (w1, ..., w9) and day t's loss is f_t(v) = (1/2)(a_t . v - b_t)^2.
struct Rng { s: u64 }
impl Rng {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn u(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}
const N: usize = 250; const S: usize = 10; const D: usize = 9; const R3: f64 = 1.7320508075688772;
type V = Vec<f64>;
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut s = 0.0; for i in 0..u.len().min(v.len()) { s += u[i] * v[i]; } s }
fn unit(x: &[f64]) -> V { let n = dot(x, x).sqrt(); x.iter().map(|q| q / n).collect() }
struct P { a: Vec<V>, b: V, h: Vec<V>, vs: V, v0: V }
impl P {
    fn res(&self, t: usize, v: &[f64]) -> f64 { dot(&self.a[t], v) - self.b[t] }
    fn full(&self, v: &[f64]) -> V { let mut g = vec![0.0; D]; for t in 0..N { let q = self.res(t, v); for k in 0..D { g[k] += q * self.a[t][k] / N as f64; } } g }
    fn fval(&self, v: &[f64]) -> f64 { let mut s = 0.0; for t in 0..N { let r = self.res(t, v); s += r * r / 500.0; } s }
    fn mul(&self, v: &[f64]) -> V { (0..D).map(|k| dot(&self.h[k], v)).collect() }
    fn solve(&self, b: &[f64]) -> V {
        let mut m: Vec<V> = (0..D).map(|i| { let mut r = self.h[i].clone(); r.push(b[i]); r }).collect();
        for k in 0..D {
            let mut p = k;
            for r in k..D { if m[r][k].abs() > m[p][k].abs() { p = r; } }
            m.swap(k, p);
            for r in k + 1..D { let f = m[r][k] / m[k][k]; for q in k..D + 1 { m[r][q] -= f * m[k][q]; } }
        }
        let mut x = vec![0.0; D];
        for k in (0..D).rev() { x[k] = (m[k][D] - dot(&m[k][k + 1..D], &x[k + 1..D])) / m[k][k]; }
        x
    }
    fn gap(&self, v: &[f64]) -> f64 { let e: V = (0..D).map(|k| v[k] - self.vs[k]).collect(); 0.5 * dot(&e, &self.mul(&e)) }
    fn table(&self, pts: &[&[f64]]) -> V { (0..N).map(|t| self.res(t, pts[t])).collect() }   // each day's miss at its stored point
    fn variance(&self, v: &[f64], tab: &[f64]) -> (f64, f64) {
        let gv = self.full(v); let (mut sg, mut sv, mut gs) = (0.0, 0.0, vec![0.0; D]);
        for t in 0..N { for k in 0..D { gs[k] += tab[t] * self.a[t][k] / N as f64; } }
        for t in 0..N {
            let (q, p) = (self.res(t, v), tab[t]);
            let e1: V = (0..D).map(|k| q * self.a[t][k] - gv[k]).collect();
            let e2: V = (0..D).map(|k| (q - p) * self.a[t][k] + gs[k] - gv[k]).collect();
            sg += dot(&e1, &e1) / N as f64; sv += dot(&e2, &e2) / N as f64;
        }
        (sg, sv)
    }
    fn tick(&self, c: &mut usize, n: usize, u: &[f64], marks: &mut V) { for _ in 0..n { *c += 1; if *c % 1000 == 0 { marks.push(self.gap(u)); } } }
    fn run(&self, method: &str, calls: usize, alpha: f64, m: usize, refresh: bool, snap_days: usize, avg: bool, seed: u64) -> (V, V, f64) {
        let (mut r, mut v, mut c, mut marks, mut epochs) = (Rng { s: seed }, self.v0.clone(), 0usize, vec![self.gap(&self.v0)], vec![]);
        let (mut snap, mut gs, mut tab, mut tavg): (V, Option<V>, Option<V>, V) = (self.v0.clone(), None, None, vec![]);
        while c < calls {
            if method == "gd" {
                let g = self.full(&v); v = (0..D).map(|k| v[k] - alpha * g[k]).collect(); self.tick(&mut c, N, &v, &mut marks);
            } else if method == "sgd" {
                let t = (r.next() % N as u64) as usize; let q = self.res(t, &v);
                v = (0..D).map(|k| v[k] - alpha * q * self.a[t][k]).collect(); self.tick(&mut c, 1, &v, &mut marks);
            } else if method == "saga" && tab.is_none() {
                tab = Some((0..N).map(|t| self.res(t, &v)).collect()); tavg = self.full(&v); self.tick(&mut c, N, &v, &mut marks);
            } else if method == "saga" {                 // the table holds each day's miss at its last visit
                let t = (r.next() % N as u64) as usize; let q = self.res(t, &v);
                let tb = tab.as_mut().unwrap(); let dq = q - tb[t]; tb[t] = q;
                v = (0..D).map(|k| v[k] - alpha * (dq * self.a[t][k] + tavg[k])).collect();
                tavg = (0..D).map(|k| tavg[k] + dq * self.a[t][k] / N as f64).collect(); self.tick(&mut c, 1, &v, &mut marks);
            } else {                                     // svrg: one epoch of m inner steps
                if gs.is_none() || refresh {
                    let days: Vec<usize> = if snap_days < N { (0..snap_days).map(|_| (r.next() % N as u64) as usize).collect() } else { (0..N).collect() };
                    let mut g = vec![0.0; D];
                    for &t in &days { let q = self.res(t, &snap); for k in 0..D { g[k] += q * self.a[t][k] / days.len() as f64; } }
                    gs = Some(g); self.tick(&mut c, snap_days, &snap, &mut marks);
                }
                let g = gs.clone().unwrap(); v = snap.clone(); let mut acc = vec![0.0; D];
                for _ in 0..m {
                    acc = (0..D).map(|k| acc[k] + v[k] / m as f64).collect();
                    let t = (r.next() % N as u64) as usize; let q = self.res(t, &v) - self.res(t, &snap);
                    v = (0..D).map(|k| v[k] - alpha * (q * self.a[t][k] + g[k])).collect(); self.tick(&mut c, 2, &v, &mut marks);
                }
                if refresh { snap = if avg { acc } else { v.clone() }; }
                epochs.push(self.gap(&snap));
            }
        }
        let e = self.gap(&v); (marks, epochs, e)
    }
}
fn main() {
    let mut rng = Rng { s: 2026 };
    let beta: V = (0..S).map(|_| 0.8 + 0.4 * rng.u()).collect();
    let sig: V = (0..S).map(|_| 1.0 + rng.u()).collect();
    let (mut a, mut b) = (vec![], vec![]);
    for _ in 0..N {
        let m = 0.04 + R3 * (2.0 * rng.u() - 1.0);
        let r: V = (0..S).map(|j| beta[j] * m + sig[j] * R3 * (2.0 * rng.u() - 1.0)).collect();
        let y = m + 0.3 * R3 * (2.0 * rng.u() - 1.0);
        a.push((0..D).map(|j| r[j] - r[S - 1]).collect::<V>()); b.push(y - r[S - 1]);
    }
    let col = |i: usize| -> V { (0..N).map(|t| a[t][i]).collect() };
    let h: Vec<V> = (0..D).map(|i| (0..D).map(|j| dot(&col(i), &col(j)) / N as f64).collect()).collect();
    let rhs: V = (0..D).map(|i| dot(&col(i), &b) / N as f64).collect();
    let mut p = P { a: a.clone(), b: b.clone(), h, vs: vec![0.0; D], v0: vec![0.1; D] };
    p.vs = p.solve(&rhs); let (vs, v0) = (p.vs.clone(), p.v0.clone()); let fs = p.fval(&vs);
    let (mut x, mut z) = (vec![1.0; D], vec![1.0; D]);
    for _ in 0..300 { x = unit(&p.solve(&x)); z = unit(&p.mul(&z)); }
    let mu = 1.0 / dot(&p.solve(&x), &p.solve(&x)).sqrt(); let lf = dot(&p.mul(&z), &p.mul(&z)).sqrt();
    let lmax = (0..N).map(|t| dot(&a[t], &a[t])).fold(f64::MIN, f64::max);
    let mut sig2 = 0.0; for t in 0..N { let r = p.res(t, &vs); sig2 += r * r * dot(&a[t], &a[t]) / N as f64; }
    let mut w = vs.clone(); w.push(1.0 - dot(&vs, &vec![1.0; D]));
    println!("optimal weights, %: {}", w.iter().map(|q| format!("{:.2}", 100.0 * q)).collect::<Vec<_>>().join(" "));
    println!("f* = {:.4}, tracking error sqrt(2 f*) = {:.4} % a day", fs, (2.0 * fs).sqrt());
    println!("start (equal weights): f - f* = {:.6} by subtraction, {:.6} by the quadratic form", p.fval(&v0) - fs, p.gap(&v0));
    println!("L_max {:.2}  L_f {:.2}  mu {:.4}  kappa_max {:.1}  kappa_f {:.1}  sigma^2 {:.4}", lmax, lf, mu, lmax / mu, lf / mu, sig2);
    println!("steps: 0.1/L_max = {:.6}, 1/(2 L_max) = {:.6}, 1/(3 L_max) = {:.6}, 1/L_f = {:.4}", 0.1 / lmax, 0.5 / lmax, 1.0 / (3.0 * lmax), 1.0 / lf);
    assert!(w.iter().all(|&q| q > 0.0) && p.full(&vs).iter().all(|q| q.abs() < 1e-12) && (p.fval(&v0) - fs - p.gap(&v0)).abs() < 1e-12);
    let d = [|x: f64| 2.0 * (x - 1.0), |x: f64| 2.0 * (x + 1.0)];   // by hand: f1 = (x-1)^2, f2 = (x+1)^2, f'(x) = 2x
    for (x, s) in [(0.0, 0.0), (0.5, 0.0), (0.25, 0.5)] {   // the point, and where the stored slopes were taken
        let e: V = d.iter().map(|g| g(x) - g(s) + (d[0](s) + d[1](s)) / 2.0).collect();
        let sgv = ((d[0](x) - 2.0 * x).powi(2) + (d[1](x) - 2.0 * x).powi(2)) / 2.0;
        println!("hand x = {:.2}, stored at {:.1}: SGD {:+.1} {:+.1} (variance {:.0}), corrected {:+.1} {:+.1}, f'(x) {:+.1}", x, s, d[0](x), d[1](x), sgv, e[0], e[1], 2.0 * x);
        assert!(e[0] == 2.0 * x && e[1] == 2.0 * x && sgv == 4.0);
    }
    for (name, v, snap) in [("start, snapshot start", &v0, &v0), ("optimum, snapshot start", &vs, &v0), ("optimum, snapshot optimum", &vs, &vs)] {
        let (sg, sv) = p.variance(v, &p.table(&vec![snap.as_slice(); N])); let bound = 4.0 * lmax * (p.gap(v) + p.gap(snap));
        println!("variance at {:<25} SGD {:.4}  SVRG {:.6}  bound {:.6}", name, sg, sv, bound);
        assert!(sv <= bound + 1e-12);
    }
    assert!((p.variance(&vs, &p.table(&vec![vs.as_slice(); N])).0 - sig2).abs() < 1e-12 && p.variance(&vs, &p.table(&vec![v0.as_slice(); N])).1 > 0.0);
    for (name, pts) in [("at the start", vec![v0.as_slice(); N]), ("half at optimum", (0..N).map(|t| if t % 2 == 1 { vs.as_slice() } else { v0.as_slice() }).collect()), ("at the optimum", vec![vs.as_slice(); N])] {
        let sv = p.variance(&vs, &p.table(&pts)).1; let bound = 4.0 * lmax * p.gap(&vs) + 2.0 * (0..N).map(|t| (p.res(t, pts[t]) - p.res(t, &vs)).powi(2) * dot(&a[t], &a[t]) / N as f64).fold(0.0, |s, x| s + x);
        println!("variance at optimum, SAGA table {:<15} SAGA {:.6}  bound {:.6}", name, sv, bound); assert!(sv <= bound + 1e-12);
    }
    let al = 0.1 / lmax;
    let runs = [("GD, step 1/L_f", p.run("gd", 10000, 1.0 / lf, 500, true, N, false, 7)), ("SGD, step 0.1/L_max", p.run("sgd", 10000, al, 500, true, N, false, 7)),
        ("SVRG, step 0.1/L_max, m 500", p.run("svrg", 10000, al, 500, true, N, false, 7)), ("SAGA, step 1/(3 L_max)", p.run("saga", 10000, 1.0 / (3.0 * lmax), 500, true, N, false, 7))];
    println!("log10(f - f*) after 0, 1000, ..., 10000 gradient calls:");
    for (name, h) in &runs { println!("{:<28} {}", name, h.0.iter().map(|q| format!("{:.2}", q.log10())).collect::<Vec<_>>().join(" ")); }
    let end: V = runs.iter().map(|(_, h)| h.2).collect(); assert!(end[2] < 1e-3 * end[1] && end[2] < end[0] && end[3] < end[2]);
    let (mut r, mut v, mut fl) = (Rng { s: 11 }, vs.clone(), 0.0);   // SGD's floor: time average from the optimum
    for _ in 0..200000 {
        let t = (r.next() % N as u64) as usize; let q = p.res(t, &v);
        v = (0..D).map(|j| v[j] - al * q * a[t][j]).collect(); fl += p.gap(&v) / 200000.0;
    }
    println!("SGD floor at step 0.1/L_max: time average {:.6}, formula alpha sigma^2 / 4 = {:.6}", fl, al * sig2 / 4.0);
    assert!((fl / (al * sig2 / 4.0) - 1.0).abs() < 0.1);
    let ratio = |al: f64, m: f64| 1.0 / (mu * al * (1.0 - 2.0 * lmax * al) * m) + 2.0 * lmax * al / (1.0 - 2.0 * lmax * al);   // the theorem's R
    assert!((ratio(0.1 / lmax, 20.0 * lmax / mu) - 0.875).abs() < 1e-12);   // the textbook setting, by hand: 1/1.6 + 1/4
    for m in [500usize, (20.0 * lmax / mu).ceil() as usize] {   // the epoch theorem, snapshot = the epoch's average
        let bound = ratio(al, m as f64);
        let ep = p.run("svrg", 6 * (N + 2 * m), al, m, true, N, true, 5).1;
        let meas = (ep[ep.len() - 1] / p.gap(&v0)).powf(1.0 / ep.len() as f64);
        println!("m = {} ({} calls an epoch): theorem's ratio {:.4}; measured, mean of {} epochs {:.4}", m, N + 2 * m, bound, ep.len(), meas);
        assert!(meas < 1.0 && (bound > 1.0 || meas <= bound));
    }
    let (stale, batch) = (p.run("svrg", 10000, al, 500, false, N, false, 7).2, p.run("svrg", 10000, al, 500, true, 25, false, 7).2);
    let big = p.run("svrg", 2500, 5.0 / lmax, 500, true, N, false, 7).2;   // far past the theorem's step limit 1/(2 L_max)
    println!("SVRG gap: snapshot never refreshed {:.6}; snapshot gradient from 25 days {:.6}; step 5/L_max {:.1}", stale, batch, big);
    assert!(stale > 1e3 * end[2] && batch > p.gap(&v0) && big > 1e5 * p.gap(&v0));
    let mut need = vec![];
    for (name, h) in [("GD", p.run("gd", 60000, 1.0 / lf, 500, true, N, false, 7)), ("SVRG", p.run("svrg", 60000, al, 500, true, N, false, 7)), ("SAGA", p.run("saga", 60000, 1.0 / (3.0 * lmax), 500, true, N, false, 7))] {
        need.push(1000 * h.0.iter().position(|&q| q < 1e-10).unwrap()); println!("calls to reach f - f* < 1e-10: {} {}", name, need[need.len() - 1]);
    }
    assert!(need[2] < need[1] && need[1] < need[0]);
    println!("calls per factor e in the bounds: GD n kappa_f = {:.0}; SVRG, SAGA of order n + kappa_max = {:.0}", N as f64 * lf / mu, N as f64 + lmax / mu);
    println!("SAGA bound per step: 1 - min(1/(4n) = {:.6}, mu/(3 L_max) = {:.6})", 1.0 / (4.0 * N as f64), mu / (3.0 * lmax));
    println!("SAGA table: {} numbers here (one miss a day); a general gradient table for 2,000 assets: {}", N, N * 2000);
    println!("ALL CHECKS PASS");
}
