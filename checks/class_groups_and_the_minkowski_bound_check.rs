// Class groups and the Minkowski bound, in the imaginary quadratic fields Q(sqrt m), m < 0.
// A number x + y*w is the pair (x, y), with w = sqrt(m), or w = (1 + sqrt(m))/2 when m = 1 mod 4.
// An ideal is (a, b, c): the whole numbers x*a + y*(b + c*w), a lattice in Hermite normal form.
use std::collections::BTreeSet;
type E = (i64, i64);
type I = (i64, i64, i64);

fn m1(m: i64) -> bool { m.rem_euclid(4) == 1 }
fn disc(m: i64) -> i64 { if m1(m) { m } else { 4 * m } }
fn mul(m: i64, u: E, v: E) -> E {
    let (s, r) = if m1(m) { ((m - 1) / 4, 1) } else { (m, 0) }; // w*w = s + r*w
    let t = u.1 * v.1;
    (u.0 * v.0 + t * s, u.0 * v.1 + u.1 * v.0 + t * r)
}
fn norm(m: i64, u: E) -> i64 { let (x, y) = u; if m1(m) { x * x + x * y + (1 - m) / 4 * y * y } else { x * x - m * y * y } }
fn conj(m: i64, u: E) -> E { if m1(m) { (u.0 + u.1, -u.1) } else { (u.0, -u.1) } }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }

