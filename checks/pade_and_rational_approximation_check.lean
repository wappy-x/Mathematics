-- Pade approximants: the Pade recipe gives a ratio P/Q whose series matches f through x^(m+n), and for tan its [5/4] ratio misses tan's series first at x^11.
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases

open PowerSeries

lemma tanAux_mul_cos : sin ℚ * (cos ℚ)⁻¹ * cos ℚ = sin ℚ := by
  rw [mul_assoc, PowerSeries.inv_mul_cancel, mul_one]
  simp [cos]

lemma tanAux_rec (n : ℕ) : coeff n (sin ℚ * (cos ℚ)⁻¹) = coeff n (sin ℚ) -
    ∑ i ∈ Finset.range n, coeff i (sin ℚ * (cos ℚ)⁻¹) * coeff (n - i) (cos ℚ) := by
  have h := congrArg (coeff n) tanAux_mul_cos
  rw [coeff_mul, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk, Finset.sum_range_succ] at h
  have h0 : coeff 0 (cos ℚ) = 1 := by simp [cos]
  simp only [Nat.sub_self, h0, mul_one] at h
  rw [← h]; ring

lemma sin_coeffs : coeff 0 (sin ℚ) = 0 ∧ coeff 1 (sin ℚ) = 1 ∧ coeff 2 (sin ℚ) = 0 ∧
    coeff 3 (sin ℚ) = -1/6 ∧ coeff 4 (sin ℚ) = 0 ∧ coeff 5 (sin ℚ) = 1/120 ∧
    coeff 6 (sin ℚ) = 0 ∧ coeff 7 (sin ℚ) = -1/5040 ∧ coeff 8 (sin ℚ) = 0 ∧
    coeff 9 (sin ℚ) = 1/362880 ∧ coeff 10 (sin ℚ) = 0 ∧ coeff 11 (sin ℚ) = -1/39916800 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> simp only [sin, coeff_mk] <;> norm_num [Nat.even_iff, Nat.factorial]

lemma cos_coeffs : coeff 0 (cos ℚ) = 1 ∧ coeff 1 (cos ℚ) = 0 ∧ coeff 2 (cos ℚ) = -1/2 ∧
    coeff 3 (cos ℚ) = 0 ∧ coeff 4 (cos ℚ) = 1/24 ∧ coeff 5 (cos ℚ) = 0 ∧
    coeff 6 (cos ℚ) = -1/720 ∧ coeff 7 (cos ℚ) = 0 ∧ coeff 8 (cos ℚ) = 1/40320 ∧
    coeff 9 (cos ℚ) = 0 ∧ coeff 10 (cos ℚ) = -1/3628800 ∧ coeff 11 (cos ℚ) = 0 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> simp only [cos, coeff_mk] <;> norm_num [Nat.even_iff, Nat.factorial]

