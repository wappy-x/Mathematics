// Inflections and Cayley-Bacharach on the Fermat cubic x^3 + y^3 = z^3 -- the check behind the card.
// Standard library only.  Exact arithmetic in Z[w], where w is a cube root of 1 (w^2 = -1 - w);
// finite counts mod 7, where 2 is a cube root of 1.  Points are (x : y : z).
use std::ops::{Add, Mul, Sub};
#[derive(Clone, Copy, PartialEq)]
struct W { a: i64, b: i64 } // the number a + b w, with whole numbers a and b
impl Add for W { type Output = W; fn add(self, o: W) -> W { W { a: self.a + o.a, b: self.b + o.b } } }
impl Sub for W { type Output = W; fn sub(self, o: W) -> W { W { a: self.a - o.a, b: self.b - o.b } } }
impl Mul for W { type Output = W; fn mul(self, o: W) -> W { W { a: self.a * o.a - self.b * o.b, b: self.a * o.b + self.b * o.a - self.b * o.b } } }
fn w(a: i64) -> W { W { a, b: 0 } }
const Z: W = W { a: 0, b: 0 }; const P: i64 = 7;
type P3 = [W; 3];
type Poly = &'static [(i64, usize, usize, usize)];
const FERMAT: Poly = &[(1, 3, 0, 0), (1, 0, 3, 0), (-1, 0, 0, 3)]; // x^3 + y^3 - z^3, as (coef, i, j, k)
const NODAL: Poly = &[(1, 0, 2, 1), (-1, 3, 0, 0), (-1, 2, 0, 1)]; // y^2 z - x^3 - x^2 z: the house curve
const NEIGH: Poly = &[(1, 0, 2, 1), (-1, 3, 0, 0), (-1, 2, 0, 1), (-1, 0, 0, 3)]; // a smooth neighbour
fn name(c: W) -> &'static str { match (c.a, c.b) { (0, 0) => "0", (1, 0) => "1", (-1, 0) => "-1", (0, 1) => "ω", (0, -1) => "-ω", (-1, -1) => "ω²", _ => "-ω²" } }
fn show(p: &P3) -> String { format!("({} : {} : {})", name(p[0]), name(p[1]), name(p[2])) }
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn pw(v: W, n: i64) -> W { (0..n).fold(w(1), |r, _| v * r) }
fn ev(f: Poly, p: &P3, d: &[usize]) -> W { // value of f at p, or of its partial derivatives in the directions d
    let mut tot = Z;
    for &(c0, i, j, k) in f {
        let (mut c, mut e) = (c0, [i as i64, j as i64, k as i64]);
        for &a in d { c *= e[a]; e[a] -= 1; }
        if e.iter().all(|&x| x >= 0) { tot = w(c) * pw(p[0], e[0]) * pw(p[1], e[1]) * pw(p[2], e[2]) + tot; }
    }
    tot
}
fn det3(m: &[P3; 3]) -> W {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn hess(f: Poly, p: &P3) -> W { det3(&[0, 1, 2].map(|a| [0, 1, 2].map(|b| ev(f, p, &[a, b])))) }
fn bord(f: Poly, p: &P3) -> W { let (fx, fy) = (ev(f, p, &[0]), ev(f, p, &[1])); ev(f, p, &[0, 0]) * fy * fy - w(2) * ev(f, p, &[0, 1]) * fx * fy + ev(f, p, &[1, 1]) * fx * fx } // affine flex test
fn m2(f: Poly, p: &P3) -> W { ev(f, p, &[0, 0]) * ev(f, p, &[1, 1]) - ev(f, p, &[0, 1]) * ev(f, p, &[0, 1]) } // the plain 2 x 2 Hessian
fn cross(p: &P3, q: &P3) -> P3 { [p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0]] }
fn wp(q: &[i64; 3]) -> P3 { [w(q[0]), w(q[1]), w(q[2])] }
fn md(v: W) -> i64 { v.a.rem_euclid(P) }
fn powm(b: i64, e: i64) -> i64 { (0..e).fold(1, |r, _| r * b % P) }
fn norm(q: [i64; 3]) -> [i64; 3] { let k = (0..3).filter(|&i| q[i] % P != 0).max().unwrap(); q.map(|c| c * powm(q[k], P - 2) % P) }
fn contact3(f: Poly, p: &[i64; 3], q: &[i64; 3]) -> bool {
    let v: Vec<i64> = (0..4).map(|t| md(ev(f, &wp(&[p[0] + t * q[0], p[1] + t * q[1], p[2] + t * q[2]]), &[]))).collect();
    v[0] == 0 && (2..4).all(|t| (v[t as usize] - t * t * t * v[1]).rem_euclid(P) == 0)
}
fn mono(q: &[i64; 3], m: &[i64; 3]) -> i64 { (0..3).fold(1, |r, i| r * powm(q[i], m[i]) % P) }
fn kernel(pts: &[[i64; 3]], mons: &[[i64; 3]]) -> (usize, Vec<Vec<i64>>) { // rank, and a basis of the curves through pts
    let n = mons.len();
    let mut rows: Vec<Vec<i64>> = pts.iter().map(|q| mons.iter().map(|m| mono(q, m)).collect()).collect();
    let (mut piv, mut r) = (vec![], 0);
    for c in 0..n {
        let k = match (r..rows.len()).find(|&i| rows[i][c] != 0) { Some(k) => k, None => continue };
        rows.swap(r, k);
        let inv = powm(rows[r][c], P - 2);
        rows[r] = rows[r].iter().map(|v| v * inv % P).collect();
        for i in 0..rows.len() {
            let f = rows[i][c]; if i == r || f == 0 { continue; }
            rows[i] = (0..n).map(|j| (rows[i][j] - f * rows[r][j]).rem_euclid(P)).collect();
        }
        piv.push(c); r += 1;
    }
    let mut basis = vec![];
    for c in (0..n).filter(|c| !piv.contains(c)) {
        let mut v = vec![0; n]; v[c] = 1;
        for (i, &pc) in piv.iter().enumerate() { v[pc] = (-rows[i][c]).rem_euclid(P); }
        basis.push(v);
    }
    (r, basis)
}
fn vanish(v: &[i64], q: &[i64; 3], mons: &[[i64; 3]]) -> bool { mons.iter().enumerate().map(|(n, m)| v[n] * mono(q, m)).sum::<i64>() % P == 0 }
fn common(pts: &[[i64; 3]], basis: &[Vec<i64>], mons: &[[i64; 3]]) -> Vec<[i64; 3]> {
    pts.iter().filter(|q| basis.iter().all(|b| vanish(b, q, mons))).cloned().collect()
}
fn wroot(s: f64) -> f64 { (0..60).fold(1.5, |w, _| w - (w * w * w + 3.0 * s * s * w - 4.0) / (3.0 * w * w + 3.0 * s * s)) }
fn sv(x: f64, y: f64) -> String { format!("{:.1},{:.1}", 210.0 + 60.0 * x, 210.0 - 60.0 * y) }
fn main() {
    println!("curve x^3 + y^3 = z^3 over the complex numbers; second partials 6x, 6y, -6z, mixed ones 0");
    let (mut hok, mut h3) = (true, true);
    for a in -2..3 { for b in -2..3 { for c in -2..3 { let h = hess(FERMAT, &[w(a), w(b), w(c)]); hok &= h == w(-216 * a * b * c); h3 &= h.a % 3 == 0 && h.b % 3 == 0; } } }
    println!("Hessian determinant equals -216xyz at all 125 points of a 5 x 5 x 5 grid: {}; so H = 0 is xyz = 0; mod 3 it is 0 at all of them: {}", yn(hok), yn(h3));
    let r3 = [w(1), W { a: 0, b: 1 }, W { a: -1, b: -1 }]; // 1, w, w^2
    let flex: Vec<P3> = (0..9).map(|n| { let r = r3[n % 3]; [[Z, r, w(1)], [r, Z, w(1)], [w(1), Z - r, Z]][n / 3] }).collect();
    for (n, side) in ["x = 0: y^3 = z^3", "y = 0: x^3 = z^3", "z = 0: x^3 = -y^3"].iter().enumerate() {
        println!("on {:18} {}", side, flex[3 * n..3 * n + 3].iter().map(show).collect::<Vec<_>>().join(", "));
    }
    let on = flex.iter().all(|p| ev(FERMAT, p, &[]) == Z && hess(FERMAT, p) == Z);
    let dist = (0..81).filter(|n| n / 9 < n % 9 && cross(&flex[n / 9], &flex[n % 9]) != [Z; 3]).count();
    println!("all nine on the curve and on H: {}; distinct pairs {} of 36; Bezout 3 x 3 = 9, so each meeting is simple", yn(on), dist);
    let mut tri = 0;
    for p in &flex { // road two: the tangent line meets the curve three times at p
        let g = [ev(FERMAT, p, &[0]), ev(FERMAT, p, &[1]), ev(FERMAT, p, &[2])];
        let q = cross(&g, &[w(1), w(2), w(3)]);
        assert!(cross(p, &q) != [Z; 3]);
        let v: Vec<W> = (0..4).map(|t| ev(FERMAT, &[p[0] + w(t) * q[0], p[1] + w(t) * q[1], p[2] + w(t) * q[2]], &[])).collect();
        if v[0] == Z && v[1] != Z && (2..4).all(|t| v[t as usize] == w(t * t * t) * v[1]) { tri += 1; }
    }
    println!("tangent test, F(P + tQ) = c t^3 along the tangent: {} of 9 points meet it three times", tri);
    assert!(hok && on && dist == 36 && tri == 9);
    let real: Vec<&P3> = flex.iter().filter(|p| p.iter().all(|c| c.b == 0)).collect();
    let mut lines = vec![];
    for i in 0..9 { for j in i + 1..9 { for k in j + 1..9 { if det3(&[flex[i], flex[j], flex[k]]) == Z { lines.push([i, j, k]); } } } }
    let lxy: Poly = &[(1, 1, 0, 0), (1, 0, 1, 0), (-1, 0, 0, 1)];
    println!("real flexes {}; on the line x + y = z: {}", real.iter().map(|p| show(p)).collect::<Vec<_>>().join(", "),
        yn(real.iter().all(|p| ev(lxy, p, &[]) == Z)));
    let pok = (0..81).filter(|n| n / 9 < n % 9).all(|n| lines.iter().filter(|l| l.contains(&(n / 9)) && l.contains(&(n % 9))).count() == 1);
    println!("collinear triples among the nine flexes: {} of 84; every pair of flexes on exactly one: {}", lines.len(), yn(pok));
    assert!(real.len() == 3 && lines.len() == 12 && pok);
    let lf = |r: W, p: &P3| p[0] + r * p[1] - r * r * p[2]; // x + y - z, x + wy - w^2 z, x + w^2 y - wz
    let conic: Poly = &[(1, 2, 0, 0), (-1, 1, 1, 0), (1, 0, 2, 0), (1, 1, 0, 1), (1, 0, 1, 1), (1, 0, 0, 2)];
    let (mut t1, mut t2, mut t3) = (true, true, true);
    for a in -1..3 { for b in -1..3 { for c in -1..3 {
        let p = [w(a), w(b), w(c)];
        t1 &= lf(r3[0], &p) * lf(r3[1], &p) * lf(r3[2], &p) == ev(FERMAT, &p, &[]) + w(3 * a * b * c);
        t2 &= lf(r3[1], &p) * lf(r3[2], &p) == ev(conic, &p, &[]);
        t3 &= w((a + b - c).pow(3) - 3 * (a - c) * (b - c) * (a + b)) == ev(FERMAT, &p, &[]);
    } } }
    let one = flex.iter().all(|p| r3.iter().filter(|&&r| lf(r, p) == Z).count() == 1);
    println!("(x + y - z)(x^2 - xy + y^2 + xz + yz + z^2) = x^3 + y^3 - z^3 + 3xyz at all 64 grid points: {}", yn(t1 && t2));
    println!("the conic is (x + ωy - ω²z)(x + ω²y - ωz); each flex lies on exactly one of the three lines: {}", yn(one));
    println!("real flex tangents x = z, y = z, x + y = 0 and flex line x + y = z: (x + y - z)^3 - 3(x - z)(y - z)(x + y) = x^3 + y^3 - z^3 at all 64 grid points: {}", yn(t3));
    assert!(t1 && t2 && one && t3);
    let pts: Vec<[i64; 3]> = (0..P * P).map(|n| [n / P, n % P, 1]).chain((0..P).map(|x| [x, 1, 0])).chain([[1, 0, 0]]).collect(); // road three: mod 7
    let f7: Vec<[i64; 3]> = flex.iter().map(|q| norm([0, 1, 2].map(|i| (q[i].a + 2 * q[i].b).rem_euclid(P)))).collect();
    println!("mod 7, with ω = 2: the flexes become {}", f7.iter().map(|q| format!("({} {} {})", q[0], q[1], q[2])).collect::<Vec<_>>().join(", "));
    for (nm, f) in [("x^3 + y^3 = z^3", FERMAT), ("y^2 = x^3 + x^2 + 1", NEIGH), ("y^2 = x^2(x + 1)", NODAL)] {
        let cur: Vec<[i64; 3]> = pts.iter().filter(|q| md(ev(f, &wp(q), &[])) == 0).cloned().collect();
        let smooth: Vec<[i64; 3]> = cur.iter().filter(|q| (0..3).any(|a| md(ev(f, &wp(q), &[a])) != 0)).cloned().collect();
        let brute: Vec<[i64; 3]> = smooth.iter().filter(|q| pts.iter().any(|r| r != *q && contact3(f, q, r))).cloned().collect();
        let hz: Vec<[i64; 3]> = smooth.iter().filter(|q| md(hess(f, &wp(q))) == 0).cloned().collect();
        let eu = cur.iter().all(|q| md(w(q[2] * q[2]) * hess(f, &wp(q)) + w(4) * bord(f, &wp(q))) == 0);
        println!("mod 7, {:19}: {:2} points, {:2} smooth; flexes by trying every line {}, by the Hessian {}; same points: {}; z^2 H = -4 x bordered Hessian at all of them: {}",
            nm, cur.len(), smooth.len(), brute.len(), hz.len(), yn(brute == hz), yn(eu));
        assert!(brute == hz && eu);
        if f == FERMAT { let (mut a, mut b) = (brute.clone(), f7.clone()); a.sort(); b.sort(); assert!(a == b && a.len() == 9); }
    }
    let mons = |d: i64| (0..=d).rev().flat_map(|i| (0..=d - i).rev().map(move |j| [i, j, d - i - j])).collect::<Vec<_>>();
    let (mon3, mon2) = (mons(3), mons(2));
    let (fv, xv): (Vec<i64>, Vec<i64>) = (vec![1, 0, 0, 0, 0, 0, 1, 0, 0, P - 1], mon3.iter().map(|m| (*m == [1, 1, 1]) as i64).collect());
    let (mut good, mut sf7) = (0, f7.clone()); sf7.sort();
    for k in 0..9 { // Cayley-Bacharach: leave out each flex in turn
        let eight: Vec<[i64; 3]> = f7.iter().enumerate().filter(|&(i, _)| i != k).map(|(_, q)| *q).collect();
        let (r, b) = kernel(&eight, &mon3);
        let inf = [&fv, &xv].iter().all(|v| eight.iter().all(|q| vanish(v, q, &mon3)));
        let mut cm = common(&pts, &b, &mon3); cm.sort();
        if r == 8 && b.len() == 2 && inf && cm == sf7 { good += 1; }
    }
    println!("cubics through 8 of the 9 flexes, each of the 9 ways: rank 8 of 10, 2 free coefficients, spanned by x^3 + y^3 - z^3 and xyz; common points of all of them: the 9 flexes, in {} of 9 cases", good);
    assert!(good == 9);
    println!("rank 8 mod 7 forces rank 8 over Z[ω]; so over C too every cubic through 8 flexes is a·(x^3 + y^3 - z^3) + b·xyz");
    let (aff, aff2) = (flex.iter().filter(|q| q[2] != Z && bord(FERMAT, q) == Z).count(), flex.iter().filter(|q| q[2] != Z && m2(FERMAT, q) == Z).count()); // what breaks
    println!("mistake, affine plane: the bordered Hessian of x^3 + y^3 = 1 is 0 at {} flexes (the plain 2 x 2 Hessian, by luck, at {}); the 3 on the line at infinity z = 0 are lost", aff, aff2);
    let lin = (-2..3).all(|x| (-2..3).all(|y| m2(NEIGH, &[w(x), w(y), w(1)]) == w(-12 * x - 4)));
    let off: Vec<(i64, i64)> = (0..4).map(|y| (m2(NEIGH, &[w(-1), w(y), w(3)]).a, hess(NEIGH, &[w(-1), w(y), w(3)]).a)).collect();
    println!("mistake, plain 2 x 2 Hessian of y^2 = x^3 + x^2 + 1: equals -12x - 4 on the 5 x 5 grid: {}; on the line x = -1/3, at (-1 : y : 3) for y = 0..3, (2 x 2, H) = {:?}: the 2 x 2 test says flex, H is never 0, so no flex lies there", yn(lin), off);
    let nod = (0..10).all(|t: i64| hess(NODAL, &[w(t * t - 1), w(t * t * t - t), w(1)]) == w(8 * (t * t - 1).pow(3) * (3 * t * t + 1)));
    println!("mistake, a node: on y^2 = x^2(x + 1), put x = t^2 - 1, y = t^3 - t; H = 8(t - 1)^3(t + 1)^3(3t^2 + 1) at t = 0..9: {}", yn(nod));
    let o = [Z, w(1), Z]; println!("  the node (t = 1 and t = -1) takes 3 + 3 = 6 of the 9 meetings; flexes: (0 : 1 : 0), on H: {}, and two complex ones at 3t^2 + 1 = 0: 3 in all", yn(ev(NODAL, &o, &[]) == Z && hess(NODAL, &o) == Z));
    let (rc, bc) = kernel(&[[1, 1, 1], [1, P - 1, 1], [P - 1, 1, 1]], &mon2);
    let cv: Vec<i64> = [(1, 1), (1, -1), (-1, 1), (-1, -1)].iter().map(|&(x, y): &(i64, i64)| (x - 1) * (1 - y)).collect();
    println!("mistake, conics: x^2 = 1 and y^2 = 1 meet at 4 corners; conics through 3 corners have {} free coefficients, not 2; (x - 1)(1 - y) at the corners: {:?}", bc.len(), cv);
    let line4 = [[0, 0, 1], [1, 0, 1], [2, 0, 1], [3, 0, 1], [0, 1, 1], [1, 3, 1], [3, 2, 1], [5, 6, 1]];
    let (r4, b4) = kernel(&line4, &mon3); let c4 = common(&pts, &b4, &mon3); let on4 = c4.iter().filter(|q| q[1] == 0).count();
    println!("mistake, 8 points with 4 on the line y = 0 (mod 7): rank {}, but every cubic through them contains the line; common points {}: {} on the line y = 0, {} off it; not 9", r4, c4.len(), on4, c4.len() - on4);
    assert!(aff == 6 && aff2 == 6 && lin && off.iter().all(|&(a, h)| a == 0 && h != 0) && nod && rc == 3 && !common(&pts, &bc, &mon2).contains(&[P - 1, P - 1, 1]));
    assert!(r4 == 8 && on4 as i64 == P + 1 && c4.len() == 12);
    let curve: Vec<String> = (0..53).map(|i| { let s = -6.5 + 0.25 * i as f64; let wv = wroot(s); sv((wv + s) / 2.0, (wv - s) / 2.0) }).collect();
    println!("figure, 1 unit = 60, origin (210,210), curve: {}", curve.join(" "));
    println!("figure, flexes {} {} line x + y = 1 {} to {} asymptote {} to {} tangents {} to {} and {} to {}", sv(1.0, 0.0), sv(0.0, 1.0), sv(-2.4, 3.4), sv(3.4, -2.4), sv(-3.4, 3.4), sv(3.4, -3.4), sv(1.0, 3.4), sv(1.0, -3.4), sv(-3.4, 1.0), sv(3.4, 1.0));
    println!("ALL CHECKS PASS");
}
