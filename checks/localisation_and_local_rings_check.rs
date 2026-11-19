// Localisation and local rings -- the same check as the Python, in Rust.  No
// crates; every number is an exact integer.  The field is Q, the rational
// numbers.  R = Q[x], f = x^3 - x^2, and we invert every g with g(0) != 0.
// Roads: orders of vanishing by a binomial shift and by synthetic division;
// their sum against the degree; and finite copies over F_3 and in Z/12, where
// every fraction a/s is sorted into classes by brute force.
type Table = Vec<Vec<usize>>;

fn show(p: &[i64]) -> String {                 // leading term first, as on the card
    let mut out = String::new();
    for k in (0..p.len()).rev() {
        let c = p[k];
        if c == 0 { continue }
        let mut body = if c.abs() == 1 && k > 0 { String::new() } else { c.abs().to_string() };
        if k > 0 { body.push('x') }
        if k > 1 { body += &format!("^{}", k) }
        let sign = if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " };
        out += sign;
        out += &body;
    }
    if out.is_empty() { "0".to_string() } else { out }
}

fn mul(p: &[i64], q: &[i64]) -> Vec<i64> {
    let mut out = vec![0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { out[i + j] += a * b } }
    out
}

fn value(p: &[i64], a: i64) -> i64 { p.iter().enumerate().map(|(k, c)| c * a.pow(k as u32)).sum() }

fn choose(n: i64, k: i64) -> i64 { let mut out = 1; for i in 0..k { out = out * (n - i) / (i + 1) } out }

fn order_by_shift(p: &[i64], a: i64) -> usize {  // road one: expand f(x + a), count the zero coefficients at the bottom
    let shifted: Vec<i64> = (0..p.len()).map(|k| (k..p.len())
        .map(|j| p[j] * choose(j as i64, k as i64) * a.pow((j - k) as u32)).sum()).collect();
    let mut n = 0;
    while shifted[n] == 0 { n += 1 }
    n
}

fn order_by_division(p: &[i64], a: i64) -> usize {  // road two: divide by (x - a) while the remainder is 0
    let (mut n, mut p) = (0, p.to_vec());
    while p.len() > 1 {
        let (mut q, mut carry) = (vec![0; p.len() - 1], 0);
        for k in (1..p.len()).rev() { carry = p[k] + a * carry; q[k - 1] = carry }
        if p[0] + a * carry != 0 { break }
        n += 1;
        p = q;
    }
    n
}

struct Ring { n: usize, add: Table, mul: Table, neg: Vec<usize> }

impl Ring {
    fn same(&self, s_set: &[usize], a: usize, s: usize, b: usize, t: usize) -> bool {
        let d = self.add[self.mul[a][t]][self.neg[self.mul[b][s]]];
        s_set.iter().any(|&u| self.mul[u][d] == 0)
    }
    // road three: sort every pair (a, s) by u(a t - b s) = 0
    fn classes(&self, s_set: &[usize]) -> (Vec<(usize, usize)>, usize, bool) {
        let mut reps: Vec<(usize, usize)> = Vec::new();
        for a in 0..self.n { for &s in s_set {
            if !reps.iter().any(|&(b, t)| self.same(s_set, a, s, b, t)) { reps.push((a, s)) }
        } }
        let units: Vec<usize> = (0..self.n).filter(|&a| (0..self.n).any(|b| self.same(s_set, self.mul[a][b], 1, 1, 1))).collect();
        let non: Vec<usize> = (0..self.n).filter(|a| !units.contains(a)).collect();
        let unit_classes = reps.iter().filter(|(b, _)| units.contains(b)).count();
        let local = non.iter().all(|&a| non.iter().all(|&b| non.contains(&self.add[a][b])));
        (reps, unit_classes, local)
    }
}

fn ring_z(m: usize) -> Ring {
    Ring { n: m, add: (0..m).map(|a| (0..m).map(|b| (a + b) % m).collect()).collect(),
           mul: (0..m).map(|a| (0..m).map(|b| a * b % m).collect()).collect(), neg: (0..m).map(|a| (m - a) % m).collect() }
}

