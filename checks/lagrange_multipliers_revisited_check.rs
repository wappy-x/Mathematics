// Lagrange multipliers, proved -- the same check as the Python, in Rust.  No crates.
// Pumps feed one water main.  Choose the flows x_i (L/s) to MINIMISE the power drawn,
// f(x) = sum a_i x_i^2 (kW), subject to equality rules g_j(x) = b_j.
// Road 1 solves the Lagrange equations grad f = sum lam_j grad g_j, g = b, by elimination.
// Road 2 walks the allowed plans with no multiplier and searches them.
// Road 3 loosens each rule, re-solves, and reads the price off the change in cost.
const A: [f64; 3] = [0.02, 0.03, 0.05]; // kW per (L/s)^2
const K: [f64; 3] = [0.1, 0.2, 0.4]; // m of head per L/s
const KWH: f64 = 0.20; // pounds per kWh

fn gauss(m0: &[Vec<f64>], r: &[f64]) -> Option<Vec<f64>> { // solve M z = r with row swaps
    let n = r.len();
    let mut m: Vec<Vec<f64>> = m0.iter().zip(r).map(|(row, v)| { let mut w = row.clone(); w.push(*v); w }).collect();
    for c in 0..n {
        let mut p = c;
        for i in c..n { if m[i][c].abs() > m[p][c].abs() { p = i } }
        if m[p][c].abs() < 1e-12 { return None } // singular: no unique solution
        m.swap(c, p);
        for i in 0..n {
            if i != c {
                let k = m[i][c] / m[c][c];
                let pivot = m[c].clone();
                for (u, v) in m[i].iter_mut().zip(pivot.iter()) { *u -= k * v }
            }
        }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}

fn lagrange(a: &[f64], g: &[Vec<f64>], b: &[f64]) -> Option<Vec<f64>> { // x_1..x_n, then lam_1..lam_m
    let (n, mm) = (a.len(), g.len());
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| {
        let mut row: Vec<f64> = (0..n).map(|j| if j == i { 2.0 * a[i] } else { 0.0 }).collect();
        row.extend((0..mm).map(|j| -g[j][i]));
        row
    }).collect();
    for j in 0..mm { let mut row = g[j].clone(); row.extend(vec![0.0; mm]); m.push(row) }
    let mut rhs = vec![0.0; n];
    rhs.extend_from_slice(b);
    gauss(&m, &rhs)
}

fn cost(a: &[f64], x: &[f64]) -> f64 { a.iter().zip(x).map(|(ai, xi)| ai * xi * xi).sum() }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(p, q)| p * q).sum() }
fn f4(v: &[f64]) -> String { // + 0.0 turns -0 into 0
    v.iter().map(|u| format!("{:.4}", (u * 1e9).round() / 1e9 + 0.0)).collect::<Vec<_>>().join(", ")
}
fn resid(a: &[f64], x: &[f64], g: &[Vec<f64>], lam: &[f64]) -> f64 { // size of grad f - sum lam_j grad g_j
    let r: Vec<f64> = (0..x.len()).map(|i| 2.0 * a[i] * x[i] - lam.iter().zip(g).map(|(l, gj)| l * gj[i]).sum::<f64>()).collect();
    dot(&r, &r).sqrt()
}
fn below(v: f64) -> &'static str { if v < 1e-12 { "below" } else { "ABOVE" } }

