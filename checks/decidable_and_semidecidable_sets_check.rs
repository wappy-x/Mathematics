// Decidable and semidecidable sets -- the same check as decidable_and_semidecidable_sets_check.py,
// in Rust.  No crates.  Programs are strings over  + - < > [ ] !  (! prints HELLO), numbered by
// length then alphabet.  The lister dovetails: at stage s, program i takes its step t = s - i + 1.
use std::collections::{BTreeMap, HashMap};
const SYM: [char; 7] = ['+', '-', '<', '>', '[', ']', '!'];
fn well_formed(p: &str) -> bool {           // brackets match: depth never below 0, ends at 0
    let mut d = 0i32;
    for c in p.chars() { d += (c == '[') as i32 - (c == ']') as i32; if d < 0 { return false; } }
    d == 0
}
fn all_programs(n: usize) -> Vec<String> { // by length, then alphabet in the order of SYM
    let (mut out, mut layer) = (vec![], vec![String::new()]);
    for _ in 0..n {
        layer = layer.iter().flat_map(|p| SYM.iter().map(move |c| format!("{}{}", p, c))).collect();
        out.extend(layer.iter().filter(|p| well_formed(p)).cloned());
    }
    out
}
fn count_by_depth(n: usize) -> Vec<u64> {  // second road: count strings by open-bracket depth
    let (mut ways, mut counts) = (vec![1u64], vec![]);
    for _ in 0..n {
        let mut new = vec![0u64; ways.len() + 1];
        for (d, &w) in ways.iter().enumerate() {
            new[d] += 5 * w; new[d + 1] += w; if d > 0 { new[d - 1] += w; }
        }
        ways = new; counts.push(ways[0]);
    }
    counts
}
struct Run { p: Vec<char>, pc: usize, ptr: i64, tape: BTreeMap<i64, u8>, steps: usize, hello: Option<usize>, jump: HashMap<usize, usize> }
type Config = (usize, i64, Vec<(i64, u8)>);
impl Run {
    fn new(s: &str) -> Run {
        let p: Vec<char> = s.chars().collect();
        let (mut jump, mut stack) = (HashMap::new(), vec![]);
        for (i, &c) in p.iter().enumerate() {
            if c == '[' { stack.push(i); } else if c == ']' { let j = stack.pop().unwrap(); jump.insert(i, j); jump.insert(j, i); }
        }
        Run { p, pc: 0, ptr: 0, tape: BTreeMap::new(), steps: 0, hello: None, jump }
    }
    fn halted(&self) -> bool { self.pc >= self.p.len() }
    fn config(&self) -> Config { (self.pc, self.ptr, self.tape.iter().filter(|(_, &v)| v != 0).map(|(&k, &v)| (k, v)).collect()) }
    fn step(&mut self) {                    // cells hold 0 to 255 and wrap round
        let (c, v) = (self.p[self.pc], *self.tape.get(&self.ptr).unwrap_or(&0));
        self.steps += 1;
        match c {
            '+' => { self.tape.insert(self.ptr, v.wrapping_add(1)); }
            '-' => { self.tape.insert(self.ptr, v.wrapping_sub(1)); }
            '>' => self.ptr += 1,
            '<' => self.ptr -= 1,
            '[' if v == 0 => self.pc = self.jump[&self.pc],
            ']' if v != 0 => self.pc = self.jump[&self.pc],
            '!' if self.hello.is_none() => self.hello = Some(self.steps),
            _ => {}
        }
        self.pc += 1;
    }
}
fn run_alone(p: &str, cap: usize) -> Run { // first road: one program on its own, up to cap steps
    let mut r = Run::new(p);
    while !r.halted() && r.steps < cap { r.step(); }
    r
}
fn repeat_proof(p: &str, cap: usize) -> Option<(usize, usize)> { // a repeat proves the run never ends
    let (mut r, mut seen) = (Run::new(p), HashMap::new());
    while !r.halted() && r.steps < cap {
        if let Some(&a) = seen.get(&r.config()) { return Some((a, r.steps)); }
        seen.insert(r.config(), r.steps); r.step();
    }
    None
}
fn dovetail(progs: &[String], cap: usize, stages: usize) -> Vec<(usize, usize, usize, u64)> {
    let (mut runs, mut listed, mut cells) = (vec![], vec![], 0u64);
    for s in 1..=stages {
        if s <= progs.len() { runs.push(Run::new(&progs[s - 1])); }
        for (k, r) in runs.iter_mut().enumerate() {
            cells += 1;                     // grid cell (i, t = s - i + 1), visited or idle
            if r.halted() || r.steps >= cap { continue; }
            r.step();
            if r.hello == Some(r.steps) { listed.push((k + 1, r.steps, s, cells)); }
        }
    }
    listed
}
fn w(i: usize, t: usize) -> u64 { let s = (i + t - 1) as u64; (s - 1) * s / 2 + i as u64 }
fn commas(n: u64) -> String {
    let s = n.to_string(); let mut out = String::new();
    for (k, c) in s.chars().enumerate() { if k > 0 && (s.len() - k) % 3 == 0 { out.push(','); } out.push(c); }
    out
}
fn two_listers(progs: &[String], cap: usize) -> HashMap<usize, &'static str> {
    let (mut runs, mut answer) = (vec![], HashMap::new());
    for s in 1..progs.len() + cap {         // lister A: yes by step cap; lister B: settled no
        if s <= progs.len() { runs.push(Run::new(&progs[s - 1])); }
        for (k, r) in runs.iter_mut().enumerate() {
            if answer.contains_key(&(k + 1)) { continue; }
            if r.halted() || r.steps >= cap { answer.insert(k + 1, "no"); continue; }
            r.step();
            if r.hello.is_some() { answer.insert(k + 1, "yes"); }
        }
    }
    answer
}
fn main() {
    let (cap, n) = (2000usize, 5usize);
    let progs = all_programs(n);
    let num: HashMap<&str, usize> = progs.iter().enumerate().map(|(i, p)| (p.as_str(), i + 1)).collect();
    let by_len: Vec<u64> = (1..=n).map(|k| progs.iter().filter(|p| p.len() == k).count() as u64).collect();
    let join = |v: &[u64]| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ");
    println!("programs of length 1 to 5    {}, total {}", join(&by_len), progs.len());
    println!("same counts by bracket depth {}", join(&count_by_depth(n)));
    let alone: Vec<Run> = progs.iter().map(|p| run_alone(p, cap)).collect();
    let mut yes: Vec<(usize, usize)> = alone.iter().enumerate().filter_map(|(i, r)| r.hello.map(|t| (i + 1, t))).collect();
    let silent = alone.iter().filter(|r| r.halted() && r.hello.is_none()).count();
    let running: Vec<String> = alone.iter().filter(|r| !r.halted() && r.hello.is_none()).map(|r| r.p.iter().collect()).collect();
    let proved = running.iter().filter(|p| repeat_proof(p, cap).is_some()).count();
    println!("run alone, {} steps each:  {} print HELLO, {} halt silent, {} still running", cap, yes.len(), silent, running.len());
    println!("of the {} still running: {} proved endless by a repeat, {} unknown", running.len(), proved, running.len() - proved);
    let unknown: Vec<&str> = running.iter().filter(|p| repeat_proof(p, cap).is_none()).map(|p| p.as_str()).collect();
    println!("the unknown ones: {}", unknown.join(" "));
    let stages = progs.len() + cap - 1;
    let listed = dovetail(&progs, cap, stages);
    println!("the lister, {} stages: {} programs listed", stages, listed.len());
    println!("first six listed (number, program, step, stage):");
    for &(i, t, s, _) in &listed[..6] { println!("  #{} {}  step {}  stage {}", i, progs[i - 1], t, s); }
    for p in ["!", "+[]", "+[-]!", "-[-]!", "+[>+]"] { println!("program {:6} is number {}", p, num[p]); }
    let &(i, t, s, c) = listed.iter().find(|x| progs[x.0 - 1] == "-[-]!").unwrap();
    println!("-[-]! prints at step {}, listed at stage {} = {} + {} - 1", t, s, i, t);
    println!("grid cells walked by then: counted {}, by formula {}", commas(c), commas(w(i, t)));
    let s0: u64 = by_len[..4].iter().sum();
    println!("worked: {} shorter + {} = #{}; steps 2 + 2 x {} + 1 = {}; cells {} x {} / 2 = {}, plus {}",
        s0, i as u64 - s0, i, (t - 3) / 2, t, s - 1, s, commas(((s - 1) * s / 2) as u64), i);
    let walk: Vec<String> = (1..5).flat_map(|st| (1..=st).map(move |k| (k, st - k + 1))).map(|(k, u)| format!("({},{})={}", k, u, w(k, u))).collect();
    println!("diagonal walk, cells 1 to 10: {}", walk.join(" "));
    let last = listed.iter().map(|x| x.2).max().unwrap();
    println!("last new listing at stage {}; stages {} to {} add nothing", last, last + 1, stages);
    let (a, b) = repeat_proof("+[]", 50).unwrap();
    println!("+[] repeats its configuration at steps {} and {}: proved never to print", a, b);
    assert!(repeat_proof("+[>+]", cap).is_none());
    println!("+[>+] after {} steps: no repeat found, tape cells used {}", cap, run_alone("+[>+]", cap).tape.len());
    let mut late: Vec<(usize, String)> = yes.iter().filter(|x| x.1 > 100).map(|&(i, t)| (t, progs[i - 1].clone())).collect();
    late.sort();
    println!("printers a 100-step cap calls never: {}", late.iter().map(|(t, p)| format!("{} (step {})", p, t)).collect::<Vec<_>>().join(", "));
    let stuck = num[running[0].as_str()];
    println!("one at a time: stuck on #{} {}, lists {} of {}", stuck, running[0], yes.iter().filter(|x| x.0 < stuck).count(), yes.len());
    println!("asked about +[>+], the lister is still silent after {} stages", stages);
    let ans = two_listers(&progs, 100);
    let count = |v: &str| ans.values().filter(|x| **x == v).count();
    println!("within 100 steps: {} yes, {} no, every one answered, agreeing with a direct run", count("yes"), count("no"));
    let short: Vec<&String> = progs.iter().filter(|p| p.len() <= 4).collect();
    let pairs: Vec<(Run, Run)> = short.iter().map(|p| (run_alone(p, cap), run_alone(&format!("{}!", p.replace('!', "")), cap + 1))).collect();
    println!("reduction on {} programs up to length 4: {} halt, {} of their P' print HELLO", short.len(),
        pairs.iter().filter(|x| x.0.halted()).count(), pairs.iter().filter(|x| x.1.hello.is_some()).count());
    for p in ["+[]", "+[-]"] {
        let q = format!("{}!", p); let r = run_alone(&q, cap);
        let tail = match r.hello { Some(h) => format!("prints at step {}", h),
            None => { let (a, b) = repeat_proof(&q, cap).unwrap(); format!("repeat at steps {} and {}", a, b) } };
        println!("  {:5} -> {:6} {}", p, q, tail);
    }
    let mut got: Vec<(usize, usize)> = listed.iter().map(|x| (x.0, x.1)).collect(); got.sort(); yes.sort();
    assert!(by_len == count_by_depth(n) && progs.len() == 5373);
    assert!(got == yes);
    assert!(listed.iter().all(|x| x.0 != num["+[>+]"]));    // the lister stays silent on +[>+]
    assert!(listed.iter().all(|&(i, t, _, c)| c == w(i, t)));
    assert!(ans.len() == progs.len() && alone.iter().enumerate().all(|(k, r)|
        ans[&(k + 1)] == if r.hello.map_or(false, |h| h <= 100) { "yes" } else { "no" }));
    assert!(pairs.iter().all(|(r, q)| r.halted() == q.hello.is_some()));
    assert!(late.iter().map(|x| x.1.as_str()).collect::<Vec<_>>() == ["+[+]!", "-[-]!"] && yes.len() - late.len() == count("yes"));
    println!("ALL CHECKS PASS");
}