lemma tanAux_coeffs :
    coeff 0 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 1 (sin ℚ * (cos ℚ)⁻¹) = 1 ∧
    coeff 2 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 3 (sin ℚ * (cos ℚ)⁻¹) = 1 / 3 ∧
    coeff 4 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 5 (sin ℚ * (cos ℚ)⁻¹) = 2 / 15 ∧
    coeff 6 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 7 (sin ℚ * (cos ℚ)⁻¹) = 17 / 315 ∧
    coeff 8 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 9 (sin ℚ * (cos ℚ)⁻¹) = 62 / 2835 ∧
    coeff 10 (sin ℚ * (cos ℚ)⁻¹) = 0 ∧ coeff 11 (sin ℚ * (cos ℚ)⁻¹) = 1382 / 155925 := by
  obtain ⟨s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11⟩ := sin_coeffs
  obtain ⟨k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10, k11⟩ := cos_coeffs
  have t0 : coeff 0 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]; simp [s0]
  have t1 : coeff 1 (sin ℚ * (cos ℚ)⁻¹) = 1 := by
    rw [tanAux_rec]; simp [s1, t0]
  have t2 : coeff 2 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s2, t0, t1, k1]
  have t3 : coeff 3 (sin ℚ * (cos ℚ)⁻¹) = 1 / 3 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s3, t0, t1, t2, k2]; norm_num
  have t4 : coeff 4 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s4, t0, t1, t2, t3, k1, k3]
  have t5 : coeff 5 (sin ℚ * (cos ℚ)⁻¹) = 2 / 15 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s5, t0, t1, t2, t3, t4, k2, k4]; norm_num
  have t6 : coeff 6 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s6, t0, t1, t2, t3, t4, t5, k1, k3, k5]
  have t7 : coeff 7 (sin ℚ * (cos ℚ)⁻¹) = 17 / 315 := by
    rw [tanAux_rec]; simp [Finset.sum_range_succ, s7, t0, t1, t2, t3, t4, t5, t6, k2, k4, k6]
    norm_num
  have t8 : coeff 8 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]
    simp [Finset.sum_range_succ, s8, t0, t1, t2, t3, t4, t5, t6, t7, k1, k3, k5, k7]
  have t9 : coeff 9 (sin ℚ * (cos ℚ)⁻¹) = 62 / 2835 := by
    rw [tanAux_rec]
    simp [Finset.sum_range_succ, s9, t0, t1, t2, t3, t4, t5, t6, t7, t8, k2, k4, k6, k8]
    norm_num
  have t10 : coeff 10 (sin ℚ * (cos ℚ)⁻¹) = 0 := by
    rw [tanAux_rec]
    simp [Finset.sum_range_succ, s10, t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, k1, k3, k5, k7, k9]
  have t11 : coeff 11 (sin ℚ * (cos ℚ)⁻¹) = 1382 / 155925 := by
    rw [tanAux_rec]
    simp [Finset.sum_range_succ, s11, t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10,
      k2, k4, k6, k8, k10]
    norm_num
  exact ⟨t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11⟩

