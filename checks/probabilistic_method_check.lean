-- The probabilistic method: a weighted average is matched or beaten by some outcome on each side, so some two-colouring of K(n − ⌊C(n,k) × 2^(1 − C(k,2))⌋) has no one-colour K(k), and every finite graph has a split of its dots crossed by at least half its edges.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Algebra.Order.Floor.Semifield
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Rat.Floor
import Mathlib.Data.Real.Basic
import Mathlib.Data.Sym.Card
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.NormNum

open Finset

/-! A two-colouring of the complete graph K(n) is a simple graph `G` on `Fin n`: the edges of
`G` get one colour (red), the edges of its complement `Gᶜ` the other (blue). A one-colour set of
`k` nails is a `k`-clique in `G` or in `Gᶜ`, so "no one-colour K(k)" is
`G.CliqueFree k ∧ Gᶜ.CliqueFree k`, and "R(k,k) > m" is the existence of such a `G` on `Fin m`.

A random outcome on finitely many outcomes `Ω` is a chance `p ω ≥ 0` for each outcome, the
chances adding to 1; the expectation of a count `X` is `∑ ω, p ω * X ω`. -/

/-- Counting colourings: the colourings `c : α → Bool` that agree with a fixed pattern `b` on a
set `A` make up a `2^(-#A)` share of all colourings. -/
theorem card_agree_mul_pow {α : Type*} [Fintype α] [DecidableEq α] (A : Finset α)
    (b : α → Bool) :
    (univ.filter (fun c : α → Bool => ∀ a ∈ A, c a = b a)).card * 2 ^ A.card =
      2 ^ Fintype.card α := by
  have h : univ.filter (fun c : α → Bool => ∀ a ∈ A, c a = b a) =
      Fintype.piFinset (fun a => if a ∈ A then {b a} else univ) := by
    ext c
    simp only [mem_filter, mem_univ, true_and, Fintype.mem_piFinset]
    constructor
    · intro hc a
      by_cases ha : a ∈ A
      · simp [ha, hc a ha]
      · simp [ha]
    · intro hc a ha
      have := hc a
      simpa [ha] using this
  rw [h, Fintype.card_piFinset]
  have : ∀ a, (if a ∈ A then ({b a} : Finset Bool) else univ).card =
      if a ∈ A then 1 else 2 := by
    intro a; split_ifs <;> simp
  simp only [this]
  rw [Finset.prod_ite, prod_const_one, one_mul, prod_const]
  rw [← pow_add]
  congr 1
  have h1 : (univ.filter (fun a => a ∉ A)) = Aᶜ := by ext; simp
  rw [h1, card_compl, Nat.sub_add_cancel (card_le_univ A)]

#print axioms card_agree_mul_pow

