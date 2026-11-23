// Universal machines and the halting problem -- the same check as the Python twin, in Rust.
// No crates.  U is an interpreter, written out here, for a small slice of Python:
// whole-number variables, + - * // %, while and if.  It runs any program in that
// slice from its text alone.  Then the diagonal program D is built and run against
// four would-be halting deciders.
use std::collections::{BTreeMap, HashSet};

type Code = Vec<Vec<String>>;
type Env = BTreeMap<String, i64>;
#[derive(Clone, Copy)] enum Decider { Table(i64), Cap(usize) }

fn compile_text(text: &str) -> Code {      // program text -> numbered instructions with jumps
    let mut code: Code = Vec::new();
    let mut open: Vec<(usize, usize)> = Vec::new();
    let mut lines: Vec<&str> = text.split('\n').filter(|l| !l.trim().is_empty()).collect();
    lines.push("");
    for line in lines {
        let depth = line.len() - line.trim_start().len();
        while !open.is_empty() && (open[open.len() - 1].0 >= depth || line.is_empty()) {
            let head = open.pop().unwrap().1;
            if code[head][0] == "while" {
                code.push(vec!["goto".to_string(), head.to_string()]); // jump back to the test
            }
            code[head][4] = code.len().to_string();                // a failed test skips the block
        }
        if line.is_empty() { return code; }
        let w: Vec<String> = line.replace('(', " ").replace(')', " ").replace(',', " ")
            .replace(':', " ").split_whitespace().map(|s| s.to_string()).collect();
        let s = |v: &[&str]| v.iter().map(|x| x.to_string()).collect::<Vec<String>>();
        if w[0] == "while" || w[0] == "if" {
            open.push((depth, code.len()));
            code.push(s(&[&w[0], &w[1], &w[2], &w[3], "none"]));
        } else if w[2] == "halts" {
            code.push(s(&["halts", &w[0], &w[3], &w[4]]));          // ask the plugged-in decider
        } else if w.len() == 3 {
            code.push(s(&["set", &w[0], &w[2], "+", "0"]));
        } else {
            code.push(s(&["set", &w[0], &w[2], &w[3], &w[4]]));
        }
    }
    code
}

struct World { code: Vec<Code>, truth: Vec<Vec<i64>> }

// U: returns ("halts" | "loops" | "fuel", steps, variables).  "loops" only with proof:
// the same line and the same variables came round twice, so it repeats forever.
fn run(w: &World, code: &Code, n: i64, fuel: usize, h: Option<Decider>, wrap: i64)
    -> (&'static str, usize, Env) {
    let mut env: Env = BTreeMap::from([("n".to_string(), n)]);
    let (mut pc, mut steps) = (0usize, 0usize);
    let mut seen: HashSet<(usize, Vec<(String, i64)>)> = HashSet::new();
    while pc < code.len() {
        let config = (pc, env.iter().map(|(k, v)| (k.clone(), *v)).collect::<Vec<_>>());
        if seen.contains(&config) { return ("loops", steps, env); }
        seen.insert(config);
        if steps >= fuel { return ("fuel", steps, env); }
        let ins = &code[pc];
        (steps, pc) = (steps + 1, pc + 1);
        let val = |a: &str, e: &Env| -> i64 {
            if a.chars().all(|c| c.is_ascii_digit()) { a.parse().unwrap() } else { *e.get(a).unwrap_or(&0) }
        };
        match ins[0].as_str() {
            "set" => {
                let (a, b) = (val(&ins[2], &env), val(&ins[4], &env));
                let mut v = match ins[3].as_str() {
                    "+" => a + b, "-" => a - b, "*" => a * b,
                    "//" => a.div_euclid(b), _ => a.rem_euclid(b),
                };
                if wrap > 0 { v = v.rem_euclid(wrap); }
                env.insert(ins[1].clone(), v);
            }
            "goto" => pc = ins[1].parse().unwrap(),
            "halts" => {
                let (a, b) = (val(&ins[2], &env), val(&ins[3], &env));
                match decide(w, h.unwrap(), a as usize, b, fuel - steps) {
                    None => return ("fuel", fuel, env),
                    Some((answer, cost)) => { env.insert(ins[1].clone(), answer); steps += cost; }
                }
            }
            _ => {
                let (a, b) = (val(&ins[1], &env), val(&ins[3], &env));
                let ok = match ins[2].as_str() { "==" => a == b, "!=" => a != b, _ => a < b };
                if !ok { pc = ins[4].parse().unwrap(); }
            }
        }
    }
    ("halts", steps, env)
}

fn decide(w: &World, h: Decider, a: usize, b: i64, budget: usize) -> Option<(i64, usize)> {
    match h {   // Table: right on all 25 table entries, guesses elsewhere.  Cap: 1 if it halts within cap.
        Decider::Table(guess) => Some((if a < 5 && b < 5 { w.truth[a][b as usize] } else { guess }, 0)),
        Decider::Cap(cap) => {
            let (out, used, _) = run(w, &w.code[a], b, cap.min(budget), Some(h), 0);
            if out == "fuel" && budget < cap { return None; }   // the caller ran out of fuel first
            Some((if out == "halts" { 1 } else { 0 }, used))
        }
    }
}

