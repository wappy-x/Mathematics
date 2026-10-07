// Martingale convergence -- the check behind the card.  Rust std only.
// Polya's urn: 1 red and 1 blue ball; draw one at random, put it back with one
// more of its colour.  R reds after n draws; M_n = R/(n+2) is the fraction red.
// Roads: exact integer dynamic programming, listing every draw sequence, closed
// formulas, and a seeded SplitMix64 simulation printed with standard errors.
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn fr(p: u128, q: u128) -> String { let g = gcd(p, q); format!("{}/{}", p / g, q / g) }
fn fact(n: u128) -> u128 { (1..=n).product() }
fn lo(r: u64, t: u64) -> bool { 5 * r <= 2 * (t + 2) } // M_t <= a = 0.4
fn hi(r: u64, t: u64) -> bool { 5 * r >= 3 * (t + 2) } // M_t >= b = 0.6
// road 1: P(R = r) * (n+1)!, stepping the urn; t+2 balls, red with chance r/(t+2)
fn law(n: usize) -> Vec<u128> {
    let mut w = vec![0u128; n + 3]; w[1] = 1;
    for t in 0..n {
        let mut nxt = vec![0u128; n + 3];
        for r in 1..=t + 1 {
            nxt[r + 1] += w[r] * r as u128;
            nxt[r] += w[r] * (t + 2 - r) as u128;
        }
        w = nxt;
    }
    w
}
// road 1: E[U_n], carrying (reds, armed) forward.  Exact: numerators over (t+2)!,
// rescaled to (n+1)!, in u128; float (for long runs): probabilities in f64.
fn up_dp(n: usize, exact: bool) -> (u128, f64) {
    let (mut wi, mut wf) = (vec![ [0u128; 2]; n + 3], vec![ [0f64; 2]; n + 3]);
    wi[1][0] = 1; wf[1][0] = 1.0;
    let (mut eui, mut euf) = (0u128, 0f64);
    for t in 0..n {
        let (mut ni, mut nf, mut ci, mut cf) = (vec![ [0u128; 2]; n + 3], vec![ [0f64; 2]; n + 3], 0u128, 0f64);
        for r in 1..=t + 1 { for a in 0..2 { for (r2, q) in [(r + 1, r), (r, t + 2 - r)] {
            let (pi, pf) = (if exact { wi[r][a] * q as u128 } else { 0 }, wf[r][a] * q as f64);
            let a2 = if a == 1 && hi(r2 as u64, t as u64 + 1) { ci += pi; cf += pf; 0 }
                     else if a == 1 || lo(r2 as u64, t as u64 + 1) { 1 } else { 0 };
            ni[r2][a2] += pi; nf[r2][a2] += pf;
        } } }
        if exact { eui += ci * (fact(n as u128 + 1) / fact(t as u128 + 2)); }
        euf += cf / (t + 2) as f64;
        wi = ni;
        wf = nf.iter().map(|v| [v[0] / (t + 2) as f64, v[1] / (t + 2) as f64]).collect();
    }
    (eui, euf)
}
// road 2: every draw sequence, weighted; k reds has chance k!(n-k)!/(n+1)!
fn up_list(n: u64) -> u128 {
    let mut total = 0u128;
    for mask in 0u64..(1 << n) {
        let (mut r, mut armed, mut u) = (1u64, false, 0u128);
        for t in 0..n {
            r += mask >> t & 1;
            if armed && hi(r, t + 1) { u += 1; armed = false; } else if lo(r, t + 1) { armed = true; }
        }
        let k = (r - 1) as u128;
        total += u * fact(k) * fact(n as u128 - k);
    }
    total
}
fn next(s: &mut u64) -> u64 { // SplitMix64, written out
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn mse(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    (m, (xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    println!("exact law of the reds R after n draws; road 2 is the formula P(R = r) = 1/(n+1)");
    for n in 1..=20usize {
        let (w, den) = (law(n), fact(n as u128 + 1));
        assert!((1..=n + 1).all(|r| w[r] * (n as u128 + 1) == den) && w[0] == 0 && w[n + 2] == 0);
        assert!(2 * (1..=n + 1).map(|r| r as u128 * w[r]).sum::<u128>() == (n as u128 + 2) * den); // E[M_n] = 1/2
        if n <= 3 {
            let s: Vec<String> = (1..=n + 1).map(|r| format!("P(R={}) = {}", r, fr(w[r], den))).collect();
            println!("n={}: {}", n, s.join("  "));
        }
    }
    let order = |q: &str| -> u128 { let v: Vec<char> = q.chars().collect(); (0..3).map(|t| 1 + v[..t].iter().filter(|&&c| c == v[t]).count() as u128).product() };
    let ords: Vec<String> = ["RRB", "RBR", "BRR"].iter().map(|q| format!("{} {}", q, fr(order(q), 2 * 3 * 4))).collect();
    println!("by hand: M_1 = {} or {}, chance 1/2 each, average {}; 3 draws, 2 reds, each order: {}", fr(2, 3), fr(1, 3), fr(2 + 1, 6), ords.join(" "));
    println!("E[M_n] = 1/2 and every P(R = r) = 1/(n+1), n = 1..20: both roads agree");
    let (n, den) = (16u128, fact(17));
    let (e1, e2) = (up_dp(16, true).0, up_list(16));
    let bnum: u128 = (1..=n + 1).map(|j| (2 * (n + 2)).saturating_sub(5 * j)).sum(); // E[(M_n - a)^-] * 5(n+2)(n+1)
    let bden = 5 * (n + 2) * (n + 1);
    assert!(e1 == e2); // two roads to E[U]
    assert!(e1 * bden < 5 * bnum * den); // E[U] under the bound; 1/(b - a) = 5
    println!("upcrossings of [0.4, 0.6] in {} draws: E[U] by DP {} = {:.6}", n, fr(e1, den), e1 as f64 / den as f64);
    println!("  by listing all {} draw sequences {} = {:.6}", 1u64 << 16, fr(e2, den), e2 as f64 / den as f64);
    println!("  E[(M_n - 0.4)^-] = {} = {:.6}; bound E[(M_n - a)^-]/(b - a) = {:.6}", fr(bnum, bden), bnum as f64 / bden as f64, 5.0 * bnum as f64 / bden as f64);
    let eu1000 = up_dp(1000, false).1;
    let b1000: f64 = (1..1002).map(|j| (0.4 - j as f64 / 1002.0).max(0.0)).sum();
    println!("E[U] in 1000 draws by DP {:.4}; bound {:.4}; limit bound (a^2/2)/(b-a) = {:.4}", eu1000, 5.0 * b1000 / 1001.0, 0.08 / 0.2);
    let mut rng = 20260929u64;
    let (urns, nn) = (10000usize, 1000u64);
    let marks = [0u64, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];
    let (mut bins, mut ups, mut fin, mut gap) = (vec![0usize; 10], vec![], vec![], vec![]);
    let (mut paths, mut early): (Vec<Vec<f64>>, Option<(usize, Vec<f64>)>) = (vec![], None);
    for i in 0..urns {
        let (mut r, mut armed, mut u, mut seen, mut f40, mut m100) = (1u64, false, 0u32, vec![0.5], vec![0.5], 0.0);
        for t in 0..nn {
            if next(&mut rng) % (t + 2) < r { r += 1; } // red with chance r/(t+2)
            if armed && hi(r, t + 1) { u += 1; armed = false; } else if lo(r, t + 1) { armed = true; }
            let m = r as f64 / (t + 3) as f64;
            if marks.contains(&(t + 1)) { seen.push(m); }
            if t + 1 == 100 { m100 = m; }
            if t < 40 { f40.push(m); }
            if t == 39 && u >= 2 && early.is_none() { early = Some((i + 1, f40.clone())); }
        }
        let last = seen[seen.len() - 1];
        bins[((10.0 * last) as usize).min(9)] += 1;
        ups.push(u as f64); fin.push(last); gap.push((last - m100).powi(2));
        if i < 3 { paths.push(seen); }
    }
    println!("simulation: {} urns, {} draws each, SplitMix64 seed 20260929", urns, nn);
    for k in 0..3 { println!("urn {}, M_n at n = 0 1 2 5 10 20 50 100 200 500 1000: {}", k + 1, join(&paths[k], 2)); }
    let (ei, ef) = early.unwrap();
    println!("urn {}, first with 2 upcrossings by draw 40, M_n for n = 0..40:", ei);
    println!("{}", join(&ef, 2));
    let exact_bin: Vec<f64> = (0..10).map(|b| (1..nn + 2).filter(|&j| (((10 * j) as f64 / (nn + 2) as f64) as usize).min(9) == b).count() as f64 / (nn + 1) as f64).collect();
    let shares: Vec<f64> = bins.iter().map(|&b| b as f64 / urns as f64).collect();
    println!("share of M_1000 in tenths 0-0.1 ... 0.9-1: {}", join(&shares, 3));
    println!("  exact from the law, each tenth:           {}", join(&exact_bin, 3));
    assert!(shares.iter().zip(&exact_bin).all(|(s, e)| (s - e).abs() < 4.0 * (0.09 / urns as f64).sqrt()));
    let ((mf, sf), (mu, su), (mg, sg)) = (mse(&fin), mse(&ups), mse(&gap));
    let g_exact = 1.0 / (6.0 * 102.0) - 1.0 / (6.0 * 1002.0);
    println!("mean M_1000 {:.4} +- {:.4} (exact 0.5000)", mf, sf);
    println!("mean upcrossings of [0.4, 0.6] {:.4} +- {:.4} (exact {:.4})", mu, su, eu1000);
    println!("mean (M_1000 - M_100)^2 {:.6} +- {:.6} (exact 1/612 - 1/6012 = {:.6})", mg, sg, g_exact);
    assert!((mf - 0.5).abs() < 4.0 * sf);
    assert!((mu - eu1000).abs() < 4.0 * su);
    assert!((mg - g_exact).abs() < 4.0 * sg);
    let rms: Vec<String> = [0.0f64, 10.0, 100.0, 1000.0].iter().map(|m| format!("n={} {:.4}", m, 1.0 / (6.0 * (m + 2.0)).sqrt())).collect();
    println!("RMS movement still to come after n draws, 1/sqrt(6(n+2)): {}", rms.join(" "));
    println!("house example: a fair $1 game.  Without credit, from $10; with credit, S_n from 0");
    let mut w = vec![0f64; 1012]; w[10] = 1.0; // chance of each fortune, stopped at $0
    for t in 1..=1000i64 {
        let mut nw = vec![0f64; 1012];
        nw[0] = w[0] + 0.5 * w[1];
        nw[1] = 0.5 * w[2];
        for x in 2..1011 { nw[x] = 0.5 * (w[x - 1] + w[x + 1]); }
        w = nw;
        if t == 100 || t == 1000 {
            let mut p = vec![0.5f64.powi(t as i32)]; // road 2: reflection, P(-10 < S_t <= 10), binomial
            for j in 0..t { let last = p[p.len() - 1]; p.push(last * (t - j) as f64 / (j + 1) as f64); }
            let refl: f64 = p.iter().enumerate().filter(|(j, _)| { let s = 2 * *j as i64 - t; -10 < s && s <= 10 }).map(|(_, q)| q).sum();
            let mean: f64 = w.iter().enumerate().map(|(x, q)| x as f64 * q).sum();
            let e_abs: f64 = p.iter().enumerate().map(|(j, q)| (2 * j as i64 - t).abs() as f64 * q).sum();
            let p0: f64 = (1..=t / 2).map(|k| (2 * k - 1) as f64 / (2 * k) as f64).product();
            assert!(((1.0 - w[0]) - refl).abs() < 1e-9 && (mean - 10.0).abs() < 1e-9);
            assert!((e_abs - t as f64 * p0).abs() < 1e-9); // E|S_t| = t P(S_t = 0) for even t
            println!("n={}: still playing {:.4} (reflection {:.4}), mean fortune {:.4}; E|S_n| {:.4} (n P(S_n=0) {:.4})", t, 1.0 - w[0], refl, mean, e_abs, t as f64 * p0);
        }
    }
    let n = 10u32; // doubling: stake 1, 2, 4, ... until the first win
    let (mut e_x, mut e_abs, mut won) = (0i64, 0i64, 0i64); // sums over all 2^n equally likely coin sequences
    for mask in 0u32..(1 << n) {
        let (mut x, mut stake) = (0i64, 1i64);
        for t in 0..n { if x == 1 { break; } if mask >> t & 1 == 1 { x += stake; } else { x -= stake; stake *= 2; } } // stop once won
        e_x += x; e_abs += x.abs(); won += (x == 1) as i64;
    }
    assert!(e_x == 0); // a fair game: average 0 at round n
    assert!(e_abs * (1i64 << (n - 1)) == (1i64 << (2 * n)) - (1i64 << n)); // formula E|X| = 2 - 2^(1-n)
    assert!(won == (1i64 << n) - 1); // formula P(X = +1) = 1 - 2^(-n)
    println!("doubling, n={}: E[X] = {}, E|X| = {} = {:.6}, P(won, X = +1) = {} = {:.6}", n, e_x, fr(e_abs as u128, 1 << n), e_abs as f64 / 1024.0, fr(won as u128, 1 << n), 1.0 - 0.5f64.powi(n as i32));
}
