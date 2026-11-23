// Pumping and Myhill-Nerode -- the same check as the Python, in Rust.  No crates.
// Bracket strings that never close more than they opened, end at depth 0 and never
// nest past a cap.  A plain counter is the reference every other road is checked against.
use std::collections::BTreeSet;
const F3: &str = "=IF(A1>0,SUM((B1+C1)*(D1-E1)),0)";
const F4: &str = "=ROUND(IF(A1>0,SUM((B1+C1)*(D1-E1)),0),2)";
const BIG: i64 = 1_000_000; // a cap no test string reaches

struct Machine { next: Vec<[usize; 2]>, start: usize, accept: Vec<bool> } // next[s][0] reads '('

fn brackets(f: &str) -> String { f.chars().filter(|&c| c == '(' || c == ')').collect() }
fn balanced(w: &str, cap: i64) -> bool { // the reference: one counter
    let mut depth = 0i64;
    for c in w.chars() {
        depth += if c == '(' { 1 } else { -1 };
        if depth < 0 || depth > cap { return false }
    }
    depth == 0
}

fn words(n: usize, letters: &str) -> Vec<String> { // every string, length 0..n
    let (mut out, mut layer) = (vec![String::new()], vec![String::new()]);
    for _ in 0..n {
        layer = layer.iter().flat_map(|w| letters.chars().map(move |c| format!("{}{}", w, c))).collect();
        out.extend(layer.iter().cloned());
    }
    out
}

fn draft(cap: i64) -> Machine { // first draft: remembers the depth AND the last bracket
    // a state is (depth, last bracket); (0, ' ') is the start, (-1, 'x') is dead
    let mut states: Vec<(i64, char)> = vec![(0, ' '), (-1, 'x')];
    let mut next: Vec<[usize; 2]> = vec![[0, 0], [0, 0]];
    let mut todo = vec![0usize, 1];
    while let Some(i) = todo.pop() {
        for (k, c) in ['(', ')'].iter().enumerate() {
            let s = states[i];
            let d = if s.0 < 0 { BIG } else { s.0 + if *c == '(' { 1 } else { -1 } };
            let t = if d >= 0 && d <= cap { (d, *c) } else { (-1, 'x') };
            let j = match states.iter().position(|&u| u == t) {
                Some(j) => j,
                None => { states.push(t); next.push([0, 0]); todo.push(states.len() - 1); states.len() - 1 }
            };
            next[i][k] = j;
        }
    }
    Machine { next, start: 0, accept: states.iter().map(|s| s.0 == 0).collect() }
}

fn counter_machine(cap: i64) -> Machine { // the small machine: states 0..cap, then dead
    let dead = (cap + 1) as usize;
    let mut next = Vec::new();
    for s in 0..=dead as i64 {
        let step = |d: i64| if s == dead as i64 || d < 0 || d > cap { dead } else { d as usize };
        next.push([step(s + 1), step(s - 1)]);
    }
    Machine { next, start: 0, accept: (0..=dead).map(|s| s == 0).collect() }
}

fn run(m: &Machine, w: &str) -> bool {
    let mut s = m.start;
    for c in w.chars() { s = m.next[s][(c == ')') as usize] }
    m.accept[s]
}

fn minimise(m: &Machine) -> (usize, Vec<usize>) { // Moore: split until no letter splits a block
    let mut label: Vec<usize> = m.accept.iter().map(|&a| a as usize).collect();
    let mut sizes = vec![label.iter().collect::<BTreeSet<_>>().len()];
    loop {
        let sig: Vec<(usize, usize, usize)> =
            (0..m.next.len()).map(|s| (label[s], label[m.next[s][0]], label[m.next[s][1]])).collect();
        let keys: Vec<(usize, usize, usize)> = sig.iter().cloned().collect::<BTreeSet<_>>().into_iter().collect();
        sizes.push(keys.len());
        if keys.len() == sizes[sizes.len() - 2] { return (keys.len(), sizes) }
        label = sig.iter().map(|g| keys.iter().position(|k| k == g).unwrap()).collect();
    }
}

fn classes(cap: i64, n: usize) -> usize { // Myhill-Nerode by brute force: distinct futures
    let tails = words(n, "()");
    words(n, "()").iter()
        .map(|x| tails.iter().map(|z| balanced(&format!("{}{}", x, z), cap)).collect::<Vec<bool>>())
        .collect::<BTreeSet<_>>().len()
}

fn abc(w: &str) -> bool { // a^i b^j c^k with i = 0 or j = k
    let (mut i, mut j, mut k) = (0, 0, 0);
    for c in w.chars() {
        if c == 'a' && j == 0 && k == 0 { i += 1 }
        else if c == 'b' && k == 0 { j += 1 }
        else if c == 'c' { k += 1 }
        else { return false }
    }
    i == 0 || j == k
}

