-- Weyl's law: on a square, the clamped and free mode counts lie within 2ℓ + 1 of the quarter-circle area πℓ²/4, the free count is the clamped count plus the 2⌊ℓ⌋ + 1 points on the axes, and either count divided by λ tends to the square's area over 4π.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SumIntegralComparisons
import Mathlib.Data.Set.Card
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum

open Real Filter Topology

lemma weyl_integral_unit_quarter : ∫ x in (0:ℝ)..1, √(1 - x ^ 2) = π / 4 := by
  have hc : Continuous fun x : ℝ => √(1 - x ^ 2) := by fun_prop
  have hsplit := intervalIntegral.integral_add_adjacent_intervals
    (hc.intervalIntegrable (μ := MeasureTheory.volume) (-1) 0) (hc.intervalIntegrable (μ := MeasureTheory.volume) 0 1)
  rw [integral_sqrt_one_sub_sq] at hsplit
  have hneg : ∫ x in (-1:ℝ)..0, √(1 - x ^ 2) = ∫ x in (0:ℝ)..1, √(1 - x ^ 2) := by
    have := intervalIntegral.integral_comp_neg (a := (-1:ℝ)) (b := 0) (fun x : ℝ => √(1 - x ^ 2))
    simp only [neg_sq, neg_zero, neg_neg] at this
    exact this
  linarith

#print axioms weyl_integral_unit_quarter

