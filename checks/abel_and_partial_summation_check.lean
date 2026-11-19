-- Partial summation: Abel's identity turns a weighted sum into the final running total times the final weight minus an integral, and it carries the prime count π(x) to the log sum θ(x) and back, so θ(x) ~ x exactly when π(x) ~ x/log x.
import Mathlib.NumberTheory.Chebyshev
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Analysis.Asymptotics.AsymptoticEquivalent
import Mathlib.NumberTheory.AbelSummation

open Chebyshev Asymptotics Filter

/-- Helper: Abel's identity when the starting point y is nonnegative, from Mathlib's
`sum_mul_eq_sub_sub_integral_mul`. -/
theorem abel_identity_of_nonneg (a : ℕ → ℝ) {f f' : ℝ → ℝ} {y x : ℝ} (hy : 0 ≤ y) (hyx : y ≤ x)
    (hf : ∀ t ∈ Set.Icc y x, HasDerivAt f (f' t) t) (hf' : ContinuousOn f' (Set.Icc y x)) :
    ∑ n ∈ (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => y < (n : ℝ)), a n * f n =
      (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, a n) * f x - (∑ n ∈ Finset.Icc 1 ⌊y⌋₊, a n) * f y
        - ∫ t in y..x, (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t := by
  set c : ℕ → ℝ := fun n => if n = 0 then 0 else a n with hc
  have hA : ∀ m : ℕ, ∑ n ∈ Finset.Icc 1 m, a n = ∑ n ∈ Finset.Icc 0 m, c n := by
    intro m
    rw [Finset.Icc_eq_cons_Ioc (Nat.zero_le _), Finset.sum_cons, ← Finset.Icc_add_one_left_eq_Ioc]
    simp only [hc, ↓reduceIte, zero_add]
    refine Finset.sum_congr rfl fun n hn => ?_
    have : n ≠ 0 := by simp at hn; omega
    simp [this]
  have hderiv : ∀ t ∈ Set.Icc y x, deriv f t = f' t := fun t ht => (hf t ht).deriv
  have key := sum_mul_eq_sub_sub_integral_mul c hy hyx
    (fun t ht => (hf t ht).differentiableAt)
    (hf'.integrableOn_Icc.congr_fun (fun t ht => (hderiv t ht).symm) measurableSet_Icc)
  have hL : ∑ n ∈ (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => y < (n : ℝ)), a n * f n =
      ∑ k ∈ Finset.Ioc ⌊y⌋₊ ⌊x⌋₊, f k * c k := by
    have hs : (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => y < (n : ℝ)) = Finset.Ioc ⌊y⌋₊ ⌊x⌋₊ := by
      ext n
      simp only [Finset.mem_filter, Finset.mem_Icc, Finset.mem_Ioc, Nat.floor_lt hy]
      constructor
      · rintro ⟨⟨_, h2⟩, h3⟩; exact ⟨h3, h2⟩
      · rintro ⟨h3, h2⟩
        refine ⟨⟨?_, h2⟩, h3⟩
        have : (0 : ℝ) < n := lt_of_le_of_lt hy h3
        exact_mod_cast this
    rw [hs]
    refine Finset.sum_congr rfl fun n hn => ?_
    have : n ≠ 0 := by simp at hn; omega
    simp [hc, this, mul_comm]
  rw [hL, key, hA, hA, intervalIntegral.integral_of_le hyx]
  rw [MeasureTheory.setIntegral_congr_fun measurableSet_Ioc
    (g := fun t => (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t)
    (fun t ht => by simp only; rw [hderiv t (Set.Ioc_subset_Icc_self ht), hA, mul_comm])]
  ring

#print axioms abel_identity_of_nonneg

/-- Helper: π(x) − θ(x)/log x is small next to x/log x. -/
theorem primeCounting_sub_theta_div_log_isLittleO :
    (fun x : ℝ => (Nat.primeCounting ⌊x⌋₊ : ℝ) - θ x / Real.log x) =o[atTop]
      (fun x => x / Real.log x) := by
  refine integral_theta_div_log_sq_isLittleO.congr' ?_ (EventuallyEq.refl _ _)
  filter_upwards [eventually_ge_atTop 2] with x hx
  rw [primeCounting_eq_theta_div_log_add_integral hx]
  ring

#print axioms primeCounting_sub_theta_div_log_isLittleO

/-- Abel's identity. Let a(n) be any numbers, one for each whole number n ≥ 1, and let
A(t) = ∑_{1 ≤ n ≤ t} a(n) be their running total. If the weight f has a continuous slope f'
on [y, x], with y < x, then the weighted sum over y < n ≤ x equals the final running total
times the final weight, minus the starting total times the starting weight, minus the area
under the running total times the slope of the weight:
∑_{y < n ≤ x} a(n) f(n) = A(x) f(x) − A(y) f(y) − ∫_y^x A(t) f'(t) dt. -/
theorem abel_identity (a : ℕ → ℝ) {f f' : ℝ → ℝ} {y x : ℝ} (hyx : y < x)
    (hf : ∀ t ∈ Set.Icc y x, HasDerivAt f (f' t) t) (hf' : ContinuousOn f' (Set.Icc y x)) :
    ∑ n ∈ (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => y < (n : ℝ)), a n * f n =
      (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, a n) * f x - (∑ n ∈ Finset.Icc 1 ⌊y⌋₊, a n) * f y
        - ∫ t in y..x, (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t := by
  rcases le_or_gt 0 y with hy | hy
  · exact abel_identity_of_nonneg a hy hyx.le hf hf'
  have hzero : ∀ t : ℝ, t ≤ 0 → (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t = 0 := by
    intro t ht
    simp [Nat.floor_eq_zero.mpr (lt_of_le_of_lt ht one_pos)]
  have hAy : ∑ n ∈ Finset.Icc 1 ⌊y⌋₊, a n = 0 := by
    simp [Nat.floor_eq_zero.mpr (lt_trans hy one_pos)]
  rcases le_or_gt x 0 with hx | hx
  · have hfx : ⌊x⌋₊ = 0 := Nat.floor_eq_zero.mpr (lt_of_le_of_lt hx one_pos)
    have hI : ∫ t in y..x, (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t = ∫ t in y..x, (0 : ℝ) :=
      intervalIntegral.integral_congr fun t ht => by
        rw [Set.uIcc_of_le hyx.le] at ht
        exact hzero t (ht.2.trans hx)
    rw [hI, hAy, hfx]
    simp
  · have h0 := abel_identity_of_nonneg a le_rfl hx.le
      (fun t ht => hf t ⟨hy.le.trans ht.1, ht.2⟩)
      (hf'.mono fun t ht => ⟨hy.le.trans ht.1, ht.2⟩)
    have hs : (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => y < (n : ℝ)) =
        (Finset.Icc 1 ⌊x⌋₊).filter (fun n : ℕ => (0 : ℝ) < (n : ℝ)) := by
      ext n
      simp only [Finset.mem_filter, Finset.mem_Icc]
      constructor
      · rintro ⟨⟨h1, h2⟩, _⟩
        exact ⟨⟨h1, h2⟩, by exact_mod_cast h1⟩
      · rintro ⟨⟨h1, h2⟩, h3⟩
        exact ⟨⟨h1, h2⟩, hy.trans h3⟩
    have hint0 : IntervalIntegrable (fun t => (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t)
        MeasureTheory.volume y 0 := by
      rw [intervalIntegrable_iff_integrableOn_Icc_of_le hy.le]
      exact (MeasureTheory.integrableOn_zero).congr_fun
        (fun t ht => (hzero t ht.2).symm) measurableSet_Icc
    have hzero' : ∫ t in y..0, (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)) fun t ht => by
        rw [Set.uIcc_of_le hy.le] at ht
        exact hzero t ht.2]
      simp
    have hint1 : IntervalIntegrable (fun t => (∑ n ∈ Finset.Icc 1 ⌊t⌋₊, a n) * f' t)
        MeasureTheory.volume 0 x := by
      rw [intervalIntegrable_iff_integrableOn_Icc_of_le hx.le]
      have h := integrableOn_mul_sum_Icc a (m := 1) le_rfl
        ((hf'.mono fun t (ht : t ∈ Set.Icc 0 x) => ⟨hy.le.trans ht.1, ht.2⟩).integrableOn_Icc)
      simpa only [mul_comm] using h
    rw [← intervalIntegral.integral_add_adjacent_intervals hint0 hint1, hzero', zero_add, hs,
      hAy, h0]
    simp

/-- The two directions of partial summation for primes, for every x ≥ 2.
Count to log sum: θ(x) = π(x) log x − ∫_2^x π(t)/t dt.
Log sum to count: π(x) = θ(x)/log x + ∫_2^x θ(t)/(t log² t) dt. -/
theorem theta_and_primeCounting_by_partial_summation {x : ℝ} (hx : 2 ≤ x) :
    θ x = (Nat.primeCounting ⌊x⌋₊ : ℝ) * Real.log x
        - ∫ t in (2 : ℝ)..x, (Nat.primeCounting ⌊t⌋₊ : ℝ) / t ∧
      (Nat.primeCounting ⌊x⌋₊ : ℝ) = θ x / Real.log x
        + ∫ t in (2 : ℝ)..x, θ t / (t * Real.log t ^ 2) := by
  exact ⟨theta_eq_primeCounting_mul_log_sub_integral hx,
    primeCounting_eq_theta_div_log_add_integral hx⟩

/-- The two forms of the prime number theorem imply each other: θ(x) ~ x holds exactly when
π(x) ~ x/log x holds, as x → ∞. -/
theorem theta_equiv_id_iff_primeCounting_equiv_div_log :
    (fun x : ℝ => θ x) ~[atTop] (fun x => x) ↔
      (fun x : ℝ => (Nat.primeCounting ⌊x⌋₊ : ℝ)) ~[atTop] (fun x => x / Real.log x) := by
  have hE := primeCounting_sub_theta_div_log_isLittleO
  constructor
  · intro h
    have h1 : (fun x : ℝ => θ x / Real.log x) ~[atTop] (fun x => x / Real.log x) :=
      h.div IsEquivalent.refl
    have h2 := h1.add_isLittleO hE
    refine h2.congr_left (Eventually.of_forall fun x => ?_)
    simp
  · intro h
    have h1 : (fun x : ℝ => θ x / Real.log x) ~[atTop] (fun x => x / Real.log x) := by
      have h2 := h.sub_isLittleO hE
      refine h2.congr_left (Eventually.of_forall fun x => ?_)
      simp
    have h3 := h1.mul (IsEquivalent.refl (u := fun x : ℝ => Real.log x))
    refine (h3.congr_left ?_).congr_right ?_
    · filter_upwards [eventually_gt_atTop 1] with x hx
      have : Real.log x ≠ 0 := (Real.log_pos hx).ne'
      simp only [Pi.mul_apply]
      field_simp
    · filter_upwards [eventually_gt_atTop 1] with x hx
      have : Real.log x ≠ 0 := (Real.log_pos hx).ne'
      simp only [Pi.mul_apply]
      field_simp

-- The hand case x = 10: the primes up to 10 are 2, 3, 5 and 7, so π(10) = 4.
example : (Finset.range 11).filter Nat.Prime = {2, 3, 5, 7} := by decide
example : Nat.primeCounting 10 = 4 := by
  simp [Nat.primeCounting, Nat.primeCounting', Nat.count_eq_card_filter_range]
  decide

-- θ(10) = log 2 + log 3 + log 5 + log 7 = log 210, the log of the product of the primes up to 10.
example : primorial 10 = 210 := by decide
example : 2 * 3 * 5 * 7 = 210 := by norm_num

-- The jumping weight: 1 for primes up to 500,000, 2 above. With π(500,000) = 41,538 and
-- π(1,000,000) = 78,498, the true sum is 115,458; the slope-only formula gives 2 × 78,498 = 156,996;
-- the jump term −41,538 × 1 restores 115,458.
example : 41538 * 1 + (78498 - 41538) * 2 = 115458 := by norm_num
example : 2 * 78498 = 156996 := by norm_num
example : 156996 - 41538 * 1 = 115458 := by norm_num

#print axioms abel_identity
#print axioms theta_and_primeCounting_by_partial_summation
#print axioms theta_equiv_id_iff_primeCounting_equiv_div_log
