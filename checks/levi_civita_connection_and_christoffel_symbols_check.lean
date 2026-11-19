-- Levi-Civita connection: a smooth, symmetric, invertible metric forces exactly one connection that keeps lengths and adds no twist, whose Christoffel symbols are ½ g^kl (∂_i g_jl + ∂_j g_il − ∂_l g_ij), and on the globe these are −sin φ cos φ and cot φ.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.Geometry.Manifold.VectorBundle.CovariantDerivative.LeviCivita

open Real Set Bundle
open scoped ContDiff Manifold

/-! A chart is a point `x : Fin n → ℝ`; the coordinate `x i` is `x^i` (an upper index is a
label, not a power). The metric is a matrix of functions, `g x i j = g_ij` at the point `x`.
A table `Γ x k i j` stands for `Γ^k_ij` at `x`, so that `∇_{∂_i} ∂_j = Γ^k_ij ∂_k`. -/

/-- `∂_i f`: the rate of change of `f` along the chart direction `i`. -/
noncomputable def pd {n : ℕ} (i : Fin n) (f : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) : ℝ :=
  fderiv ℝ f x (Pi.single i 1)

/-- The card's formula: `Γ^k_ij = ½ g^kl (∂_i g_jl + ∂_j g_il − ∂_l g_ij)`, summed over `l`,
where `g^kl` is the inverse matrix of `g_ij`. -/
noncomputable def christoffel {n : ℕ} (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ)
    (x : Fin n → ℝ) (k i j : Fin n) : ℝ :=
  (1 / 2) * ∑ l : Fin n, (g x)⁻¹ k l *
    (pd i (fun y => g y j l) x + pd j (fun y => g y i l) x - pd l (fun y => g y i j) x)

