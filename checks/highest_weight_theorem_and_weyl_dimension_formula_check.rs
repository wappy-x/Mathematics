// Highest weights and Weyl's dimension formula -- the same check as the Python,
// in Rust.  No crates.  The group is SU(3); a highest weight is a pair (a, b) of
// whole numbers.  Each size is found four ways: Weyl's product, a count of
// traceless tensors, building the representation from its top vector by
// lowering operators, and Weyl's character formula as a ratio of determinants.
use std::collections::BTreeMap;
type Poly = BTreeMap<[i64; 6], i64>; // exponents of x1 x2 x3 y1 y2 y3 -> coefficient
type Char = BTreeMap<(i64, i64), i64>; // weight in (a, b) coordinates -> multiplicity

fn weyl(a: f64, b: f64) -> f64 { (a + 1.0) * (b + 1.0) * (a + b + 2.0) / 2.0 }
fn weyl_no_rho(a: f64, b: f64) -> f64 { a * b * (a + b) / 2.0 }
fn comb2(n: i64) -> i64 { n * (n - 1) / 2 }
fn tensors(a: i64, b: i64) -> i64 { comb2(a + 2) * comb2(b + 2) - comb2(a + 1) * comb2(b + 1) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn e_op(i: usize, j: usize, poly: &Poly) -> Poly { // E_ij = x_i d/dx_j - y_j d/dy_i
    let mut out = Poly::new();
    for (m, &c) in poly {
        for (src, dst, sign) in [(j, i, 1), (3 + i, 3 + j, -1)] {
            if m[src] > 0 {
                let mut n = *m;
                n[src] -= 1;
                n[dst] += 1;
                *out.entry(n).or_insert(0) += sign * c * m[src];
            }
        }
    }
    out.retain(|_, v| *v != 0);
    out
}

// span of everything lowering reaches from the top; returns weight -> multiplicity
fn build(a: i64, b: i64) -> BTreeMap<[i64; 3], i64> {
    let mut rows: BTreeMap<[i64; 3], Vec<([i64; 6], Poly)>> = BTreeMap::new();
    let mut queue: Vec<Poly> = Vec::new();
    let insert = |mut w: Poly, rows: &mut BTreeMap<[i64; 3], Vec<([i64; 6], Poly)>>, queue: &mut Vec<Poly>| {
        let m = *w.keys().next().unwrap();
        let wt = [m[0] - m[3], m[1] - m[4], m[2] - m[5]];
        for (piv, r) in rows.get(&wt).map(|v| v.as_slice()).unwrap_or(&[]) {
            if let Some(&c) = w.get(piv) {
                let d = r[piv];
                let mut nw = Poly::new();
                for (k, v) in &w { *nw.entry(*k).or_insert(0) += d * v }
                for (k, v) in r { *nw.entry(*k).or_insert(0) -= c * v }
                nw.retain(|_, v| *v != 0);
                if nw.is_empty() { return }
                w = nw;
            }
        }
        let g = w.values().fold(0, |g, &v| gcd(g, v));
        for v in w.values_mut() { *v /= g }
        let piv = *w.keys().next_back().unwrap();
        rows.entry(wt).or_default().push((piv, w.clone()));
        queue.push(w);
    };
    let mut top = Poly::new();
    top.insert([a, 0, 0, 0, 0, b], 1); // x1^a y3^b: the highest weight vector
    assert!(e_op(0, 1, &top).is_empty() && e_op(1, 2, &top).is_empty());
    insert(top, &mut rows, &mut queue);
    while let Some(p) = queue.pop() {
        for (i, j) in [(1, 0), (2, 1)] { // the two lowering operators
            let q = e_op(i, j, &p);
            if !q.is_empty() { insert(q, &mut rows, &mut queue) }
        }
    }
    rows.into_iter().map(|(k, v)| (k, v.len() as i64)).collect()
}

fn det3(m: [[i64; 3]; 3]) -> i64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}

fn weyl_character(a: i64, b: i64, z: [i64; 3]) -> i64 { // alternating sum over alternating sum
    let lam = [a + b, b, 0];
    let (mut num, mut den) = ([[0i64; 3]; 3], [[0i64; 3]; 3]);
    for i in 0..3 {
        for j in 0..3 {
            num[i][j] = z[i].pow((lam[j] + 2 - j as i64) as u32);
            den[i][j] = z[i].pow((2 - j) as u32);
        }
    }
    let (n, d) = (det3(num), det3(den));
    assert!(n % d == 0);
    n / d
}

fn built_character(ch: &BTreeMap<[i64; 3], i64>, b: i64, z: [i64; 3]) -> i64 {
    ch.iter().map(|(m, n)| n * (0..3).map(|k| z[k].pow((m[k] + b) as u32)).product::<i64>()).sum()
}

