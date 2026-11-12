// Data structures -- the same check as the Python, in Rust.  No crates.  The same synthetic
// festival: 60,000 tickets through a hash table, 480 sets (SplitMix64, seed 2026) through a heap.
fn mix(mut z: u64) -> u64 {                    // SplitMix64's scrambler: every bit stirs every bit
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn fnv1a(code: &str) -> u64 {                  // FNV-1a 64-bit over the bytes (RFC 9923)
    let mut h: u64 = 0xCBF29CE484222325;
    for b in code.bytes() { h = (h ^ b as u64).wrapping_mul(0x100000001B3); }
    h
}
fn good_hash(code: &str) -> u64 { mix(fnv1a(code)) }   // FNV-1a, then mixed
fn byte_sum(code: &str) -> u64 { code.bytes().map(|b| b as u64).sum() }  // the bad hash
fn floor_log2(x: usize) -> usize { (usize::BITS - 1 - x.leading_zeros()) as usize }
fn out(label: &str, values: &[String]) { println!("{:<41}{}", label, values.join(" ")); }
macro_rules! s { ($($v:expr),*) => { &[$(format!("{}", $v)),*] }; }
fn code(k: usize) -> String { format!("T{:06}", k) }

// ---- road 1 for tickets: build the chains, count what a search would compare --
fn gate(n: usize, m: usize, hashf: fn(&str) -> u64) -> (f64, f64, usize) {
    let mut chains: Vec<Vec<String>> = vec![Vec::new(); m];
    for k in 1..=n { chains[(hashf(&code(k)) % m as u64) as usize].push(code(k)); }
    assert!((1..=n).all(|k| chains[(hashf(&code(k)) % m as u64) as usize].contains(&code(k))));
    let hits: usize = chains.iter().map(|c| c.len() * (c.len() + 1) / 2).sum();
    let misses: usize = (n + 1..=2 * n).map(|k| chains[(hashf(&code(k)) % m as u64) as usize].len()).sum();
    (hits as f64 / n as f64, misses as f64 / n as f64, chains.iter().map(|c| c.len()).max().unwrap())
}
// ---- search trees: plain against AVL (heights differ by at most one) ----------
struct Tree { k: Vec<usize>, l: Vec<i64>, r: Vec<i64>, h: Vec<i64>, balance: bool }
impl Tree {
    fn ht(&self, t: i64) -> i64 { if t >= 0 { self.h[t as usize] } else { -1 } }
    fn fix(&mut self, t: i64) { let u = t as usize; self.h[u] = 1 + self.ht(self.l[u]).max(self.ht(self.r[u])); }
    fn rot(&mut self, t: i64, left: bool) -> i64 {           // left: lift the right child
        let u = t as usize;
        let s = if left { self.r[u] } else { self.l[u] };
        let v = s as usize;
        if left { self.r[u] = self.l[v]; self.l[v] = t; } else { self.l[u] = self.r[v]; self.r[v] = t; }
        self.fix(t); self.fix(s); s
    }
    fn ins(&mut self, t: i64, key: usize) -> i64 {
        if t < 0 { self.k.push(key); self.l.push(-1); self.r.push(-1); self.h.push(0); return self.k.len() as i64 - 1; }
        let u = t as usize;
        if key < self.k[u] { let c = self.ins(self.l[u], key); self.l[u] = c; }
        else { let c = self.ins(self.r[u], key); self.r[u] = c; }
        self.fix(t);
        let b = self.ht(self.l[u]) - self.ht(self.r[u]);
        if self.balance && b > 1 {
            if key > self.k[self.l[u] as usize] { let c = self.rot(self.l[u], true); self.l[u] = c; }
            return self.rot(t, false);
        }
        if self.balance && b < -1 {
            if key < self.k[self.r[u] as usize] { let c = self.rot(self.r[u], false); self.r[u] = c; }
            return self.rot(t, true);
        }
        t
    }
    fn cost(&self, t: i64, d: usize) -> usize {
        if t < 0 { 0 } else { d + 1 + self.cost(self.l[t as usize], d + 1) + self.cost(self.r[t as usize], d + 1) }
    }
    fn tall(&self, t: i64) -> i64 { if t < 0 { -1 } else { 1 + self.tall(self.l[t as usize]).max(self.tall(self.r[t as usize])) } }
}
fn build(keys: &[usize], balance: bool) -> (i64, f64, bool) {
    let mut tr = Tree { k: vec![], l: vec![], r: vec![], h: vec![], balance };
    let mut root = -1;
    for &key in keys { root = tr.ins(root, key); }
    let even = (0..tr.k.len()).all(|u| (tr.tall(tr.l[u]) - tr.tall(tr.r[u])).abs() <= 1);
    (tr.h[root as usize], tr.cost(root, 0) as f64 / keys.len() as f64, even)
}

fn main() {
    let (n_t, m_b) = (60000usize, 80000usize);
    let (hit, miss, longest) = gate(n_t, m_b, good_hash);
    let (hit_f, miss_f) = (1.0 + (n_t - 1) as f64 / (2 * m_b) as f64, n_t as f64 / m_b as f64);
    let (bad_hit, bad_miss, bad_longest) = gate(n_t, m_b, byte_sum);
    let (full_hit, full_miss, _) = gate(n_t, 8000, good_hash);     // never resized: alpha 7.5
    let (mut probes, lo, mut hi) = (0, 0, n_t);                    // binary search, worst case
    while lo < hi { probes += 1; hi = (lo + hi) / 2; }
    out("gate: n, m, alpha = n/m", s!(n_t, m_b, format!("{:.2}", n_t as f64 / m_b as f64)));
    out("hash, real ticket: run, formula", s!(format!("{:.4}", hit), format!("{:.4}", hit_f)));
    out("hash, fake ticket: run, formula", s!(format!("{:.4}", miss), format!("{:.4}", miss_f)));
    out("hash, longest chain", s!(longest));
    out("FNV-1a test vectors 'a', 'foobar'", s!(format!("{:016x}", fnv1a("a")), format!("{:016x}", fnv1a("foobar"))));
    out("scan a list: real ticket avg, fake", s!(format!("{:.1}", (n_t + 1) as f64 / 2.0), n_t));
    out("binary search, worst", s!(probes));
    out("bad hash (byte sum): real, fake, longest", s!(format!("{:.1}", bad_hit), format!("{:.1}", bad_miss), bad_longest));
    out("m = 8000: real, fake, formula", s!(format!("{:.4}", full_hit), format!("{:.4}", full_miss),
        format!("{:.4}", 1.0 + (n_t - 1) as f64 / 16000.0)));

    // ---- the stage: 480 start minutes, booked in a shuffled order --------------
    let (n_s, mut state) = (480usize, 2026u64);
    let mut booked: Vec<usize> = (0..n_s).map(|k| 12 * k).collect();
    for i in (1..n_s).rev() {                                      // Fisher-Yates shuffle
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let j = (mix(state) % (i as u64 + 1)) as usize;
        booked.swap(i, j);
    }
    let (mut heap, mut cmp_up, mut cmp_down): (Vec<usize>, usize, usize) = (vec![], 0, 0);
    for &t in &booked {                                            // insert: sift up
        heap.push(t);
        let mut i = heap.len() - 1;
        while i > 0 {
            cmp_up += 1;
            let p = (i - 1) / 2;
            if heap[p] <= heap[i] { break; }
            heap.swap(p, i); i = p;
        }
    }
    let (top7, mut called): (Vec<usize>, Vec<usize>) = (heap[..7].to_vec(), vec![]);
    while !heap.is_empty() {                                       // extract-min: sift down
        called.push(heap[0]);
        let last = heap.pop().unwrap();
        if heap.is_empty() { break; }
        heap[0] = last;
        let mut i = 0;
        while 2 * i + 1 < heap.len() {
            let mut c = 2 * i + 1;
            if c + 1 < heap.len() { cmp_down += 1; if heap[c + 1] < heap[c] { c += 1; } }
            cmp_down += 1;
            if heap[i] <= heap[c] { break; }
            heap.swap(i, c); i = c;
        }
    }
    let (mut pool, mut brute, mut scan_cmp, mut sorted_moves) = (booked.clone(), vec![], 0usize, 0usize);
    for _ in 0..n_s {                                              // road 2: scan for the smallest
        let mut b = 0;
        for j in 1..pool.len() { scan_cmp += 1; if pool[j] < pool[b] { b = j; } }
        brute.push(pool.remove(b));
    }
    for (k, &t) in booked.iter().enumerate() {                     // sorted array: moves on insert
        sorted_moves += booked[..k].iter().filter(|&&x| x > t).count();
    }
    let bound_up: usize = (1..=n_s).map(floor_log2).sum();
    let bound_down: usize = 2 * (1..n_s).map(floor_log2).sum::<usize>();
    let scan_total = n_s * (n_s - 1) / 2;
    out("heap height, floor(log2 480)", s!(floor_log2(n_s)));
    out("heap inserts: comparisons, bound", s!(cmp_up, bound_up));
    out("heap extracts: comparisons, bound", s!(cmp_down, bound_down));
    out("heap, whole weekend", s!(cmp_up + cmp_down));
    out("unsorted list: comparisons, n(n-1)/2", s!(scan_cmp, scan_total));
    out("sorted array: moves, n(n-1)/4", s!(sorted_moves, n_s * (n_s - 1) / 4));
    out("first five sets called, minutes", s!(format!("{:?}", &called[..5])));
    let in_order: Vec<usize> = (0..n_s).map(|k| 12 * k).collect();
    let (plain_sorted, plain_shuf, avl_sorted) = (build(&in_order, false), build(&booked, false), build(&in_order, true));
    let avl_shuf = build(&booked, true);
    let (mut mins, mut fib): (Vec<u64>, Vec<u64>) = (vec![1, 2], vec![0, 1]);   // fewest keys at height h
    while mins.len() < 30 { let x = mins[mins.len() - 1] + mins[mins.len() - 2] + 1; mins.push(x); }
    while fib.len() < 34 { let x = fib[fib.len() - 1] + fib[fib.len() - 2]; fib.push(x); }
    let cap = |n: usize| (0..30).filter(|&h| mins[h] <= n as u64).max().unwrap();   // tallest AVL height
    let (avl_bound, avl_bound_t) = (cap(n_s), cap(n_t));
    out("plain tree, time order: height, avg", s!(plain_sorted.0, format!("{:.2}", plain_sorted.1)));
    out("plain tree, booking order: height, avg", s!(plain_shuf.0, format!("{:.2}", plain_shuf.1)));
    out("AVL tree, time order: height, avg", s!(avl_sorted.0, format!("{:.2}", avl_sorted.1)));
    out("AVL tree, booking order: height, avg", s!(avl_shuf.0, format!("{:.2}", avl_shuf.1)));
    out("fewest keys, AVL height 0..11", s!(format!("{:?}", &mins[..12])));
    out("AVL height cap, 480 and 60000 keys", s!(avl_bound, avl_bound_t));
    let fig: Vec<String> = top7.iter().enumerate().map(|(i, v)| {
        let lv = floor_log2(i + 1);
        format!("{}@{:.0},{}", v, 360.0 * (2 * (i + 1 - (1 << lv)) + 1) as f64 / (1u64 << (lv + 1)) as f64, 30 + 55 * lv)
    }).collect();
    println!("figure,{}", fig.join(";"));
    assert!((hit - hit_f).abs() < 0.015 && (miss - miss_f).abs() < 0.015);   // run meets expectation
    assert!(called == brute && called == in_order);                          // heap order = brute force
    assert!(cmp_up <= bound_up && cmp_down <= bound_down && probes == floor_log2(n_t) + 1);
    assert!(scan_cmp == scan_total && plain_sorted.0 == n_s as i64 - 1 && avl_sorted.0 <= avl_bound as i64);
    assert!((0..30).all(|h| mins[h] == fib[h + 3] - 1) && bad_hit > 100.0 * hit);
    assert!(fnv1a("a") == 0xAF63DC4C8601EC8C && fnv1a("foobar") == 0x85944171F73967E8);   // the standard's vectors
    assert!(avl_sorted.2 && avl_shuf.2 && avl_shuf.0 <= avl_bound as i64);   // every item balanced, both orders
    println!("ALL CHECKS PASS");
}
