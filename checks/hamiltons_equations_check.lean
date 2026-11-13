-- Hamilton's equations: for a twice-smooth Lagrangian that curves upward in the velocity, every motion obeying Lagrange's equation obeys q' = ∂H/∂p and p' = -∂H/∂q for its Legendre transform H and keeps H constant; for the swing H = p²/(2ml²) - mgl cos θ, and an Euler step stretches area by 1 + h²(g/l) cos θ while a leapfrog step keeps it.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Topology.Algebra.Module.Determinant
import Mathlib.Data.Real.Archimedean
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.FDeriv
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.LinearAlgebra.Basis.Fin
import Mathlib.LinearAlgebra.Determinant
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Real

noncomputable section

/-- The Legendre transform of a Lagrangian `L q v` (position `q`, velocity `v`): the Hamiltonian
`H q p = max over v of (p v - L q v)`, written as the least upper bound over every velocity. -/
def legendre (L : ℝ → ℝ → ℝ) (q p : ℝ) : ℝ :=
  ⨆ v : ℝ, p * v - L q v

lemma ham_tangent_le (f : ℝ → ℝ) (hconv : ∀ v, 0 < deriv (fun w => deriv f w) v)
    (hd : Differentiable ℝ f) (v w : ℝ) :
    deriv f v * w - f w ≤ deriv f v * v - f v := by
  have hmono : StrictMono (deriv f) := strictMono_of_deriv_pos hconv
  rcases lt_trichotomy w v with hwv | hwv | hwv
  · obtain ⟨c, hc, hcs⟩ := exists_deriv_eq_slope f hwv hd.continuous.continuousOn
      (fun y _ => (hd y).differentiableWithinAt)
    have h1 : deriv f c < deriv f v := hmono hc.2
    have h2 : f v - f w = deriv f c * (v - w) := by
      rw [hcs]; field_simp [(sub_pos.2 hwv).ne']
    nlinarith [sub_pos.2 hwv]
  · rw [hwv]
  · obtain ⟨c, hc, hcs⟩ := exists_deriv_eq_slope f hwv hd.continuous.continuousOn
      (fun y _ => (hd y).differentiableWithinAt)
    have h1 : deriv f v < deriv f c := hmono hc.1
    have h2 : f w - f v = deriv f c * (w - v) := by
      rw [hcs]; field_simp [(sub_pos.2 hwv).ne']
    nlinarith [sub_pos.2 hwv]

#print axioms ham_tangent_le

lemma ham_legendre_eq (L : ℝ → ℝ → ℝ) (hd : ∀ q, Differentiable ℝ (fun u => L q u))
    (hconv : ∀ q v, 0 < deriv (fun w => deriv (fun u => L q u) w) v) (q v : ℝ) :
    legendre L q (deriv (fun u => L q u) v) = deriv (fun u => L q u) v * v - L q v := by
  have h := fun w => ham_tangent_le (fun u => L q u) (hconv q) (hd q) v w
  unfold legendre
  apply le_antisymm
  · exact ciSup_le h
  · exact le_ciSup_of_le ⟨_, Set.forall_mem_range.2 h⟩ v le_rfl

#print axioms ham_legendre_eq

lemma ham_clm_apply (ℓ : ℝ × ℝ →L[ℝ] ℝ) (a b : ℝ) :
    ℓ (a, b) = a * ℓ (1, 0) + b * ℓ (0, 1) := by
  have : ((a, b) : ℝ × ℝ) = a • ((1 : ℝ), (0 : ℝ)) + b • ((0 : ℝ), (1 : ℝ)) := by simp
  rw [this, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]

#print axioms ham_clm_apply

lemma ham_det_eq (f : ℝ × ℝ →L[ℝ] ℝ × ℝ) :
    f.det = (f (1, 0)).1 * (f (0, 1)).2 - (f (0, 1)).1 * (f (1, 0)).2 := by
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix (Module.Basis.finTwoProd ℝ),
    Matrix.det_fin_two]
  simp [LinearMap.toMatrix_apply]

#print axioms ham_det_eq

/-- Hamilton's equations and the conservation of the Hamiltonian (Steps 2 to 4 and the detailed
proof). Take a Lagrangian `L q v` with no clock in it, twice continuously differentiable in
position and velocity together, that curves upward in the velocity (its second slope in `v` is
positive everywhere). Let `x` be a twice continuously differentiable motion that obeys Lagrange's
equation: the rate of the momentum `p = ∂L/∂v (x, x')` equals `∂L/∂q (x, x')`. Let `H` be the
Legendre transform of `L`. Then at every time `t`:
* `H (x t) (p t) = p t * x' t - L (x t) (x' t)` (momentum times velocity minus the Lagrangian);
* the position changes at the slope of `H` in the momentum: `∂H/∂p = x'`;
* the momentum changes at minus the slope of `H` in the position: `∂H/∂q = -p'`;
* `H` stays constant along the motion: `H (x t) (p t) = H (x 0) (p 0)`. -/
theorem hamiltons_equations_and_conservation (L : ℝ → ℝ → ℝ)
    (hL : ContDiff ℝ 2 (fun z : ℝ × ℝ => L z.1 z.2))
    (hconvex : ∀ q v, 0 < deriv (fun w => deriv (fun u => L q u) w) v)
    (x : ℝ → ℝ) (hx : ContDiff ℝ 2 x)
    (hlagrange : ∀ t, HasDerivAt (fun s => deriv (fun u => L (x s) u) (deriv x s))
      (deriv (fun y => L y (deriv x t)) (x t)) t) :
    let p : ℝ → ℝ := fun s => deriv (fun u => L (x s) u) (deriv x s)
    ∀ t : ℝ,
      legendre L (x t) (p t) = p t * deriv x t - L (x t) (deriv x t) ∧
      HasDerivAt (fun p' => legendre L (x t) p') (deriv x t) (p t) ∧
      HasDerivAt (fun q' => legendre L q' (p t)) (-deriv p t) (x t) ∧
      legendre L (x t) (p t) = legendre L (x 0) (p 0) := by
  intro p
  set Lz : ℝ × ℝ → ℝ := fun z => L z.1 z.2 with hLz
  have hLd : Differentiable ℝ Lz := hL.differentiable (by norm_num)
  have hv : ∀ q u, HasDerivAt (fun u => L q u) (fderiv ℝ Lz (q, u) (0, 1)) u := by
    intro q u
    have h1 : HasDerivAt (fun u : ℝ => (q, u)) ((0 : ℝ), (1 : ℝ)) u :=
      (hasDerivAt_const u q).prodMk (hasDerivAt_id u)
    exact (hLd (q, u)).hasFDerivAt.comp_hasDerivAt u h1
  have hq : ∀ q u, HasDerivAt (fun q => L q u) (fderiv ℝ Lz (q, u) (1, 0)) q := by
    intro q u
    have h1 : HasDerivAt (fun q : ℝ => (q, u)) ((1 : ℝ), (0 : ℝ)) q :=
      (hasDerivAt_id q).prodMk (hasDerivAt_const q u)
    exact (hLd (q, u)).hasFDerivAt.comp_hasDerivAt q h1
  set Φ : ℝ × ℝ → ℝ := fun z => fderiv ℝ Lz z (0, 1) with hΦdef
  have hΦ : ContDiff ℝ 1 Φ := (hL.fderiv_right (m := 1) (by norm_num)).clm_apply contDiff_const
  have hΦd : Differentiable ℝ Φ := hΦ.differentiable (by norm_num)
  have hDv : ∀ q, deriv (fun u => L q u) = fun u => Φ (q, u) :=
    fun q => funext fun u => (hv q u).deriv
  have hdiffL : ∀ q, Differentiable ℝ (fun u => L q u) := fun q u => (hv q u).differentiableAt
  -- Claim 1 at every time.
  have hE : ∀ s, legendre L (x s) (p s) = p s * deriv x s - L (x s) (deriv x s) :=
    fun s => ham_legendre_eq L hdiffL hconvex (x s) (deriv x s)
  intro t
  set q0 := x t with hq0
  set v0 := deriv x t with hv0
  set z0 : ℝ × ℝ := (q0, v0) with hz0
  have hp0 : p t = Φ z0 := by simp only [p, hDv]; rfl
  -- The map F (q, v) = (q, ∂L/∂v) and its invertible derivative.
  set DΦ := fderiv ℝ Φ z0 with hDΦ
  set c := DΦ (0, 1) with hc
  have hcpos : 0 < c := by
    have h1 : HasDerivAt (fun w => Φ (q0, w)) c v0 := by
      have h2 : HasDerivAt (fun w : ℝ => (q0, w)) ((0 : ℝ), (1 : ℝ)) v0 :=
        (hasDerivAt_const v0 q0).prodMk (hasDerivAt_id v0)
      exact (hΦd z0).hasFDerivAt.comp_hasDerivAt v0 h2
    have h3 := hconvex q0 v0
    rw [hDv] at h3
    rwa [h1.deriv] at h3
  have hlin : ∀ a b, DΦ (a, b) = DΦ (a, 0) + b * c := by
    intro a b
    have : ((a, b) : ℝ × ℝ) = (a, 0) + b • ((0 : ℝ), (1 : ℝ)) := by simp
    rw [this, map_add, map_smul, smul_eq_mul]
  let A : ℝ × ℝ →L[ℝ] ℝ × ℝ := (ContinuousLinearMap.fst ℝ ℝ ℝ).prod DΦ
  let B : ℝ × ℝ →L[ℝ] ℝ × ℝ := (ContinuousLinearMap.fst ℝ ℝ ℝ).prod
    (c⁻¹ • (ContinuousLinearMap.snd ℝ ℝ ℝ - DΦ.comp ((ContinuousLinearMap.inl ℝ ℝ ℝ).comp (ContinuousLinearMap.fst ℝ ℝ ℝ))))
  have hBA : Function.LeftInverse B A := by
    rintro ⟨a, b⟩
    simp [A, B]
    rw [hlin a b]
    congr 1
    field_simp
    ring
  have hAB : Function.RightInverse B A := by
    rintro ⟨a, b⟩
    simp [A, B]
    rw [hlin]
    congr 1
    field_simp
    ring
  let e : (ℝ × ℝ) ≃L[ℝ] (ℝ × ℝ) := ContinuousLinearEquiv.equivOfInverse A B hBA hAB
  set F : ℝ × ℝ → ℝ × ℝ := fun z => (z.1, Φ z) with hFdef
  have hFc : ContDiff ℝ 1 F := contDiff_fst.prodMk hΦ
  have hFA : HasFDerivAt F (e : ℝ × ℝ →L[ℝ] ℝ × ℝ) z0 :=
    (hasFDerivAt_fst (𝕜 := ℝ)).prodMk (hΦd z0).hasFDerivAt
  have hFs : HasStrictFDerivAt F (e : ℝ × ℝ →L[ℝ] ℝ × ℝ) z0 :=
    hFc.contDiffAt.hasStrictFDerivAt' hFA one_ne_zero
  set G := hFs.localInverse F e z0 with hGdef
  have hFz0 : F z0 = (q0, p t) := by rw [hp0]
  have hG : HasFDerivAt G (e.symm : ℝ × ℝ →L[ℝ] ℝ × ℝ) (F z0) :=
    hFs.to_localInverse.hasFDerivAt
  have hGz0 : G (F z0) = z0 := hFs.localInverse_apply_image
  -- K0 (q, v) = (∂L/∂v) v - L, so that H ∘ F = K0.
  set K0 : ℝ × ℝ → ℝ := fun z => Φ z * z.2 - Lz z with hK0def
  set K0' : ℝ × ℝ →L[ℝ] ℝ :=
    Φ z0 • ContinuousLinearMap.snd ℝ ℝ ℝ + z0.2 • DΦ - fderiv ℝ Lz z0 with hK0'def
  have hK0 : HasFDerivAt K0 K0' z0 :=
    ((hΦd z0).hasFDerivAt.mul (hasFDerivAt_snd (𝕜 := ℝ) (p := z0))).sub (hLd z0).hasFDerivAt
  have hKG : HasFDerivAt (K0 ∘ G) (K0'.comp (e.symm : ℝ × ℝ →L[ℝ] ℝ × ℝ)) (F z0) := by
    apply HasFDerivAt.comp
    · rw [hGz0]; exact hK0
    · exact hG
  rw [hFz0] at hKG
  have hev : (fun y : ℝ × ℝ => legendre L y.1 y.2) =ᶠ[nhds (q0, p t)] (K0 ∘ G) := by
    have := hFs.eventually_right_inverse
    rw [hFz0] at this
    filter_upwards [this] with y hy
    have h1 : y.1 = (G y).1 := by
      conv_lhs => rw [← hy]
    have h2 : y.2 = Φ (G y) := by
      conv_lhs => rw [← hy]
    rw [h1, h2, Function.comp_apply]
    have := ham_legendre_eq L hdiffL hconvex (G y).1 (G y).2
    rw [hDv] at this
    exact this
  have hH := hKG.congr_of_eventuallyEq hev
  -- The derivative of H at (q0, p0), on any vector w.
  have hval : ∀ w : ℝ × ℝ, (K0'.comp (e.symm : ℝ × ℝ →L[ℝ] ℝ × ℝ)) w
      = w.2 * v0 - w.1 * fderiv ℝ Lz z0 (1, 0) := by
    intro w
    have heu : e (e.symm w) = w := e.apply_symm_apply w
    have hu1 : (e.symm w).1 = w.1 := by
      conv_rhs => rw [← heu]
      rfl
    have hu2 : DΦ (e.symm w) = w.2 := by
      conv_rhs => rw [← heu]
      rfl
    have hcl := ham_clm_apply (fderiv ℝ Lz z0) (e.symm w).1 (e.symm w).2
    rw [Prod.mk.eta] at hcl
    have hLv : fderiv ℝ Lz z0 (0, 1) = Φ z0 := rfl
    rw [ContinuousLinearMap.comp_apply]
    simp only [hK0'def, ContinuousLinearMap.sub_apply, ContinuousLinearMap.add_apply,
      ContinuousLinearMap.smul_apply, ContinuousLinearMap.coe_snd', smul_eq_mul,
      ContinuousLinearEquiv.coe_coe]
    rw [hu2, hcl, hu1, hLv]
    ring
  have hderivp : deriv p t = fderiv ℝ Lz z0 (1, 0) := by
    show deriv (fun s => deriv (fun u => L (x s) u) (deriv x s)) t = _
    rw [(hlagrange t).deriv]
    exact (hq q0 v0).deriv
  have hH2 : HasDerivAt (fun p' => legendre L q0 p') v0 (p t) := by
    have h1 : HasDerivAt (fun p' : ℝ => (q0, p')) ((0 : ℝ), (1 : ℝ)) (p t) :=
      (hasDerivAt_const _ q0).prodMk (hasDerivAt_id _)
    have := hH.comp_hasDerivAt (p t) h1
    rw [hval] at this
    exact this.congr_deriv (by simp)
  have hH3 : HasDerivAt (fun q' => legendre L q' (p t)) (-deriv p t) q0 := by
    have h1 : HasDerivAt (fun q' : ℝ => (q', p t)) ((1 : ℝ), (0 : ℝ)) q0 :=
      (hasDerivAt_id _).prodMk (hasDerivAt_const _ (p t))
    have := hH.comp_hasDerivAt q0 h1
    rw [hval] at this
    rw [hderivp]
    exact this.congr_deriv (by simp)
  -- Conservation of H along the motion.
  have hx1 : ContDiff ℝ 1 (deriv x) :=
    ((contDiff_succ_iff_deriv (n := 1)).1 (by rw [one_add_one_eq_two]; exact hx)).2.2
  have hxd : Differentiable ℝ x := hx.differentiable (by norm_num)
  have hx'd : Differentiable ℝ (deriv x) := hx1.differentiable (by norm_num)
  have hEd : ∀ s, HasDerivAt (fun s => p s * deriv x s - L (x s) (deriv x s)) 0 s := by
    intro s
    have hp' := hlagrange s
    rw [(hq (x s) (deriv x s)).deriv] at hp'
    have hpath : HasDerivAt (fun s => (x s, deriv x s)) (deriv x s, deriv (deriv x) s) s :=
      (hxd s).hasDerivAt.prodMk (hx'd s).hasDerivAt
    have hLs := (hLd (x s, deriv x s)).hasFDerivAt.comp_hasDerivAt s hpath
    have key := (hp'.mul (hx'd s).hasDerivAt).sub hLs
    refine key.congr_deriv ?_
    rw [ham_clm_apply (fderiv ℝ Lz (x s, deriv x s)) (deriv x s) (deriv (deriv x) s)]
    have hps : deriv (fun u => L (x s) u) (deriv x s) = fderiv ℝ Lz (x s, deriv x s) (0, 1) := by
      rw [hDv]
    rw [hps]
    ring
  have hconst := is_const_of_deriv_eq_zero
    (f := fun s => p s * deriv x s - L (x s) (deriv x s))
    (fun s => (hEd s).differentiableAt) (fun s => (hEd s).deriv) t 0
  refine ⟨hE t, hH2, hH3, ?_⟩
  rw [hE t, hE 0]
  exact hconst