/-- The Pade recipe. Let f have Taylor coefficients c_k = coeff k f, and fix degrees m (top)
and n (bottom). Take q_0 = 1 and suppose q_1, ..., q_n solve the bottom equations
sum_(j = 0..min(k, n)) q_j c_(k-j) = 0 for k = m+1, ..., m+n.
Build Q = sum_(j <= n) q_j x^j and the top P = sum_(k <= m) p_k x^k with
p_k = sum_(j = 0..min(k, n)) q_j c_(k-j).
Then Q f - P has no terms below x^(m+n+1), and the series of P/Q matches f's through x^(m+n). -/
theorem pade_recipe_matches_series {K : Type*} [Field K] (f : K⟦X⟧) (m n : ℕ) (q : ℕ → K)
    (hq0 : q 0 = 1)
    (hQ : ∀ k, m + 1 ≤ k → k ≤ m + n →
      ∑ j ∈ Finset.range (min k n + 1), q j * coeff (k - j) f = 0) :
    let Q : K⟦X⟧ := ∑ j ∈ Finset.range (n + 1), C (q j) * X ^ j
    let P : K⟦X⟧ := ∑ k ∈ Finset.range (m + 1),
      C (∑ j ∈ Finset.range (min k n + 1), q j * coeff (k - j) f) * X ^ k
    (∀ k ≤ m + n, coeff k (Q * f - P) = 0) ∧ (∀ k ≤ m + n, coeff k (f - P * Q⁻¹) = 0) := by
  intro Q P
  have hQf : ∀ k, coeff k (Q * f) = ∑ j ∈ Finset.range (min k n + 1), q j * coeff (k - j) f := by
    intro k
    have hs : (Finset.range (n + 1)).filter (fun j => j ≤ k) = Finset.range (min k n + 1) := by
      ext j; simp only [Finset.mem_filter, Finset.mem_range]; omega
    simp only [Q, Finset.sum_mul, map_sum, mul_assoc, coeff_C_mul, coeff_X_pow_mul']
    rw [← hs, Finset.sum_filter]
    refine Finset.sum_congr rfl fun j _ => ?_
    split_ifs <;> simp
  have hP : ∀ k, coeff k P =
      if k ≤ m then ∑ j ∈ Finset.range (min k n + 1), q j * coeff (k - j) f else 0 := by
    intro k
    simp only [P]
    rw [map_sum]
    simp only [coeff_C_mul_X_pow]
    rw [Finset.sum_ite_eq]
    simp only [Finset.mem_range]
    split_ifs <;> first | rfl | omega
  have h1 : ∀ k ≤ m + n, coeff k (Q * f - P) = 0 := by
    intro k hk
    rw [map_sub, hQf, hP]
    split_ifs with h
    · exact sub_self _
    · rw [sub_zero]; exact hQ k (by omega) hk
  refine ⟨h1, ?_⟩
  have hQ0 : constantCoeff Q ≠ 0 := by
    rw [← coeff_zero_eq_constantCoeff_apply]
    simp only [Q, map_sum, coeff_C_mul_X_pow]
    rw [Finset.sum_ite_eq]
    simp [hq0]
  have hdvd : (X : K⟦X⟧) ^ (m + n + 1) ∣ Q * f - P :=
    X_pow_dvd_iff.mpr fun k hk => h1 k (by omega)
  have heq : f - P * Q⁻¹ = Q⁻¹ * (Q * f - P) := by
    rw [mul_sub, ← mul_assoc, PowerSeries.inv_mul_cancel _ hQ0, one_mul, mul_comm Q⁻¹ P]
  intro k hk
  rw [heq]
  exact X_pow_dvd_iff.mp (Dvd.dvd.mul_left hdvd _) k (by omega)

/-- The Taylor coefficients of tan = sin/cos at 0 that the card's [5/4] approximant uses:
c_1, c_3, c_5, c_7, c_9 = 1, 1/3, 2/15, 17/315, 62/2835, and every even coefficient is zero. -/
theorem tan_taylor_coefficients :
    let tanSeries : ℚ⟦X⟧ := sin ℚ * (cos ℚ)⁻¹
    coeff 1 tanSeries = 1 ∧ coeff 3 tanSeries = 1 / 3 ∧ coeff 5 tanSeries = 2 / 15 ∧
      coeff 7 tanSeries = 17 / 315 ∧ coeff 9 tanSeries = 62 / 2835 ∧
      ∀ k ≤ 10, Even k → coeff k tanSeries = 0 := by
  intro tanSeries
  obtain ⟨t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11⟩ := tanAux_coeffs
  refine ⟨t1, t3, t5, t7, t9, ?_⟩
  intro k hk he
  interval_cases k <;> first | assumption | (exfalso; revert he; decide)

/-- The [5/4] Pade approximant of tan: with Q = 1 - 4x^2/9 + x^4/63 and
P = x - x^3/9 + x^5/945 (times 945: (945x - 105x^3 + x^5)/(945 - 420x^2 + 15x^4)),
Q tan x - P has no terms below x^11, and its x^11 term is 1/9823275 (about 1.018e-07). -/
theorem pade_five_four_of_tan :
    let tanSeries : ℚ⟦X⟧ := sin ℚ * (cos ℚ)⁻¹
    let Q : ℚ⟦X⟧ := 1 - C (4 / 9) * X ^ 2 + C (1 / 63) * X ^ 4
    let P : ℚ⟦X⟧ := X - C (1 / 9) * X ^ 3 + C (1 / 945) * X ^ 5
    (∀ k ≤ 10, coeff k (Q * tanSeries - P) = 0) ∧
      coeff 11 (Q * tanSeries - P) = 1 / 9823275 := by
  intro tanSeries Q P
  obtain ⟨t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11⟩ := tanAux_coeffs
  have hc : ∀ k, coeff k (Q * tanSeries - P) =
      coeff k tanSeries - 4 / 9 * (if 2 ≤ k then coeff (k - 2) tanSeries else 0)
        + 1 / 63 * (if 4 ≤ k then coeff (k - 4) tanSeries else 0)
        - ((if k = 1 then 1 else 0) - (if k = 3 then 1 / 9 else 0)
          + (if k = 5 then 1 / 945 else 0)) := by
    intro k
    simp only [Q, P, sub_mul, add_mul, one_mul, mul_assoc, map_sub, map_add, coeff_C_mul,
      coeff_X_pow_mul', coeff_X]
    split_ifs <;> simp_all
  refine ⟨?_, ?_⟩
  · intro k hk
    rw [hc]
    interval_cases k <;> simp [tanSeries, t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10] <;> norm_num
  · rw [hc]; simp [tanSeries, t7, t9, t11]; norm_num

-- Worked numbers, by hand: build [5/4] of tan from c_1, c_3, c_5, c_7, c_9.
-- determinant c_5^2 - c_3 c_7 = 84/4725 - 85/4725 = -1/4725
example : (2 / 15 : ℚ) ^ 2 = 84 / 4725 ∧ (1 / 3 : ℚ) * (17 / 315) = 85 / 4725 := by norm_num
example : (2 / 15 : ℚ) ^ 2 - (1 / 3) * (17 / 315) = -1 / 4725 := by norm_num
-- c_3 c_9 - c_5 c_7 = 4/42525
example : (1 / 3 : ℚ) * (62 / 2835) - (2 / 15) * (17 / 315) = 4 / 42525 := by norm_num
-- q_2 = (c_3 c_9 - c_5 c_7) / det = -4/9
example : (4 / 42525 : ℚ) / (-1 / 4725) = -4 / 9 := by norm_num
-- q_4 = (c_7^2 - c_5 c_9) / det = 1/63
example : ((17 / 315 : ℚ) ^ 2 - (2 / 15) * (62 / 2835)) / (-1 / 4725) = 1 / 63 := by norm_num
-- p_3 = c_3 + q_2 c_1 = -1/9 and p_5 = c_5 + q_2 c_3 + q_4 c_1 = 1/945
example : (1 / 3 : ℚ) + (-4 / 9) * 1 = -1 / 9 := by norm_num
example : (2 / 15 : ℚ) + (-4 / 9) * (1 / 3) + (1 / 63) * 1 = 1 / 945 := by norm_num
-- times 945: top 945, -105, 1 and bottom 945, -420, 15
example : (945 : ℚ) * (-1 / 9) = -105 ∧ (945 : ℚ) * (1 / 945) = 1 ∧
    (945 : ℚ) * (-4 / 9) = -420 ∧ (945 : ℚ) * (1 / 63) = 15 := by norm_num
-- top at x = 3/2: 1417.5 - 354.375 + 7.59375 = 1070.71875
example : (945 : ℚ) * (3 / 2) = 2835 / 2 ∧ (105 : ℚ) * (3 / 2) ^ 3 = 2835 / 8 ∧
    ((3 : ℚ) / 2) ^ 5 = 243 / 32 := by norm_num
example : (945 : ℚ) * (3 / 2) - 105 * (3 / 2) ^ 3 + (3 / 2) ^ 5 = 34263 / 32 := by norm_num
-- bottom at x = 3/2: 945 - 945 + 75.9375 = 75.9375
example : (945 : ℚ) - 420 * (3 / 2) ^ 2 + 15 * (3 / 2) ^ 4 = 1215 / 16 := by norm_num
-- ratio: the balloon height 14.1 km
example : ((945 : ℚ) * (3 / 2) - 105 * (3 / 2) ^ 3 + (3 / 2) ^ 5) /
    (945 - 420 * (3 / 2) ^ 2 + 15 * (3 / 2) ^ 4) = 141 / 10 := by norm_num
-- Step 3: the [3/2] pole is sqrt(c_3 / c_5), and c_3 / c_5 = 5/2
example : (1 / 3 : ℚ) / (2 / 15) = 5 / 2 := by norm_num

#print axioms tanAux_mul_cos
#print axioms tanAux_rec
#print axioms sin_coeffs
#print axioms cos_coeffs
#print axioms tanAux_coeffs
#print axioms pade_recipe_matches_series
#print axioms tan_taylor_coefficients
#print axioms pade_five_four_of_tan
