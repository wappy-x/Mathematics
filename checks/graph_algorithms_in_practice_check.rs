// Graph algorithms as code -- the check behind the card.  std only: no BinaryHeap, no sort.
// A synthetic city: 1,200 bike-share stations on a 40 x 30 grid, a street per neighbouring pair; SplitMix64
// (seed 2026) gives each street 60-120 s of riding, 100-600 bikes an hour of room, a 40% chance of one-way.
const BIG: u64 = 1_000_000_000;
type Adj = Vec<Vec<(usize, u64)>>;
type Heap = Vec<(u64, usize)>;
struct St { u: usize, v: usize, w: u64, c: u64, one: bool } // street: ends, seconds, bikes an hour, one-way?
fn city(wd: usize, ht: usize) -> (Vec<St>, Adj) {
    let mut s: u64 = 2026;
    let mut r = || { s = s.wrapping_add(0x9E3779B97F4A7C15); let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) };
    let (mut st, mut adj) = (Vec::new(), vec![Vec::new(); wd * ht]);
    for i in 0..wd * ht { for (j, ok) in [(i + 1, i % wd + 1 < wd), (i + wd, i / wd + 1 < ht)] {
        if ok { let (w, c, o) = (60 + r() % 61, 100 * (1 + r() % 6), r() % 100 < 40); st.push(St { u: i, v: j, w, c, one: o }); }
    } }
    for e in &st { adj[e.u].push((e.v, e.w)); adj[e.v].push((e.u, e.w)); }
    (st, adj)
}
fn push(h: &mut Heap, x: (u64, usize), c: &mut u64) {     // binary heap in a Vec: slot i's parent is (i-1)/2
    h.push(x); let mut i = h.len() - 1;
    while i > 0 && h[(i - 1) / 2] > h[i] { h.swap(i, (i - 1) / 2); i = (i - 1) / 2; *c += 1; }
}
fn pop(h: &mut Heap, c: &mut u64) -> (u64, usize) {      // take the root, sift the last entry down
    let top = h.swap_remove(0); let mut i = 0;
    loop {
        let mut m = i; for k in [2 * i + 1, 2 * i + 2] { if k < h.len() && h[k] < h[m] { m = k; } }
        if m == i { return top; }
        h.swap(i, m); i = m; *c += 1;
    }
}
fn bfs(adj: &Adj, s: usize) -> (Vec<i64>, Vec<usize>, u64) { // the queue is a Vec read from the front
    let (mut d, mut back, mut q, mut looks) = (vec![-1i64; adj.len()], vec![0; adj.len()], vec![s], 0);
    d[s] = 0; let mut k = 0;
    while k < q.len() { let u = q[k]; k += 1;
        for &(v, _) in &adj[u] { looks += 1; if d[v] < 0 { d[v] = d[u] + 1; back[v] = u; q.push(v); } }
    }
    (d, back, looks)
}
fn astar(adj: &Adj, s: usize, t: usize, h: &dyn Fn(usize) -> u64) -> (Vec<u64>, u64, u64, u64) {
    let (mut d, mut done, mut hp, mut c, mut n) = (vec![BIG; adj.len()], vec![false; adj.len()], Vec::new(), 0, (1, 0));
    d[s] = 0; push(&mut hp, (h(s), s), &mut c);           // h = 0 everywhere is Dijkstra with a heap
    while !hp.is_empty() {
        let (_, u) = pop(&mut hp, &mut c); if done[u] { continue; } // stale entry: u was pushed again, cheaper
        done[u] = true; n.1 += 1;
        if u == t { break; }
        for &(v, w) in &adj[u] { if d[u] + w < d[v] { d[v] = d[u] + w; push(&mut hp, (d[v] + h(v), v), &mut c); n.0 += 1; } }
    }
    (d, n.1, n.0, c)                                      // seconds, settled, pushes, heap swaps
}
fn bellman(adj: &Adj, s: usize) -> Vec<u64> {             // second road: relax every street, V - 1 rounds
    let mut d = vec![BIG; adj.len()]; d[s] = 0;
    for _ in 1..adj.len() { for u in 0..adj.len() { for &(v, w) in &adj[u] { d[v] = d[v].min(d[u] + w); } } }
    d
}
fn find(par: &mut Vec<usize>, x0: usize, smart: bool, steps: &mut (u64, u64)) -> usize { // total parent steps, longest lookup
    let (mut r, mut x, mut k) = (x0, x0, 0);
    while par[r] != r { r = par[r]; steps.0 += 1; k += 1; steps.1 = steps.1.max(k); }
    while smart && par[x] != r { let nx = par[x]; par[x] = r; x = nx; } // path compression: point straight at the root
    r
}
fn kruskal(nv: usize, st: &[St], smart: bool) -> (u64, u64, u64, u64, u64, bool) { // heap-sort the streets; union-find the pieces
    let (mut par, mut rank, mut steps, mut hp, mut c, mut total): (Vec<usize>, Vec<u64>, (u64, u64), Heap, u64, u64) =
        ((0..nv).collect(), vec![0; nv], (0, 0), Vec::new(), 0, 0);
    for (i, e) in st.iter().enumerate() { push(&mut hp, (e.w, i), &mut c); }
    while !hp.is_empty() {
        let (w, i) = pop(&mut hp, &mut c);
        let (mut a, mut b) = (find(&mut par, st[i].u, smart, &mut steps), find(&mut par, st[i].v, smart, &mut steps));
        if a == b { continue; }                           // same piece already: this street closes a loop
        if smart && rank[a] < rank[b] { std::mem::swap(&mut a, &mut b); } // union by rank: short tree under tall
        par[b] = a; total += w; if smart && rank[a] == rank[b] { rank[a] += 1; }
    }
    let (n, top) = (steps, *rank.iter().max().unwrap());
    (total, n.0, c, n.1, top, (0..nv).all(|v| find(&mut par, v, smart, &mut steps) == par[v])) // last: compression flattens
}
fn prim(adj: &Adj) -> u64 {                               // second road: grow one piece, no heap, no sort
    let n = adj.len(); let (mut best, mut inn, mut total) = (vec![BIG; n], vec![false; n], 0); best[0] = 0;
    for _ in 0..n {
        let u = (0..n).filter(|&v| !inn[v]).min_by_key(|&v| (best[v], v)).unwrap(); inn[u] = true; total += best[u];
        for &(v, w) in &adj[u] { if !inn[v] && w < best[v] { best[v] = w; } }
    }
    total
}
struct Tj { num: Vec<i64>, low: Vec<i64>, on: Vec<bool>, stack: Vec<usize>, comps: Vec<Vec<usize>>, cnt: i64 }
fn dfs_t(g: &mut Tj, out: &Adj, v: usize) {               // one depth-first pass with low-link numbers
    g.num[v] = g.cnt; g.low[v] = g.cnt; g.cnt += 1; g.stack.push(v); g.on[v] = true;
    for &(u, _) in &out[v] {
        if g.num[u] < 0 { dfs_t(g, out, u); g.low[v] = g.low[v].min(g.low[u]); }
        else if g.on[u] { g.low[v] = g.low[v].min(g.num[u]); }
    }
    if g.low[v] == g.num[v] {                             // v was reached first in its piece: pop the piece
        let mut comp = Vec::new(); loop { let u = g.stack.pop().unwrap(); g.on[u] = false; comp.push(u); if u == v { break; } }
        g.comps.push(comp);
    }
}
fn tarjan(out: &Adj) -> Vec<Vec<usize>> {
    let n = out.len(); let mut g = Tj { num: vec![-1; n], low: vec![0; n], on: vec![false; n], stack: vec![], comps: vec![], cnt: 0 };
    for v in 0..n { if g.num[v] < 0 { dfs_t(&mut g, out, v); } }
    g.comps
}
struct Fl { to: Vec<usize>, cap: Vec<u64>, g: Vec<Vec<usize>>, lev: Vec<i64>, it: Vec<usize>, t: usize, undo: u64 }
fn dfs_f(f: &mut Fl, u: usize, lim: u64) -> u64 {         // walk only level k -> k+1; it[u] skips dead arcs
    if u == f.t { return lim; }
    while f.it[u] < f.g[u].len() {
        let a = f.g[u][f.it[u]];
        if f.cap[a] > 0 && f.lev[f.to[a]] == f.lev[u] + 1 {
            let got = dfs_f(f, f.to[a], lim.min(f.cap[a]));
            if got > 0 { f.cap[a] -= got; f.cap[a ^ 1] += got * f.undo; return got; }
        }
        f.it[u] += 1;
    }
    0
}
fn dinic(n: usize, arcs: &[(usize, usize, u64)], s: usize, t: usize, undo: u64, one_path: bool) -> (u64, u64, Vec<bool>) {
    let mut f = Fl { to: vec![], cap: vec![], g: vec![vec![]; n], lev: vec![], it: vec![], t, undo };
    for &(u, v, c) in arcs { f.g[u].push(f.to.len()); f.g[v].push(f.to.len() + 1); f.to.extend([v, u]); f.cap.extend([c, c]); }
    let (mut total, mut phases) = (0, 0);
    loop {                                                // level graph, then a blocking flow, then again
        f.lev = vec![-1; n]; f.lev[s] = 0; let (mut q, mut k) = (vec![s], 0);
        while k < q.len() {
            let u = q[k]; k += 1;
            for i in 0..f.g[u].len() { let a = f.g[u][i]; if f.cap[a] > 0 && f.lev[f.to[a]] < 0 { f.lev[f.to[a]] = f.lev[u] + 1; q.push(f.to[a]); } }
        }
        if f.lev[t] < 0 { return (total, phases, f.lev.iter().map(|&x| x >= 0).collect()); }
        phases += 1; f.it = vec![0; n];
        loop { let got = dfs_f(&mut f, s, BIG); if got == 0 { break; } total += got; if one_path { break; } } // Edmonds-Karp: one path a round
    }
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    let (wd, ht) = (40usize, 30usize); let nv = wd * ht; let (st, adj) = city(wd, ht); let ne = st.len(); let (s, t) = (20 * wd + 8, 10 * wd + 26);
    let blocks = |a: usize, b: usize| (a % wd).abs_diff(b % wd) as u64 + (a / wd).abs_diff(b / wd) as u64;
    println!("city,{} stations,{} streets,{} one-way,trip ({},{}) to ({},{}),{} blocks", nv, ne, st.iter().filter(|e| e.one).count(), s % wd, s / wd, t % wd, t / wd, blocks(s, t));
    let (d0, _, looks) = bfs(&adj, 0); let (db, back, _) = bfs(&adj, s); let (mut x, mut sec) = (t, 0);
    while x != s { sec += adj[back[x]].iter().filter(|p| p.0 == x).map(|p| p.1).min().unwrap(); x = back[x]; }
    let bfs_ok = (0..nv).all(|v| d0[v] as u64 == blocks(0, v));
    println!("bfs,arc looks {} = 2 x {},pops {},V + 2E {},fewest streets equals blocks for all {},{}", looks, ne, nv, nv + 2 * ne, nv, tf(bfs_ok));
    let (dk, sk, pk, ck) = astar(&adj, s, t, &|_| 0); let (dall, _, pall, call) = astar(&adj, s, usize::MAX, &|_| 0); let bf = bellman(&adj, s);
    let (da, sa, pa, ca) = astar(&adj, s, t, &|v| 60 * blocks(v, t)); let (dx, sx, _, _) = astar(&adj, s, t, &|v| 180 * blocks(v, t));
    println!("dijkstra,trip {} s = {:.1} min,settled {},pushes {},swaps {}", dk[t], dk[t] as f64 / 60.0, sk, pk, ck);
    println!("dijkstra all {},pushes {},swaps {},equals bellman-ford on all {},{}", nv, pall, call, nv, tf(dall == bf));
    println!("astar h = 60 x blocks,trip {} s,settled {},pushes {},swaps {},settles {:.1} times fewer", da[t], sa, pa, ca, sk as f64 / sa as f64);
    println!("mistake,fewest streets,{} streets,{} s = {:.1} min", db[t], sec, sec as f64 / 60.0);
    println!("mistake,astar h = 180 x blocks,trip {} s = {:.1} min,settled {}", dx[t], dx[t] as f64 / 60.0, sx);
    let (k1, f1, c1, deep, top, flat) = kruskal(nv, &st, true); let (k0, f0, ..) = kruskal(nv, &st, false); let pr = prim(&adj);
    println!("kruskal,{} streets,{} riding s = {:.1} km at 5 m/s,heap swaps {},find steps {},longest find {},top rank {},prim {}", nv - 1, k1, k1 as f64 * 5.0 / 1000.0, c1, f1, deep, top, pr);
    println!("mistake,union-find plain links,{} riding s,find steps {},{:.1} times more", k0, f0, f0 as f64 / f1 as f64);
    let (mut out, mut inn): (Adj, Adj) = (vec![vec![]; nv], vec![vec![]; nv]);
    for e in &st { out[e.u].push((e.v, 0)); inn[e.v].push((e.u, 0)); if !e.one { out[e.v].push((e.u, 0)); inn[e.u].push((e.v, 0)); } }
    let comps = tarjan(&out); let big = comps.iter().map(|c| c.len()).max().unwrap(); let mut lab = vec![usize::MAX; nv];
    for v in 0..nv { if lab[v] == usize::MAX {               // second road: reached forwards and backwards
        let (fw, bw) = (bfs(&out, v).0, bfs(&inn, v).0); for u in 0..nv { if fw[u] >= 0 && bw[u] >= 0 { lab[u] = v; } }
    } }
    let mut lab2 = vec![0; nv]; for c in &comps { let m = *c.iter().min().unwrap(); for &u in c { lab2[u] = m; } }
    let outside: Vec<usize> = comps.iter().map(|c| c.len()).filter(|&l| l < big).collect();
    println!("tarjan,arcs {},pieces {},largest {},sizes outside it {:?}", out.iter().map(|a| a.len()).sum::<usize>(), comps.len(), big, outside);
    let mut arcs: Vec<(usize, usize, u64)> = st.iter().map(|e| (e.u, e.v, e.c)).collect();
    for y in 0..ht { arcs.push((nv, y * wd, BIG)); arcs.push((y * wd + wd - 1, nv + 1, BIG)); } // west in, east out
    let (ff, ph, side) = dinic(nv + 2, &arcs, nv, nv + 1, 1, false); let (fek, aug, _) = dinic(nv + 2, &arcs, nv, nv + 1, 1, true);
    let (fno, _, _) = dinic(nv + 2, &arcs, nv, nv + 1, 0, false); let cut: u64 = arcs.iter().filter(|a| side[a.0] != side[a.1]).map(|a| a.2).sum();
    println!("dinic,west edge to east edge {} bikes/h,phases {},edmonds-karp {} in {} paths,cut {}\nmistake,no undo,{} bikes/h", ff, ph, fek, aug, cut, fno);
    for (w2, h2) in [(20usize, 15usize), (40, 30), (80, 60)] {
        let (st2, adj2) = city(w2, h2); let (v2, e2) = (w2 * h2, st2.len()); let (_, _, lk) = bfs(&adj2, 0); let (_, _, p2, c2) = astar(&adj2, 0, usize::MAX, &|_| 0);
        println!("growth,V {},E {},bfs looks {},heap work {},(V+E) log2 V {:.0},per (V+E) log2 V {:.3}", v2, e2, lk, 2 * p2 + c2, (v2 + e2) as f64 * (v2 as f64).log2(), (2 * p2 + c2) as f64 / ((v2 + e2) as f64 * (v2 as f64).log2()));
    }
    assert!(bfs_ok && looks == 2 * ne as u64);            // queue against the block count
    assert!(sk == 1 + (0..nv).filter(|&v| (bf[v], v) < (bf[t], t)).count() as u64 && dall == bf && da[t] == bf[t] && sa < sk && dx[t] > bf[t] && sec > bf[t]); // heap against Bellman-Ford
    assert!(k1 == pr && f0 > 10 * f1 && deep <= top && top as f64 <= (nv as f64).log2() && flat && lab == lab2); // Kruskal against Prim; union-find's rules; Tarjan against two-way reach
    assert!(ff == fek && fek == cut && fno < ff);         // a flow equal to a cut is a maximum flow
    println!("ALL CHECKS PASS");
}
