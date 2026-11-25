// Kleene's recursion theorem -- the same check as the Python, in Rust.  No
// crates.  Rust cannot run Python, so the Python quine is checked by a
// hand-written repr and fill.  The toy language is a stack of texts:
//   L<n>:<text> push the n characters   D duplicate the top   W swap the top two
//   Q quote: w becomes L<len w>:w       C join: a, b become a+b   N w becomes len(w)
//   E run the top text as a fresh program   H ask a decider about the top text:
//     "halts" -> loop for ever, "never halts" -> carry on    G the same, unflipped
// A run says "loops" only on a repeated configuration (text, place, stack).
use std::collections::HashSet;

#[derive(Clone, Copy)]
enum Dec { Yes, No, Cap(u64) }

fn quote(w: &str) -> String { format!("L{}:{}", w.len(), w) }

fn decide(d: Dec, w: &str, left: u64) -> (bool, u64) {
    match d {
        Dec::Yes => (true, 0),
        Dec::No => (false, 0),
        Dec::Cap(n) => { let r = run(w, n.min(left), d); (r.0 == "halts", r.1) }
    }
}

fn run(start: &str, budget: u64, d: Dec) -> (&'static str, u64, String) {
    let (mut prog, mut pc, mut st, mut steps): (Vec<u8>, i64, Vec<String>, u64) =
        (start.as_bytes().to_vec(), 0, Vec::new(), 0);
    let mut seen: HashSet<(Vec<u8>, i64, Vec<String>)> = HashSet::new();
    loop {
        if pc == prog.len() as i64 { return ("halts", steps, st.last().cloned().unwrap_or_default()) }
        if !seen.insert((prog.clone(), pc, st.clone())) { return ("loops", steps, String::new()) }
        if steps >= budget { return ("running", steps, String::new()) }
        steps += 1;
        if pc < 0 { continue }                    // spinning: nothing ever changes
        let c = prog[pc as usize] as char;
        pc += 1;
        let p = pc as usize;
        if c == 'L' {
            let mut j = p;
            while j < prog.len() && prog[j].is_ascii_digit() { j += 1 }
            if j == p || j >= prog.len() || prog[j] != b':' { return ("crash", steps, String::new()) }
            let n: usize = String::from_utf8(prog[p..j].to_vec()).unwrap().parse().unwrap();
            if j + 1 + n > prog.len() { return ("crash", steps, String::new()) }
            st.push(String::from_utf8(prog[j + 1..j + 1 + n].to_vec()).unwrap());
            pc = (j + 1 + n) as i64;
        } else if ("DQNEHG".contains(c) && st.len() >= 1) || ("WC".contains(c) && st.len() >= 2) {
            let w = st.pop().unwrap();
            match c {
                'D' => { st.push(w.clone()); st.push(w) }
                'Q' => st.push(quote(&w)),
                'N' => st.push(w.len().to_string()),
                'W' => { let v = st.pop().unwrap(); st.push(w); st.push(v) }
                'C' => st.last_mut().unwrap().push_str(&w),
                'E' => { prog = w.into_bytes(); pc = 0; st.clear() }
                _ => {
                    let (yes, used) = decide(d, &w, budget - steps);
                    steps += used;
                    if steps >= budget { return ("running", steps, String::new()) }
                    if yes == (c == 'H') { pc = -1 }
                }
            }
        } else { return ("crash", steps, String::new()) }
    }
}

