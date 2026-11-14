-- Hashing for size: for an ideal hash, a Bloom filter's false-alarm rate is smallest when half its bits are set, each bit stays 0 in exactly a (1 - 1/m)^(kn) share of all ways the throws can land, and the sketch (t-1)/U_(t) is right on average.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Nat.Factorial.Basic

open Real

lemma bloom_aux_xlogx (x : ℝ) (hx0 : 0 < x) (hx : x ≤ 1 / 2) :
    x * Real.log x ≤ (1 - x) * Real.log (1 - x) := by
  have hy : 0 < 1 - x := by linarith
  have h1 := Real.one_sub_inv_le_log_of_pos (div_pos hy hx0)
  have h2 := Real.one_sub_inv_le_log_of_pos hy
  rw [Real.log_div hy.ne' hx0.ne', inv_div] at h1
  have e1 : x * (1 - x / (1 - x)) = x * (1 - 2 * x) / (1 - x) := by field_simp; ring
  have e2 : 1 - (1 - x)⁻¹ = -(x / (1 - x)) := by field_simp; ring
  rw [e2] at h2
  have h3 : x * (1 - x / (1 - x)) ≤ x * (Real.log (1 - x) - Real.log x) :=
    mul_le_mul_of_nonneg_left h1 hx0.le
  have h4 : 0 ≤ (1 - 2 * x) * (x / (1 - x) + Real.log (1 - x)) :=
    mul_nonneg (by linarith) (by linarith)
  have e3 : (1 - 2 * x) * (x / (1 - x)) = x * (1 - 2 * x) / (1 - x) := by ring
  nlinarith

#print axioms bloom_aux_xlogx

