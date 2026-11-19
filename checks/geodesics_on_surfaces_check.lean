-- Geodesic on a surface: a unit-speed path's turning splits into a sideways part along the surface and a part along the normal whose squares add to the total, on a surface of revolution r sin ψ changes at rate −r cos ψ κ_g so it stays constant exactly along a geodesic, and a great circle on a sphere never steers, with the card's dome numbers checked exactly.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

/-! A point or arrow in space is a list of three real numbers, `v : Fin 3 → ℝ`, and
`![a, b, c]` is the arrow `(a, b, c)`. Mathlib's `u ⨯₃ v` (`crossProduct`) is the cross
product and `u ⬝ᵥ v` the dot product. A path is `γ : ℝ → (Fin 3 → ℝ)`, with `s` the metres
walked; `deriv γ s` is its velocity, the unit tangent `T` when the walk has unit speed, and
`deriv (deriv γ) s` is `T'`. The card's geodesic curvature is `κ_g = T' · (n × T)` and its
normal curvature is `κ_n = T' · n`, where `n` is the surface's unit normal. A geodesic is a
path with `κ_g = 0` at every point. -/

open Matrix Real

theorem diff_two_of_contDiff {f : ℝ → Fin 3 → ℝ} (h : ContDiff ℝ 2 f) :
    Differentiable ℝ f ∧ Differentiable ℝ (deriv f) := by
  have h' := contDiff_succ_iff_deriv.1 (show ContDiff ℝ (1 + 1) f from h)
  exact ⟨h'.1, h'.2.2.differentiable (by norm_num)⟩

#print axioms diff_two_of_contDiff

theorem diff_two_of_contDiff_real {f : ℝ → ℝ} (h : ContDiff ℝ 2 f) :
    Differentiable ℝ f ∧ Differentiable ℝ (deriv f) := by
  have h' := contDiff_succ_iff_deriv.1 (show ContDiff ℝ (1 + 1) f from h)
  exact ⟨h'.1, h'.2.2.differentiable (by norm_num)⟩

#print axioms diff_two_of_contDiff_real

theorem deriv_dot_self_of_unit (T : ℝ → Fin 3 → ℝ) (hT : Differentiable ℝ T)
    (h : ∀ s, T s ⬝ᵥ T s = 1) (s : ℝ) : deriv T s ⬝ᵥ T s = 0 := by
  have hi := hasDerivAt_pi.1 (hT s).hasDerivAt
  have H : HasDerivAt (fun u => T u ⬝ᵥ T u) (2 * (deriv T s ⬝ᵥ T s)) s := by
    have := ((hi 0).mul (hi 0)).add (((hi 1).mul (hi 1)).add ((hi 2).mul (hi 2)))
    convert this using 1
    · funext u; simp [dotProduct, Fin.sum_univ_three]; ring
    · simp [dotProduct, Fin.sum_univ_three]; ring
  have H0 : HasDerivAt (fun u => T u ⬝ᵥ T u) 0 s := by
    simp only [h]; exact hasDerivAt_const s 1
  have := H.unique H0
  linarith

#print axioms deriv_dot_self_of_unit

