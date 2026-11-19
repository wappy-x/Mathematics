-- Frenet-Serret frame: on any open stretch of a unit-speed space curve with three continuous derivatives and nonzero curvature, the frame T, N, B = T × N is orthonormal and turns only at the rates κ and τ, by T' = κN, N' = −κT + τB, B' = −τN, which is the spin ω = τT + κB crossed with each axis.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.LinearAlgebra.Matrix.DotProduct

/-! A point or arrow in space is a list of three real numbers, `v : Fin 3 → ℝ`, and
`![a, b, c]` is the arrow `(a, b, c)`. Mathlib's `u ⨯₃ v` (`crossProduct`) is the cross
product and `u ⬝ᵥ v` the dot product. The track is `r : ℝ → (Fin 3 → ℝ)`, labelled by `s`,
the metres of rail, on an open stretch `I`. Labelling by metres means unit speed:
`r' · r' = 1`, which also makes the curve regular. Then `T = r'` is the forward axis,
`κ = |T'|` the curvature, `N = T'/κ` the inward axis, `B = T × N` the third axis and
`τ = −B' · N` the torsion, exactly as the card defines them. Curvature not zero is
`T' = r'' ≠ 0`. -/

open Matrix

/-- A product rule for the dot product of two moving arrows. -/
lemma fs_hasDerivAt_dot {f g : ℝ → Fin 3 → ℝ} {f' g' : Fin 3 → ℝ} {s : ℝ}
    (hf : HasDerivAt f f' s) (hg : HasDerivAt g g' s) :
    HasDerivAt (fun t => f t ⬝ᵥ g t) (f' ⬝ᵥ g s + f s ⬝ᵥ g') s := by
  rw [hasDerivAt_pi] at hf hg
  have h : HasDerivAt (fun t => f t 0 * g t 0 + f t 1 * g t 1 + f t 2 * g t 2)
      ((f' 0 * g s 0 + f s 0 * g' 0) + (f' 1 * g s 1 + f s 1 * g' 1)
        + (f' 2 * g s 2 + f s 2 * g' 2)) s :=
    HasDerivAt.add (HasDerivAt.add (HasDerivAt.fun_mul (hf 0) (hg 0))
      (HasDerivAt.fun_mul (hf 1) (hg 1))) (HasDerivAt.fun_mul (hf 2) (hg 2))
  simp only [dotProduct, Fin.sum_univ_three]
  convert h using 1
  ring

/-- A product rule for the cross product of two moving arrows. -/
lemma fs_hasDerivAt_cross {f g : ℝ → Fin 3 → ℝ} {f' g' : Fin 3 → ℝ} {s : ℝ}
    (hf : HasDerivAt f f' s) (hg : HasDerivAt g g' s) :
    HasDerivAt (fun t => f t ⨯₃ g t) (f' ⨯₃ g s + f s ⨯₃ g') s := by
  rw [hasDerivAt_pi] at hf hg ⊢
  intro i
  fin_cases i
  · have h : HasDerivAt (fun t => f t 1 * g t 2 - f t 2 * g t 1)
        ((f' 1 * g s 2 + f s 1 * g' 2) - (f' 2 * g s 1 + f s 2 * g' 1)) s :=
      HasDerivAt.sub (HasDerivAt.fun_mul (hf 1) (hg 2)) (HasDerivAt.fun_mul (hf 2) (hg 1))
    simp only [cross_apply, Fin.zero_eta, Fin.isValue, Pi.add_apply, cons_val_zero]
    convert h using 1
    ring
  · have h : HasDerivAt (fun t => f t 2 * g t 0 - f t 0 * g t 2)
        ((f' 2 * g s 0 + f s 2 * g' 0) - (f' 0 * g s 2 + f s 0 * g' 2)) s :=
      HasDerivAt.sub (HasDerivAt.fun_mul (hf 2) (hg 0)) (HasDerivAt.fun_mul (hf 0) (hg 2))
    simp only [cross_apply, Fin.mk_one, Fin.isValue, Pi.add_apply, cons_val_one, cons_val_zero]
    convert h using 1
    ring
  · have h : HasDerivAt (fun t => f t 0 * g t 1 - f t 1 * g t 0)
        ((f' 0 * g s 1 + f s 0 * g' 1) - (f' 1 * g s 0 + f s 1 * g' 0)) s :=
      HasDerivAt.sub (HasDerivAt.fun_mul (hf 0) (hg 1)) (HasDerivAt.fun_mul (hf 1) (hg 0))
    simp only [cross_apply, Fin.reduceFinMk, Fin.isValue, Pi.add_apply, cons_val_two,
      tail_cons, head_cons]
    convert h using 1
    ring

