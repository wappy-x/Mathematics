// Grobner bases and Buchberger's algorithm -- the same check as the Python, in
// Rust.  No crates.  Fractions are i128 pairs in lowest terms, multiplied with
// checked_mul so an overflow stops the run.  A polynomial maps (i, j) to the
// coefficient of x^i y^j; the order is lex, x > y, so the leading key is the last.
use std::collections::BTreeMap;
type Poly = BTreeMap<(u32, u32), Fr>;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Fr {
    fn add(self, o: Fr) -> Fr { fr(m(self.n, o.d) + m(o.n, self.d), m(self.d, o.d)) }
    fn mul(self, o: Fr) -> Fr { fr(m(self.n, o.n), m(self.d, o.d)) }
    fn div(self, o: Fr) -> Fr { fr(m(self.n, o.d), m(self.d, o.n)) }
    fn neg(self) -> Fr { fr(-self.n, self.d) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
}
impl std::fmt::Display for Fr {
    fn fmt(&self, w: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(w, "{}", self.n) } else { write!(w, "{}/{}", self.n, self.d) }
    }
}
fn int(n: i128) -> Fr { fr(n, 1) }
fn quoted(v: &[String]) -> String { format!("[{}]", v.iter().map(|t| format!("'{}'", t)).collect::<Vec<_>>().join(", ")) }
fn lead(f: &Poly) -> (u32, u32) { *f.keys().next_back().unwrap() }

fn add(f: &Poly, g: &Poly, c: Fr, s: (u32, u32)) -> Poly {   // f + c * x^s0 y^s1 * g
    let mut out = f.clone();
    for (&(i, j), &a) in g {
        let k = (i + s.0, j + s.1);
        let v = out.get(&k).copied().unwrap_or(int(0)).add(c.mul(a));
        if v.n == 0 { out.remove(&k); } else { out.insert(k, v); }
    }
    out
}
fn mul(f: &Poly, g: &Poly) -> Poly {                          // plain product
    let mut out = Poly::new();
    for (&s, &a) in f { out = add(&out, g, a, s) }
    out
}
fn divide(f: &Poly, divs: &[Poly]) -> Poly {                  // division by a list
    let (mut p, mut r) = (f.clone(), Poly::new());
    while !p.is_empty() {
        let k = lead(&p);
        match divs.iter().find(|g| { let n = lead(g); n.0 <= k.0 && n.1 <= k.1 }) {
            Some(g) => { let n = lead(g); p = add(&p, g, p[&k].div(g[&n]).neg(), (k.0 - n.0, k.1 - n.1)) }
            None => { r.insert(k, p.remove(&k).unwrap()); }
        }
    }
    r
}
fn spoly(f: &Poly, g: &Poly) -> Poly {                        // cancel the leading terms
    let (a, b) = (lead(f), lead(g));
    let l = (a.0.max(b.0), a.1.max(b.1));
    let s = add(&Poly::new(), f, int(1).div(f[&a]), (l.0 - a.0, l.1 - a.1));
    add(&s, g, int(-1).div(g[&b]), (l.0 - b.0, l.1 - b.1))
}
fn tidy(f: &Poly) -> Poly {                                   // whole coefficients, no common factor
    let (mut d, mut n) = (1i128, 0i128);
    for c in f.values() { d = m(d, c.d) / gcd(d, c.d) }
    for c in f.values() { n = gcd(n, m(c.n, d / c.d)) }
    let s = if f[&lead(f)].n > 0 { fr(d, n) } else { fr(-d, n) };
    f.iter().map(|(&k, &c)| (k, c.mul(s))).collect()
}
fn show(f: &Poly) -> String {
    let mut out = String::new();
    for (&(i, j), &c) in f.iter().rev() {
        let a = if c.n < 0 { c.neg() } else { c };
        let mut mono = String::new();
        if i > 0 { mono += "x" } if i > 1 { mono += &format!("^{}", i) }
        if j > 0 { mono += "y" } if j > 1 { mono += &format!("^{}", j) }
        let coef = if a == int(1) && !mono.is_empty() { String::new() }
                   else if a.d > 1 && !mono.is_empty() { format!("({})", a) } else { a.to_string() };
        out += if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        out += &(coef + &mono);
    }
    if out.is_empty() { "0".to_string() } else { out }
}
fn buchberger(start: &[Poly], talk: bool) -> (Vec<Poly>, usize) {
    let mut g: Vec<Poly> = start.iter().map(tidy).collect();
    let mut zero = 0;
    let mut pairs: Vec<(usize, usize)> = vec![(0, 1)];
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0);
        let s = spoly(&g[i], &g[j]);
        let r = divide(&s, &g);
        if !r.is_empty() {
            g.push(tidy(&r));
            for k in 0..g.len() - 1 { pairs.push((k, g.len() - 1)) }
        } else { zero += 1 }
        if talk {
            let new = if r.is_empty() { String::new() } else { format!(" -> new f{} = {}", g.len(), show(&g[g.len() - 1])) };
            println!("pair (f{}, f{}): S = {}; remainder {}{}", i + 1, j + 1, show(&s), show(&r), new);
        }
    }
    (g, zero)
}
fn p(terms: &[(Fr, u32, u32)]) -> Poly { terms.iter().map(|&(c, i, j)| ((i, j), c)).collect() }
fn arm(a: Fr) -> Vec<Poly> {
    vec![p(&[(int(1), 2, 0), (int(1), 0, 2), (int(-9), 0, 0)]),
         p(&[(int(1), 2, 0), (a.mul(int(-2)), 1, 0), (int(1), 0, 2), (a.mul(a).add(int(-4)), 0, 0)])]
}

