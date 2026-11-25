// The 27 lines on a cubic surface -- the same check as the Python, in Rust.  No crates.
// Road 1: the Fermat cubic x^3 + y^3 + z^3 + w^3 = 0 and its 27 lines, exact in Z[r] (r^2 = -1 - r).
// Road 2: every line of P^3 over F_p, tested by brute force.
// Road 3: the plane blown up at six points, where lines are the classes D with D.D = -1 and K.D = -1.
// Road 4: name six skew Fermat lines E1..E6, read off every other line's class, compare all meetings.
type Z = (i64, i64);                     // a0 + a1 r
type Line = (Vec<Z>, Vec<Z>, bool);      // two points on the line, and "real coefficients"
fn mul(a: Z, b: Z) -> Z { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0 - a.1 * b.1) }
fn det(m: &[Vec<Z>]) -> Z {              // determinant in Z[r], expanding along row 0
    if m.len() == 1 { return m[0][0] } let mut total = (0, 0);
    for j in 0..m.len() {
        let minor: Vec<Vec<Z>> = m[1..].iter()
            .map(|row| row.iter().enumerate().filter(|(c, _)| *c != j).map(|(_, &x)| x).collect()).collect();
        let (t, sign) = (mul(m[0][j], det(&minor)), 1 - 2 * (j as i64 % 2));
        total = (total.0 + sign * t.0, total.1 + sign * t.1);
    }
    total
}
fn on_surface(p: &[Z], q: &[Z]) -> bool { // F(sP + tQ) = 0 at four points: a cubic in s, t that is 0
    [(1, 0), (0, 1), (1, 1), (1, -1)].iter().all(|&(s, t)| {
        (0..4).map(|c| { let v = (s * p[c].0 + t * q[c].0, s * p[c].1 + t * q[c].1); mul(mul(v, v), v) })
            .fold((0, 0), |a, b| (a.0 + b.0, a.1 + b.1)) == (0, 0)
    })
}
fn graph_stats(adj: &[Vec<bool>]) -> (Vec<i64>, i64, Vec<i64>, Vec<i64>) {
    let n = adj.len();
    let (mut degs, mut tri, mut lam, mut mu): (Vec<i64>, i64, Vec<i64>, Vec<i64>) =
        ((0..n).map(|u| adj[u].iter().filter(|&&x| x).count() as i64).collect(), 0, Vec::new(), Vec::new());
    for u in 0..n {
        for v in u + 1..n {
            for w in v + 1..n { if adj[u][v] && adj[v][w] && adj[u][w] { tri += 1 } }
            let c = (0..n).filter(|&w| adj[u][w] && adj[v][w]).count() as i64; if adj[u][v] { lam.push(c) } else { mu.push(c) }
        }
    }
    for s in [&mut degs, &mut lam, &mut mu] { s.sort(); s.dedup(); }
    (degs, tri, lam, mu)
}
fn rref(rows: Vec<Vec<i64>>, p: i64) -> Vec<Vec<i64>> { // reduced row echelon form mod p
    let mut rows: Vec<Vec<i64>> = rows.iter().map(|r| r.iter().map(|x| x.rem_euclid(p)).collect()).collect();
    let mut out: Vec<Vec<i64>> = Vec::new();
    for c in 0..4 {
        if let Some(k) = rows.iter().position(|r| r[c] != 0) {
            let piv = rows.remove(k);
            let inv = (1..p).find(|x| piv[c] * x % p == 1).unwrap();
            let piv: Vec<i64> = piv.iter().map(|x| x * inv % p).collect();
            let clear = |r: &Vec<i64>| -> Vec<i64> { r.iter().zip(&piv).map(|(x, y)| (x - r[c] * y).rem_euclid(p)).collect() };
            rows = rows.iter().map(clear).collect(); out = out.iter().map(clear).collect(); out.push(piv);
        }
    }
    out
}
fn lines_on(p: i64, k: [i64; 4]) -> (i64, Vec<Vec<Vec<i64>>>) { // every line of P^3 over F_p
    let (mut found, mut total) = (Vec::new(), 0);
    for i in 0..4 {
        for j in i + 1..4 {
            let fr1: Vec<usize> = (i + 1..4).filter(|&c| c != j).collect();
            let fr2: Vec<usize> = (j + 1..4).collect();
            for n1 in 0..p.pow(fr1.len() as u32) {
                for n2 in 0..p.pow(fr2.len() as u32) {
                    let r1: Vec<i64> = (0..4).map(|c| (c == i) as i64 + fr1.iter().position(|&x| x == c).map_or(0, |t| n1 / p.pow(t as u32) % p)).collect();
                    let r2: Vec<i64> = (0..4).map(|c| (c == j) as i64 + fr2.iter().position(|&x| x == c).map_or(0, |t| n2 / p.pow(t as u32) % p)).collect();
                    total += 1;
                    if [(1, 0), (0, 1), (1, 1), (1, 2)].iter().all(|&(s, t)|
                        (0..4).map(|c| { let v = s * r1[c] + t * r2[c]; k[c] * v * v * v }).sum::<i64>() % p == 0) { found.push(vec![r1, r2]) }
                }
            }
        }
    }
    (total, found)
}
fn go(n: usize, a: i64, pre: &mut Vec<i64>, s: i64, q: i64, out: &mut Vec<Vec<i64>>) {
    let k = (n - pre.len()) as i64;      // s, q: sum and sum of squares the remaining b's must make
    if k == 0 || s * s > k * q {         // Cauchy-Schwarz: s^2 <= k q, or the rest cannot fit
        if k == 0 && s == 0 && q == 0 { let mut d = vec![a]; d.extend(pre.iter()); out.push(d) }
        return;
    }
    let mut m = 0;
    while (m + 1) * (m + 1) <= q { m += 1 }
    for b in -m..=m { pre.push(b); go(n, a, pre, s - b, q - b * b, out); pre.pop(); }
}
fn classes(n: usize) -> Vec<Vec<i64>> {  // every aH - b1E1 - ... - bnEn with D.D = -1 and K.D = -1
    let mut out = Vec::new();            // Cauchy-Schwarz bounds a to 0, 1, 2; the range is far wider
    for a in -12..13 { go(n, a, &mut Vec::new(), 3 * a - 1, a * a + 1, &mut out) } out
}
fn dot(d: &[i64], f: &[i64]) -> i64 { d[0] * f[0] - (1..d.len()).map(|t| d[t] * f[t]).sum::<i64>() }
fn skew(adj: &[Vec<bool>], ch: Vec<usize>) -> Option<Vec<usize>> { // six pairwise skew lines, by backtracking
    if ch.len() == 6 { return Some(ch) }
    (ch.last().map_or(0, |&x| x + 1)..27).filter(|&u| ch.iter().all(|&v| !adj[u][v])).find_map(|u| { let mut c = ch.clone(); c.push(u); skew(adj, c) })
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn count(p: i64, k: [i64; 4]) -> usize { lines_on(p, k).1.len() }
fn main() {
    let roots: [Z; 3] = [(1, 0), (0, 1), (-1, -1)];
    let mut fermat: Vec<Line> = Vec::new();
    for ((i, j), (k, l)) in [((0, 1), (2, 3)), ((0, 2), (1, 3)), ((0, 3), (1, 2))] {
        for a in roots { for b in roots { let (mut p, mut q) = (vec![(0, 0); 4], vec![(0, 0); 4]);
            p[i] = (-a.0, -a.1); p[j] = (1, 0); q[k] = (-b.0, -b.1); q[l] = (1, 0);
            fermat.push((p, q, a == (1, 0) && b == (1, 0))); } } }
    let (mut e, mut l, mut c, mut names): (Vec<Vec<i64>>, Vec<Vec<i64>>, Vec<Vec<i64>>, Vec<String>) = (vec![], vec![], vec![], vec![]);
    for i in 0..6 { let mut d = vec![0; 7]; d[i + 1] = -1; e.push(d); names.push(format!("E{}", i + 1)) }
    for i in 0..6 { for j in i + 1..6 { let mut d = vec![1, 0, 0, 0, 0, 0, 0]; d[i + 1] = 1; d[j + 1] = 1; l.push(d); names.push(format!("L{}{}", i + 1, j + 1)) } }
    for i in 0..6 { let mut d = vec![2, 1, 1, 1, 1, 1, 1]; d[i + 1] = 0; c.push(d); names.push(format!("C{}", i + 1)) }
    let typed: Vec<Vec<i64>> = e.iter().chain(&l).chain(&c).cloned().collect();
    let (kk, h, found6) = (vec![-3, -1, -1, -1, -1, -1, -1], vec![3, 1, 1, 1, 1, 1, 1], classes(6));
    println!("Road 1: Fermat cubic x^3 + y^3 + z^3 + w^3 = 0, exact, r^2 + r + 1 = 0");
    println!("lines x = -a y, z = -b w and the 2 other pairings, a, b in 1, r, r^2: {}", fermat.len());
    let on1 = fermat.iter().filter(|f| on_surface(&f.0, &f.1)).count();
    println!("lines put back in the equation that vanish identically: {}", on1);
    println!("lines with real coefficients (a = b = 1): {}", fermat.iter().filter(|f| f.2).count());
    let adj1: Vec<Vec<bool>> = (0..27).map(|u| (0..27).map(|v| u != v && // meet: four spanning points dependent
        det(&[fermat[u].0.clone(), fermat[u].1.clone(), fermat[v].0.clone(), fermat[v].1.clone()]) == (0, 0)).collect()).collect();
    let g1 = graph_stats(&adj1);
    println!("x = -y, z = -w meets {} lines of its own pairing and {} of the other two", (0..9).filter(|&v| adj1[0][v]).count(), (9..27).filter(|&v| adj1[0][v]).count());
    println!("meeting graph, Fermat lines: degree {:?}, triangles {}, common neighbours {:?} if meeting, {:?} if not", g1.0, g1.1, g1.2, g1.3);
    let (total7, mut on7) = lines_on(7, [1, 1, 1, 1]);
    let mut red: Vec<Vec<Vec<i64>>> = fermat.iter().map(|f| rref(vec![f.0.iter().map(|z| z.0 + 2 * z.1).collect(),
                                                                f.1.iter().map(|z| z.0 + 2 * z.1).collect()], 7)).collect();
    red.sort(); red.dedup(); on7.sort();
    println!("Road 2: all {} lines of P^3 over F_7 tested, on the Fermat cubic: {}", total7, on7.len());
    println!("the 27 exact lines reduced mod 7 (r -> 2) are exactly these: {}", yn(red == on7));
    println!("Road 3: plane blown up at six points, classes D = aH - b1E1 - ... - b6E6");
    let mut avals: Vec<i64> = found6.iter().map(|d| d[0]).collect(); avals.sort(); avals.dedup();
    println!("search for D.D = -1 and K.D = -1, K = -3H + E1 + ... + E6: {} classes, a in {:?}", found6.len(), avals);
    println!("typed list: E_i {}, L_ij = H - Ei - Ej {}, C_i = 2H - (E1 + ... + E6) + Ei {}: {}", e.len(), l.len(), c.len(), typed.len());
    let (mut s1, mut s2) = (found6.clone(), typed.clone()); s1.sort(); s2.sort();
    println!("search and typed list agree: {}", yn(s1 == s2));
    let mut hd: Vec<i64> = typed.iter().map(|d| dot(&h, d)).collect(); hd.sort(); hd.dedup();
    println!("K.K = {}, h = -K = 3H - E1 - ... - E6, h.h = {}, h.D for the 27: {:?}; plane cubics: {} coefficients, minus 6 points = {} = coordinates of P^3",
             dot(&kk, &kk), dot(&h, &h), hd, 4 * 5 / 2, 10 - 6);
    for name in ["E1", "L12", "C1"] {
        let u = &typed[names.iter().position(|x| x == name).unwrap()];
        let m: Vec<&str> = (0..27).filter(|&t| dot(u, &typed[t]) == 1).map(|t| names[t].as_str()).collect();
        println!("{} meets: {}", name, m.join(" "));
    }
    let sixer = skew(&adj1, vec![]).unwrap(); // E_i is sixer[i]; meeting two of them: a = 1, meeting five: a = 2
    let lab: Vec<Vec<i64>> = (0..27).map(|u| match sixer.iter().position(|&v| v == u) {
        Some(i) => e[i].clone(),
        None => { let m: Vec<i64> = sixer.iter().map(|&v| adj1[u][v] as i64).collect(); [vec![m.iter().sum::<i64>() / 2], m].concat() } }).collect();
    let agree = (0..27).all(|u| (u + 1..27).all(|v| dot(&lab[u], &lab[v]) == adj1[u][v] as i64));
    let mut ms: Vec<usize> = (0..27).filter(|u| !sixer.contains(u)).map(|u| sixer.iter().filter(|&&v| adj1[u][v]).count()).collect();
    ms.sort(); ms.dedup();
    println!("Road 4: skew Fermat lines {:?} named E1..E6; the other 21 meet {:?} of them", sixer, ms);
    let mut sl = lab.clone(); sl.sort();
    println!("classes read off = the 27 of road 3: {}; all 351 pairs meet as the classes say: {}", yn(sl == s2), yn(agree));
    let six = (0..6).all(|i| (0..6).all(|j| (dot(&e[i], &c[j]) == (i != j) as i64)
        && (i == j || (dot(&e[i], &e[j]) == 0 && dot(&c[i], &c[j]) == 0))));
    println!("double six: Ei meets Cj exactly when i != j, E's and C's disjoint among themselves: {}", yn(six));
    let others: Vec<usize> = (3..9).map(|n| classes(n).len()).collect();
    println!("other blow-ups, classes with D.D = -1, K.D = -1 for n = 3..8 points: {:?}", others);
    let pts: Vec<(i64, i64)> = vec![(5, 0), (3, 4), (-4, 3), (-4, -3), (0, -5), (1, 1)];
    let mut col = 0;
    for x in 0..6 { for y in x + 1..6 { for z in y + 1..6 { let (a, b, cc) = (pts[x], pts[y], pts[z]);
        if (b.0 - a.0) * (cc.1 - a.1) == (b.1 - a.1) * (cc.0 - a.0) { col += 1 } } } }
    println!("figure, points {:?}, collinear triples {}, p6 on the circle x^2 + y^2 = 25: {}", pts, col, yn(pts[5].0 * pts[5].0 + pts[5].1 * pts[5].1 == 25));
    let line3 = vec![1, 1, 1, 1, 0, 0, 0];
    let split: Vec<&str> = (0..27).filter(|&t| dot(&typed[t], &line3) < 0).map(|t| names[t].as_str()).collect();
    println!("p1, p2, p3 on a line: H - E1 - E2 - E3 has D.D = {}, K.D = {}; split off {}, left {}",
             dot(&line3, &line3), dot(&kk, &line3), split.join(" "), 27 - split.len());
    println!("mistake 1, only exceptional curves and lines through two points: {}", e.len() + l.len());
    println!("mistake 2, lines over F_5, where 1 is the only cube root of 1: {}", count(5, [1, 1, 1, 1]));
    println!("mistake 3, singular cone x^3 + y^3 + z^3 = 0: lines over F_7 {}, over F_31 {}", count(7, [1, 1, 1, 0]), count(31, [1, 1, 1, 0]));
    println!("try: Fermat lines over F_11 {}, over F_13 {}", count(11, [1, 1, 1, 1]), count(13, [1, 1, 1, 1]));
    assert!(fermat.len() == 27 && on1 == 27);                       // road 1 substitutes
    assert!(on7.len() == 27 && red == on7);                         // road 2 = road 1 mod 7
    assert!(s1 == s2);                                              // road 3: search = list
    assert!(sl == s2 && agree);                                     // road 4: Fermat = blow-up
    assert!(g1 == (vec![10], 45, vec![1], vec![5]));                // each line meets 10
    assert!(others == vec![6, 10, 16, 27, 56, 240]);                // known del Pezzo counts
    println!("ALL CHECKS PASS");
}
