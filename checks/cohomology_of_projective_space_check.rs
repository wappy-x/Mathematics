// Cohomology of projective space -- the same check as the Python, in Rust.  No
// crates.  Road 1 builds the cell chains of complex P^n and reads off the Betti
// numbers.  Road 2 counts the points of P^2 over F_p by brute force.  Road 3
// multiplies classes by solving real curves exactly.  Road 4 integrates the
// Fubini-Study densities numerically.  Roads 1 to 3 are exact.
use std::collections::HashMap;
use std::f64::consts::PI;
type P = Vec<i64>; // a polynomial in one variable, lowest power first

fn rank(rows: &[Vec<i64>], p: i64) -> usize { // elimination over Q (p = 0) or over F_p
    let red = |x: i64| if p > 0 { x.rem_euclid(p) } else { x };
    let mut m: Vec<Vec<i64>> = rows.iter().map(|r| r.iter().map(|&x| red(x)).collect()).collect();
    let mut r = 0;
    for c in 0..m.first().map_or(0, |row| row.len()) {
        let Some(piv) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, piv);
        for i in 0..m.len() {
            if i != r && m[i][c] != 0 {
                let (f, g) = (m[i][c], m[r][c]);
                m[i] = (0..m[i].len()).map(|k| red(g * m[i][k] - f * m[r][k])).collect();
            }
        }
        r += 1;
    }
    r
}
fn betti(cells: &[i64], bound: &HashMap<usize, Vec<Vec<i64>>>, p: i64) -> Vec<i64> {
    let rk = |k: usize| bound.get(&k).map_or(0, |b| rank(b, p)) as i64;
    (0..cells.len()).map(|k| cells[k] - rk(k) - rk(k + 1)).collect()
}
fn complex_pn(n: usize) -> (Vec<i64>, HashMap<usize, Vec<Vec<i64>>>) { // one cell in each even dimension
    let cells: Vec<i64> = (0..2 * n + 1).map(|k| 1 - (k % 2) as i64).collect();
    let bound = (1..2 * n + 1).map(|k| (k, vec![vec![0; cells[k] as usize]; cells[k - 1] as usize])).collect();
    (cells, bound)
}
fn points(p: i64, n: usize, eq: &dyn Fn(&[i64]) -> i64) -> Vec<i64> { // last nonzero entry scaled to 1
    let mut seen: HashMap<Vec<i64>, usize> = HashMap::new();
    for code in 1..p.pow(n as u32 + 1) {
        let v: Vec<i64> = (0..=n).map(|i| code / p.pow(i as u32) % p).collect();
        let last = (0..=n).filter(|&i| v[i] != 0).max().unwrap();
        let inv = (0..p).find(|&t| v[last] * t % p == 1).unwrap();
        let w: Vec<i64> = v.iter().map(|&x| x * inv % p).collect();
        if eq(&w).rem_euclid(p) == 0 { seen.insert(w, last); }
    }
    (0..=n).map(|k| seen.values().filter(|&&l| l == k).count() as i64).collect()
}
fn det3(m: &[[i64; 3]; 3]) -> i64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn fit(ps: [i64; 3], ns: &[i64]) -> P { // a0 + a1 p + a2 p^2 through three counts, by Cramer
    let v: [[i64; 3]; 3] = [0, 1, 2].map(|i| [1, ps[i], ps[i] * ps[i]]);
    (0..3).map(|j| { let mut m = v; for i in 0..3 { m[i][j] = ns[i] } det3(&m) / det3(&v) }).collect()
}
fn add(ps: &[&P]) -> P {
    let len = ps.iter().map(|q| q.len()).max().unwrap();
    let mut out: P = (0..len).map(|i| ps.iter().map(|q| *q.get(i).unwrap_or(&0)).sum()).collect();
    while out.len() > 1 && *out.last().unwrap() == 0 { out.pop(); }
    out
}
fn mul(a: &P, b: &P) -> P {
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y } }
    add(&[&out])
}
fn ev(q: &P, x: i64) -> i64 { q.iter().enumerate().map(|(i, c)| c * x.pow(i as u32)).sum() }
fn roots(q: &P) -> P { // whole-number roots with multiplicity: search, then divide
    let (mut q, mut out) = (q.clone(), vec![]);
    for r in -30i64..31 {
        while q.len() > 1 && ev(&q, r) == 0 {
            out.push(r);
            q = (0..q.len() - 1).map(|i| (i + 1..q.len()).map(|j| q[j] * r.pow((j - i - 1) as u32)).sum()).collect();
        }
    }
    out
}
fn show(q: &P, v: &str) -> String { // leading term first
    let mut s = String::new();
    for (i, &c) in q.iter().enumerate().rev().filter(|t| *t.1 != 0) {
        let coef = if c.abs() == 1 && i > 0 { String::new() } else { c.abs().to_string() };
        let pow = if i > 1 { format!("^{}", i) } else { String::new() };
        s += &format!("{}{}{}{}", if c < 0 { " - " } else { " + " }, coef, if i > 0 { v } else { "" }, pow);
    }
    format!("{}{}", if s.starts_with(" - ") { "-" } else { "" }, &s[3..])
}
fn circle(x: &P, y: &P, z: &P) -> P { add(&[&mul(x, x), &mul(y, y), &mul(&vec![-25], &mul(z, z))]) }
fn hyperbola(x: &P, y: &P, z: &P) -> P { add(&[&mul(x, y), &mul(&vec![-12], &mul(z, z))]) }
fn beacon(x: &P, y: &P, z: &P) -> P { circle(&add(&[x, &mul(&vec![-6], z)]), y, z) }

