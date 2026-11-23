// Turing machines -- the check behind the card.  Rust std only, no crates.
// The tape machine below is the shelf's simulator kit; later cards copy it.
// A rule table is plain text, one row per line: state read write move next.
use std::collections::{BTreeMap, HashMap, HashSet};
const B: char = '_'; // the blank symbol; the card writes it as an open box
type Rules = HashMap<(String, char), (char, char, String)>;

fn table(text: &str) -> Rules {
    let mut r = Rules::new();
    for l in text.trim().lines() {
        let f: Vec<&str> = l.split_whitespace().collect();
        let c = |i: usize| f[i].chars().next().unwrap();
        r.insert((f[0].to_string(), c(1)), (c(2), c(3), f[4].to_string()));
    }
    r
}
fn show(tape: &BTreeMap<i64, char>, head: i64) -> String {
    let lo = (*tape.keys().next().unwrap()).min(head);
    let hi = (*tape.keys().last().unwrap()).max(head);
    (lo..=hi).map(|i| { let c = *tape.get(&i).unwrap_or(&B);
        if i == head { format!("[{}]", c) } else { c.to_string() } }).collect()
}

// Halts when the table has no row for (state, symbol under the head).
fn run(rules: &Rules, word: &str, start: &str, cap: usize, mut trace: Option<&mut Vec<String>>) -> (Option<String>, String, usize) {
    let mut tape: BTreeMap<i64, char> = word.chars().enumerate().map(|(i, c)| (i as i64, c)).collect();
    let (mut head, mut state, mut steps) = (0i64, start.to_string(), 0usize);
    loop {
        let read = *tape.get(&head).unwrap_or(&B);
        let Some((write, mv, nxt)) = rules.get(&(state.clone(), read)) else { break };
        if steps == cap { return (None, state, steps); }
        tape.insert(head, *write);
        head += if *mv == 'R' { 1 } else { -1 };
        steps += 1;
        if let Some(t) = trace.as_mut() {
            t.push(format!("{:>4}  {:<6} {}  {} {}  {:<6} {}", steps, state, read, write, mv, nxt, show(&tape, head)));
        }
        state = nxt.clone();
    }
    let s: String = tape.values().collect();
    (Some(s.trim_matches(B).to_string()), state, steps)
}

const ADD_ONE: &str = "
right 0 0 R right
right 1 1 R right
right _ _ L carry
carry 1 0 L carry
carry 0 1 L done
carry _ 1 L done";
fn value(s: &str) -> u64 { s.chars().fold(0, |v, c| 2 * v + (c == '1') as u64) } // road 2: place value
fn binary(mut v: u64, width: usize) -> String {
    let mut s = String::new();
    while v > 0 { s.insert(0, if v % 2 == 1 { '1' } else { '0' }); v /= 2; }
    format!("{:0>w$}", s, w = width)
}
fn trailing_ones(s: &str) -> usize { s.len() - s.trim_end_matches('1').len() }