/-- The swing (The formula). For mass `m > 0` and rod length `l > 0` under any gravity `g`, the
Lagrangian `L = ½ m l² θ'² + m g l cos θ` has Legendre transform
`H θ p = p² / (2 m l²) - m g l cos θ`, and Hamilton's equations read
`θ' = ∂H/∂p = p / (m l²)` and `p' = -∂H/∂θ = -m g l sin θ`. -/
theorem swing_hamiltonian (m l g : ℝ) (hm : 0 < m) (hl : 0 < l) (θ p : ℝ) :
    legendre (fun q v => 1 / 2 * m * l ^ 2 * v ^ 2 + m * g * l * cos q) θ p
        = p ^ 2 / (2 * m * l ^ 2) - m * g * l * cos θ ∧
      HasDerivAt (fun p' => p' ^ 2 / (2 * m * l ^ 2) - m * g * l * cos θ)
        (p / (m * l ^ 2)) p ∧
      HasDerivAt (fun θ' => p ^ 2 / (2 * m * l ^ 2) - m * g * l * cos θ')
        (m * g * l * sin θ) θ := by
  have ha : 0 < m * l ^ 2 := by positivity
  have hb : ∀ v, p * v - (1 / 2 * m * l ^ 2 * v ^ 2 + m * g * l * cos θ)
      ≤ p ^ 2 / (2 * m * l ^ 2) - m * g * l * cos θ := by
    intro v
    rw [← sub_nonneg]
    have : p ^ 2 / (2 * m * l ^ 2) - m * g * l * cos θ
        - (p * v - (1 / 2 * m * l ^ 2 * v ^ 2 + m * g * l * cos θ))
        = (p - m * l ^ 2 * v) ^ 2 / (2 * (m * l ^ 2)) := by
      field_simp; ring
    rw [this]; positivity
  refine ⟨?_, ?_, ?_⟩
  · unfold legendre
    apply le_antisymm
    · exact ciSup_le hb
    · refine le_ciSup_of_le ⟨_, Set.forall_mem_range.2 hb⟩ (p / (m * l ^ 2)) (le_of_eq ?_)
      field_simp; ring
  · have := ((hasDerivAt_pow 2 p).div_const (2 * m * l ^ 2)).sub_const (m * g * l * cos θ)
    convert this using 1
    field_simp; ring
  · have := ((hasDerivAt_cos θ).const_mul (m * g * l)).const_sub (p ^ 2 / (2 * m * l ^ 2))
    convert this using 1
    ring