lemma weyl_integral_quarter_disc (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    ∫ x in (0:ℝ)..ℓ, √(ℓ ^ 2 - x ^ 2) = π * ℓ ^ 2 / 4 := by
  rcases hℓ.eq_or_lt with h | h
  · subst h; simp
  have hpt : ∀ x : ℝ, √(ℓ ^ 2 - x ^ 2) = ℓ * √(1 - (x / ℓ) ^ 2) := by
    intro x
    have : ℓ ^ 2 - x ^ 2 = ℓ ^ 2 * (1 - (x / ℓ) ^ 2) := by field_simp
    rw [this, Real.sqrt_mul (by positivity), Real.sqrt_sq h.le]
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul,
    intervalIntegral.integral_comp_div (fun t : ℝ => √(1 - t ^ 2)) h.ne']
  rw [zero_div, div_self h.ne', weyl_integral_unit_quarter, smul_eq_mul]
  ring

#print axioms weyl_integral_quarter_disc

lemma weyl_nat_le_floor_of_sq (ℓ : ℝ) (hℓ : 0 ≤ ℓ) (a : ℕ) (h : (a : ℝ) ^ 2 ≤ ℓ ^ 2) :
    a ≤ ⌊ℓ⌋₊ := by
  apply Nat.le_floor
  have ha : (0:ℝ) ≤ a := Nat.cast_nonneg a
  nlinarith

#print axioms weyl_nat_le_floor_of_sq

lemma weyl_free_set_eq (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    {p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2} =
      ↑((Finset.range (⌊ℓ⌋₊ + 1) ×ˢ Finset.range (⌊ℓ⌋₊ + 1)).filter
        (fun p : ℕ × ℕ => (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2)) := by
  ext p
  simp only [Set.mem_ofPred_eq, Finset.coe_filter, Finset.mem_product, Finset.mem_range]
  constructor
  · intro h
    refine ⟨⟨?_, ?_⟩, h⟩
    · exact Nat.lt_succ_of_le (weyl_nat_le_floor_of_sq ℓ hℓ _ (by nlinarith))
    · exact Nat.lt_succ_of_le (weyl_nat_le_floor_of_sq ℓ hℓ _ (by nlinarith))
  · exact fun h => h.2

#print axioms weyl_free_set_eq

lemma weyl_clamped_set_eq (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    {p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2} =
      ↑((Finset.range (⌊ℓ⌋₊ + 1) ×ˢ Finset.range (⌊ℓ⌋₊ + 1)).filter
        (fun p : ℕ × ℕ => 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2)) := by
  ext p
  simp only [Set.mem_ofPred_eq, Finset.coe_filter, Finset.mem_product, Finset.mem_range]
  constructor
  · intro h
    refine ⟨⟨?_, ?_⟩, h⟩
    · exact Nat.lt_succ_of_le (weyl_nat_le_floor_of_sq ℓ hℓ _ (by nlinarith [h.2.2]))
    · exact Nat.lt_succ_of_le (weyl_nat_le_floor_of_sq ℓ hℓ _ (by nlinarith [h.2.2]))
  · exact fun h => h.2

#print axioms weyl_clamped_set_eq

lemma weyl_card_filter_product (s t : Finset ℕ) (R : ℕ × ℕ → Prop) [DecidablePred R] :
    ((s ×ˢ t).filter R).card = ∑ a ∈ s, (t.filter (fun b => R (a, b))).card := by
  rw [Finset.card_filter, Finset.sum_product]
  refine Finset.sum_congr rfl fun a _ => ?_
  rw [Finset.card_filter]

#print axioms weyl_card_filter_product

lemma weyl_box_axes_card (M : ℕ) :
    ((Finset.range (M + 1) ×ˢ Finset.range (M + 1)).filter
      (fun p : ℕ × ℕ => ¬(1 ≤ p.1 ∧ 1 ≤ p.2))).card = 2 * M + 1 := by
  have h := Finset.card_filter_add_card_filter_not
    (s := Finset.range (M + 1) ×ˢ Finset.range (M + 1)) (fun p : ℕ × ℕ => 1 ≤ p.1 ∧ 1 ≤ p.2)
  have hQ : (Finset.range (M + 1) ×ˢ Finset.range (M + 1)).filter
      (fun p : ℕ × ℕ => 1 ≤ p.1 ∧ 1 ≤ p.2) = Finset.Icc 1 M ×ˢ Finset.Icc 1 M := by
    ext p
    simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_range, Finset.mem_Icc]
    omega
  rw [hQ, Finset.card_product, Finset.card_product, Nat.card_Icc, Finset.card_range] at h
  have : (M + 1) * (M + 1) = M * M + (2 * M + 1) := by ring
  simp only [Nat.add_sub_cancel] at h
  omega

#print axioms weyl_box_axes_card

lemma weyl_free_count_eq (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    {p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard =
      {p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard
        + 2 * ⌊ℓ⌋₊ + 1 := by
  rw [weyl_free_set_eq ℓ hℓ, weyl_clamped_set_eq ℓ hℓ, Set.ncard_coe_finset,
    Set.ncard_coe_finset]
  set M := ⌊ℓ⌋₊
  set B := Finset.range (M + 1) ×ˢ Finset.range (M + 1)
  have h := Finset.card_filter_add_card_filter_not
    (s := B.filter (fun p : ℕ × ℕ => (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2))
    (fun p : ℕ × ℕ => 1 ≤ p.1 ∧ 1 ≤ p.2)
  rw [Finset.filter_filter, Finset.filter_filter] at h
  have h1 : B.filter (fun p : ℕ × ℕ => (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2 ∧
      1 ≤ p.1 ∧ 1 ≤ p.2) =
      B.filter (fun p : ℕ × ℕ => 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2) := by
    apply Finset.filter_congr
    intro p _
    tauto
  have hMl : (M : ℝ) ≤ ℓ := Nat.floor_le hℓ
  have h2 : B.filter (fun p : ℕ × ℕ => (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2 ∧
      ¬(1 ≤ p.1 ∧ 1 ≤ p.2)) = B.filter (fun p : ℕ × ℕ => ¬(1 ≤ p.1 ∧ 1 ≤ p.2)) := by
    apply Finset.filter_congr
    intro p hp
    simp only [B, Finset.mem_product, Finset.mem_range] at hp
    constructor
    · exact fun h => h.2
    · intro hq
      refine ⟨?_, hq⟩
      have ha : (p.1 : ℝ) ≤ M := by exact_mod_cast Nat.lt_succ_iff.mp hp.1
      have hb : (p.2 : ℝ) ≤ M := by exact_mod_cast Nat.lt_succ_iff.mp hp.2
      have ha0 : (0:ℝ) ≤ p.1 := Nat.cast_nonneg _
      have hb0 : (0:ℝ) ≤ p.2 := Nat.cast_nonneg _
      rcases Nat.lt_or_ge p.1 1 with h | h
      · have : p.1 = 0 := by omega
        rw [this]; push_cast; nlinarith
      · have : p.2 = 0 := by omega
        rw [this]; push_cast; nlinarith
  rw [h1, h2, weyl_box_axes_card] at h
  omega

#print axioms weyl_free_count_eq

lemma weyl_sqrt_le (ℓ : ℝ) (hℓ : 0 ≤ ℓ) (x : ℝ) : √(ℓ ^ 2 - x ^ 2) ≤ ℓ := by
  calc √(ℓ ^ 2 - x ^ 2) ≤ √(ℓ ^ 2) := Real.sqrt_le_sqrt (by nlinarith [sq_nonneg x])
    _ = ℓ := Real.sqrt_sq hℓ

#print axioms weyl_sqrt_le

lemma weyl_antitone (ℓ : ℝ) (b : ℝ) :
    AntitoneOn (fun x : ℝ => √(ℓ ^ 2 - x ^ 2)) (Set.Icc 0 b) := by
  intro x hx y hy hxy
  exact Real.sqrt_le_sqrt (by nlinarith [hx.1])

#print axioms weyl_antitone

lemma weyl_integral_le_upper (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    ∫ x in (0:ℝ)..ℓ, √(ℓ ^ 2 - x ^ 2) ≤ ∫ x in (0:ℝ)..(0 + ((⌊ℓ⌋₊ + 1 : ℕ) : ℝ)), √(ℓ ^ 2 - x ^ 2) := by
  have hc : Continuous fun x : ℝ => √(ℓ ^ 2 - x ^ 2) := by fun_prop
  apply intervalIntegral.integral_mono_interval le_rfl hℓ
  · rw [zero_add]; push_cast; exact (Nat.lt_floor_add_one ℓ).le
  · exact Filter.Eventually.of_forall fun x => Real.sqrt_nonneg _
  · exact hc.intervalIntegrable _ _

#print axioms weyl_integral_le_upper

lemma weyl_integral_ge_lower (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    ∫ x in (0:ℝ)..(0 + ((⌊ℓ⌋₊ : ℕ) : ℝ)), √(ℓ ^ 2 - x ^ 2) ≤ ∫ x in (0:ℝ)..ℓ, √(ℓ ^ 2 - x ^ 2) := by
  have hc : Continuous fun x : ℝ => √(ℓ ^ 2 - x ^ 2) := by fun_prop
  apply intervalIntegral.integral_mono_interval le_rfl (by rw [zero_add]; exact Nat.cast_nonneg _)
  · rw [zero_add]; exact Nat.floor_le hℓ
  · exact Filter.Eventually.of_forall fun x => Real.sqrt_nonneg _
  · exact hc.intervalIntegrable _ _

#print axioms weyl_integral_ge_lower

lemma weyl_free_ge (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    π * ℓ ^ 2 / 4 ≤ ({p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) := by
  rw [weyl_free_set_eq ℓ hℓ, Set.ncard_coe_finset, weyl_card_filter_product, Nat.cast_sum,
    ← weyl_integral_quarter_disc ℓ hℓ]
  set M := ⌊ℓ⌋₊
  have hMl : (M : ℝ) ≤ ℓ := Nat.floor_le hℓ
  refine (weyl_integral_le_upper ℓ hℓ).trans (((weyl_antitone ℓ _).integral_le_sum).trans ?_)
  apply Finset.sum_le_sum
  intro m hm
  rw [zero_add]
  have hm' : (m : ℝ) ≤ ℓ := by
    have : m ≤ M := Nat.lt_succ_iff.mp (Finset.mem_range.mp hm)
    exact (Nat.cast_le.mpr this).trans hMl
  have hm0 : (0:ℝ) ≤ m := Nat.cast_nonneg _
  have hz : 0 ≤ ℓ ^ 2 - (m : ℝ) ^ 2 := by nlinarith
  set K := ⌊√(ℓ ^ 2 - (m : ℝ) ^ 2)⌋₊
  have hsub : Finset.range (K + 1) ⊆ (Finset.range (M + 1)).filter
      (fun n => ((m, n) : ℕ × ℕ).1 ^ 2 + ((((m, n) : ℕ × ℕ).2 : ℕ) : ℝ) ^ 2 ≤ ℓ ^ 2) := by
    intro n hn
    have hnK : n ≤ K := Nat.lt_succ_iff.mp (Finset.mem_range.mp hn)
    have hn1 : (n : ℝ) ≤ √(ℓ ^ 2 - (m : ℝ) ^ 2) :=
      (Nat.cast_le.mpr hnK).trans (Nat.floor_le (Real.sqrt_nonneg _))
    have hn0 : (0:ℝ) ≤ n := Nat.cast_nonneg _
    have hsq := Real.sq_sqrt hz
    have hs0 := Real.sqrt_nonneg (ℓ ^ 2 - (m : ℝ) ^ 2)
    simp only [Finset.mem_filter, Finset.mem_range]
    refine ⟨Nat.lt_succ_of_le (Nat.le_floor ((hn1.trans (weyl_sqrt_le ℓ hℓ _)))), ?_⟩
    nlinarith
  have hcard := Finset.card_le_card hsub
  rw [Finset.card_range] at hcard
  calc √(ℓ ^ 2 - (m : ℝ) ^ 2) ≤ (K : ℝ) + 1 := (Nat.lt_floor_add_one _).le
    _ = ((K + 1 : ℕ) : ℝ) := by push_cast; ring
    _ ≤ _ := by exact_mod_cast hcard

#print axioms weyl_free_ge

lemma weyl_clamped_le (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    ({p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) ≤
      π * ℓ ^ 2 / 4 := by
  rw [weyl_clamped_set_eq ℓ hℓ, Set.ncard_coe_finset, weyl_card_filter_product, Nat.cast_sum,
    ← weyl_integral_quarter_disc ℓ hℓ, Finset.sum_range_succ']
  set M := ⌊ℓ⌋₊
  have h0 : (Finset.range (M + 1)).filter (fun n => 1 ≤ ((0, n) : ℕ × ℕ).1 ∧ 1 ≤ ((0, n) : ℕ × ℕ).2 ∧
      ((((0, n) : ℕ × ℕ).1 : ℕ) : ℝ) ^ 2 + ((((0, n) : ℕ × ℕ).2 : ℕ) : ℝ) ^ 2 ≤ ℓ ^ 2) = ∅ := by
    ext n; simp
  rw [h0, Finset.card_empty, Nat.cast_zero, add_zero]
  refine le_trans ?_ (((weyl_antitone ℓ _).sum_le_integral).trans (weyl_integral_ge_lower ℓ hℓ))
  apply Finset.sum_le_sum
  intro i _
  rw [zero_add]
  set m := i + 1
  set K := ⌊√(ℓ ^ 2 - ((m : ℕ) : ℝ) ^ 2)⌋₊
  have hsub : (Finset.range (M + 1)).filter (fun n => 1 ≤ ((m, n) : ℕ × ℕ).1 ∧
      1 ≤ ((m, n) : ℕ × ℕ).2 ∧
      ((((m, n) : ℕ × ℕ).1 : ℕ) : ℝ) ^ 2 + ((((m, n) : ℕ × ℕ).2 : ℕ) : ℝ) ^ 2 ≤ ℓ ^ 2) ⊆
      Finset.Icc 1 K := by
    intro n hn
    simp only [Finset.mem_filter, Finset.mem_range] at hn
    simp only [Finset.mem_Icc]
    refine ⟨hn.2.2.1, Nat.le_floor ?_⟩
    have hn0 : (0:ℝ) ≤ n := Nat.cast_nonneg _
    rw [Real.le_sqrt hn0 (by nlinarith [hn.2.2.2, sq_nonneg (n : ℝ)])]
    linarith [hn.2.2.2]
  have hcard := Finset.card_le_card hsub
  rw [Nat.card_Icc, Nat.add_sub_cancel] at hcard
  calc (((Finset.range (M + 1)).filter _).card : ℝ) ≤ (K : ℝ) := by exact_mod_cast hcard
    _ ≤ _ := Nat.floor_le (Real.sqrt_nonneg _)

#print axioms weyl_clamped_le

lemma weyl_tendsto_of_near (s : ℝ) (_hs : 0 < s) (N : ℝ → ℝ)
    (h : ∀ lam : ℝ, 0 < lam →
      π * (s * √lam / π) ^ 2 / 4 - 2 * (s * √lam / π) - 1 ≤ N lam ∧
        N lam ≤ π * (s * √lam / π) ^ 2 / 4 + 2 * (s * √lam / π) + 1) :
    Tendsto (fun lam : ℝ => N lam / lam) atTop (𝓝 (s ^ 2 / (4 * π))) := by
  have hpi := Real.pi_pos
  have hlim : ∀ c : ℝ, Tendsto (fun lam : ℝ => s ^ 2 / (4 * π) + c * (2 * s / π) * (√lam)⁻¹
      + c * lam⁻¹) atTop (𝓝 (s ^ 2 / (4 * π))) := by
    intro c
    have h1 := (tendsto_const_nhds (x := s ^ 2 / (4 * π))).add
      ((tendsto_const_nhds (x := c * (2 * s / π))).mul
        (tendsto_inv_atTop_zero.comp Real.tendsto_sqrt_atTop))
    have h2 := h1.add ((tendsto_const_nhds (x := c)).mul tendsto_inv_atTop_zero)
    simp only [mul_zero, add_zero] at h2
    exact h2
  have key : ∀ c : ℝ, ∀ lam : ℝ, 0 < lam →
      (s ^ 2 / (4 * π) + c * (2 * s / π) * (√lam)⁻¹ + c * lam⁻¹) * lam =
        π * (s * √lam / π) ^ 2 / 4 + c * (2 * (s * √lam / π)) + c := by
    intro c lam hlam
    have ht : 0 < √lam := Real.sqrt_pos.mpr hlam
    have hsq : √lam ^ 2 = lam := Real.sq_sqrt hlam.le
    generalize √lam = t at ht hsq ⊢
    subst hsq
    field_simp
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' (hlim (-1)) (hlim 1) ?_ ?_
  · filter_upwards [eventually_gt_atTop 0] with lam hlam
    rw [le_div_iff₀ hlam, key (-1) lam hlam]
    linarith [(h lam hlam).1]
  · filter_upwards [eventually_gt_atTop 0] with lam hlam
    rw [div_le_iff₀ hlam, key 1 lam hlam]
    linarith [(h lam hlam).2]

#print axioms weyl_tendsto_of_near

lemma weyl_cond_iff (s : ℝ) (hs : 0 < s) (lam : ℝ) (hlam : 0 < lam) (X : ℝ) :
    π ^ 2 * X / s ^ 2 ≤ lam ↔ X ≤ (s * √lam / π) ^ 2 := by
  have hpi := Real.pi_pos
  have hsq : √lam ^ 2 = lam := Real.sq_sqrt hlam.le
  rw [div_le_iff₀ (by positivity), div_pow, mul_pow, hsq, le_div_iff₀ (by positivity)]
  constructor <;> intro h <;> linarith

#print axioms weyl_cond_iff

/-- The lattice bounds for one square (Step 4). A square of side `s` has clamped modes
`sin(mπx/s) sin(nπy/s)` with `m, n ≥ 1` and free modes `cos(mπx/s) cos(nπy/s)` with `m, n ≥ 0`,
both with eigenvalue `π²(m² + n²)/s²`. With the lattice radius `ℓ = s√λ/π`, the clamped count
`N_D` is the number of whole-number points `(m, n)` with `m, n ≥ 1` and `m² + n² ≤ ℓ²`, and the
free count `N_N` the number with `m, n ≥ 0`. Both lie within `2ℓ + 1` of the quarter-circle area
`πℓ²/4 = s²λ/(4π)`, the clamped count below it and the free count above it:
`πℓ²/4 − 2ℓ − 1 ≤ N_D ≤ πℓ²/4 ≤ N_N ≤ πℓ²/4 + 2ℓ + 1`. -/
theorem square_mode_counts_near_quarter_circle (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    π * ℓ ^ 2 / 4 - 2 * ℓ - 1 ≤
        ({p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) ∧
      ({p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) ≤
        π * ℓ ^ 2 / 4 ∧
      π * ℓ ^ 2 / 4 ≤
        ({p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) ∧
      ({p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) ≤
        π * ℓ ^ 2 / 4 + 2 * ℓ + 1 := by
  have h2 := weyl_free_count_eq ℓ hℓ
  have h2r : ({p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ) =
      ({p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard : ℝ)
        + 2 * (⌊ℓ⌋₊ : ℝ) + 1 := by
    rw [h2]; push_cast; ring
  have hM : (⌊ℓ⌋₊ : ℝ) ≤ ℓ := Nat.floor_le hℓ
  have hA := weyl_free_ge ℓ hℓ
  have hB := weyl_clamped_le ℓ hℓ
  refine ⟨?_, hB, hA, ?_⟩ <;> linarith

/-- The free points are the clamped points plus the points on the two axes: for a lattice
radius `ℓ ≥ 0`, `N_N = N_D + 2⌊ℓ⌋ + 1`. -/
theorem free_count_eq_clamped_count_add_axis_points (ℓ : ℝ) (hℓ : 0 ≤ ℓ) :
    {p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard =
      {p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧ (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ ℓ ^ 2}.ncard
        + 2 * ⌊ℓ⌋₊ + 1 := by
  exact weyl_free_count_eq ℓ hℓ

/-- Weyl's law on a square of side `s > 0`: the number of clamped modes with eigenvalue
`π²(m² + n²)/s² ≤ λ`, and likewise the number of free modes, divided by `λ`, tends to the
square's area over `4π`, that is `N(λ)/λ → s²/(4π)` as `λ → ∞`. -/
theorem weyl_law_square (s : ℝ) (hs : 0 < s) :
    Tendsto (fun lam : ℝ =>
        ({p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧
            π ^ 2 * ((p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2) / s ^ 2 ≤ lam}.ncard : ℝ) / lam)
        atTop (𝓝 (s ^ 2 / (4 * π))) ∧
      Tendsto (fun lam : ℝ =>
        ({p : ℕ × ℕ | π ^ 2 * ((p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2) / s ^ 2 ≤ lam}.ncard : ℝ) / lam)
        atTop (𝓝 (s ^ 2 / (4 * π))) := by
  have hpi := Real.pi_pos
  constructor
  · apply weyl_tendsto_of_near s hs
    intro lam hlam
    have hℓ : 0 ≤ s * √lam / π := by positivity
    have hset : {p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧
        π ^ 2 * ((p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2) / s ^ 2 ≤ lam} =
        {p : ℕ × ℕ | 1 ≤ p.1 ∧ 1 ≤ p.2 ∧
          (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ (s * √lam / π) ^ 2} := by
      ext p; simp only [Set.mem_ofPred_eq, weyl_cond_iff s hs lam hlam]
    rw [hset]
    have := square_mode_counts_near_quarter_circle _ hℓ
    constructor <;> linarith [this.1, this.2.1]
  · apply weyl_tendsto_of_near s hs
    intro lam hlam
    have hℓ : 0 ≤ s * √lam / π := by positivity
    have hset : {p : ℕ × ℕ | π ^ 2 * ((p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2) / s ^ 2 ≤ lam} =
        {p : ℕ × ℕ | (p.1 : ℝ) ^ 2 + (p.2 : ℝ) ^ 2 ≤ (s * √lam / π) ^ 2} := by
      ext p; simp only [Set.mem_ofPred_eq, weyl_cond_iff s hs lam hlam]
    rw [hset]
    have := square_mode_counts_near_quarter_circle _ hℓ
    constructor <;> linarith [this.2.2.1, this.2.2.2]

-- The unit square at λ = 1000 1/m²: ℓ² = 1000/π² lies between 101 and 102, so a point counts
-- exactly when m² + n² ≤ 101.
example : (101 : ℝ) ≤ 1000 / π ^ 2 ∧ 1000 / π ^ 2 < 102 := by
  have h1 := pi_gt_d4
  have h2 := pi_lt_d4
  have hp : 0 < π ^ 2 := by positivity
  constructor
  · rw [le_div_iff₀ hp]; nlinarith
  · rw [div_lt_iff₀ hp]; nlinarith

-- Its clamped count is 71 and its free count 92 (every point has m, n ≤ 10).
example : ((Finset.Icc 1 10 ×ˢ Finset.Icc 1 10).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + p.2 ^ 2 ≤ 101)).card = 71 := by decide
example : ((Finset.range 11 ×ˢ Finset.range 11).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + p.2 ^ 2 ≤ 101)).card = 92 := by decide

-- Free = clamped + 2⌊ℓ⌋ + 1 with ⌊ℓ⌋ = 10, and the slack 2ℓ + 1 = 21.13 covers both gaps
-- from the area term 79.58: 79.58 − 71 = 8.58 and 92 − 79.58 = 12.42.
example : (92 : ℕ) = 71 + 2 * 10 + 1 := by norm_num

-- The 2 m × 1 m rectangle at λ = 1000: a mode counts when m²/4 + n² ≤ 1000/π², that is
-- m² + 4n² ≤ 405 (4000/π² is 405.28). Clamped count 146, free count 177.
example : ((Finset.Icc 1 20 ×ˢ Finset.Icc 1 10).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + 4 * p.2 ^ 2 ≤ 405)).card = 146 := by decide +kernel
example : ((Finset.range 21 ×ˢ Finset.range 11).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + 4 * p.2 ^ 2 ≤ 405)).card = 177 := by decide +kernel

-- The L-shaped sheet's brackets: three squares give 3 · 71 = 213 to 3 · 92 = 276; the
-- rectangle plus one square give 146 + 71 = 217 to 177 + 92 = 269.
example : 3 * 71 = 213 ∧ 3 * 92 = 276 ∧ 146 + 71 = 217 ∧ 177 + 92 = 269 := by norm_num

-- The 1 m wide clamped strip of length 10 m: m²/100 + n² ≤ 1000/π², that is
-- m² + 100n² ≤ 10132 (100000/π² is 10132.12). It holds 742 modes.
example : ((Finset.Icc 1 100 ×ˢ Finset.Icc 1 10).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + 100 * p.2 ^ 2 ≤ 10132)).card = 742 := by decide +kernel

#print axioms square_mode_counts_near_quarter_circle
#print axioms free_count_eq_clamped_count_add_axis_points
#print axioms weyl_law_square
