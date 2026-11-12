// Principal components and dimension reduction -- the check behind the card.  std only.
// 20,000 synthetic shop orders, 12 numbers each in mixed units, made by a stated rule from three
// hidden traits (basket size, loyalty, browsing) plus noise; 15% are trade buyers.  Seed 2026.
const N: usize = 20000; const D: usize = 12;
const P_TRADE: f64 = 0.15; const SHIFT: [f64; 3] = [2.5, 1.5, 0.0];
// name, unit, base value, loadings on (size, loyalty, browsing), noise sd
const FEATS: [(&str, &str, f64, [f64; 3], f64); D] = [
    ("basket value", "GBP", 60.0, [25.0, 5.0, 4.0], 12.0), ("items", "count", 6.0, [1.8, 0.3, 0.5], 1.0),
    ("distinct products", "count", 4.0, [1.3, 0.2, 0.6], 0.8), ("parcel weight", "kg", 5.0, [1.6, 0.0, 0.2], 1.0),
    ("shipping charged", "GBP", 4.5, [1.0, -0.8, 0.0], 1.0), ("discount", "GBP", 6.0, [2.5, 2.0, 1.0], 2.5),
    ("orders past year", "count", 8.0, [0.5, 4.0, 0.0], 2.0), ("days since last", "days", 50.0, [0.0, -15.0, 0.0], 12.0),
    ("minutes on site", "min", 14.0, [2.0, -1.0, 5.0], 3.0), ("pages viewed", "count", 18.0, [3.0, -1.0, 7.0], 4.0),
    ("share on sale", "%", 25.0, [0.0, 3.0, 7.0], 6.0), ("delivery distance", "km", 30.0, [0.0, 0.0, 0.0], 12.0)];
type M = Vec<Vec<f64>>;

