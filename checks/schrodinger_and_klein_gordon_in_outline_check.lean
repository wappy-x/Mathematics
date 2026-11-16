-- Schrodinger and Klein-Gordon: the free Gaussian packet solves ψ_t = i D ψ_xx exactly, its chance density is a bell of width σ₀√(1 + (t/τ)²) with total 1 at every time, and plane waves obey ω = D k² (Schrödinger) and ω² = c² k² + ω_m² (Klein-Gordon).
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Complex MeasureTheory

/-- The card's closed-form free Gaussian packet, with diffusivity `D = ħ/2m`, starting width
`σ₀`, central wavenumber `k₀` and spreading time `τ = σ₀²/D`:
ψ(x, t) = (2πσ₀²)^(-1/4) (1 + i t/τ)^(-1/2) exp((-x²/(4σ₀²) + i k₀ x - i D k₀² t)/(1 + i t/τ)). -/
noncomputable def freePacket (D σ₀ k₀ x t : ℝ) : ℂ :=
  ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
    (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ)) *
    exp ((-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t) /
      (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)))

/-- A plane wave e^{i(kx - ωt)} with wavenumber `k` and frequency `ω`. -/
noncomputable def planeWave (k ω x t : ℝ) : ℂ :=
  exp (I * ((k * x - ω * t : ℝ) : ℂ))

