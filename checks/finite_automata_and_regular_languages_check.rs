// Finite automata -- the same check as the Python, in Rust.  No crates.
// A coin machine reads 5p, 10p and 20p coins and accepts exactly 30p.  Its
// language is found three ways: running the machine, adding up each coin
// sequence, and a counting recurrence.  Then a product machine, a complement,
// and a bracket checker with fixed memory that the pigeonhole argument fools.
const COINS: [i64; 3] = [5, 10, 20];
const TARGET: i64 = 30;
const OVER: i64 = -1;
const DEPTH: i64 = 3;                            // the bracket machine's limit

fn name(q: i64) -> String { if q == OVER { "over".to_string() } else { q.to_string() } }

fn step(q: i64, a: i64) -> i64 {                 // the rule delta(q, a): one coin, one move
    if q == OVER || q + a > TARGET { OVER } else { q + a }
}

fn run(w: &[i64]) -> Vec<i64> {                  // feed the coins one at a time, keep the trail
    let mut trail = vec![0];
    for &a in w { let q = *trail.last().unwrap(); trail.push(step(q, a)); }
    trail
}

fn strings<T: Clone>(alphabet: &[T], n: usize) -> Vec<Vec<T>> {  // every string of length n
    let mut out: Vec<Vec<T>> = vec![vec![]];
    for _ in 0..n {
        let mut next = Vec::new();
        for w in &out {
            for a in alphabet { let mut v = w.clone(); v.push(a.clone()); next.push(v); }
        }
        out = next;
    }
    out
}

fn upto<T: Clone>(alphabet: &[T], n: usize) -> Vec<Vec<T>> {
    (0..=n).flat_map(|k| strings(alphabet, k)).collect()
}

fn text(w: &[i64]) -> String { w.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(" ") }

fn joined(ws: &[Vec<i64>]) -> String { ws.iter().map(|w| text(w)).collect::<Vec<_>>().join(" | ") }

fn count_step(k: i64) -> i64 { (k + 1).min(4) }  // machine B: how many coins, 0 1 2 3 or 4+

fn product_accepts(w: &[i64]) -> bool {
    let (mut q, mut k) = (0, 0);
    for &a in w { q = step(q, a); k = count_step(k); }
    q == TARGET && k <= 3
}

fn bracket_dfa(w: &str, depth: i64) -> i64 {     // fixed memory: open count 0..depth, else dead (OVER)
    let mut q = 0;
    for s in w.chars() {
        if q == OVER { break; }
        q = if s == '(' { q + 1 } else { q - 1 };
        if q < 0 || q > depth { q = OVER; }
    }
    q
}

fn depth(w: &str) -> i64 {                       // deepest nesting, read off prefix counts
    (0..=w.len()).map(|t| w[..t].matches('(').count() as i64 - w[..t].matches(')').count() as i64).max().unwrap()
}

fn counter_ok(w: &str) -> bool {                 // unbounded memory: an integer counter
    let mut d = 0;
    for s in w.chars() {
        d += if s == '(' { 1 } else { -1 };
        if d < 0 { return false; }
    }
    d == 0
}

fn verdict(ok: bool) -> &'static str { if ok { "accept" } else { "reject" } }

