// Busy beaver -- the same check as the Python, in Rust.  No crates.  A tape
// machine has n states, A, B, C, ..., and the symbols 0 and 1.  It starts in
// state A on a blank tape (all 0).  BB(n) is the most steps any n-state machine
// takes before it halts; the halting step counts.  Code never decides halting in
// general: a run either halts, or prints a proof that it never will, or prints
// 'still running' at its cap.  The tape machine is explained on the Turing card.
use std::collections::{HashMap, HashSet};
type Rule = Option<(u8, i64, i64)>;        // write, move (+1 is R), next state (-1 is halt)
const KINDS: [&str; 5] = ["halt", "repeats", "repeats shifted", "no exit", "running"];
fn parse(text: &str) -> Vec<Rule> {         // "1RB1LB_1LA1RZ": per state, the rule for 0, then for 1
    let mut tab = Vec::new();
    for part in text.split('_') {
        for c in [&part.as_bytes()[0..3], &part.as_bytes()[3..6]] {
            tab.push(if c[0] == b'-' { None } else {
                Some((c[0] - b'0', if c[1] == b'R' { 1 } else { -1 }, if c[2] == b'Z' { -1 } else { (c[2] - b'A') as i64 }))
            });
        }
    }
    tab
}
fn show(tab: &[Rule]) -> String {           // the same text form back; Z is halt, --- a rule never needed
    let cells: Vec<String> = tab.iter().map(|x| match x {
        None => "---".to_string(),
        Some((w, m, q)) => format!("{}{}{}", w, if *m > 0 { 'R' } else { 'L' }, if *q < 0 { 'Z' } else { (b'A' + *q as u8) as char }),
    }).collect();
    cells.chunks(2).map(|c| c.concat()).collect::<Vec<_>>().join("_")
}
fn no_exit(tab: &[Rule], q: usize) -> bool { // proof 3: from state q no halting or missing rule can be reached
    let (mut reach, mut todo) = (vec![q], vec![q]);
    while let Some(s) = todo.pop() {
        for x in &tab[2 * s..2 * s + 2] {
            match x {
                Some((_, _, q2)) if *q2 >= 0 => { let q2 = *q2 as usize; if !reach.contains(&q2) { reach.push(q2); todo.push(q2); } }
                _ => return false,
            }
        }
    }
    true
}
fn run(tab: &[Rule], cap: usize, prove: bool) -> (&'static str, usize, usize, usize) {
    let mut tape = vec![0u8; 2 * cap + 3];
    let (mut h, mut lo, mut hi, mut q, mut t) = (cap + 1, cap + 1, cap + 1, 0usize, 0usize);
    let mut seen: HashSet<(usize, usize, usize, Vec<u8>)> = HashSet::new();
    let mut records: HashMap<(i64, usize), Vec<(usize, usize, Vec<u8>)>> = HashMap::new();
    let mut path = vec![h];
    let ones = |tape: &Vec<u8>| tape.iter().map(|&c| c as usize).sum::<usize>();
    while t < cap {
        let k = 2 * q + tape[h] as usize;
        let (w, m, q2) = match tab[k] { None => return ("undefined", t, ones(&tape), k), Some(r) => r };
        tape[h] = w; h = (h as i64 + m) as usize; t += 1; path.push(h);
        if q2 < 0 { return ("halt", t, ones(&tape), k); }
        q = q2 as usize;
        if !prove { continue; }
        if lo <= h && h <= hi {                 // proof 1: the whole configuration comes back
            if !seen.insert((q, h, lo, tape[lo..=hi].to_vec())) { return ("repeats", t, 0, q); }
            continue;
        }
        let side: i64 = if h > hi { 1 } else { -1 };
        lo = lo.min(h); hi = hi.max(h);
        for (t1, p1, old) in records.get(&(side, q)).map(|v| v.as_slice()).unwrap_or(&[]) {
            let d = if side == 1 { p1 - path[*t1..].iter().min().unwrap() } else { path[*t1..].iter().max().unwrap() - p1 };
            let (a, b) = if side == 1 { (p1 - d, h - d) } else { (*p1, h) };   // proof 2: same state at
            if old[a..=a + d] == tape[b..=b + d] { return ("repeats shifted", t, 0, q); } // two new edges
        }
        records.entry((side, q)).or_default().push((t, h, tape.clone()));
    }
    (if prove && no_exit(tab, q) { "no exit" } else { "running" }, t, ones(&tape), q)
}
fn idx(kind: &str) -> usize { KINDS.iter().position(|k| *k == kind).unwrap() }
fn tree(n: usize, cap: usize) -> ([usize; 5], [(usize, String); 2], usize) { // road 2: rules chosen when first needed
    let (mut tally, mut most) = ([0usize; 5], [(0usize, String::new()), (0usize, String::new())]);
    let (mut todo, mut broken): (Vec<Vec<Rule>>, usize) = (vec![vec![None; 2 * n]], 0);
    while let Some(tab) = todo.pop() {
        let (verdict, t, ones, k) = run(&tab, cap, true);
        if verdict != "undefined" {           // each proof is tested by a plain run twice as long
            tally[idx(verdict)] += 1; broken += (verdict != "running" && run(&tab, 2 * cap, false).0 != "running") as usize; continue;
        }
        tally[0] += 1;                          // choice 1: the missing rule writes 1, moves R and halts
        let mut done = tab.clone(); done[k] = Some((1, 1, -1));
        if t + 1 > most[0].0 { most[0] = (t + 1, show(&done)); }
        if ones + 1 - k % 2 > most[1].0 { most[1] = (ones + 1 - k % 2, show(&done)); }
        let used = 1 + tab.iter().flatten().map(|x| x.2).max().unwrap_or(0).max(0) as usize;
        for q2 in 0..(used + 1).min(n) {        // choice 2: any rule, states named in order of use
            for w in [0u8, 1] {
                for m in [-1i64, 1] { let mut child = tab.clone(); child[k] = Some((w, m, q2 as i64)); todo.push(child); }
            }
        }
    }
    (tally, most, broken)
}
fn brute(n: usize, cap: usize) -> ([usize; 5], [usize; 2], usize, usize) { // road 1: every complete rule table
    let mut rules = Vec::new();
    for w in [0u8, 1] { for m in [1i64, -1] { for q in -1..n as i64 { rules.push((w, m, q)); } } }
    let (mut tally, mut most, mut early, mut broken) = ([0usize; 5], [0usize; 2], 0usize, 0usize);
    for code in 0..rules.len().pow(2 * n as u32) {
        let mut c = code;
        let tab: Vec<Rule> = (0..2 * n).map(|_| { let r = rules[c % rules.len()]; c /= rules.len(); Some(r) }).collect();
        let (verdict, t, ones, _) = run(&tab, cap, true);
        tally[idx(verdict)] += 1;
        if verdict == "halt" { most = [most[0].max(t), most[1].max(ones)]; early += (t <= 6) as usize; }
        else if run(&tab, 2 * cap, false).0 != "running" { broken += 1; }
    }
    (tally, most, early, broken)
}
fn long_run(tab: &[Rule], skip: bool) -> (usize, usize, usize) { // 40,000 cells, head in the middle
    let mut tape = vec![0u8; 40000];
    let (mut h, mut q, mut t, mut passes) = (20000usize, 0i64, 0usize, 0usize);
    while q >= 0 {
        passes += 1; let r = tape[h];
        let (w, m, q2) = tab[2 * q as usize + r as usize].unwrap();
        if skip && r == 1 && w == 1 && q2 == q { // road 4: a rule that keeps its state and its 1
            let mut j = h;                      // crosses the run of 1s at once
            while tape[j] != 0 { j = (j as i64 + m) as usize; }
            t += j.abs_diff(h); h = j; continue;
        }
        tape[h] = w; h = (h as i64 + m) as usize; q = q2; t += 1;
    }
    (t, tape.iter().map(|&c| c as usize).sum(), passes)
}
fn tally_text(c: &[usize; 5]) -> String { (0..5).map(|i| format!("{} {}", KINDS[i], c[i])).collect::<Vec<_>>().join(", ") }
fn main() {
    println!("choices for one rule, 1 to 5 states: {}", (1..6u64).map(|n| (4 * (n + 1)).to_string()).collect::<Vec<_>>().join(", "));
    println!("machines with 1 to 5 states: {}", (1..6u64).map(|n| (4 * (n + 1)).pow(2 * n as u32).to_string()).collect::<Vec<_>>().join(", "));
    let (b1, b2) = (brute(1, 100), brute(2, 100));
    for (n, b) in [(1, &b1), (2, &b2)] {
        println!("every {}-state machine, cap 100: {}; most steps {}, most ones {}", n, tally_text(&b.0), b.1[0], b.1[1]);
        println!("  proofs that a plain run to step 200 contradicts: {}", b.3);
    }
    println!("halting test built on BB(2) = 6: halted by step 6 {}, halted later {}, proved never to halt {}",
             b2.2, b2.0[0] - b2.2, b2.0[1] + b2.0[2] + b2.0[3]);
    let mut found = Vec::new();
    for (n, cap) in [(1usize, 100usize), (2, 100), (3, 300)] {
        let (c, most, broken) = tree(n, cap);
        println!("tree search, {} state{}, cap {}: {}", n, if n > 1 { "s" } else { "" }, cap, tally_text(&c));
        println!("  proofs that a plain run to step {} contradicts: {}", 2 * cap, broken);
        println!("  most steps {} by {}; most ones {} by {}", most[0].0, most[0].1, most[1].0, most[1].1);
        found.push((c, most, broken));
    }
    let (two, mut tape, mut h, mut q) = (parse("1RB1LB_1LA1RZ"), HashMap::new(), 0i64, 0i64);
    for step in 1..7 {                          // the two-state champion, step by step, cells -2 to 1
        let r = *tape.get(&h).unwrap_or(&0u8);
        let (w, m, q2) = two[(2 * q) as usize + r as usize].unwrap();
        tape.insert(h, w); h += m;
        let cells: Vec<String> = (-2..2).map(|i| { let v = *tape.get(&i).unwrap_or(&0); if i == h { format!("[{}]", v) } else { v.to_string() } }).collect();
        println!("step {}: state {} reads {}, writes {}, moves {}, next {}; tape {}", step, ["A", "B"][q as usize], r, w,
                 if m > 0 { "R" } else { "L" }, if q2 < 0 { "Z" } else { ["A", "B"][q2 as usize] }, cells.join(" "));
        q = q2;
    }
    let (four, five) = (parse("1RB1LB_1LA0LC_1RZ1LD_1RD0RA"), parse("1RB1LC_1RC1RB_1RD0LE_1LA1LD_1RZ0LA"));
    let (v100, v4) = (run(&four, 100, false), run(&four, 1000, false));
    println!("four-state champion, cap 100: {}", if v100.0 == "running" { "still running after 100 steps" } else { v100.0 });
    println!("four-state champion, cap 1000: {} after {} steps, {} ones", if v4.0 == "halt" { "halts" } else { v4.0 }, v4.1, v4.2);
    let (p5, s5) = (long_run(&five, false), long_run(&five, true));
    println!("five-state champion, one step at a time: halts after {} steps, {} loop passes, {} ones", p5.0, p5.2, p5.1);
    println!("five-state champion, runs of 1s crossed at once: halts after {} steps, {} loop passes, {} ones", s5.0, s5.2, s5.1);
    println!("mistakes: cap 100 on the four-state champion says {}; ones instead of steps {} and {}; halting step not counted {}; never-halting 1RA1RA let in at cap 100: {}",
             v100.0, v4.2, p5.1, found[1].1[0].0 - 1, run(&parse("1RA1RA"), 100, false).1);
    let bb: Vec<usize> = vec![found[0].1[0].0, found[1].1[0].0, found[2].1[0].0, v4.1, p5.0];
    println!("chart, log10 BB(n): {}", bb.iter().map(|&x| format!("{:.3}", (x as f64).log10())).collect::<Vec<_>>().join(", "));
    println!("n^n for n = 1 to 5: {}", (1..6u32).map(|n| n.pow(n).to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, log10 n^n:   {}", (1..6u32).map(|n| format!("{:.3}", (n.pow(n) as f64).log10())).collect::<Vec<_>>().join(", "));
    assert!(b1.1 == [1, 1] && b2.1 == [6, 4] && b2.0[4] == 0 && b2.2 == b2.0[0]);
    assert!(b1.3 == 0 && b2.3 == 0 && found.iter().all(|f| f.2 == 0)); // proofs against plain runs
    assert!(bb[..3] == [1, 6, 21] && found.iter().map(|f| f.1[1].0).collect::<Vec<_>>() == [1, 4, 6]);
    assert!(found[1].0[4] == 0 && v100.0 == "running" && (v4.0, v4.1, v4.2) == ("halt", 107, 13));
    assert!((p5.0, p5.1) == (47176870, 4098) && (s5.0, s5.1) == (47176870, 4098) && s5.2 < p5.2); // published 2024 value
    assert!(vec![b1.0.iter().sum::<usize>(), b2.0.iter().sum()] == (1..3usize).map(|n| (4 * (n + 1)).pow(2 * n as u32)).collect::<Vec<_>>()); // every table run
    assert!(b2.0 == [9784, 430, 10510, 12, 0] && found[2].0[4] == 110); // the tallies on the card
    println!("ALL CHECKS PASS");
}
