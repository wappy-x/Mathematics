// Stable matching -- the same check as the Python, in Rust.  No crates.  Road
// one runs deferred acceptance, round by round, from either side.  Road two
// lists all 3! = 6 matchings and tests each for a blocking pair.
const DOC: [&str; 3] = ["Asha", "Ben", "Carys"]; const HOS: [&str; 3] = ["Northgate", "Riverside", "Southbank"];
type P = Vec<Vec<usize>>;
fn pos(list: &[usize], x: usize) -> usize { list.iter().position(|&y| y == x).unwrap() }
// pp propose to rp; returns (proposer -> partner, proposals, rounds)
fn accept(pp: &P, rp: &P, log: &mut Vec<String>, defer: bool) -> (Vec<usize>, usize, usize) {
    let (mut held, mut nxt, mut free, mut props, mut rounds) = (vec![None::<usize>; 3], vec![0; 3], vec![0, 1, 2], 0, 0);
    while !free.is_empty() {
        rounds += 1; let mut offers: Vec<(usize, Vec<usize>)> = Vec::new();
        for &p in &free {
            let r = pp[p][nxt[p]]; nxt[p] += 1; props += 1;
            match offers.iter_mut().find(|o| o.0 == r) { Some(o) => o.1.push(p), None => offers.push((r, vec![p])) }
        }
        free.clear(); for (r, ps) in &offers {
            let mut pool = ps.clone(); if let Some(h) = held[*r] { pool.push(h) }
            let keep = match held[*r] { Some(h) if !defer => h, _ => *pool.iter().min_by_key(|&&p| pos(&rp[*r], p)).unwrap() };
            held[*r] = Some(keep);
            free.extend(pool.iter().filter(|&&p| p != keep));
        }
        if log.capacity() > 0 {
            let moves: Vec<String> = offers.iter().flat_map(|(r, ps)| ps.iter().map(move |&p| format!("{}->{}", DOC[p], HOS[*r]))).collect();
            let mut rej = free.clone(); rej.sort(); let rejs: Vec<&str> = rej.iter().map(|&p| DOC[p]).collect();
            log.push(format!("round {}: {}; rejected: {}", rounds, moves.join(" "), if rejs.is_empty() { "nobody".to_string() } else { rejs.join(" ") }));
        }
    }
    let mut m = vec![0; 3]; for r in 0..3 { m[held[r].unwrap()] = r }
    (m, props, rounds)
}
fn blocking(m: &[usize], dp: &P, hp: &P) -> Vec<(usize, usize)> {   // pairs who both prefer each other
    let mut out = Vec::new(); for d in 0..3 { for h in 0..3 {
        if pos(&dp[d], h) < pos(&dp[d], m[d]) && pos(&hp[h], d) < pos(&hp[h], pos(m, h)) { out.push((d, h)) }
    } }
    out
}
fn names(m: &[usize]) -> String { (0..3).map(|d| format!("{}-{}", DOC[d], HOS[m[d]])).collect::<Vec<_>>().join(" ") }
fn pairs(bs: &[(usize, usize)]) -> String { bs.iter().map(|&(d, h)| format!("({}, {})", DOC[d], HOS[h])).collect::<Vec<_>>().join(" ") }
fn rank(m: &[usize], dp: &P, hp: &P) -> (Vec<usize>, Vec<usize>) {
    ((0..3).map(|d| pos(&dp[d], m[d]) + 1).collect(), (0..3).map(|h| pos(&hp[h], pos(m, h)) + 1).collect())
}
fn main() {
    let (dp, hp): (P, P) = (vec![vec![0, 1, 2], vec![0, 2, 1], vec![1, 2, 0]], vec![vec![2, 1, 0], vec![1, 0, 2], vec![0, 2, 1]]);
    let all: P = (0..3).flat_map(|a| (0..3).filter(move |&b| b != a).map(move |b| vec![a, b, 3 - a - b])).collect();
    let (mut log, mut none) = (Vec::with_capacity(8), Vec::new());
    let (md, pd, rd) = accept(&dp, &hp, &mut log, true);
    let (hm, ph, rh) = accept(&hp, &dp, &mut none, true);          // hospitals propose; turned round below
    let mh: Vec<usize> = (0..3).map(|d| pos(&hm, d)).collect();
    let stable: P = all.iter().filter(|m| blocking(m, &dp, &hp).is_empty()).cloned().collect();
    let best: Vec<usize> = (0..3).map(|d| stable.iter().map(|m| m[d]).min_by_key(|&h| pos(&dp[d], h)).unwrap()).collect();
    let worst: Vec<usize> = (0..3).map(|d| stable.iter().map(|m| m[d]).max_by_key(|&h| pos(&dp[d], h)).unwrap()).collect();
    println!("doctors 3, hospitals 3; possible matchings 3! = {}", all.len());
    for l in &log { println!("{}", l) }
    println!("doctor-proposing  : {}; proposals {}, rounds {}", names(&md), pd, rd);
    println!("hospital-proposing: {}; proposals {}, rounds {}", names(&mh), ph, rh);
    for m in &all { let b = pairs(&blocking(m, &dp, &hp)); println!("listing: {}  blocked by {}", names(m), if b.is_empty() { "nobody".to_string() } else { b }) }
    println!("stable by listing: {} of {}; best per doctor {}; worst {}", stable.len(), all.len(), names(&best), names(&worst));
    let (rd0, rd1, rh0, rh1) = (rank(&md, &dp, &hp).0, rank(&md, &dp, &hp).1, rank(&mh, &dp, &hp).0, rank(&mh, &dp, &hp).1);
    println!("ranks, doctors then hospitals: doctor-proposing {:?} {:?}; hospital-proposing {:?} {:?}", rd0, rd1, rh0, rh1);
    let (mut counts, mut most, mut profiles) = ([0usize; 3], 0, Vec::<P>::new());
    for a in &all { for b in &all { for c in &all { profiles.push(vec![a.clone(), b.clone(), c.clone()]) } } }
    for dq in &profiles { for hq in &profiles {
        let (m, p, _) = accept(dq, hq, &mut none, true); most = most.max(p);
        let st: Vec<&Vec<usize>> = all.iter().filter(|s| blocking(s, dq, hq).is_empty()).collect();
        counts[0] += blocking(&m, dq, hq).is_empty() as usize;
        counts[1] += (0..3).all(|d| st.iter().map(|s| s[d]).min_by_key(|&h| pos(&dq[d], h)).unwrap() == m[d]) as usize;
        counts[2] += (0..3).all(|h| st.iter().map(|s| pos(s, h)).max_by_key(|&d| pos(&hq[h], d)).unwrap() == pos(&m, h)) as usize;
    } }
    println!("all {} profiles: stable {}, doctors best {}, hospitals worst {}; most proposals {}; bounds 3*3 = {}, 3*3-3+1 = {}", all.len().pow(6), counts[0], counts[1], counts[2], most, 3 * 3, 3 * 3 - 3 + 1);
    let ia = accept(&dp, &hp, &mut none, false).0;
    let happy = all.iter().min_by_key(|m| rank(m, &dp, &hp).0.iter().sum::<usize>()).unwrap();
    println!("mistake 1, accept for good: {}; blocking {}", names(&ia), pairs(&blocking(&ia, &dp, &hp)));
    println!("mistake 2, most doctor happiness: {}, rank sum {}; blocking {}", names(happy), rank(happy, &dp, &hp).0.iter().sum::<usize>(), pairs(&blocking(happy, &dp, &hp)));
    println!("mistake 3, doctors short of first choice under doctor-proposing: {}; blocking pairs {}", rd0.iter().filter(|&&r| r > 1).count(), blocking(&md, &dp, &hp).len());
    assert!(md == best);                               // doctor-proposing = each doctor's best, by listing
    assert!(mh == worst);                              // hospital-proposing = each doctor's worst, by listing
    assert!(counts == [all.len().pow(6); 3]);          // stable, doctor-best, hospital-worst in every profile
    assert!(most == 3 * 3 - 3 + 1);                    // the proposal bound is reached, never passed
    println!("ALL CHECKS PASS");
}
