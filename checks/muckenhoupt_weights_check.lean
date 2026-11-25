-- Muckenhoupt weights: the power weight |x|^γ passes the A₂ test on every bounded interval exactly when −1 < γ < 1, its A₂ product on [0, a] is 1/(1 − γ²), and the A₂ constant of |x|^(1/2) is 3/2.
import Mathlib.MeasureTheory.Integral.Average
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory Set

/-- Interval integrability of |x|^r on [0, c] for c ≥ 0 and r > −1. -/
theorem muck_ii_nonneg {r c : ℝ} (hr : -1 < r) (hc : 0 ≤ c) :
    IntervalIntegrable (fun x : ℝ => |x| ^ r) volume 0 c := by
  have h := intervalIntegral.intervalIntegrable_rpow' (a := 0) (b := c) hr
  rw [intervalIntegrable_iff, uIoc_of_le hc] at h ⊢
  exact h.congr_fun (fun x hx => by simp only [abs_of_pos hx.1]) measurableSet_Ioc

/-- Interval integrability of |x|^r on any interval for r > −1. -/
theorem muck_ii {r : ℝ} (hr : -1 < r) (a b : ℝ) :
    IntervalIntegrable (fun x : ℝ => |x| ^ r) volume a b := by
  have h0 : ∀ c : ℝ, IntervalIntegrable (fun x : ℝ => |x| ^ r) volume 0 c := by
    intro c
    rcases le_total 0 c with hc | hc
    · exact muck_ii_nonneg hr hc
    · have h := muck_ii_nonneg hr (neg_nonneg.2 hc)
      rw [IntervalIntegrable.iff_comp_neg] at h
      simpa only [abs_neg, neg_neg, neg_zero] using h
  exact (h0 a).symm.trans (h0 b)

/-- ∫₀ᵗ |x|^r dx = t^(r+1)/(r+1) for t ≥ 0. -/
theorem muck_int_nonneg {r t : ℝ} (hr : -1 < r) (ht : 0 ≤ t) :
    ∫ x in (0 : ℝ)..t, |x| ^ r = t ^ (r + 1) / (r + 1) := by
  rw [intervalIntegral.integral_congr (g := fun x : ℝ => x ^ r), integral_rpow (Or.inl hr),
    Real.zero_rpow (by linarith : r + 1 ≠ 0), sub_zero]
  intro x hx
  rw [uIcc_of_le ht] at hx
  simp only [abs_of_nonneg hx.1]

/-- ∫₀ᵗ |x|^r dx = −((−t)^(r+1)/(r+1)) for t ≤ 0. -/
theorem muck_int_nonpos {r t : ℝ} (hr : -1 < r) (ht : t ≤ 0) :
    ∫ x in (0 : ℝ)..t, |x| ^ r = -((-t) ^ (r + 1) / (r + 1)) := by
  have h := intervalIntegral.integral_comp_neg (a := 0) (b := -t) (fun x : ℝ => |x| ^ r)
  simp only [abs_neg, neg_neg, neg_zero] at h
  rw [intervalIntegral.integral_symm, ← h, muck_int_nonneg hr (by linarith)]

/-- ∫ₐᵇ |x|^r dx as a difference of the two integrals from 0. -/
theorem muck_int_sub {r : ℝ} (hr : -1 < r) (a b : ℝ) :
    ∫ x in a..b, |x| ^ r = (∫ x in (0 : ℝ)..b, |x| ^ r) - ∫ x in (0 : ℝ)..a, |x| ^ r :=
  (intervalIntegral.integral_interval_sub_left (muck_ii hr 0 b) (muck_ii hr 0 a)).symm

/-- The average over [a, b] is the interval integral divided by the length. -/
theorem muck_avg_eq (f : ℝ → ℝ) {a b : ℝ} (hab : a < b) :
    ⨍ x in Icc a b, f x = (∫ x in a..b, f x) / (b - a) := by
  rw [setAverage_eq, Real.volume_real_Icc_of_le hab.le, integral_Icc_eq_integral_Ioc,
    ← intervalIntegral.integral_of_le hab.le, smul_eq_mul, div_eq_inv_mul]

