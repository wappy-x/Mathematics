// The Weil pairing -- the same check as the Python, in Rust.  No crates;
// nothing used adds points or computes pairings.  The curve is
// y^2 = x^3 - x.  Its 2-torsion gives e_2.  Over F_43 (43 = 3 mod 4) it has
// 44 = 4 x 11 points, and e_11 moves a discrete log into F_(43^2) = F_43(i).
const P_: i64 = 43;
type F = (i64, i64);                     // a + bi, with i^2 = -1
type Pt = Option<(F, F)>;                // None is O, the point at infinity
const ONE: F = (1, 0);
const ZERO: F = (0, 0);
fn md(a: i64) -> i64 { a.rem_euclid(P_) }
fn c(n: i64) -> F { (md(n), 0) }
fn fa(u: F, v: F) -> F { (md(u.0 + v.0), md(u.1 + v.1)) }
fn fs(u: F, v: F) -> F { (md(u.0 - v.0), md(u.1 - v.1)) }
fn fm(u: F, v: F) -> F { (md(u.0 * v.0 - u.1 * v.1), md(u.0 * v.1 + u.1 * v.0)) }
fn powmod(b: i64, e: i64, m: i64) -> i64 {
    let (mut r, mut b, mut e) = (1i64, b.rem_euclid(m), e);
    while e > 0 { if e & 1 == 1 { r = r * b % m } b = b * b % m; e >>= 1 }
    r
}
fn fi(u: F) -> F {                       // 1/(a + bi) = (a - bi)/(a^2 + b^2)
    let n = md(u.0 * u.0 + u.1 * u.1);
    assert!(n != 0, "division by zero");
    let k = powmod(n, P_ - 2, P_);
    (md(u.0 * k), md(-u.1 * k))
}
fn fpow(u: F, k: i64) -> F { let mut r = ONE; for _ in 0..k { r = fm(r, u) } r }
fn show(u: F) -> String {                // an element a + bi of F_(43^2)
    if u.1 == 0 { return format!("{}", u.0) }
    if u.0 == 0 { format!("{}i", u.1) } else { format!("{} + {}i", u.0, u.1) }
}
fn pt(p: Pt) -> String { match p { None => "O".to_string(), Some((x, y)) => format!("({}, {})", show(x), show(y)) } }
fn pm(u: F) -> String { if u == ONE { "+1".into() } else if u == c(-1) { "-1".into() } else { show(u) } }
fn slope(t: (F, F), u: (F, F)) -> F {    // tangent slope if T = U, chord slope otherwise
    if t == u { return fm(fs(fm(c(3), fm(t.0, t.0)), ONE), fi(fm(c(2), t.1))) }
    fm(fs(u.1, t.1), fi(fs(u.0, t.0)))
}
fn add(p: Pt, q: Pt) -> Pt {             // chord and tangent on y^2 = x^3 - x
    let (a, b) = match (p, q) { (None, _) => return q, (_, None) => return p, (Some(a), Some(b)) => (a, b) };
    if a.0 == b.0 && fa(a.1, b.1) == ZERO { return None }
    let lam = slope(a, b);
    let x = fs(fs(fm(lam, lam), a.0), b.0);
    Some((x, fs(fm(lam, fs(a.0, x)), a.1)))
}
fn mul(k: i64, p: Pt) -> Pt { let mut r = None; for _ in 0..k { r = add(r, p) } r }
fn iota(p: Pt) -> Pt { p.map(|(x, y)| (fs(ZERO, x), fm((0, 1), y))) }  // (x, y) -> (-x, iy)
fn g(t: Pt, u: Pt, x: Pt) -> (F, Pt) {   // line through T and U, over the vertical at T + U, at X
    let (t0, u0, x0) = (t.unwrap(), u.unwrap(), x.unwrap());
    let v = add(t, u);
    let (num, den) = match v {
        None => (fs(x0.0, t0.0), ONE),
        Some(v0) => (fs(fs(x0.1, t0.1), fm(slope(t0, u0), fs(x0.0, t0.0))), fs(x0.0, v0.0)),
    };
    assert!(num != ZERO && den != ZERO, "X sits on a zero or pole");
    (fm(num, fi(den)), v)
}
fn miller(m: i64, p: Pt, x: Pt, log: &mut Vec<String>) -> (F, i64) {  // f_(m,P)(X)
    let (mut f, mut t, mut n, mut steps) = (ONE, p, 1, 0);
    let bits = format!("{:b}", m);
    for bit in bits.chars().skip(1) {    // double, then add when the bit is 1
        let (v, t2) = g(t, t, x); f = fm(fm(f, f), v); t = t2; n *= 2; steps += 1;
        log.push(format!("  double to {}P = {}: f = {}", n, pt(t), show(f)));
        if bit == '1' {
            let (v, t2) = g(t, p, x); f = fm(f, v); t = t2; n += 1; steps += 1;
            log.push(format!("  add P to {}P = {}: f = {}", n, pt(t), show(f)));
        }
    }
    (f, steps)
}
fn mil(m: i64, p: Pt, x: Pt) -> F { miller(m, p, x, &mut Vec::new()).0 }
fn road1(m: i64, p: Pt, q: Pt) -> F {    // (-1)^m f_P(Q) / f_Q(P)
    let r = fm(mil(m, p, q), fi(mil(m, q, p)));
    if m % 2 == 0 { r } else { fs(ZERO, r) }
}
fn road2(m: i64, p: Pt, q: Pt, r: Pt, s: Pt) -> F {  // f_P(D_Q) / f_Q(D_P)
    let ff = |a: Pt, b: Pt, x: Pt| fm(mil(m, a, x), fi(fpow(g(a, b, x).0, m)));
    let top = fm(ff(p, r, add(q, s)), fi(ff(p, r, s)));
    fm(top, fi(fm(ff(q, s, add(p, r)), fi(ff(q, s, r)))))
}
fn order(p: Pt) -> i64 { (1..45).find(|&k| mul(k, p).is_none()).unwrap() }