fn show(w: &str) -> &str { if w.is_empty() { "empty" } else { w } }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn join<T: ToString>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- depth at most 3: the formula, the 5-state machine and the draft ----
    let (m3, d3) = (counter_machine(3), draft(3));
    let all12 = words(12, "()");
    let agree = all12.iter().all(|w| balanced(w, 3) == run(&m3, w) && run(&m3, w) == run(&d3, w));
    let (n_min, sizes) = minimise(&d3);
    println!("formula {} -> brackets {}, length {}, deepest 3", F3, brackets(F3), brackets(F3).len());
    println!("counter, 5-state machine, {}-state draft agree on all {} strings to length 12: {}", d3.next.len(), all12.len(), yn(agree));
    println!("Moore refinement of the draft, blocks after each round: {}", join(&sizes));
    println!("smallest machine: {} states; Myhill-Nerode classes (strings to length 8): {}", n_min, classes(3, 8));
    let reps = ["", "(", "((", "(((", ")"];
    let mut pairs: Vec<(usize, usize, String)> = Vec::new();
    for a in 0..5 {
        for b in a + 1..5 {
            let z = words(6, "()").into_iter()
                .find(|z| balanced(&format!("{}{}", reps[a], z), 3) != balanced(&format!("{}{}", reps[b], z), 3)).unwrap();
            println!("  {} vs {}: told apart by z = {}", show(reps[a]), show(reps[b]), show(&z));
            pairs.push((a, b, z));
        }
    }
    let cert = pairs.iter().all(|(a, b, z)| run(&m3, &format!("{}{}", reps[*a], z)) != run(&m3, &format!("{}{}", reps[*b], z)));
    println!("  {} pairs, each also told apart by the 5-state machine: {}", pairs.len(), yn(cert));
    for cap in [1, 2, 3, 4, 5, 6, 64] {
        println!("cap {}: draft {} states, smallest {} states", cap, draft(cap).next.len(), minimise(&draft(cap)).0);
    }
    // ---- the pigeonhole inside the pumping lemma, run on the 5-state machine ----
    let w = brackets(F3);
    let mut trace = vec![0usize];
    for c in w.chars() { trace.push(m3.next[*trace.last().unwrap()][(c == ')') as usize]) }
    let first = (0..6).flat_map(|b| (0..b).map(move |a| (a, b))).find(|&(a, b)| trace[a] == trace[b]).unwrap();
    let (x, y, z) = (&w[..first.0], &w[first.0..first.1], &w[first.1..]);
    let pumped: Vec<String> = (0..4).map(|i| format!("{}{}{}", x, y.repeat(i), z)).collect();
    println!("run on {}: states {}; state {} after {} and {} letters, inside the first 6 states", w, join(&trace), trace[first.0], first.0, first.1);
    println!("x = {}, y = {}, z = {}; pumped i = 0..3: {}", x, y, z, pumped.join(", "));
    println!("all pumped words accepted: {}", yn(pumped.iter().all(|v| run(&m3, v))));
    // ---- unbounded brackets: pumping refuted, classes without end ----
    let mut fails = vec![(0usize, 0usize); 13];
    for p in 1..13usize {
        let w = format!("{}{}", "(".repeat(p), ")".repeat(p));
        let splits: Vec<(usize, usize)> = (1..=p).flat_map(|k| (0..=p - k).map(move |j| (j, k))).collect();
        fails[p] = (splits.len(), splits.iter().filter(|&&(j, k)| !balanced(&format!("{}{}", &w[..j], &w[j + k..]), BIG)).count());
    }
    let all_fail = (1..13).all(|p| fails[p].0 == fails[p].1);
    println!("w = (^5)^5: splits with |xy| <= 5, |y| >= 1: {}; failing at i = 0: {}", fails[5].0, fails[5].1);
    println!("every split fails, for every p from 1 to 12: {}", yn(all_fail));
    let told = (0..7).all(|j| (0..7).all(|k| j == k ||
        (balanced(&format!("{}{}", "(".repeat(j), ")".repeat(j)), BIG) && !balanced(&format!("{}{}", "(".repeat(k), ")".repeat(j)), BIG))));
    let grow: Vec<usize> = [2, 4, 6, 8].iter().map(|&n| classes(BIG, n)).collect();
    println!("(^0 .. (^6: all 21 pairs told apart by )^j: {}", yn(told));
    println!("classes seen with strings to length n = 2, 4, 6, 8: {}", join(&grow));
    // ---- what breaks ----
    let b4 = brackets(F4);
    println!("depth-3 machine on {} = {}: counter {}, machine {}", F4, b4, yn(balanced(&b4, BIG)), yn(run(&m3, &b4)));
    let mid_ok = (0..5).filter(|&i| balanced(&format!("(((({}))))", "()".repeat(i)), BIG)).count();
    println!("y = () from the middle of (^5)^5, i = 0..4: {} of 5 balanced, no contradiction", mid_ok);
    let in_l: Vec<String> = words(7, "abc").into_iter().filter(|w| !w.is_empty() && abc(w)).collect();
    let pumps = in_l.iter().all(|w| (0..5).all(|i| abc(&format!("{}{}", &w[..1].repeat(i), &w[1..]))));
    let ab: Vec<String> = (0..6).map(|j| format!("a{}", "b".repeat(j))).collect();
    let apart = (0..6).all(|j| (0..6).all(|k| j == k ||
        (abc(&format!("{}{}", ab[j], "c".repeat(j))) && !abc(&format!("{}{}", ab[k], "c".repeat(j))))));
    println!("a^i b^j c^k, i = 0 or j = k: all {} words to length 7 pump with p = 1: {}", in_l.len(), yn(pumps));
    println!("  yet a, ab, .., ab^5 are pairwise told apart by c^j: {}", yn(apart));
    println!("draft read as the minimum: {} states, true minimum {}", d3.next.len(), n_min);
    assert!(agree && n_min == 5 && classes(3, 8) == 5); // three roads to 5 states
    assert!(cert && [1, 2, 3, 4, 5, 6, 64].iter().all(|&c| minimise(&draft(c)).0 == c as usize + 2));
    assert!(all_fail && told); // brackets are not regular
    assert!(grow == vec![4, 6, 8, 10] && fails[5] == (15, 15));
    assert!(balanced(&b4, BIG) && !run(&m3, &b4) && pumps && apart);
    println!("ALL CHECKS PASS");
}
