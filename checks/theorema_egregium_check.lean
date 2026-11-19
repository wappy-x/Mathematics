-- Theorema Egregium: the Gaussian curvature of a smooth surface patch is fixed by its first fundamental form E, F, G alone, by Brioschi's formula, so patches with the same E, F, G have the same K and no flat map of any piece of a globe keeps every length.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic

open scoped ContDiff Matrix

namespace TheoremaEgregium

/-! A patch `r(u, v)` sends a chart point `q = (u, v)` to a point of space `Fin 3 → ℝ`.
`du f q` and `dv f q` are the partial derivatives of `f` in `u` and in `v` at `q`. -/

/-- The partial derivative in `u`: how fast `f` changes as `u` grows. -/
noncomputable def du {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    (f : ℝ × ℝ → V) (q : ℝ × ℝ) : V :=
  fderiv ℝ f q (1, 0)

/-- The partial derivative in `v`: how fast `f` changes as `v` grows. -/
noncomputable def dv {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    (f : ℝ × ℝ → V) (q : ℝ × ℝ) : V :=
  fderiv ℝ f q (0, 1)

/-- First fundamental form: `E = r_u · r_u`. -/
noncomputable def E (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ := du r q ⬝ᵥ du r q

/-- First fundamental form: `F = r_u · r_v`. -/
noncomputable def F (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ := du r q ⬝ᵥ dv r q

/-- First fundamental form: `G = r_v · r_v`. -/
noncomputable def G (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ := dv r q ⬝ᵥ dv r q

/-- The unit normal `n = (r_u × r_v) / |r_u × r_v|`, with the Euclidean length. -/
noncomputable def unitNormal (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ :=
  (Real.sqrt ((du r q ⨯₃ dv r q) ⬝ᵥ (du r q ⨯₃ dv r q)))⁻¹ • (du r q ⨯₃ dv r q)

/-- Second fundamental form: `L = r_uu · n`. -/
noncomputable def L (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ :=
  du (du r) q ⬝ᵥ unitNormal r q

/-- Second fundamental form: `M = r_uv · n`. -/
noncomputable def M (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ :=
  dv (du r) q ⬝ᵥ unitNormal r q

/-- Second fundamental form: `N = r_vv · n`. -/
noncomputable def N (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ :=
  dv (dv r) q ⬝ᵥ unitNormal r q

/-- Gaussian curvature from outside: `K = κ₁ κ₂ = (LN - M²) / (EG - F²)`. -/
noncomputable def gaussCurvature (r : ℝ × ℝ → Fin 3 → ℝ) (q : ℝ × ℝ) : ℝ :=
  (L r q * N r q - M r q ^ 2) / (E r q * G r q - F r q ^ 2)

/-- Brioschi's expression: built from three functions `e, f, g` (standing for E, F, G) and their
first and second partial derivatives only, with no normal and no patch in space. -/
noncomputable def brioschi (e f g : ℝ × ℝ → ℝ) (q : ℝ × ℝ) : ℝ :=
  (!![-(1 / 2) * dv (dv e) q + dv (du f) q - (1 / 2) * du (du g) q,
        (1 / 2) * du e q, du f q - (1 / 2) * dv e q;
      dv f q - (1 / 2) * du g q, e q, f q;
      (1 / 2) * dv g q, f q, g q].det -
    !![0, (1 / 2) * dv e q, (1 / 2) * du g q;
      (1 / 2) * dv e q, e q, f q;
      (1 / 2) * du g q, f q, g q].det) /
    (e q * g q - f q ^ 2) ^ 2

/-! Helper lemmas: smoothness of partial derivatives, symmetry of mixed partials,
the product rule for the dot product, and Brioschi's formula with no regularity hypothesis. -/

theorem smooth_fderiv_apply {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hg : ContDiffOn ℝ ∞ g U) (w : ℝ × ℝ) : ContDiffOn ℝ ∞ (fun q => fderiv ℝ g q w) U :=
  (hg.fderiv_of_isOpen hU (m := ∞) (by simp)).clm_apply contDiffOn_const

theorem du_smooth {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hg : ContDiffOn ℝ ∞ g U) : ContDiffOn ℝ ∞ (du g) U :=
  smooth_fderiv_apply hU hg (1, 0)

theorem dv_smooth {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hg : ContDiffOn ℝ ∞ g U) : ContDiffOn ℝ ∞ (dv g) U :=
  smooth_fderiv_apply hU hg (0, 1)

theorem diffAt_of_smooth {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hg : ContDiffOn ℝ ∞ g U) {x : ℝ × ℝ} (hx : x ∈ U) : DifferentiableAt ℝ g x :=
  (hg.contDiffAt (hU.mem_nhds hx)).differentiableAt (by simp)

theorem fderiv_apply_const {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {c : ℝ × ℝ → (ℝ × ℝ →L[ℝ] V)} {x : ℝ × ℝ} (hc : DifferentiableAt ℝ c x)
    (v w : ℝ × ℝ) : fderiv ℝ (fun y => c y v) x w = fderiv ℝ c x w v := by
  rw [fderiv_clm_apply hc (differentiableAt_const v)]
  simp

theorem du_dv_comm {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hg : ContDiffOn ℝ ∞ g U) {x : ℝ × ℝ} (hx : x ∈ U) : du (dv g) x = dv (du g) x := by
  have hc : DifferentiableAt ℝ (fderiv ℝ g) x :=
    diffAt_of_smooth hU (hg.fderiv_of_isOpen hU (m := ∞) (by simp)) hx
  have hs := ContDiffAt.isSymmSndFDerivAt (hg.contDiffAt (hU.mem_nhds hx)) (by simp)
  show fderiv ℝ (fun y => fderiv ℝ g y (0, 1)) x (1, 0) =
    fderiv ℝ (fun y => fderiv ℝ g y (1, 0)) x (0, 1)
  rw [fderiv_apply_const hc, fderiv_apply_const hc]
  exact hs _ _

theorem du_ev {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {f g : ℝ × ℝ → V} {x : ℝ × ℝ} (h : f =ᶠ[nhds x] g) : du f =ᶠ[nhds x] du g :=
  (h.fderiv (𝕜 := ℝ)).mono fun y hy => by
    show fderiv ℝ f y (1, 0) = fderiv ℝ g y (1, 0)
    rw [hy]

theorem dv_ev {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {f g : ℝ × ℝ → V} {x : ℝ × ℝ} (h : f =ᶠ[nhds x] g) : dv f =ᶠ[nhds x] dv g :=
  (h.fderiv (𝕜 := ℝ)).mono fun y hy => by
    show fderiv ℝ f y (0, 1) = fderiv ℝ g y (0, 1)
    rw [hy]

theorem hasFDerivAt_dot {g h : ℝ × ℝ → Fin 3 → ℝ} {x : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g x) (hh : DifferentiableAt ℝ h x) :
    ∃ D : ℝ × ℝ →L[ℝ] ℝ, HasFDerivAt (fun y => g y ⬝ᵥ h y) D x ∧
      ∀ w, D w = fderiv ℝ g x w ⬝ᵥ h x + g x ⬝ᵥ fderiv ℝ h x w := by
  have hsum := HasFDerivAt.sum (u := Finset.univ) (x := x) fun i _ =>
    (hasFDerivAt_pi'.1 hg.hasFDerivAt i).mul (hasFDerivAt_pi'.1 hh.hasFDerivAt i)
  refine ⟨_, hsum, fun w => ?_⟩
  simp [dotProduct, Fin.sum_univ_three]
  ring

theorem diff_dot {g h : ℝ × ℝ → Fin 3 → ℝ} {x : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g x) (hh : DifferentiableAt ℝ h x) :
    DifferentiableAt ℝ (fun y => g y ⬝ᵥ h y) x := by
  obtain ⟨D, hD, -⟩ := hasFDerivAt_dot hg hh
  exact hD.differentiableAt

theorem fderiv_dot {g h : ℝ × ℝ → Fin 3 → ℝ} {x : ℝ × ℝ}
    (hg : DifferentiableAt ℝ g x) (hh : DifferentiableAt ℝ h x) (w : ℝ × ℝ) :
    fderiv ℝ (fun y => g y ⬝ᵥ h y) x w = fderiv ℝ g x w ⬝ᵥ h x + g x ⬝ᵥ fderiv ℝ h x w := by
  obtain ⟨D, hD, hw⟩ := hasFDerivAt_dot hg hh
  rw [hD.fderiv, hw]

theorem fderiv_dot2 {g₁ g₂ g₃ g₄ : ℝ × ℝ → Fin 3 → ℝ} {x : ℝ × ℝ}
    (h₁ : DifferentiableAt ℝ g₁ x) (h₂ : DifferentiableAt ℝ g₂ x)
    (h₃ : DifferentiableAt ℝ g₃ x) (h₄ : DifferentiableAt ℝ g₄ x) (w : ℝ × ℝ) :
    fderiv ℝ (fun y => g₁ y ⬝ᵥ g₂ y + g₃ y ⬝ᵥ g₄ y) x w =
      (fderiv ℝ g₁ x w ⬝ᵥ g₂ x + g₁ x ⬝ᵥ fderiv ℝ g₂ x w) +
        (fderiv ℝ g₃ x w ⬝ᵥ g₄ x + g₃ x ⬝ᵥ fderiv ℝ g₄ x w) := by
  rw [fderiv_fun_add (f := fun y => g₁ y ⬝ᵥ g₂ y) (g := fun y => g₃ y ⬝ᵥ g₄ y)
    (diff_dot h₁ h₂) (diff_dot h₃ h₄), add_apply,
    fderiv_dot h₁ h₂, fderiv_dot h₃ h₄]

/-- Brioschi's formula at one point, for a patch smooth on an open set; it needs no regularity. -/
theorem brioschi_aux (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (q : ℝ × ℝ) (hq : q ∈ U) :
    gaussCurvature r q = brioschi (E r) (F r) (G r) q := by
  have hU' : U ∈ nhds q := hU.mem_nhds hq
  have s1 := du_smooth hU hr
  have s2 := dv_smooth hU hr
  have s11 := du_smooth hU s1
  have s12 := dv_smooth hU s1
  have s21 := du_smooth hU s2
  have s22 := dv_smooth hU s2
  have D : ∀ {g : ℝ × ℝ → Fin 3 → ℝ}, ContDiffOn ℝ ∞ g U → ∀ x ∈ U, DifferentiableAt ℝ g x :=
    fun hg x hx => diffAt_of_smooth hU hg hx
  have sym1 : du (dv r) =ᶠ[nhds q] dv (du r) := by
    filter_upwards [hU'] with x hx using du_dv_comm hU hr hx
  have hs' : du (dv r) q = dv (du r) q := sym1.eq_of_nhds
  have hZ : dv (du (dv r)) q = dv (dv (du r)) q := (dv_ev sym1).eq_of_nhds
  have hW : du (du (dv r)) q = dv (du (du r)) q :=
    (du_ev sym1).eq_of_nhds.trans (du_dv_comm hU s1 hq)
  have Eu : du (E r) q = du (du r) q ⬝ᵥ du r q + du r q ⬝ᵥ du (du r) q :=
    fderiv_dot (D s1 q hq) (D s1 q hq) _
  have Ev : dv (E r) q = dv (du r) q ⬝ᵥ du r q + du r q ⬝ᵥ dv (du r) q :=
    fderiv_dot (D s1 q hq) (D s1 q hq) _
  have Fu : du (F r) q = du (du r) q ⬝ᵥ dv r q + du r q ⬝ᵥ du (dv r) q :=
    fderiv_dot (D s1 q hq) (D s2 q hq) _
  have Fv : dv (F r) q = dv (du r) q ⬝ᵥ dv r q + du r q ⬝ᵥ dv (dv r) q :=
    fderiv_dot (D s1 q hq) (D s2 q hq) _
  have Gu : du (G r) q = du (dv r) q ⬝ᵥ dv r q + dv r q ⬝ᵥ du (dv r) q :=
    fderiv_dot (D s2 q hq) (D s2 q hq) _
  have Gv : dv (G r) q = dv (dv r) q ⬝ᵥ dv r q + dv r q ⬝ᵥ dv (dv r) q :=
    fderiv_dot (D s2 q hq) (D s2 q hq) _
  have Evv : dv (dv (E r)) q =
      (dv (dv (du r)) q ⬝ᵥ du r q + dv (du r) q ⬝ᵥ dv (du r) q) +
        (dv (du r) q ⬝ᵥ dv (du r) q + du r q ⬝ᵥ dv (dv (du r)) q) := by
    have h : dv (E r) =ᶠ[nhds q] fun x => dv (du r) x ⬝ᵥ du r x + du r x ⬝ᵥ dv (du r) x := by
      filter_upwards [hU'] with x hx using fderiv_dot (D s1 x hx) (D s1 x hx) _
    show fderiv ℝ _ q _ = _
    rw [h.fderiv_eq]
    exact fderiv_dot2 (D s12 q hq) (D s1 q hq) (D s1 q hq) (D s12 q hq) _
  have Fuv : dv (du (F r)) q =
      (dv (du (du r)) q ⬝ᵥ dv r q + du (du r) q ⬝ᵥ dv (dv r) q) +
        (dv (du r) q ⬝ᵥ du (dv r) q + du r q ⬝ᵥ dv (du (dv r)) q) := by
    have h : du (F r) =ᶠ[nhds q] fun x => du (du r) x ⬝ᵥ dv r x + du r x ⬝ᵥ du (dv r) x := by
      filter_upwards [hU'] with x hx using fderiv_dot (D s1 x hx) (D s2 x hx) _
    show fderiv ℝ _ q _ = _
    rw [h.fderiv_eq]
    exact fderiv_dot2 (D s11 q hq) (D s2 q hq) (D s1 q hq) (D s21 q hq) _
  have Guu : du (du (G r)) q =
      (du (du (dv r)) q ⬝ᵥ dv r q + du (dv r) q ⬝ᵥ du (dv r) q) +
        (du (dv r) q ⬝ᵥ du (dv r) q + dv r q ⬝ᵥ du (du (dv r)) q) := by
    have h : du (G r) =ᶠ[nhds q] fun x => du (dv r) x ⬝ᵥ dv r x + dv r x ⬝ᵥ du (dv r) x := by
      filter_upwards [hU'] with x hx using fderiv_dot (D s2 x hx) (D s2 x hx) _
    show fderiv ℝ _ q _ = _
    rw [h.fderiv_eq]
    exact fderiv_dot2 (D s21 q hq) (D s2 q hq) (D s2 q hq) (D s21 q hq) _
  unfold brioschi
  rw [Eu, Ev, Fu, Fv, Gu, Gv, Evv, Fuv, Guu, hZ, hW, hs']
  unfold gaussCurvature L M N unitNormal E F G
  generalize du r q = a, dv r q = b, du (du r) q = p, dv (du r) q = s, dv (dv r) q = t,
    dv (dv (du r)) q = X, dv (du (du r)) q = Y
  simp only [dotProduct_smul, smul_eq_mul]
  have hm : (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) = a ⬝ᵥ a * (b ⬝ᵥ b) - (a ⬝ᵥ b) ^ 2 := by
    rw [cross_dot_cross, dotProduct_comm b a]; ring
  have hnn : 0 ≤ (a ⨯₃ b) ⬝ᵥ (a ⨯₃ b) := by
    simp only [dotProduct, Fin.sum_univ_three]
    exact add_nonneg (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _)) (mul_self_nonneg _)
  have hc : ((Real.sqrt ((a ⨯₃ b) ⬝ᵥ (a ⨯₃ b)))⁻¹) ^ 2 = ((a ⨯₃ b) ⬝ᵥ (a ⨯₃ b))⁻¹ := by
    rw [inv_pow, Real.sq_sqrt hnn]
  generalize Real.sqrt ((a ⨯₃ b) ⬝ᵥ (a ⨯₃ b)) = w at hc ⊢
  rw [show w⁻¹ * (p ⬝ᵥ a ⨯₃ b) * (w⁻¹ * (t ⬝ᵥ a ⨯₃ b)) - (w⁻¹ * (s ⬝ᵥ a ⨯₃ b)) ^ 2 =
      w⁻¹ ^ 2 * ((p ⬝ᵥ a ⨯₃ b) * (t ⬝ᵥ a ⨯₃ b) - (s ⬝ᵥ a ⨯₃ b) ^ 2) by ring, hc, hm]
  rw [show ∀ K W : ℝ, W⁻¹ * K / W = K / W ^ 2 from fun K W => by ring]
  congr 1
  simp only [dotProduct, Fin.sum_univ_three, cross_apply, Matrix.det_fin_three, Matrix.of_apply,
    Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
    Matrix.empty_val', Matrix.cons_val_fin_one, Matrix.head_cons, Matrix.tail_cons,
    Matrix.head_fin_const]
  ring

/-- Brioschi's expression at `q` sees `e, f, g` only near `q`. -/
theorem brioschi_congr {e₁ f₁ g₁ e₂ f₂ g₂ : ℝ × ℝ → ℝ} {q : ℝ × ℝ}
    (he : e₁ =ᶠ[nhds q] e₂) (hf : f₁ =ᶠ[nhds q] f₂) (hg : g₁ =ᶠ[nhds q] g₂) :
    brioschi e₁ f₁ g₁ q = brioschi e₂ f₂ g₂ q := by
  unfold brioschi
  rw [he.eq_of_nhds, hf.eq_of_nhds, hg.eq_of_nhds, (du_ev he).eq_of_nhds, (dv_ev he).eq_of_nhds,
    (dv_ev (dv_ev he)).eq_of_nhds, (du_ev hf).eq_of_nhds, (dv_ev hf).eq_of_nhds,
    (dv_ev (du_ev hf)).eq_of_nhds, (du_ev hg).eq_of_nhds, (dv_ev hg).eq_of_nhds,
    (du_ev (du_ev hg)).eq_of_nhds]

theorem fderiv_component {g : ℝ × ℝ → Fin 3 → ℝ} {x : ℝ × ℝ} (hg : DifferentiableAt ℝ g x)
    (i : Fin 3) (w : ℝ × ℝ) : fderiv ℝ g x w i = fderiv ℝ (fun y => g y i) x w := by
  rw [(hasFDerivAt_pi'.1 hg.hasFDerivAt i).fderiv]
  rfl

theorem du_of_hasDerivAt {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {u v : ℝ} {w : V} (hg : DifferentiableAt ℝ g (u, v))
    (h : HasDerivAt (fun u' => g (u', v)) w u) : du g (u, v) = w := by
  have h2 : HasDerivAt (fun u' : ℝ => ((u', v) : ℝ × ℝ)) ((1 : ℝ), (0 : ℝ)) u :=
    (hasDerivAt_id u).prodMk (hasDerivAt_const u v)
  exact (hg.hasFDerivAt.comp_hasDerivAt u h2).unique h

theorem dv_of_hasDerivAt {V : Type*} [NormedAddCommGroup V] [NormedSpace ℝ V]
    {g : ℝ × ℝ → V} {u v : ℝ} {w : V} (hg : DifferentiableAt ℝ g (u, v))
    (h : HasDerivAt (fun v' => g (u, v')) w v) : dv g (u, v) = w := by
  have h2 : HasDerivAt (fun v' : ℝ => ((u, v') : ℝ × ℝ)) ((0 : ℝ), (1 : ℝ)) v :=
    (hasDerivAt_const v u).prodMk (hasDerivAt_id v)
  exact (hg.hasFDerivAt.comp_hasDerivAt v h2).unique h

theorem du_const' (c : ℝ) : du (fun _ : ℝ × ℝ => c) = fun _ => 0 := by
  funext x; simp [du]

theorem dv_const' (c : ℝ) : dv (fun _ : ℝ × ℝ => c) = fun _ => 0 := by
  funext x; simp [dv]

theorem du_fst {h h' : ℝ → ℝ} (hh : ∀ u, HasDerivAt h (h' u) u) :
    du (fun x : ℝ × ℝ => h x.1) = fun x => h' x.1 := by
  funext x
  obtain ⟨u, v⟩ := x
  exact du_of_hasDerivAt ((hh u).differentiableAt.comp _ differentiableAt_fst) (hh u)

theorem dv_fst {h : ℝ → ℝ} (hh : Differentiable ℝ h) :
    dv (fun x : ℝ × ℝ => h x.1) = fun _ => 0 := by
  funext x
  obtain ⟨u, v⟩ := x
  exact dv_of_hasDerivAt ((hh u).comp _ differentiableAt_fst) (hasDerivAt_const v (h u))

/-- Brioschi's expression for the globe's `E = R²`, `F = 0`, `G = R² sin² φ` gives `1/R²`. -/
theorem sphere_brioschi (R : ℝ) (hR : R ≠ 0) (q : ℝ × ℝ) (hs : Real.sin q.1 ≠ 0) :
    brioschi (fun _ => R ^ 2) (fun _ => 0) (fun x => R ^ 2 * Real.sin x.1 ^ 2) q = 1 / R ^ 2 := by
  have hGu : du (fun x : ℝ × ℝ => R ^ 2 * Real.sin x.1 ^ 2) =
      fun x => 2 * R ^ 2 * (Real.sin x.1 * Real.cos x.1) :=
    du_fst (h := fun u => R ^ 2 * Real.sin u ^ 2)
      (h' := fun u => 2 * R ^ 2 * (Real.sin u * Real.cos u)) fun u => by
      have := ((Real.hasDerivAt_sin u).pow 2).const_mul (R ^ 2)
      convert this using 1
      simp; ring
  have hGuu : du (fun x : ℝ × ℝ => 2 * R ^ 2 * (Real.sin x.1 * Real.cos x.1)) =
      fun x => 2 * R ^ 2 * (Real.cos x.1 ^ 2 - Real.sin x.1 ^ 2) :=
    du_fst (h := fun u => 2 * R ^ 2 * (Real.sin u * Real.cos u))
      (h' := fun u => 2 * R ^ 2 * (Real.cos u ^ 2 - Real.sin u ^ 2)) fun u => by
      have := ((Real.hasDerivAt_sin u).mul (Real.hasDerivAt_cos u)).const_mul (2 * R ^ 2)
      convert this using 1
      ring
  have hGv : dv (fun x : ℝ × ℝ => R ^ 2 * Real.sin x.1 ^ 2) = fun _ => 0 :=
    dv_fst (h := fun u => R ^ 2 * Real.sin u ^ 2) (by fun_prop)
  unfold brioschi
  simp only [du_const', dv_const', hGu, hGuu, hGv]
  simp [Matrix.det_fin_three]
  field_simp
  ring

theorem exists_sin_ne_zero {U : Set (ℝ × ℝ)} (hU : IsOpen U) (hne : U.Nonempty) :
    ∃ q ∈ U, Real.sin q.1 ≠ 0 := by
  obtain ⟨q₀, hq₀⟩ := hne
  by_cases h : Real.sin q₀.1 = 0
  · obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.1 hU q₀ hq₀
    have ht0 : 0 < min (ε / 2) 1 := lt_min (half_pos hε) one_pos
    have htε : min (ε / 2) 1 < ε := lt_of_le_of_lt (min_le_left _ _) (half_lt_self hε)
    have ht1 : min (ε / 2) 1 ≤ 1 := min_le_right _ _
    refine ⟨(q₀.1 + min (ε / 2) 1, q₀.2), hball ?_, ?_⟩
    · rw [Metric.mem_ball, Prod.dist_eq]
      simp [abs_of_pos ht0, htε, hε]
    · show Real.sin (q₀.1 + min (ε / 2) 1) ≠ 0
      rw [Real.sin_add, h, zero_mul, zero_add]
      have hc : Real.cos q₀.1 ≠ 0 := by
        intro hc
        have := Real.sin_sq_add_cos_sq q₀.1
        rw [h, hc] at this
        norm_num at this
      exact mul_ne_zero hc (Real.sin_pos_of_pos_of_lt_pi ht0 (by linarith [Real.two_le_pi])).ne'
  · exact ⟨q₀, hq₀, h⟩

/-- **Theorema Egregium.** Take two smooth regular surface patches `r₁` and `r₂` on the same
open set `U` of chart points (regular: the tangent arrows `r_u`, `r_v` have non-zero cross
product). If they have the same first fundamental form there, `E₁ = E₂`, `F₁ = F₂`, `G₁ = G₂`
(the same lengths, so one is the other bent without stretching), then they have the same
Gaussian curvature `K` at every point of `U`. Gaussian curvature can be felt from inside. -/
theorem theorema_egregium
    (r₁ r₂ : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (h₁ : ContDiffOn ℝ ∞ r₁ U) (h₂ : ContDiffOn ℝ ∞ r₂ U)
    (hreg₁ : ∀ q ∈ U, du r₁ q ⨯₃ dv r₁ q ≠ 0)
    (hreg₂ : ∀ q ∈ U, du r₂ q ⨯₃ dv r₂ q ≠ 0)
    (hE : ∀ q ∈ U, E r₁ q = E r₂ q) (hF : ∀ q ∈ U, F r₁ q = F r₂ q)
    (hG : ∀ q ∈ U, G r₁ q = G r₂ q) :
    ∀ q ∈ U, gaussCurvature r₁ q = gaussCurvature r₂ q := by
  intro q hq
  rw [brioschi_aux r₁ U hU h₁ q hq, brioschi_aux r₂ U hU h₂ q hq]
  have hn := hU.mem_nhds hq
  exact brioschi_congr (Filter.mem_of_superset hn fun x hx => hE x hx)
    (Filter.mem_of_superset hn fun x hx => hF x hx) (Filter.mem_of_superset hn fun x hx => hG x hx)

/-- **Brioschi's formula.** For a smooth regular patch `r` on an open set `U`, at every point of
`U` the Gaussian curvature `(LN - M²)/(EG - F²)` equals Brioschi's expression in `E`, `F`, `G`
and their first and second derivatives:
`K = (det A - det B) / (EG - F²)²`, with `A` and `B` the card's two 3 × 3 matrices. -/
theorem brioschi_formula
    (r : ℝ × ℝ → Fin 3 → ℝ) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hr : ContDiffOn ℝ ∞ r U) (hreg : ∀ q ∈ U, du r q ⨯₃ dv r q ≠ 0) :
    ∀ q ∈ U, gaussCurvature r q = brioschi (E r) (F r) (G r) q := by
  intro q hq
  exact brioschi_aux r U hU hr q hq

/-- The globe of radius `R` in the chart of polar angle `φ` down from the North Pole and
longitude `θ`: `r(φ, θ) = (R sin φ cos θ, R sin φ sin θ, R cos φ)`. -/
noncomputable def spherePatch (R : ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ :=
  ![R * Real.sin q.1 * Real.cos q.2, R * Real.sin q.1 * Real.sin q.2, R * Real.cos q.1]

/-- A flat map: the chart point `q` is drawn at the point `f q` of the plane `z = 0`. -/
def flatPatch (f : ℝ × ℝ → ℝ × ℝ) (q : ℝ × ℝ) : Fin 3 → ℝ :=
  ![(f q).1, (f q).2, 0]

theorem flat_smooth {f : ℝ × ℝ → ℝ × ℝ} {U : Set (ℝ × ℝ)} (hf : ContDiffOn ℝ ∞ f U) :
    ContDiffOn ℝ ∞ (flatPatch f) U := by
  rw [contDiffOn_pi]
  intro i
  fin_cases i
  · simpa [flatPatch] using hf.fst
  · simpa [flatPatch] using hf.snd
  · simpa [flatPatch] using (contDiffOn_const : ContDiffOn ℝ ∞ (fun _ : ℝ × ℝ => (0 : ℝ)) U)

/-- A flat drawing has Gaussian curvature `0`: its second derivatives and its tangent arrows
all lie in the plane `z = 0`, so `L = M = N = 0`. -/
theorem flat_gauss_zero {f : ℝ × ℝ → ℝ × ℝ} {U : Set (ℝ × ℝ)} (hU : IsOpen U)
    (hf : ContDiffOn ℝ ∞ f U) (q : ℝ × ℝ) (hq : q ∈ U) :
    gaussCurvature (flatPatch f) q = 0 := by
  have hr := flat_smooth hf
  have s1 := du_smooth hU hr
  have s2 := dv_smooth hU hr
  have hz : (fun y => flatPatch f y 2) = fun _ => 0 := by
    funext y; simp [flatPatch]
  have z1 : ∀ x ∈ U, du (flatPatch f) x 2 = 0 := by
    intro x hx
    rw [show du (flatPatch f) x 2 = fderiv ℝ (fun y => flatPatch f y 2) x (1, 0) from
      fderiv_component (diffAt_of_smooth hU hr hx) 2 _, hz]
    simp
  have z2 : ∀ x ∈ U, dv (flatPatch f) x 2 = 0 := by
    intro x hx
    rw [show dv (flatPatch f) x 2 = fderiv ℝ (fun y => flatPatch f y 2) x (0, 1) from
      fderiv_component (diffAt_of_smooth hU hr hx) 2 _, hz]
    simp
  have zz : ∀ {g : ℝ × ℝ → Fin 3 → ℝ}, ContDiffOn ℝ ∞ g U → (∀ x ∈ U, g x 2 = 0) →
      ∀ w, fderiv ℝ g q w 2 = 0 := by
    intro g hg h0 w
    have he : (fun y => g y 2) =ᶠ[nhds q] fun _ => 0 := by
      filter_upwards [hU.mem_nhds hq] with y hy using h0 y hy
    rw [fderiv_component (diffAt_of_smooth hU hg hq) 2 w, he.fderiv_eq]
    simp
  have z11 : du (du (flatPatch f)) q 2 = 0 := zz s1 z1 _
  have z12 : dv (du (flatPatch f)) q 2 = 0 := zz s1 z1 _
  have z22 : dv (dv (flatPatch f)) q 2 = 0 := zz s2 z2 _
  have a2 := z1 q hq
  have b2 := z2 q hq
  simp [gaussCurvature, L, M, N, unitNormal, dotProduct, Fin.sum_univ_three,
    cross_apply, a2, b2, z11, z12, z22]

theorem sphere_diff (R : ℝ) : Differentiable ℝ (spherePatch R) := by
  rw [differentiable_pi]
  intro i
  fin_cases i <;> simp [spherePatch] <;> fun_prop

theorem sphere_du (R u v : ℝ) : du (spherePatch R) (u, v) =
    ![R * Real.cos u * Real.cos v, R * Real.cos u * Real.sin v, -(R * Real.sin u)] := by
  apply du_of_hasDerivAt (sphere_diff R _)
  rw [hasDerivAt_pi]
  intro i
  fin_cases i <;> simp [spherePatch]
  · exact ((Real.hasDerivAt_sin u).const_mul R).mul_const _
  · exact ((Real.hasDerivAt_sin u).const_mul R).mul_const _
  · simpa using (Real.hasDerivAt_cos u).const_mul R

theorem sphere_dv (R u v : ℝ) : dv (spherePatch R) (u, v) =
    ![-(R * Real.sin u * Real.sin v), R * Real.sin u * Real.cos v, 0] := by
  apply dv_of_hasDerivAt (sphere_diff R _)
  rw [hasDerivAt_pi]
  intro i
  fin_cases i <;> simp [spherePatch]
  · simpa using (Real.hasDerivAt_cos v).const_mul (R * Real.sin u)
  · exact (Real.hasDerivAt_sin v).const_mul (R * Real.sin u)
  · exact hasDerivAt_const v _

theorem sphere_E (R : ℝ) : E (spherePatch R) = fun _ => R ^ 2 := by
  funext q
  obtain ⟨u, v⟩ := q
  simp only [E, sphere_du]
  simp [dotProduct, Fin.sum_univ_three]
  linear_combination (R ^ 2 * Real.cos u ^ 2) * Real.sin_sq_add_cos_sq v +
    R ^ 2 * Real.sin_sq_add_cos_sq u

theorem sphere_F (R : ℝ) : F (spherePatch R) = fun _ => 0 := by
  funext q
  obtain ⟨u, v⟩ := q
  simp only [F, sphere_du, sphere_dv]
  simp [dotProduct, Fin.sum_univ_three]
  ring

theorem sphere_G (R : ℝ) : G (spherePatch R) = fun q => R ^ 2 * Real.sin q.1 ^ 2 := by
  funext q
  obtain ⟨u, v⟩ := q
  simp only [G, sphere_dv]
  simp [dotProduct, Fin.sum_univ_three]
  linear_combination (R ^ 2 * Real.sin u ^ 2) * Real.sin_sq_add_cos_sq v

/-- **No flat map of a globe keeps lengths.** For a globe of radius `R > 0` and any non-empty
open set `U` of chart points (however small a piece of the globe), there is no smooth flat map
`f` that keeps every length, that is, whose drawing in the plane has the same `E`, `F`, `G` as
the globe on `U`. -/
theorem no_flat_map_keeps_lengths (R : ℝ) (hR : 0 < R) (U : Set (ℝ × ℝ)) (hU : IsOpen U)
    (hne : U.Nonempty) :
    ¬ ∃ f : ℝ × ℝ → ℝ × ℝ, ContDiffOn ℝ ∞ f U ∧
      ∀ q ∈ U, E (flatPatch f) q = E (spherePatch R) q ∧
        F (flatPatch f) q = F (spherePatch R) q ∧
        G (flatPatch f) q = G (spherePatch R) q := by
  rintro ⟨f, hf, hEFG⟩
  obtain ⟨q, hq, hs⟩ := exists_sin_ne_zero hU hne
  have h0 := flat_gauss_zero hU hf q hq
  rw [brioschi_aux _ U hU (flat_smooth hf) q hq] at h0
  have hn := hU.mem_nhds hq
  rw [brioschi_congr (Filter.mem_of_superset hn fun x hx => (hEFG x hx).1)
    (Filter.mem_of_superset hn fun x hx => (hEFG x hx).2.1)
    (Filter.mem_of_superset hn fun x hx => (hEFG x hx).2.2),
    sphere_E, sphere_F, sphere_G, sphere_brioschi R hR.ne' q hs] at h0
  have : 0 < 1 / R ^ 2 := by positivity
  linarith

end TheoremaEgregium

open TheoremaEgregium

-- The roof's saddle, plan chart E = 1 + u²/3600, F = -uv/3600, G = 1 + v²/3600,
-- at the lamp fixing P = (30, 20): E = 5/4, F = -1/6 (-0.166667), G = 10/9.
example : (1 : ℚ) + 30 ^ 2 / 3600 = 5 / 4 := by norm_num
example : -((30 : ℚ) * 20) / 3600 = -1 / 6 := by norm_num
example : (1 : ℚ) + 20 ^ 2 / 3600 = 10 / 9 := by norm_num
-- EG - F² = 49/36 = 1 + 1/4 + 1/9 (the card's 1.361111).
example : (5 / 4 : ℚ) * (10 / 9) - (-1 / 6) ^ 2 = 49 / 36 := by norm_num
example : (1 : ℚ) + 1 / 4 + 1 / 9 = 49 / 36 := by norm_num
-- Brioschi at P, with E_u = 1/60, E_v = 0, E_vv = 0, F_u = -1/180, F_v = -1/120,
-- F_uv = -1/3600, G_u = 0, G_v = 1/90, G_uu = 0: det A = -1/3600 and det B = 0,
-- so K = (-1/3600)/(49/36)² = -9/60025 (-0.000149938 per m²).
example : !![(-1 / 3600 : ℚ), 1 / 120, -1 / 180;
    -1 / 120, 5 / 4, -1 / 6;
    1 / 180, -1 / 6, 10 / 9].det = -1 / 3600 := by
  simp [Matrix.det_fin_three]; norm_num
example : !![(0 : ℚ), 0, 0;
    0, 5 / 4, -1 / 6;
    0, -1 / 6, 10 / 9].det = 0 := by
  simp [Matrix.det_fin_three]
example : ((-1 / 3600 : ℚ) - 0) / (49 / 36) ^ 2 = -9 / 60025 := by norm_num
-- The dome, a sphere of radius 60 m: K = 1/60² = 1/3600 per m².
example : (1 : ℚ) / 60 ^ 2 = 1 / 3600 := by norm_num

#print axioms theorema_egregium
#print axioms brioschi_formula
#print axioms no_flat_map_keeps_lengths
#print axioms smooth_fderiv_apply
#print axioms du_smooth
#print axioms dv_smooth
#print axioms diffAt_of_smooth
#print axioms fderiv_apply_const
#print axioms du_dv_comm
#print axioms du_ev
#print axioms dv_ev
#print axioms hasFDerivAt_dot
#print axioms diff_dot
#print axioms fderiv_dot
#print axioms fderiv_dot2
#print axioms brioschi_aux
#print axioms brioschi_congr
#print axioms fderiv_component
#print axioms du_of_hasDerivAt
#print axioms dv_of_hasDerivAt
#print axioms du_const'
#print axioms dv_const'
#print axioms du_fst
#print axioms dv_fst
#print axioms sphere_brioschi
#print axioms exists_sin_ne_zero
#print axioms flat_smooth
#print axioms flat_gauss_zero
#print axioms sphere_diff
#print axioms sphere_du
#print axioms sphere_dv
#print axioms sphere_E
#print axioms sphere_F
#print axioms sphere_G
