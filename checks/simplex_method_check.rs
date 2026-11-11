// The simplex method -- the check behind the card.  std only, no crates.
// Exact fractions from a small rational type.  Roads to the answer: the tableau
// walk; the prices read off its last row, checked against every limit; every
// corner of the region listed by crossing pairs of walls.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }

fn show(v: Q, dec: u32) -> String { // whole number, short decimal, or a/b
    for k in 0..dec {
        let p = 10i128.pow(k);
        if (v.n * p) % v.d == 0 {
            let s = format!("{:0>w$}", ((v.n * p) / v.d).abs(), w = k as usize + 1);
            let body = if k > 0 { format!("{}.{}", &s[..s.len() - k as usize], &s[s.len() - k as usize..]) } else { s };
            return format!("{}{}", if v.n < 0 { "-" } else { "" }, body);
        }
    }
    format!("{}/{}", v.n, v.d)
}
fn sh(v: Q) -> String { show(v, 4) }

type Tab = (Vec<Vec<Q>>, Vec<Q>, Vec<usize>);
fn start(a: &[Vec<Q>], b: &[Q], c: &[Q]) -> Tab {
    let (m, n) = (a.len(), c.len());
    let t = (0..m).map(|i| { let mut r = a[i].clone(); for k in 0..m { r.push(z((i == k) as i128)); } r.push(b[i]); r }).collect();
    let mut zr: Vec<Q> = c.iter().map(|&v| z(0) - v).collect();
    zr.extend(vec![z(0); m + 1]);
    (t, zr, (n..n + m).collect())
}
fn pivot(s: &mut Tab, r: usize, j: usize) { // row r's basic variable leaves, column j enters
    let p = s.0[r][j];
    s.0[r] = s.0[r].iter().map(|&v| v / p).collect();
    let pr = s.0[r].clone();
    for i in 0..s.0.len() { if i != r { let f = s.0[i][j]; s.0[i] = s.0[i].iter().zip(&pr).map(|(&a, &b)| a - f * b).collect(); } }
    let f = s.1[j];
    s.1 = s.1.iter().zip(&pr).map(|(&a, &b)| a - f * b).collect();
    s.2[r] = j;
}
fn point(s: &Tab, n: usize) -> Vec<Q> {
    let mut x = vec![z(0); n];
    for (i, &bv) in s.2.iter().enumerate() { if bv < n { x[bv] = *s.0[i].last().unwrap(); } }
    x
}
const NAME: [&str; 5] = ["t", "c", "s1", "s2", "s3"];
fn table(s: &Tab) {
    for i in 0..=s.0.len() {
        let row = if i < s.0.len() { &s.0[i] } else { &s.1 };
        let lab = if i < s.0.len() { NAME[s.2[i]] } else { "z" };
        let cells: Vec<String> = row[..row.len() - 1].iter().map(|&v| format!("{:>5}", show(v, 1))).collect();
        println!("  {:>2} | {} | {}", lab, cells.join(" "), sh(*row.last().unwrap()));
    }
}
struct Step { best: Q, zv: Q, x: Vec<Q>, out: usize }
fn simplex(a: &[Vec<Q>], b: &[Q], c: &[Q], dantzig: bool, low: bool, say: bool) -> (Tab, Vec<Step>, String) {
    let mut s = start(a, b, c);
    let (n, m) = (c.len(), a.len());
    let mut log: Vec<Step> = vec![];
    let mut seen = vec![{ let mut v = s.2.clone(); v.sort(); v }];
    while log.len() < 60 {
        let neg: Vec<usize> = (0..n + m).filter(|&j| s.1[j] < z(0)).collect(); // columns that still raise profit
        if neg.is_empty() { return (s, log, "optimal".to_string()); }
        let j = if dantzig { *neg.iter().min_by(|&&p, &&k| s.1[p].cmp(&s.1[k]).then(p.cmp(&k))).unwrap() } else { neg[0] };
        let rat: Vec<Option<Q>> = (0..m).map(|i| if s.0[i][j] > z(0) { Some(*s.0[i].last().unwrap() / s.0[i][j]) } else { None }).collect();
        let best = rat.iter().flatten().min().copied().unwrap(); // ratio test
        let ties: Vec<usize> = (0..m).filter(|&i| rat[i] == Some(best)).collect();
        let r = if low { *ties.iter().min_by_key(|&&i| s.2[i]).unwrap() } else { *ties.iter().max_by_key(|&&i| s.2[i]).unwrap() };
        let out = s.2[r];
        pivot(&mut s, r, j);
        log.push(Step { best, zv: *s.1.last().unwrap(), x: point(&s, n + m), out });
        if say {
            let rs: Vec<String> = rat.iter().map(|r| r.map_or("-".to_string(), sh)).collect();
            println!("pivot {}: {} enters; ratios {}{}; {} leaves; point ({}, {}); profit {}", log.len(), NAME[j], rs.join(", "),
                if ties.len() > 1 { "; tie" } else { "" }, NAME[out], sh(log.last().unwrap().x[0]), sh(log.last().unwrap().x[1]), sh(s.1[5]));
            table(&s);
        }
        let mut key = s.2.clone(); key.sort();
        if let Some(p) = seen.iter().position(|k| *k == key) { return (s, log, format!("back to the basis of pivot {}", p)); }
        seen.push(key);
    }
    (s, log, "cap".to_string())
}
fn qm(v: &[&[i128]]) -> Vec<Vec<Q>> { v.iter().map(|r| r.iter().map(|&x| z(x)).collect()).collect() }
fn qv(v: &[i128]) -> Vec<Q> { v.iter().map(|&x| z(x)).collect() }
fn path(l: &[Step]) -> String { l.iter().map(|s| format!("({}, {}) {}", sh(s.x[0]), sh(s.x[1]), sh(s.zv))).collect::<Vec<_>>().join(" -> ") }

