// Continuous wavelet transform -- the same check as continuous_wavelet_transform_and_the_scalogram_check.py.
// Standard library only, no crates.  A synthetic, illustrative earthquake record
// (ground velocity, mm/s): P wave 8 Hz near 4 s, S wave 2 Hz near 10 s, surface
// wave 0.5 Hz near 16 s.  Morlet wavelet; scale a in seconds, frequency 1/a in hertz.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn exp(self) -> C { let m = self.re.exp(); C { re: m * self.im.cos(), im: m * self.im.sin() } }
}
const Z: C = C { re: 0.0, im: 0.0 };
fn kk() -> f64 { PI.powf(-0.25) * (2.0 * PI).sqrt() }    // peak height of the Morlet spectrum, at 1 Hz
fn kap() -> f64 { (-2.0 * PI * PI).exp() }                 // the correction that makes the mean zero
const WAVES: [(f64, f64, f64, f64); 3] = [(0.5, 8.0, 4.0, 0.2), (1.0, 2.0, 10.0, 0.8), (0.8, 0.5, 16.0, 3.2)];

fn record(t: f64) -> f64 {
    WAVES.iter().map(|&(a, nu, c, s)| a * (-(t - c).powi(2) / (2.0 * s * s)).exp() * (2.0 * PI * nu * t).cos()).sum()
}
fn psi(t: f64) -> C {                                      // Morlet mother wavelet (complex)
    C { re: (2.0 * PI * t).cos() - kap(), im: (2.0 * PI * t).sin() }.sc(PI.powf(-0.25) * (-t * t / 2.0).exp())
}
fn psi_hat(xi: f64) -> f64 { kk() * ((-2.0 * PI * PI * (xi - 1.0).powi(2)).exp() - kap() * (-2.0 * PI * PI * xi * xi).exp()) }
fn bump_hat(xi: f64) -> f64 { kk() * (-2.0 * PI * PI * xi * xi).exp() }

fn w(a: f64, b: f64) -> C {                                // road 1: closed form, Gaussian integrals in u = t - b
    let mut tot = Z;
    for &(amp, nu, c, s) in WAVES.iter() {
        let (d, al) = (c - b, 1.0 / (2.0 * s * s) + 1.0 / (2.0 * a * a));
        for sg in [1.0, -1.0] {
            for (m, wt) in [(1.0, 1.0), (0.0, -kap())] {
                let be = C { re: d / (s * s), im: 2.0 * PI * (sg * nu - m / a) };
                let ga = C { re: -d * d / (2.0 * s * s), im: 2.0 * PI * sg * nu * b };
                tot = tot.add(be.mul(be).sc(1.0 / (4.0 * al)).add(ga).exp().sc(amp / 2.0 * wt * (PI / al).sqrt()));
            }
        }
    }
    tot.sc(PI.powf(-0.25) / a.sqrt())
}
fn w_sum(a: f64, b: f64) -> C {                            // road 2: the defining integral as a sum of samples
    let fs = 50.0;
    let mut tot = Z;
    for k in 0..=1500 { let t = k as f64 / fs; tot = tot.add(psi((t - b) / a).conj().sc(record(t))); }
    tot.sc(1.0 / (fs * a.sqrt()))
}
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(lo + i as f64 * h); }
    s * h / 3.0
}
fn c_psi(hat: &dyn Fn(f64) -> f64, eps: f64, n: usize) -> f64 {
    simpson(&|u: f64| 0.5 * (hat(u.exp()).powi(2) + hat(-u.exp()).powi(2)), eps.ln(), 4.0f64.ln(), n)
}
fn double(dv: f64, r: f64, ts: &[f64], lo: f64, hi: f64) -> (f64, Vec<C>) {   // lo Hz to 1/hi Hz
    let (vlo, vhi, blo, bhi) = ((1.0 / lo).ln(), hi.ln(), -10.0, 40.0);
    let (mut e, mut rr) = (0.0, vec![Z; ts.len()]);
    for i in 0..=((vhi - vlo) / dv).round() as usize {
        let a = (vlo + i as f64 * dv).exp();
        let db = r * a;
        for j in 0..=((bhi - blo) / db).round() as usize {
            let b = blo + j as f64 * db;
            let x = w(a, b);
            e += x.abs().powi(2) / a * dv * db;
            for (k, &t) in ts.iter().enumerate() { rr[k] = rr[k].add(x.mul(psi((t - b) / a)).sc(dv * db / (a * a.sqrt()))); }
        }
    }
    (e, rr)
}
fn show(name: &str, vs: &[f64], d: usize) {
    let mut s = format!("{:<42}", name);
    for v in vs { s += &format!(" {:>12.*}", d, v); }
    println!("{}", s);
}

