// Proj of a graded ring -- the same check as proj_of_a_graded_ring_check.py, in
// Rust.  Standard library only, no crates; every number is an exact integer mod p.
use std::collections::BTreeSet;
const P: i64 = 7;
fn proj_points(n: usize, p: i64) -> Vec<Vec<i64>> { // P^n(F_p): first nonzero coordinate scaled to 1
    let mut out = vec![];
    for i in 0..=n {
        for rest in 0..p.pow((n - i) as u32) {
            let mut v = vec![0; i];
            v.push(1);
            for j in 0..(n - i) { v.push(rest / p.pow(j as u32) % p); }
            out.push(v);
        }
    }
    out
}
fn inv(a: i64, p: i64) -> i64 { let mut r = 1; for _ in 0..p - 2 { r = r * a % p; } r } // a^(p-2)
fn norm(v: &[i64], p: i64) -> Vec<i64> { // scale a nonzero vector: first nonzero entry 1
    let a = *v.iter().find(|c| *c % p != 0).unwrap();
    v.iter().map(|c| c * inv(a, p) % p).collect()
}
fn show(q: &[i64]) -> String { format!("({})", q.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" : ")) }
fn rank(rows: &[Vec<i64>], p: i64) -> usize { // Gaussian elimination mod p
    let mut rows = rows.to_vec();
    let mut r = 0;
    let cols = if rows.is_empty() { 0 } else { rows[0].len() };
    for c in 0..cols {
        let piv = match (r..rows.len()).find(|&i| rows[i][c] % p != 0) { Some(i) => i, None => continue };
        rows.swap(r, piv);
        let k = inv(rows[r][c].rem_euclid(p), p);
        for i in 0..rows.len() {
            if i != r && rows[i][c] % p != 0 {
                let f = rows[i][c] * k % p;
                let pr = rows[r].clone();
                rows[i] = rows[i].iter().zip(pr.iter()).map(|(x, y)| (x - f * y).rem_euclid(p)).collect();
            }
        }
        r += 1;
    }
    r
}
fn roots(c: &[i64], p: i64) -> usize { // points (s : t) of P^1(F_p) where the form vanishes
    let d = c.len() - 1;
    proj_points(1, p).iter().filter(|q| c.iter().enumerate()
        .map(|(i, ci)| ci * q[0].pow((d - i) as u32) * q[1].pow(i as u32)).sum::<i64>() % p == 0).count()
}
fn mono(d: i64, n: usize) -> Vec<Vec<i64>> { // exponent vectors of degree d in n variables
    if n == 1 { return vec![vec![d]]; }
    let mut out = vec![];
    for a in (0..=d).rev() { for m in mono(d - a, n - 1) { let mut v = vec![a]; v.extend(m); out.push(v); } }
    out
}
fn orbits(a: u32, b: u32, p: i64) -> Vec<Vec<i64>> { // naive classes of (x, y) != 0 under (l^a x, l^b y)
    let mut s = BTreeSet::new();
    for x in 0..p { for y in 0..p {
        if x == 0 && y == 0 { continue; }
        s.insert((1..p).map(|l| vec![x * l.pow(a) % p, y * l.pow(b) % p]).min().unwrap());
    } }
    s.into_iter().collect()
}
fn conic_count(p: i64) -> usize { proj_points(2, p).iter().filter(|q| (q[0] * q[2] - q[1] * q[1]) % p == 0).count() }
fn main() {
    println!("== projective space: Proj F_7[x, y] and Proj F_7[x, y, z] ==");
    let (line, plane) = (proj_points(1, P), proj_points(2, P));
    assert!(line.len() as i64 == (P * P - 1) / (P - 1) && plane.len() as i64 == (P * P * P - 1) / (P - 1));
    println!("P^1(F_7): {} points {}", line.len(), line.iter().map(|q| show(q)).collect::<Vec<_>>().join(" "));
    println!("P^2(F_7): {} points = (343 - 1)/6", plane.len());
    let ux: BTreeSet<i64> = line.iter().filter(|q| q[0] != 0).map(|q| q[1] * inv(q[0], P) % P).collect();
    let uy: BTreeSet<i64> = line.iter().filter(|q| q[1] != 0).map(|q| q[0] * inv(q[1], P) % P).collect();
    let both = line.iter().filter(|q| q[0] != 0 && q[1] != 0).count();
    assert!(ux.len() + uy.len() - both == line.len());
    println!("charts of P^1: D+(x) {} values of y/x, D+(y) {} values of x/y, overlap {}: {} + {} - {} = {}", ux.len(), uy.len(), both, ux.len(), uy.len(), both, line.len());
    let mut n = vec![0i64, line.len() as i64, 0, 0];
    for d in 2..4usize { // degree 2 and 3: irreducible means no root
        n[d] = proj_points(d, P).iter().filter(|c| roots(c, P) == 0).count() as i64;
        assert!((1..=d).filter(|e| d % e == 0).map(|e| e as i64 * n[e]).sum::<i64>() == P.pow(d as u32) + 1);
    }
    println!("closed points of Proj F_7[x, y] by degree 1, 2, 3: {} {} {}  check: 8 + 2 x 21 = {}, 8 + 3 x 112 = {}", n[1], n[2], n[3], 8 + 2 * 21, 8 + 3 * 112);
    assert!(roots(&[1, 0, 1], P) == 0);
    let sq: BTreeSet<i64> = (1..P).map(|a| a * a % P).collect();
    println!("x^2 + y^2 has {} roots: a closed point of degree 2; squares mod 7: [{}]", roots(&[1, 0, 1], P), sq.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    println!("== Proj Z[x, y]: the line over Z, one fibre per prime ==");
    for p in [2i64, 3, 5, 7, 11, 13] {
        assert!(proj_points(1, p).len() as i64 == p + 1);
        println!("fibre over {}: {} points; the rational point (3 : 5) lands on {}", p, p + 1, show(&norm(&[3 % p, 5 % p], p)));
    }
    println!("over 7: 1/3 = {}, 5 x {} = {} = {} mod 7", inv(3, P), inv(3, P), 5 * inv(3, P), 5 * inv(3, P) % P);
    println!("== the conic Proj F_7[x, y, z]/(xz - y^2) ==");
    let conic: Vec<Vec<i64>> = plane.iter().filter(|q| (q[0] * q[2] - q[1] * q[1]) % P == 0).cloned().collect();
    let par = |q: &Vec<i64>| norm(&[q[0] * q[0], q[0] * q[1], q[1] * q[1]], P);
    let image: BTreeSet<Vec<i64>> = line.iter().map(|q| par(q)).collect();
    assert!(image == conic.iter().cloned().collect::<BTreeSet<_>>() && conic.len() as i64 == P + 1);
    let back = |q: &Vec<i64>| if q[0] != 0 || q[1] != 0 { norm(&q[..2], P) } else { norm(&q[1..], P) };
    assert!(line.iter().all(|q| back(&par(q)) == *q));
    println!("points: {} -> {}", conic.iter().map(|q| show(q)).collect::<Vec<_>>().join(" "), conic.len());
    println!("from (s : t): {} ...", line[..3].iter().map(|q| format!("{}->{}", show(q), show(&par(q)))).collect::<Vec<_>>().join(" "));
    let mut cone = 0usize;
    for x in 0..P { for y in 0..P { for z in 0..P { if (x * z - y * y) % P == 0 { cone += 1; } } } }
    assert!(cone == 1 + (P as usize - 1) * conic.len()); // lines through the cone's vertex
    println!("affine cone xz = y^2 in F_7^3: {} points = 1 + {}; ({} - 1)/6 = {} lines", cone, (P as usize - 1) * conic.len(), cone, (cone - 1) / (P as usize - 1));
    let pairs = |f: &dyn Fn(i64, i64) -> bool| -> Vec<(i64, i64)> { (0..P).flat_map(|a| (0..P).map(move |b| (a, b))).filter(|&(a, b)| f(a, b)).collect() };
    let cx = pairs(&|u, v| (v - u * u) % P == 0); // S_(x): v = u^2
    let cz = pairs(&|a, b| (a - b * b) % P == 0); // S_(z): a = b^2
    let cy = pairs(&|c, e| (c * e - 1) % P == 0); // S_(y): ce = 1
    let xz: Vec<&Vec<i64>> = conic.iter().filter(|q| q[0] != 0 && q[2] != 0).collect();
    assert!(conic.iter().all(|q| q[0] != 0 || q[2] != 0) && cx.len() + cz.len() - xz.len() == conic.len() && conic.len() == cx.len() + 1);
    assert!(xz.len() == cy.len() && xz.iter().all(|q| q[1] * inv(q[0], P) % P * q[1] % P * inv(q[2], P) % P == 1));
    println!("charts: Spec S_(x) {} points, Spec S_(z) {}, overlap {} (= Spec S_(y), {}): {} + {} - {} = {}", cx.len(), cz.len(), xz.len(), cy.len(), cx.len(), cz.len(), xz.len(), conic.len());
    println!("on the overlap (y/x)(y/z) = 1 at all {} points; chart x = 1 holds {}", xz.len(), cx.iter().map(|(u, v)| format!("({}, {})", u, v)).collect::<Vec<_>>().join(" "));
    let mut hf = vec![];
    for d in 0..7i64 {
        let ms = mono(d, 3);
        let idx = |m: Vec<i64>| ms.iter().position(|x| *x == m).unwrap();
        let mut rows = vec![];
        for m in if d >= 2 { mono(d - 2, 3) } else { vec![] } { // the multiples of xz - y^2 in degree d
            let mut row = vec![0i64; ms.len()];
            row[idx(vec![m[0] + 1, m[1], m[2] + 1])] += 1;
            row[idx(vec![m[0], m[1] + 2, m[2]])] -= 1;
            rows.push(row);
        }
        let pic = ms.iter().map(|m| (2 * m[0] + m[1], m[1] + 2 * m[2])).collect::<BTreeSet<_>>().len();
        assert!(ms.len() - rank(&rows, P) == pic && pic as i64 == 2 * d + 1);
        hf.push(pic);
    }
    println!("dim S_d, d = 0..6: {}  = 2d + 1 = dim k[s, t] in degree 2d; top coefficient 2, the degree", hf.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(" "));
    println!("dim S_3 = {} - {} = {}", mono(3, 3).len(), mono(1, 3).len(), hf[3]);
    println!("== the weighted line Proj F_7[x, y], deg x = 1, deg y = 2 ==");
    let w: Vec<i64> = (0..9i64).map(|d| (0..=d).flat_map(|i| (0..=d).map(move |j| (i, j))).filter(|&(i, j)| i + 2 * j == d).count() as i64).collect();
    assert!(w == (0..9i64).map(|d| d / 2 + 1).collect::<Vec<_>>());
    println!("dim S_d, d = 0..8: {}  even degrees 2d: {} = d + 1, as for P^1", w.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(" "), (0..5).map(|d| w[2 * d].to_string()).collect::<Vec<_>>().join(" "));
    let orb = orbits(1, 2, P);
    let pts: BTreeSet<Vec<i64>> = orb.iter().map(|q| norm(&[q[0] * q[0], q[1]], P)).collect(); // (x : y) -> (x^2 : y)
    let wx: BTreeSet<i64> = orb.iter().filter(|q| q[0] != 0).map(|q| q[1] * inv(q[0] * q[0] % P, P) % P).collect();
    let wy: BTreeSet<i64> = orb.iter().filter(|q| q[1] != 0).map(|q| q[0] * q[0] % P * inv(q[1], P) % P).collect();
    let wxy = pts.iter().filter(|q| q[0] != 0 && q[1] != 0).count();
    assert!(wx.len() + wy.len() - wxy == pts.len() && pts.len() == line.len() && orb.len() == pts.len() + 1);
    let merged: Vec<String> = orb.iter().filter(|q| q[0] == 0).map(|q| show(q)).collect();
    println!("naive orbits: {}; scheme points: {} = {} values of y/x^2 + {} of x^2/y - {} on the overlap", orb.len(), pts.len(), wx.len(), wy.len(), wxy);
    println!("orbits {} both have x^2/y = 0: one point of Proj", merged.join(" and "));
    println!("== what breaks ==");
    println!("Spec instead of Proj, keeping the vertex: {} points, not {}", cone, conic.len());
    let whole = (1..P).count() * P as usize;
    println!("whole localisation S_x = F_7[x, y, 1/x], not its degree-0 part: {} points, not {}", whole, ux.len());
    println!("weighted points as naive orbits: {}, not {}", orb.len(), pts.len());
    println!("three different rings, one P^1: dim S_1 = {}, {}, {}; every one has {} points over F_7", mono(1, 2).len(), hf[1], w[1], line.len());
    println!("== try changing ==");
    let cubes: BTreeSet<i64> = (1..P).map(|a| a * a * a % P).collect();
    println!("orbits for weights 1, 3 over F_7: {}, cubes mod 7: [{}]; conic over F_11: {} points; dim S_10 of the conic: {}", orbits(1, 3, P).len(), cubes.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "), conic_count(11), mono(10, 3).len() - mono(8, 3).len());
    println!("figure, chart x = 1 points (u, v) at px = 60 + 40u, py = 300 - 40v: {} ; (0 : 0 : 1) at infinity", cx.iter().map(|(u, v)| format!("({}, {})", 60 + 40 * u, 300 - 40 * v)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