theorem orthonormal_split (v T n : Fin 3 → ℝ) (hT : T ⬝ᵥ T = 1) (hn : n ⬝ᵥ n = 1)
    (hnT : n ⬝ᵥ T = 0) (hvT : v ⬝ᵥ T = 0) :
    v = (v ⬝ᵥ (n ⨯₃ T)) • (n ⨯₃ T) + (v ⬝ᵥ n) • n := by
  simp only [dotProduct, Fin.sum_univ_three] at *
  ext i
  fin_cases i <;> simp [cross_apply]
  · linear_combination
      ((n 0 * T 0 + n 1 * T 1 + n 2 * T 2) * v 0 - (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * T 0
        - (v 0 * T 0 + v 1 * T 1 + v 2 * T 2) * n 0) * hnT + (-v 0) * hn
      + (-(n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 0 + (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * n 0) * hT
      + ((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * T 0) * hvT
  · linear_combination
      ((n 0 * T 0 + n 1 * T 1 + n 2 * T 2) * v 1 - (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * T 1
        - (v 0 * T 0 + v 1 * T 1 + v 2 * T 2) * n 1) * hnT + (-v 1) * hn
      + (-(n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 1 + (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * n 1) * hT
      + ((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * T 1) * hvT
  · linear_combination
      ((n 0 * T 0 + n 1 * T 1 + n 2 * T 2) * v 2 - (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * T 2
        - (v 0 * T 0 + v 1 * T 1 + v 2 * T 2) * n 2) * hnT + (-v 2) * hn
      + (-(n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * v 2 + (v 0 * n 0 + v 1 * n 1 + v 2 * n 2) * n 2) * hT
      + ((n 0 * n 0 + n 1 * n 1 + n 2 * n 2) * T 2) * hvT

#print axioms orthonormal_split

theorem clairaut_algebra (R0 R1 R2 Z1 Z2 S1 S2 H1 H2 c sn : ℝ) (Tv Tpv es et : Fin 3 → ℝ)
    (hT : Tv = ![R1 * S1 * c - R0 * sn * H1, R1 * S1 * sn + R0 * c * H1, Z1 * S1])
    (hTp : Tpv = ![R2 * S1 * S1 * c + R1 * S2 * c - R1 * S1 * sn * H1
          - (R1 * S1 * sn * H1 + R0 * c * H1 * H1 + R0 * sn * H2),
        R2 * S1 * S1 * sn + R1 * S2 * sn + R1 * S1 * c * H1
          + (R1 * S1 * c * H1 - R0 * sn * H1 * H1 + R0 * c * H2),
        Z2 * S1 * S1 + Z1 * S2])
    (hes : es = ![R1 * c, R1 * sn, Z1]) (het : et = ![-sn, c, 0])
    (h1 : c ^ 2 + sn ^ 2 = 1) (h2 : R1 ^ 2 + Z1 ^ 2 = 1) (h3 : R1 * R2 + Z1 * Z2 = 0)
    (hTT : Tv ⬝ᵥ Tv = 1) (hTpT : Tpv ⬝ᵥ Tv = 0) :
    Tv ⬝ᵥ (-es) = -S1 ∧ Tv ⬝ᵥ et = R0 * H1 ∧
    2 * R0 * R1 * S1 * H1 + R0 ^ 2 * H2 = -(R0 * (Tv ⬝ᵥ (-es)) * (Tpv ⬝ᵥ ((es ⨯₃ et) ⨯₃ Tv))) := by
  subst hT hTp hes het
  have hcos : ![R1 * S1 * c - R0 * sn * H1, R1 * S1 * sn + R0 * c * H1, Z1 * S1] ⬝ᵥ
      (-![R1 * c, R1 * sn, Z1]) = -S1 := by
    simp only [dotProduct, Fin.sum_univ_three, Pi.neg_apply, cons_val_zero, cons_val_one,
      cons_val_two, head_cons, tail_cons]
    linear_combination (-R1 ^ 2 * S1) * h1 + (-S1) * h2
  refine ⟨hcos, ?_, ?_⟩
  · simp only [dotProduct, Fin.sum_univ_three, cons_val_zero, cons_val_one,
      cons_val_two, head_cons, tail_cons]
    linear_combination (H1 * R0) * h1
  · rw [hcos]
    simp only [dotProduct, Fin.sum_univ_three, cons_val_zero, cons_val_one,
      cons_val_two, head_cons, tail_cons] at hTT hTpT
    have g4 : S1 ^ 2 + R0 ^ 2 * H1 ^ 2 = 1 := by
      linear_combination hTT - (H1 ^ 2 * R0 ^ 2 + R1 ^ 2 * S1 ^ 2) * h1 - S1 ^ 2 * h2
    have g5 : S1 * S2 + R0 * R1 * S1 * H1 ^ 2 + R0 ^ 2 * H1 * H2 = 0 := by
      linear_combination hTpT
        - (H1 ^ 2 * R0 * R1 * S1 + H1 * H2 * R0 ^ 2 + R1 ^ 2 * S1 * S2 + R1 * R2 * S1 ^ 3) * h1
        - (S1 * S2) * h2 - S1 ^ 3 * h3
    simp only [cross_apply, dotProduct, Fin.sum_univ_three, cons_val_zero, cons_val_one,
      cons_val_two, head_cons, tail_cons]
    linear_combination
      (-H1^3*R0^3*R1*S1*c^2 - H1^3*R0^3*R1*S1*sn^2 - H1^3*R0^3*R1*S1 + H1*R0^2*R1^2*S1*S2*c^2
        + H1*R0^2*R1^2*S1*S2*sn^2 + H1*R0^2*R1^2*S1*S2 + H1*R0^2*R1*R2*S1^3*c^2
        + H1*R0^2*R1*R2*S1^3*sn^2 + H1*R0^2*R1*R2*S1^3 + H1*R0^2*S1^3*Z1*Z2 + H1*R0^2*S1*S2*Z1^2
        - 2*H1*R0*R1^3*S1^3*c^2 - 2*H1*R0*R1^3*S1^3*sn^2 - 2*H1*R0*R1^3*S1^3
        - 2*H1*R0*R1*S1^3*Z1^2 - H2*R0^2*R1^2*S1^2*c^2 - H2*R0^2*R1^2*S1^2*sn^2
        - H2*R0^2*R1^2*S1^2 - H2*R0^2*S1^2*Z1^2) * h1
      + (H1*R0^2*S1*S2 - 2*H1*R0*R1*S1^3 - H2*R0^2*S1^2) * h2
      + (H1*R0^2*S1^3) * h3
      + (-2*H1*R0*R1*S1 - H2*R0^2) * g4
      + (H1*R0^2) * g5

#print axioms clairaut_algebra

/-- The split of a path's turning. Walk a smooth path at unit speed, and let `n` be a unit
arrow square to the direction of travel `T` (the surface's normal). Then the rate `T'` is
`κ_g (n × T) + κ_n n`, with `κ_g = T' · (n × T)` the sideways turning along the surface and
`κ_n = T' · n` the forced bending along the normal; their squares add to the square of the
total curvature, `κ² = |T'|² = κ_g² + κ_n²`. So a path has `κ_g = 0` (it is a geodesic at
that point) exactly when all its turning points along the normal. -/
theorem turning_splits_into_geodesic_and_normal_curvature
    (γ n : ℝ → Fin 3 → ℝ) (hγ : ContDiff ℝ 2 γ)
    (hunit : ∀ s, deriv γ s ⬝ᵥ deriv γ s = 1)
    (hn : ∀ s, n s ⬝ᵥ n s = 1) (hnT : ∀ s, n s ⬝ᵥ deriv γ s = 0) (s : ℝ) :
    let T := deriv γ
    let κg := deriv T s ⬝ᵥ (n s ⨯₃ T s)
    let κn := deriv T s ⬝ᵥ n s
    deriv T s = κg • (n s ⨯₃ T s) + κn • n s ∧
    deriv T s ⬝ᵥ deriv T s = κg ^ 2 + κn ^ 2 ∧
    (κg = 0 ↔ ∃ k : ℝ, deriv T s = k • n s) := by
  intro T κg κn
  simp only [T, κg, κn]
  have h0 : deriv (deriv γ) s ⬝ᵥ deriv γ s = 0 :=
    deriv_dot_self_of_unit _ (diff_two_of_contDiff hγ).2 hunit s
  have hdec := orthonormal_split _ _ _ (hunit s) (hn s) (hnT s) h0
  refine ⟨hdec, ?_, ?_⟩
  · nth_rewrite 1 [hdec]
    simp only [add_dotProduct, smul_dotProduct, smul_eq_mul,
      dotProduct_comm (n s ⨯₃ deriv γ s), dotProduct_comm (n s)]
    ring
  · constructor
    · intro h
      refine ⟨deriv (deriv γ) s ⬝ᵥ n s, ?_⟩
      exact hdec.trans (by rw [h, zero_smul, zero_add])
    · rintro ⟨k, hk⟩
      rw [hk, smul_dotProduct, dot_self_cross, smul_zero]

/-- Clairaut's relation, from the steering formula. On a surface of revolution
`X(σ, θ) = (r(σ) cos θ, r(σ) sin θ, z(σ))`, with `σ` the distance down a meridian (so
`r_σ² + z_σ² = 1`) and `r > 0` the distance from the axis, walk a smooth path
`(σ(s), θ(s))` at unit speed. Let `e_σ = X_σ` (down the slope), `e_θ` (round the axis),
`n = e_σ × e_θ`, and write `cos ψ = T · (−e_σ)` and `sin ψ = T · e_θ` for the parts of the
direction of travel up the meridian and round the axis. Then `(r sin ψ)' = −r cos ψ κ_g`
along the walk; so, wherever `cos ψ ≠ 0`, `r sin ψ` is momentarily constant exactly when
`κ_g = 0`, and along a geodesic `r sin ψ = c` for one constant `c`. -/
theorem clairaut_relation_on_surface_of_revolution
    (r z σ θ : ℝ → ℝ) (hr : ContDiff ℝ 2 r) (hz : ContDiff ℝ 2 z)
    (hprofile : ∀ t, deriv r t ^ 2 + deriv z t ^ 2 = 1) (hpos : ∀ t, 0 < r t)
    (hσ : ContDiff ℝ 2 σ) (hθ : ContDiff ℝ 2 θ) :
    let γ : ℝ → Fin 3 → ℝ := fun s => ![r (σ s) * cos (θ s), r (σ s) * sin (θ s), z (σ s)]
    let eσ : ℝ → Fin 3 → ℝ := fun s =>
      ![deriv r (σ s) * cos (θ s), deriv r (σ s) * sin (θ s), deriv z (σ s)]
    let eθ : ℝ → Fin 3 → ℝ := fun s => ![-sin (θ s), cos (θ s), 0]
    let n : ℝ → Fin 3 → ℝ := fun s => eσ s ⨯₃ eθ s
    let T := deriv γ
    let κg : ℝ → ℝ := fun s => deriv T s ⬝ᵥ (n s ⨯₃ T s)
    let cosψ : ℝ → ℝ := fun s => T s ⬝ᵥ (-eσ s)
    let sinψ : ℝ → ℝ := fun s => T s ⬝ᵥ eθ s
    (∀ s, T s ⬝ᵥ T s = 1) →
    (∀ s, HasDerivAt (fun u => r (σ u) * sinψ u) (-(r (σ s) * cosψ s * κg s)) s) ∧
    (∀ s, cosψ s ≠ 0 → (deriv (fun u => r (σ u) * sinψ u) s = 0 ↔ κg s = 0)) ∧
    ((∀ s, κg s = 0) → ∃ c : ℝ, ∀ s, r (σ s) * sinψ s = c) := by
  intro γ eσ eθ n T κg cosψ sinψ hunit
  obtain ⟨hr1, hr2⟩ := diff_two_of_contDiff_real hr
  obtain ⟨hz1, hz2⟩ := diff_two_of_contDiff_real hz
  obtain ⟨hσ1, hσ2⟩ := diff_two_of_contDiff_real hσ
  obtain ⟨hθ1, hθ2⟩ := diff_two_of_contDiff_real hθ
  have hprof' : ∀ t, deriv r t * deriv (deriv r) t + deriv z t * deriv (deriv z) t = 0 := by
    intro t
    have H := ((hr2 t).hasDerivAt.mul (hr2 t).hasDerivAt).add
      ((hz2 t).hasDerivAt.mul (hz2 t).hasDerivAt)
    have H0 : HasDerivAt (fun u => deriv r u * deriv r u + deriv z u * deriv z u) 0 t := by
      have hc : (fun u => deriv r u * deriv r u + deriv z u * deriv z u) = fun _ => 1 :=
        funext fun u => by rw [← hprofile u]; ring
      rw [hc]; exact hasDerivAt_const t 1
    have := H.unique H0
    linarith
  have hR0 : ∀ s, HasDerivAt (fun u => r (σ u)) (deriv r (σ s) * deriv σ s) s :=
    fun s => (hr1 (σ s)).hasDerivAt.comp s (hσ1 s).hasDerivAt
  have hR1 : ∀ s, HasDerivAt (fun u => deriv r (σ u)) (deriv (deriv r) (σ s) * deriv σ s) s :=
    fun s => (hr2 (σ s)).hasDerivAt.comp s (hσ1 s).hasDerivAt
  have hZ0 : ∀ s, HasDerivAt (fun u => z (σ u)) (deriv z (σ s) * deriv σ s) s :=
    fun s => (hz1 (σ s)).hasDerivAt.comp s (hσ1 s).hasDerivAt
  have hZ1 : ∀ s, HasDerivAt (fun u => deriv z (σ u)) (deriv (deriv z) (σ s) * deriv σ s) s :=
    fun s => (hz2 (σ s)).hasDerivAt.comp s (hσ1 s).hasDerivAt
  have hS1 : ∀ s, HasDerivAt (deriv σ) (deriv (deriv σ) s) s := fun s => (hσ2 s).hasDerivAt
  have hH1 : ∀ s, HasDerivAt (deriv θ) (deriv (deriv θ) s) s := fun s => (hθ2 s).hasDerivAt
  have hc : ∀ s, HasDerivAt (fun u => cos (θ u)) (-sin (θ s) * deriv θ s) s :=
    fun s => (hθ1 s).hasDerivAt.cos
  have hsn : ∀ s, HasDerivAt (fun u => sin (θ u)) (cos (θ s) * deriv θ s) s :=
    fun s => (hθ1 s).hasDerivAt.sin
  have hTform : ∀ s, HasDerivAt γ
      ![deriv r (σ s) * deriv σ s * cos (θ s) - r (σ s) * sin (θ s) * deriv θ s,
        deriv r (σ s) * deriv σ s * sin (θ s) + r (σ s) * cos (θ s) * deriv θ s,
        deriv z (σ s) * deriv σ s] s := by
    intro s
    apply hasDerivAt_pi.2
    intro i
    fin_cases i
    · show HasDerivAt (fun u => r (σ u) * cos (θ u))
        (deriv r (σ s) * deriv σ s * cos (θ s) - r (σ s) * sin (θ s) * deriv θ s) s
      convert (hR0 s).mul (hc s) using 1; ring
    · show HasDerivAt (fun u => r (σ u) * sin (θ u))
        (deriv r (σ s) * deriv σ s * sin (θ s) + r (σ s) * cos (θ s) * deriv θ s) s
      convert (hR0 s).mul (hsn s) using 1; ring
    · exact hZ0 s
  have hTs : ∀ s, T s =
      ![deriv r (σ s) * deriv σ s * cos (θ s) - r (σ s) * sin (θ s) * deriv θ s,
        deriv r (σ s) * deriv σ s * sin (θ s) + r (σ s) * cos (θ s) * deriv θ s,
        deriv z (σ s) * deriv σ s] := fun s => (hTform s).deriv
  have hTfun : T = fun s =>
      ![deriv r (σ s) * deriv σ s * cos (θ s) - r (σ s) * sin (θ s) * deriv θ s,
        deriv r (σ s) * deriv σ s * sin (θ s) + r (σ s) * cos (θ s) * deriv θ s,
        deriv z (σ s) * deriv σ s] := funext hTs
  have hT'form : ∀ s, HasDerivAt T
      ![deriv (deriv r) (σ s) * deriv σ s * deriv σ s * cos (θ s)
          + deriv r (σ s) * deriv (deriv σ) s * cos (θ s)
          - deriv r (σ s) * deriv σ s * sin (θ s) * deriv θ s
          - (deriv r (σ s) * deriv σ s * sin (θ s) * deriv θ s
            + r (σ s) * cos (θ s) * deriv θ s * deriv θ s + r (σ s) * sin (θ s) * deriv (deriv θ) s),
        deriv (deriv r) (σ s) * deriv σ s * deriv σ s * sin (θ s)
          + deriv r (σ s) * deriv (deriv σ) s * sin (θ s)
          + deriv r (σ s) * deriv σ s * cos (θ s) * deriv θ s
          + (deriv r (σ s) * deriv σ s * cos (θ s) * deriv θ s
            - r (σ s) * sin (θ s) * deriv θ s * deriv θ s + r (σ s) * cos (θ s) * deriv (deriv θ) s),
        deriv (deriv z) (σ s) * deriv σ s * deriv σ s + deriv z (σ s) * deriv (deriv σ) s] s := by
    intro s
    rw [hTfun]
    apply hasDerivAt_pi.2
    intro i
    fin_cases i
    · show HasDerivAt
        (fun u => deriv r (σ u) * deriv σ u * cos (θ u) - r (σ u) * sin (θ u) * deriv θ u)
        (deriv (deriv r) (σ s) * deriv σ s * deriv σ s * cos (θ s)
          + deriv r (σ s) * deriv (deriv σ) s * cos (θ s)
          - deriv r (σ s) * deriv σ s * sin (θ s) * deriv θ s
          - (deriv r (σ s) * deriv σ s * sin (θ s) * deriv θ s
            + r (σ s) * cos (θ s) * deriv θ s * deriv θ s
            + r (σ s) * sin (θ s) * deriv (deriv θ) s)) s
      exact ((((hR1 s).mul (hS1 s)).mul (hc s)).sub
        (((hR0 s).mul (hsn s)).mul (hH1 s))).congr_deriv (by simp only [Pi.mul_apply]; ring)
    · show HasDerivAt
        (fun u => deriv r (σ u) * deriv σ u * sin (θ u) + r (σ u) * cos (θ u) * deriv θ u)
        (deriv (deriv r) (σ s) * deriv σ s * deriv σ s * sin (θ s)
          + deriv r (σ s) * deriv (deriv σ) s * sin (θ s)
          + deriv r (σ s) * deriv σ s * cos (θ s) * deriv θ s
          + (deriv r (σ s) * deriv σ s * cos (θ s) * deriv θ s
            - r (σ s) * sin (θ s) * deriv θ s * deriv θ s
            + r (σ s) * cos (θ s) * deriv (deriv θ) s)) s
      exact ((((hR1 s).mul (hS1 s)).mul (hsn s)).add
        (((hR0 s).mul (hc s)).mul (hH1 s))).congr_deriv (by simp only [Pi.mul_apply]; ring)
    · show HasDerivAt (fun u => deriv z (σ u) * deriv σ u)
        (deriv (deriv z) (σ s) * deriv σ s * deriv σ s + deriv z (σ s) * deriv (deriv σ) s) s
      exact ((hZ1 s).mul (hS1 s)).congr_deriv (by ring)
  have hTdiff : Differentiable ℝ T := fun s => (hT'form s).differentiableAt
  have hTpT : ∀ s, deriv T s ⬝ᵥ T s = 0 := deriv_dot_self_of_unit T hTdiff hunit
  have core : ∀ s, _ := fun s => clairaut_algebra (r (σ s)) (deriv r (σ s))
    (deriv (deriv r) (σ s)) (deriv z (σ s)) (deriv (deriv z) (σ s)) (deriv σ s)
    (deriv (deriv σ) s) (deriv θ s) (deriv (deriv θ) s) (cos (θ s)) (sin (θ s))
    (T s) (deriv T s) (eσ s) (eθ s) (hTs s) (hT'form s).deriv rfl rfl
    (cos_sq_add_sin_sq _) (hprofile _) (hprof' _) (hunit s) (hTpT s)
  have hsin : ∀ u, sinψ u = r (σ u) * deriv θ u := fun u => (core u).2.1
  have hcos : ∀ u, cosψ u = -deriv σ u := fun u => (core u).1
  have hkey : ∀ s, 2 * r (σ s) * deriv r (σ s) * deriv σ s * deriv θ s
      + r (σ s) ^ 2 * deriv (deriv θ) s = -(r (σ s) * cosψ s * κg s) := fun s => (core s).2.2
  have part1 : ∀ s, HasDerivAt (fun u => r (σ u) * sinψ u) (-(r (σ s) * cosψ s * κg s)) s := by
    intro s
    have hfun : (fun u => r (σ u) * sinψ u) = fun u => r (σ u) * (r (σ u) * deriv θ u) :=
      funext fun u => by rw [hsin u]
    rw [hfun, ← hkey s]
    exact ((hR0 s).mul ((hR0 s).mul (hH1 s))).congr_deriv (by simp only [Pi.mul_apply]; ring)
  refine ⟨part1, ?_, ?_⟩
  · intro s hcs
    rw [(part1 s).deriv]
    have hne := mul_ne_zero (hpos (σ s)).ne' hcs
    constructor
    · intro h
      rw [neg_eq_zero] at h
      exact (mul_eq_zero.1 h).resolve_left hne
    · intro h
      rw [h]; ring
  · intro hk
    have hd : ∀ x, HasDerivAt (fun u => r (σ u) * sinψ u) 0 x := fun x => by
      have := part1 x
      rwa [hk x, mul_zero, neg_zero] at this
    exact ⟨r (σ 0) * sinψ 0, fun s =>
      is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) s 0⟩

/-- A great circle never steers. On the sphere of radius `R > 0` about the origin, the great
circle `γ(s) = R (cos(s/R) a + sin(s/R) b)` through two square unit arrows `a` and `b` lies
on the sphere and is walked at unit speed; with the sphere's outward normal `n = γ / R`, its
geodesic curvature is `κ_g = 0` at every point, so it is a geodesic, and its normal
curvature is `κ_n = −1/R`. -/
theorem great_circle_is_geodesic
    (R : ℝ) (hR : 0 < R) (a b : Fin 3 → ℝ)
    (ha : a ⬝ᵥ a = 1) (hb : b ⬝ᵥ b = 1) (hab : a ⬝ᵥ b = 0) (s : ℝ) :
    let γ : ℝ → Fin 3 → ℝ := fun t => R • (cos (t / R) • a + sin (t / R) • b)
    let n : Fin 3 → ℝ := R⁻¹ • γ s
    γ s ⬝ᵥ γ s = R ^ 2 ∧
    deriv γ s ⬝ᵥ deriv γ s = 1 ∧
    deriv (deriv γ) s ⬝ᵥ (n ⨯₃ deriv γ s) = 0 ∧
    deriv (deriv γ) s ⬝ᵥ n = -1 / R := by
  intro γ n
  have hR0 : R ≠ 0 := hR.ne'
  have hba : b ⬝ᵥ a = 0 := by rw [dotProduct_comm]; exact hab
  have h1 : ∀ t, HasDerivAt γ ((-sin (t / R)) • a + cos (t / R) • b) t := by
    intro t
    have hc : HasDerivAt (fun t => cos (t / R)) (-sin (t / R) * R⁻¹) t := by
      simpa [div_eq_mul_inv] using ((hasDerivAt_id t).mul_const R⁻¹).cos
    have hs : HasDerivAt (fun t => sin (t / R)) (cos (t / R) * R⁻¹) t := by
      simpa [div_eq_mul_inv] using ((hasDerivAt_id t).mul_const R⁻¹).sin
    have := ((hc.smul_const a).add (hs.smul_const b)).const_smul R
    convert this using 1
    simp only [smul_add, smul_smul]
    congr 2 <;> field_simp
  have hd1 : deriv γ = fun t => (-sin (t / R)) • a + cos (t / R) • b :=
    funext fun t => (h1 t).deriv
  have h2 : HasDerivAt (deriv γ) ((-R⁻¹) • (cos (s / R) • a + sin (s / R) • b)) s := by
    rw [hd1]
    have hc : HasDerivAt (fun t => cos (t / R)) (-sin (s / R) * R⁻¹) s := by
      simpa [div_eq_mul_inv] using ((hasDerivAt_id s).mul_const R⁻¹).cos
    have hs : HasDerivAt (fun t => sin (t / R)) (cos (s / R) * R⁻¹) s := by
      simpa [div_eq_mul_inv] using ((hasDerivAt_id s).mul_const R⁻¹).sin
    have := (hs.neg.smul_const a).add (hc.smul_const b)
    convert this using 1
    ext i; simp; ring
  have hn : n = cos (s / R) • a + sin (s / R) • b := by
    simp only [n, γ, smul_smul, inv_mul_cancel₀ hR0, one_smul]
  have hcs := sin_sq_add_cos_sq (s / R)
  have huu : (cos (s / R) • a + sin (s / R) • b) ⬝ᵥ (cos (s / R) • a + sin (s / R) • b) = 1 := by
    simp only [add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul, ha, hb, hab, hba,
      smul_eq_mul]
    linear_combination hcs
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp only [γ, smul_dotProduct, dotProduct_smul, huu, smul_eq_mul]; ring
  · rw [hd1]
    simp only [add_dotProduct, dotProduct_add, smul_dotProduct, dotProduct_smul, ha, hb, hab, hba,
      smul_eq_mul]
    linear_combination hcs
  · rw [h2.deriv, hn, smul_dotProduct, dot_self_cross, smul_zero]
  · rw [h2.deriv, hn, smul_dotProduct, huu, smul_eq_mul]; field_simp

/-! The card's dome, by hand: sphere radius 60 m, rim at `sin φ₀ = 3/5`, `cos φ₀ = 4/5`. -/

-- Rim radius 60 × 3/5 = 36 m, and the crown stands 60 − 60 × 4/5 = 12 m above the rim.
example : (60 : ℚ) * (3 / 5) = 36 ∧ (60 : ℚ) - 60 * (4 / 5) = 12 := by norm_num

-- The unit arrows to A and B, (3/5, 0, 4/5) and (0, 3/5, 4/5), have dot product 16/25 = 0.64.
example : ![(3 : ℚ) / 5, 0, 4 / 5] ⬝ᵥ ![0, 3 / 5, 4 / 5] = 16 / 25 := by
  simp [dotProduct, Fin.sum_univ_three]; norm_num

-- On the rim: κ² − κ_n² = (1/36)² − (1/60)² = (1/45)², so κ_g = 1/45 per metre.
example : ((1 : ℚ) / 36) ^ 2 - (1 / 60) ^ 2 = (1 / 45) ^ 2 := by norm_num

-- The steering formula on the rim: r_σ / r = (4/5) / 36 = 1/45, and cot φ₀ / R = (4/3) / 60 = 1/45.
example : ((4 : ℚ) / 5) / 36 = 1 / 45 ∧ ((4 : ℚ) / 5) / (3 / 5) / 60 = 1 / 45 := by norm_num

-- Halfway round, tan² φ = (3/4)² / 2 = 9/32, so sin² φ = 9/41; then sin² ψ = 60² × (9/41) / 36²
-- = 25/41 at A, and tan² ψ = (25/41) / (1 − 25/41) = (5/4)², the card's tan ψ = 1.25.
example : ((3 : ℚ) / 4) ^ 2 / 2 = 9 / 32 ∧ ((9 : ℚ) / 32) / (1 + 9 / 32) = 9 / 41 ∧
    (60 : ℚ) ^ 2 * (9 / 41) / 36 ^ 2 = 25 / 41 ∧
    ((25 : ℚ) / 41) / (1 - 25 / 41) = (5 / 4) ^ 2 := by norm_num

#print axioms turning_splits_into_geodesic_and_normal_curvature
#print axioms clairaut_relation_on_surface_of_revolution
#print axioms great_circle_is_geodesic
