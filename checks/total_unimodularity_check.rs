// Total unimodularity -- the check behind the card. Standard library only. Same roads as the
// Python: exact-fraction simplex, all 720 whole plans, dual prices, and the matrix's determinants.
use std::collections::BTreeMap;

const ACTS: [&str; 6] = ["Headliner", "Rock band", "DJ", "Folk trio", "Brass band", "Singer"];
const SLOTS: [&str; 6] = ["Fri main", "Sat main", "Sun main", "Fri late tent", "Sat tent", "Sun tent"];
const VALUE: [[i64; 6]; 6] = [[48, 60, 30, 20, 25, 22], [40, 45, 28, 22, 30, 26], [30, 35, 15, 38, 24, 18],
                              [18, 20, 26, 12, 22, 24], [15, 18, 25, 10, 20, 21], [20, 22, 24, 14, 21, 25]];
const FEE: [i64; 6] = [40, 25, 15, 8, 6, 7]; // booking fees, pounds thousand
const N: usize = 6;

#[derive(Clone, Copy, PartialEq, PartialOrd)]
struct Q { n: i128, d: i128 } // exact fraction, d > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
fn lt(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }
fn show(x: Q) -> String { if x.d == 1 { format!("{}", x) } else { format!("{} = {}", x, x.n as f64 / x.d as f64) } }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "no" } } fn whole01(x: &[Q]) -> bool { x.iter().all(|v| v.d == 1 && (v.n == 0 || v.n == 1)) }

fn assignment_matrix(n: usize) -> Vec<Vec<i64>> { // n act rows, then n slot rows
    let mut a: Vec<Vec<i64>> = (0..n).map(|i| (0..n * n).map(|k| (k / n == i) as i64).collect()).collect();
    a.extend((0..n).map(|j| (0..n * n).map(|k| (k % n == j) as i64).collect::<Vec<i64>>()));
    a
}

fn det(m0: &[Vec<i64>]) -> i64 { // fraction-free elimination
    let (mut m, mut sign, mut prev, n) = (m0.to_vec(), 1, 1, m0.len());
    for k in 0..n - 1 {
        let p = match (k..n).find(|&i| m[i][k] != 0) { Some(p) => p, None => return 0 };
        if p != k { m.swap(k, p); sign = -sign; }
        for i in k + 1..n { for j in k + 1..n { m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev; } }
        prev = m[k][k];
    }
    sign * m[n - 1][n - 1]
}

// max c.x with A x <= b, x >= 0, b >= 0; tableau in exact fractions, Bland's rule.
fn simplex(a: &[Vec<i64>], b: &[i64], c: &[i64]) -> (Vec<Q>, Q, Vec<Q>, usize, bool, bool) {
    let (m, n) = (a.len(), a[0].len());
    let full: Vec<Vec<i64>> = (0..m).map(|i| { let mut r = a[i].clone(); r.extend((0..m).map(|k| (k == i) as i64)); r }).collect();
    let mut t: Vec<Vec<Q>> = (0..m).map(|i| full[i].iter().map(|&v| q(v as i128, 1)).chain([q(b[i] as i128, 1)]).collect()).collect();
    let mut z: Vec<Q> = c.iter().map(|&v| q(-v as i128, 1)).chain((0..=m).map(|_| q(0, 1))).collect();
    let (mut basis, mut pivots, mut whole, mut unit): (Vec<usize>, usize, bool, bool) = ((n..n + m).collect(), 0, true, true);
    while let Some(e) = (0..n + m).find(|&j| z[j].n < 0) {
        let mut r = usize::MAX;
        for i in (0..m).filter(|&i| t[i][e].n > 0) {
            if r == usize::MAX { r = i; continue; }
            let (ri, rr) = (t[i][n + m] / t[i][e], t[r][n + m] / t[r][e]);
            if lt(ri, rr) || (ri == rr && basis[i] < basis[r]) { r = i; }
        }
        let p = t[r][e];
        t[r] = t[r].iter().map(|&v| v / p).collect();
        let pr = t[r].clone();
        for i in (0..m).filter(|&i| i != r) { let f = t[i][e]; t[i] = t[i].iter().zip(&pr).map(|(&x, &y)| x - f * y).collect(); }
        let f = z[e]; z = z.iter().zip(&pr).map(|(&x, &y)| x - f * y).collect();
        basis[r] = e; pivots += 1;
        whole &= t.iter().all(|row| row[n + m].d == 1);
        let bm: Vec<Vec<i64>> = (0..m).map(|i| basis.iter().map(|&j| full[i][j]).collect()).collect();
        unit &= det(&bm).abs() == 1;
    }
    let mut x = vec![q(0, 1); n + m]; for (i, &j) in basis.iter().enumerate() { x[j] = t[i][n + m]; }
    (x[..n].to_vec(), z[n + m], z[n..n + m].to_vec(), pivots, whole, unit)
}

