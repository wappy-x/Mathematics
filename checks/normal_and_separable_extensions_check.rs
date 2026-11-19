// Normal and separable extensions -- the same check as the Python, in Rust.  No crates.
// A field is Q[x, y]/(f(x), g(y)), basis x^i y^j.  Road 1 searches for every root of f and g
// in it (degree n allows at most n roots) and counts automorphisms.  Road 2 measures what each
// automorphism group fixes, by rank.  Road 3 is evidence: how two cubics factor mod primes.
type V = Vec<i128>;
struct F { f: V, g: V, n: usize, m: usize }
fn cm(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }   // checked: an overflow stops the run
fn ca(a: i128, b: i128) -> i128 { a.checked_add(b).expect("overflow") }
fn field(f: &[i128], g: &[i128]) -> F { F { f: f.to_vec(), g: g.to_vec(), n: f.len() - 1, m: g.len() - 1 } }
fn cst(k: &F, c: i128) -> V { let mut v = vec![0; k.n * k.m]; v[0] = c; v }
fn add(a: &V, b: &V) -> V { a.iter().zip(b).map(|(u, v)| ca(*u, *v)).collect() }
fn mul(k: &F, a: &V, b: &V) -> V {
    let (n, m) = (k.n, k.m);
    let mut w = vec![vec![0i128; 2 * m - 1]; 2 * n - 1];
    for i in 0..n * m { for j in 0..n * m { w[i / m + j / m][i % m + j % m] = ca(w[i / m + j / m][i % m + j % m], cm(a[i], b[j])); } }
    for i in (n..2 * n - 1).rev() {             // x^n = -(f_0 + ... + f_(n-1) x^(n-1))
        for j in 0..2 * m - 1 { let c = w[i][j]; w[i][j] = 0; for t in 0..n { w[i - n + t][j] = ca(w[i - n + t][j], cm(c, -k.f[t])); } }
    }
    for row in w.iter_mut().take(n) {           // the same for y^m, using g
        for j in (m..2 * m - 1).rev() { let c = row[j]; row[j] = 0; for t in 0..m { row[j - m + t] = ca(row[j - m + t], cm(c, -k.g[t])); } }
    }
    (0..n * m).map(|i| w[i / m][i % m]).collect()
}
fn ev(k: &F, p: &[i128], a: &V) -> V {          // p(a) by Horner's rule
    let mut r = cst(k, p[p.len() - 1]);
    for c in p[..p.len() - 1].iter().rev() { r = add(&mul(k, &r, a), &cst(k, *c)); }
    r
}
fn roots(k: &F, p: &[i128], lo: i128, hi: i128) -> Vec<V> {
    let mut out: Vec<V> = vec![vec![]];         // every coordinate vector in a box
    for _ in 0..k.n * k.m { out = out.iter().flat_map(|v| (lo..=hi).map(move |c| { let mut w = v.clone(); w.push(c); w })).collect(); }
    out.into_iter().filter(|v| ev(k, p, v).iter().all(|&c| c == 0)).collect()
}
fn image(k: &F, a: &V, b: &V, e: &V) -> V {    // sum of e_ij A^i B^j
    let (mut out, mut pa) = (cst(k, 0), cst(k, 1));
    for i in 0..k.n {
        let mut pb = pa.clone();
        for j in 0..k.m {
            out = add(&out, &pb.iter().map(|c| cm(e[i * k.m + j], *c)).collect());
            pb = mul(k, &pb, b);
        }
        pa = mul(k, &pa, a);
    }
    out
}
fn unit(d: usize, k: usize) -> V { (0..d).map(|i| (i == k) as i128).collect() }
fn is_hom(k: &F, a: &V, b: &V) -> bool {      // respects every product of basis vectors
    let d = k.n * k.m; (0..d).all(|u| (0..d).all(|v| {
        let (eu, evv) = (unit(d, u), unit(d, v));
        image(k, a, b, &mul(k, &eu, &evv)) == mul(k, &image(k, a, b, &eu), &image(k, a, b, &evv))
    }))
}
fn autos(k: &F, rf: &[V], rg: &[V]) -> Vec<(V, V)> {
    rf.iter().flat_map(|a| rg.iter().map(move |b| (a.clone(), b.clone()))).filter(|(a, b)| is_hom(k, a, b)).collect()
}
fn gcd(a: i128, b: i128) -> i128 { if b != 0 { gcd(b, a % b) } else { a.abs() } }
fn binom(n: i128, k: i128) -> i128 { if k == 0 || k == n { 1 } else { ca(binom(n - 1, k - 1), binom(n - 1, k)) } }
fn rank(rows: Vec<V>) -> usize {                // integer elimination, no fractions
    let (mut rows, mut r): (Vec<V>, usize) = (rows.into_iter().filter(|r| r.iter().any(|&x| x != 0)).collect(), 0);
    for col in 0..if rows.is_empty() { 0 } else { rows[0].len() } {
        let piv = match (r..rows.len()).find(|&i| rows[i][col] != 0) { Some(p) => p, None => continue };
        rows.swap(r, piv);
        for i in 0..rows.len() {
            if i == r || rows[i][col] == 0 { continue; }
            let (c, p) = (rows[i][col], rows[r][col]);
            let new: V = rows[i].iter().zip(&rows[r]).map(|(x, y)| ca(cm(p, *x), cm(-1, cm(c, *y)))).collect();
            let g = new.iter().fold(0, |g, &x| gcd(g, x)).max(1);
            rows[i] = new.iter().map(|x| x / g).collect();
        }
        r += 1;
    }
    r
}
fn fixed_dim(k: &F, gr: &[(V, V)]) -> usize {  // dimension of what every map in G fixes
    let (d, mut rows) = (k.n * k.m, vec![]);
    for (a, b) in gr {
        let cols: Vec<V> = (0..d).map(|j| image(k, a, b, &unit(d, j))).collect();
        for i in 0..d { rows.push((0..d).map(|j| ca(cols[j][i], -((i == j) as i128))).collect()); }
    }
    d - rank(rows)
}
fn name(v: &V, s: &[&str]) -> String {         // coordinates as a readable sum
    let t: Vec<String> = v.iter().enumerate().filter(|(_, &c)| c != 0).map(|(k, &c)| if k == 0 { format!("{}", c) }
        else { format!("{}{}", match c { 1 => "".to_string(), -1 => "-".to_string(), _ => c.to_string() }, s[k]) }).collect();
    let j = t.join(" + ").replace("+ -", "- ");
    if j.is_empty() { "0".to_string() } else { j }
}
fn names(vs: &[V], s: &[&str]) -> String { vs.iter().map(|v| name(v, s)).collect::<Vec<_>>().join(", ") }
fn prem(mut a: V, b: &V) -> V {                 // pseudo-remainder over the integers
    while a.len() >= b.len() {
        let (c, s) = (a[a.len() - 1], a.len() - b.len());
        a = a.iter().map(|x| cm(*x, b[b.len() - 1])).collect();
        for (i, x) in b.iter().enumerate() { a[i + s] = ca(a[i + s], cm(-1, cm(c, *x))); }
        while a.last() == Some(&0) { a.pop(); }
    }
    a
}
fn gcd_deg(mut a: V, mut b: V) -> i64 {         // degree of gcd(a, b), Euclid's algorithm
    while !b.is_empty() { let r = prem(a, &b); a = b; b = r; }
    a.len() as i64 - 1
}
fn deriv(f: &[i128], p: i128) -> V {
    let mut d: V = f.iter().enumerate().skip(1).map(|(k, c)| if p > 0 { k as i128 * c % p } else { k as i128 * c }).collect();
    while d.last() == Some(&0) { d.pop(); }
    d
}
fn mod_roots(f: &[i128], p: i128) -> usize { (0..p).filter(|x| (f[0] + f[1] * x + x * x * x) % p == 0).count() }
fn main() {
    let (mut lo, mut hi) = (1.0f64, 2.0f64);    // the real cube root of 2, by bisection
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if mid * mid * mid < 2.0 { lo = mid } else { hi = mid } }
    println!("cube root of 2 = {:.6}; other roots {:.6} +/- {:.6} i", lo, -lo / 2.0, lo * 3f64.sqrt() / 2.0);
    let (l6, q3) = (field(&[-2, 0, 0, 1], &[1, 1, 1]), field(&[-2, 0, 0, 1], &[0, 1]));
    let (l8, q4) = (field(&[-2, 0, 0, 0, 1], &[1, 0, 1]), field(&[-2, 0, 0, 0, 1], &[0, 1]));
    let c3 = field(&[1, -3, 0, 1], &[0, 1]);
    let (s6, s8) = (["", "w", "a", "aw", "a^2", "a^2w"], ["", "i", "b", "bi", "b^2", "b^2i", "b^3", "b^3i"]);
    let (r6, w6) = (roots(&l6, &l6.f, -1, 1), roots(&l6, &l6.g, -1, 1));
    let (r8, i8) = (roots(&l8, &l8.f, -1, 1), roots(&l8, &l8.g, -1, 1));
    let (g6, g8) = (autos(&l6, &r6, &w6), autos(&l8, &r8, &i8));
    let restrict = |rs: &[V], n: usize| -> Vec<V> {
        rs.iter().filter(|v| (0..n).all(|i| v[2 * i + 1] == 0)).map(|v| (0..n).map(|i| v[2 * i]).collect()).collect() };
    let (in_q3, in_q4) = (restrict(&r6, 3), restrict(&r8, 4));
    let (gq3, gq4) = (autos(&q3, &in_q3, &[cst(&q3, 0)]), autos(&q4, &in_q4, &[cst(&q4, 0)]));
    let rc = roots(&c3, &c3.f, -2, 2);
    let gc = autos(&c3, &rc, &[cst(&c3, 0)]);
    let orbit: std::collections::BTreeSet<V> = g6.iter().map(|(a, b)| image(&l6, a, b, &vec![0, 1, 1, 0, 0, 0])).collect();   // images of a + w
    println!("L = Q(a, w), a^3 = 2, w^2 + w + 1 = 0; roots of x^3 - 2 in L: {}", names(&r6, &s6));
    println!("  roots of x^2 + x + 1 in L: {}; a + w has {} images", names(&w6, &s6), orbit.len());
    let (h3, h4, none) = (["", "a", "a^2"], ["", "b", "b^2", "b^3"], vec![]);
    let cases: [(&str, &F, &Vec<V>, &Vec<(V, V)>, &[&str]); 5] = [("L = Q(a, w)", &l6, &none, &g6, &s6),
        ("Q(a), x^3 - 2", &q3, &in_q3, &gq3, &h3), ("M = Q(b, i)", &l8, &none, &g8, &s8),
        ("Q(b), x^4 - 2", &q4, &in_q4, &gq4, &h4), ("Q(r), x^3 - 3x + 1", &c3, &rc, &gc, &["", "r", "r^2"])];
    for (lab, k, rs, gr, s) in cases.iter() {
        let inside = if rs.is_empty() { String::new() } else { format!("; roots inside: {}", names(rs, s)) };
        println!("{}: degree {}{}; automorphisms {}; fixed dimension {}", lab, k.n * k.m, inside, gr.len(), fixed_dim(k, gr));
    }
    let sig: (V, V) = (vec![0, 0, 0, 1, 0, 0, 0, 0], vec![0, -1, 0, 0, 0, 0, 0, 0]);   // b -> bi, i -> -i, order 2
    let nb = (0..8).filter(|&k| image(&l8, &sig.0, &sig.1, &unit(8, k)) == unit(8, k)).count();
    println!("M, the pair id and b -> bi, i -> -i (one of the 8: {}): basis vectors fixed {}; fixed dimension {} = 8 / 2", if g8.contains(&sig) { "True" } else { "False" }, nb, fixed_dim(&l8, &[sig.clone()]));
    let (mut sep, mut tally) = (vec![], vec![]);
    for (lab, a, b) in [("x^3 - 2", 0i128, -2i128), ("x^3 - 3x + 1", -3, 1), ("x^3 - 3x + 2", -3, 2)] {
        sep.push((gcd_deg(vec![b, a, 0, 1], deriv(&[b, a, 0, 1], 0)), -4 * a * a * a - 27 * b * b));
        println!("{}: gcd(f, f') degree {}; discriminant -4a^3 - 27b^2 = {}", lab, sep[sep.len() - 1].0, sep[sep.len() - 1].1);
    }
    for p in [2usize, 3] {
        let mut f = vec![0i128; p + 1]; f[p] = 1; let d = deriv(&f, p as i128);
        let mid: Vec<i128> = (1..p as i128).map(|k| binom(p as i128, k) % p as i128).collect();
        let k = if mid.iter().all(|&c| c == 0) { 1 } else { p };
        println!("char {}: x^{} - t has derivative {}; (x - s)^{} middle binomials mod {}: {:?}; degree {}, distinct roots {}, automorphisms {}",
                 p, p, if d.is_empty() { "0".to_string() } else { format!("{:?}", d) }, p, p, mid, p, k, k);
    }
    let primes: Vec<i128> = (2..1000).filter(|&p| (2..).take_while(|q| q * q <= p).all(|q| p % q != 0)).collect();
    for (lab, f, bad) in [("x^3 - 2", [-2i128, 0], vec![2i128, 3]), ("x^3 - 3x + 1", [1, -3], vec![3])] {
        let cnt: Vec<usize> = primes.iter().filter(|p| !bad.contains(p)).map(|&p| mod_roots(&f, p)).collect();
        let t: Vec<usize> = [0, 1, 3].iter().map(|k| cnt.iter().filter(|&&c| c == *k).count()).collect();
        println!("{}, {} primes below 1,000 (p not dividing the discriminant): 0 roots {}, 1 root {}, 3 roots {}", lab, cnt.len(), t[0], t[1], t[2]);
        tally.push(t);
    }
    let one2 = primes.iter().filter(|&&p| p % 3 == 2 && p > 2).all(|&p| mod_roots(&[-2, 0], p) == 1);
    println!("x^3 - 2 has exactly one root mod every prime p = 2 mod 3 above 2: {}", if one2 { "yes" } else { "no" });
    println!("mistake, complex roots counted as automorphisms: Q(a) {} against {}; Q(b) {} against {}; Q(a) fixes dimension {}, not 1",
             r6.len(), gq3.len(), r8.len(), gq4.len(), fixed_dim(&q3, &gq3));
    assert!(r6.len() == 3 && w6.len() == 2 && g6.len() == 6 && fixed_dim(&l6, &g6) == 1); // normal, separable
    assert!(gq3.len() == 1 && fixed_dim(&q3, &gq3) == 3 && orbit.len() == 6);           // not normal; primitive
    assert!(g8.len() == 8 && fixed_dim(&l8, &g8) == 1 && gq4.len() == 2 && fixed_dim(&q4, &gq4) == 2);
    assert!(g8.contains(&sig) && nb == 2 && fixed_dim(&l8, &[sig.clone()]) == 4);   // a fixed field off the basis
    assert!(gc.len() == 3 && fixed_dim(&c3, &gc) == 1 && tally[1][1] == 0 && one2);
    assert!(sep.iter().map(|&(g, d)| (g == 0, d != 0)).collect::<Vec<_>>() == [(true, true), (true, true), (false, false)]);  // two roads agree
    assert!(deriv(&[0, 0, 1], 2).is_empty() && deriv(&[0, 0, 0, 1], 3).is_empty());
    println!("ALL CHECKS PASS");
}
