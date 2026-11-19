-- Torsion: a unit-speed space curve whose curvature and torsion are constant, with curvature above 0, is a helix of radius κ/(κ² + τ²) climbing τ/(κ² + τ²) per radian, a helix has curvature a/(a² + c²) and torsion c/(a² + c²), and torsion keeps its sign when the travel is reversed and flips it in a mirror.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.Module
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

/-! A point or arrow in space is a list of three real numbers, `v : Fin 3 → ℝ`, and
`![a, b, c]` is the arrow `(a, b, c)`. Mathlib's `u ⨯₃ v` (`crossProduct`) is the cross
product and `u ⬝ᵥ v` the dot product. The rail is `r : ℝ → (Fin 3 → ℝ)`, labelled by `s`,
the metres travelled along it. As on the card: `T = r'` is the direction of travel,
`κ = |T'|` the curvature, `N = T'/κ` the normal, `B = T × N` the binormal and
`τ = −B' · N` the torsion. A right-handed helix has `τ > 0`. -/

open Matrix Real

/-- Curvature `κ = |T'|`, with `T = r'`. -/
noncomputable def curvature (r : ℝ → Fin 3 → ℝ) (s : ℝ) : ℝ :=
  Real.sqrt (deriv (deriv r) s ⬝ᵥ deriv (deriv r) s)

/-- The normal `N = T'/κ`. -/
noncomputable def normal (r : ℝ → Fin 3 → ℝ) (s : ℝ) : Fin 3 → ℝ :=
  (curvature r s)⁻¹ • deriv (deriv r) s

/-- The binormal `B = T × N`. -/
noncomputable def binormal (r : ℝ → Fin 3 → ℝ) (s : ℝ) : Fin 3 → ℝ :=
  deriv r s ⨯₃ normal r s

