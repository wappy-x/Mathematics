// SAT solvers: a five-a-side league's fixtures as clauses, solved by DPLL.
// std only. Road 1: the solver. Road 2: a direct search over fixture lists
// that knows nothing of clauses. A verifier checks the rules.
use std::collections::HashSet;
struct S { nv: usize, cl: Vec<Vec<i32>>, occ: Vec<Vec<usize>>, order: Vec<usize>, val: Vec<i32>,
    trail: Vec<usize>, dec: u64, prop: u64, units: usize, models: u128, first: Option<Vec<i32>>,
    capped: bool, log: Vec<(i32, u64)>, all: bool, cap: u64, init: u64 }
impl S {
    fn ix(&self, l: i32) -> usize { if l > 0 { l as usize } else { self.nv + (-l) as usize } }
    fn tv(&self, l: i32) -> i32 { let v = self.val[l.unsigned_abs() as usize]; if l > 0 { v } else { -v } }
    fn assign(&mut self, l: i32) { let a = l.unsigned_abs() as usize; self.val[a] = if l > 0 { 1 } else { -1 }; self.trail.push(a); }
    fn propagate(&mut self, mut q: Vec<i32>) -> bool { // a clause with one free literal forces it
        while let Some(l) = q.pop() {
            let k = self.ix(-l);
            for j in 0..self.occ[k].len() {
                let i = self.occ[k][j];
                let (mut free, mut nfree, mut sat) = (0, 0, false);
                for &m in &self.cl[i] { let t = self.tv(m); if t == 1 { sat = true; break; } if t == 0 { nfree += 1; free = m; } }
                if sat { continue; }
                if nfree == 0 { return false; }
                if nfree == 1 { self.assign(free); self.prop += 1; q.push(free); }
            }
        }
        true
    }
    fn pick(&self) -> Option<Vec<i32>> { // unsatisfied clause, fewest free literals, long clauses first
        let mut best: Option<Vec<i32>> = None;
        for &i in &self.order {
            let c = &self.cl[i];
            if best.is_some() && c.len() == 2 { break; }
            if c.iter().any(|&m| self.tv(m) == 1) { continue; }
            let fr: Vec<i32> = c.iter().cloned().filter(|&m| self.tv(m) == 0).collect();
            if best.as_ref().map_or(true, |b| fr.len() < b.len()) { best = Some(fr); }
        }
        best
    }
    fn rec(&mut self) -> bool {
        let b = match self.pick() { None => {
            self.models += 1u128 << (self.nv - self.trail.len());
            if self.first.is_none() { self.first = Some(self.val.clone()); }
            return !self.all; } Some(b) => b };
        for l in [b[0], -b[0]] {
            if self.dec >= self.cap { self.capped = true; return true; }
            self.dec += 1; let mark = self.trail.len(); self.assign(l); let before = self.prop;
            let ok = self.propagate(vec![l]);
            if !self.all { self.log.push((l, self.prop - before)); }
            if ok && self.rec() { return true; }
            while self.trail.len() > mark { let v = self.trail.pop().unwrap(); self.val[v] = 0; }
        }
        false
    }
}
fn solve(nv: usize, cl: &Vec<Vec<i32>>, all: bool, cap: u64) -> S {
    let mut occ = vec![Vec::new(); 2 * nv + 1];
    let mut s = S { nv, cl: cl.clone(), occ: vec![], order: vec![], val: vec![0; nv + 1], trail: vec![], dec: 0, prop: 0,
        units: 0, models: 0, first: None, capped: false, log: vec![], all, cap, init: 0 };
    for (i, c) in cl.iter().enumerate() { for &l in c { occ[s.ix(l)].push(i); } } s.occ = occ;
    s.order = (0..cl.len()).filter(|&i| cl[i].len() > 2).chain((0..cl.len()).filter(|&i| cl[i].len() <= 2)).collect();
    let q: Vec<i32> = cl.iter().filter(|c| c.len() == 1).map(|c| c[0]).collect();
    for &l in &q { s.assign(l); } s.units = q.len();
    if s.propagate(q) { s.init = s.prop; s.rec(); }
    s
}
fn league(n: usize, r_: usize, rules: bool, clash: bool) -> (usize, Vec<Vec<i32>>, Vec<(usize, usize)>) {
    let mut pairs = vec![];
    for a in 0..n { for b in a + 1..n { pairs.push((a, b)); } }
    let pi = |a: usize, b: usize| pairs.iter().position(|&p| p == (a.min(b), a.max(b))).unwrap();
    let x = |a: usize, b: usize, r: usize| (pi(a, b) * r_ + r + 1) as i32;
    let mut cl: Vec<Vec<i32>> = vec![];
    for &(a, b) in &pairs { // every pair meets in some round, and in only one
        cl.push((0..r_).map(|r| x(a, b, r)).collect());
        for r in 0..r_ { for s in r + 1..r_ { cl.push(vec![-x(a, b, r), -x(a, b, s)]); } }
    }
    for t in 0..n {
        let o: Vec<usize> = (0..n).filter(|&u| u != t).collect();
        for r in 0..r_ {
            if clash { for i in 0..o.len() { for j in i + 1..o.len() { cl.push(vec![-x(t, o[i], r), -x(t, o[j], r)]); } } }
            if clash && r_ >= n - 1 { cl.push(o.iter().map(|&u| x(t, u, r)).collect()); } // plays every round
        }
    }
    if rules {
        cl.push(vec![x(0, 1, 4)]); // A-B, the derby, in round 5
        cl.push(vec![x(2, 5, 0)]); // C-F, last season's cup final, in round 1
        for r in [0, 1, 4] { cl.push(vec![-x(3, 4, r)]); } // D-E only in round 3 or 4
        for r in 0..r_ - 1 { cl.push(vec![-x(1, 2, r), -x(1, 3, r + 1)]); cl.push(vec![-x(1, 3, r), -x(1, 2, r + 1)]); }
    }
    (pairs.len() * r_, cl, pairs)
}
type Rounds = Vec<Vec<(usize, usize)>>;
fn fixtures(val: &[i32], pairs: &[(usize, usize)], r_: usize) -> Rounds {
    (0..r_).map(|r| (0..pairs.len()).filter(|&i| val[i * r_ + r + 1] == 1).map(|i| pairs[i]).collect()).collect()
}
fn obeys(rounds: &Rounds) -> bool { // the verifier: reads the rules, never the clauses
    let mut rd = std::collections::HashMap::new();
    for (r, ms) in rounds.iter().enumerate() { for &p in ms { rd.insert(p, r); } }
    let once = rounds.iter().all(|ms| { let mut t: Vec<usize> = ms.iter().flat_map(|p| [p.0, p.1]).collect(); t.sort(); t == (0..6).collect::<Vec<_>>() }) && rd.len() == 15;
    if !once { return false; }
    let (bc, bd) = (rd[&(1, 2)], rd[&(1, 3)]);
    rd[&(0, 1)] == 4 && rd[&(2, 5)] == 0 && (rd[&(3, 4)] == 2 || rd[&(3, 4)] == 3) && bc.abs_diff(bd) != 1
}
fn matchings(free: &[usize], left: &HashSet<(usize, usize)>) -> Rounds {
    if free.is_empty() { return vec![vec![]]; }
    let a = free[0]; let mut out = vec![];
    for &b in &free[1..] { if left.contains(&(a, b)) {
        let rest: Vec<usize> = free.iter().cloned().filter(|&t| t != a && t != b).collect();
        for m in matchings(&rest, left) { let mut v = vec![(a, b)]; v.extend(m); out.push(v); } } }
    out
}
fn all_schedules(left: &HashSet<(usize, usize)>, rounds: &Rounds, out: &mut Vec<Rounds>) { // road 2
    if left.is_empty() { out.push(rounds.clone()); return; }
    for m in matchings(&(0..6).collect::<Vec<_>>(), left) {
        let mut l2 = left.clone(); for p in &m { l2.remove(p); }
        let mut r2 = rounds.clone(); r2.push(m); all_schedules(&l2, &r2, out);
    }
}
fn commas(v: u128) -> String { let s = v.to_string(); let mut o = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(ch); } o }
fn name(p: (usize, usize)) -> String { let t = b"ABCDEF"; format!("{}-{}", t[p.0] as char, t[p.1] as char) }
fn line(ms: &[(usize, usize)]) -> String { ms.iter().map(|&p| name(p)).collect::<Vec<_>>().join(" ") }
fn main() { const NO: u64 = u64::MAX; // no decision cap
    let (nv, cl, pairs) = league(6, 5, true, true);
    println!("league: 6 teams, 5 rounds, {} yes-or-no variables, {} clauses", nv, cl.len());
    println!("assignments a blind search would face: 2^{} = {}", nv, commas(1u128 << nv));
    let base = league(6, 5, false, true).1; let fam = |c: &Vec<i32>| (c.len(), c[0] > 0, c.iter().map(|&l| (l.abs() - 1) / 5).collect::<HashSet<_>>().len()); // size, sign, pairs
    let parts: Vec<usize> = [(5, true, 1), (2, false, 1), (2, false, 2), (5, true, 5)].iter().map(|k| base.iter().filter(|&c| fam(c) == *k).count()).chain([cl.len() - base.len()]).collect();
    println!("clauses: pair meets {} | pair once {} | once a round {} | every round {} | rules {}", parts[0], parts[1], parts[2], parts[3], parts[4]); let s = solve(nv, &cl, false, NO);
    println!("unit clauses set {} variables before any guess, and these force {} more", s.units, s.init);
    for (k, &(l, f)) in s.log.iter().enumerate() {
        let a = l.unsigned_abs() as usize - 1;
        println!("  decision {}: {} in round {} {}, forces {} more", k + 1, name(pairs[a / 5]), a % 5 + 1, if l > 0 { "yes" } else { "no" }, f);
    }
    println!("decisions {}, forced {}, total {} of {}", s.dec, s.prop, s.units as u64 + s.dec + s.prop, nv);
    let rounds = fixtures(s.first.as_ref().unwrap(), &pairs, 5); for (r, ms) in rounds.iter().enumerate() { println!("  round {}: {}", r + 1, line(ms)); }
    println!("verifier, reading the rules not the clauses: every rule kept: {}", if obeys(&rounds) { "yes" } else { "no" });
    assert!(obeys(&rounds));
    let c = solve(nv, &cl, true, NO);
    let mut every = vec![]; all_schedules(&pairs.iter().cloned().collect(), &vec![], &mut every);
    let good = every.iter().filter(|sc| obeys(sc)).count();
    println!("road 2, fixture lists built directly: {} in all, {} keep the rules", every.len(), good);
    println!("road 1, the solver counting every model: {} models in {} decisions", c.models, c.dec);
    assert!(every.len() == 6 * 120 && c.models == good as u128 && good == 9);
    assert!(s.init == 2 * (4 + 4 + 4)); // A-B and C-F each rule out 4 other rounds and 4 + 4 rival matches
    let (nf, clf, _) = league(6, 5, false, true); let free = solve(nf, &clf, true, NO).models; println!("no extra rules: the solver counts {} models", free);
    assert!(free == every.len() as u128);
    let mut pts = vec![]; println!("teams | variables | clauses | in n - 1 rounds: decisions | in n - 2 rounds: decisions, answer");
    for n in [4usize, 6, 8, 10] {
        let a = league(n, n - 1, false, true); let sa = solve(a.0, &a.1, false, NO);
        let b = league(n, n - 2, false, true); let sb = solve(b.0, &b.1, false, NO);
        assert!(sa.models == 1 && sb.models == 0);
        println!("{} | {} | {} | {} | {}, no schedule ({} matches, {} slots)", n, a.0, a.1.len(), sa.dec, sb.dec, n * (n - 1) / 2, n / 2 * (n - 2));
        pts.push(((sa.dec as f64).log10(), (sb.dec as f64).log10()));
    }
    println!("chart, log10 decisions: {}", pts.iter().map(|(a, b)| format!("{:.2}/{:.2}", a, b)).collect::<Vec<_>>().join(" "));
    for n in [12usize, 16, 20] {
        let a = league(n, n - 1, false, true); let sa = solve(a.0, &a.1, false, NO); assert!(sa.models == 1);
        println!("{} teams in {} rounds: {} variables, {} clauses, {} decisions, found", n, n - 1, a.0, a.1.len(), sa.dec);
    }
    let (nm, clm, _) = league(6, 5, true, false); let m = solve(nm, &clm, false, NO);
    let bad = fixtures(m.first.as_ref().unwrap(), &pairs, 5); let per: Vec<usize> = bad.iter().map(|ms| ms.len()).collect();
    println!("mistake 1, the once-a-round and every-round clauses dropped: {} clauses, {} fewer; matches per round {}; rules kept: {}", clm.len(), cl.len() - clm.len(),
        per.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "), if obeys(&bad) { "yes" } else { "no" });
    assert!(*per.iter().max().unwrap() > 3 && !obeys(&bad) && cl.len() - clm.len() == parts[2] + parts[3]);
    let b = league(12, 10, false, true); let cp = solve(b.0, &b.1, false, 100000);
    println!("mistake 2, 12 teams in 10 rounds, capped at 100,000 decisions: {}", if cp.capped { "still undecided after 100,000 decisions" } else { "decided" });
    assert!(cp.capped);
    println!("mistake 3, blind search: 2^75 is about {:.2}e22 assignments, against {} decisions", (1u128 << 75) as f64 / 1e22, s.dec);
    println!("sudoku on an n by n grid as SAT: one variable per cell and digit, {} for 4 by 4, {} for 9 by 9", 4u32.pow(3), 9u32.pow(3));
    assert!(parts.iter().sum::<usize>() == cl.len() && parts == [15, 15 * 10, 6 * 5 * 10, 6 * 5, 1 + 1 + 3 + 2 * 4]); // counted, against formulas
    println!("ALL CHECKS PASS");
}
