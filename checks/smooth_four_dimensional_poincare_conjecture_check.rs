// The smooth Poincare conjecture in dimension four -- the check behind the card.  std only, no crates.
// Nothing here proves or refutes the conjecture.  It prints the status by dimension and checks the
// card's instances: 28 smooth 7-spheres by two roads, the E8 form that dimension 4 cannot smooth,
// and the dimension count behind the Whitney trick.  Every number on the card is printed here.
use std::collections::BTreeMap;
use std::fmt;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 } // an exact fraction n/d, kept in lowest terms with d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn qi(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { q(-self.n, self.d) } }
impl Q { fn abs(self) -> Q { q(self.n.abs(), self.d) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn comb(n: i128, k: i128) -> i128 { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) }
fn fact(n: i128) -> i128 { (1..=n).product() }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }

const NS: usize = 3;
fn mul(a: &[Q], b: &[Q]) -> Vec<Q> { (0..NS).map(|j| (0..=j).fold(qi(0), |s, i| s + a[i] * b[j - i])).collect() }
fn inv(a: &[Q]) -> Vec<Q> {
    let mut out = vec![qi(1) / a[0]];
    for j in 1..NS { let s = (1..=j).fold(qi(0), |s, i| s + a[i] * out[j - i]); out.push(-s / a[0]); }
    out
}
fn log1(a: &[Q]) -> Vec<Q> { // log of a series that starts with 1
    let mut u = a.to_vec(); u[0] = qi(0);
    let (mut out, mut pw) = (vec![qi(0); NS], vec![qi(1), qi(0), qi(0)]);
    for m in 1..NS {
        pw = mul(&pw, &u);
        let sg = if m % 2 == 1 { 1 } else { -1 };
        for i in 0..NS { out[i] = out[i] + pw[i] * q(sg, m as i128); }
    }
    out
}
fn bareiss(g: &[Vec<Q>]) -> i128 { // second road: a determinant in whole numbers only
    let mut m: Vec<Vec<i128>> = g.iter().map(|r| r.iter().map(|x| x.n / x.d).collect()).collect();
    let mut prev = 1i128;
    for i in 0..7 {
        for r in i + 1..8 { for c in i + 1..8 { m[r][c] = (m[r][c] * m[i][i] - m[r][i] * m[i][c]) / prev; } }
        prev = m[i][i];
    }
    m[7][7]
}

