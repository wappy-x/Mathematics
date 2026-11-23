// The language ladder -- the check behind the card.  std only, no crates.
// Four patterns over a and b, one per rung; each machine meets its definition and a generated list.
use std::collections::{BTreeSet, HashMap, HashSet};
fn strings(n: usize) -> Vec<String> { (0..1usize << n).map(|m| (0..n).map(|i| if m >> (n - 1 - i) & 1 == 0 { 'a' } else { 'b' }).collect()).collect() }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
// rung 3, fixed memory: A = only a's so far, B = b's have started, D = dead
fn dfa(w: &str) -> bool { w.chars().fold('A', |q, c| match (q, c) { ('A', 'a') => 'A', ('A', 'b') => 'B', ('B', 'b') => 'B', _ => 'D' }) != 'D' }
// rung 2, one stack: push for each a, pop for each b, never an a after a b
fn stack_run(w: &str) -> (bool, usize) {
    let (mut st, mut seen_b, mut high) = (Vec::new(), false, 0);
    for c in w.chars() {
        if c == 'a' && seen_b { return (false, high); }
        if c == 'a' { st.push('a'); high = high.max(st.len()); }
        else if st.is_empty() { return (false, high); }
        else { seen_b = true; st.pop(); }
    }
    (st.is_empty(), high)
}
// rung 1, a tape no longer than the input: the Turing machines card's simulator, cut down (no cap or trace; rows may
// share a line, split at ';'), with one rule added: the head may read the blank past each end but never write or go on.
type Rules = HashMap<(String, char), (char, char, String)>;
fn table(text: &str) -> Rules {
    text.split([';', '\n']).filter(|l| !l.trim().is_empty()).map(|l| {
        let f: Vec<&str> = l.split_whitespace().collect(); let c = |i: usize| f[i].chars().next().unwrap();
        ((f[0].to_string(), c(1)), (c(2), c(3), f[4].to_string())) }).collect()
}
fn run_tm(rules: &Rules, word: &str, start: &str) -> (bool, usize, usize) {
    let (mut tape, n): (HashMap<i64, char>, i64) = (word.chars().enumerate().map(|(i, c)| (i as i64, c)).collect(), word.len() as i64);
    let (mut head, mut state, mut steps, mut used) = (0i64, start.to_string(), 0usize, HashSet::new());
    while let Some((write, mv, nxt)) = rules.get(&(state.clone(), *tape.get(&head).unwrap_or(&'_'))) {
        let to = head + if *mv == 'R' { 1 } else { -1 };
        assert!((0 <= head && head < n || *write == '_') && -1 <= to && to <= n);
        if *write != '_' { used.insert(head); }
        tape.insert(head, *write); head = to; steps += 1; state = nxt.clone();
    }
    (state == "accept", steps, used.len()) // stopping in any state but accept means no
}
// Mark the ends inward to find the middle, then carry each second-half letter back to its partner (Y carried, X matched).
const WW: &str = "mark a A R right; mark b B R right; mark A Y L carrya; mark B Y L carryb; mark _ _ L accept
right a a R right; right b b R right; right A A L end; right B B L end; right _ _ L end
end a A L left; end b B L left; left a a L left; left b b L left; left A A R mark; left B B R mark
carrya Y Y L carrya; carrya A A L carrya; carrya B B L carrya; carrya X X R isa; carrya _ _ R isa
carryb Y Y L carryb; carryb A A L carryb; carryb B B L carryb; carryb X X R isb; carryb _ _ R isb
isa A X R fwd; isb B X R fwd; fwd A A R fwd; fwd B B R fwd; fwd Y Y R next; next Y Y R next; next A Y L carrya; next B Y L carryb; next _ _ L accept";
const NAMES: [&str; 3] = ["a*b*", "a^n b^n", "ww"];
// the plain definitions, and each language generated rather than tested
fn def(name: &str, w: &str) -> bool {
    let h = w.len() / 2;
    match name { "a*b*" => !w.contains("ba"), "a^n b^n" => w == "a".repeat(h) + &"b".repeat(h), _ => w[..h] == w[h..] }
}
fn generate(name: &str, n: usize) -> BTreeSet<String> {
    match name {
        "a*b*" => (0..=n).map(|i| "a".repeat(i) + &"b".repeat(n - i)).collect(),
        "a^n b^n" => { // grammar S -> aSb | empty, applied n/2 times
            let mut s = String::new();
            for _ in 0..n / 2 { s = format!("a{}b", s); }
            if n % 2 == 0 { [s].into_iter().collect() } else { BTreeSet::new() }
        }
        _ => if n % 2 == 0 { strings(n / 2).iter().map(|u| format!("{}{}", u, u)).collect() } else { BTreeSet::new() },
    }
}
fn machine(name: &str, w: &str) -> bool { match name { "a*b*" => dfa(w), "a^n b^n" => stack_run(w).0, _ => run_tm(&table(WW), w, "mark").0 } }
// memory needed: how many length-k beginnings must be told apart (endings up to k letters)
fn classes(name: &str, k: usize) -> usize {
    let ends: Vec<String> = (0..=k).flat_map(strings).collect();
    strings(k).iter().map(|p| ends.iter().map(|e| def(name, &format!("{}{}", p, e))).collect()).collect::<HashSet<Vec<bool>>>().len()
}
// rung 0, this card's own small encoding: states 1 to k, 0 halts.  Header a^k b, then 2k rules in order
// (state 1 reads 0, state 1 reads 1, ...): write a/b = 0/1, move a/b = L/R, next a^j b (j = 0 halts)
type Rule = (usize, char, usize);
fn encode(m: &[Rule]) -> String {
    let rules: String = m.iter().map(|&(w, mv, nx)| format!("{}{}{}b", ["a", "b"][w], if mv == 'R' { "b" } else { "a" }, "a".repeat(nx))).collect();
    "a".repeat(m.len() / 2) + "b" + &rules
}
fn decode(c: &str) -> Vec<Rule> {
    let (c, mut m) = (c.as_bytes(), Vec::new());
    let (k, mut i) = (c.iter().position(|&x| x == b'b').unwrap(), c.iter().position(|&x| x == b'b').unwrap() + 1);
    for _ in 0..2 * k {
        let j = i + 2 + c[i + 2..].iter().position(|&x| x == b'b').unwrap();
        m.push(((c[i] == b'b') as usize, if c[i + 1] == b'b' { 'R' } else { 'L' }, j - i - 2)); i = j + 1;
    }
    m
}
fn run(m: &[Rule], cap: usize) -> Option<(usize, usize)> {
    let (mut tape, mut pos, mut q) = (std::collections::HashMap::new(), 0i64, 1usize);
    for step in 1..=cap {
        let (w, mv, nx) = m[2 * (q - 1) + *tape.get(&pos).unwrap_or(&0)];
        tape.insert(pos, w); pos += if mv == 'R' { 1 } else { -1 }; q = nx;
        if q == 0 { return Some((step, tape.values().sum())); }
    }
    None
}
// what breaks: fixed memory sized for nesting 3 (a count of a's up to 3, then of b's), and a stack used for ww
fn depth3(w: &str) -> bool {
    let (mut a, mut b) = (0, 0);
    for c in w.chars() { if c == 'a' && (b > 0 || a == 3) { return false; } if c == 'a' { a += 1 } else { b += 1 } }
    a == b
}
fn bal3(w: &str) -> bool { let mut d = 0i32; w.chars().all(|c| { d += if c == 'a' { 1 } else { -1 }; (0..=3).contains(&d) }) && d == 0 }
fn stack_ww(w: &str) -> bool { w.len() % 2 == 0 && w[..w.len() / 2].chars().rev().collect::<String>() == w[w.len() / 2..] }
fn main() {
    for name in NAMES {
        let mut checked = 0;
        for n in 0..13 {
            let (acc, by_def): (BTreeSet<String>, BTreeSet<String>) = (strings(n).into_iter().filter(|w| machine(name, w)).collect(), strings(n).into_iter().filter(|w| def(name, w)).collect());
            assert!(acc == by_def && by_def == generate(name, n), "{}", name);
            checked += 1 << n;
        }
        println!("agree {:<8} machine = definition = generated on {} strings, lengths 0 to 12", name, checked);
    }
    let counts: Vec<String> = NAMES.iter().map(|k| format!("{} {}", k, generate(k, 12).len())).collect();
    println!("of 4096 strings of length 12: {}", counts.join(", "));
    let ((sa, sh), (la, lk, lc), ww) = (stack_run("aaaaabbbbb"), run_tm(&table(WW), "abbaabba", "mark"), table(WW));
    println!("stack on aaaaabbbbb: accept {}  highest stack {}", py(sa), sh);
    let yes: Vec<String> = (0..13).flat_map(|n| generate("ww", n)).collect();
    let fit = yes.iter().filter(|w| run_tm(&ww, w, "mark").1 == w.len() * w.len() + 3 * w.len() + 1).count();
    assert!((la, lk, lc) == (true, 8 * 8 + 3 * 8 + 1, "abbaabba".len()) && fit == yes.len());
    println!("tape on abbaabba: accept {}  rows {}, cells written {}, steps {}; steps = |w|^2 + 3|w| + 1 on {} of {} accepted", py(la), ww.len(), lc, lk, fit, yes.len());
    for k in [2usize, 4, 6, 8, 10] {
        let c: Vec<usize> = NAMES.iter().map(|nm| classes(nm, k)).collect();
        assert!(c == vec![3, k / 2 + 2, 1 << k], "{:?}", c);
        println!("classes after {:>2} letters: a*b* {:>4}  a^n b^n {:>4}  ww {:>5}", k, c[0], c[1], c[2]);
    }
    // ww is not context-free: pump s = a^p b^p a^p b^p at every split u v x y z
    for p in 1..5usize {
        let s = "a".repeat(p) + &"b".repeat(p) + &"a".repeat(p) + &"b".repeat(p);
        let (mut splits, mut survive) = (0, 0);
        for i in 0..s.len() { for lv in 0..=p { for lx in 0..=p - lv { for ly in 0..=p - lv - lx {
            if lv + ly == 0 || i + lv + lx + ly > s.len() { continue; }
            let (u, v, x) = (&s[..i], &s[i..i + lv], &s[i + lv..i + lv + lx]);
            let (y, z) = (&s[i + lv + lx..i + lv + lx + ly], &s[i + lv + lx + ly..]);
            splits += 1;
            if (0..4).all(|t| def("ww", &format!("{}{}{}{}{}", u, v.repeat(t), x, y.repeat(t), z))) { survive += 1; }
        } } } }
        assert!(survive == 0, "{}", p);
        println!("pump ww, p = {}: {} has {} splits, {} survive pumping", p, s, splits, survive);
    }
    let mut rules = Vec::new();
    for w in 0..2 { for mv in ['L', 'R'] { for nx in 0..3 { rules.push((w, mv, nx)); } } }
    let mut machines: Vec<Vec<Rule>> = vec![vec![]];
    for _ in 0..4 { machines = machines.iter().flat_map(|m| rules.iter().map(move |r| { let mut v = m.clone(); v.push(*r); v })).collect(); }
    assert!(machines.iter().all(|m| decode(&encode(m)) == *m));
    let res = |cap: usize| -> Vec<Option<usize>> { machines.iter().map(|m| run(m, cap).map(|r| r.0)).collect() };
    let (r5, r6, r100) = (res(5), res(6), res(100));
    let halt: Vec<usize> = r100.iter().flatten().cloned().collect();
    let longest = *halt.iter().max().unwrap();
    let champ: Vec<Rule> = vec![(1, 'R', 2), (1, 'L', 2), (1, 'L', 1), (1, 'R', 0)];
    println!("2-state machines {} = {}^4: halt within 100 steps {}, longest {}, still running {}", machines.len(), rules.len(), halt.len(), longest, machines.len() - halt.len());
    let (cs, co) = run(&champ, 100).unwrap();
    assert!(longest == 6 && (cs, co) == (6, 4));
    println!("champion {} halts at step {} with ones {}", encode(&champ), cs, co);
    println!("tape-bounded configurations q |w| g^|w|, q = 10, |w| = 20, g = 4: {}", 10u64 * 20 * 4u64.pow(20));
    let miss3: Vec<String> = (0..13).flat_map(strings).filter(|w| depth3(w) != def("a^n b^n", w)).collect();
    let wrong: Vec<String> = (0..13).step_by(2).flat_map(strings).filter(|w| stack_ww(w) != def("ww", w)).collect();
    assert!(miss3 == vec!["aaaabbbb", "aaaaabbbbb", "aaaaaabbbbbb"] && wrong.contains(&"abab".to_string()) && wrong.contains(&"abba".to_string()));
    let e8: Vec<String> = (0..9).flat_map(strings).collect();
    let st3 = e8.iter().map(|p| e8.iter().map(|e| depth3(&format!("{}{}", p, e))).collect()).collect::<HashSet<Vec<bool>>>().len();
    assert!(st3 == 4 + 3 + 1); // a count 0..3, then 2, 1 or 0 b's still owed, then dead
    let st5 = e8.iter().map(|p| e8.iter().map(|e| bal3(&format!("{}{}", p, e))).collect()).collect::<HashSet<Vec<bool>>>().len();
    assert!(st5 == 4 + 1); // all brackets to depth 3: depth 0..3, then dead
    println!("break: depth-3 checker ({} states; {} for all brackets to depth 3) misses {} strings up to 12 letters, first {}", st3, st5, miss3.len(), miss3[0]);
    println!("break: stack used for ww wrong on {} even strings up to 12; abab says {} abba says {}", wrong.len(), py(stack_ww("abab")), py(stack_ww("abba")));
    let miss = |r: &Vec<Option<usize>>| r.iter().zip(&r100).filter(|(a, b)| a != b).count();
    let c5 = if run(&champ, 5).is_none() { "still running after 5 steps" } else { "halts" };
    println!("break: cap 5 misses {} halting machines; champion at cap 5: {} | try: cap 6 misses {}", miss(&r5), c5, miss(&r6));
    let boxes: Vec<String> = (0..4).map(|i| format!("{} {} {} {}", 10 + 30 * i, 10 + 50 * i, 620 - 60 * i, 380 - 80 * i)).collect();
    println!("figure, boxes x y w h: {}", boxes.join("; "));
    println!("ALL CHECKS PASS");
}
