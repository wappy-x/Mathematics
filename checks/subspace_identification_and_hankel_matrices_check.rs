// Subspace identification: the Hankel matrix's rank is the model's order.
// std only. Radiator panel: h_k = 0.8^k + 0.5^k degC per valve-minute.
type Mat = Vec<Vec<f64>>;
struct Rng(u64);
impl Rng {
    fn bits(&mut self) -> u64 { // SplitMix64 random bits, seed 2026
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.bits() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn gauss(&mut self) -> f64 { // Box-Muller
        let r = (-2.0 * self.unif().ln()).sqrt();
        r * (2.0 * std::f64::consts::PI * self.unif()).cos()
    }
}
fn jacobi(s: &Mat) -> (Vec<f64>, Mat) { // eigenvalues and eigenvectors of a symmetric matrix
    let (n, mut a) = (s.len(), s.clone());
    let mut v: Mat = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..60 {
        for p in 0..n {
            for q in p + 1..n {
                if a[p][q].abs() < 1e-300 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let sn = t * c;
                for k in 0..n {
                    let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - sn * y; a[k][q] = sn * x + c * y;
                    let (x, y) = (v[k][p], v[k][q]); v[k][p] = c * x - sn * y; v[k][q] = sn * x + c * y;
                }
                for k in 0..n {
                    let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - sn * y; a[q][k] = sn * x + c * y;
                }
            }
        }
    }
    ((0..n).map(|i| a[i][i]).collect(), v)
}
fn svd_sym(s: &Mat) -> (Vec<f64>, Mat, Mat) { // symmetric: singular values = |eigenvalues|
    let (ev, v) = jacobi(s);
    let n = s.len();
    let mut idx: Vec<usize> = (0..n).collect();
    idx.sort_by(|&i, &j| (-ev[i].abs()).partial_cmp(&(-ev[j].abs())).unwrap());
    let u: Mat = (0..n).map(|r| idx.iter().map(|&i| v[r][i]).collect()).collect();
    let w: Mat = (0..n).map(|r| idx.iter().map(|&i| v[r][i] * if ev[i] >= 0.0 { 1.0 } else { -1.0 }).collect()).collect();
    (idx.iter().map(|&i| ev[i].abs()).collect(), u, w)
}
fn hankel(h: &[f64], shift: usize) -> Mat { (0..4).map(|i| (0..4).map(|j| h[i + j + 1 + shift]).collect()).collect() }
fn era(h: &[f64], n: usize, shift: usize) -> (Mat, Vec<f64>, Vec<f64>) { // Ho-Kalman / ERA
    let (sig, u, w) = svd_sym(&hankel(h, 0));
    let h1 = hankel(h, shift);
    let a: Mat = (0..n).map(|a| (0..n).map(|b| {
        let mut s = 0.0;
        for r in 0..4 { for c in 0..4 { s += u[r][a] * h1[r][c] * w[c][b]; } }
        s / (sig[a] * sig[b]).sqrt() }).collect()).collect();
    (a, (0..n).map(|a| sig[a].sqrt() * w[0][a]).collect(), (0..n).map(|a| sig[a].sqrt() * u[0][a]).collect())
}
fn roots2(m: &Mat) -> (f64, f64) { // eigenvalues of a 2x2 matrix (real case), larger first
    let tr = m[0][0] + m[1][1];
    let d = (tr * tr / 4.0 - (m[0][0] * m[1][1] - m[0][1] * m[1][0])).sqrt();
    (tr / 2.0 + d, tr / 2.0 - d)
}
fn markov(a: &Mat, b: &[f64], c: &[f64], k: usize) -> f64 { // h_k = C A^(k-1) B
    let mut x = b.to_vec();
    for _ in 0..k - 1 { x = (0..x.len()).map(|i| { let mut s = 0.0; for j in 0..x.len() { s += a[i][j] * x[j]; } s }).collect(); }
    let mut s = 0.0; for i in 0..x.len() { s += c[i] * x[i]; } s
}
fn tau(p: f64) -> f64 { -1.0 / p.ln() } // time constant in minutes, one sample = 1 min
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let mut rng = Rng(2026);
    let mut h = vec![0.0; 13];
    for k in 1..13 { h[k] = 0.8f64.powf(k as f64) + 0.5f64.powf(k as f64); }
    let h0 = hankel(&h, 0);
    println!("Hankel H0 from h_1..h_7 (degC per valve-minute):");
    for r in &h0 { println!("  {}", row(r)); }
    let (sig, _, _) = svd_sym(&h0);
    println!("singular values, clean: {}  2x2 minor h1*h3 - h2^2 = {:.6}", row(&sig), h[1] * h[3] - h[2] * h[2]);
    assert!(sig[1] > 1e-2 && sig[2] < 1e-12);
    let mut m: Vec<Vec<i128>> = (0..4).map(|i| (0..4).map(|j| 8i128.pow(i + j + 1) + 5i128.pow(i + j + 1)).collect()).collect();
    let (mut rank, mut prev) = (0, 1i128);
    for k in 0..4 { // Bareiss elimination on 10^(i+j-1) h, exact integers
        let piv = match (k..4).find(|&r| m[r][k] != 0) { Some(p) => p, None => break };
        m.swap(k, piv); rank += 1;
        for i in k + 1..4 {
            for j in k + 1..4 { m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev; }
            m[i][k] = 0;
        }
        prev = m[k][k];
    }
    println!("exact integer rank of [8^(i+j-1) + 5^(i+j-1)]: {}", rank);
    assert_eq!(rank, 2);
    let (at, bt, ct) = (vec![vec![0.8f64, 0.0], vec![0.0, 0.5]], vec![0.8, 0.5], vec![1.0, 1.0]);
    let obs: Mat = (0..4).map(|k| (0..2).map(|a| ct[a] * at[a][a].powf(k as f64)).collect()).collect();
    let con: Mat = (0..2).map(|a| (0..4).map(|k| at[a][a].powf(k as f64) * bt[a]).collect()).collect();
    for i in 0..4 { for j in 0..4 { assert!((obs[i][0] * con[0][j] + obs[i][1] * con[1][j] - h0[i][j]).abs() < 1e-12); } }
    let small: Mat = (0..2).map(|a| (0..2).map(|b| { let mut s = 0.0; for k in 0..4 { s += con[a][k] * obs[k][b]; } s }).collect()).collect();
    let s2 = roots2(&small);
    println!("singular values from the 2x2 product Con*Obs: {}", row(&[s2.0, s2.1]));
    assert!((s2.0 - sig[0]).abs() < 1e-9 && (s2.1 - sig[1]).abs() < 1e-9);
    let (a, b, c) = era(&h, 2, 1);
    let p = roots2(&a);
    println!("ERA order 2: A = {} / {}  B = {}  C = {}", row(&a[0]), row(&a[1]), row(&b), row(&c));
    println!("ERA poles: {}  trace {:.6} det {:.6}  time constants (min): {:.2} {:.2}", row(&[p.0, p.1]),
        a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0], tau(p.0), tau(p.1));
    let det = h[1] * h[3] - h[2] * h[2]; // recurrence h(k+2) = a1 h(k+1) + a0 h(k), from h_1..h_4
    let a0 = (h[3] * h[3] - h[2] * h[4]) / det;
    let a1 = (h[1] * h[4] - h[2] * h[3]) / det;
    let q = roots2(&vec![vec![a1, a0], vec![1.0, 0.0]]);
    println!("recurrence: h(k+2) = {:.6} h(k+1) - {:.6} h(k); roots {}", a1, -a0, row(&[q.0, q.1]));
    assert!((p.0 - 0.8).abs() < 1e-9 && (p.1 - 0.5).abs() < 1e-9 && (q.0 - p.0).abs() < 1e-9 && (q.1 - p.1).abs() < 1e-9);
    let pred: Vec<f64> = (9..13).map(|k| markov(&a, &b, &c, k)).collect();
    println!("model h_9..h_12: {}  true: {}", row(&pred), row(&h[9..13]));
    for i in 0..4 { assert!((pred[i] - h[9 + i]).abs() < 1e-9); }
    let mut hn = vec![0.0; 9];
    for k in 1..9 { hn[k] = h[k] + 0.005 * rng.gauss(); }
    let (sn, _, _) = svd_sym(&hankel(&hn, 0));
    println!("noisy h_1..h_8 (sd 0.005 degC): {}", row(&hn[1..]));
    println!("singular values, noisy: {}  gap sigma2/sigma3 = {:.1}", row(&sn), sn[1] / sn[2]);
    assert!(sn[1] / sn[2] > 5.0 && sn[2] / sn[3] < 5.0);
    let (an, bn, cn) = era(&hn, 2, 1);
    let pn = roots2(&an);
    println!("noisy ERA poles: {}  time constants (min): {:.2} {:.2}", row(&[pn.0, pn.1]), tau(pn.0), tau(pn.1));
    assert!((pn.0 - 0.8).abs() < 0.02 && (pn.1 - 0.5).abs() < 0.05);
    let err = (1..13).map(|k| (markov(&an, &bn, &cn, k) - h[k]).abs()).fold(0.0, f64::max);
    println!("noisy model, worst error on true h_1..h_12: {:.6} degC", err);
    println!("WHAT BREAKS");
    let (a1m, b1m, c1m) = era(&hn, 1, 1);
    let e1 = (1..13).map(|k| (markov(&a1m, &b1m, &c1m, k) - h[k]).abs()).fold(0.0, f64::max);
    println!("order 1: pole {:.6}, time constant {:.2} min, worst error {:.6} degC", a1m[0][0], tau(a1m[0][0]), e1);
    assert!(e1 > 10.0 * err);
    println!("count every non-zero singular value of the noisy H0: order {}", sn.iter().filter(|&&s| s > 1e-12).count());
    let p0 = roots2(&era(&h, 2, 0).0);
    println!("forget the shift (H0 for H1): poles {}", row(&[p0.0, p0.1]));
    assert!((p0.1 - 1.0).abs() < 1e-9);
    let mut rng = Rng(2026);
    let mut hb = vec![0.0; 9];
    for k in 1..9 { hb[k] = h[k] + 0.05 * rng.gauss(); }
    let (sb, _, _) = svd_sym(&hankel(&hb, 0));
    println!("noise sd 0.05 degC: singular values {}  gap {:.1}", row(&sb), sb[1] / sb[2]);
    assert!(sb[1] / sb[2] < 2.0);
    let nn = 1440; // subspace core from a day of valve data
    let (mut x, mut us, mut ys) = ([0.0f64, 0.0], vec![], vec![]);
    for _ in 0..nn + 4 {
        let u = if rng.bits() >> 63 == 1 { 0.5 } else { -0.5 }; // valve 50% above or below its middle
        us.push(u); ys.push(ct[0] * x[0] + ct[1] * x[1]);
        x = [at[0][0] * x[0] + bt[0] * u, at[1][1] * x[1] + bt[1] * u];
    }
    let dot = |p: &[f64], q: &[f64]| -> Mat { (0..4).map(|i| (0..4).map(|j| {
        let mut s = 0.0; for k in 0..nn { s += p[k + i] * q[k + j]; } s / nn as f64 }).collect()).collect() };
    let (yy, yu, uu) = (dot(&ys, &ys), dot(&ys, &us), dot(&us, &us));
    let mut g: Mat = (0..4).map(|i| { let mut r = uu[i].clone(); for k in 0..4 { r.push(yu[k][i]); } r }).collect();
    for k in 0..4 { // solve UU X = YU^T, Gauss-Jordan
        let pv = g[k][k];
        g[k] = g[k].iter().map(|v| v / pv).collect();
        for i in 0..4 { if i != k { let f = g[i][k]; g[i] = (0..8).map(|j| g[i][j] - f * g[k][j]).collect(); } }
    }
    let pm: Mat = (0..4).map(|i| (0..4).map(|j| { let mut s = 0.0; for k in 0..4 { s += yu[i][k] * g[k][4 + j]; } yy[i][j] - s }).collect()).collect();
    let (sp, up, _) = svd_sym(&pm);
    println!("subspace core, inputs projected out: singular values {}", row(&sp));
    let l: Mat = (0..2).map(|a| (0..2).map(|b| (0..3).map(|k| up[k][a] * up[k][b]).fold(0.0, |s, v| s + v)).collect()).collect();
    let r: Mat = (0..2).map(|a| (0..2).map(|b| (0..3).map(|k| up[k][a] * up[k + 1][b]).fold(0.0, |s, v| s + v)).collect()).collect();
    let d = l[0][0] * l[1][1] - l[0][1] * l[1][0];
    let li = vec![vec![l[1][1] / d, -l[0][1] / d], vec![-l[1][0] / d, l[0][0] / d]];
    let ps = roots2(&(0..2).map(|i| (0..2).map(|j| li[i][0] * r[0][j] + li[i][1] * r[1][j]).collect()).collect());
    println!("subspace core poles (shift of the observability block): {}", row(&[ps.0, ps.1]));
    assert!(sp[2] < 1e-9 * sp[1] && (ps.0 - 0.8).abs() < 1e-9 && (ps.1 - 0.5).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