fn perms(k: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if k == N { out.push(cur.clone()); return; }
    for j in 0..N { if !cur.contains(&j) { cur.push(j); perms(k + 1, cur, out); cur.pop(); } }
}
fn combos(n: usize, s: usize) -> Vec<Vec<usize>> {
    if s == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for last in s - 1..n { for mut c in combos(last, s - 1) { c.push(last); out.push(c); } }
    out
}
fn search(i: usize, used: &mut Vec<bool>, spent: i64, got: i64, budget: i64, best: &mut (i64, usize)) {
    if i == N { best.0 = best.0.max(got); best.1 += 1; return; }
    search(i + 1, used, spent, got, budget, best);
    for j in 0..N {
        if !used[j] && spent + FEE[i] <= budget { used[j] = true; search(i + 1, used, spent + FEE[i], got + VALUE[i][j], budget, best); used[j] = false; }
    }
}

fn main() {
    println!("slots: {}", SLOTS.join(", "));
    for i in 0..N { println!("{:<11} fee {:>2}, values {}", ACTS[i], FEE[i], VALUE[i].map(|v| v.to_string()).join(" ")); }
    let a = assignment_matrix(N);
    let c: Vec<i64> = (0..N * N).map(|k| VALUE[k / N][k % N]).collect();
    let ones = vec![1i64; 2 * N];
    let (x, val, y, piv, whole, unit) = simplex(&a, &ones, &c);
    println!("LP relaxation by simplex: {} pivots from the empty plan, value {}", piv, show(val));
    println!("every corner on the way whole: {} | every basis determinant +1 or -1: {}", yes(whole), yes(unit));
    let plan: Vec<(usize, usize)> = (0..N * N).filter(|&k| x[k].n != 0).map(|k| (k / N, k % N)).collect();
    for &(i, j) in &plan { println!("  {:<11} -> {:<14} x = {}  value {}", ACTS[i], SLOTS[j], x[i * N + j], VALUE[i][j]); }
    let mut all = vec![]; perms(0, &mut vec![], &mut all);
    let tot = |cc: &[i64], p: &[usize]| -> i64 { (0..N).map(|i| cc[i * N + p[i]]).sum() };
    let mut totals: Vec<i64> = all.iter().map(|p| tot(&c, p)).collect(); totals.sort();
    let best_p = all.iter().max_by_key(|p| tot(&c, p)).unwrap();
    println!("all {} whole plans: best {}, runner-up {}, worst {}", all.len(), totals[719], totals[718], totals[0]);
    let (u, v, ys) = (&y[..N], &y[N..], y.iter().fold(q(0, 1), |s, &w| s + w));
    let js = |w: &[Q]| w.iter().map(|z| z.to_string()).collect::<Vec<_>>().join(" ");
    println!("dual prices, acts:  {} | slots: {} | total {}", js(u), js(v), ys);
    let dual_ok = (0..N).all(|i| (0..N).all(|j| !lt(u[i] + v[j], q(VALUE[i][j] as i128, 1)))) && y.iter().all(|w| w.n >= 0);
    println!("every act price + slot price >= that pair's value: {}", yes(dual_ok));
    println!("price checks: {}", [(0, 1), (1, 1)].map(|(i, j): (usize, usize)| format!("{} + {} {} + {} >= {}", ACTS[i], SLOTS[j], u[i], v[j], VALUE[i][j])).join("; "));
    assert!(whole01(&x) && plan.len() == N); // the LP answer is whole
    assert!(val == q(totals[719] as i128, 1) && val == ys && dual_ok && lt(q(totals[718] as i128, 1), val));
    assert!(whole && unit && plan.iter().map(|&(_, j)| j).collect::<Vec<_>>() == *best_p);

    // ---- the matrix itself ----
    let cols_ok = (0..N * N).all(|k| (0..2 * N).filter(|&i| a[i][k] != 0).collect::<Vec<_>>() == vec![k / N, N + k % N]);
    println!("table A: {} rows x {} columns, plus {} slack columns; each column has one 1 in an act row and one in a slot row: {}", a.len(), a[0].len(), a.len(), yes(cols_ok));
    let a3 = assignment_matrix(3); let mut count: BTreeMap<i64, usize> = BTreeMap::new();
    for s in 1..=6 { for r in combos(6, s) { for cc in combos(9, s) {
        let sub: Vec<Vec<i64>> = r.iter().map(|&i| cc.iter().map(|&j| a3[i][j]).collect()).collect();
        *count.entry(det(&sub)).or_insert(0) += 1;
    } } }
    let total: usize = count.values().sum(); println!("3 acts x 3 slots: {} square submatrices; determinants {}", total,
             count.iter().map(|(d, k)| format!("{}: {}", d, k)).collect::<Vec<_>>().join(", "));
    assert!(cols_ok && count.keys().cloned().collect::<Vec<_>>() == vec![-1, 0, 1] && total == 5004);

    // ---- what breaks ----
    let tri = vec![vec![1, 0, 1], vec![1, 1, 0], vec![0, 1, 1]]; // duets: rows Folk, Brass, Singer
    let (xt, vt, ..) = simplex(&tri, &[1, 1, 1], &[1, 1, 1]);
    let best_t = (0..8).map(|s: usize| [s & 1, (s >> 1) & 1, (s >> 2) & 1])
        .filter(|s| tri.iter().all(|r| (0..3).map(|k| r[k] * s[k] as i64).sum::<i64>() <= 1)).map(|s| s.iter().sum::<usize>()).max().unwrap();
    let cram: Vec<i64> = (0..3).map(|k| det(&tri.iter().map(|r| (0..3).map(|j| if j == k { 1 } else { r[j] }).collect()).collect::<Vec<Vec<i64>>>())).collect(); // B_k: column k -> b
    println!("duet triangle: determinant {}, Cramer det(B_k) {}, LP x = {}, value {}, best whole {}", det(&tri), cram.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(" "), js(&xt), show(vt), best_t);
    assert!(det(&tri) == 2 && vt == q(3, 2) && best_t == 1 && (0..3).all(|k| xt[k] == q(cram[k] as i128, det(&tri) as i128)));

    let budget_case = |bud: i64| {
        let mut ab = a.clone(); ab.push((0..N * N).map(|k| FEE[k / N]).collect());
        let mut bb = ones.clone(); bb.push(bud);
        let (xb, vb, ..) = simplex(&ab, &bb, &c);
        let mut best = (0, 0); search(0, &mut vec![false; N], 0, 0, bud, &mut best);
        (xb, vb, best)
    };
    let (xb, vb, (bw, nplans)) = budget_case(80);
    let frac: Vec<String> = (0..N * N).filter(|&k| xb[k].d > 1).map(|k| format!("{}/{} {}", ACTS[k / N], SLOTS[k % N], xb[k])).collect();
    println!("budget 80: LP value {}; fractional: {}", show(vb), frac.join("; "));
    let rnd: Vec<usize> = (0..N * N).filter(|&k| lt(q(1, 2), xb[k])).collect();
    let (r_val, r_fee): (i64, i64) = (rnd.iter().map(|&k| c[k]).sum(), rnd.iter().map(|&k| FEE[k / N]).sum());
    println!("budget 80: best whole {} over {} plans within budget; LP rounded to nearest {} (fees {})", bw, nplans, r_val, r_fee);
    assert!(!frac.is_empty() && r_val < bw && lt(q(bw as i128, 1), vb) && r_fee <= 80 && vb == q(1449, 8));

    // ---- try changing ----
    let mut c2 = c.clone(); c2[4 * N + 2] = 15; // Brass on Sun main worth 15, not 25
    let (x2, v2, ..) = simplex(&a, &ones, &c2);
    let (x3, v3, _) = budget_case(101);
    let mut b4 = ones.clone(); b4[N + 1] = 2; // Sat main takes a double bill
    let (x4, v4, ..) = simplex(&a, &b4, &c);
    let mut c5 = c.clone(); c5[5 * N + 4] = 23; // Singer on Sat tent worth 23: a tie
    let (x5, v5, ..) = simplex(&a, &ones, &c5);
    let ties: Vec<&Vec<usize>> = all.iter().filter(|p| q(tot(&c5, p) as i128, 1) == v5).collect();
    let mid: Vec<Q> = (0..N * N).map(|k| q(ties.iter().filter(|p| p[k / N] == k % N).count() as i128, ties.len() as i128)).collect(); // halfway point
    let dot = |r: &[i64]| (0..N * N).fold(q(0, 1), |s, k| s + q(r[k] as i128, 1) * mid[k]);
    let (mval, room) = (dot(&c5), a.iter().map(|r| dot(r)).fold(q(0, 1), |m, v| if lt(m, v) { v } else { m }));
    for (name, xx, vv) in [("Brass/Sun main 15", &x2, v2), ("budget 101", &x3, v3), ("Sat main double bill", &x4, v4), ("Singer/Sat tent 23", &x5, v5)] {
        println!("try {}: LP value {}, whole: {}", name, show(vv), yes(whole01(xx)));
    }
    println!("try Singer/Sat tent 23: {} whole plans tie at {}; halfway between them: {} x values at 1/2, value {}, fullest row {}", ties.len(), v5, mid.iter().filter(|&&m| m == q(1, 2)).count(), mval, room);
    assert!(whole01(&x2) && whole01(&x4) && whole01(&x5) && v3 == val && ties.len() == 2 && mval == v5 && mid.contains(&q(1, 2)) && room == q(1, 1));
    println!("ALL CHECKS PASS");
}