/-- One Euler step of size `h` for the swing on the state `(θ, p)`: a straight step along the
current rates, `θ + h p / (m l²)` and `p - h m g l sin θ`. -/
def swingEuler (m l g h : ℝ) (z : ℝ × ℝ) : ℝ × ℝ :=
  (z.1 + h * z.2 / (m * l ^ 2), z.2 - h * (m * g * l) * sin z.1)

/-- One leapfrog step of size `h` for the swing: half a kick to `p`, a drift of `θ` at the new
momentum, then the second half kick felt at the new angle. -/
def swingLeapfrog (m l g h : ℝ) (z : ℝ × ℝ) : ℝ × ℝ :=
  let p₁ := z.2 - h / 2 * (m * g * l) * sin z.1
  let θ₁ := z.1 + h * p₁ / (m * l ^ 2)
  (θ₁, p₁ - h / 2 * (m * g * l) * sin θ₁)

/-- Step 6, area in the angle–momentum plane. For a swing with `m ≠ 0` and `l ≠ 0`, at every
state `(θ, p)` and every step size `h`, one Euler step stretches area by the factor
`1 + h² (g / l) cos θ` (the determinant of its Jacobian), while one leapfrog step keeps area
exactly (factor 1). -/
theorem swing_step_area_factors (m l g h : ℝ) (hm : m ≠ 0) (hl : l ≠ 0) (z : ℝ × ℝ) :
    (fderiv ℝ (swingEuler m l g h) z).det = 1 + h ^ 2 * (g / l) * cos z.1 ∧
      (fderiv ℝ (swingLeapfrog m l g h) z).det = 1 := by
  have hf : HasFDerivAt (fun z : ℝ × ℝ => z.1) (ContinuousLinearMap.fst ℝ ℝ ℝ) z :=
    hasFDerivAt_fst
  have hs : HasFDerivAt (fun z : ℝ × ℝ => z.2) (ContinuousLinearMap.snd ℝ ℝ ℝ) z :=
    hasFDerivAt_snd
  constructor
  · have hfun : swingEuler m l g h = fun z : ℝ × ℝ =>
        (z.1 + h / (m * l ^ 2) * z.2, z.2 - h * (m * g * l) * sin z.1) := by
      funext z; simp only [swingEuler]; congr 1; ring
    have h1 := hf.add (hs.const_mul (h / (m * l ^ 2)))
    have h2 := hs.sub (((hasDerivAt_sin z.1).comp_hasFDerivAt z hf).const_mul (h * (m * g * l)))
    have hE : HasFDerivAt (swingEuler m l g h) _ z := hfun ▸ h1.prodMk h2
    rw [hE.fderiv, ham_det_eq]
    simp
    field_simp
  · have hfun : swingLeapfrog m l g h = fun z : ℝ × ℝ =>
        (z.1 + h / (m * l ^ 2) * (z.2 - h / 2 * (m * g * l) * sin z.1),
          (z.2 - h / 2 * (m * g * l) * sin z.1) - h / 2 * (m * g * l) *
            sin (z.1 + h / (m * l ^ 2) * (z.2 - h / 2 * (m * g * l) * sin z.1))) := by
      funext z; simp only [swingLeapfrog]; congr 1 <;> ring_nf
    have hp1 := hs.sub (((hasDerivAt_sin z.1).comp_hasFDerivAt z hf).const_mul
      (h / 2 * (m * g * l)))
    have hθ1 := hf.add (hp1.const_mul (h / (m * l ^ 2)))
    have hp2 := hp1.sub
      (((hasDerivAt_sin _).comp_hasFDerivAt z hθ1).const_mul (h / 2 * (m * g * l)))
    have hE : HasFDerivAt (swingLeapfrog m l g h) _ z := hfun ▸ hθ1.prodMk hp2
    rw [hE.fderiv, ham_det_eq]
    simp
    ring


