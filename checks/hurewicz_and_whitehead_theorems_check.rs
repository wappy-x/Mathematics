// Hurewicz and Whitehead -- the same check as the Python, in Rust.  No crates.  Integer homology by
// Smith normal form, written out here; figure-eight loops as reduced words; Kunneth from the factors.
use std::collections::BTreeMap;

type Mat = Vec<Vec<i64>>;
type Cx = (Vec<usize>, BTreeMap<usize, Mat>);
type Hom = Vec<(i64, Vec<i64>)>;

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } } // Euclid
fn diagonal(m: &Mat) -> Vec<i64> {                 // Smith normal form: the invariant factors
    let (mut a, mut out) = (m.clone(), Vec::new());
    loop {
        let mut nz: Vec<(i64, usize, usize)> = Vec::new();
        for i in 0..a.len() { for j in 0..a[0].len() { if a[i][j] != 0 { nz.push((a[i][j].abs(), i, j)) } } }
        let Some(&(_, p, q)) = nz.iter().min() else { break };
        let mut clean = true;
        for i in 0..a.len() { if i != p && a[i][q] != 0 {   // clear column q with row operations
            let f = a[i][q].div_euclid(a[p][q]);
            for j in 0..a[0].len() { a[i][j] -= f * a[p][j] }
            clean = clean && a[i][q] == 0;
        } }
        for j in 0..a[0].len() { if j != q && a[p][j] != 0 {   // clear row p with column operations
            let f = a[p][j].div_euclid(a[p][q]);
            for i in 0..a.len() { a[i][j] -= f * a[i][q] }
            clean = clean && a[p][j] == 0;
        } }
        if clean {
            out.push(a[p][q].abs());
            a = a.iter().enumerate().filter(|(i, _)| *i != p)
                .map(|(_, r)| r.iter().enumerate().filter(|(j, _)| *j != q).map(|(_, x)| *x).collect()).collect();
        }
    }
    for i in 0..out.len() { for j in i + 1..out.len() {   // make each factor divide the next
        let g = gcd(out[i], out[j]);
        (out[i], out[j]) = (g, out[i] * out[j] / g);
    } }
    out
}

fn homology(c: &Cx) -> Hom {                       // cells[k] = number of k-cells; d[k]: C_k -> C_(k-1)
    let (cells, d) = c;
    let fac: Vec<Vec<i64>> = (0..=cells.len()).map(|k| d.get(&k).map(diagonal).unwrap_or_default()).collect();
    (0..cells.len()).map(|k| (cells[k] as i64 - fac[k].len() as i64 - fac[k + 1].len() as i64,
                              fac[k + 1].iter().copied().filter(|&t| t > 1).collect())).collect()
}

fn zero_dd(d: &BTreeMap<usize, Mat>) -> bool {     // the boundary of a boundary is zero
    d.iter().filter(|(k, _)| d.contains_key(&(*k - 1))).all(|(k, b)| {
        let a = &d[&(k - 1)];
        (0..a.len()).all(|i| (0..b[0].len()).all(|j| (0..b.len()).map(|m| a[i][m] * b[m][j]).sum::<i64>() == 0))
    })
}
fn show(h: &Hom) -> String { h.iter().enumerate().map(|(k, (r, t))| format!("H{}: rank {}, torsion {:?}", k, r, t)).collect::<Vec<_>>().join("; ") }
fn cx(cells: Vec<usize>, d: Vec<(usize, Mat)>) -> Cx { (cells, d.into_iter().collect()) }
fn sphere(n: usize) -> Cx { let mut c = vec![0; n + 1]; c[0] = 1; c[n] = 1; cx(c, vec![]) }
fn rp(n: usize) -> Cx {                            // one cell per dimension, boundary 1 + (-1)^k
    cx(vec![1; n + 1], (1..=n).map(|k| (k, vec![vec![if k % 2 == 0 { 2 } else { 0 }]])).collect())
}