fn by_labels(ch: &BTreeMap<[i64; 3], i64>) -> Char {
    let mut out = Char::new();
    for (m, n) in ch { *out.entry((m[0] - m[1], m[1] - m[2])).or_insert(0) += n }
    out
}

fn times(c1: &Char, c2: &Char) -> Char { // character of a tensor product
    let mut out = Char::new();
    for (w1, n1) in c1 {
        for (w2, n2) in c2 { *out.entry((w1.0 + w2.0, w1.1 + w2.1)).or_insert(0) += n1 * n2 }
    }
    out
}

fn split(ch: &Char) -> Vec<(i64, i64)> { // peel off highest weights, one at a time
    let (mut ch, mut parts) = (ch.clone(), Vec::new());
    while ch.values().any(|&n| n != 0) {
        let top = *ch.iter().filter(|(_, &n)| n != 0).map(|(w, _)| w)
            .max_by_key(|w| (w.0 + w.1, w.0)).unwrap();
        parts.push(top);
        for (w, n) in by_labels(&build(top.0, top.1)) { *ch.entry(w).or_insert(0) -= n }
    }
    parts
}

fn show(parts: &[(i64, i64)]) -> String {
    let s: Vec<String> = parts.iter().map(|p| format!("({}, {})", p.0, p.1)).collect();
    format!("[{}]", s.join(", "))
}

fn main() {
    let z = [1, 2, 3];
    println!("(a, b)  Weyl  tensors  built  character at z = (1, 2, 3): built, Weyl");
    let mut squares = 0;
    for s in 0..4 {
        for a in (0..=s).rev() {
            let b = s - a;
            let ch = build(a, b);
            let d: i64 = ch.values().sum();
            let (cb, cw) = (built_character(&ch, b, z), weyl_character(a, b, z));
            let w = weyl(a as f64, b as f64);
            println!("({}, {})  {:4}  {:7}  {:5}  {:6}, {}", a, b, w as i64, tensors(a, b), d, cb, cw);
            assert!(w == tensors(a, b) as f64 && tensors(a, b) == d && cb == cw);
            squares += d * d;
        }
    }
    for (a, b) in [(1, 0), (1, 1), (3, 0)] {
        println!("by hand, ({}, {}): Weyl {} x {} x {} / 2 = {}; tensors {} - {}", a, b, a + 1, b + 1, a + b + 2,
                 weyl(a as f64, b as f64) as i64, comb2(a + 2) * comb2(b + 2), comb2(a + 1) * comb2(b + 1));
    }
    println!("matrix entries of these ten, the sum of size squared: {}", squares);
    let adj = by_labels(&build(1, 1));
    let adj_states: i64 = adj.values().sum::<i64>();
    println!("adjoint (1, 1): {} distinct weights, {} states, weight (0, 0) held {} times",
             adj.len(), adj_states, adj[&(0, 0)]);
    let (q, qb) = (by_labels(&build(1, 0)), by_labels(&build(0, 1)));
    let qqq = times(&times(&q, &q), &q);
    for (name, ch) in [("3 x 3bar", times(&q, &qb)), ("3 x 3", times(&q, &q)), ("3 x 3 x 3", qqq.clone())] {
        let parts = split(&ch);
        let sizes: Vec<String> = parts.iter().map(|p| format!("{}", weyl(p.0 as f64, p.1 as f64) as i64)).collect();
        println!("{} = {} -> {} = {}; colourless singlets: {}", name, show(&parts), sizes.join(" + "), ch.values().sum::<i64>(),
                 parts.iter().filter(|&&p| p == (0, 0)).count());
    }
    assert!(split(&times(&q, &qb)) == vec![(1, 1), (0, 0)]);
    assert!(split(&qqq) == vec![(3, 0), (1, 1), (1, 1), (0, 0)]);
    for (name, ab) in [("3", (1, 0)), ("8", (1, 1)), ("10", (3, 0))] {
        let mut pts: Vec<((i64, i64), i64)> =
            by_labels(&build(ab.0, ab.1)).iter().map(|(&(p, r), &n)| ((p, p + 2 * r), n)).collect();
        pts.sort();
        let s: Vec<String> = pts.iter().map(|((xx, yy), n)| format!("({},{})x{}", xx, yy, n)).collect();
        println!("figure, {}: {}", name, s.join(" "));
    }
    println!("mistake 1, non-dominant (-3, 0) in Weyl's product: {:.3}, no such representation", weyl(-3.0, 0.0));
    println!("mistake 2, half-integer (1/2, 0) in Weyl's product: {:.3}, not a count", weyl(0.5, 0.0));
    println!("mistake 3, dropping rho for the quark (1, 0): {:.3} states", weyl_no_rho(1.0, 0.0));
    println!("mistake 4, counting weight points for the adjoint: {}, not {}", adj.len(), adj_states);
    assert!(adj.len() == 7 && adj[&(0, 0)] == 2);
    println!("ALL CHECKS PASS");
}
