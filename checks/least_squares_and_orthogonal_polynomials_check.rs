// Fitting instead of passing through: a cubic trend through 30 years of monthly rainfall
// (illustrative data from a seeded generator), fitted in several bases. Standard library only.
// Roads: exact whole numbers in the discrete orthogonal basis; Legendre columns with Cholesky;
// the three-term recurrence; kappa by one-sided Jacobi and from a formula; a fit by those rotations.
const M: usize = 360; const U: f64 = 1.0 / 9007199254740992.0; // months, Jan 1995 to Dec 2024; unit roundoff
const SEASON: [f64; 12] = [22.0, 4.0, 4.0, -10.0, -10.0, -15.0, -20.0, -10.0, -5.0, 14.0, 22.0, 4.0];
type Cols = Vec<Vec<f64>>;
struct Term { c: f64, nk: f64, dp: f64, rss: f64, p: Vec<f64> }

fn fe(x: f64, p: usize) -> String { // Python-style e-notation: 1.23e-08
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap(); let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn splitmix(s: &mut u64) -> f64 { // SplitMix64: uniform numbers in [0, 1)
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}
fn dot(p: &[f64], q: &[f64]) -> f64 { // plain loop: same rounding in Python and Rust
    let mut t = 0.0; for (a, b) in p.iter().zip(q) { t += a * b; } t
}
fn exact(tenths: &[i128]) -> ([[i128; 4]; 4], Vec<f64>, Vec<f64>) { // road 1: whole numbers
    let m = M as i128;
    let t: Vec<i128> = (1..=m).map(|j| 2 * j - m - 1).collect(); // t = 2j - 361 = 360 x
    let q: Vec<Vec<i128>> = vec![vec![1; M], t.clone(), t.iter().map(|v| 3 * v * v - (m * m - 1)).collect(),
        t.iter().map(|v| 5 * v * v * v - (3 * m * m - 7) * v).collect()];
    let mut g = [[0i128; 4]; 4]; for i in 0..4 { for k in 0..4 { g[i][k] = q[i].iter().zip(&q[k]).map(|(a, b)| a * b).sum(); } }
    let c: Vec<f64> = (0..4).map(|k| q[k].iter().zip(tenths).map(|(a, b)| a * b).sum::<i128>() as f64
        / (10 * g[k][k]) as f64).collect();
    let fit = (0..M).map(|j| c[0] + c[1] * q[1][j] as f64 + c[2] * q[2][j] as f64 + c[3] * q[3][j] as f64).collect();
    let d = vec![c[0] + c[2], (m as f64) * c[1] + (7 * m) as f64 * c[3], (2 * m * m) as f64 * c[2], (2 * m * m * m) as f64 * c[3]];
    (g, d, fit)
}
fn powers(xs: &[f64], n: usize) -> Cols { // columns 1, x, x^2, .. x^n
    let mut cols = vec![vec![1.0; M]];
    for k in 0..n { let next = cols[k].iter().zip(xs).map(|(a, x)| a * x).collect(); cols.push(next); } cols
}
fn legendre(xs: &[f64], n: usize) -> Cols { // columns P_0 .. P_n by Bonnet's recurrence
    let mut cols = vec![vec![1.0; M], xs.to_vec()];
    for k in 1..n {
        let (kf, a, b) = (k as f64, &cols[k], &cols[k - 1]); let next = (0..M).map(|j| ((2.0 * kf + 1.0) * xs[j] * a[j] - kf * b[j]) / (kf + 1.0)).collect();
        cols.push(next);
    }
    cols.truncate(n + 1); cols
}
fn cholesky_fit(cols: &Cols, y: &[f64]) -> Option<(Vec<f64>, Vec<f64>)> { // road 2: normal equations
    let n = cols.len(); let mut r = vec![vec![0.0; n]; n];
    for j in 0..n {
        let mut d = dot(&cols[j], &cols[j]); for k in 0..j { d -= r[k][j] * r[k][j]; }
        if d <= 0.0 { return None; } // rounding made G look singular
        r[j][j] = d.sqrt();
        for i in j + 1..n {
            let mut e = dot(&cols[j], &cols[i]); for k in 0..j { e -= r[k][j] * r[k][i]; } r[j][i] = e / r[j][j];
        }
    }
    let (mut z, mut c) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let mut e = dot(&cols[i], y); for k in 0..i { e -= r[k][i] * z[k]; } z[i] = e / r[i][i];
    }
    for i in (0..n).rev() {
        let mut e = z[i]; for k in i + 1..n { e -= r[i][k] * c[k]; } c[i] = e / r[i][i];
    }
    let f = (0..M).map(|j| dot(&cols.iter().map(|col| col[j]).collect::<Vec<f64>>(), &c)).collect();
    Some((c, f))
}
fn recurrence(xs: &[f64], y: &[f64], n: usize) -> (Vec<f64>, Vec<Term>) { // road 3: three terms
    let (mut old, mut p, mut nold, mut f, mut out) = (vec![0.0; M], vec![1.0; M], 1.0, vec![0.0; M], Vec::new());
    for _ in 0..=n {
        let (nk, xp): (f64, Vec<f64>) = (dot(&p, &p), xs.iter().zip(&p).map(|(x, v)| x * v).collect());
        let c = dot(y, &p) / nk; f = f.iter().zip(&p).map(|(a, b)| a + c * b).collect();
        let res: Vec<f64> = y.iter().zip(&f).map(|(a, b)| a - b).collect();
        out.push(Term { c, nk, dp: p[M - 1] - p[0], rss: dot(&res, &res), p: p.clone() });
        let (al, be) = (dot(&xp, &p) / nk, nk / nold);
        let next = (0..M).map(|j| (xs[j] - al) * p[j] - be * old[j]).collect(); old = p; p = next; nold = nk;
    }
    (f, out)
}
fn sing(cols: &Cols) -> (f64, Cols) { // one-sided Jacobi: rotate columns until perpendicular
    let mut v = cols.clone();
    for _sweep in 0..60 {
        let mut worst: f64 = 0.0;
        for p in 0..v.len() {
            for q in p + 1..v.len() {
                let (al, be, ga) = (dot(&v[p], &v[p]), dot(&v[q], &v[q]), dot(&v[p], &v[q]));
                if ga == 0.0 { continue; }
                worst = worst.max(ga.abs() / (al * be).sqrt());
                let ze = (be - al) / (2.0 * ga);
                let t = (if ze >= 0.0 { 1.0 } else { -1.0 }) / (ze.abs() + (1.0 + ze * ze).sqrt());
                let cs = 1.0 / (1.0 + t * t).sqrt(); let sn = cs * t;
                for i in 0..M { let (x1, x2) = (v[p][i], v[q][i]); v[p][i] = cs * x1 - sn * x2; v[q][i] = sn * x1 + cs * x2; }
            }
        }
        if worst < 1e-15 { break; }
    }
    let mut s: Vec<f64> = v.iter().map(|w| dot(w, w).sqrt()).collect(); s.sort_by(f64::total_cmp); (s[s.len() - 1] / s[0], v)
}
fn kappa(cols: &Cols) -> f64 { // kappa with each column scaled to length 1
    sing(&cols.iter().map(|col| { let n = dot(col, col).sqrt(); col.iter().map(|v| v / n).collect() }).collect()).0 }
