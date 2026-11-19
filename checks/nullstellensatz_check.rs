// The Nullstellensatz -- the same check as the Python, in Rust.  No crates.
// Polynomials are maps from exponents [ex, ey, ez] to exact fractions, in
// x > y > z.  Certificates are checked by expanding them exactly, found by
// solving a linear system, and cross-checked against points over F_p.
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Copy, PartialEq)] struct Fr { n: i128, d: i128 }                   // a fraction; overflow stops the run

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr {
    let g = gcd(n, d).max(1) * d.signum();
    Fr { n: n / g, d: d / g }
}
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn fadd(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.d).checked_add(m(b.n, a.d)).expect("overflow"), m(a.d, b.d)) }
fn fmul(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.n), m(a.d, b.d)) }
fn fdiv(a: Fr, b: Fr) -> Fr { fr(m(a.n, b.d), m(a.d, b.n)) }
fn fs(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

type Poly = BTreeMap<[u32; 3], Fr>;
fn p(terms: &[(Fr, [u32; 3])]) -> Poly {
    let mut out = Poly::new();
    for &(c, k) in terms {
        let v = fadd(*out.get(&k).unwrap_or(&fr(0, 1)), c);
        if v.n == 0 { out.remove(&k); } else { out.insert(k, v); }
    }
    out
}
fn i(c: i128, k: [u32; 3]) -> (Fr, [u32; 3]) { (fr(c, 1), k) }
fn add(f: &Poly, g: &Poly) -> Poly {
    p(&f.iter().chain(g.iter()).map(|(&k, &c)| (c, k)).collect::<Vec<_>>())
}
fn mul(f: &Poly, g: &Poly) -> Poly {
    let mut t = Vec::new();
    for (a, &c) in f { for (b, &e) in g { t.push((fmul(c, e), [a[0] + b[0], a[1] + b[1], a[2] + b[2]])) } }
    p(&t)
}
fn combo(mults: &[Poly], gens: &[Poly]) -> Poly {
    mults.iter().zip(gens).fold(Poly::new(), |acc, (a, f)| add(&acc, &mul(a, f)))
}
fn show(f: &Poly, names: &str) -> String {         // leading term first
    let mut s = String::new();
    for (k, &c) in f.iter().rev() {
        let mono: String = names.chars().zip(k.iter()).filter(|(_, &e)| e > 0)
            .map(|(v, &e)| if e > 1 { format!("{}^{}", v, e) } else { v.to_string() }).collect();
        let a = fr(c.n.abs(), c.d);
        let body = if mono.is_empty() { fs(a) } else if a == fr(1, 1) { mono }
                   else if a.d == 1 { format!("{}{}", fs(a), mono) } else { format!("({}){}", fs(a), mono) };
        s += &if s.is_empty() { format!("{}{}", if c.n < 0 { "-" } else { "" }, body) }
              else { format!("{}{}", if c.n < 0 { " - " } else { " + " }, body) };
    }
    if s.is_empty() { "0".to_string() } else { s }
}
fn monos(n: usize, d: u32) -> Vec<[u32; 3]> {
    let lim = |j: usize| if j < n { d } else { 0 };
    let mut out = Vec::new();
    for a in 0..=lim(0) { for b in 0..=lim(1) { for c in 0..=lim(2) { if a + b + c <= d { out.push([a, b, c]) } } } }
    out
}
fn search(gens: &[Poly], target: &Poly, n: usize, d: u32) -> Option<Vec<Poly>> {
    let cols: Vec<(usize, [u32; 3])> = (0..gens.len()).flat_map(|g| monos(n, d).into_iter().map(move |k| (g, k))).collect();
    let prods: Vec<Poly> = cols.iter().map(|&(g, k)| mul(&p(&[i(1, k)]), &gens[g])).collect();
    let mut keys: BTreeSet<[u32; 3]> = target.keys().copied().collect();
    for q in &prods { keys.extend(q.keys().copied()) }
    let z = fr(0, 1);
    let mut rows: Vec<Vec<Fr>> = keys.iter().map(|k| prods.iter().chain([target])
        .map(|q| *q.get(k).unwrap_or(&z)).collect()).collect();
    let (mut piv, mut r) = (Vec::new(), 0);
    for c in 0..cols.len() {                         // Gauss-Jordan elimination, written out
        let Some(k) = (r..rows.len()).find(|&i| rows[i][c].n != 0) else { continue };
        rows.swap(r, k);
        let pv = rows[r][c]; rows[r] = rows[r].iter().map(|&v| fdiv(v, pv)).collect();
        for i in 0..rows.len() {
            let f = rows[i][c];
            if i != r && f.n != 0 {
                rows[i] = rows[i].iter().zip(&rows[r]).map(|(&a, &b)| fadd(a, fmul(fr(-1, 1), fmul(f, b)))).collect();
            }
        }
        piv.push(c); r += 1;
    }
    if rows[r..].iter().any(|row| row.last().unwrap().n != 0) { return None }
    let mut mults = vec![Poly::new(); gens.len()];
    for (i, &c) in piv.iter().enumerate() {
        let (g, k) = cols[c];
        mults[g] = add(&mults[g], &p(&[(*rows[i].last().unwrap(), k)]));
    }
    Some(mults)
}
fn none(r: &Option<Vec<Poly>>) -> &'static str { if r.is_none() { "no certificate at this degree" } else { "found" } }
fn count(gens: &[Poly], q: i128) -> Vec<(i128, i128)> {
    let ev = |f: &Poly, x: i128, y: i128| f.iter().map(|(k, c)| c.n * x.pow(k[0]) * y.pow(k[1])).sum::<i128>().rem_euclid(q);
    (0..q).flat_map(|x| (0..q).map(move |y| (x, y))).filter(|&(x, y)| gens.iter().all(|f| ev(f, x, y) == 0)).collect()
}
fn main() {
    let (x, y, one) = (p(&[i(1, [1, 0, 0])]), p(&[i(1, [0, 1, 0])]), p(&[i(1, [0, 0, 0])]));
    let neg = p(&[i(-1, [0, 0, 0])]);
    let primes: Vec<i128> = vec![2, 3, 5, 7];
    let f = vec![p(&[i(1, [1, 1, 0]), i(-1, [0, 0, 0])]), x.clone()];
    println!("system 1, over C: {} = 0 and {} = 0", show(&f[0], "xyz"), show(&f[1], "xyz"));
    let hand = combo(&[neg.clone(), y.clone()], &f);
    println!("road 1, the certificate by hand: (-1)({}) + (y)({}) = {}", show(&f[0], "xyz"), show(&f[1], "xyz"), show(&hand, "xyz"));
    let s0 = search(&f, &one, 2, 0);
    println!("road 2, search with constant multipliers: {}", none(&s0));
    let found = search(&f, &one, 2, 1).unwrap();
    println!("road 2, search with degree-1 multipliers: a1 = {}, a2 = {}", show(&found[0], "xyz"), show(&found[1], "xyz"));
    println!("road 2, expanded: {}", show(&combo(&found, &f), "xyz"));
    let pts1: Vec<usize> = primes.iter().map(|&q| count(&f, q).len()).collect();
    println!("road 3, common zeros over F_p for p = {:?}: {:?}", primes, pts1);
    println!("sign slip: (1)({}) + (y)({}) = {}", show(&f[0], "xyz"), show(&f[1], "xyz"), show(&combo(&[one.clone(), y.clone()], &f), "xyz"));
    let g = vec![p(&[i(1, [0, 1, 0]), i(-1, [2, 0, 0])]), y.clone()];
    println!("system 2, over C: {} = 0 and {} = 0", show(&g[0], "xyz"), show(&g[1], "xyz"));
    let pts2: Vec<Vec<(i128, i128)>> = primes.iter().map(|&q| count(&g, q)).collect();
    println!("common zeros over F_p for p = {:?}: {:?}, all at (0, 0): {}", primes, pts2.iter().map(|s| s.len()).collect::<Vec<_>>(),
             if pts2.iter().all(|s| *s == vec![(0, 0)]) { "yes" } else { "no" });
    let kill = |f: &Poly| -> Poly { f.iter().filter(|(k, _)| k[1] == 0 && k[0] < 2).map(|(&k, &c)| (k, c)).collect() };
    println!("the test map (y -> 0, then x^2 -> 0) sends the generators to {}, {} and x to {}",
             show(&kill(&g[0]), "xyz"), show(&kill(&g[1]), "xyz"), show(&kill(&x), "xyz"));
    println!("search for x = a1 g1 + a2 g2, degree <= 3: {}", none(&search(&g, &x, 2, 3)));
    let sq = search(&g, &mul(&x, &x), 2, 0).unwrap();
    println!("x^2 = ({})({}) + ({})({})", show(&sq[0], "xyz"), show(&g[0], "xyz"), show(&sq[1], "xyz"), show(&g[1], "xyz"));
    let rr = vec![g[0].clone(), g[1].clone(), p(&[i(1, [0, 0, 0]), i(-1, [1, 0, 1])])];
    let cert = search(&rr, &one, 3, 2).unwrap();
    println!("Rabinowitsch: 1 = sum a_i g_i with g3 = {}:", show(&rr[2], "xyz"));
    for j in 0..3 { println!("  a{} = {}", j + 1, show(&cert[j], "xyz")) }
    println!("  expanded: {}", show(&combo(&cert, &rr), "xyz"));
    let mz = cert[..2].iter().flat_map(|a| a.keys().map(|k| k[2])).max().unwrap();
    let back: Vec<Poly> = cert[..2].iter().map(|a| p(&a.iter().map(|(k, &c)| (c, [k[0] + mz - k[2], k[1], 0])).collect::<Vec<_>>())).collect();
    println!("put z = 1/x, multiply by x^{}: x^{} = ({})({}) + ({})({}), expanded {}", mz, mz, show(&back[0], "xyz"), show(&g[0], "xyz"),
             show(&back[1], "xyz"), show(&g[1], "xyz"), show(&combo(&back, &g), "xyz"));
    let h = vec![p(&[i(1, [2, 0, 0]), i(1, [0, 0, 0])])];
    let gi = |f: &Poly| { let t = [[1i128, 0, -1, 0], [0, 1, 0, -1]].map(|t| f.iter().map(|(k, c)| c.n * t[k[0] as usize % 4]).sum::<i128>()); (t[0], t[1]) };   // f at x = i
    println!("break 1: {} at x = i gives {:?}; search for 1, degree <= 4: {}", show(&h[0], "xyz"), gi(&h[0]), none(&search(&h, &one, 1, 4)));
    let zs: Vec<usize> = primes.iter().map(|&q| (0..q).filter(|&t| (t * t + 1) % q == 0).count()).collect();
    println!("break 1: zeros of {} over F_p for p = {:?}: {:?}", show(&h[0], "xyz"), primes, zs);
    let real1 = add(&mul(&x, &x), &mul(&neg, &h[0]));
    println!("break 1, real certificate: x^2 + (-1)({}) = {}", show(&h[0], "xyz"), show(&real1, "xyz"));
    let arm = |q: i128| vec![p(&[i(1, [2, 0, 0]), i(1, [0, 2, 0]), i(-9, [0, 0, 0])]),
                             p(&[i(1, [2, 0, 0]), i(-2 * q, [1, 0, 0]), i(1, [0, 2, 0]), i(q * q - 4, [0, 0, 0])])];
    let a6p = arm(6);
    println!("break 2, arm aimed 6 m away: {} = 0 and {} = 0", show(&a6p[0], "ab"), show(&a6p[1], "ab"));
    let a6 = fr(41, 12);
    let b6 = fadd(fr(9, 1), fmul(fr(-1, 1), fmul(a6, a6)));
    let d6 = fadd(a6, fr(-6, 1));
    let (r9, r4) = (fadd(fmul(a6, a6), b6), fadd(fmul(d6, d6), b6));
    println!("break 2, elbow a = {}, b^2 = {}; reach checks {} and {}", fs(a6), fs(b6), fs(r9), fs(r4));
    let lin = add(&a6p[0], &mul(&neg, &a6p[1]));
    let sos = p(&[(fr(144, 385), [0, 2, 0])]);
    let shift = p(&[(fr(1, 12), [1, 0, 0]), (fr(41, 144), [0, 0, 0])]);
    let in_i = add(&a6p[0], &mul(&neg, &mul(&shift, &lin)));
    let real2 = add(&sos, &mul(&p(&[(fr(-144, 385), [0, 0, 0])]), &in_i));
    println!("break 2: {} - ({}) = {}; in the ideal: {}", show(&a6p[0], "ab"), show(&a6p[1], "ab"), show(&lin, "ab"), show(&in_i, "ab"));
    println!("break 2, real certificate: {} - (144/385)({}) = {}", show(&sos, "ab"), show(&in_i, "ab"), show(&real2, "ab"));
    let a4 = fr(21, 8);
    let b4 = fadd(fr(9, 1), fmul(fr(-1, 1), fmul(a4, a4)));
    println!("arm at 4 m: elbow a = {}, b^2 = {}, b = +-{:.6} m", fs(a4), fs(b4), (b4.n as f64 / b4.d as f64).sqrt());
    let hyp: Vec<String> = [fr(1, 4), fr(1, 2), fr(1, 1), fr(2, 1), fr(4, 1)].iter().map(|&t| format!("({}, {})", fs(t), fs(fdiv(fr(1, 1), t)))).collect();
    println!("figure, hyperbola xy = 1 through {}", hyp.join(" "));
    let par: Vec<String> = [-2i64, -1, 0, 1, 2].iter().map(|t| format!("({}, {})", t, t * t)).collect();
    println!("figure, parabola y = x^2 through {} and the line y = 0, meeting at (0, 0)", par.join(" "));
    assert!(hand == one && combo(&found, &f) == one);                 // two certificates, expanded
    assert!(s0.is_none() && pts1 == vec![0, 0, 0, 0]);                // no point anywhere we can count
    assert!(kill(&g[0]).is_empty() && kill(&g[1]).is_empty() && kill(&x) == x);
    assert!(combo(&cert, &rr) == one && combo(&back, &g) == mul(&x, &x) && mz == 2);
    assert!(gi(&h[0]) == (0, 0) && real1 == neg && real2 == neg);
    assert!(r4 == fr(4, 1) && fadd(fmul(fadd(a4, fr(-4, 1)), fadd(a4, fr(-4, 1))), b4) == fr(4, 1) && b6.n < 0 && b4.n > 0);
    println!("ALL CHECKS PASS");
}
