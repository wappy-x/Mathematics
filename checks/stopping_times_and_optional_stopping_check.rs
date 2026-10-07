// Stopping times and optional stopping -- the check behind the card.  Rust std only.
// A fair game at 1 dollar a round.  The rule: quit the first time 5 dollars ahead,
// and stop at round 100 whatever happens.  Three roads to the answer: exact path
// counts carried round by round, the reflection principle, a seeded simulation.
use std::ops::{Add, Mul};

const A: i64 = 5;
const N: usize = 100;

fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

// Road 1: carry the weight of every path still playing; fortune f sits at index f + n + 1.
fn dp<T: Copy + Add<Output = T> + Mul<Output = T> + From<i32>>(
    n_max: usize, one: T, half: impl Fn(T) -> T,
) -> (Vec<T>, Vec<T>, Vec<T>, T) {
    let a = A as usize;
    let zero = T::from(0);
    let pos = |i: usize| T::from(i as i32 - n_max as i32 - 1);
    let mut w = vec![zero; n_max + a + 3];
    w[n_max + 1] = one;
    let (mut hit, mut hits, mut possum, mut alive) = (zero, vec![], vec![], vec![]);
    for n in 0..=n_max {
        if n > 0 {
            let mut nw = vec![zero; n_max + a + 3];
            for i in 1..n_max + a + 2 { nw[i] = half(w[i - 1] + w[i + 1]); }
            w = nw;
            hit = hit + w[n_max + a + 1];
            w[n_max + a + 1] = zero; // reached +A: quits, leaves the board
        }
        hits.push(hit);
        possum.push((0..w.len()).fold(zero, |acc, i| acc + pos(i) * w[i]));
        alive.push(w.iter().fold(zero, |acc, &x| acc + x));
    }
    let sq = (0..w.len()).fold(T::from((A * A) as i32) * hit, |acc, i| acc + pos(i) * pos(i) * w[i]);
    (hits, possum, alive, sq)
}

fn comb(n: i64, k: i64) -> i128 {
    let mut c: i128 = 1;
    for i in 0..k { c = c * (n - i) as i128 / (i + 1) as i128; }
    c
}

// Road 2: a path that touched +A and ends at s mirrors to one ending at 2A - s.
fn reflect(n: i64) -> (i128, i128, i128) {
    let end = |s: i64| if (n + s) % 2 == 0 && -n <= s && s <= n { comb(n, (n + s) / 2) } else { 0 };
    let hit: i128 = (A..=n).map(|s| (if s > A { 2 } else { 1 }) * end(s)).sum();
    let lose: Vec<(i128, i128)> = (-n..A).map(|s| (s as i128, end(s) - end(2 * A - s))).collect();
    (hit, lose.iter().map(|&(s, c)| s * c).sum(), lose.iter().map(|&(s, c)| s * s * c).sum())
}

fn reflect_float(n: i64) -> (f64, f64) {
    let (mut lc, mut pmf) = (0.0f64, vec![]);
    for k in 0..=n {
        pmf.push((lc - n as f64 * 2.0f64.ln()).exp());
        if k < n { lc += ((n - k) as f64).ln() - ((k + 1) as f64).ln(); }
    }
    let end = |s: i64| if (n + s) % 2 == 0 && -n <= s && s <= n { pmf[((n + s) / 2) as usize] } else { 0.0 };
    let p = (A..=n).fold(0.0, |acc, s| acc + (if s > A { 2.0 } else { 1.0 }) * end(s));
    (p, (-n..A).fold(0.0, |acc, s| acc + s as f64 * (end(s) - end(2 * A - s))))
}