fn rotated_fit(cols: &Cols, y: &[f64]) -> Vec<f64> { // no A^T A: rotate the columns perpendicular, then project y
    let v = sing(cols).1; let c: Vec<f64> = v.iter().map(|w| dot(y, w) / dot(w, w)).collect(); (0..M).map(|j| dot(&v.iter().map(|w| w[j]).collect::<Vec<f64>>(), &c)).collect() }
fn worst(f: &[f64], r: &[f64]) -> f64 { f.iter().zip(r).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }
fn mean(v: &[f64]) -> f64 { dot(v, &vec![1.0; v.len()]) / v.len() as f64 }

fn main() {
    let mf = M as f64;
    let x: Vec<f64> = (1..=M as i64).map(|j| (2 * j - M as i64 - 1) as f64 / mf).collect(); // month centres on -1 .. 1
    let (mut s, mut tenths) = (2024u64, Vec::new()); // rainfall in tenths of a mm
    for j in 0..M {
        let mut e = 0.0; for _ in 0..12 { e += splitmix(&mut s); } // noise: 12 uniforms minus 6, sd 1
        let v = 70.0 - 9.0 * x[j] + 12.0 * x[j] * x[j] * x[j] + SEASON[j % 12] + 25.0 * (e - 6.0);
        tenths.push(if v > 0.0 { (v * 10.0 + 0.5) as i128 } else { 0 });
    }
    let y: Vec<f64> = tenths.iter().map(|v| *v as f64 / 10.0).collect();
    let (g, dx, fx) = exact(&tenths);
    let (dl, fl) = cholesky_fit(&legendre(&x, 3), &y).unwrap();
    let (f3, rec) = (recurrence(&x, &y, 3).0, recurrence(&x, &y, 6).1);
    println!("data: {} months, mean {:.4} mm, smallest {:.1}, largest {:.1}", M, mean(&y),
        y.iter().cloned().fold(f64::MAX, f64::min), y.iter().cloned().fold(0.0, f64::max));
    println!("trend = d0 + d1 P1 + d2 P2 + d3 P3, in mm");
    for (name, d) in [("exact", &dx), ("Legendre", &dl)] { println!("{:<9}{}", name, (0..4).map(|k| format!(" d{} {}", k, fe(d[k], 12))).collect::<String>()); }
    let sig = (rec[3].rss / (mf - 4.0)).sqrt();
    let se = sig * (rec[1].dp * rec[1].dp / rec[1].nk + rec[3].dp * rec[3].dp / rec[3].nk).sqrt();
    println!("trend Jan 1995 {:.2} mm, Dec 2024 {:.2} mm, change {:.2} mm", fx[0], fx[M - 1], fx[M - 1] - fx[0]);
    println!("noise sd estimate {:.2} mm; change standard error {:.2} mm; cubic term {:.2} standard errors",
        sig, se, rec[3].c * rec[3].nk.sqrt() / sig);
    let yr: Vec<f64> = (1..=M).map(|j| 1995.0 + (j as f64 - 0.5) / 12.0).collect();
    let months: Vec<f64> = (0..M).map(|j| j as f64 + 1.0).collect();
    let bases: Vec<(&str, Cols)> = vec![("calendar years", powers(&yr, 3)), ("months 1..360", powers(&months, 3)),
        ("powers of x", powers(&x, 3)), ("Legendre", legendre(&x, 3)), ("recurrence", rec[..4].iter().map(|r| r.p.clone()).collect())];
    for (name, cols) in &bases {
        let err = match cholesky_fit(cols, &y) { None => "Cholesky stops: G not positive".to_string(),
            Some((_, f)) => format!("{} mm", fe(worst(&f, &fx), 2)) };
        let k = kappa(cols); println!("degree 3, {:<14} kappa {}  k^2 u {}  trend error {}", name, fe(k, 7), fe(k * k * U, 2), err);
    }
    println!("calendar years by Jacobi rotations, no A^T A: trend error {} mm", fe(worst(&rotated_fit(&bases[0].1, &y), &fx), 2));
    let kf = 1.0 + 7.0 * 21f64.sqrt() / (6.0 * mf * mf);
    println!("recurrence trend error {} mm; kappa formula 1 + 7 sqrt(21)/(6 m^2) = {}", fe(worst(&f3, &fx), 2), fe(kf, 7));
    let l = legendre(&x, 3);
    println!("sum of P0 P2 {:.9}, -1/(2m) {:.9}; sum of P1 P3 {:.9}, -7(m^2 - 1)/(6 m^3) {:.9}", dot(&l[0], &l[2]),
        -1.0 / (2.0 * mf), dot(&l[1], &l[3]), -7.0 * (mf * mf - 1.0) / (6.0 * mf * mf * mf));
    let sh: Vec<f64> = l.iter().map(|col| dot(&y, col) / dot(col, col)).collect(); let fs: Vec<f64> = (0..M).map(|j| dot(&l.iter().map(|col| col[j]).collect::<Vec<f64>>(), &sh)).collect();
    println!("shortcut ignoring the small overlaps: trend error {} mm", fe(worst(&fs, &fx), 2));
    println!("degree, kappa powers, kappa Legendre, log10 of each, k^2 u powers, error powers, error Legendre (mm, vs recurrence)");
    let mut sweep = Vec::new();
    for n in [3usize, 6, 9, 12, 15, 18, 21] {
        let rf = recurrence(&x, &y, n).0; let (kp, kl) = (kappa(&powers(&x, n)), kappa(&legendre(&x, n)));
        let (ep, el) = (worst(&cholesky_fit(&powers(&x, n), &y).unwrap().1, &rf), worst(&cholesky_fit(&legendre(&x, n), &y).unwrap().1, &rf));
        println!("sweep {:>2} {} {:.6} {:5.2} {:5.2} {} {} {}", n, fe(kp, 3), kl, kp.log10(), kl.log10(), fe(kp * kp * U, 2), fe(ep, 2), fe(el, 2));
        sweep.push((kp, kl, ep, el));
    }
    for k in 1..7 {
        println!("degree {}: rss {:.3}, drop {:.3}, c^2 |p|^2 {:.3}, z {:.2}", k, rec[k].rss, rec[k - 1].rss - rec[k].rss,
            rec[k].c * rec[k].c * rec[k].nk, rec[k].c * rec[k].nk.sqrt() / sig);
    }
    println!("flops m=360: normal eqns 4 coefs {}, 16 coefs {}; recurrence 4 coefs {}, 16 coefs {}", 360 * 16 + 21, 360 * 256 + 1365, 13 * 360 * 4, 13 * 360 * 16);
    let am: Vec<String> = (0..30).map(|i| format!("{:.1}", mean(&y[12 * i..12 * i + 12]))).collect();
    let at: Vec<String> = (0..30).map(|i| format!("{:.1}", mean(&fx[12 * i..12 * i + 12]))).collect();
    println!("annual mean {}", am.join(" ")); println!("annual trend {}", at.join(" "));

    assert!((0..4).all(|i| (0..i).all(|k| g[i][k] == 0))); // exactly orthogonal
    assert!((0..4).map(|k| (dl[k] - dx[k]).abs()).fold(0.0, f64::max) < 1e-11); // Legendre basis = exact
    assert!(worst(&f3, &fx) < 1e-11 && worst(&fl, &fx) < 1e-11); // recurrence = exact
    assert!(worst(&cholesky_fit(&bases[0].1, &y).unwrap().1, &fx) > 1.0 && worst(&rotated_fit(&bases[0].1, &y), &fx) < 1e-5); // A^T A breaks it
    assert!((kappa(&l) - kf).abs() < 1e-8); // kappa from the formula
    assert!((1..7).all(|k| (rec[k - 1].rss - rec[k].rss - rec[k].c * rec[k].c * rec[k].nk).abs() < 1e-6));
    assert!(sweep[4].2 > 1e4 * sweep[4].3 && sweep[4].1 < 1.02); // powers lose, Legendre holds
    println!("ALL CHECKS PASS");
}
