-- Branch cuts and complex powers: the principal power z ^ a jumps by the factor e^(2πia) across the negative real axis, the values e^(a·L) over all logarithms L of z are z ^ a times e^(2πiak), and there are q of them when a = p/q in lowest terms and infinitely many when a is not rational.
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Data.Set.Card

open Complex Filter Topology Real

lemma branch_set_eq_range (z a : ℂ) (hz : z ≠ 0) :
    {w : ℂ | ∃ L : ℂ, exp L = z ∧ w = exp (a * L)} =
      Set.range (fun k : ℤ => z ^ a * exp (2 * π * I * a * k)) := by
  ext w
  simp only [Set.mem_ofPred_eq, Set.mem_range]
  constructor
  · rintro ⟨L, hL, rfl⟩
    rw [← Complex.exp_log hz, exp_eq_exp_iff_exists_int] at hL
    obtain ⟨n, rfl⟩ := hL
    refine ⟨n, ?_⟩
    rw [cpow_def_of_ne_zero hz, ← Complex.exp_add]; ring_nf
  · rintro ⟨k, rfl⟩
    refine ⟨Complex.log z + k * (2 * π * I), ?_, ?_⟩
    · rw [Complex.exp_add, Complex.exp_log hz, exp_int_mul_two_pi_mul_I, mul_one]
    · rw [cpow_def_of_ne_zero hz, ← Complex.exp_add]; ring_nf

