// Modes of convergence -- the check behind the card.  Rust std only.
// Four sequences, each number found twice: by the formula the card derives and
// by counting grid cells that every step of the functions lines up with.  A
// grid point is the midpoint t/D of a cell, t odd.  Fractions are exact pairs
// of integers.  The code checks finite stages only; limits rest on the proofs.
const L: i64 = 5040; // cells per unit on [0, 1); 1..10, 16 divide it
const D: i64 = 2 * L;

fn gcd(a: i64, b: i64) -> i64 {
    if b == 0 { a.abs() } else { gcd(b, a % b) }
}
fn q(n: i64, d: i64) -> (i64, i64) {
    let g = gcd(n, d).max(1);
    (n / g, d / g)
}
fn show(x: (i64, i64)) -> String {
    if x.1 == 1 { format!("{}", x.0) } else { format!("{}/{}", x.0, x.1) }
}
fn dec(x: (i64, i64)) -> String {
    let s = format!("{:.4}", x.0 as f64 / x.1 as f64);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}
fn le(a: (i64, i64), b: (i64, i64)) -> bool {
    a.0 * b.1 <= b.0 * a.1
}
fn top(n: i64) -> i64 {
    1 << (63 - n.leading_zeros() as i64)
}
fn tw(n: i64, t: i64) -> i64 {
    let (m, k) = (top(n), n - top(n));
    if D * k <= t * m && t * m < D * (k + 1) { 1 } else { 0 }
}
fn spike(n: i64, t: i64) -> i64 {
    if t * n < D { n } else { 0 }
}
fn ts() -> impl Iterator<Item = i64> {
    (1..D).step_by(2)
}
fn g_int(f: fn(i64, i64) -> i64, n: i64, p: u32) -> (i64, i64) {
    q(ts().map(|t| f(n, t).pow(p)).sum(), L)
}
fn g_len(f: fn(i64, i64) -> i64, n: i64) -> (i64, i64) {
    q(ts().filter(|&t| 2 * f(n, t) > 1).count() as i64, L)
}
fn join(v: &[i64]) -> String {
    v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")
}