/-- x-derivative of the packet. -/
lemma freePacket_hasDerivAt_x (D σ₀ k₀ t y : ℝ) :
    HasDerivAt (fun y : ℝ => freePacket D σ₀ k₀ y t)
      (((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
        (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ)) *
        (exp ((-(y : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * y - I * D * k₀ ^ 2 * t) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))) *
        ((-(2 * (y : ℂ)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))))) y := by
  set C := ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
        (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ))
  set A := (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))
  have h : HasDerivAt (fun z : ℂ => C * exp ((-z ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * z
      - I * D * k₀ ^ 2 * t) / A))
      (C * (exp ((-(y : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * y - I * D * k₀ ^ 2 * t) / A) *
        ((-(2 * (y : ℂ)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) / A))) (y : ℂ) := by
    have h1 := (((((hasDerivAt_id (y : ℂ)).pow 2).neg.div_const (4 * (σ₀ : ℂ) ^ 2)).add
      ((hasDerivAt_id (y : ℂ)).const_mul (I * k₀))).sub_const (I * D * k₀ ^ 2 * t)).div_const A
    have h2 := (h1.cexp).const_mul C
    convert h2 using 2
    · simp
    · simp
  exact h.comp_ofReal

lemma freePacket_deriv2_x (D σ₀ k₀ t x : ℝ) :
    deriv (deriv (fun y : ℝ => freePacket D σ₀ k₀ y t)) x =
      ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
        (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ)) *
        (exp ((-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))) *
        (((-(2 * (x : ℂ)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))) ^ 2 +
          (-2 / (4 * (σ₀ : ℂ) ^ 2)) / (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)))) := by
  have hd : deriv (fun y : ℝ => freePacket D σ₀ k₀ y t) = fun y : ℝ =>
      ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
        (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ)) *
        (exp ((-(y : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * y - I * D * k₀ ^ 2 * t) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))) *
        ((-(2 * (y : ℂ)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) /
          (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)))) := by
    funext y; exact (freePacket_hasDerivAt_x D σ₀ k₀ t y).deriv
  rw [hd]
  set C := ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ)) *
        (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ)) ^ (-(1 / 2 : ℂ))
  set A := (1 + I * ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ))
  have h : HasDerivAt (fun z : ℂ => C * (exp ((-z ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * z
      - I * D * k₀ ^ 2 * t) / A) * (((-(2 * z)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) / A)))
      (C * (exp ((-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t) / A) *
        ((((-(2 * (x : ℂ)) / (4 * (σ₀ : ℂ) ^ 2) + I * k₀) / A) ^ 2 +
          (-2 / (4 * (σ₀ : ℂ) ^ 2)) / A)))) (x : ℂ) := by
    have h1 := (((((hasDerivAt_id (x : ℂ)).pow 2).neg.div_const (4 * (σ₀ : ℂ) ^ 2)).add
      ((hasDerivAt_id (x : ℂ)).const_mul (I * k₀))).sub_const (I * D * k₀ ^ 2 * t)).div_const A
    have h3 := ((((hasDerivAt_id (x : ℂ)).const_mul 2).neg.div_const (4 * (σ₀ : ℂ) ^ 2)).add_const
      (I * k₀)).div_const A
    have h2 := ((h1.cexp).mul h3).const_mul C
    convert h2 using 1
    · funext z; simp
    · simp only [id, Pi.add_apply, Pi.neg_apply, Pi.pow_apply]; push_cast; ring
  exact h.comp_ofReal.deriv

lemma freePacket_hasDerivAt_t (D σ₀ k₀ x t : ℝ) (hD : 0 < D) (hσ₀ : 0 < σ₀) :
    HasDerivAt (fun s : ℝ => freePacket D σ₀ k₀ x s)
      (I * D * deriv (deriv (fun y : ℝ => freePacket D σ₀ k₀ y t)) x) t := by
  rw [freePacket_deriv2_x]
  set N := ((2 * Real.pi * σ₀ ^ 2 : ℝ) : ℂ) ^ (-(1 / 4 : ℂ))
  have hσc : (σ₀ : ℂ) ≠ 0 := by exact_mod_cast hσ₀.ne'
  have hDc : (D : ℂ) ≠ 0 := by exact_mod_cast hD.ne'
  set τ : ℂ := (σ₀ : ℂ) ^ 2 / D with hτ
  have hτ0 : τ ≠ 0 := div_ne_zero (pow_ne_zero 2 hσc) hDc
  set E : ℂ → ℂ := fun w => -(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * w
    with hEdef
  set Af : ℂ → ℂ := fun w => 1 + I * (w / τ) with hAfdef
  have hcast : ((t / (σ₀ ^ 2 / D) : ℝ) : ℂ) = (t : ℂ) / τ := by rw [hτ]; push_cast; ring
  have hfun : (fun s : ℝ => freePacket D σ₀ k₀ x s) =
      fun s : ℝ => N * (Af s) ^ (-(1 / 2 : ℂ)) * exp (E s / Af s) := by
    funext s
    simp only [freePacket, N, Af, E, hτ]
    push_cast; ring_nf
  rw [hfun, hcast]
  have hAt : Af t ∈ slitPlane := by
    rw [mem_slitPlane_iff]; left
    show 0 < (1 + I * ((t : ℂ) / τ)).re
    rw [← hcast]; simp only [add_re, one_re, mul_re, I_re, I_im, ofReal_re, ofReal_im]; norm_num
  have hA0 : Af t ≠ 0 := slitPlane_ne_zero hAt
  have hA : HasDerivAt Af (I * (1 / τ)) (t : ℂ) := by
    have := (((hasDerivAt_id (t : ℂ)).div_const τ).const_mul I).const_add 1
    exact this.congr_deriv (by simp)
  have hE : HasDerivAt E (-(I * D * k₀ ^ 2)) (t : ℂ) := by
    have := ((hasDerivAt_id (t : ℂ)).const_mul (I * D * k₀ ^ 2)).const_sub
      (-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x)
    exact this.congr_deriv (by simp)
  have hP := (Complex.hasStrictDerivAt_cpow_const (c := -(1 / 2 : ℂ)) hAt).hasDerivAt.comp
    (t : ℂ) hA
  have hX := ((hE.div hA hA0).cexp)
  have h := (hP.const_mul N).mul hX
  have h' := h.comp_ofReal
  convert h' using 1
  · funext s; simp [Function.comp, mul_assoc]
  · have hsub : Af t ^ (-(1 / 2 : ℂ) - 1) = Af t ^ (-(1 / 2 : ℂ)) / Af t := by
      rw [cpow_sub _ _ hA0, cpow_one]
    simp only [Function.comp, Pi.div_apply, hsub]
    rw [show (1 + I * ((t : ℂ) / τ)) = Af t from rfl,
      show (-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t) = E t from rfl]
    generalize Af t ^ (-(1 / 2 : ℂ)) = P
    generalize cexp (E t / Af t) = X
    have hAt' : Af t = 1 + I * ((t : ℂ) / τ) := rfl
    have hEt : E t = -(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t := rfl
    clear_value Af E
    rw [hEt]
    field_simp
    rw [hAt', hτ]
    field_simp
    ring_nf
    rw [I_sq]
    ring

lemma freePacket_normSq (D σ₀ k₀ x t : ℝ) (hD : 0 < D) (hσ₀ : 0 < σ₀) :
    Complex.normSq (freePacket D σ₀ k₀ x t) =
        1 / (σ₀ * Real.sqrt (1 + (t / (σ₀ ^ 2 / D)) ^ 2) * Real.sqrt (2 * Real.pi)) *
          Real.exp (-(x - 2 * D * k₀ * t) ^ 2 /
            (2 * (σ₀ * Real.sqrt (1 + (t / (σ₀ ^ 2 / D)) ^ 2)) ^ 2)) := by
  set s : ℝ := t / (σ₀ ^ 2 / D) with hs
  set r : ℝ := 2 * Real.pi * σ₀ ^ 2 with hr
  have hr0 : 0 < r := by positivity
  have hq0 : 0 < 1 + s ^ 2 := by positivity
  set a : ℝ := Real.sqrt (1 + s ^ 2) with ha
  have ha0 : 0 < a := Real.sqrt_pos.mpr hq0
  have hA : (1 + I * (s : ℂ)) = ((1 : ℝ) : ℂ) + (s : ℂ) * I := by push_cast; ring
  have hAne : (1 + I * (s : ℂ)) ≠ 0 := by
    intro h0; have := congrArg Complex.re h0; simp at this
  have hAnorm : ‖(1 + I * (s : ℂ))‖ = a := by rw [hA, norm_add_mul_I]; simp [ha]
  have hE : (-(x : ℂ) ^ 2 / (4 * (σ₀ : ℂ) ^ 2) + I * k₀ * x - I * D * k₀ ^ 2 * t) =
      ((-x ^ 2 / (4 * σ₀ ^ 2) : ℝ) : ℂ) + ((k₀ * x - D * k₀ ^ 2 * t : ℝ) : ℂ) * I := by
    push_cast; ring
  have hre : ((((-x ^ 2 / (4 * σ₀ ^ 2) : ℝ) : ℂ) + ((k₀ * x - D * k₀ ^ 2 * t : ℝ) : ℂ) * I) /
      (((1 : ℝ) : ℂ) + (s : ℂ) * I)).re =
      ((-x ^ 2 / (4 * σ₀ ^ 2)) + (k₀ * x - D * k₀ ^ 2 * t) * s) / (1 + s ^ 2) := by
    rw [Complex.div_re, normSq_add_mul_I]
    simp only [ofReal_re, ofReal_im, add_re, add_im, mul_re, mul_im, I_re, I_im]
    ring
  unfold freePacket
  rw [normSq_eq_norm_sq, norm_mul, norm_mul, norm_exp, norm_cpow_eq_rpow_re_of_pos hr0,
    norm_cpow_of_ne_zero hAne, hAnorm, hE, hA, hre]
  simp only [neg_re, div_ofNat_re, one_re, neg_im, div_ofNat_im, one_im, zero_div, neg_zero,
    mul_zero, Real.exp_zero, div_one]
  have h1 : (r ^ (-(1 / 4 : ℝ))) ^ 2 = 1 / (σ₀ * Real.sqrt (2 * Real.pi)) := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul hr0.le]
    rw [show (-(1 / 4 : ℝ)) * ((2 : ℕ) : ℝ) = -(1 / 2) by norm_num, Real.rpow_neg hr0.le,
      ← Real.sqrt_eq_rpow, hr, mul_comm (2 * Real.pi), Real.sqrt_mul (by positivity),
      Real.sqrt_sq hσ₀.le]
    ring
  have h2 : (a ^ (-(1 / 2 : ℝ))) ^ 2 = 1 / a := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul ha0.le]
    rw [show (-(1 / 2 : ℝ)) * ((2 : ℕ) : ℝ) = -1 by norm_num, Real.rpow_neg_one]
    ring
  have h3 : Real.exp ((-x ^ 2 / (4 * σ₀ ^ 2) + (k₀ * x - D * k₀ ^ 2 * t) * s) / (1 + s ^ 2)) ^ 2
      = Real.exp (-(x - 2 * D * k₀ * t) ^ 2 / (2 * (σ₀ * a) ^ 2)) := by
    rw [← Real.exp_nat_mul]
    congr 1
    rw [mul_pow, ha, Real.sq_sqrt hq0.le, hs]
    have hσ2 : σ₀ ^ 2 ≠ 0 := by positivity
    field_simp
    ring
  rw [mul_pow, mul_pow, h1, h2, h3]
  field_simp

lemma freePacket_contDiff (D σ₀ k₀ t : ℝ) : ContDiff ℝ 2 (fun x : ℝ => freePacket D σ₀ k₀ x t) := by
  have hof : ContDiff ℝ 2 (fun x : ℝ => (x : ℂ)) := ofRealCLM.contDiff
  unfold freePacket
  fun_prop

lemma pw_dt (k ω x s : ℝ) :
    HasDerivAt (fun s : ℝ => planeWave k ω x s) (-(I * ω) * planeWave k ω x s) s := by
  have h : HasDerivAt (fun w : ℂ => exp (I * (k * x - ω * w))) (exp (I * (k * x - ω * s)) * (I * -(ω * 1))) (s : ℂ) :=
    (((hasDerivAt_id (s : ℂ)).const_mul (ω : ℂ)).const_sub ((k : ℂ) * x)).const_mul I |>.cexp
  have h' := h.comp_ofReal
  convert h' using 1
  · funext u; simp [planeWave]
  · simp [planeWave]; ring

lemma pw_dx (k ω y t : ℝ) :
    HasDerivAt (fun y : ℝ => planeWave k ω y t) (I * k * planeWave k ω y t) y := by
  have h : HasDerivAt (fun w : ℂ => exp (I * (k * w - ω * t))) (exp (I * (k * y - ω * t)) * (I * (k * 1))) (y : ℂ) :=
    (((hasDerivAt_id (y : ℂ)).const_mul (k : ℂ)).sub_const ((ω : ℂ) * t)).const_mul I |>.cexp
  have h' := h.comp_ofReal
  convert h' using 1
  · funext u; simp [planeWave]
  · simp [planeWave]; ring

lemma pw_deriv2_x (k ω x t : ℝ) :
    deriv (deriv (fun y : ℝ => planeWave k ω y t)) x = (I * k) ^ 2 * planeWave k ω x t := by
  have hd : deriv (fun y : ℝ => planeWave k ω y t) = fun y => I * k * planeWave k ω y t := by
    funext y; exact (pw_dx k ω y t).deriv
  rw [hd, ((pw_dx k ω x t).const_mul (I * k)).deriv]; ring

lemma pw_deriv2_t (k ω x t : ℝ) :
    deriv (deriv (fun s : ℝ => planeWave k ω x s)) t = (-(I * ω)) ^ 2 * planeWave k ω x t := by
  have hd : deriv (fun s : ℝ => planeWave k ω x s) = fun s => -(I * ω) * planeWave k ω x s := by
    funext s; exact (pw_dt k ω x s).deriv
  rw [hd, ((pw_dt k ω x t).const_mul (-(I * ω))).deriv]; ring

lemma pw_ne (k ω x t : ℝ) : planeWave k ω x t ≠ 0 := exp_ne_zero _

#print axioms freePacket_hasDerivAt_x
#print axioms freePacket_deriv2_x
#print axioms freePacket_hasDerivAt_t
#print axioms freePacket_normSq
#print axioms freePacket_contDiff
#print axioms pw_dt
#print axioms pw_dx
#print axioms pw_deriv2_x
#print axioms pw_deriv2_t
#print axioms pw_ne

/-- The free Schrödinger packet spreads but does not fade: with no force (V = 0), the Gaussian
packet of starting width σ₀ is a classical solution of ψ_t = i D ψ_xx on the whole line, and its
chance density |ψ|² is a bell centred at v₀ t = 2 D k₀ t whose width is
σ(t) = σ₀ √(1 + (t/τ)²), τ = σ₀²/D. -/
theorem gaussian_packet_spreads_by_width_formula (D σ₀ k₀ : ℝ) (hD : 0 < D) (hσ₀ : 0 < σ₀) :
    (∀ t : ℝ, ContDiff ℝ 2 (fun x : ℝ => freePacket D σ₀ k₀ x t)) ∧
    (∀ x t : ℝ, HasDerivAt (fun s : ℝ => freePacket D σ₀ k₀ x s)
      (I * D * deriv (deriv (fun y : ℝ => freePacket D σ₀ k₀ y t)) x) t) ∧
    (∀ x t : ℝ,
      Complex.normSq (freePacket D σ₀ k₀ x t) =
        1 / (σ₀ * Real.sqrt (1 + (t / (σ₀ ^ 2 / D)) ^ 2) * Real.sqrt (2 * Real.pi)) *
          Real.exp (-(x - 2 * D * k₀ * t) ^ 2 /
            (2 * (σ₀ * Real.sqrt (1 + (t / (σ₀ ^ 2 / D)) ^ 2)) ^ 2))) := by
  exact ⟨fun t => freePacket_contDiff D σ₀ k₀ t,
   fun x t => freePacket_hasDerivAt_t D σ₀ k₀ x t hD hσ₀,
   fun x t => freePacket_normSq D σ₀ k₀ x t hD hσ₀⟩

/-- Nothing fades: the total chance ∫ |ψ|² dx of the free Gaussian packet is exactly 1 at every
time t. -/
theorem gaussian_packet_total_chance_eq_one (D σ₀ k₀ : ℝ) (hD : 0 < D) (hσ₀ : 0 < σ₀) (t : ℝ) :
    ∫ x : ℝ, Complex.normSq (freePacket D σ₀ k₀ x t) = 1 := by
  simp_rw [freePacket_normSq D σ₀ k₀ _ t hD hσ₀]
  set a : ℝ := Real.sqrt (1 + (t / (σ₀ ^ 2 / D)) ^ 2) with ha
  have ha0 : 0 < a := Real.sqrt_pos.mpr (by positivity)
  set μ : ℝ := 2 * D * k₀ * t
  have hb : 0 < 1 / (2 * (σ₀ * a) ^ 2) := by positivity
  rw [integral_const_mul]
  have hshift : ∫ x : ℝ, Real.exp (-(x - μ) ^ 2 / (2 * (σ₀ * a) ^ 2)) =
      ∫ x : ℝ, Real.exp (-(1 / (2 * (σ₀ * a) ^ 2)) * x ^ 2) := by
    rw [← integral_sub_right_eq_self (fun x : ℝ => Real.exp (-(1 / (2 * (σ₀ * a) ^ 2)) * x ^ 2)) μ]
    congr 1; funext x; congr 1; ring
  rw [hshift, integral_gaussian]
  rw [show Real.pi / (1 / (2 * (σ₀ * a) ^ 2)) = (σ₀ * a) ^ 2 * (2 * Real.pi) by field_simp,
    Real.sqrt_mul (x := (σ₀ * a) ^ 2) (by positivity), Real.sqrt_sq (by positivity)]
  have : 0 < Real.sqrt (2 * Real.pi) := by positivity
  field_simp

/-- The two dispersion relations: a plane wave e^{i(kx - ωt)} solves the free Schrödinger
equation ψ_t = i D ψ_xx exactly when ω = D k², and solves the Klein-Gordon equation
ψ_tt = c² ψ_xx - ω_m² ψ exactly when ω² = c² k² + ω_m². -/
theorem plane_wave_dispersion_relations (D c ωm k ω : ℝ) :
    ((∀ x t : ℝ, HasDerivAt (fun s : ℝ => planeWave k ω x s)
        (I * D * deriv (deriv (fun y : ℝ => planeWave k ω y t)) x) t) ↔ ω = D * k ^ 2) ∧
    ((∀ x t : ℝ, deriv (deriv (fun s : ℝ => planeWave k ω x s)) t =
        (c : ℂ) ^ 2 * deriv (deriv (fun y : ℝ => planeWave k ω y t)) x -
          (ωm : ℂ) ^ 2 * planeWave k ω x t) ↔ ω ^ 2 = c ^ 2 * k ^ 2 + ωm ^ 2) := by
  constructor
  · constructor
    · intro h
      have h0 := (h 0 0).unique (pw_dt k ω 0 0)
      rw [pw_deriv2_x] at h0
      have hne := pw_ne k ω 0 0
      have h1 : (I * D * (I * k) ^ 2 - -(I * ω)) * planeWave k ω 0 0 = 0 := by
        linear_combination h0
      have h2 := (mul_eq_zero.mp h1).resolve_right hne
      rw [mul_pow, I_sq] at h2
      have h3 : I * ((ω : ℂ) - D * k ^ 2) = 0 := by
        linear_combination h2
      have h4 := (mul_eq_zero.mp h3).resolve_left I_ne_zero
      have h5 : ((ω - D * k ^ 2 : ℝ) : ℂ) = 0 := by push_cast; exact h4
      have := ofReal_eq_zero.mp h5
      linarith
    · intro hω x t
      rw [pw_deriv2_x]
      convert pw_dt k ω x t using 1
      rw [hω]; push_cast; rw [mul_pow, I_sq]; ring
  · constructor
    · intro h
      have h0 := h 0 0
      rw [pw_deriv2_t, pw_deriv2_x] at h0
      have hne := pw_ne k ω 0 0
      have h1 : ((-(I * ω)) ^ 2 - ((c : ℂ) ^ 2 * (I * k) ^ 2 - (ωm : ℂ) ^ 2)) *
          planeWave k ω 0 0 = 0 := by
        linear_combination h0
      have h2 := (mul_eq_zero.mp h1).resolve_right hne
      rw [neg_sq, mul_pow, mul_pow, I_sq] at h2
      have h5 : ((ω ^ 2 - (c ^ 2 * k ^ 2 + ωm ^ 2) : ℝ) : ℂ) = 0 := by
        push_cast; linear_combination -h2
      have := ofReal_eq_zero.mp h5
      linarith
    · intro hω x t
      rw [pw_deriv2_t, pw_deriv2_x]
      have hc : (ω : ℂ) ^ 2 = (c : ℂ) ^ 2 * k ^ 2 + ωm ^ 2 := by exact_mod_cast hω
      rw [neg_sq, mul_pow, mul_pow, I_sq, hc]; ring

-- The card's scaled dispersion chart, exact rows: at K = 3/4 Klein-Gordon's ω/ω_m = √(1 + K²) is 5/4.
example : (1 : ℚ) + (3 / 4) ^ 2 = (5 / 4) ^ 2 := by norm_num
-- At K = 1, Schrödinger plus the rest frequency gives 1 + K²/2 = 3/2; at K = 2 it gives 3.
example : (1 : ℚ) + 1 ^ 2 / 2 = 3 / 2 := by norm_num
example : (1 : ℚ) + 2 ^ 2 / 2 = 3 := by norm_num

#print axioms gaussian_packet_spreads_by_width_formula
#print axioms gaussian_packet_total_chance_eq_one
#print axioms plane_wave_dispersion_relations
