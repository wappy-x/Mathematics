-- Maxwell's equations: for smooth fields the flux of a curl out of any point is zero, so Ampère's old loop law forbids charge from ever piling up, while Gauss's law and charge conservation make the current plus Maxwell's displacement term have zero outflow everywhere.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.ContDiff.Comp

/-! Space is `Fin 3 → ℝ`, a point `x = (x 0, x 1, x 2)`. A vector field is a map
`(Fin 3 → ℝ) → (Fin 3 → ℝ)`. A field that also changes in time is a map
`ℝ → (Fin 3 → ℝ) → (Fin 3 → ℝ)`: its value at time `t` and point `x` is `E t x`. -/

/-- The partial derivative `∂f/∂xᵢ` at `x`: the rate of change of `f` along axis `i`. -/
noncomputable def partialAt (f : (Fin 3 → ℝ) → ℝ) (i : Fin 3) (x : Fin 3 → ℝ) : ℝ :=
  fderiv ℝ f x (Pi.single i 1)

/-- The divergence `div F = ∂F₁/∂x + ∂F₂/∂y + ∂F₃/∂z`: outflow per volume at `x`. -/
noncomputable def divergence (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x : Fin 3 → ℝ) : ℝ :=
  partialAt (fun y => F y 0) 0 x + partialAt (fun y => F y 1) 1 x + partialAt (fun y => F y 2) 2 x

/-- The curl `curl F = (∂F₃/∂y − ∂F₂/∂z, ∂F₁/∂z − ∂F₃/∂x, ∂F₂/∂x − ∂F₁/∂y)`: spin per area at `x`. -/
noncomputable def curl (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x : Fin 3 → ℝ) : Fin 3 → ℝ :=
  ![partialAt (fun y => F y 2) 1 x - partialAt (fun y => F y 1) 2 x,
    partialAt (fun y => F y 0) 2 x - partialAt (fun y => F y 2) 0 x,
    partialAt (fun y => F y 1) 0 x - partialAt (fun y => F y 0) 1 x]

/-- The rate of change `∂E/∂t` of a field at a fixed point `x`, at time `t`. -/
noncomputable def timeRate (E : ℝ → (Fin 3 → ℝ) → (Fin 3 → ℝ)) (t : ℝ) (x : Fin 3 → ℝ) :
    Fin 3 → ℝ :=
  deriv (fun s => E s x) t

/-- The rate of change `∂ρ/∂t` of a density at a fixed point `x`, at time `t`. -/
noncomputable def densityRate (ρ : ℝ → (Fin 3 → ℝ) → ℝ) (t : ℝ) (x : Fin 3 → ℝ) : ℝ :=
  deriv (fun s => ρ s x) t

/-- Applying a derivative-valued map to a fixed vector commutes with differentiation. -/
lemma fderiv_apply_const_vec {Z A : Type*} [NormedAddCommGroup Z] [NormedSpace ℝ Z]
    [NormedAddCommGroup A] [NormedSpace ℝ A]
    (Φ : Z → (A →L[ℝ] (Fin 3 → ℝ))) (z : Z) (hΦ : DifferentiableAt ℝ Φ z) (w : A) (v : Z)
    (k : Fin 3) :
    fderiv ℝ (fun z => Φ z w k) z v = fderiv ℝ Φ z v w k := by
  have h1 : DifferentiableAt ℝ (fun z => Φ z w) z := hΦ.clm_apply (differentiableAt_const w)
  rw [fderiv_apply h1 k, fderiv_clm_apply hΦ (differentiableAt_const w)]
  simp

/-- A partial derivative of a component is that component of the full derivative. -/
lemma partialAt_component (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x : Fin 3 → ℝ)
    (hF : DifferentiableAt ℝ F x) (k j : Fin 3) :
    partialAt (fun y => F y k) j x = fderiv ℝ F x (Pi.single j 1) k := by
  unfold partialAt
  rw [fderiv_apply hF k]
  simp

lemma partialAt_sub (a b : (Fin 3 → ℝ) → ℝ) (i : Fin 3) (x : Fin 3 → ℝ)
    (ha : DifferentiableAt ℝ a x) (hb : DifferentiableAt ℝ b x) :
    partialAt (fun y => a y - b y) i x = partialAt a i x - partialAt b i x := by
  unfold partialAt
  rw [fderiv_fun_sub ha hb]
  simp

