// Regular expressions -- the same check as the Python, in Rust.  No crates, no regex.  A postcode
// shape is a pattern over L (capital letter), D (digit) and _ (space).  It is compiled into a
// machine (Thompson), run, made guess-free (subset construction) and read back (elimination).
use std::{cell::Cell, collections::{BTreeSet, HashMap}};
#[derive(Clone, PartialEq)]
enum Re { Eps, Sym(char), Cat(Box<Re>, Box<Re>), Alt(Box<Re>, Box<Re>), Star(Box<Re>) }
use Re::*;
type P = Option<Re>;                  // None means "no route at all"
fn bx(r: Re) -> Box<Re> { Box::new(r) }
fn sym(c: char) -> P { Some(Sym(c)) }
fn cat(a: P, b: P) -> P { match (a, b) { (Some(Eps), b) => b, (a, Some(Eps)) => a, (Some(a), Some(b)) => Some(Cat(bx(a), bx(b))), _ => None } }
fn alt(a: P, b: P) -> P { match (a, b) { (None, b) => b, (a, None) => a, (Some(a), Some(b)) => Some(if a == b { a } else { Alt(bx(a), bx(b)) }) } }
fn star(a: P) -> P { match a { None | Some(Eps) => Some(Eps), Some(Star(x)) => Some(Star(x)), Some(x) => Some(Star(bx(x))) } }
fn seq(rs: Vec<P>) -> P { let mut out = Some(Eps); for r in rs.into_iter().rev() { out = cat(r, out) } out }
fn show(r: &Re, p: u8) -> String {    // write a pattern out, brackets only where needed
    match r {
        Eps => "ε".to_string(), Sym(c) => c.to_string(),
        Star(a) => show(a, 3) + "*",
        Cat(a, b) => { let s = show(a, 2) + &show(b, 2); if p > 2 { format!("({})", s) } else { s } }
        Alt(a, b) => { let s = show(a, 1) + "|" + &show(b, 1); if p > 1 { format!("({})", s) } else { s } }
    }
}
fn pieces(r: &Re) -> usize { match r { Eps | Sym(_) => 1, Star(a) => 1 + pieces(a), Cat(a, b) => pieces(a) + pieces(b), Alt(a, b) => 1 + pieces(a) + pieces(b) } }
type Arrow = (usize, Option<char>, usize); type Set = BTreeSet<usize>;
struct Nfa { n: usize, arrows: Vec<Arrow>, s: usize, e: usize }
fn thompson(r: &Re, n: &mut usize, ar: &mut Vec<Arrow>) -> (usize, usize) {
    if let Cat(a, b) = r {            // joining: exit of the first -> entry of the second
        let (x, y) = (thompson(a, n, ar), thompson(b, n, ar));
        ar.push((x.1, None, y.0));
        return (x.0, y.1);
    }
    let (s, e) = (*n, *n + 1);        // every other piece gets a new entry s and exit e
    *n += 2;
    match r {
        Eps | Sym(_) => ar.push((s, if let Sym(c) = r { Some(*c) } else { None }, e)),
        Alt(a, b) => { let (x, y) = (thompson(a, n, ar), thompson(b, n, ar)); ar.extend([(s, None, x.0), (s, None, y.0), (x.1, None, e), (y.1, None, e)]) }
        Star(a) => { let x = thompson(a, n, ar); ar.extend([(s, None, x.0), (s, None, e), (x.1, None, x.0), (x.1, None, e)]) }   // skip, or go round again
        Cat(..) => unreachable!(),
    }
    (s, e)
}
fn compile_nfa(r: &Re) -> Nfa { let (mut n, mut ar) = (0, Vec::new()); let (s, e) = thompson(r, &mut n, &mut ar); Nfa { n, arrows: ar, s, e } }
fn close(states: Set, ar: &[Arrow]) -> Set {   // add every state reachable by free moves
    let (mut out, mut todo): (Set, Vec<usize>) = (states.clone(), states.into_iter().collect());
    while let Some(q) = todo.pop() { for &(a, c, b) in ar { if a == q && c.is_none() && out.insert(b) { todo.push(b) } } }
    out
}
fn step(st: &Set, c: char, ar: &[Arrow]) -> Set { close(ar.iter().filter(|x| st.contains(&x.0) && x.1 == Some(c)).map(|x| x.2).collect(), ar) }
fn nfa_accepts(m: &Nfa, w: &[char], trace: &mut Vec<usize>) -> bool {   // keep the set of live states
    let mut cur = close(Set::from([m.s]), &m.arrows);
    for &c in w { cur = step(&cur, c, &m.arrows); trace.push(cur.len()) }
    cur.contains(&m.e)
}
fn search_ends(m: &Nfa, w: &[char]) -> Vec<usize> {   // searching text: a fresh start at every position
    let start = close(Set::from([m.s]), &m.arrows);
    let (mut cur, mut out) = (start.clone(), Vec::new());
    for (i, &c) in w.iter().enumerate() { cur = step(&cur, c, &m.arrows).union(&start).copied().collect(); if cur.contains(&m.e) { out.push(i + 1) } }
    out
}
struct Dfa { n: usize, delta: HashMap<(usize, char), usize>, acc: Set }
fn subset_dfa(m: &Nfa, sigma: &str) -> Dfa {   // each guess-free state is a set of Thompson states
    let (mut names, mut delta, mut i) = (vec![close(Set::from([m.s]), &m.arrows)], HashMap::new(), 0);
    while i < names.len() {
        for c in sigma.chars() {
            let nxt = step(&names[i], c, &m.arrows);
            if nxt.is_empty() { continue } let t = match names.iter().position(|x| *x == nxt) { Some(t) => t, None => { names.push(nxt); names.len() - 1 } };
            delta.insert((i, c), t);
        }
        i += 1;
    }
    let acc = (0..names.len()).filter(|&q| names[q].contains(&m.e)).collect();
    Dfa { n: names.len(), delta, acc }
}
fn dfa_accepts(d: &Dfa, w: &[char]) -> bool {   // one state at a time; None means "fell off the machine"
    let mut q = Some(0);
    for &c in w { q = q.and_then(|x| d.delta.get(&(x, c)).copied()) }
    q.map_or(false, |x| d.acc.contains(&x))
}
fn read_back(d: &Dfa, keep_loop: bool) -> P {   // state elimination: machine -> pattern
    let n = d.n;
    let mut r: Vec<Vec<P>> = vec![vec![None; n + 2]; n + 2];
    r[n][0] = Some(Eps);              // new start n, new finish n + 1
    for &q in &d.acc { r[q][n + 1] = Some(Eps) }
    for q in 0..n { for c in "LD_".chars() { if let Some(&t) = d.delta.get(&(q, c)) { r[q][t] = alt(r[q][t].clone(), sym(c)) } } }
    for k in (0..n).rev() {           // remove state k, rerouting every path through it
        let rest: Vec<usize> = (0..n + 2).filter(|&i| i < k || i >= n).collect();
        let lp = if keep_loop { star(r[k][k].clone()) } else { Some(Eps) };
        for &i in &rest { for &j in &rest { r[i][j] = alt(r[i][j].clone(), seq(vec![r[i][k].clone(), lp.clone(), r[k][j].clone()])) } }
    }
    r[n][n + 1].clone()
}
fn bt(r: &Re, w: &[char], i: usize, k: &dyn Fn(usize) -> bool, cnt: &Cell<u64>) -> bool {   // try, undo, retry
    cnt.set(cnt.get() + 1);
    match r {
        Eps => k(i),
        Sym(c) => i < w.len() && w[i] == *c && k(i + 1),
        Cat(a, b) => bt(a, w, i, &|j| bt(b, w, j, k, cnt), cnt),
        Alt(a, b) => bt(a, w, i, k, cnt) || bt(b, w, i, k, cnt),
        Star(a) => bt(a, w, i, &|j| j > i && bt(r, w, j, k, cnt), cnt) || k(i),
    }
}
fn matches(r: &Re, w: &[char]) -> bool { bt(r, w, 0, &|j| j == w.len(), &Cell::new(0)) }   // reads the pattern itself
fn by_words(w: &str) -> bool { w.len() >= 5 && w.ends_with("DLL") && ["LD", "LDD", "LDL", "LLD", "LLDD", "LLDL"].contains(&w[..w.len() - 3].trim_end_matches('_')) }   // the rule in words
fn classes(t: &str) -> String { t.chars().map(|c| if c.is_ascii_uppercase() { 'L' } else if c.is_ascii_digit() { 'D' } else if c == ' ' { '_' } else { '?' }).collect() }
fn ch(s: &str) -> Vec<char> { s.chars().collect() }
fn yn(ok: bool) -> &'static str { if ok { "accept" } else { "reject" } }
fn commas(x: u64) -> String { let s = x.to_string(); let mut o = String::new(); for (i, c) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(',') } o.push(c) } o }
fn depth(k: u32) -> P { if k == 0 { Some(Eps) } else { star(seq(vec![sym('('), depth(k - 1), sym(')')])) } }
fn main() {
    let (l, d, sp) = (|| sym('L'), || sym('D'), || sym('_'));
    let post = seq(vec![l(), alt(l(), Some(Eps)), d(), alt(l(), alt(d(), Some(Eps))), star(sp()), d(), l(), l()]).unwrap();
    let (nfa, nmax) = (compile_nfa(&post), 9);
    let dfa = subset_dfa(&nfa, "LD_"); let back = read_back(&dfa, true).unwrap();
    println!("pattern {}: {} pieces, so {} Thompson states", show(&post, 0), pieces(&post), 2 * pieces(&post));
    println!("Thompson machine: {} states, {} arrows, {} of them free moves", nfa.n, nfa.arrows.len(), nfa.arrows.iter().filter(|a| a.1.is_none()).count());
    for text in ["SW1A 1AA", "M1 1AE", "SW1A1AA", "SW1A 1A"] {
        let mut tr = Vec::new();
        let ok = nfa_accepts(&nfa, &ch(&classes(text)), &mut tr);
        println!("{:9} reads {:9} live states after each symbol {:?}: {}", text, classes(text), tr, yn(ok));
    }
    println!("guess-free machine: {} states, accepting {:?}", dfa.n, dfa.acc.iter().collect::<Vec<_>>());
    for q in 0..dfa.n {
        let mv: Vec<String> = "LD_".chars().filter_map(|c| dfa.delta.get(&(q, c)).map(|t| format!("{} -> {}", c, t))).collect();
        println!("  state {}: {}", q, if mv.is_empty() { "no moves".to_string() } else { mv.join(", ") });
    }
    println!("read back: {}", show(&back, 0));
    let small = seq(vec![star(sp()), d(), l(), l()]).unwrap(); let sd = subset_dfa(&compile_nfa(&small), "LD_");
    println!("round trip of {} through a {}-state machine: {}", show(&small, 0), sd.n, show(&read_back(&sd, true).unwrap(), 0));
    let (mut words, mut layer) = (vec![String::new()], vec![String::new()]);
    for _ in 0..nmax { layer = layer.iter().flat_map(|w| "LD_".chars().map(move |c| format!("{}{}", w, c))).collect(); words.extend(layer.clone()) }
    let spec: Vec<bool> = words.iter().map(|w| by_words(w)).collect();
    let roads: Vec<(&str, Vec<bool>)> = vec![
        ("Thompson machine", words.iter().map(|w| nfa_accepts(&nfa, &ch(w), &mut Vec::new())).collect()),
        ("guess-free machine", words.iter().map(|w| dfa_accepts(&dfa, &ch(w))).collect()),
        ("pattern read directly", words.iter().map(|w| matches(&post, &ch(w))).collect()),
        ("pattern read back", words.iter().map(|w| matches(&back, &ch(w))).collect())];
    let groups: Vec<usize> = [2, 3, 4].iter().map(|&h| words.iter().zip(&spec).filter(|(w, &s)| s && w.len() - w.matches('_').count() == h + 3).count()).collect();
    println!("all {} strings of L, D, _ up to length {}: {} pass the rule in words; first half 2, 3, 4 long: {:?}", words.len(), nmax, spec.iter().filter(|&&s| s).count(), groups);
    for (name, got) in &roads {
        println!("  {:22} accepts {}, disagrees with the rule on {}", name, got.iter().filter(|&&g| g).count(), got.iter().zip(&spec).filter(|(a, b)| a != b).count());
    }
    let note = "SEND TO SW1A 1AA TODAY";
    let found = search_ends(&nfa, &ch(&classes(note)));
    let starts: Vec<usize> = (0..found[0]).filter(|&j| by_words(&classes(note)[j..found[0]])).collect();
    let quoted: Vec<String> = starts.iter().map(|&j| format!("'{}'", &note[j..found[0]])).collect();
    println!("search '{}': a match ends at {:?}; it can start at {:?}: [{}]", note, found, starts, quoted.join(", "));
    let whole = nfa_accepts(&nfa, &ch(&classes(note)), &mut Vec::new()); println!("the whole note as a postcode: {}", yn(whole));
    let one = seq(vec![l(), alt(l(), Some(Eps)), d(), alt(l(), alt(d(), Some(Eps))), sp(), d(), l(), l()]).unwrap();
    println!("mistake 1, one space in place of _*: accepts {}; SW1A1AA: {}", words.iter().filter(|w| matches(&one, &ch(w))).count(), yn(matches(&one, &ch("LLDLDLL"))));
    let bad = read_back(&dfa, false).unwrap();
    let miss: Vec<&String> = words.iter().zip(&spec).filter(|(w, &s)| s && !matches(&bad, &ch(w))).map(|(w, _)| w).collect();
    println!("mistake 2, elimination without the loop: accepts {}, loses {}, e.g. {}", words.iter().filter(|w| matches(&bad, &ch(w))).count(), miss.len(), miss[0]);
    let (evil, mut cost) = (seq(vec![star(seq(vec![sym('a'), star(sym('a'))])), sym('b')]).unwrap(), Vec::new());
    for n in [5usize, 10, 15, 20] {
        let (w, cnt, mut tr) = (vec!['a'; n], Cell::new(0u64), Vec::new());
        let ok = bt(&evil, &w, 0, &|j| j == n, &cnt);
        let live = if nfa_accepts(&compile_nfa(&evil), &w, &mut tr) == ok { tr.iter().sum::<usize>() as i64 } else { -1 };
        cost.push((n, cnt.get(), live));
        println!("mistake 3, {} on {} a's: backtracking takes {} steps, the live-state run {}", show(&evil, 0), n, commas(cnt.get()), live);
    }
    let b3 = compile_nfa(&depth(3).unwrap());
    let (ok3, ok4) = (nfa_accepts(&b3, &ch("((()))"), &mut Vec::new()), nfa_accepts(&b3, &ch("(((())))"), &mut Vec::new()));
    println!("mistake 4, depth-3 pattern, {} states (depth 4 needs {}): ((())) {}, (((()))) {}", b3.n, compile_nfa(&depth(4).unwrap()).n, yn(ok3), yn(ok4));
    for (name, got) in &roads { assert!(*got == spec, "{}", name) }      // four roads against the rule in words
    assert!(nfa.n == 2 * pieces(&post) && dfa.n == 10);                   // Thompson's count, from the pattern alone
    assert!(starts == vec![8, 9] && !whole);                              // search finds it; a whole match does not
    assert!(cost.iter().all(|&(n, c, t)| c == 3 * (1u64 << (n + 1)) - 1 && t == 8 * n as i64 - 1));   // exponential against linear
    assert!(ok3 && !ok4);                                                 // fixed depth, fixed memory
    println!("ALL CHECKS PASS");
}