end

/-! Worked numbers from the card: m = 20 kg, l = 2 m, g = 9.81 = 981/100 m/s², written as exact
fractions. -/

-- m l² = 80 kg m², m g l = 392.4 = 1962/5 J, and 2 m l² = 160.
example : (20 : ℚ) * 2 ^ 2 = 80 ∧ (20 : ℚ) * (981 / 100) * 2 = 1962 / 5 ∧
    2 * (20 : ℚ) * 2 ^ 2 = 160 := by norm_num
-- H at release: 0/160 - 392.4 × cos(-60°) = -392.4 × 1/2 = -196.2 = -981/5 J.
example : (0 : ℚ) ^ 2 / 160 - 1962 / 5 * (1 / 2) = -981 / 5 := by norm_num
-- At the bottom H is still -196.2: p² = 160 × 196.2 = 31392, and 31392/160 - 392.4 = -196.2.
example : (160 : ℚ) * (981 / 5) = 31392 ∧ (31392 : ℚ) / 160 - 1962 / 5 = -981 / 5 := by norm_num
-- Over the top needs H above 392.4: p²/160 = 784.8, so p² = 125568, four times 31392.
example : (1962 / 5 : ℚ) + 1962 / 5 = 3924 / 5 ∧ (160 : ℚ) * (3924 / 5) = 125568 ∧
    (125568 : ℚ) = 4 * 31392 := by norm_num
-- Mistake 1: momentum m l θ' is half of m l² θ', so H = (p/2)²/160 - 392.4 = -343.35 J.
example : (31392 : ℚ) / 4 / 160 - 1962 / 5 = -6867 / 20 := by norm_num
-- Euler's area factor at the bottom, h = 0.05 s: 1 + 0.05² × (9.81/2) × 1 = 1.01226250.
example : (1 : ℚ) + (1 / 20) ^ 2 * ((981 / 100) / 2) * 1 = 101226250 / 100000000 := by norm_num
-- Shorter rods, l = 1 m: the factor rises to 1 + 0.05² × 9.81 = 1.02452500.
example : (1 : ℚ) + (1 / 20) ^ 2 * ((981 / 100) / 1) * 1 = 102452500 / 100000000 := by norm_num

#print axioms hamiltons_equations_and_conservation
#print axioms swing_hamiltonian
#print axioms swing_step_area_factors
