// Proof assistants -- the same check as the Python, in Rust.  No crates.  A tiny
// proof checker (the "kernel") accepts a proof only if every line follows from
// earlier lines by one of its eight rules.  Road 1: it checks an 11-step proof
// that no fraction p/q squares to 2.  Road 2: search.  Road 3: factors of 2.
use std::collections::{BTreeMap, BTreeSet, HashMap};
type Poly = BTreeMap<String, i64>;                  // "kk" -> 4 means 4*k*k
#[derive(Clone, PartialEq)] struct Fact { op: String, l: Poly, r: Poly }        // "=", "<", "<=" or "FALSE"
#[derive(Clone)] struct Step { label: String, claim: String, rule: String, refs: Vec<String>, sub: Vec<Step> }
struct Kernel { buggy: bool, show: bool }           // switches: a planted bug, and printing
fn sorted(s: &str) -> String { let mut c: Vec<char> = s.chars().collect(); c.sort(); c.into_iter().collect() }
fn parse(side: &str) -> Poly {                      // "4*k*k+4*k+1" -> {"": 1, "k": 4, "kk": 4}
    let mut poly = Poly::new();
    for term in side.split('+') {
        let (mut c, mut mono) = (1i64, String::new());
        for f in term.split('*').map(|f| f.trim()) { if let Ok(d) = f.parse::<i64>() { c *= d } else { mono.push_str(f) } }
        *poly.entry(sorted(&mono)).or_insert(0) += c;
    } poly }
fn mono(m: &str, c: i64) -> Poly { let mut p = Poly::new(); p.insert(m.to_string(), c); p }
fn mul(a: &Poly, b: &Poly) -> Poly { let mut out = Poly::new();
    for (ma, ca) in a { for (mb, cb) in b { *out.entry(sorted(&format!("{}{}", ma, mb))).or_insert(0) += ca * cb } } out }
fn subst(poly: &Poly, x: char, t: &Poly) -> Poly {  // replace the letter x by the polynomial t
    let mut out = Poly::new();
    for (m, c) in poly { let mut term = mono("", *c);
        for v in m.chars() { term = mul(&term, &if v == x { t.clone() } else { mono(&v.to_string(), 1) }) }
        for (mm, d) in term { *out.entry(mm).or_insert(0) += d } }
    out }
fn fact(claim: &str) -> Fact {                      // "L = R", "L < R", "L <= R" or "FALSE"
    for op in ["<=", "<", "="] {
        if let Some((l, r)) = claim.split_once(op) { return Fact { op: op.to_string(), l: parse(l), r: parse(r) } }
    } Fact { op: "FALSE".to_string(), l: Poly::new(), r: Poly::new() } }
fn var(p: &Poly) -> Option<char> {                  // the letter, if p is one bare letter
    let (m, c) = p.iter().next()?; if p.len() == 1 && *c == 1 && m.len() == 1 { m.chars().next() } else { None } }