fn main() {
    let (a, fs) = (int(4), arm(int(4)));
    let (f1, f2) = (&fs[0], &fs[1]);
    println!("arm: links 3 m and 2 m, shoulder (0, 0), target ({}, 0); order lex x > y", a);
    println!("f1 = {}   f2 = {}", show(f1), show(f2));
    let (g, zero) = buchberger(&fs, true);
    let (s13, s23) = (spoly(&g[0], &g[2]), spoly(&g[1], &g[2]));
    println!("by hand: S(f1, f3) = f1 - ({})x f3, then take away {} f3; S(f2, f3) leaves {} = ({}) f4", int(1).div(g[2][&(1, 0)]),
             s13[&(1, 0)].div(g[2][&(1, 0)]), show(&divide(&s23, &g[..3])), int(1).div(g[3][&(0, 2)]));
    let np = g.len() * (g.len() - 1) / 2;
    println!("pairs checked {}, new members {}, remainders 0: {}", np, g.len() - 2, zero);
    let crit = (0..g.len()).all(|j| (0..j).all(|i| divide(&spoly(&g[i], &g[j]), &g).is_empty()));
    println!("criterion on the final basis: all {} S-polynomials divide to 0: {}", np, if crit { "yes" } else { "no" });
    let mut coprime = vec![];
    for j in 0..g.len() { for i in 0..j {
        let (u, v) = (lead(&g[i]), lead(&g[j]));
        if u.0.min(v.0) == 0 && u.1.min(v.1) == 0 { coprime.push((i + 1, j + 1)) }
    } }
    println!("pairs with leading terms sharing no variable (can be skipped; here they also divide to 0): {:?}", coprime);
    let xb = int(9).add(a.mul(a)).add(int(-4)).div(a.mul(int(2)));     // road two: law of cosines
    let yy = int(9).add(xb.mul(xb).neg());
    println!("law of cosines: elbow x = (9 + {} - 4)/(2*{}) = {}, y^2 = 9 - x^2 = {}", a.mul(a), a, xb, yy);
    let g3 = tidy(&p(&[(int(1), 1, 0), (xb.neg(), 0, 0)]));
    let g4 = tidy(&p(&[(int(1), 0, 2), (yy.neg(), 0, 0)]));
    let same = g3 == g[2] && g4 == g[3];
    println!("as polynomials: {} and {}; same as f3, f4: {}", show(&g3), show(&g4), if same { "yes" } else { "no" });
    println!("tidy basis (Normal forms card): x - {}, y^2 - {}", xb, yy);
    let c1 = add(f1, f2, int(-1), (0, 0));                              // road three: certificates
    let c2 = add(&mul(&p(&[(int(43), 0, 0), (int(-8), 1, 0)]), f1),
                 &mul(&p(&[(int(8), 1, 0), (int(21), 0, 0)]), f2), int(1), (0, 0));
    println!("certificates: f1 - f2 = {};  (43 - 8x)f1 + (8x + 21)f2 = {}", show(&c1), show(&c2));
    let (e1, e2) = (xb.mul(xb).add(yy).add(int(-9)), xb.add(a.neg()).mul(xb.add(a.neg())).add(yy).add(int(-4)));
    let ys = yy.f().sqrt();
    println!("elbows ({:.6}, {:.6}) and ({:.6}, {:.6}) put back exactly: f1 = {}, f2 = {}", xb.f(), ys, xb.f(), -ys, e1, e2);
    let std: Vec<String> = (0..9u32).map(|t| (t / 3, t % 3)).filter(|&(i, j)| !g.iter().any(|q| { let l = lead(q); i >= l.0 && j >= l.1 }))
        .map(|(i, j)| show(&p(&[(int(1), i, j)]))).collect();
    println!("monomials no leading term divides: {} -> {} elbows over the complex numbers", quoted(&std), std.len());
    println!("figure, shoulder (0, 0) r 3; target ({}, 0) r 2; line x = {:.3}; elbows y = +-{:.6}", a, xb.f(), ys);
    let (r1, r2) = (divide(&g[2], &fs), divide(&g[3], &g[..3]));
    println!("mistake 1, f3 = {} divided by [f1, f2] leaves {}; by the basis, {}", show(&g[2]), show(&r1), show(&divide(&g[2], &g)));
    println!("mistake 2, stopping after f3: {} divided by [f1, f2, f3] leaves {}", show(&g[3]), show(&r2));
    let h = p(&[(int(1), 2, 1), (int(1), 1, 2), (int(1), 0, 2)]);
    let (u, v) = (p(&[(int(1), 1, 1), (int(-1), 0, 0)]), p(&[(int(1), 0, 2), (int(-1), 0, 0)]));
    let (ra, rb) = (divide(&h, &[u.clone(), v.clone()]), divide(&h, &[v.clone(), u.clone()]));
    println!("mistake 3, {} divided by [{}, {}] leaves {}; in the other order, {}", show(&h), show(&u), show(&v), show(&ra), show(&rb));
    let (hb, _) = buchberger(&[u.clone(), v.clone()], false);
    let orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]];
    let mut rs: Vec<String> = orders.iter().map(|o| show(&divide(&h, &o.map(|k| hb[k].clone())))).collect();
    rs.sort(); rs.dedup();
    println!("after Buchberger adds {}: the 6 orders of the 3 divisors leave {}", show(&hb[2]), quoted(&rs));
    let gap = add(&rb, &ra, int(-1), (0, 0));
    let cert = add(&mul(&p(&[(int(1), 0, 1)]), &u), &mul(&p(&[(int(1), 1, 0)]), &v), int(-1), (0, 0));
    println!("the gap {} = y(xy - 1) - x(y^2 - 1) = {}", show(&gap), show(&cert));
    let (g6, _) = buchberger(&arm(int(6)), false);
    let y6 = g6[3][&(0, 0)].neg().div(g6[3][&(0, 2)]);
    println!("mistake 4, target 6 m away: new members {} and {}, so y^2 = {}: no real elbow", show(&g6[2]), show(&g6[3]), y6);
    assert!(show(&g[2]) == "8x - 21" && show(&g[3]) == "64y^2 - 135");   // the hand computation
    assert!(spoly(&g[0], &g[2]) == p(&[(fr(21, 8), 1, 0), (int(1), 0, 2), (int(-9), 0, 0)]));  // S(f1, f3) by hand
    assert!(crit && same && std.len() == 2);                             // criterion, cosines, count
    assert!(c1 == g[2] && c2 == g[3]);                                   // members of <f1, f2>
    assert!(e1 == int(0) && e2 == int(0));                               // elbows on both circles
    assert!(ra != rb && rs.len() == 1 && divide(&gap, &hb).is_empty());
    assert!(!r1.is_empty() && !r2.is_empty() && divide(&g[3], &g).is_empty() && y6.n < 0);
    println!("ALL CHECKS PASS");
}
