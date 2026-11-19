-- Green, divergence and curl theorems: Stokes on a smoothly bent cube of any dimension k + 1 in any space, and the two translations that turn d of a work form into the flux of the curl and d of a flux form into the divergence times volume.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.DivergenceTheorem

open MeasureTheory

/-- The curl of a field `v` on space at `x`, from its partial derivatives
`∂ⱼ vᵢ = fderiv ℝ v x (Pi.single j 1) i`:
`curl v = (∂_y v_z - ∂_z v_y, ∂_z v_x - ∂_x v_z, ∂_x v_y - ∂_y v_x)`. -/
noncomputable def curl (v : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x : Fin 3 → ℝ) : Fin 3 → ℝ :=
  ![fderiv ℝ v x (Pi.single 1 1) 2 - fderiv ℝ v x (Pi.single 2 1) 1,
    fderiv ℝ v x (Pi.single 2 1) 0 - fderiv ℝ v x (Pi.single 0 1) 2,
    fderiv ℝ v x (Pi.single 0 1) 1 - fderiv ℝ v x (Pi.single 1 1) 0]

/-- The divergence of a field `j` on space at `x`: `∂_x j_x + ∂_y j_y + ∂_z j_z`. -/
noncomputable def div (j : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x : Fin 3 → ℝ) : ℝ :=
  ∑ i : Fin 3, fderiv ℝ j x (Pi.single i 1) i

/-- Helper: the derivative of `y ↦ j y · c` in direction `d`, written in coordinates. -/
theorem fderiv_dotProduct_const_apply (j : (Fin 3 → ℝ) → (Fin 3 → ℝ)) (x c d : Fin 3 → ℝ)
    (hj : DifferentiableAt ℝ j x) :
    fderiv ℝ (fun y => j y ⬝ᵥ c) x d =
      ∑ i : Fin 3, (∑ m : Fin 3, d m * fderiv ℝ j x (Pi.single m 1) i) * c i := by
  let ℓ : (Fin 3 → ℝ) →L[ℝ] ℝ := ∑ i : Fin 3, c i • ContinuousLinearMap.proj i
  have hℓ : (fun y => j y ⬝ᵥ c) = ℓ ∘ j := by
    funext y; simp [ℓ, dotProduct, mul_comm]
  rw [hℓ, fderiv_comp x ℓ.differentiableAt hj, ContinuousLinearMap.fderiv]
  have hd : d = ∑ m : Fin 3, d m • (Pi.single m 1 : Fin 3 → ℝ) := by
    funext i; simp [Finset.sum_apply, Pi.single_apply]
  conv_lhs => rw [hd]
  simp [ℓ, map_smul, Fin.sum_univ_three]
  ring

#print axioms fderiv_dotProduct_const_apply

