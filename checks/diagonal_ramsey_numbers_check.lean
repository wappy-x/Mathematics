-- Diagonal Ramsey numbers: for every k ≥ 3, any red/blue colouring of the lines among C(2k − 2, k − 1) or more dots has k dots joined all in one colour, that number is below 4^k, at most 2^(k/2) dots can always dodge, and R(3, 3) = 6.
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Push
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Data.Nat.Choose.Bounds
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring.Finset

/-! A red/blue colouring of every line of K(n) is a graph `G` on the dots: its edges are the red
lines and the edges of its complement `Gᶜ` are the blue lines. A one-colour K(k) is a k-clique of
`G` or of `Gᶜ`, so "no one-colour K(k)" is `G.CliqueFree k ∧ Gᶜ.CliqueFree k`. -/

open Finset in
theorem ramsey_finset_aux {V : Type} (G : SimpleGraph V) :
    ∀ s t : ℕ, ∀ A : Finset V, Nat.choose (s + t) s ≤ A.card →
      (∃ X ⊆ A, G.IsNClique (s + 1) X) ∨ (∃ Y ⊆ A, Gᶜ.IsNClique (t + 1) Y) := by
  classical
  intro s
  induction s with
  | zero =>
    intro t A hA
    rw [Nat.choose_zero_right] at hA
    obtain ⟨a, ha⟩ : A.Nonempty := Finset.card_pos.1 (by omega)
    exact Or.inl ⟨{a}, by simpa using ha, by simp [SimpleGraph.isNClique_singleton]⟩
  | succ s ihs =>
    intro t
    induction t with
    | zero =>
      intro A hA
      rw [Nat.add_zero, Nat.choose_self] at hA
      obtain ⟨a, ha⟩ : A.Nonempty := Finset.card_pos.1 (by omega)
      exact Or.inr ⟨{a}, by simpa using ha, by simp [SimpleGraph.isNClique_singleton]⟩
    | succ t iht =>
      intro A hA
      have hpos : 0 < A.card := lt_of_lt_of_le (Nat.choose_pos (by omega)) hA
      obtain ⟨v, hv⟩ := Finset.card_pos.1 hpos
      set N := (A.erase v).filter (fun w => G.Adj v w) with hN
      set M := (A.erase v).filter (fun w => ¬ G.Adj v w) with hM
      have hNM : N.card + M.card = A.card - 1 := by
        rw [hN, hM, Finset.card_filter_add_card_filter_not, Finset.card_erase_of_mem hv]
      have hsplit : Nat.choose (s + 1 + (t + 1)) (s + 1) =
          Nat.choose (s + (t + 1)) s + Nat.choose (s + 1 + t) (s + 1) := by
        rw [show s + 1 + (t + 1) = (s + t + 1) + 1 by omega, Nat.choose_succ_succ,
          show s + (t + 1) = s + t + 1 by omega, show s + 1 + t = s + t + 1 by omega]
      have hNA : N ⊆ A := fun w hw => Finset.mem_of_mem_erase (Finset.mem_filter.1 hw).1
      have hMA : M ⊆ A := fun w hw => Finset.mem_of_mem_erase (Finset.mem_filter.1 hw).1
      by_cases hc : Nat.choose (s + (t + 1)) s ≤ N.card
      · rcases ihs (t + 1) N hc with ⟨X, hXN, hX⟩ | ⟨Y, hYN, hY⟩
        · refine Or.inl ⟨insert v X, Finset.insert_subset hv (hXN.trans hNA), hX.insert ?_⟩
          intro b hb
          exact (Finset.mem_filter.1 (hXN hb)).2
        · exact Or.inr ⟨Y, hYN.trans hNA, hY⟩
      · have hc' : Nat.choose (s + 1 + t) (s + 1) ≤ M.card := by omega
        rcases iht M hc' with ⟨X, hXM, hX⟩ | ⟨Y, hYM, hY⟩
        · exact Or.inl ⟨X, hXM.trans hMA, hX⟩
        · refine Or.inr ⟨insert v Y, Finset.insert_subset hv (hYM.trans hMA), hY.insert ?_⟩
          intro b hb
          have hb' := Finset.mem_filter.1 (hYM hb)
          rw [SimpleGraph.compl_adj]
          exact ⟨(Finset.ne_of_mem_erase hb'.1).symm, hb'.2⟩


open Finset in
theorem erdos_count_aux (k n : ℕ) (h : 2 * n.choose k < 2 ^ k.choose 2) :
    ∃ G : SimpleGraph (Fin n), G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  classical
  set U : Finset (Finset (Fin n)) := powersetCard 2 univ with hU
  let T : Finset (Fin n) → Finset (Finset (Fin n)) := fun s => powersetCard 2 s
  let bad : Finset (Fin n) → Finset (Finset (Finset (Fin n))) := fun s =>
    U.powerset.filter (fun S => T s ⊆ S) ∪ U.powerset.filter (fun S => Disjoint (T s) S)
  let Bad := (powersetCard k (univ : Finset (Fin n))).biUnion bad
  have hbad : ∀ s ∈ powersetCard k (univ : Finset (Fin n)),
      (bad s).card * 2 ^ k.choose 2 ≤ 2 * 2 ^ U.card := by
    intro s hs
    rw [mem_powersetCard] at hs
    have hTU : T s ⊆ U := powersetCard_mono (subset_univ _)
    have hTc : (T s).card = k.choose 2 := by
      simp only [T]; rw [card_powersetCard, hs.2]
    have h1 : (U.powerset.filter (fun S => T s ⊆ S)).card ≤ 2 ^ (U \ T s).card := by
      rw [← card_powerset]
      refine card_le_card_of_injOn (fun S => S \ T s) ?_ ?_
      · intro S hS
        simp only [coe_filter, mem_powerset, Set.mem_ofPred_eq] at hS
        simp only [coe_powerset, Set.mem_preimage, Set.mem_powerset_iff, coe_subset]
        exact sdiff_subset_sdiff hS.1 le_rfl
      · intro S1 hS1 S2 hS2 heq
        simp only [coe_filter, mem_powerset, Set.mem_ofPred_eq] at hS1 hS2
        have e1 : S1 = (S1 \ T s) ∪ T s := (sdiff_union_of_subset hS1.2).symm
        have e2 : S2 = (S2 \ T s) ∪ T s := (sdiff_union_of_subset hS2.2).symm
        rw [e1, e2]
        simp only at heq
        rw [heq]
    have h2 : (U.powerset.filter (fun S => Disjoint (T s) S)).card ≤ 2 ^ (U \ T s).card := by
      rw [← card_powerset]
      apply card_le_card
      intro S hS
      simp only [mem_filter, mem_powerset] at hS ⊢
      exact subset_sdiff.2 ⟨hS.1, hS.2.symm⟩
    have hle : (T s).card ≤ U.card := card_le_card hTU
    have h3 : 2 ^ (U \ T s).card * 2 ^ k.choose 2 = 2 ^ U.card := by
      rw [← pow_add, card_sdiff_of_subset hTU, hTc]
      congr 1
      omega
    calc (bad s).card * 2 ^ k.choose 2
        ≤ (2 ^ (U \ T s).card + 2 ^ (U \ T s).card) * 2 ^ k.choose 2 :=
          Nat.mul_le_mul_right _ ((card_union_le _ _).trans (add_le_add h1 h2))
      _ = 2 * 2 ^ U.card := by rw [← h3]; ring
  have hBad : Bad.card < U.powerset.card := by
    rw [card_powerset]
    have hsum : Bad.card * 2 ^ k.choose 2 ≤ n.choose k * (2 * 2 ^ U.card) := by
      calc Bad.card * 2 ^ k.choose 2
          ≤ (∑ s ∈ powersetCard k (univ : Finset (Fin n)), (bad s).card) * 2 ^ k.choose 2 :=
            Nat.mul_le_mul_right _ card_biUnion_le
        _ = ∑ s ∈ powersetCard k (univ : Finset (Fin n)), (bad s).card * 2 ^ k.choose 2 :=
            sum_mul _ _ _
        _ ≤ ∑ s ∈ powersetCard k (univ : Finset (Fin n)), 2 * 2 ^ U.card := sum_le_sum hbad
        _ = n.choose k * (2 * 2 ^ U.card) := by
            rw [sum_const, card_powersetCard, card_univ, Fintype.card_fin, smul_eq_mul]
    have h4 : n.choose k * (2 * 2 ^ U.card) < 2 ^ k.choose 2 * 2 ^ U.card := by
      rw [← mul_assoc, mul_comm (n.choose k) 2]
      exact Nat.mul_lt_mul_of_pos_right h (by positivity)
    by_contra hc
    push Not at hc
    have h5 := Nat.mul_le_mul_right (2 ^ k.choose 2) hc
    nlinarith
  obtain ⟨S, hSU, hSnot⟩ : ∃ S ∈ U.powerset, S ∉ Bad := by
    by_contra hc
    push Not at hc
    exact absurd (card_le_card (show U.powerset ⊆ Bad from hc)) (not_le.2 hBad)
  let G : SimpleGraph (Fin n) := SimpleGraph.fromRel (fun a b => ({a, b} : Finset (Fin n)) ∈ S)
  refine ⟨G, ?_, ?_⟩
  · intro X hX
    apply hSnot
    rw [mem_biUnion]
    refine ⟨X, mem_powersetCard.2 ⟨subset_univ _, hX.2⟩,
      mem_union_left _ (mem_filter.2 ⟨hSU, ?_⟩)⟩
    intro p hp
    rw [mem_powersetCard, card_eq_two] at hp
    obtain ⟨hpX, a, b, hab, rfl⟩ := hp
    have hadj : G.Adj a b := hX.1 (hpX (by simp)) (hpX (by simp)) hab
    simp only [G, SimpleGraph.fromRel_adj] at hadj
    rcases hadj.2 with h' | h'
    · exact h'
    · rwa [pair_comm]
  · intro X hX
    apply hSnot
    rw [mem_biUnion]
    refine ⟨X, mem_powersetCard.2 ⟨subset_univ _, hX.2⟩,
      mem_union_right _ (mem_filter.2 ⟨hSU, ?_⟩)⟩
    rw [disjoint_left]
    intro p hp hpS
    rw [mem_powersetCard, card_eq_two] at hp
    obtain ⟨hpX, a, b, hab, rfl⟩ := hp
    have hadj : Gᶜ.Adj a b := hX.1 (hpX (by simp)) (hpX (by simp)) hab
    rw [SimpleGraph.compl_adj] at hadj
    exact hadj.2 (by simp only [G, SimpleGraph.fromRel_adj]; exact ⟨hab, Or.inl hpS⟩)

theorem two_mul_choose_two_add (k : ℕ) : 2 * k.choose 2 + k = k * k := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Nat.choose_succ_succ, Nat.choose_one_right]
    nlinarith

