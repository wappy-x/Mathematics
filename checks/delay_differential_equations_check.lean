-- Delay equations: for x'(t) = -k x(t - tau), e^(lambda t) is a solution exactly when lambda = -k e^(-lambda tau), a root i omega on the imaginary axis needs omega = k or -k and k tau = pi/2 plus whole turns, and real roots exist exactly when k tau is at most 1/e.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Complex
import Mathlib.Topology.Order.IntermediateValue

open Real

theorem helper_parts (k τ ω : ℝ) :
    ((ω : ℂ) * Complex.I = -(k : ℂ) * Complex.exp (-((ω : ℂ) * Complex.I) * (τ : ℂ))) ↔
      (Real.cos (ω * τ) * k = 0 ∧ ω = k * Real.sin (ω * τ)) := by
  have h : -((ω : ℂ) * Complex.I) * (τ : ℂ) = ((-(ω * τ) : ℝ) : ℂ) * Complex.I := by
    push_cast; ring
  rw [h, Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin, Complex.ext_iff]
  simp only [Complex.mul_re, Complex.mul_im, Complex.neg_re, Complex.neg_im, Complex.ofReal_re,
    Complex.ofReal_im, Complex.I_re, Complex.I_im, Complex.add_re, Complex.add_im,
    Real.cos_neg, Real.sin_neg]
  constructor
  · rintro ⟨h1, h2⟩
    exact ⟨by linarith, by linarith⟩
  · rintro ⟨h1, h2⟩
    exact ⟨by linarith, by linarith⟩

#print axioms helper_parts

theorem helper_xexp_le (x : ℝ) : x * Real.exp (-x) ≤ Real.exp (-1) := by
  have h1 : x ≤ Real.exp (x - 1) := by linarith [Real.add_one_le_exp (x - 1)]
  have h2 : Real.exp (x - 1) * Real.exp (-x) = Real.exp (-1) := by
    rw [← Real.exp_add]; ring_nf
  rw [← h2]
  exact mul_le_mul_of_nonneg_right h1 (Real.exp_pos _).le

#print axioms helper_xexp_le

