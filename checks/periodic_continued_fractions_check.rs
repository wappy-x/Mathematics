// Periodic continued fractions -- the same check in Rust, no crates.  Road one: flip-and-peel run exactly on
// (P + root D)/Q in whole numbers.  Road two: the repeating block solved as a quadratic.  Road three: 13,228 starts swept.
fn isqrt(n: i64) -> i64 { let r = (n as f64).sqrt() as i64; r - (r * r > n) as i64 + ((r + 1) * (r + 1) <= n) as i64 }
fn run(mut p: i64, mut q: i64, d: i64) -> (Vec<i64>, Vec<(i64, i64)>, usize) {   // steps and pairs until a pair comes back
    let (mut seen, mut steps) = (Vec::new(), Vec::new());
    while !seen.contains(&(p, q)) {   // whole part a of (P + root D)/Q, then the new pair
        seen.push((p, q)); let r = isqrt(d * q * q); let a = (p * q + if q > 0 { r } else { -r - 1 }).div_euclid(q * q); steps.push(a); p = a * q - p; q = (d - p * p) / q; }
    let k = seen.iter().position(|&s| s == (p, q)).unwrap(); (steps, seen, k)   // the loop starts at step k
}
fn stops(steps: &[i64]) -> Vec<(i64, i64)> {     // top/bottom pairs, built as on Continued fractions
    let (mut p, mut pb, mut q, mut qb, mut out) = (1, 0, 0, 1, vec![]);
    for &a in steps { (p, pb, q, qb) = (a * p + pb, p, a * q + qb, q); out.push((p, q)); } out
}
fn euler(front: &[i64], block: &[i64]) -> (i64, i64, i64, f64) {   // q y^2 + (qb - p) y - pb = 0
    let s = [vec![(1, 0)], stops(block)].concat(); let ((pb, qb), (p, q)) = (s[s.len() - 2], s[s.len() - 1]);
    let (a2, b, c) = (q, qb - p, -pb); let mut y = (-b as f64 + ((b * b - 4 * a2 * c) as f64).sqrt()) / (2 * a2) as f64;
    for &a in front.iter().rev() { y = a as f64 + 1.0 / y; } (a2, b, c, y)
}
fn fr(v: &[(i64, i64)]) -> String { v.iter().map(|(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(" ") }
fn main() {
    for (name, p, q, d) in [("golden ratio", 1, 2, 5), ("(1 + root 3)/2", 1, 2, 3), ("root 7", 0, 1, 7), ("root 2", 0, 1, 2)] {
        let (st, _, k) = run(p, q, d); let (a2, b, c, y) = euler(&st[..k], &st[k..]); let (x, disc) = ((p as f64 + (d as f64).sqrt()) / q as f64, b * b - 4 * a2 * c);
        let shown: Vec<String> = (0..9).map(|i| if i < k { st[i] } else { st[k + (i - k) % (st.len() - k)] }.to_string()).collect();
        println!("{:<15}{}  repeat length {}  {}y^2 {:+}y {:+} = 0  {:.10} = {:.10}", name, shown.join(", "), st.len() - k, a2, b, c, x, y);
        assert!((x - y).abs() < 1e-12 && disc % d == 0 && isqrt(disc / d).pow(2) == disc / d);   // roads one and two agree
    }
    let (s7, g, r2, true_) = (stops(&[2, 1, 1, 1]), stops(&[1; 6]), stops(&[1, 2, 2, 2, 2, 2]), [vec![2], [1, 1, 1, 4].repeat(20)].concat());
    let pairs: Vec<String> = run(0, 1, 7).1.iter().chain([run(0, 1, 7).1[1]].iter()).map(|t| format!("{:?}", t)).collect();
    println!("root 7 pairs (P, Q): {} ...  stops {}  {}^2 - 7 x {}^2 = {}", pairs.join(" "), fr(&s7), s7[3].0, s7[3].1, s7[3].0.pow(2) - 7 * s7[3].1.pow(2));
    let a4: Vec<(i64, i64)> = r2.iter().cloned().filter(|&(p, q)| p * 210 == q * 297).collect();
    println!("golden stops {}   root 2 stops {}  A4 297/210 = {}", fr(&g), fr(&r2), fr(&a4));
    let mut runs = vec![]; for d in (2..101).filter(|&d| isqrt(d).pow(2) != d) { for p in -12..13 { for q in (-12..13).filter(|&q| q != 0 && (d - p * p) % q == 0) { runs.push((d, run(p, q, d))); } } }
    let inbox = runs.iter().all(|(d, (_, seen, k))| seen[*k..].iter().all(|&(p, q)| 0 < q && q <= *d && p * p < *d));   // the proof's box
    println!("starts tried {}, every one repeats, longest wait {} steps, longest loop {}, loop pairs in the box: {}", runs.len(), runs.iter().map(|r| r.1 .2).max().unwrap(), runs.iter().map(|r| r.1 .0.len() - r.1 .2).max().unwrap(), if inbox { "True" } else { "False" });
    let (mut x, mut n) = (7f64.sqrt(), 0); while x as i64 == true_[n] { x = 1.0 / (x - (x as i64) as f64); n += 1; }   // the same flip-and-peel on a decimal
    println!("mistakes: block 2, 1, 1, 1 gives {:.4}; other root {:.4}; decimals go wrong at flip {}: {}, not {}", euler(&[], &[2, 1, 1, 1]).3, (1.0 - 5f64.sqrt()) / 2.0, n, x as i64, true_[n]);
    assert!(inbox && s7[3].0.pow(2) - 7 * s7[3].1.pow(2) == 1 && g.iter().all(|&(p, q)| (p * p - p * q - q * q).abs() == 1));
    println!("ALL CHECKS PASS");
}