lemma branch_value_eq_iff (z a : ℂ) (hz : z ≠ 0) (k k' : ℤ) :
    z ^ a * exp (2 * π * I * a * k) = z ^ a * exp (2 * π * I * a * k') ↔
      ∃ n : ℤ, a * k = a * k' + n := by
  have h0 : z ^ a ≠ 0 := by rw [cpow_def_of_ne_zero hz]; exact Complex.exp_ne_zero _
  rw [mul_right_inj' h0, exp_eq_exp_iff_exists_int]
  have h2 : (2 * π * I : ℂ) ≠ 0 := two_pi_I_ne_zero
  constructor
  · rintro ⟨n, hn⟩
    refine ⟨n, ?_⟩
    apply mul_left_cancel₀ h2
    linear_combination hn
  · rintro ⟨n, hn⟩
    refine ⟨n, ?_⟩
    linear_combination (2 * π * I) * hn

#print axioms branch_set_eq_range
#print axioms branch_value_eq_iff

/-- Crossing the cut. Take a point x on the negative real axis and any exponent a.
Approached from just above (imaginary part positive), the principal power z ^ a tends to
x ^ a; approached from just below, it tends to x ^ a · e^(−2πia). So stepping up across the
cut multiplies the principal value by e^(2πia). -/
theorem principal_power_jumps_by_exp_two_pi_i_a_across_cut (x : ℝ) (hx : x < 0) (a : ℂ) :
    Tendsto (fun z : ℂ => z ^ a) (𝓝[{z : ℂ | 0 < z.im}] (x : ℂ)) (𝓝 ((x : ℂ) ^ a)) ∧
    Tendsto (fun z : ℂ => z ^ a) (𝓝[{z : ℂ | z.im < 0}] (x : ℂ))
      (𝓝 ((x : ℂ) ^ a * exp (-(2 * π * I * a)))) := by
  have hx0 : (x : ℂ) ≠ 0 := by exact_mod_cast hx.ne
  have hre : (x : ℂ).re < 0 := by simpa using hx
  have him : (x : ℂ).im = 0 := by simp
  have hev : ∀ s : Set ℂ, ∀ᶠ z in 𝓝[s] (x : ℂ), z ^ a = exp (Complex.log z * a) := by
    intro s
    apply eventually_nhdsWithin_of_eventually_nhds
    filter_upwards [isOpen_ne.mem_nhds hx0] with z hz
    exact cpow_def_of_ne_zero hz a
  constructor
  · have hc := continuousWithinAt_log_of_re_neg_of_im_zero hre him
    have h1 : Tendsto Complex.log (𝓝[{z : ℂ | 0 < z.im}] (x : ℂ)) (𝓝 (Complex.log x)) :=
      hc.tendsto.mono_left (nhdsWithin_mono _ (fun z (hz : 0 < z.im) => le_of_lt hz))
    have h2 := ((Complex.continuous_exp.tendsto _).comp (h1.mul_const a))
    rw [cpow_def_of_ne_zero hx0]
    exact h2.congr' (by filter_upwards [hev _] with z hz; simp [hz])
  · have h1 := tendsto_log_nhdsWithin_im_neg_of_re_neg_of_im_zero hre him
    have h2 := ((Complex.continuous_exp.tendsto _).comp (h1.mul_const a))
    have hlog : Complex.log (x : ℂ) = Real.log ‖(x : ℂ)‖ + π * I := by
      rw [Complex.log, arg_ofReal_of_neg hx]
    have heq : exp ((Real.log ‖(x : ℂ)‖ - π * I) * a) = (x : ℂ) ^ a * exp (-(2 * π * I * a)) := by
      rw [cpow_def_of_ne_zero hx0, ← Complex.exp_add, hlog]; ring_nf
    rw [← heq]
    exact h2.congr' (by filter_upwards [hev _] with z hz; simp [hz])

/-- The power is built from the logarithm, and every logarithm gives a branch. For nonzero z,
the principal power is z ^ a = e^(a (ln|z| + i Arg z)) with Arg z in (−π, π], and the values
e^(a L), over all logarithms L of z (all L with e^L = z), are exactly z ^ a · e^(2πiak) for
whole numbers k. -/
theorem cpow_eq_exp_mul_log_and_branches (z a : ℂ) (hz : z ≠ 0) :
    z ^ a = exp (a * (Real.log ‖z‖ + arg z * I)) ∧ arg z ∈ Set.Ioc (-π) π ∧
    {w : ℂ | ∃ L : ℂ, exp L = z ∧ w = exp (a * L)} =
      {w : ℂ | ∃ k : ℤ, w = z ^ a * exp (2 * π * I * a * k)} := by
  refine ⟨?_, ⟨neg_pi_lt_arg z, arg_le_pi z⟩, ?_⟩
  · rw [cpow_def_of_ne_zero hz, mul_comm]; rfl
  · ext w
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨L, hL, rfl⟩
      rw [← Complex.exp_log hz, exp_eq_exp_iff_exists_int] at hL
      obtain ⟨n, rfl⟩ := hL
      refine ⟨n, ?_⟩
      rw [cpow_def_of_ne_zero hz, ← Complex.exp_add]; ring_nf
    · rintro ⟨k, rfl⟩
      refine ⟨Complex.log z + k * (2 * π * I), ?_, ?_⟩
      · rw [Complex.exp_add, Complex.exp_log hz, exp_int_mul_two_pi_mul_I, mul_one]
      · rw [cpow_def_of_ne_zero hz, ← Complex.exp_add]; ring_nf


/-- Counting the values. For nonzero z: if a = p/q in lowest terms (q ≥ 1), the values
e^(a L) over all logarithms L of z number exactly q (one value when a is a whole number,
q = 1); if a is not a rational number, there are infinitely many. -/
theorem number_of_values_of_complex_power (z : ℂ) (hz : z ≠ 0) :
    (∀ (p : ℤ) (q : ℕ), 0 < q → Nat.Coprime p.natAbs q →
      {w : ℂ | ∃ L : ℂ, exp L = z ∧ w = exp (((p : ℂ) / q) * L)}.ncard = q) ∧
    (∀ a : ℂ, (∀ r : ℚ, a ≠ (r : ℂ)) →
      {w : ℂ | ∃ L : ℂ, exp L = z ∧ w = exp (a * L)}.Infinite) := by
  constructor
  · intro p q hq hcop
    rw [branch_set_eq_range _ _ hz]
    set a : ℂ := (p : ℂ) / q with ha
    set f : ℤ → ℂ := fun k => z ^ a * exp (2 * π * I * a * k) with hf
    have hq0 : (q : ℂ) ≠ 0 := by exact_mod_cast hq.ne'
    have hrange : Set.range f = ((Finset.range q).image (fun r : ℕ => f r) : Set ℂ) := by
      ext w
      simp only [Set.mem_range, Finset.coe_image, Finset.coe_range, Set.mem_image, Set.mem_Iio]
      constructor
      · rintro ⟨k, rfl⟩
        have hqz : (0 : ℤ) < q := by exact_mod_cast hq
        have hm0 : 0 ≤ k % (q : ℤ) := Int.emod_nonneg _ hqz.ne'
        have hmq : k % (q : ℤ) < q := Int.emod_lt_of_pos _ hqz
        refine ⟨(k % (q : ℤ)).toNat, by omega, ?_⟩
        have hcast : (((k % (q : ℤ)).toNat : ℕ) : ℤ) = k % (q : ℤ) := Int.toNat_of_nonneg hm0
        show f (((k % (q : ℤ)).toNat : ℕ) : ℤ) = f k
        rw [hcast, hf]
        simp only
        rw [branch_value_eq_iff z a hz]
        refine ⟨-(p * (k / (q : ℤ))), ?_⟩
        have hk : (k : ℂ) = ((k % (q : ℤ) : ℤ) : ℂ) + (q : ℂ) * ((k / (q : ℤ) : ℤ) : ℂ) := by
          have := Int.emod_add_mul_ediv k q
          exact_mod_cast this.symm
        rw [ha, hk]
        push_cast
        field_simp
        ring
      · rintro ⟨r, _, rfl⟩
        exact ⟨r, rfl⟩
    rw [hrange, Set.ncard_coe_finset, Finset.card_image_of_injOn, Finset.card_range]
    intro r hr r' hr' hrr
    simp only [Finset.coe_range, Set.mem_Iio] at hr hr'
    have hrr' : f r = f r' := hrr
    rw [hf] at hrr'
    simp only at hrr'
    obtain ⟨n, hn⟩ := (branch_value_eq_iff z a hz r r').1 hrr'
    rw [ha] at hn
    have hint : (p : ℂ) * ((r : ℤ) - (r' : ℤ) : ℤ) = ((n * q : ℤ) : ℂ) := by
      push_cast
      field_simp at hn
      linear_combination hn
    have hint' : p * ((r : ℤ) - (r' : ℤ)) = n * q := by exact_mod_cast hint
    have hdvd : (q : ℤ) ∣ p * ((r : ℤ) - (r' : ℤ)) := ⟨n, by rw [hint']; ring⟩
    have hdvd' : q ∣ p.natAbs * ((r : ℤ) - (r' : ℤ)).natAbs := by
      have := Int.natAbs_dvd_natAbs.2 hdvd
      rwa [Int.natAbs_mul, Int.natAbs_natCast] at this
    have hd : q ∣ ((r : ℤ) - (r' : ℤ)).natAbs := hcop.symm.dvd_of_dvd_mul_left hdvd'
    have hlt : ((r : ℤ) - (r' : ℤ)).natAbs < q := by omega
    have := Nat.eq_zero_of_dvd_of_lt hd hlt
    omega
  · intro a ha
    rw [branch_set_eq_range _ _ hz]
    apply Set.infinite_range_of_injective
    intro k k' hkk
    obtain ⟨n, hn⟩ := (branch_value_eq_iff z a hz k k').1 hkk
    by_contra hne
    have hne' : ((k : ℂ) - k') ≠ 0 := by
      rw [sub_ne_zero]; exact_mod_cast hne
    apply ha ((n : ℚ) / ((k : ℚ) - k'))
    push_cast
    field_simp
    linear_combination hn

-- The calculator's answer: the principal cube root of −8 is 1 + √3 i.
example : (-8 : ℂ) ^ ((1 : ℂ) / 3) = 1 + (Real.sqrt 3 : ℂ) * I := by
  have hlog : Complex.log (-8) = (3 * Real.log 2 : ℝ) + π * I := by
    have h8 : (-8 : ℂ) = ((-8 : ℝ) : ℂ) := by push_cast; ring
    rw [h8, Complex.log, arg_ofReal_of_neg (by norm_num)]
    congr 2
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_neg (by norm_num : (-8:ℝ) < 0)]
    rw [show (-(-8 : ℝ)) = 2 ^ 3 by norm_num, Real.log_pow]; push_cast; ring
  rw [cpow_def_of_ne_zero (by norm_num), hlog]
  have : ((3 * Real.log 2 : ℝ) + π * I) * (1 / 3) = (Real.log 2 : ℝ) + (π / 3 : ℝ) * I := by
    push_cast; ring
  rw [this, Complex.exp_add, ← ofReal_exp, Real.exp_log (by norm_num), exp_mul_I,
    ← ofReal_cos, ← ofReal_sin, Real.cos_pi_div_three, Real.sin_pi_div_three]
  push_cast; ring

-- The next branch round (k = 1) is the real cube root −2.
example : exp ((1 : ℂ) / 3 * (Complex.log (-8) + 2 * π * I)) = -2 := by
  have hlog : Complex.log (-8) = (3 * Real.log 2 : ℝ) + π * I := by
    have h8 : (-8 : ℂ) = ((-8 : ℝ) : ℂ) := by push_cast; ring
    rw [h8, Complex.log, arg_ofReal_of_neg (by norm_num)]
    congr 2
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_neg (by norm_num : (-8:ℝ) < 0)]
    rw [show (-(-8 : ℝ)) = 2 ^ 3 by norm_num, Real.log_pow]; push_cast; ring
  rw [hlog]
  have : (1 : ℂ) / 3 * ((3 * Real.log 2 : ℝ) + π * I + 2 * π * I) = (Real.log 2 : ℝ) + π * I := by
    push_cast; ring
  rw [this, Complex.exp_add, ← ofReal_exp, Real.exp_log (by norm_num), exp_pi_mul_I]
  push_cast; ring

-- The jump factor at the cut for a = 1/3 is −1/2 + (√3/2) i.
example : exp (2 * π * I * ((1 : ℂ) / 3)) = -1 / 2 + (Real.sqrt 3 / 2 : ℂ) * I := by
  have : 2 * π * I * ((1 : ℂ) / 3) = ((π - π / 3 : ℝ) : ℂ) * I := by push_cast; ring
  rw [this, exp_mul_I, ← ofReal_cos, ← ofReal_sin, Real.cos_pi_sub, Real.sin_pi_sub,
    Real.cos_pi_div_three, Real.sin_pi_div_three]
  push_cast; ring

-- For the square root the jump is a sign flip: e^(2πi/2) = −1.
example : exp (2 * π * I * ((1 : ℂ) / 2)) = -1 := by
  rw [show 2 * π * I * ((1 : ℂ) / 2) = π * I by ring, exp_pi_mul_I]

-- The principal value of i^i is the real number e^(−π/2).
example : I ^ I = (Real.exp (-(π / 2)) : ℂ) := by
  rw [cpow_def_of_ne_zero I_ne_zero, log_I, ofReal_exp]
  congr 1
  push_cast
  ring_nf
  rw [I_sq]; ring

-- Laws of exponents fail: √(−1) · √(−1) = −1, while √1 = 1.
example : (-1 : ℂ) ^ ((1 : ℂ) / 2) * (-1 : ℂ) ^ ((1 : ℂ) / 2) = -1 := by
  rw [← cpow_add _ _ (by norm_num)]
  norm_num
example : (1 : ℂ) ^ ((1 : ℂ) / 2) = 1 := by simp

#print axioms principal_power_jumps_by_exp_two_pi_i_a_across_cut
#print axioms cpow_eq_exp_mul_log_and_branches
#print axioms number_of_values_of_complex_power