/-- A quantity that is constant on an open set has derivative zero there. -/
lemma fs_deriv_eq_zero_of_const {φ : ℝ → ℝ} {φ' : ℝ} {I : Set ℝ} (hI : IsOpen I) {s : ℝ}
    (hs : s ∈ I) (c : ℝ) (hc : ∀ t ∈ I, φ t = c) (h : HasDerivAt φ φ' s) : φ' = 0 :=
  h.unique ((hasDerivAt_const s c).congr_of_eventuallyEq
    (Filter.eventually_of_mem (hI.mem_nhds hs) hc))

lemma fs_dot_self_pos (v : Fin 3 → ℝ) (hv : v ≠ 0) : 0 < v ⬝ᵥ v := by
  have h0 : 0 ≤ v ⬝ᵥ v := by
    simp only [dotProduct, Fin.sum_univ_three]
    nlinarith [mul_self_nonneg (v 0), mul_self_nonneg (v 1), mul_self_nonneg (v 2)]
  exact lt_of_le_of_ne h0 (fun h => hv (dotProduct_self_eq_zero.mp h.symm))

lemma fs_gram (a b c v : Fin 3 → ℝ) :
    (a ⬝ᵥ b ⨯₃ c) • v = (v ⬝ᵥ b ⨯₃ c) • a + (v ⬝ᵥ c ⨯₃ a) • b + (v ⬝ᵥ a ⨯₃ b) • c := by
  ext i
  fin_cases i <;> simp [cross_apply, dotProduct, Fin.sum_univ_three] <;> ring

lemma fs_cross_cross (u v w : Fin 3 → ℝ) : u ⨯₃ (v ⨯₃ w) = (u ⬝ᵥ w) • v - (u ⬝ᵥ v) • w := by
  ext i
  fin_cases i <;> simp [cross_apply, dotProduct, Fin.sum_univ_three] <;> ring

lemma fs_cross_dot_self (u v : Fin 3 → ℝ) :
    (u ⨯₃ v) ⬝ᵥ (u ⨯₃ v) = (u ⬝ᵥ u) * (v ⬝ᵥ v) - (u ⬝ᵥ v) ^ 2 := by
  simp [cross_apply, dotProduct, Fin.sum_univ_three]
  ring

/-- Two unit arrows square to each other, with `B = T × N`, make a right-handed frame,
and every arrow is the sum of its parts along the three axes. -/
lemma fs_frame_alg (T N : Fin 3 → ℝ) (hT : T ⬝ᵥ T = 1) (hN : N ⬝ᵥ N = 1)
    (hTN : T ⬝ᵥ N = 0) :
    (T ⨯₃ N) ⬝ᵥ (T ⨯₃ N) = 1 ∧ T ⬝ᵥ (T ⨯₃ N) = 0 ∧ N ⬝ᵥ (T ⨯₃ N) = 0 ∧
    N ⨯₃ (T ⨯₃ N) = T ∧ (T ⨯₃ N) ⨯₃ T = N ∧
    ∀ v, v = (v ⬝ᵥ T) • T + (v ⬝ᵥ N) • N + (v ⬝ᵥ (T ⨯₃ N)) • (T ⨯₃ N) := by
  have hNB : N ⨯₃ (T ⨯₃ N) = T := by
    rw [fs_cross_cross, hN, dotProduct_comm N T, hTN]
    simp
  have hBT : (T ⨯₃ N) ⨯₃ T = N := by
    rw [← cross_anticomm T (T ⨯₃ N), fs_cross_cross, hTN, hT]
    simp
  refine ⟨?_, dot_self_cross T N, dot_cross_self T N, hNB, hBT, ?_⟩
  · rw [fs_cross_dot_self, hT, hN, hTN]
    norm_num
  · intro v
    have g := fs_gram T N (T ⨯₃ N) v
    rw [hNB, hBT, hT, one_smul] at g
    exact g

/-- The whole Frenet-Serret package for a moving unit arrow `T` whose turn `T'` is never
zero on the open stretch `I`. -/
lemma fs_main (T : ℝ → Fin 3 → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hT : ∀ s ∈ I, DifferentiableAt ℝ T s)
    (hT2 : ∀ s ∈ I, DifferentiableAt ℝ (deriv T) s)
    (hunit : ∀ s ∈ I, T s ⬝ᵥ T s = 1)
    (hκ : ∀ s ∈ I, deriv T s ≠ 0) (s : ℝ) (hs : s ∈ I) :
    let κ : ℝ → ℝ := fun s => Real.sqrt (deriv T s ⬝ᵥ deriv T s)
    let N : ℝ → Fin 3 → ℝ := fun s => (κ s)⁻¹ • deriv T s
    let B : ℝ → Fin 3 → ℝ := fun s => T s ⨯₃ N s
    let τ : ℝ → ℝ := fun s => -(deriv B s ⬝ᵥ N s)
    (0 < κ s ∧ T s ⬝ᵥ T s = 1 ∧ N s ⬝ᵥ N s = 1 ∧ B s ⬝ᵥ B s = 1 ∧
      T s ⬝ᵥ N s = 0 ∧ T s ⬝ᵥ B s = 0 ∧ N s ⬝ᵥ B s = 0 ∧
      N s ⨯₃ B s = T s ∧ B s ⨯₃ T s = N s) ∧
    (deriv T s = κ s • N s ∧ deriv N s = -κ s • T s + τ s • B s ∧
      deriv B s = -τ s • N s) := by
  intro κ N B τ
  -- `T · T' = 0` everywhere on `I`, from `T · T = 1`.
  have hTT' : ∀ t ∈ I, T t ⬝ᵥ deriv T t = 0 := by
    intro t ht
    have d := (hT t ht).hasDerivAt
    have h0 := fs_deriv_eq_zero_of_const hI ht 1 (hunit) (fs_hasDerivAt_dot d d)
    rw [dotProduct_comm (deriv T t) (T t)] at h0
    linarith
  have hpos : ∀ t ∈ I, 0 < deriv T t ⬝ᵥ deriv T t := fun t ht => fs_dot_self_pos _ (hκ t ht)
  have hκpos : ∀ t ∈ I, 0 < κ t := fun t ht => Real.sqrt_pos.mpr (hpos t ht)
  have hκsq : ∀ t ∈ I, κ t * κ t = deriv T t ⬝ᵥ deriv T t :=
    fun t ht => Real.mul_self_sqrt (hpos t ht).le
  have hNN : ∀ t ∈ I, N t ⬝ᵥ N t = 1 := by
    intro t ht
    show ((κ t)⁻¹ • deriv T t) ⬝ᵥ ((κ t)⁻¹ • deriv T t) = 1
    rw [smul_dotProduct, dotProduct_smul, ← hκsq t ht, smul_eq_mul, smul_eq_mul]
    have := (hκpos t ht).ne'
    field_simp
  have hTN : ∀ t ∈ I, T t ⬝ᵥ N t = 0 := by
    intro t ht
    show T t ⬝ᵥ ((κ t)⁻¹ • deriv T t) = 0
    rw [dotProduct_smul, hTT' t ht, smul_zero]
  have hfr : ∀ t ∈ I, _ := fun t ht => fs_frame_alg (T t) (N t) (hunit t ht) (hNN t ht) (hTN t ht)
  have hT'eq : ∀ t ∈ I, deriv T t = κ t • N t := by
    intro t ht
    show deriv T t = κ t • ((κ t)⁻¹ • deriv T t)
    rw [smul_smul, mul_inv_cancel₀ (hκpos t ht).ne', one_smul]
  -- Differentiability of κ, N and B at `s`.
  have dT := (hT s hs).hasDerivAt
  have dT2 := (hT2 s hs).hasDerivAt
  have dκ : DifferentiableAt ℝ κ s :=
    ((fs_hasDerivAt_dot dT2 dT2).sqrt (hpos s hs).ne').differentiableAt
  have dN : HasDerivAt N (deriv N s) s :=
    ((dκ.inv (hκpos s hs).ne').smul (hT2 s hs)).hasDerivAt
  have dB : HasDerivAt B (deriv B s) s :=
    (fs_hasDerivAt_cross dT dN).differentiableAt.hasDerivAt
  obtain ⟨hBB, hTB, hNB, hNxB, hBxT, hdec⟩ := hfr s hs
  -- Differentiate the five constant dot products.
  have e1 := fs_deriv_eq_zero_of_const hI hs 0 hTN (fs_hasDerivAt_dot dT dN)
  have e2 := fs_deriv_eq_zero_of_const hI hs 1 hNN (fs_hasDerivAt_dot dN dN)
  have e3 := fs_deriv_eq_zero_of_const hI hs 0 (fun t ht => (hfr t ht).2.2.1)
    (fs_hasDerivAt_dot dN dB)
  have e4 := fs_deriv_eq_zero_of_const hI hs 0 (fun t ht => (hfr t ht).2.1)
    (fs_hasDerivAt_dot dT dB)
  have e5 := fs_deriv_eq_zero_of_const hI hs 1 (fun t ht => (hfr t ht).1)
    (fs_hasDerivAt_dot dB dB)
  have hT's := hT'eq s hs
  refine ⟨⟨hκpos s hs, hunit s hs, hNN s hs, hBB, hTN s hs, hTB, hNB, hNxB, hBxT⟩,
    hT's, ?_, ?_⟩
  · have a1 : deriv N s ⬝ᵥ T s = -κ s := by
      rw [hT's, smul_dotProduct, hNN s hs, smul_eq_mul, mul_one] at e1
      rw [dotProduct_comm]
      linarith
    have a2 : deriv N s ⬝ᵥ N s = 0 := by
      rw [dotProduct_comm (N s)] at e2
      linarith
    have a3 : deriv N s ⬝ᵥ B s = τ s := by
      have hτ : τ s = -(deriv B s ⬝ᵥ N s) := rfl
      rw [hτ, dotProduct_comm (deriv B s)]
      linarith
    conv_lhs => rw [hdec (deriv N s)]
    rw [a1, a2, a3, zero_smul, add_zero]
  · have b1 : deriv B s ⬝ᵥ T s = 0 := by
      rw [hT's, smul_dotProduct, hNB, smul_zero] at e4
      rw [dotProduct_comm]
      linarith
    have b2 : deriv B s ⬝ᵥ N s = -τ s := by
      have hτ : τ s = -(deriv B s ⬝ᵥ N s) := rfl
      rw [hτ, neg_neg]
    have b3 : deriv B s ⬝ᵥ B s = 0 := by
      rw [dotProduct_comm (B s)] at e5
      linarith
    conv_lhs => rw [hdec (deriv B s)]
    rw [b1, b2, b3, zero_smul, zero_smul, zero_add, add_zero]

/-- Three continuous derivatives on an open stretch: the first and second derivatives can
both be differentiated at every point of the stretch. -/
lemma fs_diff (r : ℝ → Fin 3 → ℝ) (I : Set ℝ) (hI : IsOpen I) (hr : ContDiffOn ℝ 3 r I) :
    (∀ s ∈ I, DifferentiableAt ℝ (deriv r) s) ∧
      (∀ s ∈ I, DifferentiableAt ℝ (deriv (deriv r)) s) := by
  have h2 : ContDiffOn ℝ 2 (deriv r) I := hr.deriv_of_isOpen hI (by norm_num)
  have h1 : ContDiffOn ℝ 1 (deriv (deriv r)) I := h2.deriv_of_isOpen hI (by norm_num)
  exact ⟨fun s hs => (h2.contDiffAt (hI.mem_nhds hs)).differentiableAt (by norm_num),
    fun s hs => (h1.contDiffAt (hI.mem_nhds hs)).differentiableAt (by norm_num)⟩

lemma fs_add_smul_cross (a b : ℝ) (u v w : Fin 3 → ℝ) :
    (a • u + b • v) ⨯₃ w = a • (u ⨯₃ w) + b • (v ⨯₃ w) := by
  ext i
  fin_cases i <;> simp [cross_apply]

#print axioms fs_hasDerivAt_dot
#print axioms fs_hasDerivAt_cross
#print axioms fs_deriv_eq_zero_of_const
#print axioms fs_dot_self_pos
#print axioms fs_gram
#print axioms fs_cross_cross
#print axioms fs_cross_dot_self
#print axioms fs_frame_alg
#print axioms fs_main
#print axioms fs_diff
#print axioms fs_add_smul_cross

/-- The Frenet-Serret equations. On an open stretch where the track has three continuous
derivatives, is labelled by metres of rail (unit speed, so regular) and has curvature not zero,
the forward axis turns towards the inward axis at rate κ, the inward axis turns back towards
the forward axis at κ and towards the third axis at τ, and the third axis turns back towards
the inward axis at τ: `T' = κN`, `N' = −κT + τB`, `B' = −τN`. -/
theorem frenet_serret_equations (r : ℝ → Fin 3 → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hr : ContDiffOn ℝ 3 r I)
    (hunit : ∀ s ∈ I, deriv r s ⬝ᵥ deriv r s = 1)
    (hκ : ∀ s ∈ I, deriv (deriv r) s ≠ 0) :
    let T := deriv r
    let κ : ℝ → ℝ := fun s => Real.sqrt (deriv T s ⬝ᵥ deriv T s)
    let N : ℝ → Fin 3 → ℝ := fun s => (κ s)⁻¹ • deriv T s
    let B : ℝ → Fin 3 → ℝ := fun s => T s ⨯₃ N s
    let τ : ℝ → ℝ := fun s => -(deriv B s ⬝ᵥ N s)
    ∀ s ∈ I, deriv T s = κ s • N s ∧
      deriv N s = -κ s • T s + τ s • B s ∧
      deriv B s = -τ s • N s := by
  intro T κ N B τ s hs
  obtain ⟨hd1, hd2⟩ := fs_diff r I hI hr
  exact (fs_main (deriv r) I hI hd1 hd2 hunit hκ s hs).2

/-- The frame is a frame. Under the same conditions, T, N and B are unit arrows, each square
to the other two, and they are right-handed in the order T, N, B (`B = T × N`, so also
`N × B = T` and `B × T = N`), and the curvature κ is positive. -/
theorem frenet_frame_orthonormal (r : ℝ → Fin 3 → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hr : ContDiffOn ℝ 3 r I)
    (hunit : ∀ s ∈ I, deriv r s ⬝ᵥ deriv r s = 1)
    (hκ : ∀ s ∈ I, deriv (deriv r) s ≠ 0) :
    let T := deriv r
    let κ : ℝ → ℝ := fun s => Real.sqrt (deriv T s ⬝ᵥ deriv T s)
    let N : ℝ → Fin 3 → ℝ := fun s => (κ s)⁻¹ • deriv T s
    let B : ℝ → Fin 3 → ℝ := fun s => T s ⨯₃ N s
    ∀ s ∈ I, 0 < κ s ∧
      T s ⬝ᵥ T s = 1 ∧ N s ⬝ᵥ N s = 1 ∧ B s ⬝ᵥ B s = 1 ∧
      T s ⬝ᵥ N s = 0 ∧ T s ⬝ᵥ B s = 0 ∧ N s ⬝ᵥ B s = 0 ∧
      N s ⨯₃ B s = T s ∧ B s ⨯₃ T s = N s := by
  intro T κ N B s hs
  obtain ⟨hd1, hd2⟩ := fs_diff r I hI hr
  exact (fs_main (deriv r) I hI hd1 hd2 hunit hκ s hs).1

/-- The spin vector form. Under the same conditions, put `ω = τT + κB`. Then each axis
changes by `ω` crossed with itself: `T' = ω × T`, `N' = ω × N`, `B' = ω × B`. Per metre of
rail the frame turns as one rigid body, by τ about the forward axis, κ about the third axis
and never about the inward axis. -/
theorem frenet_frame_turns_by_spin_vector (r : ℝ → Fin 3 → ℝ) (I : Set ℝ)
    (hI : IsOpen I) (hr : ContDiffOn ℝ 3 r I)
    (hunit : ∀ s ∈ I, deriv r s ⬝ᵥ deriv r s = 1)
    (hκ : ∀ s ∈ I, deriv (deriv r) s ≠ 0) :
    let T := deriv r
    let κ : ℝ → ℝ := fun s => Real.sqrt (deriv T s ⬝ᵥ deriv T s)
    let N : ℝ → Fin 3 → ℝ := fun s => (κ s)⁻¹ • deriv T s
    let B : ℝ → Fin 3 → ℝ := fun s => T s ⨯₃ N s
    let τ : ℝ → ℝ := fun s => -(deriv B s ⬝ᵥ N s)
    let ω : ℝ → Fin 3 → ℝ := fun s => τ s • T s + κ s • B s
    ∀ s ∈ I, deriv T s = ω s ⨯₃ T s ∧ deriv N s = ω s ⨯₃ N s ∧
      deriv B s = ω s ⨯₃ B s := by
  intro T κ N B τ ω s hs
  obtain ⟨hd1, hd2⟩ := fs_diff r I hI hr
  have key : (0 < κ s ∧ T s ⬝ᵥ T s = 1 ∧ N s ⬝ᵥ N s = 1 ∧ B s ⬝ᵥ B s = 1 ∧
      T s ⬝ᵥ N s = 0 ∧ T s ⬝ᵥ B s = 0 ∧ N s ⬝ᵥ B s = 0 ∧
      N s ⨯₃ B s = T s ∧ B s ⨯₃ T s = N s) ∧
      (deriv T s = κ s • N s ∧ deriv N s = -κ s • T s + τ s • B s ∧
        deriv B s = -τ s • N s) :=
    fs_main (deriv r) I hI hd1 hd2 hunit hκ s hs
  obtain ⟨⟨-, -, -, -, -, -, -, hNxB, hBxT⟩, h1, h2, h3⟩ := key
  have hω : ω s = τ s • T s + κ s • B s := rfl
  have hTxN : T s ⨯₃ N s = B s := rfl
  refine ⟨?_, ?_, ?_⟩
  · rw [h1, hω, fs_add_smul_cross, cross_self, hBxT, smul_zero, zero_add]
  · rw [h2, hω, fs_add_smul_cross, hTxN, ← cross_anticomm (N s) (B s), hNxB, smul_neg,
      neg_smul]
    abel
  · rw [h3, hω, fs_add_smul_cross, cross_self, ← cross_anticomm (B s) (T s), hBxT, smul_zero,
      add_zero, smul_neg, neg_smul]

-- The worked point t = 1 on r(t) = 15 (t, t²/2, t³/3): position (15, 7.5, 5) m.
example : (15 : ℚ) * 1 = 15 ∧ (15 : ℚ) * (1 ^ 2 / 2) = 15 / 2 ∧ (15 : ℚ) * (1 ^ 3 / 3) = 5 := by
  norm_num
-- Before scaling to length 1: T along (1, 1, 1) and N along (−1, 0, 1), so B = T × N
-- is along (1, −2, 1), square to both.
example : (![1, 1, 1] : Fin 3 → ℤ) ⨯₃ ![-1, 0, 1] = ![1, -2, 1] := by
  simp [cross_apply]
example : (![1, 1, 1] : Fin 3 → ℤ) ⬝ᵥ ![-1, 0, 1] = 0 ∧
    (![1, -2, 1] : Fin 3 → ℤ) ⬝ᵥ ![1, 1, 1] = 0 ∧
    (![1, -2, 1] : Fin 3 → ℤ) ⬝ᵥ ![-1, 0, 1] = 0 := by
  simp [dotProduct, Fin.sum_univ_three]
-- Step 5: dr/dt × d²r/dt² = 15 (1, 1, 1) × 15 (0, 1, 2) = 15² (1, −2, 1) at t = 1.
example : (![15, 15, 15] : Fin 3 → ℤ) ⨯₃ ![0, 15, 30] = ![225, -450, 225] := by
  simp [cross_apply]
-- Closed forms at t = 1: κ² = (t⁴ + 4t² + 1)/(15² (1 + t² + t⁴)³) = 2/2025 (κ = √2/45)
-- and τ = 2/(15 (t⁴ + 4t² + 1)) = 1/45.
example : ((1 : ℚ) ^ 4 + 4 * 1 ^ 2 + 1) / (15 ^ 2 * (1 + 1 ^ 2 + 1 ^ 4) ^ 3) = 2 / 2025 := by
  norm_num
example : (2 : ℚ) / (15 * (1 ^ 4 + 4 * 1 ^ 2 + 1)) = 1 / 45 := by norm_num
-- At 15 m/s: the rig's spin squared V²(κ² + τ²) is 1/3 (spin 1/√3 rad/s), the roll τV is
-- 1/3 rad/s, and the push towards N, κV², squared is 50 (so 5√2 m/s²).
example : (15 : ℚ) ^ 2 * (2 / 2025 + (1 / 45) ^ 2) = 1 / 3 := by norm_num
example : (1 / 45 : ℚ) * 15 = 1 / 3 := by norm_num
example : (2 / 2025 : ℚ) * (15 ^ 2) ^ 2 = 50 := by norm_num

#print axioms frenet_serret_equations
#print axioms frenet_frame_orthonormal
#print axioms frenet_frame_turns_by_spin_vector