theorem two_pow_lt_factorial_sq (k : ℕ) (hk : 3 ≤ k) : 2 ^ (k + 2) < (k.factorial) ^ 2 := by
  induction k, hk using Nat.le_induction with
  | base => decide
  | succ k hk ih =>
    rw [Nat.factorial_succ, mul_pow, pow_succ]
    have : 2 ≤ (k + 1) ^ 2 := by nlinarith
    nlinarith

theorem erdos_numeric (k : ℕ) (hk : 3 ≤ k) (n : ℕ) (hn : n ^ 2 ≤ 2 ^ k) :
    2 * n.choose k < 2 ^ k.choose 2 := by
  set c := n.choose k
  set F := k.factorial
  set C := k.choose 2
  have hF : 0 < F := Nat.factorial_pos k
  have e1 : 2 * c * F ≤ 2 * n ^ k := by
    have := Nat.descFactorial_le_pow n k
    rw [Nat.descFactorial_eq_factorial_mul_choose] at this
    nlinarith
  have e2 : (2 * n ^ k) ^ 2 ≤ 4 * 2 ^ (k * k) := by
    have : (n ^ 2) ^ k ≤ (2 ^ k) ^ k := Nat.pow_le_pow_left hn k
    rw [← pow_mul, ← pow_mul] at this
    calc (2 * n ^ k) ^ 2 = 4 * n ^ (k * 2) := by ring
      _ ≤ 4 * 2 ^ (k * k) := by rw [mul_comm k 2]; exact Nat.mul_le_mul_left 4 this
  have e3 : 4 * 2 ^ (k * k) < (2 ^ C * F) ^ 2 := by
    have hC := two_mul_choose_two_add k
    have hf := two_pow_lt_factorial_sq k hk
    calc 4 * 2 ^ (k * k) = 2 ^ (2 * C) * 2 ^ (k + 2) := by
          rw [← pow_add, show 2 * C + (k + 2) = k * k + 2 by omega, pow_add]; ring
      _ < 2 ^ (2 * C) * F ^ 2 := Nat.mul_lt_mul_of_pos_left hf (by positivity)
      _ = (2 ^ C * F) ^ 2 := by rw [mul_pow, ← pow_mul, mul_comm C 2]
  have e4 : (2 * c * F) ^ 2 < (2 ^ C * F) ^ 2 :=
    lt_of_le_of_lt (Nat.pow_le_pow_left e1 2) (lt_of_le_of_lt e2 e3)
  have e5 : 2 * c * F < 2 ^ C * F := lt_of_pow_lt_pow_left₀ 2 (by positivity) e4
  exact Nat.lt_of_mul_lt_mul_right e5

