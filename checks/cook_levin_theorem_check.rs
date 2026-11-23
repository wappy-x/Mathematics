// Cook-Levin: write a checker's whole run as clauses (an AND of ORs), then test it.
// The tape machine follows the Turing-machines card: state, read, write, move, next.
const DIG: &[u8] = b"1234"; const SYM: &[u8] = b"1234X#";
const ST: [&str; 8] = ["P", "C1", "C2", "C3", "C4", "B", "A", "R"]; const W: usize = 5;
const ROW: &[u8] = b"1__4#"; // top row of a 4 by 4 sudoku; _ is an empty square
type Row = (usize, usize, Vec<u8>); // state number, head, tape
use std::sync::atomic::{AtomicUsize, Ordering::Relaxed}; static BRANCHES: AtomicUsize = AtomicUsize::new(0); // branches the solver has taken so far

fn delta(q: usize, s: u8) -> Option<(u8, i64, usize)> { // (write, move, next); None = no rule
    let dig = DIG.contains(&s);
    match q {
        0 if dig => Some((b'X', 1, (s - b'0') as usize)),
        0 if s == b'#' => Some((b'#', -1, 6)),
        1..=4 if dig => Some(if s - b'0' != q as u8 { (s, 1, q) } else { (s, 1, 7) }),
        1..=4 if s == b'#' => Some((b'#', -1, 5)),
        5 if dig => Some((s, -1, 5)),
        5 if s == b'X' => Some((b'X', 1, 0)),
        _ => None,
    }
}
fn run(tape: &[u8], t: usize) -> (Vec<Row>, bool) { // road 1: run the machine; A and R stay put
    let (mut tape, mut q, mut h, mut rows) = (tape.to_vec(), 0usize, 0usize, vec![]);
    for i in 0..=t {
        rows.push((q, h, tape.clone()));
        if q >= 6 || i == t { continue; }
        let Some((b, m, q2)) = delta(q, tape[h]) else { return (rows, false) };
        tape[h] = b; h = (h as i64 + m) as usize; q = q2;
    }
    (rows, q == 6)
}
fn per() -> usize { W * SYM.len() + 8 + W }
fn vc(i: usize, j: usize, s: usize) -> i64 { (i * per() + j * SYM.len() + s + 1) as i64 }
fn vq(i: usize, q: usize) -> i64 { (i * per() + W * SYM.len() + q + 1) as i64 }
fn vh(i: usize, j: usize) -> i64 { (i * per() + W * SYM.len() + 8 + j + 1) as i64 }
fn si(s: u8) -> usize { SYM.iter().position(|&x| x == s).unwrap() }
fn formula(t: usize, cert: &[u8], frame: bool, accept: bool) -> (usize, Vec<Vec<i64>>) {
    let mut c: Vec<Vec<i64>> = vec![];
    let one = |c: &mut Vec<Vec<i64>>, xs: Vec<i64>| { c.push(xs.clone()); // exactly one: at least one, and no two
        for a in 0..xs.len() { for b in a + 1..xs.len() { c.push(vec![-xs[a], -xs[b]]); } }
    };
    for i in 0..=t {
        for j in 0..W { one(&mut c, (0..SYM.len()).map(|s| vc(i, j, s)).collect()); }
        one(&mut c, (0..8).map(|q| vq(i, q)).collect());
        one(&mut c, (0..W).map(|j| vh(i, j)).collect());
    }
    c.push(vec![vq(0, 0)]); c.push(vec![vh(0, 0)]);
    for (j, &s) in ROW.iter().enumerate() { // start row: givens fixed, empty squares from cert
        c.push(if s != b'_' { vec![vc(0, j, si(s))] } else { cert.iter().map(|&d| vc(0, j, si(d))).collect() });
    }
    for i in 0..t { for j in 0..W { for q in 0..8 { for (s, &sy) in SYM.iter().enumerate() {
        let pre = vec![-vh(i, j), -vq(i, q), -vc(i, j, s)];
        let r = if q >= 6 { Some((sy, 0, q)) } else { delta(q, sy) };
        let j2 = j as i64 + r.map_or(0, |x| x.1);
        match r {
            Some((b, _, q2)) if j2 >= 0 && (j2 as usize) < W => for x in [vc(i + 1, j, si(b)), vq(i + 1, q2), vh(i + 1, j2 as usize)] {
                let mut cl = pre.clone(); cl.push(x); c.push(cl);
            },
            _ => c.push(pre),
        }
    }}}}
    for i in 0..t { for j in 0..W { for s in 0..SYM.len() { // frame: a cell away from the head keeps its symbol
        if frame { c.push(vec![vh(i, j), -vc(i, j, s), vc(i + 1, j, s)]); }
    }}}
    if accept { c.push(vec![vq(t, 6)]); }
    ((t + 1) * per(), c)
}
struct Solver<'a> { c: &'a Vec<Vec<i64>>, occ: Vec<Vec<usize>>, val: Vec<i8>, models: Vec<Vec<i8>>, limit: usize }
impl<'a> Solver<'a> { // roads 2 and 3: a small SAT solver that counts models
    fn lit(&self, y: i64) -> i8 { let v = self.val[y.unsigned_abs() as usize]; if v < 0 { -1 } else { (v == 1) as i8 ^ (y < 0) as i8 } }
    fn key(x: i64) -> usize { (2 * x.unsigned_abs() as usize) + (x < 0) as usize }
    fn setlit(&mut self, x: i64, trail: &mut Vec<usize>) -> bool { // make x true, then follow every forced literal
        let mut stack = vec![x];
        while let Some(x) = stack.pop() {
            let a = x.unsigned_abs() as usize;
            if self.val[a] >= 0 { if (self.val[a] == 1) != (x > 0) { return false; } continue; }
            self.val[a] = (x > 0) as i8; trail.push(a);
            for &k in &self.occ[Self::key(x)] {
                if self.c[k].iter().any(|&y| self.lit(y) == 1) { continue; }
                let free: Vec<i64> = self.c[k].iter().cloned().filter(|&y| self.lit(y) < 0).collect();
                if free.is_empty() { return false; }
                if free.len() == 1 { stack.push(free[0]); }
            }
        }
        true
    }
    fn go(&mut self, n: usize) {
        if self.models.len() >= self.limit { return; }
        match (n..self.val.len()).find(|&a| self.val[a] < 0) {
            None => self.models.push(self.val.clone()),
            Some(x) => { BRANCHES.fetch_add(1, Relaxed); for lit in [x as i64, -(x as i64)] { // a branch: try x true, then x false
                let mut trail = vec![];
                if self.setlit(lit, &mut trail) { self.go(x + 1); }
                for a in trail { self.val[a] = -1; }
            }},
        }
    }
}
fn solve(nv: usize, c: &Vec<Vec<i64>>, fix: &[i64], limit: usize) -> Vec<Vec<i8>> {
    let mut occ = vec![vec![]; 2 * nv + 2];
    for (k, cl) in c.iter().enumerate() { for &x in cl { occ[Solver::key(-x)].push(k); } }
    let mut s = Solver { c, occ, val: vec![-1; nv + 1], models: vec![], limit };
    let units: Vec<i64> = c.iter().filter(|cl| cl.len() == 1).map(|cl| cl[0]).chain(fix.iter().cloned()).collect();
    if units.iter().all(|&x| s.setlit(x, &mut vec![])) { s.go(1); }
    s.models
}
fn bound(t: usize, w: usize, s: usize, q: usize) -> usize { // clause count from the recipe, without building anything
    let one = |m: usize| 1 + m * (m - 1) / 2;
    (t + 1) * (w * one(s) + one(q) + one(w)) + t * w * s * (3 * q + 1) + 2 + w + 1
}
fn pairs(a: &[u8]) -> Vec<[u8; 2]> { a.iter().flat_map(|&x| a.iter().map(move |&y| [x, y])).collect() }
fn row_of(p: [u8; 2]) -> Vec<u8> { let mut k = 0; ROW.iter().map(|&x| if x == b'_' { k += 1; p[k - 1] } else { x }).collect() } fn st(p: &[u8]) -> String { String::from_utf8(p.to_vec()).unwrap() }
fn sat_fillings(f: &(usize, Vec<Vec<i64>>), alphabet: &[u8]) -> Vec<String> { // fillings whose formula is satisfiable
    pairs(alphabet).into_iter().filter(|p| !solve(f.0, &f.1, &[vc(0, 1, si(p[0])), vc(0, 2, si(p[1]))], 1).is_empty()).map(|p| st(&p)).collect()
}
fn assign(nv: usize, tab: &[Row]) -> Vec<i8> { // the variables that a table of rows makes true
    let mut a = vec![0i8; nv + 1];
    for (i, (q, h, t)) in tab.iter().enumerate() {
        a[vq(i, *q) as usize] = 1; a[vh(i, *h) as usize] = 1; for (j, &s) in t.iter().enumerate() { a[vc(i, j, si(s)) as usize] = 1; }
    }
    a
}
fn holds(c: &[Vec<i64>], a: &[i8]) -> bool { c.iter().all(|cl| cl.iter().any(|&x| (a[x.unsigned_abs() as usize] == 1) == (x > 0))) }
fn main() {
    let t = run(b"1234#", 99).0.iter().position(|r| r.0 == 6).unwrap();
    println!("machine: 8 states, 6 tape symbols; row {} ; steps to accept: {}", st(&ROW[..4]), t);
    println!("the run on the row 1 2 3 4, one row per step:");
    for (i, (q, h, tape)) in run(b"1234#", t).0.iter().enumerate() {
        let cells: String = tape.iter().enumerate().map(|(k, &c)| if k == *h { format!("[{}]", c as char) } else { format!(" {} ", c as char) }).collect();
        println!("{}", format!("step {:2} state {:2} tape {}", i, ST[*q], cells).trim_end());
    }
    let (nv, c) = formula(t, DIG, true, true); let cl: Vec<usize> = c.iter().map(|x| x.len()).collect();
    println!("variables {} clauses {} literals {}", nv, c.len(), cl.iter().sum::<usize>());
    let mut lens: Vec<usize> = cl.clone(); lens.sort(); lens.dedup();
    println!("clauses by length: {}", lens.iter().map(|&k| format!("{}: {}", k, cl.iter().filter(|&&x| x == k).count())).collect::<Vec<_>>().join(", "));
    let cnt = |f: &dyn Fn(&Vec<i64>) -> bool| c.iter().filter(|x| f(x)).count(); let acc = cnt(&|x| *x == vec![vq(t, 6)]);
    let fam = [cnt(&|x| (x.len() == 2 && x[0] < 0) || (*x.iter().min().unwrap() > 0 && x.len() >= 5)), cnt(&|x| *x.iter().min().unwrap() > 0 && x.len() <= 4) - acc,
        cnt(&|x| x.len() == 4 && x[0] < 0), cnt(&|x| x.len() == 3 && *x.iter().max().unwrap() < 0), cnt(&|x| x.len() == 3 && x[0] > 0), acc];
    println!("families: exactly-one {} start {} rule {} forbidden {} frame {} accept {}", fam[0], fam[1], fam[2], fam[3], fam[4], fam[5]);
    println!("recipe bound on clauses {} built {}", bound(t, W, 6, 8), c.len());
    let direct: Vec<String> = pairs(DIG).into_iter().filter(|&p| run(&row_of(p), t).1).map(|p| st(&p)).collect();
    println!("road 1, run the machine on all 16 fillings: accepted {}", direct.join(" "));
    let fixed = sat_fillings(&(nv, c.clone()), DIG); let branched = BRANCHES.load(Relaxed);
    println!("road 2, formula with each filling fixed: satisfiable {} ; solver branches {}", fixed.join(" "), branched);
    let models = solve(nv, &c, &[], usize::MAX);
    let read: Vec<String> = models.iter().map(|m| (1..3).map(|j| DIG.iter().find(|&&d| m[vc(0, j, si(d)) as usize] == 1).map(|&d| d as char).unwrap()).collect()).collect();
    println!("road 3, formula left free: satisfying assignments {} read back as {}", models.len(), read.join(" "));
    for n in [10, 100, 1000] { let w = 2 * n + 1; println!("growth: {n} steps on {w} cells: variables {}, clauses at most {}", (n + 1) * (7 * w + 8), bound(n, w, 6, 8)); }
    let mut sr = read.clone(); sr.sort();
    assert!(direct == fixed && fixed == sr && sr == ["23", "32"] && models.len() == 2 && branched == 0);
    assert!(nv == (t + 1) * (6 * W + 8 + W) && bound(t, W, 6, 8) == c.len() + 2 * fam[3] && fam.iter().sum::<usize>() == c.len());
    for (m, filling) in models.iter().zip(&read) { // each assignment, read row by row, is the machine's own run
        let tab: Vec<Row> = (0..=t).map(|i| ((0..8).find(|&q| m[vq(i, q) as usize] == 1).unwrap(), (0..W).find(|&j| m[vh(i, j) as usize] == 1).unwrap(),
            (0..W).map(|j| SYM[(0..6).find(|&s| m[vc(i, j, s) as usize] == 1).unwrap()]).collect())).collect();
        assert!(tab == run(&row_of([filling.as_bytes()[0], filling.as_bytes()[1]]), t).0);
    }
    let (ns, cs) = formula(t - 1, DIG, true, true); let short = solve(ns, &cs, &[], usize::MAX);
    let anys = sat_fillings(&formula(t, SYM, true, true), SYM);
    let anyrun: Vec<String> = pairs(SYM).into_iter().filter(|&p| run(&row_of(p), t).1).map(|p| st(&p)).collect();
    let noacc = sat_fillings(&formula(t, DIG, true, false), DIG);
    let good = run(b"1234#", t).0;
    let fakes: Vec<Vec<Row>> = pairs(DIG).into_iter().map(|p| { let mut f = vec![(0, 0, row_of(p))]; f.extend(good[1..].iter().cloned()); f }).collect();
    let (nn, cn) = formula(t, DIG, false, true);
    let noframe = fakes.iter().filter(|f| holds(&cn, &assign(nn, f))).count();
    assert!(noframe == 16 && !holds(&c, &assign(nv, &fakes[0])) && holds(&c, &assign(nv, &good)) && anys == anyrun && short.is_empty() && noacc.len() == 16);
    println!("break: step bound {} instead of {} : satisfying assignments {}", t - 1, t, short.len());
    println!("break: empty squares may hold any tape symbol: satisfiable {} of 36: {}", anys.len(), anys.join(" "));
    println!("break: no accept clause: satisfiable fillings {} of 16", noacc.len());
    println!("break: no frame clauses: satisfied by a faked run for {} of 16 fillings", noframe);
    println!("ALL CHECKS PASS");
}