fn main() {
    let t: i128 = 1 << N;
    let tf = t as f64;
    let (hits, possum, alive, sq) = dp(N, t, |x: i128| x / 2);
    let (h2, lsum2, lsq2) = reflect(N as i64);
    let a = A as i128;
    assert_eq!(hits[N], h2); // road 1 = road 2, exact integers
    assert!((0..=N).all(|n| a * hits[n] + possum[n] == 0)); // E[S at min(n, tau)] = 0 at every n
    assert_eq!(a * h2 + lsum2, 0); // E[S_tau] = 0 by the mirror count
    assert_eq!(alive[..N].iter().sum::<i128>(), a * a * h2 + lsq2); // E[tau] = E[S_tau^2]
    assert_eq!(sq, a * a * h2 + lsq2); // road 1 = road 2 for E[S_tau^2]
    let p = hits[N] as f64 / tf;
    let row = |v: Vec<String>| v.join(" ");
    println!("rule: quit at +{} dollars, deadline {} rounds, 1 dollar a round", A, N);
    println!("P(quit {} up)  exact path counts   {:.6}", A, p);
    println!("P(quit {} up)  reflection          {:.6}", A, h2 as f64 / tf);
    println!("E[S_tau]  exact path counts       {:.6}", (a * hits[N] + possum[N]) as f64 / tf);
    println!("E[S_tau]  reflection              {:.6}", (a * h2 + lsum2) as f64 / tf);
    println!("E[S_min(n,tau)] = 0 at rounds 0..{}: {} of {}", N, (0..=N).filter(|&n| a * hits[n] + possum[n] == 0).count(), N + 1);
    println!("P(still playing at round {})     {:.6}", N, alive[N] as f64 / tf);
    println!("losers' mean at round {}          {:.6}", N, possum[N] as f64 / alive[N] as f64);
    println!("E[tau] rounds, from survival       {:.6}", alive[..N].iter().sum::<i128>() as f64 / tf);
    println!("E[S_tau^2], from final fortunes    {:.6}", sq as f64 / tf);
    let grid: Vec<usize> = (0..=N).step_by(10).collect();
    println!("chart, round       {}", row(grid.iter().map(|n| format!("{:6}", n)).collect()));
    println!("chart, quitters    {}", row(grid.iter().map(|&n| format!("{:6.2}", (a * hits[n]) as f64 / tf)).collect()));
    println!("chart, players     {}", row(grid.iter().map(|&n| format!("{:6.2}", possum[n] as f64 / tf)).collect()));

    // Road 3: simulation.  Player j draws 128 bits; bit n-1 is round n (1 = win a dollar).
    let (pl, seed) = (100000usize, 20260929u64);
    let mut s = seed;
    let (mut g, mut g2, mut nh, mut pk, mut pk2) = (0i64, 0i64, 0i64, 0i64, 0i64);
    let mut fig: Option<(usize, usize, Vec<i64>, Vec<i64>)> = None;
    for j in 0..pl {
        let b1 = splitmix(&mut s) as u128;
        let b2 = splitmix(&mut s) as u128;
        let bits = b1 | (b2 << 64);
        let (mut x, mut y, mut tau, mut lead) = (0i64, 0i64, N, N as i64);
        let (mut path, mut free) = (vec![0i64], vec![0i64]);
        for n in 1..=N {
            let up = (bits >> (n - 1)) & 1 == 1;
            if !up && lead == N as i64 { lead = n as i64 - 1; } // peek rule: stop before the first loss
            y += if up { 1 } else { -1 };
            if tau == N && x != A { x = y; }
            if x == A && tau == N { tau = n; }
            path.push(x);
            free.push(y);
        }
        g += x; g2 += x * x; nh += (x == A) as i64; pk += lead; pk2 += lead * lead;
        if fig.is_none() && (20..=40).contains(&tau) { fig = Some((j, tau, path[..51].to_vec(), free[..51].to_vec())); }
    }
    let pf64 = pl as f64;
    let (m, ph, mp) = (g as f64 / pf64, nh as f64 / pf64, pk as f64 / pf64);
    let se = ((g2 as f64 / pf64 - m * m) / pf64).sqrt();
    let seh = (ph * (1.0 - ph) / pf64).sqrt();
    let sep = ((pk2 as f64 / pf64 - mp * mp) / pf64).sqrt();
    assert!(m.abs() < 4.0 * se);
    assert!((ph - p).abs() < 4.0 * seh);
    println!("simulation, {} players, seed {}", pl, seed);
    println!("P(quit {} up)  simulated           {:.6}  se {:.6}", A, ph, seh);
    println!("E[S_tau]  simulated               {:.6}  se {:.6}", m, se);

    println!("no deadline: N, P(quit {} up by N), losers' mean, theorem's -{}p/(1-p)", A, A);
    let af = A as f64;
    for mm in [100i64, 1000, 10000, 100000] {
        let (pf, lf) = reflect_float(mm);
        assert!((lf / (1.0 - pf) + af * pf / (1.0 - pf)).abs() < 1e-9 * (1.0 + af * pf / (1.0 - pf)));
        println!("  {:6}  {:.6}  {:11.4}  {:11.4}", mm, pf, lf / (1.0 - pf), -af * pf / (1.0 - pf));
    }
    let (hf, pf_, alf, _) = dp(1000, 1.0f64, |x: f64| 0.5 * x);
    assert!((hf[1000] - reflect_float(1000).0).abs() < 1e-12);
    println!("  1000 by path weights: P(quit {} up) {:.6}, losers' mean {:.4}", A, hf[1000], pf_[1000] / alf[1000]);

    let exact_peek = 1.0 - 2.0f64.powi(-(N as i32));
    assert!((mp - exact_peek).abs() < 4.0 * sep);
    println!("peek rule (quit before the first loss): simulated {:.6} se {:.6}, exact {:.6}", mp, sep, exact_peek);
    let k = 10u32; // doubling, stakes 1, 2, 4, ... for at most k rounds
    let (mut tot, mut ruin) = (0i64, 0i64);
    for mask in 0..(1u32 << k) {
        let (mut gain, mut stake) = (0i64, 1i64);
        for n in 0..k {
            if (mask >> n) & 1 == 1 { gain += stake; break; }
            gain -= stake;
            stake *= 2;
        }
        tot += gain;
        ruin += (gain < 0) as i64;
    }
    assert_eq!(tot, 0); // capped doubling: mean gain 0
    assert_eq!(ruin, 1);
    let k2 = (1i64 << k) as f64;
    println!("doubling, {} rounds: P(win 1) {:.6}, P(lose {}) {:.6} (1 in {}), mean {:.6}", k, 1.0 - ruin as f64 / k2, (1i64 << k) - 1, ruin as f64 / k2, 1i64 << k, tot as f64 / k2);
    let (fj, ft, fpath, ffree) = fig.unwrap();
    println!("figure, player {} quits at round {}", fj, ft);
    println!("figure, fortune  {}", row(ffree.iter().map(|v| v.to_string()).collect()));
    println!("figure, stopped  {}", row(fpath.iter().map(|v| v.to_string()).collect()));
}