fn main() {
    // ---- the admissibility constant, and the bump that fails it ----
    let (c1, c2) = (c_psi(&psi_hat, 1e-6, 2000), c_psi(&psi_hat, 1e-6, 4000));
    show("C_psi Morlet, 2000 and 4000 steps", &[c1, c2], 9);
    for e in [1e-2, 1e-4, 1e-6] {
        show(&format!("cut-off {:.6} Hz: C Morlet, C bump", e), &[c_psi(&psi_hat, e, 4000), c_psi(&bump_hat, e, 4000)], 6);
    }
    show("psi_hat(0): Morlet, uncorrected, bump", &[psi_hat(0.0), kk() * kap(), bump_hat(0.0)], 12);
    let direct = 0.5 * simpson(&|x: f64| if x > 0.0 { psi_hat(x).powi(2) / x } else { 0.0 }, 0.0, 4.0, 40000);
    assert!((c1 - c2).abs() < 1e-9 && psi_hat(0.0).abs() < 1e-15 && (c2 - direct).abs() < 1e-8);
    assert!(c_psi(&bump_hat, 1e-6, 4000) - c_psi(&bump_hat, 1e-4, 4000) > 16.0);
    let side = |sg: f64| simpson(&|u: f64| psi_hat(sg * u.exp()).powi(2), (1e-6f64).ln(), 4.0f64.ln(), 4000);
    let (cp, cm) = (side(1.0), side(-1.0));
    show("C_+, C_-: scale totals, xi > 0 and xi < 0", &[cp, cm], 6);
    assert!(cm < 1e-12);                                  // the complex Morlet passes positive frequencies only

    // ---- energy and rebuild: the transform loses nothing ----
    let e1 = simpson(&|t: f64| record(t).powi(2), -10.0, 40.0, 10000);
    let e2 = simpson(&|t: f64| record(t).powi(2), -10.0, 40.0, 20000);
    show("energy of the record, 10000 and 20000 steps", &[e1, e2], 6);
    let ts = [4.05, 10.1, 16.3];
    let (ec, _) = double(0.04, 0.5, &ts, 40.0, 10.0);
    let (ef, rf) = double(0.02, 0.25, &ts, 40.0, 10.0);
    show("scalogram energy: coarse, fine grid", &[ec, ef], 6);
    let (ew, _) = double(0.04, 0.5, &[], 80.0, 20.0);   // second cut-off: 80 Hz to 0.05 Hz
    show("coarse, widened to 80 to 0.05 Hz; change", &[ew, (ew - ec).abs()], 9);
    assert!((ew - ec).abs() < 1e-9);
    show("C_psi x energy", &[c2 * e2], 6);
    show("scalogram energy / energy; same, no 1/2", &[ef / e2, ef / e2 / (2.0 * c2)], 6);
    for (t, r) in ts.iter().zip(rf.iter()) {
        show(&format!("record at {:.2} s: true, rebuilt", t), &[record(*t), r.re / c2], 6);
        assert!((r.re / c2 - record(*t)).abs() < 1e-5);
    }
    assert!((ef - c2 * e2).abs() < 1e-5 * e2 && (e1 - e2).abs() < 1e-9);

    // ---- the scalogram, and reading it ----
    let freqs: Vec<f64> = (0..9).map(|k| 8.0 * 2f64.powf(-(k as f64) / 2.0)).collect();
    let grid: Vec<Vec<f64>> = freqs.iter().map(|&f| (0..31).map(|b| w(1.0 / f, b as f64).abs().powi(2) * f).collect()).collect();
    let top = grid.iter().flatten().cloned().fold(0.0, f64::max);
    println!("normalised scalogram |W|^2/a, percent of its peak; time 0 to 30 s across");
    for (f, r) in freqs.iter().zip(grid.iter()) {
        let cells: String = r.iter().map(|v| format!("{:4}", (v / top * 100.0 + 0.5).floor() as i64)).collect();
        println!("{:5.2} Hz {}", f, cells);
    }
    let (mut raw, mut nrm) = (vec![], vec![]);
    for &(amp, nu, c, s) in WAVES.iter() {
        let a = 1.0 / nu;
        let (x, xs) = (w(a, c), w_sum(a, c));
        raw.push(x.abs().powi(2)); nrm.push(x.abs().powi(2) / a);
        println!("{:.1} Hz wave at {:.0} s, scale a = {:.3} s", nu, c, a);
        show("  |W|: closed form, sum of samples, gap", &[x.abs(), xs.abs(), x.sub(xs).abs()], 9);
        assert!(x.sub(xs).abs() < 1e-6);
        let se = (1.0 / (s * s) + 1.0 / (a * a)).powf(-0.5);
        let read = 2.0 * x.abs() / (kk() * a.sqrt());
        let hand = amp / 2.0 * kk() * se / a.sqrt();      // one-burst formula: the other bursts left out
        show("  by hand: sqrt a, envelope width, |W|", &[a.sqrt(), se, hand], 4);
        show("  s/a; one-burst |W|, gap to full |W|", &[s / a, hand, (x.abs() - hand).abs()], 9);
        show("  amplitude read 2|W|/(K sqrt a), by hand", &[read, amp * se / a], 4);
        assert!((read - amp * se / a).abs() < 1e-6);
        show("  time spread a/sqrt2 s, band 1/(2 sqrt2 pi a) Hz", &[a / 2f64.sqrt(), 1.0 / (2.0 * 2f64.sqrt() * PI * a)], 4);
    }
    let (mr, mn) = (raw.iter().cloned().fold(0.0, f64::max), nrm.iter().cloned().fold(0.0, f64::max));
    show("raw |W|^2, percent of largest: P, S, surface", &raw.iter().map(|x| 100.0 * x / mr).collect::<Vec<_>>(), 1);
    show("|W|^2/a, percent of largest: P, S, surface", &nrm.iter().map(|x| 100.0 * x / mn).collect::<Vec<_>>(), 1);
    show("K = pi^(-1/4) sqrt(2 pi); envelope factor", &[kk(), (1.0 + 1.0 / (1.6f64 * 1.6)).powf(-0.5)], 6);
    show("S - P time s; distance km at 6.0, 3.5 km/s", &[6.0, 6.0 * 6.0 * 3.5 / 2.5], 1);
    let fine: Vec<Vec<f64>> = (0..17).map(|k| { let f = 8.0 * 2f64.powf(-(k as f64) / 4.0);
        (0..121).map(|j| w(1.0 / f, j as f64 / 4.0).abs().powi(2) * f).collect() }).collect();
    let fmax = fine.iter().flatten().cloned().fold(0.0, f64::max);
    let pk: Vec<String> = [(16usize, 0usize), (40, 8), (64, 16)].iter().map(|&(j, k)| format!("{:.1}% at ({:.2} s, {:.2} Hz)",
        fine[k][j] / fmax * 100.0, j as f64 / 4.0, 8.0 * 2f64.powf(-(k as f64) / 4.0))).collect();
    println!("figure, 121 x 17 cells, 0 to 30 s by 8 to 0.5 Hz; peak shades {}", pk.join(", "));
    println!("ALL CHECKS PASS");
}