fn ix(c: &[i64]) -> usize { (c[0].rem_euclid(3) + 3 * c[1].rem_euclid(3) + 9 * c[2].rem_euclid(3)) as usize }

fn ring_f3() -> (Vec<[i64; 3]>, Ring) {         // F_3[x] / <x^3 - x^2>: index c0 + 3 c1 + 9 c2; x^3 = x^2 there
    let co: Vec<[i64; 3]> = (0..27).map(|i| [i % 3, i / 3 % 3, i / 9]).collect();
    let add = (0..27).map(|a| (0..27).map(|b| ix(&[co[a][0] + co[b][0], co[a][1] + co[b][1], co[a][2] + co[b][2]])).collect()).collect();
    let mt = (0..27).map(|a| (0..27).map(|b| { let d = mul(&co[a], &co[b]); ix(&[d[0], d[1], d[2] + d[3] + d[4]]) }).collect()).collect();
    let neg = (0..27).map(|a| ix(&[-co[a][0], -co[a][1], -co[a][2]])).collect();
    (co, Ring { n: 27, add, mul: mt, neg })
}

fn ok(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn at(p: i64, q: i64) -> String {               // f(p/q) = (p^3 - p^2 q)/q^3, in lowest terms
    let (a, b) = (p.pow(3) - p * p * q, q.pow(3));
    let (mut g, mut h) = (a.abs(), b);
    while h != 0 { (g, h) = (h, g % h) }
    if q > 1 { format!("({}/{}, {}/{})", p, q, a / g, b / g) } else { format!("({}, {})", p, a / g) }
}

fn main() {
    let f: Vec<i64> = vec![0, 0, -1, 1];
    let o0 = (order_by_shift(&f, 0), order_by_division(&f, 0));
    let o1 = (order_by_shift(&f, 1), order_by_division(&f, 1));
    let others: Vec<usize> = [-1, 2].iter().map(|&a| order_by_division(&f, a)).collect();
    println!("field Q; R = Q[x]; f = {}; S = all g with g(0) != 0", show(&f));
    println!("f = x^2 * ({}); the factor {} has value {} at 0, so it is a unit", show(&[-1, 1]), show(&[-1, 1]), value(&[-1, 1], 0));
    println!("order of f at 0: by shifting {}, by dividing {}", o0.0, o0.1);
    println!("order of f at 1: by shifting {}, by dividing {}", o1.0, o1.1);
    println!("order of f at -1 and at 2: {} and {}", others[0], others[1]);
    println!("local orders {} + {} = {}; degree of f = {}", o0.0, o1.0, o0.0 + o1.0, f.len() - 1);
    let shift1: Vec<i64> = (0..4).map(|k| (k..4).map(|j| f[j] * choose(j as i64, k as i64)).sum()).collect();
    println!("f(x + 1) = {}; values at 0 of x - 1, x^2 - 2, x^2 + 1: {}, {}, {}, so those points leave",
             show(&shift1), value(&[-1, 1], 0), value(&[-2, 0, 1], 0), value(&[1, 0, 1], 0));
    println!("in Z_(2), 1/3 reads {} mod 2; in Z[1/10], 4.95 = {}/{}", (0..2).find(|b| 3 * b % 2 == 1).unwrap(), 495, 10i64.pow(2));
    let (lhs, rhs) = (mul(&[0, -1, 1], &[1, 1]), mul(&[0, 1], &[-1, 0, 1]));
    println!("(x^2 - x)/(x^2 - 1) against x/(x + 1): cross products {} and {}", show(&lhs), show(&rhs));
    println!("(x + 2)/(x - 1) has value {} at 0: a unit; times (x - 1)/(x + 2) gives {} over {}",
             value(&[2, 1], 0) / value(&[-1, 1], 0), show(&mul(&[2, 1], &[-1, 1])), show(&mul(&[-1, 1], &[2, 1])));
    println!("x/(x + 1) has value {} at 0: in the maximal ideal, no inverse", value(&[0, 1], 0));
    println!("x^2 = f/(x - 1) in R_m, since x^2 * (x - 1) = {}; x has order {} < 2, so x is not a multiple of f there",
             show(&mul(&[0, 0, 1], &[-1, 1])), order_by_division(&[0, 1], 0));
    let (co, r) = ring_f3();
    let s0: Vec<usize> = (0..27).filter(|&a| co[a][0] != 0).collect();
    let s1: Vec<usize> = (0..27).filter(|&a| (co[a][0] + co[a][1] + co[a][2]) % 3 != 0).collect();
    let (reps0, u0, loc0) = r.classes(&s0);
    let (reps1, u1, loc1) = r.classes(&s1);
    let (_, ur, locr) = r.classes(&[1]);
    println!("finite copy F_3[x]/<f>: 27 elements; at 0: {} denominators, {} pairs, {} classes", s0.len(), 27 * s0.len(), reps0.len());
    println!("at 1: {} denominators, {} classes; {} x {} = {}", s1.len(), reps1.len(), reps0.len(), reps1.len(), reps0.len() * reps1.len());
    println!("units: R {} of 27, at 0 {} of {}, at 1 {} of {}", ur, u0, reps0.len(), u1, reps1.len());
    println!("non-units closed under addition (local): R {}, at 0 {}, at 1 {}", ok(locr), ok(loc0), ok(loc1));
    let z = ring_z(12);
    let odd = [1, 3, 5, 7, 9, 11];
    let (repz, uz, locz) = z.classes(&odd);
    println!("Z/12 with the odd numbers inverted: {} classes, {} unit classes, local {}", repz.len(), uz, ok(locz));
    let cross = |a: usize, s: usize, b: usize, t: usize| (a * t + 144 - b * s % 12) % 12 == 0;
    let mut bad: Vec<(usize, usize, usize, usize)> = Vec::new();
    for a in 0..12 { for &s in &odd { for b in 0..12 { for &t in &odd {
        if cross(a, s, b, t) && cross(b, t, 0, 1) && !cross(a, s, 0, 1) { bad.push((a, s, b, t)) }
    } } } }
    let (a, s, b, t) = bad[0];
    println!("mistake 1, cross-multiplying only: ({}, {}) ~ ({}, {}) ~ (0, 1) but ({}, {}) is not ~ (0, 1); the u-test: {}",
             a, s, b, t, a, s, ok(z.same(&odd, a, s, 0, 1)));
    println!("mistake 2, inverting a set that holds 0: {} class", z.classes(&[0, 1]).0.len());
    println!("mistake 3, counting the whole ring: 27 elements = 3^3, against {} = 3^2 at the origin", reps0.len());
    let in_s = |p: &[i64]| value(p, 0) != 0 || value(p, 1) != 0;   // outside <x(x - 1)>
    println!("mistake 4, complement of <x(x - 1)>: x in it {}, x - 1 in it {}, x(x - 1) in it {}",
             ok(in_s(&[0, 1])), ok(in_s(&[-1, 1])), ok(in_s(&mul(&[0, 1], &[-1, 1]))));
    println!("figure, y = x^3 - x^2 from {} to {}; touches {}; crosses {}; dips to {}", at(-3, 4), at(3, 2), at(0, 1), at(1, 1), at(2, 3));
    assert!(o0 == (2, 2) && o1 == (1, 1) && others == vec![0, 0]);       // two roads to each order
    assert!(o0.0 + o1.0 == f.len() - 1);                                 // local orders add up to the degree
    assert!(lhs == rhs && mul(&[0, 0, 1], &[-1, 1]) == f);
    assert!(reps0.len() == 9 && reps1.len() == 3 && reps0.len() * reps1.len() == 27);  // brute force against x^2 and x - 1
    assert!((ur, u0, u1, locr, loc0, loc1) == (12, 6, 2, false, true, true));
    assert!((repz.len(), uz, locz) == (4, 2, true) && z.same(&odd, 4, 1, 0, 1) && bad[0] == (4, 1, 0, 3));
    println!("ALL CHECKS PASS");
}
