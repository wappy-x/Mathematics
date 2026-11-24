// Deblurring a 64-channel spectrum. Roads: singular values by a cosine sum, by aliasing and by
// Jacobi on A; Tikhonov by filter factors against Cholesky on (A^T A + lam^2 I) x = A^T b.
use std::f64::consts::PI;
const N: usize = 64;
type V = Vec<f64>;
fn sm(v: impl Iterator<Item = f64>) -> f64 { let mut t = 0.0; for a in v { t += a; } t }
fn e(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn nrm(v: &[f64]) -> f64 { sm(v.iter().map(|t| t * t)).sqrt() }
fn dot(u: &[f64], v: &[f64]) -> f64 { sm(u.iter().zip(v).map(|(p, q)| p * q)) }
fn sub(u: &[f64], v: &[f64]) -> V { u.iter().zip(v).map(|(p, q)| p - q).collect() }
struct P { a: Vec<V>, xt: V, sig: V, u: Vec<V> }
impl P {
    fn mv(&self, v: &[f64]) -> V { (0..N).map(|i| sm((0..N).map(|j| self.a[i][j] * v[j]))).collect() }
    fn err(&self, x: &[f64]) -> f64 { nrm(&sub(x, &self.xt)) / nrm(&self.xt) }
    fn tik(&self, lam: f64, cc: &[f64]) -> (V, f64, V) {
        let f: V = self.sig.iter().map(|sg| sg * sg / (sg * sg + lam * lam)).collect();
        let x = (0..N).map(|j| sm((0..N).map(|i| f[i] * cc[i] / self.sig[i] * self.u[i][j]))).collect();
        let r = sm((0..N).map(|i| ((1.0 - f[i]) * cc[i]) * ((1.0 - f[i]) * cc[i]))).sqrt();
        (x, r, f)
    }
    fn dp(&self, target: f64, c: &[f64]) -> f64 {
        let (mut lo, mut hi) = (-10.0f64, 0.0f64);
        for _ in 0..60 {
            let mid = (lo + hi) / 2.0;
            if self.tik(10f64.powf(mid), c).1 < target { lo = mid } else { hi = mid }
        }
        10f64.powf(lo)
    }
}
fn main() {
    let (n, s, dl) = (N, 2.0f64, 1e-3f64);
    let g0: V = (0..n).map(|j| { let m = j.min(n - j) as f64; (-(m * m) / (2.0 * s * s)).exp() }).collect();
    let gs = sm(g0.iter().cloned());
    let g: V = g0.iter().map(|v| v / gs).collect();
    let a: Vec<V> = (0..n).map(|i| (0..n).map(|j| g[(i + n - j) % n]).collect()).collect();
    let gauss = |j: usize, m: f64| { let d = j as f64 - m; (-(d * d) / 8.0).exp() };
    let xt: V = (0..n).map(|j| gauss(j, 26.0) + 0.6 * gauss(j, 34.0)).collect();
    let mut st: u64 = 0x2026;
    let mut rnd = || { // SplitMix64, seed 0x2026, uniform on [0, 1)
        st = st.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (st ^ (st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    };
    let noise: V = (0..n).map(|_| dl * (sm((0..12).map(|_| rnd())) - 6.0)).collect();
    let (mut kk, mut u): (Vec<usize>, Vec<V>) = (vec![], vec![]);
    for k in 0..=n / 2 {
        let fs: Vec<fn(f64) -> f64> = if k > 0 && k < n / 2 { vec![f64::cos, f64::sin] } else { vec![f64::cos] };
        for f in fs {
            let w: V = (0..n).map(|j| f(2.0 * PI * k as f64 * j as f64 / n as f64)).collect();
            let l = nrm(&w);
            kk.push(k); u.push(w.iter().map(|t| t / l).collect());
        }
    }
    let sig: V = kk.iter().map(|&k| sm((0..n).map(|j| g[j] * (2.0 * PI * k as f64 * j as f64 / n as f64).cos()))).collect();
    let pr = P { a: a.clone(), xt: xt.clone(), sig: sig.clone(), u: u.clone() };
    let b: V = pr.mv(&xt).iter().zip(&noise).map(|(p, q)| p + q).collect();
    let (c, cn): (V, V) = (u.iter().map(|w| dot(w, &b)).collect(), u.iter().map(|w| dot(w, &noise)).collect());
    let ali = 2.0 * (-PI * PI * s * s / 2.0).exp();
    println!("sigma_max {:.6}  sigma_min {}  kappa {}", sig[0], e(sig[n - 1], 4), e(sig[0] / sig[n - 1], 4));
    println!("aliasing estimate 2exp(-pi^2 s^2/2) {}", e(ali, 4));
    assert!((sig[n - 1] - ali).abs() / ali < 1e-6);
    let mut bm = a.clone(); // road 2: cyclic Jacobi rotations until A is diagonal
    for _ in 0..12 {
        for p in 0..n - 1 {
            for q in p + 1..n {
                if bm[p][q] == 0.0 { continue; }
                let th = (bm[q][q] - bm[p][p]) / (2.0 * bm[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let cs = 1.0 / (t * t + 1.0).sqrt(); let sn = t * cs;
                for r in 0..n { let (x, y) = (bm[r][p], bm[r][q]); bm[r][p] = cs * x - sn * y; bm[r][q] = sn * x + cs * y; }
                for r in 0..n { let (x, y) = (bm[p][r], bm[q][r]); bm[p][r] = cs * x - sn * y; bm[q][r] = sn * x + cs * y; }
            }
        }
    }
    let mut ev: V = (0..n).map(|i| bm[i][i]).collect(); ev.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let mut ss = sig.clone(); ss.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let gap = ss.iter().zip(&ev).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max);
    println!("jacobi, 12 sweeps: largest |closed form - jacobi| {}, smallest {}", e(gap, 1), e(ev[0], 4));
    assert!(gap < 1e-13);
    let idx = |k: usize| kk.iter().position(|&q| q == k).unwrap();
    let pc: V = (0..=32).map(|k| (sm((0..n).filter(|&i| kk[i] == k).map(|i| c[i] * c[i])) / kk.iter().filter(|&&q| q == k).count() as f64).sqrt()).collect(); // rms share of each cos-sin pair
    println!("picard: k  sigma_k  |cos share|  |sin share|  rms share  rms/sigma");
    for k in [0, 4, 8, 12, 16, 20, 24, 28, 32] {
        let i = idx(k);
        println!("  {:2}  {}  {}  {}  {}  {}", k, e(sig[i], 2), e(c[i].abs(), 2), if k > 0 && k < 32 { e(c[i + 1].abs(), 2) } else { "-".to_string() }, e(pc[k], 2), e(pc[k] / sig[i], 2));
    }
    let ca: V = kk.iter().map(|&k| pc[k]).collect();
    for (name, v) in [("log10 sigma", &sig), ("log10 rms share", &ca)] {
        let row: Vec<String> = (0..=32).step_by(2).map(|k| format!("{:.2}", v[idx(k)].log10())).collect();
        println!("chart {}: {}", name, row.join(" "));
    }
    println!("chart noise per coefficient: log10 {} = {:.2}", e(dl, 0), dl.log10());
    let (xn, _, _) = pr.tik(0.0, &c);
    println!("|x_true| {:.4}  |noise| {:.5}  |A x - b| of plain solve {}", nrm(&xt), nrm(&noise), e(nrm(&sub(&pr.mv(&xn), &b)), 1));
    let en = nrm(&sub(&xn, &xt));
    println!("plain solve: error {}  bound |noise|/sigma_min {}  bound/true {:.2}", e(en, 4), e(nrm(&noise) / sig[n - 1], 4), nrm(&noise) / sig[n - 1] / en);
    let target = (n as f64).sqrt() * dl;
    let lam = pr.dp(target, &c);
    let (xd, rd, fd) = pr.tik(lam, &c);
    println!("discrepancy target sqrt(64) x 1e-3 = {:.4}  lambda_DP {}", target, e(lam, 4));
    let rdm = nrm(&sub(&pr.mv(&xd), &b));
    println!("  residual by formula {:.6}  by A x - b {:.6}  rel error {:.4}", rd, rdm, pr.err(&xd));
    assert!((rd - target).abs() < 1e-9 && (rdm - rd).abs() < 1e-12);
    let xe = pr.tik(lam, &cn).0;
    println!("  noise gain {:.3}  bound 1/(2 lambda) {:.3}  bound/true {:.2}", nrm(&xe) / nrm(&noise), 1.0 / (2.0 * lam), nrm(&noise) / (2.0 * lam * nrm(&xe)));
    assert!(nrm(&xe) / nrm(&noise) <= 1.0 / (2.0 * lam));
    for m in [10.0f64, 1.0, 0.1] { println!("filter factor at sigma = {} lambda: {:.4}", m, m * m / (m * m + 1.0)); }
    let kmax = kk.iter().zip(&fd).filter(|(_, &f)| f > 0.5).map(|(&k, _)| k).max().unwrap();
    let fk: Vec<String> = [8, 12, 16].iter().map(|&k| format!("{:.4}", fd[idx(k)])).collect();
    println!("factor > 0.5 for {} of {}, frequencies 0..{}; sigma_12 {:.6}; factor at k = 8, 12, 16: {}", fd.iter().filter(|&&f| f > 0.5).count(), n, kmax, sig[idx(12)], fk.join(" "));
    for j in [26, 30, 34] { println!("channel {}: true {:.4}  blurred {:.4}  Tikhonov {:.4}", j, xt[j], b[j], xd[j]); }
    let nm: Vec<V> = (0..n).map(|i| (0..n).map(|j| sm((0..n).map(|r| a[r][i] * a[r][j])) + if i == j { lam * lam } else { 0.0 }).collect()).collect();
    let mut l = vec![vec![0.0; n]; n]; // road 3: Cholesky of A^T A + lam^2 I
    for i in 0..n {
        for j in 0..=i {
            let t = nm[i][j] - sm((0..j).map(|q| l[i][q] * l[j][q]));
            l[i][j] = if i == j { t.sqrt() } else { t / l[j][j] };
        }
    }
    let (mut y, mut xc) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n { y[i] = (sm((0..n).map(|r| a[r][i] * b[r])) - sm((0..i).map(|q| l[i][q] * y[q]))) / l[i][i]; }
    for i in (0..n).rev() { xc[i] = (y[i] - sm((i + 1..n).map(|q| l[q][i] * xc[q]))) / l[i][i]; }
    let dif = nrm(&sub(&xc, &xd)) / nrm(&xd);
    println!("cholesky against filter formula: relative difference {}", e(dif, 1));
    assert!(dif < 1e-10);
    let (mut kc, mut rt, mut keep) = (0, 0.0, vec![]);
    for k in 0..=32 { // TSVD: keep frequencies 0..kc, smallest kc meeting the target
        kc = k;
        keep = kk.iter().map(|&q| q <= k).collect::<Vec<bool>>();
        rt = sm((0..n).filter(|&i| !keep[i]).map(|i| c[i] * c[i])).sqrt();
        if rt <= target { break; }
    }
    let xk: V = (0..n).map(|j| sm((0..n).filter(|&i| keep[i]).map(|i| c[i] / sig[i] * u[i][j]))).collect();
    let nk = keep.iter().filter(|&&q| q).count();
    println!("TSVD by discrepancy: frequencies 0..{}, {} components, residual {:.5} (A x - b {:.5}), rel error {:.4}", kc, nk, rt, nrm(&sub(&pr.mv(&xk), &b)), pr.err(&xk));
    let grid: V = (0..121).map(|i| -6.0 + 0.05 * i as f64).collect(); // L-curve and GCV
    let (mut rho, mut eta, mut gcv, mut ers) = (vec![], vec![], vec![], vec![]);
    for &ex in &grid {
        let (x, r, f) = pr.tik(10f64.powf(ex), &c);
        rho.push(r.log10()); eta.push(nrm(&x).log10());
        let dn = n as f64 - sm(f.iter().cloned());
        gcv.push(r * r / (dn * dn)); ers.push(pr.err(&x));
    }
    let mut cur = vec![-1e300; 121];
    for i in 1..120 {
        let (r1, e1) = ((rho[i + 1] - rho[i - 1]) / 0.1, (eta[i + 1] - eta[i - 1]) / 0.1);
        let (r2, e2) = ((rho[i + 1] - 2.0 * rho[i] + rho[i - 1]) / 0.0025, (eta[i + 1] - 2.0 * eta[i] + eta[i - 1]) / 0.0025);
        cur[i] = (r1 * e2 - r2 * e1) / (r1 * r1 + e1 * e1).powf(1.5);
    }
    let arg = |v: &V, big: bool| { let mut b = 0; for i in 0..v.len() { if (big && v[i] > v[b]) || (!big && v[i] < v[b]) { b = i; } } b };
    let pick = [("L-curve corner", arg(&cur, true)), ("GCV minimum", arg(&gcv, false)), ("best possible, needs x_true", arg(&ers, false))];
    for (name, i) in pick {
        println!("{}: lambda {}  residual {:.5}  rel error {:.4}", name, e(10f64.powf(grid[i]), 2), 10f64.powf(rho[i]), ers[i]);
    }
    assert!(ers[pick[1].1] < 2.0 * ers[pick[2].1] && 2.0 * ers[pick[2].1] < ers[pick[0].1] && pr.err(&xd) < 1.1 * ers[pick[2].1]);
    for (name, v) in [("lambda", &grid), ("residual", &rho), ("|x|", &eta)] {
        let row: Vec<String> = (0..121).step_by(10).map(|i| format!("{:.*}", if name == "lambda" { 1 } else { 2 }, v[i])).collect();
        println!("chart log10 {}: {}", name, row.join(" "));
    }
    for lv in [1e-6f64, lam.sqrt()] {
        let x = pr.tik(lv, &c).0;
        println!("what breaks: lambda {}  rel error {:.4}  height at 26 {:.4}", e(lv, 2), pr.err(&x), x[26]);
    }
    let l1 = pr.dp(dl, &c);
    println!("what breaks: target 1e-3, no sqrt(64): lambda {}  rel error {:.4}", e(l1, 2), pr.err(&pr.tik(l1, &c).0));
    println!("cost per lambda: cholesky n^3/3 + 2n^2 = {} flops; filter route 2n^2 + 4n = {}", n * n * n / 3 + 2 * n * n, 2 * n * n + 4 * n);
    println!("ALL CHECKS PASS");
}