fn fs_curve(phi: &dyn Fn(f64) -> f64, n: usize) -> f64 { // (1/2) r (u'' + u'/r) dr on a curve chart
    let (mut tot, w) = (0.0, PI / (2 * n) as f64);
    for i in 0..n {
        let r = ((i as f64 + 0.5) * w).tan();
        let (h, u) = (1e-4 * (1.0 + r), |s: f64| phi(s * s).ln());
        let (d1, d2) = ((u(r + h) - u(r - h)) / (2.0 * h), (u(r + h) - 2.0 * u(r) + u(r - h)) / (h * h));
        tot += 0.5 * r * (d2 + d1 / r) * (1.0 + r * r) * w;
    }
    tot
}
fn fs_plane(n: usize) -> f64 { // h^2 density over the chart C^2: 8 r s / (1 + r^2 + s^2)^3
    let (w, mut tot) = (PI / (2 * n) as f64, 0.0);
    for i in 0..n { for j in 0..n {
        let (r, s) = (((i as f64 + 0.5) * w).tan(), ((j as f64 + 0.5) * w).tan());
        tot += 8.0 * r * s / (1.0 + r * r + s * s).powi(3) * (1.0 + r * r) * (1.0 + s * s) * w * w;
    } }
    tot
}

fn main() {
    let (x, line, tan_y, one, zero): (P, P, P, P, P) = (vec![0, 1], vec![7, -1], vec![5], vec![1], vec![0]);
    let join = |v: &P| v.iter().map(|b| b.to_string()).collect::<Vec<_>>().join(" ");
    for n in 1..5 {
        let (c, b) = complex_pn(n);
        println!("P^{}: Betti numbers in degrees 0 to {}: {}", n, 2 * n, join(&betti(&c, &b, 0)));
    }
    let real_bound: HashMap<usize, Vec<Vec<i64>>> = [(1, vec![vec![0]]), (2, vec![vec![2]])].into_iter().collect();
    let (bq, b2) = (betti(&[1, 1, 1], &real_bound, 0), betti(&[1, 1, 1], &real_bound, 2));
    println!("real P^2, cells in dimensions 0, 1, 2, boundary 2: over Q {:?}, over F_2 {:?}", bq, b2);
    let (mut plane, mut quad): (P, P) = (vec![], vec![]);
    for p in [2i64, 3, 5, 7] {
        let c = points(p, 2, &|_| 0);
        let q: i64 = points(p, 3, &|w| w[0] * w[3] - w[1] * w[2]).iter().sum();
        plane.push(c.iter().sum()); quad.push(q);
        println!("p = {}: P^2 has {} points = {} + {} + {} by cell; quadric surface {}", p, c.iter().sum::<i64>(), c[2], c[1], c[0], q);
        assert!(c == vec![1, p, p * p]);
    }
    let (a, qa) = (fit([2, 3, 5], &plane), fit([2, 3, 5], &quad));
    println!("fitted from p = 2, 3, 5: P^2 {} + {}p + {}p^2, predicts {} at p = 7; quadric {} + {}p + {}p^2",
             a[0], a[1], a[2], ev(&a, 7), qa[0], qa[1], qa[2]);
    let chi: P = [1i64, 2, 4].iter().map(|d| d.pow(3) - 4 * d * d + 6 * d).collect();
    println!("Euler characteristic d^3 - 4d^2 + 6d: plane {}, quadric {}, quartic {}, quartic b2 = {}", chi[0], chi[1], chi[2], chi[2] - 2);
    let mut cls: P = vec![];
    let curves: [(&str, fn(&P, &P, &P) -> P); 2] = [("circle x^2 + y^2 = 25z^2", circle), ("hyperbola xy = 12z^2", hyperbola)];
    for (name, f) in curves {
        let q = f(&x, &line, &one);
        cls.push(roots(&q).len() as i64);
        println!("{} on the line x + y = 7z: {} = 0, x = {:?}, class {}h", name, show(&q, "x"), roots(&q), cls[cls.len() - 1]);
    }
    let elim = add(&[&vec![144], &mul(&add(&[&mul(&x, &x), &vec![-25]]), &mul(&x, &x))]); // Res_y = a e^2 - b d e + c d^2
    let grid: Vec<(i64, i64)> = (-30..31).flat_map(|a| (-30..31).map(move |b| (a, b)))
        .filter(|&(a, b)| a * a + b * b == 25 && a * b == 12).collect();
    let jac: P = grid.iter().map(|&(a, b)| 2 * (a * a - b * b)).collect();
    let g = |a: i64, b: i64| a * a + b * b; // xy = 0 at (0 : 1) and (1 : 0); test x^2 + y^2 there
    println!("cup product 2h x 2h = {}h^2; eliminant {}, roots {:?}", cls[0] * cls[1], show(&elim, "x"), roots(&elim));
    println!("integer search finds {:?}; Jacobian 2(x^2 - y^2) there {:?}", grid, jac);
    println!("points at infinity: x^2 + y^2 and xy share none, resultant {}; total {}", g(0, 1) * g(1, 0), grid.len());
    let (u, v) = ([0i64, 1, 0], [0i64, 1, -1]); // the lines y = 0 and y - z = 0; they meet at the cross product
    let m = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
    println!("parallel lines y = 0, y = z meet at ({} : {} : {}) = (1 : 0 : 0)", m[0], m[1], m[2]);
    println!("lines x = 0, y = 0, x + y = z: determinant {}, no common point: h^3 = 0", det3(&[[1, 0, 0], [0, 1, 0], [1, 1, -1]]));
    let (fl, fc, fp) = (fs_curve(&|s| 1.0 + s, 4000), fs_curve(&|s| 1.0 + s + s * s, 4000), fs_plane(800));
    println!("Fubini-Study integrals: line {:.5}, conic (1 : t : t^2) {:.5}, h^2 over P^2 {:.5}", fl, fc, fp);
    let (inf_b, tan) = (beacon(&one, &x, &zero), circle(&x, &tan_y, &one));
    let real_b: Vec<(i64, i64)> = (-30..31).flat_map(|a| (-30..31).map(move |b| (a, b)))
        .filter(|&(a, b)| a * a + b * b == 25 && (a - 6) * (a - 6) + b * b == 25).collect();
    println!("mistake 1, real P^2 over Q: {:?}, the top class lost", bq);
    println!("mistake 2, beacon circles 6 apart: real affine points {:?}; at infinity both give {} = 0, discriminant {}: 2 more, total 4",
             real_b, show(&inf_b, "y"), -4 * inf_b[0] * inf_b[2]);
    println!("mistake 3, tangent line y = 5z: {} = 0, roots {:?}: 1 point, multiplicity 2", show(&tan, "x"), roots(&tan));
    println!("mistake 4, the quadric surface: {} classes in degree 2, not 1; Bezout in P^5 for conics: 6^5 = {}, true count 3264", qa[1], 6i64.pow(5));
    let (c2, b2map) = complex_pn(2);
    assert!(betti(&c2, &b2map, 0) == vec![a[0], 0, a[1], 0, a[2]] && ev(&a, 7) == plane[3]); // cells against counts
    assert!(qa == vec![1, 2, 1] && ev(&qa, 7) == quad[3] && chi[..2] == [a.iter().sum::<i64>(), qa.iter().sum::<i64>()]);
    assert!(bq == vec![1, 0, 0] && b2 == vec![1, 1, 1] && cls == vec![2, 2]);
    let mut xs: P = grid.iter().map(|&(a, _)| a).collect(); xs.sort();
    assert!(xs == roots(&elim) && roots(&elim).len() as i64 == cls[0] * cls[1] && !jac.contains(&0));
    assert!(real_b.len() == 2 && inf_b == circle(&one, &x, &zero) && roots(&inf_b).is_empty() && g(0, 1) * g(1, 0) != 0);
    assert!(roots(&tan) == vec![0, 0] && m[1] == 0 && m[2] == 0 && m[0] != 0 && (fl - 1.0).abs() + (fc - 2.0).abs() + (fp - 1.0).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
