// NL = coNL: a guessing machine certifies "no path" by inductive counting.
// std only. Rooms 1 to 6, start room 1, exit room 6, one-way doors.
// The guessing machine is simulated by trying every guess it could make: every guessed
// set of rooms (a 6-bit mask, 64 of them) and every guessed walk of at most k doors.
use std::collections::BTreeSet;

const N: usize = 6;
const START: usize = 1;
const EXIT: usize = 6;
type Doors = Vec<(usize, usize)>;

// Road 1, no guessing: the sets R_0, R_1, ... built explicitly, one door at a time.
fn layers(doors: &Doors, rounds: usize) -> Vec<BTreeSet<usize>> {
    let mut sets = vec![BTreeSet::from([START])];
    for _ in 0..rounds {
        let mut next = sets.last().unwrap().clone();
        for &(a, b) in doors {
            if sets.last().unwrap().contains(&a) { next.insert(b); }
        }
        sets.push(next);
    }
    sets
}

// The machine's walk guess, every guess tried: room sequences of at most k doors
// from START that end at u. A guess that is not a real door kills that branch.
fn walks(door: &Doors, u: usize, k: usize) -> usize {
    let (mut good, mut seqs) = (0, vec![vec![START]]);
    for _ in 0..=k {
        good += seqs.iter().filter(|s| *s.last().unwrap() == u).count();
        let mut next = Vec::new();
        for s in &seqs {
            for r in 1..=N {
                if door.contains(&(*s.last().unwrap(), r)) {
                    let mut t = s.clone();
                    t.push(r);
                    next.push(t);
                }
            }
        }
        seqs = next;
    }
    good
}

fn members(g: usize) -> Vec<usize> { (1..=N).filter(|&u| g >> (u - 1) & 1 == 1).collect() }

// One counting round, for room v: each branch guesses a set G of rooms 'within k doors',
// proves each member by a walk, and (if check) must have exactly c members.
// Returns the answers 'v is within k + 1 doors' given by surviving branches, and their number.
fn round_answers(door: &Doors, v: usize, c: usize, k: usize, check: bool) -> (BTreeSet<bool>, usize) {
    let (mut answers, mut alive) = (BTreeSet::new(), 0);
    for g in 0..(1usize << N) {
        let gs = members(g);
        if (check && gs.len() != c) || !gs.iter().all(|&u| walks(door, u, k) > 0) {
            continue; // this branch rejects
        }
        alive += 1;
        answers.insert(gs.iter().any(|&u| u == v || door.contains(&(u, v))));
    }
    (answers, alive)
}

// Road 2: the guessing machine, every branch tried. Counts c_k until the count
// repeats, then re-finds c rooms one by one and accepts 'no path' if none is the exit.
fn machine(door: &Doors, final_check: bool, max_rounds: usize) -> (Vec<usize>, usize, usize) {
    let (mut c, mut k, mut counts) = (1usize, 0usize, vec![1usize]);
    while k < max_rounds {
        let mut new = 0;
        for v in 1..=N {
            let (answers, alive) = round_answers(door, v, c, k, true);
            assert!(alive == 1 && answers.len() == 1); // exactly one branch survives
            new += *answers.iter().next().unwrap() as usize;
        }
        k += 1;
        counts.push(new);
        if new == c { break; }
        c = new;
    }
    let acc = (0..(1usize << N)).filter(|&g| {
        let gs = members(g);
        (!final_check || gs.len() == c) && gs.iter().all(|&u| walks(door, u, k) > 0) && !gs.contains(&EXIT)
    }).count();
    (counts, acc, k)
}

fn names(s: &BTreeSet<usize>) -> String {
    format!("{{{}}}", s.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(", "))
}

fn reg_bits(n: u64) -> u64 { 8 * (64 - n.leading_zeros() as u64) + 1 } // 8 registers + 1 flag

