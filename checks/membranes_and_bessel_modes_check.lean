-- Drumheads: the modes J_m(kr)(A cos mθ + B sin mθ) cos(ckt) solve the wave equation on a disc, vanish on the rim exactly when J_m(kR) = 0, and the angular part closes up only for whole m.
import Mathlib.Analysis.SpecialFunctions.Bessel
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Complex.LocallyUniformLimit

open Real

theorem besselJ_hasSum_series (m : ℕ) (x : ℂ) :
    HasSum (fun p : ℕ => (-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) *
        (x / 2) ^ (2 * p + m)) (Complex.besselJ (m : ℂ) x) := by
  have hs := Complex.summable_pow_mul_regularizedHGFunCoeff_zero (b := {(m : ℂ) + 1})
    (-(x / 2) ^ 2)
  have hF : Complex.regularizedHGFun 0 {(m : ℂ) + 1} (-(x / 2) ^ 2) =
      ∑' n, (-(x / 2) ^ 2) ^ n * Complex.regularizedHGFunCoeff 0 {(m : ℂ) + 1} n := by
    simp [Complex.regularizedHGFun, FormalMultilinearSeries.sum]
  have := hs.hasSum.mul_left ((x / 2) ^ m)
  rw [Complex.besselJ, Complex.cpow_natCast, hF]
  convert this using 1
  funext p
  have hG : Complex.Gamma ((m : ℂ) + 1 + p) = ((p + m).factorial : ℂ) := by
    rw [show (m : ℂ) + 1 + p = ((p + m : ℕ) : ℂ) + 1 by push_cast; ring,
      Complex.Gamma_nat_eq_factorial]
  simp only [Complex.regularizedHGFunCoeff, Multiset.map_zero, Multiset.prod_zero,
    Multiset.map_singleton, Multiset.prod_singleton, hG]
  rw [neg_pow ((x / 2) ^ 2), ← pow_mul, pow_add]
  ring

#print axioms besselJ_hasSum_series

