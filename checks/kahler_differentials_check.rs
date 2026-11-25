// Kahler differentials on the cusp y^2 = x^3 and on the smooth cubic y^2 = x^3 - x.
// std only. A polynomial maps (i, j) to the coefficient of x^i y^j, an exact i128 fraction;
// checked_mul stops the run on overflow. A 1-form P dx + Q dy is the pair (P, Q).
// Road 1: the presentation: fibre dimension at a point = 2 - rank of (f_x, f_y) there.
// Road 2: dual numbers a + b e with e^2 = 0, no derivatives: solutions v of f(P + e v) = 0.
// Road 3: weights x:2, y:3 on the cusp, against the pullback to the line t -> (t^2, t^3).
// Road 4: exact certificates for the smooth cubic, substituted back and reduced mod f.
use std::collections::BTreeMap;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn qm(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qa(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
type P = BTreeMap<(u32, u32), Q>;
fn pl(t: &[(u32, u32, i128, i128)]) -> P { t.iter().map(|&(i, j, n, d)| ((i, j), q(n, d))).collect() }
fn cl(h: P) -> P { h.into_iter().filter(|(_, c)| c.n != 0).collect() }
fn add(fs: &[&P]) -> P {
    let mut h = P::new();
    for f in fs { for (m, c) in f.iter() { let e = h.entry(*m).or_insert(q(0, 1)); *e = qa(*e, *c); } }
    cl(h)
}
fn mul(f: &P, g: &P) -> P {
    let mut h = P::new();
    for (&(a, b), &c) in f { for (&(e, k), &u) in g { let x = h.entry((a + e, b + k)).or_insert(q(0, 1)); *x = qa(*x, qm(c, u)); } }
    cl(h)
}
fn sc(c: i128, f: &P) -> P { cl(f.iter().map(|(m, u)| (*m, qm(q(c, 1), *u))).collect()) }
fn nf(p: &P, g: &P) -> P { // remainder modulo y^2 - g(x): swap each y^2 for g
    let mut p = p.clone();
    while let Some(&m) = p.keys().filter(|m| m.1 > 1).max() {
        let c = p.remove(&m).unwrap();
        let t: P = [((m.0, m.1 - 2), c)].into_iter().collect();
        p = add(&[&p, &mul(&t, g)]);
    }
    p
}
fn d(f: &P, k: usize) -> P {
    cl(f.iter().filter(|(m, _)| if k == 0 { m.0 > 0 } else { m.1 > 0 })
        .map(|(&(i, j), &c)| if k == 0 { ((i - 1, j), qm(c, q(i as i128, 1))) } else { ((i, j - 1), qm(c, q(j as i128, 1))) }).collect())
}
fn ev(f: &P, p: (i128, i128), m: i128) -> Q {
    let s = f.iter().fold(q(0, 1), |s, (&(i, j), &c)| qa(s, qm(c, q(p.0.pow(i) * p.1.pow(j), 1))));
    if m > 0 { q(s.n.rem_euclid(m), 1) } else { s }
}
fn dual(f: &P, p: (i128, i128), v: (i128, i128), m: i128) -> (i128, i128) { // f(P + e v), e^2 = 0
    let (mut aa, mut bb) = (0i128, 0i128);
    for (&(i, j), c) in f {
        let (mut a, mut b) = (c.n, 0i128);
        for (p0, v0, n) in [(p.0, v.0, i), (p.1, v.1, j)] { for _ in 0..n { let t = a * p0; b = a * v0 + b * p0; a = t; } }
        aa += a; bb += b;
    }
    if m > 0 { (aa.rem_euclid(m), bb.rem_euclid(m)) } else { (aa, bb) }
}
fn show(f: &P) -> String {
    let mut out = String::new();
    for (&(i, j), &c) in f.iter().rev() {
        let a = q(c.n.abs(), c.d);
        let mut mono = String::new();
        if i > 0 { mono += "x"; if i > 1 { mono += &format!("^{}", i); } }
        if j > 0 { mono += "y"; if j > 1 { mono += &format!("^{}", j); } }
        let cs = if a.n == 1 && a.d == 1 && !mono.is_empty() { String::new() } else if a.d == 1 || mono.is_empty() { qs(a) } else { format!("({})", qs(a)) };
        out += if out.is_empty() { if c.n < 0 { "-" } else { "" } } else if c.n < 0 { " - " } else { " + " };
        out += &(cs + &mono);
    }
    if out.is_empty() { "0".into() } else { out }
}
fn fib(f: &P, p: (i128, i128), m: i128) -> ((Q, Q), usize) { // road 1
    let r = (ev(&d(f, 0), p, m), ev(&d(f, 1), p, m));
    (r, if r.0.n == 0 && r.1.n == 0 { 2 } else { 1 })
}
fn nsol(f: &P, p: (i128, i128), m: i128) -> i128 { // road 2
    let mut c = 0;
    for a in 0..m { for b in 0..m { if dual(f, p, (a, b), m) == (0, 0) { c += 1; } } }
    c
}
fn tl<T: std::fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn tp(v: &[(i128, i128)]) -> String { tl(&v.iter().map(|p| format!("({}, {})", p.0, p.1)).collect::<Vec<_>>()) }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn pts(f: &P, m: i128) -> Vec<(i128, i128)> {
    let mut v = vec![];
    for a in 0..m { for b in 0..m { if ev(f, (a, b), m).n == 0 { v.push((a, b)); } } }
    v
}
fn main() {
    let cub = pl(&[(0, 2, 1, 1), (3, 0, -1, 1), (1, 0, 1, 1)]); let g1 = pl(&[(3, 0, 1, 1), (1, 0, -1, 1)]);
    let (cusp, g0, one_p) = (pl(&[(0, 2, 1, 1), (3, 0, -1, 1)]), pl(&[(3, 0, 1, 1)]), pl(&[(0, 0, 1, 1)]));
    println!("field: the rationals Q, exact; F_p only where named");
    for (name, f) in [("cusp", &cusp), ("smooth cubic", &cub)] {
        println!("{} f = {}: Omega = (A dx + A dy) / (df), df = ({}) dx + ({}) dy", name, show(f), show(&d(f, 0)), show(&d(f, 1)));
    }
    for (name, f, p) in [("cusp", &cusp, (0, 0)), ("cusp", &cusp, (1, 1)), ("cubic", &cub, (-1, 0)), ("cubic", &cub, (0, 0)), ("cubic", &cub, (1, 0))] {
        let (r, k) = fib(f, p, 0); let lin = (dual(f, p, (1, 0), 0).1, dual(f, p, (0, 1), 0).1);
        println!("{} at ({}, {}): f = {}; df there = {} dx + {} dy; dual numbers give {}a + {}b; fibre dimension {}", name, p.0, p.1, qs(ev(f, p, 0)), qs(r.0), qs(r.1), lin.0, lin.1, k);
        assert!(ev(f, p, 0).n == 0 && r == (q(lin.0, 1), q(lin.1, 1)));
    }
    let (r, _) = fib(&cusp, (1, 1), 0); let slope = q(-r.0.n, r.1.n);
    println!("cusp at (1, 1): dy = {} dx; velocity of (t^2, t^3) at t = 1 is (2, 3), slope {}", qs(slope), qs(q(3 * 1i128.pow(2), 2 * 1)));
    assert!(slope == q(3 * 1i128.pow(2), 2 * 1) && fib(&cusp, (0, 0), 0).1 == 2);
    let roots: Vec<i128> = (-3..4).filter(|a: &i128| a.pow(3) - a == 0).collect();
    let vals: Vec<i128> = roots.iter().map(|a| 3 * a * a - 1).collect();
    println!("cubic: 2y = 0 forces y = 0, so x^3 - x = 0: x = {}; 3x^2 - 1 there: {}; no singular point", tl(&roots), tl(&vals));
    assert!(vals.iter().all(|&v| v != 0) && roots.len() == 3);
    let (u, v) = (pl(&[(2, 0, 3, 2), (0, 0, -1, 1)]), pl(&[(1, 1, -9, 4)]));
    let (a3, b2) = (sc(-1, &d(&cub, 0)), d(&cub, 1)); // 3x^2 - 1 and 2y: the relation reads 2y dy = (3x^2 - 1) dx
    let one = nf(&add(&[&mul(&u, &a3), &mul(&v, &b2)]), &g1);
    println!("certificate: ({})(3x^2 - 1) + ({})(2y) = {} mod f", show(&u), show(&v), show(&one));
    let xq = |n: i128, dn: i128| pl(&[(1, 0, n, dn)]); // (n/dn) x
    let s1 = add(&[&mul(&xq(1, 3), &a3), &xq(-2, 3), &sc(-1, &g1)]); // x^3 - x = (x/3)(3x^2 - 1) - (2/3)x
    let s2 = add(&[&mul(&xq(-9, 2), &xq(-2, 3)), &sc(-1, &one_p), &sc(-1, &a3)]); // 3x^2 - 1 = (-(9/2)x)(-(2/3)x) - 1
    let s3 = add(&[&mul(&u, &a3), &mul(&xq(-9, 2), &g1)]); // 1 = u (3x^2 - 1) - (9/2) x (x^3 - x)
    println!("division steps: x^3 - x = (x/3)(3x^2 - 1) - (2/3)x; 3x^2 - 1 = (-(9/2)x)(-(2/3)x) - 1; back-substituted: {}", show(&s3));
    assert!(one == one_p && s1.is_empty() && s2.is_empty() && s3 == one_p);
    let rel = [d(&cub, 0), d(&cub, 1)]; let w = [v.clone(), u.clone()]; // w = u dy + v dx
    let e1 = [nf(&add(&[&one_p, &sc(-1, &mul(&b2, &w[0]))]), &g1), nf(&sc(-1, &mul(&b2, &w[1])), &g1)];
    let e2 = [nf(&sc(-1, &mul(&a3, &w[0])), &g1), nf(&add(&[&one_p, &sc(-1, &mul(&a3, &w[1]))]), &g1)];
    let ok1 = (0..2).all(|i| nf(&add(&[&e1[i], &mul(&u, &rel[i])]), &g1).is_empty());
    let ok2 = (0..2).all(|i| nf(&add(&[&e2[i], &sc(-1, &mul(&v, &rel[i]))]), &g1).is_empty());
    println!("w = ({}) dy + ({}) dx: dx - 2y w = -u df: {}; dy - (3x^2 - 1) w = v df: {}", show(&u), show(&v), tf(ok1), tf(ok2));
    let dd = nf(&add(&[&mul(&b2, &rel[0]), &mul(&a3, &rel[1])]), &g1);
    println!("derivation D = 2y d/dx + (3x^2 - 1) d/dy: D(f) = {}; phi(dx) = 2y, phi(dy) = 3x^2 - 1, phi(w) = {}", show(&dd), show(&one));
    assert!(ok1 && ok2 && dd.is_empty());
    for m in [7i128, 13] {
        for (name, f) in [("cusp", &cusp), ("cubic", &cub)] {
            let ps = pts(f, m);
            let k1: Vec<usize> = ps.iter().map(|&p| fib(f, p, m).1).collect();
            let k2: Vec<i128> = ps.iter().map(|&p| nsol(f, p, m)).collect();
            let sing: Vec<(i128, i128)> = ps.iter().zip(&k1).filter(|(_, &k)| k == 2).map(|(p, _)| *p).collect();
            let mut ks = k2.clone(); ks.sort(); ks.dedup();
            println!("over F_{}: {} {} points; fibre 2 at {}, 1 at {}; dual-number counts {}", m, name, ps.len(), tp(&sing), k1.iter().filter(|&&k| k == 1).count(), tl(&ks));
            let gx = sc(-1, &add(&[f, &pl(&[(0, 2, -1, 1)])])); // f = y^2 - g(x); count by Euler's criterion
            let chi = |n: i128| if n == 0 { 0 } else { let mut r = 1; for _ in 0..(m - 1) / 2 { r = r * n % m; } if r == 1 { 1 } else { -1 } };
            let euler: i128 = (0..m).map(|a| 1 + chi(ev(&gx, (a, 0), m).n)).sum();
            assert!(k2.iter().zip(&k1).all(|(&n, &k)| n == m.pow(k as u32)) && ps.len() as i128 == euler);
            assert!(sing == if name == "cusp" { vec![(0, 0)] } else { vec![] });
        }
    }
    let wt = |m: (i32, i32)| 2 * m.0 + 3 * m.1;
    let aw = |n: i32| -> i32 { let mut c = 0; for i in 0..=n.max(0) / 2 { for j in 0..2 { if 2 * i + 3 * j == n { c += 1; } } } c };
    let om: Vec<i32> = (0..13).map(|n| aw(n - 2) + aw(n - 3) - aw(n - 6)).collect();
    let img: Vec<i32> = (0..13).map(|n| if aw(n - 2) + aw(n - 3) > 0 { 1 } else { 0 }).collect();
    let tor: Vec<i32> = om.iter().zip(&img).map(|(a, b)| a - b).collect();
    println!("cusp by weight 0..12: dim Omega_n {}; image in k[t] dt {}; torsion {}", tl(&om), tl(&img), tl(&tor));
    assert!(tor.iter().sum::<i32>() == 2 && (0..13).filter(|&n| tor[n] != 0).collect::<Vec<_>>() == vec![5, 7]);
    let sub = |p: &P| -> P { cl(p.iter().map(|(&(i, j), &c)| ((2 * i + 3 * j, 0), c)).collect()) };
    let tw = [pl(&[(0, 1, -3, 1)]), pl(&[(1, 0, 2, 1)])]; // w0 = 2x dy - 3y dx
    let pb = add(&[&mul(&sub(&tw[0]), &pl(&[(1, 0, 2, 1)])), &mul(&sub(&tw[1]), &pl(&[(2, 0, 3, 1)]))]);
    let cr = [d(&cusp, 0), d(&cusp, 1)];
    let (yy, xx, x2) = (pl(&[(0, 1, 1, 1)]), pl(&[(1, 0, 1, 1)]), pl(&[(2, 0, 1, 1)]));
    let ky = (0..2).all(|i| nf(&add(&[&mul(&yy, &tw[i]), &sc(-1, &mul(&xx, &cr[i]))]), &g0).is_empty());
    let kx = (0..2).all(|i| nf(&add(&[&mul(&x2, &tw[i]), &sc(-1, &mul(&yy, &cr[i]))]), &g0).is_empty());
    println!("weights x {}, y {}, df {}; w0 = 2x dy - 3y dx, weight {}: pullback {}; y w0 = x df: {}; x^2 w0 = y df: {}", wt((1, 0)), wt((0, 1)), wt((0, 2)), wt((1, 0)) + wt((0, 1)), show(&pb), tf(ky), tf(kx));
    assert!(pb.is_empty() && ky && kx);
    let sq = mul(&cub, &cub); let p7 = pts(&cub, 7);
    let n_sq = p7.iter().filter(|&&p| fib(&sq, p, 7).1 == 2).count(); let n_f = p7.iter().filter(|&&p| fib(&cub, p, 7).1 == 2).count();
    println!("mistake 1, f^2 over F_7: fibre 2 at {} of {} points; with f: {}", n_sq, p7.len(), n_f);
    let p2 = pts(&cub, 2);
    let f2: Vec<usize> = p2.iter().map(|&p| fib(&cub, p, 2).1).collect(); let c2: Vec<i128> = p2.iter().map(|&p| nsol(&cub, p, 2)).collect();
    println!("mistake 2, cubic over F_2: points {}; fibres {}; dual-number counts {}", tp(&p2), tl(&f2), tl(&c2));
    assert!(f2 == vec![1, 2] && c2 == vec![2, 4] && n_sq == p7.len() && n_f == 0);
    let (unev, ev0) = (2 - if cr[0].is_empty() && cr[1].is_empty() { 0 } else { 1 }, fib(&cusp, (0, 0), 0).1);
    println!("mistake 3, df of the cusp left unevaluated: not zero, so 'fibre' {}; evaluated at (0, 0): {}", unev, ev0);
    assert!((unev, ev0) == (1, 2));
    println!("mistake 4, pull back to the line: w0 becomes {}, torsion invisible; true torsion dimension {}", show(&pb), tor.iter().sum::<i32>());
    println!("house: plane curve of degree d = 3: genus (d - 1)(d - 2)/2 = {}; Omega = O(d - 3) = O({})", (3 - 1) * (3 - 2) / 2, 3 - 3);
    let vert: Vec<String> = roots.iter().filter(|&&a| { let r = fib(&cub, (a, 0), 0); r.0.1.n == 0 && r.1 == 1 }).map(|a| format!("({},0)", a)).collect(); // f_y = 0, f_x != 0
    println!("figure, cusp: (0,0) singular, (1,1) slope {}; cubic: {} vertical; cusp x -1..2.2, cubic x -1.5..2.2, y -3.2..3.2", qs(slope), vert.join(" "));
    println!("ALL CHECKS PASS");
}
