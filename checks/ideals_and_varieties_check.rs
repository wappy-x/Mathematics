// Ideals and varieties -- the same check as the Python, in Rust.  No crates.
// Beacon A at (0, 0) reads 6 km; beacon B at (10, 0) reads 8 km.  A polynomial
// is a map {(i, j): coefficient of x^i y^j}, every coefficient an exact fraction.
use std::collections::BTreeMap;
use std::fmt;
const P: i128 = 101;                                // the clock for brute-force counts

#[derive(Clone, Copy, PartialEq, PartialOrd)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1) * d.signum();
    Q { n: n / g, d: d / g }
}
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Q {
    fn add(self, o: Q) -> Q { q(m(self.n, o.d).checked_add(m(o.n, self.d)).expect("overflow"), m(self.d, o.d)) }
    fn mul(self, o: Q) -> Q { q(m(self.n, o.n), m(self.d, o.d)) }
    fn pow(self, k: u32) -> Q { (0..k).fold(q(1, 1), |a, _| a.mul(self)) }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
type Poly = BTreeMap<(u32, u32), Q>;
fn add(ps: &[&Poly]) -> Poly {
    let mut out = Poly::new();
    for p in ps { for (k, c) in p.iter() { let e = out.entry(*k).or_insert(q(0, 1)); *e = e.add(*c); } }
    out.retain(|_, c| c.n != 0);
    out
}
fn mul(p: &Poly, r: &Poly) -> Poly {
    let mut out = Poly::new();
    for (&(a, b), c) in p { for (&(d, e), k) in r {
        let s = out.entry((a + d, b + e)).or_insert(q(0, 1)); *s = s.add(c.mul(*k));
    } }
    add(&[&out])
}
fn sc(k: Q, p: &Poly) -> Poly { add(&[&p.iter().map(|(t, c)| (*t, k.mul(*c))).collect()]) }
fn at(p: &Poly, x: Q, y: Q) -> Q { p.iter().fold(q(0, 1), |s, (&(i, j), c)| s.add(c.mul(x.pow(i)).mul(y.pow(j)))) }
fn mk(t: &[((u32, u32), i128)]) -> Poly { add(&[&t.iter().map(|&(k, c)| (k, q(c, 1))).collect()]) }
fn show(p: &Poly) -> String {                         // leading term first, x before y
    let mut s = String::new();
    for (&(i, j), c) in p.iter().rev() {
        let mono = format!("{}{}{}{}", if i > 0 { "x" } else { "" }, if i > 1 { format!("^{}", i) } else { String::new() },
                           if j > 0 { "y" } else { "" }, if j > 1 { format!("^{}", j) } else { String::new() });
        let a = q(c.n.abs(), c.d);
        let txt = format!("{}{}", if a != q(1, 1) || mono.is_empty() { a.to_string() } else { String::new() }, mono);
        let sign = if s.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        s += &format!("{}{}", sign, txt);
    }
    if s.is_empty() { "0".to_string() } else { s }
}
fn rem(p: &Poly, x: Q, y2: Q) -> Poly {                // divide by x - X and y^2 - Y2: a + b y is left
    let parts: Vec<Poly> = p.iter().map(|(&(i, j), c)| [((0, j % 2), c.mul(x.pow(i)).mul(y2.pow(j / 2)))].into()).collect();
    add(&parts.iter().collect::<Vec<_>>())
}
fn circle(cx: i128, r: i128) -> Poly { mk(&[((2, 0), 1), ((0, 2), 1), ((1, 0), -2 * cx), ((0, 0), cx * cx - r * r)]) }
fn mpow(b: i128, e: i128) -> i128 { (0..e).fold(1, |a, _| a * b.rem_euclid(P) % P) }
fn modp(c: Q) -> i128 { c.n.rem_euclid(P) * mpow(c.d, P - 2) % P }
fn count(ps: &[&Poly]) -> Vec<(i128, i128)> {        // every (x, y) on the 101-clock, tried
    let qs: Vec<Vec<((u32, u32), i128)>> = ps.iter().map(|p| p.iter().map(|(k, c)| (*k, modp(*c))).collect()).collect();
    let mut out = vec![];
    for x in 0..P { for y in 0..P {
        if qs.iter().all(|r| r.iter().map(|&((i, j), c)| c * mpow(x, i as i128) * mpow(y, j as i128)).sum::<i128>() % P == 0) {
            out.push((x, y));
        }
    } }
    out
}
fn fix(ra: i128, d: i128, rb: i128) -> (Poly, Q, Q) { // two roads to x and y^2 for two range circles
    let line = add(&[&circle(0, ra), &sc(q(-1, 1), &circle(d, rb))]);
    let c0 = line.get(&(0, 0)).copied().unwrap_or(q(0, 1));
    let x = q(-c0.n * line[&(1, 0)].d, c0.d * line[&(1, 0)].n);
    let y2 = q(0, 1).add(at(&circle(0, ra), x, q(0, 1)).mul(q(-1, 1)));
    assert!(x == q(d * d + ra * ra - rb * rb, 2 * d) && y2 == q(ra * ra, 1).add(x.mul(x).mul(q(-1, 1))));
    (line, x, y2)
}
struct Rng(u64);
impl Rng {                                          // SplitMix64, started from the seed
    fn rnd(&mut self, n: u64) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) % n
    }
    fn poly(&mut self, deg: u32) -> Poly {
        let mut t = vec![];
        for i in 0..=deg { for j in 0..=(deg - i) { t.push(((i, j), self.rnd(19) as i128 - 9)); } }
        mk(&t)
    }
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (x, y) = (mk(&[((1, 0), 1)]), mk(&[((0, 1), 1)]));
    let (f1, f2) = (circle(0, 6), circle(10, 8));
    let (line, xf, y2) = fix(6, 10, 8);
    let g1 = sc(q(1, 4), &line);
    let lin = add(&[&sc(q(5, 1), &x), &mk(&[((0, 0), 18)])]);
    let g2 = add(&[&sc(q(25, 1), &f1), &sc(q(-1, 1), &mul(&lin, &g1))]);
    let fixes = [(xf, q(24, 5)), (xf, q(-24, 5))];
    println!("field: rational coefficients, real points; terms in lex order, x before y");
    println!("f1 = {}  (beacon A at (0, 0) reads 6 km)", show(&f1));
    println!("f2 = {}  (beacon B at (10, 0) reads 8 km)", show(&f2));
    println!("g1 = (f1 - f2)/4 = {}", show(&g1));
    println!("g2 = 25 f1 - (5x + 18) g1 = {}", show(&g2));
    let back1 = sc(q(1, 25), &add(&[&g2, &mul(&lin, &g1)])) == f1;
    let back2 = add(&[&f1, &sc(q(-4, 1), &g1)]) == f2;
    println!("back again: (g2 + (5x + 18) g1)/25 = f1: {}; f1 - 4 g1 = f2: {}", yn(back1), yn(back2));
    println!("fixes from g1 = 0 and g2 = 0: ({}, 24/5) and ({}, -24/5); y^2 = {}", xf, xf, y2);
    println!("in decimals: x = {:.1} km, y^2 = {:.2}, y = +/-{:.1} km", xf.n as f64 / xf.d as f64, y2.n as f64 / y2.d as f64, 24.0 / 5.0);
    let tx = q(72, 20);
    println!("by the triangle: x = (10^2 + 6^2 - 8^2)/(2 x 10) = {}; y^2 = 6^2 - x^2 = {}", tx, q(36, 1).add(tx.mul(tx).mul(q(-1, 1))));
    let vals: Vec<Vec<Q>> = fixes.iter().map(|&(a, b)| [&f1, &f2, &g1, &g2].iter().map(|p| at(p, a, b)).collect()).collect();
    let j = |v: &Vec<Q>| v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ");
    println!("f1, f2, g1, g2 at the north fix: {}; at the south fix: {}", j(&vals[0]), j(&vals[1]));
    let xx = add(&[&mul(&x, &f1), &sc(q(-1, 1), &mul(&x, &f2))]);
    println!("by hand: x f1 - x f2 = {}; at x = 18/5: {} - {} = {}", show(&xx), q(20, 1).mul(xf).mul(xf), q(72, 1).mul(xf), at(&xx, xf, q(0, 1)));
    let seed = 2026;
    let mut g = Rng(seed);
    let combos: Vec<Poly> = (0..1000).map(|_| { let h1 = g.poly(2); let h2 = g.poly(2); add(&[&mul(&h1, &f1), &mul(&h2, &f2)]) }).collect();
    let others: Vec<Poly> = (0..1000).map(|_| g.poly(4)).collect();
    let tally = |ps: &Vec<Poly>| (ps.iter().filter(|p| fixes.iter().all(|&(a, b)| at(p, a, b).n == 0)).count(),
                                  ps.iter().filter(|p| rem(p, xf, y2).is_empty()).count());
    let ((cz, cr), (oz, orr)) = (tally(&combos), tally(&others));
    println!("1000 random h1 f1 + h2 f2 (SplitMix64, seed {}): zero at both fixes {}, remainder 0 in {}", seed, cz, cr);
    println!("1000 random polynomials not built that way: zero at both fixes {}, remainder 0 in {}", oz, orr);
    let brute = count(&[&f1, &f2]);
    let reduced: Vec<(i128, i128)> = fixes.iter().map(|&(a, b)| (modp(a), modp(b))).collect();
    println!("over the 101-clock, every (x, y) tried: V(f1, f2) = {:?}", brute);
    println!("the two fixes reduced mod 101: {:?} and {:?}", reduced[0], reduced[1]);
    let bear = add(&[&sc(q(4, 1), &x), &sc(q(-3, 1), &y)]);
    let left: Vec<(Q, Q)> = fixes.iter().copied().filter(|&(a, b)| at(&bear, a, b).n == 0).collect();
    println!("add a bearing 4x - 3y: remainder {}, not in the ideal; fixes left [({}, {})]; mod 101 points {}",
             show(&rem(&bear, xf, y2)), left[0].0, left[0].1, count(&[&f1, &f2, &bear]).len());
    let inside = add(&[&mul(&x, &f1), &mul(&y, &f2)]);
    println!("add x f1 + y f2: remainder {}, in the ideal; mod 101 points {}", show(&rem(&inside, xf, y2)), count(&[&f1, &f2, &inside]).len());
    let (tl, t_x, t_y2) = fix(6, 10, 4);
    println!("tangent, B reads 4 km: f1 - f2 = {}; x = {}, y^2 = {}; ideal <x - 6, y^2>; point ({}, 0)", show(&tl), t_x, t_y2, t_x);
    println!("  y is zero at ({}, 0), yet its remainder is {}: not in the ideal; mod 101 points {}",
             t_x, show(&rem(&y, t_x, t_y2)), count(&[&circle(0, 6), &circle(10, 4)]).len());
    println!("x^2 + 1: no real point, since x^2 + 1 >= 1; mod 101 roots {:?}", (0..P).filter(|t| (t * t + 1) % P == 0).collect::<Vec<_>>());
    println!("mistake 1, one beacon only (f1): mod 101 points {}", count(&[&f1]).len());
    println!("mistake 2, f1 f2 = 0 instead of both: mod 101 points {}", count(&[&mul(&f1, &f2)]).len());
    println!("mistake 3, the line g1 kept, both circles dropped: mod 101 points {}", count(&[&g1]).len());
    for t in [4, 6] {
        let (_, ax, ay2) = fix(3, t, 2);
        println!("arm, links 3 m and 2 m, target {} m: elbow x = {}, y^2 = {}, real places {}", t, ax, ay2, (ay2.n > 0) as i32 + (ay2.n >= 0) as i32);
    }
    let px = |u: Q| q(20, 1).mul(u.add(q(7, 1)));
    let py = |v: Q| q(20, 1).mul(q(9, 1).add(v.mul(q(-1, 1))));
    println!("figure, 20 px per km: A ({}, {}) r 120; B ({}, {}) r 160; fixes ({}, {}) and ({}, {})",
             px(q(0, 1)), py(q(0, 1)), px(q(10, 1)), py(q(0, 1)), px(xf), py(q(24, 5)), px(xf), py(q(-24, 5)));
    let mut sorted = reduced.clone();
    sorted.sort();
    assert!(back1 && back2 && g1 == mk(&[((1, 0), 5), ((0, 0), -18)]) && g2 == mk(&[((0, 2), 25), ((0, 0), -576)]));
    assert!(vals.iter().flatten().all(|v| v.n == 0) && y2 == q(24, 5).pow(2));
    assert!(cz == 1000 && cr == 1000 && oz == 0 && orr == 0);  // vanishing agrees with remainder
    assert!(brute == sorted && left.len() == 1);               // brute force agrees with algebra
    assert!(t_y2.n == 0 && rem(&y, t_x, t_y2) == y && count(&[&f1]).len() == 100 && count(&[&mul(&f1, &f2)]).len() == 198);
    println!("ALL CHECKS PASS");
}
