// Column generation on a cutting-stock problem.  std only, exact fractions.
// Minimise the number of 10 m boards cut to cover an order of pieces.  The master LP picks how many
// boards to cut to each pattern; a knapsack (the pricing problem) writes each new pattern from the duals.
use std::cmp::Ordering;
#[derive(Clone, Copy, Debug)]
struct Q(i128, i128); // numerator, denominator > 0, in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn z(n: i64) -> Q { Q(n as i128, 1) }
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn ceil(x: Q) -> i64 { (x.0.div_euclid(x.1) + if x.0.rem_euclid(x.1) != 0 { 1 } else { 0 }) as i64 }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { r(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { r(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { r(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { r(self.0 * o.1, self.1 * o.0) } }
impl PartialEq for Q { fn eq(&self, o: &Q) -> bool { self.cmp(o) == Ordering::Equal } }
impl Eq for Q {}
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) } } }

type Pat = Vec<i64>;
fn pt(a: &[i64]) -> String { format!("({})", a.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ")) }
fn fs(v: &[Q]) -> String { v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(" ") }
fn dot(y: &[Q], a: &[i64]) -> Q { y.iter().zip(a).fold(z(0), |s, (yi, ai)| s + *yi * z(*ai)) }

fn solve_master(p: &[Pat], d: &[i64]) -> (Q, Vec<Q>, Vec<Q>) { // simplex on the master's dual, Bland's rule
    let (m, n) = (d.len(), p.len());
    let mut t: Vec<Vec<Q>> = (0..n).map(|row| { let mut v: Vec<Q> = (0..m).map(|i| z(p[row][i])).collect();
        v.extend((0..n).map(|j| z((j == row) as i64))); v.push(z(1)); v }).collect();
    let mut obj: Vec<Q> = d.iter().map(|v| z(-v)).chain((0..=n).map(|_| z(0))).collect();
    let mut basis: Vec<usize> = (0..n).map(|row| m + row).collect();
    while let Some(e) = (0..m + n).find(|&j| obj[j] < z(0)) {
        let row = (0..n).filter(|&k| t[k][e] > z(0))
            .min_by(|&a, &b| (t[a][n + m] / t[a][e]).cmp(&(t[b][n + m] / t[b][e])).then(basis[a].cmp(&basis[b]))).unwrap();
        let pv = t[row][e]; t[row] = t[row].iter().map(|v| *v / pv).collect();
        for k in 0..n { if k != row && t[k][e] != z(0) { let f = t[k][e]; let tr = t[row].clone();
            t[k] = t[k].iter().zip(&tr).map(|(a, b)| *a - f * *b).collect(); } }
        let f = obj[e]; obj = obj.iter().zip(&t[row]).map(|(a, b)| *a - f * *b).collect(); basis[row] = e;
    }
    let mut y = vec![z(0); m];
    for (row, b) in basis.iter().enumerate() { if *b < m { y[*b] = t[row][n + m]; } }
    (obj[m + n], y, obj[m..m + n].to_vec())
}
fn price(y: &[Q], l: &[i64], cap: i64) -> (Q, Pat) { // exact pricing: unbounded knapsack table over length
    let mut best: Vec<(Q, Pat)> = vec![(z(0), vec![0; l.len()]); cap as usize + 1];
    for c in 1..=cap as usize {
        best[c] = best[c - 1].clone();
        for i in 0..l.len() { let li = l[i] as usize;
            if li <= c && best[c - li].0 + y[i] > best[c].0 { let mut a = best[c - li].1.clone(); a[i] += 1; best[c] = (best[c - li].0 + y[i], a); } }
    }
    best[cap as usize].clone()
}
fn greedy(y: &[Q], l: &[i64], cap: i64) -> (Q, Pat) { // a quick pricing guess: fill by price per metre
    let mut ord: Vec<usize> = (0..l.len()).collect();
    ord.sort_by(|&a, &b| (y[b] / z(l[b])).cmp(&(y[a] / z(l[a]))).then(a.cmp(&b)));
    let (mut a, mut room) = (vec![0; l.len()], cap);
    for i in ord { a[i] = room / l[i]; room -= a[i] * l[i]; }
    (dot(y, &a), a)
}
type Hist = Vec<(Q, Vec<Q>, Q, Pat, Q)>;
fn colgen(l: &[i64], d: &[i64], cap: i64, start: &[Pat], pricer: fn(&[Q], &[i64], i64) -> (Q, Pat), show: bool)
    -> (Q, Vec<Q>, Vec<Q>, Vec<Pat>, Hist) {
    let (mut p, mut hist): (Vec<Pat>, Hist) = (start.to_vec(), vec![]);
    loop {
        let (zz, y, x) = solve_master(&p, d);
        let (v, a) = pricer(&y, l, cap);
        hist.push((zz, y.clone(), v, a.clone(), zz / v));
        if show { println!("round {}: master {} boards, duals {}; best pattern {} worth {}, reduced cost {}; bound {} = {:.4}",
            hist.len() - 1, zz, fs(&y), pt(&a), v, z(1) - v, zz / v, fl(zz / v)); }
        if v <= z(1) { return (zz, y, x, p, hist); }
        p.push(a);
    }
}
fn fits(l: &[i64], cap: i64) -> Vec<Pat> { // every pattern that fits one board, listed by brute force
    if l.is_empty() { return vec![vec![]]; }
    (0..=cap / l[0]).flat_map(|a| fits(&l[1..], cap - a * l[0]).into_iter().map(move |mut q| { q.insert(0, a); q })).collect()
}
fn cover(x: &[Q], p: &[Pat]) -> Vec<Q> { (0..3).map(|i| x.iter().zip(p).fold(z(0), |s, (xp, a)| s + *xp * z(a[i]))).collect() }

fn main() {
    let (l, d, cap) = ([3i64, 4, 5], [30i64, 20, 10], 10i64);
    let start: Vec<Pat> = vec![vec![3, 0, 0], vec![0, 2, 0], vec![0, 0, 2]];
    let (zz, y, x, p, hist) = colgen(&l, &d, cap, &start, price, true);
    println!("round 0, bound from kappa = 25 boards: {}", hist[0].0 + z(25) * (z(1) - hist[0].2));
    println!("master plan: {}", x.iter().zip(&p).filter(|(xp, _)| **xp != z(0)).map(|(xp, a)| format!("{} x {}", xp, pt(a))).collect::<Vec<_>>().join(", "));
    let mut allp: Vec<Pat> = vec![];
    for a in 0..4 { for b in 0..3 { for c in 0..3 { if 3 * a + 4 * b + 5 * c <= cap && a + b + c > 0 { allp.push(vec![a, b, c]); } } } }
    let maxp: Vec<Pat> = allp.iter().filter(|q| 10 - (3 * q[0] + 4 * q[1] + 5 * q[2]) < 3).cloned().collect();
    let vals: Vec<Q> = allp.iter().map(|q| dot(&y, q)).collect();
    let top = *vals.iter().max().unwrap();
    println!("patterns that fit: {}, with no room for another piece: {}; highest value at the final duals {}, on {} patterns",
        allp.len(), maxp.len(), top, vals.iter().filter(|v| **v == z(1)).count());
    println!("round 0 master plan: {} boards for {}", fs(&solve_master(&start, &d).2), start.iter().map(|a| pt(a)).collect::<Vec<_>>().join(", "));
    for k in 0..2 { println!("round {} values: {}", k, maxp.iter().map(|q| format!("{} {}", pt(q), dot(&hist[k].1, q))).collect::<Vec<_>>().join(", ")); }
    let covered = cover(&x, &p);
    let dual = dot(&y, &d);
    println!("certificate: pieces covered {} ; boards {} ; dual value {}", fs(&covered), x.iter().fold(z(0), |s, v| s + *v), dual);
    let z_all = solve_master(&allp, &d).0;
    println!("road 2, master with all {} patterns listed: {}", allp.len(), z_all);
    let length: i64 = l.iter().zip(&d).map(|(a, b)| a * b).sum();
    let k_pt: Vec<Q> = d.iter().map(|di| r(*di as i128, 22)).collect();
    println!("compact LP: total length {} m, so at least {} boards; 22 boards each holding {} pieces fill {} m",
        length, r(length as i128, cap as i128), fs(&k_pt), dot(&k_pt, &l));
    let mut f = vec![0i64; 31 * 21 * 11]; // road 3: fewest whole boards for every smaller order
    let ix = |a: i64, b: i64, c: i64| (a * 231 + b * 11 + c) as usize;
    for a in 0..31 { for b in 0..21 { for c in 0..11 { if a + b + c > 0 {
        f[ix(a, b, c)] = 1 + maxp.iter().map(|q| ((a - q[0]).max(0), (b - q[1]).max(0), (c - q[2]).max(0)))
            .filter(|s| *s != (a, b, c)).map(|s| f[ix(s.0, s.1, s.2)]).min().unwrap();
    } } } }
    let plan: Vec<Q> = x.iter().map(|v| z(ceil(*v))).collect();
    let pc = cover(&plan, &p);
    let nplan: i64 = plan.iter().map(|v| v.0 as i64).sum();
    println!("road 3, whole boards by table over {} orders: {}; rounding the master up: {} boards covering {}", f.len(), f[ix(30, 20, 10)], nplan, fs(&pc));
    let down: Vec<Q> = x.iter().map(|v| z(v.0.div_euclid(v.1) as i64)).collect();
    let dc = cover(&down, &p);
    println!("round down: {} boards covering {}", down.iter().map(|v| v.0 as i64).sum::<i64>(), fs(&dc));
    let (zg, _, _, _, hg) = colgen(&l, &d, cap, &start, greedy, false);
    println!("greedy pricing: pattern {} worth {}; stops at {} boards", pt(&hg[0].3), hg[0].2, zg);
    let waste: i64 = plan.iter().zip(&p).map(|(n, a)| n.0 as i64 * (cap - l.iter().zip(a).map(|(li, ai)| li * ai).sum::<i64>())).sum(); // sawn offcut
    println!("unused: {} m over {} boards: offcut {} m, spare pieces {}", nplan * cap - length, nplan, waste,
        fs(&pc.iter().zip(&d).map(|(c, di)| *c - z(*di)).collect::<Vec<_>>()));

    let (lb, db, cb) = ([120i64, 150, 180, 230, 270, 310, 340, 380, 430, 470], [30i64, 25, 40, 22, 18, 35, 14, 20, 12, 16], 1000i64);
    let sb: Vec<Pat> = (0..10).map(|i| (0..10).map(|j| if i == j { cb / lb[i] } else { 0 }).collect()).collect();
    let (zb, yb, xb, _pb, hb) = colgen(&lb, &db, cb, &sb, price, false);
    for (k, h) in hb.iter().enumerate() {
        println!("tail k={:2}: master {:8.4} bound {:8.4} gap {:7.4}", k, fl(h.0), fl(h.4), fl(h.0 - h.4));
    }
    println!("tail: LP {} = {:.2} after {} new patterns; at least {} boards; rounding up uses {}; final duals {} ...",
        zb, fl(zb), hb.len() - 1, ceil(zb), xb.iter().map(|v| ceil(*v)).sum::<i64>(), fs(&yb[..3]));
    let kb = (0..hb.len() - 1).fold(0, |b, k| if hb[k].4 > hb[b].4 { k } else { b });
    let within = hb.iter().position(|h| h.0 <= r(101, 100) * zb).unwrap();
    let lenb = r(lb.iter().zip(&db).map(|(a, b)| a * b).sum::<i64>() as i128, cb as i128); // length floor: every piece at l_i / L
    let ks = (0..hb.len()).find(|&k| ceil(hb[k].0) == ceil(hb[..=k].iter().fold(lenb, |m, h| m.max(h.4)))).unwrap();
    println!("tail: length floor {:.2} from k=0, proving {} boards; best bound z/v* before the last round {:.4} at k={}, proving {}",
        fl(lenb), ceil(lenb), fl(hb[kb].4), kb, ceil(hb[kb].4));
    println!("tail: stop rule, master and best floor both round up to {} from k={}, {} rounds early; master within 1% from k={}",
        ceil(hb[ks].0), ks, hb.len() - 1 - ks, within);
    let allb: Vec<Pat> = fits(&lb, cb).into_iter().filter(|q| q.iter().any(|&a| a > 0)).collect();
    let vb = allb.iter().map(|q| dot(&yb, q)).max().unwrap();
    println!("tail: all {} patterns that fit, listed: highest value at the final duals {}", allb.len(), vb);

    assert!(zz == z_all && z_all == r(45, 2) && dual == zz); // column generation = full master = dual
    assert!(top == z(1) && covered.iter().zip(&d).all(|(c, di)| *c >= z(*di))); // duals feasible for every pattern
    assert!(f[ix(30, 20, 10)] == nplan && nplan == ceil(zz) && pc.iter().zip(&d).all(|(c, di)| *c >= z(*di)));
    assert!(hist.iter().all(|h| h.4 <= zz) && hb.iter().all(|h| h.4 <= zb)); // every round's bound is below the LP
    assert!(zg == z(25) && zg > zz && covered[1] > dc[1]);
    assert!(vb == z(1)); // the final duals price every pattern at most 1
    assert!(zb == lenb && ceil(hb[ks].0) == ceil(zb) && xb.iter().all(|v| *v >= z(0))); // LP = length floor; the stop rule's bound is final
    for (nd, nl, lab) in [([31i64, 20, 10], 10i64, "31 short pieces"), ([30, 20, 10], 11, "11 m boards")] {
        let zt = colgen(&l, &nd, nl, &start, price, false).0;
        println!("try {}: LP {} = {:.2}, so at least {} boards", lab, zt, fl(zt), ceil(zt));
    }
    let one: Vec<Pat> = vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, 1]];
    let (zt, _, _, _, ht) = colgen(&l, &d, cap, &one, price, false);
    println!("try one piece per board to start: {} boards, {} new patterns, LP {}", ht[0].0, ht.len() - 1, zt);
    println!("ALL CHECKS PASS");
}