fn times(x: &Cx, y: &Cx) -> Cx {                   // product cells: d(a x b) = da x b + (-1)^|a| a x db
    let ((cx_, dx), (cy, dy)) = (x, y);
    let mut cells: BTreeMap<usize, Vec<(usize, usize, usize, usize)>> = BTreeMap::new();
    for p in 0..cx_.len() { for q in 0..cy.len() {
        let e = cells.entry(p + q).or_default();
        for i in 0..cx_[p] { for j in 0..cy[q] { e.push((p, i, q, j)) } }
    } }
    let top = *cells.keys().max().unwrap();
    let get = |k: usize| cells.get(&k).cloned().unwrap_or_default();
    let pos = |k: usize, c: (usize, usize, usize, usize)| get(k).iter().position(|&x| x == c).unwrap();
    let mut d = BTreeMap::new();
    for k in 1..=top {
        let mut m = vec![vec![0i64; get(k).len()]; get(k - 1).len()];
        for (col, &(p, i, q, j)) in get(k).iter().enumerate() {
            if let Some(b) = dx.get(&p) { for r in 0..cx_[p - 1] { m[pos(k - 1, (p - 1, r, q, j))][col] += b[r][i] } }
            let s = if p % 2 == 0 { 1 } else { -1 };
            if let Some(b) = dy.get(&q) { for r in 0..cy[q - 1] { m[pos(k - 1, (p, i, q - 1, r))][col] += s * b[r][j] } }
        }
        d.insert(k, m);
    }
    ((0..=top).map(|k| get(k).len()).collect(), d)
}

fn kunneth(hx: &Hom, hy: &Hom, tor: bool) -> Hom {  // second road: tensor plus Tor, from the factors
    (0..hx.len() + hy.len() - 1).map(|k| {
        let (mut rank, mut tors) = (0i64, Vec::new());
        for (i, (r1, t1)) in hx.iter().enumerate() { for (j, (r2, t2)) in hy.iter().enumerate() {
            let pairs: Vec<i64> = t1.iter().flat_map(|&a| t2.iter().map(move |&b| gcd(a, b))).collect();
            if i + j == k {
                rank += r1 * r2;
                for _ in 0..*r2 { tors.extend(t1) } for _ in 0..*r1 { tors.extend(t2) } tors.extend(&pairs);
            }
            if tor && i + j + 1 == k { tors.extend(&pairs) }
        } }
        tors.retain(|&t| t > 1); tors.sort();
        (rank, tors)
    }).collect()
}
fn reduce(w: &str) -> String {                     // free reduction: cancel a A, A a, b B, B b
    let mut out: Vec<char> = Vec::new();
    for x in w.chars() {
        let inv = if x.is_lowercase() { x.to_ascii_uppercase() } else { x.to_ascii_lowercase() };
        if out.last() == Some(&inv) { out.pop(); } else { out.push(x) }
    }
    out.into_iter().collect()
}
fn h(w: &str) -> (i64, i64) {                      // the Hurewicz map on the figure eight: exponent sums
    let n = |c: char| w.chars().filter(|&x| x == c).count() as i64;
    (n('a') - n('A'), n('b') - n('B'))
}

