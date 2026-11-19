// Algebraic integers in Q(sqrt d): a number a + b*sqrt(d) is stored as the pair (a, b) of fractions.
use std::fmt;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 } // a fraction in lowest terms, denominator positive

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
impl Q {
    fn add(self, o: Q) -> Q {
        q(self.n.checked_mul(o.d).unwrap().checked_add(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap())
    }
    fn mul(self, o: Q) -> Q { q(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) }
    fn neg(self) -> Q { Q { n: -self.n, d: self.d } }
    fn abs(self) -> Q { Q { n: self.n.abs(), d: self.d } }
    fn whole(self) -> bool { self.d == 1 }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
type E = (Q, Q);

fn mul(x: E, y: E, d: i128) -> E {
    (x.0.mul(y.0).add(z(d).mul(x.1).mul(y.1)), x.0.mul(y.1).add(x.1.mul(y.0)))
}
fn show(cs: &[Q]) -> String {
    // A polynomial, highest power first, written out: [1, -2, 6] -> x^2 - 2x + 6.
    let (mut out, n) = (String::new(), cs.len() - 1);
    for (i, &c) in cs.iter().enumerate() {
        let e = n - i;
        if c.n == 0 { continue; }
        let mono = if e == 0 { String::new() } else if e == 1 { "x".to_string() } else { format!("x^{}", e) };
        let a = c.abs();
        let num = if e > 0 && a == z(1) { String::new() } else if e > 0 && a.d > 1 { format!("({})", a) } else { a.to_string() };
        let sign = if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        out += &format!("{}{}{}", sign, num, mono);
    }
    out
}
fn root_of(cs: &[Q], x: E, d: i128) -> bool {
    // Road 2's tool: evaluate a polynomial (highest power first) at x exactly, by Horner's rule.
    let mut acc = (z(0), z(0));
    for &c in cs { acc = mul(acc, x, d); acc = (acc.0.add(c), acc.1); }
    acc == (z(0), z(0))
}
fn minpoly(a: Q, b: Q, d: i128) -> Vec<Q> {
    // Road 1: the monic minimal polynomial over Q, from (x - a)^2 = d b^2.
    if b.n == 0 { return vec![z(1), a.neg()]; }
    vec![z(1), z(-2).mul(a), a.mul(a).add(z(-d).mul(b).mul(b))]
}
fn road1(a: Q, b: Q, d: i128) -> bool { minpoly(a, b, d).iter().all(|c| c.whole()) }
fn search(x: E, d: i128, deg: usize, h: i128) -> Vec<Vec<Q>> {
    // Road 2: every monic integer polynomial of degree 1..deg, coefficients -h..h, with x as a root.
    let mut found = vec![];
    for n in 1..=deg {
        let w = (2 * h + 1) as usize;
        for code in 0..w.pow(n as u32) {
            let mut cs = vec![z(1)];
            let mut k = code;
            let mut tail = vec![];
            for _ in 0..n { tail.push(z((k % w) as i128 - h)); k /= w; }
            tail.reverse();
            cs.extend(tail);
            if root_of(&cs, x, d) { found.push(cs); }
        }
    }
    found
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn zs(v: &[i128]) -> Vec<Q> { v.iter().map(|&n| z(n)).collect() }

fn main() {
    let dd = -5;
    let (r5, half) = ((z(0), z(1)), (z(0), q(1, 2)));
    println!("the field Q(sqrt -5): generator sqrt(-5), basis 1, sqrt(-5)");
    for (name, (a, b)) in [("sqrt(-5)", r5), ("sqrt(-5)/2", half), ("1 + sqrt(-5)", (z(1), z(1)))] {
        let m = minpoly(a, b, dd);
        println!("{}: minimal polynomial {}, degree {}, algebraic integer {}", name, show(&m), m.len() - 1, tf(road1(a, b, dd)));
    }
    assert!(road1(r5.0, r5.1, dd) && !road1(half.0, half.1, dd));
    let mut p = (z(1), z(0));
    let mut pw = vec![];
    for _ in 0..5 { pw.push(p); p = mul(p, r5, dd); }
    println!("powers of sqrt(-5) as (a, b): {}", pw.iter().map(|(a, b)| format!("({}, {})", a, b)).collect::<Vec<_>>().join(", "));
    assert!(pw[2] == (z(-5), z(0)) && pw[3] == (z(0), z(-5)), "sqrt(-5)^2 = -5 keeps every power in degree 2");

    // Road 2: brute-force search, degree up to 4, coefficients -H..H
    let h = 6;
    let (f5, fh) = (search(r5, dd, 4, h), search(half, dd, 4, h));
    println!("monic integer polys, degree <= 4, coefficients -{}..{}: {} have root sqrt(-5), {} have root sqrt(-5)/2", h, h, f5.len(), fh.len());
    println!("  the shortest one for sqrt(-5): {}", show(f5.iter().min_by_key(|c| c.len()).unwrap()));
    let small = (2 * (h / 5) + 1) as usize; // 5*c0 and 5*c1 must stay within -H..H
    let predicted = small * small + small + 1; // (x^2+5)(x^2+c1*x+c0), (x^2+5)(x+c0), x^2+5
    println!("  predicted from multiples of x^2 + 5: 1 + {} + {} = {}", small, small * small, predicted);
    assert!(f5.len() == predicted && fh.is_empty(), "every hit is a multiple of x^2 + 5; the half has none");
    let sq = mul(half, half, dd);
    let hits = search(sq, dd, 3, 6);
    println!("(sqrt(-5)/2)^2 = {}; monic integer polys, degree <= 3, coefficients -6..6, with that root: {}", sq.0, hits.len());
    assert!(sq == (q(-5, 4), z(0)) && hits.is_empty());

    // The grid: a, b in quarters from -2 to 2, so 289 numbers a + b*sqrt(d)
    let grid: Vec<Q> = (-8..=8).map(|k| q(k, 4)).collect();
    let mut polys: Vec<Vec<Q>> = (-2..=2).map(|c| zs(&[1, c])).collect();
    for p_ in -4..=4 { for c in -24..=24 { polys.push(zs(&[1, p_, c])); } }
    for d in [-5i128, 5] {
        let (mut r1, mut r2, mut coords) = (vec![], vec![], 0);
        for &a in &grid { for &b in &grid {
            if road1(a, b, d) { r1.push((a, b)); }
            if polys.iter().any(|c| root_of(c, (a, b), d)) { r2.push((a, b)); }
            if a.whole() && b.whole() { coords += 1; }
        } }
        println!("d = {}: grid {} x {} = {}, road 1 (minimal polynomial) {}, road 2 (search) {}, whole a and b {}, extra {}",
                 d, grid.len(), grid.len(), grid.len() * grid.len(), r1.len(), r2.len(), coords, r1.len() - coords);
        assert_eq!(r1, r2);
        assert!((r1.len() == coords) == (d == -5), "Z[sqrt -5] is everything for d = -5, not for d = 5");
    }
    let phi = (q(1, 2), q(1, 2));
    println!("golden ratio (1 + sqrt 5)/2: minimal polynomial {}, algebraic integer {}", show(&minpoly(phi.0, phi.1, 5)), tf(road1(phi.0, phi.1, 5)));

    // The house example: 6 two ways, and no proper split of 2, 3 or 1 + sqrt(-5) in a box
    println!("2 x 3 = {} ; (1 + sqrt-5)(1 - sqrt-5) = {}", mul((z(2), z(0)), (z(3), z(0)), dd).0, mul((z(1), z(1)), (z(1), z(-1)), dd).0);
    let mut bx = vec![];
    for a in -6..=6 { for b in -6..=6 { bx.push((z(a), z(b))); } }
    let unit = |x: &E| *x == (z(1), z(0)) || *x == (z(-1), z(0));
    for (name, t) in [("2", (z(2), z(0))), ("3", (z(3), z(0))), ("1 + sqrt(-5)", (z(1), z(1)))] {
        let mut pairs = vec![];
        for &x in &bx { for &y in &bx { if mul(x, y, dd) == t { pairs.push((x, y)); } } }
        let trivial = pairs.iter().all(|(x, y)| unit(x) || unit(y));
        println!("factor pairs of {} with |a|, |b| <= 6: {}, every one uses 1 or -1: {}", name, pairs.len(), tf(trivial));
        assert!(pairs.len() == 4 && trivial);
    }

    // What breaks
    let cleared = |a: Q, b: Q| -> Vec<Q> {
        // the minimal polynomial times the lcm of its denominators: integer, not monic
        let m = minpoly(a, b, dd);
        let k = m.iter().fold(1, |k, c| k * c.d / gcd(k, c.d));
        m.iter().map(|c| c.mul(z(k))).collect()
    };
    let mut nonmonic = 0;
    for &a in &grid { for &b in &grid {
        let c = cleared(a, b);
        if c.iter().all(|v| v.whole()) && root_of(&c, (a, b), dd) { nonmonic += 1; }
    } }
    println!("accept any integer polynomial, monic or not: grid numbers passing {}", nonmonic);
    let wrong = [z(1), q(-1, 2), z(5), q(-5, 2)]; // (x^2 + 5)(x - 1/2)
    println!("sqrt(-5) is a root of {}: {}; judged by it, not an integer", show(&wrong), tf(root_of(&wrong, r5, dd)));
    assert!(root_of(&wrong, r5, dd) && !wrong.iter().all(|c| c.whole()));
    let x4 = zs(&[1, 0, 0, 0, -25]);
    println!("degree read off x^4 - 25: {} ; true degree {}", x4.len() - 1, minpoly(r5.0, r5.1, dd).len() - 1);
    assert!(root_of(&x4, r5, dd) && nonmonic == grid.len() * grid.len());

    // The ring property at work: phi^n + (1 - phi)^n is rational, so it is whole (the Lucas numbers)
    let (mut x, mut y) = ((z(1), z(0)), (z(1), z(0)));
    for _ in 0..10 { x = mul(x, phi, 5); y = mul(y, (q(1, 2), q(-1, 2)), 5); }
    let s = (x.0.add(y.0), x.1.add(y.1));
    let mut lucas = vec![2i128, 1];
    while lucas.len() < 11 { let n = lucas.len(); lucas.push(lucas[n - 1] + lucas[n - 2]); }
    println!("phi^10 + (1 - phi)^10 = {} + {} sqrt 5; the whole-number recurrence 2, 1, 3, 4, ... gives {}", s.0, s.1, lucas[10]);
    assert!(s == (z(lucas[10]), z(0)));
    println!("figure, sqrt(-5) at (0, {:.6}), sqrt(-5)/2 at (0, {:.6})", 5f64.sqrt(), 5f64.sqrt() / 2.0);
    println!("ALL CHECKS PASS");
}