theorem c5_ok : (SimpleGraph.cycleGraph 5).CliqueFree 3 ∧ (SimpleGraph.cycleGraph 5)ᶜ.CliqueFree 3 := by
  rw [← SimpleGraph.cliqueFinset_eq_empty_iff, ← SimpleGraph.cliqueFinset_eq_empty_iff]
  decide

#print axioms ramsey_finset_aux
#print axioms erdos_count_aux
#print axioms two_mul_choose_two_add
#print axioms two_pow_lt_factorial_sq
#print axioms erdos_numeric
#print axioms c5_ok

/-- The classical ceiling (Erdős and Szekeres, 1935): for every k ≥ 3, every red/blue colouring of
the lines among n dots, with n at least C(2k − 2, k − 1), has k dots whose lines are all one colour,
so R(k, k) ≤ C(2k − 2, k − 1); and C(2k − 2, k − 1) is below 4^k. -/
theorem diagonal_ramsey_le_choose_lt_four_pow (k : ℕ) (hk : 3 ≤ k) :
    Nat.choose (2 * k - 2) (k - 1) < 4 ^ k ∧
      ∀ (V : Type) [Fintype V], Nat.choose (2 * k - 2) (k - 1) ≤ Fintype.card V →
        ∀ G : SimpleGraph V, ¬ (G.CliqueFree k ∧ Gᶜ.CliqueFree k) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 1 := ⟨k - 1, by omega⟩
  refine ⟨?_, ?_⟩
  · rw [show 2 * (j + 1) - 2 = 2 * j by omega, show j + 1 - 1 = j by omega]
    calc Nat.choose (2 * j) j ≤ 2 ^ (2 * j) := Nat.choose_le_two_pow _ _
      _ = 4 ^ j := by rw [pow_mul]; norm_num
      _ < 4 ^ (j + 1) := Nat.pow_lt_pow_right (by norm_num) (by omega)
  · intro V _ hcard G hG
    rw [show 2 * (j + 1) - 2 = j + j by omega, show j + 1 - 1 = j by omega] at hcard
    rcases ramsey_finset_aux G j j Finset.univ (by rwa [Finset.card_univ]) with
      ⟨X, -, hX⟩ | ⟨Y, -, hY⟩
    · exact hG.1 X hX
    · exact hG.2 Y hY

