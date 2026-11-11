// Robust and chance constraints -- the check behind the card.  std only, no crates.
// Five assets, returns in % a year.  Maximise the worst-case expected return over a ball
// of radius DELTA = 1 point around the estimates, with a 95% chance of losing at most ELL = 10%.
// Roads: log-barrier Newton with a gap certificate, a 2% grid, water-filling, the ball sampled, simulated years.
const N: usize = 5;
const NAMES: [&str; N] = ["UK", "World", "Prop", "Gilts", "Gold"];
const MU: [f64; N] = [7.0, 7.4, 6.8, 4.0, 5.0]; // estimated expected return, %
const SD: [f64; N] = [16.0, 15.0, 18.0, 8.0, 14.0]; // yearly standard deviation, %
const DELTA: f64 = 1.0; const ELL: f64 = 10.0; const EPS: f64 = 0.05;
type V = Vec<f64>;
fn add(xs: impl Iterator<Item = f64>) -> f64 { xs.fold(0.0, |a, b| a + b) } // left-to-right sum
fn dot(a: &[f64], b: &[f64]) -> f64 { add(a.iter().zip(b).map(|(x, y)| x * y)) }
fn pc(w: &[f64]) -> String { w.iter().map(|v| format!("{:6.2}", 100.0 * v)).collect::<Vec<_>>().join(" ") }
fn f4(w: &[f64]) -> String { w.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" ") }
fn ncdf(x: f64) -> f64 { // bell-curve area left of x, Simpson's rule
    let (n, mut s) = (2000, 1.0 + (-0.5 * x * x).exp());
    let h = x / n as f64;
    for k in 1..n { let kh = k as f64 * h; s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * (-0.5 * kh * kh).exp(); }
    0.5 + s * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}
