// Lower bounds for first-order methods: the check behind the card.  std only.
// The chain quadratic, its minimiser, the best point any gradient-span method can reach,
// and gradient descent, Nesterov, conjugate gradient and 1000 random span methods on it.
const L: f64 = 1.0;
const N: usize = 21;
const K: usize = 10;

fn grad(x: &[f64]) -> Vec<f64> {            // gradient of the chain: (L/4)(A x - e1)
    let n = x.len();
    (0..n).map(|i| L / 4.0 * (2.0 * x[i] - if i > 0 { x[i - 1] } else { 0.0 }
        - if i < n - 1 { x[i + 1] } else { 0.0 } - if i == 0 { 1.0 } else { 0.0 })).collect()
}
fn f(x: &[f64]) -> f64 {
    let n = x.len();
    let s = x[0].powi(2) + x[n - 1].powi(2) + (0..n - 1).map(|i| (x[i] - x[i + 1]).powi(2)).sum::<f64>();
    L / 8.0 * s - L / 4.0 * x[0]
}
fn solve(m: usize, d: f64, off: f64, rhs: &[f64]) -> Vec<f64> {   // elimination, tridiagonal
    let (mut c, mut r) = (vec![0.0; m], vec![0.0; m]);
    for i in 0..m {
        let piv = d - if i > 0 { off * c[i - 1] } else { 0.0 };
        c[i] = off / piv;
        r[i] = (rhs[i] - if i > 0 { off * r[i - 1] } else { 0.0 }) / piv;
    }
    for i in (0..m - 1).rev() { r[i] -= c[i] * r[i + 1]; }
    r
}
fn e1(m: usize, v: f64) -> Vec<f64> { let mut e = vec![0.0; m]; e[0] = v; e }
fn pad(v: &[f64]) -> Vec<f64> { let mut w = v.to_vec(); w.resize(N, 0.0); w }
fn nnz(x: &[f64]) -> usize { x.iter().filter(|v| v.abs() > 1e-15).count() }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(u, v)| u * v).sum() }
fn lg(v: f64) -> String { format!("{:.2}", v.log10()) }
fn sci(v: f64) -> String {                    // Python's .3e layout
    let s = format!("{:.3e}", v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn cg(steps: usize) -> Vec<f64> {            // conjugate gradient from 0, one product A p per step
    let mut x = vec![0.0; N];
    let mut r: Vec<f64> = grad(&x).iter().map(|g| -g).collect();
    let mut p = r.clone();
    for _ in 0..steps {
        let ap: Vec<f64> = grad(&p).iter().enumerate().map(|(i, g)| g + if i == 0 { L / 4.0 } else { 0.0 }).collect();
        let rr = dot(&r, &r); let a = rr / dot(&p, &ap);
        x = x.iter().zip(&p).map(|(u, v)| u + a * v).collect();
        r = r.iter().zip(&ap).map(|(u, v)| u - a * v).collect();
        let b = dot(&r, &r) / rr;
        p = r.iter().zip(&p).map(|(u, v)| u + b * v).collect();
    }
    x
}
fn runs(a: f64, b: f64, nest: bool, fs: f64, r2: f64) -> (f64, Vec<usize>) {
    let (mut x, mut xp, mut z, mut t, mut sup) = (vec![0.0; N], vec![0.0; N], vec![0.0; N], 1.0f64, vec![]);
    for _ in 0..K {
        let g = grad(if nest { &z } else { &x });
        let xn: Vec<f64>;
        if nest {
            xn = z.iter().zip(&g).map(|(u, v)| u - v / L).collect();
            let tn = (1.0 + (1.0 + 4.0 * t * t).sqrt()) / 2.0;
            z = xn.iter().zip(&x).map(|(u, v)| u + (t - 1.0) / tn * (u - v)).collect(); t = tn;
        } else {
            xn = (0..N).map(|i| x[i] - a * g[i] / L + b * (x[i] - xp[i])).collect();
        }
        xp = x; x = xn; sup.push(nnz(&x));
    }
    ((f(&x) - fs) / (L * r2), sup)
}
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn calls(bound: &dyn Fn(f64) -> f64, eps: f64) -> usize { let mut k = 1; while bound(k as f64) > eps { k += 1; } k }

fn main() {
    let xs: Vec<f64> = (1..=N).map(|i| 1.0 - i as f64 / (N + 1) as f64).collect();
    let (fs, r2) = (f(&xs), dot(&xs, &xs));
    let (nf, kf) = (N as f64, K as f64);
    let elim = solve(N, 2.0, -1.0, &e1(N, 1.0));
    assert!(elim.iter().zip(&xs).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) < 1e-12);
    assert!((fs + L / 8.0 * (1.0 - 1.0 / (nf + 1.0))).abs() < 1e-12 && (r2 - nf * (2.0 * nf + 1.0) / (6.0 * (nf + 1.0))).abs() < 1e-12);
    assert!(r2 <= (nf + 1.0) / 3.0);
    println!("chain: {} coordinates, L {:.0}, start x0 = 0, {} gradient calls", N, L, K);
    println!("minimiser x*_i = 1 - i/{}: x*_1 {:.6}, x*_{} {:.6}; f* {:.6}", N + 1, xs[0], N, xs[N - 1], fs);
    println!("start distance R^2 {:.6} (bound (n+1)/3 = {:.6}), R {:.6}", r2, (nf + 1.0) / 3.0, r2.sqrt());
    let best_cf = -L / 8.0 * (1.0 - 1.0 / (kf + 1.0));
    let xk = pad(&solve(K, 2.0, -1.0, &e1(K, 1.0)));
    let best_el = f(&xk);
    let xcg = cg(K);
    assert!((best_cf - best_el).abs() < 1e-12 && (best_cf - f(&xcg)).abs() < 1e-12 && nnz(&xcg) == K);
    let (best, floor) = ((best_cf - fs) / (L * r2), 3.0 / (32.0 * (kf + 1.0).powi(2)));
    assert!(best >= floor);
    println!("best after {} calls: closed form {:.6}; elimination {:.6}; conjugate gradient {:.6}", K, best_cf, best_el, f(&xcg));
    println!("gap after {} calls: {:.6}; per unit L R^2: best possible {:.6}; floor 3/(32*{}^2) {:.6}", K, best_cf - fs, best, K + 1, floor);
    let (gd, sgd) = runs(1.0, 0.0, false, fs, r2);
    let (ne, sne) = runs(1.0, 0.0, true, fs, r2);
    assert!(sgd == (1..=K).collect::<Vec<_>>() && sne == sgd);
    assert!(best <= ne && ne < gd && gd <= 1.0 / (2.0 * kf) && ne <= 2.0 / (kf + 1.0).powi(2));
    println!("nonzero coordinates after calls 1..{}: gd {:?}; nesterov {:?}", K, sgd, sne);
    println!("gap per unit L R^2 after {} calls: gd {:.6} (guarantee {:.6}); nesterov {:.6} (guarantee {:.6})", K, gd, 1.0 / (2.0 * kf), ne, 2.0 / (kf + 1.0).powi(2));
    let mut rng = Rng(2026);
    let mut low = f64::INFINITY;
    for _ in 0..1000 { let a = 0.2 + 1.6 * rng.next(); let b = 0.9 * rng.next(); low = low.min(runs(a, b, false, fs, r2).0); }
    assert!(low >= best);
    println!("1000 random heavy-ball methods (step 0.2..1.8, momentum 0..0.9): smallest gap {:.6}", low);
    for (eps, lab) in [(1e-4, "0.0001"), (1e-6, "0.000001")] {
        let c = [calls(&|k| 3.0 / (32.0 * (k + 1.0).powi(2)), eps), calls(&|k| 2.0 / (k + 1.0).powi(2), eps), calls(&|k| 1.0 / (2.0 * k), eps)];
        assert!(c[0] < c[1] && c[1] < c[2] && 2 * c[0] + 1 <= 2000);
        println!("calls to promise a gap <= {} L R^2: floor {}, nesterov {}, gd {}", lab, c[0], c[1], c[2]);
    }
    let ks = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0, 128.0];
    let row = |h: &dyn Fn(f64) -> f64| ks.iter().map(|&k| lg(h(k))).collect::<Vec<_>>().join(" ");
    println!("chart k {}", ks.iter().map(|k| format!("{}", k)).collect::<Vec<_>>().join(" "));
    println!("chart log10, gd guarantee       {}", row(&|k| 1.0 / (2.0 * k)));
    println!("chart log10, nesterov guarantee {}", row(&|k| 2.0 / (k + 1.0).powi(2)));
    println!("chart log10, floor              {} ; nesterov - floor {}", row(&|k| 3.0 / (32.0 * (k + 1.0).powi(2))), lg(64.0 / 3.0));
    for kap in [100.0f64, 10000.0] {             // strongly convex chain, n = 2000, mu = L/kappa
        let (mu, m) = (L / kap, 2000); let c = (L - mu) / 4.0; let q = (kap.sqrt() - 1.0) / (kap.sqrt() + 1.0);
        let xst = solve(m, 2.0 * c + mu, -c, &e1(m, c)); let rr = dot(&xst, &xst);
        let gap = c / 2.0 * (xst[0] - solve(K, 2.0 * c + mu, -c, &e1(K, c))[0]);
        let lb = mu / 2.0 * q.powi(2 * K as i32) * rr;
        assert!(gap >= lb && (xst[4] - q.powi(5)).abs() < 1e-9);
        let l10 = 10f64.ln();
        let d = [l10 / (-2.0 * q.ln()), l10 / (-(1.0 - 1.0 / kap.sqrt()).ln()), l10 / (-(1.0 - 1.0 / kap).ln())];
        println!("strongly convex chain, kappa {:.0}: x*_5 {:.6} = q^5 {:.6}; best gap after {} calls {} >= floor {}", kap, xst[4], q.powi(5), K, sci(gap), sci(lb));
        println!("  calls per tenfold cut: floor {:.2}, nesterov {:.2}, gd {:.2}", d[0], d[1], d[2]);
    }
    let (t, r, g) = (10usize, 1.0f64, 1.0f64);    // nonsmooth: b max_{i<=t} x_i + (a/2)|x|^2
    let tf = t as f64;
    let (a, b) = ((g / r) / (1.0 + tf.sqrt()), g * tf.sqrt() / (1.0 + tf.sqrt()));
    let fnn = |x: &[f64]| b * x.iter().cloned().fold(f64::NEG_INFINITY, f64::max) + a / 2.0 * dot(x, x);
    let fmin = -b * b / (2.0 * a * tf);
    let scan = (0..=500000).map(|j| { let c = -(j as f64) * 1e-6; b * c + a * tf * c * c / 2.0 }).fold(f64::INFINITY, f64::min);
    let (mut x, mut fb) = (vec![0.0; t], f64::INFINITY);
    for _ in 0..t {                              // subgradient method, step R/(G sqrt t)
        fb = fb.min(fnn(&x));
        let mx = x.iter().cloned().fold(f64::NEG_INFINITY, f64::max); let i = x.iter().position(|&v| v == mx).unwrap();
        x = x.iter().enumerate().map(|(j, v)| v - r / (g * tf.sqrt()) * (a * v + if j == i { b } else { 0.0 })).collect();
    }
    assert!((scan - fmin).abs() < 1e-9 && fb >= 0.0 && (-fmin - r * g / (2.0 * (1.0 + tf.sqrt()))).abs() < 1e-12);
    println!("nonsmooth, t {}, R 1, G 1: weights a {:.4}, b {:.4}; min {:.6} (scan {:.6}); best of {} queried points {:.6}", t, a, b, fmin, scan, t, fb);
    println!("  floor RG/(2(1+sqrt t)) {:.6}; subgradient guarantee RG/sqrt t {:.6}", -fmin, r * g / tf.sqrt());
    let j3 = |v: &[f64]| v.iter().map(|u| format!("{:.3}", u)).collect::<Vec<_>>().join(" ");
    println!("figure, x*         {}", j3(&xs));
    println!("figure, 10 calls   {}", j3(&xk));
    let x0 = vec![0.0; N];                       // one Newton step x0 - H^-1 grad f(x0), H = (L/4) A
    let xn: Vec<f64> = x0.iter().zip(&solve(N, L / 2.0, -L / 4.0, &grad(&x0))).map(|(u, v)| u - v).collect();
    let g21 = (f(&cg(N)) - fs).abs() / (L * r2); let newton = (f(&xn) - fs).abs();
    let bowl = |x: &[f64]| L / 2.0 * x.iter().zip(&xs).map(|(u, v)| (u - v).powi(2)).sum::<f64>();   // the round bowl (L/2)|x - x*|^2
    let gbowl = |x: &[f64]| -> Vec<f64> { x.iter().zip(&xs).map(|(u, v)| L * (u - v)).collect() };   // and its gradient
    let xr: Vec<f64> = x0.iter().zip(&gbowl(&x0)).map(|(u, g)| u - g / L).collect(); let round_gap = bowl(&xr);   // one step 1/L
    assert!(g21 < 1e-12 && newton < 1e-12 && round_gap < 1e-15);
    println!("breaks: {} calls on {} coordinates: cg gap {:.6}, below the floor {:.6}", N, N, g21, 3.0 / (32.0 * (nf + 1.0).powi(2)));
    println!("breaks: one Newton step (a Hessian solve, outside the span): gap {:.6}", newton);
    println!("breaks: round bowl (L/2)|x - x*|^2: gd lands on x* in 1 call, gap {:.6}", round_gap);
    for k in [20usize, 40] {
        let rk: f64 = (1..2 * k + 2).map(|i| (1.0 - i as f64 / (2 * k + 2) as f64).powi(2)).sum();
        println!("try: k {}, chain of {}: best possible {:.6}, floor {:.6}", k, 2 * k + 1, 1.0 / (16.0 * (k + 1) as f64 * rk), 3.0 / (32.0 * ((k + 1) as f64).powi(2)));
    }
    println!("ALL CHECKS PASS");
}