const BRACKETS: &str = "
seek ( ( R seek
seek X X R seek
seek ) X L back
seek _ _ L check
back X X L back
back ( X R seek
back _ _ R reject
check X X L check
check ( ( R reject
check _ _ R accept";
// The stack machine, copied from the Grammars and a stack card (path, cap and progress tracking cut); it returns
// its accepting run's move count, or None.  A move is (state, read, pop, push, next); "" means read or pop nothing.
type Mv = (&'static str, &'static str, &'static str, &'static str, &'static str);
fn stack_machine(moves: &[Mv], w: &str, start: &str) -> Option<usize> {
    let (mut todo, mut seen) = (vec![(start.to_string(), 0usize, "Z".to_string(), 0usize)], HashSet::new()); // Z marks the stack's bottom; the last number counts moves
    while let Some((q, i, st, k)) = todo.pop() {
        if q == "yes" && i == w.len() { return Some(k); }
        if !seen.insert((q.clone(), i, st.clone())) { continue; }
        for &(p, a, x, y, r) in moves.iter().rev() {
            if p != q || (!a.is_empty() && w.get(i..i + 1) != Some(a)) || !st.ends_with(x) { continue; }
            let (s2, i2) = (format!("{}{}", &st[..st.len() - x.len()], y.chars().rev().collect::<String>()), i + a.len());
            if s2.len() > w.len() - i2 + 1 { continue; }
            todo.push((r.to_string(), i2, s2, k + 1));
        }
    }
    None
}
const NEST: [Mv; 3] = [("up", "(", "", "(", "up"), ("up", ")", "(", "", "up"), ("up", "", "Z", "", "yes")];
fn main() {
    const CAP: usize = 100000;
    let add = table(ADD_ONE);
    // ---- the odometer: 10111 is 23 miles; one more mile ----
    let mut trace = Vec::new();
    let (out, state, steps) = run(&add, "10111", "right", CAP, Some(&mut trace)); let out = out.unwrap();
    println!("add one to 10111 = {}; step  state  read  write move  next  tape after, head in [ ]", value("10111"));
    println!("{}", trace.join("\n"));
    println!("result {} = {}, halted in {} after {} steps", out, value(&out), state, steps);
    assert!(out == binary(value("10111") + 1, 5) && out == "11000");
    assert!(state == "done" && trace.iter().map(|l| l.split_whitespace().last().unwrap()).collect::<Vec<_>>() == "1[0]111 10[1]11 101[1]1 1011[1] 10111[_] 1011[1]_ 101[1]0_ 10[1]00_ 1[0]000_ [1]1000_".split(' ').collect::<Vec<_>>());
    let (n, t) = (5, trailing_ones("10111"));
    println!("steps = n + t + 2 = {} + {} + 2 = {}", n, t, n + t + 2);
    assert!(steps == n + t + 2);

    // ---- every odometer reading of 1 to 10 digits: machine against arithmetic ----
    let (mut count, mut good_value, mut good_steps) = (0, 0, 0);
    for width in 1..=10usize {
        for v in 0..(1u64 << width) {
            let s = binary(v, width);
            let (o, q, k) = run(&add, &s, "right", CAP, None); let o = o.unwrap();
            count += 1;
            if q == "done" && value(&o) == v + 1 && o.len() == width.max(binary(v + 1, 1).len()) { good_value += 1; }
            if k == width + trailing_ones(&s) + 2 { good_steps += 1; }
        }
    }
    println!("readings checked {}; value + 1 agrees {}; steps = n + t + 2 {}", count, good_value, good_steps);
    assert!(count == 2046 && good_value == 2046 && good_steps == 2046);
    let worst: Vec<String> = [5, 10, 20].iter().map(|&w| format!("n={}:{}", w, run(&add, &"1".repeat(w), "right", CAP, None).2)).collect();
    println!("worst case, all ones: {}", worst.join("  "));

    // ---- what breaks ----
    let mut no_blank = add.clone();
    no_blank.remove(&("carry".to_string(), B));
    let (o, q, _) = run(&no_blank, "11111", "right", CAP, None); let o = o.unwrap();
    println!("wrong: no (carry, _) row, 11111 -> {} = {}, halted in {}", o, value(&o), q);
    assert!(value(&o) != value("11111") + 1);
    let mut moves_r = add.clone();
    moves_r.insert(("carry".to_string(), '1'), ('0', 'R', "carry".to_string()));
    let o = run(&moves_r, "10111", "right", CAP, None).0.unwrap();
    println!("wrong: carry moves R, 10111 -> {} = {}", o, value(&o));
    let o = run(&add, "10111", "carry", CAP, None).0.unwrap();
    println!("wrong: carry starts at the left end, 10111 -> {} = {}", o, value(&o));
    let capped = run(&add, "11111", "right", 11, None);
    println!("wrong: cap of 11 steps on 11111 -> still running after {} steps (it halts at step 12)", capped.2);
    assert!(capped.0.is_none() && run(&add, "11111", "right", CAP, None).2 == 12);

    // ---- the bracket checker: cross off each ) with the nearest open ( to its left ----
    let br = table(BRACKETS);
    for w in ["(()())", "(()", "())("] {
        let (o, q, k) = run(&br, w, "seek", CAP, None);
        println!("brackets {:<7} -> {} after {} steps, tape {}", w, q, k, o.unwrap());
    }
    let (mut agree, mut balanced, mut worst) = (0, [0u64; 13], vec![(0usize, String::new()); 13]);
    for length in 0..13usize {
        for code in 0..(1u32 << length) {
            let w: String = (0..length).map(|i| if (code >> i) & 1 == 1 { ')' } else { '(' }).collect();
            let (_, q, k) = run(&br, &w, "seek", CAP, None);
            if (q == "accept") == stack_machine(&NEST, &w, "up").is_some() { agree += 1; }
            if q == "accept" { balanced[length] += 1; }
            if k > worst[length].0 { worst[length] = (k, w); } // the first string with the most steps
        }
    }
    println!("bracket strings of length 0 to 12: {}; tape machine agrees with stack machine on {}", (1 << 13) - 1, agree);
    assert!(agree == (1 << 13) - 1);
    let mut catalan = vec![1u64];
    for k in 1..7u64 { let c = catalan[catalan.len() - 1] * 2 * (2 * k - 1) / (k + 1); catalan.push(c); }
    let bal: Vec<String> = (0..7).map(|k| balanced[2 * k].to_string()).collect();
    let cat: Vec<String> = catalan.iter().map(|c| c.to_string()).collect();
    println!("balanced strings of length 0,2,..,12: {} | Catalan: {}", bal.join(" "), cat.join(" "));
    assert!((0..7).all(|k| balanced[2 * k] == catalan[k]));
    let sm: Vec<(usize, usize)> = [4, 8, 12].iter().map(|&m| (m, stack_machine(&NEST, &worst[m].1, "up").unwrap())).collect(); // stack moves on the same worst strings
    let ws: Vec<String> = sm.iter().map(|&(m, s)| format!("n={}:{}/{}", m, worst[m].0, s)).collect();
    println!("worst-case steps, tape machine against stack machine: {}", ws.join("  "));
    assert!(sm.iter().all(|&(m, s)| s == m + 1)); // one move per bracket, then one to pop the bottom marker

    // ---- try changing ----
    for w in ["11111", "0", "0111"] {
        let (o, _, k) = run(&add, w, "right", CAP, None); let o = o.unwrap();
        println!("try: {} -> {} = {} in {} steps", w, o, value(&o), k);
    }
    println!("ALL CHECKS PASS");
}