/-- **One statement, every degree** (Stokes on a cube bent into place, the version the card's
code follows). Take a box `[a, b]` in `ℝ^(k+1)`, with its standard orientation, and a smooth
chart `φ` that places it in `ℝ^m` as the region `M`: a path (`k = 0`), a flat region, a piece
of ground, or a solid. Let `ω` be a `k`-form on `ℝ^m` that is smooth on an open set holding all
of `M`, edge included. Then `dω` added over `M` equals `ω` added over the whole edge of `M`, each
face carrying the orientation `M` gives it: the face where coordinate `i` (counted from 0) is at
its top end gets the sign `(-1)^i`, and the face at its bottom end the opposite sign.
Choosing `k = 0` gives the gradient theorem, `k = 1` in the plane gives Green's theorem,
`k = 1` on a surface in space gives the curl theorem, and `k = 2` in space gives the
divergence theorem. -/
theorem stokes_integral_d_over_region_eq_integral_over_edge {m k : ℕ}
    (a b : Fin (k + 1) → ℝ) (hab : a ≤ b)
    (φ : (Fin (k + 1) → ℝ) → (Fin m → ℝ)) (V : Set (Fin (k + 1) → ℝ))
    (hV : IsOpen V) (hboxV : Set.Icc a b ⊆ V) (hφ : ContDiffOn ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) φ V)
    (ω : (Fin m → ℝ) → (Fin m → ℝ) [⋀^Fin k]→L[ℝ] ℝ) (U : Set (Fin m → ℝ))
    (hU : IsOpen U) (hMU : φ '' Set.Icc a b ⊆ U) (hω : ContDiffOn ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) ω U) :
    ∫ x in Set.Icc a b, extDeriv ω (φ x) (fun j => fderiv ℝ φ x (Pi.single j 1)) =
      ∑ i : Fin (k + 1), (-1 : ℝ) ^ (i : ℕ) *
        ((∫ y in Set.Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
            ω (φ (i.insertNth (b i) y))
              (fun j => fderiv ℝ φ (i.insertNth (b i) y) (Pi.single (i.succAbove j) 1))) -
          ∫ y in Set.Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
            ω (φ (i.insertNth (a i) y))
              (fun j => fderiv ℝ φ (i.insertNth (a i) y) (Pi.single (i.succAbove j) 1))) := by
  classical
  let e : Fin (k + 1) → (Fin (k + 1) → ℝ) := fun j => Pi.single j 1
  let W := V ∩ φ ⁻¹' U
  have hIW : Set.Icc a b ⊆ W := fun x hx => ⟨hboxV hx, hMU ⟨x, hx, rfl⟩⟩
  have h3 : (3 : WithTop ℕ∞) ≤ ((⊤ : ℕ∞) : WithTop ℕ∞) := WithTop.coe_le_coe.2 le_top
  have hφ3 : ∀ x ∈ V, ContDiffAt ℝ 3 φ x := fun x hx =>
    (hφ.contDiffAt (hV.mem_nhds hx)).of_le h3
  have hω3 : ∀ y ∈ U, ContDiffAt ℝ 3 ω y := fun y hy =>
    (hω.contDiffAt (hU.mem_nhds hy)).of_le h3
  have hdφ : ∀ x ∈ V, DifferentiableAt ℝ (fderiv ℝ φ) x := fun x hx =>
    ((hφ3 x hx).fderiv_right (m := 2) (by norm_num)).differentiableAt (by norm_num)
  have hdω : ∀ y ∈ U, DifferentiableAt ℝ (fderiv ℝ ω) y := fun y hy =>
    ((hω3 y hy).fderiv_right (m := 2) (by norm_num)).differentiableAt (by norm_num)
  let η : (Fin (k + 1) → ℝ) → (Fin (k + 1) → ℝ) [⋀^Fin k]→L[ℝ] ℝ :=
    fun x => (ω (φ x)).compContinuousLinearMap (fderiv ℝ φ x)
  have hη : ∀ x ∈ W, DifferentiableAt ℝ η x := fun x hx =>
    DifferentiableAt.continuousAlternatingMapCompContinuousLinearMap
      (((hω3 _ hx.2).differentiableAt (by norm_num)).comp x
        ((hφ3 x hx.1).differentiableAt (by norm_num))) (hdφ x hx.1)
  have hpull : ∀ x ∈ W, extDeriv η x =
      (extDeriv ω (φ x)).compContinuousLinearMap (fderiv ℝ φ x) := fun x hx =>
    extDeriv_pullback ((hω3 _ hx.2).differentiableAt (by norm_num)) (hφ3 x hx.1)
      (by simp [minSmoothness_of_isRCLikeNormedField]; norm_num)
  let g : Fin (k + 1) → (Fin (k + 1) → ℝ) → ℝ := fun i x =>
    (-1 : ℝ) ^ (i : ℕ) * η x (i.removeNth e)
  let g' : Fin (k + 1) → (Fin (k + 1) → ℝ) → (Fin (k + 1) → ℝ) →L[ℝ] ℝ := fun i x =>
    ((-1 : ℝ) ^ (i : ℕ)) • fderiv ℝ (fun y => η y (i.removeNth e)) x
  have hgd : ∀ i, ∀ x ∈ W, HasFDerivAt (g i) (g' i x) x := fun i x hx =>
    ((hη x hx).continuousAlternatingMap_apply
      (fun _ => differentiableAt_const _)).hasFDerivAt.const_mul _
  -- the integrand on the box
  let F : (Fin (k + 1) → ℝ) → ℝ := fun x =>
    extDeriv ω (φ x) (fun j => fderiv ℝ φ x (Pi.single j 1))
  have hFg : ∀ x ∈ Set.Icc a b, F x = ∑ i, g' i x (e i) := by
    intro x hx
    have h1 : F x = extDeriv η x e := by
      rw [hpull x (hIW hx)]; rfl
    rw [h1, extDeriv_apply (hη x (hIW hx))]
    simp [g']
  have hFc : ContinuousOn F (Set.Icc a b) := by
    intro x hx
    have hxW := hIW hx
    have hd1 : DifferentiableAt ℝ (fun y => extDeriv ω (φ y)) x := by
      have : DifferentiableAt ℝ (extDeriv ω) (φ x) := by
        have he : extDeriv ω = fun y =>
            ContinuousAlternatingMap.alternatizeUncurryFinCLM ℝ _ _ (fderiv ℝ ω y) := by
          funext y; rfl
        rw [he]
        exact ((ContinuousAlternatingMap.alternatizeUncurryFinCLM ℝ (Fin m → ℝ) ℝ
          (n := k)).differentiableAt).comp (φ x) (hdω _ hxW.2)
      exact this.comp x ((hφ3 x hxW.1).differentiableAt (by norm_num))
    exact (hd1.continuousAlternatingMap_apply (fun j => (hdφ x hxW.1).clm_apply
      (differentiableAt_const _))).continuousAt.continuousWithinAt
  have key := integral_divergence_of_hasFDerivAt_off_countable' a b hab g g' ∅
    Set.countable_empty
    (fun i x hx => (hgd i x (hIW hx)).continuousAt.continuousWithinAt)
    (fun x hx i => hgd i x
      (hIW ⟨fun l => (hx.1 l trivial).1.le, fun l => (hx.1 l trivial).2.le⟩))
    ((hFc.integrableOn_compact isCompact_Icc).congr_fun hFg measurableSet_Icc)
  have hL : ∫ x in Set.Icc a b, F x = ∫ x in Set.Icc a b, ∑ i, g' i x (e i) :=
    setIntegral_congr_fun measurableSet_Icc hFg
  refine hL.trans (key.trans ?_)
  refine Finset.sum_congr rfl fun i _ => ?_
  simp only [g, integral_const_mul, mul_sub]
  rfl

/-- **d of a work form is the flux form of the curl.** Let `ω` be the work form of a field `v`
on space, `ω = v₁ dx + v₂ dy + v₃ dz`, so `ω` fed an arrow `u` gives `v · u`. Where `v` is
differentiable, `dω` fed two arrows `a`, `b` gives `curl v · (a × b)`: the flux of the curl
through the small parallelogram they span. -/
theorem d_work_form_eq_flux_form_of_curl
    (v : (Fin 3 → ℝ) → (Fin 3 → ℝ))
    (ω : (Fin 3 → ℝ) → (Fin 3 → ℝ) [⋀^Fin 1]→L[ℝ] ℝ)
    (hω : ∀ x u, ω x ![u] = v x ⬝ᵥ u)
    (x : Fin 3 → ℝ) (hv : DifferentiableAt ℝ v x) (a b : Fin 3 → ℝ) :
    extDeriv ω x ![a, b] = curl v x ⬝ᵥ (crossProduct a b) := by
  have hω' : ∀ y (w : Fin 1 → Fin 3 → ℝ), ω y w = v y ⬝ᵥ w 0 := by
    intro y w
    have : w = ![w 0] := by funext i; fin_cases i; rfl
    rw [this, hω]; rfl
  let B : Fin 3 → (Fin 3 → ℝ) [⋀^Fin 1]→L[ℝ] ℝ := fun i =>
    ContinuousAlternatingMap.ofSubsingleton ℝ (Fin 3 → ℝ) ℝ (0 : Fin 1)
      (ContinuousLinearMap.proj i)
  have hωeq : ω = fun y => ∑ i : Fin 3, v y i • B i := by
    funext y; ext w
    simp [hω' y w, B, dotProduct]
  have hωd : DifferentiableAt ℝ ω x := by
    rw [hωeq]
    exact DifferentiableAt.fun_sum fun i _ => ((differentiableAt_pi.1 hv) i).smul_const _
  rw [extDeriv_apply hωd]
  simp [Fin.sum_univ_two, hω', Fin.removeNth]
  rw [fderiv_dotProduct_const_apply v x b a hv, fderiv_dotProduct_const_apply v x a b hv]
  simp [curl, Fin.sum_univ_three, cross_apply, dotProduct]
  ring

/-- **d of a flux form is the divergence times volume.** Let `Φ` be the flux form of a field
`j` on space, `Φ = j₁ dy∧dz + j₂ dz∧dx + j₃ dx∧dy`, so `Φ` fed two arrows `a`, `b` gives
`j · (a × b)`. Where `j` is differentiable, `dΦ` fed three arrows `a`, `b`, `c` gives
`div j` times the signed volume `det [a; b; c]` of the box they span, that is,
`dΦ = (div j) dx∧dy∧dz`. -/
theorem d_flux_form_eq_div_times_volume
    (j : (Fin 3 → ℝ) → (Fin 3 → ℝ))
    (Φ : (Fin 3 → ℝ) → (Fin 3 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ)
    (hΦ : ∀ x a b, Φ x ![a, b] = j x ⬝ᵥ (crossProduct a b))
    (x : Fin 3 → ℝ) (hj : DifferentiableAt ℝ j x) (a b c : Fin 3 → ℝ) :
    extDeriv Φ x ![a, b, c] = div j x * Matrix.det (Matrix.of ![a, b, c]) := by
  have hΦ' : ∀ y (w : Fin 2 → Fin 3 → ℝ), Φ y w = j y ⬝ᵥ (crossProduct (w 0) (w 1)) := by
    intro y w
    have : w = ![w 0, w 1] := by funext i; fin_cases i <;> rfl
    rw [this, hΦ]; rfl
  let P : Fin 3 → (Fin 3 → ℝ) [⋀^Fin 1]→L[ℝ] ℝ := fun i =>
    ContinuousAlternatingMap.ofSubsingleton ℝ (Fin 3 → ℝ) ℝ (0 : Fin 1)
      (ContinuousLinearMap.proj i)
  let C : Fin 3 → Fin 3 → (Fin 3 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ := fun p q =>
    ContinuousAlternatingMap.alternatizeUncurryFin ((ContinuousLinearMap.proj p).smulRight (P q))
  have hΦeq : Φ = fun y => j y 0 • C 1 2 + j y 1 • C 2 0 + j y 2 • C 0 1 := by
    funext y; ext w
    simp [hΦ' y w, C, P, dotProduct, ContinuousAlternatingMap.alternatizeUncurryFin_apply,
      Fin.sum_univ_two, Fin.sum_univ_three, cross_apply, Fin.removeNth]
    ring
  have hΦd : DifferentiableAt ℝ Φ x := by
    rw [hΦeq]
    have h := differentiableAt_pi.1 hj
    exact (((h 0).smul_const _).add ((h 1).smul_const _)).add ((h 2).smul_const _)
  rw [extDeriv_apply hΦd]
  simp [Fin.sum_univ_three, hΦ', Fin.removeNth]
  have h21 : (Fin.succAbove (2 : Fin 3) 1 : Fin 3) = 1 := rfl
  simp only [h21, fderiv_dotProduct_const_apply j x _ _ hj]
  simp [div, Matrix.det_fin_three, Fin.sum_univ_three, cross_apply, dotProduct]
  ring

-- k = 0: the climb h(0, 4) - h(3, 0), with h = 0.04 (x - 3)² + 0.05 y, is 0.56 km
example : ((1 / 25 : ℚ) * (0 - 3) ^ 2 + 1 / 20 * 4) - ((1 / 25) * (3 - 3) ^ 2 + 1 / 20 * 0)
    = 14 / 25 := by norm_num
-- Green at 1 km: 0.4 × 6 × 8 = 19.2 km²/h, and the glider's legs -56 + 65.6 + 3 + 6.6 agree
example : (2 / 5 : ℚ) * 6 * 8 = 96 / 5 := by norm_num
example : (-56 : ℚ) + 328 / 5 + 3 + 33 / 5 = 96 / 5 := by norm_num
-- curl theorem on the ground: tilt term 0.45 × (-0.05) × 24 = -0.54, and 0 - 0.54 + 19.2 = 18.66
example : (9 / 20 : ℚ) * (-1 / 20) * 24 = -27 / 50 := by norm_num
example : (0 : ℚ) - 27 / 50 + 96 / 5 = 933 / 50 := by norm_num
-- the rim's legs -51.68 + 61.34 + 0.432 + 8.568 also give 18.66 km²/h
example : (-1292 / 25 : ℚ) + 3067 / 50 + 54 / 125 + 1071 / 125 = 933 / 50 := by norm_num
-- divergence theorem: ground 32.4592 plus north wall 3.400704 is 35.859904 mm·km²/h
example : (324592 / 10000 : ℚ) + 3400704 / 1000000 = 35859904 / 1000000 := by norm_num

#print axioms stokes_integral_d_over_region_eq_integral_over_edge
#print axioms d_work_form_eq_flux_form_of_curl
#print axioms d_flux_form_eq_div_times_volume