lemma bloom_aux_logprod_half (f : ℝ) (hf0 : 0 < f) (hf : f ≤ 1 / 2) :
    Real.log f * Real.log (1 - f) ≤ Real.log 2 ^ 2 := by
  let F : ℝ → ℝ := fun x => Real.log x * Real.log (1 - x)
  have hmono : MonotoneOn F (Set.Ioc 0 (1 / 2)) := by
    apply monotoneOn_of_deriv_nonneg (convex_Ioc 0 (1 / 2))
    · intro x hx
      have : x ≠ 0 := hx.1.ne'
      have : 1 - x ≠ 0 := by linarith [hx.2]
      apply ContinuousAt.continuousWithinAt
      apply ContinuousAt.mul
      · exact Real.continuousAt_log (by assumption)
      · exact (Real.continuousAt_log (by assumption)).comp (by fun_prop)
    · intro x hx
      rw [interior_Ioc] at hx
      have : x ≠ 0 := hx.1.ne'
      have : 1 - x ≠ 0 := by linarith [hx.2]
      apply DifferentiableAt.differentiableWithinAt
      apply DifferentiableAt.mul
      · exact Real.differentiableAt_log (by assumption)
      · exact (Real.differentiableAt_log (by assumption)).comp x (by fun_prop)
    · intro x hx
      rw [interior_Ioc] at hx
      have hx0 : 0 < x := hx.1
      have hy : 0 < 1 - x := by linarith [hx.2]
      have hd : HasDerivAt F (x⁻¹ * Real.log (1 - x) + Real.log x * ((1 - x)⁻¹ * (-1))) x := by
        have h1 := Real.hasDerivAt_log hx0.ne'
        have h2 : HasDerivAt (fun y : ℝ => 1 - y) (-1) x := by
          simpa using (hasDerivAt_id x).const_sub 1
        have h3 := (Real.hasDerivAt_log hy.ne').comp x h2
        exact h1.mul h3
      rw [hd.deriv]
      have key := bloom_aux_xlogx x hx0 hx.2.le
      have e : x⁻¹ * Real.log (1 - x) + Real.log x * ((1 - x)⁻¹ * (-1))
          = ((1 - x) * Real.log (1 - x) - x * Real.log x) / (x * (1 - x)) := by
        field_simp; ring
      rw [e]
      apply div_nonneg (by linarith) (mul_pos hx0 hy).le
  have := hmono ⟨hf0, hf⟩ ⟨by norm_num, le_refl _⟩ hf
  simp only [F] at this
  have e : (1 : ℝ) - 1 / 2 = 1 / 2 := by norm_num
  rw [e, one_div, Real.log_inv] at this
  nlinarith

#print axioms bloom_aux_logprod_half

lemma bloom_aux_logprod (f : ℝ) (hf0 : 0 < f) (hf1 : f < 1) :
    Real.log f * Real.log (1 - f) ≤ Real.log 2 ^ 2 := by
  rcases le_total f (1 / 2) with h | h
  · exact bloom_aux_logprod_half f hf0 h
  · have := bloom_aux_logprod_half (1 - f) (by linarith) (by linarith)
    rw [sub_sub_cancel] at this
    linarith [mul_comm (Real.log f) (Real.log (1 - f))]

#print axioms bloom_aux_logprod

lemma beta_nat (a b : ℕ) :
    ∫ u in (0 : ℝ)..1, u ^ a * (1 - u) ^ b
      = ((a.factorial : ℝ) * b.factorial) / (a + b + 1).factorial := by
  induction b generalizing a with
  | zero =>
    simp [integral_pow]
    rw [Nat.factorial_succ]; push_cast
    field_simp
  | succ b ih =>
    have e : ∀ u : ℝ, u ^ a * (1 - u) ^ (b + 1) = u ^ a * (1 - u) ^ b - u ^ (a + 1) * (1 - u) ^ b := by
      intro u; ring
    simp_rw [e]
    rw [intervalIntegral.integral_sub (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop), ih a, ih (a + 1)]
    rw [show a + 1 + b + 1 = (a + b + 1) + 1 by ring, show a + (b + 1) + 1 = (a + b + 1) + 1 by ring]
    rw [Nat.factorial_succ (a + b + 1), Nat.factorial_succ a, Nat.factorial_succ b]
    push_cast
    field_simp
    ring

#print axioms beta_nat

/-- Step 3 of the card: in a filter of `m` bits holding `n` items, choose the number of
hashes `k` so that a fraction `f` of the bits is still 0, that is `k = -(m/n) ln f`.
The false-alarm rate `(1 - f)^k` is then smallest when half the bits are set,
`f = 1/2`, where `k = (m/n) ln 2` and the rate is `(1/2)^k`. -/
theorem bloom_false_alarms_least_when_half_bits_set (m n : ℝ) (hm : 0 < m) (hn : 0 < n)
    (f : ℝ) (hf0 : 0 < f) (hf1 : f < 1) :
    (1 / 2 : ℝ) ^ ((m / n) * Real.log 2) ≤ (1 - f) ^ (-(m / n) * Real.log f) := by
  have hy : 0 < 1 - f := by linarith
  rw [Real.rpow_def_of_pos (by norm_num), Real.rpow_def_of_pos hy, Real.exp_le_exp,
    one_div, Real.log_inv]
  have hk := bloom_aux_logprod f hf0 hf1
  have hmn : 0 < m / n := div_pos hm hn
  nlinarith [mul_le_mul_of_nonneg_left hk hmn.le]

/-- Step 1 of the card: storing items makes `N = k n` hash throws into `m` bits. Over all
`m ^ N` equally likely ways the throws can land, the number of bits still 0, added up,
is `m (m - 1) ^ N`. So each bit stays 0 with chance `(1 - 1/m) ^ (k n)`, and that is also
the expected fraction of zeros. -/
theorem bloom_zero_bits_total (m N : ℕ) :
    ∑ g : Fin N → Fin m, (Finset.univ.filter (fun b : Fin m => ∀ i, g i ≠ b)).card
      = m * (m - 1) ^ N := by
  simp only [Finset.card_filter]
  rw [Finset.sum_comm]
  have h : ∀ b : Fin m, (∑ g : Fin N → Fin m, if ∀ i, g i ≠ b then 1 else 0) = (m - 1) ^ N := by
    intro b
    rw [← Finset.card_filter]
    have : (Finset.univ.filter (fun g : Fin N → Fin m => ∀ i, g i ≠ b))
        = Fintype.piFinset (fun _ => Finset.univ.erase b) := by
      ext g; simp [Fintype.mem_piFinset]
    rw [this, Fintype.card_piFinset]
    simp [Finset.card_erase_of_mem]
  rw [Finset.sum_congr rfl (fun b _ => h b)]
  simp

/-- Step 5 of the card: the `t`-th smallest of `D` independent uniform points has density
`D! / ((t-1)! (D-t)!) u^(t-1) (1-u)^(D-t)` on `0 < u < 1`. Averaging the estimate
`(t - 1) / u` against it gives exactly `D`: the sketch is right on average. -/
theorem kmv_sketch_unbiased (D t : ℕ) (ht : 2 ≤ t) (htD : t ≤ D) :
    ∫ u in (0 : ℝ)..1,
      ((t : ℝ) - 1) / u *
        ((D.factorial : ℝ) / ((t - 1).factorial * (D - t).factorial) *
          u ^ (t - 1) * (1 - u) ^ (D - t)) = D := by
  obtain ⟨a, rfl⟩ : ∃ a, t = a + 2 := ⟨t - 2, by omega⟩
  obtain ⟨b, rfl⟩ : ∃ b, D = a + 2 + b := ⟨D - (a + 2), by omega⟩
  have h1 : a + 2 - 1 = a + 1 := by omega
  have h2 : a + 2 + b - (a + 2) = b := by omega
  rw [h1, h2]
  set C : ℝ := ((a + 2 + b).factorial : ℝ) / ((a + 1).factorial * b.factorial)
  have hcongr : ∫ u in (0 : ℝ)..1, (((a + 2 : ℕ) : ℝ) - 1) / u * (C * u ^ (a + 1) * (1 - u) ^ b)
      = ∫ u in (0 : ℝ)..1, (C * (a + 1)) * (u ^ a * (1 - u) ^ b) := by
    apply intervalIntegral.integral_congr_ae
    refine Filter.Eventually.of_forall (fun u hu => ?_)
    rw [Set.uIoc_of_le zero_le_one] at hu
    have : u ≠ 0 := hu.1.ne'
    push_cast
    field_simp
    ring
  rw [hcongr, intervalIntegral.integral_const_mul, beta_nat]
  simp only [C]
  rw [show a + b + 1 = a + 1 + b by ring, show a + 2 + b = (a + 1 + b) + 1 by ring,
    Nat.factorial_succ (a + 1 + b), Nat.factorial_succ a]
  push_cast
  field_simp

-- The toy filter: 8 bits, 2 hashes, 3 items, so 6 throws and 8^6 arrangements.
example : 8 ^ (2 * 3) = 262144 := by norm_num
-- Its average number of bits set, m (1 - (1 - 1/m)^(kn)), as an exact fraction (4.409637...).
example : (8 : ℚ) * (1 - (1 - 1 / 8) ^ (2 * 3)) = 144495 / 32768 := by norm_num
-- The 12 MB budget in bits, and 9.6 bits per URL as 96 tenths.
example : 12000000 * 8 = 96000000 := by norm_num
example : 96000000 * 10 / 10000000 = 96 := by norm_num
-- One 8-byte fingerprint per URL: 80 MB.
example : 8 * 10000000 = 80000000 := by norm_num
-- The sketch: 1,024 values of 8 bytes.
example : 1024 * 8 = 8192 := by norm_num
-- The exact list of 389,921 visitors at 8 bytes each.
example : 389921 * 8 = 3119368 := by norm_num

#print axioms bloom_false_alarms_least_when_half_bits_set
#print axioms bloom_zero_bits_total
#print axioms kmv_sketch_unbiased