fn main() {
    let (a, b, c) = (qm(&[&[4, 2], &[3, 1], &[1, 2]]), qv(&[160, 120, 64]), qv(&[19, 20]));
    println!("maximise 19 t + 20 c pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l");
    println!("columns:   t     c    s1    s2    s3 | right side");
    println!("tableau k=0: point (0, 0); profit 0");
    table(&start(&a, &b, &c));
    let (s, log, st) = simplex(&a, &b, &c, false, false, true);
    let (x, y) = (point(&s, 2), s.1[2..5].to_vec()); // prices sit under the slack columns
    let steps: Vec<String> = log.iter().map(|l| sh(l.best)).collect();
    println!("stop: {} after {} pivots; steps {}; make {} tables, {} chairs, profit {}", st, log.len(), steps.join(", "), sh(x[0]), sh(x[1]), sh(s.1[5]));
    let bound = (0..3).fold(z(0), |acc, i| acc + b[i] * y[i]);
    let terms: Vec<String> = (0..3).map(|i| format!("{}*{}", sh(b[i]), sh(y[i]))).collect();
    println!("prices: timber {}, labour {}, finish {}; bound {} = {}", sh(y[0]), sh(y[1]), sh(y[2]), terms.join(" + "), sh(bound));
    let cover: Vec<Q> = (0..2).map(|j| (0..3).fold(z(0), |acc, i| acc + a[i][j] * y[i])).collect();
    println!("prices cover each profit: tables {} >= 19, chairs {} >= 20", sh(cover[0]), sh(cover[1]));
    let walls = qm(&[&[4, 2], &[3, 1], &[1, 2], &[-1, 0], &[0, -1]]);
    let lims = qv(&[160, 120, 64, 0, 0]);
    let mut corners: Vec<((Q, Q), Q)> = vec![];
    for p in 0..5 { for r in p + 1..5 { // cross every pair of walls
        let (a1, a2, a3, a4) = (walls[p][0], walls[p][1], walls[r][0], walls[r][1]);
        let d = a1 * a4 - a2 * a3;
        if d == z(0) { continue; }
        let pt = ((lims[p] * a4 - a2 * lims[r]) / d, (a1 * lims[r] - lims[p] * a3) / d);
        if (0..5).all(|w| walls[w][0] * pt.0 + walls[w][1] * pt.1 <= lims[w]) && !corners.iter().any(|k| k.0 == pt) {
            corners.push((pt, z(19) * pt.0 + z(20) * pt.1));
        }
    } }
    corners.sort();
    let cs: Vec<String> = corners.iter().map(|(p, v)| format!("({}, {}) {}", sh(p.0), sh(p.1), sh(*v))).collect();
    println!("corners: {}", cs.join("; "));
    let tight = (0..5).filter(|&w| walls[w][0] * z(40) == lims[w]).count();
    println!("walls tight at (40, 0): {} for 2 unknowns, so the corner is degenerate; {} ways to pick 3 basic columns of 5", tight, (5 * 4 * 3) / (3 * 2));
    let (sd, ld, _) = simplex(&a, &b, &c, true, false, false);
    println!("Dantzig's rule: {}; {} pivots", path(&ld), ld.len());
    let (_, lb, _) = simplex(&a, &b, &c, false, true, false);
    println!("tie broken by timber: {}; {} pivots; after pivot 1, {} has left and s2 = {}", path(&lb), lb.len(), NAME[lb[0].out], sh(lb[0].x[3]));
    let mut tm = start(&a, &b, &c);
    pivot(&mut tm, 2, 0); // skip the ratio test: finish leaves
    println!("break, no ratio test: point ({}, 0), timber slack {}, labour slack {}, claimed profit {}", sh(tm.0[2][5]), sh(tm.0[0][5]), sh(tm.0[1][5]), sh(tm.1[5]));
    let first0 = log.iter().find(|l| l.best == z(0)).unwrap();
    println!("break, stop at the step-0 pivot: profit {}, short by {}", sh(first0.zv), sh(s.1[5] - first0.zv));
    let ba = vec![vec![q(1, 4), z(-8), z(-1), z(9)], vec![q(1, 2), z(-12), q(-1, 2), z(3)], qv(&[0, 0, 1, 0])];
    let (bb, bc) = (qv(&[0, 0, 1]), vec![q(3, 4), z(-20), q(1, 2), z(-6)]);
    let (_, lbe, sbe) = simplex(&ba, &bb, &bc, true, true, false);
    let (tb, lbl, sbl) = simplex(&ba, &bb, &bc, false, true, false);
    let pe: Vec<String> = lbe.iter().map(|l| sh(l.zv)).collect();
    println!("Beale, Dantzig's rule: profit after each pivot {}; {}", pe.join(", "), sbe);
    let (xb, yb) = (point(&tb, 4), tb.1[4..7].to_vec());
    let js = |v: &[Q]| v.iter().map(|&w| sh(w)).collect::<Vec<_>>().join(", ");
    println!("Beale, Bland's rule: {} after {} pivots, profit {}, x = ({}), prices ({})", sbl, lbl.len(), sh(tb.1[7]), js(&xb), js(&yb));
    let (ka, kb, kc) = (qm(&[&[1, 0, 0], &[20, 1, 0], &[200, 20, 1]]), qv(&[1, 100, 10000]), qv(&[100, 10, 1]));
    let (sk, lk, _) = simplex(&ka, &kb, &kc, true, false, false);
    println!("Klee-Minty cube, 3 variables, Dantzig's rule: {} pivots to profit {}", lk.len(), sh(sk.1[6]));
    for (lab, b2) in [("finish 70 l", [160, 120, 70]), ("labour 130 h", [160, 130, 64])] {
        let (st2, lt, _) = simplex(&a, &qv(&b2), &c, false, false, false);
        let xt = point(&st2, 2);
        println!("try {}: ({}, {}), profit {}, {} pivots, {} with step 0", lab, sh(xt[0]), sh(xt[1]), sh(st2.1[5]), lt.len(), lt.iter().filter(|l| l.best == z(0)).count());
    }
    let fc: Vec<String> = corners.iter().map(|(p, _)| format!("({},{})", sh(z(50) + z(5) * p.0), sh(z(225) - z(5) * p.1))).collect();
    println!("figure, px = 50 + 5*t, py = 225 - 5*c: corners {}; timber to (160,45), labour to (190,45), finish to (370,225)", fc.join(" "));

    let best = corners.iter().map(|k| k.1).max().unwrap();
    assert!(x == qv(&[32, 16]) && s.1[5] == best && best == z(928) && log.len() == 3); // walk meets enumeration
    assert!(y.iter().all(|&v| v >= z(0)) && cover[0] >= z(19) && cover[1] >= z(20)); // prices are a valid bound
    assert!(bound == best); // bound meets the best corner
    assert!(log[1].best == z(0) && log[1].x == log[0].x && tight == 3); // the degenerate pivot
    assert!(sd.1[5] == best && ld.len() == 2 && lb.len() == 2 && lb[0].out == 2 && lb[0].x[3] == z(0));
    assert!(sbe == "back to the basis of pivot 0" && lbe.len() == 6); // cycling without Bland
    let val = (0..4).fold(z(0), |acc, j| acc + bc[j] * xb[j]);
    let dual = (0..3).fold(z(0), |acc, i| acc + bb[i] * yb[i]);
    assert!(sbl == "optimal" && tb.1[7] == val && val == dual && dual == q(5, 4));
    assert!(lk.len() == 7 && sk.1[6] == z(10000));
    println!("ALL CHECKS PASS");
}