theorem hasSum_deriv_tsum_pow (a : ℕ → ℂ) (e : ℕ → ℕ)
    (h : ∀ R : ℝ, 1 ≤ R → Summable fun p => ‖a p‖ * R ^ (e p)) (x : ℂ) :
    HasSum (fun p => a p * (e p : ℂ) * x ^ (e p - 1))
      (deriv (fun w => ∑' p, a p * w ^ (e p)) x) := by
  have hR : (1 : ℝ) ≤ ‖x‖ + 1 := by have := norm_nonneg x; linarith
  have key := Complex.hasSum_deriv_of_summable_norm (U := Metric.ball (0 : ℂ) (‖x‖ + 1))
    (F := fun p w => a p * w ^ (e p)) (z := x) (h _ hR)
    (fun p => (differentiable_const _).mul (differentiable_pow _) |>.differentiableOn)
    Metric.isOpen_ball
    (fun p w hw => by
      rw [norm_mul, norm_pow]
      have hw' : ‖w‖ < ‖x‖ + 1 := by simpa using hw
      gcongr)
    (by simp)
  convert key using 1
  funext p
  simp
  ring

#print axioms hasSum_deriv_tsum_pow

theorem besselJ_series_solves_bessel_equation_aux (m : ℕ) (x : ℂ) :
    HasSum (fun p : ℕ => (-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) *
        (x / 2) ^ (2 * p + m)) (Complex.besselJ (m : ℂ) x) ∧
    x ^ 2 * deriv^[2] (Complex.besselJ (m : ℂ)) x + x * deriv (Complex.besselJ (m : ℂ)) x +
        (x ^ 2 - (m : ℂ) ^ 2) * Complex.besselJ (m : ℂ) x = 0 := by
  refine ⟨besselJ_hasSum_series m x, ?_⟩
  set a : ℕ → ℂ := fun p => (-1 : ℂ) ^ p /
    ((p.factorial : ℂ) * ((p + m).factorial : ℂ) * 2 ^ (2 * p + m)) with ha
  set e : ℕ → ℕ := fun p => 2 * p + m with he
  have hterm : ∀ (w : ℂ) (p : ℕ), (-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) *
      (w / 2) ^ (2 * p + m) = a p * w ^ (e p) := by
    intro w p
    simp only [ha, he, div_pow]
    field_simp
  have h0 : ∀ w, HasSum (fun p => a p * w ^ (e p)) (Complex.besselJ (m : ℂ) w) := by
    intro w
    have := besselJ_hasSum_series m w
    simp only [hterm] at this
    exact this
  have hJ : Complex.besselJ (m : ℂ) = fun w => ∑' p, a p * w ^ (e p) :=
    funext fun w => (h0 w).tsum_eq.symm
  -- the bound
  have hnorm : ∀ p, ‖a p‖ = 1 / ((p.factorial : ℝ) * ((p + m).factorial : ℝ) * 2 ^ (2 * p + m)) := by
    intro p
    simp [ha, norm_pow]
  have hbound : ∀ R : ℝ, 1 ≤ R → ∀ p, ‖a p‖ * (((e p : ℕ) : ℝ) + 1) * R ^ (e p) ≤
      R ^ m * (R ^ 2) ^ p / (p.factorial : ℝ) := by
    intro R hR p
    rw [hnorm p]
    have h2 : ((e p : ℕ) : ℝ) + 1 ≤ 2 ^ (e p) := by
      have := Nat.lt_two_pow_self (n := e p)
      exact_mod_cast this
    have hf1 : (1 : ℝ) ≤ ((p + m).factorial : ℝ) := by exact_mod_cast Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero _)
    have hfp : (0 : ℝ) < (p.factorial : ℝ) := by exact_mod_cast Nat.factorial_pos p
    have hRp : (0 : ℝ) < R ^ (e p) := by positivity
    have heq : R ^ m * (R ^ 2) ^ p = R ^ (e p) := by
      simp only [he]; rw [← pow_mul, ← pow_add]; ring_nf
    rw [heq, le_div_iff₀ hfp]
    have hfac : (0 : ℝ) < ((p + m).factorial : ℝ) := by linarith
    calc 1 / ((p.factorial : ℝ) * ((p + m).factorial : ℝ) * 2 ^ (2 * p + m)) *
          (((e p : ℕ) : ℝ) + 1) * R ^ (e p) * (p.factorial : ℝ)
        = (((e p : ℕ) : ℝ) + 1) / (((p + m).factorial : ℝ) * 2 ^ (e p)) * R ^ (e p) := by
          simp only [he]; field_simp
      _ ≤ 1 * R ^ (e p) := by
          gcongr
          rw [div_le_one (by positivity)]
          have : (1 : ℝ) * 2 ^ (e p) ≤ ((p + m).factorial : ℝ) * 2 ^ (e p) := by gcongr
          linarith
      _ = R ^ (e p) := one_mul _
  have hsumB : ∀ R : ℝ, 1 ≤ R → Summable fun p => ‖a p‖ * (((e p : ℕ) : ℝ) + 1) * R ^ (e p) := by
    intro R hR
    refine Summable.of_nonneg_of_le (fun p => by positivity) (hbound R hR) ?_
    simpa [mul_div_assoc] using (Real.summable_pow_div_factorial (R ^ 2)).mul_left (R ^ m)
  have hsum0 : ∀ R : ℝ, 1 ≤ R → Summable fun p => ‖a p‖ * R ^ (e p) := by
    intro R hR
    refine Summable.of_nonneg_of_le (fun p => by positivity) (fun p => ?_) (hsumB R hR)
    have : (1 : ℝ) ≤ ((e p : ℕ) : ℝ) + 1 := by have := (e p).cast_nonneg (α := ℝ); linarith
    have h0 : 0 ≤ ‖a p‖ * R ^ (e p) := by positivity
    nlinarith
  have hsum1 : ∀ R : ℝ, 1 ≤ R → Summable fun p => ‖a p * (e p : ℂ)‖ * R ^ (e p - 1) := by
    intro R hR
    refine Summable.of_nonneg_of_le (fun p => by positivity) (fun p => ?_) (hsumB R hR)
    rw [norm_mul, Complex.norm_natCast]
    have hpow : R ^ (e p - 1) ≤ R ^ (e p) := pow_le_pow_right₀ hR (Nat.sub_le _ _)
    have : ‖a p‖ * (e p : ℝ) ≤ ‖a p‖ * (((e p : ℕ) : ℝ) + 1) := by
      have := norm_nonneg (a p); nlinarith
    calc ‖a p‖ * (e p : ℝ) * R ^ (e p - 1) ≤ ‖a p‖ * (((e p : ℕ) : ℝ) + 1) * R ^ (e p) := by
          gcongr
      _ = _ := rfl
  have h1 : ∀ w, HasSum (fun p => a p * (e p : ℂ) * w ^ (e p - 1))
      (deriv (Complex.besselJ (m : ℂ)) w) := by
    intro w; rw [hJ]; exact hasSum_deriv_tsum_pow a e hsum0 w
  have hJ' : deriv (Complex.besselJ (m : ℂ)) = fun w => ∑' p, (a p * (e p : ℂ)) * w ^ (e p - 1) :=
    funext fun w => (h1 w).tsum_eq.symm
  have h2 : HasSum (fun p => a p * (e p : ℂ) * ((e p - 1 : ℕ) : ℂ) * x ^ (e p - 1 - 1))
      (deriv^[2] (Complex.besselJ (m : ℂ)) x) := by
    show HasSum _ (deriv (deriv (Complex.besselJ (m : ℂ))) x)
    rw [hJ']
    exact hasSum_deriv_tsum_pow (fun p => a p * (e p : ℂ)) (fun p => e p - 1) hsum1 x
  have hpow2 : ∀ n : ℕ, x ^ 2 * ((n : ℂ) * ((n - 1 : ℕ) : ℂ) * x ^ (n - 1 - 1)) =
      n * ((n : ℂ) - 1) * x ^ n := by
    intro n
    rcases n with _ | _ | n
    · simp
    · simp
    · simp only [Nat.add_sub_cancel]; push_cast; ring
  have hpow1 : ∀ n : ℕ, x * ((n : ℂ) * x ^ (n - 1)) = n * x ^ n := by
    intro n
    rcases n with _ | n
    · simp
    · simp only [Nat.add_sub_cancel]; ring
  set V : ℕ → ℂ := fun p => x ^ 2 * (a p * x ^ (e p)) with hVdef
  have hV : HasSum V (x ^ 2 * Complex.besselJ (m : ℂ) x) := (h0 x).mul_left _
  have hT := (((h2.mul_left (x ^ 2)).add ((h1 x).mul_left x)).add ((h0 x).mul_left (x ^ 2 - (m : ℂ) ^ 2))).sub hV
  set W : ℕ → ℂ := fun p => x ^ 2 * (a p * (e p : ℂ) * ((e p - 1 : ℕ) : ℂ) * x ^ (e p - 1 - 1)) +
      x * (a p * (e p : ℂ) * x ^ (e p - 1)) + (x ^ 2 - (m : ℂ) ^ 2) * (a p * x ^ (e p)) - V p
    with hWdef
  have hWeq : ∀ p, W p = a p * (((e p : ℕ) : ℂ) ^ 2 - (m : ℂ) ^ 2) * x ^ (e p) := by
    intro p
    have q2 := hpow2 (e p)
    have q1 := hpow1 (e p)
    simp only [hWdef, hVdef]
    linear_combination (a p) * q2 + (a p) * q1
  have hW0 : W 0 = 0 := by rw [hWeq]; simp [he]
  have hWs : ∀ p, W (p + 1) = - V p := by
    intro p
    rw [hWeq]
    simp only [hVdef, ha, he]
    rw [show p + 1 + m = (p + m) + 1 by ring, Nat.factorial_succ, Nat.factorial_succ]
    have hp1 : (p : ℂ) + 1 ≠ 0 := by norm_cast
    have hpm : (p : ℂ) + m + 1 ≠ 0 := by norm_cast
    have hf1 : (p.factorial : ℂ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero p
    have hf2 : ((p + m).factorial : ℂ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero _
    push_cast
    field_simp
    ring
  have hW1 : HasSum (fun p => W (p + 1)) _ := (hasSum_nat_add_iff' 1).mpr hT
  simp only [Finset.range_one, Finset.sum_singleton] at hW1
  rw [hW0, sub_zero] at hW1
  have hW2 : HasSum (fun p => W (p + 1)) (-(x ^ 2 * Complex.besselJ (m : ℂ) x)) := by
    simp only [hWs]; exact hV.neg
  have := hW1.unique hW2
  linear_combination this

#print axioms besselJ_series_solves_bessel_equation_aux

theorem besselJ_ofReal_im (m : ℕ) (s : ℝ) : (Complex.besselJ (m : ℂ) (s : ℂ)).im = 0 := by
  have h := (besselJ_hasSum_series m (s : ℂ)).mapL Complex.imCLM
  have h0 : (fun p : ℕ => Complex.imCLM ((-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) *
      ((s : ℂ) / 2) ^ (2 * p + m))) = fun _ => 0 := by
    funext p
    have : (-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) * ((s : ℂ) / 2) ^ (2 * p + m)
        = (((-1 : ℝ) ^ p / ((p.factorial : ℝ) * ((p + m).factorial : ℝ)) * (s / 2) ^ (2 * p + m) : ℝ) : ℂ) := by
      push_cast; ring
    rw [this, Complex.imCLM_apply, Complex.ofReal_im]
  rw [h0] at h
  exact (h.unique hasSum_zero)

#print axioms besselJ_ofReal_im

theorem deriv2_of_hasDerivAt (g g1 g2 : ℝ → ℝ) (h1 : ∀ s, HasDerivAt g (g1 s) s)
    (h2 : ∀ s, HasDerivAt g1 (g2 s) s) (s : ℝ) : deriv^[2] g s = g2 s := by
  have : deriv g = g1 := funext fun s => (h1 s).deriv
  show deriv (deriv g) s = _
  rw [this]
  exact (h2 s).deriv

#print axioms deriv2_of_hasDerivAt

/-- Drumhead modes. For a whole number `m`, the separated shape
`u(r, θ, t) = J_m(k r) (A cos(mθ) + B sin(mθ)) cos(c k t)`, with `J_m` Bessel's function of
order `m`, solves the wave equation written in polar coordinates,
`u_tt = c² (u_rr + u_r / r + u_θθ / r²)`, at every point off the centre; and, when the
angular part is not zero everywhere (`A ≠ 0`, or `m ≠ 0` and `B ≠ 0`: for `m = 0` the sine term
is zero), it is zero all round the rim `r = R` exactly when `k R` is a zero of `J_m`. -/
theorem drum_modes_are_bessel_patterns (m : ℕ) (c k R A B : ℝ)
    (hAB : A ≠ 0 ∨ (m ≠ 0 ∧ B ≠ 0)) :
    let u : ℝ → ℝ → ℝ → ℝ := fun r θ t =>
      (Complex.besselJ (m : ℂ) ((k * r : ℝ) : ℂ)).re *
        (A * Real.cos (m * θ) + B * Real.sin (m * θ)) * Real.cos (c * k * t)
    (∀ r θ t : ℝ, 0 < r →
      deriv^[2] (fun t => u r θ t) t =
        c ^ 2 * (deriv^[2] (fun r => u r θ t) r + deriv (fun r => u r θ t) r / r +
          deriv^[2] (fun θ => u r θ t) θ / r ^ 2)) ∧
    ((∀ θ t : ℝ, u R θ t = 0) ↔ Complex.besselJ (m : ℂ) ((k * R : ℝ) : ℂ) = 0) := by
  intro u
  have hJa : ∀ z, AnalyticAt ℂ (Complex.besselJ (m : ℂ)) z := by
    intro z
    have := Complex.analyticAt_besselJ_int (m : ℤ) z
    simpa using this
  obtain ⟨f, hfdef⟩ : ∃ f : ℝ → ℝ, f = fun s : ℝ => (Complex.besselJ (m : ℂ) (s : ℂ)).re := ⟨_, rfl⟩
  obtain ⟨f1, hf1def⟩ : ∃ f1 : ℝ → ℝ,
      f1 = fun s : ℝ => (deriv (Complex.besselJ (m : ℂ)) (s : ℂ)).re := ⟨_, rfl⟩
  obtain ⟨f2, hf2def⟩ : ∃ f2 : ℝ → ℝ,
      f2 = fun s : ℝ => (deriv (deriv (Complex.besselJ (m : ℂ))) (s : ℂ)).re := ⟨_, rfl⟩
  have hf : ∀ s, HasDerivAt f (f1 s) s := by
    intro s; rw [hfdef, hf1def]
    exact ((hJa s).differentiableAt.hasDerivAt).real_of_complex
  have hf1 : ∀ s, HasDerivAt f1 (f2 s) s := by
    intro s; rw [hf1def, hf2def]
    exact ((hJa s).deriv.differentiableAt.hasDerivAt).real_of_complex
  have hode : ∀ s : ℝ, s ^ 2 * f2 s + s * f1 s + (s ^ 2 - (m : ℝ) ^ 2) * f s = 0 := by
    intro s
    have h := congrArg Complex.re (besselJ_series_solves_bessel_equation_aux m (s : ℂ)).2
    have e : deriv^[2] (Complex.besselJ (m : ℂ)) = deriv (deriv (Complex.besselJ (m : ℂ))) := rfl
    rw [e, show (s : ℂ) ^ 2 = ((s ^ 2 : ℝ) : ℂ) by push_cast; ring,
      show ((s ^ 2 : ℝ) : ℂ) - (m : ℂ) ^ 2 = ((s ^ 2 - (m : ℝ) ^ 2 : ℝ) : ℂ) by push_cast; ring]
      at h
    rw [hfdef, hf1def, hf2def]
    simpa only [Complex.add_re, Complex.re_ofReal_mul, Complex.zero_re] using h
  have hu : ∀ r θ t, u r θ t =
      f (k * r) * (A * Real.cos (m * θ) + B * Real.sin (m * θ)) * Real.cos (c * k * t) := by
    intro r θ t; rw [hfdef]
  refine ⟨?_, ?_⟩
  · intro r θ t hr
    obtain ⟨F, hF⟩ : ∃ F, F = f (k * r) := ⟨_, rfl⟩
    obtain ⟨cs, hcs⟩ : ∃ x, x = Real.cos (m * θ) := ⟨_, rfl⟩
    obtain ⟨sn, hsn⟩ : ∃ x, x = Real.sin (m * θ) := ⟨_, rfl⟩
    obtain ⟨C, hC⟩ : ∃ x, x = Real.cos (c * k * t) := ⟨_, rfl⟩
    have hut : (fun t => u r θ t) = fun t => F * (A * cs + B * sn) * Real.cos (c * k * t) := by
      funext t; rw [hu, hF, hcs, hsn]
    have hur : (fun r => u r θ t) = fun r => f (k * r) * ((A * cs + B * sn) * C) := by
      funext r; rw [hu, hcs, hsn, hC, mul_assoc]
    have huθ : (fun θ => u r θ t) =
        fun θ => F * (A * Real.cos (m * θ) + B * Real.sin (m * θ)) * C := by
      funext θ; rw [hu, hF, hC]
    have ht : deriv^[2] (fun t => u r θ t) t = F * (A * cs + B * sn) * (-(C * (c * k) * (c * k))) := by
      rw [hut, hC]
      refine deriv2_of_hasDerivAt _ (fun t => F * (A * cs + B * sn) * (-(Real.sin (c * k * t)) * (c * k)))
        (fun t => F * (A * cs + B * sn) * (-(Real.cos (c * k * t) * (c * k) * (c * k))))
        (fun s => ?_) (fun s => ?_) t
      · exact ((((hasDerivAt_id' s).const_mul (c * k)).cos).const_mul (F * (A * cs + B * sn))).congr_deriv
          (by ring)
      · exact ((((hasDerivAt_id' s).const_mul (c * k)).sin).neg.mul_const (c * k)).const_mul
          (F * (A * cs + B * sn)) |>.congr_deriv (by ring)
    have hr1 : ∀ s, HasDerivAt (fun r => f (k * r) * ((A * cs + B * sn) * C))
        (f1 (k * s) * k * ((A * cs + B * sn) * C)) s := by
      intro s
      exact (((hf (k * s)).comp s ((hasDerivAt_id' s).const_mul k)).mul_const
        ((A * cs + B * sn) * C)).congr_deriv (by ring)
    have hr2 : ∀ s, HasDerivAt (fun s => f1 (k * s) * k * ((A * cs + B * sn) * C))
        (f2 (k * s) * k * k * ((A * cs + B * sn) * C)) s := by
      intro s
      exact ((((hf1 (k * s)).comp s ((hasDerivAt_id' s).const_mul k)).mul_const k).mul_const
        ((A * cs + B * sn) * C)).congr_deriv (by ring)
    have hrr : deriv^[2] (fun r => u r θ t) r = f2 (k * r) * k * k * ((A * cs + B * sn) * C) := by
      rw [hur]; exact deriv2_of_hasDerivAt _ _ _ hr1 hr2 r
    have hr' : deriv (fun r => u r θ t) r = f1 (k * r) * k * ((A * cs + B * sn) * C) := by
      rw [hur]; exact (hr1 r).deriv
    have hth : deriv^[2] (fun θ => u r θ t) θ =
        F * (A * (-(cs * m * m)) + B * (-(sn * m * m))) * C := by
      rw [huθ, hcs, hsn]
      refine deriv2_of_hasDerivAt _
        (fun θ => F * (A * (-(Real.sin (m * θ)) * m) + B * (Real.cos (m * θ) * m)) * C)
        (fun θ => F * (A * (-(Real.cos (m * θ) * m * m)) + B * (-(Real.sin (m * θ) * m * m))) * C)
        (fun s => ?_) (fun s => ?_) θ
      · exact (((((((hasDerivAt_id' s).const_mul (m : ℝ)).cos).const_mul A).add
          ((((hasDerivAt_id' s).const_mul (m : ℝ)).sin).const_mul B))).const_mul F).mul_const C
          |>.congr_deriv (by ring)
      · exact (((((((hasDerivAt_id' s).const_mul (m : ℝ)).sin).neg.mul_const (m : ℝ)).const_mul A).add
          (((((hasDerivAt_id' s).const_mul (m : ℝ)).cos).mul_const (m : ℝ)).const_mul B))).const_mul F
          |>.mul_const C |>.congr_deriv (by ring)
    rw [ht, hrr, hr', hth]
    have hO := hode (k * r)
    rw [← hF] at hO
    have hr0 : r ≠ 0 := hr.ne'
    field_simp
    linear_combination (-(c ^ 2) * (A * cs + B * sn) * C) * hO
  · have him := besselJ_ofReal_im m (k * R)
    have hre : (Complex.besselJ (m : ℂ) ((k * R : ℝ) : ℂ)).re = f (k * R) := by rw [hfdef]
    constructor
    · intro h
      have hfz : f (k * R) = 0 := by
        rcases hAB with hA | ⟨hm, hB⟩
        · have := h 0 0
          rw [hu] at this
          simp only [mul_zero, Real.cos_zero, Real.sin_zero, mul_one, add_zero] at this
          exact (mul_eq_zero.mp this).resolve_right hA
        · have := h (π / (2 * m)) 0
          have hm' : (m : ℝ) ≠ 0 := by exact_mod_cast hm
          have e2 : (m : ℝ) * (π / (2 * m)) = π / 2 := by field_simp
          rw [hu, e2] at this
          simp only [mul_zero, Real.cos_zero, Real.cos_pi_div_two, Real.sin_pi_div_two,
            mul_one, zero_add] at this
          exact (mul_eq_zero.mp this).resolve_right hB
      exact Complex.ext (by rw [hre, hfz]; rfl) him
    · intro h θ t
      have hfz : f (k * R) = 0 := by rw [← hre, h]; rfl
      rw [hu, hfz, zero_mul, zero_mul]

/-- Bessel's function of order `m` is the card's series
`J_m(x) = ∑ (-1)^p / (p! (p+m)!) (x/2)^(2p+m)`, and it solves Bessel's equation of order `m`,
`x² y'' + x y' + (x² - m²) y = 0`. -/
theorem besselJ_series_solves_bessel_equation (m : ℕ) (x : ℂ) :
    HasSum (fun p : ℕ => (-1 : ℂ) ^ p / ((p.factorial : ℂ) * ((p + m).factorial : ℂ)) *
        (x / 2) ^ (2 * p + m)) (Complex.besselJ (m : ℂ) x) ∧
    x ^ 2 * deriv^[2] (Complex.besselJ (m : ℂ)) x + x * deriv (Complex.besselJ (m : ℂ)) x +
        (x ^ 2 - (m : ℂ) ^ 2) * Complex.besselJ (m : ℂ) x = 0 := by
  exact besselJ_series_solves_bessel_equation_aux m x

/-- The angular part `A cos(mθ) + B sin(mθ)`, not identically zero, takes the same value at
`θ` and `θ + 2π` for every `θ` exactly when `m` is a whole number. -/
theorem angular_part_closes_iff_whole (m A B : ℝ) (hAB : A ≠ 0 ∨ B ≠ 0) :
    (∀ θ : ℝ, A * Real.cos (m * (θ + 2 * π)) + B * Real.sin (m * (θ + 2 * π)) =
        A * Real.cos (m * θ) + B * Real.sin (m * θ)) ↔ ∃ n : ℤ, m = n := by
  constructor
  · intro h
    by_cases hm : m = 0
    · exact ⟨0, by simp [hm]⟩
    have h0 := h 0
    have h1 := h (π / (2 * m))
    have e1 : m * (π / (2 * m) + 2 * π) = π / 2 + m * (2 * π) := by field_simp
    have e2 : m * (π / (2 * m)) = π / 2 := by field_simp
    rw [e1, e2, Real.cos_add, Real.sin_add] at h1
    simp only [mul_zero, zero_add, Real.cos_zero, Real.sin_zero, Real.cos_pi_div_two,
      Real.sin_pi_div_two] at h0 h1
    have hc : Real.cos (m * (2 * π)) = 1 := by
      have hpos : 0 < A ^ 2 + B ^ 2 := by
        rcases hAB with h | h
        · positivity
        · positivity
      have : (A ^ 2 + B ^ 2) * (Real.cos (m * (2 * π)) - 1) = 0 := by
        have h0' : A * (Real.cos (m * (2 * π)) - 1) + B * Real.sin (m * (2 * π)) = 0 := by
          linarith
        have h1' : -A * Real.sin (m * (2 * π)) + B * (Real.cos (m * (2 * π)) - 1) = 0 := by
          linarith
        linear_combination A * h0' + B * h1'
      have := (mul_eq_zero.mp this).resolve_left hpos.ne'
      linarith
    obtain ⟨n, hn⟩ := (Real.cos_eq_one_iff _).mp hc
    refine ⟨n, ?_⟩
    have hpi : (2 * π) ≠ 0 := by positivity
    exact (mul_right_cancel₀ hpi hn).symm
  · rintro ⟨n, rfl⟩ θ
    have e : (n : ℝ) * (θ + 2 * π) = n * θ + n * (2 * π) := by ring
    rw [e, Real.cos_add_int_mul_two_pi, Real.sin_add_int_mul_two_pi]

/-- Wave speed: tension 2000 N/m over 0.2 kg/m² gives c = 100 m/s. -/
example : Real.sqrt (2000 / (1 / 5)) = 100 := by
  rw [show (2000 : ℝ) / (1 / 5) = 100 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

/-- Tightening the head four times doubles the wave speed, to 200 m/s. -/
example : Real.sqrt (4 * 2000 / (1 / 5)) = 200 := by
  rw [show (4 * 2000 : ℝ) / (1 / 5) = 200 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

/-- m = 3/2 tears the head: cos(1.5 θ) is 1 at θ = 0 and -1 after a full turn, a jump of 2. -/
example : Real.cos (3 / 2 * 0) - Real.cos (3 / 2 * (0 + 2 * π)) = 2 := by
  have h : (3 : ℝ) / 2 * (0 + 2 * π) = (3 : ℕ) * π := by push_cast; ring
  rw [h, Real.cos_nat_mul_pi]
  norm_num

/-- Reading the 30 cm width as the radius halves every note `c j / (2π R)`. -/
example (c j : ℝ) : c * j / (2 * π * (3 / 10)) = (c * j / (2 * π * (3 / 20))) / 2 := by
  have : π ≠ 0 := Real.pi_ne_zero
  field_simp
  ring

#print axioms drum_modes_are_bessel_patterns
#print axioms besselJ_series_solves_bessel_equation
#print axioms angular_part_closes_iff_whole
