-- Erdos's counting trick: the two-colourings of K(n) with a one-colour K(k) number at most 2 x C(n,k) x 2^(C(n,2) - C(k,2)), so when 2 x C(n,k) < 2^C(k,2) a colouring with no one-colour K(k) exists, and for k at least 3 this holds whenever n ≤ 2^(k/2), giving R(k,k) > 2^(k/2).
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Nat.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Data.Sym.Card
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.BigOperators.Group.Finset

/-! A two-colouring of the complete graph K(n) is a simple graph `G` on `Fin n`: the edges of
`G` get the first colour (copper), the edges of its complement `Gᶜ` the second (fibre).
A one-colour K(k) is a k-clique in `G` or in `Gᶜ`, so "no one-colour K(k)" is
`G.CliqueFree k ∧ Gᶜ.CliqueFree k`, and "R(k,k) > n" is the existence of such a `G`. -/

open Finset in
theorem clique_count_le_aux (n k : ℕ) (f : SimpleGraph (Fin n) → SimpleGraph (Fin n))
    (hf : Function.Injective f) (s : Finset (Fin n)) (hs : s.card = k)
    (B : Finset (SimpleGraph (Fin n))) (hB : ∀ G ∈ B, (f G).IsNClique k s) :
    B.card ≤ 2 ^ (n.choose 2 - k.choose 2) := by
  classical
  set U := (⊤ : SimpleGraph (Fin n)).edgeFinset with hUdef
  set E := s.offDiag.image Sym2.mk.uncurry with hEdef
  have hE : E.card = k.choose 2 := by rw [hEdef, Sym2.card_image_offDiag, hs]
  have hU : U.card = n.choose 2 := by
    rw [hUdef, SimpleGraph.card_edgeFinset_top_eq_card_choose_two, Fintype.card_fin]
  have hcl : ∀ G : SimpleGraph (Fin n), G.IsNClique k s → E ⊆ G.edgeFinset := by
    intro G hG e he
    simp only [hEdef, mem_image, mem_offDiag] at he
    obtain ⟨⟨a, b⟩, ⟨ha, hb, hab⟩, rfl⟩ := he
    simp only [Function.uncurry_apply_pair, SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet]
    exact hG.isClique ha hb hab
  have hEU : E ⊆ U := by convert hcl ⊤ ⟨fun a _ b _ hab => hab, hs⟩
  calc B.card ≤ (U \ E).powerset.card := by
        refine card_le_card_of_injOn (fun G => (f G).edgeFinset \ E) ?_ ?_
        · intro G _
          simp only [coe_powerset, Set.mem_preimage, Set.mem_powerset_iff, coe_subset]
          exact sdiff_subset_sdiff (SimpleGraph.edgeFinset_mono le_top) le_rfl
        · intro G hG H hH hGH
          have h1 := hcl _ (hB G hG)
          have h2 := hcl _ (hB H hH)
          apply hf
          rw [← SimpleGraph.edgeFinset_inj, ← sdiff_union_of_subset h1,
            ← sdiff_union_of_subset h2]
          simp only at hGH
          rw [hGH]
    _ = 2 ^ (n.choose 2 - k.choose 2) := by
        rw [card_powerset, card_sdiff_of_subset hEU, hU, hE]

#print axioms clique_count_le_aux

open Finset in
theorem card_simpleGraph_fin_ge (n : ℕ) :
    2 ^ (n.choose 2) ≤ Fintype.card (SimpleGraph (Fin n)) := by
  classical
  have hU : (⊤ : SimpleGraph (Fin n)).edgeFinset.card = n.choose 2 := by
    rw [SimpleGraph.card_edgeFinset_top_eq_card_choose_two, Fintype.card_fin]
  rw [← hU, ← card_powerset, ← card_univ]
  refine card_le_card_of_injOn (fun T => SimpleGraph.fromEdgeSet (T : Set (Sym2 (Fin n))))
    (fun _ _ => mem_coe.2 (mem_univ _)) ?_
  intro T hT T' hT' h
  have hd : ∀ S ∈ ((⊤ : SimpleGraph (Fin n)).edgeFinset.powerset : Set (Finset (Sym2 (Fin n)))),
      ((S : Set (Sym2 (Fin n))) \ Sym2.diagSet) = S := by
    intro S hS
    rw [mem_coe, mem_powerset] at hS
    ext e
    simp only [Set.mem_sdiff, mem_coe, and_iff_left_iff_imp]
    intro he
    have := hS he
    rw [SimpleGraph.mem_edgeFinset, SimpleGraph.edgeSet_top] at this
    exact this
  have := congrArg SimpleGraph.edgeSet h
  simp only [SimpleGraph.edgeSet_fromEdgeSet] at this
  rw [hd T hT, hd T' hT'] at this
  exact_mod_cast this

