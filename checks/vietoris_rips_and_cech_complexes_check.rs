// Vietoris-Rips and Cech complexes -- the check behind the card.  std only, no crates.
// Twelve sensor sites (metres), ball radius r: a Rips edge joins sites within 2r.
// Roads: Cech membership by the angle rule plus Helly, against a brute-force smallest
// enclosing circle on every subset; holes by mod-2 ranks, against union-find for the
// pieces and against a flood fill of the real union of discs (the nerve theorem).
use std::{cmp::Ordering, collections::{BTreeMap, HashSet}};
const P: [(i64, i64); 12] = [(270, 200), (235, 285), (150, 320), (65, 285), (30, 200), (65, 115), (150, 80),
    (235, 115), (330, 278), (102, 315), (0, 120), (200, 10)];
const N: usize = 12; type Cx = Vec<Vec<Vec<usize>>>;
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i128, d: i128 } // an exact fraction, lowest terms, positive denominator
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
impl Q {
    fn new(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
    fn add(self, o: Q) -> Q { Q::new(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Q) -> Q { Q::new(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Q) -> Q { Q::new(self.n * o.n, self.d * o.d) }  fn f(self) -> f64 { self.n as f64 / self.d as f64 }
    fn int(v: i64) -> Q { Q::new(v as i128, 1) }
}
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
fn d2(a: usize, b: usize) -> i64 { (P[a].0 - P[b].0).pow(2) + (P[a].1 - P[b].1).pow(2) }
fn cross(a: usize, b: usize, c: usize) -> i64 { (P[b].0 - P[a].0) * (P[c].1 - P[a].1) - (P[b].1 - P[a].1) * (P[c].0 - P[a].0) }
fn circum2(a: usize, b: usize, c: usize) -> Q { // circumradius squared, exact
    Q::new((d2(a, b) * d2(b, c) * d2(a, c)) as i128, 4 * (cross(a, b, c) as i128).pow(2))
}
fn combos(items: &[usize], k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]]; }
    (0..items.len()).flat_map(|i| combos(&items[i + 1..], k - 1).into_iter().map(move |r| [vec![items[i]], r].concat())).collect()
}
fn tri_ok(t: &[usize], rr: i64, rule: bool) -> bool { // road 1: discs around a, b, c share a point
    let mut s: Vec<i64> = combos(t, 2).iter().map(|e| d2(e[0], e[1])).collect();
    s.sort();
    if rule && s[2] >= s[0] + s[1] { return s[2] <= 4 * rr; } // right or obtuse: longest side is a diameter
    s[2] <= 4 * rr && circum2(t[0], t[1], t[2]) <= Q::int(rr)
}
fn centres(s: &[usize]) -> Vec<(Q, Q)> { // every candidate centre of a smallest enclosing circle
    let mut out: Vec<(Q, Q)> = combos(s, 2).iter()
        .map(|e| (Q::new((P[e[0]].0 + P[e[1]].0) as i128, 2), Q::new((P[e[0]].1 + P[e[1]].1) as i128, 2))).collect();
    for t in combos(s, 3) {
        let (a, b, c) = (t[0], t[1], t[2]);
        let (dd, bx, by, cx, cy) = (2 * cross(a, b, c) as i128, P[b].0 - P[a].0, P[b].1 - P[a].1, P[c].0 - P[a].0, P[c].1 - P[a].1);
        if dd != 0 { out.push((Q::int(P[a].0).add(Q::new((cy * d2(a, b) - by * d2(a, c)) as i128, dd)),
                               Q::int(P[a].1).add(Q::new((bx * d2(a, c) - cx * d2(a, b)) as i128, dd)))); }
    }
    out
}
fn dist2(c: (Q, Q), v: usize) -> Q { let (dx, dy) = (c.0.sub(Q::int(P[v].0)), c.1.sub(Q::int(P[v].1))); dx.mul(dx).add(dy.mul(dy)) }
fn meb2(s: &[usize]) -> Q { // road 2: smallest enclosing circle, brute force
    centres(s).iter().map(|&c| s.iter().map(|&v| dist2(c, v)).max().unwrap()).min().unwrap()
}
fn complexes(rr: i64, rule: bool) -> (Cx, Cx) {
    let all: Vec<usize> = (0..N).collect();
    let verts: Vec<Vec<usize>> = (0..N).map(|v| vec![v]).collect();
    let e: Vec<Vec<usize>> = combos(&all, 2).into_iter().filter(|e| d2(e[0], e[1]) <= 4 * rr).collect();
    let (mut r, mut c) = (vec![verts.clone(), e.clone()], vec![verts, e.clone()]);
    for k in 2..N {
        let rk: Vec<Vec<usize>> = combos(&all, k + 1).into_iter().filter(|s| combos(s, 2).iter().all(|p| e.contains(p))).collect();
        let ck = rk.iter().filter(|s| combos(s, 3).iter().all(|t| tri_ok(t, rr, rule))).cloned().collect(); // Helly
        let empty = rk.is_empty(); r.push(rk); c.push(ck);
        if empty { break; }
    }
    (r, c)
}
fn betti(k: &Cx) -> Vec<i64> { // over Z mod 2: columns as sorted lists, reduced by lowest row
    let mut rank = vec![0i64; k.len() + 1];
    for d in 1..k.len() {
        let mut low: BTreeMap<usize, Vec<usize>> = BTreeMap::new();
        for s in &k[d] {
            let mut col: Vec<usize> = (0..s.len()).map(|i| { let mut f = s.clone(); f.remove(i); k[d - 1].iter().position(|x| *x == f).unwrap() }).collect();
            col.sort();
            while let Some(&l) = col.last() {
                let Some(p) = low.get(&l) else { break };
                let (a, b): (HashSet<usize>, HashSet<usize>) = (col.iter().cloned().collect(), p.iter().cloned().collect());
                col = a.symmetric_difference(&b).cloned().collect(); col.sort();
            }
            if let Some(&l) = col.last() { low.insert(l, col); rank[d] += 1; }
        }
    }
    (0..k.len()).map(|d| k[d].len() as i64 - rank[d] - rank[d + 1]).collect()
}
fn pieces(e: &[Vec<usize>]) -> i64 { // union-find on the edges: betti0 without any rank
    fn find(r: &[usize], mut v: usize) -> usize { while r[v] != v { v = r[v]; } v }
    let mut root: Vec<usize> = (0..N).collect();
    for p in e { let (a, b) = (find(&root, p[0]), find(&root, p[1])); root[a] = b; }
    (0..N).map(|v| find(&root, v)).collect::<HashSet<_>>().len() as i64
}
fn union(rr: i64) -> (usize, Vec<usize>) { // flood fill on a 1 m grid: covered pieces, enclosed gaps
    let m = (rr as f64).sqrt() as i64 + 10; let (x0, x1) = (P.iter().map(|p| p.0).min().unwrap() - m, P.iter().map(|p| p.0).max().unwrap() + m);
    let (y0, y1) = (P.iter().map(|p| p.1).min().unwrap() - m, P.iter().map(|p| p.1).max().unwrap() + m);
    let (w, h) = ((x1 - x0 + 1) as usize, (y1 - y0 + 1) as usize);
    let cov: Vec<bool> = (0..w * h).map(|i| { let (x, y) = (x0 + (i / h) as i64, y0 + (i % h) as i64);
        P.iter().any(|&(a, b)| (x - a).pow(2) + (y - b).pow(2) <= rr) }).collect();
    let (mut seen, mut pieces, mut gaps) = (vec![false; w * h], 0, vec![]);
    for st in 0..w * h {
        if seen[st] { continue; }
        let val = cov[st];
        let (mut stack, mut size, mut edge) = (vec![st], 0, false); seen[st] = true;
        while let Some(i) = stack.pop() {
            size += 1;
            let (x, y) = ((i / h) as i64, (i % h) as i64); edge |= x == 0 || y == 0 || x == w as i64 - 1 || y == h as i64 - 1;
            let steps = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)];
            for &(dx, dy) in &steps[..if val { 4 } else { 8 }] {
                let (nx, ny) = (x + dx, y + dy);
                if nx < 0 || ny < 0 || nx >= w as i64 || ny >= h as i64 { continue; }
                let q = nx as usize * h + ny as usize;
                if !seen[q] && cov[q] == val { seen[q] = true; stack.push(q); }
            }
        }
        if val { pieces += 1; } else if !edge { gaps.push(size); }
    }
    gaps.sort(); (pieces, gaps)
}
fn size(k: &Cx) -> Vec<usize> { k.iter().map(|x| x.len()).filter(|&n| n > 0).collect() }
fn ls<T: std::fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn tup(v: &[usize]) -> String { ls(v).replace('[', "(").replace(']', ")") }
fn sq(q: Q) -> String { format!("{:.2}", q.f().sqrt()) }
fn main() {
    let r: i64 = 50;
    let (rc, cc) = complexes(r * r, true);
    let (br, bc) = (betti(&rc), betti(&cc));
    println!("sites {} | ball radius {} m | edge if distance <= {} m", N, r, 2 * r);
    println!("edges, length m: {}", rc[1].iter().map(|e| format!("{}-{} {:.1}", e[0], e[1], (d2(e[0], e[1]) as f64).sqrt())).collect::<Vec<_>>().join(", "));
    println!("Rips simplices by dimension {} total {} | betti mod 2 {}", ls(&size(&rc)), size(&rc).iter().sum::<usize>(), ls(&br[..3]));
    println!("Cech simplices by dimension {} total {} | betti mod 2 {}", ls(&size(&cc)), size(&cc).iter().sum::<usize>(), ls(&bc[..3]));
    println!("triangles Rips fills, Cech leaves open {}", ls(&rc[2].iter().filter(|t| !cc[2].contains(t)).map(|t| tup(t)).collect::<Vec<_>>()));
    for t in &rc[2] {
        let sides: Vec<String> = combos(t, 2).iter().map(|e| format!("{:.1}", (d2(e[0], e[1]) as f64).sqrt())).collect();
        println!("triangle {} sides m {} | squared {} | area m^2 {:.1} | circumradius {} | enclosing radius {}", tup(t), sides.join(" "), combos(t, 2).iter().map(|e| d2(e[0], e[1]).to_string()).collect::<Vec<_>>().join(" "),
                 cross(t[0], t[1], t[2]).abs() as f64 / 2.0, sq(circum2(t[0], t[1], t[2])), sq(meb2(t)));
    }
    let g = circum2(0, 1, 8);
    println!("gap triangle: circumradius^2 {}/{} m^2, so its discs share a point only from r = {} m", g.n, g.d, sq(g));
    let subsets: Vec<Vec<usize>> = (2..5).flat_map(|k| combos(&(0..N).collect::<Vec<_>>(), k)).collect();
    for (rad, (rh, ch)) in [(r, (rc.clone(), cc.clone())), (85, complexes(85 * 85, true))] { // Helly: at 85 m some four sites are pairwise joined
        let brute: HashSet<Vec<usize>> = subsets.iter().filter(|s| meb2(s) <= Q::int(rad * rad)).cloned().collect();
        let rule: HashSet<Vec<usize>> = (1..ch.len()).flat_map(|k| ch[k].iter().cloned()).collect();
        assert!(brute == rule, "angle rule + Helly disagrees with brute force");
        println!("Cech by brute-force enclosing circles on {} subsets at r = {} m: same {} simplices | sets of four: Rips {} Cech {}", subsets.len(), rad,
                 brute.len(), rh.get(3).map_or(0, |x| x.len()), ch.get(3).map_or(0, |x| x.len()));
    }
    for (name, k, b) in [("Rips", &rc, &br), ("Cech", &cc, &bc)] {
        let chi: i64 = size(k).iter().enumerate().map(|(i, &n)| if i % 2 == 0 { n as i64 } else { -(n as i64) }).sum();
        assert!(b[0] == pieces(&k[1]), "ranks disagree with union-find");
        println!("Euler characteristic {} {} = betti0 - betti1 + betti2", name, chi);
    }
    let jung = Q::new(4 * (r * r) as i128, 3); // Jung: Rips at r sits inside Cech at 2r/sqrt3
    assert!((1..3).all(|k| rc[k].iter().all(|s| meb2(s) <= jung)));
    println!("every Rips simplex lies in Cech at 2r/sqrt3 = {:.2} m", (4.0 * (r * r) as f64 / 3.0).sqrt());
    println!("r m | Rips sizes, betti0, betti1 | Cech sizes, betti0, betti1 | union pieces, gaps, gap sizes m^2");
    for rad in [45i64, 50, 60, 75] {
        let (rx, cx) = complexes(rad * rad, true);
        let (pieces, gaps) = union(rad * rad);
        let (bx, brx) = (betti(&cx), betti(&rx));
        assert!(bx[0] == pieces as i64 && bx[1] == gaps.len() as i64, "nerve theorem: Cech must match the union");
        println!("{} | {} {} {} | {} {} {} | {} {} {}", rad, ls(&size(&rx)), brx[0], brx[1], ls(&size(&cx)), bx[0], bx[1], pieces, gaps.len(), ls(&gaps));
    }
    let (rd, _) = complexes(r * r / 4, true); // mistake: edge within r, not 2r
    println!("mistake, edge if distance <= r: {} betti {}", ls(&size(&rd)), ls(&betti(&rd)[..2]));
    let (_, cm) = complexes(r * r, false); // mistake: circumradius for every triangle
    println!("mistake, circumradius for every triangle: {} betti {}", ls(&size(&cm)), ls(&betti(&cm)[..2]));
    assert!(betti(&cm)[1] == bc[1] + 1 && !cm[2].contains(&vec![2, 3, 9]), "the obtuse triangle should be lost");
    let (m, c239) = ((Q::new((P[2].0 + P[3].0) as i128, 2), Q::new((P[2].1 + P[3].1) as i128, 2)), *centres(&[2, 3, 9]).last().unwrap());
    assert!((0..N).filter(|i| ![2, 3, 9].contains(i)).all(|i| dist2(c239, i) > circum2(2, 3, 9))); // empty circle
    println!("alpha: midpoint of 2-3 is {} m from site 9; edge 2-3 enters at r = {} m | Delaunay ceiling: edges <= {} triangles <= {}",
             sq(dist2(m, 9)), sq(circum2(2, 3, 9)), 3 * N - 6, 2 * N - 5);
    let (gc, sites): ((Q, Q), Vec<String>) = (*centres(&[0, 1, 8]).last().unwrap(), P.iter().map(|p| format!("({}, {})", p.0, p.1)).collect());
    println!("figure, sites {} | gap centre at ({:.2}, {:.2})", ls(&sites), gc.0.f(), gc.1.f());
    println!("ALL CHECKS PASS");
}
