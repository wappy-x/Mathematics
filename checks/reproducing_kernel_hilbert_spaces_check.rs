// Reproducing kernels -- the same check as the Python, in Rust.  No crates; the solver is written out.
// Gaussian kernel in base 2, k(x, z) = 2^-((x - z)/1 m)^2: at whole-metre depths every kernel value
// is an exact fraction, held in the small struct Q below.
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128);                                 // numerator, denominator > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }

trait Fld: Copy + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self> { fn zero() -> Self; fn mag(self) -> f64; }
impl Fld for Q { fn zero() -> Q { Q(0, 1) } fn mag(self) -> f64 { (self.0 as f64 / self.1 as f64).abs() } }
impl Fld for f64 { fn zero() -> f64 { 0.0 } fn mag(self) -> f64 { self.abs() } }

fn z(n: i128) -> Q { Q(n, 1) }
fn fq(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn kq(x: i128, w: i128) -> Q { Q(1, 1i128 << ((x - w) * (x - w))) }    // exact, whole metres only
fn kf(x: f64, w: f64) -> f64 { 2f64.powf(-((x - w) * (x - w))) }
fn num(x: Q) -> String { if x.1 == 1 { format!("{}", x.0) } else { format!("{:.4}", fq(x)) } }
fn vec(v: &[Q]) -> String { format!("({})", v.iter().map(|x| num(*x)).collect::<Vec<_>>().join(", ")) }
fn c2f(v: f64) -> String { format!("{:5.2}", if v.abs() < 0.005 { 0.0 } else { v }) }   // no "-0.00"
fn dot<T: Fld>(u: &[T], v: &[T]) -> T { u.iter().zip(v).fold(T::zero(), |s, (a, b)| s + *a * *b) }
fn mv<T: Fld>(a: &[Vec<T>], v: &[T]) -> Vec<T> { a.iter().map(|r| dot(r, v)).collect() }

fn solve<T: Fld>(a: &[Vec<T>], b: &[T]) -> Vec<T> {   // Gauss-Jordan with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<T>> = a.iter().zip(b).map(|(r, v)| { let mut r = r.clone(); r.push(*v); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].mag() > m[p][c].mag() { p = r } }
        m.swap(c, p);
        for r in 0..n {
            if r != c {
                let f = m[r][c] / m[c][c];
                let pivot = m[c].clone();
                m[r] = m[r].iter().zip(&pivot).map(|(x, e)| *x - f * *e).collect();
            }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}

fn ridge(cent: &[f64], xs: &[f64], ys: &[f64], lm: f64) -> (Vec<f64>, f64) {
    let b: Vec<Vec<f64>> = xs.iter().map(|&x| cent.iter().map(|&w| kf(x, w)).collect()).collect();
    let g: Vec<Vec<f64>> = cent.iter().map(|&x| cent.iter().map(|&w| kf(x, w)).collect()).collect();
    let nc = cent.len();
    let a: Vec<Vec<f64>> = (0..nc).map(|r| (0..nc).map(|s| (0..xs.len()).fold(0.0, |t, i| t + b[i][r] * b[i][s]) + lm * g[r][s]).collect()).collect();
    let c = solve(&a, &(0..nc).map(|r| (0..xs.len()).fold(0.0, |t, i| t + b[i][r] * ys[i])).collect::<Vec<f64>>());
    let miss = ys.iter().zip(&mv(&b, &c)).fold(0.0, |t, (a, b)| t + (a - b) * (a - b));
    (c.clone(), miss + lm * dot(&c, &mv(&g, &c)))
}

fn phi(x: f64, m: usize) -> Vec<f64> {
    let c2 = 2.0 * 2f64.ln();
    let mut fact = 1.0;
    (0..m).map(|k| { if k > 0 { fact *= k as f64 } 2f64.powf(-((x - 2.0) * (x - 2.0))) * (c2.sqrt() * (x - 2.0)).powi(k as i32) / fact.sqrt() }).collect()
}

fn main() {
    let (depth, temp, deep): ([i128; 3], [i128; 3], i128) = ([1, 2, 3], [16, 13, 12], 10);
    let y: Vec<Q> = temp.iter().map(|t| z(t - deep)).collect();
    let (lam, deepf) = (q(1, 16), deep as f64);
    // ---- the finite rehearsal: functions on the three depths ----
    let k: Vec<Vec<Q>> = depth.iter().map(|&a| depth.iter().map(|&b| kq(a, b)).collect()).collect();
    let kinv: Vec<Vec<Q>> = (0..3).map(|j| solve(&k, &(0..3).map(|i| z((i == j) as i128)).collect::<Vec<Q>>())).collect();
    let reads: Vec<Q> = (0..3).map(|j| dot(&y, &mv(&kinv, &k[j]))).collect();
    println!("Gram matrix K, rows: {}", k.iter().map(|r| vec(r)).collect::<Vec<_>>().join("; "));
    println!("K^-1 x 225, rows: {}", kinv.iter().map(|r| vec(&r.iter().map(|v| z(225) * *v).collect::<Vec<Q>>())).collect::<Vec<_>>().join("; "));
    println!("<y, k_x> on the three depths reads off y: {}", vec(&reads));
    println!("base-2 kernel = exp(-d^2/(2 l^2)) with reach l = 1/sqrt(2 ln 2) = {:.4} m", 1.0 / (2.0 * 2f64.ln()).sqrt());
    // ---- kernel ridge: the best fit is a sum of kernels at the data points ----
    let kl: Vec<Vec<Q>> = (0..3).map(|i| (0..3).map(|j| if i == j { k[i][j] + lam } else { k[i][j] }).collect()).collect();
    let alpha = solve(&kl, &y);
    let fitted = mv(&k, &alpha);
    let resid: Vec<Q> = y.iter().zip(&fitted).map(|(a, b)| *a - *b).collect();
    let norm2 = dot(&alpha, &mv(&k, &alpha));
    let jstar = dot(&resid, &resid) + lam * norm2;
    println!("alpha = (K + I/16)^-1 y = {}  exactly {}", vec(&alpha), alpha.iter().map(|a| if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) }).collect::<Vec<_>>().join(", "));
    println!("by hand: 16(K + I/16) rows {}; 16y = {}", kl.iter().map(|r| vec(&r.iter().map(|v| z(16) * *v).collect::<Vec<Q>>())).collect::<Vec<_>>().join("; "), vec(&y.iter().map(|v| z(16) * *v).collect::<Vec<Q>>()));
    let s13 = alpha[0] + alpha[2];
    println!("  a1 - a3 = {}, a1 + a3 = {}/{} = {}, 89 a2 = {}", num(alpha[0] - alpha[2]), s13.0, s13.1, num(s13), num(z(89) * alpha[1]));
    println!("fit at 1, 2, 3 m: {} deg C; residuals {}", vec(&fitted.iter().map(|f| *f + z(deep)).collect::<Vec<Q>>()), vec(&resid));
    println!("residual / lambda = {} (equals alpha)", vec(&resid.iter().map(|r| *r / lam).collect::<Vec<Q>>()));
    println!("|f|^2 = alpha.K.alpha = {}, |f| = {:.4}; J* = misses {} + lambda |f|^2 {} = {}", num(norm2), fq(norm2).sqrt(), num(dot(&resid, &resid)), num(lam * norm2), num(jstar));
    let fx = |x: f64| alpha.iter().zip(&depth).fold(0.0, |s, (a, d)| s + fq(*a) * kf(x, *d as f64));
    let grid: Vec<f64> = (0..11).map(|i| i as f64 / 2.0).collect();
    println!("depth m:  {}", grid.iter().map(|x| format!("{:5.1}", x)).collect::<Vec<_>>().join(" "));
    println!("fit - 10:  {}", grid.iter().map(|&x| c2f(fx(x))).collect::<Vec<_>>().join(" "));
    for (a, d) in alpha.iter().zip(&depth) {
        println!("bump {} m: {}", d, grid.iter().map(|&x| c2f(fq(*a) * kf(x, *d as f64))).collect::<Vec<_>>().join(" "));
    }
    let (k1, k3) = (kf(1.5, 1.0), kf(1.5, 3.0));
    println!("by hand at 1.5 m: k = {:.4}, {:.4}, {:.4}; (a1 + a2) x {:.4} = {:.4}, a3 x {:.4} = {:.4}", k1, k1, k3, k1, fq(alpha[0] + alpha[1]) * k1, k3, fq(alpha[2]) * k3);
    println!("answer: 1.5 m reads {:.4} deg C, 2.5 m {:.4}, surface 0 m {:.4}", deepf + fx(1.5), deepf + fx(2.5), deepf + fx(0.0));
    let big = (0..801).map(|i| fx(i as f64 / 100.0).abs()).fold(0.0, f64::max);
    println!("largest |f| on 0 to 8 m: {:.4} <= |f| sqrt(k(x,x)) = {:.4}", big, fq(norm2).sqrt());
    // ---- representer: a direction off the span only adds cost ----
    let kz: Vec<Q> = depth.iter().map(|&d| kq(0, d)).collect();
    let cz = solve(&k, &kz);
    let g_at: Vec<Q> = (0..3).map(|i| kz[i] - dot(&k[i], &cz)).collect();
    let g2 = z(1) - dot(&kz, &cz);
    let k4: Vec<Vec<Q>> = (0..4).map(|a| (0..4).map(|b| kq(a, b)).collect()).collect();     // centres 0, 1, 2, 3 m
    let coef: Vec<Q> = [z(1)].into_iter().chain(alpha.iter().zip(&cz).map(|(a, c)| *a - *c)).collect();
    let vals: Vec<Q> = (0..3).map(|i| dot(&k4[i + 1], &coef)).collect();
    let jg = y.iter().zip(&vals).fold(z(0), |s, (a, b)| s + (*a - *b) * (*a - *b)) + lam * dot(&coef, &mv(&k4, &coef));
    println!("g = k_0 minus its projection: g at 1, 2, 3 m = {}; |g|^2 = {} = {}/{}", vec(&g_at), num(g2), g2.0, g2.1);
    println!("J(f + g) = {} = J* + lambda |g|^2 = {}", num(jg), num(jstar + lam * g2));
    let cost = |a: &[Q]| { let r: Vec<Q> = y.iter().zip(&mv(&k, a)).map(|(u, v)| *u - *v).collect(); dot(&r, &r) + lam * dot(a, &mv(&k, a)) };
    let mut nudge = cost(&[z(1000), z(0), z(0)]);
    for s in [-1, 1] { for j in 0..3 {
        let a: Vec<Q> = (0..3).map(|i| if i == j { alpha[i] + q(s, 100) } else { alpha[i] }).collect();
        if fq(cost(&a)) < fq(nudge) { nudge = cost(&a) }
    } }
    println!("six nudges of one alpha by 0.01: least J = {} > J*", num(nudge));
    // ---- a second road: ordinary ridge on M explicit features ----
    let yf: Vec<f64> = y.iter().map(|v| fq(*v)).collect();
    let mut gaps: Vec<f64> = Vec::new();
    println!("M features: prediction at 1.5 m (deg C), gap to the kernel answer");
    for m in [1usize, 2, 3, 4, 6, 8, 12, 16, 20] {
        let p: Vec<Vec<f64>> = depth.iter().map(|&d| phi(d as f64, m)).collect();
        let a: Vec<Vec<f64>> = (0..m).map(|r| (0..m).map(|s| (0..3).fold(0.0, |t, i| t + p[i][r] * p[i][s]) + fq(lam) * ((r == s) as i32 as f64)).collect()).collect();
        let rhs: Vec<f64> = (0..m).map(|r| (0..3).fold(0.0, |t, i| t + p[i][r] * yf[i])).collect();
        let w = solve(&a, &rhs);
        let pred = dot(&phi(1.5, m), &w);
        gaps.push((pred - fx(1.5)).abs());
        println!("  M = {:2}: {:.6}  gap {:.9}", m, deepf + pred, gaps[gaps.len() - 1]);
    }
    // ---- what breaks ----
    let pts = [1.0, 1.9, 2.8f64];
    let bx: Vec<Vec<i64>> = pts.iter().map(|a| pts.iter().map(|b| ((a - b).abs() < 1.0) as i64).collect()).collect();
    let cb = [1i64, -1, 1];
    let qbox: i64 = (0..3).map(|i| (0..3).map(|j| cb[i] * bx[i][j] * cb[j]).sum::<i64>()).sum();
    println!("mistake 1, box kernel at 1, 1.9, 2.8 m: rows {:?}; c = (1, -1, 1) gives c.K.c = {}", bx, qbox);
    println!("mistake 2, L2 tents of norm 1 and half-width w: value at the peak");
    let mut spikes: Vec<f64> = Vec::new();
    for (wd, lab) in [(1.0f64, "1"), (0.01, "0.01"), (0.0001, "0.0001")] {
        let (h, n) = ((3.0 / (2.0 * wd)).sqrt(), 20000);
        let sq = (0..n).fold(0.0, |t, i| { let x = -wd + (i as f64 + 0.5) * 2.0 * wd / n as f64; let v = h * (1.0 - x.abs() / wd); t + v * v }) * 2.0 * wd / n as f64;
        spikes.push(h / sq.sqrt());
        println!("  w = {} m: peak {:.4}, formula sqrt(3/(2w)) = {:.4}", lab, spikes[spikes.len() - 1], (3.0 / (2.0 * wd)).sqrt());
    }
    let (xs4, ys4) = ([1.0, 2.0, 2.1, 3.0], [6.0, 3.0, 4.0, 2.0]);
    let mut wild = 0.0;
    for lm in [0.0, 0.0625] {
        let (c4, _) = ridge(&xs4, &xs4, &ys4, lm);
        let p = |x: f64| c4.iter().zip(&xs4).fold(0.0, |s, (a, d)| s + a * kf(x, *d));
        println!("mistake 3, extra sensor 2.1 m at 14 deg C, lambda = {:.4}: alpha = ({}), fit at 1.5 m {:.2}, at 2.5 m {:.2}",
                 lm, c4.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(", "), deepf + p(1.5), deepf + p(2.5));
        if lm == 0.0 { wild = c4.iter().fold(0.0, |m: f64, a| m.max(a.abs())) }
    }
    let araw: Vec<f64> = solve(&kl, &temp.iter().map(|t| z(*t)).collect::<Vec<Q>>()).iter().map(|a| fq(*a)).collect();
    let fr = |x: f64| araw.iter().zip(&depth).fold(0.0, |s, (a, d)| s + a * kf(x, *d as f64));
    println!("mistake 4, deep 10 deg C not removed: fit at 1.5 m {:.2}, at 5 m {:.2} deg C", fr(1.5), fr(5.0));
    let (_, jelse) = ridge(&[0.5, 2.5, 4.5], &[1.0, 2.0, 3.0], &yf, fq(lam));
    println!("mistake 5, kernels centred at 0.5, 2.5, 4.5 m instead: J = {:.4} against J* = {:.4}", jelse, fq(jstar));

    assert!(reads == y && resid.iter().zip(&alpha).all(|(r, a)| *r == lam * *a));       // reproducing; residual = lambda alpha
    assert!(g_at.iter().all(|v| *v == z(0)) && fq(g2) > 0.0 && jg == jstar + lam * g2);    // representer, exactly
    assert!(fq(nudge) > fq(jstar) && jelse > fq(jstar) + 0.1 && big <= fq(norm2).sqrt());
    assert!(gaps[gaps.len() - 1] < 1e-9 && gaps[..7].windows(2).all(|p| p[0] > p[1]));    // features meet the kernel
    assert!(qbox == -1 && spikes.iter().zip([1.0f64, 0.01, 0.0001]).all(|(s, w)| (s - (3.0 / (2.0 * w)).sqrt()).abs() < 1e-3 * s));
    assert!(wild > 10.0 * alpha.iter().fold(0.0, |m: f64, a| m.max(fq(*a).abs())));
    println!("ALL CHECKS PASS");
}