theorem two_pow_add_two_lt_factorial_sq (k : ℕ) (hk : 3 ≤ k) : 2 ^ (k + 2) < (k.factorial) ^ 2 := by
  induction k, hk using Nat.le_induction with
  | base => decide
  | succ k hk ih =>
    rw [Nat.factorial_succ, mul_pow, pow_succ]
    have : 2 ≤ (k + 1) ^ 2 := by nlinarith
    calc 2 ^ (k + 2) * 2 < k.factorial ^ 2 * 2 := Nat.mul_lt_mul_of_pos_right ih (by norm_num)
      _ ≤ k.factorial ^ 2 * (k + 1) ^ 2 := Nat.mul_le_mul_left _ this
      _ = (k + 1) ^ 2 * k.factorial ^ 2 := mul_comm _ _

theorem two_mul_choose_two_add_self (k : ℕ) : 2 * k.choose 2 + k = k * k := by
  induction k with
  | zero => rfl
  | succ k ih =>
    rw [Nat.choose_succ_succ', Nat.choose_one_right]
    have h2 : k.choose (1 + 1) = k.choose 2 := rfl
    rw [h2]; nlinarith [ih]

#print axioms card_simpleGraph_fin_ge
#print axioms two_pow_add_two_lt_factorial_sq
#print axioms two_mul_choose_two_add_self

open scoped Classical in
theorem bad_colourings_le_aux (n k : ℕ) :
    (Finset.univ.filter
        (fun G : SimpleGraph (Fin n) => ¬ G.CliqueFree k ∨ ¬ Gᶜ.CliqueFree k)).card ≤
      2 * n.choose k * 2 ^ (n.choose 2 - k.choose 2) := by
  calc _ ≤ ((Finset.univ.powersetCard k).biUnion fun s =>
          (Finset.univ.filter fun G : SimpleGraph (Fin n) => G.IsNClique k s) ∪
            (Finset.univ.filter fun G : SimpleGraph (Fin n) => Gᶜ.IsNClique k s)).card := by
        apply Finset.card_le_card
        intro G hG
        simp only [Finset.mem_filter, Finset.mem_univ, true_and, SimpleGraph.CliqueFree,
          not_forall, not_not] at hG
        simp only [Finset.mem_biUnion, Finset.mem_powersetCard, Finset.subset_univ, true_and,
          Finset.mem_union, Finset.mem_filter, Finset.mem_univ]
        rcases hG with ⟨s, hs⟩ | ⟨s, hs⟩
        · exact ⟨s, hs.card_eq, Or.inl hs⟩
        · exact ⟨s, hs.card_eq, Or.inr hs⟩
    _ ≤ ∑ s ∈ Finset.univ.powersetCard k,
          ((Finset.univ.filter fun G : SimpleGraph (Fin n) => G.IsNClique k s) ∪
            (Finset.univ.filter fun G : SimpleGraph (Fin n) => Gᶜ.IsNClique k s)).card :=
        Finset.card_biUnion_le
    _ ≤ ∑ _s ∈ Finset.univ.powersetCard k, 2 * 2 ^ (n.choose 2 - k.choose 2) := by
        apply Finset.sum_le_sum
        intro s hs
        rw [Finset.mem_powersetCard] at hs
        refine (Finset.card_union_le _ _).trans ?_
        rw [two_mul]
        refine add_le_add ?_ ?_
        · exact clique_count_le_aux n k id Function.injective_id s hs.2 _
            (fun G hG => (Finset.mem_filter.1 hG).2)
        · exact clique_count_le_aux n k (fun G => Gᶜ) compl_injective s hs.2 _
            (fun G hG => (Finset.mem_filter.1 hG).2)
    _ = 2 * n.choose k * 2 ^ (n.choose 2 - k.choose 2) := by
        rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin,
          smul_eq_mul]
        ring

#print axioms bad_colourings_le_aux