/-- Torsion, `τ = −B' · N`, the card's sign: `B' = −τN`. -/
noncomputable def torsion (r : ℝ → Fin 3 → ℝ) (s : ℝ) : ℝ :=
  -(deriv (binormal r) s ⬝ᵥ normal r s)


lemma hasDerivAt_cross3 {u v : ℝ → Fin 3 → ℝ} {u' v' : Fin 3 → ℝ} {x : ℝ}
    (hu : HasDerivAt u u' x) (hv : HasDerivAt v v' x) :
    HasDerivAt (fun y => u y ⨯₃ v y) (u' ⨯₃ v x + u x ⨯₃ v') x := by
  rw [hasDerivAt_pi] at hu hv ⊢
  intro i
  fin_cases i
  · show HasDerivAt (fun y => u y 1 * v y 2 - u y 2 * v y 1)
      (u' 1 * v x 2 - u' 2 * v x 1 + (u x 1 * v' 2 - u x 2 * v' 1)) x
    convert ((hu 1).fun_mul (hv 2)).fun_sub ((hu 2).fun_mul (hv 1)) using 1
    ring
  · show HasDerivAt (fun y => u y 2 * v y 0 - u y 0 * v y 2)
      (u' 2 * v x 0 - u' 0 * v x 2 + (u x 2 * v' 0 - u x 0 * v' 2)) x
    convert ((hu 2).fun_mul (hv 0)).fun_sub ((hu 0).fun_mul (hv 2)) using 1
    ring
  · show HasDerivAt (fun y => u y 0 * v y 1 - u y 1 * v y 0)
      (u' 0 * v x 1 - u' 1 * v x 0 + (u x 0 * v' 1 - u x 1 * v' 0)) x
    convert ((hu 0).fun_mul (hv 1)).fun_sub ((hu 1).fun_mul (hv 0)) using 1
    ring

lemma hasDerivAt_dot3 {u v : ℝ → Fin 3 → ℝ} {u' v' : Fin 3 → ℝ} {x : ℝ}
    (hu : HasDerivAt u u' x) (hv : HasDerivAt v v' x) :
    HasDerivAt (fun y => u y ⬝ᵥ v y) (u' ⬝ᵥ v x + u x ⬝ᵥ v') x := by
  rw [hasDerivAt_pi] at hu hv
  simp only [vec3_dotProduct]
  convert (((hu 0).fun_mul (hv 0)).fun_add ((hu 1).fun_mul (hv 1))).fun_add ((hu 2).fun_mul (hv 2)) using 1
  ring

lemma hasDerivAt_mirror3 {f : ℝ → Fin 3 → ℝ} {f' : Fin 3 → ℝ} {x : ℝ}
    (hf : HasDerivAt f f' x) :
    HasDerivAt (fun y => ![-(f y 0), f y 1, f y 2]) ![-(f' 0), f' 1, f' 2] x := by
  rw [hasDerivAt_pi] at hf ⊢
  intro i
  fin_cases i
  · simpa using (hf 0).fun_neg
  · simpa using hf 1
  · simpa using hf 2

lemma deriv_mirror3 (f : ℝ → Fin 3 → ℝ) (x : ℝ) :
    deriv (fun y => ![-(f y 0), f y 1, f y 2]) x
      = ![-(deriv f x 0), deriv f x 1, deriv f x 2] := by
  by_cases h : DifferentiableAt ℝ f x
  · exact (hasDerivAt_mirror3 h.hasDerivAt).deriv
  · have h2 : ¬ DifferentiableAt ℝ (fun y => ![-(f y 0), f y 1, f y 2]) x := by
      intro h2
      apply h
      have h3 := (hasDerivAt_mirror3 h2.hasDerivAt).differentiableAt
      convert h3 using 1
      funext y i
      fin_cases i <;> simp
    rw [deriv_zero_of_not_differentiableAt h, deriv_zero_of_not_differentiableAt h2]
    ext i; fin_cases i <;> simp

lemma mirror_cross3 (u v : Fin 3 → ℝ) :
    ![-(u 0), u 1, u 2] ⨯₃ ![-(v 0), v 1, v 2]
      = -![-((u ⨯₃ v) 0), (u ⨯₃ v) 1, (u ⨯₃ v) 2] := by
  ext i; fin_cases i <;> simp [cross_apply] <;> ring

lemma mirror_dot3 (u v : Fin 3 → ℝ) :
    ![-(u 0), u 1, u 2] ⬝ᵥ ![-(v 0), v 1, v 2] = u ⬝ᵥ v := by
  simp [vec3_dotProduct]; ring

lemma hasDerivAt_vec3 {f₀ f₁ f₂ : ℝ → ℝ} {d₀ d₁ d₂ x : ℝ}
    (h₀ : HasDerivAt f₀ d₀ x) (h₁ : HasDerivAt f₁ d₁ x) (h₂ : HasDerivAt f₂ d₂ x) :
    HasDerivAt (fun y => ![f₀ y, f₁ y, f₂ y]) ![d₀, d₁, d₂] x := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · exact h₀
  · exact h₁
  · exact h₂

lemma frame_expand (t n v : Fin 3 → ℝ) (htt : t ⬝ᵥ t = 1) (hnn : n ⬝ᵥ n = 1)
    (htn : t ⬝ᵥ n = 0) :
    v = (v ⬝ᵥ t) • t + (v ⬝ᵥ n) • n + (v ⬝ᵥ t ⨯₃ n) • (t ⨯₃ n) := by
  rw [vec3_dotProduct] at htt hnn htn
  ext i
  fin_cases i <;> simp [vec3_dotProduct, cross_apply, Matrix.vecHead, Matrix.vecTail]
  · linear_combination (-((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 0 - n 0 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2))) * htt + (-(v 0 - t 0 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2))) * hnn + (-(t 0 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) + n 0 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2) - (t 0 * n 0 + t 1 * n 1 + t 2 * n 2) * v 0)) * htn
  · linear_combination (-((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 1 - n 1 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2))) * htt + (-(v 1 - t 1 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2))) * hnn + (-(t 1 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) + n 1 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2) - (t 0 * n 0 + t 1 * n 1 + t 2 * n 2) * v 1)) * htn
  · linear_combination (-((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 2 - n 2 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2))) * htt + (-(v 2 - t 2 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2))) * hnn + (-(t 2 * (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) + n 2 * (v 0 * t 0 + v 1 * t 1 + v 2 * t 2) - (t 0 * n 0 + t 1 * n 1 + t 2 * n 2) * v 2)) * htn

lemma triple_aux (t n m : Fin 3 → ℝ) : -((t ⨯₃ m) ⬝ᵥ n) = m ⬝ᵥ (t ⨯₃ n) := by
  simp [vec3_dotProduct, cross_apply, Matrix.vecHead, Matrix.vecTail]
  ring

#print axioms hasDerivAt_cross3
#print axioms hasDerivAt_dot3
#print axioms hasDerivAt_mirror3
#print axioms deriv_mirror3
#print axioms mirror_cross3
#print axioms mirror_dot3
#print axioms hasDerivAt_vec3
#print axioms frame_expand
#print axioms triple_aux

/-- Constant curvature and torsion force a helix. On a stretch of curve (an open interval,
or any open connected piece of the line) where the curve has three continuous derivatives,
is labelled by distance travelled (unit speed), and has constant curvature `κ > 0` and
constant torsion `τ`, the curve is a piece of helix: there is a point `p` on its axis and two
unit arrows `e₁`, `e₂` at right angles, with the axis along `e₁ × e₂`, such that the curve
goes round the axis at radius `a = κ/(κ² + τ²)`, turning `√(κ² + τ²)` radians per metre, and
climbs `c = τ/(κ² + τ²)` per radian turned. -/
theorem constant_curvature_and_torsion_is_helix (r : ℝ → Fin 3 → ℝ) (I : Set ℝ)
    (hI : IsOpen I) (hIc : IsPreconnected I) (hr : ContDiffOn ℝ 3 r I)
    (hunit : ∀ s ∈ I, deriv r s ⬝ᵥ deriv r s = 1)
    (κ τ : ℝ) (hκ : 0 < κ)
    (hcurv : ∀ s ∈ I, curvature r s = κ) (htors : ∀ s ∈ I, torsion r s = τ) :
    ∃ p e₁ e₂ : Fin 3 → ℝ, e₁ ⬝ᵥ e₁ = 1 ∧ e₂ ⬝ᵥ e₂ = 1 ∧ e₁ ⬝ᵥ e₂ = 0 ∧
      ∀ s ∈ I, r s = p
        + (κ / (κ ^ 2 + τ ^ 2)) • (cos (√(κ ^ 2 + τ ^ 2) * s) • e₁
            + sin (√(κ ^ 2 + τ ^ 2) * s) • e₂)
        + (τ / (κ ^ 2 + τ ^ 2) * (√(κ ^ 2 + τ ^ 2) * s)) • (e₁ ⨯₃ e₂) := by
  rcases I.eq_empty_or_nonempty with hIe | ⟨s₀, hs₀⟩
  · refine ⟨0, ![1, 0, 0], ![0, 1, 0], by simp [vec3_dotProduct], by simp [vec3_dotProduct],
      by simp [vec3_dotProduct], ?_⟩
    intro s hs
    rw [hIe] at hs
    exact absurd hs (Set.notMem_empty s)
  have hκne : κ ≠ 0 := hκ.ne'
  have hD : 0 < κ ^ 2 + τ ^ 2 := by positivity
  obtain ⟨ω, hω⟩ : ∃ ω, ω = √(κ ^ 2 + τ ^ 2) := ⟨_, rfl⟩
  rw [← hω]
  have hω2 : ω ^ 2 = κ ^ 2 + τ ^ 2 := by rw [hω]; exact Real.sq_sqrt hD.le
  have hωpos : 0 < ω := by rw [hω]; exact Real.sqrt_pos.2 hD
  have hωne : ω ≠ 0 := hωpos.ne'
  -- the moving frame
  obtain ⟨T, hT⟩ : ∃ T : ℝ → Fin 3 → ℝ, T = deriv r := ⟨_, rfl⟩
  obtain ⟨T', hT'⟩ : ∃ T' : ℝ → Fin 3 → ℝ, T' = deriv T := ⟨_, rfl⟩
  obtain ⟨T'', hT''⟩ : ∃ T'' : ℝ → Fin 3 → ℝ, T'' = deriv T' := ⟨_, rfl⟩
  have hc2 : ContDiffOn ℝ 2 T I := by rw [hT]; exact hr.deriv_of_isOpen hI (by norm_num)
  have hc1 : ContDiffOn ℝ 1 T' I := by rw [hT']; exact hc2.deriv_of_isOpen hI (by norm_num)
  have hdr : ∀ s ∈ I, HasDerivAt r (T s) s := fun s hs => by
    rw [hT]
    exact ((hr.differentiableOn (by norm_num)) s hs |>.differentiableAt
      (hI.mem_nhds hs)).hasDerivAt
  have hdT : ∀ s ∈ I, HasDerivAt T (T' s) s := fun s hs => by
    rw [hT']
    exact ((hc2.differentiableOn (by norm_num)) s hs |>.differentiableAt
      (hI.mem_nhds hs)).hasDerivAt
  have hdT' : ∀ s ∈ I, HasDerivAt T' (T'' s) s := fun s hs => by
    rw [hT'']
    exact ((hc1.differentiableOn (by norm_num)) s hs |>.differentiableAt
      (hI.mem_nhds hs)).hasDerivAt
  have hzero : ∀ (f : ℝ → ℝ) (c d s : ℝ), s ∈ I → (∀ y ∈ I, f y = c) →
      HasDerivAt f d s → d = 0 := by
    intro f c d s hs hf hd
    have h0 : HasDerivAt f 0 s := (hasDerivAt_const s c).congr_of_eventuallyEq
      (Filter.eventually_of_mem (hI.mem_nhds hs) fun y hy => hf y hy)
    exact hd.unique h0
  have hTT : ∀ s ∈ I, T s ⬝ᵥ T s = 1 := by rw [hT]; exact hunit
  have hTT' : ∀ s ∈ I, T s ⬝ᵥ T' s = 0 := by
    intro s hs
    have := hzero _ 1 _ s hs hTT (hasDerivAt_dot3 (hdT s hs) (hdT s hs))
    rw [dotProduct_comm] at this
    linarith
  have hT'T' : ∀ s ∈ I, T' s ⬝ᵥ T' s = κ ^ 2 := by
    intro s hs
    have h := hcurv s hs
    rw [curvature, ← hT, ← hT'] at h
    rw [← h, Real.sq_sqrt]
    rw [vec3_dotProduct]
    exact add_nonneg (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _)) (mul_self_nonneg _)
  have hT'T'' : ∀ s ∈ I, T' s ⬝ᵥ T'' s = 0 := by
    intro s hs
    have := hzero _ (κ ^ 2) _ s hs hT'T' (hasDerivAt_dot3 (hdT' s hs) (hdT' s hs))
    rw [dotProduct_comm] at this
    linarith
  have hTT'' : ∀ s ∈ I, T s ⬝ᵥ T'' s = -κ ^ 2 := by
    intro s hs
    have := hzero _ 0 _ s hs hTT' (hasDerivAt_dot3 (hdT s hs) (hdT' s hs))
    rw [hT'T' s hs] at this
    linarith
  obtain ⟨N, hN⟩ : ∃ N : ℝ → Fin 3 → ℝ, N = fun y => κ⁻¹ • T' y := ⟨_, rfl⟩
  obtain ⟨Nd, hNd⟩ : ∃ Nd : ℝ → Fin 3 → ℝ, Nd = fun y => κ⁻¹ • T'' y := ⟨_, rfl⟩
  obtain ⟨B, hB⟩ : ∃ B : ℝ → Fin 3 → ℝ, B = fun y => T y ⨯₃ N y := ⟨_, rfl⟩
  have hnormal : ∀ y ∈ I, normal r y = N y := by
    intro y hy; rw [normal, hcurv y hy, ← hT, ← hT', hN]
  have hbin : ∀ y ∈ I, binormal r y = B y := by
    intro y hy; rw [binormal, hnormal y hy, ← hT, hB]
  have hT'N : ∀ s, T' s = κ • N s := by
    intro s; rw [hN]; simp [smul_smul, hκne]
  have hdN : ∀ s ∈ I, HasDerivAt N (Nd s) s := by
    intro s hs; rw [hN, hNd]; exact (hdT' s hs).fun_const_smul κ⁻¹
  have hdB0 : ∀ s ∈ I, HasDerivAt B (T s ⨯₃ Nd s) s := by
    intro s hs
    have := hasDerivAt_cross3 (hdT s hs) (hdN s hs)
    rw [hB]
    convert this using 1
    rw [hT'N s]
    simp
  -- frame facts
  have hTN : ∀ s ∈ I, T s ⬝ᵥ N s = 0 := by
    intro s hs; rw [hN]; simp [dotProduct_smul, hTT' s hs]
  have hNN : ∀ s ∈ I, N s ⬝ᵥ N s = 1 := by
    intro s hs; rw [hN]; simp [dotProduct_smul, smul_dotProduct, hT'T' s hs]; field_simp
  have hNdN : ∀ s ∈ I, Nd s ⬝ᵥ N s = 0 := by
    intro s hs; rw [hN, hNd]; simp [dotProduct_smul, smul_dotProduct, dotProduct_comm (T'' s),
      hT'T'' s hs]
  have hNdT : ∀ s ∈ I, Nd s ⬝ᵥ T s = -κ := by
    intro s hs; rw [hNd]; simp [smul_dotProduct, dotProduct_comm (T'' s), hTT'' s hs]
    field_simp
  have hNdB : ∀ s ∈ I, Nd s ⬝ᵥ B s = τ := by
    intro s hs
    have h := htors s hs
    rw [torsion, hnormal s hs] at h
    have hev : binormal r =ᶠ[nhds s] B :=
      Filter.eventually_of_mem (hI.mem_nhds hs) fun y hy => hbin y hy
    rw [hev.deriv_eq, (hdB0 s hs).deriv, triple_aux] at h
    rw [hB, ← h]
  have hFN : ∀ s ∈ I, Nd s = (-κ) • T s + τ • B s := by
    intro s hs
    have h := frame_expand (T s) (N s) (Nd s) (hTT s hs) (hNN s hs) (hTN s hs)
    have hB' : T s ⨯₃ N s = B s := by rw [hB]
    rw [hB', hNdT s hs, hNdN s hs, hNdB s hs, zero_smul, add_zero] at h
    exact h
  have hTB : ∀ s ∈ I, T s ⨯₃ B s = -N s := by
    intro s hs
    rw [hB]
    simp only
    rw [cross_cross_eq_smul_sub_smul', hTT s hs, hTN s hs]
    simp
  have hdN' : ∀ s ∈ I, HasDerivAt N ((-κ) • T s + τ • B s) s := by
    intro s hs; rw [← hFN s hs]; exact hdN s hs
  have hdB : ∀ s ∈ I, HasDerivAt B ((-τ) • N s) s := by
    intro s hs
    convert hdB0 s hs using 1
    rw [hFN s hs]
    simp [hTB s hs]
  have hdT2 : ∀ s ∈ I, HasDerivAt T (κ • N s) s := by
    intro s hs; rw [← hT'N s]; exact hdT s hs
  -- more frame facts
  have hTNB : ∀ s, T s ⨯₃ N s = B s := by intro s; rw [hB]
  have hNT : ∀ s, N s ⨯₃ T s = -B s := by intro s; rw [hB]; exact (cross_anticomm _ _).symm
  have hNB : ∀ s ∈ I, N s ⨯₃ B s = T s := by
    intro s hs; rw [hB]; simp only
    rw [cross_cross_eq_smul_sub_smul', hNN s hs, hTN s hs]; simp
  have hBT : ∀ s ∈ I, B s ⨯₃ T s = N s := by
    intro s hs; rw [← cross_anticomm, hTB s hs, neg_neg]
  have hBN : ∀ s ∈ I, B s ⨯₃ N s = -T s := by
    intro s hs; rw [← cross_anticomm, hNB s hs]
  have hBB : ∀ s ∈ I, B s ⬝ᵥ B s = 1 := by
    intro s hs; rw [hB]; simp only
    rw [cross_dot_cross, hTT s hs, hNN s hs, dotProduct_comm (N s), hTN s hs]; ring
  have hTB0 : ∀ s, T s ⬝ᵥ B s = 0 := by intro s; rw [hB]; exact dot_self_cross _ _
  have hNB0 : ∀ s, N s ⬝ᵥ B s = 0 := by intro s; rw [hB]; exact dot_cross_self _ _
  have hBT0 : ∀ s, B s ⬝ᵥ T s = 0 := by intro s; rw [dotProduct_comm]; exact hTB0 s
  have hBN0 : ∀ s, B s ⬝ᵥ N s = 0 := by intro s; rw [dotProduct_comm]; exact hNB0 s
  have hNT0 : ∀ s ∈ I, N s ⬝ᵥ T s = 0 := by intro s hs; rw [dotProduct_comm]; exact hTN s hs
  -- constants of the helix
  obtain ⟨α, hα⟩ : ∃ α : ℝ, α = κ / ω := ⟨_, rfl⟩
  obtain ⟨β, hβ⟩ : ∃ β : ℝ, β = τ / ω := ⟨_, rfl⟩
  have hαω : α * ω = κ := by rw [hα]; field_simp
  have hβω : β * ω = τ := by rw [hβ]; field_simp
  have hακβτ : α * κ + β * τ = ω := by
    rw [hα, hβ]; field_simp; linear_combination -hω2
  have hαβ : α ^ 2 + β ^ 2 = 1 := by
    rw [hα, hβ]; field_simp; linear_combination -hω2
  have hβκ : β * κ = α * τ := by rw [hα, hβ]; ring
  obtain ⟨k, hk⟩ : ∃ k : ℝ, k = κ / (κ ^ 2 + τ ^ 2) := ⟨_, rfl⟩
  obtain ⟨c, hc⟩ : ∃ c : ℝ, c = τ / (κ ^ 2 + τ ^ 2) := ⟨_, rfl⟩
  rw [← hk, ← hc]
  have hkc : k * κ + c * τ = 1 := by rw [hk, hc]; field_simp
  have hkc2 : k * τ = c * κ := by rw [hk, hc]; ring
  obtain ⟨P, hP⟩ : ∃ P : ℝ → Fin 3 → ℝ, P = fun y => α • T y - β • B y := ⟨_, rfl⟩
  obtain ⟨E₁, hE₁⟩ : ∃ E : ℝ → Fin 3 → ℝ,
      E = fun y => -(cos (ω * y) • N y) - sin (ω * y) • P y := ⟨_, rfl⟩
  obtain ⟨E₂, hE₂⟩ : ∃ E : ℝ → Fin 3 → ℝ,
      E = fun y => -(sin (ω * y) • N y) + cos (ω * y) • P y := ⟨_, rfl⟩
  obtain ⟨E₃, hE₃⟩ : ∃ E : ℝ → Fin 3 → ℝ, E = fun y => β • T y + α • B y := ⟨_, rfl⟩
  obtain ⟨Q, hQ⟩ : ∃ Q : ℝ → Fin 3 → ℝ,
      Q = fun y => r y + k • N y - (c * (ω * y)) • E₃ y := ⟨_, rfl⟩
  have hcos : ∀ s, HasDerivAt (fun y => cos (ω * y)) (-sin (ω * s) * ω) s := by
    intro s; convert ((hasDerivAt_id' s).const_mul ω).cos using 1; ring
  have hsin : ∀ s, HasDerivAt (fun y => sin (ω * y)) (cos (ω * s) * ω) s := by
    intro s; convert ((hasDerivAt_id' s).const_mul ω).sin using 1; ring
  have hdP : ∀ s ∈ I, HasDerivAt P (ω • N s) s := by
    intro s hs; rw [hP]
    convert ((hdT2 s hs).fun_const_smul α).fun_sub ((hdB s hs).fun_const_smul β) using 1
    linear_combination (norm := module) (-1 : ℝ) • (hακβτ • N s)
  have hdE₁ : ∀ s ∈ I, HasDerivAt E₁ 0 s := by
    intro s hs; rw [hE₁]
    convert (((hcos s).fun_smul (hdN' s hs)).fun_neg).fun_sub
      ((hsin s).fun_smul (hdP s hs)) using 1
    rw [hP]
    linear_combination (norm := module) hαω • (cos (ω * s) • T s)
      - hβω • (cos (ω * s) • B s)
  have hdE₂ : ∀ s ∈ I, HasDerivAt E₂ 0 s := by
    intro s hs; rw [hE₂]
    convert (((hsin s).fun_smul (hdN' s hs)).fun_neg).fun_add
      ((hcos s).fun_smul (hdP s hs)) using 1
    rw [hP]
    linear_combination (norm := module) hαω • (sin (ω * s) • T s)
      - hβω • (sin (ω * s) • B s)
  have hdE₃ : ∀ s ∈ I, HasDerivAt E₃ 0 s := by
    intro s hs; rw [hE₃]
    convert ((hdT2 s hs).fun_const_smul β).fun_add ((hdB s hs).fun_const_smul α) using 1
    linear_combination (norm := module) hβκ.symm • N s
  have hdQ : ∀ s ∈ I, HasDerivAt Q 0 s := by
    intro s hs; rw [hQ]
    have hl : HasDerivAt (fun y => c * (ω * y)) (c * (ω * 1)) s :=
      ((hasDerivAt_id' s).const_mul ω).const_mul c
    convert ((hdr s hs).fun_add ((hdN' s hs).fun_const_smul k)).fun_sub
      (hl.fun_smul (hdE₃ s hs)) using 1
    rw [hE₃]
    linear_combination (norm := module) hkc • T s + hβω • (c • T s) + hαω • (c • B s)
      - hkc2 • B s
  have hconst : ∀ F : ℝ → Fin 3 → ℝ, (∀ s ∈ I, HasDerivAt F 0 s) → ∀ s ∈ I, F s = F s₀ := by
    intro F hF s hs
    exact hI.is_const_of_deriv_eq_zero hIc
      (fun y hy => (hF y hy).differentiableAt.differentiableWithinAt)
      (fun y hy => (hF y hy).deriv) hs hs₀
  have hcomb : ∀ s, cos (ω * s) • E₁ s + sin (ω * s) • E₂ s = -N s := by
    intro s; rw [hE₁, hE₂]
    linear_combination (norm := module) (sin_sq_add_cos_sq (ω * s)).symm • N s
  have hcross : ∀ s ∈ I, E₁ s ⨯₃ E₂ s = E₃ s := by
    intro s hs
    rw [hE₁, hE₂, hE₃, hP]
    simp only [map_add, map_sub, map_neg, map_smul, LinearMap.add_apply, LinearMap.sub_apply,
      LinearMap.neg_apply, LinearMap.smul_apply, cross_self, hTNB, hNT, hNB s hs, hBT s hs,
      hBN s hs, hTB s hs]
    linear_combination (norm := module) (sin_sq_add_cos_sq (ω * s)) • (β • T s + α • B s)
  have hdots : ∀ s ∈ I, E₁ s ⬝ᵥ E₁ s = 1 ∧ E₂ s ⬝ᵥ E₂ s = 1 ∧ E₁ s ⬝ᵥ E₂ s = 0 := by
    intro s hs
    rw [hE₁, hE₂, hP]
    simp only [dotProduct_add, add_dotProduct, dotProduct_sub, sub_dotProduct, dotProduct_neg,
      neg_dotProduct, dotProduct_smul, smul_dotProduct, smul_eq_mul, hTT s hs, hNN s hs,
      hBB s hs, hTN s hs, hNT0 s hs, hTB0, hBT0, hNB0, hBN0]
    refine ⟨?_, ?_, ?_⟩
    · linear_combination sin (ω * s) ^ 2 * hαβ + sin_sq_add_cos_sq (ω * s)
    · linear_combination cos (ω * s) ^ 2 * hαβ + sin_sq_add_cos_sq (ω * s)
    · linear_combination (-(sin (ω * s) * cos (ω * s))) * hαβ
  obtain ⟨h1, h2, h3⟩ := hdots s₀ hs₀
  refine ⟨Q s₀, E₁ s₀, E₂ s₀, h1, h2, h3, ?_⟩
  intro s hs
  rw [← hconst E₁ hdE₁ s hs, ← hconst E₂ hdE₂ s hs, ← hconst Q hdQ s hs, hcomb s,
    hcross s hs, hQ]
  simp only
  module

/-- The helix's two rates. The helix of radius `a > 0` that climbs `c` metres per radian,
`(a cos t, a sin t, c t)`, labelled by distance travelled (`t = s/w`, with speed
`w = √(a² + c²)` metres per radian), has unit speed, curvature `a/(a² + c²)` and torsion
`c/(a² + c²)` at every point. -/
theorem helix_curvature_and_torsion (a c : ℝ) (ha : 0 < a) :
    let w := √(a ^ 2 + c ^ 2)
    let r : ℝ → Fin 3 → ℝ := fun s => ![a * cos (s / w), a * sin (s / w), c * (s / w)]
    ∀ s, deriv r s ⬝ᵥ deriv r s = 1 ∧ curvature r s = a / (a ^ 2 + c ^ 2) ∧
      torsion r s = c / (a ^ 2 + c ^ 2) := by
  intro w r
  have hw2 : w ^ 2 = a ^ 2 + c ^ 2 := Real.sq_sqrt (by positivity)
  have hwpos : 0 < w := Real.sqrt_pos.2 (by positivity)
  have hwne : w ≠ 0 := hwpos.ne'
  have hT : deriv r = fun s => ![-(a / w) * sin (s / w), (a / w) * cos (s / w), c / w] := by
    funext s
    apply HasDerivAt.deriv
    apply hasDerivAt_vec3
    · convert (((hasDerivAt_id' s).div_const w).cos).const_mul a using 1; ring
    · convert (((hasDerivAt_id' s).div_const w).sin).const_mul a using 1; ring
    · convert ((hasDerivAt_id' s).div_const w).const_mul c using 1; ring
  have hT' : deriv (deriv r) = fun s =>
      ![-(a / w ^ 2) * cos (s / w), -(a / w ^ 2) * sin (s / w), 0] := by
    funext s
    rw [hT]
    apply HasDerivAt.deriv
    apply hasDerivAt_vec3
    · convert (((hasDerivAt_id' s).div_const w).sin).const_mul (-(a / w)) using 1; ring
    · convert (((hasDerivAt_id' s).div_const w).cos).const_mul (a / w) using 1; ring
    · exact hasDerivAt_const s (c / w)
  have hcurv : ∀ s, curvature r s = a / (a ^ 2 + c ^ 2) := by
    intro s
    have h : deriv (deriv r) s ⬝ᵥ deriv (deriv r) s = (a / w ^ 2) ^ 2 := by
      rw [hT']
      simp only [vec3_dotProduct, Matrix.cons_val_zero, Matrix.cons_val_one,
        Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
      linear_combination (a / w ^ 2) ^ 2 * sin_sq_add_cos_sq (s / w)
    rw [curvature, h, Real.sqrt_sq (by positivity), hw2]
  have hN : normal r = fun s => ![-cos (s / w), -sin (s / w), 0] := by
    funext s
    simp only [normal, hcurv, hT']
    rw [← hw2]
    ext i
    fin_cases i <;> simp <;> field_simp
  have hB : binormal r = fun s => ![(c / w) * sin (s / w), -(c / w) * cos (s / w), a / w] := by
    funext s
    simp only [binormal, hN, hT]
    ext i
    fin_cases i <;> simp [cross_apply]
    linear_combination (a * w⁻¹) * sin_sq_add_cos_sq (s / w)
  have hB' : ∀ s, deriv (binormal r) s =
      ![(c / w ^ 2) * cos (s / w), (c / w ^ 2) * sin (s / w), 0] := by
    intro s
    rw [hB]
    apply HasDerivAt.deriv
    apply hasDerivAt_vec3
    · convert (((hasDerivAt_id' s).div_const w).sin).const_mul (c / w) using 1; ring
    · convert (((hasDerivAt_id' s).div_const w).cos).const_mul (-(c / w)) using 1; ring
    · exact hasDerivAt_const s (a / w)
  intro s
  refine ⟨?_, hcurv s, ?_⟩
  · rw [hT]
    simp only [vec3_dotProduct, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    field_simp
    linear_combination a ^ 2 * sin_sq_add_cos_sq (s / w) - hw2
  · rw [torsion, hB', hN, ← hw2]
    simp only [vec3_dotProduct, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    field_simp
    linear_combination c * sin_sq_add_cos_sq (s / w)

/-- The sign of torsion records handedness. On an open stretch where the curve has three
continuous derivatives, unit speed and curvature not zero: walking it the other way,
`s ↦ r(−s)`, keeps the torsion, and its mirror image `(x, y, z) ↦ (−x, y, z)` has the same
torsion with the sign flipped. -/
theorem torsion_reverse_and_mirror (r : ℝ → Fin 3 → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hr : ContDiffOn ℝ 3 r I)
    (hunit : ∀ s ∈ I, deriv r s ⬝ᵥ deriv r s = 1)
    (hκ : ∀ s ∈ I, deriv (deriv r) s ≠ 0) :
    ∀ s ∈ I, torsion (fun x => r (-x)) (-s) = torsion r s ∧
      torsion (fun x => ![-(r x 0), r x 1, r x 2]) s = -torsion r s := by
  intro s _
  constructor
  · have h1 : deriv (fun x => r (-x)) = fun x => -deriv r (-x) := by
      funext x; exact deriv_comp_neg r x
    have h2 : deriv (deriv (fun x => r (-x))) = fun x => deriv (deriv r) (-x) := by
      funext x
      rw [h1, deriv.fun_neg, deriv_comp_neg (deriv r) x, neg_neg]
    have hc : curvature (fun x => r (-x)) = fun x => curvature r (-x) := by
      funext x; simp only [curvature, h2]
    have hn : normal (fun x => r (-x)) = fun x => normal r (-x) := by
      funext x; simp only [normal, hc, h2]
    have hb : binormal (fun x => r (-x)) = fun x => -binormal r (-x) := by
      funext x; simp only [binormal, hn, h1, map_neg, LinearMap.neg_apply]
    have hdb : deriv (binormal (fun x => r (-x))) (-s) = deriv (binormal r) s := by
      rw [hb, deriv.fun_neg, deriv_comp_neg (binormal r) (-s), neg_neg, neg_neg]
    simp only [torsion, hdb, hn, neg_neg]
  · set m := fun x => ![-(r x 0), r x 1, r x 2] with hm
    have h1 : deriv m = fun x => ![-(deriv r x 0), deriv r x 1, deriv r x 2] := by
      funext x; exact deriv_mirror3 r x
    have h2 : deriv (deriv m) = fun x =>
        ![-(deriv (deriv r) x 0), deriv (deriv r) x 1, deriv (deriv r) x 2] := by
      funext x; rw [h1]; exact deriv_mirror3 (deriv r) x
    have hc : curvature m = curvature r := by
      funext x; simp only [curvature, h2, mirror_dot3]
    have hn : normal m = fun x => ![-(normal r x 0), normal r x 1, normal r x 2] := by
      funext x; simp only [normal, hc, h2]; ext i; fin_cases i <;> simp
    have hb : binormal m = fun x =>
        -![-(binormal r x 0), binormal r x 1, binormal r x 2] := by
      funext x; simp only [binormal, hn, h1, mirror_cross3]
    have hdb : deriv (binormal m) s =
        -![-(deriv (binormal r) s 0), deriv (binormal r) s 1, deriv (binormal r) s 2] := by
      rw [hb, deriv.fun_neg, deriv_mirror3]
    simp only [torsion, hdb, hn, neg_dotProduct, mirror_dot3]

-- Rise 5.026548 m per turn makes the climb per radian equal the radius, c = a = 0.8 m:
-- then κ = a/(a² + c²) and τ = c/(a² + c²) are both 0.625 = 5/8 per metre, which is 1/(2a).
example : (4 / 5 : ℚ) / ((4 / 5) ^ 2 + (4 / 5) ^ 2) = 5 / 8 := by norm_num
example : (1 : ℚ) / (2 * (4 / 5)) = 5 / 8 := by norm_num
-- Back again: the rates 5/8 and 5/8 give radius κ/(κ² + τ²) = 0.8 m and climb τ/(κ² + τ²) = 0.8 m.
example : (5 / 8 : ℚ) / ((5 / 8) ^ 2 + (5 / 8) ^ 2) = 4 / 5 := by norm_num
-- A straight landing rail, posts 0.3 m apart: the cross product of two post-to-post steps is 0,
-- so there is no bending plane and no torsion.
example : (![0, 0, 3 / 10] : Fin 3 → ℚ) ⨯₃ ![0, 0, 3 / 10] = 0 := by
  simp [cross_apply]

#print axioms constant_curvature_and_torsion_is_helix
#print axioms helix_curvature_and_torsion
#print axioms torsion_reverse_and_mirror
