// Guessing machines -- the same check as the Python, in Rust.  No crates.
// A guessing machine (NFA) watches a payment log for "cash" or "card".  The
// subset construction turns it into an ordinary machine (DFA) whose states are
// sets of guessing-machine states, kept here as bit masks (bit q = state q).
// Three roads must agree on every string: the DFA, a search that tries every
// guess in turn, and a written-out scan.
use std::collections::HashMap;

const SIGMA: &str = "abcdefghijklmnopqrstuvwxyz0123456789 .:"; // 39 symbols
const NAMES: [&str; 11] = ["S", "A0", "A1", "A2", "A3", "A4", "B0", "B1", "B2", "B3", "B4"];
const EPS: char = '\0'; // the label of an epsilon-move

type Nfa = HashMap<(usize, char), Vec<usize>>;

fn add(d: &mut Nfa, p: usize, a: char, q: usize) { let v = d.entry((p, a)).or_default(); if !v.contains(&q) { v.push(q) } }

fn payment_nfa() -> Nfa { // S, then A watches for cash, B for card
    let mut d = Nfa::new();
    for q in [1, 6] { add(&mut d, 0, EPS, q) } // S guesses: run A and B, both at once
    for (base, word) in [(1, "cash"), (6, "card")] {
        for a in SIGMA.chars() {
            add(&mut d, base, a, base); // not started yet: wait
            add(&mut d, base + 4, a, base + 4); // word seen: stay happy
        }
        for (i, ch) in word.chars().enumerate() { add(&mut d, base + i, ch, base + i + 1) }
    }
    d
}

fn moves(d: &Nfa, p: usize, a: char) -> &[usize] { d.get(&(p, a)).map(|v| v.as_slice()).unwrap_or(&[]) }

fn closure(d: &Nfa, set: u32) -> u32 { // add everything epsilon-moves reach
    let (mut seen, mut todo) = (set, members(set));
    while let Some(p) = todo.pop() {
        for &q in moves(d, p, EPS) {
            if seen >> q & 1 == 0 { seen |= 1 << q; todo.push(q) }
        }
    }
    seen
}

fn step(d: &Nfa, set: u32, a: char) -> u32 {
    let out = members(set).iter().flat_map(|&p| moves(d, p, a)).fold(0, |o, &q| o | 1 << q);
    closure(d, out)
}

fn subset_construction(d: &Nfa, start: usize, alphabet: &str) -> (u32, HashMap<(u32, char), u32>) {
    let first = closure(d, 1 << start); // road one
    let (mut table, mut seen, mut todo) = (HashMap::new(), vec![first], vec![first]);
    while let Some(t) = todo.pop() {
        for a in alphabet.chars() {
            let u = step(d, t, a);
            table.insert((t, a), u);
            if !seen.contains(&u) { seen.push(u); todo.push(u) }
        }
    }
    (first, table)
}

fn run(first: u32, table: &HashMap<(u32, char), u32>, w: &str) -> u32 { // follow the DFA table
    w.chars().fold(first, |t, a| table[&(t, a)])
}

fn dfa_accepts(first: u32, table: &HashMap<(u32, char), u32>, accept: u32, w: &str) -> bool {
    run(first, table, w) & accept != 0
}

fn guess_accepts(d: &Nfa, accept: u32, p: usize, w: &[char], i: usize) -> bool { // road two
    if i == w.len() && accept >> p & 1 == 1 { return true }
    if moves(d, p, EPS).iter().any(|&q| guess_accepts(d, accept, q, w, i)) { return true }
    i < w.len() && moves(d, p, w[i]).iter().any(|&q| guess_accepts(d, accept, q, w, i + 1))
}

fn contains(w: &[char], word: &str) -> bool { // road three: plain scan
    let word: Vec<char> = word.chars().collect();
    w.len() >= word.len() && (0..=w.len() - word.len()).any(|s| (0..word.len()).all(|j| w[s + j] == word[j]))
}

fn naive(w: &[char]) -> bool { // the usual mistake: reset on a mismatch
    for word in ["cash", "card"] {
        let word: Vec<char> = word.chars().collect();
        let mut k = 0;
        for &a in w {
            k = if a == word[k] { k + 1 } else { 0 };
            if k == word.len() { return true }
        }
    }
    false
}

