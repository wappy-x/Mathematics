// Sums, products, sups and limits of measurable functions -- the same check as the
// Python, in Rust, std only.  Three roads.  (1) A four-point space: every function
// with values 0, 1, 2 is tested for measurability two ways, then every sum, product,
// max and min.  (2) A toy river gauge on [0, 1): the card's events measured by exact
// fractions, reduced by hand, and by counting a grid of 60000 years hour by hour.
// (3) The rationals: Riemann's upper sums on a pointwise limit that never settle.

type F4 = [i32; 4];
const F1: [u8; 4] = [0b0000, 0b0011, 0b1100, 0b1111];   // unions of blocks {0,1} {2,3}
const F2: [u8; 4] = [0b0000, 0b0101, 0b1010, 0b1111];   // unions of blocks {0,2} {1,3}

fn mask<P: Fn(i32) -> bool>(h: &F4, p: P) -> u8 {
    (0..4).filter(|&w| p(h[w])).map(|w| 1u8 << w).sum()
}
fn measurable(h: &F4, f: &[u8; 4]) -> bool {            // threshold test: {h > c} allowed, every cut c
    let lo = *h.iter().min().unwrap() - 1;
    h.iter().copied().chain(std::iter::once(lo)).all(|c| f.contains(&mask(h, |x| x > c)))
}
fn block_constant(h: &F4) -> bool { h[0] == h[1] && h[2] == h[3] }   // second road
fn show(h: &F4) -> String { format!("({}, {}, {}, {})", h[0], h[1], h[2], h[3]) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn level(w: f64, n: i32) -> f64 {                       // metres at hour n, w = the year's wetness
    let s = (w - 0.75).max(0.0);                        // the sluice swing, wettest years only
    2.0 + 2.0 * w * (1.0 - 0.5f64.powi(n)) + if n % 2 == 0 { s } else { -s }
}
fn exact_flood(big_n: i32) -> (i128, i128) {            // length of {max of hours 1..N > 4}, reduced
    let n = big_n - big_n % 2;                          // only even hours can pass 4 m
    let p = 1i128 << (n - 1).max(0);
    let (num, den) = (p - 4, 4 * (3 * p - 1));          // 1 - (11/4) / (3 - 2^(1-n)), by hand
    if num <= 0 || n == 0 { return (0, 1) }
    let g = gcd(num, den);
    (num / g, den / g)
}
fn frac(r: (i128, i128)) -> String { if r.1 == 1 { format!("{}", r.0) } else { format!("{}/{}", r.0, r.1) } }

fn upper(points: &[(i128, i128)], n: i128) -> i128 {   // pieces [i/N, (i+1)/N] holding a point
    let mut hit = vec![false; n as usize];
    for &(p, q) in points {
        let (i, r) = (p * n / q, p * n % q);
        for j in [i, if r == 0 { i - 1 } else { i }] { if j >= 0 && j < n { hit[j as usize] = true } }
    }
    hit.iter().filter(|&&b| b).count() as i128
}
fn upper2(points: &[(i128, i128)], n: i128) -> i128 {  // second road: test each closed piece directly
    (0..n).filter(|&j| points.iter().any(|&(p, q)| j * q <= p * n && p * n <= (j + 1) * q)).count() as i128
}

fn main() {
    // ---- road 1 ----
    let funcs: Vec<F4> = (0..81).map(|k| [k / 27, k / 9 % 3, k / 3 % 3, k % 3]).collect();
    let good: Vec<F4> = funcs.iter().filter(|h| measurable(h, &F1)).copied().collect();
    let good2: Vec<F4> = funcs.iter().filter(|h| measurable(h, &F2)).copied().collect();
    let agree = funcs.iter().all(|h| measurable(h, &F1) == block_constant(h));
    let names = ["sum", "product", "max", "min"];
    let op = |k: usize, x: i32, y: i32| match k { 0 => x + y, 1 => x * y, 2 => x.max(y), _ => x.min(y) };
    let comb = |k: usize, a: &F4, b: &F4| -> F4 { [0, 1, 2, 3].map(|w| op(k, a[w], b[w])) };
    let closed: Vec<bool> = (0..4).map(|k| good.iter().all(|a| good.iter().all(|b| measurable(&comb(k, a, b), &F1)))).collect();
    let (u, v): (F4, F4) = ([0, 0, 1, 1], [2, 2, 1, 1]);
    let at = |n: i32| -> F4 { [0, 1, 2, 3].map(|w| v[w] + (-1i32).pow(n as u32) * u[w]) };
    let lim_set: Vec<usize> = (0..4).filter(|&w| at(10)[w] == at(11)[w]).collect();
    let lim_mask: u8 = lim_set.iter().map(|&w| 1u8 << w).sum();
    let (f, g): (F4, F4) = ([1, 1, 0, 0], [1, 0, 1, 0]);
    let s = comb(0, &f, &g);
    let neither = good.iter().flat_map(|a| good2.iter().map(move |b| (a, b)))
        .filter(|(a, b)| { let t = comb(0, a, b); !measurable(&t, &F1) && !measurable(&t, &F2) }).count();
    println!("four points, blocks {{0,1}} {{2,3}}: {} functions, {} measurable", funcs.len(), good.len());
    println!("threshold test and block test agree on all {}: {}", funcs.len(), yn(agree));
    for k in 0..4 {
        println!("{:8} of all {} measurable pairs is measurable: {}", names[k], good.len() * good.len(), yn(closed[k]));
    }
    println!("f_n = v + (-1)^n u: limit exists on {:?}, an allowed event: {}", lim_set, yn(F1.contains(&lim_mask)));
    println!("mixing: f = {} fits blocks {{0,1}} {{2,3}}, g = {} fits {{0,2}} {{1,3}}, f + g = {}", show(&f), show(&g), show(&s));
    println!("  f + g measurable for the first: {}, for the second: {}", yn(measurable(&s, &F1)), yn(measurable(&s, &F2)));
    println!("  pairs (one of each kind) whose sum fits neither: {} of {}", neither, good.len() * good2.len());

    // ---- road 2 ----
    let (m, h) = (60000usize, 41i32);
    let ds = [1i64, 10, 100, 1000];
    let (mut first_hour, mut n_lim, mut n_sum, mut cover) = (vec![0i32; m], 0usize, 0usize, [0usize; 4]);
    for i in 0..m {
        let w = (i as f64 + 0.5) / m as f64;
        let lv: Vec<f64> = (1..=h).map(|n| level(w, n)).collect();
        first_hour[i] = (1..h).find(|&n| lv[(n - 1) as usize] > 4.0).unwrap_or(0);
        if (lv[(h - 1) as usize] - lv[(h - 2) as usize]).abs() < 1e-9 { n_lim += 1 }
        if lv[1] + lv[2] < 6.0 { n_sum += 1 }
        for (j, &d) in ds.iter().enumerate() {
            let k = (lv[1] * d as f64) as i64 + 1;
            if (k as f64) / (d as f64) < 6.0 - lv[2] { cover[j] += 1 }
        }
    }
    let row = |label: String, vals: Vec<f64>| println!("{}{}", label, vals.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "));
    println!("\nhour          {}", (1..=12).map(|n| format!("{:5}", n)).collect::<Vec<_>>().join(" "));
    for w in [0.45, 0.95] { row(format!("level, w={:.2} ", w), (1..=12).map(|n| level(w, n)).collect()) }
    row("running max   ".to_string(), (1..=12).map(|n| (1..=n).map(|k| level(0.95, k)).fold(f64::MIN, f64::max)).collect());
    println!("\nlength of {{highest of hours 1..N above 4 m}}: exact fraction, then the grid");
    let mut grid_flood = vec![];
    for big_n in [2, 4, 6, 8, 12, 20] {
        let gf = first_hour.iter().filter(|&&x| x > 0 && x <= big_n).count() as f64 / m as f64;
        let e = exact_flood(big_n);
        println!("  N = {:2}   {:>16} = {:.6}   grid {:.6}   band w > {}", big_n, frac(e), e.0 as f64 / e.1 as f64, gf, frac((e.1 - e.0, e.1)));
        grid_flood.push((e, gf));
    }
    println!("  ever above 4 m, the union: 1 - 11/12 = {:.6}", 1.0 / 12.0);
    println!("  w = 11/12: 4 minus hour 10 = {:.8}, 4 minus hour 20 = {:.8}; sup 4, never reached",
             4.0 - level(11.0 / 12.0, 10), 4.0 - level(11.0 / 12.0, 20));
    let grid_lim = n_lim as f64 / m as f64;
    println!("length of the limit set: exact 3/4 = 0.750000, grid {:.6}", grid_lim);
    println!("long-run level where it exists, w = 0.45: {:.2} m; w = 0.95 swings between {:.2} and {:.2} m",
             2.0 + 2.0 * 0.45, 2.0 + 2.0 * 0.95 - 0.2, 2.0 + 2.0 * 0.95 + 0.2);
    let grid_sum = n_sum as f64 / m as f64;
    println!("{{hour 2 + hour 3 < 6 m}}: exact 8/13 = {:.6}, grid {:.6}", 8.0 / 13.0, grid_sum);
    for (j, &d) in ds.iter().enumerate() { println!("  covered by the union over k/{:<4} {:.6}", d, cover[j] as f64 / m as f64) }
    let mut whole = (0i128, 1i128);                     // w < 0.75: f2 = 2 + 1.5w, f3 = 2 + 1.75w
    for q in 2..5i128 {
        let (a, b) = ((2 * (q - 2), 3i128), (4 * (4 - q), 7i128));
        let lo = if a.0 * b.1 < b.0 * a.1 { a } else { b };
        if lo.0 * whole.1 > whole.0 * lo.1 { whole = lo }
    }
    let gw = gcd(whole.0, whole.1);
    let whole = (whole.0 / gw, whole.1 / gw);
    println!("  the k/1 union exactly: wetness below {} = {:.6}", frac(whole), whole.0 as f64 / whole.1 as f64);
    let xs: Vec<String> = std::iter::once(0.75).chain([4, 6, 8].map(|n| { let e = exact_flood(n); 1.0 - e.0 as f64 / e.1 as f64 }))
        .chain(std::iter::once(11.0 / 12.0)).map(|t| format!("{:.1}", 30.0 + 300.0 * t)).collect();
    println!("figure, x of w = 0.75, N = 4, 6, 8 and 11/12: {}", xs.join(", "));

    // ---- road 3 ----
    let rats: Vec<(i128, i128)> = (1..=100i128).flat_map(|q| (0..=q).filter(move |&p| gcd(p, q) == 1).map(move |p| (p, q))).collect();
    let first10 = &rats[..10];
    println!("\nfirst 10 rationals: {}", first10.iter().map(|&r| frac(r)).collect::<Vec<_>>().join(", "));
    let ups: Vec<(i128, i128)> = [10i128, 100, 1000].iter().map(|&n| (n, upper(first10, n))).collect();
    for &(n, c) in &ups { println!("upper sum of the 10-point indicator, {:4} pieces: {:.4}; lower 0", n, c as f64 / n as f64) }
    let all_up = upper(&rats, 100);
    println!("upper sum of the indicator of all rationals, 100 pieces: {:.4}; lower 0", all_up as f64 / 100.0);

    assert!(agree && good.len() == 3 * 3);              // two tests agree; 3 values on each of 2 blocks
    assert!(closed.iter().all(|&c| c) && F1.contains(&lim_mask));
    assert!(!measurable(&s, &F1) && !measurable(&s, &F2) && neither > 0);
    for &(e, gf) in &grid_flood { assert!((gf - e.0 as f64 / e.1 as f64).abs() < 2.0 / m as f64) }
    assert!((grid_lim - 0.75).abs() < 2.0 / m as f64 && (grid_sum - 8.0 / 13.0).abs() < 2.0 / m as f64);
    assert!(cover.windows(2).all(|p| p[0] < p[1]) && cover[3] <= n_sum && grid_sum - cover[3] as f64 / (m as f64) < 0.01);
    assert!((cover[0] as f64 / m as f64 - whole.0 as f64 / whole.1 as f64).abs() < 2.0 / m as f64); // whole-number q: grid against the exact union
    assert!(ups.iter().all(|&(n, c)| c <= 20 && c == upper2(first10, n)));
    assert!(all_up == 100 && upper2(&rats, 100) == 100);
    println!("ALL CHECKS PASS");
}
