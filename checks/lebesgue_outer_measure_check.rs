// Outer measure -- the same check as the Python, in Rust.  No crates.  Exact
// rationals by hand on small integers, whole micrometres (um) on the fence, and
// random covers from SplitMix64 written out here.  The fence is [0, 3000000] um.
const M: i64 = 1_000_000;
type Iv = (i64, i64);

fn metres(um: i64) -> String {                           // whole um as metres, zeros trimmed
    let s = format!("{}.{:06}", um.abs() / M, um.abs() % M);
    let s = s.trim_end_matches('0').trim_end_matches('.').to_string();
    if um < 0 { format!("-{}", s) } else { s }
}

fn dec(mut num: u128, den: u128, digits: usize) -> String {   // long division, no float; cuts off, never rounds
    let mut out = format!("{}.", num / den);
    for _ in 0..digits {
        num = num % den * 10;
        out += &(num / den).to_string();
    }
    out
}

fn merge(ivs: &[Iv]) -> Vec<Iv> {      // road one: the union as disjoint open pieces
    let mut v = ivs.to_vec();
    v.sort();
    let mut out: Vec<Iv> = Vec::new();
    for (c, d) in v {
        match out.last_mut() {
            Some(last) if c < last.1 => last.1 = last.1.max(d),   // touching ends leave a point out
            _ => out.push((c, d)),
        }
    }
    out
}

fn covers(ivs: &[Iv], a: i64, b: i64) -> bool {
    merge(ivs).iter().any(|&(c, d)| c < a && d > b)
}

fn chain(ivs: &[Iv], a: i64, b: i64) -> Option<Vec<Iv>> {   // road two: the proof's walk
    let (mut x, mut used) = (a, Vec::new());
    loop {
        let best = *ivs.iter().filter(|iv| iv.0 < x && x < iv.1).max_by_key(|iv| (iv.1, iv.0))?;
        used.push(best);
        if best.1 > b { return Some(used) }
        x = best.1;
    }
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }

fn rationals(count: usize) -> Vec<(i64, i64)> {         // 0, 1, 1/2, 1/3, 2/3, ... each once
    let (mut out, mut q) = (Vec::new(), 1);
    while out.len() < count {
        for p in 0..=q { if gcd(p, q) == 1 { out.push((p, q)) } }
        q += 1;
    }
    out.truncate(count);
    out
}

fn show(r: (i64, i64)) -> String { if r.1 == 1 { r.0.to_string() } else { format!("{}/{}", r.0, r.1) } }

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn size(ivs: &[Iv]) -> i64 { ivs.iter().map(|&(c, d)| d - c).sum() }

fn join(ivs: &[Iv]) -> String {
    ivs.iter().map(|&(c, d)| format!("({}, {})", metres(c), metres(d))).collect::<Vec<_>>().join(", ")
}