/-- Pulling back along an edge-preserving embedding: if `φ` sends edges of `G` to edges of `G'`
and lands inside `R`, and no `k`-clique of `G'` lies inside `R`, then `G` has no `k`-clique. -/
theorem cliqueFree_of_adj_imp {α β : Type*} {G : SimpleGraph α} {G' : SimpleGraph β}
    (φ : α ↪ β) (hadj : ∀ x y, G.Adj x y → G'.Adj (φ x) (φ y)) (k : ℕ) (R : Set β)
    (hR : ∀ x, φ x ∈ R) (hbad : ∀ t : Finset β, G'.IsNClique k t → ¬ ((t : Set β) ⊆ R)) :
    G.CliqueFree k := by
  intro s hs
  apply hbad (s.map φ)
  · refine ⟨?_, by rw [card_map, hs.card_eq]⟩
    intro a ha b hb hab
    rw [coe_map] at ha hb
    obtain ⟨x, hx, rfl⟩ := ha
    obtain ⟨y, hy, rfl⟩ := hb
    exact hadj x y (hs.isClique hx hy (fun h => hab (by rw [h])))
  · intro a ha
    rw [coe_map] at ha
    obtain ⟨x, -, rfl⟩ := ha
    exact hR x

#print axioms cliqueFree_of_adj_imp

/-- The averaging principle: on finitely many outcomes with chances adding to 1, a random
quantity `X` takes, in at least one outcome, a value no bigger than its expectation `E[X]`,
and in at least one outcome a value no smaller. -/
theorem exists_le_expectation_and_exists_ge_expectation {Ω : Type*} [Fintype Ω]
    (p : Ω → ℝ) (hp : ∀ ω, 0 ≤ p ω) (hsum : ∑ ω, p ω = 1) (X : Ω → ℝ) :
    (∃ ω, X ω ≤ ∑ ω', p ω' * X ω') ∧ (∃ ω, ∑ ω', p ω' * X ω' ≤ X ω) := by
  have hne : (univ : Finset Ω).Nonempty := by
    by_contra h
    rw [not_nonempty_iff_eq_empty] at h
    rw [h, sum_empty] at hsum
    norm_num at hsum
  obtain ⟨a, -, ha⟩ := exists_min_image univ X hne
  obtain ⟨b, -, hb⟩ := exists_max_image univ X hne
  refine ⟨⟨a, ?_⟩, ⟨b, ?_⟩⟩
  · calc X a = ∑ ω', p ω' * X a := by rw [← sum_mul, hsum, one_mul]
      _ ≤ ∑ ω', p ω' * X ω' :=
        sum_le_sum fun ω _ => mul_le_mul_of_nonneg_left (ha ω (mem_univ _)) (hp ω)
  · calc ∑ ω', p ω' * X ω' ≤ ∑ ω', p ω' * X b :=
        sum_le_sum fun ω _ => mul_le_mul_of_nonneg_left (hb ω (mem_univ _)) (hp ω)
      _ = X b := by rw [← sum_mul, hsum, one_mul]

/-- The deletion bound: for every board size `n` and every clique size `k ≥ 1`, with
`E[X] = C(n,k) × 2^(1 − C(k,2))` the expected number of one-colour k-sets under fair coin
flips, some two-colouring of K(n − ⌊E[X]⌋) has no one-colour K(k); that is,
R(k,k) > n − ⌊E[X]⌋. (At `k = 0` the empty set is always "one colour", so the count's
expectation is not `C(n,0) × 2^(1 − 0)` there.) -/
theorem ramsey_gt_sub_floor_expectation (n k : ℕ) (hk : 0 < k) :
    ∃ G : SimpleGraph (Fin (n - ⌊(n.choose k : ℚ) * 2 / 2 ^ k.choose 2⌋₊)),
      G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  classical
  set F := ⌊(n.choose k : ℚ) * 2 / 2 ^ k.choose 2⌋₊ with hF
  let Gc : (Sym2 (Fin n) → Bool) → SimpleGraph (Fin n) :=
    fun c => SimpleGraph.fromEdgeSet {e | c e = true}
  let A : Finset (Fin n) → Finset (Sym2 (Fin n)) := fun t => t.offDiag.image Sym2.mk.uncurry
  let mono : Finset (Fin n) → (Sym2 (Fin n) → Bool) → Prop :=
    fun t c => (∀ e ∈ A t, c e = true) ∨ (∀ e ∈ A t, c e = false)
  let P := (univ : Finset (Fin n)).powersetCard k
  let N := Fintype.card (Sym2 (Fin n))
  have hmono : ∀ t ∈ P,
      (univ.filter (fun c => mono t c)).card * 2 ^ k.choose 2 ≤ 2 * 2 ^ N := by
    intro t ht
    have hA : (A t).card = k.choose 2 := by
      rw [Sym2.card_image_offDiag, (mem_powersetCard.1 ht).2]
    rw [← hA, filter_or]
    have h1 := card_agree_mul_pow (A t) (fun _ => true)
    have h2 := card_agree_mul_pow (A t) (fun _ => false)
    calc _ ≤ ((univ.filter (fun c : Sym2 (Fin n) → Bool => ∀ e ∈ A t, c e = true)).card +
            (univ.filter (fun c : Sym2 (Fin n) → Bool => ∀ e ∈ A t, c e = false)).card) *
              2 ^ (A t).card := Nat.mul_le_mul_right _ (card_union_le _ _)
      _ = 2 * 2 ^ N := by rw [add_mul, h1, h2]; ring
  have hsum : ∑ c : Sym2 (Fin n) → Bool, (P.filter (fun t => mono t c)).card * 2 ^ k.choose 2 ≤
      ∑ c : Sym2 (Fin n) → Bool, n.choose k * 2 := by
    calc ∑ c : Sym2 (Fin n) → Bool, (P.filter (fun t => mono t c)).card * 2 ^ k.choose 2
          = ∑ t ∈ P, (univ.filter (fun c => mono t c)).card * 2 ^ k.choose 2 := by
            simp only [card_filter, sum_mul]
            rw [sum_comm]
      _ ≤ ∑ t ∈ P, 2 * 2 ^ N := sum_le_sum hmono
      _ = _ := by
        have hPc : P.card = n.choose k := by simp [P]
        simp only [sum_const, card_univ, Fintype.card_fun, Fintype.card_bool, smul_eq_mul, hPc]
        ring
  obtain ⟨c, -, hc⟩ := exists_le_of_sum_le univ_nonempty hsum
  set Mono := P.filter (fun t => mono t c) with hMono
  have hM : Mono.card ≤ F := by
    apply Nat.le_floor
    rw [le_div_iff₀ (by positivity)]
    exact_mod_cast hc
  have hne : ∀ t ∈ Mono, t.Nonempty := by
    intro t ht
    rw [← card_pos, (mem_powersetCard.1 (mem_filter.1 ht).1).2]
    exact hk
  let D := Mono.attach.image (fun t => t.1.min' (hne t.1 t.2))
  have hD : D.card ≤ Mono.card := card_image_le.trans card_attach.le
  have hbad : ∀ t ∈ Mono, ¬ t ⊆ Dᶜ := by
    intro t ht hsub
    have h1 : t.min' (hne t ht) ∈ D := mem_image_of_mem _ (mem_attach _ ⟨t, ht⟩)
    exact (mem_compl.1 (hsub (min'_mem t (hne t ht)))) h1
  have hm : n - F ≤ Dᶜ.card := by
    rw [card_compl, Fintype.card_fin]; omega
  let φ : Fin (n - F) ↪ Fin n :=
    (Fin.castLEEmb hm).trans (Dᶜ.equivFin.symm.toEmbedding.trans (Function.Embedding.subtype _))
  have hφ : ∀ i, φ i ∈ ((Dᶜ : Finset (Fin n)) : Set (Fin n)) := by
    intro i
    exact (Dᶜ.equivFin.symm (Fin.castLEEmb hm i)).2
  have hP : ∀ t : Finset (Fin n), t.card = k → t ∈ P := fun t ht =>
    mem_powersetCard.2 ⟨subset_univ _, ht⟩
  refine ⟨SimpleGraph.comap φ (Gc c), ?_, ?_⟩
  · refine cliqueFree_of_adj_imp φ (G' := Gc c) (fun x y h => h) k _ hφ ?_
    intro t ht hsub
    refine hbad t (mem_filter.2 ⟨hP t ht.card_eq, Or.inl ?_⟩) (coe_subset.1 hsub)
    intro e he
    obtain ⟨⟨u, v⟩, huv, rfl⟩ := mem_image.1 he
    obtain ⟨hu, hv, hne⟩ := mem_offDiag.1 huv
    have := ht.isClique hu hv hne
    simp only [Gc, SimpleGraph.fromEdgeSet_adj, Set.mem_ofPred_eq] at this
    exact this.1
  · refine cliqueFree_of_adj_imp φ (G' := (Gc c)ᶜ) ?_ k _ hφ ?_
    · intro x y h
      rw [SimpleGraph.compl_adj] at h ⊢
      exact ⟨φ.injective.ne h.1, h.2⟩
    intro t ht hsub
    refine hbad t (mem_filter.2 ⟨hP t ht.card_eq, Or.inr ?_⟩) (coe_subset.1 hsub)
    intro e he
    obtain ⟨⟨u, v⟩, huv, rfl⟩ := mem_image.1 he
    obtain ⟨hu, hv, hne⟩ := mem_offDiag.1 huv
    have := ht.isClique hu hv hne
    simpa [Gc, SimpleGraph.fromEdgeSet_adj, hne] using this

/-- The large cut: every finite graph with `m` edges has a split of its dots into a set `S`
and the rest such that at least `m / 2` edges cross the split. Each crossing edge is counted
once, as the ordered pair `(u, v)` with `u ∈ S`, `v ∉ S`. -/
theorem exists_cut_ge_half_edges {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    ∃ S : Finset V,
      G.edgeFinset.card ≤ 2 * ((S ×ˢ Sᶜ).filter (fun e => G.Adj e.1 e.2)).card := by
  set P := (univ : Finset (V × V)).filter (fun e => G.Adj e.1 e.2) with hP
  have hPcard : P.card = 2 * G.edgeFinset.card := by
    rw [← G.sum_degrees_eq_twice_card_edges, hP, card_filter, Fintype.sum_prod_type]
    refine sum_congr rfl fun u _ => ?_
    rw [← G.card_neighborFinset_eq_degree, G.neighborFinset_eq_filter, card_filter]
  have hpair : ∀ e ∈ P,
      (univ.filter (fun c : V → Bool => c e.1 = true ∧ c e.2 = false)).card * 4 =
        2 ^ Fintype.card V := by
    intro e he
    have hne : e.1 ≠ e.2 := by
      have := (mem_filter.1 he).2
      exact G.ne_of_adj this
    have h := card_agree_mul_pow ({e.1, e.2} : Finset V) (fun w => decide (w = e.1))
    rw [card_pair hne] at h
    rw [← h]
    congr 2
    ext c
    simp only [mem_filter, mem_univ, true_and, mem_insert, mem_singleton, forall_eq_or_imp,
      forall_eq, decide_true]
    simp [hne.symm]
  have hcut : ∀ c : V → Bool,
      ((univ.filter (fun v => c v = true)) ×ˢ (univ.filter (fun v => c v = true))ᶜ).filter
          (fun e => G.Adj e.1 e.2) =
        P.filter (fun e => c e.1 = true ∧ c e.2 = false) := by
    intro c
    ext e
    simp only [hP, mem_filter, mem_product, mem_univ, true_and, mem_compl,
      Bool.not_eq_true]
    tauto
  have hsum : ∑ c : V → Bool, P.card ≤
      ∑ c : V → Bool, 4 * (P.filter (fun e => c e.1 = true ∧ c e.2 = false)).card := by
    apply le_of_eq
    simp only [card_filter, mul_sum]
    rw [sum_comm]
    simp only [← mul_sum, ← card_filter]
    rw [sum_const, card_univ, smul_eq_mul, Fintype.card_fun, Fintype.card_bool]
    rw [mul_sum, mul_comm, ← smul_eq_mul, ← sum_const]
    exact sum_congr rfl fun e he => by rw [mul_comm, hpair e he]
  obtain ⟨c, -, hc⟩ := exists_le_of_sum_le univ_nonempty hsum
  refine ⟨univ.filter (fun v => c v = true), ?_⟩
  rw [hcut c]
  omega

-- The 21-nail board: 210 threads, 54264 six-sets, 15 threads in each.
example : Nat.choose 21 2 = 210 := by decide
example : Nat.choose 21 6 = 54264 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; decide
example : Nat.choose 6 2 = 15 := by decide
-- E[X] = 54264 × 2 / 2^15 has whole-number part 3, so 21 − 3 = 18 nails survive deletion.
example : ⌊((Nat.choose 21 6 : ℕ) : ℚ) * 2 / 2 ^ Nat.choose 6 2⌋₊ = 3 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
example : 21 - 3 = 18 := by decide
-- The counting argument alone: E[X] < 1 at 17 nails (2 × C(17,6) < 2^15), not at 18.
example : 2 * Nat.choose 17 6 < 2 ^ Nat.choose 6 2 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
example : ¬ (2 * Nat.choose 18 6 < 2 ^ Nat.choose 6 2) := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
-- n − ⌊E[X]⌋ for n = 17 to 23 at k = 6 is 17, 17, 18, 18, 18, 18, 17.
example : (List.range' 17 7).map (fun n => n - Nat.choose n 6 * 2 / 2 ^ Nat.choose 6 2) =
    [17, 17, 18, 18, 18, 18, 17] := by
  simp only [Nat.choose_eq_descFactorial_div_factorial]; decide
-- The small board K(6): 15 four-sets give E[X] = 15 × 2^-5 = 15/32; 20 three-sets give 5.
example : ((Nat.choose 6 4 : ℕ) : ℚ) * 2 / 2 ^ Nat.choose 4 2 = 15 / 32 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
example : ((Nat.choose 6 3 : ℕ) : ℚ) * 2 / 2 ^ Nat.choose 3 2 = 5 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
-- K(6) has 2^15 = 32768 colourings.
example : 2 ^ Nat.choose 6 2 = 32768 := by decide
-- The office: 15 clashing pairs, E = 15/2, so some split separates at least 8 (2 × 8 ≥ 15 > 2 × 7).
example : 15 ≤ 2 * 8 ∧ ¬ (15 ≤ 2 * 7) := by decide
-- 1024 splits of 10 staff; 460 reach 8 or more and 564 fall below.
example : 2 ^ 10 = 1024 ∧ 460 + 564 = 1024 := by decide

#print axioms exists_le_expectation_and_exists_ge_expectation
#print axioms ramsey_gt_sub_floor_expectation
#print axioms exists_cut_ge_half_edges
