-- Randomised experiments: when a lottery picks which visitors see page B, every visitor has the same chance n_B/N of landing in B, the gap between the arms' averages equals the average treatment effect when averaged over all lotteries, and its variance over all lotteries is S_B²/n_B + S_A²/n_A - S_τ²/N.
import Mathlib.Data.Finset.Powerset
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Fintype.Fin
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

lemma rab_card_superset {α : Type*} [DecidableEq α] (U T : Finset α) (hT : T ⊆ U) (n : ℕ)
    (hn : T.card ≤ n) :
    ((U.powersetCard n).filter (fun s => T ⊆ s)).card = (U.card - T.card).choose (n - T.card) := by
  rw [← card_sdiff_of_subset hT, ← card_powersetCard]
  apply card_nbij' (fun s => s \ T) (fun t => t ∪ T)
  · intro s hs
    simp only [coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at hs
    simp only [mem_coe, mem_powersetCard]
    refine ⟨sdiff_subset_sdiff hs.1.1 le_rfl, ?_⟩
    rw [card_sdiff_of_subset hs.2, hs.1.2]
  · intro t ht
    simp only [mem_coe, mem_powersetCard] at ht
    simp only [coe_filter, mem_powersetCard, Set.mem_ofPred_eq]
    have hd : Disjoint t T := by
      rw [disjoint_iff_ne]; intro a ha b hb hab; subst hab
      have := ht.1 ha; simp at this; exact this.2 hb
    refine ⟨⟨union_subset (fun x hx => (mem_sdiff.1 (ht.1 hx)).1) hT, ?_⟩, subset_union_right⟩
    rw [card_union_of_disjoint hd, ht.2]; omega
  · intro s hs
    simp only [coe_filter, mem_powersetCard, Set.mem_ofPred_eq] at hs
    exact sdiff_union_of_subset hs.2
  · intro t ht
    simp only [mem_coe, mem_powersetCard] at ht
    have hd : Disjoint t T := by
      rw [disjoint_iff_ne]; intro a ha b hb hab; subst hab
      have := ht.1 ha; simp at this; exact this.2 hb
    exact union_sdiff_cancel_right hd

lemma rab_card_one (N n : ℕ) (i : Fin N) :
    (((univ : Finset (Fin N)).powersetCard n).filter (fun s => i ∈ s)).card * N =
      ((univ : Finset (Fin N)).powersetCard n).card * n := by
  rcases n with _ | m
  · simp
  · have h := rab_card_superset (univ : Finset (Fin N)) {i} (subset_univ _) (m+1) (by simp)
    have e : ((univ : Finset (Fin N)).powersetCard (m+1)).filter (fun s => i ∈ s) =
        ((univ : Finset (Fin N)).powersetCard (m+1)).filter (fun s => {i} ⊆ s) := by
      simp
    rw [e, h, card_powersetCard]
    simp only [card_univ, Fintype.card_fin, card_singleton, Nat.add_sub_cancel]
    obtain ⟨M, rfl⟩ : ∃ M, N = M + 1 := ⟨N - 1, by have := i.2; omega⟩
    simp only [Nat.add_sub_cancel]
    rw [mul_comm]
    exact Nat.add_one_mul_choose_eq M m

lemma rab_card_two (N n : ℕ) (i j : Fin N) (hij : i ≠ j) :
    (((univ : Finset (Fin N)).powersetCard n).filter (fun s => i ∈ s ∧ j ∈ s)).card * (N * (N - 1)) =
      ((univ : Finset (Fin N)).powersetCard n).card * (n * (n - 1)) := by
  rcases n with _ | _ | m
  · simp
  · simp only [zero_add, Nat.sub_self, mul_zero, Nat.mul_eq_zero, card_eq_zero]
    left
    rw [filter_eq_empty_iff]
    intro s hs ⟨hi, hj⟩
    rw [mem_powersetCard, card_eq_one] at hs
    obtain ⟨a, rfl⟩ := hs.2
    simp at hi hj; exact hij (hi.trans hj.symm)
  · have hc : ({i, j} : Finset (Fin N)).card = 2 := card_pair hij
    have h := rab_card_superset (univ : Finset (Fin N)) {i, j} (subset_univ _) (m+2) (by omega)
    have e : ((univ : Finset (Fin N)).powersetCard (m+2)).filter (fun s => i ∈ s ∧ j ∈ s) =
        ((univ : Finset (Fin N)).powersetCard (m+2)).filter (fun s => {i, j} ⊆ s) := by
      apply filter_congr; intro s _; rw [insert_subset_iff, singleton_subset_iff]
    rw [e, h, card_powersetCard, hc]
    simp only [card_univ, Fintype.card_fin, Nat.add_sub_cancel]
    obtain ⟨M, rfl⟩ : ∃ M, N = M + 2 := by
      refine ⟨N - 2, ?_⟩
      have := i.2; have := j.2
      rcases Nat.lt_or_ge N 2 with h2 | h2
      · exfalso; apply hij; apply Fin.ext; omega
      · omega
    simp only [Nat.add_sub_cancel, show M + 2 - 1 = M + 1 by omega]
    have h1 := Nat.add_one_mul_choose_eq M m
    have h2 := Nat.add_one_mul_choose_eq (M+1) (m+1)
    calc M.choose m * ((M + 2) * (M + 1)) = (M+2) * ((M + 1) * M.choose m) := by ring
      _ = (M+2) * ((M+1).choose (m+1) * (m+1)) := by rw [h1]
      _ = ((M+2) * (M+1).choose (m+1)) * (m+1) := by ring
      _ = (M+2).choose (m+2) * (m+2) * (m+1) := by rw [h2]
      _ = _ := by ring

lemma rab_ind (N : ℕ) (f : Fin N → ℝ) (s : Finset (Fin N)) :
    ∑ i ∈ s, f i = ∑ i, if i ∈ s then f i else 0 := by
  rw [sum_ite_mem, univ_inter]

lemma rab_sum_one (N n : ℕ) (hN : (N : ℝ) ≠ 0) (f : Fin N → ℝ) :
    ∑ s ∈ (univ : Finset (Fin N)).powersetCard n, ∑ i ∈ s, f i =
      (((univ : Finset (Fin N)).powersetCard n).card : ℝ) * n / N * ∑ i, f i := by
  rw [sum_congr rfl (fun s _ => rab_ind N f s), sum_comm, mul_sum]
  apply sum_congr rfl
  intro i _
  rw [← sum_filter, sum_const, nsmul_eq_mul]
  congr 1
  rw [eq_div_iff hN]
  exact_mod_cast rab_card_one N n i

lemma rab_sum_two (N n : ℕ) (hN : (N : ℝ) ≠ 0) (hN1 : (N : ℝ) - 1 ≠ 0) (hn : 1 ≤ n)
    (f g : Fin N → ℝ) :
    ∑ s ∈ (univ : Finset (Fin N)).powersetCard n, (∑ i ∈ s, f i) * (∑ i ∈ s, g i) =
      (((univ : Finset (Fin N)).powersetCard n).card : ℝ) * n * (n - 1) / (N * (N - 1)) *
          ((∑ i, f i) * (∑ i, g i)) +
        ((((univ : Finset (Fin N)).powersetCard n).card : ℝ) * n / N -
          (((univ : Finset (Fin N)).powersetCard n).card : ℝ) * n * (n - 1) / (N * (N - 1))) *
          ∑ i, f i * g i := by
  set K : ℝ := (((univ : Finset (Fin N)).powersetCard n).card : ℝ) with hK
  set p : ℝ := K * n / N
  set q : ℝ := K * n * (n - 1) / (N * (N - 1))
  have hc : ∀ i j : Fin N,
      ((((univ : Finset (Fin N)).powersetCard n).filter (fun s => i ∈ s ∧ j ∈ s)).card : ℝ) =
        q + if i = j then p - q else 0 := by
    intro i j
    by_cases hij : i = j
    · subst hij
      simp only [and_self, ite_true, add_sub_cancel]
      rw [eq_div_iff hN, hK]
      exact_mod_cast rab_card_one N n i
    · simp only [hij, ite_false, add_zero]
      rw [eq_div_iff (mul_ne_zero hN hN1)]
      have h := rab_card_two N n i j hij
      have hN1' : 1 ≤ N := by
        by_contra h0; push Not at h0; interval_cases N; simp at hN
      have e : ((N * (N - 1) : ℕ) : ℝ) = (N : ℝ) * (N - 1) := by push_cast [hN1']; ring
      have e2 : ((n * (n - 1) : ℕ) : ℝ) = (n : ℝ) * (n - 1) := by push_cast [hn]; ring
      have h' : ((((univ : Finset (Fin N)).powersetCard n).filter
          (fun s => i ∈ s ∧ j ∈ s)).card : ℝ) * ((N * (N - 1) : ℕ) : ℝ) =
          K * ((n * (n - 1) : ℕ) : ℝ) := by rw [hK]; exact_mod_cast h
      rw [e, e2] at h'
      rw [h']; ring
  calc ∑ s ∈ (univ : Finset (Fin N)).powersetCard n, (∑ i ∈ s, f i) * (∑ i ∈ s, g i)
      = ∑ s ∈ (univ : Finset (Fin N)).powersetCard n, ∑ i, ∑ j,
          (if i ∈ s ∧ j ∈ s then f i * g j else 0) := by
        apply sum_congr rfl
        intro s _
        rw [rab_ind N f, rab_ind N g, sum_mul_sum]
        apply sum_congr rfl; intro i _; apply sum_congr rfl; intro j _
        by_cases hi : i ∈ s <;> by_cases hj : j ∈ s <;> simp [hi, hj]
    _ = ∑ i, ∑ j, ∑ s ∈ (univ : Finset (Fin N)).powersetCard n,
          (if i ∈ s ∧ j ∈ s then f i * g j else 0) := by
        rw [sum_comm]; apply sum_congr rfl; intro i _; rw [sum_comm]
    _ = ∑ i, ∑ j, (q + if i = j then p - q else 0) * (f i * g j) := by
        apply sum_congr rfl; intro i _; apply sum_congr rfl; intro j _
        rw [← sum_filter, sum_const, nsmul_eq_mul, hc]
    _ = q * ((∑ i, f i) * (∑ i, g i)) + (p - q) * ∑ i, f i * g i := by
        simp only [add_mul, sum_add_distrib, ite_mul, zero_mul, sum_ite_eq, mem_univ, ite_true]
        rw [sum_mul_sum, ← mul_sum, mul_sum]
        congr 1
        rw [mul_sum]; apply sum_congr rfl; intro i _; rw [mul_sum]

lemma rab_dev_sq (N : ℕ) (hN : (N : ℝ) ≠ 0) (y : Fin N → ℝ) :
    ∑ i, (y i - (∑ j, y j) / N) ^ 2 = ∑ i, y i * y i - (∑ i, y i) ^ 2 / N := by
  have h : ∀ i, (y i - (∑ j, y j) / N) ^ 2 =
      y i * y i - 2 * (∑ j, y j) / N * y i + (∑ j, y j) ^ 2 / N ^ 2 := by intro i; ring
  rw [sum_congr rfl (fun i _ => h i), sum_add_distrib, sum_sub_distrib, ← mul_sum, sum_const,
    card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp
  ring

lemma rab_card_ne (N n : ℕ) (h : n ≤ N) :
    (((univ : Finset (Fin N)).powersetCard n).card : ℝ) ≠ 0 := by
  rw [card_powersetCard, card_univ, Fintype.card_fin]
  exact_mod_cast (Nat.choose_pos h).ne'

#print axioms rab_card_superset
#print axioms rab_card_one
#print axioms rab_card_two
#print axioms rab_ind
#print axioms rab_sum_one
#print axioms rab_sum_two
#print axioms rab_dev_sq
#print axioms rab_card_ne

/-- **Assign by lottery and the gap is, on average, exactly the treatment effect.** Number the
visitors `0, …, N-1`. Visitor `i` would show outcome `yA i` on page A and `yB i` on page B (for a
purchase, 1 or 0); both are fixed before the test. A lottery picks the set `s` of visitors sent to
B, with exactly `nB` of them, so the other `nA = N - nB` go to A, and neither arm is empty. The
observed gap is B's average outcome minus A's:
`τ̂(s) = (∑_{i ∈ s} yB i)/nB - (∑_{i ∉ s} yA i)/nA`.
Averaged over all `C(N, nB)` equally likely lotteries, `τ̂` equals the average treatment effect
`τ = (1/N) ∑_i (yB i - yA i)`. -/
theorem lottery_gap_averages_to_average_treatment_effect
    (N nA nB : ℕ) (hN : nA + nB = N) (hA : 1 ≤ nA) (hB : 1 ≤ nB) (yA yB : Fin N → ℝ) :
    let S := (univ : Finset (Fin N)).powersetCard nB
    let gap := fun s : Finset (Fin N) => (∑ i ∈ s, yB i) / nB - (∑ i ∈ sᶜ, yA i) / nA
    (∑ s ∈ S, gap s) / S.card = (∑ i, (yB i - yA i)) / N := by
  intro S gap
  have hK : (S.card : ℝ) ≠ 0 := rab_card_ne N nB (by omega)
  have hNr : (N : ℝ) = nA + nB := by rw [← hN]; push_cast; ring
  have hN0 : (N : ℝ) ≠ 0 := by rw [hNr]; positivity
  have hA1 : (1 : ℝ) ≤ nA := by exact_mod_cast hA
  have hB1 : (1 : ℝ) ≤ nB := by exact_mod_cast hB
  have hA0 : (nA : ℝ) ≠ 0 := by linarith
  have hB0 : (nB : ℝ) ≠ 0 := by linarith
  have hgap : ∀ s, gap s = (∑ i ∈ s, yB i) / nB - ((∑ i, yA i) - ∑ i ∈ s, yA i) / nA := by
    intro s; simp only [gap]; rw [← sum_compl_add_sum s yA]; ring
  rw [sum_congr rfl (fun s _ => hgap s), sum_sub_distrib, ← sum_div, ← sum_div, sum_sub_distrib,
    sum_const, nsmul_eq_mul, rab_sum_one N nB hN0, rab_sum_one N nB hN0, sum_sub_distrib]
  generalize (S.card : ℝ) = K at *
  generalize ∑ i, yA i = a
  generalize ∑ i, yB i = b
  rw [hNr] at hN0 ⊢
  field_simp
  ring

/-- **Neyman's variance over all lotteries.** Same setting. Write `S_A²`, `S_B²` and `S_τ²` for the
spreads, with divisor `N - 1`, of the column of A outcomes, the column of B outcomes, and the column
of individual effects `yB i - yA i`. Over all `C(N, nB)` equally likely lotteries, the variance of
the observed gap `τ̂` is exactly `S_B²/nB + S_A²/nA - S_τ²/N`. -/
theorem lottery_gap_variance_eq_neyman
    (N nA nB : ℕ) (hN : nA + nB = N) (hA : 1 ≤ nA) (hB : 1 ≤ nB) (yA yB : Fin N → ℝ) :
    let S := (univ : Finset (Fin N)).powersetCard nB
    let gap := fun s : Finset (Fin N) => (∑ i ∈ s, yB i) / nB - (∑ i ∈ sᶜ, yA i) / nA
    let mean := (∑ s ∈ S, gap s) / S.card
    let spread := fun y : Fin N → ℝ => (∑ i, (y i - (∑ j, y j) / N) ^ 2) / (N - 1)
    (∑ s ∈ S, (gap s - mean) ^ 2) / S.card =
      spread yB / nB + spread yA / nA - spread (fun i => yB i - yA i) / N := by
  intro S gap mean spread
  have hmean : mean = (∑ i, (yB i - yA i)) / N :=
    lottery_gap_averages_to_average_treatment_effect N nA nB hN hA hB yA yB
  have hK : (S.card : ℝ) ≠ 0 := rab_card_ne N nB (by omega)
  have hNr : (N : ℝ) = nA + nB := by rw [← hN]; push_cast; ring
  have hA1 : (1 : ℝ) ≤ nA := by exact_mod_cast hA
  have hB1 : (1 : ℝ) ≤ nB := by exact_mod_cast hB
  have hN0 : (N : ℝ) ≠ 0 := by rw [hNr]; positivity
  have hN1 : (N : ℝ) - 1 ≠ 0 := by rw [hNr]; intro h; linarith
  have hA0 : (nA : ℝ) ≠ 0 := by linarith
  have hB0 : (nB : ℝ) ≠ 0 := by linarith
  have hsq : ∀ s : Finset (Fin N), (gap s - mean) ^ 2 =
      1 / nB ^ 2 * ((∑ i ∈ s, yB i) * (∑ i ∈ s, yB i)) +
      1 / nA ^ 2 * ((∑ i ∈ s, yA i) * (∑ i ∈ s, yA i)) +
      2 / (nA * nB) * ((∑ i ∈ s, yB i) * (∑ i ∈ s, yA i)) +
      (-2 * ((∑ i, yA i) / nA + mean) / nB) * (∑ i ∈ s, yB i) +
      (-2 * ((∑ i, yA i) / nA + mean) / nA) * (∑ i ∈ s, yA i) +
      ((∑ i, yA i) / nA + mean) ^ 2 := by
    intro s; simp only [gap]; rw [← sum_compl_add_sum s yA]; field_simp; ring
  rw [sum_congr rfl (fun s _ => hsq s)]
  simp only [sum_add_distrib, ← mul_sum, sum_const, nsmul_eq_mul]
  rw [rab_sum_two N nB hN0 hN1 hB, rab_sum_two N nB hN0 hN1 hB, rab_sum_two N nB hN0 hN1 hB,
    rab_sum_one N nB hN0, rab_sum_one N nB hN0]
  simp only [spread]
  rw [rab_dev_sq N hN0, rab_dev_sq N hN0, rab_dev_sq N hN0, hmean]
  have e1 : ∑ i, (yB i - yA i) * (yB i - yA i) =
      ∑ i, yB i * yB i - 2 * ∑ i, yB i * yA i + ∑ i, yA i * yA i := by
    rw [mul_sum, ← sum_sub_distrib, ← sum_add_distrib]
    apply sum_congr rfl; intro i _; ring
  rw [e1, sum_sub_distrib]
  generalize (S.card : ℝ) = K at *
  generalize ∑ i, yA i = a
  generalize ∑ i, yB i = b
  generalize ∑ i, yA i * yA i = aa
  generalize ∑ i, yB i * yB i = bb
  generalize ∑ i, yB i * yA i = ab
  rw [hNr] at hN0 hN1 ⊢
  field_simp
  ring

/-- **Every visitor has the same chance `nB/N` of landing in B.** Same lottery: of the `C(N, nB)`
equally likely ways to choose arm B, the share that put a given visitor `i` in B is exactly
`nB/N`, whoever that visitor is. -/
theorem every_visitor_lands_in_B_with_chance_nB_over_N
    (N nA nB : ℕ) (hN : nA + nB = N) (hA : 1 ≤ nA) (hB : 1 ≤ nB) (i : Fin N) :
    let S := (univ : Finset (Fin N)).powersetCard nB
    ((S.filter (fun s => i ∈ s)).card : ℚ) / S.card = nB / N := by
  intro S
  have hK : (S.card : ℚ) ≠ 0 := by
    simp only [S]; rw [card_powersetCard, card_univ, Fintype.card_fin]
    exact_mod_cast (Nat.choose_pos (by omega : nB ≤ N)).ne'
  have hN0 : (N : ℚ) ≠ 0 := by exact_mod_cast (by omega : N ≠ 0)
  rw [div_eq_div_iff hK hN0, mul_comm (nB : ℚ)]
  exact_mod_cast rab_card_one N nB i

-- The 8-visitor table with 4 slots in B: 70 possible lotteries, and 35 of them put visitor 1 in B.
example : ((univ : Finset (Fin 8)).powersetCard 4).card = 70 := by decide
example : (((univ : Finset (Fin 8)).powersetCard 4).filter (fun s => (0 : Fin 8) ∈ s)).card = 35 := by
  decide
-- On that table (A column 1,0,0,1,0,0,0,0; B column 1,1,1,0,0,0,0,0), 4 × gap = (B buyers) - (A buyers)
-- adds up to 35 over the 70 lotteries, so the average gap is 35/(4 × 70) = 1/8 (0.1250) = τ = (3 - 2)/8.
example :
    (∑ s ∈ (univ : Finset (Fin 8)).powersetCard 4,
      ((∑ i ∈ s, (![1, 1, 1, 0, 0, 0, 0, 0] : Fin 8 → ℤ) i) -
        ∑ i ∈ sᶜ, (![1, 0, 0, 1, 0, 0, 0, 0] : Fin 8 → ℤ) i)) = 35 := by
  decide
example : (35 : ℚ) / (4 * 70) = 1 / 8 ∧ ((3 : ℚ) - 2) / 8 = 1 / 8 := by norm_num
-- The squares of 4 × gap add up to 95, so the variance over all 70 lotteries is
-- 95/(16 × 70) - (1/8)² = 31/448 (0.069196).
example :
    (∑ s ∈ (univ : Finset (Fin 8)).powersetCard 4,
      ((∑ i ∈ s, (![1, 1, 1, 0, 0, 0, 0, 0] : Fin 8 → ℤ) i) -
        ∑ i ∈ sᶜ, (![1, 0, 0, 1, 0, 0, 0, 0] : Fin 8 → ℤ) i) ^ 2) = 95 := by
  decide
example : (95 : ℚ) / (16 * 70) - (1 / 8) ^ 2 = 31 / 448 := by norm_num
-- Neyman's formula on that table: S_A² = 3/14, S_B² = 15/56, S_τ² = 23/56, and
-- S_B²/4 + S_A²/4 - S_τ²/8 = 31/448 (0.069196), the same number.
example : (15 / 56 : ℚ) / 4 + (3 / 14) / 4 - (23 / 56) / 8 = 31 / 448 := by norm_num
-- The model shop: 900 always buy, 260 are won by B, 100 are lost by B, 18,740 never buy: 20,000 visitors.
example : 900 + 260 + 100 + 18740 = 20000 := by decide
-- Its true effect: (1,160 - 1,000)/20,000 = 1/125 (0.0080).
example : ((900 + 260 : ℚ) - (900 + 100)) / 20000 = 1 / 125 := by norm_num
-- The observed test: 580/10,000 - 500/10,000 = 1/125 (0.0080); pooled rate 1,080/20,000 = 27/500 (0.0540).
example : (580 : ℚ) / 10000 - 500 / 10000 = 1 / 125 ∧ (500 + 580 : ℚ) / 20000 = 27 / 500 := by
  norm_num
-- B shown only to the 4,000 returning visitors (760 buy on B) and A to the 16,000 new ones (280 buy on A):
-- gap 760/4000 - 280/16000 = 69/400 (0.1725). The reverse: 400/16000 - 720/4000 = -31/200 (-0.1550).
example : (760 : ℚ) / 4000 - 280 / 16000 = 69 / 400 ∧ (400 : ℚ) / 16000 - 720 / 4000 = -31 / 200 := by
  norm_num

#print axioms lottery_gap_averages_to_average_treatment_effect
#print axioms lottery_gap_variance_eq_neyman
#print axioms every_visitor_lands_in_B_with_chance_nB_over_N
