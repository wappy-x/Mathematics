// Level, slope and curvature -- the same check as principal_components_of_the_curve_check.py.
// Std only, no crates.  Same 500 synthetic days, same seed; PCA by Jacobi and by power iteration.
// Compile: rustc --edition 2021 -O principal_components_of_the_curve_check.rs -o /tmp/pcc
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;

struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 {                                     // Box-Muller
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }

fn cov(rows: &[Vec<f64>]) -> Mat {                                  // centred, divide by n
    let (n, m) = (rows.len() as f64, rows[0].len());
    let mu: Vec<f64> = (0..m).map(|j| rows.iter().map(|r| r[j]).sum::<f64>() / n).collect();
    (0..m).map(|i| (0..m).map(|j| rows.iter().map(|r| (r[i] - mu[i]) * (r[j] - mu[j])).sum::<f64>() / n).collect()).collect()
}

fn jacobi(a0: &Mat) -> (Vec<f64>, Mat) {                           // road 1: rotate until diagonal
    let (m, mut a) = (a0.len(), a0.clone());
    let mut v: Mat = (0..m).map(|i| (0..m).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..100 {
        let mut off = 0.0;
        for i in 0..m { for j in 0..m { if i != j { off += a[i][j] * a[i][j]; } } }
        if off < 1e-24 { break; }
        for p in 0..m {
            for q in p + 1..m {
                if a[p][q].abs() < 1e-300 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let (c, s) = (1.0 / (t * t + 1.0).sqrt(), t / (t * t + 1.0).sqrt());
                for k in 0..m { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
                for k in 0..m { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
                for k in 0..m { let (x, y) = (v[k][p], v[k][q]); v[k][p] = c * x - s * y; v[k][q] = s * x + c * y; }
            }
        }
    }
    let mut idx: Vec<usize> = (0..m).collect();
    idx.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    (idx.iter().map(|&i| a[i][i]).collect(), idx.iter().map(|&i| (0..m).map(|k| v[k][i]).collect()).collect())
}

fn power(a0: &Mat, k: usize) -> (Vec<f64>, Mat) {                  // road 2: multiply, deflate, repeat
    let (m, mut a) = (a0.len(), a0.clone());
    let (mut vals, mut vecs) = (vec![], vec![]);
    for _ in 0..k {
        let mut v: Vec<f64> = (0..m).map(|i| 1.0 + 0.1 * i as f64).collect();
        for _ in 0..3000 {
            let w: Vec<f64> = (0..m).map(|i| dot(&a[i], &v)).collect();
            let nw = dot(&w, &w).sqrt();
            v = w.iter().map(|x| x / nw).collect();
        }
        let lam = (0..m).map(|i| v[i] * dot(&a[i], &v)).sum::<f64>();
        for i in 0..m { for j in 0..m { a[i][j] -= lam * v[i] * v[j]; } }
        vals.push(lam); vecs.push(v);
    }
    (vals, vecs)
}

fn orient(vecs: &[Vec<f64>]) -> Mat {                              // fix the arbitrary signs
    vecs.iter().enumerate().map(|(k, v)| {
        let test = match k { 0 => v.iter().sum::<f64>(), 1 => v[5] - v[0], _ => v[2] + v[3] - v[0] - v[5] };
        if test < 0.0 { v.iter().map(|x| -x).collect() } else { v.clone() }
    }).collect()
}

fn share3(rows: &[Vec<f64>]) -> (f64, f64) {
    let lam = jacobi(&cov(rows)).0;
    let tot: f64 = lam.iter().sum();
    ((lam[0] + lam[1] + lam[2]) / tot, lam[0] / tot)
}

fn f(v: &[f64]) -> String { v.iter().map(|x| format!("{:8.4}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let t = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0];
    let mut d = [1.0 / 1.02, 1.0 / 1.042, 0.0, 0.0, 0.0, 0.0];       // D at 0.5, 1, 2, 3, 4, 5
    for (n, s) in [(2usize, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)] {
        let annuity: f64 = (1..n).map(|j| d[j]).sum();               // D(1) .. D(n-1)
        d[n] = (1.0 - s * annuity) / (1.0 + s);
    }
    let zero: Vec<f64> = (0..6).map(|i| -d[i].ln() / t[i] * 1e4).collect();
    let mut g = Lcg(20260928);
    let slope: Vec<f64> = t.iter().map(|x| (x - 2.5) / 2.5).collect();
    let bend: Vec<f64> = t.iter().map(|x| 1.0 - 2.0 * ((x - 2.5) / 2.5f64).powi(2)).collect();
    let mut x: Mat = vec![];
    for _ in 0..500 {
        let (lv, sl, cv) = (5.0 * g.gauss(), 2.0 * g.gauss(), 1.0 * g.gauss());
        x.push((0..6).map(|i| lv + sl * slope[i] + cv * bend[i] + 1.3 * g.gauss()).collect());
    }
    let s = cov(&x);
    let (lam, u_all) = jacobi(&s);
    let u = orient(&u_all[..3]);
    let (plam, pu0) = power(&s, 3);
    let pu = orient(&pu0);
    let trace: f64 = (0..6).map(|i| s[i][i]).sum();
    let mu: Vec<f64> = (0..6).map(|j| x.iter().map(|r| r[j]).sum::<f64>() / 500.0).collect();
    let z: Mat = x.iter().map(|r| (0..6).map(|j| r[j] - mu[j]).collect()).collect();
    let resid = z.iter().map(|zz| dot(zz, zz) - u.iter().map(|uu| dot(zz, uu).powi(2)).sum::<f64>()).sum::<f64>() / 500.0;
    let sc: Mat = z.iter().map(|zz| u.iter().map(|uu| dot(zz, uu)).collect()).collect();
    let mut offcov: f64 = 0.0;
    for a in 0..3 { for b in a + 1..3 { offcov = offcov.max((sc.iter().map(|r| r[a] * r[b]).sum::<f64>() / 500.0).abs()); } }
    let mut h: Mat = vec![];                                         // hand-made flat / line / bowl
    for v0 in [vec![1.0; 6], t.to_vec(), t.iter().map(|x| x * x).collect::<Vec<f64>>()] {
        let mut v = v0;
        for uu in &h { let c = dot(&v, uu); v = v.iter().zip(uu).map(|(a, b)| a - c * b).collect(); }
        let nv = dot(&v, &v).sqrt();
        h.push(v.iter().map(|a| a / nv).collect());
    }
    let hand = h.iter().map(|hh| (0..6).map(|i| hh[i] * dot(&s[i], hh)).sum::<f64>()).sum::<f64>() / trace;
    let (mut lev, mut y): (Mat, Vec<f64>) = (vec![], zero.clone());
    for r in &x { y = y.iter().zip(r).map(|(a, b)| a + b).collect(); lev.push(y.clone()); }
    let sd: Vec<f64> = (0..6).map(|i| s[i][i].sqrt()).collect();
    let pct: Mat = x.iter().map(|r| { let mut q = r.clone(); q[5] /= 100.0; q }).collect();

    println!("tenor, years          {}", t.iter().map(|v| format!("{:8.1}", v)).collect::<Vec<_>>().join(" "));
    println!("slice E zero, %       {}", f(&zero.iter().map(|v| v / 100.0).collect::<Vec<_>>()));
    println!("sd of daily change bp {}", f(&sd));
    println!("total variance, bp^2  {:10.4}", trace);
    println!("eigenvalues, Jacobi   {}", f(&lam));
    println!("eigenvalues, power    {}", f(&plam));
    println!("share of each, %      {}", f(&lam.iter().map(|l| 100.0 * l / trace).collect::<Vec<_>>()));
    println!("cumulative share, %   {}", f(&(0..6).map(|k| 100.0 * lam[..=k].iter().sum::<f64>() / trace).collect::<Vec<_>>()));
    for (k, name) in ["level", "slope", "curvature"].iter().enumerate() {
        println!("{:<22}{}", format!("{} loading", name), f(&u[k]));
        println!("{:<22}{}", format!("{} (power road)", name), f(&pu[k]));
    }
    println!("factor sd, bp a day   {}", f(&lam[..3].iter().map(|l| l.sqrt()).collect::<Vec<_>>()));
    println!("leftover, direct bp^2 {:10.4}", resid);
    println!("leftover, l4+l5+l6    {:10.4}", lam[3] + lam[4] + lam[5]);
    println!("largest score cov     {:10.4}", offcov);
    println!("wrong: hand shapes, % {:10.4}", 100.0 * hand);
    let (lv3, lv1) = share3(&lev);
    println!("wrong: levels 1st, %  {:10.4}", 100.0 * lv1);
    println!("wrong: levels 3, %    {:10.4}", 100.0 * lv3);
    println!("wrong: 5y %, 5y load  {:10.4}", orient(&jacobi(&cov(&pct)).1[..1])[0][5]);
    let three: Mat = x.iter().map(|r| vec![r[1], r[3], r[5]]).collect();
    println!("wrong: 3 tenors, %    {:10.4}", 100.0 * share3(&three).0);
    println!("house: 3-sd shock of each factor on the slice E curve");
    let price = |zz: &[f64]| 100.0 * (-zz[5] / 1e4 * 5.0).exp();
    let mut prices = vec![format!("base={:.4}", price(&zero))];
    for (k, name) in ["level", "slope", "curvature"].iter().enumerate() {
        let mv: Vec<f64> = u[k].iter().map(|uu| 3.0 * lam[k].sqrt() * uu).collect();
        let after: Vec<f64> = zero.iter().zip(&mv).map(|(a, b)| a + b).collect();
        println!("{:<22}{}", format!("chart, {} bp", name), mv.iter().map(|m| format!("{:8.2}", m)).collect::<Vec<_>>().join(" "));
        println!("{:<22}{}", "  zero % after", f(&after.iter().map(|v| v / 100.0).collect::<Vec<_>>()));
        prices.push(format!("{}={:.4}", name, price(&after)));
    }
    println!("5y zero-coupon, $100  {}", prices.join(" "));

    let share = (lam[0] + lam[1] + lam[2]) / trace;
    assert!((0..3).all(|k| (lam[k] - plam[k]).abs() < 1e-8), "two eigen-solvers agree");
    assert!((0..3).all(|k| (0..6).all(|i| (u[k][i] - pu[k][i]).abs() < 1e-6)), "same shapes");
    assert!((lam.iter().sum::<f64>() - trace).abs() < 1e-9, "eigenvalues add up to the total variance");
    assert!((resid - (lam[3] + lam[4] + lam[5])).abs() < 1e-8, "day-by-day leftover equals the dropped eigenvalues");
    assert!(offcov < 1e-8, "factor scores are uncorrelated");
    assert!(hand < share, "no other three shapes capture more");
    assert!(share > 0.965 && share < 0.975, "about 97 percent in three factors");
    println!("ALL CHECKS PASS");
}