struct Rng { s: u64 } // SplitMix64
impl Rng {
    fn unif(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half
        let u1 = self.unif(); let u2 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
fn add<I: Iterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for x in xs { s += x; } s } // left to right
fn dot(a: &[f64], b: &[f64]) -> f64 { add(a.iter().zip(b).map(|(x, y)| x * y)) }
fn line(label: &str, vals: &[f64], w: usize, p: usize) {
    print!("{:<32}", label); for x in vals { print!("{:w$.p$}", x, w = w, p = p); } println!();
}
fn covariance(rows: &M) -> (M, Vec<f64>) { // centre each column, divide by n - 1
    let n = rows.len() as f64;
    let m: Vec<f64> = (0..D).map(|j| add(rows.iter().map(|r| r[j])) / n).collect();
    let c: M = (0..D).map(|j| rows.iter().map(|r| r[j] - m[j]).collect()).collect();
    ((0..D).map(|i| (0..D).map(|j| dot(&c[i], &c[j]) / (n - 1.0)).collect()).collect(), m)
}
fn rot(m: &mut M, p: usize, q: usize, c: f64, s: f64, cols: bool) {
    for k in 0..D {
        if cols { let (x, y) = (m[k][p], m[k][q]); m[k][p] = c * x - s * y; m[k][q] = s * x + c * y; }
        else { let (x, y) = (m[p][k], m[q][k]); m[p][k] = c * x - s * y; m[q][k] = s * x + c * y; }
    }
}
fn jacobi_eig(a0: &M) -> Vec<(f64, Vec<f64>)> { // rotate pairs until the matrix is diagonal
    let mut a = a0.clone();
    let mut v: M = (0..D).map(|i| (0..D).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..60 {
        let off = add((0..D).flat_map(|i| (0..D).map(move |j| (i, j))).filter(|(i, j)| i != j).map(|(i, j)| a[i][j] * a[i][j]));
        if off < 1e-24 { break; }
        for p in 0..D { for q in p + 1..D {
            if a[p][q] == 0.0 { continue; }
            let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            rot(&mut a, p, q, c, s, true); rot(&mut v, p, q, c, s, true); rot(&mut a, p, q, c, s, false);
        } }
    }
    let mut pairs: Vec<(f64, Vec<f64>)> = (0..D).map(|i| (a[i][i], (0..D).map(|k| v[k][i]).collect())).collect();
    let mut out = Vec::new();
    while !pairs.is_empty() { // largest eigenvalue first, by selection
        let mut b = 0; for i in 0..pairs.len() { if pairs[i].0 > pairs[b].0 { b = i; } }
        let (lam, u) = pairs.remove(b);
        let mut big = 0; for k in 0..D { if u[k].abs() > u[big].abs() { big = k; } } // sign: largest loading positive
        out.push((lam, if u[big] > 0.0 { u } else { u.iter().map(|x| -x).collect() }));
    }
    out
}
fn svd_values(cols0: &M) -> Vec<f64> { // one-sided Jacobi on the data table itself
    let mut cols = cols0.clone();
    for _ in 0..30 {
        let mut worst: f64 = 0.0;
        for p in 0..D { for q in p + 1..D {
            let (al, be, ga) = (dot(&cols[p], &cols[p]), dot(&cols[q], &cols[q]), dot(&cols[p], &cols[q]));
            worst = worst.max(ga.abs() / (al * be).sqrt());
            let ze = (be - al) / (2.0 * ga);
            let t = (if ze >= 0.0 { 1.0 } else { -1.0 }) / (ze.abs() + (ze * ze + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            for i in 0..cols[p].len() { let (a, b) = (cols[p][i], cols[q][i]); cols[p][i] = c * a - s * b; cols[q][i] = s * a + c * b; }
        } }
        if worst < 1e-13 { break; }
    }
    let mut sv: Vec<f64> = cols.iter().map(|c| dot(c, c)).collect(); // squared singular values
    let mut out = Vec::new();
    while !sv.is_empty() { let mut b = 0; for i in 0..sv.len() { if sv[i] > sv[b] { b = i; } } out.push(sv.remove(b)); }
    out
}
fn cum(ls: &[f64]) -> Vec<f64> { let tot = add(ls.iter().cloned()); (0..D).map(|k| add(ls[..k + 1].iter().cloned()) / tot * 100.0).collect() }
fn px(s1: f64) -> i64 { (160.0 + 18.0 * s1 + 0.5).floor() as i64 }
fn py(s2: f64) -> i64 { (120.0 - 18.0 * s2 + 0.5).floor() as i64 }

fn main() {
    // ---- the data: 20,000 orders ----
    let mut rng = Rng { s: 2026 }; let mut x: M = Vec::new(); let mut trade = Vec::new();
    for _ in 0..N {
        let t = if rng.unif() < P_TRADE { 1.0 } else { 0.0 };
        let h: Vec<f64> = (0..3).map(|k| rng.normal() + SHIFT[k] * t).collect();
        x.push(FEATS.iter().map(|f| f.2 + dot(&f.3, &h) + f.4 * rng.normal()).collect()); trade.push(t);
    }
    let below = add(x.iter().flat_map(|r| r.iter()).map(|&v| if v < 0.0 { 1.0 } else { 0.0 })) / (N * D) as f64 * 100.0;
    println!("orders {}, trade buyers {}, values below zero per 100: {:.2}", N, add(trade.iter().cloned()) as i64, below);
    let (c, mean) = covariance(&x); let sd: Vec<f64> = (0..D).map(|j| c[j][j].sqrt()).collect();
    let z: M = x.iter().map(|r| (0..D).map(|j| (r[j] - mean[j]) / sd[j]).collect()).collect(); // standardise every column
    let (r, _) = covariance(&z);
    let eig = jacobi_eig(&r); let lam: Vec<f64> = eig.iter().map(|e| e.0).collect(); let u: M = eig.iter().map(|e| e.1.clone()).collect();
    println!("{:<18}{:>6}{:>8}{:>8}{:>9}{:>7}{:>7}{:>7}{:>7}{:>7}", "feature", "unit", "mean", "sd", "order 1", "z", "PC1", "PC2", "PC3", "PC4");
    for (j, f) in FEATS.iter().enumerate() {
        print!("{:<18}{:>6}{:8.2}{:8.2}{:9.2}{:7.2}", f.0, f.1, mean[j], sd[j], x[0][j], z[0][j]);
        for k in 0..4 { print!("{:7.2}", u[k][j]); } println!();
    }

    // ---- road 1: eigenvalues of the correlation matrix; road 2: SVD of the table; road 3: the model's truth ----
    let sv: Vec<f64> = svd_values(&(0..D).map(|j| z.iter().map(|r| r[j]).collect()).collect()).iter().map(|s| s / (N - 1) as f64).collect();
    let p = P_TRADE * (1.0 - P_TRADE); // the model's covariance, exactly
    let sz: M = (0..3).map(|i| (0..3).map(|j| (if i == j { 1.0 } else { 0.0 }) + p * SHIFT[i] * SHIFT[j]).collect()).collect();
    let s: M = (0..D).map(|i| (0..D).map(|j| {
        let inner: Vec<f64> = (0..3).map(|k| dot(&sz[k], &FEATS[j].3)).collect();
        dot(&FEATS[i].3, &inner) + if i == j { FEATS[i].4 * FEATS[i].4 } else { 0.0 }
    }).collect()).collect();
    let corr: M = (0..D).map(|i| (0..D).map(|j| s[i][j] / (s[i][i] * s[j][j]).sqrt()).collect()).collect();
    let truth: Vec<f64> = jacobi_eig(&corr).iter().map(|e| e.0).collect();
    let (cl, ct) = (cum(&lam), cum(&truth));
    line("eigenvalues, Jacobi on R", &lam, 7, 3); line("eigenvalues, SVD of the table", &sv, 7, 3);
    line("eigenvalues, the model's truth", &truth, 7, 3); line("kept by first r, data, %", &cl, 7, 2); line("kept by first r, truth, %", &ct, 7, 2);
    let gap = (0..D).map(|k| (cl[k] - ct[k]).abs()).fold(0.0, f64::max);
    let r85 = (0..D).find(|&k| cl[k] >= 85.0).unwrap() + 1;
    println!("components needed for 85%: r = {}, keeping {:.2}%; largest gap to truth {:.2} points", r85, cl[r85 - 1], gap);
    println!("trace of R {:.4}, eigenvalue sum {:.4}", add((0..D).map(|i| r[i][i])), add(lam.iter().cloned()));

    // ---- road 4: straight from the orders: score variance and the rebuild error ----
    let scores: M = z.iter().map(|zr| (0..D).map(|k| dot(&u[k], zr)).collect()).collect();
    let var1 = add(scores.iter().map(|s| s[0] * s[0])) / (N - 1) as f64;
    let lost = add(z.iter().zip(&scores).map(|(zr, s)| add((0..D).map(|j| {
        let e = zr[j] - add((0..r85).map(|k| s[k] * u[k][j])); e * e })))) / (N - 1) as f64;
    println!("variance of the 20,000 PC1 scores {:.4}; rebuild error with r = 4 {:.4}, last eight eigenvalues {:.4}", var1, lost, add(lam[4..].iter().cloned()));
    let prods: Vec<String> = (0..D).map(|j| format!("{:.2}", u[0][j] * z[0][j])).collect();
    println!("order 1 PC1 products {} -> score {:.4}", prods.join(" "), scores[0][0]);
    line("order 1 scores PC1 to PC4", &scores[0][..4], 8, 4);
    let rebuilt: Vec<f64> = (0..D).map(|j| mean[j] + sd[j] * add((0..4).map(|k| scores[0][k] * u[k][j]))).collect();
    line("order 1 rebuilt from 4, raw units", &rebuilt, 7, 2);

    // ---- what breaks ----
    let raw = jacobi_eig(&c); let craw = cum(&raw.iter().map(|e| e.0).collect::<Vec<f64>>());
    println!("wrong, raw units: PC1 keeps {:.2}%, loading on basket value {:.2}, on items {:.2}; two keep {:.2}%; PC3 loading on distance {:.2}",
             craw[0], raw[0].1[0], raw[0].1[1], craw[1], raw[2].1[11]);
    println!("wrong, order 1 not standardised: PC1 score {:.2}, right {:.2}", dot(&u[0], &x[0]), scores[0][0]);
    println!("wrong, the 2-D plot read as the 85% summary: it keeps {:.2}%", cl[1]);
    println!("pure-noise column (distance): PC4 eigenvalue {:.4}, loading {:.4}, share {:.2}%", lam[3], u[3][11], lam[3] / D as f64 * 100.0);
    // ---- the figure: every 400th order, PC1 across and PC2 up, 18 units per score unit on both axes ----
    for (g, name) in [(0.0, "households"), (1.0, "trade buyers")] {
        let k = add(trade.iter().map(|&t| if t == g { 1.0 } else { 0.0 }));
        let cc: Vec<f64> = (0..2).map(|i| add(scores.iter().zip(&trade).filter(|(_, &t)| t == g).map(|(s, _)| s[i])) / k).collect();
        println!("figure, centre of the {:<13} x {} y {}   (scores PC1 {:5.2}, PC2 {:5.2})", name, px(cc[0]), py(cc[1]), cc[0], cc[1]);
    }
    let pts: Vec<(i64, i64, i64)> = (0..N).step_by(400).map(|i| (px(scores[i][0]), py(scores[i][1]), trade[i] as i64)).collect();
    for k in (0..50).step_by(10) {
        let parts: Vec<String> = pts[k..k + 10].iter().map(|(a, b, c)| format!("{},{},{}", a, b, c)).collect();
        println!("figure, x,y,trade {}", parts.join(" "));
    }

    assert!(r85 == 4 && (cl[3] - 85.82).abs() < 0.01, "four components clear 85 percent");
    assert!(lam.iter().zip(&sv).all(|(a, b)| (a - b).abs() < 1e-9), "SVD of the table meets the covariance road");
    assert!(gap < 0.5, "sample shares within half a point of the model");
    assert!((var1 - lam[0]).abs() < 1e-9, "variance along PC1 is its eigenvalue");
    assert!((lost - add(lam[4..].iter().cloned())).abs() < 1e-9, "rebuild error is the dropped eigenvalues");
    assert!((add(lam.iter().cloned()) - D as f64).abs() < 1e-9, "eigenvalues share out the 12 units of variance");
    assert!(pts.iter().all(|&(a, b, _)| (30..=350).contains(&a) && (26..=214).contains(&b)), "every plotted order inside the frame");
    println!("ALL CHECKS PASS");
}