fn main() {
    let mut markov: Vec<((i64, i64), (i64, i64))> = Vec::new();
    println!("typewriter f_n on [0, 1): n = M + k, M = 2^m, f_n = 1 on [k/M, (k+1)/M)");
    let (mut tw_formula, mut tw_grid) = (Vec::new(), Vec::new());
    for n in 1..32i64 {
        let (m, k) = (top(n), n - top(n));
        tw_formula.push(q(1, m));
        tw_grid.push(g_int(tw, n, 1));
        markov.push((g_len(tw, n), g_int(tw, n, 1)));
        let at_third = tw(n, D / 3); // the seat x = 1/3 is the grid value t = D/3
        if n <= 16 {
            println!("n={:2} m={} [{}/{}, {}/{}) integral {:.4} grid {:.4} f_n(1/3)={}", n, 63 - m.leading_zeros(), k, m, k + 1, m,
                1.0 / m as f64, { let g = g_int(tw, n, 1); g.0 as f64 / g.1 as f64 }, at_third);
        }
    }
    let once = (0..5).all(|m| ts().all(|t| ((1i64 << m)..(2i64 << m)).map(|n| tw(n, t)).sum::<i64>() == 1));
    println!("every one of {} grid points is hit exactly once in each stage m=0..4: {}", L, if once { "yes" } else { "no" });
    let hits: Vec<i64> = (1..128i64).filter(|&n| tw(n, D / 3) == 1).collect();
    let hits_formula: Vec<i64> = (0..7).map(|m| (1i64 << m) + (1i64 << m) / 3).collect();
    println!("x = 1/3 is hit at n = {} (one per stage m=0..6)", join(&hits));

    let riesz: Vec<i64> = (1..5).map(|j| (1..32).find(|&n| le(g_len(tw, n), q(1, 1 << j))).unwrap()).collect();
    println!("subsequence n_j, j=1..4, by search: {} ; by formula 2^j: {}", join(&riesz), join(&[2, 4, 8, 16]));
    let mut tails = Vec::new();
    for jj in 1..5usize {
        let u = q(ts().filter(|&t| (jj..5).any(|j| tw(riesz[j - 1], t) == 1)).count() as i64, L);
        tails.push(u);
        println!("J={}: length of union of bad sets j>=J (to j=4) {}, bound sum 2^-j = {}", jj, show(u), show(q(2, 1 << jj)));
    }

    println!("growing spike g_n = n on [0, 1/n): n, integral, length{{g_n > 1/2}}, integral g_n^2, g_n(1/10)");
    let (mut sp_formula, mut sp_grid) = (Vec::new(), Vec::new());
    for &n in [1i64, 2, 4, 8, 16].iter() {
        sp_formula.push((q(1, 1), q(1, n), q(n, 1)));
        let row = (g_int(spike, n, 1), g_len(spike, n), g_int(spike, n, 2));
        sp_grid.push(row);
        markov.push((row.1, row.0));
        println!("n={:2}: {}, {}, {}, {}", n, show(row.0), show(row.1), show(row.2), spike(n, D / 10));
    }
    let sp_all: Vec<(i64, i64)> = (1..11).chain([16]).map(|n| g_int(spike, n, 1)).collect();
    println!("spike integral, n = 1..16, by formula: 1 each; by grid, n = 1..10 and 16: {}", sp_all.iter().map(|&x| show(x)).collect::<Vec<_>>().join(" "));
    let en: Vec<(i64, i64)> = [1i64, 2, 4, 8].iter().map(|&nn| q(ts().filter(|&t| (nn..65).any(|n| 2 * spike(n, t) > 1)).count() as i64, L)).collect();
    println!("E_N = union over n >= N of {{g_n > 1/2}}, lengths N=1,2,4,8: {}", en.iter().map(|&x| show(x)).collect::<Vec<_>>().join(", "));
    let egorov: Vec<i64> = [10i64, 100].iter().map(|&d| (1..500).find(|&n| ts().filter(|&t| t * d >= D).all(|t| spike(n, t) == 0)).unwrap()).collect();
    let sup9 = ts().filter(|&t| 10 * t >= D).map(|t| spike(9, t)).max().unwrap();
    println!("Egorov: g_n = 0 on [1/10, 1) from n = {}; on [1/100, 1) from n = {}; sup of g_9 on [1/10, 1) = {}", egorov[0], egorov[1], sup9);

    let (c, w) = (8i64, 64i64); // the half-line, cut at W, C cells per unit
    let bump = |n: i64, s: i64| if 2 * c * n <= s && s < 2 * c * (n + 1) { 1i64 } else { 0 };
    let spread = |n: i64, s: i64| if s < 2 * c * n { (1i64, n) } else { (0, 1) }; // w_n at s/(2C), a fraction
    println!("sliding bump h_n = 1 on [n, n+1) and flat spread w_n = 1/n on [0, n), on [0, {}), cells of 1/{}:", w, c);
    let mut hw = Vec::new();
    for &n in [1i64, 2, 4, 8, 16, 32].iter() {
        let xs = (1..2 * c * w).step_by(2);
        let bl = q(xs.clone().filter(|&s| 2 * bump(n, s) > 1).count() as i64, c);
        let bi = q(xs.clone().map(|s| bump(n, s)).sum(), c);
        let inside = xs.clone().filter(|&s| s < 2 * c * n).count() as i64; // cells where w_n = 1/n
        let sl = q(xs.clone().filter(|&s| { let v = spread(n, s); 2 * v.0 > v.1 }).count() as i64, c);
        let si = q(inside, n * c);
        markov.push((bl, bi));
        markov.push((sl, si));
        hw.push((bl, bi, sl, si));
        println!("n={:2}: bump length{{>1/2}} {}, integral {}; spread sup {}, length{{>1/2}} {}, integral {}",
            n, show(bl), show(bi), show(q(1, n)), show(sl), show(si));
    }
    let wins: Vec<i64> = [w, 2 * w].iter().map(|&ww| (1..2 * c * ww).step_by(2).filter(|&s| (4..ww).any(|n| bump(n, s) == 1)).count() as i64 / c).collect();
    println!("bump E_4 inside [0, W): W={} gives {}, W={} gives {}; formula W - 4", w, wins[0], 2 * w, wins[1]);
    let mk = markov.iter().all(|&(a, b)| le(a, (2 * b.0, b.1)));
    let (t10, s16) = (markov[9], markov[35]);
    println!("Markov: length{{|f_n| > 1/2}} <= 2 x integral held in all {} rows: {}; typewriter n=10: {} <= {}; spike n=16: {} <= {}",
        markov.len(), if mk { "yes" } else { "no" }, show(t10.0), show(q(2 * t10.1 .0, t10.1 .1)), show(s16.0), show(q(2 * s16.1 .0, s16.1 .1)));
    let px = |a: i64, b: i64| dec(q(40 * b + 280 * a, b)); // [0, 1) drawn from x=40 to x=320
    let shade: Vec<String> = hits[..4].iter().enumerate().map(|(m, &n)| { let mm = 1i64 << m; format!("{}-{}", px(n - mm, mm), px(n - mm + 1, mm)) }).collect();
    println!("figure, 280 per metre from x=40; x=1/3 at {:.2}; rows m=0..3 at y 50, 95, 140, 185; shaded n = {}: x {}",
        (40.0 + 280.0 / 3.0), join(&hits[..4]), shade.join(", "));

    assert_eq!(tw_grid, tw_formula); // two roads to each integral
    assert!(once && hits == hits_formula); // every point hit every stage
    assert_eq!(sp_grid, sp_formula); // spike: grid against formula
    assert!(riesz == vec![2, 4, 8, 16] && tails == (1..5).map(|j| q(1, 1 << j)).collect::<Vec<_>>());
    assert!(en == vec![q(1, 1), q(1, 2), q(1, 4), q(1, 8)] && egorov == vec![10, 100] && sup9 == 9);
    assert!(wins == vec![w - 4, 2 * w - 4] && mk && sp_all.iter().all(|&x| x == (1, 1)));
    let hw_formula: Vec<_> = [1i64, 2, 4, 8, 16, 32].iter().map(|&n| ((1, 1), (1, 1), if n == 1 { (1, 1) } else { (0, 1) }, (1, 1))).collect();
    assert_eq!(hw, hw_formula); // bump, spread
}
