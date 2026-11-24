// Desargues and Pappus -- the same check as the Python, in Rust, std only.
// A point (x, y) is the whole-number triple (x, y, 1) or any nonzero multiple.
// The line through two points and the meet of two lines are cross products;
// three points share a line, or three lines a point, when the 3 x 3 determinant
// of their triples is 0.  All arithmetic is exact, in whole numbers (i128).
type V3 = [i128; 3];
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn det(a: V3, b: V3, c: V3) -> i128 { let x = cross(a, b); x[0] * c[0] + x[1] * c[1] + x[2] * c[2] }
fn meet(p: V3, q: V3, r: V3, s: V3) -> V3 { cross(cross(p, q), cross(r, s)) } // line pq meets line rs
fn sub(a: V3, b: V3) -> V3 { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn gcd(a: i128, b: i128) -> i128 { if b != 0 { gcd(b, a % b) } else { a.abs() } }
fn fr(n: i128, d: i128) -> String { let g = gcd(n, d) * d.signum(); if d == g { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
fn tri(p: V3) -> String { format!("({}, {}, {})", p[0], p[1], p[2]) }
fn pt(p: V3) -> String { if p[2] != 0 { format!("({}, {})", fr(p[0], p[2]), fr(p[1], p[2])) } else { tri(p) } }
fn sl(u: V3, v: V3) -> String { fr(v[1] * u[2] - u[1] * v[2], v[0] * u[2] - u[0] * v[2]) }
fn slopes(m: [V3; 3]) -> String { format!("{} {}", sl(m[0], m[1]), sl(m[1], m[2])) }
fn sides(a: V3, b: V3, c: V3, a2: V3, b2: V3, c2: V3) -> [V3; 3] { [meet(a, b, a2, b2), meet(b, c, b2, c2), meet(c, a, c2, a2)] }
fn pappus(d: [V3; 3], t: [V3; 3]) -> [V3; 3] { [meet(d[0], t[1], d[1], t[0]), meet(d[0], t[2], d[2], t[0]), meet(d[1], t[2], d[2], t[1])] }
// a 64-bit congruential generator, giving whole numbers -9 to 9
fn rnd(s: &mut u64) -> i128 { *s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407); ((*s >> 33) % 19) as i128 - 9 }
fn on(s: &mut u64, p: V3, q: V3) -> V3 { let k = match rnd(s) { 0 => 10, k => k }; [k * p[0] + q[0], k * p[1] + q[1], k * p[2] + q[2]] }
fn figs(ps: &[V3], x0: f64, y0: f64) -> String { ps.iter().map(|p| format!("({:.1}, {:.1})",
    x0 + 40.0 * p[0] as f64 / p[2] as f64, y0 - 40.0 * p[1] as f64 / p[2] as f64)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (o, a, b, c, a2, b2, c2): (V3, V3, V3, V3, V3, V3, V3) = ([0, 0, 1], [1, 0, 1], [0, 1, 1], [1, 2, 1], [2, 0, 1], [0, 3, 1], [3, 6, 2]);
    println!("triangles A B C = {} {} {}  A' B' C' = {} {} {}  centre O {}", pt(a), pt(b), pt(c), pt(a2), pt(b2), pt(c2), pt(o));
    let [p, q, r] = sides(a, b, c, a2, b2, c2);
    println!("road 1, meets of matching sides: P {} Q {} R {} | det {} | slopes {}", pt(p), pt(q), pt(r), det(p, q, r), slopes([p, q, r]));
    let pairs = [(a, a2), (b, b2), (c, c2)];
    let sc: Vec<(i128, i128, i128)> = pairs.iter().map(|&(u, u2)| { // s, s2, k with s*u - s2*u2 = k*O
        let d = cross(u, u2); let i = if d[0] != 0 { 0 } else if d[1] != 0 { 1 } else { 2 }; (cross(o, u2)[i], cross(o, u)[i], d[i]) }).collect();
    let reps: Vec<V3> = (0..6).map(|j| { let (i, m) = (j / 2, sc[0].2 * sc[1].2 * sc[2].2 / sc[j / 2].2);
        if j % 2 == 0 { pairs[i].0.map(|x| sc[i].0 * m * x) } else { pairs[i].1.map(|x| sc[i].1 * m * x) } }).collect();
    let g = reps.iter().flatten().fold(0, |g, &x| gcd(g, x));
    let [ra, ra2, rb, rb2, rc, rc2]: [V3; 6] = std::array::from_fn(|i| reps[i].map(|x| x / g));
    println!("road 2, rescaled: a {} a' {} b {} b' {} c {} c' {} | each pair differs by {}",
             tri(ra), tri(ra2), tri(rb), tri(rb2), tri(rc), tri(rc2), tri(sub(ra, ra2)));
    let road2 = [sub(ra, rb), sub(rb, rc), sub(rc, ra)];
    println!("road 2: a - b = {} -> {}  b - c = {} -> {}  c - a = {} -> {}",
             tri(road2[0]), pt(road2[0]), tri(road2[1]), pt(road2[1]), tri(road2[2]), pt(road2[2]));
    let dual = sides(cross(b, c), cross(c, a), cross(a, b), cross(b2, c2), cross(c2, a2), cross(a2, b2)); // lines in, lines out
    println!("dual, the sides fed in as points: lines {} {} {} | det {} | common point {}",
             tri(dual[0]), tri(dual[1]), tri(dual[2]), det(dual[0], dual[1], dual[2]), pt(cross(dual[0], dual[1])));
    let (d, t): ([V3; 3], [V3; 3]) = ([[0, 0, 1], [1, 0, 1], [3, 0, 1]], [[0, 2, 1], [2, 2, 1], [5, 2, 1]]);
    let m = pappus(d, t);
    println!("Pappus, x = 0 1 3 on y = 0, x = 0 2 5 on y = 2: M12 {} M13 {} M23 {} | det {} | slopes {}",
             pt(m[0]), pt(m[1]), pt(m[2]), det(m[0], m[1], m[2]), slopes(m));
    let v: [V3; 3] = std::array::from_fn(|i| [d[i][0] * t[i][0], 2 * d[i][0], d[i][0] + t[i][0]]); // V_i = (d t, h d, d + t)
    let diffs = [sub(v[1], v[0]), sub(v[2], v[0]), sub(v[2], v[1])];
    println!("Pappus road 2: V = {} {} {} | V2 - V1, V3 - V1, V3 - V2 -> {} {} {}",
             tri(v[0]), tri(v[1]), tri(v[2]), pt(diffs[0]), pt(diffs[1]), pt(diffs[2]));
    let (mut s, mut n) = (2026u64, [0i128; 5]); // random state; genuine cases, off the line; nudged, off; nudged, flat ABC
    for _ in 0..2000 {
        let [o, x, y, z, u]: [V3; 5] = std::array::from_fn(|_| [rnd(&mut s), rnd(&mut s), rnd(&mut s)]);
        let (e1, e2, e3) = (on(&mut s, o, x), on(&mut s, o, y), on(&mut s, o, z));
        let dd: [V3; 3] = std::array::from_fn(|_| on(&mut s, u, o));
        let tt: [V3; 3] = std::array::from_fn(|_| on(&mut s, x, y));
        let (f1, f2, f3) = (on(&mut s, o, x), on(&mut s, o, y), on(&mut s, o, z));
        for (i, pqr) in [sides(x, y, z, e1, e2, e3), pappus(dd, tt), sides(x, y, z, f1, f2, sub(f3, cross(o, z)))].iter().enumerate() {
            if !pqr.contains(&[0, 0, 0]) { n[i / 2 * 2] += 1; n[i / 2 * 2 + 1] += (det(pqr[0], pqr[1], pqr[2]) != 0) as i128; n[4] += (i == 2 && det(x, y, z) == 0) as i128; }
        }
    }
    println!("road 3, 2000 random cases of each theorem: {} with three genuine meets, {} of them off one line; nudge C' off its ray: {} of {} off the line, {} with a flat triangle ABC",
             n[0], n[1], n[3], n[2], n[4]);
    let (w, nn, k) = (sides(a, b, c, c2, a2, b2), sides(a, b, c, a2, b2, [3, 5, 2]), pappus([d[0], d[1], [6, 1, 2]], t));
    println!("mistakes: AB with C'A', BC with A'B', CA with B'C' -> slopes {} | C' = (3/2, 5/2) -> slopes {}", slopes(w), slopes(nn));
    println!("mistakes: A - B unscaled -> {} | D3 = (3, 1/2) -> slopes {}", tri(sub(a, b)), slopes(k));
    println!("figure, Desargues 40 per unit: {}", figs(&[o, a, b, c, a2, b2, c2, p, q, r], 60.0, 280.0));
    println!("figure, Pappus 40 per unit: {}", figs(&[d[0], d[1], d[2], t[0], t[1], t[2], m[0], m[1], m[2]], 330.0, 260.0));
    assert!(det(p, q, r) == 0 && [pt(p), pt(q), pt(r)] == ["(4, -3)", "(2, 3)", "(1, 6)"]);
    assert!(sub(ra, ra2) == sub(rb, rb2) && sub(rb, rb2) == sub(rc, rc2));
    assert!(road2.iter().zip([p, q, r]).all(|(&x, y)| cross(x, y) == [0, 0, 0]));
    assert!(det(dual[0], dual[1], dual[2]) == 0 && cross(dual[0], dual[1])[..2] == [0, 0] && det(m[0], m[1], m[2]) == 0);
    assert!(diffs.iter().zip(m).all(|(&x, y)| cross(x, y) == [0, 0, 0]));
    assert!(n[1] == 0 && n[0] > 3000 && n[3] + n[4] == n[2]);
    println!("ALL CHECKS PASS");
}