fn main() {
    let words: Vec<Vec<String>> = (0..5u32).map(|k| (0..4usize.pow(k)).map(|mut n| {
        let mut s = vec!['a'; k as usize];
        for p in (0..k as usize).rev() { s[p] = ['a', 'A', 'b', 'B'][n % 4]; n /= 4 }
        s.into_iter().collect::<String>()
    }).filter(|w| reduce(w) == *w).collect()).collect();
    let eight = homology(&cx(vec![1, 2], vec![]));
    println!("figure eight, cells [1, 2]: {}", show(&eight));
    let counts: Vec<usize> = (1..5).map(|k| words[k].len()).collect();
    println!("reduced words of length 1 to 4: {:?}", counts);
    let dead: Vec<String> = words[4].iter().filter(|w| h(w) == (0, 0)).cloned().collect();
    println!("length-4 loops that h sends to (0, 0): {}: {}", dead.len(), dead.join(" "));
    println!("h(ab) = {:?}, h(ba) = {:?}; ab and ba the same loop: {}", h("ab"), h("ba"), if reduce("abAB").is_empty() { "yes" } else { "no" });
    let short: Vec<String> = (0..3).flat_map(|k| words[k].clone()).collect();
    let hom = short.iter().all(|u| short.iter().all(|v| h(&reduce(&format!("{}{}", u, v))) == (h(u).0 + h(v).0, h(u).1 + h(v).1)));
    println!("h(uv) = h(u) + h(v) on all {} pairs up to length 2: {}", short.len() * short.len(), if hom { "yes" } else { "no" });
    let wedge = homology(&cx(vec![1, 0, 2], vec![]));
    println!("S2 v S2, cells [1, 0, 2]: {}", show(&wedge));
    let mut tris: Vec<Vec<usize>> = Vec::new();
    for s in [[0, 1, 2, 3], [0, 4, 5, 6]] { for a in 0..4 { for b in a + 1..4 { for c in b + 1..4 { tris.push(vec![s[a], s[b], s[c]]) } } } }
    let mut edges: Vec<Vec<usize>> = tris.iter().flat_map(|t| vec![vec![t[0], t[1]], vec![t[0], t[2]], vec![t[1], t[2]]]).collect();
    edges.sort(); edges.dedup();
    let bd = |faces: &Vec<Vec<usize>>, cells: &Vec<Vec<usize>>| -> Mat { faces.iter().map(|f| cells.iter().map(|c| (0..c.len())
        .filter(|&i| { let mut g = c.clone(); g.remove(i); g == *f }).map(|i| if i % 2 == 0 { 1 } else { -1 }).sum()).collect()).collect() };
    let verts: Vec<Vec<usize>> = (0..7).map(|v| vec![v]).collect();
    let tri = homology(&cx(vec![7, edges.len(), tris.len()], vec![(1, bd(&verts, &edges)), (2, bd(&edges, &tris))]));
    println!("S2 v S2, two hollow tetrahedra, V E F = 7 {} {}, chi {}: {}", edges.len(), tris.len(), 7 - edges.len() as i64 + tris.len() as i64, show(&tri));
    println!("pi1 = 1 (no 1-cells), so Hurewicz: pi2(S2 v S2) = H2: rank {}", wedge[2].0);
    let (p, q) = (times(&rp(2), &sphere(3)), times(&sphere(2), &rp(3)));
    let (hp, hq) = (homology(&p), homology(&q));
    let (kp, kq) = (kunneth(&homology(&rp(2)), &homology(&sphere(3)), true), kunneth(&homology(&sphere(2)), &homology(&rp(3)), true));
    println!("RP2 x S3, product cells {:?}: {}", p.0, show(&hp));
    println!("RP2 x S3, by Kunneth: {}", show(&kp));
    println!("S2 x RP3, product cells {:?}: {}", q.0, show(&hq));
    println!("S2 x RP3, by Kunneth: {}", show(&kq));
    let cover = homology(&times(&sphere(2), &sphere(3)));
    println!("common universal cover S2 x S3: {}", show(&cover));
    println!("pi1 of both: Z/{}; pi2 of both = H2(S2 x S3): rank {}", hp[1].1[0], cover[2].0);
    println!("H5: RP2 x S3 rank {}, S2 x RP3 rank {}: not homotopy equivalent", hp[5].0, hq[5].0);
    let dunce = homology(&cx(vec![1, 1, 1], vec![(2, vec![vec![h("aaA").0]])]));
    println!("dunce hat, rim aaA, incidence {}: {}; chi {}", h("aaA").0, show(&dunce), 1 - 1 + 1);
    println!("rim aaA freely reduced: {}, so the relation reads a = 1 and pi1 = 1", reduce("aaA"));
    println!("mistake, Hurewicz with pi1 = Z/2: RP2 {}; pi2(RP2) = pi2(S2) = H2(S2): rank {}", show(&homology(&rp(2))), homology(&sphere(2))[2].0);
    println!("mistake, Hurewicz with pi1 = Z^2: torus {}; pi2 = 0 (cover R2)", show(&homology(&cx(vec![1, 2, 1], vec![]))));
    println!("mistake, past the first group: H3(S2): rank {}, but pi3(S2) = Z (Hopf)", homology(&cx(vec![1, 0, 1, 0], vec![]))[3].0);
    let rr = times(&rp(2), &rp(2));
    let (hr, no_tor) = (homology(&rr), kunneth(&homology(&rp(2)), &homology(&rp(2)), false));
    let third = |s: String| s.split("; ").nth(3).unwrap().to_string();
    println!("mistake, Kunneth without Tor: RP2 x RP2 reads {}; truly {}", third(show(&no_tor)), third(show(&hr)));
    println!("mistake, no abelianising: {} loops of length 4 are not trivial in pi1 yet read 0 in H1", dead.len());
    assert!(eight == vec![(1, vec![]), (2, vec![])] && dead.len() == 8 && hom);
    assert!(counts == (1..5).map(|k| 4 * 3usize.pow(k - 1)).collect::<Vec<_>>());
    assert!(wedge == tri && wedge[2] == (2, vec![]));
    assert!(hp == kp && hq == kq);
    assert!(hr == kunneth(&homology(&rp(2)), &homology(&rp(2)), true) && hr[3] == (0, vec![2]) && zero_dd(&rr.1));
    assert!(hp[5] == (0, vec![]) && hq[5] == (1, vec![]) && cover[2] == (1, vec![]));
    assert!(dunce == vec![(1, vec![]), (0, vec![]), (0, vec![])] && reduce("aaA") == "a");
    println!("ALL CHECKS PASS");
}
