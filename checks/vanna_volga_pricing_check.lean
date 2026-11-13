-- Vanna-volga pricing: the method returns each pillar's market price exactly, its hedge weights for a vanilla call have a closed Lagrange form, and its overlay equals the target's Greeks times three market prices of risk.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Matrix

namespace VannaVolga

/-- Garman-Kohlhagen distance `d₁` for a call at strike `K`: spot `S`, dollar rate `rd`,
euro rate `rf`, flat volatility `σ`, time to expiry `T`. -/
noncomputable def d1 (S rd rf σ T K : ℝ) : ℝ :=
  (Real.log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * Real.sqrt T)

/-- Garman-Kohlhagen distance `d₂ = d₁ - σ √T`. -/
noncomputable def d2 (S rd rf σ T K : ℝ) : ℝ :=
  d1 S rd rf σ T K - σ * Real.sqrt T

/-- Height of the standard bell curve. -/
noncomputable def φ (u : ℝ) : ℝ :=
  Real.exp (-(u ^ 2) / 2) / Real.sqrt (2 * Real.pi)

/-- Vega of a call: `S e^{-rf T} φ(d₁) √T`. -/
noncomputable def vega (S rd rf σ T K : ℝ) : ℝ :=
  S * Real.exp (-rf * T) * φ (d1 S rd rf σ T K) * Real.sqrt T

/-- Vanna of a call: `-vega · d₂ / (S σ √T)`. -/
noncomputable def vanna (S rd rf σ T K : ℝ) : ℝ :=
  -(vega S rd rf σ T K * d2 S rd rf σ T K) / (S * σ * Real.sqrt T)

/-- Volga of a call: `vega · d₁ d₂ / σ`. -/
noncomputable def volga (S rd rf σ T K : ℝ) : ℝ :=
  vega S rd rf σ T K * d1 S rd rf σ T K * d2 S rd rf σ T K / σ

/-- The Greek column (vega, vanna, volga) of a call at strike `K`, all at the flat vol. -/
noncomputable def greeks (S rd rf σ T K : ℝ) : Fin 3 → ℝ :=
  ![vega S rd rf σ T K, vanna S rd rf σ T K, volga S rd rf σ T K]

/-- The pillar matrix `A`: one row per Greek, one column per pillar strike `Ks i`. -/
noncomputable def pillarMatrix (S rd rf σ T : ℝ) (Ks : Fin 3 → ℝ) : Matrix (Fin 3) (Fin 3) ℝ :=
  Matrix.of fun r i => greeks S rd rf σ T (Ks i) r

/-- The three Lagrange weights `ℓᵢ(ln K)` that fit a parabola in log-strike through the pillars. -/
noncomputable def lagrange (Ks : Fin 3 → ℝ) (K : ℝ) : Fin 3 → ℝ :=
  let z := Real.log K
  let z₁ := Real.log (Ks 0)
  let z₂ := Real.log (Ks 1)
  let z₃ := Real.log (Ks 2)
  ![(z - z₂) * (z - z₃) / ((z₁ - z₂) * (z₁ - z₃)),
    (z - z₁) * (z - z₃) / ((z₂ - z₁) * (z₂ - z₃)),
    (z - z₁) * (z - z₂) / ((z₃ - z₁) * (z₃ - z₂))]

/-- **The three pillars come back exactly.** Let `A` be the 3×3 table of pillar Greeks with
`det A ≠ 0`. Feed the method pillar `j`: its Greek column is column `j` of `A`, and its flat
price is `C_j^BS`. Then for the hedge weights `x` solving `A x = g`, the vanna-volga price
`C_j^BS + Σᵢ xᵢ (C_i^mkt - C_i^BS)` equals the pillar's market price `C_j^mkt`. -/
theorem vanna_volga_reproduces_pillar_prices (A : Matrix (Fin 3) (Fin 3) ℝ) (hA : A.det ≠ 0)
    (Cmkt Cbs : Fin 3 → ℝ) (j : Fin 3) (x : Fin 3 → ℝ) (hx : A *ᵥ x = fun r => A r j) :
    Cbs j + ∑ i, x i * (Cmkt i - Cbs i) = Cmkt j := by
  have hinj := mulVec_injective_iff_isUnit.2 ((isUnit_iff_isUnit_det A).2 (isUnit_iff_ne_zero.2 hA))
  have hxj : x = Pi.single j 1 := by
    apply hinj
    rw [hx]
    ext r
    simp [mulVec, dotProduct, Pi.single_apply]
  subst hxj
  simp [Pi.single_apply]