const B: &str = "DQWC";                           // rebuilds the whole program from its literal
fn self_prog(task: &str) -> String { format!("{}{}{}", quote(&format!("{}{}", B, task)), B, task) }
fn show(r: &(&str, u64, String)) -> String {
    let n = format!("{} step{}", r.1, if r.1 == 1 { "" } else { "s" });
    if r.0 == "halts" { format!("halts after {}, output {}", n, if r.2.is_empty() { "(empty)" } else { &r.2 }) }
    else { format!("{} after {}", r.0, n) }
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn myrepr(w: &str) -> String { format!("'{}'", w.replace('\\', "\\\\").replace('\'', "\\'")) }
fn fill(t: &str, args: &[&str]) -> (Option<String>, usize) {  // Python's % formatting, written out
    let (b, mut out, mut i, mut slots) = (t.as_bytes(), String::new(), 0, 0);
    while i < b.len() {
        if b[i] != b'%' { out.push(b[i] as char); i += 1; continue }
        let code = b[i + 1];
        i += 2;
        if code == b'%' { out.push('%'); continue }
        if slots < args.len() {
            if code == b'r' { out += &myrepr(args[slots]) } else { out += args[slots] }
        }
        slots += 1;
    }
    (if slots == args.len() { Some(out) } else { None }, slots)
}

fn main() {
    let src = "s='s=%r;print(s%%s)';print(s%s)";
    let s = "s=%r;print(s%%s)";
    println!("python line: {}  ({} characters)", src, src.len());
    println!("s quoted by repr: {}", myrepr(s));
    let road2 = fill(s, &[s]).0.unwrap();
    let road1 = format!("s={};print(s%s)", myrepr(s));    // road 1: the line rebuilt from its halves
    println!("its output, by a hand-written repr and fill: equals the line: {}", yn(road2 == src));
    let quine = self_prog("");
    let rq = run(&quine, 10000, Dec::No);
    println!("toy quine {} ({} characters): {}; equals itself: {}", quine, quine.len(), show(&rq), yn(rq.2 == quine));
    let mut words: Vec<String> = vec![String::new()];
    for len in 0..4 {
        let last: Vec<String> = words.iter().filter(|w| w.len() == len).cloned().collect();
        for w in last { for c in B.chars() { words.push(format!("{}{}", w, c)) } }
    }
    let mut found: Vec<String> = Vec::new();
    for a in &words { for b in &words {
        let p = format!("{}{}", quote(a), b);
        if run(&p, 50, Dec::No).2 == p { found.push(p) }
    } }
    let fl: Vec<String> = found.iter().map(|p| format!("'{}'", p)).collect();
    println!("search: {} programs (one literal of up to 4 of DQWC, then up to 4 of DQWC): quines [{}]",
             words.len() * words.len(), fl.join(", "));
    let own = self_prog("N");
    let ro = run(&own, 10000, Dec::No);
    println!("self-length {} ({} characters): {}", own, own.len(), show(&ro));
    let fixed: [(&str, &str, fn(&str) -> String); 3] = [
        ("quote it", "QE", |w| quote(w)),
        ("print its length", "NQE", |w| quote(&w.len().to_string())),
        ("run it, then add !", "L5:L1:!CCE", |w| format!("{}L1:!C", w))];
    for (name, task, f) in fixed.iter() {
        let e = self_prog(task);
        let (a, b) = (run(&e, 10000, Dec::No), run(&f(&e), 10000, Dec::No));
        println!("fixed point of '{}': e = {} ({} characters)", name, e, e.len());
        println!("  e: {}; f(e) = {}: {}", show(&a), f(&e), show(&b));
        assert!(a.0 == b.0 && a.2 == b.2);                 // e behaves like f(e)
    }
    let con = self_prog("H");
    println!("contrary program C = {}: get my own code, ask the decider, do the opposite", con);
    for (name, d, want) in [("always halts", Dec::Yes, 6 + 1), ("always never halts", Dec::No, 6),
                            ("halts within 100 steps", Dec::Cap(100), 6 + 100), ("halts within 300 steps", Dec::Cap(300), 6 + 300)] {
        let says = decide(d, &con, 10000).0;
        let r = run(&con, 10000, d);
        println!("decider '{}': says {}; C {}", name, if says { "halts" } else { "never halts" }, show(&r));
        assert!(says != (r.0 == "halts"));                // every decider is wrong about C
        assert!(r.1 == want);                             // C's own 6 steps, plus 1 spin or the cap spent
    }
    let nq = "L2:DCDC";
    println!("mistake 1, copy without quoting: {} outputs {}", nq, run(nq, 100, Dec::No).2);
    let bad = "s=%r;print(s%s)";
    let (filled, slots) = fill(bad, &[bad]);
    println!("mistake 2, % for %%: {} slots, 1 value; runs: {}", slots, yn(filled.is_some()));
    let agree = self_prog("G");
    let ra = run(&agree, 10000, Dec::Yes);
    println!("mistake 3, no flip: {} with 'always halts': {}; decider right: {}", agree, show(&ra), yn(ra.0 == "halts"));
    assert!(road1 == src && road2 == src && filled.is_none());   // two roads to the quine
    assert!(rq.2 == quine && found == vec![quine.clone()]);       // construction against search
    assert!(ro.2 == own.len().to_string() && run(nq, 100, Dec::No).2 != nq);
    println!("ALL CHECKS PASS");
}
