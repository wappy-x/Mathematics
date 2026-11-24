// Attention and transformers -- the same check as attention_and_transformers_check.py, in Rust.
// Standard library only, no crates.  Sentence "the cat sat on the mat", width d = 2.
type M = Vec<Vec<f64>>;
const WORDS: [&str; 6] = ["the", "cat", "sat", "on", "the", "mat"];

fn emb(w: &str) -> [f64; 2] {
    match w { "the" => [1.0, 0.0], "cat" => [0.0, 2.0], "sat" => [1.0, 1.0], "on" => [1.0, -1.0], _ => [0.0, 1.0] }
}
fn wq() -> M { vec![vec![1.0, 0.0], vec![0.0, 1.0]] }      // query matrix: keep x
fn wk() -> M { vec![vec![0.0, 1.0], vec![1.0, 0.0]] }      // key matrix: swap the two numbers
fn wv() -> M { vec![vec![1.0, 0.0], vec![0.0, 1.0]] }      // value matrix: keep x

fn matmul(a: &M, b: &M, count: &mut u64) -> M {            // row by column, counting every multiplication
    *count += (a.len() * b.len() * b[0].len()) as u64;
    a.iter().map(|r| (0..b[0].len()).map(|j| (0..b.len()).map(|t| r[t] * b[t][j]).sum()).collect()).collect()
}
fn transpose(a: &M) -> M { (0..a[0].len()).map(|j| a.iter().map(|r| r[j]).collect()).collect() }
fn softmax(row: &[f64]) -> Vec<f64> {                      // shift by the largest score, exponentiate, divide
    let m = row.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let e: Vec<f64> = row.iter().map(|s| (s - m).exp()).collect();
    let z: f64 = e.iter().sum();
    e.iter().map(|t| t / z).collect()
}
fn attention(x: &M, c: &mut u64) -> (M, M) {              // road 1: softmax(Q K^T / sqrt d) V
    let (q, k, v) = (matmul(x, &wq(), c), matmul(x, &wk(), c), matmul(x, &wv(), c));
    let d = q[0].len() as f64;
    let a: M = matmul(&q, &transpose(&k), c).iter()
        .map(|r| softmax(&r.iter().map(|s| s / d.sqrt()).collect::<Vec<_>>())).collect();
    let z = matmul(&a, &v, c);
    (a, z)
}
fn attention_online(x: &M, c: &mut u64) -> M {            // road 2: one pass, running max and running sum
    let (q, k, v) = (matmul(x, &wq(), c), matmul(x, &wk(), c), matmul(x, &wv(), c));
    let d = q[0].len();
    q.iter().map(|qi| {
        let (mut m, mut z, mut acc) = (-1e300_f64, 0.0_f64, vec![0.0; d]);
        for (kj, vj) in k.iter().zip(v.iter()) {
            let s: f64 = qi.iter().zip(kj).map(|(a, b)| a * b).sum::<f64>() / (d as f64).sqrt();
            let m2 = m.max(s); let cc = (m - m2).exp(); let w = (s - m2).exp();
            z = z * cc + w; for t in 0..d { acc[t] = acc[t] * cc + w * vj[t]; } m = m2;
        }
        acc.iter().map(|a| a / z).collect()
    }).collect()
}
fn embed(words: &[&str], with_pos: bool) -> M {          // the sine-and-cosine position code, width 2
    words.iter().enumerate().map(|(t, w)| {
        let e = emb(w); let (s, co) = if with_pos { ((t as f64).sin(), (t as f64).cos()) } else { (0.0, 0.0) };
        vec![e[0] + s, e[1] + co]
    }).collect()
}
fn show(label: &str, v: &[f64]) {
    let parts: Vec<String> = v.iter().map(|x| format!("{:8.4}", x)).collect();
    println!("{:<30}{}", label, parts.join(" "));
}
fn gap(p: &M, r: &M) -> f64 {
    p.iter().zip(r).flat_map(|(a, b)| a.iter().zip(b).map(|(x, y)| (x - y).abs())).fold(0.0, f64::max)
}
fn permute<T: Clone>(l: &[T], p: &[usize]) -> Vec<T> { p.iter().map(|&i| l[i].clone()).collect() }
fn perms(l: &[usize]) -> Vec<Vec<usize>> {
    if l.len() <= 1 { return vec![l.to_vec()]; }
    let mut out = vec![];
    for i in 0..l.len() {
        let mut rest = l.to_vec(); let head = rest.remove(i);
        for mut r in perms(&rest) { r.insert(0, head); out.push(r); }
    }
    out
}
fn block(n: usize, d: usize, h: usize) -> u64 {           // road 4: one transformer block, counting multiplications
    let mut c = 0u64;
    let x: M = (0..n).map(|i| (0..d).map(|j| 0.01 * (i + j) as f64).collect()).collect();
    let id: M = (0..d).map(|i| (0..d).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let (q, k, v) = (matmul(&x, &id, &mut c), matmul(&x, &id, &mut c), matmul(&x, &id, &mut c));
    let w = d / h; let mut hcat: M = vec![vec![]; n];
    for g in 0..h {                                        // each head sees its own w = d/h columns
        let cut = |m: &M| -> M { m.iter().map(|r| r[g * w..(g + 1) * w].to_vec()).collect() };
        let (qh, kh, vh) = (cut(&q), cut(&k), cut(&v));
        let a: M = matmul(&qh, &transpose(&kh), &mut c).iter()
            .map(|r| softmax(&r.iter().map(|s| s / (w as f64).sqrt()).collect::<Vec<_>>())).collect();
        for (i, r) in matmul(&a, &vh, &mut c).into_iter().enumerate() { hcat[i].extend(r); }
    }
    let y = matmul(&hcat, &id, &mut c);                    // output matrix W_O
    let f: M = matmul(&y, &vec![vec![0.1; 4 * d]; d], &mut c).iter()
        .map(|r| r.iter().map(|x| x.max(0.0)).collect()).collect();
    matmul(&f, &vec![vec![0.1; d]; 4 * d], &mut c);        // feed-forward d -> 4d -> d
    c
}
fn formula(n: u64, d: u64) -> u64 { 12 * n * d * d + 2 * n * n * d }
fn splitmix(s: &mut u64) -> f64 {                          // SplitMix64, written out
    *s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = *s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) as f64 / 18446744073709551616.0
}

