-- d'Alembert: the wave equation u_tt = c^2 u_xx is two transport equations, so u_t - c u_x rides right along x - ct = constant and u_t + c u_x rides left along x + ct = constant, d'Alembert's formula is the one classical solution, and a corner in a string released from rest splits into two corners, each carrying half the jump in slope.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.MeanValue

theorem wave_deriv_snd_eq (G : ℝ × ℝ → ℝ) (x t : ℝ) (hG : DifferentiableAt ℝ G (x, t)) :
    HasDerivAt (fun t => G (x, t)) (fderiv ℝ G (x, t) (0, 1)) t := by
  have h1 : HasDerivAt (fun t : ℝ => (x, t)) ((0 : ℝ), (1 : ℝ)) t :=
    (hasDerivAt_const t x).prodMk (hasDerivAt_id t)
  exact hG.hasFDerivAt.comp_hasDerivAt t h1

#print axioms wave_deriv_snd_eq

theorem wave_deriv_fst_eq (G : ℝ × ℝ → ℝ) (x t : ℝ) (hG : DifferentiableAt ℝ G (x, t)) :
    HasDerivAt (fun x => G (x, t)) (fderiv ℝ G (x, t) (1, 0)) x := by
  have h1 : HasDerivAt (fun x : ℝ => (x, t)) ((1 : ℝ), (0 : ℝ)) x :=
    (hasDerivAt_id x).prodMk (hasDerivAt_const x t)
  exact hG.hasFDerivAt.comp_hasDerivAt x h1

#print axioms wave_deriv_fst_eq

theorem wave_fderiv_apply (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 2 F) (p v w : ℝ × ℝ) :
    fderiv ℝ (fun q => fderiv ℝ F q w) p v = fderiv ℝ (fderiv ℝ F) p v w := by
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  rw [fderiv_clm_apply (hd p) (differentiableAt_const w)]
  simp

#print axioms wave_fderiv_apply

theorem wave_signal_const (k : ℝ) (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 2 F)
    (hw : ∀ x t, 0 ≤ t → fderiv ℝ (fderiv ℝ F) (x, t) (0, 1) (0, 1) =
      k ^ 2 * fderiv ℝ (fderiv ℝ F) (x, t) (1, 0) (1, 0)) (x0 t : ℝ) (ht : 0 ≤ t) :
    fderiv ℝ F (x0 + k * t, t) (0, 1) - k * fderiv ℝ F (x0 + k * t, t) (1, 0) =
      fderiv ℝ F (x0, 0) (0, 1) - k * fderiv ℝ F (x0, 0) (1, 0) := by
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have hγ : ∀ s : ℝ, HasDerivAt (fun s : ℝ => (x0 + k * s, s)) (k, (1 : ℝ)) s := by
    intro s
    have := ((hasDerivAt_id s).const_mul k).const_add x0
    simp only [mul_one] at this
    exact this.prodMk (hasDerivAt_id s)
  have hA : ∀ (w : ℝ × ℝ) s, HasDerivAt (fun s => fderiv ℝ F (x0 + k * s, s) w)
      (fderiv ℝ (fderiv ℝ F) (x0 + k * s, s) (k, 1) w) s := by
    intro w s
    have := (((hd _).clm_apply (differentiableAt_const w)).hasFDerivAt).comp_hasDerivAt s (hγ s)
    rwa [wave_fderiv_apply F hF] at this
  have hW : ∀ s, HasDerivAt (fun s => fderiv ℝ F (x0 + k * s, s) (0, 1) -
      k * fderiv ℝ F (x0 + k * s, s) (1, 0))
      (fderiv ℝ (fderiv ℝ F) (x0 + k * s, s) (k, 1) (0, 1) -
        k * fderiv ℝ (fderiv ℝ F) (x0 + k * s, s) (k, 1) (1, 0)) s :=
    fun s => (hA _ s).sub ((hA _ s).const_mul k)
  have hzero : ∀ s, 0 ≤ s → fderiv ℝ (fderiv ℝ F) (x0 + k * s, s) (k, 1) (0, 1) -
        k * fderiv ℝ (fderiv ℝ F) (x0 + k * s, s) (k, 1) (1, 0) = 0 := by
    intro s hs
    have hsymm := (hF.contDiffAt (x := (x0 + k * s, s))).isSymmSndFDerivAt (by simp)
    have hv : ((k, 1) : ℝ × ℝ) = k • ((1, 0) : ℝ × ℝ) + ((0, 1) : ℝ × ℝ) := by
      ext <;> simp
    rw [hv]
    simp only [map_add, map_smul, add_apply, smul_apply,
      smul_eq_mul]
    rw [hsymm.eq (1, 0) (0, 1), hw _ _ hs]
    ring
  have hc := constant_of_has_deriv_right_zero (a := 0) (b := t)
    (fun s _ => (hW s).continuousAt.continuousWithinAt)
    (fun s hs => by
      have := (hW s).hasDerivWithinAt (s := Set.Ici s)
      rwa [hzero s hs.1] at this) t ⟨ht, le_rfl⟩
  simpa using hc