fn members(t: u32) -> Vec<usize> { (0..32).filter(|q| t >> q & 1 == 1).collect() }
fn show(t: u32) -> String { format!("{{{}}}", members(t).iter().map(|&q| NAMES[q]).collect::<Vec<_>>().join(" ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (d, s, f) = (payment_nfa(), 0usize, (1u32 << 5) | (1 << 10));
    let (first, table) = subset_construction(&d, s, SIGMA);
    let mut reached: Vec<u32> = table.keys().map(|k| k.0).collect();
    reached.sort_by_key(|&t| members(t)); reached.dedup();
    let happy = reached.iter().filter(|&&t| t & f != 0).count();
    println!("guessing machine: {} states, {} symbols, {} possible sets", NAMES.len(), SIGMA.len(), 1 << NAMES.len());
    println!("subset construction reaches {} sets, {} of them accepting; table {} x {} = {} entries",
             reached.len(), happy, reached.len(), SIGMA.len(), reached.len() * SIGMA.len());
    for &t in &reached { println!("  set {}{}", show(t), if t & f != 0 { " accept" } else { "" }) }
    let mut kinds: Vec<String> = reached.iter().filter(|&&t| t & 1 == 0).map(|&t| show(t & !(1 << 1 | 1 << 5 | 1 << 6 | 1 << 10))).collect();
    kinds.sort(); kinds.dedup(); // drop A0, A4, B0, B4
    println!("after the start set, partial matches beside A0 B0 A4 B4: {} kinds, {}", kinds.len(), kinds.join(" "));
    let (w, mut t) = ("paid ccard", first);
    println!("trace of '{}': start {}", w, show(t));
    for a in w.chars() { t = table[&(t, a)]; println!("  read '{}' -> {}", a, show(t)) }
    let logs = ["09:14 latte 3.20 card", "09:20 cashback 5.00", "09:31 cart refund 2.80",
                "09:40 paid ccard 4.10", "09:52 voucher 1.50"];
    let mut verdicts = Vec::new();
    for line in logs {
        let c: Vec<char> = line.chars().collect();
        let v = [dfa_accepts(first, &table, f, line), guess_accepts(&d, f, s, &c, 0),
                 contains(&c, "cash") || contains(&c, "card"), naive(&c)];
        println!("log '{}': dfa {}, guesses {}, scan {}, reset-scan {}", line, yn(v[0]), yn(v[1]), yn(v[2]), yn(v[3]));
        verdicts.push(v);
    }
    let small = "cashrdx"; // x stands for every other symbol
    let mut words: Vec<String> = vec![String::new()];
    for n in 0..6 {
        let longer: Vec<String> = words.iter().filter(|u| u.len() == n)
            .flat_map(|u| small.chars().map(move |a| format!("{}{}", u, a))).collect();
        words.extend(longer);
    }
    let (mut agree, mut naive_wrong) = (0, 0);
    for u in &words {
        let c: Vec<char> = u.chars().collect();
        let a = dfa_accepts(first, &table, f, u);
        if a == guess_accepts(&d, f, s, &c, 0) && a == (contains(&c, "cash") || contains(&c, "card")) { agree += 1 }
        if naive(&c) != a { naive_wrong += 1 }
    }
    println!("all {} strings over '{}' up to length 6: three roads agree on {}; the reset-scan disagrees on {}",
             words.len(), small, agree, naive_wrong);
    let mut t = 1u32 << s; // two more mistakes, on the card line
    for a in logs[0].chars() { t = step(&d, t, a) }
    let (no_closure, all_must) = (t & f != 0, run(first, &table, logs[0]) & !f == 0);
    println!("mistakes on '{}': start without epsilon-moves {}, every guess must accept {}", logs[0], yn(no_closure), yn(all_must));
    let (mut ends, mut pair): (Vec<u32>, Vec<&str>) = (Vec::new(), Vec::new());
    let mut growth = Vec::new();
    for k in 1..=10usize { // "the k-th symbol from the end is c"
        let mut dk = Nfa::new();
        for a in "cx".chars() { add(&mut dk, 0, a, 0); for i in 1..k { add(&mut dk, i, a, i + 1) } } // 0 waits, 1.. count
        add(&mut dk, 0, 'c', 1); // at a c, guess "this is the one"
        let (fk, tk) = subset_construction(&dk, 0, "cx");
        if k == 3 { // where the 8 strings of length 3 end up
            for u in ["ccc", "ccx", "cxc", "cxx", "xcc", "xcx", "xxc", "xxx"] { ends.push(run(fk, &tk, u)) }
            ends.sort(); ends.dedup();
            pair = ["ccxx", "cxxx"].iter().map(|u| if dfa_accepts(fk, &tk, 1 << 3, u) { "accept" } else { "reject" }).collect();
        }
        let mut sets: Vec<u32> = tk.keys().map(|k| k.0).collect();
        sets.sort(); sets.dedup();
        growth.push(sets.len());
        println!("k = {:2}: guessing machine {:2} states, subset machine {:4} states", k, k + 1, sets.len());
    }
    assert!(agree == words.len() && words.len() == 137257); // three roads, every string
    assert!(verdicts.iter().map(|v| v[0]).collect::<Vec<_>>() == vec![true, true, false, true, false]);
    assert!(verdicts.iter().all(|v| v[0] == v[1] && v[1] == v[2]) && !verdicts[3][3]);
    assert!(growth == (1..=10).map(|k| 1usize << k).collect::<Vec<_>>()); // the blow-up is real
    assert!(reached.len() == 1 + 5 * 2 * 2 && happy == 5 * 3 && naive_wrong > 0); // the count by hand
    let mut tiny = Nfa::new(); add(&mut tiny, 0, 'c', 1); add(&mut tiny, 1, EPS, 2);
    assert!(step(&tiny, 1 << 0, 'c') == 1 << 1 | 1 << 2); // epsilon after a symbol: closure needed
    println!("k = 3: the 8 strings of length 3 end in {} different sets; with 4 states two share one, such as ccx and cxx, yet the ending x needs ccxx {}, cxxx {}",
        ends.len(), pair[0], pair[1]);
    assert!(!no_closure && !all_must && ends.len() == 8 && pair == ["accept", "reject"]); // each piece is needed
    println!("ALL CHECKS PASS");
}
