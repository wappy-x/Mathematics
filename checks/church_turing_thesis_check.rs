// Church-Turing thesis: double a recipe in three models, then run one model inside another.
// std only. The tape machine is explained on the Turing machines card.
const SYM: [char; 4] = ['_', '1', 'X', 'Y']; // symbols 0..3: blank, one, done-mark X, copy-mark Y
type Rule = (usize, i64, &'static str);

fn tm(q: &str, s: usize) -> Option<Rule> {
    Some(match (q, s) {
        ("mark", 1) => (2, 1, "end"), ("mark", 3) => (1, 1, "fix"), ("mark", 0) => (0, 1, "halt"),
        ("end", 1) => (1, 1, "end"), ("end", 3) => (3, 1, "end"), ("end", 0) => (3, -1, "back"),
        ("back", 1) => (1, -1, "back"), ("back", 3) => (3, -1, "back"), ("back", 2) => (2, 1, "mark"),
        ("fix", 3) => (1, 1, "fix"), ("fix", 0) => (0, -1, "home"),
        ("home", 1) => (1, -1, "home"), ("home", 2) => (1, -1, "home"), ("home", 0) => (0, 1, "halt"),
        _ => return None,
    })
}

type Reads = Vec<(&'static str, usize)>;

// Model 1, a Turing machine on a vector. Cell p sits at index p + 1.
fn tape_run(n: usize, cells: i64, trace: &mut Vec<String>) -> (Reads, Option<usize>, usize) {
    let mut tape = vec![0usize; 3 * n + 3];
    for i in 1..=n { tape[i] = 1; }
    let (mut h, mut q, mut reads): (i64, &'static str, Reads) = (1, "mark", vec![]);
    while q != "halt" {
        if h >= cells { let k = reads.len(); return (reads, None, k); } // tape is cells -1 to cells - 2
        let s = tape[h as usize];
        let (w, m, q2) = tm(q, s).unwrap();
        reads.push((q, s));
        tape[h as usize] = w;
        h += m;
        let cs: String = tape[1..6.min(tape.len())].iter().map(|&c| SYM[c]).collect();
        trace.push(format!("{},{},{},{},{},{},{},{}", reads.len(), q, SYM[s], SYM[w],
                           if m == 1 { "R" } else { "L" }, q2, h - 1, cs));
        q = q2;
    }
    let ones = tape.iter().filter(|&&c| c == 1).count();
    let k = reads.len();
    (reads, Some(ones), k)
}

fn arith_start(n: usize, b: u128) -> u128 { (0..n).map(|i| b.pow(i as u32)).sum() }

// Road 2: the same machine on two whole numbers, moved by *b, /b and %b.
fn arith_run(n: usize, b: u128, cap: usize, trace: &mut Vec<(u128, u128)>) -> (Reads, usize) {
    let (mut lft, mut rgt, mut q, mut reads): (u128, u128, &'static str, Reads) =
        (0, arith_start(n, b), "mark", vec![]);
    while q != "halt" && reads.len() < cap {
        let s = (rgt % b) as usize;
        let Some((w, m, q2)) = tm(q, s) else { break };
        reads.push((q, s));
        rgt = rgt - s as u128 + w as u128;
        if m == 1 { lft = lft * b + w as u128; rgt /= b; }
        else { let d = lft % b; lft /= b; rgt = rgt * b + d; }
        trace.push((lft, rgt));
        q = q2;
    }
    let (mut ones, mut x) = (0, rgt);
    while x > 0 { if x % b == 1 { ones += 1; } x /= b; }
    (reads, ones)
}

#[derive(Clone, Copy)]
enum Op { Inc(usize), Dec(usize), Jz(usize, usize), Halt }
use Op::*;
// registers: 0 = a, 1 = b, 2 = z (always 0)
const DOUBLE: [Op; 6] = [Jz(0, 5), Dec(0), Inc(1), Inc(1), Jz(2, 0), Halt];
const TRIPLE: [Op; 7] = [Jz(0, 6), Dec(0), Inc(1), Inc(1), Inc(1), Jz(2, 0), Halt];

// Model 2, a counter machine.
fn cm_run(prog: &[Op], n: u64) -> (u64, u64) {
    let (mut reg, mut pc, mut steps) = ([n, 0, 0], 0usize, 0u64);
    loop {
        match prog[pc] {
            Halt => break,
            Inc(r) => { reg[r] += 1; pc += 1; }
            Dec(r) => { reg[r] -= 1; pc += 1; }
            Jz(r, t) => { pc = if reg[r] == 0 { t } else { pc + 1 }; }
        }
        steps += 1;
    }
    (reg[1], steps)
}

// Model 3, recursive equations d(0) = 0 and d(S(x)) = S(S(d(x))), applied by rewriting text.
fn rec_run(n: usize) -> (usize, usize) {
    let mut t: Vec<u8> = format!("d({}0{})", "S(".repeat(n), ")".repeat(n)).into_bytes();
    let mut steps = 0;
    while let Some(i) = t.windows(2).position(|w| w == b"d(") {
        if t[i + 2] == b'0' {
            t.splice(i..i + 4, b"0".iter().cloned());
        } else {
            let (mut j, mut depth) = (i + 4, 1i64);
            while depth > 0 {
                if t[j] == b'(' { depth += 1; } else if t[j] == b')' { depth -= 1; }
                j += 1;
            }
            let mut mid = b"S(S(d(".to_vec();
            mid.extend_from_slice(&t[i + 4..j - 1]);
            mid.extend_from_slice(b")))");
            t.splice(i..j + 1, mid);
        }
        steps += 1;
    }
    (t.iter().filter(|&&c| c == b'S').count(), steps)
}

fn main() {
    let (mut tr, mut nu) = (vec![], vec![]);
    let mut checks = 0;
    for n in 0..=60usize {
        let (reads, ones, tms) = tape_run(n, i64::MAX, &mut tr);
        let (n64, c, r) = (n as u64, cm_run(&DOUBLE, n as u64), rec_run(n));
        assert!(ones == Some(2 * n) && c.0 == 2 * n64 && r.0 == 2 * n);
        assert!(c.1 == 5 * n64 + 1 && r.1 == n + 1);
        assert!(n == 0 || tms == 2 * (n + 1) * (n + 1));
        if n <= 30 {
            let (areads, aones) = arith_run(n, 4, 100000, &mut nu);
            assert!(areads == reads && aones == 2 * n);
        }
        checks += 1;
    }
    println!("agree: tape, counters, equations all give 2n for n = 0..60; {} values", checks);
    println!("closed forms: tape 2(n+1)^2 steps, counters 5n+1, equations n+1 rewrites");
    println!("simulation: tape and two base-4 numbers make the same reads at every step, n = 0..30");
    println!("recipe,n,doubled,tape_steps,counter_steps,rewrites");
    for (name, n) in [("flour g", 200), ("milk ml", 300), ("eggs", 2), ("sugar g", 25)] {
        let (_, ones, tms) = tape_run(n, i64::MAX, &mut tr);
        println!("{},{},{},{},{},{}", name, n, ones.unwrap(), tms, cm_run(&DOUBLE, n as u64).1, rec_run(n).1);
    }
    let (mut trace, mut nums) = (vec![], vec![]);
    tape_run(2, i64::MAX, &mut trace);
    arith_run(2, 4, 100000, &mut nums);
    println!("run,step,state,read,write,move,next,head,cells 0-4,left,right");
    println!("run,0,mark,-,-,-,-,0,{}{}{}{}{},0,{}", SYM[1], SYM[1], SYM[0], SYM[0], SYM[0], arith_start(2, 4));
    for (row, (lf, rg)) in trace.iter().zip(nums.iter()) { println!("run,{},{},{}", row, lf, rg); }
    for n in [25usize, 50, 100, 200, 300] {
        let (a, b, c) = (tape_run(n, i64::MAX, &mut tr).2, cm_run(&DOUBLE, n as u64).1, rec_run(n).1);
        println!("chart,{},{:.2},{:.2},{:.2}", n, (a as f64).log10(), (b as f64).log10(), (c as f64).log10());
    }
    let (reads, _) = arith_run(2, 4, 100000, &mut nu);
    let (bad, _) = arith_run(2, 3, 200, &mut nu);
    let k = (0..bad.len()).find(|&i| bad[i] != reads[i]).unwrap();
    assert!((k + 1, SYM[bad[k].1], SYM[reads[k].1]) == (7, '_', 'Y')); // traced by hand on the card
    println!("break,base 3 for 4 symbols: first wrong read at step {}: read {} where the tape holds {}",
             k + 1, SYM[bad[k].1], SYM[reads[k].1]);
    let big = (0..100).filter(|&n| tape_run(n, 64, &mut tr).1 == Some(2 * n)).max().unwrap();
    let off = tape_run(200, 64, &mut tr);
    assert!(big == 31 && off.1.is_none());
    println!("break,tape of 64 cells: largest n doubled {}; flour 200 runs off at step {}", big, off.2);
    for steps in [10, 30] {
        println!("break,zeno: step k takes 2^-k s; after {} steps {:.10} s", steps, 1.0 - 2f64.powi(-steps));
    }
    let t = cm_run(&TRIPLE, 200);
    println!("try,triple program on flour: {} in {} steps", t.0, t.1);
    let ok = (0..=20).all(|n| arith_run(n, 5, 100000, &mut nu).0 == tape_run(n, i64::MAX, &mut tr).0);
    println!("try,base 5 agrees for n = 0..20: {}", if ok { "True" } else { "False" });
    println!("ALL CHECKS PASS");
}