/-- The A₂ product of |x|^γ is at most 4/(1 − γ) on every interval when 0 ≤ γ < 1. -/
theorem muck_bound {γ : ℝ} (hγ0 : 0 ≤ γ) (hγ1 : γ < 1) {a b : ℝ} (hab : a < b) :
    (⨍ x in Icc a b, |x| ^ γ) * (⨍ x in Icc a b, |x| ^ (-γ)) ≤ 4 / (1 - γ) := by
  rw [muck_avg_eq _ hab, muck_avg_eq _ hab]
  have hr1 : -1 < γ := by linarith
  have hr2 : -1 < -γ := by linarith
  have hLpos : 0 < b - a := by linarith
  obtain ⟨M, hM⟩ : ∃ M, M = max |a| |b| := ⟨_, rfl⟩
  have haM : |a| ≤ M := hM ▸ le_max_left _ _
  have hbM : |b| ≤ M := hM ▸ le_max_right _ _
  have hab1 := neg_abs_le a
  have hab2 := le_abs_self b
  have hab3 := le_abs_self a
  have hab4 := neg_abs_le b
  have hLM : b - a ≤ 2 * M := by linarith
  have hMpos : 0 < M := by linarith
  have hI1nn : 0 ≤ ∫ x in a..b, |x| ^ γ := intervalIntegral.integral_nonneg hab.le
    (fun x _ => Real.rpow_nonneg (abs_nonneg x) _)
  have hI2nn : 0 ≤ ∫ x in a..b, |x| ^ (-γ) := intervalIntegral.integral_nonneg hab.le
    (fun x _ => Real.rpow_nonneg (abs_nonneg x) _)
  have hxM : ∀ x ∈ Icc a b, |x| ≤ M := by
    intro x hx
    rw [abs_le]
    constructor <;> linarith [hx.1, hx.2]
  have hI1le : (∫ x in a..b, |x| ^ γ) ≤ M ^ γ * (b - a) := by
    have h := intervalIntegral.integral_mono_on (f := fun x : ℝ => |x| ^ γ)
      (g := fun _ => M ^ γ) hab.le (muck_ii hr1 a b) intervalIntegrable_const
      (fun x hx => Real.rpow_le_rpow (abs_nonneg x) (hxM x hx) hγ0)
    simp only [intervalIntegral.integral_const, smul_eq_mul] at h
    linarith [h]
  have hPpos : 0 < M ^ γ := Real.rpow_pos_of_pos hMpos γ
  have hPQ : M ^ γ * M ^ (-γ) = 1 := by
    rw [Real.rpow_neg hMpos.le, mul_inv_cancel₀ hPpos.ne']
  have hK : 0 < 1 - γ := by linarith
  rw [div_mul_div_comm, div_le_div_iff₀ (mul_pos hLpos hLpos) hK]
  rcases le_or_gt M (2 * (b - a)) with hcase | hcase
  · -- the interval sits inside [−M, M] with M ≤ 2L
    have hI2le : (∫ x in a..b, |x| ^ (-γ)) ≤ ∫ x in (-M)..M, |x| ^ (-γ) :=
      intervalIntegral.integral_mono_interval (by linarith) hab.le
        (by linarith) (Filter.Eventually.of_forall
          (fun x => Real.rpow_nonneg (abs_nonneg x) _)) (muck_ii hr2 _ _)
    rw [muck_int_sub hr2 (-M) M, muck_int_nonneg hr2 hMpos.le,
      muck_int_nonpos hr2 (by linarith : -M ≤ 0), neg_neg, Real.rpow_add_one hMpos.ne'] at hI2le
    have hI2le' : (∫ x in a..b, |x| ^ (-γ)) * (1 - γ) ≤ 2 * (M ^ (-γ) * M) := by
      have e : M ^ (-γ) * M / (-γ + 1) - -(M ^ (-γ) * M / (-γ + 1)) =
          2 * (M ^ (-γ) * M) / (1 - γ) := by ring
      rw [e, le_div_iff₀ hK] at hI2le
      exact hI2le
    have h3 := mul_le_mul hI1le hI2le' (mul_nonneg hI2nn hK.le) (mul_nonneg hPpos.le hLpos.le)
    have e2 : M ^ γ * (b - a) * (2 * (M ^ (-γ) * M)) =
        2 * (b - a) * M * (M ^ γ * M ^ (-γ)) := by ring
    rw [e2, hPQ] at h3
    nlinarith
  · -- the interval stays away from 0: |x| ≥ M/2 on it
    have hxlow : ∀ x ∈ Icc a b, M / 2 ≤ |x| := by
      intro x hx
      obtain ⟨hxa, hxb⟩ := hx
      have h1 := abs_sub_abs_le_abs_sub a x
      have h2 := abs_sub_abs_le_abs_sub b x
      rw [abs_of_nonpos (by linarith : a - x ≤ 0)] at h1
      rw [abs_of_nonneg (by linarith : 0 ≤ b - x)] at h2
      have h3 : M ≤ |x| + (b - a) := by
        rw [hM]; exact max_le (by linarith) (by linarith)
      linarith
    have hM2 : 0 < M / 2 := by linarith
    have hI2le : (∫ x in a..b, |x| ^ (-γ)) ≤ (M / 2) ^ (-γ) * (b - a) := by
      have h := intervalIntegral.integral_mono_on (f := fun x : ℝ => |x| ^ (-γ))
        (g := fun _ => (M / 2) ^ (-γ)) hab.le (muck_ii hr2 a b) intervalIntegrable_const
        (fun x hx => Real.rpow_le_rpow_of_nonpos hM2 (hxlow x hx) (by linarith))
      simp only [intervalIntegral.integral_const, smul_eq_mul] at h
      linarith [h]
    have h3 := mul_le_mul hI1le hI2le hI2nn (mul_nonneg hPpos.le hLpos.le)
    have h2pow : M ^ γ * (M / 2) ^ (-γ) = 2 ^ γ := by
      rw [Real.rpow_neg hM2.le, Real.div_rpow hMpos.le (by norm_num)]
      have : (0 : ℝ) < 2 ^ γ := Real.rpow_pos_of_pos (by norm_num) γ
      field_simp
    have h2le : (2 : ℝ) ^ γ ≤ 2 := by
      have := Real.rpow_le_rpow_of_exponent_le (x := 2) (by norm_num) hγ1.le
      simpa using this
    have e2 : M ^ γ * (b - a) * ((M / 2) ^ (-γ) * (b - a)) =
        (b - a) ^ 2 * (M ^ γ * (M / 2) ^ (-γ)) := by ring
    rw [e2, h2pow] at h3
    nlinarith [mul_le_mul_of_nonneg_right h3 hK.le, sq_nonneg (b - a),
      mul_le_mul_of_nonneg_left h2le (sq_nonneg (b - a))]

/-- ∫₀ᵗ of |x|^(1/2) and |x|^(−1/2) for t ≥ 0, in terms of √t. -/
theorem muck_half_nonneg {t : ℝ} (ht : 0 ≤ t) :
    (∫ x in (0 : ℝ)..t, |x| ^ (1 / 2 : ℝ)) = 2 / 3 * Real.sqrt t ^ 3 ∧
      (∫ x in (0 : ℝ)..t, |x| ^ (-(1 / 2 : ℝ))) = 2 * Real.sqrt t := by
  constructor
  · rw [muck_int_nonneg (by norm_num) ht, Real.rpow_add' ht (by norm_num), Real.rpow_one,
      ← Real.sqrt_eq_rpow]
    nth_rewrite 2 [← Real.sq_sqrt ht]
    ring
  · rw [muck_int_nonneg (by norm_num) ht]
    have e : -(1 / 2 : ℝ) + 1 = 1 / 2 := by norm_num
    rw [e, ← Real.sqrt_eq_rpow]
    ring

/-- ∫₀ᵗ of |x|^(1/2) and |x|^(−1/2) for t ≤ 0, in terms of √(−t). -/
theorem muck_half_nonpos {t : ℝ} (ht : t ≤ 0) :
    (∫ x in (0 : ℝ)..t, |x| ^ (1 / 2 : ℝ)) = -(2 / 3 * Real.sqrt (-t) ^ 3) ∧
      (∫ x in (0 : ℝ)..t, |x| ^ (-(1 / 2 : ℝ))) = -(2 * Real.sqrt (-t)) := by
  have ht' : 0 ≤ -t := by linarith
  have h := muck_half_nonneg ht'
  rw [muck_int_nonneg (by norm_num) ht', muck_int_nonneg (by norm_num) ht'] at h
  rw [muck_int_nonpos (by norm_num) ht, muck_int_nonpos (by norm_num) ht, h.1, h.2]
  exact ⟨rfl, rfl⟩

/-- The A₂ product of |x|^(1/2) on [a, b], written through the two integrals from 0. -/
theorem muck_half_prod {a b : ℝ} (hab : a < b) :
    (⨍ x in Icc a b, |x| ^ (1 / 2 : ℝ)) * (⨍ x in Icc a b, |x| ^ (-(1 / 2 : ℝ))) =
      ((∫ x in (0 : ℝ)..b, |x| ^ (1 / 2 : ℝ)) - ∫ x in (0 : ℝ)..a, |x| ^ (1 / 2 : ℝ)) *
        ((∫ x in (0 : ℝ)..b, |x| ^ (-(1 / 2 : ℝ))) - ∫ x in (0 : ℝ)..a, |x| ^ (-(1 / 2 : ℝ))) /
        (b - a) ^ 2 := by
  rw [muck_avg_eq _ hab, muck_avg_eq _ hab, muck_int_sub (r := 1 / 2) (by norm_num) a b,
    muck_int_sub (r := -(1 / 2)) (by norm_num) a b, div_mul_div_comm, sq]

/-- No interval gives an A₂ product above 3/2 for |x|^(1/2). -/
theorem muck_half_le {a b : ℝ} (hab : a < b) :
    (⨍ x in Icc a b, |x| ^ (1 / 2 : ℝ)) * (⨍ x in Icc a b, |x| ^ (-(1 / 2 : ℝ))) ≤ 3 / 2 := by
  rw [muck_half_prod hab, div_le_iff₀ (pow_pos (sub_pos.2 hab) 2)]
  rcases le_total 0 a with ha | ha
  · have hb : 0 ≤ b := by linarith
    obtain ⟨hb1, hb2⟩ := muck_half_nonneg hb
    obtain ⟨ha1, ha2⟩ := muck_half_nonneg ha
    rw [hb1, hb2, ha1, ha2]
    have hu := Real.sqrt_nonneg a
    have hv := Real.sqrt_nonneg b
    have e : b - a = Real.sqrt b ^ 2 - Real.sqrt a ^ 2 := by
      rw [Real.sq_sqrt hb, Real.sq_sqrt ha]
    rw [e]
    set u := Real.sqrt a
    set v := Real.sqrt b
    have key : 3 / 2 * (v ^ 2 - u ^ 2) ^ 2 - (2 / 3 * v ^ 3 - 2 / 3 * u ^ 3) * (2 * v - 2 * u) =
        (v - u) ^ 2 * ((v ^ 2 + u ^ 2) / 6 + 5 / 3 * (u * v)) := by ring
    nlinarith [mul_nonneg (sq_nonneg (v - u)) (add_nonneg (div_nonneg (add_nonneg (sq_nonneg v)
      (sq_nonneg u)) (by norm_num : (0 : ℝ) ≤ 6)) (mul_nonneg (by norm_num : (0 : ℝ) ≤ 5 / 3)
      (mul_nonneg hu hv)))]
  · rcases le_total 0 b with hb | hb
    · obtain ⟨hb1, hb2⟩ := muck_half_nonneg hb
      obtain ⟨ha1, ha2⟩ := muck_half_nonpos ha
      rw [hb1, hb2, ha1, ha2]
      have ha' : 0 ≤ -a := by linarith
      have e : b - a = Real.sqrt b ^ 2 + Real.sqrt (-a) ^ 2 := by
        rw [Real.sq_sqrt hb, Real.sq_sqrt ha']; ring
      rw [e]
      set u := Real.sqrt (-a)
      set v := Real.sqrt b
      have key : 3 / 2 * (v ^ 2 + u ^ 2) ^ 2 -
          (2 / 3 * v ^ 3 - -(2 / 3 * u ^ 3)) * (2 * v - -(2 * u)) =
          (u ^ 2 - 4 * u * v + v ^ 2) ^ 2 / 6 := by ring
      nlinarith [sq_nonneg (u ^ 2 - 4 * u * v + v ^ 2)]
    · obtain ⟨hb1, hb2⟩ := muck_half_nonpos hb
      obtain ⟨ha1, ha2⟩ := muck_half_nonpos ha
      rw [hb1, hb2, ha1, ha2]
      have ha' : 0 ≤ -a := by linarith
      have hb' : 0 ≤ -b := by linarith
      have e : b - a = Real.sqrt (-a) ^ 2 - Real.sqrt (-b) ^ 2 := by
        rw [Real.sq_sqrt hb', Real.sq_sqrt ha']; ring
      rw [e]
      have hu := Real.sqrt_nonneg (-a)
      have hv := Real.sqrt_nonneg (-b)
      set u := Real.sqrt (-a)
      set v := Real.sqrt (-b)
      have key : 3 / 2 * (u ^ 2 - v ^ 2) ^ 2 -
          (-(2 / 3 * v ^ 3) - -(2 / 3 * u ^ 3)) * (-(2 * v) - -(2 * u)) =
          (u - v) ^ 2 * ((v ^ 2 + u ^ 2) / 6 + 5 / 3 * (u * v)) := by ring
      nlinarith [mul_nonneg (sq_nonneg (u - v)) (add_nonneg (div_nonneg (add_nonneg (sq_nonneg v)
        (sq_nonneg u)) (by norm_num : (0 : ℝ) ≤ 6)) (mul_nonneg (by norm_num : (0 : ℝ) ≤ 5 / 3)
        (mul_nonneg hu hv)))]

/-- The interval [−(2 − √3)², 1] gives A₂ product exactly 3/2 for |x|^(1/2). -/
theorem muck_half_eq :
    (⨍ x in Icc (-(2 - Real.sqrt 3) ^ 2) 1, |x| ^ (1 / 2 : ℝ)) *
        (⨍ x in Icc (-(2 - Real.sqrt 3) ^ 2) 1, |x| ^ (-(1 / 2 : ℝ))) = 3 / 2 := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hs0 := Real.sqrt_nonneg 3
  have hu0 : 0 ≤ 2 - Real.sqrt 3 := by nlinarith
  have ha : -(2 - Real.sqrt 3) ^ 2 ≤ 0 := by nlinarith
  have hab : -(2 - Real.sqrt 3) ^ 2 < 1 := by linarith
  rw [muck_half_prod hab]
  obtain ⟨hb1, hb2⟩ := muck_half_nonneg (zero_le_one' ℝ)
  obtain ⟨ha1, ha2⟩ := muck_half_nonpos ha
  rw [hb1, hb2, ha1, ha2, neg_neg, Real.sqrt_sq hu0, Real.sqrt_one]
  set u := 2 - Real.sqrt 3 with hu
  have hq : u ^ 2 - 4 * u + 1 = 0 := by rw [hu]; nlinarith
  have hden : (1 - -u ^ 2) ^ 2 ≠ 0 := pow_ne_zero 2 (by nlinarith [sq_nonneg u])
  rw [div_eq_iff hden]
  linear_combination (-(1 / 6) * (u ^ 2 - 4 * u + 1)) * hq


/-- The power weight w(x) = |x|^γ is a Muckenhoupt A₂ weight exactly when −1 < γ < 1:
both w and its reciprocal 1/w = |x|^(−γ) have finite integrals over every bounded interval,
and on every interval I the average of w times the average of 1/w stays below one fixed
number C. -/
theorem rpow_abs_mem_A2_iff (γ : ℝ) :
    ((∀ a b : ℝ, a < b →
        IntegrableOn (fun x : ℝ => |x| ^ γ) (Icc a b) ∧
        IntegrableOn (fun x : ℝ => |x| ^ (-γ)) (Icc a b)) ∧
      ∃ C : ℝ, ∀ a b : ℝ, a < b →
        (⨍ x in Icc a b, |x| ^ γ) * (⨍ x in Icc a b, |x| ^ (-γ)) ≤ C) ↔
    (-1 < γ ∧ γ < 1) := by
  constructor
  · rintro ⟨hint, -⟩
    obtain ⟨h1, h2⟩ := hint 0 1 one_pos
    have key : ∀ s : ℝ, IntegrableOn (fun x : ℝ => |x| ^ s) (Icc 0 1) → -1 < s := by
      intro s hs
      rw [← intervalIntegral.integrableOn_Ioo_rpow_iff one_pos]
      exact (hs.mono_set Ioo_subset_Icc_self).congr_fun
        (fun x hx => by simp only [abs_of_pos hx.1]) measurableSet_Ioo
    have k1 := key _ h1
    have k2 := key _ h2
    constructor <;> linarith
  · rintro ⟨h1, h2⟩
    refine ⟨fun a b hab => ⟨?_, ?_⟩, ?_⟩
    · exact (intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).1 (muck_ii h1 a b)
    · exact (intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).1
        (muck_ii (by linarith) a b)
    · rcases le_total 0 γ with hγ | hγ
      · exact ⟨4 / (1 - γ), fun a b hab => muck_bound hγ h2 hab⟩
      · refine ⟨4 / (1 - -γ), fun a b hab => ?_⟩
        have h := muck_bound (γ := -γ) (by linarith) (by linarith) hab
        rw [neg_neg, mul_comm] at h
        exact h

/-- On every interval [0, a] with a > 0, the A₂ product of the power weight |x|^γ
(average of w times average of 1/w) is exactly 1/(1 − γ²), whatever the scale a,
when −1 < γ < 1. -/
theorem A2_product_rpow_abs_Icc_zero (γ : ℝ) (hγ₁ : -1 < γ) (hγ₂ : γ < 1) (a : ℝ) (ha : 0 < a) :
    (⨍ x in Icc 0 a, |x| ^ γ) * (⨍ x in Icc 0 a, |x| ^ (-γ)) = 1 / (1 - γ ^ 2) := by
  rw [muck_avg_eq _ ha, muck_avg_eq _ ha, muck_int_nonneg (by linarith) ha.le,
    muck_int_nonneg (by linarith) ha.le, Real.rpow_add_one ha.ne', Real.rpow_add_one ha.ne']
  have hP : a ^ γ * a ^ (-γ) = 1 := by
    rw [Real.rpow_neg ha.le, mul_inv_cancel₀ (Real.rpow_pos_of_pos ha γ).ne']
  have h1 : γ + 1 ≠ 0 := by linarith
  have h2 : -γ + 1 ≠ 0 := by linarith
  have h3 : 1 - γ ^ 2 ≠ 0 := by nlinarith
  rw [sub_zero]
  have e : a ^ γ * a / (γ + 1) / a * (a ^ (-γ) * a / (-γ + 1) / a) =
      (a ^ γ * a ^ (-γ)) / ((γ + 1) * (-γ + 1)) := by
    field_simp
  rw [e, hP]
  congr 1
  ring

/-- The A₂ constant of the weight |x|^(1/2) is exactly 3/2: no interval [a, b] gives an
A₂ product above 3/2, and the interval [−(2 − √3)², 1], which pokes just past 0,
gives exactly 3/2. -/
theorem A2_constant_rpow_abs_half :
    IsGreatest
      {q : ℝ | ∃ a b : ℝ, a < b ∧
        q = (⨍ x in Icc a b, |x| ^ (1 / 2 : ℝ)) * (⨍ x in Icc a b, |x| ^ (-(1 / 2 : ℝ)))}
      (3 / 2) ∧
    (⨍ x in Icc (-(2 - Real.sqrt 3) ^ 2) 1, |x| ^ (1 / 2 : ℝ)) *
        (⨍ x in Icc (-(2 - Real.sqrt 3) ^ 2) 1, |x| ^ (-(1 / 2 : ℝ))) = 3 / 2 := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hs0 := Real.sqrt_nonneg 3
  have hab : -(2 - Real.sqrt 3) ^ 2 < 1 := by nlinarith
  refine ⟨⟨⟨-(2 - Real.sqrt 3) ^ 2, 1, hab, muck_half_eq.symm⟩, ?_⟩, muck_half_eq⟩
  rintro q ⟨a, b, hab', rfl⟩
  exact muck_half_le hab'

-- Worked numbers: the product on [0, a] for γ = 1/2 is 1/(1 − 1/4) = 4/3.
example : (1 : ℚ) / (1 - (1 / 2) ^ 2) = 4 / 3 := by norm_num
-- Average of w on [0, 1] is 1/1.5 = 2/3, of 1/w is 1/0.5 = 2; their product is 4/3.
example : (1 / (3 / 2) : ℚ) * (1 / (1 / 2)) = 4 / 3 := by norm_num
-- On [0, 0.01] and [0, 100]: (1/15) × 20 and (20/3) × (1/5), both 4/3.
example : (1 / 15 : ℚ) * 20 = 4 / 3 ∧ (20 / 3 : ℚ) * (1 / 5) = 4 / 3 := by norm_num
-- By hand: at the best y = 1/4 the product (4/3)(1 + y − 2y²) is (4/3)(9/8) = 3/2.
example : (4 / 3 : ℚ) * (1 + 1 / 4 - 2 * (1 / 4) ^ 2) = 3 / 2 := by norm_num
-- The best r = 2 − √3 solves r² − 4r + 1 = 0.
example : (2 - Real.sqrt 3) ^ 2 - 4 * (2 - Real.sqrt 3) + 1 = 0 := by
  nlinarith [Real.sq_sqrt (show (0 : ℝ) ≤ 3 by norm_num)]
-- The weak bound 9 [w]_A₂² with [w]_A₂ = 3/2 is 81/4 = 20.25.
example : (9 : ℚ) * (3 / 2) ^ 2 = 81 / 4 := by norm_num
-- Table: 1/(1 − γ²) at γ = 1/4 and γ = 3/4 is 16/15 and 16/7.
example : (1 : ℚ) / (1 - (1 / 4) ^ 2) = 16 / 15 ∧ (1 : ℚ) / (1 - (3 / 4) ^ 2) = 16 / 7 := by norm_num

#print axioms muck_ii_nonneg
#print axioms muck_ii
#print axioms muck_int_nonneg
#print axioms muck_int_nonpos
#print axioms muck_int_sub
#print axioms muck_avg_eq
#print axioms muck_bound
#print axioms muck_half_nonneg
#print axioms muck_half_nonpos
#print axioms muck_half_prod
#print axioms muck_half_le
#print axioms muck_half_eq
#print axioms rpow_abs_mem_A2_iff
#print axioms A2_product_rpow_abs_Icc_zero
#print axioms A2_constant_rpow_abs_half
