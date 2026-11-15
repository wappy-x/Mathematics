-- Equivalent norms: any two norms on lists of n real numbers are pinned within fixed positive multiples of each other, while the sup and average norms on N slots need the pin N and continuous price curves have no pin at all.
import Mathlib.Analysis.Normed.Module.Seminorm.Basic
import Mathlib.Analysis.Normed.Group.Constructions
import Mathlib.Topology.ContinuousMap.Compact
import Mathlib.MeasureTheory.Constructions.UnitInterval
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open scoped unitInterval

theorem seminorm_le_const_mul_supNorm {n : ℕ} (p : Seminorm ℝ (Fin n → ℝ)) :
    ∃ K : ℝ, 0 < K ∧ ∀ x : Fin n → ℝ, p x ≤ K * ‖x‖ := by
  refine ⟨(∑ i, p (Pi.single i 1)) + 1,
    add_pos_of_nonneg_of_pos (Finset.sum_nonneg fun i _ => apply_nonneg p _) one_pos, fun x => ?_⟩
  have hx : x = ∑ i, x i • (Pi.single i 1 : Fin n → ℝ) := by
    conv_lhs => rw [← Finset.univ_sum_single x]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Pi.single_smul, smul_eq_mul, mul_one]
  calc p x = p (∑ i, x i • (Pi.single i 1 : Fin n → ℝ)) := by rw [← hx]
    _ ≤ ∑ i, p (x i • (Pi.single i 1 : Fin n → ℝ)) := Finset.le_sum_of_subadditive p (map_zero p).le (map_add_le_add p) _ _
    _ = ∑ i, ‖x i‖ * p (Pi.single i 1) := by simp only [map_smul_eq_mul]
    _ ≤ ∑ i, ‖x‖ * p (Pi.single i 1) := by
        refine Finset.sum_le_sum fun i _ => ?_
        exact mul_le_mul_of_nonneg_right (norm_le_pi_norm x i) (apply_nonneg p _)
    _ = (∑ i, p (Pi.single i 1)) * ‖x‖ := by rw [← Finset.mul_sum, mul_comm]
    _ ≤ ((∑ i, p (Pi.single i 1)) + 1) * ‖x‖ := by
        nlinarith [norm_nonneg x]

#print axioms seminorm_le_const_mul_supNorm

theorem seminorm_continuous_on_finite_lists {n : ℕ} (p : Seminorm ℝ (Fin n → ℝ)) :
    Continuous p := by
  obtain ⟨K, hK, hp⟩ := seminorm_le_const_mul_supNorm p
  refine Metric.continuous_iff.2 fun x ε hε => ⟨ε / K, by positivity, fun y hy => ?_⟩
  rw [Real.dist_eq]
  calc |p y - p x| ≤ p (y - x) := abs_sub_map_le_sub p y x
    _ ≤ K * ‖y - x‖ := hp _
    _ < K * (ε / K) := by rw [← dist_eq_norm]; gcongr
    _ = ε := by field_simp

#print axioms seminorm_continuous_on_finite_lists

