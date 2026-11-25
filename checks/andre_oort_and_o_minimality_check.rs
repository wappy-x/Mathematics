// Andre-Oort and o-minimality -- the same check as the Python, in Rust.  No crates.
// Five parts, each by two roads: (1) j = E4^3/Delta as an exact q-series, against
// 1728 + E6^2/Delta; (2) j at CM points from the series, against exact integers, with
// class numbers counted from reduced forms; (3) the level-2 modular polynomial, exactly
// at special pairs and numerically at tau = 1.1i; (4) class numbers by forms
// against Dirichlet's sum, and CM-point heights; (5) rational points of bounded height.
use std::f64::consts::PI;
const M: usize = 12; // exact series to q^M
const N: u64 = 40; // numeric series to q^N
type C = (f64, f64);
fn sigma(k: u32, n: u64) -> u64 { (1..=n).filter(|d| n % d == 0).map(|d| d.pow(k)).sum() }
fn sci(x: f64) -> String { // 12 significant digits, same as Python
    let (s, mut e, mut v) = (if x < 0.0 { "-" } else { "" }, 0, x.abs());
    while v >= 10.0 { v /= 10.0; e += 1; }
    while v < 1.0 { v *= 10.0; e -= 1; }
    format!("{}{:.11}e{}", s, v, e)
}
fn mul(a: &[i128], b: &[i128]) -> Vec<i128> { (0..=M).map(|n| (0..=n).map(|i| a[i] * b[n - i]).sum()).collect() }
fn cm(a: C, b: C) -> C { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn cdiv(a: C, b: C) -> C { let d = b.0 * b.0 + b.1 * b.1; ((a.0 * b.0 + a.1 * b.1) / d, (a.1 * b.0 - a.0 * b.1) / d) }
fn ev(x: f64, y: f64) -> (C, C, C) { // E4, E6, Delta at tau = x + iy
    let r = (-2.0 * PI * y).exp();
    let q = (r * (2.0 * PI * x).cos(), r * (2.0 * PI * x).sin());
    let (mut e4, mut e6, mut pr, mut qn) = ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
    for n in 1..=N {
        qn = cm(qn, q);
        let (s3, s5) = ((240 * sigma(3, n)) as f64, (504 * sigma(5, n)) as f64);
        e4 = (e4.0 + s3 * qn.0, e4.1 + s3 * qn.1);
        e6 = (e6.0 - s5 * qn.0, e6.1 - s5 * qn.1);
        let f = (1.0 - qn.0, -qn.1);
        for _ in 0..24 { pr = cm(pr, f); }
    }
    (e4, e6, cm(q, pr))
}
fn jval(x: f64, y: f64) -> (C, C) { let (e4, e6, d) = ev(x, y); (cdiv(cm(cm(e4, e4), e4), d), cdiv(cm(e6, e6), d)) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn forms(d: i64) -> Vec<(i64, i64, i64)> { // primitive reduced forms of discriminant d
    let (mut out, mut a) = (vec![], 1i64);
    while 3 * a * a <= -d {
        for b in -a + 1..=a {
            if (b * b - d) % (4 * a) != 0 { continue; }
            let c = (b * b - d) / (4 * a);
            if c >= a && !(c == a && b < 0) && gcd(gcd(a, b), c) == 1 { out.push((a, b, c)); }
        }
        a += 1;
    }
    out
}
fn phi2(x: f64, y: f64) -> [f64; 11] { [x * x * x, y * y * y, -x * x * y * y, 1488.0 * x * x * y, 1488.0 * x * y * y, -162000.0 * x * x,
    -162000.0 * y * y, 40773375.0 * x * y, 8748000000.0 * x, 8748000000.0 * y, -157464000000000.0] }
fn phi2_exact(x: i128, y: i128) -> i128 { x * x * x + y * y * y - x * x * y * y + 1488 * x * x * y + 1488 * x * y * y - 162000 * x * x
    - 162000 * y * y + 40773375 * x * y + 8748000000 * x + 8748000000 * y - 157464000000000 }
fn jac(n: i64, m: i64) -> i64 { // Jacobi symbol (n/m), m odd
    let (mut n, mut m, mut r) = (n % m, m, 1);
    while n != 0 {
        while n % 2 == 0 { n /= 2; if m % 8 == 3 || m % 8 == 5 { r = -r; } }
        std::mem::swap(&mut n, &mut m);
        if n % 4 == 3 && m % 4 == 3 { r = -r; }
        n %= m;
    }
    if m == 1 { r } else { 0 }
}
fn main() {
    let e4: Vec<i128> = (0..=M as u64).map(|n| if n == 0 { 1 } else { 240 * sigma(3, n) as i128 }).collect();
    let e6: Vec<i128> = (0..=M as u64).map(|n| if n == 0 { 1 } else { -504 * sigma(5, n) as i128 }).collect();
    let mut p: Vec<i128> = (0..=M).map(|k| (k == 0) as i128).collect(); // 1 / prod (1 - q^n)^24
    for n in 1..=M {
        let g: Vec<i128> = (0..=M).map(|k| (k % n == 0) as i128).collect(); // 1 / (1 - q^n)
        for _ in 0..24 { p = mul(&p, &g); }
    }
    let j = mul(&mul(&mul(&e4, &e4), &e4), &p); // j[k] is the coefficient of q^(k-1)
    let mut j2 = mul(&mul(&e6, &e6), &p); j2[1] += 1728; // road 2: j = 1728 + E6^2 / Delta
    let terms: Vec<String> = (1..7).map(|k| match k { 1 => j[1].to_string(), 2 => format!("{} q", j[2]), _ => format!("{} q^{}", j[k], k - 1) }).collect();
    println!("j = 1/q + {} + ...", terms.join(" + "));
    assert!(j == j2 && j[0] == 1);
    let qi = (-2.0 * PI).exp();
    let (mut part, mut s) = (vec![], 1.0 / qi);
    for k in 0..7 { if k > 0 { s += j[k] as f64 * qi.powf((k - 1) as f64); } part.push(s); }
    println!("tau = i: q = {:.8}; partial sums {}", qi, part.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "));
    let (_, e6i, _) = ev(0.0, 1.0); let (e4r, _, _) = ev(-0.5, 3f64.sqrt() / 2.0);
    let (z6, z4) = (e6i.0.abs() + e6i.1.abs() < 1e-12, e4r.0.abs() + e4r.1.abs() < 1e-12);
    println!("|E6(i)| < 1e-12: {}; |E4(rho)| < 1e-12: {}", if z6 { "True" } else { "False" }, if z4 { "True" } else { "False" });
    assert!((part[6] - 1728.0).abs() < 0.01 && z6 && z4);
    let jx: [(i64, i128); 13] = [(-3, 0), (-4, 1728), (-7, -3375), (-8, 8000), (-11, -32768), (-12, 54000), (-16, 287496), (-19, -884736),
        (-27, -12288000), (-28, 16581375), (-43, -884736000), (-67, -147197952000), (-163, -262537412640768000)];
    println!("    D  h               exact j(tau_D)   from the series");
    for &(d, x) in jx.iter() {
        let (a, b, _) = forms(d)[0];
        assert!(forms(d).len() == 1);
        let ((jr, ji), (kr, _)) = jval(-b as f64 / (2 * a) as f64, ((-d) as f64).sqrt() / (2 * a) as f64);
        let shown = if jr.abs() > 1e-6 { sci(jr) } else { "below 1e-6".to_string() };
        println!("{:>5}  1 {:>24}   {}", d, x, shown);
        let tol = 1e-9 * (x as f64).abs().max(1.0);
        assert!((jr - x as f64).abs() <= tol && ji.abs() <= tol && (kr + 1728.0 - jr).abs() <= tol);
    }
    let one: Vec<i64> = (3..=2000i64).map(|m| -m).filter(|d| d.rem_euclid(4) <= 1 && forms(*d).len() == 1).collect();
    let same = one == jx.iter().map(|t| t.0).collect::<Vec<_>>();
    println!("class number 1 for -2000 <= D <= -3: {} discriminants, the 13 above: {}", one.len(), if same { "True" } else { "False" });
    assert!(same);
    let f15 = forms(-15);
    let j15: Vec<f64> = f15.iter().map(|&(a, b, _)| jval(-b as f64 / (2 * a) as f64, 15f64.sqrt() / (2 * a) as f64).0 .0).collect();
    println!("D = -15, forms {:?}: j = {:.4}, {:.4}; sum {:.3}, product {:.1}", f15, j15[0], j15[1], j15[0] + j15[1], j15[0] * j15[1]);
    assert!((j15[0] + j15[1] + 191025.0).abs() < 1e-3 && (j15[0] * j15[1] + 121287375.0).abs() < 1.0);
    let (ja, jb) = (jval(0.0, 1.1).0 .0, jval(0.0, 2.2).0 .0); // road 2 for the coefficients: Phi_2 vanishes at every tau
    let t = phi2(ja, jb);
    let ok = t.iter().sum::<f64>().abs() < 1e-10 * t.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    println!("tau = 1.1i: j(tau) = {}, j(2 tau) = {}, |Phi_2| / largest term < 1e-10: {}", sci(ja), sci(jb), if ok { "True" } else { "False" });
    assert!(ok);
    println!("tau = 1.1i is special too: 100 tau^2 + 121 = 0, and (100, 0, 121) is a reduced form of D = -48400: {}", if forms(-48400).contains(&(100, 0, 121)) { "True" } else { "False" });
    let small: Vec<i128> = jx.iter().map(|t| t.1).filter(|v| v.abs() < 1_000_000_000).collect();
    let on2: Vec<(i128, i128)> = small.iter().flat_map(|&x| small.iter().map(move |&y| (x, y))).filter(|&(x, y)| phi2_exact(x, y) == 0).collect();
    let line = small.iter().flat_map(|&x| small.iter().map(move |&y| x + y)).filter(|&s| s == 1728).count();
    println!("special pairs among the {} values under 10^9 in size: on Phi_2 = 0: {}; on X = Y: {}; on X + Y = 1728: {}", small.len(), on2.len(), small.len(), line);
    println!("on Phi_2 = 0: {}", on2.iter().filter(|p| p.0 <= p.1).map(|p| format!("({},{})", p.0, p.1)).collect::<Vec<_>>().join(" "));
    assert!(on2.contains(&(1728, 287496)) && on2.contains(&(0, 54000)) && on2.contains(&(-3375, 16581375)));
    println!("       D      h  h/sqrt|D|  max height of (Re tau, Im tau^2)");
    for m in [15i64, 103, 1003, 10003, 100003, 1000003] { // D = -m, fundamental, D = 1 mod 4
        let f = forms(-m);
        let hd = -(1..m).map(|n| jac(n, m) * n).sum::<i64>() / m; // Dirichlet: h = -(1/m) sum chi(n) n
        let ht = f.iter().map(|&(a, b, _)| { let (g, h) = (gcd(b, 2 * a), gcd(m, 4 * a * a));
            (b.abs() / g).max(2 * a / g).max(m / h).max(4 * a * a / h) }).max().unwrap();
        println!("{:>8} {:>6}  {:.4}  {}", -m, f.len(), f.len() as f64 / (m as f64).sqrt(), ht);
        assert!(hd == f.len() as i64 && ht <= 2 * m);
    }
    let phi = |n: i64| (1..=n).filter(|&a| gcd(a, n) == 1).count() as i64;
    let rats = |t: i64, lo: i64, hi: i64| -> Vec<(i64, i64)> {
        (1..=t).flat_map(|r| (lo * r..=(hi * r).min(t)).map(move |p| (p, r))).filter(|&(p, r)| gcd(p, r) == 1).collect() };
    let x = rats(100, 0, 1); // every fraction in [0, 1] of height <= 100
    let grid = x.iter().map(|&(a, b)| x.iter().filter(|&&(p, r)| p * b * b == a * a * r).count() as i64).sum::<i64>(); // y = x^2
    println!("      T  y = x^2: grid search  sum of phi  count / T  sin(pi x) = 0, x = 0..T");
    let mut c100 = 0;
    for t in [100i64, 10000, 1000000] {
        let form = 1 + (1..=t).take_while(|b| b * b <= t).map(phi).sum::<i64>();
        if t == 100 { c100 = form; }
        println!("{:>7}  {:>20}  {:>10}  {:.4}  {:>8}", t, if t == 100 { grid.to_string() } else { "-".to_string() }, form, form as f64 / t as f64, t + 1);
        assert!((form as f64 / t as f64 - 3.0 / (PI * PI)).abs() < 0.03);
    }
    assert!(grid == c100); // the grid search against the totient sum
    let y = rats(25, 1, 2); // every y = p/r in [1, 2] of height <= 25; p^b <= 25^25 < 2^128, and an overflowing side is larger
    let two: Vec<(i64, i64, i64, i64)> = x.iter().filter(|&&(_, b)| b <= 25).flat_map(|&(a, b)| y.iter().map(move |&(p, r)| (a, b, p, r)))
        .filter(|&(a, b, p, r)| Some((p as u128).pow(b as u32)) == (r as u128).checked_pow(b as u32).and_then(|v| v.checked_mul(1u128 << a))).collect();
    println!("y = 2^x on [0, 1], every rational (x, y) of height <= 25 tested by y^b = 2^a: {} points, x = 0 and 1; 3/pi^2 = {:.4}", two.len(), 3.0 / PI.powf(2.0));
    assert!(two == vec![(0, 1, 1, 1), (1, 1, 2, 1)]);
    println!("ALL CHECKS PASS");
}