fn commas(x: u64) -> String {
    let s = x.to_string();
    let mut out = String::new();
    for (k, ch) in s.chars().enumerate() {
        if k > 0 && (s.len() - k) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn main() {
    let maze_a: Doors = vec![(1, 2), (1, 3), (2, 4), (3, 4), (4, 1), (5, 6), (6, 5), (5, 2), (6, 3)];
    let mut maze_b = maze_a.clone();
    maze_b.push((4, 5)); // one extra door: now the exit is reachable
    let corridor: Doors = (1..N).map(|r| (r, r + 1)).collect();
    let ds: Vec<String> = maze_a.iter().map(|(a, b)| format!("{}>{}", a, b)).collect();
    println!("maze A: rooms 1-6, start 1, exit 6, doors {}", ds.join(" "));
    let (counts, acc, k) = machine(&maze_a, true, 99);
    let sets = layers(&maze_a, counts.len() - 1);
    for (j, s) in sets.iter().enumerate() {
        println!("road 1, k {}: R_{} = {:<14} size {}   road 2, c_{} = {}", j, j, names(s), s.len(), j, counts[j]);
    }
    assert!(counts == sets.iter().map(|s| s.len()).collect::<Vec<_>>() && counts == vec![1, 3, 4, 4]);
    println!("road 2: count stops growing at round {}; 6 rooms x 64 guessed sets per round, 1 branch survives per room", k);
    println!("road 2: final pass, 64 guessed sets, only those listing exactly {} rooms count: {} branch accepts 'no path'", counts[counts.len() - 1], acc);
    assert!(acc == 1 && !sets[sets.len() - 1].contains(&EXIT));
    for (j, &c) in counts.iter().enumerate() {
        println!("bar c_{} {}{} {}", j, "####".repeat(c), " ".repeat(4 * (N - c)), c);
    }
    let w4 = walks(&maze_a, 4, 2);
    println!("walk guesses: room 4 within 2 doors has {} proofs (1>2>4, 1>3>4); room 5 within 3 doors has {}", w4, walks(&maze_a, 5, 3));
    assert!(w4 == 2);

    let (cb, ab, _) = machine(&maze_b, true, 99);
    let sb = layers(&maze_b, cb.len() - 1);
    println!("maze B (add door 4>5): counts {:?}, R = {}, accepting branches {}", cb, names(&sb[sb.len() - 1]), ab);
    assert!(cb == sb.iter().map(|s| s.len()).collect::<Vec<_>>() && ab == 0 && sb[sb.len() - 1].contains(&EXIT));
    let (cc, ac, kc) = machine(&corridor, true, 99);
    println!("corridor 1>2>3>4>5>6: counts {:?}, growth stops at round {} = n - 1, accepting branches {}", cc, kc - 1, ac);
    assert!(cc == layers(&corridor, cc.len() - 1).iter().map(|s| s.len()).collect::<Vec<_>>() && kc - 1 == N - 1);

    let (_, wrong1, _) = machine(&maze_b, false, 99);
    println!("wrong: drop the final count check, maze B: {} branches accept 'no path'", wrong1);
    assert!(wrong1 == 32);
    let (_, a2, _) = machine(&maze_a, false, 99);
    let (c2, wrong2, _) = machine(&maze_b, true, 2);
    println!("wrong: stop after 2 rounds, maze B: counts {:?}, {} branch accepts 'no path'; exit is 4 doors away", c2, wrong2);
    assert!(wrong2 == 1 && layers(&maze_b, 4)[4].contains(&EXIT) && !layers(&maze_b, 3)[3].contains(&EXIT));
    let mixed: Vec<usize> = (1..=N).filter(|&v| round_answers(&maze_a, v, 3, 1, false).0.len() == 2).collect();
    println!("wrong: drop the count check in round 2, maze A: rooms {:?} get both answers", mixed);
    assert!(mixed == vec![1, 2, 3, 4]);

    println!("memory: rooms n, counting registers (8 numbers up to n in binary + 1 flag), one-bit-per-room list");
    for &n in &[6u64, 1000, 1000000] {
        println!("  n {:>9}  registers {:>4} bits  list {:>9} bits", commas(n), reg_bits(n), commas(n));
    }
    let cross = (2..10000u64).find(|&n| (n..10000).all(|m| reg_bits(m) < m)).unwrap();
    println!("registers beat the list for every n from {} on (checked to 9,999)", cross);
    assert!(cross == 50 && reg_bits(1000000) == 161);
    println!("try: drop the final count check, maze A: {} branches accept, all happen to be right", a2);
    println!("try: n = 10^9 rooms: registers {} bits", reg_bits(1000000000));
    println!("ALL CHECKS PASS");
}