fn main() {
    // ---- two pumps, 100 L/s in total: the one-rule case ----
    let a2 = &A[..2];
    let z = lagrange(a2, &[vec![1.0, 1.0]], &[100.0]).unwrap();
    let (x1, x2, lam) = (z[0], z[1], z[2]);
    let c2 = |q: f64| cost(a2, &[q, 100.0 - q]);
    let mut scan = 0;
    for q in 0..=100 { if c2(q as f64) < c2(scan as f64) { scan = q } }
    println!("two pumps: flows {} L/s, marginal costs {} kW per L/s", f4(&[x1, x2]), f4(&[2.0 * A[0] * x1, 2.0 * A[1] * x2]));
    println!("two pumps: lambda {:.4} kW per L/s, power {:.4} kW, {:.4} pounds per hour", lam, c2(x1), KWH * c2(x1));
    println!("two pumps: integer scan finds {} L/s from pump A; even split costs {:.4} kW, marginal costs {}", scan, c2(50.0), f4(&[2.0 * A[0] * 50.0, 2.0 * A[1] * 50.0]));
    let chart: Vec<String> = (0..=10).map(|k| format!("{}", (c2(10.0 * k as f64) * 1e6).round() / 1e6)).collect();
    println!("chart, power (kW) at pump A = 0, 10, ..., 100 L/s: {}", chart.join(" "));
    assert!(scan as f64 == x1.round() && (c2(scan as f64) - cost(a2, &[x1, x2])).abs() < 1e-9);

    // ---- three pumps, two rules: total flow 150 L/s and 35 m of head at the hill tank ----
    let g: Vec<Vec<f64>> = vec![vec![1.0, 1.0, 1.0], K.to_vec()];
    let z = lagrange(&A, &g, &[150.0, 35.0]).unwrap();
    let (x, l1, l2) = (z[..3].to_vec(), z[3], z[4]);
    let p0 = cost(&A, &x);
    let h: Vec<f64> = (0..3).map(|e| 6.0 * (0..3).map(|i| K[i].powi(e) / (2.0 * A[i])).sum::<f64>()).collect(); // x_i = (lam1 + lam2 k_i) / (2 a_i)
    println!("hand elimination, times 6: {:.1} lam1 + {:.1} lam2 = {:.1}; {:.1} lam1 + {:.1} lam2 = {:.1}; det {:.1}",
             h[0], h[1], 6.0 * 150.0, h[1], h[2], 6.0 * 35.0, h[0] * h[2] - h[1] * h[1]);
    let gf: Vec<f64> = (0..3).map(|i| 2.0 * A[i] * x[i]).collect();
    println!("three pumps: flows {} L/s, lambda1 {:.4} kW per L/s, lambda2 {:.4} kW per m", f4(&x), l1, l2);
    println!("three pumps: power {:.4} kW, {:.4} pounds per hour; prices {:.4} pounds/h per L/s, {:.4} pounds/h per m", p0, KWH * p0, KWH * l1, KWH * l2);
    println!("grad f = ({}); residual {} 1e-12", f4(&gf), below(resid(&A, &x, &g, &[l1, l2])));
    let o = &g[0];
    let t = [10.0 * (o[1] * K[2] - o[2] * K[1]), 10.0 * (o[2] * K[0] - o[0] * K[2]), 10.0 * (o[0] * K[1] - o[1] * K[0])];
    println!("allowed step t = ({}); rule rates {}; grad f . t = {}", f4(&t), f4(&[dot(o, &t), dot(&K, &t)]), f4(&[dot(&gf, &t)]));
    let line = |s: f64| cost(&A, &[x[0] + s * t[0], x[1] + s * t[1], x[2] + s * t[2]]);
    let (mut lo, mut hi, r) = (-25.0, 50.0 / 3.0, (5f64.sqrt() - 1.0) / 2.0); // every pump flow stays at or above zero
    for _ in 0..200 {
        let (p, q) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if line(p) < line(q) { hi = q } else { lo = p }
    }
    let s = (lo + hi) / 2.0;
    println!("road 2, golden-section search along the line: s = {}, power {:.4} kW", f4(&[s]), line(s));
    println!("power along the line at s = -2, -1, 0, 1, 2: {}", f4(&[line(-2.0), line(-1.0), line(0.0), line(1.0), line(2.0)]));
    assert!(s.abs() < 1e-6 && resid(&A, &x, &g, &[l1, l2]) < 1e-12 && (line(s) - p0).abs() < 1e-9 && (line(1.0) - p0 - 0.4).abs() < 1e-9);
    let w = gauss(&[vec![1.0, K[1]], vec![1.0, K[2]]], &[gf[1], gf[2]]).unwrap(); // solve for lam from pumps B, C
    println!("implicit-function road, pumps B and C solved for: lambda = ({}); pump A row {:.4} = {:.4}", f4(&w), gf[0], w[0] + w[1] * K[0]);
    assert!((w[0] - l1).abs() < 1e-9 && (w[1] - l2).abs() < 1e-9 && (gf[0] - w[0] - w[1] * K[0]).abs() < 1e-9);
    let pstar = |b1: f64, b2: f64| cost(&A, &lagrange(&A, &g, &[b1, b2]).unwrap()[..3]);
    let d1 = (pstar(151.0, 35.0) - pstar(149.0, 35.0)) / 2.0;
    let d2 = (pstar(150.0, 36.0) - pstar(150.0, 34.0)) / 2.0;
    println!("road 3, re-solved: 151 L/s costs {:.4} kW (+{:.4}); 36 m costs {:.4} kW (+{:.4})",
             pstar(151.0, 35.0), pstar(151.0, 35.0) - p0, pstar(150.0, 36.0), pstar(150.0, 36.0) - p0);
    println!("road 3, central differences: {:.4} kW per L/s, {:.4} kW per m", d1, d2);
    assert!((d1 - l1).abs() < 1e-9 && (d2 - l2).abs() < 1e-9);

    // ---- what breaks ----
    let y = lagrange(&A, &[vec![1.0, 1.0, 1.0]], &[150.0]).unwrap()[..3].to_vec();
    println!("no head rule: flows {} L/s, power {:.4} kW, head {:.4} m, {:.4} m short", f4(&y), cost(&A, &y), dot(&K, &y), 35.0 - dot(&K, &y));
    let d: Vec<Vec<f64>> = vec![vec![1.0, 1.0, 1.0], vec![2.0, 2.0, 2.0], K.to_vec()];
    let sing = lagrange(&A, &d, &[150.0, 300.0, 35.0]).is_none();
    println!("demand written twice: Lagrange system {}", if sing { "singular" } else { "solvable" });
    for lam3 in [[l1, 0.0, l2], [0.0, l1 / 2.0, l2]] {
        println!("  multipliers ({}) leave residual {} 1e-12", f4(&lam3), below(resid(&A, &x, &d, &lam3)));
    }
    assert!(sing && resid(&A, &x, &d, &[0.0, l1 / 2.0, l2]) < 1e-12);
    let neg = lagrange(&A, &[vec![1.0, 1.0, 1.0], K.iter().map(|k| -k).collect()], &[150.0, -35.0]).unwrap();
    println!("head rule written as -k.x = -35: lambda2 = {:.4}", neg[4]);
    let (gc, e) = (|p: [f64; 2]| p[1] * p[1] - p[0].powi(3), 1e-6); // the rule g = x2^2 - x1^3; grad g by central difference
    let (gfc, ggc) = ([1.0, 0.0], [(gc([e, 0.0]) - gc([-e, 0.0])) / (2.0 * e), (gc([0.0, e]) - gc([0.0, -e])) / (2.0 * e)]);
    let best = (-1000..=1000).map(|u| u as f64 / 10.0)
        .map(|l| ((gfc[0] - l * ggc[0]).powi(2) + (gfc[1] - l * ggc[1]).powi(2)).sqrt()).fold(f64::INFINITY, f64::min);
    let root = |x2: f64| { // the x1 with g(x1, x2) = 0, by bisection: g falls as x1 rises
        let (mut lo, mut hi) = (-1.0f64, 2.0f64);
        for _ in 0..60 { if gc([(lo + hi) / 2.0, x2]) > 0.0 { lo = (lo + hi) / 2.0 } else { hi = (lo + hi) / 2.0 } }
        (lo + hi) / 2.0
    };
    let cusp = (-10..=10).map(|u| [root(u as f64 / 10.0), u as f64 / 10.0]) // 21 points on the curve, lowest x1 first
        .fold([f64::INFINITY, 0.0], |a, p| if p[0] < a[0] { p } else { a });
    println!("cusp, minimise x1 on x2^2 = x1^3: grad g at (0, 0) = ({}); best residual over lambda {:.4}; lowest of 21 curve points ({})", f4(&ggc), best, f4(&cusp));
    assert!(best > 0.99 && cusp[0].abs() < 1e-9 && cusp[1].abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