/-- Contracting with the inverse matrix and then the matrix gives back the vector. -/
theorem lc_inv_contract {n : ℕ} (G : Matrix (Fin n) (Fin n) ℝ) (hG : G.IsSymm)
    (hdet : IsUnit G.det) (v : Fin n → ℝ) (j : Fin n) :
    ∑ l : Fin n, (∑ m : Fin n, G⁻¹ l m * v m) * G l j = v j := by
  have h1 : G⁻¹ * G = 1 := Matrix.nonsing_inv_mul G hdet
  have hs : (G⁻¹).transpose = G⁻¹ := by rw [Matrix.transpose_nonsing_inv, hG.eq]
  calc ∑ l : Fin n, (∑ m : Fin n, G⁻¹ l m * v m) * G l j
      = ∑ m : Fin n, v m * ∑ l : Fin n, G⁻¹ m l * G l j := by
        simp_rw [Finset.sum_mul, Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun m _ => Finset.sum_congr rfl fun l _ => ?_
        have : G⁻¹ l m = G⁻¹ m l := by
          simpa using congrFun (congrFun hs m) l
        rw [this]; ring
    _ = ∑ m : Fin n, v m * (1 : Matrix (Fin n) (Fin n) ℝ) m j := by
        refine Finset.sum_congr rfl fun m _ => ?_
        rw [← h1, Matrix.mul_apply]
    _ = v j := by simp [Matrix.one_apply]

theorem lc_inv_contract' {n : ℕ} (G : Matrix (Fin n) (Fin n) ℝ) (hG : G.IsSymm)
    (hdet : IsUnit G.det) (v : Fin n → ℝ) (j : Fin n) :
    ∑ l : Fin n, G j l * (∑ m : Fin n, G⁻¹ l m * v m) = v j := by
  rw [← lc_inv_contract G hG hdet v j]
  refine Finset.sum_congr rfl fun l _ => ?_
  rw [mul_comm, hG.apply l j]

/-- `∑_l g^kl (∑_m Γ^m g_ml) = Γ^k`. -/
theorem lc_inv_lower {n : ℕ} (G : Matrix (Fin n) (Fin n) ℝ) (hG : G.IsSymm)
    (hdet : IsUnit G.det) (w : Fin n → ℝ) (k : Fin n) :
    ∑ l : Fin n, G⁻¹ k l * (∑ m : Fin n, w m * G m l) = w k := by
  have h1 : G⁻¹ * G = 1 := Matrix.nonsing_inv_mul G hdet
  calc ∑ l : Fin n, G⁻¹ k l * (∑ m : Fin n, w m * G m l)
      = ∑ m : Fin n, w m * ∑ l : Fin n, G⁻¹ k l * G l m := by
        simp_rw [Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun m _ => Finset.sum_congr rfl fun l _ => ?_
        rw [hG.apply m l]; ring
    _ = ∑ m : Fin n, w m * (1 : Matrix (Fin n) (Fin n) ℝ) k m := by
        refine Finset.sum_congr rfl fun m _ => ?_
        rw [← h1, Matrix.mul_apply]
    _ = w k := by simp [Matrix.one_apply]

/-- The pointwise algebra behind the chart theorem. -/
theorem lc_pointwise {n : ℕ} (G : Matrix (Fin n) (Fin n) ℝ) (hG : G.IsSymm)
    (hdet : IsUnit G.det) (D : Fin n → Fin n → Fin n → ℝ)
    (hD : ∀ k i j, D k i j = D k j i) (Γ : Fin n → Fin n → Fin n → ℝ) :
    ((∀ k i j, Γ k i j = Γ k j i) ∧
      (∀ k i j, D k i j = ∑ l : Fin n, (Γ l k i * G l j + Γ l k j * G i l))) ↔
      ∀ k i j, Γ k i j = (1 / 2) * ∑ l : Fin n, G⁻¹ k l * (D i j l + D j i l - D l i j) := by
  constructor
  · rintro ⟨hs, hc⟩ k i j
    have key : ∀ l, D i j l + D j i l - D l i j = 2 * ∑ m : Fin n, Γ m i j * G m l := by
      intro l
      rw [hc i j l, hc j i l, hc l i j, Finset.mul_sum, ← Finset.sum_add_distrib,
        ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun m _ => ?_
      rw [hs m j i, hs m l i, hs m l j, hG.apply m j]
      ring
    simp_rw [key]
    rw [← lc_inv_lower G hG hdet (fun m => Γ m i j) k, Finset.mul_sum]
    refine Finset.sum_congr rfl fun l _ => ?_
    ring
  · intro hΓ
    refine ⟨fun k i j => ?_, fun k i j => ?_⟩
    · rw [hΓ, hΓ]
      congr 1
      refine Finset.sum_congr rfl fun l _ => ?_
      rw [hD l i j]
      ring
    · simp_rw [hΓ]
      have e1 := lc_inv_contract G hG hdet (fun m => D k i m + D i k m - D m k i) j
      have e2 := lc_inv_contract' G hG hdet (fun m => D k j m + D j k m - D m k j) i
      have e1' : ∑ l : Fin n, (1 / 2 * ∑ m : Fin n, G⁻¹ l m * (D k i m + D i k m - D m k i))
          * G l j = (1 / 2) * (D k i j + D i k j - D j k i) := by
        rw [← e1, Finset.mul_sum]
        refine Finset.sum_congr rfl fun l _ => ?_
        ring
      have e2' : ∑ l : Fin n, (1 / 2 * ∑ m : Fin n, G⁻¹ l m * (D k j m + D j k m - D m k j))
          * G i l = (1 / 2) * (D k j i + D j k i - D i k j) := by
        rw [← e2, Finset.mul_sum]
        refine Finset.sum_congr rfl fun l _ => ?_
        ring
      rw [Finset.sum_add_distrib, e1', e2', hD k j i]
      ring

theorem lc_pd_symm {n : ℕ} (U : Set (Fin n → ℝ)) (hU : IsOpen U)
    (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ) (hsymm : ∀ x ∈ U, (g x).IsSymm)
    (x : Fin n → ℝ) (hx : x ∈ U) (k i j : Fin n) :
    pd k (fun y => g y i j) x = pd k (fun y => g y j i) x := by
  have h : (fun y => g y i j) =ᶠ[nhds x] (fun y => g y j i) := by
    filter_upwards [hU.mem_nhds hx] with y hy
    exact (hsymm y hy).apply j i
  unfold pd
  rw [h.fderiv_eq]

#print axioms lc_inv_contract
#print axioms lc_inv_contract'
#print axioms lc_inv_lower
#print axioms lc_pointwise
#print axioms lc_pd_symm

/-- The fundamental theorem of Riemannian geometry, in a chart. Let the metric `g_ij` be smooth,
symmetric and invertible on an open chart domain `U` (positive lengths are not needed). A table
`Γ^k_ij` adds no twist (`Γ^k_ij = Γ^k_ji`) and keeps lengths
(`∂_k g_ij = Γ^l_ki g_lj + Γ^l_kj g_il`) at every point of `U` if and only if it is the
Christoffel formula there. So the formula's table meets both demands, and it is the only one. -/
theorem christoffel_formula_is_the_unique_symmetric_metric_table {n : ℕ}
    (U : Set (Fin n → ℝ)) (hU : IsOpen U)
    (g : (Fin n → ℝ) → Matrix (Fin n) (Fin n) ℝ)
    (hsmooth : ∀ i j, ContDiffOn ℝ ∞ (fun x => g x i j) U)
    (hsymm : ∀ x ∈ U, (g x).IsSymm)
    (hinv : ∀ x ∈ U, IsUnit (g x).det)
    (Γ : (Fin n → ℝ) → Fin n → Fin n → Fin n → ℝ) :
    ((∀ x ∈ U, ∀ k i j, Γ x k i j = Γ x k j i) ∧
      (∀ x ∈ U, ∀ k i j, pd k (fun y => g y i j) x =
        ∑ l : Fin n, (Γ x l k i * g x l j + Γ x l k j * g x i l))) ↔
      ∀ x ∈ U, ∀ k i j, Γ x k i j = christoffel g x k i j := by
  have P := fun x (hx : x ∈ U) => lc_pointwise (g x) (hsymm x hx) (hinv x hx)
    (fun k i j => pd k (fun y => g y i j) x) (lc_pd_symm U hU g hsymm x hx) (Γ x)
  constructor
  · rintro ⟨hs, hc⟩ x hx
    exact (P x hx).mp ⟨hs x hx, hc x hx⟩
  · intro h
    exact ⟨fun x hx => ((P x hx).mpr (h x hx)).1, fun x hx => ((P x hx).mpr (h x hx)).2⟩

/-- The fundamental theorem of Riemannian geometry, chart-free. On a smooth Riemannian manifold
`M` with a smooth metric, there is a connection on the tangent bundle that keeps lengths and adds
no twist (a Levi-Civita connection), and any two such connections agree on every differentiable
vector field. -/
theorem levi_civita_connection_exists_unique
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H)
    {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
    [RiemannianBundle (fun (x : M) ↦ TangentSpace I x)]
    [IsContMDiffRiemannianBundle I ∞ E (fun (x : M) ↦ TangentSpace I x)] :
    (∃ cov : CovariantDerivative I E (TangentSpace I : M → Type _),
        cov.IsLeviCivitaConnection) ∧
      ∀ cov cov' : CovariantDerivative I E (TangentSpace I : M → Type _),
        cov.IsLeviCivitaConnection → cov'.IsLeviCivitaConnection →
        ∀ (Y : Π x : M, TangentSpace I x) (x : M), MDiffAt (T% Y) x →
          ∀ X₀ : TangentSpace I x, cov Y x X₀ = cov' Y x X₀ := by
  refine ⟨⟨_, CovariantDerivative.isLeviCivitaConnection_leviCivitaConnection I⟩, ?_⟩
  intro cov cov' h h' Y x hY X₀
  exact h.uniqueness I h' hY X₀

/-- The globe of radius `R` in the chart `(φ, θ)`, index `0` for `φ` (down from the North Pole)
and `1` for `θ` (longitude east): `g_φφ = R²`, `g_φθ = 0`, `g_θθ = R² sin² φ`. -/
noncomputable def globeMetric (R : ℝ) (x : Fin 2 → ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![R ^ 2, 0; 0, R ^ 2 * sin (x 0) ^ 2]

/-- The globe's Christoffel symbols: `Γ^φ_θθ = −sin φ cos φ`, `Γ^θ_φθ = Γ^θ_θφ = cot φ`, and the
other five are `0`. -/
noncomputable def globeSymbols (x : Fin 2 → ℝ) : Fin 2 → Fin 2 → Fin 2 → ℝ :=
  ![![![0, 0], ![0, -(sin (x 0) * cos (x 0))]],
    ![![0, cos (x 0) / sin (x 0)], ![cos (x 0) / sin (x 0), 0]]]

theorem lc_pd_const {n : ℕ} (i : Fin n) (c : ℝ) (x : Fin n → ℝ) :
    pd i (fun _ => c) x = 0 := by
  simp [pd]

theorem lc_pd_globe (R : ℝ) (i : Fin 2) (x : Fin 2 → ℝ) :
    pd i (fun y => R ^ 2 * sin (y 0) ^ 2) x =
      (Pi.single i (1 : ℝ) : Fin 2 → ℝ) 0 * (R ^ 2 * (2 * sin (x 0) * cos (x 0))) := by
  have h := ((HasFDerivAt.sin (hasFDerivAt_apply (𝕜 := ℝ) (0 : Fin 2) x)).pow 2).const_mul (R ^ 2)
  unfold pd
  rw [h.fderiv]
  simp
  ring

theorem lc_globe_entry_00 (R : ℝ) (y : Fin 2 → ℝ) : globeMetric R y 0 0 = R ^ 2 := by
  simp [globeMetric]
theorem lc_globe_entry_01 (R : ℝ) (y : Fin 2 → ℝ) : globeMetric R y 0 1 = 0 := by
  simp [globeMetric]
theorem lc_globe_entry_10 (R : ℝ) (y : Fin 2 → ℝ) : globeMetric R y 1 0 = 0 := by
  simp [globeMetric]
theorem lc_globe_entry_11 (R : ℝ) (y : Fin 2 → ℝ) :
    globeMetric R y 1 1 = R ^ 2 * sin (y 0) ^ 2 := by
  simp [globeMetric]

theorem lc_globe_inv (R : ℝ) (hR : 0 < R) (x : Fin 2 → ℝ) (hs : sin (x 0) ≠ 0) :
    (globeMetric R x)⁻¹ = !![1 / R ^ 2, 0; 0, 1 / (R ^ 2 * sin (x 0) ^ 2)] := by
  apply Matrix.inv_eq_left_inv
  have hR2 : R ^ 2 ≠ 0 := by positivity
  ext i j
  fin_cases i <;> fin_cases j <;> simp [globeMetric, Matrix.mul_apply, Fin.sum_univ_two] <;>
    field_simp

#print axioms lc_pd_const
#print axioms lc_pd_globe
#print axioms lc_globe_entry_00
#print axioms lc_globe_entry_01
#print axioms lc_globe_entry_10
#print axioms lc_globe_entry_11
#print axioms lc_globe_inv

/-- On a globe of radius `R > 0`, away from the poles (`0 < φ < π`), the Christoffel formula
applied to the globe's metric gives `Γ^φ_θθ = −sin φ cos φ`, `Γ^θ_φθ = cot φ`, and `0` for the
rest. -/
theorem christoffel_symbols_of_globe (R : ℝ) (hR : 0 < R) (x : Fin 2 → ℝ)
    (hx : x 0 ∈ Ioo 0 π) (k i j : Fin 2) :
    christoffel (globeMetric R) x k i j = globeSymbols x k i j := by
  have hs : sin (x 0) ≠ 0 := (sin_pos_of_pos_of_lt_pi hx.1 hx.2).ne'
  have hR2 : R ^ 2 ≠ 0 := by positivity
  unfold christoffel
  rw [lc_globe_inv R hR x hs]
  fin_cases k <;> fin_cases i <;> fin_cases j <;>
    simp [Fin.sum_univ_two, globeSymbols, lc_globe_entry_00, lc_globe_entry_01,
      lc_globe_entry_10, lc_globe_entry_11, lc_pd_const, lc_pd_globe] <;>
    field_simp

/-! Worked counts from the card, checked exactly. -/

/-- Step 0 in two dimensions: a symmetric table `Γ^k_ij = Γ^k_ji` has 6 unknowns,
two values of `k` times three unordered pairs `ij`. -/
example : (Finset.univ.filter (fun t : Fin 2 × Fin 2 × Fin 2 => t.2.1 ≤ t.2.2)).card = 6 := by
  decide

/-- Step 0: both counts are `n · n(n+1)/2`, which is `2 × 3 = 6` when `n = 2`. -/
example : 2 * (2 * (2 + 1) / 2) = 6 := by norm_num

#print axioms christoffel_formula_is_the_unique_symmetric_metric_table
#print axioms levi_civita_connection_exists_unique
#print axioms christoffel_symbols_of_globe