fn hnf(vs: Vec<E>) -> I { // the lattice spanned by integer vectors, as (a, b, c)
    let mut vs: Vec<E> = vs.into_iter().filter(|v| *v != (0, 0)).collect();
    while vs.iter().filter(|v| v.1 != 0).count() > 1 {
        vs.sort_by_key(|v| (v.1 == 0, v.1.abs()));
        let p = vs[0];
        let rest: Vec<E> = vs[1..].iter().map(|v| { let k = v.1.div_euclid(p.1); (v.0 - k * p.0, v.1 - k * p.1) }).collect();
        vs = vec![p]; vs.extend(rest);
    }
    let mut p = *vs.iter().find(|v| v.1 != 0).unwrap();
    if p.1 < 0 { p = (-p.0, -p.1); }
    let a = vs.iter().filter(|v| v.1 == 0).fold(0, |g, v| gcd(g, v.0));
    (a, p.0.rem_euclid(a), p.1)
}
fn basis(i: I) -> [E; 2] { [(i.0, 0), (i.1, i.2)] }
fn ideal(m: i64, gens: &[E]) -> I { let mut v = gens.to_vec(); for g in gens { v.push(mul(m, *g, (0, 1))); } hnf(v) }
fn imul(m: i64, a: I, b: I) -> I { let mut v = vec![]; for u in basis(a) { for w in basis(b) { v.push(mul(m, u, w)); } } hnf(v) }
fn iconj(m: i64, a: I) -> I { hnf(basis(a).iter().map(|u| conj(m, *u)).collect()) }
fn has(i: I, u: E) -> bool { u.1.rem_euclid(i.2) == 0 && (u.0 - u.1 / i.2 * i.1).rem_euclid(i.0) == 0 }
fn gen(m: i64, i: I) -> Option<E> { // a generator if the ideal is principal: an element whose norm is N(I)
    let n = i.0 * i.2; let yy = 2 * isqrt(n / -m) + 2; let xx = isqrt(n) + yy;
    for y in -yy..=yy { for x in -xx..=xx {
        if norm(m, (x, y)) == n && has(i, (x, y)) { return Some(std::cmp::max((x, y), (-x, -y))); }
    } }
    None
}
fn same_class(m: i64, a: I, b: I) -> bool { gen(m, imul(m, a, iconj(m, b))).is_some() }
fn ideals_upto(m: i64, b: i64) -> Vec<I> { // every ideal of norm <= B: lattices closed under multiplying by w
    let mut out = vec![];
    for n in 1..=b { for c in 1..=n { if n % c != 0 { continue; } for bb in 0..n / c {
        let i = (n / c, bb, c);
        if has(i, (0, i.0)) && has(i, mul(m, (bb, c), (0, 1))) { out.push(i); }
    } } }
    out
}
fn class_group(m: i64, gens: &[I]) -> Vec<I> { // multiply out the generators until no new class appears
    let mut reps = vec![(1, 0, 1)]; let mut k = 0;
    while k < reps.len() {
        for g in gens { let p = imul(m, reps[k], *g); if !reps.iter().any(|s| same_class(m, p, *s)) { reps.push(p); } }
        k += 1;
    }
    reps
}
fn order(m: i64, i: I) -> i64 { let (mut k, mut p) = (1, i); while gen(m, p).is_none() { k += 1; p = imul(m, p, i); } k }
fn forms(d: i64) -> Vec<I> { // road 2: Gauss's reduced forms a x^2 + b x y + c y^2, b^2 - 4ac = d
    let mut out = vec![]; let mut a = 1;
    while 3 * a * a <= -d {
        for b in -a + 1..=a {
            if (b * b - d) % (4 * a) == 0 {
                let c = (b * b - d) / (4 * a);
                if c >= a && !(b < 0 && a == c) && gcd(gcd(a, b), c) == 1 { out.push((a, b, c)); }
            }
        }
        a += 1;
    }
    out
}
fn kron(d: i64, n0: i64) -> i64 { // the Kronecker symbol (d/n), n > 0
    let (mut r, mut n) = (1, n0);
    while n % 2 == 0 { n /= 2; if d % 2 == 0 { return 0; } r *= if [1, 7].contains(&d.rem_euclid(8)) { 1 } else { -1 }; }
    let mut a = d.rem_euclid(n);
    while a != 0 {
        while a % 2 == 0 { a /= 2; if [3, 5].contains(&(n % 8)) { r = -r; } }
        std::mem::swap(&mut a, &mut n);
        if a % 4 == 3 && n % 4 == 3 { r = -r; }
        a %= n;
    }
    if n == 1 { r } else { 0 }
}
fn h_formula(d: i64) -> (i64, i64) { // road 3: h = -(w_K / 2|d|) * sum of kron(d, a) * a for 0 < a < |d|
    let w = if d == -3 { 6 } else if d == -4 { 4 } else { 2 };
    let s: i64 = (1..-d).map(|a| kron(d, a) * a).sum(); (s, -w * s / (2 * -d))
}
fn mink(m: i64) -> f64 { 2.0 / std::f64::consts::PI * ((-disc(m)) as f64).sqrt() }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn sh(g: Option<E>) -> String { match g { Some(u) => format!("{:?}", u), None => "none".to_string() } }
fn pairs(m: i64, n: i64) -> Vec<Vec<E>> { // factorisations n = u * v into two non-units of Z[sqrt-5], up to sign and order
    let mut out = BTreeSet::new();
    for x in -n..=n { for y in -n..=n {
        let nn = norm(m, (x, y)); let t = mul(m, (n, 0), conj(m, (x, y)));
        if 1 < nn && nn < n * n && t.0 % nn == 0 && t.1 % nn == 0 {
            let mut f: Vec<E> = [(x, y), (t.0 / nn, t.1 / nn)].iter().map(|u| std::cmp::max(*u, (-u.0, -u.1))).collect();
            f.sort(); f.dedup(); out.insert(f);
        }
    } }
    out.into_iter().collect()
}
fn groupings(m: i64, j: [I; 4]) -> usize { // ways to split four prime ideals into two pairs with principal products
    let mut out = BTreeSet::new();
    for [a, b, c, d] in [[0, 1, 2, 3], [0, 2, 1, 3], [0, 3, 1, 2]] {
        let (x, y) = (imul(m, j[a], j[b]), imul(m, j[c], j[d]));
        if gen(m, x).is_some() && gen(m, y).is_some() { out.insert(if x <= y { (x, y) } else { (y, x) }); }
    }
    out.len()
}
fn main() {
    let m = -5; let mk = mink(m);
    println!("Q(sqrt -5): d_K = {}, degree 2, r1 = 0, r2 = 1, Minkowski bound M_K = (2/pi) sqrt 20 = {:.6}", disc(m), mk);
    let small = ideals_upto(m, mk as i64); println!("ideals of norm <= M_K, as (a, b, c): {:?}", small);
    let p = ideal(m, &[(2, 0), (1, 1)]); let q = ideal(m, &[(3, 0), (1, 1)]); let q2 = ideal(m, &[(3, 0), (1, -1)]);
    let sols = (-2..3i64).flat_map(|x| (-1..2i64).map(move |y| (x, y))).filter(|(x, y)| x * x + 5 * y * y == 2).count();
    println!("p2 = (2, 1 + sqrt-5) = {:?} ; solutions of x^2 + 5y^2 = 2: {} ; p2^2 = (2): {}", p, sols, yn(imul(m, p, p) == ideal(m, &[(2, 0)])));
    let cl = class_group(m, &small[1..]); let fm = forms(-20); let (s, hf) = h_formula(-20);
    println!("road 1, Minkowski search: h = {} ; road 2, reduced forms {:?} h = {} ; road 3, formula: sum = {} h = {}", cl.len(), fm, fm.len(), s, hf);
    assert!(sols == 0 && cl.len() == 2 && fm.len() == 2 && hf == 2);
    let (i2, i3, a, b) = (ideal(m, &[(2, 0)]), ideal(m, &[(3, 0)]), ideal(m, &[(1, 1)]), ideal(m, &[(1, -1)]));
    let fact = [i2 == imul(m, p, p), i3 == imul(m, q, q2), a == imul(m, p, q), b == imul(m, p, q2)];
    println!("6 = 2 x 3 = (1 + sqrt-5)(1 - sqrt-5); (2) = p2 p2, (3) = p3 p3bar, (1 + sqrt-5) = p2 p3, (1 - sqrt-5) = p2 p3bar: {}", yn(fact.iter().all(|f| *f)));
    println!("generators: p2, p3, p3bar {} {} {} ; p2 p3, p2 p3bar, p3 p3bar {} {} {}", sh(gen(m, p)), sh(gen(m, q)), sh(gen(m, q2)),
        sh(gen(m, imul(m, p, q))), sh(gen(m, imul(m, p, q2))), sh(gen(m, imul(m, q, q2))));
    assert!(fact.iter().all(|f| *f) && gen(m, p).is_none() && gen(m, q).is_none() && gen(m, imul(m, q, q2)) == Some((3, 0)));
    let r = ideal(m, &[(7, 0), (3, 1)]); let r2 = ideal(m, &[(7, 0), (3, -1)]);
    for (n, j) in [(6, [p, p, q, q2]), (21, [q, q2, r, r2])] {
        let (f, g) = (pairs(m, n), groupings(m, j));
        println!("{}: factorisations found by search {:?}; pairings of its prime ideals {}", n, f, g);
        assert!(f.len() == g);
    }
    println!("no element has norm 2, 3 or 7: {}", yn((0..3i64).all(|x| (0..2i64).all(|y| ![2, 3, 7].contains(&(x * x + 5 * y * y))))));
    let all = ideals_upto(m, 60); let npr: Vec<I> = all.iter().cloned().filter(|j| gen(m, *j).is_none()).collect();
    let cnt: i64 = (1..61).map(|n| (1..=n).filter(|e| n % e == 0).map(|e| kron(-20, e)).sum::<i64>()).sum();
    let ok = npr.iter().all(|j| gen(m, imul(m, *j, p)).is_some());
    println!("ideals of norm <= 60: {} (divisor sum of kron(-20, e): {}); not principal {}; each of those times p2 principal: {}", all.len(), cnt, npr.len(), yn(ok));
    assert!(all.len() as i64 == cnt && ok);
    println!("m, d_K, M_K, ideals searched, h by search, h by forms, h by formula, orders of the classes");
    for m in [-1, -2, -3, -5, -6, -14, -21, -23, -163] {
        let d = disc(m); let g = ideals_upto(m, mink(m) as i64); let cl = class_group(m, &g[1..]);
        let mut od: Vec<i64> = cl.iter().map(|j| order(m, *j)).collect(); od.sort();
        println!("{} {} {:.4} {} {} {} {} {:?}", m, d, mink(m), g.len(), cl.len(), forms(d).len(), h_formula(d).1, od);
        assert!(cl.len() == forms(d).len() && cl.len() as i64 == h_formula(d).1);
    }
    let sqf = |n: i64, k0: i64, st: usize| (k0..=isqrt(n.abs())).step_by(st).all(|k| n % (k * k) != 0);
    let fund: Vec<i64> = (-1000i64..=-3).rev().filter(|&d| (d.rem_euclid(4) == 1 && sqf(d, 3, 2))
        || (d % 4 == 0 && [2, 3].contains(&(d / 4).rem_euclid(4)) && sqf(d / 4, 2, 1))).collect();
    let one: Vec<i64> = fund.iter().cloned().filter(|&d| forms(d).len() == 1).collect();
    println!("fundamental discriminants from -3 to -1000: {}; class number 1: {:?}", fund.len(), one);
    assert!(one == vec![-3, -4, -7, -8, -11, -19, -43, -67, -163]);
    let ps: Vec<i64> = (2..200).filter(|&n| (2..=isqrt(n)).all(|k| n % k != 0)).collect();
    let f1: Vec<i64> = ps.iter().cloned().filter(|&n| (0..15).any(|x: i64| (0..7).any(|y: i64| x * x + 5 * y * y == n))).collect();
    let f2: Vec<i64> = ps.iter().cloned().filter(|&n| (-10..11).any(|x: i64| (-10..11).any(|y: i64| 2 * x * x + 2 * x * y + 3 * y * y == n))).collect();
    println!("primes below 200 of the form x^2 + 5y^2: {:?}", f1); println!("of the form 2x^2 + 2xy + 3y^2: {:?}", f2);
    assert!(f1 == ps.iter().cloned().filter(|&n| n == 5 || [1, 9].contains(&(n % 20))).collect::<Vec<i64>>());
    assert!(f2 == ps.iter().cloned().filter(|&n| n == 2 || [3, 7].contains(&(n % 20))).collect::<Vec<i64>>());
    let cg = |m: i64, b: i64| class_group(m, &ideals_upto(m, b)[1..]);
    println!("what breaks: Q(sqrt -14) searched only to norm 2: {} classes; to the bound {:.4}: {}", cg(-14, 2).len(), mink(-14), cg(-14, 4).len());
    println!("what breaks: Q(sqrt -23), ideals of norm <= M_K counted as classes: {} ; true h {}", ideals_upto(-23, 3).len(), forms(-23).len());
    println!("what breaks: Z[sqrt -11] taken for the ring of integers: forms of discriminant -44 give {} ; true h {}", forms(-44).len(), forms(-11).len());
    let ords = |m: i64, b: i64| { let mut o: Vec<i64> = cg(m, b).iter().map(|j| order(m, *j)).collect(); o.sort(); o };
    let (o14, o21) = (ords(-14, 4), ords(-21, 5)); println!("what breaks: h = 4 for both, class orders -14 {:?} -21 {:?}", o14, o21); assert!(o14 == [1, 2, 4, 4] && o21 == [1, 2, 2, 2]);
    let cov = 2.0 * 5f64.sqrt(); let rad = (4.0 * cov / std::f64::consts::PI).sqrt();
    println!("figure, rows {:.6} apart, p2 covolume {:.6}, disc radius {:.6}, radius squared {:.6} = M_K N(p2), |1 + sqrt-5| = {:.6}, |2| = 2", 5f64.sqrt(), cov, rad, rad * rad, 6f64.sqrt());
    println!("ALL CHECKS PASS");
}
