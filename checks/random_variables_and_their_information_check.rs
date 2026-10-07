// Random variables and their information -- the same check as the Python, in
// Rust, std only.  A toy league: each side scores 0 to 3 goals, home and away
// independent.  The 16 final scores are the outcomes; a set of scores is a
// 16-bit mask.  The total T = home + away generates sigma(T), built by two
// roads; Doob-Dynkin is then tested on every yes/no question about the score.
// The code checks one finite space exactly; the general theorem is the proof's.
use std::collections::{BTreeMap, BTreeSet};
const PH: [i64; 4] = [25, 35, 25, 15]; // P(home scores 0, 1, 2, 3), in hundredths
const PA: [i64; 4] = [35, 35, 20, 10]; // P(away scores 0, 1, 2, 3), in hundredths
const FULL: u32 = (1 << 16) - 1;

fn score(i: usize) -> (i64, i64) { ((i / 4) as i64, (i % 4) as i64) }

fn mask<F: Fn(i64, i64) -> bool>(test: F) -> u32 {  // the set of scores passing a test
    (0..16).filter(|&i| { let (h, a) = score(i); test(h, a) }).map(|i| 1u32 << i).sum()
}

fn prob(m: u32) -> i64 {                              // road one: add score by score, in 1/10000
    (0..16).filter(|&i| m >> i & 1 == 1).map(|i| { let (h, a) = score(i); PH[h as usize] * PA[a as usize] }).sum()
}

fn dec(n: i64, d: i64) -> String {                    // n/d rounded to 4 places, integers only
    let r = (20000 * n + d) / (2 * d);
    format!("{}.{:04}", r / 10000, r % 10000)
}

fn closure(gens: &[u32]) -> (BTreeSet<u32>, Vec<usize>) { // sigma road one: complements, unions, repeat
    let mut s: BTreeSet<u32> = gens.iter().copied().collect();
    let mut rounds = vec![s.len()];
    loop {
        let mut new = s.clone();
        for &m in &s { new.insert(FULL ^ m); for &n in &s { new.insert(m | n); } }
        if new == s { return (s, rounds); }
        s = new;
        rounds.push(s.len());
    }
}

fn level_sets<F: Fn(i64, i64) -> i64>(f: F) -> BTreeMap<i64, Vec<usize>> { // the scores sharing each value
    let mut out: BTreeMap<i64, Vec<usize>> = BTreeMap::new();
    for i in 0..16 { let (h, a) = score(i); out.entry(f(h, a)).or_default().push(i); }
    out
}