#print axioms wave_signal_const

theorem wave_partials (F : ℝ × ℝ → ℝ) (hF : ContDiff ℝ 2 F) :
    (∀ x t, deriv (fun t => F (x, t)) t = fderiv ℝ F (x, t) (0, 1)) ∧
    (∀ x t, deriv (fun x => F (x, t)) x = fderiv ℝ F (x, t) (1, 0)) ∧
    (∀ x t, deriv (fun t => deriv (fun t => F (x, t)) t) t =
      fderiv ℝ (fderiv ℝ F) (x, t) (0, 1) (0, 1)) ∧
    (∀ x t, deriv (fun x => deriv (fun x => F (x, t)) x) x =
      fderiv ℝ (fderiv ℝ F) (x, t) (1, 0) (1, 0)) := by
  have hF1 : Differentiable ℝ F := hF.differentiable (by norm_num)
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have h1 : ∀ x t, deriv (fun t => F (x, t)) t = fderiv ℝ F (x, t) (0, 1) :=
    fun x t => (wave_deriv_snd_eq F x t (hF1 _)).deriv
  have h2 : ∀ x t, deriv (fun x => F (x, t)) x = fderiv ℝ F (x, t) (1, 0) :=
    fun x t => (wave_deriv_fst_eq F x t (hF1 _)).deriv
  refine ⟨h1, h2, ?_, ?_⟩
  · intro x t
    have e : (fun t => deriv (fun t => F (x, t)) t) = fun t => fderiv ℝ F (x, t) (0, 1) :=
      funext (h1 x)
    rw [e, (wave_deriv_snd_eq (fun q => fderiv ℝ F q (0, 1)) x t
      ((hd _).clm_apply (differentiableAt_const _))).deriv, wave_fderiv_apply F hF]
  · intro x t
    have e : (fun x => deriv (fun x => F (x, t)) x) = fun x => fderiv ℝ F (x, t) (1, 0) :=
      funext (fun x => h2 x t)
    rw [e, (wave_deriv_fst_eq (fun q => fderiv ℝ F q (1, 0)) x t
      ((hd _).clm_apply (differentiableAt_const _))).deriv, wave_fderiv_apply F hF]

#print axioms wave_partials

