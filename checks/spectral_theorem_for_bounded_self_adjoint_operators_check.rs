// Spectral theorem for bounded self-adjoint operators: the check behind the card.
// Standard library only. The code holds finite rehearsals: the fade on N samples,
// the blur on a click, the blur on N samples. Integrals and the eigen solver are written out.
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;
fn close(a: f64, b: f64, tol: f64, what: &str) { assert!((a - b).abs() <= tol, "{}: {} vs {}", what, a, b); }
fn sci(x: f64) -> String {
    let mut e = x.abs().log10().floor() as i32;
    let mut m = x / 10f64.powf(e as f64);
    if m.abs() >= 9.9995 { m /= 10.0; e += 1; }
    format!("{:.3}e{:+03}", m, e)
}
// a plain loop, so the additions run in the same order as in Python
fn dot(xs: &[f64], ys: &[f64]) -> f64 {
    let mut s = 0.0;
    for (x, y) in xs.iter().zip(ys) { s += x * y; }
    s
}
// eigenvalues, and eigenvectors as the columns of q, of a symmetric matrix
fn jacobi(a0: &Mat) -> (Vec<f64>, Mat) {
    let n = a0.len();
    let mut a = a0.clone();
    let mut q: Mat = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _sweep in 0..12 {
        for p in 0..n - 1 {
            for r in p + 1..n {
                if a[p][r].abs() < 1e-300 { continue; }
                let th = (a[r][r] - a[p][p]) / (2.0 * a[p][r]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt();
                let s = t * c;
                for m in [&mut a, &mut q] {
                    for k in 0..n { let (x, y) = (m[k][p], m[k][r]); m[k][p] = c * x - s * y; m[k][r] = s * x + c * y; }
                }
                for k in 0..n { let (x, y) = (a[p][k], a[r][k]); a[p][k] = c * x - s * y; a[r][k] = s * x + c * y; }
            }
        }
    }
    ((0..n).map(|i| a[i][i]).collect(), q)
}
fn blur(n: usize) -> Mat {
    (0..n).map(|i| (0..n).map(|j| if i == j { 0.5 } else if i.abs_diff(j) == 1 { 0.25 } else { 0.0 }).collect()).collect()
}
fn mul(x: &Mat, y: &Mat) -> Mat {
    let n = x.len();
    (0..n).map(|i| (0..n).map(|j| dot(&x[i], &(0..n).map(|k| y[k][j]).collect::<Vec<_>>())).collect()).collect()
}
fn c(n: i64) -> f64 { 2.0 / PI * (if n % 2 == 0 { 1.0 } else { -1.0 }) / (1 - 4 * n * n) as f64 }
fn top(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::MIN, f64::max) }
fn main() {
    println!("fade-in M: (M u)(t) = t u(t) on a 1 s clip; steady note u = 1, energy 1");
    println!("N      <u, M u>   |M u|^2    |P u|^2 (gains in [0.5, 1])   |M u|^2 - 1/3");
    let mut len2 = 0.0f64; // |M u|^2 at N = 44100: lambda^2 against length
    for n in [10usize, 100, 1000, 44100] {
        let nf = n as f64;
        let (mut a, mut b, mut cc) = (0.0f64, 0.0f64, 0.0f64);
        for k in 0..n {
            let t = (k as f64 + 0.5) / nf; // sample k sits mid-slot; each slot holds energy 1/N
            a += t / nf;
            b += t * t / nf;
            cc += if t >= 0.5 { 1.0 / nf } else { 0.0 };
        }
        println!("{:<6} {:.6}   {:.6}   {:.6}                      {}", n, a, b, cc, sci(b - 1.0 / 3.0));
        close(b - 1.0 / 3.0, -1.0 / (12.0 * nf * nf), 1e-12, "midpoint error is -1/(12 N^2)");
        close(cc, 0.5, 1e-9, "upper half of the gains holds half the energy");
        len2 = b;
    }
    println!("no eigenvector: spike phi of width w at t = 0.5, energy 1; residual |(M - 0.5) phi|");
    for w in [0.1f64, 0.01, 0.001] {
        let ts: Vec<f64> = (0..1000).map(|k| (k as f64 + 0.5) * w / 1000.0 - w / 2.0).collect();
        let r = (dot(&ts, &ts) / 1000.0).sqrt(); // phi^2 = 1/w on the spike, slot width w/1000
        let ex = w / (2.0 * 3f64.sqrt());
        println!("w = {:<6} residual {} (closed form w/(2 sqrt3) = {})", w, sci(r), sci(ex));
        close(r / ex, 1.0, 1e-5, "spike residual");
    }
    let d = (0..1001).map(|k| (k as f64 / 1000.0 - 1.2).abs()).fold(f64::INFINITY, f64::min);
    println!("lambda = 1.2: distance to the gains [0, 1] = {:.6}, so |R(1.2, M)| = {:.6}", d, 1.0 / d);
    close(1.0 / d, 5.0, 1e-9, "resolvent norm outside the spectrum");
    let (gn, gf) = (60000usize, 60000.0f64); // midpoint grid on the frequency circle (-pi, pi)
    let xi: Vec<f64> = (0..gn).map(|j| -PI + (j as f64 + 0.5) * 2.0 * PI / gf).collect();
    let g: Vec<f64> = xi.iter().map(|x| (x / 2.0).cos() * (x / 2.0).cos()).collect(); // cos^2(xi/2)
    println!("energy by gain band   fade, steady note   blur, click (grid)   blur, click (exact)");
    for (lo, hi) in [(0.0f64, 0.25f64), (0.25, 0.5), (0.5, 0.75), (0.75, 1.0)] {
        let grid = g.iter().filter(|&&v| (lo <= v && v < hi) || (v == hi && hi == 1.0)).count() as f64;
        let exact = 2.0 / PI * (hi.sqrt().asin() - lo.sqrt().asin());
        println!("[{:.2}, {:.2})         {:.6}            {:.6}             {:.6}", lo, hi, hi - lo, grid / gf, exact);
        close(grid / gf, exact, 1e-4, "click's spectral measure is the arcsine law");
    }
    println!("blur B: (B u)_n = (u_(n-1) + 2 u_n + u_(n+1))/4 on a click; <click, B^k click>");
    println!("k    direct conv.   spectral integral   C(2k,k)/4^k");
    for k in [1i32, 2, 10] {
        let mut u = vec![1.0f64];
        for _ in 0..k {
            let p: Vec<f64> = [vec![0.0, 0.0], u.clone(), vec![0.0, 0.0]].concat();
            u = (1..p.len() - 1).map(|i| (p[i - 1] + 2.0 * p[i] + p[i + 1]) / 4.0).collect();
        }
        let mut spec = 0.0;
        for v in &g { spec += v.powf(k as f64) / gf; }
        let mut binom = 1.0f64;
        for i in 0..k { binom = binom * (2 * k - i) as f64 / (i + 1) as f64; }
        binom /= 4f64.powi(k);
        let mid = u[u.len() / 2];
        println!("{:<4} {:.6}       {:.6}            {:.6}", k, mid, spec, binom);
        close(mid, binom, 1e-12, "convolution vs binomial");
        close(spec, binom, 1e-9, "spectral integral vs binomial");
    }
    println!("half-blur sqrt(B): kernel c_n = (1/2pi) int sqrt(g) cos(n xi) dxi");
    for n in 0..4i64 {
        let xs: Vec<f64> = g.iter().map(|v| v.sqrt() / gf).collect();
        let num = dot(&xs, &xi.iter().map(|x| (n as f64 * x).cos()).collect::<Vec<_>>());
        println!("c_{} = {:.6} (closed form (2/pi)(-1)^n/(1 - 4n^2) = {:.6})", n, num, c(n));
        close(num, c(n), 1e-8, "half-blur kernel");
    }
    println!("K      (c*c)_0 - 1/2   (c*c)_1 - 1/4   (kernel cut to |n| <= K)");
    for kk in [10i64, 100, 1000] {
        let v0: Vec<f64> = (-kk..=kk).map(c).collect();
        let s0 = dot(&v0, &v0);
        let a1: Vec<f64> = (1 - kk..=kk).map(c).collect();
        let s1 = dot(&a1, &(1 - kk..=kk).map(|n| c(1 - n)).collect::<Vec<_>>());
        println!("{:<6} {}      {}", kk, sci(s0 - 0.5), sci(s1 - 0.25));
        close(s0, 0.5, 1.0 / (kk * kk * kk) as f64, "half-blur twice is the blur, centre");
        close(s1, 0.25, 1.0 / (kk * kk * kk) as f64, "half-blur twice is the blur, neighbour");
    }
    println!("blur on N samples, zero past the ends: Jacobi eigenvalues against cos^2(j pi/(2(N+1)))");
    let (mut lam, mut q, mut nn) = (vec![], vec![], 0usize);
    for n in [8usize, 16, 32] {
        (lam, q, nn) = { let (l, qq) = jacobi(&blur(n)); (l, qq, n) };
        let mut s = lam.clone();
        s.sort_by(|x, y| x.partial_cmp(y).unwrap());
        let mut ex: Vec<f64> = (1..=n).map(|j| (j as f64 * PI / (2 * n + 2) as f64).cos().powf(2.0)).collect();
        ex.sort_by(|x, y| x.partial_cmp(y).unwrap());
        close(s.iter().zip(&ex).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max), 0.0, 1e-12, "Jacobi vs closed form");
        println!("N = {:<3} top {:.6}, 1 - top {:.6}, every eigenvalue matches to 1e-12", n, top(&lam), 1.0 - top(&lam));
    }
    let f = |h: &dyn Fn(f64) -> f64| -> Mat {
        let row = |i: usize| (0..nn).map(|k| q[i][k] * h(lam[k])).collect::<Vec<_>>();
        (0..nn).map(|i| (0..nn).map(|j| dot(&row(i), &(0..nn).map(|k| q[j][k]).collect::<Vec<_>>())).collect()).collect()
    };
    let (b, r, f2) = (blur(nn), f(&|x: f64| x.sqrt()), f(&|x: f64| x * x));
    let (bb, rr) = (mul(&b, &b), mul(&r, &r));
    let mut err = 0.0f64;
    for i in 0..nn { for j in 0..nn { err = err.max((f2[i][j] - bb[i][j]).abs() + (rr[i][j] - b[i][j]).abs()); } }
    close(err, 0.0, 1e-12, "functions through the eigenvectors");
    println!("N = 32: Q L^2 Q^T = B B and (Q sqrt(L) Q^T)^2 = B to 1e-12; half-blur centre {:.6}", r[15][15]);
    println!("what breaks");
    for eps in [0.1f64, 0.01, 0.001] {
        let (n, tp, mut s) = (400000.0f64, PI - eps, 0.0f64);
        for j in 0..400000 {
            let x = (j as f64 + 0.5) * tp / n;
            s += 1.0 / (x / 2.0).cos().powf(2.0) * tp / n / PI;
        }
        let exact = 2.0 / PI / (eps / 2.0).tan();
        println!("unblur 1/lambda, cut {} from xi = pi: {:.2} (closed form (2/pi)cot(eps/2) = {:.2})", eps, s, exact);
        close(s / exact, 1.0, 1e-3, "unblur blows up");
    }
    let tj = [[0.0f64, 1.0], [0.0, 0.0]]; // the Jordan block: not symmetric
    let ttt: Mat = (0..2).map(|i| (0..2).map(|j| dot(&[tj[0][i], tj[1][i]], &[tj[0][j], tj[1][j]])).collect()).collect(); // T^T T
    let (tr, det, nj) = (tj[0][0] + tj[1][1], tj[0][0] * tj[1][1] - tj[0][1] * tj[1][0], top(&jacobi(&ttt).0).sqrt());
    println!("Jordan block [[0, 1], [0, 0]]: trace {:.1}, det {:.1}, so spectrum {{0}}, but its norm is sqrt(top of T^T T) = {:.6}", tr, det, nj);
    close(tr.abs() + det.abs(), 0.0, 0.0, "trace 0 and det 0: both eigenvalues are 0");
    close(nj, 1.0, 1e-12, "non-symmetric norm");
    let right = dot(&g, &g) / gf; // lambda^2 against the click's measure
    println!("blur's click with length on [0, 1] as its measure: {:.6}, not {:.6}", len2, right);
    close(right - len2, 0.375 - 1.0 / 3.0, 1e-9, "length is not the click's measure");
    println!("chart: cumulative spectral measure at lambda = 0, 0.1, ..., 1");
    let fade: Vec<String> = (0..11).map(|j| format!("{:.3}", j as f64 / 10.0)).collect();
    let bl: Vec<String> = (0..11).map(|j| format!("{:.3}", 2.0 / PI * (j as f64 / 10.0).sqrt().asin())).collect();
    println!("fade, steady note: {}\nblur, click:       {}", fade.join(", "), bl.join(", "));
    println!("ALL CHECKS PASS");
}
