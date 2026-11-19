// Field extensions and degree -- the same check as the Python, in Rust.  No
// crates.  The field Q(a), a = 2^(1/4), is stored as Q[x]/(x^4 - 2): a number is
// four rational coordinates on the basis 1, a, a^2, a^3.  The degree 4 comes by
// three roads: a complete factor search, Eisenstein's test at 2, and the tower
// Q < Q(r2) < Q(a), whose two steps of 2 multiply.  r2 is the square root of 2.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
struct Q { n: i128, d: i128 }              // a fraction in lowest terms, d > 0

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1) * d.signum();
    Q { n: n / g, d: d / g }
}
fn add(x: Q, y: Q) -> Q { q(x.n.checked_mul(y.d).unwrap().checked_add(y.n.checked_mul(x.d).unwrap()).unwrap(), x.d.checked_mul(y.d).unwrap()) }
fn sub(x: Q, y: Q) -> Q { add(x, Q { n: y.n.checked_neg().unwrap(), d: y.d }) }
fn mulq(x: Q, y: Q) -> Q { q(x.n.checked_mul(y.n).unwrap(), x.d.checked_mul(y.d).unwrap()) }
fn divq(x: Q, y: Q) -> Q { q(x.n.checked_mul(y.d).unwrap(), x.d.checked_mul(y.n).unwrap()) }
fn z(k: i128) -> Q { Q { n: k, d: 1 } }
fn cmpq(x: Q, y: Q) -> std::cmp::Ordering { x.n.checked_mul(y.d).unwrap().cmp(&y.n.checked_mul(x.d).unwrap()) }

fn mul(u: &[Q], v: &[Q], f: &[i128]) -> Vec<Q> {     // multiply, then trade x^n for -(f - x^n)
    let n = f.len() - 1;
    let mut prod = vec![z(0); 2 * n - 1];
    for (i, &x) in u.iter().enumerate() { for (j, &y) in v.iter().enumerate() { prod[i + j] = add(prod[i + j], mulq(x, y)) } }
    for k in (n..=2 * n - 2).rev() {
        let c = std::mem::replace(&mut prod[k], z(0));
        for i in 0..n { prod[k - n + i] = sub(prod[k - n + i], mulq(c, z(f[i]))) }
    }
    prod[..n].to_vec()
}
fn reduce(rows: &[Vec<Q>]) -> (Vec<Vec<Q>>, usize) {  // Gauss-Jordan over Q: (reduced rows, rank)
    let mut rows = rows.to_vec();
    let mut r = 0;
    for col in 0..rows[0].len() {
        let piv = match (r..rows.len()).find(|&i| rows[i][col].n != 0) { Some(p) => p, None => continue };
        rows.swap(r, piv);
        let p = rows[r][col];
        rows[r] = rows[r].iter().map(|&x| divq(x, p)).collect();
        for i in 0..rows.len() {
            if i != r && rows[i][col].n != 0 {
                let t = rows[i][col];
                let pr = rows[r].clone();
                rows[i] = rows[i].iter().zip(pr.iter()).map(|(&x, &y)| sub(x, mulq(t, y))).collect();
            }
        }
        r += 1;
    }
    (rows, r)
}
fn degree(beta: &[Q], f: &[i128]) -> usize {         // first n with 1, beta, ..., beta^n dependent
    let mut powers = vec![e(0, f.len() - 1)];
    loop {
        let nxt = mul(powers.last().unwrap(), beta, f);
        let all = [powers.clone(), vec![nxt.clone()]].concat();
        if reduce(&all).1 == powers.len() { return powers.len() }
        powers.push(nxt);
    }
}

fn e(k: usize, n: usize) -> Vec<Q> { (0..n).map(|i| z((i == k) as i128)).collect() }
fn divisors(n: i128) -> Vec<i128> { (1..=n.abs()).filter(|d| n % d == 0).collect() }

