// Games in turns -- the same check as the Python, in Rust.  No crates.  A rival bakery
// goes In next to one of the chain's shops or stays Out; after In the chain will Fight
// (price war) or Accommodate.  Synthetic pounds a month, (rival, chain): Out (0, 2000),
// Fight (-1000, -1000), Accommodate (1000, 1000).  Roads: (1) backward induction; (2)
// every profile tested for Nash and subgame perfection; (3) a threat's belief threshold.
const OUT: (i64, i64) = (0, 2000);
const FIGHT: (i64, i64) = (-1000, -1000);
const ACC: (i64, i64) = (1000, 1000);
const MOVES: [[&str; 2]; 2] = [["In", "Out"], ["Fight", "Accommodate"]];

struct Node { player: i64, pay: Vec<i64>, kids: Vec<usize> }   // a leaf has player -1
fn leaf(pay: Vec<i64>) -> Node { Node { player: -1, pay, kids: vec![] } }

fn build(nodes: &mut Vec<Node>, towns: usize, acc_chain: i64, k: usize, pay: Vec<i64>) -> usize {
    let i = nodes.len();
    nodes.push(leaf(vec![]));
    if k == towns { nodes[i] = leaf(pay); return i; }
    let c = nodes.len();
    nodes.push(leaf(vec![]));
    let add = |nodes: &mut Vec<Node>, rival: i64, chain: i64| {   // town k's payoffs
        let mut p = pay.clone();
        p[k] += rival;
        p[towns] += chain;
        build(nodes, towns, acc_chain, k + 1, p)
    };
    let f = add(nodes, FIGHT.0, FIGHT.1);
    let a = add(nodes, ACC.0, acc_chain);
    let o = add(nodes, OUT.0, OUT.1);
    nodes[c] = Node { player: towns as i64, pay: vec![], kids: vec![f, a] };
    nodes[i] = Node { player: k as i64, pay: vec![], kids: vec![c, o] };
    i
}
fn chain_store(towns: usize, acc_chain: i64) -> Vec<Node> {      // players 0..towns-1 rivals
    let mut nodes = Vec::new();
    build(&mut nodes, towns, acc_chain, 0, vec![0; towns + 1]);
    nodes
}
fn solve(nodes: &[Node], i: usize, plan: &mut Vec<usize>, visits: &mut usize) -> Vec<i64> {
    *visits += 1;                                                 // road 1: backward induction
    let n = &nodes[i];
    if n.player < 0 { return n.pay.clone(); }
    let values: Vec<Vec<i64>> = n.kids.iter().map(|&c| solve(nodes, c, plan, visits)).collect();
    let p = n.player as usize;
    let mut best = 0;
    for j in 1..values.len() { if values[j][p] > values[best][p] { best = j; } }  // ties: first
    plan[i] = best;
    values[best].clone()
}
fn run(nodes: &[Node]) -> (Vec<usize>, Vec<i64>, usize) {
    let (mut plan, mut visits) = (vec![0; nodes.len()], 0);
    let v = solve(nodes, 0, &mut plan, &mut visits);
    (plan, v, visits)
}
fn play(nodes: &[Node], mut i: usize, prof: &[usize]) -> Vec<i64> {
    while nodes[i].player >= 0 { i = nodes[i].kids[prof[i]]; }
    nodes[i].pay.clone()
}
fn stable(nodes: &[Node], h: usize, prof: &[usize], owners: &[(usize, Vec<usize>)]) -> bool {
    for (p, own) in owners {                                      // nobody gains alone, from h
        let base = play(nodes, h, prof)[*p];
        for bits in 0..(1usize << own.len()) {
            let mut alt = prof.to_vec();
            for (b, &n) in own.iter().enumerate() { alt[n] = bits >> b & 1; }
            if play(nodes, h, &alt)[*p] > base { return false; }
        }
    }
    true
}
fn exhaustive(nodes: &[Node]) -> (Vec<usize>, Vec<Vec<usize>>, Vec<Vec<usize>>) {   // road 2
    let dec: Vec<usize> = (0..nodes.len()).filter(|&i| nodes[i].player >= 0).collect();
    let mut owners: Vec<(usize, Vec<usize>)> = Vec::new();
    for &i in &dec {
        let p = nodes[i].player as usize;
        match owners.iter_mut().find(|o| o.0 == p) { Some(o) => o.1.push(i), None => owners.push((p, vec![i])) }
    }
    let (mut ne, mut spe) = (Vec::new(), Vec::new());
    for bits in 0..(1usize << dec.len()) {
        let mut prof = vec![0; nodes.len()];
        for (b, &n) in dec.iter().enumerate() { prof[n] = bits >> b & 1; }
        if stable(nodes, 0, &prof, &owners) {
            if dec.iter().all(|&h| stable(nodes, h, &prof, &owners)) { spe.push(prof.clone()); }
            ne.push(prof);
        }
    }
    (dec, ne, spe)
}
fn layout(nodes: &[Node], i: usize, depth: i64, xs: &mut Vec<f64>, pos: &mut Vec<(f64, i64)>) -> f64 {
    let x = if nodes[i].player < 0 {
        let x = 70.0 + 110.0 * xs.len() as f64;
        xs.push(x);
        x
    } else {
        nodes[i].kids.iter().map(|&c| layout(nodes, c, depth + 1, xs, pos)).sum::<f64>() / 2.0
    };
    pos[i] = (x, 40 + 80 * depth);
    x
}
fn fmt(p: &[i64]) -> String { format!("({})", p.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let g = chain_store(1, ACC.1);
    let (plan, spe_pay, visits) = run(&g);
    println!("entry game: {} nodes, payoffs listed (rival, chain)", g.len());
    println!("chain's node: Fight gives the chain {}, Accommodate {} -> {}", FIGHT.1, ACC.1, MOVES[1][plan[1]]);
    println!("rival's node: In gives the rival {}, Out {} -> {}", ACC.0, OUT.0, MOVES[0][plan[0]]);
    println!("road 1, backward induction: rival {}, chain {}, payoffs {}, nodes visited {}", MOVES[0][plan[0]], MOVES[1][plan[1]], fmt(&spe_pay), visits);
    let (dec, ne, spe) = exhaustive(&g);
    let name = |p: &Vec<usize>| format!("rival {} / chain {} {}", MOVES[0][p[0]], MOVES[1][p[1]], fmt(&play(&g, 0, p)));
    println!("road 2, all {} profiles, Nash equilibria: {}", 1usize << dec.len(), ne.iter().map(|p| name(p)).collect::<Vec<_>>().join("; "));
    println!("road 2, subgame perfect: {}; matches road 1: {}", spe.iter().map(|p| name(p)).collect::<Vec<_>>().join("; "), yn(spe == vec![plan.clone()]));
    let q_formula = (ACC.0 - OUT.0) as f64 / (ACC.0 - FIGHT.0) as f64;
    let mut j = 0i64;
    while j * FIGHT.0 + (100 - j) * ACC.0 > 100 * OUT.0 { j += 1; }
    println!("road 3, belief in a fight that keeps the rival out: formula {}/{} = {:.2}; grid {}/100 = {:.2}", ACC.0 - OUT.0, ACC.0 - FIGHT.0, q_formula, j, j as f64 / 100.0);
    println!("rival's expected gain from In if a fight is believed 0.40 likely: {}; 0.60 likely: {}", (40 * FIGHT.0 + 60 * ACC.0) / 100, (60 * FIGHT.0 + 40 * ACC.0) / 100);
    let com: Vec<(i64, (Vec<usize>, Vec<i64>, usize))> = [2500, 1500].iter().map(|&pen| (pen, run(&chain_store(1, ACC.1 - pen)))).collect();
    for (pen, (cplan, cpay, _)) in &com {
        println!("commitment, penalty {}: Accommodate pays the chain {} - {} = {}; chain {}, rival {}, payoffs {}; worth {} a month to the chain",
                 pen, ACC.1, pen, ACC.1 - pen, MOVES[1][cplan[1]], MOVES[0][cplan[0]], fmt(cpay), cpay[1] - spe_pay[1]);
    }
    let g2 = chain_store(2, ACC.1);
    let plan2 = run(&g2).0;
    let (dec2, ne2, spe2) = exhaustive(&g2);
    let same2 = spe2.len() == 1 && dec2.iter().all(|&i| spe2[0][i] == plan2[i]);
    println!("two towns: {} profiles, {} Nash equilibria, {} subgame perfect; matches road 1: {}", 1usize << dec2.len(), ne2.len(), spe2.len(), yn(same2));
    let g3 = chain_store(3, ACC.1);
    let (plan3, pay3, visits3) = run(&g3);
    let d3 = g3.iter().filter(|n| n.player >= 0).count();
    println!("three towns: backward induction visits {} nodes ({} decisions, {} leaves); the table has 2^{} = {} profiles", visits3, d3, visits3 - d3, d3, 1u64 << d3);
    let last: Vec<usize> = (0..g3.len()).filter(|&i| g3[i].player == 3 && g3[g3[i].kids[0]].player < 0).collect();
    println!("three towns, payoffs {}; town-3 chain nodes {}, accommodating at {}", fmt(&pay3), last.len(), last.iter().map(|&i| plan3[i]).sum::<usize>());
    let scared: Vec<usize> = g3.iter().map(|n| if (0..3).contains(&n.player) { 1 } else { 0 }).collect();
    let mut early = plan3.clone();
    early[1] = 0;                                                 // chain fights in town 1 only
    let early_chain = play(&g3, 0, &early)[3];
    println!("if every rival believed 'always fight': chain {}; fighting in town 1, then accommodating: chain {}", play(&g3, 0, &scared)[3], early_chain);
    let takes = [[4i64, 1], [2, 8], [16, 4], [8, 32]];
    let end = vec![64i64, 16];
    let mut cen = Vec::new();
    for (m, pay) in takes.iter().enumerate() {
        cen.push(Node { player: (m % 2) as i64, pay: vec![], kids: vec![2 * m + 1, 2 * m + 2] });
        cen.push(leaf(pay.to_vec()));
    }
    cen.push(leaf(end.clone()));
    let (cplan2, cval, _) = run(&cen);
    println!("centipede: backward induction takes at move {} with {}; passing to the end pays {}", cplan2[0] + 1, fmt(&cval), fmt(&end));
    let mut ult = vec![Node { player: 0, pay: vec![], kids: vec![] }];   // offers 0..100 tenpences
    for o in 0..=100i64 {
        let n = ult.len();
        ult[0].kids.push(n);
        ult.push(Node { player: 1, pay: vec![], kids: vec![n + 1, n + 2] });
        ult.push(leaf(vec![0, 0]));
        ult.push(leaf(vec![100 - o, o]));
    }
    let (uplan, uval, _) = run(&ult);
    println!("ultimatum over £10 (1000p) in 10p steps: offer {}p, proposer keeps {}p ({} nodes)", 10 * uplan[0], 10 * uval[0], ult.len());
    println!("mistakes: rival trusting (Out, Fight) gives up {}; chain carrying out the threat loses {}; one reputation fight costs {}", spe_pay[0] - OUT.0, ACC.1 - FIGHT.1, pay3[3] - early_chain);
    let mut pos = vec![(0.0, 0i64); g.len()];
    layout(&g, 0, 0, &mut Vec::new(), &mut pos);
    let keys = [("rival", 0), ("chain", 1), ("fight", 2), ("accommodate", 3), ("out", 4)];
    println!("figure, {}", keys.iter().map(|(k, i)| format!("{} ({:.1}, {})", k, pos[*i].0, pos[*i].1)).collect::<Vec<_>>().join(", "));
    assert!(spe == vec![plan.clone()] && plan[0] == 0 && plan[1] == 1);   // road 2 agrees with road 1
    assert!(ne.len() == 2 && play(&g, 0, &ne[0]) == vec![OUT.0, OUT.1]);    // the empty-threat equilibrium
    assert!(j as f64 / 100.0 == q_formula);                                  // road 3: grid meets formula
    assert!(same2 && pay3[3] == 3 * ACC.1 && visits3 == g3.len() && g3.len() == 53);
    assert!(com[0].1 .1 == vec![OUT.0, OUT.1] && cval == takes[0].to_vec() && uplan[0] == 1);
    println!("ALL CHECKS PASS");
}