/-- The classical floor (Erdős, 1947): for every k ≥ 3, R(k, k) > 2^(k/2). That is, for every
number of dots n with n ≤ 2^(k/2), written n² ≤ 2^k, some red/blue colouring of the lines among
the n dots has no k dots joined all in one colour. -/
theorem diagonal_ramsey_gt_two_pow_half (k : ℕ) (hk : 3 ≤ k) (n : ℕ) (hn : n ^ 2 ≤ 2 ^ k) :
    ∃ G : SimpleGraph (Fin n), G.CliqueFree k ∧ Gᶜ.CliqueFree k := by
  exact erdos_count_aux k n (erdos_numeric k hk n hn)

/-- R(3, 3) = 6: every red/blue colouring of the lines among 6 dots has a one-colour triangle, and
some colouring of the lines among 5 dots has none. -/
theorem ramsey_three_three_eq_six :
    (∀ G : SimpleGraph (Fin 6), ¬ (G.CliqueFree 3 ∧ Gᶜ.CliqueFree 3)) ∧
      ∃ G : SimpleGraph (Fin 5), G.CliqueFree 3 ∧ Gᶜ.CliqueFree 3 := by
  refine ⟨fun G hG => ?_, SimpleGraph.cycleGraph 5, c5_ok⟩
  rcases ramsey_finset_aux G 2 2 Finset.univ (by decide) with ⟨X, -, hX⟩ | ⟨Y, -, hY⟩
  · exact hG.1 X hX
  · exact hG.2 Y hY

