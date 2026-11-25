// Formal proofs and soundness: a checker for natural-deduction lines, and truth in every small structure.
use std::collections::{BTreeMap, BTreeSet};
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)] enum F { Atom(String, Vec<String>), Imp(Box<F>, Box<F>), All(String, Box<F>), Ex(String, Box<F>) }
use F::*;
fn at(p: &str, ts: &[&str]) -> F { Atom(p.into(), ts.iter().map(|t| t.to_string()).collect()) }
fn imp(f: &F, g: &F) -> F { Imp(Box::new(f.clone()), Box::new(g.clone())) }
fn all(v: &str, f: &F) -> F { All(v.into(), Box::new(f.clone())) } fn ex(v: &str, f: &F) -> F { Ex(v.into(), Box::new(f.clone())) }
fn tf(b: bool) -> &'static str { if b { "true" } else { "false" } }
fn show(f: &F) -> String {
    match f { Atom(p, ts) => format!("{}({})", p, ts.join(", ")), Imp(a, b) => format!("({} -> {})", show(a), show(b)),
        All(v, b) => format!("forall {} {}", v, show(b)), Ex(v, b) => format!("exists {} {}", v, show(b)) }
}
fn free(f: &F) -> BTreeSet<String> { // free names: free variables and constants
    match f { Atom(_, ts) => ts.iter().cloned().collect(), Imp(a, b) => free(a).union(&free(b)).cloned().collect(),
        All(v, b) | Ex(v, b) => { let mut s = free(b); s.remove(v); s } }
}
fn sub(f: &F, x: &str, t: &str) -> Option<F> { // f with t put in for the free x; None if a quantifier would capture t
    match f {
        Atom(p, ts) => Some(Atom(p.clone(), ts.iter().map(|s| if s == x { t.to_string() } else { s.clone() }).collect())),
        Imp(a, b) => Some(Imp(Box::new(sub(a, x, t)?), Box::new(sub(b, x, t)?))),
        All(v, b) | Ex(v, b) => {
            if v == x || !free(b).contains(x) { return Some(f.clone()); }
            if v == t { return None; }
            let nb = Box::new(sub(b, x, t)?);
            Some(if let All(..) = f { All(v.clone(), nb) } else { Ex(v.clone(), nb) })
        }
    }
}
struct L { rule: &'static str, u: Vec<usize>, name: &'static str, dis: Option<F>, claim: F }
fn ln(rule: &'static str, u: &[usize], name: &'static str, claim: F) -> L { L { rule, u: u.to_vec(), name, dis: None, claim } }
type Done = Vec<(BTreeSet<F>, F)>; fn check(lines: &[L], side: bool) -> Result<Done, String> {
    let mut done: Done = vec![];
    for (i, l) in lines.iter().enumerate() {
        let bad = |why: String| Err(format!("rejected at line {}: {}", i + 1, why));
        let get = |k: usize| done[k - 1].clone();
        let (g, f) = match l.rule {
            "assume" => (BTreeSet::from([l.claim.clone()]), l.claim.clone()),
            "->E" => { let ((g1, f1), (g2, f2)) = (get(l.u[0]), get(l.u[1]));
                match &f1 { Imp(a, b) if **a == f2 => (g1.union(&g2).cloned().collect(), (**b).clone()),
                    _ => return bad(format!("line {} is not the if-part of line {}", l.u[1], l.u[0])) } }
            "->I" => { let (mut g1, f1) = get(l.u[0]); let d = l.dis.clone().unwrap(); g1.remove(&d); (g1, imp(&d, &f1)) }
            "AE" => { let (g1, f1) = get(l.u[0]);
                let All(v, b) = &f1 else { return bad(format!("wrong shape for {}", l.rule)) };
                match sub(b, v, l.name) { Some(f) => (g1, f), None => return bad(format!("{} is not free for {}", l.name, v)) } }
            "AI" => { let (g1, f1) = get(l.u[0]);
                if side && g1.iter().any(|h| free(h).contains(l.name)) { return bad(format!("{} is free in an open assumption", l.name)); }
                (g1, all(l.name, &f1)) }
            "EI" => { let (g1, f1) = get(l.u[0]);
                let Ex(v, b) = &l.claim else { return bad(format!("wrong shape for {}", l.rule)) };
                if sub(b, v, l.name) != Some(f1) { return bad(format!("line {} is not an instance", l.u[0])); }
                (g1, l.claim.clone()) }
            _ => { let ((g1, f1), (g2, f2)) = (get(l.u[0]), get(l.u[1])); let w = l.name;
                let Ex(v, b) = &f1 else { return bad(format!("wrong shape for {}", l.rule)) };
                let mut rest = g2.clone(); if let Some(h) = sub(b, v, w) { rest.remove(&h); }
                if side && [&f1, &f2].into_iter().chain(rest.iter()).any(|h| free(h).contains(w)) { return bad(format!("witness {} is not new", w)); }
                (g1.union(&rest).cloned().collect(), f2) }
        };
        if f != l.claim { return bad(format!("the rule gives {}", show(&f))); }
        done.push((g, f));
    }
    Ok(done)
}
#[derive(Clone)] struct M { n: usize, rel: Vec<(String, BTreeSet<Vec<usize>>)>, con: Vec<(String, usize)> }
type G = BTreeMap<String, usize>;
fn holds(f: &F, m: &M, g: &G) -> bool {
    match f {
        Atom(p, ts) => { let v: Vec<usize> = ts.iter().map(|t| *g.get(t).unwrap_or_else(|| &m.con.iter().find(|c| &c.0 == t).unwrap().1)).collect();
            m.rel.iter().find(|r| &r.0 == p).unwrap().1.contains(&v) }
        Imp(a, b) => !holds(a, m, g) || holds(b, m, g),
        All(v, b) | Ex(v, b) => { let mut it = (0..m.n).map(|d| { let mut h = g.clone(); h.insert(v.clone(), d); holds(b, m, &h) });
            if let All(..) = f { it.all(|x| x) } else { it.any(|x| x) } }
    }
}
fn digits(mut i: usize, radix: &[usize]) -> Vec<usize> { // mixed radix, last digit fastest
    let mut d = vec![0; radix.len()]; for k in (0..radix.len()).rev() { d[k] = i % radix[k]; i /= radix[k]; } d
}
fn structures(sig: &[(&str, u32)], nmax: usize) -> Vec<M> { // 0 places is a constant. Every structure on {0, ..., n-1}
    let mut out = vec![]; for n in 1..=nmax {
        let radix: Vec<usize> = sig.iter().map(|&(_, k)| if k == 0 { n } else { 1 << n.pow(k) }).collect();
        for idx in 0..radix.iter().product::<usize>() {
            let mut m = M { n, rel: vec![], con: vec![] };
            for (&(name, k), c) in sig.iter().zip(digits(idx, &radix)) {
                if k == 0 { m.con.push((name.into(), c)); continue; }
                let ts = (0..n.pow(k)).filter(|i| c >> i & 1 == 1).map(|i| digits(i, &vec![n; k as usize])).collect();
                m.rel.push((name.into(), ts));
            }
            out.push(m);
        } }
    out
}
fn cases(gs: &[F], f: &F, sig: &[(&str, u32)], nmax: usize) -> (usize, Vec<(M, G)>) {
    let vs: BTreeSet<String> = gs.iter().chain([f]).flat_map(|h| free(h)).filter(|x| "xyz".contains(x.as_str())).collect();
    let (mut total, mut bad) = (0, vec![]);
    for m in structures(sig, nmax) {
        for i in 0..m.n.pow(vs.len() as u32) {
            let g: G = vs.iter().cloned().zip(digits(i, &vec![m.n; vs.len()])).collect(); total += 1;
            if gs.iter().all(|h| holds(h, &m, &g)) && !holds(f, &m, &g) { bad.push((m.clone(), g)); }
        } }
    (total, bad)
}
fn show_m(m: &M, g: &G) -> String {
    let mut s: Vec<String> = m.rel.iter().map(|(r, v)| format!("{} = {{{}}}", r, v.iter().map(|t| if t.len() == 1 { t[0].to_string() }
        else { format!("({},{})", t[0], t[1]) }).collect::<Vec<_>>().join(", "))).collect();
    s.extend(m.con.iter().chain(g.iter().map(|(k, v)| (k.clone(), *v)).collect::<Vec<_>>().iter()).map(|(k, v)| format!("{} = {}", k, v)));
    format!("domain {{{}}}: {}", (0..m.n).map(|d| d.to_string()).collect::<Vec<_>>().join(", "), s.join(", "))
}
fn main() {
    let (p, q) = (|t: &str| at("P", &[t]), |t: &str| at("Q", &[t]));
    let sig = [("P", 1), ("Q", 1), ("a", 0)]; let (rule, allp) = (all("x", &imp(&p("x"), &q("x"))), all("x", &p("x")));
    let mut d7 = ln("->I", &[6], "", imp(&allp, &all("x", &q("x")))); d7.dis = Some(allp.clone());
    let ds = vec![("D1", vec![ln("assume", &[], "", rule.clone()), ln("assume", &[], "", p("a")), ln("AE", &[1], "a", imp(&p("a"), &q("a"))), ln("->E", &[3, 2], "", q("a"))]),
        ("D2", vec![ln("assume", &[], "", rule.clone()), ln("assume", &[], "", ex("x", &p("x"))), ln("assume", &[], "", p("y")), ln("AE", &[1], "y", imp(&p("y"), &q("y"))),
            ln("->E", &[4, 3], "", q("y")), ln("EI", &[5], "y", ex("x", &q("x"))), ln("EE", &[2, 6], "y", ex("x", &q("x")))]),
        ("D3", vec![ln("assume", &[], "", rule.clone()), ln("assume", &[], "", allp.clone()), ln("AE", &[2], "x", p("x")), ln("AE", &[1], "x", imp(&p("x"), &q("x"))),
            ln("->E", &[4, 3], "", q("x")), ln("AI", &[5], "x", all("x", &q("x"))), d7])];
    println!("road 1, the checker: every line names one rule and the lines it uses");
    let (mut checks, mut nlines) = (0, 0);
    for (name, lines) in &ds {
        let out = check(lines, true).unwrap();
        println!("{}: line, rule, uses, open assumptions, claim", name);
        for (n, (l, (g, f))) in lines.iter().zip(&out).enumerate() {
            let opn: Vec<String> = lines.iter().enumerate().filter(|(_, k)| k.rule == "assume" && g.contains(&k.claim)).map(|(i, _)| (i + 1).to_string()).collect();
            let u: Vec<String> = l.u.iter().map(|x| x.to_string()).collect();
            println!("  {} {} {} {{{}}} {}", n + 1, l.rule, if u.is_empty() { "-".into() } else { u.join(",") }, opn.join(","), show(f));
            let (total, bad) = cases(&g.iter().cloned().collect::<Vec<_>>(), f, &sig, 3); checks += total; nlines += 1;
            assert!(bad.is_empty()); // road 3: every accepted line is true in every case, the induction run line by line
        }
    }
    println!("road 3, soundness line by line: all {} lines of D1 to D3 true in every case: {} checks, 0 failures", nlines, checks);
    let m0 = M { n: 2, rel: vec![("P".into(), BTreeSet::from([vec![1]])), ("Q".into(), BTreeSet::from([vec![1]]))], con: vec![("a".into(), 1)] };
    let e = G::new(); let row: Vec<bool> = (0..2).map(|d| holds(&imp(&p("x"), &q("x")), &m0, &G::from([("x".to_string(), d)]))).collect();
    println!("the structure {}", show_m(&m0, &e));
    println!("  P(x) -> Q(x) at x = 0: {}; at x = 1: {}; so forall x (P(x) -> Q(x)) is {}", tf(row[0]), tf(row[1]), tf(holds(&rule, &m0, &e)));
    println!("  P(a) is {} and Q(a) is {}", tf(holds(&p("a"), &m0, &e)), tf(holds(&q("a"), &m0, &e)));
    assert!(row == [true, true] && holds(&q("a"), &m0, &e) && !holds(&p("x"), &m0, &G::from([("x".to_string(), 0)])));
    let all_m = structures(&sig, 3);
    let prem: Vec<&M> = all_m.iter().filter(|m| holds(&rule, m, &e) && holds(&p("a"), m, &e)).collect();
    println!("road 2, every structure on 1 to 3 elements: {}; both premises true in {}; Q(a) true in {} of those",
        all_m.len(), prem.len(), prem.iter().filter(|m| holds(&q("a"), m, &e)).count());
    assert!(all_m.len() == (1..=3).map(|n: usize| n * 4usize.pow(n as u32)).sum::<usize>() && all_m.len() == 228);
    assert!(prem.len() == (1..=3).map(|n: usize| n * 3usize.pow(n as u32 - 1)).sum::<usize>() && prem.len() == 34);
    assert!(prem.iter().all(|m| holds(&q("a"), m, &e)));
    let r = |s: &str, t: &str| at("R", &[s, t]);
    let (fx, rxy, sig_r) = (ex("x", &p("x")), all("x", &ex("y", &r("x", "y"))), [("R", 2)]);
    let fs: Vec<(&str, Vec<L>, Vec<F>, &[(&str, u32)], usize)> = vec![
        ("F1 exists x P(x), so P(a)", vec![ln("assume", &[], "", fx.clone()), ln("assume", &[], "", p("a")), ln("EE", &[1, 2], "a", p("a"))], vec![fx.clone()], &sig, 3),
        ("F2 P(x), so forall x P(x)", vec![ln("assume", &[], "", p("x")), ln("AI", &[1], "x", allp.clone())], vec![p("x")], &sig, 3),
        ("F3 forall x exists y R(x, y), so exists y R(y, y)", vec![ln("assume", &[], "", rxy.clone()), ln("AE", &[1], "y", ex("y", &r("y", "y")))], vec![rxy.clone()], &sig_r, 2),
        ("F4 P(a) -> Q(a) and Q(a), so P(a)", vec![ln("assume", &[], "", imp(&p("a"), &q("a"))), ln("assume", &[], "", q("a")), ln("->E", &[1, 2], "", p("a"))], vec![imp(&p("a"), &q("a")), q("a")], &sig, 3)];
    println!("forged proofs: the checker's verdict, then the first structure that refutes the claim");
    for ((name, lines, prems, sg, nmax), why) in fs.iter().zip(["witness a is not new", "x is free in an open assumption", "y is not free for x", "line 2 is not the if-part of line 1"]) {
        let verdict = check(lines, true).err().unwrap();
        assert!(verdict == format!("rejected at line {}: {}", lines.len(), why)); // caught by the test meant for it
        let (total, bad) = cases(prems, &lines.last().unwrap().claim, sg, *nmax);
        assert!(!bad.is_empty()); // a countermodel, so by soundness no derivation of the claim exists at all
        println!("  {}: {}\n    refuted in {} of {} cases, first: {}", name, verdict, bad.len(), total, show_m(&bad[0].0, &bad[0].1));
    }
    let (_, bad1) = cases(&[fx.clone()], &p("a"), &sig, 3);
    let per: Vec<usize> = (1..=3).map(|n| bad1.iter().filter(|(m, _)| m.n == n).count()).collect();
    let off: Vec<String> = fs[..2].iter().map(|f| show(&check(&f.1, false).unwrap().last().unwrap().1)).collect();
    println!("F1 countermodels by size 1, 2, 3: {}; with the side conditions off, the checker gives {}",
        per.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "), off.join(", "));
    assert!(per == [0, 8, 72] && per == (1..=3).map(|n: u32| n as usize * (2usize.pow(n - 1) - 1) * 2usize.pow(n)).collect::<Vec<_>>()); // a outside P, P not empty
    assert!(show_m(&bad1[0].0, &bad1[0].1) == "domain {0, 1}: P = {0}, Q = {}, a = 1");
    let four = structures(&sig, 4);
    println!("try changing, sizes up to 4: {} structures; premises of D1 true in {}; F1 refuted in {}", four.len(),
        four.iter().filter(|m| holds(&rule, m, &e) && holds(&p("a"), m, &e)).count(), cases(&[fx.clone()], &p("a"), &sig, 4).1.len());
    println!("ALL CHECKS PASS");
}
