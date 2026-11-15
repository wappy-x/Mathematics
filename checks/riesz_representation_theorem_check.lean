-- Riesz representation: on a Hilbert space every bounded linear functional is the inner product with exactly one fixed vector of the same size, and this identifies the space with its dual conjugate-linearly.
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! `E` is a Hilbert space: a complete inner product space over `𝕜`, the real or the complex
numbers (`RCLike 𝕜`). Mathlib's inner product `⟪y, x⟫_𝕜` conjugates its first slot, as on
the card. A bounded linear functional is a continuous linear map `φ : E →L[𝕜] 𝕜`
(an element of Mathlib's dual space `StrongDual 𝕜 E`), and `‖φ‖` is its operator norm,
the largest `|φ x| / ‖x‖`. -/

open scoped InnerProductSpace ComplexConjugate

section General

variable {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]
  [CompleteSpace E]

/-- The Riesz representation theorem: on a Hilbert space, every bounded linear functional `φ`
is the inner product with one fixed vector `y`, placed in the first (conjugated) slot:
`φ x = ⟪y, x⟫` for every `x`. That vector is the only one that does this, and its length is
the size of the functional: `‖φ‖ = ‖y‖`. -/
theorem riesz_representation (φ : StrongDual 𝕜 E) :
    ∃ y : E, (∀ x : E, φ x = ⟪y, x⟫_𝕜) ∧ ‖φ‖ = ‖y‖ ∧
      ∀ y' : E, (∀ x : E, φ x = ⟪y', x⟫_𝕜) → y' = y := by
  refine ⟨(InnerProductSpace.toDual 𝕜 E).symm φ, ?_, ?_, ?_⟩
  · intro x
    rw [InnerProductSpace.toDual_symm_apply]
  · rw [LinearIsometryEquiv.norm_map]
  · intro y' hy'
    apply (InnerProductSpace.toDual 𝕜 E).injective
    rw [LinearIsometryEquiv.apply_symm_apply]
    ext x
    rw [InnerProductSpace.toDual_apply_apply, hy' x]

/-- The way back: every vector `y` gives the bounded functional `x ↦ ⟪y, x⟫`, and the map
`y ↦ ⟪y, ·⟫` from the Hilbert space to its dual is a bijection that keeps lengths and is
conjugate-linear (scaling `y` by `a` scales the functional by `conj a`). So the dual is a copy
of the space. -/
theorem hilbert_space_conjugate_isometric_to_dual :
    ∃ T : E ≃ₗᵢ⋆[𝕜] StrongDual 𝕜 E, ∀ y x : E, T y x = ⟪y, x⟫_𝕜 := by
  exact ⟨InnerProductSpace.toDual 𝕜 E, fun y x => InnerProductSpace.toDual_apply_apply⟩

/-- Complex scalars are conjugated: if `y` represents `φ`, then the representer of `a • φ`
is `conj a • y`, not `a • y`. -/
theorem representer_of_scaled_functional (φ : StrongDual 𝕜 E) (y : E)
    (hy : ∀ x : E, φ x = ⟪y, x⟫_𝕜) (a : 𝕜) :
    ∀ x : E, (a • φ) x = ⟪conj a • y, x⟫_𝕜 := by
  intro x
  rw [smul_apply, hy x, inner_smul_left, RCLike.conj_conj, smul_eq_mul]

end General

/-! The card's worked numbers. The clip is 2, −1, 3, 1 Pa, four samples `Δt = 1/4` s apart.
The meter keeps half its old value and adds half of each new sample. -/

-- The meter's run on the clip: 0 → 1 → 0 → 3/2 → 5/4, final reading 5/4 Pa.
example : ([2, -1, 3, 1] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 = 5 / 4 := by norm_num
-- Probing each lone sample gives the weights 1/16, 1/8, 1/4, 1/2.
example : ([1, 0, 0, 0] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 = 1 / 16 ∧
    ([0, 1, 0, 0] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 = 1 / 8 ∧
    ([0, 0, 1, 0] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 = 1 / 4 ∧
    ([0, 0, 0, 1] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 = 1 / 2 := by norm_num
-- Dividing by Δt = 1/4 gives the shape 1/4, 1/2, 1, 2.
example : (1 / 16 : ℚ) / (1 / 4) = 1 / 4 ∧ (1 / 8 : ℚ) / (1 / 4) = 1 / 2 ∧
    (1 / 4 : ℚ) / (1 / 4) = 1 ∧ (1 / 2 : ℚ) / (1 / 4) = 2 := by norm_num
-- The meter equals the overlap with that shape on every four-sample clip.
example (x₀ x₁ x₂ x₃ : ℚ) :
    ([x₀, x₁, x₂, x₃] : List ℚ).foldl (fun m s => m / 2 + s / 2) 0 =
      (1 / 4) * ((1 / 4) * x₀ + (1 / 2) * x₁ + 1 * x₂ + 2 * x₃) := by
  norm_num; ring
-- The overlap with the clip: 1/4 × (1/4·2 − 1/2·1 + 1·3 + 2·1) = 5/4 Pa.
example : (1 / 4 : ℚ) * ((1 / 4) * 2 + (1 / 2) * (-1) + 1 * 3 + 2 * 1) = 5 / 4 := by norm_num
-- The meter's size squared: ‖y‖² = 1/4 × (1/16 + 1/4 + 1 + 4) = 85/64.
example : (1 / 4 : ℚ) * ((1 / 4) ^ 2 + (1 / 2) ^ 2 + 1 ^ 2 + 2 ^ 2) = 85 / 64 := by norm_num
-- The miss z = (8, 16, 32, 64)/85: the meter reads it as 1/2 and ‖z‖² = 16/85.
example : (1 / 16 : ℚ) * (8 / 85) + (1 / 8) * (16 / 85) + (1 / 4) * (32 / 85) +
    (1 / 2) * (64 / 85) = 1 / 2 := by norm_num
example : (1 / 4 : ℚ) * ((8 / 85) ^ 2 + (16 / 85) ^ 2 + (32 / 85) ^ 2 + (64 / 85) ^ 2) =
    16 / 85 := by norm_num
-- z is perpendicular to the silent clips: the silent clip e₀ − (1/8)·e₃ reads 0 and meets z at a right angle.
example : (1 / 16 : ℚ) * 1 + (1 / 2) * (-(1 / 8)) = 0 ∧
    (1 / 4 : ℚ) * (1 * (8 / 85) + (-(1 / 8)) * (64 / 85)) = 0 := by norm_num
-- The representer (conj φ(z) / ‖z‖²) · z = (85/32) · z = (1/4, 1/2, 1, 2).
example : (1 / 2 : ℚ) / (16 / 85) = 85 / 32 ∧
    (85 / 32 : ℚ) * (8 / 85) = 1 / 4 ∧ (85 / 32 : ℚ) * (16 / 85) = 1 / 2 ∧
    (85 / 32 : ℚ) * (32 / 85) = 1 ∧ (85 / 32 : ℚ) * (64 / 85) = 2 := by norm_num
-- Mistake, the plain sum without Δt: 5 Pa, not 5/4.
example : (1 / 4 : ℚ) * 2 + (1 / 2) * (-1) + 1 * 3 + 2 * 1 = 5 := by norm_num
-- The 1 Hz coefficient: conj f₁ at t = 0, 1/4, 1/2, 3/4 is 1, −i, −1, i,
-- so c₁(clip) = 1/4 × (2 − (−i) − 3 + i) = −1/4 + i/2.
example : (1 / 4 : ℂ) * (2 * 1 + (-1) * (-Complex.I) + 3 * (-1) + 1 * Complex.I) =
    -1 / 4 + Complex.I / 2 := by ring
-- The reading i·c₁ is −1/2 − i/4; its representer −i·f₁ gives conj(−i)·c₁ = −1/2 − i/4.
example : Complex.I * (-1 / 4 + Complex.I / 2) = -1 / 2 - Complex.I / 4 := by
  ring_nf; rw [Complex.I_sq]; ring
example : conj (-Complex.I) * (-1 / 4 + Complex.I / 2) = -1 / 2 - Complex.I / 4 := by
  rw [map_neg, Complex.conj_I]; ring_nf; rw [Complex.I_sq]; ring
-- Mistake, the shape i·f₁ gives conj(i)·c₁ = 1/2 + i/4 instead.
example : conj Complex.I * (-1 / 4 + Complex.I / 2) = 1 / 2 + Complex.I / 4 := by
  rw [Complex.conj_I]; ring_nf; rw [Complex.I_sq]; ring

#print axioms riesz_representation
#print axioms hilbert_space_conjugate_isometric_to_dual
#print axioms representer_of_scaled_functional
