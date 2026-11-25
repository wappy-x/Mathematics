// The sum-product problem -- the same check as the Python, in Rust.  No crates.
// Road 1 builds each sumset and product set as a set of values.  Road 2 gets
// the same counts without the set: a closed form, or a divisor test per number.
// Then a model of the 2026 recipe A = G.P in the whole numbers of Q(sqrt 2),
// computed exactly on pairs (a, b) meaning a + b sqrt 2, and the 2026 bound
// read at fixed degree.  Nothing here proves the conjecture or its refutation.
use std::collections::HashSet;

type Q2 = (i64, i64);

fn sums(a: &[i64]) -> usize { a.iter().flat_map(|x| a.iter().map(move |y| x + y)).collect::<HashSet<_>>().len() }
fn prods(a: &[i64]) -> usize { a.iter().flat_map(|x| a.iter().map(move |y| x * y)).collect::<HashSet<_>>().len() }

fn products_by_test(n: i64) -> usize {   // road 2: k is a product when some a <= n divides it with k/a <= n
    (1..=n * n).filter(|&k| (1..=n).any(|a| k % a == 0 && k / a <= n)).count()
}

fn expo(size: usize, n: usize) -> f64 { (size as f64).ln() / (n as f64).ln() }

fn mul(x: Q2, y: Q2) -> Q2 { (x.0 * y.0 + 2 * x.1 * y.1, x.0 * y.1 + x.1 * y.0) }
fn norm(x: Q2) -> i64 { x.0 * x.0 - 2 * x.1 * x.1 }

fn at_least(a: i64, b: i64, s: i64, t: i64) -> bool {   // is a + s*b*sqrt2 >= t?  exact
    let r = t - a;
    if s * b >= 0 { r <= 0 || 2 * b * b >= r * r } else { r < 0 && 2 * b * b <= r * r }
}