theorem wave_affine_hasDerivAt (c : ℝ) (φ φ' : ℝ → ℝ) (hφ : ∀ y, HasDerivAt φ (φ' y) y) (x t : ℝ) :
    HasDerivAt (fun t => φ (x + c * t)) (c * φ' (x + c * t)) t ∧
    HasDerivAt (fun t => φ (x - c * t)) (-c * φ' (x - c * t)) t ∧
    HasDerivAt (fun x => φ (x + c * t)) (φ' (x + c * t)) x ∧
    HasDerivAt (fun x => φ (x - c * t)) (φ' (x - c * t)) x := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · have h := ((hasDerivAt_id t).const_mul c).const_add x
    simp only [mul_one] at h
    have := (hφ (x + c * t)).comp t h
    rwa [mul_comm] at this
  · have h := ((hasDerivAt_id t).const_mul c).const_sub x
    simp only [mul_one] at h
    have := (hφ (x - c * t)).comp t h
    rw [mul_comm, neg_mul] at this
    rw [neg_mul]
    exact this
  · have := (hφ (x + c * t)).comp x ((hasDerivAt_id x).add_const (c * t))
    rwa [mul_one] at this
  · have := (hφ (x - c * t)).comp x ((hasDerivAt_id x).sub_const (c * t))
    rwa [mul_one] at this

#print axioms wave_affine_hasDerivAt

/-- The two signals ride the characteristics. Take wave speed `c > 0`, a starting shape `f`
with two continuous rates and a starting velocity `g` with one. Let `u` have two continuous
rates in `(x, t)` and solve `u_tt = c^2 u_xx` for `t ≥ 0`, with `u(x, 0) = f(x)` and
`u_t(x, 0) = g(x)`. Then for every `x` and every `t ≥ 0` the right-riding signal
`w = u_t - c u_x` equals its starting value `g - c f'` at `x - ct`, and the left-riding signal
`v = u_t + c u_x` equals its starting value `g + c f'` at `x + ct`. -/
theorem wave_signals_ride_characteristics (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiff ℝ 2 f) (hg : ContDiff ℝ 1 g) (u : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hwave : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x)
    (h0 : ∀ x, u x 0 = f x) (h1 : ∀ x, deriv (fun t => u x t) 0 = g x) :
    ∀ x t, 0 ≤ t →
      deriv (fun t => u x t) t - c * deriv (fun x => u x t) x =
          g (x - c * t) - c * deriv f (x - c * t) ∧
      deriv (fun t => u x t) t + c * deriv (fun x => u x t) x =
          g (x + c * t) + c * deriv f (x + c * t) := by
  set F : ℝ × ℝ → ℝ := fun p => u p.1 p.2 with hFdef
  obtain ⟨p1, p2, p3, p4⟩ := wave_partials F hu
  have hw : ∀ (k : ℝ), k ^ 2 = c ^ 2 → ∀ x t, 0 ≤ t →
      fderiv ℝ (fderiv ℝ F) (x, t) (0, 1) (0, 1) =
        k ^ 2 * fderiv ℝ (fderiv ℝ F) (x, t) (1, 0) (1, 0) := by
    intro k hk x t ht
    rw [hk, ← p3, ← p4]
    exact hwave x t ht
  have hfx : ∀ y, deriv (fun x => u x 0) y = deriv f y := by
    intro y
    have : (fun x => u x 0) = f := funext h0
    rw [this]
  intro x t ht
  have A := wave_signal_const c F hu (hw c rfl) (x - c * t) t ht
  have B := wave_signal_const (-c) F hu (hw (-c) (by ring)) (x + c * t) t ht
  have ex1 : x - c * t + c * t = x := by ring
  have ex2 : x + c * t + -c * t = x := by ring
  rw [ex1] at A
  rw [ex2] at B
  rw [← p1, ← p2, ← p1, ← p2] at A B
  simp only [hFdef] at A B
  rw [hfx, h1] at A B
  constructor
  · linarith
  · linarith

/-- d'Alembert's formula, rebuilt from the two signals. With wave speed `c > 0`, a starting
shape `f` with two continuous rates and a starting velocity `g` with one,
`u(x,t) = (f(x - ct) + f(x + ct)) / 2 + (1 / 2c) ∫_{x-ct}^{x+ct} g(y) dy`
has two continuous rates, solves `u_tt = c^2 u_xx`, starts with shape `f` and velocity `g`,
and is the only such classical solution for `t ≥ 0`. -/
theorem dalembert_formula_unique_classical_solution (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiff ℝ 2 f) (hg : ContDiff ℝ 1 g) :
    let u : ℝ → ℝ → ℝ := fun x t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * ∫ y in (x - c * t)..(x + c * t), g y
    ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) ∧
    (∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
    (∀ x, u x 0 = f x) ∧
    (∀ x, deriv (fun t => u x t) 0 = g x) ∧
    (∀ v : ℝ → ℝ → ℝ, ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2) →
      (∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x) →
      (∀ x, v x 0 = f x) →
      (∀ x, deriv (fun t => v x t) 0 = g x) →
      ∀ x t, 0 ≤ t → v x t = u x t) := by
  intro u
  have hcne : c ≠ 0 := hc.ne'
  set G : ℝ → ℝ := fun y => ∫ s in (0 : ℝ)..y, g s with hGdef
  have hgc : Continuous g := hg.continuous
  have hGd : ∀ y, HasDerivAt G (g y) y := fun y => (hgc.integral_hasStrictDerivAt 0 y).hasDerivAt
  have hG2 : ContDiff ℝ 2 G := by
    have : ContDiff ℝ (1 + 1) G := by
      rw [contDiff_succ_iff_deriv]
      refine ⟨fun y => (hGd y).differentiableAt, by simp, ?_⟩
      have e : deriv G = g := funext fun y => (hGd y).deriv
      rw [e]; exact hg
    exact this
  have hf' : ContDiff ℝ (1 + 1) f := hf
  rw [contDiff_succ_iff_deriv] at hf'
  have hfd : ∀ y, HasDerivAt f (deriv f y) y :=
    fun y => (hf.differentiable (by norm_num) y).hasDerivAt
  have hf1d : ∀ y, HasDerivAt (deriv f) (deriv (deriv f) y) y :=
    fun y => (hf'.2.2.differentiable (by norm_num) y).hasDerivAt
  have hgd : ∀ y, HasDerivAt g (deriv g y) y :=
    fun y => (hg.differentiable (by norm_num) y).hasDerivAt
  have hu' : u = fun x t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * (G (x + c * t) - G (x - c * t)) := by
    funext x t
    simp only [u, hGdef]
    rw [intervalIntegral.integral_interval_sub_left (hgc.intervalIntegrable _ _)
      (hgc.intervalIntegrable _ _)]
  clear_value u
  subst hu'
  -- first and second derivatives
  have hUt : ∀ x t, HasDerivAt (fun t => (f (x - c * t) + f (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t)))
      ((-c * deriv f (x - c * t) + c * deriv f (x + c * t)) / 2 +
        1 / (2 * c) * (c * g (x + c * t) - -c * g (x - c * t))) t := by
    intro x t
    have F := wave_affine_hasDerivAt c f _ hfd x t
    have H := wave_affine_hasDerivAt c G g hGd x t
    exact ((F.2.1.add F.1).div_const 2).add ((H.1.sub H.2.1).const_mul _)
  have hUx : ∀ x t, HasDerivAt (fun x => (f (x - c * t) + f (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t)))
      ((deriv f (x - c * t) + deriv f (x + c * t)) / 2 +
        1 / (2 * c) * (g (x + c * t) - g (x - c * t))) x := by
    intro x t
    have F := wave_affine_hasDerivAt c f _ hfd x t
    have H := wave_affine_hasDerivAt c G g hGd x t
    exact ((F.2.2.2.add F.2.2.1).div_const 2).add ((H.2.2.1.sub H.2.2.2).const_mul _)
  have hUtt : ∀ x t, HasDerivAt (fun t => (-c * deriv f (x - c * t) + c * deriv f (x + c * t)) / 2 +
        1 / (2 * c) * (c * g (x + c * t) - -c * g (x - c * t)))
      ((-c * (-c * deriv (deriv f) (x - c * t)) + c * (c * deriv (deriv f) (x + c * t))) / 2 +
        1 / (2 * c) * (c * (c * deriv g (x + c * t)) - -c * (-c * deriv g (x - c * t)))) t := by
    intro x t
    have F := wave_affine_hasDerivAt c (deriv f) _ hf1d x t
    have H := wave_affine_hasDerivAt c g _ hgd x t
    exact (((F.2.1.const_mul (-c)).add (F.1.const_mul c)).div_const 2).add
      (((H.1.const_mul c).sub (H.2.1.const_mul (-c))).const_mul _)
  have hUxx : ∀ x t, HasDerivAt (fun x => (deriv f (x - c * t) + deriv f (x + c * t)) / 2 +
        1 / (2 * c) * (g (x + c * t) - g (x - c * t)))
      ((deriv (deriv f) (x - c * t) + deriv (deriv f) (x + c * t)) / 2 +
        1 / (2 * c) * (deriv g (x + c * t) - deriv g (x - c * t))) x := by
    intro x t
    have F := wave_affine_hasDerivAt c (deriv f) _ hf1d x t
    have H := wave_affine_hasDerivAt c g _ hgd x t
    exact ((F.2.2.2.add F.2.2.1).div_const 2).add ((H.2.2.1.sub H.2.2.2).const_mul _)
  have hcd : ContDiff ℝ 2 (fun p : ℝ × ℝ => (f (p.1 - c * p.2) + f (p.1 + c * p.2)) / 2 +
      1 / (2 * c) * (G (p.1 + c * p.2) - G (p.1 - c * p.2))) := by
    fun_prop
  have hwave : ∀ x t, deriv (fun t => deriv (fun t => (f (x - c * t) + f (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => (f (x - c * t) + f (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) x) x := by
    intro x t
    have e1 := funext fun t => (hUt x t).deriv
    have e2 := funext fun x => (hUx x t).deriv
    rw [e1, e2, (hUtt x t).deriv, (hUxx x t).deriv]
    field_simp
  have h0 : ∀ x, (f (x - c * 0) + f (x + c * 0)) / 2 +
      1 / (2 * c) * (G (x + c * 0) - G (x - c * 0)) = f x := by
    intro x; simp
  have h1 : ∀ x, deriv (fun t => (f (x - c * t) + f (x + c * t)) / 2 +
      1 / (2 * c) * (G (x + c * t) - G (x - c * t))) 0 = g x := by
    intro x
    rw [(hUt x 0).deriv]
    simp only [mul_zero, sub_zero, add_zero]
    field_simp
    ring
  refine ⟨hcd, hwave, h0, h1, ?_⟩
  intro v hv hwv hv0 hv1 x t ht
  have hvd : Differentiable ℝ (fun p : ℝ × ℝ => v p.1 p.2) := hv.differentiable (by norm_num)
  have hud : Differentiable ℝ (fun p : ℝ × ℝ => (f (p.1 - c * p.2) + f (p.1 + c * p.2)) / 2 +
      1 / (2 * c) * (G (p.1 + c * p.2) - G (p.1 - c * p.2))) := hcd.differentiable (by norm_num)
  have same : ∀ s, 0 ≤ s → deriv (fun t => v x t) s = deriv (fun t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * (G (x + c * t) - G (x - c * t))) s := by
    intro s hs
    have A := wave_signals_ride_characteristics c hc f g hf hg v hv hwv hv0 hv1 x s hs
    have B := wave_signals_ride_characteristics c hc f g hf hg _ hcd (fun x t _ => hwave x t)
      h0 h1 x s hs
    linarith [A.1, A.2, B.1, B.2]
  have hD : ∀ s, HasDerivAt (fun s => v x s - ((f (x - c * s) + f (x + c * s)) / 2 +
      1 / (2 * c) * (G (x + c * s) - G (x - c * s))))
      (deriv (fun t => v x t) s - deriv (fun t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * (G (x + c * t) - G (x - c * t))) s) s := by
    intro s
    have h1 := (wave_deriv_snd_eq _ x s (hvd (x, s)))
    have h2 := (hUt x s)
    exact (h1.differentiableAt.hasDerivAt).sub (h2.differentiableAt.hasDerivAt)
  have hc0 := constant_of_has_deriv_right_zero (a := 0) (b := t)
    (fun s _ => (hD s).continuousAt.continuousWithinAt)
    (fun s hs => by
      have := (hD s).hasDerivWithinAt (s := Set.Ici s)
      rwa [same s hs.1, sub_self] at this) t ⟨ht, le_rfl⟩
  have := h0 x
  rw [hv0, this, sub_self] at hc0
  linarith

/-- A corner splits in two, each carrying half the jump. Release a string from rest with
starting shape `f` whose slope jumps at `a`: slope `m₁` just left of `a` and `m₂` just right.
Let `u(x,t) = (f(x - ct) + f(x + ct)) / 2` with `c > 0`. At a time `t > 0`, if `f` is smooth
at the far feet `a + 2ct` and `a - 2ct`, then the string has a corner at `a + ct` and one at
`a - ct`, and at each the slope jumps by `(m₂ - m₁) / 2`, half the starting jump. -/
theorem corner_splits_into_two_half_corners (c : ℝ) (hc : 0 < c) (f : ℝ → ℝ) (a m₁ m₂ : ℝ)
    (hl : HasDerivWithinAt f m₁ (Set.Iic a) a) (hr : HasDerivWithinAt f m₂ (Set.Ici a) a)
    (t : ℝ) (ht : 0 < t)
    (hR : DifferentiableAt ℝ f (a + 2 * c * t)) (hL : DifferentiableAt ℝ f (a - 2 * c * t)) :
    let u : ℝ → ℝ → ℝ := fun x t => (f (x - c * t) + f (x + c * t)) / 2
    (∃ sL sR : ℝ, HasDerivWithinAt (fun x => u x t) sL (Set.Iic (a + c * t)) (a + c * t) ∧
      HasDerivWithinAt (fun x => u x t) sR (Set.Ici (a + c * t)) (a + c * t) ∧
      sR - sL = (m₂ - m₁) / 2) ∧
    (∃ sL sR : ℝ, HasDerivWithinAt (fun x => u x t) sL (Set.Iic (a - c * t)) (a - c * t) ∧
      HasDerivWithinAt (fun x => u x t) sR (Set.Ici (a - c * t)) (a - c * t) ∧
      sR - sL = (m₂ - m₁) / 2) := by
  intro u
  -- the smooth foot of each corner
  have sR : ∀ s : Set ℝ, HasDerivWithinAt (fun x => f (x + c * t)) (deriv f (a + 2 * c * t)) s
      (a + c * t) := by
    intro s
    have h1 : HasDerivAt f (deriv f (a + c * t + c * t)) (a + c * t + c * t) := by
      rw [show a + c * t + c * t = a + 2 * c * t by ring]; exact hR.hasDerivAt
    have := h1.comp (a + c * t) ((hasDerivAt_id (a + c * t)).add_const (c * t))
    simp only [mul_one] at this
    rw [show a + c * t + c * t = a + 2 * c * t by ring] at this
    exact this.hasDerivWithinAt
  have sL : ∀ s : Set ℝ, HasDerivWithinAt (fun x => f (x - c * t)) (deriv f (a - 2 * c * t)) s
      (a - c * t) := by
    intro s
    have h1 : HasDerivAt f (deriv f (a - c * t - c * t)) (a - c * t - c * t) := by
      rw [show a - c * t - c * t = a - 2 * c * t by ring]; exact hL.hasDerivAt
    have := h1.comp (a - c * t) ((hasDerivAt_id (a - c * t)).sub_const (c * t))
    simp only [mul_one] at this
    rw [show a - c * t - c * t = a - 2 * c * t by ring] at this
    exact this.hasDerivWithinAt
  -- the corner foot, shifted
  have cR : ∀ (m : ℝ) (s s' : Set ℝ), HasDerivWithinAt f m s a → (∀ y ∈ s', y - c * t ∈ s) →
      HasDerivWithinAt (fun x => f (x - c * t)) m s' (a + c * t) := by
    intro m s s' h hs
    have h' : HasDerivWithinAt f m s (a + c * t - c * t) := by rwa [add_sub_cancel_right]
    have := h'.comp (a + c * t) ((hasDerivAt_id (a + c * t)).sub_const (c * t)).hasDerivWithinAt hs
    rw [mul_one] at this
    exact this
  have cL : ∀ (m : ℝ) (s s' : Set ℝ), HasDerivWithinAt f m s a → (∀ y ∈ s', y + c * t ∈ s) →
      HasDerivWithinAt (fun x => f (x + c * t)) m s' (a - c * t) := by
    intro m s s' h hs
    have h' : HasDerivWithinAt f m s (a - c * t + c * t) := by rwa [sub_add_cancel]
    have := h'.comp (a - c * t) ((hasDerivAt_id (a - c * t)).add_const (c * t)).hasDerivWithinAt hs
    rw [mul_one] at this
    exact this
  refine ⟨⟨(m₁ + deriv f (a + 2 * c * t)) / 2, (m₂ + deriv f (a + 2 * c * t)) / 2, ?_, ?_, by ring⟩,
    ⟨(deriv f (a - 2 * c * t) + m₁) / 2, (deriv f (a - 2 * c * t) + m₂) / 2, ?_, ?_, by ring⟩⟩
  · exact HasDerivWithinAt.div_const (HasDerivWithinAt.add
      (cR m₁ (Set.Iic a) (Set.Iic (a + c * t)) hl
        (fun y hy => by simp only [Set.mem_Iic] at *; linarith)) (sR _)) 2
  · exact HasDerivWithinAt.div_const (HasDerivWithinAt.add
      (cR m₂ (Set.Ici a) (Set.Ici (a + c * t)) hr
        (fun y hy => by simp only [Set.mem_Ici] at *; linarith)) (sR _)) 2
  · exact HasDerivWithinAt.div_const (HasDerivWithinAt.add (sL _)
      (cL m₁ (Set.Iic a) (Set.Iic (a - c * t)) hl
        (fun y hy => by simp only [Set.mem_Iic] at *; linarith))) 2
  · exact HasDerivWithinAt.div_const (HasDerivWithinAt.add (sL _)
      (cL m₂ (Set.Ici a) (Set.Ici (a - c * t)) hr
        (fun y hy => by simp only [Set.mem_Ici] at *; linarith))) 2

/-- The plucked open A string: 65 cm long, pulled 3 mm aside at 65/3 cm from the bridge.
Place in cm, height in mm. -/
def pluck (x : ℚ) : ℚ := if x ≤ 65 / 3 then 3 * x / (65 / 3) else 3 * (65 - x) / (65 - 65 / 3)

-- Wave speed: c = 2 × 65/100 m × 110 Hz = 143 m/s; one period 2L/c = 1/110 s.
example : (2 : ℚ) * (65 / 100) * 110 = 143 := by norm_num
example : (2 : ℚ) * (65 / 100) / 143 = 1 / 110 := by norm_num

-- A tenth of a period, 1/1100 s, carries a corner ct = 143 × 1/1100 m = 13 cm.
example : (143 : ℚ) * (1 / 1100) * 100 = 13 := by norm_num

-- The 12th fret, 65/2 cm, starts at 9/4 mm = 2.25 mm.
example : pluck (65 / 2) = 9 / 4 := by norm_num [pluck]

-- At a tenth of a period its feet are 39/2 cm and 91/2 cm, heights 27/10 and 27/20 mm,
-- and d'Alembert's average is 81/40 mm = 2.025 mm.
example : pluck (65 / 2 - 13) = 27 / 10 ∧ pluck (65 / 2 + 13) = 27 / 20 := by norm_num [pluck]
example : (pluck (65 / 2 - 13) + pluck (65 / 2 + 13)) / 2 = 81 / 40 := by norm_num [pluck]

-- The corner riding toward the nut sits at 104/3 cm at height 21/10 mm = 2.1 mm.
example : (pluck (104 / 3 - 13) + pluck (104 / 3 + 13)) / 2 = 21 / 10 := by norm_num [pluck]

-- Slopes 3 mm over 65/3 cm and 3 mm over 130/3 cm: 180/13 and -90/13 mm per m;
-- the jump 270/13 mm per m splits into two jumps of 135/13 mm per m.
example : (3 : ℚ) / (65 / 300) = 180 / 13 ∧ -(3 : ℚ) / (130 / 300) = -90 / 13 := by norm_num
example : ((180 : ℚ) / 13 - (-90 / 13)) / 2 = 135 / 13 := by norm_num

-- Signals at the 12th fret: w = -143 × 180/13 = -1980 mm/s, v = 143 × (-90/13) = -990 mm/s,
-- so u_t = (v + w)/2 = -1485 mm/s and u_x = (v - w)/(2c) = 45/13 mm per m.
example : -(143 : ℚ) * (180 / 13) = -1980 ∧ (143 : ℚ) * (-90 / 13) = -990 := by norm_num
example : ((-990 : ℚ) + -1980) / 2 = -1485 ∧ ((-990 : ℚ) - -1980) / (2 * 143) = 45 / 13 := by
  norm_num

#print axioms wave_signals_ride_characteristics
#print axioms dalembert_formula_unique_classical_solution
#print axioms corner_splits_into_two_half_corners
