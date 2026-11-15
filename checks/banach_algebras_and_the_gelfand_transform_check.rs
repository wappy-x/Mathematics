// Banach algebras and the Gelfand transform -- the same check as the Python, in
// Rust.  No crates.  The algebra is C[0, 24]: continuous price curves over one
// day, sized by their largest absolute value.  The curve is p(t) = 30 + (t-12)^2/2
// in pounds per MWh (illustrative).  Every computation is a grid of N points.
fn p(t: f64) -> f64 { 30.0 + (t - 12.0) * (t - 12.0) / 2.0 }
fn grid(n: usize) -> Vec<f64> { (0..n).map(|k| 24.0 * k as f64 / (n - 1) as f64).collect() }
fn sup(f: &[f64]) -> f64 { f.iter().fold(0.0, |m, v| if v.abs() > m { v.abs() } else { m }) }
fn neumann(lam: f64, n: usize) -> (f64, Option<Vec<f64>>, usize) {   // road 3: algebra
    let g: Vec<f64> = grid(n).iter().map(|&t| p(t) - lam).collect();
    let mut best = (f64::INFINITY, 0.0);
    for c in [1.0 / sup(&g), -1.0 / sup(&g)] {
        let q = sup(&g.iter().map(|v| 1.0 - c * v).collect::<Vec<f64>>());
        if q < best.0 { best = (q, c); }
    }
    let (q, c) = best;
    if q >= 1.0 { return (q, None, 0); }
    let (mut inv, mut term, mut k) = (vec![c; n], vec![c; n], 0);  // c * sum of (1 - c g)^k
    while sup(&term) > 1e-14 && k < 5000 {
        for i in 0..n { term[i] *= 1.0 - c * g[i]; inv[i] += term[i]; }
        k += 1;
    }
    assert!(sup(&(0..n).map(|i| inv[i] * g[i] - 1.0).collect::<Vec<f64>>()) < 1e-12);
    (q, Some(inv), k)
}
fn root(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 {     // bisection
    for _ in 0..60 {
        let m = (a + b) / 2.0;
        if f(a) * f(m) > 0.0 { a = m; } else { b = m; }
    }
    (a + b) / 2.0
}
type M2 = [[f64; 2]; 2];
fn mul(x: M2, y: M2) -> M2 {
    let mut r = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { for k in 0..2 { r[i][j] += x[i][k] * y[k][j]; } } }
    r
}
fn norm(x: M2) -> f64 { (x[0][0].abs() + x[0][1].abs()).max(x[1][0].abs() + x[1][1].abs()) }
fn ab(a: f64, b: f64) -> M2 { [[a, b], [b, a]] }
fn hat(a: f64, b: f64) -> (f64, f64) { (a + b, a - b) }               // the Gelfand transform
fn chi(x: M2, s: f64) -> f64 { x[0][0] + s * x[0][1] }               // a candidate character: a I + b X -> a + s b
fn join(v: &[String]) -> String { v.join(", ") }
fn main() {
    let ch: Vec<String> = (0..13).map(|k| format!("{}", p(2.0 * k as f64))).collect();
    println!("chart, p at 0,2,..,24 h: {}", ch.join(" "));
    println!("spectrum of p, exact: [30, 102]");
    for n in [25usize, 241, 2401] {                                    // road 2: the grid
        let mut vals: Vec<f64> = grid(n).iter().map(|&t| (p(t) * 1e9).round() / 1e9).collect();
        vals.sort_by(|a, b| a.partial_cmp(b).unwrap());
        vals.dedup();
        let gap = vals.windows(2).map(|w| w[1] - w[0]).fold(0.0, f64::max);
        println!("grid N={:>5}: min {:.4}, max {:.4}, {} values, largest gap {:.5}",
                 n, vals[0], vals[vals.len() - 1], vals.len(), gap);
        assert!(vals[0] == 30.0 && vals[vals.len() - 1] == 102.0 && gap < 12.0 * 24.0 / (n - 1) as f64);
    }
    for (lam, dist) in [(20.0, 10.0), (110.0, 8.0)] {
        let (q, inv, k) = neumann(lam, 2401);
        let si = sup(&inv.unwrap());
        println!("lambda={}: |1 - c g| = {:.6} < 1, {} terms, |inverse| = {:.6}, 1/{} = {:.6}",
                 lam, q, k, si, dist, 1.0 / dist);
        assert!((si - 1.0 / dist).abs() < 1e-9);
    }
    let (q, inv, _) = neumann(80.0, 2401);
    let (r1, r2) = (root(&|t| p(t) - 80.0, 0.0, 12.0), root(&|t| p(t) - 80.0, 12.0, 24.0));
    println!("lambda=80: best |1 - c g| = {:.6}, no series; p = 80 at t = {:.6} and {:.6}", q, r1, r2);
    assert!(inv.is_none() && (r1 - 2.0).abs() < 1e-9 && (r2 - 22.0).abs() < 1e-9);
    let s = 2f64.sqrt();
    println!("lambda=31: true crossings t = {:.6} and {:.6}; min |p - 31| on the grid:", 12.0 - s, 12.0 + s);
    let mins: Vec<f64> = [25usize, 241, 2401, 24001].iter()
        .map(|&n| grid(n).iter().map(|&t| (p(t) - 31.0).abs()).fold(f64::INFINITY, f64::min)).collect();
    println!("  N = 25, 241, 2401, 24001: {}", join(&mins.iter().map(|m| format!("{:.6}", m)).collect::<Vec<_>>()));
    println!("  so the grid's inverse has size {}", join(&mins.iter().map(|m| format!("{:.1}", 1.0 / m)).collect::<Vec<_>>()));
    assert!(mins[0] == 0.5 && mins[3] < 1e-3 && (root(&|t| p(t) - 31.0, 0.0, 12.0) - (12.0 - s)).abs() < 1e-9);
    // The rehearsal: C^4, prices at 0, 6, 12 and 18 h, multiplied place by place.
    let x4 = [p(0.0), p(6.0), p(12.0), p(18.0)];
    let ws = [-1.0, -0.5, 0.0, 0.5, 1.0, 2.0];
    let mut chars: Vec<[f64; 4]> = Vec::new();
    let mut ncand = 0;
    for a in ws { for b in ws { for c in ws { for d in ws {
        let w = [a, b, c, d];
        ncand += 1;
        let ok = w.iter().sum::<f64>() == 1.0 && (0..4).all(|i| (0..4).all(|j|
            (if i == j { w[i] } else { 0.0 }) == w[i] * w[j]));   // chi(e_i e_j) = chi(e_i) chi(e_j)
        if ok { chars.push(w); }
    } } } }
    chars.sort_by(|x, y| y.partial_cmp(x).unwrap());
    let cv: Vec<String> = chars.iter().map(|w| format!("{}", (0..4).map(|i| w[i] * x4[i]).sum::<f64>())).collect();
    println!("C^4 rehearsal: {} candidate weightings, {} characters, values on the price list {}",
             ncand, chars.len(), join(&cv));
    assert!(chars.len() == 4 && (0..4).all(|k| (0..4).all(|i| chars[k][i] == if i == k { 1.0 } else { 0.0 })));
    let spec4: Vec<String> = (0..201).filter(|&l| x4.iter().any(|&v| v - l as f64 == 0.0)).map(|l| l.to_string()).collect();
    println!("C^4 spectrum of the list (lambda with a zero coordinate): {}", join(&spec4));
    let simpson = |f: &dyn Fn(f64) -> f64| {                           // the day's average
        let (n, h) = (2400, 24.0 / 2400.0);
        let mut s2 = f(0.0) + f(24.0);
        for k in 1..n { s2 += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(k as f64 * h); }
        s2 * h / 3.0 / 24.0
    };
    let (m1, m2) = (simpson(&p), simpson(&|t| p(t) * p(t)));
    println!("daily average: mean p = {:.4}, mean p^2 = {:.4}, (mean p)^2 = {:.4}, gap {:.4}", m1, m2, m1 * m1, m2 - m1 * m1);
    assert!((m1 - 54.0).abs() < 1e-9 && (m2 - 3376.8).abs() < 1e-6);
    println!("evaluation at 5 h: p(5) = {:.1}, inside [30, 102]", p(5.0));
    let g1 = grid(240001).iter().map(|&t| (p(t) - 80.0).powi(2) + (t - 12.0).powi(2)).fold(f64::INFINITY, f64::min);
    let mut g2 = (f64::INFINITY, 0.0);
    for t in grid(2401) { let v = (p(t) - 80.0).powi(2) + (t - 2.0).powi(2); if v < g2.0 { g2 = (v, t); } }
    println!("ideal of p-80 and t-12: min of the sum of squares {:.4} > 0, so it holds 1", g1);
    println!("ideal of p-80 and t-2: min of the sum of squares {:.4} at t = {:.4}", g2.0, g2.1);
    assert!((g1 - 99.0).abs() < 1e-6 && g2.0 == 0.0 && g2.1 == 2.0);
    // A commuting algebra that is not functions: a I + b J, J swapping two hours.
    let (i2, j): (M2, M2) = ([[1.0, 0.0], [0.0, 1.0]], [[0.0, 1.0], [1.0, 0.0]]);
    let svals: Vec<f64> = (-300..=300).map(|k| k as f64 / 100.0).collect();   // keep s only if chi(J J) = chi(J)^2
    let jvals: Vec<f64> = svals.iter().cloned().filter(|&s| (chi(mul(j, j), s) - chi(j, s).powi(2)).abs() < 1e-9).collect();
    println!("J^2 = I: {}; characters send J to {} and {}", mul(j, j) == i2, jvals[0], jvals[1]);
    let bh = hat(0.8, 0.2);
    let ih = (1.0 / bh.0, 1.0 / bh.1);
    let inv = ((ih.0 + ih.1) / 2.0, (ih.0 - ih.1) / 2.0);
    let res = mul(ab(0.8, 0.2), ab(inv.0, inv.1));
    println!("blur 0.8I+0.2J: transform ({:.1}, {:.1}); inverse {:.6} I {:+.6} J; product {:.6} {:.6}",
             bh.0, bh.1, inv.0, inv.1, res[0][0], res[0][1]);
    assert!((res[0][0] - 1.0).abs() < 1e-12 && res[0][1].abs() < 1e-12 && jvals == vec![-1.0, 1.0]);
    let (ah, m) = (hat(0.5, 0.5), ab(0.5, 0.5));
    let det_m = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    println!("average 0.5I+0.5J: transform ({:.1}, {:.1}), determinant {:.2}", ah.0, ah.1, det_m);
    let (t, nn): (M2, M2) = ([[1.0, 1.0], [0.0, 1.0]], [[0.0, 1.0], [0.0, 0.0]]);
    let (mut pw, mut out) = (i2, Vec::new());
    for n in 1..=100 {
        pw = mul(pw, t);
        if [1, 10, 100].contains(&n) { out.push(format!("{:.6}", norm(pw).powf(1.0 / n as f64))); }
        assert!(norm(pw) == (n + 1) as f64);                           // |T^n| = n + 1
    }
    let nvals: Vec<f64> = svals.iter().cloned().filter(|&s| (chi(mul(nn, nn), s) - chi(nn, s).powi(2)).abs() < 1e-9).collect();
    println!("|Z| = {}, |Z^2| = {}, every character sends Z to {}", norm(nn), norm(mul(nn, nn)), nvals[0]);
    println!("|T^n|^(1/n) for T = I + Z, n = 1, 10, 100: {}; spectral radius 1", join(&out));
    let rot: M2 = [[0.0, -1.0], [1.0, 0.0]];                           // rotation; det(R - lambda) from its entries
    let dets = (-1000..=1000).map(|k| { let l = k as f64 / 100.0; (rot[0][0] - l) * (rot[1][1] - l) - rot[0][1] * rot[1][0] })
        .fold(f64::INFINITY, f64::min);
    println!("rotation over the reals: min det(R - lambda) = {:.4}, real spectrum empty", dets);
    assert!(norm(mul(nn, nn)) == 0.0 && nvals == vec![0.0] && ah.1 == 0.0 && det_m == 0.0 && dets == 1.0);
    println!("ALL CHECKS PASS");
}
