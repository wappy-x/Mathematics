// Point arithmetic and double-and-add -- the same check as the Python, in Rust.  No crates.
// Curve y^2 = x^3 - 2, point P = (3, 5).  Over Q the fractions explode, so 1000P is found
// modulo the prime p = 1087: in plain (affine) coordinates, one division per step, and in
// Jacobian coordinates, one division at the end.  Integer work over Q uses checked_mul.
const P_: i128 = 1087;
const B: i128 = -2;
type Pt = Option<(i128, i128)>;            // None is O, the zero point
type Jac = (i128, i128, i128);
struct Cnt { mul: u64, inv: u64, invmul: u64 }

fn md(v: i128, m: i128) -> i128 { if m == 0 { v } else { v.rem_euclid(m) } }
fn fm(c: &mut Cnt, u: i128, v: i128, m: i128) -> i128 {   // one counted multiplication
    c.mul += 1;
    md(u.checked_mul(v).expect("overflow"), m)
}
fn inv(c: &mut Cnt, u: i128) -> Result<i128, String> {   // Fermat: u^(p-2) by square-and-multiply
    if md(u, P_) == 0 { return Err("no inverse of 0 mod 1087".to_string()) }
    c.inv += 1;
    let (mut r, e) = (md(u, P_), P_ - 2);
    for i in (0..(127 - e.leading_zeros() as i32)).rev() {
        r = r * r % P_; c.invmul += 1;
        if (e >> i) & 1 == 1 { r = r * md(u, P_) % P_; c.invmul += 1 }
    }
    Ok(r)
}
fn aff_add(c: &mut Cnt, a: Pt, d: Pt, three: i128) -> Result<Pt, String> {   // chord-and-tangent
    let ((x1, y1), (x2, y2)) = match (a, d) { (None, _) => return Ok(d), (_, None) => return Ok(a),
                                               (Some(s), Some(t)) => (s, t) };
    if x1 == x2 && md(y1 + y2, P_) == 0 { return Ok(None) }          // vertical line
    let m = if a == d { let t = three * fm(c, x1, x1, P_); let i = inv(c, 2 * y1)?; fm(c, t, i, P_) }
            else { let i = inv(c, x2 - x1)?; fm(c, y2 - y1, i, P_) };
    let x3 = md(fm(c, m, m, P_) - x1 - x2, P_);
    Ok(Some((x3, md(fm(c, m, x1 - x3, P_) - y1, P_))))
}
fn jac_dbl(c: &mut Cnt, j: Jac, m: i128) -> Jac {   // tangent rule with the denominator kept as Z
    let (x, y, z) = j;
    let yy = fm(c, y, y, m); let s = 4 * fm(c, x, yy, m); let t = 3 * fm(c, x, x, m);
    let x3 = fm(c, t, t, m) - 2 * s;
    let y3 = fm(c, t, s - x3, m) - 8 * fm(c, yy, yy, m);
    let z3 = 2 * fm(c, y, z, m);
    (md(x3, m), md(y3, m), md(z3, m))
}
fn jac_add(c: &mut Cnt, j: Jac, a: (i128, i128), m: i128) -> Jac {   // chord rule: j Jacobian, a plain
    let (x, y, z) = j;
    let zz = fm(c, z, z, m); let h = fm(c, a.0, zz, m) - x;
    let zzz = fm(c, z, zz, m); let r = fm(c, a.1, zzz, m) - y;
    let hh = fm(c, h, h, m); let hhh = fm(c, h, hh, m); let v = fm(c, x, hh, m);
    let x3 = fm(c, r, r, m) - hhh - 2 * v;
    let y3 = fm(c, r, v - x3, m) - fm(c, y, hhh, m);
    (md(x3, m), md(y3, m), md(fm(c, z, h, m), m))
}
fn to_affine(c: &mut Cnt, j: Jac) -> Pt {     // the one division: x = X/Z^2, y = Y/Z^3
    if j.2 == 0 { return None }
    let zi = inv(c, j.2).unwrap(); let zz = fm(c, zi, zi, P_);
    let zzz = fm(c, zz, zi, P_);
    Some((fm(c, j.0, zz, P_), fm(c, j.1, zzz, P_)))
}
fn bits(n: i128) -> String { format!("{:b}", n) }
fn aff_times(c: &mut Cnt, n: i128, a: (i128, i128)) -> (Pt, [u32; 2]) {   // double-and-add
    let (mut acc, mut ops): (Pt, [u32; 2]) = (Some(a), [0, 0]);
    for bit in bits(n).chars().skip(1) {
        acc = aff_add(c, acc, acc, 3).unwrap(); ops[0] += 1;
        if bit == '1' { acc = aff_add(c, acc, Some(a), 3).unwrap(); ops[1] += 1 }
    }
    (acc, ops)
}
fn jac_times(c: &mut Cnt, n: i128, a: (i128, i128)) -> Jac {
    let mut acc = (a.0, a.1, 1);
    for bit in bits(n).chars().skip(1) {
        acc = jac_dbl(c, acc, P_);
        if bit == '1' { acc = jac_add(c, acc, a, P_) }
    }
    acc
}
fn fresh() -> Cnt { Cnt { mul: 0, inv: 0, invmul: 0 } }
fn show(a: Pt) -> String { match a { None => "O".to_string(), Some((x, y)) => format!("({}, {})", x, y) } }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i128, d: i128) -> String { let g = gcd(n, d); format!("{}/{}", n / g, d / g) }
fn on(a: Pt) -> bool { let (x, y) = a.unwrap(); md(y * y - x * x * x - B, P_) == 0 }
fn inv_cost(hi: u128, lo: u128, nbits: u32) -> u32 { nbits - 1 + hi.count_ones() + lo.count_ones() - 1 }