fn main() {
    let mut c = 0u64;
    let x = embed(&WORDS, false);
    let (a, z) = attention(&x, &mut c);
    println!("weights: row = the word looking, columns = the six words it looks at");
    for (w, row) in WORDS.iter().zip(&a) { show(&format!("  {:<4} (row sum {:.4})", w, row.iter().sum::<f64>()), row); }
    for (w, zi) in WORDS.iter().zip(&z) { show(&format!("output {}", w), zi); }
    let s: Vec<f64> = x.iter().map(|k| 1.0 * k[1] + 1.0 * k[0]).collect();
    show("sat: dot products q.k", &s);
    show("sat: divided by sqrt 2", &s.iter().map(|t| t / 2f64.sqrt()).collect::<Vec<_>>());
    let e: Vec<f64> = s.iter().map(|t| (t / 2f64.sqrt()).exp()).collect();
    show("sat: e to each", &e); show("sat: total of e", &[e.iter().sum::<f64>()]);
    let r2 = 2f64.sqrt();
    let hand = r2.exp() / (3.0 * (1.0 / r2).exp() + 2.0 * r2.exp() + 1.0);   // closed form, sat on cat
    show("sat on cat: closed form", &[hand]);
    show("sat: weight x value, first", &(0..6).map(|j| a[2][j] * x[j][0]).collect::<Vec<_>>());
    show("sat: weight x value, second", &(0..6).map(|j| a[2][j] * x[j][1]).collect::<Vec<_>>());
    let zo = attention_online(&x, &mut c); show("road 2 online, largest gap", &[gap(&z, &zo)]);

    let swap = [0usize, 5, 2, 3, 4, 1];                    // "the mat sat on the cat"
    let (_, zs) = attention(&embed(&permute(&WORDS, &swap), false), &mut c);
    show("swapped: output at slot 2 (mat)", &zs[1]); show("swapped: output at slot 6 (cat)", &zs[5]);
    show("swapped vs reordered, gap", &[gap(&zs, &permute(&z, &swap))]);
    let (_, zp) = attention(&embed(&WORDS, true), &mut c);
    let (mut ok_plain, mut ok_pos) = (0, 0);
    for p in perms(&[0, 1, 2, 3, 4, 5]) {                  // road 3: all 720 orders
        let pw = permute(&WORDS, &p);
        if gap(&attention(&embed(&pw, false), &mut c).1, &permute(&z, &p)) < 1e-12 { ok_plain += 1; }
        if gap(&attention(&embed(&pw, true), &mut c).1, &permute(&zp, &p)) < 1e-12 { ok_pos += 1; }
    }
    println!("orders tested 720; equivariant without positions {}; with positions {}", ok_plain, ok_pos);
    show("positions: output the (slot 1)", &zp[0]); show("positions: output the (slot 5)", &zp[4]);
    let (_, zps) = attention(&embed(&permute(&WORDS, &swap), true), &mut c);
    show("positions: swap gap", &[gap(&zps, &permute(&zp, &swap))]);

    println!("house block n=6 d=2: projections {}, scores {}, mixing {}, output {}, feed-forward {}", 3 * 6 * 4, 36 * 2, 36 * 2, 6 * 4, 8 * 6 * 4);
    for (n, d, h) in [(6usize, 2usize, 1usize), (6, 2, 2), (12, 4, 2), (24, 4, 2), (48, 4, 4), (96, 8, 2)] {
        let cnt = block(n, d, h); let f = formula(n as u64, d as u64);
        println!("block n={:<3} d={} heads={}: counted {:>7}, 12nd^2 + 2n^2d = {:>7}", n, d, h, cnt, f);
        assert!(cnt == f, "counted multiplications must meet the formula");
    }
    println!("attention part overtakes the rest at n = 6d = {} for d = 768, at n = 6d = {} for d = 2", 6 * 768, 6 * 2);
    println!("block total n=1024 d=768: {:.2}e9; sqrt 512 = {:.4}", formula(1024, 768) as f64 / 1e9, 512f64.sqrt());
    for n in [512u64, 1024, 2048, 4096, 8192, 16384] {
        println!("chart, d=768 n={:<5}  attention 2n^2d {:6.2}e9  rest 12nd^2 {:6.2}e9", n,
                 (2 * n * n * 768) as f64 / 1e9, (12 * n * 768 * 768) as f64 / 1e9);
    }
    let mut seed = 2026u64;
    for d in [2usize, 64, 512] {                           // what breaks: drop the 1/sqrt d
        let mut tot = [0.0f64, 0.0];
        for _ in 0..1000 {
            let vals: Vec<f64> = (0..7 * d).map(|_| 3f64.sqrt() * (2.0 * splitmix(&mut seed) - 1.0)).collect();
            let q = &vals[..d];
            let raw: Vec<f64> = (0..6).map(|j| q.iter().zip(&vals[d * (j + 1)..d * (j + 2)]).map(|(a, b)| a * b).sum()).collect();
            let sc: Vec<f64> = raw.iter().map(|r| r / (d as f64).sqrt()).collect();
            tot[0] += softmax(&sc).iter().cloned().fold(0.0, f64::max);
            tot[1] += softmax(&raw).iter().cloned().fold(0.0, f64::max);
        }
        println!("d={:<4} average largest weight: scaled {:.4}  unscaled {:.4}", d, tot[0] / 1000.0, tot[1] / 1000.0);
        if d == 512 { assert!(tot[1] / 1000.0 > 0.95 && tot[0] / 1000.0 < 0.6, "unscaled softmax should saturate"); }
    }
    let sm = matmul(&matmul(&x, &wq(), &mut c), &transpose(&matmul(&x, &wk(), &mut c)), &mut c);
    let cols: M = (0..6).map(|j| softmax(&(0..6).map(|i| sm[i][j] / 2f64.sqrt()).collect::<Vec<_>>())).collect();
    show("wrong axis: row sums", &(0..6).map(|i| (0..6).map(|j| cols[j][i]).sum()).collect::<Vec<f64>>());
    println!("causal mask: scores kept {} of 36", (0..6).map(|i| i + 1).sum::<usize>());

    assert!(a.iter().all(|r| (r.iter().sum::<f64>() - 1.0).abs() < 1e-12), "each row of weights sums to 1");
    assert!((a[2][1] - hand).abs() < 1e-12, "sat's weight on cat meets the closed form");
    assert!(gap(&z, &zo) < 1e-12, "online road meets the matrix road");
    assert!(ok_plain == 720 && ok_pos < 720, "equivariant in every order, until positions are added");
    assert!(gap(&zs, &permute(&z, &swap)) < 1e-12 && gap(&zps, &permute(&zp, &swap)) > 0.01, "the swap test");
    println!("ALL CHECKS PASS");
}
