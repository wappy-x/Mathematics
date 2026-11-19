// Hilbert's basis theorem -- the same check as the Python, in Rust.  No crates.
// A fair four-sided die has hidden faces x, y, z, w.  Equation n says the faces'
// n-th powers add to s_n = 1 + 2^n + 3^n + 4^n, for n = 1, 2, 3, ...  Field: the
// rationals, as an i128 fraction whose checked arithmetic stops the run on overflow.
// Order: lex, x > y > z > w (a BTreeMap of exponent vectors sorts in lex).
use std::collections::BTreeMap;
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn mul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn add(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn div(a: Q, b: Q) -> Q { mul(a, q(b.d, b.n)) }
fn int(n: i128) -> Q { Q { n, d: 1 } }
fn qs(a: Q) -> String { if a.d == 1 { a.n.to_string() } else { format!("{}/{}", a.n, a.d) } }
type M = Vec<u32>; type P = BTreeMap<M, Q>;
const NV: usize = 4; const TOP: u32 = 12; const FACES: [i128; 4] = [1, 2, 3, 4]; const NAMES: [char; 4] = ['x', 'y', 'z', 'w'];
fn s(n: u32) -> i128 { FACES.iter().map(|f| f.pow(n)).sum() }
fn unit(i: usize, n: u32, nv: usize) -> M { (0..nv).map(|j| if j == i { n } else { 0 }).collect() }
fn eq(n: u32) -> P { (0..NV).map(|i| (unit(i, n, NV), int(1))).chain([(vec![0; NV], int(-s(n)))]).collect() } // f_n
fn shift(m: &M, a: &M, sign: i64) -> M { m.iter().zip(a).map(|(&u, &v)| (u as i64 + sign * v as i64) as u32).collect() }
fn addm(p: &P, g: &P, c: Q, m: &M) -> P {            // p + c * (monomial m) * g
    let mut out = p.clone(); for (e, &a) in g {
        let (k, v) = (shift(e, m, 1), add(*out.get(&shift(e, m, 1)).unwrap_or(&int(0)), mul(c, a)));
        if v.n == 0 { out.remove(&k); } else { out.insert(k, v); }
    }
    out
}
fn divides(a: &M, b: &M) -> bool { a.iter().zip(b).all(|(u, v)| u <= v) }
fn lead(p: &P) -> M { p.keys().next_back().unwrap().clone() }
fn nf(p: &P, g: &[P]) -> P {                          // the remainder of p on division by g
    let (mut p, mut r) = (p.clone(), P::new());
    while let Some((m, c)) = p.last_key_value().map(|(k, &v)| (k.clone(), v)) {
        match g.iter().find(|h| divides(&lead(h), &m)) {
            None => { p.remove(&m); r.insert(m, c); }
            Some(h) => { let lh = lead(h); p = addm(&p, h, div(int(-1), div(h[&lh], p[&m])), &shift(&m, &lh, -1)); }
        }
    }
    r
}
fn spoly(f: &P, g: &P) -> P {
    let (a, b) = (lead(f), lead(g)); let l: M = a.iter().zip(&b).map(|(&u, &v)| u.max(v)).collect();
    addm(&addm(&P::new(), f, div(int(1), f[&a]), &shift(&l, &a, -1)), g, div(int(-1), g[&b]), &shift(&l, &b, -1))
}
fn buchberger(fs: Vec<P>) -> (Vec<P>, usize, Vec<M>) {
    let (mut g, mut checked, mut added) = (fs.clone(), 0, Vec::new());
    let mut pairs: Vec<(usize, usize)> = (0..fs.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0); checked += 1;
        let r = nf(&spoly(&g[i], &g[j]), &g);
        if !r.is_empty() {                            // a new leading term: the chain grows
            pairs.extend((0..g.len()).map(|k| (k, g.len())));
            added.push(lead(&r)); g.push(r);
        }
    }
    g.sort_by(|a, b| lead(a).cmp(&lead(b)));           // drop any whose leading term is divisible
    let mut keep: Vec<P> = Vec::new(); for x in g { if !keep.iter().any(|h| divides(&lead(h), &lead(&x))) { keep.push(x) } }
    let red = (0..keep.len()).rev().map(|i| {
        let r = nf(&keep[i], &[&keep[..i], &keep[i + 1..]].concat());
        r.iter().map(|(k, &v)| (k.clone(), div(v, r[&lead(&r)]))).collect()
    }).collect();
    (red, checked, added)
}
fn mono(m: &M) -> String {
    let parts: Vec<String> = m.iter().enumerate().filter(|&(_, &k)| k > 0)
        .map(|(i, &k)| if k > 1 { format!("{}^{}", NAMES[i], k) } else { NAMES[i].to_string() }).collect();
    if parts.is_empty() { "1".to_string() } else { parts.join("*") }
}
fn show(p: &P) -> String {
    let mut out = String::new();
    for (m, &c) in p.iter().rev() {
        let (a, body) = (Q { n: c.n.abs(), d: c.d }, if m.iter().any(|&k| k > 0) { mono(m) } else { String::new() });
        let txt = if body.is_empty() { qs(a) } else if a == int(1) { body } else { format!("{}*{}", qs(a), body) };
        let sign = if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        out += &format!("{}{}", sign, txt);
    }
    out
}
fn h(d: u32, k: usize) -> Vec<M> {                    // every monomial of degree d in variables k..w
    if k == NV - 1 { return vec![unit(k, d, NV)] }
    (0..=d).rev().flat_map(|j| h(d - j, k + 1).into_iter().map(move |e| shift(&unit(k, j, NV), &e, 1))).collect()
}
fn perms(t: &[i128]) -> Vec<Vec<i128>> {
    if t.len() < 2 { return vec![t.to_vec()] }
    (0..t.len()).flat_map(|i| perms(&[&t[..i], &t[i + 1..]].concat()).into_iter().map(move |r| [vec![t[i]], r].concat())).collect()
}
fn ev(p: &P, pt: &[i128]) -> Q {
    p.iter().fold(int(0), |acc, (m, &c)| add(acc, mul(c, int((0..NV).map(|i| pt[i].pow(m[i])).product()))))
}
fn minimal(set: &[(i64, i64)]) -> Vec<(i64, i64)> {  // members no other member divides
    let below = |a: i64, b: i64| set.iter().any(|&(c, d)| (c, d) != (a, b) && c <= a && d <= b);
    let mut v: Vec<(i64, i64)> = set.iter().filter(|&&(a, b)| !below(a, b)).cloned().collect();
    v.sort(); v.dedup(); v
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let mut c: Vec<i128> = vec![1];                   // coefficients of (t - 1)(t - 2)(t - 3)(t - 4)
    for f in FACES { let mut nc = c.clone(); nc.push(0); for i in 0..c.len() { nc[i + 1] -= f * c[i] } c = nc; }
    let c: Vec<i128> = c.iter().map(|a| a.abs()).collect();     // e_0 .. e_4 of the faces
    let mut formula: Vec<P> = vec![P::new(); NV];    // g_k = sum_j (-1)^j e_j h_(k-j)(x_k..w)
    for k in 1..=NV { for j in 0..=k {
        let cst: P = [(vec![0; NV], int((-1i128).pow(j as u32) * c[j]))].into_iter().collect();
        for m in h((k - j) as u32, k - 1) { formula[k - 1] = addm(&formula[k - 1], &cst, int(1), &m) }
    } }
    let (g, checked, added) = buchberger((1..=4).map(eq).collect());
    println!("field Q, lex order x > y > z > w; true faces {:?}; e_1..e_4 = {:?}", FACES, &c[1..]);
    println!("power sums s_1..s_{}: {:?}", TOP, (1..=TOP).map(s).collect::<Vec<_>>());
    println!("Buchberger on f_1..f_4: {} pairs checked, {} remainders added, leading terms {}", checked, added.len(),
             added.iter().map(mono).collect::<Vec<_>>().join(", "));
    for (k, p) in g.iter().enumerate() { println!("g_{} = {}", k + 1, show(p)) }
    println!("the closed formula gives the same four: {}", yn(g == formula));
    let mut grow = Vec::new();
    for k in 1..4u32 {
        let r = nf(&eq(k + 1), &buchberger((1..=k).map(eq).collect()).0);
        grow.push(r.len());
        println!("I_{} < I_{}: f_{} leaves a remainder of {} terms, leading {}", k, k + 1, k + 1, r.len(), mono(&lead(&r)));
    }
    let rest: Vec<usize> = (5..=TOP).map(|n| nf(&eq(n), &g).len()).collect();
    println!("f_5..f_{} on division by g_1..g_4 leave remainder sizes {:?}", TOP, rest);
    let rec = (5..=TOP).all(|n| s(n) == c[1] * s(n - 1) - c[2] * s(n - 2) + c[3] * s(n - 3) - c[4] * s(n - 4));
    println!("the strong-induction step s_n = 10 s_(n-1) - 35 s_(n-2) + 50 s_(n-3) - 24 s_(n-4), n = 5..{}: {}", TOP, yn(rec));
    let std = (0..625u32).filter(|i| !g.iter().any(|p| divides(&lead(p), &vec![i / 125, i / 25 % 5, i / 5 % 5, i % 5]))).count();
    let dice = perms(&FACES);
    let all: Vec<P> = g.iter().cloned().chain((1..=TOP).map(eq)).collect();
    let ok = dice.iter().all(|t| all.iter().all(|p| ev(p, t).n == 0));
    println!("monomials under the staircase x, y^2, z^3, w^4: {}; orderings of 1, 2, 3, 4: {}; all satisfy every equation: {}", std, dice.len(), yn(ok));
    let inside = |a: i64, b: i64| a * b >= 6;
    let corners = minimal(&(0..31).flat_map(|a| (0..31).map(move |b| (a, b))).filter(|&(a, b)| inside(a, b)).collect::<Vec<_>>());
    let (a0, b0) = (2i64, 3i64);                      // Dickson's proof: one member, then finitely many rows and columns
    let mut picked = vec![(a0, b0)];
    for b in 0..b0 { if let Some(a) = (0..31).find(|&a| inside(a, b)) { picked.push((a, b)) } }
    for a in 0..a0 { if let Some(b) = (0..31).find(|&b| inside(a, b)) { picked.push((a, b)) } }
    let dickson = minimal(&picked);
    println!("monomials x^a y^b with a*b >= 6: corners {:?}; Dickson's proof from (2, 3) finds {:?}", corners, dickson);
    let cs: Vec<String> = corners.iter().map(|(a, b)| format!("{},{}", a, b)).collect();
    println!("figure, corners {}; curve a*b = 6 through (1,6) (1.5,4) (2,3) (3,2) (4,1.5) (6,1)", cs.join(" "));
    let w = q(3, 2);                                  // mistake 1: only three moments
    let pw = [int(1), w, mul(w, w), mul(mul(w, w), w), mul(mul(w, w), mul(w, w))];
    let pp = [int(0), sub(int(s(1)), pw[1]), sub(int(s(2)), pw[2]), sub(int(s(3)), pw[3])];
    let (e1, e2) = (pp[1], div(sub(mul(pp[1], pp[1]), pp[2]), int(2)));
    let e3 = div(add(sub(mul(e2, pp[1]), mul(e1, pp[2])), pp[3]), int(3));
    let p4 = add(add(sub(mul(e1, pp[3]), mul(e2, pp[2])), mul(e3, pp[1])), pw[4]);
    println!("mistake 1, three moments only: faces 3/2, 7/2, (5 - 6^(1/2))/2 = {:.4}, (5 + 6^(1/2))/2 = {:.4}; cubic t^3 - {} t^2 + {} t - {} = (t - 7/2)(t^2 - {} t + {}); fourth sum {} = {}, not {}",
             (5.0 - 6f64.sqrt()) / 2.0, (5.0 + 6f64.sqrt()) / 2.0, qs(e1), qs(e2), qs(e3), qs(sub(e1, q(7, 2))), qs(div(e3, q(7, 2))), qs(p4), p4.n as f64 / p4.d as f64, s(4));
    let chain: Vec<usize> = (1..9).map(|n| {
        let gens: Vec<P> = (0..n).map(|i| [(unit(i, 1, 9), int(1))].into_iter().collect()).collect();
        nf(&[(unit(n, 1, 9), int(1))].into_iter().collect(), &gens).len()
    }).collect();
    println!("mistake 2, endless variables x_1, x_2, ...: x_(n+1) outside <x_1..x_n> for n = 1..8, remainder sizes {:?}", chain);
    let mut r: BTreeMap<i64, i64> = [(2, 1)].into_iter().collect();          // mistake 3: lowest degree leads;
    let gq: BTreeMap<i64, i64> = [(1, 1), (2, -1)].into_iter().collect();    // divide x^2 by x - x^2
    let mut steps: Vec<String> = Vec::new();
    for _ in 0..5 {
        let (m, cm) = r.pop_first().unwrap();         // the "leading" term is the lowest power
        for (&e, &a) in &gq { if e > 1 { *r.entry(e + m - 1).or_insert(0) -= cm / gq[&1] * a } }
        let (&lo, &cl) = r.iter().next().unwrap();
        steps.push(if cl != 1 { format!("{}*x^{}", cl, lo) } else { format!("x^{}", lo) });
    }
    println!("mistake 3, lowest-degree-first order, x^2 divided by x - x^2: remainders {} -> ... never ends", steps.join(" -> "));
    let lt: Vec<String> = g.iter().map(|p| mono(&lead(p))).collect();
    assert!(g == formula && lt == ["x", "y^2", "z^3", "w^4"]);                    // two roads, one basis
    assert!(grow.iter().all(|&n| n > 0) && rest.iter().all(|&n| n == 0) && rec);  // chain stops at 4
    assert!(std == 24 && dice.len() == 24 && ok && ev(&eq(1), &[1, 2, 3, 5]) == int(1));   // substitution
    assert!(corners == dickson && corners == vec![(1, 6), (2, 3), (3, 2), (6, 1)] && chain.iter().all(|&n| n == 1) && steps[4] == "x^7");
    assert!(e1 == add(q(7, 2), int(5)) && e2 == add(q(19, 4), q(35, 2)) && e3 == mul(q(7, 2), q(19, 4)) && p4 == q(1401, 4));
    println!("ALL CHECKS PASS");
}