lemma partialAt_add (a b : (Fin 3 → ℝ) → ℝ) (i : Fin 3) (x : Fin 3 → ℝ)
    (ha : DifferentiableAt ℝ a x) (hb : DifferentiableAt ℝ b x) :
    partialAt (fun y => a y + b y) i x = partialAt a i x + partialAt b i x := by
  unfold partialAt
  rw [fderiv_fun_add ha hb]
  simp

lemma partialAt_const_mul (c : ℝ) (a : (Fin 3 → ℝ) → ℝ) (i : Fin 3) (x : Fin 3 → ℝ)
    (ha : DifferentiableAt ℝ a x) :
    partialAt (fun y => c * a y) i x = c * partialAt a i x := by
  unfold partialAt
  rw [fderiv_const_mul ha]
  simp

/-- For a `C²` field, a partial derivative of a component is differentiable. -/
lemma partialAt_component_differentiable (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (hF : ContDiff ℝ 2 F)
    (k j : Fin 3) : Differentiable ℝ (fun y => partialAt (fun z => F z k) j y) := by
  have hF1 : Differentiable ℝ F := hF.differentiable (by norm_num)
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have : (fun y => partialAt (fun z => F z k) j y) = fun y => fderiv ℝ F y (Pi.single j 1) k := by
    funext y; exact partialAt_component F y (hF1 y) k j
  rw [this]
  intro y
  exact differentiableAt_pi.1 ((hd y).clm_apply (differentiableAt_const _)) k

/-- For a `C²` field, the second partial derivative is the second derivative on two axes. -/
lemma second_partialAt (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (hF : ContDiff ℝ 2 F)
    (k i j : Fin 3) (x : Fin 3 → ℝ) :
    partialAt (fun y => partialAt (fun z => F z k) j y) i x =
      fderiv ℝ (fderiv ℝ F) x (Pi.single i 1) (Pi.single j 1) k := by
  have hF1 : Differentiable ℝ F := hF.differentiable (by norm_num)
  have hd : Differentiable ℝ (fderiv ℝ F) :=
    (hF.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have : (fun y => partialAt (fun z => F z k) j y) = fun y => fderiv ℝ F y (Pi.single j 1) k := by
    funext y; exact partialAt_component F y (hF1 y) k j
  rw [this]
  unfold partialAt
  exact fderiv_apply_const_vec (fderiv ℝ F) x (hd x) _ _ k

lemma curl_component_differentiable (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (hF : ContDiff ℝ 2 F)
    (k : Fin 3) : Differentiable ℝ (fun y => curl F y k) := by
  have P := partialAt_component_differentiable F hF
  fin_cases k <;> simp [curl] <;> exact (P _ _).sub (P _ _)

/-- Freezing time: the space derivative of a field of time and space. -/
lemma fderiv_slice_space {Y : Type*} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (V : ℝ × (Fin 3 → ℝ) → Y) (t : ℝ) (y : Fin 3 → ℝ) (hV : DifferentiableAt ℝ V (t, y))
    (v : Fin 3 → ℝ) : fderiv ℝ (fun y => V (t, y)) y v = fderiv ℝ V (t, y) (0, v) := by
  have h : HasFDerivAt (fun y : Fin 3 → ℝ => (t, y))
      ((0 : (Fin 3 → ℝ) →L[ℝ] ℝ).prod (ContinuousLinearMap.id ℝ (Fin 3 → ℝ))) y :=
    (hasFDerivAt_const t y).prodMk (hasFDerivAt_id y)
  have h2 : HasFDerivAt (fun y => V (t, y)) _ y := hV.hasFDerivAt.comp y h
  rw [h2.fderiv]
  simp

lemma differentiableAt_slice_space {Y : Type*} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (V : ℝ × (Fin 3 → ℝ) → Y) (t : ℝ) (y : Fin 3 → ℝ) (hV : DifferentiableAt ℝ V (t, y)) :
    DifferentiableAt ℝ (fun y => V (t, y)) y := by
  have h : HasFDerivAt (fun y : Fin 3 → ℝ => (t, y))
      ((0 : (Fin 3 → ℝ) →L[ℝ] ℝ).prod (ContinuousLinearMap.id ℝ (Fin 3 → ℝ))) y :=
    (hasFDerivAt_const t y).prodMk (hasFDerivAt_id y)
  exact (hV.hasFDerivAt.comp y h).differentiableAt

/-- Freezing the point: the time derivative of a field of time and space. -/
lemma hasDerivAt_slice_time {Y : Type*} [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (V : ℝ × (Fin 3 → ℝ) → Y) (t : ℝ) (y : Fin 3 → ℝ) (hV : DifferentiableAt ℝ V (t, y)) :
    HasDerivAt (fun s => V (s, y)) (fderiv ℝ V (t, y) (1, 0)) t := by
  have h : HasDerivAt (fun s : ℝ => (s, y)) ((1 : ℝ), (0 : Fin 3 → ℝ)) t :=
    (hasDerivAt_id t).prodMk (hasDerivAt_const t y)
  exact hV.hasFDerivAt.comp_hasDerivAt t h

#print axioms fderiv_apply_const_vec
#print axioms partialAt_component
#print axioms partialAt_sub
#print axioms partialAt_add
#print axioms partialAt_const_mul
#print axioms partialAt_component_differentiable
#print axioms second_partialAt
#print axioms curl_component_differentiable
#print axioms fderiv_slice_space
#print axioms differentiableAt_slice_space
#print axioms hasDerivAt_slice_time

/-- Maxwell's repair (Step 4). Take an electric field `E` that is smooth in time and space
(twice continuously differentiable), a current density `J` that is differentiable in space, a
charge density `ρ`, and the vacuum constant `ε₀ > 0`. If Gauss's law `div E = ρ/ε₀` holds and
charge is conserved, `div J = −∂ρ/∂t`, at every time and point, then the current plus the
displacement current density, `J + ε₀ ∂E/∂t`, has zero divergence at every time and point:
it never has net outflow, which is what the right side of the curl law for `B` needs. -/
theorem current_plus_displacement_current_has_zero_divergence
    (ε₀ : ℝ) (hε₀ : 0 < ε₀)
    (E J : ℝ → (Fin 3 → ℝ) → (Fin 3 → ℝ)) (ρ : ℝ → (Fin 3 → ℝ) → ℝ)
    (hE : ContDiff ℝ 2 (Function.uncurry E)) (hJ : ∀ t, Differentiable ℝ (J t))
    (gauss : ∀ t x, divergence (E t) x = ρ t x / ε₀)
    (conservation : ∀ t x, divergence (J t) x = -densityRate ρ t x) :
    ∀ t x, divergence (fun y => J t y + ε₀ • timeRate E t y) x = 0 := by
  intro t x
  set U := Function.uncurry E with hUdef
  have hU1 : Differentiable ℝ U := hE.differentiable (by norm_num)
  have hdU : Differentiable ℝ (fderiv ℝ U) :=
    (hE.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  have hs := (hE.contDiffAt (x := (t, x))).isSymmSndFDerivAt (by simp)
  -- the component maps `p ↦ (DU p w) k` are differentiable
  have hcomp : ∀ (w : ℝ × (Fin 3 → ℝ)) (k : Fin 3) p,
      DifferentiableAt ℝ (fun p => fderiv ℝ U p w k) p := fun w k p =>
    differentiableAt_pi.1 ((hdU p).clm_apply (differentiableAt_const w)) k
  -- space derivatives of `E s`
  have hEs : ∀ s y, DifferentiableAt ℝ (E s) y := fun s y =>
    differentiableAt_slice_space U s y (hU1 _)
  have hEsD : ∀ s y v, fderiv ℝ (E s) y v = fderiv ℝ U (s, y) (0, v) := fun s y v =>
    fderiv_slice_space U s y (hU1 _) v
  -- the time rate in terms of `DU`
  have hTR : ∀ y, timeRate E t y = fderiv ℝ U (t, y) (1, 0) := fun y =>
    (hasDerivAt_slice_time U t y (hU1 _)).deriv
  -- the charge density in terms of `DU`
  have hρ : (fun s => ρ s x) = fun s => ε₀ * (fderiv ℝ U (s, x) (0, Pi.single 0 1) 0 +
      fderiv ℝ U (s, x) (0, Pi.single 1 1) 1 + fderiv ℝ U (s, x) (0, Pi.single 2 1) 2) := by
    funext s
    have g := gauss s x
    unfold divergence at g
    rw [partialAt_component _ _ (hEs s x), partialAt_component _ _ (hEs s x),
      partialAt_component _ _ (hEs s x), hEsD, hEsD, hEsD] at g
    rw [g]
    field_simp
  have hd : ∀ k : Fin 3, HasDerivAt (fun s => fderiv ℝ U (s, x) (0, Pi.single k 1) k)
      (fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (0, Pi.single k 1) k) t := by
    intro k
    have := hasDerivAt_slice_time (fun p => fderiv ℝ U p (0, Pi.single k 1) k) t x
      (hcomp _ _ _)
    rwa [fderiv_apply_const_vec (fderiv ℝ U) (t, x) (hdU _)] at this
  have hrate : densityRate ρ t x = ε₀ * (fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (0, Pi.single 0 1) 0 +
      fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (0, Pi.single 1 1) 1 +
      fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (0, Pi.single 2 1) 2) := by
    unfold densityRate
    rw [hρ]
    exact ((((hd 0).add (hd 1)).add (hd 2)).const_mul ε₀).deriv
  -- each component of the sum field
  have hG : ∀ k : Fin 3, (fun y => (J t y + ε₀ • timeRate E t y) k) =
      fun y => J t y k + ε₀ * fderiv ℝ U (t, y) (1, 0) k := by
    intro k; funext y; simp [hTR]
  have hTd : ∀ k : Fin 3, DifferentiableAt ℝ (fun y => fderiv ℝ U (t, y) (1, 0) k) x := fun k =>
    differentiableAt_slice_space (fun p => fderiv ℝ U p (1, 0) k) t x (hcomp _ _ _)
  have hTp : ∀ k : Fin 3, partialAt (fun y => fderiv ℝ U (t, y) (1, 0) k) k x =
      fderiv ℝ (fderiv ℝ U) (t, x) (1, 0) (0, Pi.single k 1) k := by
    intro k
    unfold partialAt
    rw [fderiv_slice_space (fun p => fderiv ℝ U p (1, 0) k) t x (hcomp _ _ _),
      fderiv_apply_const_vec (fderiv ℝ U) (t, x) (hdU _), hs]
  have hJd : ∀ k : Fin 3, DifferentiableAt ℝ (fun y => J t y k) x := fun k =>
    differentiableAt_pi.1 (hJ t x) k
  have hc := conservation t x
  unfold divergence at hc ⊢
  rw [hG 0, hG 1, hG 2,
    partialAt_add _ _ _ _ (hJd 0) ((hTd 0).const_mul ε₀),
    partialAt_add _ _ _ _ (hJd 1) ((hTd 1).const_mul ε₀),
    partialAt_add _ _ _ _ (hJd 2) ((hTd 2).const_mul ε₀),
    partialAt_const_mul _ _ _ _ (hTd 0), partialAt_const_mul _ _ _ _ (hTd 1),
    partialAt_const_mul _ _ _ _ (hTd 2), hTp, hTp, hTp]
  rw [hrate] at hc
  linarith

/-- Step 0, at a point: for any twice continuously differentiable field `F`, the divergence of
its curl is zero everywhere, because each mixed second derivative appears twice with opposite
signs. -/
theorem divergence_curl_eq_zero (F : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (hF : ContDiff ℝ 2 F) :
    ∀ x, divergence (curl F) x = 0 := by
  intro x
  have P := partialAt_component_differentiable F hF
  have S := second_partialAt F hF
  have hs := (hF.contDiffAt (x := x)).isSymmSndFDerivAt (by simp)
  have e0 : (fun y => curl F y 0) =
      fun y => partialAt (fun z => F z 2) 1 y - partialAt (fun z => F z 1) 2 y := by
    funext y; simp [curl]
  have e1 : (fun y => curl F y 1) =
      fun y => partialAt (fun z => F z 0) 2 y - partialAt (fun z => F z 2) 0 y := by
    funext y; simp [curl]
  have e2 : (fun y => curl F y 2) =
      fun y => partialAt (fun z => F z 1) 0 y - partialAt (fun z => F z 0) 1 y := by
    funext y; simp [curl]
  unfold divergence
  rw [e0, e1, e2, partialAt_sub _ _ _ _ (P _ _ _) (P _ _ _),
    partialAt_sub _ _ _ _ (P _ _ _) (P _ _ _), partialAt_sub _ _ _ _ (P _ _ _) (P _ _ _),
    S, S, S, S, S, S, hs (Pi.single 1 1) (Pi.single 0 1), hs (Pi.single 2 1) (Pi.single 0 1),
    hs (Pi.single 2 1) (Pi.single 1 1)]
  ring

/-- Step 3, the old law contradicts itself. Take a magnetic field `B` that is twice continuously
differentiable in space at every time, a current density `J`, a charge density `ρ`, and the
constant `μ₀ > 0`. If Ampère's law without Maxwell's term, `curl B = μ₀ J`, held at every time
and point, and charge is conserved, `div J = −∂ρ/∂t`, then `∂ρ/∂t = 0` everywhere: charge could
never pile up anywhere, so the old law cannot describe a charging capacitor. -/
theorem old_ampere_law_forbids_charge_piling_up
    (μ₀ : ℝ) (hμ₀ : 0 < μ₀)
    (B J : ℝ → (Fin 3 → ℝ) → (Fin 3 → ℝ)) (ρ : ℝ → (Fin 3 → ℝ) → ℝ)
    (hB : ∀ t, ContDiff ℝ 2 (B t))
    (ampere : ∀ t x, curl (B t) x = μ₀ • J t x)
    (conservation : ∀ t x, divergence (J t) x = -densityRate ρ t x) :
    ∀ t x, densityRate ρ t x = 0 := by
  intro t x
  have hJ : ∀ k, (fun y => J t y k) = fun y => μ₀⁻¹ * curl (B t) y k := by
    intro k; funext y
    rw [ampere t y]
    simp [smul_eq_mul, hμ₀.ne']
  have D := curl_component_differentiable (B t) (hB t)
  have h0 := divergence_curl_eq_zero (B t) (hB t) x
  have hdiv : divergence (J t) x = μ₀⁻¹ * divergence (curl (B t)) x := by
    unfold divergence
    rw [hJ 0, hJ 1, hJ 2, partialAt_const_mul _ _ _ _ (D 0 x),
      partialAt_const_mul _ _ _ _ (D 1 x), partialAt_const_mul _ _ _ _ (D 2 x)]
    ring
  have := conservation t x
  rw [hdiv, h0] at this
  linarith

-- Worked numbers, in exact fractions (lengths in m, currents in A, times in s).
-- Plate radius 5 cm against a 1 mm gap: the plate is 50 gaps wide in radius.
example : ((5 : ℚ) / 100) / (1 / 1000) = 50 := by norm_num
-- Charge after 1 µs at 10 mA: 10 nC.
example : ((10 : ℚ) / 1000) * (1 / 1000000) = 10 / 1000000000 := by norm_num
-- Share of the 10 mA displacement current inside 2.5 cm of a 5 cm plate: 2.5 mA.
example : (10 : ℚ) * ((25 / 10) / 5) ^ 2 = 25 / 10 := by norm_num
-- Wire formula inside the gap at 2.5 cm counts all 10 mA, not 2.5 mA: four times too big (80 against 20 nT).
example : (10 : ℚ) / (25 / 10) = 4 ∧ (20 : ℚ) * 4 = 80 := by norm_num
-- Gap formula past the rim at 8 cm overshoots by (8/5)²: 64 against 25 nT.
example : ((8 : ℚ) / 5) ^ 2 = 64 / 25 := by norm_num

#print axioms current_plus_displacement_current_has_zero_divergence
#print axioms divergence_curl_eq_zero
#print axioms old_ampere_law_forbids_charge_piling_up