struct P { sig: Vec<V>, z: f64 }
impl P {
    fn stats(&self, w: &[f64], delta: f64) -> (f64, V, f64, f64, f64) { // |w|, Sigma w, sd, worst mean, VaR slack
        let sw: V = self.sig.iter().map(|r| dot(r, w)).collect();
        let (nw, sd, m) = (dot(w, w).sqrt(), dot(w, &sw).sqrt(), dot(&MU, w));
        (nw, sw, sd, m - delta * nw, m + ELL - self.z * sd)
    }
    fn phi(&self, x: &[f64], t: f64, delta: f64) -> f64 { // barrier cost on four weights
        let w = full(x); let (_, _, _, f, s) = self.stats(&w, delta);
        if w.iter().cloned().fold(f64::INFINITY, f64::min) <= 0.0 || s <= 0.0 { return f64::INFINITY; }
        -t * f - add(w.iter().map(|v| v.ln())) - s.ln()
    }
    fn barrier(&self, delta: f64) -> (V, f64, f64, i32) { // road 1: feasible start, t = 1
        let (mut x, mut t, mut newton, z) = (vec![0.1, 0.1, 0.1, 0.5], 1.0f64, 0, self.z);
        while 6.0 / t >= 1e-6 {
            t *= 10.0;
            loop {
                let w = full(&x); let (nw, sw, sd, _, s) = self.stats(&w, delta);
                let gf: V = (0..N).map(|i| MU[i] - delta * w[i] / nw).collect();
                let gs: V = (0..N).map(|i| MU[i] - z * sw[i] / sd).collect();
                let g: V = (0..N).map(|i| -t * gf[i] - 1.0 / w[i] - gs[i] / s).collect();
                let h: Vec<V> = (0..N).map(|i| (0..N).map(|j| {
                    let e = if i == j { 1.0 } else { 0.0 };
                    t * delta * (e - w[i] * w[j] / (nw * nw)) / nw + e / (w[i] * w[i])
                        + gs[i] * gs[j] / (s * s) + z * (self.sig[i][j] - sw[i] * sw[j] / (sd * sd)) / (sd * s)
                }).collect()).collect();
                let gx: V = (0..4).map(|i| g[i] - g[4]).collect();
                let hx: Vec<V> = (0..4).map(|i| (0..4).map(|j| h[i][j] - h[i][4] - h[4][j] + h[4][4]).collect()).collect();
                let d = solve(&hx, &gx.iter().map(|v| -v).collect::<V>()); let dec = -dot(&gx, &d);
                let (mut a, p0) = (1.0, self.phi(&x, t, delta));
                while a > 1e-9 && self.phi(&(0..4).map(|i| x[i] + a * d[i]).collect::<V>(), t, delta) > p0 - 0.25 * a * dec { a *= 0.5; }
                if dec < 1e-10 || a <= 1e-9 { break; } // centred, or rounding stops progress
                x = (0..4).map(|i| x[i] + a * d[i]).collect(); newton += 1;
            }
        }
        let w = full(&x); let (nw, sw, sd, _, s) = self.stats(&w, delta);
        let (lam, lb): (f64, V) = (1.0 / (t * s), w.iter().map(|v| 1.0 / (t * v)).collect()); // prices: VaR, w_i >= 0
        let gr: V = (0..N).map(|i| MU[i] - delta * w[i] / nw + lam * (MU[i] - z * sw[i] / sd) + lb[i]).collect();
        let nu = add(gr.iter().cloned()) / N as f64; // KKT: every entry of gr equals nu
        assert!(gr.iter().all(|v| (v - nu).abs() < 1e-6) && lb.iter().all(|&v| v > 0.0) && lam > 0.0);
        (w, lam, 6.0 / t, newton)
    }
}
fn full(x: &[f64]) -> V { let mut w = x.to_vec(); w.push(1.0 - add(x.iter().cloned())); w }
fn solve(m: &[V], b: &[f64]) -> V { // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut r: Vec<V> = (0..n).map(|i| { let mut row = m[i].clone(); row.push(b[i]); row }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, i| if r[i][c].abs() > r[p][c].abs() { i } else { p });
        r.swap(c, p);
        let rc = r[c].clone();
        for i in (0..n).filter(|&i| i != c) { let f = r[i][c] / rc[c]; for j in 0..=n { r[i][j] -= f * rc[j]; } }
    }
    (0..n).map(|i| r[i][n] / r[i][i]).collect()
}
struct Rng(u64);
impl Rng {
    fn rnd(&mut self) -> f64 { // SplitMix64, a uniform in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = self.rnd(); let u2 = self.rnd();
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos() }
}
fn main() {
    let rho = |i: usize, j: usize| match (i.min(j), i.max(j)) {
        (0, 1) => 0.9, (0, 2) => 0.7, (1, 2) => 0.5, (1, 4) => 0.2, (2, 3) => 0.3, (2, 4) => 0.2, (3, 4) => 0.3, _ => 0.0 };
    let sig: Vec<V> = (0..N).map(|i| (0..N).map(|j| SD[i] * SD[j] * if i == j { 1.0 } else { rho(i, j) }).collect()).collect();
    let (mut lo, mut hi) = (0.0f64, 4.0f64);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if ncdf(mid) < 1.0 - EPS { lo = mid } else { hi = mid } }
    let p = P { sig: sig.clone(), z: lo };
    println!("z for chance {:.2}: {:.6}, N(z) = {:.6}", EPS, p.z, ncdf(p.z));
    println!("assets      {}", NAMES.iter().map(|n| format!("{:>6}", n)).collect::<Vec<_>>().join(" "));
    println!("estimates % {}", MU.iter().map(|m| format!("{:6.2}", m)).collect::<Vec<_>>().join(" "));
    // ---- no VaR limit: water-filling, certified by its worst-case estimates ----
    let mut order: Vec<usize> = (0..N).collect();
    order.sort_by(|&a, &b| MU[b].partial_cmp(&MU[a]).unwrap());
    let mut nu = 0.0;
    for k in 1..=N {
        let top: V = order[..k].iter().map(|&i| MU[i]).collect(); let m = add(top.iter().cloned()) / k as f64;
        let ss = add(top.iter().map(|v| (v - m) * (v - m)));
        if ss > DELTA * DELTA { continue; }
        nu = m - ((DELTA * DELTA - ss) / k as f64).sqrt();
        if k == N || MU[order[k]] <= nu { break; }
    }
    let wf0: V = (0..N).map(|i| (MU[i] - nu).max(0.0)).collect();
    let wf: V = wf0.iter().map(|v| v / add(wf0.iter().cloned())).collect();
    let nf = p.stats(&wf, DELTA); let mf: V = (0..N).map(|i| MU[i] - DELTA * wf[i] / nf.0).collect();
    println!("no VaR limit: {}  worst {:.4}, VaR95 {:.4}", pc(&wf), nf.3, ELL - nf.4);
    println!("  its worst estimates {}", f4(&mf));
    assert!((nf.3 - nu).abs() < 1e-12 && mf.iter().all(|&v| v <= nu + 1e-12));
    // ---- the card's problem: nominal (radius 0) and robust (radius 1) ----
    println!("plan        {}  est.   |w|    worst  sd     VaR95", NAMES.iter().map(|n| format!("{:>6}", n)).collect::<Vec<_>>().join(" "));
    let mut plans = vec![];
    for (name, dl) in [("nominal", 0.0), ("robust", DELTA)] {
        let (w, lam, gap, newton) = p.barrier(dl); let (nw, _, sd, worst, s) = p.stats(&w, DELTA);
        println!("{:11} {}  {:.4} {:.4} {:.4} {:.4} {:.4}", name, pc(&w), dot(&MU, &w), nw, worst, sd, ELL - s);
        println!("  certificate: {} Newton steps, gap at most {:.7}, VaR price {:.4}", newton, gap, lam);
        assert!(s.abs() < 1e-5); // the VaR limit binds
        plans.push(w);
    }
    let (wn, wr) = (plans[0].clone(), plans[1].clone());
    let ((nr, _, sdr, best, _), nn) = (p.stats(&wr, DELTA), p.stats(&wn, DELTA));
    // ---- road 2: every split on a 2% grid that meets the VaR limit ----
    let (mut gbest, mut gw) = (f64::NEG_INFINITY, vec![]);
    for a in 0..51 { for b in 0..51 - a { for c in 0..51 - a - b { for d in 0..51 - a - b - c {
        let w = vec![a as f64 / 50.0, b as f64 / 50.0, c as f64 / 50.0, d as f64 / 50.0, (50 - a - b - c - d) as f64 / 50.0];
        let st = p.stats(&w, DELTA);
        if st.4 >= 0.0 && st.3 > gbest { gbest = st.3; gw = w; }
    } } } }
    println!("2% grid best: {}  worst {:.4}, below the barrier by {:.4}", pc(&gw), gbest, best - gbest);
    assert!(gbest <= best + 1e-9 && best - gbest < 0.02);
    // ---- road 3: the worst case by Cauchy-Schwarz, against 20,000 points on the ball ----
    let mstar: V = (0..N).map(|i| MU[i] - DELTA * wr[i] / nr).collect();
    println!("robust plan's worst estimates {}, earns {:.4}", f4(&mstar), dot(&mstar, &wr));
    let (mut g, mut smin) = (Rng(0x2026111100000001), f64::INFINITY); // seed
    for _ in 0..20000 {
        let u: V = (0..N).map(|_| g.gauss()).collect(); let r = dot(&u, &u).sqrt();
        smin = smin.min(dot(&(0..N).map(|i| MU[i] + DELTA * u[i] / r).collect::<V>(), &wr));
    }
    println!("20,000 points on the ball: lowest {:.4}, never below {:.4}", smin, best);
    assert!(best - 1e-12 <= smin && smin < best + 0.05);
    let mn: V = (0..N).map(|i| MU[i] - DELTA * wn[i] / nn.0).collect();
    println!("in the nominal plan's worst world: nominal earns {:.4}, robust {:.4}", dot(&mn, &wn), dot(&mn, &wr));
    // ---- road 4: the chance constraint, 200,000 simulated years (C with C C^T = Sigma) ----
    let mut cm = vec![vec![0.0; N]; N];
    for i in 0..N { for j in 0..=i {
        let v = sig[i][j] - add((0..j).map(|k| cm[i][k] * cm[j][k]));
        cm[i][j] = if i == j { v.sqrt() } else { v / cm[j][j] };
    } }
    let cw: V = (0..N).map(|j| add((0..N).map(|i| cm[i][j] * wr[i]))).collect(); // C^T w
    let (years, mut bad, se) = (200000, 0, (EPS * (1.0 - EPS) / 200000.0).sqrt());
    for _ in 0..years {
        let e: V = (0..N).map(|_| g.gauss()).collect(); if dot(&MU, &wr) + dot(&cw, &e) < -ELL { bad += 1; }
    }
    println!("simulated years losing over {:.0}%: {} of {} = {:.4} (target {:.4}, se {:.4})", ELL, bad, years, bad as f64 / years as f64, EPS, se);
    assert!((bad as f64 / years as f64 - EPS).abs() < 4.0 * se && (dot(&cw, &cw).sqrt() - sdr).abs() < 1e-9);
    // ---- what breaks ----
    let m = dot(&MU, &wr); let kk = (m + 10.5) / sdr; let p2 = 1.0 / (1.0 + kk * kk);
    println!("two-point year, same mean and sd: lose 10.50% with chance {:.4}, else gain {:.4}", p2, m + sdr / kk);
    assert!((p2 * -10.5 + (1.0 - p2) * (m + sdr / kk) - m).abs() < 1e-9 && p2 > 5.0 * EPS);
    println!("any-law z (Cantelli): {:.4}", ((1.0 - EPS) / EPS).sqrt());
    println!("nominal promises {:.4}, can earn {:.4}; box promise {:.4}; robust worst case on £1,000,000: £{:.0} a year", dot(&MU, &wn), nn.3, dot(&MU, &wn) - DELTA, 1e4 * best);
    println!("by hand, robust: w {}, |w|^2 {:.5}, |w| {:.5}, est {:.5}, worst {:.5}, sd {:.5}, z*sd {:.5}, VaR95 at worst estimates {:.5}", wr.iter().map(|v| format!("{:.5}", v)).collect::<Vec<_>>().join(" "), nr * nr, nr, dot(&MU, &wr), best, sdr, p.z * sdr, ELL + DELTA * nr);
    let r2 = DELTA / 2f64.sqrt(); // figure: half in each of two assets, 1 point = 60
    println!("figure, centre 180 120, radius 60, box corner 120 180, worst point {:.1} {:.1}, ball worst {:.4}, box worst {:.4}", 180.0 - 60.0 * r2, 120.0 + 60.0 * r2, 7.2 - r2, 7.2 - DELTA);
    println!("ALL CHECKS PASS");
}
