// Polynomials behave like integers -- the same check as the Python, in Rust.  No
// crates.  A polynomial is a list of whole-number coefficients, constant term
// first: [-6, 11, -6, 1] is x^3 - 6x^2 + 11x - 6 and [] is the zero polynomial.
// Every divisor here has leading coefficient 1, so whole numbers do; in general a field's fractions are needed.
fn trim(mut p: Vec<i64>) -> Vec<i64> {         // drop zero top coefficients
    while p.last() == Some(&0) { p.pop(); }
    p
}
fn show(p: &[i64]) -> String {                 // write a polynomial the way the card does
    let mut out = String::from(if p.is_empty() { "0" } else { "" });
    for k in (0..p.len()).rev() {
        let (c, a) = (p[k], p[k].abs());
        if c == 0 { continue; }
        out.push_str(if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " });
        if !(a == 1 && k > 0) { out.push_str(&a.to_string()); }
        out.push_str(&if k == 0 { String::new() } else if k == 1 { "x".to_string() } else { format!("x^{}", k) });
    }
    out
}
fn value(p: &[i64], t: i64) -> i64 {           // what the polynomial comes to at x = t
    let mut s = 0;
    for (k, &c) in p.iter().enumerate() { s += c * t.pow(k as u32); }
    s
}
fn divide(f: &[i64], g: &[i64]) -> (Vec<i64>, Vec<i64>) {   // long division, a top term at a time
    assert!(!g.is_empty() && *g.last().unwrap() == 1);      // the step needs 1 over the top coefficient
    let mut q = vec![0i64; if f.len() >= g.len() { f.len() - g.len() + 1 } else { 0 }];
    let mut r = f.to_vec();
    while !r.is_empty() && r.len() >= g.len() {
        let (k, c) = (r.len() - g.len(), *r.last().unwrap());
        q[k] = c;
        for (j, t) in g.iter().enumerate() { r[k + j] -= c * t; }
        r = trim(r);
    }
    (trim(q), r)
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }   // whole-number Euclid
fn primitive(p: &[i64]) -> Vec<i64> {          // strip the shared whole-number constant
    let mut d = 0;
    for &c in p { d = gcd(d, c); }
    let s = if *p.last().unwrap() < 0 { -1 } else { 1 };
    p.iter().map(|&c| s * c / d).collect()
}
fn euclid(f0: &[i64], g0: &[i64]) -> (Vec<i64>, Vec<String>) {   // road one: divide, keep the remainder
    let (mut f, mut g, mut steps) = (f0.to_vec(), g0.to_vec(), Vec::new());
    while !g.is_empty() {
        let (q, r) = divide(&f, &g);
        steps.push(format!("{} = ({})({}) + {}", show(&f), show(&q), show(&g), show(&r)));
        f = g;
        g = if r.is_empty() { Vec::new() } else { primitive(&r) };
    }
    (f, steps)
}
fn main() {
    let (f, g) = (vec![-6i64, 11, -6, 1], vec![-1i64, 0, 1]);
    let (twog, root2) = (vec![-2i64, 0, 2], vec![-2i64, 0, 1]);
    let (q1, r1) = divide(&f, &g);
    let (h, steps) = euclid(&f, &g);
    let rf: Vec<i64> = (-9..=9).filter(|&t| value(&f, t) == 0).collect();   // road two: hunt the roots
    let rg: Vec<i64> = (-9..=9).filter(|&t| value(&g, t) == 0).collect();
    let rh: Vec<i64> = (-9..=9).filter(|&t| value(&h, t) == 0).collect();
    let shared: Vec<i64> = rf.iter().cloned().filter(|t| rg.contains(t)).collect();
    println!("f = {}, degree {}; g = {}, degree {}", show(&f), f.len() - 1, show(&g), g.len() - 1);
    for (i, s) in steps.iter().enumerate() { println!("Euclid step {}: {}", i + 1, s); }
    println!("last nonzero remainder, made monic: {}, degree {}", show(&h), h.len() - 1);
    println!("whole-number roots -- f: {:?}, g: {:?}, shared: {:?}, gcd: {:?}", rf, rg, shared, rh);
    println!("f divided by {}: {}, remainder {}; g divided by {}: {}, remainder {}", show(&h),
             show(&divide(&f, &h).0), show(&divide(&f, &h).1), show(&h), show(&divide(&g, &h).0), show(&divide(&g, &h).1));
    println!("the same loop on whole numbers: 84 = {} x 36 + {}, 36 = {} x 12 + {}, gcd {}", 84 / 36, 84 % 36, 36 / 12, 36 % 12, gcd(84, 36));
    println!("stopping at the first quotient {}: remainder {}, not 0", show(&q1), show(&r1));
    println!("x + 1 divides g, so try it on f: remainder {}, and f(-1) = {}", show(&divide(&f, &[1, 1]).1), value(&f, -1));
    println!("constants are units: {} strips to {}, {} strips to {}", show(&twog), show(&primitive(&twog)), show(&r1), show(&primitive(&r1)));
    let vals: Vec<i64> = [-2, -1, 1, 2].iter().map(|&t| value(&root2, t)).collect();
    println!("{} at x = -2, -1, 1, 2: {:?}, no whole-number root", show(&root2), vals);
    assert!((-4..=4).all(|t| value(&f, t) == value(&q1, t) * value(&g, t) + value(&r1, t)));
    assert!((-4..=4).all(|t| value(&f, t) == (t - 1) * (t - 2) * (t - 3)));
    assert!(rh == shared && h.len() - 1 == shared.len() && *h.last().unwrap() == 1 && primitive(&r1) == h);
    assert!(divide(&f, &[1, 1]).1 == vec![value(&f, -1)] && value(&f, -1) != 0);
    println!("ALL CHECKS PASS");
}
