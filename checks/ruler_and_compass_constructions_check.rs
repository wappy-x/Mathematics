// Ruler and compass -- the same check as the Python, in Rust.  No crates.  cos(360/17 deg) by four square
// roots and by bisection on the cosine sum; the cubics that block the 7-gon hunted for rational roots.
fn sqrt(a: f64) -> f64 {                          // Newton's method, written out here
    let mut x = a.max(1.0); for _ in 0..80 { x = (x + a / x) / 2.0 }
    x
}
fn cheb(c: f64, k: usize) -> f64 {                // cos(k t) from c = cos t
    if k == 0 { return 1.0 }
    let (mut lo, mut hi) = (1.0, c);
    for _ in 1..k { (lo, hi) = (hi, 2.0 * c * hi - lo) }
    hi
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // a root where f changes sign
    for _ in 0..200 { let m = (lo + hi) / 2.0; if (f(lo) > 0.0) == (f(m) > 0.0) { lo = m } else { hi = m } }
    (lo + hi) / 2.0
}
fn rational_roots(a: [i64; 4]) -> Vec<String> {   // every p/q with p | a0 and q | a3, in lowest terms
    let ds = |m: i64| (1..=m.abs()).filter(|d| m % d == 0).collect::<Vec<i64>>();
    let mut out = Vec::new();
    for p in ds(a[0]) { for q in ds(a[3]) { for s in [-1, 1] {
        let v: i64 = (0..4).map(|i| a[i] * (s * p).pow(i as u32) * q.pow(3 - i as u32)).sum();
        if v == 0 && (2..=q).all(|d| p % d != 0 || q % d != 0) {
            out.push(if q == 1 { format!("{}", s * p) } else { format!("{}/{}", s * p, q) })
        }
    } } }
    out
}
fn buildable(mut n: u64) -> bool {                // 2^k times distinct primes p with p - 1 a power of 2
    while n % 2 == 0 { n /= 2 }
    for p in 3..=n {
        if n % p == 0 && (2..p).all(|d| p % d != 0) {
            n /= p; if n % p == 0 || (p - 1) & (p - 2) != 0 { return false }
        }
    }
    true
}
fn main() {
    let r17 = sqrt(17.0);
    let (a, b) = ((-1.0 + r17) / 2.0, (-1.0 - r17) / 2.0);
    let (a1, b1) = ((a + sqrt(a * a + 4.0)) / 2.0, (b + sqrt(b * b + 4.0)) / 2.0);
    let (tower, small) = ((a1 + sqrt(a1 * a1 - 4.0 * b1)) / 4.0, (a1 - sqrt(a1 * a1 - 4.0 * b1)) / 4.0);
    let sum_root = |m: usize, lo: f64| bisect(&|c| 1.0 + 2.0 * (1..m).map(|k| cheb(c, k)).sum::<f64>(), lo, 0.99);
    let (c17, c7) = (sum_root(9, 0.8), sum_root(4, 0.3));
    let ck: Vec<f64> = (0..9).map(|k| cheb(c17, k)).collect();
    let (a2, b2) = (2.0 * (ck[1] + ck[2] + ck[4] + ck[8]), 2.0 * (ck[3] + ck[5] + ck[6] + ck[7]));
    let cubics = [("8c^3 + 4c^2 - 4c - 1 (7-gon)", [-1, -4, 4, 8]), ("8x^3 - 6x - 1 (trisect 60 deg)", [-1, -6, 0, 8]),
                  ("x^3 - 2 (double the cube)", [-2, 0, 0, 1]), ("4x^3 - 3x + 1 (trisect 180 deg)", [1, -3, 0, 4])];
    let (c20, cube2) = (bisect(&|x| 8.0 * x * x * x - 6.0 * x - 1.0, 0.5, 1.0), bisect(&|x| x * x * x - 2.0, 1.0, 2.0));
    let mut s = 1.0;                              // Archimedes: side of a 6 x 2^k-gon in a unit circle
    for _ in 0..30 { s = s / sqrt(2.0 + sqrt(4.0 - s * s)) }
    let pi = 3.0 * 2f64.powi(30) * s;
    let cosd = |d: f64| { let (x, mut term, mut sum) = (d * pi / 180.0, 1.0, 0.0);   // own cosine
        for j in 0..30 { sum += term; term *= -x * x / (((2 * j + 1) * (2 * j + 2)) as f64) } sum };
    let ang = |x: f64, y: f64| bisect(&|d| cosd(d) - x / sqrt(x * x + y * y), 0.0, 90.0);
    let (t1, t2) = (ang(5.0 / 6.0, sqrt(3.0) / 6.0), ang(2.0 / 3.0, sqrt(3.0) / 3.0));
    let (yes, no): (Vec<u64>, Vec<u64>) = (3..21).partition(|&n| buildable(n));
    println!("17-gon, road one, four square roots: cos(360/17 deg) = {:.12}", tower);
    println!("17-gon, road two, bisection on the cosine sum: {:.12}", c17);
    println!("tower: sqrt 17 = {:.6}, A = {:.6}, B = {:.6}, A1 = {:.6}, B1 = {:.6}", r17, a, b, a1, b1);
    println!("road two's cosines: A + B = {:.6}, A x B = {:.6}, 17 turns give cos = {:.6}", a2 + b2, a2 * b2, cheb(c17, 17));
    println!("7-gon: cos(360/7 deg) = {:.12}, 7 turns give cos = {:.6}", c7, cheb(c7, 7));
    for (name, c) in &cubics { let r = rational_roots(*c);
        println!("rational roots of {}: {}", name, if r.is_empty() { "none".to_string() } else { r.join(", ") }) }
    println!("cos 20 deg = {:.6}, own cosine of 20 deg = {:.6}, cube root of 2 = {:.6}, pi by Archimedes = {:.6}, square side for a unit circle sqrt(pi) = {:.6}", c20, cosd(20.0), cube2, pi, sqrt(pi));
    println!("buildable n-gons, n = 3 to 20: {:?}; not buildable: {:?}", yes, no);
    println!("mistake, smaller root at the last step: {:.6} = cos(4 x 360/17 deg) = {:.6}", small, ck[4]);
    println!("mistake, chord of 60 deg cut in three: angles {:.3}, {:.3}, {:.3} deg", t1, t2 - t1, 60.0 - t2);
    let (near, side7) = (sqrt(3.0) / 2.0, sqrt(2.0 - 2.0 * c7));
    println!("mistake, near-miss 7-gon side sqrt(3)/2 = {:.6}, true {:.6}, short by {:.2}%", near, side7, 100.0 * (1.0 - near / side7));
    println!("figure, 17-gon: centre (180, 120), radius 100, P1 ({:.1}, {:.1})", 180.0 + 100.0 * c17, 120.0 - 100.0 * sqrt(1.0 - c17 * c17));
    println!("figure, root: base (20, 200) to (340, 200), foot x {:.1}, top y {:.1}", 20.0 + 320.0 / 18.0, 200.0 - 320.0 / 18.0 * r17);
    assert!((tower - c17).abs() < 1e-12 && (small - ck[4]).abs() < 1e-12);       // two roads, both roots
    assert!((a2 + b2 + 1.0).abs() < 1e-9 && (a2 * b2 + 4.0).abs() < 1e-9);         // the first pairing, by road two
    let found: Vec<Vec<String>> = cubics.iter().map(|(_, c)| rational_roots(*c)).collect();
    assert!(found == vec![vec![], vec![], vec![], vec!["-1".to_string(), "1/2".to_string()]]);  // control finds its roots
    assert!((cheb(c7, 7) - 1.0).abs() < 1e-9 && (cosd(20.0) - c20).abs() < 1e-9);  // 7 turns close; cubic gives cos 20
    println!("ALL CHECKS PASS");
}