/-- **Closed-form weights for a vanilla call.** With Garman-Kohlhagen Greeks at the flat vol,
positive spot, vol, time and strikes, and a pillar matrix with `det A ≠ 0`, the hedge weights
for a call at strike `K` are exactly `xᵢ = vega(K) / vega(Kᵢ) · ℓᵢ(ln K)`: these weights solve
`A x = g`, and no other weights do. -/
theorem vanna_volga_vanilla_weights_closed_form (S rd rf σ T K : ℝ) (Ks : Fin 3 → ℝ)
    (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) (hK : 0 < K) (hKs : ∀ i, 0 < Ks i)
    (hA : (pillarMatrix S rd rf σ T Ks).det ≠ 0) (x : Fin 3 → ℝ) :
    pillarMatrix S rd rf σ T Ks *ᵥ x = greeks S rd rf σ T K ↔
      x = fun i => vega S rd rf σ T K / vega S rd rf σ T (Ks i) * lagrange Ks K i := by
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.2 hT
  have hφ : ∀ u, 0 < φ u := fun u =>
    div_pos (Real.exp_pos _) (Real.sqrt_pos.2 (by positivity))
  have hV : ∀ K', 0 < vega S rd rf σ T K' := fun K' => by
    unfold vega; have := hφ (d1 S rd rf σ T K'); positivity
  have hd1 : ∀ K', 0 < K' → d1 S rd rf σ T K' =
      (Real.log S - Real.log K' + (rd - rf + σ ^ 2 / 2) * T) / (σ * Real.sqrt T) := by
    intro K' hK'; unfold d1; rw [Real.log_div hS.ne' hK'.ne']
  have hdist : ∀ i k, i ≠ k → Real.log (Ks i) - Real.log (Ks k) ≠ 0 := by
    intro i k hik heq
    have : Ks i = Ks k := Real.log_injOn_pos (hKs i) (hKs k) (sub_eq_zero.1 heq)
    apply hA
    exact Matrix.det_zero_of_column_eq hik (by intro r; simp [pillarMatrix, this])
  have h01 := hdist 0 1 (by decide)
  have h02 := hdist 0 2 (by decide)
  have h12 := hdist 1 2 (by decide)
  have h10 := hdist 1 0 (by decide)
  have h20 := hdist 2 0 (by decide)
  have h21 := hdist 2 1 (by decide)
  have hV0 := (hV (Ks 0)).ne'
  have hV1 := (hV (Ks 1)).ne'
  have hV2 := (hV (Ks 2)).ne'
  have hsol : pillarMatrix S rd rf σ T Ks *ᵥ
      (fun i => vega S rd rf σ T K / vega S rd rf σ T (Ks i) * lagrange Ks K i) =
      greeks S rd rf σ T K := by
    ext r
    fin_cases r <;>
    simp only [mulVec, dotProduct, Fin.sum_univ_three, pillarMatrix, Matrix.of_apply, greeks,
      lagrange, vanna, volga, d2, Fin.zero_eta, Fin.mk_one, Fin.reduceFinMk,
      Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
      Matrix.vecHead, Matrix.vecTail, Function.comp_apply, Fin.succ_zero_eq_one,
      hd1 _ (hKs 0), hd1 _ (hKs 1), hd1 _ (hKs 2), hd1 _ hK] <;>
    generalize vega S rd rf σ T (Ks 0) = V0 at * <;>
    generalize vega S rd rf σ T (Ks 1) = V1 at * <;>
    generalize vega S rd rf σ T (Ks 2) = V2 at * <;>
    generalize vega S rd rf σ T K = VK at * <;>
    generalize Real.log (Ks 0) = z0 at * <;>
    generalize Real.log (Ks 1) = z1 at * <;>
    generalize Real.log (Ks 2) = z2 at * <;>
    generalize Real.log K = z at * <;>
    generalize Real.sqrt T = q at * <;>
    field_simp <;>
    ring
  constructor
  · intro h
    exact (mulVec_injective_iff_isUnit.2
      ((isUnit_iff_isUnit_det _).2 (isUnit_iff_ne_zero.2 hA))) (h.trans hsol.symm)
  · rintro rfl; exact hsol

/-- **The overlay as three market prices of risk.** If the weights solve `A x = g` and the
prices of risk solve `Aᵀ y = Δp`, then the overlay `Σᵢ xᵢ Δpᵢ` equals `Σⱼ gⱼ yⱼ`: the target's
vega, vanna and volga times the market's price for one unit of each. -/
theorem vanna_volga_overlay_eq_greeks_times_prices_of_risk (A : Matrix (Fin 3) (Fin 3) ℝ)
    (g Δp x y : Fin 3 → ℝ) (hx : A *ᵥ x = g) (hy : Aᵀ *ᵥ y = Δp) :
    ∑ i, x i * Δp i = ∑ j, g j * y j := by
  calc ∑ i, x i * Δp i = x ⬝ᵥ (Aᵀ *ᵥ y) := by rw [hy]; rfl
    _ = (x ᵥ* Aᵀ) ⬝ᵥ y := dotProduct_mulVec _ _ _
    _ = (A *ᵥ x) ⬝ᵥ y := by rw [vecMul_transpose]
    _ = ∑ j, g j * y j := by rw [hx]; rfl

#print axioms vanna_volga_reproduces_pillar_prices
#print axioms vanna_volga_vanilla_weights_closed_form
#print axioms vanna_volga_overlay_eq_greeks_times_prices_of_risk

end VannaVolga
