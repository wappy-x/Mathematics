// Farey fractions and Ford circles -- the same check as the Python, in Rust.  No crates.  Order 5 is listed twice.
type F = (i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn v(f: F) -> f64 { f.0 as f64 / f.1 as f64 }
fn show(fs: &[F]) -> String { fs.iter().map(|f| format!("{}/{}", f.0, f.1)).collect::<Vec<_>>().join(" ") }
fn farey(n: i64) -> Vec<F> {                         // road one: every p/q with q <= n, lowest terms, sorted
    let mut fs: Vec<F> = (1..=n).flat_map(|q| (0..=q).map(move |p| (p, q))).filter(|f| gcd(f.0, f.1) == 1).collect();
    fs.sort_by(|f, g| (f.0 * g.1).cmp(&(g.0 * f.1))); fs }
fn by_mediants(n: i64) -> Vec<F> { let mut fs: Vec<F> = vec![(0, 1), (1, 1)];   // road two: 0/1 and 1/1, then mediants only
    for k in 2..=n { let mut out = vec![fs[0]];
        for w in fs.windows(2) { if w[0].1 + w[1].1 == k { out.push((w[0].0 + w[1].0, k)); } out.push(w[1]); } fs = out; }
    fs }
fn gap(f: F, g: F, s: f64) -> (f64, f64) {           // centre distance and radius sum; radius 1/(s q^2)
    let (r1, r2) = (1.0 / (s * (f.1 * f.1) as f64), 1.0 / (s * (g.1 * g.1) as f64));
    (((v(g) - v(f)).powi(2) + (r2 - r1).powi(2)).sqrt(), r1 + r2)
}
fn trap(n: i64, x: f64) -> (F, bool) {               // neighbours around x, then the mediant picks a half
    let fs = farey(n); let w = fs.windows(2).find(|w| v(w[0]) < x && x < v(w[1])).unwrap(); let ((a, b), (c, d)) = (w[0], w[1]);
    let (p, q) = if x < v((a + c, b + d)) { (a, b) } else { (c, d) }; let (off, m) = ((x - v((p, q))).abs(), (q * (b + d)) as f64);
    println!("order {}: {}/{} < {:.6} < {}/{}, mediant {}/{}, so {}/{} is {:.5} off, under 1/({} x {}) = {:.5} < 1/{} = {:.6}", n, a, b, x, c, d, a + c, b + d, p, q, off, q, b + d, 1.0 / m, q * q, 1.0 / (q * q) as f64);
    ((p, q), off < 1.0 / m && 1.0 / m < 1.0 / (q * q) as f64)
}
fn main() {
    let x = (5f64.sqrt() - 1.0) / 2.0;               // 0.618034, the golden ratio less 1
    let f5 = farey(5); let pr: Vec<(F, F)> = f5.windows(2).map(|w| (w[0], w[1])).collect();
    println!("order 5, {} fractions: {}; built from mediants: {}", f5.len(), show(&f5), if by_mediants(5) == f5 { "same" } else { "DIFFERENT" });
    println!("b x c - a x d: {}; gaps 1/(b x d): {}", pr.iter().map(|((a, b), (c, d))| (b * c - a * d).to_string()).collect::<Vec<_>>().join(" "), pr.iter().map(|(f, g)| format!("1/{}", f.1 * g.1)).collect::<Vec<_>>().join(" "));
    println!("1/3 and 2/5: 2 x 3 - 1 x 5 = {}, gap {:.5} = 1/15; mediant of 1/3 and 1/2: {}/{}; average {}/{}; sum {}/{}", 2 * 3 - 1 * 5, 2.0 / 5.0 - 1.0 / 3.0, 1 + 1, 3 + 2, 1 * 2 + 1 * 3, 3 * 2 * 2, 1 * 2 + 1 * 3, 3 * 2);
    let ((dist, rsum), (bad, badsum)) = (gap((1, 3), (2, 5), 2.0), gap((1, 3), (2, 5), 1.0));
    println!("Ford circles at 1/3 and 2/5: radii {:.5} and {:.5}, centres {:.5} apart, radii add to {:.5}; with radius 1/q^2 they overlap by {:.5}", 1.0 / 18.0, 1.0 / 50.0, dist, rsum, badsum - bad);
    println!("figure, centre 1/3 ({:.5}, {:.5}), centre 2/5 ({:.5}, {:.5}), touch at ({:.5}, {:.5}) = (13/34, 1/34)", 1.0 / 3.0, 1.0 / 18.0, 2.0 / 5.0, 1.0 / 50.0, 13.0 / 34.0, 1.0 / 34.0);
    let hits = [trap(5, x), trap(8, x)];
    let near: Vec<F> = (1..14).flat_map(|q| (0..=q).map(move |p| (p, q))).filter(|&(p, q)| gcd(p, q) == 1 && (x - v((p, q))).abs() < 1.0 / (q * q) as f64).collect();
    println!("search, q up to 13, fractions within 1/q^2: {}; 3/4 misses: {:.5} > 1/16 = {:.5}", show(&near), (x - 0.75).abs(), 1.0 / 16.0);
    assert!(by_mediants(30) == farey(30) && (1..31).all(|n| farey(n).windows(2).all(|w| w[0].1 * w[1].0 - w[0].0 * w[1].1 == 1)));
    assert!(farey(30).windows(2).all(|w| { let (d, s) = gap(w[0], w[1], 2.0); (d - s).abs() < 1e-12 }) && gap((1, 4), (1, 2), 2.0).0 > gap((1, 4), (1, 2), 2.0).1 + 1e-9);
    assert!(hits.iter().all(|&(f, ok)| ok && near.contains(&f)) && near == vec![(0, 1), (1, 1), (1, 2), (2, 3), (3, 5), (5, 8), (8, 13)]);
    assert!((1.0 / 3.0 + (2.0 / 5.0 - 1.0 / 3.0) / 18.0 / dist - 13.0 / 34.0).abs() < 1e-12 && (1.0 / 18.0 - (1.0 / 18.0 - 1.0 / 50.0) / 18.0 / dist - 1.0 / 34.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