fn rational_roots(c: &[i128]) -> Vec<Q> {             // every candidate p/q, p | constant, q | leading
    let mut cands: Vec<Q> = Vec::new();
    for p in divisors(c[0]) { for qq in divisors(*c.last().unwrap()) { for s in [1, -1] { cands.push(q(s * p, qq)) } } }
    cands.sort_by(|x, y| cmpq(*x, *y));
    cands.dedup();
    cands.into_iter().filter(|&r| {
        let (mut val, mut pw) = (z(0), z(1));
        for &ci in c { val = add(val, mulq(z(ci), pw)); pw = mulq(pw, r) }
        val.n == 0
    }).collect()
}
fn quadratic_factors(c: &[i128]) -> Vec<(i128, i128, i128, i128)> {   // (x^2+ax+b)(x^2+gx+d)?
    let bound = 2 * (1 + c[..4].iter().map(|x| x.abs()).max().unwrap());
    let mut found = Vec::new();
    for dv in divisors(c[0]) { for s in [1, -1] {
        let b = s * dv;
        let d = c[0] / b;
        for a in -bound..=bound {
            let g = c[3] - a;
            if (b + d + a * g, a * d + b * g) == (c[2], c[1]) && (a, b) <= (g, d) { found.push((a, b, g, d)) }
        }
    } }
    found
}
fn eisenstein(c: &[i128], p: i128) -> bool {
    let k = c.len() - 1;
    c[..k].iter().all(|x| x % p == 0) && c[0] % (p * p) != 0 && c[k] % p != 0
}
fn gf2_mul(mut u: u32, mut v: u32, f: u32, n: u32) -> u32 {   // GF(2) polynomials as bit masks
    let mut out = 0;
    while v != 0 {
        if v & 1 == 1 { out ^= u }
        v >>= 1; u <<= 1;
        if (u >> n) & 1 == 1 { u ^= f }
    }
    out
}
fn fq(x: &Q) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }
fn show(v: &[Q]) -> String { format!("[{}]", v.iter().map(fq).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (f4, f6, g4): (Vec<i128>, Vec<i128>, Vec<i128>) = (vec![-2, 0, 0, 0, 1], vec![-2, 0, 0, 0, 0, 0, 1], vec![4, 0, 0, 0, 1]);
    let (one, a, r2) = (e(0, 4), e(1, 4), e(2, 4));
    let (rr4, qf4) = (rational_roots(&f4), quadratic_factors(&f4));
    let (step1, step2) = (rational_roots(&[-2, 0, 1]), rational_roots(&[1, 0, 0, 0, 2]));
    let deg_r2 = degree(&r2, &f4);
    let tower = (if step1.is_empty() { 2 } else { 1 }) * (if step2.is_empty() { 2 } else { 1 });
    let products: Vec<Vec<Q>> = [&one, &r2].iter().flat_map(|x| [&one, &a].map(|y| mul(x, y, &f4))).collect();
    let names = ["3", "a", "a^2", "a^3", "a + a^2", "1 + a^2"];
    let elems: Vec<Vec<Q>> = [[3, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [0, 1, 1, 0], [1, 0, 1, 0]]
        .iter().map(|v| v.iter().map(|&k| z(k)).collect()).collect();
    let degs: Vec<usize> = elems.iter().map(|v| degree(v, &f4)).collect();
    let outside = reduce(&[one.clone(), r2.clone(), a.clone()]).1;
    let one_plus_a = vec![z(1), z(1), z(0), z(0)];
    let cols: Vec<Vec<Q>> = (0..4).map(|j| mul(&one_plus_a, &e(j, 4), &f4)).collect();
    let aug: Vec<Vec<Q>> = (0..4).map(|i| { let mut r: Vec<Q> = (0..4).map(|j| cols[j][i]).collect(); r.push(one[i]); r }).collect();
    let inv: Vec<Q> = reduce(&aug).0.iter().map(|r| r[4]).collect();
    let series = vec![z(-1), z(1), z(-1), z(1)];          // (1 + a)(1 - a + a^2 - a^3) = 1 - a^4 = -1
    let x = 2f64.sqrt().sqrt();
    let d6: Vec<usize> = [3, 2, 1].iter().map(|&k| degree(&e(k, 6), &f6)).collect();
    let (qg4, rg4, rg2) = (quadratic_factors(&g4), rational_roots(&g4), rational_roots(&[2, -2, 1]));
    let pos = (rational_roots(&[-4, 0, 1]), rational_roots(&[-1, 0, 0, 0, 1]), eisenstein(&g4, 2));
    let real = (-300..300).filter(|&k| ((k as f64 / 100.0).powi(4) - 2.0) * (((k + 1) as f64 / 100.0).powi(4) - 2.0) < 0.0).count();
    let gf8_ok = (1..8).all(|u| (1..8).any(|v| gf2_mul(u, v, 0b1011, 3) == 1));
    let w8 = (0..8).filter(|&w| gf2_mul(w, w, 0b1011, 3) ^ w ^ 1 == 0).count();
    let w16 = (0..16).filter(|&w| gf2_mul(w, w, 0b10011, 4) ^ w ^ 1 == 0).count();
    let aes = 0b100011011;                                // x^8 + x^4 + x^3 + x + 1
    let aes_units = (1..256).filter(|&u| (1..256).any(|v| gf2_mul(u, v, aes, 8) == 1)).count();
    let aes_ex = gf2_mul(0x57, 0x83, aes, 8);
    let (prods, da): (Vec<String>, usize) = (products.iter().map(|p| show(p)).collect(), degree(&a, &f4));
    println!("a = 2^(1/4) = {:.11}; Q(a) stored on the basis 1, a, a^2, a^3", x);
    println!("road 1, factor search on x^4 - 2, roots under {}: rational roots {}, quadratic factors {:?}: {}",
             1 + f4[..4].iter().map(|c| c.abs()).max().unwrap(), show(&rr4), qf4, if rr4.is_empty() && qf4.is_empty() { "irreducible" } else { "factors" });
    println!("road 2, Eisenstein at 2 on x^4 - 2: {}", yn(eisenstein(&f4, 2)));
    println!("road 3, x^2 - 2 rational roots {}: [Q(r2):Q] = 2; dependence search on r2 = a^2: {}", show(&step1), deg_r2);
    println!("        x^2 - r2 has a root in Q(r2) only if 2t^4 + 1 has a rational root: {}: [Q(a):Q(r2)] = 2", show(&step2));
    println!("        tower: [Q(a):Q] = 2 x 2 = {}", tower);
    println!("other answers: rational roots of x^2 - 4 {}, of x^4 - 1 {}; Eisenstein at 2 on x^4 + 4: {}", show(&pos.0), show(&pos.1), yn(pos.2));
    println!("basis products 1, a, r2, r2 a as coordinates: {}; rank {}", prods.join(" "), reduce(&products).1);
    println!("a outside Q(r2): rank of 1, r2, a is {}", outside);
    println!("degrees over Q of {}: {:?}", names.join(", "), degs);
    println!("every degree divides 4: {}; so no element has degree 3", yn(degs.iter().all(|d| 4 % d == 0)));
    println!("1/(1 + a) by solving the 4 x 4 system: {}", show(&inv));
    println!("1/(1 + a) by the geometric series:    {}; product {}", show(&series), show(&mul(&one_plus_a, &inv, &f4)));
    println!("as decimals: 1/(1 + a) = {:.12}; -1 + a - a^2 + a^3 = {:.12}", 1.0 / (1.0 + x), -1.0 + x - x * x + x * x * x);
    println!("x^6 - 2: Eisenstein at 2 {}; degrees of r2, 2^(1/3), 2^(1/6): {:?}", yn(eisenstein(&f6, 2)), d6);
    println!("tower law on Q < Q(2^(1/3)) < Q(2^(1/6)): top step = {} / {} = {}", d6[2], d6[1], d6[2] / d6[1]);
    println!("splitting field Q(a, i): i is not real and Q(a) is, so the top step is 2; tower law 4 x 2 = {}", tower * 2);
    println!("GF(8) = GF(2)[x]/(x^3 + x + 1): {} elements, all nonzero invertible: {}", 2u32.pow(3), yn(gf8_ok));
    println!("roots of w^2 + w + 1: in GF(8) {}, in GF(16) {}", w8, w16);
    println!("GF(256) with x^8 + x^4 + x^3 + x + 1: {} of 255 nonzero bytes invertible; 57 x 83 = {:02x}", aes_units, aes_ex);
    println!("mistake 1, x^4 + 4: rational roots {}, yet quadratic factors {:?}", show(&rg4), qg4);
    println!("           its root 1 + i solves x^2 - 2x + 2, rational roots {}: degree 2, not 4", show(&rg2));
    println!("mistake 2, adding up the tower: 3 + 2 = {}, true degree {}", d6[1] + 2, d6[2]);
    println!("mistake 3, base field dropped: a has degree {} over Q(r2), {} over Q", da / deg_r2, da);
    println!("symmetries: x^4 - 2 changes sign {} times on [-3, 3], so the real field Q(a) holds {} of its roots: {} symmetries, not 4", real, real, real);
    assert!(rr4.is_empty() && qf4.is_empty() && eisenstein(&f4, 2));     // roads 1 and 2
    assert!(tower == 4 && deg_r2 == 2);                                  // road 3
    assert!(pos.0 == vec![z(-2), z(2)] && pos.1 == vec![z(-1), z(1)] && !pos.2 && real == 2);   // the tests can say the other thing
    assert!(reduce(&products).1 == 4 && outside == 3);
    assert!(degs == vec![1, 4, 2, 4, 4, 2]);
    assert!(inv == series && mul(&one_plus_a, &inv, &f4) == one);
    assert!(((-1.0 + x - x * x + x * x * x) - 1.0 / (1.0 + x)).abs() < 1e-12);
    assert!(d6 == vec![2, 3, 6] && qg4 == vec![(-2, 2, 2, 2)] && rg4.is_empty() && rg2.is_empty());
    assert!(gf8_ok && (w8, w16) == (0, 2) && aes_units == 255 && aes_ex == 0xC1);
    println!("ALL CHECKS PASS");
}