fn main() {
    let mut states: Vec<i64> = (0..=TARGET / 5).map(|k| 5 * k).collect();
    states.push(OVER);
    let bits = 64 - ((states.len() - 1) as u64).leading_zeros();
    let names: Vec<String> = states.iter().map(|&q| name(q)).collect();
    println!("coin machine: alphabet {:?}; states {}; start 0; accept {}", COINS, names.join(" "), TARGET);
    println!("{} states fit in {} bits, however many coins arrive", states.len(), bits);
    println!("state: after 5, after 10, after 20");
    for &q in &states {
        let row: Vec<String> = COINS.iter().map(|&a| name(step(q, a))).collect();
        println!("  {}: {}", name(q), row.join(", "));
    }
    for w in [vec![10, 5, 5, 10], vec![20, 5, 10], vec![10, 10]] {
        let t = run(&w);
        let trail: Vec<String> = t.iter().map(|&q| name(q)).collect();
        println!("run {}: {}, {} steps, {}", text(&w), trail.join(" -> "), w.len(), verdict(*t.last().unwrap() == TARGET));
    }
    let all = upto(&COINS, 8);
    let by_machine: Vec<Vec<i64>> = all.iter().filter(|w| *run(w).last().unwrap() == TARGET).cloned().collect();
    let by_sum: Vec<Vec<i64>> = all.iter().filter(|w| w.iter().sum::<i64>() == TARGET).cloned().collect();  // road two
    let mut c: Vec<i64> = vec![1];                                // road three: in 5p units
    for k in 1..=(TARGET / 5) as usize {
        c.push([1usize, 2, 4].iter().filter(|&&d| d <= k).map(|&d| c[k - d]).sum());
    }
    println!("coin sequences of 0 to 8 coins checked: {}", all.len());
    println!("accepted by the machine: {}; by adding the coins: {}", by_machine.len(), by_sum.len());
    let cs: Vec<String> = c.iter().map(|x| x.to_string()).collect();
    println!("recurrence c(k) = c(k-1) + c(k-2) + c(k-4), k in 5p units: {}", cs.join(" "));
    for n in 1..=8 {
        let found: Vec<Vec<i64>> = by_machine.iter().filter(|w| w.len() == n).cloned().collect();
        if !found.is_empty() { println!("  {} coins ({}): {}", n, found.len(), joined(&found)); }
    }
    let longest = by_machine.iter().map(|w| w.len()).max().unwrap();
    println!("longest accepted: {} coins; any {} coins make at least {}p", longest, longest + 1, 5 * (longest + 1));
    let mut pairs: Vec<(i64, i64)> = vec![(0, 0)];               // product machine: run both side by side
    let mut todo = vec![(0i64, 0i64)];
    while let Some((q, k)) = todo.pop() {
        for &a in &COINS {
            let nxt = (step(q, a), count_step(k));
            if !pairs.contains(&nxt) { pairs.push(nxt); todo.push(nxt); }
        }
    }
    let both: Vec<Vec<i64>> = all.iter().filter(|w| product_accepts(w)).cloned().collect();
    let both_brute: Vec<Vec<i64>> = by_sum.iter().filter(|w| w.len() <= 3).cloned().collect();
    let either = all.iter().filter(|w| by_sum.contains(w) || w.len() <= 3).count();
    println!("product machine, exactly {}p AND at most 3 coins: {} x 5 = {} pairs, {} reachable", TARGET, states.len(), states.len() * 5, pairs.len());
    println!("  accepted by the product: {}; by brute force: {}: {}", both.len(), both_brute.len(), joined(&both));
    let six = upto(&COINS, 6);
    let flipped = six.iter().filter(|w| *run(w).last().unwrap() != TARGET).count();
    let partial = six.iter().filter(|w| { let t = run(w); !t.contains(&OVER) && *t.last().unwrap() != TARGET }).count();
    println!("complement on 0 to 6 coins: {} strings - {} = {} accepted after swapping accept states", six.len(), by_machine.len(), flipped);
    println!("mistake 1, swap accept states with no over state: accepts {}, not {}", partial, flipped);
    println!("mistake 2, accept if either test passes: {} accepted on 0 to 8 coins, not {}", either, both.len());
    let (no_coins, nonempty) = (*run(&[]).last().unwrap() != TARGET, six.iter().filter(|w| !w.is_empty() && *run(w).last().unwrap() != TARGET).count());
    println!("empty string: in the complement {}; left out, the complement counts {}, not {}", if no_coins { "yes" } else { "no" }, nonempty, flipped);
    let b: Vec<String> = upto(&['(', ')'], 8).iter().map(|w| w.iter().collect()).collect();
    let good = b.iter().filter(|w| counter_ok(w)).count();
    let dfa = b.iter().filter(|w| bracket_dfa(w, DEPTH) == 0).count();
    let wrong: Vec<String> = b.iter().filter(|w| counter_ok(w) != (bracket_dfa(w, DEPTH) == 0)).cloned().collect();
    println!("brackets, 0 to 8 symbols: {} strings; balanced by the counter: {}; depth-{} machine accepts {}", b.len(), good, DEPTH, dfa);
    println!("mistake 3, depth-{} machine ({} states) wrong on {}: {}", DEPTH, DEPTH + 2, wrong.len(), wrong.join(" "));
    let top = (DEPTH + 3) as usize;
    let seen: Vec<i64> = (0..top).map(|i| bracket_dfa(&"(".repeat(i), DEPTH)).collect();
    let (i, j) = (0..top).flat_map(|b| (0..b).map(move |a| (a, b))).find(|&(a, b)| seen[a] == seen[b]).unwrap();
    let ss: Vec<String> = seen.iter().map(|&q| if q == OVER { "dead".to_string() } else { q.to_string() }).collect();
    println!("pigeonhole: after 0 to {} opens the states are {}; first repeat at {} and {} opens", DEPTH + 2, ss.join(" "), i, j);
    let (x, y) = ("(".repeat(i) + &")".repeat(i), "(".repeat(j) + &")".repeat(i));
    for w in [&x, &y] {
        println!("  {}: balanced {}, machine {}", w, if counter_ok(w) { "yes" } else { "no" }, verdict(bracket_dfa(w, DEPTH) == 0));
    }
    let mut cat: Vec<i64> = vec![1];                              // Catalan numbers, by their own recurrence
    for n in 0..4 { cat.push((0..=n).map(|t| cat[t] * cat[n - t]).sum()); }
    assert!(by_machine == by_sum);                                // road one against road two
    assert!(by_sum.len() as i64 == *c.last().unwrap());           // road two against road three
    assert!(both == both_brute);                                  // product against brute force
    let mut brute: Vec<(i64, i64)> = all.iter().map(|w| (*run(w).last().unwrap(), (w.len() as i64).min(4))).collect();
    brute.sort(); brute.dedup(); pairs.sort();
    assert!(pairs == brute);                                      // reachable pairs, by brute force
    assert!(flipped + by_sum.iter().filter(|w| w.len() <= 6).count() == six.len());
    assert!(partial as i64 == c[..c.len() - 1].iter().sum::<i64>()); // totals 0p to 25p, counted
    assert!(no_coins && !by_machine.contains(&vec![]));          // no coins: the complement accepts
    assert!(good as i64 == cat.iter().sum::<i64>());             // counter against Catalan
    let deep: Vec<String> = b.iter().filter(|w| counter_ok(w) && depth(w) > DEPTH).cloned().collect();
    assert!(wrong == deep);                                       // wrong exactly when too deep
    assert!(bracket_dfa(&y, DEPTH) == bracket_dfa(&x, DEPTH));    // same state, same answer,
    assert!(counter_ok(&x) != counter_ok(&y));                    // but only one is balanced
    println!("ALL CHECKS PASS");
}
