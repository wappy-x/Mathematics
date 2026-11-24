// The Lovasz local lemma -- the same check as the Python, in Rust, no crates.  A
// 10-SAT formula: 1000 on/off variables, 3800 clauses of 10.  The rule e p (d+1) <= 1
// is tested, resampling finds a setting, a ring of six clauses is listed in full.
fn rnd(s: &mut u64, n: u64) -> u64 {     // a fixed pseudo-random stream, the same as the Python
    *s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    (*s >> 33) % n
}
fn c(n: f64, k: u32) -> f64 { (0..k).fold(1.0, |o, i| o * (n - i as f64) / (i as f64 + 1.0)) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn formula(r: &mut u64, layers: usize, colour: bool) -> (usize, usize, usize, usize, bool) {
    let (mut sets, mut bad): (Vec<Vec<usize>>, Vec<Vec<u64>>) = (vec![], vec![]);
    for _ in 0..layers {                  // one shuffle of all 1000 variables per layer
        let mut p: Vec<usize> = (0..1000).collect();
        for i in (1..1000).rev() { let j = rnd(r, i as u64 + 1) as usize; p.swap(i, j) }
        for b in (0..1000).step_by(10) { sets.push(p[b..b + 10].to_vec()); bad.push((0..10).map(|_| rnd(r, 2)).collect()) }
    }
    let mut used = vec![vec![]; 1000];    // clauses per variable
    for (ci, vs) in sets.iter().enumerate() { for &v in vs { used[v].push(ci) } }
    let d = sets.iter().map(|vs| {        // neighbours of the worst set
        let mut nb: Vec<usize> = vs.iter().flat_map(|&v| used[v].iter().copied()).collect();
        nb.sort(); nb.dedup(); nb.len() - 1 }).max().unwrap();
    let mut x: Vec<u64> = (0..1000).map(|_| rnd(r, 2)).collect();
    let fails = |x: &Vec<u64>, ci: usize| if colour { sets[ci].iter().all(|&v| x[v] == x[sets[ci][0]]) }
        else { sets[ci].iter().zip(&bad[ci]).all(|(&v, &b)| x[v] == b) };
    let (start, mut fixes) = ((0..sets.len()).filter(|&ci| fails(&x, ci)).count(), 0);
    while let Some(ci) = (0..sets.len()).find(|&ci| fails(&x, ci)) {
        for &v in &sets[ci] { x[v] = rnd(r, 2) }   // resample the failing clause's variables
        fixes += 1;
    }
    let ok = sets.iter().zip(&bad).all(|(vs, bb)| if colour { let t: u64 = vs.iter().map(|&v| x[v]).sum(); t > 0 && t < 10 }
        else { vs.iter().zip(bb).any(|(&v, &b)| x[v] != b) });   // checked literal by literal
    (sets.len(), d, start, fixes, ok)
}
fn top(test: &dyn Fn(f64, u32) -> bool, k: u32) -> u64 {   // largest n passing: double, then halve the gap
    let mut lo = k as u64;
    while test(2.0 * lo as f64, k) { lo *= 2 }
    for t in (0..64 - lo.leading_zeros()).rev() { if test((lo + (1 << t)) as f64, k) { lo += 1 << t } }
    lo
}
fn main() {
    let (mut e, mut f) = (0.0f64, 1.0f64);   // e = 1/0! + 1/1! + 1/2! + ...
    for j in 0..20 { e += 1.0 / f; f *= (j + 1) as f64 }
    let d_top = (0..2000).find(|&d| e * (d + 2) as f64 / 1024.0 > 1.0).unwrap();
    let mut r = 2026u64;                 // floating-point Ramsey counts here; the Python's are exact
    let (m, d, start, fixes, ok) = formula(&mut r, 38, false);
    let (h, hd, hs, hf, hok) = formula(&mut r, 19, true);
    let mut hist = [0u64; 64];            // ring: clause i fails iff v_i, a_i, b_i = 0 and v_i+1 = 1
    for a in 0u32..1 << 18 {
        let q = (0..6).filter(|&i| a & (1 << i | 3 << (6 + 2 * i) | 1 << ((i + 1) % 6)) == 1 << ((i + 1) % 6)).fold(0, |q, i| q | 1 << i);
        hist[q] += 1;
    }
    let (mut p, mut p5) = ([[1u64, 0], [0, 1]], [[0u64; 2]; 2]);   // second road: a 2 x 2 matrix to the 5th and 6th powers
    for _ in 0..6 { p5 = p; p = [0, 1].map(|i| [p[i][0] * 4 + p[i][1] * 4, p[i][0] * 3 + p[i][1] * 4]) }
    let cnt = |mask: &dyn Fn(usize) -> bool| (0..64).filter(|&q| mask(q)).map(|q| hist[q]).sum::<u64>() as f64;
    let worst = (0..6).flat_map(|i| (0..64usize).filter(move |s| s >> i & 1 == 0).map(move |s| (i, s)))
        .map(|(i, s)| cnt(&|q| q & s == 0 && q >> i & 1 == 1) / cnt(&|q| q & s == 0)).fold(0.0, f64::max);
    let erd = |n: f64, k: u32| 2.0 * c(n, k) < 2f64.powi(c(k as f64, 2) as i32);
    let lll = move |n: f64, k: u32| e * ((2..k).map(|i| c(k as f64, i) * c(n - k as f64, k - i)).sum::<f64>() + 1.0)
        / 2f64.powi(c(k as f64, 2) as i32 - 1) <= 1.0;
    let rows: Vec<(u32, u64, u64)> = [10, 20, 30, 40].iter().map(|&k| (k, top(&erd, k), top(&lll, k))).collect();
    let none = (0..1024u32).filter(|z| !(0..1024u32).any(|cl| (0..10).all(|v| z >> v & 1 == cl >> v & 1))).count();   // clause cl bans setting cl
    println!("10-SAT: p = 1/1024; e = {:.9}; e x p x (d + 1) at d = 375: {:.5}, at 376: {:.5}", e, e * 376.0 / 1024.0, e * 377.0 / 1024.0);
    println!("largest d the rule allows: {} by floor(1024/e) - 1, {} by stepping up", (1024.0 / e) as i64 - 1, d_top);
    println!("formula: 1000 variables, {} clauses of 10, each variable in {}; worst clause meets {} others", m, m / 100, d);
    println!("union bound: {}/1024 = {:.2}, over 1, so counting alone says nothing", m, m as f64 / 1024.0);
    println!("resampling: {} clauses fail at the random start; after {} fixes, all hold: {}", start, fixes, yn(ok));
    println!("2-colouring {} ten-sets: rule allows d up to {}, worst here {}; {} one-colour at start, after {} fixes none: {}",
             h, (512.0 / e) as i64 - 1, hd, hs, hf, yn(hok));
    println!("ring of 6 clauses, 4 variables each, d = 2: e x 3/16 = {:.5}", e * 3.0 / 16.0);
    println!("ring good settings: {} of {} by listing, {} by matrix power, share {:.5}", hist[0], 1 << 18, p[0][0] + p[1][1], hist[0] as f64 / 262144.0);
    println!("lemma's floor (2/3)^6 = {:.5}; worst chance a clause fails given others hold: {:.5}, cap 1/3", (2.0f64 / 3.0).powi(6), worst);
    println!("Ramsey, largest n each test clears (counting, local lemma, ratio):");
    for &(k, a, b) in &rows { println!("k = {}: {}, {}, {:.2}", k, a, b, b as f64 / a as f64) }
    println!("mistake, drop the e: 1024 clauses on 10 variables give p(d+1) = {:.1}; settings that work: {}", 1024.0 / 1024.0, none);
    assert!(d_top == (1024.0 / e) as usize - 1 && d_top == 375 && d <= d_top && ok && hok && hd <= (512.0 / e) as usize - 1);
    assert!(hist[0] == p[0][0] + p[1][1] && (worst - p5[1][0] as f64 / (p5[1][0] + p[0][0] + p[1][1]) as f64).abs() < 1e-12);   // listing against the matrix powers
    assert!(hist[0] as f64 / 262144.0 >= (2.0f64 / 3.0).powi(6) && worst <= 1.0 / 3.0);   // the lemma's two claims
    assert!(rows.iter().map(|&(_, a, b)| (a, b)).collect::<Vec<_>>() == [(100, 104), (5817, 7753), (272717, 406690), (11490820, 18213047)] && rows.iter().all(|&(k, a, b)| !erd((a + 1) as f64, k) && !lll((b + 1) as f64, k)));
    println!("ALL CHECKS PASS");
}
