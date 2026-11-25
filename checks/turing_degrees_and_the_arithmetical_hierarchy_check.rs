// Turing degrees and the arithmetical hierarchy -- the same check as the Python, in Rust.  No crates.
// Programs use six symbols  + - < > [ ]  on a row of cells holding 0, 1, 2, ... with no top
// ("-" leaves 0 at 0).  Input n starts in cell 0.  A program halts when it runs off its end.
// The interpreter is the one explained on the Decidable and semidecidable card, without "!".
use std::collections::{BTreeMap, HashMap};
type Config = (usize, i64, Vec<(i64, u64)>);
struct Run { p: Vec<char>, pc: usize, ptr: i64, tape: BTreeMap<i64, u64>, steps: usize, jump: HashMap<usize, usize> }
impl Run {
    fn new(s: &str, n: u64) -> Run {
        let p: Vec<char> = s.chars().collect();
        let (mut jump, mut stack) = (HashMap::new(), vec![]);
        for (i, &c) in p.iter().enumerate() {
            if c == '[' { stack.push(i); } else if c == ']' { let j = stack.pop().unwrap(); jump.insert(i, j); jump.insert(j, i); }
        }
        let mut tape = BTreeMap::new();
        if n > 0 { tape.insert(0, n); }
        Run { p, pc: 0, ptr: 0, tape, steps: 0, jump }
    }
    fn halted(&self) -> bool { self.pc >= self.p.len() }
    fn config(&self) -> Config { (self.pc, self.ptr, self.tape.iter().filter(|(_, &v)| v != 0).map(|(&k, &v)| (k, v)).collect()) }
    fn step(&mut self) {
        let (c, v) = (self.p[self.pc], *self.tape.get(&self.ptr).unwrap_or(&0));
        self.steps += 1;
        match c {
            '+' => { self.tape.insert(self.ptr, v + 1); }
            '-' => { self.tape.insert(self.ptr, v.saturating_sub(1)); }
            '>' => self.ptr += 1,
            '<' => self.ptr -= 1,
            '[' if v == 0 => self.pc = self.jump[&self.pc],
            ']' if v != 0 => self.pc = self.jump[&self.pc],
            _ => {}
        }
        self.pc += 1;
    }
}
#[derive(PartialEq, Clone, Copy)]
enum Cert { H(usize), L(usize, usize), Unknown }
fn certify(p: &str, n: u64, cap: usize) -> Cert { // H(t): halts at step t; L(a, b): a repeat proves a loop
    let (mut r, mut seen) = (Run::new(p, n), HashMap::new());
    while !r.halted() && r.steps < cap {
        if let Some(&a) = seen.get(&r.config()) { return Cert::L(a, r.steps); }
        seen.insert(r.config(), r.steps); r.step();
    }
    if r.halted() { Cert::H(r.steps) } else { Cert::Unknown }
}
fn kind(c: Cert) -> &'static str { match c { Cert::H(_) => "h", Cert::L(_, _) => "l", Cert::Unknown => "?" } }
fn steps(c: Cert) -> usize { if let Cert::H(t) = c { t } else { 0 } }
fn oracle(p: &str) -> bool {            // stand-in for a HALT oracle: every answer carries a proof
    let a = certify(p, 0, 5000);
    assert!(a != Cert::Unknown, "the stand-in has no proof for {}", p);
    kind(a) == "h"
}
fn not_total(e: &str, ask: &dyn Fn(&str) -> bool, limit: usize) -> (Option<usize>, usize) {
    for n in 0..limit { if !ask(&format!("{}{}", "+".repeat(n), e)) { return (Some(n), n + 1); } }
    (None, limit)
}
type Prefix = Vec<(char, &'static str, bool)>;
fn blocks(pre: &Prefix) -> Vec<char> {  // quantifier blocks, bounded quantifiers dropped
    let mut out: Vec<char> = vec![];
    for &(q, _, bounded) in pre { if !bounded && out.last() != Some(&q) { out.push(q); } }
    out
}
fn level(pre: &Prefix) -> String {
    let b = blocks(pre);
    if b.is_empty() { "Delta0".to_string() } else { format!("{}{}", if b[0] == 'E' { "Sigma" } else { "Pi" }, b.len()) }
}
fn negate(pre: &Prefix) -> Prefix { pre.iter().map(|&(q, v, b)| (if q == 'E' { 'A' } else { 'E' }, v, b)).collect() }
fn dual(lv: &str) -> String { lv.replace("Sigma", "P").replace("Pi", "Sigma").replace("P", "Pi") }
fn show(pre: &Prefix) -> String {
    pre.iter().map(|&(q, v, _)| format!("{}{}", if q == 'E' { "exists " } else { "forall " }, v)).collect::<Vec<_>>().join(" ")
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let zoo = ["[-]", "[]", "-[]", "+[]", ">+<[[-]>-<]>[]"];
    println!("programs on inputs 0 to 9 (h halts, l loops, proved by a repeated configuration):");
    let table: HashMap<&str, Vec<Cert>> = zoo.iter().map(|&e| (e, (0..10).map(|n| certify(e, n, 5000)).collect())).collect();
    for e in zoo {
        let row = &table[e];
        let marks: Vec<&str> = row.iter().map(|&a| kind(a)).collect();
        println!("  {:15} {}   halting inputs {} of 10", e, marks.join(" "), row.iter().filter(|&&a| kind(a) == "h").count());
    }
    let st: Vec<String> = table["[-]"].iter().map(|&a| steps(a).to_string()).collect();
    println!("[-] on input n halts at step: {}", st.join(" "));
    if let Cert::L(a, b) = certify("[]", 1, 50) { println!("[] on input 1 repeats its configuration at steps {} and {}", a, b); }
    let f: Vec<(&str, Prefix, &str)> = vec![
        ("HALT", vec![('E', "s", false)], "H(e,0,s)"),
        ("TOT", vec![('A', "n", false), ('E', "s", false)], "H(e,n,s)"),
        ("FIN", vec![('E', "m", false), ('A', "n", false), ('A', "s", false)], "n <= m or not H(e,n,s)"),
        ("PROVABLE", vec![('E', "p", false)], "Proof(p,y)"),
        ("UPTO", vec![('A', "n<=m", true), ('E', "s", false)], "H(e,n,s)")];
    println!("quantifier blocks (bounded quantifiers dropped, repeats merged):");
    for (name, pre, mat) in &f {
        println!("  {:8} {:55} {:7} complement {}", name, format!("{} : {}", show(pre), mat), level(pre), level(&negate(pre)));
    }
    // road two: the reduction HALT <=m TOT, e -> [-]e, checked configuration by configuration
    let (mut progs, mut layer): (Vec<String>, Vec<String>) = (vec![], vec![String::new()]);
    for _ in 0..4 {
        layer = layer.iter().flat_map(|p| "+-<>[]".chars().map(move |c| format!("{}{}", p, c))).collect();
        for p in &layer {
            let (mut d, mut ok) = (0i32, true);
            for c in p.chars() { d += (c == '[') as i32 - (c == ']') as i32; if d < 0 { ok = false; } }
            if ok && d == 0 { progs.push(p.clone()); }
        }
    }
    let (mut matched, mut closed, mut halting) = (true, true, 0);
    for e in &progs {
        let base = certify(e, 0, 60);
        if kind(base) == "h" { halting += 1; }
        for n in 0..5u64 {
            let (mut r, mut q) = (Run::new(&format!("[-]{}", e), n), Run::new(e, 0));
            for _ in 0..1 + 2 * n { r.step(); }
            for _ in 0..61 {
                let (c1, c2) = (r.config(), q.config());
                matched &= (c1.0 - 3, c1.1, c1.2) == c2 && r.halted() == q.halted();
                if q.halted() { break; }
                r.step(); q.step();
            }
            if kind(base) == "h" { closed &= certify(&format!("[-]{}", e), n, 200) == Cert::H(1 + 2 * n as usize + steps(base)); }
        }
    }
    println!("reduction e -> [-]e on all {} programs up to 4 symbols, inputs 0 to 4, 60 steps:", progs.len());
    println!("  configurations agree at every step: {}", yn(matched));
    println!("  {} halt on 0 within 60 steps; steps on n = 1 + 2n + steps of e: {}", halting, yn(closed));
    let s5: Vec<String> = (0..5).map(|n| steps(certify("[-]-[]", n, 99)).to_string()).collect();
    println!("  -[] halts on 0 at step {}; [-]-[] on 0 to 4 at steps {}", steps(certify("-[]", 0, 99)), s5.join(" "));
    let loops = (0..5).all(|n| kind(certify("[-]+[]", n, 99)) == "l") && kind(certify("+[]", 0, 99)) == "l";
    println!("  +[] loops on 0; [-]+[] loops on 0 to 4: {}", yn(loops));
    // road three: an oracle machine for "not total" against a direct scan of the certified runs
    println!("oracle machine for 'not total', at most 30 questions to the HALT stand-in:");
    let mut found: Vec<(Option<usize>, Option<usize>)> = vec![];
    for e in zoo {
        let (w, asked) = not_total(e, &|p| oracle(p), 30);
        let direct = table[e].iter().position(|&a| kind(a) == "l");
        found.push((w, direct));
        match w {
            Some(w) => println!("  {:15} oracle says no at question {}: witness n = {}; direct scan {}", e, asked, w, direct.unwrap()),
            None => println!("  {:15} still searching after {} questions, all yes", e, asked),
        }
    }
    println!("not in HALT, one question: +[] -> {}", if oracle("+[]") { "oracle yes -> answer no" } else { "oracle no -> answer yes" });
    println!("Post's theorem, levels against oracles:");
    for k in 1..4 {
        println!("  Sigma{}: semidecidable with oracle 0{}   Delta{}: decidable with oracle 0{}", k, "'".repeat(k - 1), k + 1, "'".repeat(k));
    }
    // what breaks
    let naive: Vec<usize> = f.iter().map(|x| x.1.len()).collect();
    println!("mistake 1, counting quantifiers not blocks: FIN has {}, read as Sigma{}", naive[2], naive[2]);
    println!("mistake 2, counting the bounded quantifier: UPTO read as Pi{}, true level {}", naive[4], level(&f[4].1));
    let nt = zoo.iter().filter(|&&e| table[e].iter().any(|&a| kind(a) == "l")).count();
    let none = zoo.iter().filter(|&&e| table[e].iter().all(|&a| kind(a) == "l")).count();
    println!("mistake 3, 'not total' read as 'halts on no input': {} of {} not total, {} of {} halt on none", nt, zoo.len(), none, zoo.len());
    let (w100, asked100) = not_total("[-]", &|p| kind(certify(p, 0, 100)) == "h", 200);
    let w100 = w100.unwrap();
    println!("mistake 4, a 100-step cap as the oracle: [-] called not total at n = {}, question {}; that question halts at step {}",
        w100, asked100, steps(certify(&format!("{}[-]", "+".repeat(w100)), 0, 999)));
    assert!(matched && closed && loops && halting > 0);                       // simulation = closed form
    assert!(found.iter().all(|&(w, d)| w.is_none() || w == d) && found[0] == (None, None));
    assert!(f.iter().all(|x| level(&negate(&x.1)) == dual(&level(&x.1))));
    let differ: Vec<&str> = f.iter().zip(&naive).filter(|(x, &k)| k != blocks(&x.1).len()).map(|(x, _)| x.0).collect();
    assert!(differ == ["FIN", "UPTO"]);
    assert!(f.iter().map(|x| level(&x.1)).collect::<Vec<_>>() == ["Sigma1", "Pi2", "Sigma2", "Sigma1", "Sigma1"]); // by hand
    assert!(w100 == (0..200).find(|n| n + 1 + 2 * n > 100).unwrap() && (nt, none) == (4, 1));
    println!("ALL CHECKS PASS");
}