fn main() {
    let spots: Vec<i64> = (1..=100).map(|k| 30000 * k).collect();   // a rust spot every 3 cm
    let fence = [(-1000, 3001000)];
    let spot_cover: Vec<Iv> = spots.iter().map(|&s| (s - 50, s + 50)).collect();
    let mut gap_cover: Vec<Iv> = vec![(-1000, 30000)];
    gap_cover.extend(spots[1..].iter().map(|&s| (s - 30000, s)));
    let pieces = merge(&gap_cover);
    let mut holes: Vec<Iv> = if pieces[0].0 >= 0 { vec![(0, pieces[0].0)] } else { vec![] };
    holes.extend(pieces.windows(2).map(|w| (w[0].1, w[1].0)));
    holes.push((pieces[pieces.len() - 1].1, 3 * M));
    let missed: Vec<i64> = holes.iter().filter(|h| h.0 == h.1).map(|h| h.0).collect();
    println!("fence [0, 3] m; {} rust spots at 0.03, 0.06, ..., {} m", spots.len(), metres(spots[99]));
    println!("cover of the fence: (-0.001, 3.001), total {} m", metres(size(&fence)));
    println!("cover of the spots: 100 intervals of {} m, total {} m", metres(100), metres(size(&spot_cover)));
    println!("cover of the fence minus the spots: {} gaps, total {} m", gap_cover.len(), metres(size(&gap_cover)));
    println!("points of the fence the gap cover misses: {}, exactly the spots: {}",
             missed.len(), if missed == spots { "yes" } else { "no" });
    println!("fence minus spots, lower bound by subadditivity: 3 - 0.01 = {} m", metres(3 * M - size(&spot_cover)));
    let mut tiny_gaps = gap_cover.clone();
    tiny_gaps[0] = (-1, 30000);
    let tiny_spots: Vec<Iv> = spots.iter().map(|&s| (s - 1, s + 1)).collect();
    println!("shrunk: gap cover {} m above, 3 - {} = {} m below",
             metres(size(&tiny_gaps)), metres(size(&tiny_spots)), metres(3 * M - size(&tiny_spots)));

    let qs = rationals(40);
    println!("rationals in [0, 1], first ten: {}", qs[..10].iter().map(|&q| show(q)).collect::<Vec<_>>().join(", "));
    println!("rational number k gets an interval of length 0.01 / 2^k around it");
    for n in [10u32, 20, 40] {
        let den: u128 = 100 << n;                                  // 100 * 2^n
        let by_terms: u128 = (1..=n).map(|k| 1u128 << (n - k)).sum();
        let closed: u128 = (1u128 << n) - 1;
        assert!(by_terms == closed);                               // geometric series, two roads
        println!("total after {} intervals: {}, short of 0.01 by 0.01 / 2^{}", n, dec(by_terms, den, 15), n);
    }

    let example: [Iv; 5] = [(-200000, 1100000), (800000, 1900000), (1000000, 1400000),
                            (1500000, 2600000), (2400000, 3300000)];
    let x = |um: i64| 40 + (9 * um).div_euclid(100000);          // 90 figure units per metre
    println!("figure, fence 0 to 3 m drawn from x=40 to x=310, 90 units per metre");
    println!("figure, {}", example.iter().map(|&(c, d)| format!("({}, {}) m at x {} to {}", metres(c), metres(d), x(c), x(d)))
             .collect::<Vec<_>>().join("; "));
    let walk = chain(&example, 0, 3 * M).unwrap();
    println!("chain from the proof: {}; chain total {} m, all five {} m", join(&walk), metres(size(&walk)), metres(size(&example)));
    assert!(walk == [example[0], example[1], example[3], example[4]] && size(&walk) == 4_400_000);  // the figure

    let (seed, per, trials) = (2026u64, 6, 20000);                 // seed, tapes per family, families
    let (mut state, mut hits, mut agree) = (seed, 0, true);
    let (mut low_total, mut low_chain) = (i64::MAX, i64::MAX);
    for _ in 0..trials {
        let mut fam: Vec<Iv> = Vec::new();
        for _ in 0..per {
            let (r1, r2) = (splitmix(&mut state), splitmix(&mut state));
            let c = -300000 + (r1 % 3200001) as i64;
            fam.push((c, c + 300000 + (r2 % 1200001) as i64));
        }
        let walked = chain(&fam, 0, 3 * M);
        agree = agree && (walked.is_some() == covers(&fam, 0, 3 * M));
        if let Some(w) = walked {
            hits += 1;
            assert!(size(&fam) >= size(&w) && size(&w) > 3 * M);  // the theorem, one cover at a time
            low_total = low_total.min(size(&fam));
            low_chain = low_chain.min(size(&w));
        }
    }
    println!("random families of {} open intervals (SplitMix64, seed {}): {}", per, seed, trials);
    println!("families covering [0, 3]: {}; union test and chain walk agree on every one: {}", hits, if agree { "yes" } else { "no" });
    println!("smallest total among covers: {} m; smallest chain total: {} m", metres(low_total), metres(low_chain));

    let first = |n: usize| -> (i64, i64) {                     // |a/b - p/r| >= 1 / (200 * 2^k)
        *rationals(n + 60).iter().find(|&&(a, b)| qs[..n].iter().enumerate().all(|(i, &(p, r))|
            ((a * r - p * b).abs() as i128) * (200i128 << (i + 1)) >= (b * r) as i128)).unwrap()
    };
    println!("mistake 1, finitely many intervals: the first 10 miss {}, the first 40 miss {}; \
              a finite cover of every rational in [0, 1] totals at least 1", show(first(10)), show(first(40)));
    let overlap = merge(&[(0, 2 * M), (M, 3 * M)]);
    println!("mistake 2, adding overlapping pieces: (0, 2) and (1, 3) give 2 + 2 = 4 m; their union is {} m", metres(size(&overlap)));
    println!("mistake 3, 'no interval inside, so size 0': irrationals in [0, 1] at least {}",
             [10000, 100, 1].iter().map(|&e| format!("1 - {} = {}", metres(e), metres(M - e))).collect::<Vec<_>>().join(", "));
    assert!(agree && hits > 0);                                    // two roads to "is it a cover"
    assert!(missed == spots && holes.len() == missed.len());        // the gaps miss exactly the spots
    assert!(size(&overlap) == 3 * M);                               // the union is (0, 3)
    let touch = [(-M, 3 * M / 2), (3 * M / 2, 4 * M)];              // meet at 1.5 m, leave it out
    assert!(chain(&touch, 0, 3 * M).is_none() && !covers(&touch, 0, 3 * M));
    for bare in [(0, 3 * M + 1000), (-1000, 3 * M)] {                // one tape, one fence end left out
        assert!(chain(&[bare], 0, 3 * M).is_none() && !covers(&[bare], 0, 3 * M));
    }
    println!("ALL CHECKS PASS");
}