// build g with y = g(total) if one exists, else the atom that splits
fn g_of<Y: Fn(i64, i64) -> i64>(y: Y) -> Result<BTreeMap<i64, i64>, (i64, Vec<i64>)> {
    let mut g = BTreeMap::new();
    for (v, idx) in level_sets(|h, a| h + a) {
        let vals: Vec<i64> = idx.iter().map(|&i| { let (h, a) = score(i); y(h, a) })
            .collect::<BTreeSet<i64>>().into_iter().collect();
        if vals.len() > 1 { return Err((v, vals)); }
        g.insert(v, vals[0]);
    }
    Ok(g)
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let thresholds: Vec<u32> = (0..6).map(|t| mask(|h, a| h + a <= t)).collect();
    let (sig, rounds) = closure(&thresholds);
    let pre: BTreeSet<u32> = (0..128u32).map(|b| mask(|h, a| b >> (h + a) & 1 == 1)).collect();
    let atoms = level_sets(|h, a| h + a);
    let ph: Vec<String> = PH.iter().map(|&x| dec(x, 100)).collect();
    let pa: Vec<String> = PA.iter().map(|&x| dec(x, 100)).collect();
    println!("P(home scores 0..3): {}; P(away scores 0..3): {}", ph.join(", "), pa.join(", "));
    println!("each side scores 0 to 3 goals: scores 16, questions about the score 2^16 = {}", 1 << 16);
    let r: Vec<String> = rounds.iter().map(|x| x.to_string()).collect();
    println!("sigma(T) from the thresholds 'T <= t?': {} sets, rounds {}", sig.len(), r.join(" -> "));
    println!("sigma(T) as preimages of all 2^7 sets of totals: {} sets; same family: {}", pre.len(), yn(sig == pre));
    let sizes: Vec<String> = (0..7).map(|t| atoms[&t].len().to_string()).collect();
    println!("atoms, scores per total 0..6: {}", sizes.join(", "));
    let a2: Vec<String> = atoms[&2].iter().map(|&i| { let (h, a) = score(i); format!("{}-{}", h, a) }).collect();
    println!("total 2 atom: {}", a2.join(", "));
    let const_on_atoms: BTreeSet<u32> = (0..1u32 << 16)
        .filter(|&m| atoms.values().all(|idx| idx.iter().all(|&i| (m >> i & 1) == (m >> idx[0] & 1)))).collect();
    let agree = (0..1u32 << 16).all(|m| sig.contains(&m) == const_on_atoms.contains(&m));
    println!("of {} questions: in sigma(T) {}, constant on every atom {}, agree on all: {}",
             1 << 16, sig.len(), const_on_atoms.len(), yn(agree));
    let questions: Vec<(&str, fn(i64, i64) -> bool)> = vec![
        ("more than 3 goals", |h, a| h + a > 3),
        ("no goals at all", |h, a| h + a == 0),
        ("total is even", |h, a| (h + a) % 2 == 0),
        ("margin is even", |h, a| (h - a).rem_euclid(2) == 0),
        ("home won", |h, a| h > a),
        ("draw", |h, a| h == a),
        ("both teams scored", |h, a| h > 0 && a > 0),
    ];
    println!("question            | scores | P      | in sigma(T) | g(0..6) or the atom that splits");
    let mut verdict = vec![];
    for (name, test) in &questions {
        let m = mask(test);
        let g = g_of(|h, a| test(h, a) as i64);
        verdict.push((sig.contains(&m), g.is_ok()));
        let shown = match &g {
            Ok(g) => (0..7).map(|t| g[&t].to_string()).collect::<String>(),
            Err((v, vals)) => format!("total {} gives {:?}", v, vals),
        };
        println!("{:19} | {:6} | {} | {:11} | {}", name, m.count_ones(), dec(prob(m), 10000), yn(sig.contains(&m)), shown);
    }
    let bet = |h: i64, a: i64| if h + a > 3 { 19 } else { 0 }; // 10 staked on over 3.5, returns 19
    let gbv: Vec<i64> = g_of(bet).map(|g| (0..7).map(|t| g[&t]).collect()).unwrap_or_default(); // empty when no g
    println!("10 staked on over 3.5 returns g(T), g = {:?}", gbv);
    let (cv, cvals) = g_of(|h, a| h - a).unwrap_err();
    println!("home margin as g(T): none; total {} gives margins {:?}", cv, cvals);
    // probabilities by a second road: the law of T by convolution, and a running total
    let law: Vec<i64> = (0..7i64).map(|t| (0..4i64).filter(|h| (0..=3).contains(&(t - h)))
        .map(|h| PH[h as usize] * PA[(t - h) as usize]).sum()).collect();
    let home_win2: i64 = (0..4).map(|h| PH[h] * PA[..h].iter().sum::<i64>()).sum();
    let lw: Vec<String> = law.iter().map(|&p| dec(p, 10000)).collect();
    println!("law of T, P(T = 0..6): {}", lw.join(", "));
    let over = mask(|h, a| h + a > 3);
    println!("P(more than 3): by scores {}, by the law of T {}", dec(prob(over), 10000), dec(law[4..].iter().sum(), 10000));
    let hw = mask(|h, a| h > a);
    println!("P(home won): by scores {}, by home goals and a running total {}", dec(prob(hw), 10000), dec(home_win2, 10000));
    let cond: Vec<(i64, i64)> = (0..7).map(|t| (prob(hw & mask(|h, a| h + a == t)), law[t as usize])).collect();
    let cs: Vec<String> = cond.iter().map(|&(n, d)| dec(n, d)).collect();
    println!("P(home won | T = t), t = 0..6: {}", cs.join(", "));
    println!("  total 1 by hand: {}/{} = {}", cond[1].0, cond[1].1, dec(cond[1].0, cond[1].1));
    // what breaks
    let (coarse, _) = closure(&[over]);
    println!("mistake 1, home won read off the total: P(home won | T = 1) = {}, not 0 or 1", dec(cond[1].0, cond[1].1));
    println!("mistake 2, sigma(T) taken as its 7 values: it has 2^7 = {} sets", sig.len());
    println!("mistake 3, only 'more than 3?' recorded: {} sets; settles 'exactly 2 goals': {}",
             coarse.len(), yn(coarse.contains(&mask(|h, a| h + a == 2))));
    let sq_gens: Vec<u32> = (0..37).map(|v| mask(|h, a| (h + a) * (h + a) == v)).collect();
    let (sq, _) = closure(&sq_gens);
    println!("relabelled total T*T generates the same family: {}", yn(sq == sig));
    let (cx, cy) = (|h: i64| 95 + 50 * h, |a: i64| 185 - 50 * a); // the picture: 50 units per goal
    let fig: Vec<String> = (0..7i64).map(|t| { let (h, k) = ((t - 3).max(0), t.min(3));
        format!("{}: {},{} {},{}", t, cx(h), cy(t - h), cx(k), cy(t - k)) }).collect();
    println!("figure, cell 50, grid x 70..270, y 10..210, total lines from (x, y) to (x, y): {}", fig.join("; "));
    assert!(sig == pre && sig.len() == 1 << atoms.len() && sig.len() == 128); // two roads, one sigma(T)
    assert!(agree && const_on_atoms.len() == 128);                          // Doob-Dynkin on 65536 questions
    let firsts: Vec<bool> = verdict.iter().map(|v| v.0).collect();
    assert_eq!(firsts, vec![true, true, true, true, false, false, false]);
    assert!(verdict.iter().all(|&(v, w)| v == w));                          // membership = a g exists
    assert!(law[4..].iter().sum::<i64>() == prob(over) && home_win2 == prob(hw));
    assert!(coarse.len() == 4 && !coarse.contains(&mask(|h, a| h + a == 2))); // mistake 3
    assert!(sq == sig && gbv == vec![0, 0, 0, 0, 19, 19, 19]);               // T*T; the bet's g by hand
    assert!(cond[1] == (PH[1] * PA[0], PH[0] * PA[1] + PH[1] * PA[0]));      // 1-0 over 1-0 or 0-1, by hand
    println!("ALL CHECKS PASS");
}
