// Cheyette (quasi-Gaussian) check: x and y carry the whole forward curve.  std only, no crates.  Roads:
// (1) Hull-White's closed-form bond call; (2) a 2-D (x, y) grid stepped back from expiry; (3) Monte Carlo of
// x and y; (4) the bond formula against Hull-White's, and y's equation by RK4 against its closed form.
const KAP: f64 = 0.03; const S0: f64 = 0.01; const SKEW: f64 = 0.2; // pull, base vol, slope
const TE: f64 = 1.0; const TM: f64 = 5.0; const STRIKES: [f64; 5] = [0.79, 0.81, 0.83, 0.85, 0.87];   // expiry, bond
const NX: usize = 161; const NY: usize = 41; const NT: usize = 160; const XM: f64 = 0.06; const YM: f64 = 3e-4;
struct Curve { pil: Vec<f64>, d: Vec<f64>, fw: Vec<f64> }
impl Curve {
    fn new() -> Curve {                                // the Hull-White card's six quotes
        let mut d: Vec<f64> = vec![1.0, 1.0 / (1.0 + 0.5 * 0.0400), 1.0 / (1.0 + 1.0 * 0.0420)];
        for (n, s) in [(2usize, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)] {
            let mut acc = 0.0; for j in 1..n { acc += d[j + 1]; } d.push((1.0 - s * acc) / (1.0 + s));   // D at 1, 2, ... years
        }
        let pil = vec![0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0];
        let fw = (0..6).map(|i| (d[i] / d[i + 1]).ln() / (pil[i + 1] - pil[i])).collect();
        Curve { pil, d, fw }
    }
    fn df(&self, t: f64) -> f64 { self.d[self.pil.iter().position(|&p| p == t).unwrap()] }
    fn f0(&self, t: f64) -> f64 { self.fw[self.pil[1..].iter().filter(|&&p| t >= p).count().min(5)] }
    fn recon(&self, t: f64, tt: f64, x: f64, y: f64) -> f64 { let g = gg(t, tt, KAP); self.df(tt) / self.df(t) * (-g * x - 0.5 * g * g * y).exp() }
    fn hw(&self, t: f64, tt: f64, r: f64) -> f64 {     // Hull-White's A, B formula, a = kappa
        let b = gg(t, tt, KAP);
        self.df(tt) / self.df(t) * (b * self.f0(t) - S0 * S0 / (4.0 * KAP) * (1.0 - (-2.0 * KAP * t).exp()) * b * b - b * r).exp()
    }
    fn zbc(&self, k: f64, sig: f64, kap: f64) -> (f64, f64, f64) {   // road 1
        let sp = sig * ((1.0 - (-2.0 * kap * TE).exp()) / (2.0 * kap)).sqrt() * gg(TE, TM, kap);
        let h = (self.df(TM) / (self.df(TE) * k)).ln() / sp + sp / 2.0;
        (self.df(TM) * ncdf(h) - k * self.df(TE) * ncdf(h - sp), sp, h)
    }
    fn implied(&self, k: f64, p: f64) -> f64 {
        let (mut lo, mut hi) = (0.001, 0.05);
        for _ in 0..50 { let mid = 0.5 * (lo + hi); if self.zbc(k, mid, KAP).0 < p { lo = mid } else { hi = mid } }
        0.5 * (lo + hi)
    }
}
fn gg(t: f64, tt: f64, k: f64) -> f64 { (1.0 - (-k * (tt - t)).exp()) / k }
fn ybar(t: f64) -> f64 { S0 * S0 * (1.0 - (-2.0 * KAP * t).exp()) / (2.0 * KAP) }
fn vol(x: f64, b: f64) -> f64 { (S0 + b * x).max(0.001) }
fn ncdf(z: f64) -> f64 {                               // bell-curve area by Simpson's rule
    let n = 2000; let a = z.abs(); let h = a / n as f64;
    let g = |u: f64| (-u * u / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt();
    let mut acc = 0.0; for k in 1..n { acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(k as f64 * h); }
    let s = h / 3.0 * (g(0.0) + g(a) + acc); if z > 0.0 { 0.5 + s } else { 0.5 - s }
}
type Pay<'a> = Box<dyn Fn(f64, f64) -> f64 + 'a>;
fn grid(c: &Curve, pays: &[Pay], b: f64, by: f64, ex: Option<&Pay>) -> Vec<f64> {   // y carried at vol(x, by)
    let xs: Vec<f64> = (0..NX).map(|i| -XM + 2.0 * XM * i as f64 / (NX - 1) as f64).collect();
    let ys: Vec<f64> = (0..NY).map(|j| YM * j as f64 / (NY - 1) as f64).collect();
    let (dx, dy, dt) = (xs[1] - xs[0], ys[1], TE / NT as f64);
    let mut vs: Vec<Vec<Vec<f64>>> = pays.iter().map(|p| xs.iter().map(|&x| ys.iter().map(|&y| p(x, y)).collect()).collect()).collect();
    for n in (0..NT).rev() {
        let rf = c.f0(n as f64 * dt); let th = if n >= NT - 4 { 1.0 } else { 0.5 };
        for v in vs.iter_mut() {
            let mut w = vec![vec![0.0; NY]; NX];           // 1: carry y along its drift
            for i in 0..NX {
                let s2 = vol(xs[i], by) * vol(xs[i], by);
                for j in 0..NY {
                    let y = ys[j]; let q = (y + (s2 - 2.0 * KAP * y) * dt).min(YM) / dy;
                    let m = (q as usize).min(NY - 2);
                    w[i][j] = v[i][m] + (q - m as f64) * (v[i][m + 1] - v[i][m]);
                }
            }
            for j in 0..NY {                               // 2: theta-scheme in x
                let y = ys[j]; let mut l = Vec::with_capacity(NX);
                for i in 0..NX {
                    let x = xs[i]; let mu = y - KAP * x;
                    let d = 0.5 * vol(x, b) * vol(x, b) / (dx * dx);
                    if i == 0 { l.push((0.0, -(rf + x) - mu / dx, mu / dx)); }
                    else if i == NX - 1 { l.push((-mu / dx, -(rf + x) + mu / dx, 0.0)); }
                    else { l.push((d - mu / (2.0 * dx), -2.0 * d - rf - x, d + mu / (2.0 * dx))); }
                }
                let cc = (1.0 - th) * dt;
                let mut rh: Vec<f64> = (0..NX).map(|i| w[i][j] + cc * ((if i > 0 { l[i].0 * w[i - 1][j] } else { 0.0 }) + l[i].1 * w[i][j]
                    + (if i < NX - 1 { l[i].2 * w[i + 1][j] } else { 0.0 }))).collect();
                let lo: Vec<f64> = l.iter().map(|e| -th * dt * e.0).collect();
                let mut di: Vec<f64> = l.iter().map(|e| 1.0 - th * dt * e.1).collect();
                let up: Vec<f64> = l.iter().map(|e| -th * dt * e.2).collect();
                for i in 1..NX { let ww = lo[i] / di[i - 1]; di[i] -= ww * up[i - 1]; rh[i] -= ww * rh[i - 1]; }
                v[NX - 1][j] = rh[NX - 1] / di[NX - 1];
                for i in (0..NX - 1).rev() { v[i][j] = (rh[i] - up[i] * v[i + 1][j]) / di[i]; }
            }
        }
        if let (Some(e), true) = (ex, n == NT / 2) { let v = vs.last_mut().unwrap(); for i in 0..NX { for j in 0..NY { v[i][j] = v[i][j].max(e(xs[i], ys[j])); } } }
    }
    vs.iter().map(|v| v[NX / 2][0]).collect()
}
struct Rng(u64);                                       // 64-bit LCG, then Box-Muller
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u1 = self.unif(); let u2 = self.unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos() }
}
fn monte_carlo(c: &Curve, b: f64, pairs: usize, steps: usize) -> Vec<(f64, f64)> {   // road 3
    let dt = TE / steps as f64; let mut acc = vec![(0.0, 0.0); STRIKES.len() + 3]; let mut rng = Rng(20261123);
    for _ in 0..pairs {
        let zs: Vec<f64> = (0..steps).map(|_| rng.gauss()).collect(); let mut vals = vec![];
        for sgn in [1.0, -1.0] {
            let (mut x, mut y, mut ix) = (0.0, 0.0, 0.0);
            for &z in &zs {
                let s = vol(x, b); let nx = x + (y - KAP * x) * dt + s * dt.sqrt() * sgn * z;
                y += (s * s - 2.0 * KAP * y) * dt; ix += 0.5 * dt * (x + nx); x = nx;
            }
            let disc = c.df(TE) * (-ix).exp(); let p = c.recon(TE, TM, x, y);
            let mut row: Vec<f64> = STRIKES.iter().map(|&k| disc * (p - k).max(0.0)).collect();
            row.extend([disc * p, disc, y]); vals.push(row);
        }
        for k in 0..acc.len() { let v = 0.5 * (vals[0][k] + vals[1][k]); acc[k].0 += v; acc[k].1 += v * v; }
    }
    let n = pairs as f64; acc.iter().map(|&(s, q)| (s / n, ((q / n - (s / n) * (s / n)).max(0.0) / n).sqrt())).collect()
}
fn main() {
    let c = Curve::new(); let (mut y, h, fy) = (0.0, 0.001, |y: f64| S0 * S0 - 2.0 * KAP * y);   // road 4a: dy/dt by RK4
    for _ in 0..1000 { let k1 = fy(y); let k2 = fy(y + h / 2.0 * k1); let k3 = fy(y + h / 2.0 * k2); y += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + fy(y + h * k3)); }
    let (g15, fwd) = (gg(TE, TM, KAP), c.df(TM) / c.df(TE));
    println!("curve: D(1) {:.8}  D(5) {:.8}  forward bond D(5)/D(1) {:.6}", c.df(1.0), c.df(5.0), fwd);
    println!("kappa {}  G(1,5) {:.6}  y(1) closed {:.10}  RK4 {:.10}", KAP, g15, ybar(1.0), y);
    assert!((y - ybar(1.0)).abs() < 1e-13);
    println!("t=1 bond to 5 y: x %, short rate %, Cheyette P(1,5), Hull-White P(1,5)");
    for x in [-0.02, 0.0, 0.02] {                         // road 4b
        let (pc, ph) = (c.recon(TE, TM, x, ybar(TE)), c.hw(TE, TM, c.f0(TE) + x));
        println!("  {:+.1}  {:.4}  {:.8}  {:.8}", 100.0 * x, 100.0 * (c.f0(TE) + x), pc, ph);
        assert!((pc - ph).abs() < 1e-12);
    }
    let (c83, sp, hh) = c.zbc(0.83, S0, KAP);
    println!("by hand, K 0.83: sigma_p {:.6}  h {:.6}  N(h) {:.6}  N(h-sp) {:.6}  call {:.6}", sp, hh, ncdf(hh), ncdf(hh - sp), c83);
    let lv: Vec<String> = [-0.02, -0.01, 0.0, 0.01, 0.02].iter().map(|&x| format!("{:.2}", 100.0 * vol(x, SKEW))).collect();
    println!("local vol % at x = -2, -1, 0, 1, 2 %: {}", lv.join(" "));
    let mut pays: Vec<Pay> = vec![];
    for &k in STRIKES.iter() { let cr = &c; pays.push(Box::new(move |x, y| (cr.recon(TE, TM, x, y) - k).max(0.0))); }
    pays.push(Box::new(|x, y| c.recon(TE, TM, x, y))); let cr = &c;
    let put = |t: f64| -> Pay { Box::new(move |x, y| (0.83 - cr.recon(t, TM, x, y)).max(0.0)) };
    let (g0, g1, o1) = (grid(&c, &pays, 0.0, 0.0, None), grid(&c, &pays, SKEW, SKEW, None), grid(&c, &pays, SKEW, 0.0, None));   // o1: one state
    let (mc, mc0) = (monte_carlo(&c, SKEW, 10000, 100), monte_carlo(&c, 0.0, 10000, 100));
    println!("strike: HW closed, grid b=0, implied % | grid b=0.2, MC b=0.2 (se), implied %");
    let (mut iv0, mut iv1) = (vec![], vec![]);
    for (k, &kk) in STRIKES.iter().enumerate() {
        let cf = c.zbc(kk, S0, KAP).0; iv0.push(c.implied(kk, g0[k])); iv1.push(c.implied(kk, g1[k]));
        println!("  {:.2}  {:.6}  {:.6}  {:.4} | {:.6}  {:.6} ({:.6})  {:.4}", kk, cf, g0[k], 100.0 * iv0[k], g1[k], mc[k].0, mc[k].1, 100.0 * iv1[k]);
        assert!((g0[k] - cf).abs() < 3e-6 && (iv0[k] - S0).abs() < 2e-5);
        assert!((g1[k] - mc[k].0).abs() < 4.0 * mc[k].1);
    }
    assert!(iv1[0] > iv1[2] && iv1[2] > iv1[4] && iv1[0] - iv1[4] > 0.002); let nb = STRIKES.len();
    println!("5-y zero through the grid: b=0 {:.8}  b=0.2 {:.8}  market {:.8}", g0[nb], g1[nb], c.df(5.0));
    assert!((g0[nb] - c.df(5.0)).abs() < 3e-6 && (g1[nb] - c.df(5.0)).abs() < 3e-6);
    println!("MC b=0.2: D(1) {:.6} ({:.6})  D(5) {:.6} ({:.6})  mean y(1) {:.10}", mc[nb + 1].0, mc[nb + 1].1, mc[nb].0, mc[nb].1, mc[nb + 2].0);
    println!("MC b=0, same draws: D(1) {:.8} ({:.8})  D(5) {:.8} ({:.8})  call 0.83 {:.6} ({:.6})", mc0[nb + 1].0, mc0[nb + 1].1, mc0[nb].0, mc0[nb].1, mc0[2].0, mc0[2].1);
    for m in [&mc, &mc0] { assert!((m[nb + 1].0 - c.df(1.0)).abs() < 4.0 * m[nb + 1].1 && (m[nb].0 - c.df(5.0)).abs() < 4.0 * m[nb].1); }
    assert!(STRIKES.iter().enumerate().all(|(k, &kk)| (mc0[k].0 - c.zbc(kk, S0, KAP).0).abs() < 4.0 * mc0[k].1));
    let bp = grid(&c, &[put(TE), put(TE)], SKEW, SKEW, Some(&put(0.5)));   // the second put may also be exercised at 0.5 y
    let par = g1[2] - g1[nb] + 0.83 * c.df(TE);
    println!("put K 0.83, b=0.2: European {:.6}  (parity {:.6})  Bermudan, also at 0.5 y {:.6}", bp[0], par, bp[1]);
    assert!((bp[0] - par).abs() < 3e-6 && bp[1] > bp[0] + 1e-3);
    let os: Vec<String> = [nb, 0, 2, 4].iter().map(|&k| format!("{:.2}", 1e7 * (o1[k] - g1[k]))).collect();
    println!("one state, y held at ybar(t), minus two states, on 10,000,000 face: 5-y zero {}  (calls 0.79, 0.83, 0.87)", os.join(" "));
    assert!((o1[nb] - g1[nb]).abs() > 2e-6);
    let i5 = (0..1000).map(|k| gg(TE * (k as f64 + 0.5) / 1000.0, TM, KAP).powi(2)).sum::<f64>() * TE / 1000.0;   // integral of G(s,5)^2
    let (nod, noc) = (c.df(TM) * (0.5 * S0 * S0 * i5 - 0.5 * g15 * g15 * ybar(TE)).exp(), c.df(TM) * (0.5 * g15 * g15 * ybar(TE)).exp());
    println!("what breaks, on 10,000,000 face (b=0, closed form):");
    println!("  drop y from x's drift: 5-y zero {:.8}, error {:.2}", nod, 1e7 * (nod - c.df(5.0)));
    println!("  drop the G^2 y / 2 term: 5-y zero {:.8}, error {:.2}", noc, 1e7 * (noc - c.df(5.0)));
    let c3 = c.zbc(0.83, S0, 0.3).0;
    println!("  kappa 0.3 not 0.03, K 0.83: call {:.6}, error {:.2}", c3, 1e7 * (c3 - c83));
    let f87 = c.zbc(0.87, S0, KAP).0; println!("  flat Hull-White on the skewed market, K 0.87: {:.6} vs {:.6}, error {:.2}", f87, g1[4], 1e7 * (f87 - g1[4]));
    assert!((nod - c.df(5.0)).abs() > 1e-4 && (c3 - c83).abs() > 1e-3);
    let fm = |v: &Vec<f64>| v.iter().map(|x| format!("{:.2}", 100.0 * x)).collect::<Vec<_>>().join(" ");
    println!("chart, implied %: b=0 {} | b=0.2 {}", fm(&iv0), fm(&iv1));
    println!("ALL CHECKS PASS");
}