fn main() {
    let p = P_;
    let pts: Vec<Pt> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
        .filter(|&(x, y)| md(y * y - x * x * x + x) == 0).map(|(x, y)| Some((c(x), c(y)))).collect();
    let euler = p + 1 + (0..p).filter(|&x| md(x * x * x - x) != 0)
        .map(|x| if powmod(x * x * x - x, (p - 1) / 2, p) == 1 { 1 } else { -1 }).sum::<i64>();
    let gg = *pts.iter().find(|&&q| order(q) == 22).unwrap();
    let (r, s) = (gg, iota(gg));
    println!("y^2 = x^3 - x over F_{}: {} points by listing, {} by Euler's test, p + 1 = {}", p, pts.len() + 1, euler, p + 1);
    println!("G = {}, order {}; shifts R = G, S = iota(G) = {}", pt(gg), order(gg), pt(s));
    assert!(pts.len() as i64 + 1 == euler && euler == p + 1);
    let f = |x: i64| md(x * x * x - x);
    let sq: Vec<i64> = (0..p).filter(|&x| f(x) != 0 && powmod(f(x), (p - 1) / 2, p) == 1).collect();
    let split = (0..p).filter(|&x| f(x) != 0).all(|x| sq.contains(&x) != sq.contains(&(p - x)));
    println!("x with x^3 - x a nonzero square: {}, one from each pair x, -x: {}", sq.len(), if split { "yes" } else { "no" });
    assert!(split && 2 * sq.len() + 4 == pts.len() + 1);
    let t2: Vec<Pt> = pts.iter().copied().filter(|q| q.unwrap().1 == ZERO).collect();
    println!("e_2 on the 2-torsion, road 1 (Miller) / road 2 (divisors):");
    for &a in &t2 {
        let row: Vec<(Option<F>, F)> = t2.iter().map(|&b| (if a != b { Some(road1(2, a, b)) } else { None }, road2(2, a, b, r, s))).collect();
        let cells: Vec<String> = row.iter().map(|&(x, y)| format!("{} / {}", x.map_or("n/a".to_string(), pm), pm(y))).collect();
        println!("  {:8} {}", pt(a), cells.join("  "));
        assert!(row.iter().zip(&t2).all(|(&(x, y), &b)| y == (if a == b { ONE } else { c(-1) }) && x.map_or(true, |v| v == y)));
    }
    let pp = mul(2, gg); let qd = iota(pp);
    let mut trace = Vec::new();
    let (fp, nsteps) = miller(11, pp, qd, &mut trace);
    let alpha = road1(11, pp, qd);
    println!("P = 2G = {}, order {}; iota(P) = {}", pt(pp), order(pp), pt(qd));
    println!("Miller, m = 11 = 1011 in binary: {} line steps; f_P(iota P) = {}, f_iotaP(P) = {}", nsteps, show(fp), show(mil(11, qd, pp)));
    println!("{}", trace.join("\n"));
    println!("alpha = e_11(P, iota P) = {} by road 1, {} by road 2", show(alpha), show(road2(11, pp, qd, r, s)));
    println!("alpha^11 = {}; alpha = 1? {}", show(fpow(alpha, 11)), if alpha == ONE { "yes" } else { "no" });
    assert!(road2(11, pp, qd, r, s) == alpha && alpha != ONE && fpow(alpha, 11) == ONE);
    let mut e11: Vec<((i64, i64), Pt)> = Vec::new();
    for a in 0..11 { for b in 0..11 { e11.push(((a, b), add(mul(a, pp), mul(b, qd)))) } }
    let mut bad = 0;
    for &((a, b), x) in &e11 { for &((cc, d), y) in &e11 {
        if x.is_some() && y.is_some() && road2(11, x, y, r, s) != fpow(alpha, (a * d - b * cc).rem_euclid(11)) { bad += 1 }
    } }
    println!("e_11(aP + b iotaP, cP + d iotaP) = alpha^(ad - bc), all 120 x 120 pairs: {} failures", bad);
    assert!(bad == 0);
    let d = 7; let q = mul(d, pp); let beta = road1(11, q, qd);
    let mov = (0..11).find(|&k| fpow(alpha, k) == beta).unwrap();
    let brute = (0..11).find(|&k| mul(k, pp) == q).unwrap();
    println!("secret d = {}: Q = dP = {}; beta = e_11(Q, iota P) = {}", d, pt(q), show(beta));
    println!("MOV: alpha^k = beta in F_43^2 at k = {}; brute force on the curve: k = {}", mov, brute);
    assert!(mov == brute && brute == d);
    let kap = (1..12).find(|&k| powmod(p, k, 11) == 1).unwrap();
    println!("embedding degree of 11 over F_43: {} (43 mod 11 = {}); the field F_43^{} has {} elements", kap, p % 11, kap, p.pow(kap as u32));
    assert!(kap == 2);
    let (a1, b1, c1) = (2, 5, 9);
    let keys = [fpow(road1(11, mul(b1, pp), iota(mul(c1, pp))), a1),
                fpow(road1(11, mul(a1, pp), iota(mul(c1, pp))), b1),
                fpow(road1(11, mul(a1, pp), iota(mul(b1, pp))), c1)];
    println!("three-party key, secrets {}, {}, {}: {}; alpha^{} = {}", a1, b1, c1,
             keys.iter().map(|&k| show(k)).collect::<Vec<_>>().join(", "), a1 * b1 * c1, show(fpow(alpha, a1 * b1 * c1)));
    assert!(keys[0] == keys[1] && keys[1] == keys[2] && keys[2] == fpow(alpha, a1 * b1 * c1));
    let same: Vec<F> = (1..11).map(|k| road2(11, pp, mul(k, pp), r, s)).collect();
    let mut vals: Vec<String> = same.iter().map(|&v| show(v)).collect(); vals.sort(); vals.dedup();
    println!("mistake 1, no distortion map: e_11(P, kP) for k = 1..10 takes the values {}", vals.join(", "));
    let neg = fs(ZERO, alpha);
    println!("mistake 2, sign (-1)^11 dropped: {}, whose 11th power is {}", show(neg), pm(fpow(neg, 11)));
    let wrong = road1(11, gg, qd);
    println!("mistake 3, G of order 22 put into e_11: {}, whose 11th power is {}", show(wrong), show(fpow(wrong, 11)));
    let hn = 1 + (0..13i64).flat_map(|x| (0..13i64).map(move |y| (x, y))).filter(|&(x, y)| (y * y - x * x * x + 2).rem_euclid(13) == 0).count();
    let kh = (1..19).find(|&k| powmod(13, k, 19) == 1).unwrap();
    println!("mistake 4, house curve y^2 = x^3 - 2 mod 13: {} points, embedding degree {}, field of 13^{} = {} elements",
             hn, kh, kh, 13i128.pow(kh as u32));
    assert!(same.iter().all(|&v| v == ONE) && fpow(wrong, 11) != ONE);
    assert!(hn == 19 && kh == 18);
    println!("ALL CHECKS PASS");
}
