// Polynomial long division -- the same check as the Python, in Rust.  No crates.  An open tray
// folded from a 30 by 20 cm card, after cutting an x cm square from each corner, holds
// x(30 - 2x)(20 - 2x) cubic cm: one litre where p(x) = 4x^3 - 100x^2 + 600x - 1000 is zero.
fn show(c: &[i64]) -> String {                // coefficients back into readable form
    let mut out = String::new();
    for (i, &a) in c.iter().enumerate() {
        let k = c.len() - 1 - i;              // the power this coefficient sits on
        if a == 0 { continue; }
        let mut t = String::new();
        if !(a.abs() == 1 && k > 0) { t += &a.abs().to_string(); }
        if k > 0 { t.push('x'); }
        if k > 1 { t += &format!("^{}", k); }
        if out.is_empty() { out = if a < 0 { format!("-{}", t) } else { t }; }
        else { out += if a > 0 { " + " } else { " - " }; out += &t; }
    }
    if out.is_empty() { "0".to_string() } else { out }
}
fn divide(p: &[i64], d: &[i64]) -> (Vec<i64>, Vec<i64>, Vec<String>) {
    let (mut q, mut s, mut steps) = (Vec::new(), p.to_vec(), Vec::new());
    while s.len() >= d.len() {                // long division, one leading term a step
        let c = s[0] / d[0];                  // the term that kills the leading term
        q.push(c);
        for i in 0..d.len() { s[i] -= c * d[i]; }
        s.remove(0);                          // the leading term is now zero: drop it
        steps.push(show(&s));
    }
    (q, s, steps)
}
fn value(p: &[i64], x: i64) -> i64 {          // the polynomial worked out at a number
    (0..p.len()).map(|i| p[i] * x.pow((p.len() - 1 - i) as u32)).sum()
}
fn mul(a: &[i64], b: &[i64]) -> Vec<i64> {    // multiply two polynomials back together
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, &u) in a.iter().enumerate() {
        for (j, &w) in b.iter().enumerate() { out[i + j] += u * w; }
    }
    out
}
fn add(a: &[i64], b: &[i64]) -> Vec<i64> {
    let mut out = a.to_vec();                 // b is the shorter one: line up the ends
    for (i, &w) in b.iter().enumerate() { out[a.len() - b.len() + i] += w; }
    out
}
fn line(name: &str, text: &str) { println!("{:<30}{}", name, text); }
fn row(v: &[i64]) -> String { v.iter().map(|n| format!("{:>6}", n)).collect() }
fn main() {
    let (p, d, e) = ([4i64, -100, 600, -1000], [1i64, -5], [1i64, -4]);   // p, x - 5, x - 4
    let (q, s, steps) = divide(&p, &d);       // one road: divide by x - 5
    let (q2, s2, _) = divide(&p, &e);         // the same p divided by x - 4
    line("p(x), volume minus 1000", &show(&p));
    line("leftovers as the loop runs", &steps.join(" | "));
    line("q(x), the quotient", &show(&q));
    line("s(x), the remainder", &show(&s));
    line("d(x) q(x) + s(x)", &show(&add(&mul(&d, &q), &s)));
    println!("a 5 cm cut: 5 by {} by {} cm, volume {}", 30 - 2 * 5, 20 - 2 * 5, 5 * (30 - 2 * 5) * (20 - 2 * 5));
    let (a, b, disc) = (q[0] as f64, q[1] as f64, (q[1] * q[1] - 4 * q[0] * q[2]) as f64);   // the formula
    let (lo, hi) = ((-b - disc.sqrt()) / (2.0 * a), (-b + disc.sqrt()) / (2.0 * a));
    println!("q(x) = 0 at x = {:.2} and x = {:.2}; two {:.2} cm squares do not fit across 20 cm", lo, hi, hi);
    println!("a {:.2} cm cut: {:.2} by {:.2} by {:.2} cm, volume {:.2}",
             lo, lo, 30.0 - 2.0 * lo, 20.0 - 2.0 * lo, lo * (30.0 - 2.0 * lo) * (20.0 - 2.0 * lo));
    let p20 = value(&p, 20);                  // second road: plain numbers
    println!("at x = 20: p = {}, x - 5 = 15, {} / 15 = {} remainder {}, and q(20) = {}", p20, p20, p20 / 15, p20 % 15, value(&q, 20));
    line("divide p(x) by x - 4", &format!("{}   remainder {}", show(&q2), show(&s2)));
    line("p(4), at the root of x - 4", &value(&p, 4).to_string());
    let roots: Vec<i64> = (0..11).collect();
    let rems: Vec<i64> = roots.iter().map(|&r| divide(&p, &[1, -r]).1[0]).collect();
    let vals: Vec<i64> = roots.iter().map(|&r| value(&p, r)).collect();
    line("r", &row(&roots));
    line("remainder, dividing by x - r", &row(&rems));
    line("p(r)", &row(&vals));
    let mut part = q[..2].to_vec(); part.push(0);
    println!("stopping a step early: quotient {}, leftover {}", show(&part), steps[1]);
    println!("dropping the remainder 56 leaves {} at x = 4; the root of x - 5 read as -5 \
              gives p(-5) = {}", value(&mul(&q2, &e), 4), value(&p, -5));
    assert!(s == [0] && add(&mul(&d, &q), &s) == p && add(&mul(&e, &q2), &s2) == p);
    assert!(rems == vals);
    assert!(s2 == [56] && value(&p, 4) == 4 * 22 * 12 - 1000 && value(&p, -5) == -7000);
    assert!((lo * (30.0 - 2.0 * lo) * (20.0 - 2.0 * lo) - 1000.0).abs() < 1e-9 && 20.0 - 2.0 * hi < 0.0 && p20 == 15 * value(&q, 20));
    println!("ALL CHECKS PASS");
}