/-- The Hopf point. For the delay law x'(t) = -k x(t - τ) with k and τ positive, a root of the
characteristic equation λ = -k e^(-λτ) lies on the imaginary axis, λ = iω, exactly when the
turning rate is ω = k (or its mirror -k) and kτ = π/2 plus a whole number of full turns 2π.
So the first such crossing, the Hopf point, is at kτ = π/2 with ω = k. -/
theorem hopf_point_imaginary_root (k τ ω : ℝ) (hk : 0 < k) (hτ : 0 < τ) :
    ((ω : ℂ) * Complex.I = -(k : ℂ) * Complex.exp (-((ω : ℂ) * Complex.I) * (τ : ℂ))) ↔
      ((ω = k ∨ ω = -k) ∧ ∃ n : ℕ, k * τ = π / 2 + 2 * π * n) := by
  rw [helper_parts]
  constructor
  · rintro ⟨h1, h2⟩
    have hc : Real.cos (ω * τ) = 0 := by
      rcases mul_eq_zero.mp h1 with h | h
      · exact h
      · exact absurd h hk.ne'
    have hω : ω = k ∨ ω = -k := by
      rcases Real.cos_eq_zero_iff_sin_eq.mp hc with h | h
      · left; rw [h] at h2; linarith
      · right; rw [h] at h2; linarith
    have hs1 : Real.sin (k * τ) = 1 := by
      rcases hω with h | h
      · subst h
        rcases Real.cos_eq_zero_iff_sin_eq.mp hc with h' | h'
        · exact h'
        · rw [h'] at h2; linarith
      · subst h
        rcases Real.cos_eq_zero_iff_sin_eq.mp hc with h' | h'
        · rw [h'] at h2; linarith
        · rw [neg_mul, Real.sin_neg] at h'; linarith
    refine ⟨hω, ?_⟩
    obtain ⟨n, hn⟩ := Real.sin_eq_one_iff.mp hs1
    have hpos : 0 < k * τ := mul_pos hk hτ
    have hn0 : 0 ≤ n := by
      by_contra hneg
      have hle : n ≤ -1 := by omega
      have : (n : ℝ) ≤ -1 := by exact_mod_cast hle
      nlinarith [Real.pi_pos]
    refine ⟨n.toNat, ?_⟩
    have : ((n.toNat : ℕ) : ℝ) = (n : ℝ) := by
      rw [← Int.cast_natCast, Int.toNat_of_nonneg hn0]
    rw [this, ← hn]; ring
  · rintro ⟨hω, n, hn⟩
    have hc : Real.cos (k * τ) = 0 := by
      rw [hn, show π / 2 + 2 * π * n = π / 2 + n * (2 * π) by ring,
        Real.cos_add_nat_mul_two_pi, Real.cos_pi_div_two]
    have hs : Real.sin (k * τ) = 1 := by
      rw [hn, show π / 2 + 2 * π * n = π / 2 + n * (2 * π) by ring,
        Real.sin_add_nat_mul_two_pi, Real.sin_pi_div_two]
    rcases hω with h | h
    · subst h; rw [hc, hs]; simp
    · subst h; rw [neg_mul, Real.cos_neg, Real.sin_neg, hc, hs]; simp

/-- The characteristic equation. With k and τ positive, the trial solution x(t) = e^(λt) obeys
x'(t) = -k x(t - τ) at every time t exactly when λ = -k e^(-λτ). -/
theorem exp_solves_delay_law_iff_characteristic (k τ : ℝ) (lam : ℂ) (hk : 0 < k) (hτ : 0 < τ) :
    (∀ t : ℝ, HasDerivAt (fun s : ℝ => Complex.exp (lam * s))
        (-(k : ℂ) * Complex.exp (lam * ((t : ℂ) - τ))) t) ↔
      lam = -(k : ℂ) * Complex.exp (-lam * τ) := by
  have hd : ∀ t : ℝ, HasDerivAt (fun s : ℝ => Complex.exp (lam * s))
      (lam * Complex.exp (lam * t)) t := by
    intro t
    have h1 : HasDerivAt (fun s : ℝ => lam * (s : ℂ)) (lam * 1) t :=
      (Complex.ofRealCLM.hasDerivAt).const_mul lam
    have := h1.cexp
    simpa [mul_comm] using this
  have hsplit : ∀ t : ℝ, Complex.exp (lam * ((t : ℂ) - τ)) =
      Complex.exp (lam * t) * Complex.exp (-lam * τ) := by
    intro t; rw [← Complex.exp_add]; ring_nf
  constructor
  · intro h
    have h0 := (h 0).unique (hd 0)
    rw [hsplit] at h0
    simp only [Complex.ofReal_zero, mul_zero, Complex.exp_zero, one_mul, mul_one] at h0
    exact h0.symm
  · intro h t
    convert hd t using 1
    calc -(k : ℂ) * Complex.exp (lam * ((t : ℂ) - τ))
        = (-(k : ℂ) * Complex.exp (-lam * τ)) * Complex.exp (lam * t) := by rw [hsplit]; ring
      _ = lam * Complex.exp (lam * t) := by rw [← h]

/-- Real roots vanish at kτ = 1/e. With k and τ positive, the characteristic equation
λ + k e^(-λτ) = 0 has a real root λ exactly when kτ ≤ 1/e. -/
theorem real_root_iff_le_inv_e (k τ : ℝ) (hk : 0 < k) (hτ : 0 < τ) :
    (∃ lam : ℝ, lam + k * Real.exp (-lam * τ) = 0) ↔ k * τ ≤ Real.exp (-1) := by
  constructor
  · rintro ⟨lam, h⟩
    have hl : -lam = k * Real.exp (-lam * τ) := by linarith
    have hkey : k * τ = (-lam * τ) * Real.exp (-(-lam * τ)) := by
      calc k * τ = k * τ * (Real.exp (-lam * τ) * Real.exp (-(-lam * τ))) := by
            rw [← Real.exp_add]; simp
        _ = (k * Real.exp (-lam * τ)) * τ * Real.exp (-(-lam * τ)) := by ring
        _ = (-lam * τ) * Real.exp (-(-lam * τ)) := by rw [← hl]
    rw [hkey]; exact helper_xexp_le _
  · intro hle
    have hcont : ContinuousOn (fun x : ℝ => x * Real.exp (-x)) (Set.Icc 0 1) :=
      (continuous_id.mul (Real.continuous_exp.comp continuous_neg)).continuousOn
    have hmem : k * τ ∈ Set.Icc ((fun x : ℝ => x * Real.exp (-x)) 0)
        ((fun x : ℝ => x * Real.exp (-x)) 1) := by
      simp only [zero_mul, one_mul]
      exact ⟨(mul_pos hk hτ).le, hle⟩
    obtain ⟨x, -, hxv⟩ := intermediate_value_Icc zero_le_one hcont hmem
    simp only at hxv
    refine ⟨-x / τ, ?_⟩
    have hE : Real.exp (-x) * Real.exp x = 1 := by rw [← Real.exp_add]; simp
    have harg : -(-x / τ) * τ = x := by field_simp
    rw [harg]
    have hx : x = k * τ * Real.exp x := by
      rw [← hxv]
      calc x = x * (Real.exp (-x) * Real.exp x) := by rw [hE, mul_one]
        _ = _ := by ring
    have : -x / τ = -(k * Real.exp x) := by
      rw [div_eq_iff hτ.ne']; linarith [hx]
    rw [this]; ring

/- The card's method of steps with k = 1, τ = 1 and x = 1 on [-1, 0]: each piece is the
previous end value plus the integral of minus the piece before, in s = t - j. -/
-- x = 1 - t on [0, 1]: x(1) = 0
example : (1 : ℚ) - 1 = 0 := by norm_num
-- x = t^2/2 - 2t + 3/2 on [1, 2]: it starts at 0 and x(2) = -1/2
example : (1 : ℚ) ^ 2 / 2 - 2 * 1 + 3 / 2 = 0 := by norm_num
example : (2 : ℚ) ^ 2 / 2 - 2 * 2 + 3 / 2 = -1 / 2 := by norm_num
-- x = -1/2 + (t - 2)^2/2 - (t - 2)^3/6 on [2, 3]: x(3) = -1/6
example : (-1 / 2 : ℚ) + 1 ^ 2 / 2 - 1 ^ 3 / 6 = -1 / 6 := by norm_num
-- next piece -1/6 + s/2 - s^3/6 + s^4/24 in s = t - 3: x(4) = 5/24 = 0.2083
example : (-1 / 6 : ℚ) + 1 / 2 - 1 / 6 + 1 / 24 = 5 / 24 := by norm_num

#print axioms hopf_point_imaginary_root
#print axioms exp_solves_delay_law_iff_characteristic
#print axioms real_root_iff_le_inv_e