/-! The card's whole-number examples. -/

-- 43 dots have C(43, 2) = 903 lines.
example : Nat.choose 43 2 = 903 := by decide

-- The ceiling at k = 5: C(8, 4) = 8 · 7 · 6 · 5 / 24 = 70.
example : Nat.choose 8 4 = 70 ∧ 8 * 7 * 6 * 5 / 24 = 70 := by decide

-- The exact count at k = 5: 2 × C(11, 5) = 924 < 1,024 = 2^C(5, 2) ≤ 1,584 = 2 × C(12, 5), so R(5, 5) > 11.
example : 2 * Nat.choose 11 5 = 924 ∧ 2 ^ Nat.choose 5 2 = 1024 ∧ 2 * Nat.choose 12 5 = 1584 ∧
    2 * Nat.choose 11 5 < 2 ^ Nat.choose 5 2 ∧ 2 ^ Nat.choose 5 2 ≤ 2 * Nat.choose 12 5 := by
  decide

-- The clean floor at k = 5: 5² ≤ 2^5 < 6², so 2^(5/2) lies between 5 and 6.
example : 5 ^ 2 ≤ 2 ^ 5 ∧ 2 ^ 5 < 6 ^ 2 := by norm_num

-- Mistake 3: 4^5 = 1,024, against C(8, 4) = 70.
example : 4 ^ 5 = 1024 := by norm_num

-- The table's ceiling column C(2k − 2, k − 1) and 4^(k − 1), for k = 3 to 10.
example : Nat.choose 4 2 = 6 ∧ Nat.choose 6 3 = 20 ∧ Nat.choose 10 5 = 252 ∧
    Nat.choose 12 6 = 924 ∧ Nat.choose 14 7 = 3432 ∧ Nat.choose 16 8 = 12870 ∧
    Nat.choose 18 9 = 48620 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial, and_self]
example : 4 ^ 2 = 16 ∧ 4 ^ 3 = 64 ∧ 4 ^ 4 = 256 ∧ 4 ^ 5 = 1024 ∧ 4 ^ 6 = 4096 ∧
    4 ^ 7 = 16384 ∧ 4 ^ 8 = 65536 ∧ 4 ^ 9 = 262144 := by norm_num

-- The table's count floor column: the largest n with 2 × C(n, k) < 2^C(k, 2) is
-- 3, 6, 11, 17, 27, 42, 65, 100 for k = 3 to 10.
example : 2 * Nat.choose 3 3 < 2 ^ Nat.choose 3 2 ∧ ¬ 2 * Nat.choose 4 3 < 2 ^ Nat.choose 3 2 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]; norm_num
example : 2 * Nat.choose 100 10 < 2 ^ Nat.choose 10 2 ∧
    ¬ 2 * Nat.choose 101 10 < 2 ^ Nat.choose 10 2 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]; norm_num

-- k = 100: the floor 2^50 = 1,125,899,906,842,624, and 2^50 < C(198, 99) < 4^100 = 2^200.
example : 2 ^ 50 = 1125899906842624 := by norm_num
example : 2 ^ 50 < Nat.choose 198 99 ∧ Nat.choose 198 99 < 4 ^ 100 ∧ 4 ^ 100 = 2 ^ 200 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]; norm_num

-- Groups the Paley checks count: C(17, 4) = 2,380 and C(37, 5) = 435,897.
example : Nat.choose 17 4 = 2380 ∧ Nat.choose 37 5 = 435897 := by
  simp only [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial, and_self]

#print axioms diagonal_ramsey_le_choose_lt_four_pow
#print axioms diagonal_ramsey_gt_two_pow_half
#print axioms ramsey_three_three_eq_six