fn main() {
    println!("Poincare conjecture by dimension, status as of 2026-11-24");
    println!("  n  topological   smooth        smooth homotopy n-spheres");
    for (a, b, c, d) in [("1", "true", "true", "1"), ("2", "true", "true", "1"), ("3", "true (2003)", "true (2003)", "1"),
        ("4", "true (1982)", "OPEN", "unknown, at least 1"), ("5", "true (1961)", "true (1963)", "1"),
        ("6", "true (1961)", "true (1963)", "1"), ("7", "true (1961)", "false (1956)", "28"),
        ("8", "true (1961)", "false (1963)", "2")] {
        println!("  {:<2} {:<13} {:<13} {}", a, b, c, d);
    }
    println!("ledger");
    for (date, event) in [("1952", "Rokhlin: smooth spin 4-manifolds, signature divisible by 16"),
        ("1956", "Milnor: a 7-sphere that is not smoothly standard"),
        ("1961", "Smale: h-cobordism, smooth dimensions 5 and up"),
        ("1962", "Stallings: R^n has one smooth structure for n >= 5"),
        ("1962", "Gluck: the twist of S^4 along a 2-sphere"), ("1963", "Kervaire-Milnor: 28 smooth 7-spheres"),
        ("1966", "Newman (1967 Connell): topological manifolds, n >= 5"),
        ("1976", "Cappell-Shaneson: candidate homotopy 4-spheres"),
        ("1982", "Freedman: dimension 4, topological"), ("1983", "Donaldson: smooth definite forms are diagonal"),
        ("1987", "Taubes: uncountably many smooth R^4"), ("1987", "Donaldson: smooth h-cobordism fails in dim 4"),
        ("2003", "Perelman: dimension 3"), ("2010", "Akbulut: Cappell-Shaneson spheres are standard"),
        ("2010", "Freedman-Gompf-Morrison-Walker: computer test, no verdict"),
        ("2022-09-17", "Akbulut: outline of a proof of smooth dimension 4, revised to 2024-07-30; claimed, not accepted"),
        ("2026-11-24", "smooth dimension 4: open")] {
        println!("  {:<11}{}", date, event);
    }

    // 1. Bernoulli numbers from the recurrence sum_{j<=m} C(m+1, j) B_j = 0.
    let mut b = vec![qi(1)];
    for m in 1..11i128 {
        let s = (0..m).fold(qi(0), |s, j| s + qi(comb(m + 1, j)) * b[j as usize]);
        b.push(-s / qi(m + 1));
    }
    let bs: Vec<String> = (2..11).step_by(2).map(|i| b[i].to_string()).collect();
    println!("Bernoulli B2, B4, B6, B8, B10: {}", bs.join(", "));

    // 2. Road 1 to 28: Kervaire-Milnor's order of bP(4k), the spheres that bound parallelizable manifolds.
    let num = |k: i128| (qi(4) * b[2 * k as usize].abs() / qi(k)).n;
    let bp = |k: i128| (1i128 << (2 * k - 2)) * ((1i128 << (2 * k - 1)) - 1) * num(k);
    let quoted: BTreeMap<i128, i128> = [(7, 28), (11, 992), (15, 16256)].into_iter().collect();
    for k in 1..5i128 {
        let n = 4 * k - 1;
        let note = match quoted.get(&n) { Some(v) => format!("table: {}", v), None if k == 1 => "but the 3-sphere has 1 smooth structure".to_string(), None => "beyond the quoted table".to_string() };
        println!("  k={}  n={:<3} bP = {} x {} x {} = {:<6} {}", k, n, 1i128 << (2 * k - 2), (1i128 << (2 * k - 1)) - 1, num(k), bp(k), note);
    }
    assert!(bp(2) == quoted[&7] && bp(3) == quoted[&11], "the formula must match the quoted table");
    assert!(quoted[&15] % bp(4) == 0, "bP(16) is a subgroup of Theta_15");

    // 3. Road 2 to 28: the L and A-hat genera of a closed 8-manifold, from power series in z = x^2.
    let cosh: Vec<Q> = (0..NS as i128).map(|i| q(1, fact(2 * i))).collect();
    let sinhx: Vec<Q> = (0..NS as i128).map(|i| q(1, fact(2 * i + 1))).collect();
    let sinh_half: Vec<Q> = (0..NS as i128).map(|i| q(1, (1i128 << (2 * i)) * fact(2 * i + 1))).collect();
    let mut genus: BTreeMap<&str, (Q, Q, Q)> = BTreeMap::new();
    for (name, ser) in [("L", mul(&cosh, &inv(&sinhx))), ("A-hat", inv(&sinh_half))] {
        let c = log1(&ser); // p1 = s1, p2 = (s1^2 - s2)/2 in power sums s_m of z
        let g = (c[1], qi(-2) * c[2], c[2] + c[1] * c[1] / qi(2));
        println!("{:<6} genus: dim 4 = ({}) p1;  dim 8 = ({}) p2 + ({}) p1^2", name, c[1], g.1, g.2);
        genus.insert(name, g);
    }
    for k in [1i128, 2] { // second road to the top coefficients: Hirzebruch's Bernoulli forms
        let bk = b[2 * k as usize].abs();
        let lk = qi((1i128 << (2 * k)) * ((1i128 << (2 * k - 1)) - 1)) * bk / qi(fact(2 * k));
        let ak = -bk / qi(2 * fact(2 * k));
        let (gl, ga) = if k == 1 { (genus["L"].0, genus["A-hat"].0) } else { (genus["L"].1, genus["A-hat"].1) };
        assert!(lk == gl && ak == ga, "series against Bernoulli");
    }
    let step = qi(1) / genus["A-hat"].1.abs();
    let sig = genus["L"].1 * step;
    println!("8-manifold with p1 = 0: p2 in steps of {}, signature in steps of {}; {} / 8 = {}", step, sig, sig, sig / qi(8));
    assert!(sig / qi(8) == qi(bp(2)), "two roads to 28 must agree");

    // 4. The E8 form: simple roots in coordinates, their dot products, determinant two ways, signature.
    let h = q(1, 2);
    let mut roots: Vec<Vec<Q>> = vec![vec![h, -h, -h, -h, -h, -h, -h, h], [1, 1, 0, 0, 0, 0, 0, 0].map(qi).to_vec()];
    for i in 0..6 { let mut r = vec![qi(0); 8]; r[i] = qi(-1); r[i + 1] = qi(1); roots.push(r); }
    let g: Vec<Vec<Q>> = roots.iter().map(|a| roots.iter().map(|c| (0..8).fold(qi(0), |s, i| s + a[i] * c[i])).collect()).collect();
    let (mut a, mut piv) = (g.clone(), Vec::new());
    for i in 0..8 {
        piv.push(a[i][i]);
        for r in i + 1..8 { let f = a[r][i] / a[i][i]; for c in 0..8 { a[r][c] = a[r][c] - f * a[i][c]; } }
    }
    let det = piv.iter().fold(qi(1), |p, &x| p * x);
    let sigma = piv.iter().filter(|x| x.n > 0).count() as i64 - piv.iter().filter(|x| x.n < 0).count() as i64;
    let diag: Vec<String> = (0..8).map(|i| g[i][i].to_string()).collect();
    let pv: Vec<String> = piv.iter().map(|p| p.to_string()).collect();
    println!("E8 diagonal [{}]  pivots {}", diag.join(", "), pv.join(", "));
    let even = (0..8).all(|i| g[i][i].d == 1 && g[i][i].n % 2 == 0);
    println!("E8 determinant {} (whole-number road {}), signature {}, even {}", det, bareiss(&g), sigma, py(even));
    assert!(det == qi(bareiss(&g)) && det == qi(1) && sigma == 8, "E8 must have determinant 1 and signature 8");
    let (mut e8, mut dg): (BTreeMap<i64, i64>, BTreeMap<i64, i64>) = (BTreeMap::new(), BTreeMap::new());
    for m in 0..3i64.pow(8) { // every vector of square <= 2 lies in these boxes
        let v: Vec<i64> = (0..8).map(|i| (m / 3i64.pow(i)) % 3 - 1).collect();
        let s: i64 = v.iter().map(|x| x * x).sum();
        *dg.entry(s).or_insert(0) += 1;
        if v.iter().sum::<i64>().rem_euclid(2) == 0 { *e8.entry(s).or_insert(0) += 1; }
    }
    *e8.get_mut(&2).unwrap() += (0..256u32).filter(|m| m.count_ones() % 2 == 0).count() as i64; // all entries +-1/2
    let e1 = *e8.get(&1).unwrap_or(&0);
    println!("square 1: E8 {}, diagonal form {};  square 2: E8 {} = {} + {}", e1, dg[&1], e8[&2], 4 * comb(8, 2), 1 << 7);
    assert!(e1 == 0 && dg[&1] == 2 * 8, "a diagonal form has 16 square-1 vectors, E8 none");
    assert!(e8[&2] as i128 == 4 * comb(8, 2) + 128, "E8 has 112 + 128 = 240 vectors of square 2");
    println!("Rokhlin test: smooth needs signature divisible by 16; E8 gives {} mod 16 = {}", sigma, sigma % 16);
    let ks: Vec<String> = (1..60).filter(|k| (8 * k) % 224 == 0).map(|k: i64| k.to_string()).collect();
    println!("Milnor's 7-spheres: k copies of the E8 plumbing, signature 8k, standard when 224 divides 8k: [{}]", ks.join(", "));

    // 5. Whitney trick: a 2-disc in general position in a level of dimension d crosses itself in dimension 2+2-d.
    let w: Vec<String> = (4..8).map(|d: i64| format!("d={}: {}", d, 4 - d)).collect();
    println!("Whitney disc self-crossing dimension 2+2-d: {}", w.join(", "));
    println!("ALL CHECKS PASS");
}
