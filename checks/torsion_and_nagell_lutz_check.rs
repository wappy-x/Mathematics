// Torsion on y^2 = x^3 - 2: Nagell-Lutz, division polynomials and Mazur's list, the check behind the card.
// Standard library only: exact fractions on i128 with checked arithmetic, so an overflow stops the run.
#[derive(Clone, Copy, PartialEq, Debug)]
struct R { n: i128, d: i128 }                        // n/d in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> R { assert!(d != 0); let g = gcd(n, d) * d.signum(); R { n: n / g, d: d / g } }  fn ri(n: i128) -> R { r(n, 1) }
fn cm(a: i128, b: i128) -> i128 { a.checked_mul(b).unwrap() }
fn mul(a: R, b: R) -> R { r(cm(a.n, b.n), cm(a.d, b.d)) }
fn div(a: R, b: R) -> R { r(cm(a.n, b.d), cm(a.d, b.n)) }
fn add_r(a: R, b: R) -> R { r(cm(a.n, b.d).checked_add(cm(b.n, a.d)).unwrap(), cm(a.d, b.d)) }
fn neg(a: R) -> R { R { n: -a.n, d: a.d } }  fn sub(a: R, b: R) -> R { add_r(a, neg(b)) }
fn fs(a: R) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
type P = Option<(R, R)>;                              // None is the point O
fn add(p: P, q: P, a: i128) -> P {                    // chord-tangent rule on y^2 = x^3 + a x + b
    let (p, q) = match (p, q) { (None, _) => return q, (_, None) => return p, (Some(p), Some(q)) => (p, q) };
    if p.0 == q.0 && p.1 == neg(q.1) { return None; }
    let m = if p == q { div(add_r(mul(ri(3), mul(p.0, p.0)), ri(a)), mul(ri(2), p.1)) } else { div(sub(q.1, p.1), sub(q.0, p.0)) };
    let x = sub(sub(mul(m, m), p.0), q.0);
    Some((x, sub(mul(m, sub(p.0, x)), p.1)))
}
fn whole(p: P) -> bool { match p { None => true, Some((x, y)) => x.d == 1 && y.d == 1 } }
fn order(p: P, a: i128, stop: bool) -> i128 {          // smallest n <= 13 with nP = O; 0 once a multiple is not whole
    let (mut k, mut s) = (1, p);
    while s.is_some() && k <= 13 && (whole(s) || !stop) { k += 1; s = add(s, p, a); }
    if s.is_none() { k } else { 0 }
}
fn show(p: P) -> String { match p { None => "O".to_string(), Some((x, y)) => format!("({}, {})", fs(x), fs(y)) } }
fn pt(x: i128, y: i128) -> P { Some((ri(x), ri(y))) }
fn curve(a: i128, b: i128) -> String {
    let mut s = "y^2 = x^3".to_string();
    let sgn = |c: i128| if c < 0 { "-" } else { "+" };
    if a != 0 { s += &format!(" {} {}x", sgn(a), if a.abs() > 1 { a.abs().to_string() } else { String::new() }); }
    if b != 0 { s += &format!(" {} {}", sgn(b), b.abs()); }
    s
}
fn isqrt(v: i128) -> i128 { let mut s = (v as f64).sqrt() as i128; while s * s > v { s -= 1; } while (s + 1) * (s + 1) <= v { s += 1; } s }
fn divisors(n: i128) -> Vec<i128> { let mut v = Vec::new(); for k in 1..=isqrt(n) { if n % k == 0 { v.push(k); v.push(n / k); } } v }
fn is_prime(n: i128) -> bool { n > 1 && (2..=isqrt(n)).all(|d| n % d != 0) }
fn pow_mod(b: i128, e: i128, m: i128) -> i128 {   // b^e mod m by repeated squaring
    if e == 0 { 1 } else { let h = pow_mod(b, e / 2, m); h * h % m * if e % 2 == 1 { b.rem_euclid(m) } else { 1 } % m }
}
fn count_mod(p: i128, a: i128, b: i128) -> i128 {     // points mod p, O included (Euler's square test)
    1 + (0..p).map(|x| { let v = (x * x % p * x + a * x + b).rem_euclid(p);
        if v == 0 { 1 } else if pow_mod(v, (p - 1) / 2, p) == 1 { 2 } else { 0 } }).sum::<i128>()
}
fn gcd_counts(a: i128, b: i128, top: i128) -> i128 {
    let dd = 4 * a * a * a + 27 * b * b;
    (5..top).filter(|&p| is_prime(p) && dd % p != 0).fold(0, |g, p| gcd(g, count_mod(p, a, b)))
}
fn pmul(p: &[i128], q: &[i128]) -> Vec<i128> {
    let mut v = vec![0i128; p.len() + q.len() - 1];
    for (i, &s) in p.iter().enumerate() { for (j, &t) in q.iter().enumerate() { v[i + j] = v[i + j].checked_add(cm(s, t)).unwrap(); } }
    v
}
fn psub(p: &[i128], q: &[i128]) -> Vec<i128> {
    let mut v: Vec<i128> = (0..p.len().max(q.len())).map(|i| p.get(i).unwrap_or(&0) - q.get(i).unwrap_or(&0)).collect();
    while *v.last().unwrap() == 0 { v.pop(); }
    v
}
fn divpolys(a: i128, b: i128) -> Vec<Vec<i128>> {   // g_n = psi_n for odd n, psi_n / (2y) for even n
    let f2 = pmul(&[4 * b, 4 * a, 0, 4], &[4 * b, 4 * a, 0, 4]);
    let mut g = vec![vec![0], vec![1], vec![1], vec![-a * a, 12 * b, 6 * a, 0, 3], vec![-16 * b * b - 2 * a * a * a, -8 * a * b, -10 * a * a, 40 * b, 10 * a, 0, 2]];
    g.push(psub(&pmul(&f2, &pmul(&g[4], &cube(&g[2]))), &pmul(&g[1], &cube(&g[3]))));
    g.push(vec![0]);
    g.push(psub(&pmul(&g[5], &cube(&g[3])), &pmul(&f2, &pmul(&g[2], &cube(&g[4])))));
    g
}
fn rat_roots(c0: &[i128]) -> (Vec<R>, usize) {     // a root u/v has u | constant term, v | leading term
    let (mut roots, mut c) = (Vec::new(), c0.to_vec());
    while c[0] == 0 { roots = vec![ri(0)]; c.remove(0); }
    let mut cs: Vec<R> = Vec::new();
    for &u in &divisors(c[0].abs()) { for &v in &divisors(c.last().unwrap().abs()) { for s in [1, -1] {
        let q = r(s * u, v); if !cs.contains(&q) { cs.push(q); } } } }
    let m: i128 = (1 << 61) - 1;                        // a prime: a root must give 0 mod m first
    for &q in &cs {
        let dg = c.len() as u32 - 1;
        let md = c.iter().enumerate().fold(0, |t, (i, &ci)| (t + ci.rem_euclid(m) * pow_mod(q.n, i as i128, m) % m * pow_mod(q.d, (dg - i as u32) as i128, m)) % m);
        if md == 0 && c.iter().enumerate().fold(0i128, |t, (i, &ci)| t + cm(ci, cm(q.n.pow(i as u32), q.d.pow(dg - i as u32)))) == 0 { roots.push(q); }
    }
    roots.sort_by(|x, y| cm(x.n, y.d).cmp(&cm(y.n, x.d)));
    (roots, cs.len())
}
fn cube(p: &[i128]) -> Vec<i128> { pmul(p, &pmul(p, p)) }  fn evalp(c: &[i128], x: i128) -> i128 { c.iter().rev().fold(0, |t, &ci| cm(t, x) + ci) }
fn main() {
    let (a0, b0) = (0i128, -2i128);                   // the house curve y^2 = x^3 - 2
    // Road 1: Nagell-Lutz
    let dd = 4 * a0 * a0 * a0 + 27 * b0 * b0;
    let ys: Vec<i128> = (0..=isqrt(dd)).filter(|&y| y == 0 || dd % (y * y) == 0).collect();
    let cands: Vec<String> = ys.iter().flat_map(|&y| (-50..51i128).filter(move |&x| x * x * x + a0 * x + b0 == y * y).map(move |x| format!("({}, {})", x, y))).collect();
    println!("Nagell-Lutz on {}: 4a^3 + 27b^2 = {}; allowed y: {:?}", curve(a0, b0), dd, ys);
    let need: Vec<String> = ys.iter().map(|y| (y * y - b0).to_string()).collect();
    println!("  y^2 - b = {}; whole x with x^3 + ax = y^2 - b: {}; candidates: {}", need.join(", "), if cands.is_empty() { "none".to_string() } else { cands.join(", ") }, cands.len());
    assert!(cands.is_empty() && ys == vec![0, 1, 2, 3, 6]);
    let mut ident = true;
    for x in 0..8i128 { for a in 0..5i128 { for b in 0..4i128 {
        ident &= (3 * x * x + 4 * a) * (x.pow(4) - 2 * a * x * x - 8 * b * x + a * a) - (3 * x.pow(3) - 5 * a * x - 27 * b) * (x.pow(3) + a * x + b) == 4 * a.pow(3) + 27 * b * b;
    } } }
    println!("identity (3x^2 + 4a)(x^4 - 2ax^2 - 8bx + a^2) - (3x^3 - 5ax - 27b)(x^3 + ax + b) = 4a^3 + 27b^2 on an 8 x 5 x 4 grid: {}", if ident { "True" } else { "False" });
    assert!(ident);

    // Road 2: division polynomials
    let g = divpolys(a0, b0);
    let lst = |v: &[R]| format!("[{}]", v.iter().map(|q| format!("'{}'", fs(*q))).collect::<Vec<_>>().join(", "));
    let (r2, n2) = rat_roots(&[b0, a0, 0, 1]);
    println!("order 2: y = 0 needs x^3 - 2 = 0; {} candidates, rational roots: {}", n2, lst(&r2));
    let (r3, n3) = rat_roots(&g[3]);
    let vals: Vec<String> = r3.iter().map(|&q| fs(sub(mul(q, mul(q, q)), ri(2)))).collect();
    println!("order 3: psi_3 = 3x^4 - 24x; {} candidates, rational roots: {}; x^3 - 2 there: {}, not squares", n3, lst(&r3), vals.join(", "));
    let mut nroots = Vec::new();
    for n in [5usize, 7] {
        let (rt, k) = rat_roots(&g[n]);
        println!("order {}: psi_{} has degree {}, leading {}, constant {}; {} candidates, rational roots: {}", n, n, g[n].len() - 1, g[n].last().unwrap(), g[n][0], k, rt.len());
        nroots.push(rt.len());
    }
    assert!(r2.is_empty() && r3 == vec![ri(0), ri(2)] && r3.iter().all(|&q| { let v = sub(mul(q, mul(q, q)), ri(2)); v.n <= 0 || isqrt(v.n) * isqrt(v.n) != v.n }) && nroots == vec![0, 0]);
    for (n, a, b, x) in [(3usize, 0i128, 4i128, 0i128), (5, -432, 8208, -12), (7, -43, 166, 3)] { assert!(evalp(&divpolys(a, b)[n], x) == 0); }
    println!("psi_3, psi_5, psi_7 vanish at (0, 2), (-12, 108), (3, 8) on y^2 = x^3 + 4, x^3 - 432x + 8208, x^3 - 43x + 166: True");

    // Road 3: counts mod good primes
    let cs: Vec<String> = (5..40).filter(|&p| is_prime(p)).map(|p| format!("{}:{}", p, count_mod(p, a0, b0))).collect();
    println!("points mod p on y^2 = x^3 - 2: {}; gcd {}", cs.join(", "), gcd_counts(a0, b0, 40));
    assert!(gcd_counts(a0, b0, 40) == 1);

    // Road 4: the house point P = (3, 5) has infinite order
    let p = pt(3, 5);
    let mult = [p, add(p, p, a0), add(add(p, p, a0), p, a0)];
    println!("P = (3, 5): 5^2 = 25 does not divide 108; 2P = {}; 3P = {}", show(mult[1]), show(mult[2]));
    assert!(mult.iter().all(|q| { let (x, y) = q.unwrap(); mul(y, y) == sub(mul(x, mul(x, x)), ri(2)) }) && mult[1].unwrap().0.d == 100 && order(p, a0, true) == 0);

    // Mazur's list
    let mazur: [(&str, i128, i128, P, P); 15] = [("Z/1", 0, -2, None, None), ("Z/2", -2, 0, pt(0, 0), None), ("Z/3", 0, 4, pt(0, 2), None), ("Z/4", 4, 0, pt(2, 4), None),
        ("Z/5", -432, 8208, pt(-12, 108), None), ("Z/6", 0, 1, pt(2, 3), None), ("Z/7", -43, 166, pt(3, 8), None),
        ("Z/8", 45333, -1978074, pt(87, 1620), None), ("Z/9", -219, 1654, pt(-13, 48), None), ("Z/10", -58347, 3954150, pt(-213, 2592), None),
        ("Z/12", -1947, 108214, pt(-37, 360), None), ("Z/2 x Z/2", -1, 0, pt(0, 0), pt(1, 0)), ("Z/2 x Z/4", -12987, -263466, pt(-57, 540), pt(-102, 0)),
        ("Z/2 x Z/6", -24003, 1296702, pt(-69, 1620), pt(-177, 0)), ("Z/2 x Z/8", -1386747, 368636886, pt(-933, 29160), pt(-1293, 0))];
    println!("Mazur's fifteen groups, one curve each (group size = gcd of counts mod good primes below 100):");
    for &(name, a, b, p, t) in &mazur {
        let gens: Vec<P> = [p, t].iter().filter(|q| q.is_some()).cloned().collect();
        assert!(gens.iter().all(|q| { let (x, y) = q.unwrap(); mul(y, y) == add_r(add_r(mul(x, mul(x, x)), mul(ri(a), x)), ri(b)) }));
        let (mut grp, mut frontier): (Vec<P>, Vec<P>) = (vec![None], vec![None]);
        while grp.len() <= 16 { let Some(s) = frontier.pop() else { break };   // 16: the largest group on the list
            for &q in &gens { let u = add(s, q, a); if !grp.contains(&u) { grp.push(u); frontier.push(u); } }
        }
        let desc: Vec<String> = gens.iter().map(|&q| format!("{} order {}", show(q), order(q, a, true))).collect();
        let (size, gg) = (grp.len() as i128, gcd_counts(a, b, 100));
        println!("  {:<9}: {}; {}; {} point(s); gcd {}", name, curve(a, b), if desc.is_empty() { "only O".to_string() } else { desc.join(", ") }, size, gg);
        assert!(size == gg && grp.iter().all(|&q| whole(q)));
    }

    // What breaks
    let h: P = Some((r(1, 2), r(3, 8)));
    println!("fraction coefficients: (1/2, 3/8) on y^2 = x^3 + 1/64 has order {}, yet is not whole", order(h, 0, false));
    let x0 = ri(2);
    let x2 = div(sub(mul(mul(x0, x0), mul(x0, x0)), mul(ri(8 * b0), x0)), mul(ri(4), add_r(mul(x0, mul(x0, x0)), ri(b0))));
    println!("root 2 of psi_3 read as a point: y^2 = {}, not a square; over Q(sqrt 6) x(2P) = {}, so 3P = O there", fs(add_r(mul(x0, mul(x0, x0)), ri(b0))), fs(x2));
    let mut c8: Vec<(i128, i128)> = Vec::new();
    for y in 0..42i128 { if y == 0 || 1728 % (y * y) == 0 { for x in -9..9i128 { for s in [1, -1] { if x * x * x + 8 == y * y && !c8.contains(&(x, s * y)) { c8.push((x, s * y)); } } } } }
    c8.sort();
    let o8: Vec<i128> = c8.iter().map(|&(x, y)| order(pt(x, y), 0, true)).collect();
    let d8: Vec<String> = c8.iter().zip(&o8).map(|(&(x, y), &o)| format!("({}, {}) order {}", x, y, if o == 0 { "infinite".to_string() } else { o.to_string() })).collect();
    println!("y^2 = x^3 + 8, 4a^3 + 27b^2 = 1728, candidates: {}", d8.join(", "));
    println!("bad prime 3: y^2 = x^3 + 1 mod 3 has {} points; gcd with the true 6 is {}", count_mod(3, 0, 1), gcd(6, count_mod(3, 0, 1)));
    assert!(order(h, 0, false) == 6 && x2 == ri(2) && count_mod(3, 0, 1) == 4 && o8 == vec![2, 0, 0, 0, 0]);
    let dbl = |x: i128, y: i128| fs(add(pt(x, y), pt(x, y), 0).unwrap().0);
    let (h1, h2): (Vec<i128>, Vec<i128>) = ([1i128, -1, 2, -2].iter().map(|x| x * x * x - 2).collect(), (0..5i128).map(|x| (x * x * x - 2).rem_euclid(5)).collect());
    println!("by hand: slope at (3, 5) = {}; x^3 - 2 at 1, -1, 2, -2: {:?}; x^3 - 2 mod 5 at 0..4: {:?}", fs(r(3 * 9 + a0, 2 * 5)), h1, h2);
    println!("by hand: x(2(2, 3)) on y^2 = x^3 + 1 is {}; x(2(1, 3)) and x(2(2, 4)) on y^2 = x^3 + 8 are {} and {}", dbl(2, 3), dbl(1, 3), dbl(2, 4));
    assert!(dbl(2, 3) == "0" && dbl(1, 3) == "-7/4" && dbl(2, 4) == "-7/4" && { let mut h3 = h2.clone(); h3.sort(); h3 } == vec![0, 1, 2, 3, 4]);
    println!("ALL CHECKS PASS");
}
