// The Jacobian of the genus-2 curve y^2 = x^5 + x + 1 over F_5 -- the same check as the Python.
// No crates.  F_25 is F_5 with a new element t, t^2 = 2; the number a + 5b stands for
// a + b t, so 0..4 are F_5 itself.  A polynomial is a list of coefficients, lowest power first.
type P = Vec<usize>;
type D = (P, P);
type Pt = Option<(usize, usize)>;
fn add(a: usize, b: usize) -> usize { (a + b) % 5 + 5 * ((a / 5 + b / 5) % 5) }
fn mul(a: usize, b: usize) -> usize {
    (a % 5 * (b % 5) + 2 * (a / 5) * (b / 5)) % 5 + 5 * ((a % 5 * (b / 5) + a / 5 * (b % 5)) % 5)
}
fn neg(a: usize) -> usize { (0..25).find(|&b| add(a, b) == 0).unwrap() }
fn inv(a: usize) -> usize { (1..25).find(|&b| mul(a, b) == 1).unwrap() }

fn trim(mut a: P) -> P { while a.last() == Some(&0) { a.pop(); } a }
fn padd(a: &P, b: &P) -> P {
    let n = a.len().max(b.len());
    trim((0..n).map(|i| add(*a.get(i).unwrap_or(&0), *b.get(i).unwrap_or(&0))).collect())
}
fn pneg(a: &P) -> P { a.iter().map(|&x| neg(x)).collect() }
fn scale(c: usize, a: &P) -> P { trim(a.iter().map(|&x| mul(c, x)).collect()) }
fn pmul(a: &P, b: &P) -> P {
    if a.is_empty() || b.is_empty() { return vec![]; }
    let mut r = vec![0; a.len() + b.len() - 1];
    for (i, &x) in a.iter().enumerate() { for (j, &y) in b.iter().enumerate() { r[i + j] = add(r[i + j], mul(x, y)); } }
    trim(r)
}
fn pdivmod(a: &P, b: &P) -> (P, P) {                 // long division by a nonzero b
    let mut a = trim(a.clone());
    let mut qt = vec![0; (a.len() + 1).saturating_sub(b.len())];
    while a.len() >= b.len() {
        let (c, s) = (mul(a[a.len() - 1], inv(b[b.len() - 1])), a.len() - b.len());
        qt[s] = c;
        let mut sh = vec![0; s];
        sh.extend(scale(c, b));
        a = padd(&a, &pneg(&sh));
    }
    (trim(qt), a)
}
fn xgcd(a: &P, b: &P) -> (P, P, P) {                 // Euclid, keeping d = s a + t b, d monic
    let (mut r0, mut r1, mut s0, mut s1, mut t0, mut t1) = (a.clone(), b.clone(), vec![1], vec![], vec![], vec![1]);
    while !r1.is_empty() {
        let (qt, r) = pdivmod(&r0, &r1);
        let (s2, t2) = (padd(&s0, &pneg(&pmul(&qt, &s1))), padd(&t0, &pneg(&pmul(&qt, &t1))));
        r0 = std::mem::replace(&mut r1, r);
        s0 = std::mem::replace(&mut s1, s2);
        t0 = std::mem::replace(&mut t1, t2);
    }
    let c = inv(r0[r0.len() - 1]);
    (scale(c, &r0), scale(c, &s0), scale(c, &t0))
}
fn ev(a: &P, x: usize) -> usize { a.iter().rev().fold(0, |o, &c| add(mul(o, x), c)) }
fn cantor(d1: &D, d2: &D, f: &P, g: usize, keep: &mut Vec<D>) -> D {   // add; reduce until deg u <= g
    let ((u1, v1), (u2, v2)) = (d1, d2);
    let (dd1, e1, e2) = xgcd(u1, u2);
    let (d, c1, c2) = xgcd(&dd1, &padd(v1, v2));
    let mut u = pdivmod(&pmul(u1, u2), &pmul(&d, &d)).0;
    let w = padd(&padd(&pmul(&pmul(&c1, &e1), &pmul(u1, v2)), &pmul(&pmul(&c1, &e2), &pmul(u2, v1))),
                 &pmul(&c2, &padd(&pmul(v1, v2), f)));
    let mut v = pdivmod(&pdivmod(&w, &d).0, &u).1;
    keep.push((u.clone(), v.clone()));
    while u.len() - 1 > g {
        u = pdivmod(&padd(f, &pneg(&pmul(&v, &v))), &u).0;
        v = pdivmod(&pneg(&v), &u).1;
    }
    (scale(inv(u[u.len() - 1]), &u), v)
}
fn sum(a: &D, b: &D, f: &P, g: usize) -> D { cantor(a, b, f, g, &mut vec![]) }
fn pairs(f: &P, q: usize, top: usize) -> Vec<D> {   // every (u, v): u monic, deg v < deg u <= top, u | v^2 - f
    let mut out = vec![];
    for d in 0..=top as u32 {
        for k in 0..q.pow(d) {
            let mut u: P = (0..d).map(|i| k / q.pow(i) % q).collect();
            u.push(1);
            for m in 0..q.pow(d) {
                let v = trim((0..d).map(|i| m / q.pow(i) % q).collect());
                if pdivmod(&padd(f, &pneg(&pmul(&v, &v))), &u).1.is_empty() { out.push((u.clone(), v)); }
            }
        }
    }
    out
}
fn npoints(f: &P, q: usize) -> usize { 1 + (0..q).map(|x| (0..q).filter(|&y| mul(y, y) == ev(f, x)).count()).sum::<usize>() }
fn px(a: &P) -> String {
    let t: Vec<String> = (0..a.len()).rev().filter(|&i| a[i] != 0).map(|i| format!("{}{}",
        if a[i] != 1 || i == 0 { a[i].to_string() } else { String::new() },
        match i { 0 => String::new(), 1 => "x".to_string(), _ => format!("x^{}", i) })).collect();
    if t.is_empty() { "0".to_string() } else { t.join(" + ") }
}
fn show(d: &D) -> String { format!("({}, {})", px(&d.0), px(&d.1)) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn chord(p: Pt, q: Pt) -> Pt {                       // the chord-and-tangent law on y^2 = x^3 + x^2 + 1
    let (Some((x1, y1)), Some((x2, y2))) = (p, q) else { return if p.is_none() { q } else { p } };
    if x1 == x2 && add(y1, y2) == 0 { return None; }
    let m = if p != q { mul(add(y1, neg(y2)), inv(add(x1, neg(x2)))) }
            else { mul(add(mul(3, mul(x1, x1)), mul(2, x1)), inv(mul(2, y1))) };
    let x = add(add(mul(m, m), neg(1)), neg(add(x1, x2)));
    Some((x, neg(add(y1, mul(m, add(x, neg(x1)))))))
}
fn aj(p: Pt) -> D { match p { None => (vec![1], vec![]), Some((x, y)) => (vec![neg(x), 1], trim(vec![y])) } }  // P -> class of P - O
fn main() {
    let (f, q, g): (P, usize, usize) = (vec![1, 1, 0, 0, 0, 1], 5, 2);
    let deriv = trim(f.iter().enumerate().map(|(i, &c)| i * c % 5).skip(1).collect());
    println!("curve y^2 = x^5 + x + 1 over F_5; gcd(f, f') = {}, so smooth; genus {}", px(&xgcd(&f, &deriv).0), g);
    let pts: Vec<(usize, usize)> = (0..q).flat_map(|x| (0..q).map(move |y| (x, y))).filter(|&(x, y)| mul(y, y) == ev(&f, x)).collect();
    let (n1, n2) = (npoints(&f, 5) as i64, npoints(&f, 25) as i64);
    println!("affine points over F_5: {:?}; with the point at infinity N1 = {}", pts, n1);
    println!("f(x) at x = 0..4: {:?}; monic u of degree <= 2: {} over F_5, {} over F_25", (0..5).map(|x| ev(&f, x)).collect::<Vec<usize>>(), 1 + 5 + 25, 1 + 25 + 625);
    println!("points over F_25: N2 = {}", n2);
    let qi = q as i64;
    let a1 = n1 - qi - 1;
    let a2 = (n2 - qi * qi - 1 + a1 * a1) / 2;
    let (l1, lm1) = (1 + a1 + a2 + qi * a1 + qi * qi, 1 - a1 + a2 - qi * a1 + qi * qi);
    println!("L-polynomial: 1 + {}T + {}T^2 + {}T^3 + {}T^4; L(1) = {}, L(-1) = {}", a1, a2, qi * a1, qi * qi, l1, lm1);
    let sym2 = (n1 * n1 + n2) / 2;
    println!("effective degree-2 divisors: {} rational pairs + {} conjugate pairs = {}", n1 * (n1 + 1) / 2, (n2 - n1) / 2, sym2);
    println!("formula (N1^2 + N2)/2 - q = {} - {} = {}", sym2, q, sym2 - qi);
    let jac = pairs(&f, q, g);
    let by_deg: Vec<usize> = (0..3).map(|d| jac.iter().filter(|(u, _)| u.len() - 1 == d).count()).collect();
    println!("reduced pairs (u, v) by deg u = 0, 1, 2: {:?}; total #Jac(F_5) = {}", by_deg, jac.len());
    println!("the {} split as {} + {} + {}: one class each, and q + 1 = 6 on the canonical class", sym2, by_deg[2], by_deg[1], q + 1);
    let j25 = pairs(&f, 25, g).len() as i64;
    println!("#Jac(F_25) by enumeration = {}; L(1) L(-1) = {}", j25, l1 * lm1);
    let (lo, hi) = ((5f64.sqrt() - 1.0).powi(4), (5f64.sqrt() + 1.0).powi(4));
    println!("Weil window for #Jac(F_5): {:.2} to {:.2}; q^g = {}", lo, hi, q.pow(g as u32));
    let (d1, d2, d3): (D, D, D) = ((vec![0, 1], vec![1]), (vec![1, 1], vec![2]), (vec![3, 1], vec![]));
    println!("D1 = (0, 1) - oo is {}; D2 = (4, 2) - oo is {}; D3 = (2, 0) - oo is {}", show(&d1), show(&d2), show(&d3));
    println!("D1 + D2 = {}", show(&sum(&d1, &d2, &f, g)));
    let two = sum(&d1, &d1, &f, g);
    let mut raw = vec![];
    let three = cantor(&two, &d1, &f, g, &mut raw);
    println!("2 D1 = {}; 3 D1 before reduction {}, after {}", show(&two), show(&raw[0]), show(&three));
    println!("u = x^2 + x + 2 has no root in F_5: {}; f = (x - 2)(x^2 + x + 2)(x^2 + x + 1): {}",
             yn((0..5).all(|x| ev(&three.0, x) != 0)), yn(pmul(&pmul(&vec![3, 1], &vec![2, 1, 1]), &vec![1, 1, 1]) == f));
    let closed = jac.iter().all(|a| jac.iter().all(|b| jac.contains(&sum(a, b, &f, g))));
    let orders: Vec<usize> = jac.iter().map(|a| {
        let (mut k, mut b) = (1, a.clone());
        while b != (vec![1], vec![]) { k += 1; b = sum(&b, a, &f, g); }
        k
    }).collect();
    println!("every sum of two of the 36 is one of the 36: {}", yn(closed));
    let mut ks: Vec<usize> = orders.clone();
    ks.sort();
    ks.dedup();
    let parts: Vec<String> = ks.iter().map(|k| format!("{}: {}", k, orders.iter().filter(|&o| o == k).count())).collect();
    let exponent = *orders.iter().max().unwrap();
    println!("orders: {}; exponent {}, so (Z/6)^2; D1 has order {}", parts.join(", "), exponent, orders[jac.iter().position(|d| *d == d1).unwrap()]);
    let semi = pairs(&f, q, 3).len();
    println!("mistake 1, drop the - q: {}; mistake 2, drop infinity: ({} + {})/2 - 5 = {}", sym2, (n1 - 1) * (n1 - 1), n2 - 1, ((n1 - 1) * (n1 - 1) + n2 - 1) / 2 - 5);
    println!("mistake 3, stop before reducing: pairs with deg u <= 3 number {}, not {}", semi, jac.len());
    let fe: P = vec![1, 0, 1, 1];
    let je = pairs(&fe, q, 1);
    let mut pts_e: Vec<Pt> = vec![None];
    for x in 0..q { for y in 0..q { if mul(y, y) == ev(&fe, x) { pts_e.push(Some((x, y))); } } }
    let agree = pts_e.iter().all(|&p| pts_e.iter().all(|&r| sum(&aj(p), &aj(r), &fe, 1) == aj(chord(p, r))));
    println!("genus 1, y^2 = x^3 + x^2 + 1: {} points, {} classes; Cantor = chord-and-tangent on all 25 pairs: {}", pts_e.len(), je.len(), yn(agree));
    let (cx, cy) = chord(Some((0, 1)), Some((4, 4))).unwrap();
    println!("(0, 1) + (4, 4) = ({}, {}); Cantor gives {}", cx, cy, show(&sum(&aj(Some((0, 1))), &aj(Some((4, 4))), &fe, 1)));
    let fh: P = vec![0, 0, 1, 1];
    let mut smooth: Vec<D> = vec![(vec![1], vec![])];
    for x in 1..q { for y in 0..q { if mul(y, y) == ev(&fh, x) { smooth.push(aj(Some((x, y)))); } } }
    let ok_h = smooth.iter().all(|a| smooth.iter().all(|b| smooth.contains(&sum(a, b, &fh, 1))));
    println!("mistake 4, nodal y^2 = x^3 + x^2: {} points, but the smooth ones give a group of {} (closed: {})", npoints(&fh, 5), smooth.len(), yn(ok_h));
    assert!(jac.len() as i64 == sym2 - qi && sym2 - qi == 36);               // enumeration = divisor count
    assert!(j25 == l1 * lm1 && j25 == 1296);                                  // over F_25, enumeration = L(1) L(-1)
    assert!((by_deg[2] + by_deg[1] + q + 1) as i64 == sym2);                  // the fibres of Sym^2 over the Jacobian
    assert!(closed && exponent == 6 && three == (vec![2, 1, 1], vec![]));
    assert!(agree && je.len() == pts_e.len() && je.len() == 5);               // genus 1: Jacobian = curve
    assert!(ok_h && smooth.len() == 4 && npoints(&fh, 5) != 4);
    println!("ALL CHECKS PASS");
}