fn show(o: &(&str, usize, Env)) -> String {
    format!("{} {}", if o.0 == "fuel" { "running" } else { o.0 }, o.1)
}

fn main() {
    let names = ["countdown", "collatz", "even-stop", "count-up", "below-3", "D"];
    let texts = ["while n != 0:\n    n = n - 1",
        concat!("steps = 0\nwhile n != 1:\n    r = n % 2\n    if r == 0:\n        n = n // 2\n",
                "    if r == 1:\n        n = 3 * n\n        n = n + 1\n    steps = steps + 1"),
        "r = n % 2\nwhile r == 1:\n    r = 1",
        "while n != 0:\n    n = n + 1",
        "while 2 < n:\n    n = n",
        "r = halts(n, n)\nwhile r == 1:\n    r = 1"];        // D, program number 5
    let mut w = World { code: texts.iter().map(|t| compile_text(t)).collect(), truth: Vec::new() };
    let fuel = 10000;
    let listing: Vec<String> = w.code[0].iter().enumerate()
        .map(|(k, ins)| format!("{}: {}", k, ins.join(" "))).collect();
    println!("U compiles countdown to {}", listing.join(" | "));
    for k in [0i64, 2, 40] {
        let o = run(&w, &w.code[0], k, fuel, None, 0);
        println!("U runs countdown on {}: {} steps", k, show(&o));
        assert!(o.0 == "halts" && o.1 == 3 * k as usize + 1);  // one test, one subtract, one jump back
    }
    let (mut m, mut moves) = (27i64, 0i64);                 // Collatz as a direct loop, a second road
    while m != 1 { m = if m % 2 == 0 { m / 2 } else { 3 * m + 1 }; moves += 1; }
    let c27 = run(&w, &w.code[1], 27, fuel, None, 0);
    println!("U runs collatz on 27: {} steps, {} moves; a direct loop counts {}",
             show(&c27), c27.2["steps"], moves);
    assert!(c27.0 == "halts" && c27.2["steps"] == moves);
    // Left running: the card proves these never stop.  Collatz on 0 halves 0 to 0 for
    // ever, while its move counter climbs; count-up from 1 or more only grows.
    let running = [(1usize, 0usize), (3, 1), (3, 2), (3, 3), (3, 4)];
    let header: String = (0..5).map(|x| format!("{:>14}", format!("input {}", x))).collect();
    println!("program   {}", header);
    for i in 0..5 {                                         // the program-against-input table
        let row: Vec<_> = (0..5).map(|x| run(&w, &w.code[i], x, fuel, None, 0)).collect();
        assert!(row.iter().enumerate().all(|(x, o)| (o.0 == "fuel") == running.contains(&(i, x))));
        w.truth.push(row.iter().map(|o| if o.0 == "halts" { 1 } else { 0 }).collect());
        let cells: String = row.iter().map(|o| format!("{:>14}", show(o))).collect();
        println!("{:10}{}", names[i], cells);
    }
    let diag: Vec<i64> = (0..5).map(|i| w.truth[i][i]).collect();
    let flip: Vec<i64> = diag.iter().map(|b| 1 - b).collect();
    println!("diagonal, 1 = halts: {:?}  flipped: {:?}", diag, flip);
    let d_row: Vec<i64> = (0..5).map(|x| {
        if run(&w, &w.code[5], x, fuel, Some(Decider::Table(1)), 0).0 == "halts" { 1 } else { 0 }
    }).collect();
    println!("D on inputs 0 to 4, 1 = halts: {:?}", d_row);
    assert!(d_row == flip && (0..5).all(|i| d_row[i] != w.truth[i][i]));
    for (label, h) in [("table, guess 1", Decider::Table(1)), ("table, guess 0", Decider::Table(0)),
                       ("cap 100", Decider::Cap(100)), ("cap 300", Decider::Cap(300))] {
        let said = decide(&w, h, 5, 5, fuel).unwrap().0;
        let did = run(&w, &w.code[5], 5, fuel, Some(h), 0);
        println!("H = {}: says H(5, 5) = {}; D on 5 {} steps", label, said, show(&did));
        assert!(did.0 != "fuel");                            // D's run ended, or provably repeats
        assert!(said != if did.0 == "halts" { 1 } else { 0 });  // every decider is wrong on D
        if let Decider::Cap(c) = h { assert!(did.0 == "halts" && did.1 == c + 2); }  // N + 2
    }
    let copier = compile_text("r = halts(n, n)\nwhile r == 0:\n    r = 0");
    let cp = run(&w, &copier, 5, fuel, Some(Decider::Table(1)), 0);
    println!("copier, no flip, H = table, guess 1: says 1; copier on 5 {} steps", show(&cp));
    assert!(cp.0 == "halts");                                // no contradiction without the flip
    println!("cap 100 on countdown 40: {} steps; uncapped: {} steps",
             show(&run(&w, &w.code[0], 40, 100, None, 0)), show(&run(&w, &w.code[0], 40, fuel, None, 0)));
    let up8 = run(&w, &w.code[3], 1, fuel, None, 256);
    println!("count-up on 1 with numbers kept 0 to 255: {} steps", show(&up8));
    assert!(up8.0 == "halts" && up8.1 == 3 * 255 + 1);
    println!("ALL CHECKS PASS");
}