fn main() {
    let (pt, n) = ((3i128, 5i128), 1000i128);
    let mut c = fresh();
    let mut psi: Vec<i128> = vec![0, 1, 10, 3 * 81 + 12 * B * 3, 20 * (729 + 20 * B * 27 - 8 * B * B)];
    for k in 5..11usize {                     // division polynomials at P; exact integer steps
        let m = k / 2;
        let cu = |v: i128| v.checked_mul(v).and_then(|w| w.checked_mul(v)).expect("overflow");
        let sqr = |v: i128| v.checked_mul(v).expect("overflow");
        let v = if k % 2 == 1 { psi[m + 2].checked_mul(cu(psi[m])).unwrap() - psi[m - 1].checked_mul(cu(psi[m + 1])).unwrap() }
                else { psi[m].checked_mul(psi[m + 2].checked_mul(sqr(psi[m - 1])).unwrap()
                       - psi[m - 2].checked_mul(sqr(psi[m + 1])).unwrap()).unwrap() / 10 };
        psi.push(v);
    }
    let digits: Vec<String> = (1..11).map(|k| ((2.0 * (psi[k].abs() as f64).log10()) as i64 + 1).to_string()).collect();
    let j2 = jac_dbl(&mut c, (3, 5, 1), 0);
    let rate = 2.0 * (psi[10].abs() as f64).log10() / 100.0;
    println!("curve y^2 = x^3 - 2, P = (3, 5): 5^2 = 25 = 3^3 - 2");
    println!("over Q, tangent slope at P: 3*3^2/(2*5) = {}; 2P = ({}, {})", frac(27, 10),
             frac(j2.0, j2.2 * j2.2), frac(j2.1, j2.2 * j2.2 * j2.2));
    let (x, y) = pt; let j3 = jac_add(&mut c, j2, pt, 0);
    println!("Jacobian doubling of (3 : 5 : 1), integers only: S = {}, T = {}, 8Y^4 = {} -> ({} : {} : {})",
             4 * x * y * y, 3 * x * x, 8 * y * y * y * y, j2.0, j2.1, j2.2);
    let (h, r) = (x * j2.2 * j2.2 - j2.0, y * j2.2 * j2.2 * j2.2 - j2.1);   // x2 Z^2 - X and y2 Z^3 - Y
    println!("Jacobian addition 2P + P: H = {}, R = {}, R^2 = {}, H^3 = {}, 2XH^2 = {}", h, r, r * r, h * h * h, 2 * j2.0 * h * h);
    println!("  3P = ({} : {} : {}) -> x = {}, y = {}", j3.0, j3.1, j3.2, frac(j3.0, j3.2 * j3.2), frac(j3.1, j3.2 * j3.2 * j3.2));
    println!("digits in the denominator of x(nP), n = 1..10: {}", digits.join(" "));
    println!("log10(denominator) / n^2 at n = 10: {:.4}; estimate for x(1000P): about {:.0} digits", rate, (rate * 1e6 / 1e4).round() * 1e4);
    let mut sq = vec![0i128; P_ as usize];
    for v in 0..P_ { sq[(v * v % P_) as usize] += 1 }
    let order: i128 = 1 + (0..P_).map(|u| sq[md(u * u * u + B, P_) as usize]).sum::<i128>();
    println!("mod {}: points on the curve, counted x by x: {}; Hasse window {} +- {:.2}", P_, order, P_ + 1, 2.0 * (P_ as f64).sqrt());
    let bs = bits(n); let mut chain = vec![1i128];
    for bit in bs.chars().skip(1) { let l = *chain.last().unwrap(); chain.push(2 * l); if bit == '1' { chain.push(2 * l + 1) } }
    println!("{} in binary: {}; chain: {}", n, bs, chain.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "));
    c = fresh(); let (a1, ops) = aff_times(&mut c, n, pt); let (i1, m1) = (c.inv, c.mul);
    c = fresh(); let j = jac_times(&mut c, n, pt); let (i2, m2) = (c.inv, c.mul);
    c = fresh(); let a2 = to_affine(&mut c, j); let (i3, m3, ii) = (c.inv, c.mul, c.invmul as u32);
    let e = P_ - 2; let ie = (127 - e.leading_zeros()) + e.count_ones() - 1;
    let p2 = aff_add(&mut fresh(), Some(pt), Some(pt), 3).unwrap();
    let j2p = jac_dbl(&mut fresh(), (3, 5, 1), P_);
    let cost = |f: &dyn Fn(&mut Cnt)| { let mut k = fresh(); f(&mut k); k.mul };
    let ad = cost(&|k| { aff_add(k, Some(pt), Some(pt), 3).unwrap(); });
    let aa = cost(&|k| { aff_add(k, p2, Some(pt), 3).unwrap(); });
    let jd = cost(&|k| { jac_dbl(k, j2p, P_); });
    let ja = cost(&|k| { jac_add(k, j2p, pt, P_); });
    println!("{} doublings + {} additions = {} curve operations, not {}: the top bit is the start", ops[0], ops[1], ops[0] + ops[1],
             bs.len() - 1 + bs.matches('1').count());
    println!("multiplications per step, I = one inversion: affine doubling {} + I, addition {} + I; Jacobian doubling {}, addition {}, back to affine {} + I", ad, aa, jd, ja, m3);
    println!("affine:   {}P = {}; {} inversions, {} other multiplications", n, show(a1), i1, m1);
    println!("Jacobian: ({} : {} : {}) -> {}P = {}; {} inversion, {} other multiplications", j.0, j.1, j.2, n, show(a2), i2 + i3, m2 + m3);
    println!("one inversion: p - 2 = {} = {}: {} squarings + {} multiplications = {}", e, bits(e), 127 - e.leading_zeros(), e.count_ones() - 1, ie);
    let (ta, tj) = (m1 + i1 * ie as u64, m2 + m3 + ie as u64);
    println!("total multiplications at p = {}: affine {}, Jacobian {}, ratio {:.1}", P_, ta, tj, ta as f64 / tj as f64);
    let (mut a3, mut i4) = (Some(pt), 0);
    for _ in 0..n - 1 { a3 = aff_add(&mut c, a3, Some(pt), 3).unwrap(); i4 += 1 }
    println!("{} additions one at a time: {}P = {}; {} inversions", n - 1, n, show(a3), i4);
    let jo = jac_times(&mut c, order, pt); let mut a33 = Some(pt);
    for _ in 0..32 { a33 = aff_add(&mut c, a33, Some(pt), 3).unwrap() }
    let (x33, y33) = a33.unwrap(); let neg33 = Some((x33, md(-y33, P_)));
    println!("{}P by double-and-add: Z = {}, so {}P = O; 33P = {}; -33P = {}", order, jo.2, order, show(a33), show(neg33));
    let red = |c: &mut Cnt, a: i128, d: i128| md(a * inv(c, d).unwrap(), P_);
    let r2 = Some((red(&mut c, 129, 100), red(&mut c, -383, 1000)));
    println!("2P mod {}: by the tangent rule {}; 129/100 and -383/1000 reduced {}", P_, show(p2), show(r2));
    let (hi, lo) = (u128::MAX, u128::MAX - ((1u128 << 32) + 978));   // 2^256 - 2^32 - 979 = p - 2
    let ib = inv_cost(hi, lo, 256) as u64;
    println!("secp256k1 prime 2^256 - 2^32 - 977: one inversion = {} multiplications", ib);
    println!("  {}P there: affine {}, Jacobian {}, ratio {:.1}", n, m1 + i1 * ib, m2 + m3 + ib, (m1 + i1 * ib) as f64 / (m2 + m3 + ib) as f64);
    let (ka, kj) = (255 * (ad + ib) + 128 * (aa + ib), 255 * jd + 128 * ja + m3 + ib);
    println!("  key with 255 doublings, 128 additions: affine {}, Jacobian {}, ratio {:.1}", ka, kj, ka as f64 / kj as f64);
    if let Err(err) = aff_add(&mut c, Some(pt), Some((3, 5 + P_)), 3) { println!("mistake, chord slope used to double P: x2 - x1 = 0, {}", err) }
    let jb = jac_add(&mut c, (3, 5, 1), pt, P_);
    println!("mistake, Jacobian addition used to double P: ({} : {} : {}), not a point", jb.0, jb.1, jb.2);
    let w = aff_add(&mut c, Some(pt), Some(pt), 1).unwrap();
    println!("mistake, tangent slope without the 3: 2P = {}, on the curve: {}", show(w), if on(w) { "yes" } else { "no" });
    let zi = inv(&mut c, j.2).unwrap(); let wz = Some((j.0 * zi % P_, j.1 * zi % P_));
    println!("mistake, Jacobian read as x = X/Z, y = Y/Z: {}, on the curve: {}", show(wz), if on(wz) { "yes" } else { "no" });
    let rs: String = bs.chars().rev().collect(); let rev = i128::from_str_radix(&rs, 2).unwrap();
    println!("mistake, bits read right to left: {} = {}, gives {}P = {}", rs, rev, rev, show(aff_times(&mut c, rev, pt).0));
    for k in [1023i128, 1024] { let o = aff_times(&mut c, k, pt).1; println!("try: {} = {}: {} doublings + {} additions", k, bits(k), o[0], o[1]) }
    println!("try: {} times (3, -5) = {}", n, show(aff_times(&mut c, n, (3, P_ - 5)).0));
    assert!(((order - P_ - 1) as f64).abs() <= 2.0 * (P_ as f64).sqrt() && jo.2 == 0);   // Hasse; 1033P = O
    assert!(a1 == a2 && a2 == a3 && a3 == neg33 && neg33 == Some((498, 929)));           // four roads to 1000P
    assert!(ii == ie && ops[0] + ops[1] == bs.matches('1').count() as u32 - 1 + bs.len() as u32 - 1);
    assert!(p2 == r2);                                                    // mod p agrees with the exact answer
    assert!(!on(w) && !on(wz));                                           // the wrong points are off the curve
    println!("ALL CHECKS PASS");
}
