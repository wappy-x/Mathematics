// Rice's theorem and reductions -- the same check as the Python, in Rust.  No
// crates.  The tape machine is the one explained on the Turing-machines card;
// here a rule may also carry one side effect: delete a file.  The code never
// decides the undecidable.  It runs the reduction f, which turns a machine M and
// an input w into a macro, and checks on seven machines that the macro deletes a
// file exactly when M stops on w.  Road one runs M; road two runs the macro.
use std::collections::{BTreeMap, HashMap, HashSet};

const B: char = '_';
const SYMS: [char; 3] = ['_', '0', '1'];
const CAP: usize = 1000;
type Rules = HashMap<(String, char), (char, char, String, bool)>;

// "A_:1RB" means: in A reading _, write 1, go R, enter B; a trailing "!" deletes a file
fn table(text: &str) -> Rules {
    let mut out = Rules::new();
    for t in text.split_whitespace() {
        let c: Vec<char> = t.chars().collect();
        let next: String = c[5..].iter().filter(|&&x| x != '!').collect();
        out.insert((c[0].to_string(), c[1]), (c[3], c[4], next, t.ends_with('!')));
    }
    out
}

struct Run { verdict: &'static str, step: usize, deletes: Vec<usize>, ones: usize }

// Run until the machine stops (it enters the halt state H, or no row applies),
// a repeated configuration (a proof of looping), or the cap.
fn run(rules: &Rules, start: &str, w: &str, cap: usize) -> Run {
    let mut tape: BTreeMap<i64, char> = w.chars().enumerate().map(|(i, c)| (i as i64, c)).collect();
    let (mut head, mut state, mut deletes) = (0i64, start.to_string(), Vec::new());
    let snap = |t: &BTreeMap<i64, char>| -> Vec<(i64, char)> {
        t.iter().filter(|(_, &v)| v != B).map(|(&k, &v)| (k, v)).collect()
    };
    let mut seen: HashSet<(String, i64, Vec<(i64, char)>)> = HashSet::new();
    seen.insert((state.clone(), head, tape.iter().map(|(&k, &v)| (k, v)).collect()));
    for step in 1..=cap {
        let read = *tape.get(&head).unwrap_or(&B);
        let Some(rule) = rules.get(&(state.clone(), read)) else {   // no row: stopped after step - 1 steps
            let ones = tape.values().filter(|&&v| v == '1').count();
            return Run { verdict: "halts", step: step - 1, deletes, ones };
        };
        let (write, mv, next, act) = rule.clone();
        tape.insert(head, write);
        head += if mv == 'R' { 1 } else { -1 };
        state = next;
        if act { deletes.push(step) }
        if state == "H" {
            let ones = tape.values().filter(|&&v| v == '1').count();
            return Run { verdict: "halts", step, deletes, ones };
        }
        let config = (state.clone(), head, snap(&tape));
        if seen.contains(&config) { return Run { verdict: "repeats", step, deletes, ones: 0 } }
        seen.insert(config);
    }
    Run { verdict: "running", step: cap, deletes, ones: 0 }
}

// The reduction f: a macro that writes w, walks back, runs M with its own deletes
// switched off, and deletes one file only if M stops: enters H, or meets a missing row.
fn reduce_to_macro(m: &Rules, w: &str, disarm: bool) -> (Rules, String) {
    let (wc, mut out): (Vec<char>, Rules) = (w.chars().collect(), Rules::new());
    let n = wc.len();
    for (i, &ch) in wc.iter().enumerate() {                 // writing phase: n steps
        let next = if i + 1 < n { format!("w{}", i + 1) } else { "b0".to_string() };
        for &s in &SYMS { out.insert((format!("w{}", i), s), (ch, 'R', next.clone(), false)); }
    }
    for j in 0..n {                                         // walking back: n steps
        let next = if j + 1 < n { format!("b{}", j + 1) } else { "m.A".to_string() };
        for &s in &SYMS { out.insert((format!("b{}", j), s), (s, 'L', next.clone(), false)); }
    }
    for ((q, s), (wr, mv, nx, act)) in m.iter() {
        let next = if nx == "H" { "DEL".to_string() } else { format!("m.{}", nx) };
        out.insert((format!("m.{}", q), *s), (*wr, *mv, next, *act && !disarm));
    }
    let mut states: HashSet<String> = m.iter().flat_map(|((q, _), r)| [q.clone(), r.2.clone()]).collect();
    states.insert("A".to_string());
    states.remove("H");
    for q in states {                                       // M has no row here, so it stops: delete, then stop
        for &s in &SYMS { out.entry((format!("m.{}", q), s)).or_insert((s, 'R', "H".to_string(), true)); }
    }
    for &s in &SYMS { out.insert(("DEL".to_string(), s), (s, 'R', "H".to_string(), true)); }
    (out, if n > 0 { "w0".to_string() } else { "m.A".to_string() })
}

// never "loops" without a repeated configuration
fn say(v: &str, k: usize) -> String {
    match v {
        "halts" => format!("halts at step {}", k),
        "repeats" => format!("loops: configuration repeats at step {}", k),
        _ => format!("still running after {} steps", k),
    }
}

fn main() {
    let machines = [
        ("flip", "A0:1RA A1:0RA A_:_RH", "10"),
        ("bb2", "A_:1RB A1:1LB B_:1LA B1:1RH", ""),
        ("bb4", "A_:1RB A1:1LB B_:1LA B1:_LC C_:1RH C1:1LD D_:1RD D1:_RA", ""),
        ("pingpong", "A_:_RB A1:1RB B_:_LA B1:1LA", ""),
        ("rightward", "A_:_RA A0:0RA A1:1RA", ""),
        ("delete-loop", "A_:_RB! B_:_LC C_:_RB", ""),
        ("flip-norow", "A0:1RA A1:0RA", "10"),   // flip with no blank row: stops where no row applies
    ];
    println!("{:<12} | {:<5} | {:<40} | road two: the macro f(M, w)", "machine", "input", "road one: M on w");
    let mut results: HashMap<&str, (Run, Run, Rules, String)> = HashMap::new();
    let mut agree = 0;
    for &(name, text, w) in machines.iter() {
        let m = table(text);
        let r1 = run(&m, "A", w, CAP);
        let (macro_rules, start) = reduce_to_macro(&m, w, true);
        let r2 = run(&macro_rules, &start, "", CAP + 2 * w.len() + 1);
        let mut one = say(r1.verdict, r1.step);
        if name.starts_with("bb") && r1.verdict == "halts" { one += &format!(", {} ones on the tape", r1.ones) }
        let two = if !r2.deletes.is_empty() {
            format!("deletes a file at step {}, then halts", r2.deletes[0])
        } else { say(r2.verdict, r2.step) + ", no delete" };
        println!("{:<12} | {:<5} | {:<40} | {}", name, if w.is_empty() { "-" } else { w }, one, two);
        if r1.verdict == "halts" {          // yes goes to yes, at the predicted step 2n + k + 1
            assert!(r2.deletes == vec![2 * w.len() + r1.step + 1] && r2.verdict == "halts");
            agree += 1;
        } else if r1.verdict == "repeats" { // a proved loop goes to a proved loop with no delete
            assert!(r2.deletes.is_empty() && r2.verdict == "repeats" && r2.step == 2 * w.len() + r1.step);
            agree += 1;
        } else {                            // unknown stays unknown, and no delete within the cap
            assert!(r2.deletes.is_empty() && r2.verdict == "running");
            agree += 1;
        }
        results.insert(name, (r1, r2, macro_rules, start));
    }
    println!("machines checked: {}; macro deletes exactly when M stops: {} of {}", machines.len(), agree, machines.len());
    let n_flip = machines[0].2.len();
    let flip_k = results["flip"].0.step;
    println!("flip on {}: write {} + walk back {} + run {} + delete 1 = step {}", machines[0].2, n_flip, n_flip, flip_k, 2 * n_flip + flip_k + 1);
    assert!(results["bb2"].0.step == 6 && results["bb2"].0.ones == 4);      // the published 2-state record
    assert!(results["bb4"].0.step == 107 && results["bb4"].0.ones == 13);   // Brady's 1983 4-state record
    assert!(results["rightward"].0.verdict == "running");

    println!("what breaks:");
    let (_, bb4_two, bb4_macro, bb4_start) = &results["bb4"];
    let capped = run(bb4_macro, bb4_start, "", 100);
    println!("  sandbox capped at 100 steps on f(bb4): {}, {} deletes seen; uncapped, it deletes at step {}",
             say(capped.verdict, capped.step), capped.deletes.len(), bb4_two.deletes[0]);
    assert!(capped.verdict == "running" && capped.deletes.is_empty() && bb4_two.deletes == vec![108]);
    let (_, ping_two, ping_macro, _) = &results["pingpong"];
    let says = ping_macro.values().any(|r| r.3);
    println!("  text scan of f(pingpong) for a delete rule: {}; the run {}, no delete",
             if says { "yes" } else { "no" }, say(ping_two.verdict, ping_two.step));
    assert!(says && ping_two.deletes.is_empty());
    let evil = table(machines[5].1);
    let (naive, s0) = reduce_to_macro(&evil, "", false);
    let r = run(&naive, &s0, "", CAP);
    let (evil_one, evil_two, _, _) = &results["delete-loop"];
    println!("  f without switching off M's deletes, on delete-loop: deletes at step {}, though M {}",
             r.deletes[0], say(evil_one.verdict, evil_one.step));
    assert!(r.deletes == vec![1] && r.verdict == "repeats" && evil_two.deletes.is_empty());
    println!("ALL CHECKS PASS");
}
