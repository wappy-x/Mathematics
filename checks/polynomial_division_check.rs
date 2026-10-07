// Polynomial long division -- the same check as the Python, in Rust.  No crates.  A box holds
// x^3 + 6x^2 + 11x + 6 cubic cm, edge x + 1 cm.  Highest power first; both divisors start with 1.
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
fn row(v: &[i64]) -> String { v.iter().map(|n| format!("{:>4}", n)).collect() }
fn main() {
    let (p, d, e) = ([1i64, 6, 11, 6], [1i64, 1], [1i64, -2]);   // volume, x + 1, x - 2
    let (q, s, steps) = divide(&p, &d);       // one road: divide by the edge x + 1
    let (q2, s2, _) = divide(&p, &e);         // the same box divided by x - 2
    line("p(x), the volume", &show(&p));
    line("d(x), the edge", &show(&d));
    line("leftovers as the loop runs", &steps.join(" | "));
    line("q(x), the cross-section", &show(&q));
    line("s(x), the remainder", &show(&s));
    line("d(x) q(x) + s(x)", &show(&add(&mul(&d, &q), &s)));
    line("(x + 2)(x + 3) multiplied out", &show(&mul(&[1, 2], &[1, 3])));
    line("p(-1), at the root of x + 1", &value(&p, -1).to_string());
    println!("at x = 2 the box is {} by {} by {}, volume {}",
             value(&d, 2), value(&[1, 2], 2), value(&[1, 3], 2), value(&p, 2));
    let ten = value(&d, 10);                  // second road: plain numbers
    println!("at x = 10 the box is {} by {} by {}: {} / {} = {} remainder {}",
             ten, value(&[1, 2], 10), value(&[1, 3], 10), value(&p, 10), ten,
             value(&p, 10) / ten, value(&p, 10) % ten);
    line("divide p(x) by x - 2", &format!("{}   remainder {}", show(&q2), show(&s2)));
    line("p(2), at the root of x - 2", &value(&p, 2).to_string());
    let roots: Vec<i64> = (-3..4).collect();
    let rems: Vec<i64> = roots.iter().map(|&r| divide(&p, &[1, -r]).1[0]).collect();
    let vals: Vec<i64> = roots.iter().map(|&r| value(&p, r)).collect();
    line("r", &row(&roots));
    line("remainder, dividing by x - r", &row(&rems));
    line("p(r)", &row(&vals));
    let mut part = q[..2].to_vec(); part.push(0);
    println!("stopping a step early: quotient {}, leftover {}", show(&part), steps[1]);
    println!("dropping the remainder 60 leaves {} at x = 2; the root of x + 1 read as 1 \
              gives p(1) = {}", value(&mul(&q2, &e), 2), value(&p, 1));
    assert!(q == mul(&[1, 2], &[1, 3]) && s == [0]);   // the cross-section, from the factors
    assert!(add(&mul(&d, &q), &s) == p && add(&mul(&e, &q2), &s2) == p);
    assert!(rems == vals);
    assert!(value(&p, 10) == 1716 && value(&p, 10) / ten == value(&q, 10) && value(&p, 10) % ten == 0);
    println!("ALL CHECKS PASS");
}