theorem supNorm_le_const_mul_seminorm {n : ℕ} (p : Seminorm ℝ (Fin n → ℝ))
    (hp : ∀ x, p x = 0 → x = 0) :
    ∃ k : ℝ, 0 < k ∧ ∀ x : Fin n → ℝ, k * ‖x‖ ≤ p x := by
  have hS : IsCompact (Metric.sphere (0 : Fin n → ℝ) 1) := isCompact_sphere 0 1
  rcases (Metric.sphere (0 : Fin n → ℝ) 1).eq_empty_or_nonempty with he | hne
  · refine ⟨1, one_pos, fun x => ?_⟩
    by_cases hx : x = 0
    · subst hx; simp
    · exfalso
      have hmem : ‖x‖⁻¹ • x ∈ Metric.sphere (0 : Fin n → ℝ) 1 := by
        rw [mem_sphere_zero_iff_norm, norm_smul, norm_inv, norm_norm,
          inv_mul_cancel₀ (norm_ne_zero_iff.2 hx)]
      rw [he] at hmem
      exact hmem
  · obtain ⟨u, hu, hmin⟩ := hS.exists_isMinOn hne (seminorm_continuous_on_finite_lists p).continuousOn
    have hu0 : u ≠ 0 := by
      rintro rfl
      simp at hu
    have hpu : 0 < p u := lt_of_le_of_ne (apply_nonneg p u) (fun h => hu0 (hp u h.symm))
    refine ⟨p u, hpu, fun x => ?_⟩
    by_cases hx : x = 0
    · subst hx; simp
    · have hnx : 0 < ‖x‖ := norm_pos_iff.2 hx
      have hmem : ‖x‖⁻¹ • x ∈ Metric.sphere (0 : Fin n → ℝ) 1 := by
        rw [mem_sphere_zero_iff_norm, norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ hnx.ne']
      have h1 : p u ≤ p (‖x‖⁻¹ • x) := hmin hmem
      rw [map_smul_eq_mul, norm_inv, norm_norm] at h1
      calc p u * ‖x‖ ≤ (‖x‖⁻¹ * p x) * ‖x‖ := by gcongr
        _ = p x := by field_simp

#print axioms supNorm_le_const_mul_seminorm

theorem integral_one_sub_pow_on_unit_interval (k : ℕ) :
    ∫ t : I, |(1 - (t : ℝ)) ^ k| = 1 / (k + 1) := by
  have h1 : ∫ t : I, |(1 - (t : ℝ)) ^ k| = ∫ x in Set.Icc (0 : ℝ) 1, |(1 - x) ^ k| :=
    MeasureTheory.integral_subtype_comap measurableSet_Icc (fun x : ℝ => |(1 - x) ^ k|)
  rw [h1, MeasureTheory.integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
  have h2 : ∫ x in (0 : ℝ)..1, |(1 - x) ^ k| = ∫ x in (0 : ℝ)..1, (1 - x) ^ k := by
    refine intervalIntegral.integral_congr fun x hx => ?_
    rw [Set.uIcc_of_le zero_le_one] at hx
    exact abs_of_nonneg (pow_nonneg (by linarith [hx.2]) k)
  rw [h2, intervalIntegral.integral_comp_sub_left (fun x : ℝ => x ^ k) 1]
  simp

#print axioms integral_one_sub_pow_on_unit_interval

/-- On lists of n real numbers, every two norms are equivalent: for any two size rules
that scale, obey the triangle rule and give 0 only to the zero list, there are fixed
positive numbers c and C with c‖x‖_a ≤ ‖x‖_b ≤ C‖x‖_a for every list x. -/
theorem norms_on_finite_lists_are_equivalent {n : ℕ} (a b : Seminorm ℝ (Fin n → ℝ))
    (ha : ∀ x, a x = 0 → x = 0) (hb : ∀ x, b x = 0 → x = 0) :
    ∃ c C : ℝ, 0 < c ∧ 0 < C ∧ ∀ x : Fin n → ℝ, c * a x ≤ b x ∧ b x ≤ C * a x := by
  obtain ⟨Ka, hKa, hKa'⟩ := seminorm_le_const_mul_supNorm a
  obtain ⟨Kb, hKb, hKb'⟩ := seminorm_le_const_mul_supNorm b
  obtain ⟨ka, hka, hka'⟩ := supNorm_le_const_mul_seminorm a ha
  obtain ⟨kb, hkb, hkb'⟩ := supNorm_le_const_mul_seminorm b hb
  refine ⟨kb / Ka, Kb / ka, by positivity, by positivity, fun x => ⟨?_, ?_⟩⟩
  · calc kb / Ka * a x ≤ kb / Ka * (Ka * ‖x‖) := by gcongr; exact hKa' x
      _ = kb * ‖x‖ := by field_simp
      _ ≤ b x := hkb' x
  · calc b x ≤ Kb * ‖x‖ := hKb' x
      _ = Kb / ka * (ka * ‖x‖) := by field_simp
      _ ≤ Kb / ka * a x := by gcongr; exact hka' x

/-- A price list cut into N slots: its average slot size is at most its worst slot, the
worst slot is at most N times the average, and the pin N is reached by a single spike. -/
theorem sup_and_average_pinned_by_N {N : ℕ} (hN : 0 < N) :
    (∀ f : Fin N → ℝ, (∑ j, |f j|) / N ≤ ‖f‖ ∧ ‖f‖ ≤ N * ((∑ j, |f j|) / N)) ∧
    ∃ f : Fin N → ℝ, f ≠ 0 ∧ ‖f‖ = N * ((∑ j, |f j|) / N) := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  refine ⟨fun f => ⟨?_, ?_⟩, ?_⟩
  · rw [div_le_iff₀ hN']
    calc ∑ j, |f j| ≤ ∑ _j : Fin N, ‖f‖ :=
          Finset.sum_le_sum fun j _ => by rw [← Real.norm_eq_abs]; exact norm_le_pi_norm f j
      _ = ‖f‖ * N := by simp [mul_comm]
  · rw [mul_div_cancel₀ _ hN'.ne']
    refine (pi_norm_le_iff_of_nonneg (Finset.sum_nonneg fun j _ => abs_nonneg (f j))).2
      fun i => ?_
    rw [Real.norm_eq_abs]
    exact Finset.single_le_sum (f := fun j => |f j|) (fun j _ => abs_nonneg (f j))
      (Finset.mem_univ i)
  · refine ⟨Pi.single ⟨0, hN⟩ 1, ?_, ?_⟩
    · intro h
      have := congrFun h ⟨0, hN⟩
      simp at this
    · rw [mul_div_cancel₀ _ hN'.ne', Pi.norm_single]
      have : ∀ j, |(Pi.single (⟨0, hN⟩ : Fin N) (1 : ℝ) : Fin N → ℝ) j|
          = (Pi.single (⟨0, hN⟩ : Fin N) (1 : ℝ) : Fin N → ℝ) j := by
        intro j
        by_cases hj : j = ⟨0, hN⟩
        · subst hj; simp
        · simp [hj]
      simp only [this, Finset.sum_pi_single', Finset.mem_univ, ite_true, norm_one]

/-- For price curves over continuous time (a week rescaled to the unit interval) there is
no pin at all: no constant C bounds the worst value by C times the time-average size. -/
theorem no_pin_for_continuous_price_curves :
    ¬ ∃ C : ℝ, ∀ f : C(I, ℝ), ‖f‖ ≤ C * ∫ t, |f t| := by
  rintro ⟨C, hC⟩
  obtain ⟨k, hk⟩ := exists_nat_gt C
  let f : C(I, ℝ) := ⟨fun t => (1 - (t : ℝ)) ^ k, by fun_prop⟩
  have hf0 : ‖f 0‖ ≤ ‖f‖ := f.norm_coe_le_norm 0
  have hf0' : f 0 = 1 := by simp [f]
  have hint : ∫ t, |f t| = 1 / (k + 1) := integral_one_sub_pow_on_unit_interval k
  have h := hC f
  rw [hint] at h
  rw [hf0', norm_one] at hf0
  have hk1 : (0 : ℝ) < k + 1 := by positivity
  have : C * (1 / (k + 1)) < 1 := by
    rw [mul_one_div, div_lt_one hk1]; linarith
  linarith

-- The batch error (6, -4, 3) g is 13 g off in total.
example : |(6 : ℤ)| + |(-4 : ℤ)| + |(3 : ℤ)| = 13 := by decide

-- Percent off for each ingredient, out of 300, 200 and 100 g: 2%, 2%, 3%; the worst is 3%.
example : max (100 * 6 / 300 : ℚ) (max (100 * 4 / 200) (100 * 3 / 100)) = 3 := by norm_num

-- One gram of each ingredient is 1/3%, 1/2% and 1%, so the upper pin is B = 1 %/g.
example : max (100 / 300 : ℚ) (max (100 / 200) (100 / 100)) = 1 := by norm_num

-- The list x* = (3, 2, 1)/6 g is 1 g off in total and each ingredient misses by 1/6%.
example : (3 / 6 : ℚ) + 2 / 6 + 1 / 6 = 1 ∧
    100 * (3 / 6) / 300 = (1 / 6 : ℚ) ∧ 100 * (2 / 6) / 200 = (1 / 6 : ℚ) ∧
    100 * (1 / 6) / 100 = (1 / 6 : ℚ) := by norm_num

-- The batch sandwich: 13 g × 1/6 %/g ≤ 3% ≤ 13 g × 1 %/g.
example : (13 : ℚ) * (1 / 6) ≤ 3 ∧ (3 : ℚ) ≤ 13 * 1 := by norm_num

-- The grams-sphere walk with K = 60 has 4K² + 2 = 14,402 points.
example : 4 * 60 ^ 2 + 2 = 14402 := by norm_num

-- N = 7 brute force: of the 5^7 lists with entries -1, -1/2, 0, 1/2, 1, those with worst slot 1 number 75,938.
example : 5 ^ 7 = 78125 ∧ 5 ^ 7 - 3 ^ 7 = 75938 := by norm_num

-- A single spike of 920 £/MWh in N = 168 slots: sup 920 is 168 times the average 920/168.
example : (920 : ℚ) = 168 * (920 / 168) := by norm_num

#print axioms norms_on_finite_lists_are_equivalent
#print axioms sup_and_average_pinned_by_N
#print axioms no_pin_for_continuous_price_curves