fn in_box(x: Q2, lo: i64, hi: i64) -> bool {   // both real images in [lo, hi)
    [1, -1].iter().all(|&s| at_least(x.0, x.1, s, lo) && !at_least(x.0, x.1, s, hi))
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> Q2 { let g = gcd(n, d); (n / g, d / g) }
fn fsums(q: &[Q2]) -> usize { q.iter().flat_map(|x| q.iter().map(move |y| frac(x.0 * y.1 + y.0 * x.1, x.1 * y.1))).collect::<HashSet<_>>().len() }
fn fprods(q: &[Q2]) -> usize { q.iter().flat_map(|x| q.iter().map(move |y| frac(x.0 * y.0, x.1 * y.1))).collect::<HashSet<_>>().len() }
fn show(q: Q2) -> String { if q.1 == 1 { format!("'{}'", q.0) } else { format!("'{}/{}'", q.0, q.1) } }

fn main() {
    let line: Vec<i64> = (1..=10).collect();
    let pow2: Vec<i64> = (0..10).map(|i| 1i64 << i).collect();
    let n: usize = 10;
    let (s_line, p_line, s_pow, p_pow) = (sums(&line), prods(&line), sums(&pow2), prods(&pow2));
    println!("A = 1..10:        |A+A| = {} (closed form 2n-1 = {}), |AA| = {} (divisor test {})", s_line, 2 * n - 1, p_line, products_by_test(10));
    println!("A = 1, 2, ..., 512: |A+A| = {} (closed form n(n+1)/2 = {}), |AA| = {} (closed form 2n-1 = {})", s_pow, n * (n + 1) / 2, p_pow, 2 * n - 1);
    println!("ordered pairs 10 x 10 = {}; distinct sums of 1..10 only {}", n * n, s_line);
    let mut table = Vec::new();
    for m in [10usize, 100, 1000] {
        let r: Vec<i64> = (1..=m as i64).collect();
        let t = prods(&r);
        table.push(t);
        println!("multiplication table 1..{}: {} distinct products of {}; exponent {:.4}", m, t, m * m, expo(t, m));
    }
    let test100 = products_by_test(100);
    println!("multiplication table 1..100 by divisor test: {}", test100);

    let q: Vec<Q2> = vec![(1, 2), (1, 3), (2, 3), (3, 4), (5, 6), (1, 1)];
    let d = 12;   // common denominator of the six fractions
    let z: Vec<i64> = q.iter().map(|f| f.0 * d / f.1).collect();
    println!("fractions [{}] times {} = {:?}", q.iter().map(|&f| show(f)).collect::<Vec<_>>().join(", "), d, z);
    println!("  sums {} and {}; products {} and {}", fsums(&q), sums(&z), fprods(&q), prods(&z));

    let (x, l, y) = (30i64, 30i64, 3usize);   // the box [X, X+L) for both images; units u^k with |k| <= Y
    let mut p: Vec<Q2> = Vec::new();
    for a in 0..4 * x { for b in -3 * x..3 * x { if in_box((a, b), x, x + l) { p.push((a, b)) } } }
    let (mut g, mut h, mut units) = ((1i64, 0i64), (1i64, 0i64), vec![(1i64, 0i64)]);
    for _ in 0..y { g = mul(g, (1, 1)); h = mul(h, (-1, 1)); units.push(g); units.push(h); }
    let a_set: HashSet<Q2> = units.iter().flat_map(|&u| p.iter().map(move |&v| mul(u, v))).collect();
    let a: Vec<Q2> = a_set.iter().copied().collect();
    let pp: HashSet<Q2> = p.iter().flat_map(|u| p.iter().map(move |v| (u.0 + v.0, u.1 + v.1))).collect();
    let sa: HashSet<Q2> = a.iter().flat_map(|u| a.iter().map(move |v| (u.0 + v.0, u.1 + v.1))).collect();
    let ma: HashSet<Q2> = a.iter().flat_map(|&u| a.iter().map(move |&v| mul(u, v))).collect();
    let nn = a.len();
    let inter = prods(&(1..=nn as i64).collect::<Vec<_>>());
    let pp_in = pp.iter().all(|&v| in_box(v, 2 * x, 2 * x + 2 * l));
    println!("Q(sqrt2) model, box [{}, {}), units (1+sqrt2)^k for |k| <= {}:", x, x + l, y);
    println!("  |P| = {}, |G| = {}, |A| = |G||P| = {}, counted {}", p.len(), units.len(), units.len() * p.len(), nn);
    println!("  |P+P| = {} = {:.2} x |P|, all inside the box [{}, {}): {}", pp.len(), pp.len() as f64 / p.len() as f64, 2 * x, 2 * x + 2 * l,
             if pp_in { "True" } else { "False" });
    println!("  |A+A| = {} = {:.1} x |A|, |AA| = {}; max exponent {:.4}", sa.len(), sa.len() as f64 / nn as f64, ma.len(), expo(sa.len().max(ma.len()), nn));
    println!("  interval 1..{}: |A+A| = {}, |AA| = {}; max exponent {:.4}", nn, 2 * nn - 1, inter, expo(inter, nn));
    let np = p.len() as i64;   // the same recipe in Z
    let b: Vec<i64> = (0..=2 * y as u32).flat_map(|k| (np..2 * np).map(move |v| (1i64 << k) * v)).collect::<HashSet<_>>().into_iter().collect();
    let (sb, mb) = (sums(&b), prods(&b));
    println!("  whole numbers 2^k x [{}, {}), 0 <= k <= {}: |A| = {}, |A+A| = {}, |AA| = {}; max exponent {:.4}",
             np, 2 * np, 2 * y, b.len(), sb, mb, expo(sb.max(mb), b.len()));
    println!("2026 bound |AA| <= 2^-d |A|^2, saving 2^-d written as |A|^-s:");
    for k in [3i32, 6, 9] {
        let big = 10f64.powi(k).ln();
        println!("  |A| = 1e{}: d = 1 gives s = {:.4}, d = 2 gives s = {:.4}", k, 2f64.ln() / big, 2.0 * 2f64.ln() / big);
    }
    println!("exponent windows: proved floor 4/3 + 2/1167 = {:.6}; claimed floor 4/3 + 10/4407 = {:.6}; claimed ceiling over the reals 2 - 0.00000087 = {:.8}",
             4.0 / 3.0 + 2.0 / 1167.0, 4.0 / 3.0 + 10.0 / 4407.0, 2.0 - 0.00000087);
    let bars: Vec<(String, f64)> = vec![("1..10".into(), expo(p_line, 10)), ("1, 2, ..., 512".into(), expo(s_pow, 10)),
        ("1..1000".into(), expo(table[2], 1000)), (format!("1..{}", nn), expo(inter, nn)),
        ("Z, 2^k x box".into(), expo(sb.max(mb), b.len())), ("Q(sqrt2) model".into(), expo(sa.len().max(ma.len()), nn))];
    for (name, e) in &bars {
        println!("  {:<15} {:<40} {:.4}", name, "#".repeat((40.0 * (e - 1.0)).round() as usize), e);
    }

    assert!((s_line, p_line, s_pow, p_pow) == (2 * n - 1, products_by_test(10), n * (n + 1) / 2, 2 * n - 1));
    assert!(table[1] == test100 && test100 == 2906);
    assert!((fsums(&q), fprods(&q)) == (sums(&z), prods(&z)));
    assert!(nn == units.len() * p.len() && p[..40].iter().all(|&u| units.iter().all(|&v| norm(mul(u, v)) == norm(u) * norm(v))));
    assert!(pp_in && pp.len() <= 4 * p.len());
    assert!(sa.len().max(ma.len()) < inter && b.len() == nn);
    println!("ALL CHECKS PASS");
}