theorem good_colouring_aux (n k : ℕ) (h : 2 * n.choose k < 2 ^ k.choose 2) :
    ∃ G : SimpleGraph (Fin n), G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  classical
  rcases lt_or_ge n k with hkn | hkn
  · refine ⟨⊥, SimpleGraph.cliqueFree_of_card_lt ?_, SimpleGraph.cliqueFree_of_card_lt ?_⟩ <;>
      simpa using hkn
  · by_contra hne
    simp only [not_exists, not_and] at hne
    have hb := bad_colourings_le_aux n k
    rw [Finset.filter_true_of_mem (fun G _ => by
      by_cases hG : G.CliqueFree k
      · exact Or.inr (hne G hG)
      · exact Or.inl hG), Finset.card_univ] at hb
    have hc : k.choose 2 ≤ n.choose 2 := Nat.choose_le_choose 2 hkn
    have hg := card_simpleGraph_fin_ge n
    have : 2 ^ n.choose 2 < 2 ^ n.choose 2 := by
      calc 2 ^ n.choose 2 ≤ 2 * n.choose k * 2 ^ (n.choose 2 - k.choose 2) := hg.trans hb
        _ < 2 ^ k.choose 2 * 2 ^ (n.choose 2 - k.choose 2) :=
            Nat.mul_lt_mul_of_pos_right h (by positivity)
        _ = 2 ^ n.choose 2 := by rw [← pow_add, Nat.add_sub_cancel' hc]
    exact lt_irrefl _ this

#print axioms good_colouring_aux

/-- Erdos's bound: for every clique size `k` of at least 3 and every number of dots `n` with
`n ≤ 2^(k/2)` (written `n^2 ≤ 2^k`), some two-colouring of K(n) has no one-colour K(k).
That is, R(k,k) > 2^(k/2). -/
theorem ramsey_diagonal_gt_two_pow_half (k n : ℕ) (hk : 3 ≤ k) (hn : n ^ 2 ≤ 2 ^ k) :
    ∃ G : SimpleGraph (Fin n), G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  apply good_colouring_aux
  by_contra h
  rw [not_lt] at h
  have h1 : k.factorial * n.choose k ≤ n ^ k := by
    rw [← Nat.descFactorial_eq_factorial_mul_choose]; exact Nat.descFactorial_le_pow n k
  have h2 : (k.factorial * n.choose k) ^ 2 ≤ 2 ^ (k * k) := by
    calc (k.factorial * n.choose k) ^ 2 ≤ (n ^ k) ^ 2 := Nat.pow_le_pow_left h1 2
      _ = (n ^ 2) ^ k := by rw [← pow_mul, ← pow_mul, mul_comm]
      _ ≤ (2 ^ k) ^ k := Nat.pow_le_pow_left hn k
      _ = 2 ^ (k * k) := by rw [← pow_mul]
  have h3 := two_pow_add_two_lt_factorial_sq k hk
  have h4 := two_mul_choose_two_add_self k
  have : 2 ^ (k * k + 2) < 2 ^ (k * k + 2) := by
    calc 2 ^ (k * k + 2) = 2 ^ (2 * k.choose 2) * 2 ^ (k + 2) := by
          rw [← pow_add, ← h4]; ring_nf
      _ < 2 ^ (2 * k.choose 2) * k.factorial ^ 2 :=
          Nat.mul_lt_mul_of_pos_left h3 (by positivity)
      _ = (2 ^ k.choose 2) ^ 2 * k.factorial ^ 2 := by ring
      _ ≤ (2 * n.choose k) ^ 2 * k.factorial ^ 2 :=
          Nat.mul_le_mul_right _ (Nat.pow_le_pow_left h 2)
      _ = 4 * (k.factorial * n.choose k) ^ 2 := by ring
      _ ≤ 4 * 2 ^ (k * k) := Nat.mul_le_mul_left 4 h2
      _ = 2 ^ (k * k + 2) := by ring
  exact lt_irrefl _ this

open scoped Classical in
/-- The over-count by blame: among all `2^C(n,2)` two-colourings of K(n), those with a one-colour
K(k) number at most `2 × C(n,k) × 2^(C(n,2) − C(k,2))` (pick the colour, pick the k dots, let
every other edge fall as it likes). -/
theorem bad_colourings_le (n k : ℕ) :
    (Finset.univ.filter
        (fun G : SimpleGraph (Fin n) => ¬ G.CliqueFree k ∨ ¬ Gᶜ.CliqueFree k)).card ≤
      2 * n.choose k * 2 ^ (n.choose 2 - k.choose 2) := by
  exact bad_colourings_le_aux n k

/-- The exact test: if the bad share `C(n,k) × 2^(1 − C(k,2))` is under 1, that is
`2 × C(n,k) < 2^C(k,2)`, then a two-colouring of K(n) with no one-colour K(k) exists,
so R(k,k) > n. -/
theorem good_colouring_of_two_mul_choose_lt (n k : ℕ) (h : 2 * n.choose k < 2 ^ k.choose 2) :
    ∃ G : SimpleGraph (Fin n), G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  exact good_colouring_aux n k h

-- The server hall: 32 machines, 496 cables, 2^496 plans, 64512240 ten-sets, 45 cables in each.
example : Nat.choose 32 2 = 496 := by decide
example : Nat.choose 32 10 = 64512240 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; decide
example : Nat.choose 10 2 = 45 := by decide
example : 496 - 45 = 451 := by decide
-- 2^496 has 150 digits: 10^149 ≤ 2^496 < 10^150.
set_option exponentiation.threshold 600 in
example : 10 ^ 149 ≤ 2 ^ 496 ∧ 2 ^ 496 < 10 ^ 150 := by decide
-- Witnesses times free plans over all plans: 2 x 64512240 x 2^451 / 2^496 = 64512240 / 2^44.
set_option exponentiation.threshold 600 in
example : 2 * 64512240 * 2 ^ 451 * 2 ^ 44 = 64512240 * 2 ^ 496 := by decide
-- The bad share is under 1: 2 x C(32,10) < 2^C(10,2), so R(10,10) > 32.
example : 2 * Nat.choose 32 10 < 2 ^ Nat.choose 10 2 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
-- The loose form at k = 10: 2^(1 + 10/2) = 64 and 10! = 3628800, so 64 < 3628800.
example : 2 ^ (1 + 10 / 2) = 64 ∧ Nat.factorial 10 = 3628800 ∧ 64 < 3628800 := by
  norm_num [Nat.factorial]
-- k = 3 for the clean fraction: 2^5 = 32 < 36 = (3!)^2; at k = 2 the fraction 2^2 / 2! = 2 is over 1.
example : 2 ^ 5 < (Nat.factorial 3) ^ 2 ∧ (Nat.factorial 3) ^ 2 = 36 := by decide
example : ¬ (2 ^ (1 + 2 / 2) < Nat.factorial 2) := by decide
-- The exact test clears 100 machines at k = 10 and fails at 101.
example : 2 * Nat.choose 100 10 < 2 ^ Nat.choose 10 2 := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
example : ¬ (2 * Nat.choose 101 10 < 2 ^ Nat.choose 10 2) := by
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]
-- The small bounds: K(4) with k = 4 gives 2, K(5) with k = 4 gives 160, K(5) with k = 3 gives 2560.
example : 2 * Nat.choose 4 4 * 2 ^ (Nat.choose 4 2 - Nat.choose 4 2) = 2 := by decide
example : 2 * Nat.choose 5 4 * 2 ^ (Nat.choose 5 2 - Nat.choose 4 2) = 160 := by decide
example : 2 * Nat.choose 5 3 * 2 ^ (Nat.choose 5 2 - Nat.choose 3 2) = 2560 := by decide
example : 2 ^ Nat.choose 4 2 = 64 ∧ 2 ^ Nat.choose 5 2 = 1024 := by decide
example : 1024 - 132 = 892 ∧ 1024 - 1012 = 12 := by decide
-- Rings on five labelled machines: 5!/(5 x 2) = 12.
example : Nat.factorial 5 / (5 * 2) = 12 := by decide
-- Ordered lists of ten: 32 x 31 x ... x 23 = 234102016512000 = 10! x C(32,10).
example : Nat.descFactorial 32 10 = 234102016512000 := by decide
example : Nat.descFactorial 32 10 = Nat.factorial 10 * Nat.choose 32 10 := by
  norm_num [Nat.descFactorial, Nat.factorial, Nat.choose_eq_factorial_div_factorial]
-- n = whole part of 2^(k/2) for k = 3 to 16, and the exact test passes at every one.
example : ∀ p ∈ List.zip (List.range' 3 14) [2, 4, 5, 8, 11, 16, 22, 32, 45, 64, 90, 128, 181, 256],
    p.2 ^ 2 ≤ 2 ^ p.1 ∧ 2 ^ p.1 < (p.2 + 1) ^ 2 := by decide
example : ∀ p ∈ List.zip (List.range' 3 14) [2, 4, 5, 8, 11, 16, 22, 32, 45, 64, 90, 128, 181, 256],
    2 * p.2.choose p.1 < 2 ^ p.1.choose 2 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial]; decide

#print axioms ramsey_diagonal_gt_two_pow_half
#print axioms bad_colourings_le
#print axioms good_colouring_of_two_mul_choose_lt
