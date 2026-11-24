// Ceva and Menelaus -- the same check as the Python, in Rust, no crates.  Triangle A (0, 0), B (6, 0), C (2, 4).
// Roads: multiply three signed side ratios; meet the lines and test the third directly; areas at the meeting point.
#[derive(Clone, Copy, PartialEq)]
struct Q(i64, i64); // numerator, denominator; always in lowest terms, denominator positive
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sb(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn dv(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn f(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
fn s(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
type P = (Q, Q); // a point: two exact coordinates
fn n(k: i64) -> Q { Q(k, 1) }
fn sub(p: P, r: P) -> P { (sb(p.0, r.0), sb(p.1, r.1)) }
fn cross(u: P, v: P) -> Q { sb(mul(u.0, v.1), mul(u.1, v.0)) }
fn dot(u: P, v: P) -> Q { add(mul(u.0, v.0), mul(u.1, v.1)) }
fn at(p: P, r: P, t: Q) -> P { (add(p.0, mul(t, sb(r.0, p.0))), add(p.1, mul(t, sb(r.1, p.1)))) }
fn ratio(p: P, x: P, r: P) -> Q { // signed PX/XR: negative when X lies outside P-R
    let t = dv(dot(sub(x, p), sub(r, p)), dot(sub(r, p), sub(r, p)));
    dv(t, sb(n(1), t))
}
fn meet(p: P, r: P, a: P, b: P) -> P { at(p, r, dv(cross(sub(a, p), sub(b, a)), cross(sub(r, p), sub(b, a)))) }
fn area(p: P, r: P, t: P) -> Q { let c = cross(sub(r, p), sub(t, p)); q(c.0.abs(), 2 * c.1) }
fn pt(p: P) -> String { format!("({}, {})", s(p.0), s(p.1)) }
fn foot(p: P, r: P, t: P) -> P { at(r, t, dv(dot(sub(p, r), sub(t, r)), dot(sub(t, r), sub(t, r)))) }
const A: P = (Q(0, 1), Q(0, 1)); const B: P = (Q(6, 1), Q(0, 1)); const C: P = (Q(2, 1), Q(4, 1));
fn ceva(d: P, e: P, fp: P, name: &str) -> (Q, P, Q) { // D on BC, E on CA, F on AB
    let r = [ratio(A, fp, B), ratio(B, d, C), ratio(C, e, A)];
    let p = meet(A, d, B, e); // two lines meet at P; does the third pass?
    let miss = cross(sub(fp, C), sub(p, C)); // 0 exactly when P lies on line CF
    let gap = f(miss).abs() / f(dot(sub(fp, C), sub(fp, C))).sqrt();
    let pr = mul(mul(r[0], r[1]), r[2]);
    println!("{}: feet F {}, D {}, E {}; AF/FB {}, BD/DC {}, CE/EA {}; product {}; AD and BE meet at {}; P is {:.2} off CF",
             name, pt(fp), pt(d), pt(e), s(r[0]), s(r[1]), s(r[2]), s(pr), pt(p), gap);
    (pr, p, miss)
}
fn main() {
    println!("triangle A {}, B {}, C {}; area {}", pt(A), pt(B), pt(C), s(area(A, B, C)));
    let (pm, g, mm) = ceva(at(B, C, q(1, 2)), at(C, A, q(1, 2)), at(A, B, q(1, 2)), "medians");
    let (da, eb, fc) = (foot(A, B, C), foot(B, C, A), foot(C, A, B));
    let (ph, h, mh) = ceva(da, eb, fc, "altitudes");
    let ar = [area(A, B, h), area(B, C, h), area(C, A, h)];
    println!("areas at H: ABH {}, BCH {}, CAH {}; CAH/BCH {}, ABH/CAH {}, BCH/ABH {}", s(ar[0]), s(ar[1]), s(ar[2]),
             s(dv(ar[2], ar[1])), s(dv(ar[0], ar[2])), s(dv(ar[1], ar[0])));
    let (px, _, mx) = ceva(at(B, C, q(1, 2)), at(C, A, q(1, 2)), fc, "mixed");
    let (nn, l, m) = ((n(9), n(0)), at(B, C, q(1, 4)), at(C, A, q(1, 2))); // one straight line
    let mr = [ratio(A, nn, B), ratio(B, l, C), ratio(C, m, A)];
    let k = meet(A, B, C, (add(C.0, sb(nn.0, m.0)), add(C.1, sb(nn.1, m.1)))); // through C, parallel
    let mp = mul(mul(mr[0], mr[1]), mr[2]);
    println!("transversal: N {}, L {}, M {}; AN/NB {}, BL/LC {}, CM/MA {}; product {}; off-line by {}",
             pt(nn), pt(l), pt(m), s(mr[0]), s(mr[1]), s(mr[2]), s(mp), s(cross(sub(l, nn), sub(m, nn))));
    println!("slips: altitudes with BD/DC flipped {}; transversal with signs dropped {}",
             s(mul(dv(ratio(A, fc, B), ratio(B, da, C)), ratio(C, eb, A))), s(q(mp.0.abs(), mp.1)));
    println!("parallel through C meets AB at K {}; BN/NK {}, KN/NA {}", pt(k), s(ratio(B, nn, k)), s(ratio(k, nn, A)));
    let (mut cv, mut mn, mut bad, mut tot) = (0, 0, 0, 0);
    for i in 1..6 { for j in 1..6 { for kk in 1..6 { // every cevian triple on the sixths of the sides
        let (d, e, fp) = (at(B, C, q(i, 6)), at(C, A, q(j, 6)), at(A, B, q(kk, 6)));
        let one = mul(mul(ratio(A, fp, B), ratio(B, d, C)), ratio(C, e, A)) == n(1);
        let p = meet(A, d, B, e);
        cv += one as i32; tot += 1; bad += (one != (cross(sub(fp, C), sub(p, C)) == n(0))) as i32;
    } } }
    let st = [n(-1), q(-1, 2), q(1, 3), q(1, 2), q(2, 3), q(3, 2), n(2), n(3)];
    for &i in &st { for &j in &st { for &kk in &st { // points on the three side-lines, inside or out
        let (l2, m2, n2) = (at(B, C, i), at(C, A, j), at(A, B, kk));
        let one = mul(mul(ratio(A, n2, B), ratio(B, l2, C)), ratio(C, m2, A)) == n(-1);
        mn += one as i32; bad += (one != (cross(sub(l2, n2), sub(m2, n2)) == n(0))) as i32;
    } } }
    println!("sweep: Ceva product 1 for {} of {} triples, Menelaus -1 for {} of {}; mismatches {}", cv, tot, mn, st.len().pow(3), bad);
    let sv = |p: P| format!("({:.1}, {:.1})", 24.0 + 34.0 * f(p.0), 172.0 - 34.0 * f(p.1));
    let pts = [("A", A), ("B", B), ("C", C), ("H", h), ("D", da), ("E", eb), ("F", fc), ("L", l), ("M", m), ("N", nn)];
    println!("figure, 1 unit = 34: {}", pts.iter().map(|(t, p)| format!("{} {}", t, sv(*p))).collect::<Vec<_>>().join(", "));
    assert!(pm == n(1) && mm == n(0) && g == (q(8, 3), q(4, 3))); // medians: product 1, they meet
    assert!(ph == n(1) && mh == n(0) && h == (n(2), n(2))); // altitudes: product 1, they meet
    assert!([dv(ar[2], ar[1]), dv(ar[0], ar[2]), dv(ar[1], ar[0])] == [ratio(A, fc, B), ratio(B, da, C), ratio(C, eb, A)]);
    assert!(px != n(1) && mx != n(0)); // product off 1: the lines miss
    assert!(mp == n(-1) && cross(sub(l, nn), sub(m, nn)) == n(0));
    assert!(ratio(B, nn, k) == mr[1] && ratio(k, nn, A) == mr[2] && bad == 0);
    println!("ALL CHECKS PASS");
}