fn first(p: &Poly) -> Option<String> { p.keys().next().cloned() }
fn even(p: &Poly) -> bool { p.values().all(|c| c % 2 == 0) }
fn halved(p: &Poly) -> Poly { p.iter().map(|(m, c)| (m.clone(), c / 2)).collect() }
fn odd_clash(a: &Poly, b: &Poly) -> bool { a.get("").unwrap_or(&0) % 2 == 1 && a.iter().all(|(m, c)| m.is_empty() || c % 2 == 0) && even(b) }
fn rule_ok(k: &Kernel, rule: &str, f: &Fact, got: &[Fact], givens: &[String]) -> Option<bool> {
    let n = got.len();
    Some(match rule {
        "subst" if n == 2 => {                       // from x = t and L = R: L and R with x replaced by t
            let x = var(&got[0].l)?;
            got[0].op == "=" && got[1].op == f.op && f.l == subst(&got[1].l, x, &got[0].r) && f.r == subst(&got[1].r, x, &got[0].r)
        }
        "halve" if n == 1 => { let g = &got[0];      // from 2A = 2B: A = B
            g.op == "=" && even(&g.l) && even(&g.r) && f.op == "=" && f.l == halved(&g.l) && f.r == halved(&g.r) }
        "clash" if n == 1 => { let g = &got[0];      // odd = even can never hold
            if k.buggy { g.op == "=" && g.l.get("").unwrap_or(&0) % 2 == 1 }   // the bug: forgets the other terms
            else { g.op == "=" && f.op == "FALSE" && (odd_clash(&g.l, &g.r) || odd_clash(&g.r, &g.l)) } }
        "half" if n == 2 => {                        // from x = 2*y and 1 <= x: y < x, and 1 <= y
            let y = first(&got[0].r)?;
            got[0].op == "=" && got[1].op == "<=" && got[1].l == mono("", 1) && got[1].r == got[0].l && got[0].r == mono(&y, 2)
                && ((f.op == "<" && f.l == mono(&y, 1) && f.r == got[0].l) || (f.op == "<=" && f.l == mono("", 1) && f.r == mono(&y, 1)))
        }
        "descent" if n == 3 => {                     // a smaller solution, so the smallest q was not the smallest
            let kk = first(&got[0].l)?.chars().next()?;
            let m = var(&got[2].l)?;
            let (g1, g2) = (fact(givens.get(0)?), fact(givens.get(1)?));
            f.op == "FALSE" && got[0].op == "=" && got[0].l == subst(&g1.l, 'p', &mono(&kk.to_string(), 1))
                && got[0].r == subst(&g1.r, 'q', &mono(&m.to_string(), 1)) && got[1].op == "<=" && got[1].l == g2.l
                && got[1].r == subst(&g2.r, 'q', &mono(&m.to_string(), 1)) && got[2].op == "<" && got[2].r == mono("q", 1)
        }
        _ => false,
    })
}
fn check(k: &Kernel, proof: &[Step], givens: &[String], seen0: &BTreeSet<char>, facts0: &HashMap<String, Fact>, case: &str) -> String {
    let (mut facts, mut seen) = (facts0.clone(), seen0.clone());
    let mut last = Fact { op: "none".into(), l: Poly::new(), r: Poly::new() };
    for (i, s) in proof.iter().enumerate() {
        let f = fact(&s.claim);
        let mut why = String::new();
        let got: Option<Vec<Fact>> = s.refs.iter().map(|r| facts.get(r).cloned()).collect();
        let ok = match got {
            None => false,
            Some(_) if s.rule == "even" => {       // x = 2*y, because the odd case x = 2*y+1 ends in FALSE
                match (var(&f.l), first(&f.r)) {
                    (Some(x), Some(y)) if f.op == "=" && f.r == mono(&y, 2) && y.len() == 1
                        && !seen.contains(&y.chars().next().unwrap()) && !s.sub.is_empty() => {
                        let mut s2 = seen.clone(); s2.insert(y.chars().next().unwrap());
                        why = check(k, &s.sub, givens, &s2, &facts, &format!("{} = 2*{}+1", x, y));
                        why == "FALSE"
                    }
                    _ => false,
                }
            }
            Some(got) => (s.rule == "given" && givens.contains(&s.claim)) || (s.rule == "case" && i == 0 && s.claim == case)
                || rule_ok(k, &s.rule, &f, &got, givens).unwrap_or(false),
        };
        if k.show { println!("  {:<4}{:<22}{:<8}{:<9}{}", s.label, s.claim, s.rule, s.refs.join(","), if ok { "ok" } else { "REJECTED" }) }
        if !ok { return if why.starts_with("rejected") { why } else { format!("rejected at step {}", s.label) } }
        for m in f.l.keys().chain(f.r.keys()) { for ch in m.chars() { seen.insert(ch); } }
        facts.insert(s.label.clone(), f.clone());
        last = f;
    }
    if last.op == "FALSE" { "FALSE".to_string() } else { "no contradiction".to_string() }
}
fn st(label: &str, claim: &str, rule: &str, refs: &[&str], sub: Vec<Step>) -> Step {
    Step { label: label.into(), claim: claim.into(), rule: rule.into(), refs: refs.iter().map(|r| r.to_string()).collect(), sub }
}
fn swap(proof: &[Step], old: &str, new: &str) -> Vec<Step> {   // the same proof with one piece of text replaced
    proof.iter().map(|s| Step { claim: s.claim.replace(old, new), sub: swap(&s.sub, old, new), ..s.clone() }).collect()
}
fn twos(n: u64) -> u64 { if n % 2 == 1 { 0 } else { 1 + twos(n / 2) } }   // how many times 2 divides n
fn run(k: &Kernel, proof: &[Step], givens: &[&str], seen: &str) -> String {
    check(k, proof, &givens.iter().map(|s| s.to_string()).collect::<Vec<_>>(), &seen.chars().collect(), &HashMap::new(), "")
}
fn pairs(v: &[(u64, u64)]) -> String { format!("[{}]", v.iter().map(|(a, b)| format!("({}, {})", a, b)).collect::<Vec<_>>().join(", ")) }
fn main() {
    let odd_p = vec![st("3a", "p = 2*k+1", "case", &[], vec![]), st("3b", "4*k*k+4*k+1 = 2*q*q", "subst", &["3a", "1"], vec![]),
                     st("3c", "FALSE", "clash", &["3b"], vec![])];
    let odd_q = vec![st("6a", "q = 2*m+1", "case", &[], vec![]), st("6b", "2*k*k = 4*m*m+4*m+1", "subst", &["6a", "5"], vec![]),
                     st("6c", "FALSE", "clash", &["6b"], vec![])];
    let proof = vec![st("1", "p*p = 2*q*q", "given", &[], vec![]), st("2", "1 <= q", "given", &[], vec![]),
        st("3", "p = 2*k", "even", &[], odd_p.clone()), st("4", "4*k*k = 2*q*q", "subst", &["3", "1"], vec![]),
        st("5", "2*k*k = q*q", "halve", &["4"], vec![]), st("6", "q = 2*m", "even", &[], odd_q),
        st("7", "2*k*k = 4*m*m", "subst", &["6", "5"], vec![]), st("8", "k*k = 2*m*m", "halve", &["7"], vec![]),
        st("9", "m < q", "half", &["6", "2"], vec![]), st("10", "1 <= m", "half", &["6", "2"], vec![]),
        st("11", "FALSE", "descent", &["8", "10", "9"], vec![])];
    let givens = ["p*p = 2*q*q", "1 <= q"];
    let quiet = Kernel { buggy: false, show: false };
    println!("kernel rules: given, case, subst, halve, clash, even, half, descent (8)\n  step claim                 rule    uses     verdict");
    let verdict = run(&Kernel { buggy: false, show: true }, &proof, &givens, "pq");
    println!("road 1, the checker: {} reached from the givens, so no such p and q exist", verdict);
    let (b, mut sols, mut near, mut p) = (10000u64, Vec::new(), Vec::new(), 0u64);   // road 2: walk p up to the root of 2*q*q
    for q in 1..=b {
        while (p + 1) * (p + 1) <= 2 * q * q { p += 1 }
        if p * p == 2 * q * q { sols.push((p, q)) }
        for c in [p, p + 1] { if (c * c).abs_diff(2 * q * q) == 1 { near.push(format!("{}/{}", c, q)) } }
    }
    println!("road 2, search 1 <= q <= {}: solutions {}", b, if sols.is_empty() { format!("none up to {}", b) } else { pairs(&sols) });
    println!("  misses by exactly 1: {}", near.join(" "));
    println!("  99*99 = {} and 2*70*70 = {}; 99/70 squared = {:.6}", 99 * 99, 2 * 70 * 70, 9801.0 / 4900.0);
    let n = 20000u64;                                // road 3: an even count of 2s can never equal an odd one
    let (ev, od) = ((1..=n).filter(|i| twos(i * i) % 2 == 0).count() as u64, (1..=n).filter(|i| twos(2 * i * i) % 2 == 1).count() as u64);
    println!("road 3, factors of 2 for n = 1 to {}: n*n has an even count {} times, 2*n*n an odd count {} times", n, ev, od);
    println!("what breaks:");
    let forged = [("k*k = q*q", st("5", "k*k = q*q", "halve", &["4"], vec![])), ("4*k*k = 3*q*q", st("4", "4*k*k = 3*q*q", "subst", &["3", "1"], vec![])),
        ("q < m", st("9", "q < m", "half", &["6", "2"], vec![])), ("p = 2*q, reusing q", st("3", "p = 2*q", "even", &[], swap(&odd_p, "k", "q"))),
        ("p = 2*k, odd case left out", st("3", "p = 2*k", "even", &[], vec![]))];
    let mut res = Vec::new();
    for (d, f) in &forged {
        let pf: Vec<Step> = proof.iter().map(|s| if s.label == f.label { f.clone() } else { s.clone() }).collect();
        res.push(run(&quiet, &pf, &givens, "pq")); println!("  step {} forged as {}: {}", f.label, d, res[res.len() - 1]);
    }
    let p2: Vec<Step> = proof.iter().filter(|s| s.label != "2").cloned().collect();
    let m2 = run(&quiet, &p2, &givens[..1], "pq");
    let zero: Vec<(u64, u64)> = (0..3).flat_map(|a| (0..3).map(move |c| (a, c))).filter(|(a, c)| a * a == 2 * c * c).collect();
    println!("  given 1 <= q dropped: {}; the search finds p, q = ({}, {}), so the shorter claim is false", m2, zero[0].0, zero[0].1);
    let bug = vec![st("1", "k+1 = 2*q", "given", &[], vec![]), st("2", "FALSE", "clash", &["1"], vec![])];
    let b1 = run(&Kernel { buggy: true, show: false }, &bug, &["k+1 = 2*q"], "kq");
    let b2 = run(&quiet, &bug, &["k+1 = 2*q"], "kq");
    let kq: Vec<(u64, u64)> = (0..4).flat_map(|a| (0..4).map(move |c| (a, c))).filter(|(a, c)| a + 1 == 2 * c).collect();
    println!("  buggy clash rule on k+1 = 2*q: {}; correct kernel: {}; yet k, q = ({}, {}) solves it", b1, b2, kq[0].0, kq[0].1);
    let h3 = run(&quiet, &[st("1", "3*k*k = 2*q*q", "given", &[], vec![]), st("2", "k*k = q*q", "halve", &["1"], vec![])], &["3*k*k = 2*q*q"], "kq");
    let pl: Vec<Step> = proof.iter().map(|s| if s.label == "9" { st("9", "m <= q", "given", &[], vec![]) } else { s.clone() }).collect();
    let le = run(&quiet, &pl, &["p*p = 2*q*q", "1 <= q", "m <= q"], "pq");
    println!("  halve on 3*k*k = 2*q*q, an odd side: {}; descent fed m <= q, not m < q: {}", h3, le);
    println!("try changing:");
    let m5 = run(&quiet, &swap(&proof, "2*q*q", "3*q*q"), &["p*p = 3*q*q", "1 <= q"], "pq"); println!("  3 in place of 2: {}", m5);
    let four: Vec<(u64, u64)> = (1..4).flat_map(|c| (0..9).map(move |a| (a, c))).filter(|(a, c)| a * a == 4 * c * c).collect();
    let m4 = run(&quiet, &swap(&proof, "2*q*q", "4*q*q"), &["p*p = 4*q*q", "1 <= q"], "pq");
    println!("  4 in place of 2: {}; the search finds {}", m4, pairs(&four));
    let r = (0..3u64).filter(|i| i * i <= 2).max().unwrap();
    println!("  whole-number square root of 2: {}, and {}*{} = {}, not 2", r, r, r, r * r);
    println!("record (quoted, not computed): BB(5) = 47176870, settled in 2024 in Coq");
    assert!(verdict == "FALSE" && res == [5, 4, 9, 3, 3].iter().map(|n| format!("rejected at step {}", n)).collect::<Vec<_>>());
    assert!(sols.is_empty() && near[5] == "99/70" && near.len() == 11 && zero == vec![(0, 0)]);
    assert!(ev == n && od == n && m2 == "rejected at step 9" && m4 == "rejected at step 5" && m5 == "rejected at step 3c");
    assert!(b1 == "FALSE" && b2 == "rejected at step 2" && kq[0] == (1, 1) && four == vec![(2, 1), (4, 2), (6, 3)] && h3 == "rejected at step 2" && le == "rejected at step 11");
    println!("ALL CHECKS PASS");
}
