// Invariants of a finite group -- the same check as the Python, in Rust.  No crates.
// The group: the powers of the quarter turn A(x, y) = (-y, x), four matrices.  Field:
// the rationals, as an i128 fraction whose checked arithmetic stops the run on overflow.
// Four roads to the number of invariants of each degree d: Molien's average of
// 1/det(I - tg); the rank of the Reynolds averages of the degree-d monomials; the
// average trace of g on degree-d polynomials; and the products u^i v^j w^k (k = 0 or 1)
// of the three generators.  Then a Grobner basis, lex x > y > u > v > w (a BTreeMap of
// exponent vectors sorts in lex), finds the one relation among u, v, w.
use std::collections::BTreeMap;
#[derive(Clone, Copy, PartialEq, Debug)] struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn mulq(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn addq(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn divq(a: Q, b: Q) -> Q { mulq(a, q(b.d, b.n)) }
fn int(n: i128) -> Q { Q { n, d: 1 } }
fn qs(a: Q) -> String { if a.d == 1 { a.n.to_string() } else { format!("{}/{}", a.n, a.d) } }
type M = Vec<u32>; type P = BTreeMap<M, Q>; type Mat = [[i128; 2]; 2];
const TOP: usize = 12; const NAMES: [char; 5] = ['x', 'y', 'u', 'v', 'w'];
const A: Mat = [[0, -1], [1, 0]]; const S: Mat = [[0, 1], [1, 0]]; const I2: Mat = [[1, 0], [0, 1]];
fn matmul(a: &Mat, b: &Mat) -> Mat { let mut c = [[0; 2]; 2]; for i in 0..2 { for j in 0..2 { c[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] } } c }
fn closure(gens: &[Mat]) -> Vec<Mat> {                // every product of the generators
    let (mut g, mut new) = (vec![I2], vec![I2]);
    while !new.is_empty() { new = Vec::new(); for a in &g { for h in gens { let m = matmul(a, h); if !g.contains(&m) && !new.contains(&m) { new.push(m) } } } g.extend(new.clone()); }
    g
}
fn add(p: &P, r: &P, c: Q) -> P {                     // p + c * r
    let mut out = p.clone();
    for (m, &a) in r { let v = addq(*out.get(m).unwrap_or(&int(0)), mulq(c, a)); if v.n == 0 { out.remove(m); } else { out.insert(m.clone(), v); } }
    out
}
fn mul(p: &P, r: &P) -> P {
    let mut out = P::new();
    for (m, &a) in p { let t: P = r.iter().map(|(e, &b)| (m.iter().zip(e).map(|(i, j)| i + j).collect(), mulq(a, b))).collect(); out = add(&out, &t, int(1)); }
    out
}
fn mono(m: M, c: Q) -> P { [(m, c)].into_iter().collect() }
fn pw(p: &P, k: u32) -> P { let n = p.keys().next().unwrap().len(); (0..k).fold(mono(vec![0; n], int(1)), |o, _| mul(&o, p)) }
fn act(f: &P, g: &Mat) -> P {                         // f(g(x, y)): x -> g00 x + g01 y, y -> g10 x + g11 y
    let lin = |r: [i128; 2]| -> P { [(vec![1, 0], r[0]), (vec![0, 1], r[1])].into_iter().filter(|t| t.1 != 0).map(|(m, c)| (m, int(c))).collect() };
    let (x, y) = (lin(g[0]), lin(g[1]));
    f.iter().fold(P::new(), |o, (m, &c)| add(&o, &mul(&pw(&x, m[0]), &pw(&y, m[1])), c))
}
fn reynolds(f: &P, g: &[Mat]) -> P { g.iter().fold(P::new(), |o, h| add(&o, &act(f, h), q(1, g.len() as i128))) }
fn rank(polys: &[P]) -> usize {                        // Gaussian elimination over Q
    let (mut rows, mut r): (Vec<P>, usize) = (polys.iter().filter(|p| !p.is_empty()).cloned().collect(), 0);
    while let Some(p) = rows.pop() {
        let m = lead(&p); r += 1;
        rows = rows.into_iter().map(|t| if let Some(&c) = t.get(&m) { add(&t, &p, divq(int(-1), divq(p[&m], c))) } else { t }).filter(|t| !t.is_empty()).collect();
    }
    r
}
fn series(num: &[i128], den: &[i128]) -> Vec<Q> {     // power series of num / den up to t^TOP, den[0] = 1
    let mut c: Vec<Q> = Vec::new();
    for n in 0..=TOP { let mut v = int(*num.get(n).unwrap_or(&0)); for k in 1..=n.min(den.len() - 1) { v = addq(v, mulq(int(-den[k]), c[n - k])) } c.push(v) }
    c
}
fn molien(g: &[Mat]) -> Vec<Q> {
    let t: Vec<Vec<Q>> = g.iter().map(|h| series(&[1], &[1, -(h[0][0] + h[1][1]), h[0][0] * h[1][1] - h[0][1] * h[1][0]])).collect();
    (0..=TOP).map(|n| divq(t.iter().fold(int(0), |o, s| addq(o, s[n])), int(g.len() as i128))).collect()
}
fn monos(d: u32) -> Vec<M> { (0..=d).rev().map(|a| vec![a, d - a]).collect() }
fn show(p: &P) -> String {
    let mut out = String::new(); for (m, &c) in p.iter().rev() {
        let body: Vec<String> = m.iter().enumerate().filter(|t| *t.1 > 0).map(|(i, &k)| if k > 1 { format!("{}^{}", NAMES[i], k) } else { NAMES[i].to_string() }).collect();
        let a = Q { n: c.n.abs(), d: c.d };
        let txt = if body.is_empty() { qs(a) } else if a == int(1) { body.join("*") } else { format!("{}*{}", qs(a), body.join("*")) };
        out += &format!("{}{}", if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " }, txt);
    } out
}
fn or0(s: String) -> String { if s.is_empty() { "0".to_string() } else { s } }
fn ints(c: &[Q]) -> String { format!("[{}]", c.iter().map(|&a| qs(a)).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn lead(p: &P) -> M { p.keys().next_back().unwrap().clone() }
fn divides(a: &M, b: &M) -> bool { a.iter().zip(b).all(|(i, j)| i <= j) }
fn diff(a: &M, b: &M) -> M { a.iter().zip(b).map(|(i, j)| i - j).collect() }
fn nf(p: &P, b: &[P]) -> P {                          // remainder of p on division by the list b
    let (mut p, mut r) = (p.clone(), P::new());
    while !p.is_empty() {
        let m = lead(&p);
        match b.iter().find(|g| divides(&lead(g), &m)) {
            None => { let c = p.remove(&m).unwrap(); r.insert(m, c); }
            Some(g) => { let lg = lead(g); p = add(&p, &mul(&mono(diff(&m, &lg), divq(p[&m], g[&lg])), g), int(-1)); }
        }
    }
    r
}
fn spoly(f: &P, g: &P) -> P {
    let (a, b) = (lead(f), lead(g)); let l: M = a.iter().zip(&b).map(|(&i, &j)| i.max(j)).collect();
    add(&mul(&mono(diff(&l, &a), divq(int(1), f[&a])), f), &mul(&mono(diff(&l, &b), divq(int(1), g[&b])), g), int(-1))
}
fn buchberger(f: &[P]) -> Vec<P> {
    let mut b = f.to_vec(); let mut pairs: Vec<(usize, usize)> = (0..b.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    while !pairs.is_empty() {
        let (i, j) = pairs.remove(0); let r = nf(&spoly(&b[i], &b[j]), &b);
        if !r.is_empty() { pairs.extend((0..b.len()).map(|k| (k, b.len()))); b.push(r); }
    }
    b.sort_by(|x, y| lead(x).cmp(&lead(y)));
    let mut keep: Vec<P> = Vec::new(); for g in b { if !keep.iter().any(|h| divides(&lead(h), &lead(&g))) { keep.push(g) } }
    let mut red: Vec<P> = (0..keep.len()).map(|i| { let r = nf(&keep[i], &[&keep[..i], &keep[i + 1..]].concat()); let c = r[&lead(&r)]; r.iter().map(|(k, &v)| (k.clone(), divq(v, c))).collect() }).collect();
    red.sort_by(|x, y| lead(y).cmp(&lead(x))); red
}
fn ev(p: &P, a: i128, b: i128) -> Q { p.iter().fold(int(0), |o, (m, &c)| addq(o, mulq(c, int(a.pow(m[0]) * b.pow(m[1]))))) }
fn main() {
    let (g, d4) = (closure(&[A]), closure(&[A, S]));
    let (x, y) = (mono(vec![1, 0], int(1)), mono(vec![0, 1], int(1)));
    let (u, v) = (add(&pw(&x, 2), &pw(&y, 2), int(1)), mul(&pw(&x, 2), &pw(&y, 2)));
    let w = add(&mul(&pw(&x, 3), &y), &mul(&x, &pw(&y, 3)), int(-1));
    let one = |m: &M| mono(m.clone(), int(1));
    let mol = molien(&g);
    let closed = series(&[1, 0, 0, 0, 1], &[1, 0, -1, 0, -1, 0, 1]);     // (1 + t^4) / ((1 - t^2)(1 - t^4))
    let rey: Vec<Q> = (0..=TOP as u32).map(|d| int(rank(&monos(d).iter().map(|m| reynolds(&one(m), &g)).collect::<Vec<_>>()) as i128)).collect();
    let trace: Vec<Q> = (0..=TOP as u32).map(|d| divq(g.iter().fold(int(0), |o, h| monos(d).iter().fold(o, |o, m| addq(o, *act(&one(m), h).get(m).unwrap_or(&int(0))))), int(g.len() as i128))).collect();
    let (mut prods, mut span) = (Vec::new(), Vec::new());
    for d in 0..=TOP {
        let mut pp: Vec<P> = Vec::new();
        for k in 0..2u32 { for j in 0..TOP as u32 { for i in 0..TOP as u32 { if 2 * i + 4 * j + 4 * k == d as u32 { pp.push(mul(&mul(&pw(&u, i), &pw(&v, j)), &pw(&w, k))) } } } }
        let mut both = pp.clone(); both.extend(monos(d as u32).iter().map(|m| reynolds(&one(m), &g)));
        prods.push(int(pp.len() as i128)); span.push((rank(&pp), rank(&both)));
    }
    let gs: Vec<String> = g.iter().map(|h| format!("[{} {}; {} {}]", h[0][0], h[0][1], h[1][0], h[1][1])).collect();
    println!("field Q; group of the quarter turn (x, y) -> (-y, x): {} matrices {}", g.len(), gs.join(" "));
    let dets: Vec<String> = g.iter().map(|h| show(&[(vec![0], 1), (vec![1], -h[0][0] - h[1][1]), (vec![2], h[0][0] * h[1][1] - h[0][1] * h[1][0])].into_iter().filter(|t| t.1 != 0).map(|(m, c)| (m, int(c))).collect()).replace('x', "t")).collect();
    println!("det(I - tg) for each: {}", dets.join(", "));
    println!("degree d                            {}", ints(&(0..=TOP as i128).map(int).collect::<Vec<_>>()));
    println!("all polynomials of degree d         {}", ints(&(1..=TOP as i128 + 1).map(int).collect::<Vec<_>>()));
    println!("Molien, average of 1/det(I - tg)    {}", ints(&mol));
    println!("(1 + t^4)/((1 - t^2)(1 - t^4))      {}", ints(&closed));
    println!("rank of Reynolds images             {}", ints(&rey));
    println!("average trace of g on degree d      {}", ints(&trace));
    let ok_span = span.iter().zip(&prods).all(|(&(a, b), c)| a == b && int(a as i128) == *c);
    println!("products u^i v^j w^k, k <= 1        {}; independent and spanning: {}", ints(&prods), yn(ok_span));
    for m in [vec![1, 0], vec![2, 0], vec![1, 1], vec![4, 0], vec![3, 1], vec![2, 2]] { println!("R({}) = {}", show(&one(&m)), or0(show(&reynolds(&one(&m), &g)))) }
    println!("u = {}, v = {}, w = {}; each fixed by A: {}", show(&u), show(&v), show(&w), yn([&u, &v, &w].iter().all(|p| act(p, &A) == **p)));
    let lift = |p: &P| -> P { p.iter().map(|(m, &c)| ([m.clone(), vec![0, 0, 0]].concat(), c)).collect() };   // into Q[x, y, u, v, w]
    let var = |i: usize| mono((0..5).map(|j| (j == i) as u32).collect(), int(1));
    let gb = buchberger(&[add(&var(2), &lift(&u), int(-1)), add(&var(3), &lift(&v), int(-1)), add(&var(4), &lift(&w), int(-1))]);
    let elim: Vec<&P> = gb.iter().filter(|p| p.keys().all(|m| m[0] == 0 && m[1] == 0)).collect();
    println!("Grobner basis of <u - (x^2 + y^2), v - x^2y^2, w - (x^3y - xy^3)>, lex x > y > u > v > w: {} polynomials", gb.len());
    println!("free of x and y: {}: {} = 0", elim.len(), show(elim[0]));
    let rel = add(&add(&mul(&pw(&u, 2), &v), &pw(&v, 2), int(-4)), &pw(&w, 2), int(-1));   // u^2 v - 4 v^2 - w^2, put back in x, y
    println!("u^2*v - 4*v^2 - w^2 with u, v, w written in x and y: {}", or0(show(&rel)));
    let (n4, n2) = (nf(&lift(&add(&pw(&x, 4), &pw(&y, 4), int(1))), &gb), nf(&lift(&pw(&x, 2)), &gb));
    println!("normal form of x^4 + y^4: {}; of x^2 (not invariant): {}", show(&n4), show(&n2));
    let orbit: Vec<(i128, i128)> = g.iter().map(|h| (h[0][0] * 3 + h[0][1], h[1][0] * 3 + h[1][1])).collect();   // the orbit of (3, 1)
    let pts: Vec<String> = orbit.iter().map(|&(a, b)| format!("({}, {}): u, v, w = {}, {}, {}", a, b, qs(ev(&u, a, b)), qs(ev(&v, a, b)), qs(ev(&w, a, b)))).collect();
    let (u0, v0, w0) = (ev(&u, 3, 1), ev(&v, 3, 1), ev(&w, 3, 1)); let k0 = addq(mulq(u0, u0), mulq(int(-4), v0));
    println!("at {}; w^2 = {}, v(u^2 - 4v) = {} * {} = {}", pts.join(" and "), qs(mulq(w0, w0)), qs(v0), qs(k0), qs(mulq(v0, k0)));
    let md4 = molien(&d4);
    let rd4: Vec<Q> = (0..=TOP as u32).map(|d| int(rank(&monos(d).iter().map(|m| reynolds(&one(m), &d4)).collect::<Vec<_>>()) as i128)).collect();
    println!("with the mirror (x, y) -> (y, x) added: {} matrices; Molien {}; Reynolds ranks agree: {}; R(w) = {}", d4.len(), ints(&md4), yn(md4 == rd4), or0(show(&reynolds(&w, &d4))));
    let free = series(&[1], &[1, 0, -1, 0, -2, 0, 2, 0, 1, 0, -1]);   // 1/((1 - t^2)(1 - t^4)^2): u, v, w taken as free
    let only = series(&[1], &[1, -2, 1]);                             // 1/(1 - t)^2: the identity's term alone
    println!("mistake 1, identity term only: 1/(1 - t)^2 gives {} for d = 0..5, so {} at degree 4, not {}", ints(&only[..6]), qs(only[4]), qs(mol[4]));
    println!("mistake 2, u, v, w taken as free: 1/((1 - t^2)(1 - t^4)^2) gives {} at degree 8, not {}; the extra one is w^2 = u^2*v - 4*v^2", qs(free[8]), qs(mol[8]));
    let low: Vec<P> = (1..=2).flat_map(|d| monos(d)).map(|m| reynolds(&one(&m), &g)).filter(|r| !r.is_empty()).collect();   // averages of degree <= 2 only
    let low4 = rank(&low.iter().flat_map(|a| low.iter().map(move |b| mul(a, b))).collect::<Vec<_>>());
    println!("mistake 3, generators of degree <= 2 only: {} independent one (u), and degree 4 holds {} product, not {}", rank(&low), low4, qs(mol[4]));
    let tr2: Vec<P> = monos(2).iter().map(|m| add(&one(m), &act(&one(m), &S), int(1)).into_iter().filter(|t| t.1.n % 2 != 0).map(|(k, c)| (k, int(c.n.rem_euclid(2)))).collect()).collect();   // f + S(f), mod 2
    println!("mistake 4, field F_2, swap group {{I, S}}: f + S(f) for f = x^2, xy, y^2 gives {}; the invariant xy is never reached", tr2.iter().map(|t| or0(show(t))).collect::<Vec<_>>().join(", "));
    assert!(mol == closed && closed == rey && rey == trace && mol[..9] == [1, 0, 1, 0, 3, 0, 3, 0, 5].map(int));   // four roads to one count
    assert!(prods == mol && ok_span);                                                         // generators span, w^2 aside
    assert!(elim.len() == 1 && *elim[0] == [(vec![0, 0, 2, 1, 0], int(1)), (vec![0, 0, 0, 2, 0], int(-4)), (vec![0, 0, 0, 0, 2], int(-1))].into_iter().collect::<P>() && rel.is_empty());
    assert!(n4 == [(vec![0, 0, 2, 0, 0], int(1)), (vec![0, 0, 0, 1, 0], int(-2))].into_iter().collect::<P>() && n2.keys().any(|m| m[0] + m[1] > 0));
    assert!(mulq(w0, w0) == int(576) && mulq(v0, k0) == int(576) && g.len() == 4);
    assert!(orbit.len() == 4 && orbit.iter().all(|&(a, b)| ev(&u, a, b) == u0 && ev(&v, a, b) == v0 && ev(&w, a, b) == w0));   // same values round the orbit
    assert!(md4 == rd4 && md4[4] == int(2) && reynolds(&w, &d4).is_empty() && free[8] == int(6) && free[8] == addq(only[4], int(1)) && low4 == 1 && tr2 == vec![u.clone(), P::new(), u.clone()]);
    println!("ALL CHECKS PASS");
}
