-- Curvature and torsion at any speed: for a track labelled by distance with its Frenet-Serret frame, timed by any clock whose rate is never zero, the curvature is |ṙ × r̈| / |ṙ|³ and the torsion is ((ṙ × r̈) · r⃛) / |ṙ × r̈|², computed from clock-time derivatives alone.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

/-!
Points and arrows in space are `Fin 3 → ℝ`, read as (east, north, up): a right-handed set of
axes. `a ⨯₃ b` is Mathlib's cross product (`crossProduct`) and `a ⬝ᵥ b` its dot product, so the
Euclidean length of an arrow `w` is `√(w ⬝ᵥ w)`.

The track is `γ`, labelled by distance travelled `σ` (metres). Near the point it carries the
Frenet-Serret frame of the earlier cards: unit tangent `T = γ'`, principal normal `N`, binormal
`B = T × N`, with `T' = κ N` and `N' = -κ T + τ B`. The clock is `s`: the skier is at distance
`s t` along the track at time `t`, so her position is `r = γ ∘ s` and her speed is `|ṡ|`.
-/

open Matrix Filter Topology Real

lemma ct_contDiffAt_deriv {f : ℝ → Fin 3 → ℝ} {x : ℝ} {n m : WithTop ℕ∞}
    (hf : ContDiffAt ℝ n f x) (h : m + 1 ≤ n) : ContDiffAt ℝ m (deriv f) x :=
  (hf.fderiv_right h).clm_apply contDiffAt_const
#print axioms ct_contDiffAt_deriv

lemma ct_contDiffAt_deriv_real {f : ℝ → ℝ} {x : ℝ} {n m : WithTop ℕ∞}
    (hf : ContDiffAt ℝ n f x) (h : m + 1 ≤ n) : ContDiffAt ℝ m (deriv f) x :=
  (hf.fderiv_right h).clm_apply contDiffAt_const
#print axioms ct_contDiffAt_deriv_real

lemma ct_derivs
    (γ T N B : ℝ → Fin 3 → ℝ) (κ τ s : ℝ → ℝ) (t : ℝ)
    (hframe : ∀ᶠ σ in 𝓝 (s t),
      HasDerivAt γ (T σ) σ ∧ HasDerivAt T (κ σ • N σ) σ ∧
      HasDerivAt N (-κ σ • T σ + τ σ • B σ) σ ∧
      T σ ⬝ᵥ T σ = 1 ∧ N σ ⬝ᵥ N σ = 1 ∧ T σ ⬝ᵥ N σ = 0 ∧ B σ = T σ ⨯₃ N σ)
    (hs : ContDiffAt ℝ 2 s t) :
    deriv (γ ∘ s) =ᶠ[𝓝 t] (fun u => deriv s u • T (s u)) ∧
    deriv (deriv (γ ∘ s)) =ᶠ[𝓝 t]
      (fun u => deriv (deriv s) u • T (s u) + (deriv s u ^ 2 * κ (s u)) • N (s u)) := by
  have hds : ContDiffAt ℝ 1 (deriv s) t := ct_contDiffAt_deriv_real hs (by norm_num)
  have e1 : ∀ᶠ u in 𝓝 t, DifferentiableAt ℝ s u :=
    (hs.eventually (by simp)).mono fun u h => h.differentiableAt (by simp)
  have e2 : ∀ᶠ u in 𝓝 t, DifferentiableAt ℝ (deriv s) u :=
    (hds.eventually (by simp)).mono fun u h => h.differentiableAt (by simp)
  have e3 := hs.continuousAt.tendsto.eventually hframe
  have h1 : ∀ᶠ u in 𝓝 t, HasDerivAt (γ ∘ s) (deriv s u • T (s u)) u :=
    (e1.and e3).mono fun u h => h.2.1.scomp u h.1.hasDerivAt
  have E1 : deriv (γ ∘ s) =ᶠ[𝓝 t] (fun u => deriv s u • T (s u)) := h1.mono fun u h => h.deriv
  have h2 : ∀ᶠ u in 𝓝 t, HasDerivAt (fun u => deriv s u • T (s u))
      (deriv (deriv s) u • T (s u) + (deriv s u ^ 2 * κ (s u)) • N (s u)) u := by
    filter_upwards [e1, e2, e3] with u hu1 hu2 hu3
    have := hu2.hasDerivAt.smul (hu3.2.1.scomp u hu1.hasDerivAt)
    have h' : HasDerivAt (fun u => deriv s u • T (s u)) _ u := this
    convert h' using 1
    rw [smul_smul, smul_smul, add_comm]
    congr 2
    ring
  refine ⟨E1, E1.deriv.trans (h2.mono fun u h => h.deriv)⟩
#print axioms ct_derivs

lemma ct_cross
    (γ T N B : ℝ → Fin 3 → ℝ) (κ τ s : ℝ → ℝ) (t : ℝ)
    (hframe : ∀ᶠ σ in 𝓝 (s t),
      HasDerivAt γ (T σ) σ ∧ HasDerivAt T (κ σ • N σ) σ ∧
      HasDerivAt N (-κ σ • T σ + τ σ • B σ) σ ∧
      T σ ⬝ᵥ T σ = 1 ∧ N σ ⬝ᵥ N σ = 1 ∧ T σ ⬝ᵥ N σ = 0 ∧ B σ = T σ ⨯₃ N σ)
    (hs : ContDiffAt ℝ 2 s t) :
    deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t = (deriv s t ^ 3 * κ (s t)) • B (s t) := by
  obtain ⟨E1, E2⟩ := ct_derivs γ T N B κ τ s t hframe hs
  rw [E1.eq_of_nhds, E2.eq_of_nhds, hframe.self_of_nhds.2.2.2.2.2.2]
  simp only [map_add, map_smul, LinearMap.smul_apply, cross_self, smul_zero,
    zero_add, smul_smul]
  congr 1
  ring
#print axioms ct_cross

lemma ct_helix_d1 (a c x : ℝ) :
    HasDerivAt (fun θ : ℝ => (![a * cos θ, -(a * sin θ), -(c * θ)] : Fin 3 → ℝ))
      ![-(a * sin x), -(a * cos x), -c] x := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · simpa using (hasDerivAt_cos x).const_mul a
  · simpa using (hasDerivAt_sin x).const_mul (-a)
  · simpa using (hasDerivAt_id x).const_mul (-c)
#print axioms ct_helix_d1

lemma ct_helix_d2 (a c x : ℝ) :
    HasDerivAt (fun θ : ℝ => (![-(a * sin θ), -(a * cos θ), -c] : Fin 3 → ℝ))
      ![-(a * cos x), a * sin x, 0] x := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · simpa using (hasDerivAt_sin x).const_mul (-a)
  · simpa using (hasDerivAt_cos x).const_mul (-a)
  · simpa using (hasDerivAt_const x (-c))
#print axioms ct_helix_d2

lemma ct_helix_d3 (a x : ℝ) :
    HasDerivAt (fun θ : ℝ => (![-(a * cos θ), a * sin θ, 0] : Fin 3 → ℝ))
      ![a * sin x, a * cos x, 0] x := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · simpa using (hasDerivAt_cos x).const_mul (-a)
  · simpa using (hasDerivAt_sin x).const_mul a
  · simpa using (hasDerivAt_const x (0 : ℝ))
#print axioms ct_helix_d3

/-- **Curvature and torsion at any speed.** Take a track `γ` labelled by distance, with its
Frenet-Serret frame `T`, `N`, `B` and curvature `κ`, torsion `τ` near the point `s t`, and time it
with any clock `s`, so the position at time `t` is `r(t) = γ(s(t))`. Suppose the speed is not zero
there (`ṡ(t) ≠ 0`), the curvature is not zero (`κ > 0`), and track and clock have three
derivatives. Then, from the clock derivatives of position alone (velocity `ṙ`, acceleration `r̈`,
jerk `r⃛`), the curvature is `|ṙ × r̈| / |ṙ|³` and the torsion is `((ṙ × r̈) · r⃛) / |ṙ × r̈|²`.
No relabelling by distance is needed. -/
theorem curvature_and_torsion_from_any_parametrisation
    (γ T N B : ℝ → Fin 3 → ℝ) (κ τ s : ℝ → ℝ) (t : ℝ)
    (hframe : ∀ᶠ σ in 𝓝 (s t),
      HasDerivAt γ (T σ) σ ∧ HasDerivAt T (κ σ • N σ) σ ∧
      HasDerivAt N (-κ σ • T σ + τ σ • B σ) σ ∧
      T σ ⬝ᵥ T σ = 1 ∧ N σ ⬝ᵥ N σ = 1 ∧ T σ ⬝ᵥ N σ = 0 ∧ B σ = T σ ⨯₃ N σ)
    (hγ : ContDiffAt ℝ 3 γ (s t)) (hs : ContDiffAt ℝ 3 s t)
    (hspeed : deriv s t ≠ 0) (hκ : 0 < κ (s t)) :
    κ (s t) =
        √((deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t) ⬝ᵥ
            (deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t)) /
          √(deriv (γ ∘ s) t ⬝ᵥ deriv (γ ∘ s) t) ^ 3 ∧
      τ (s t) =
        ((deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t) ⬝ᵥ deriv (deriv (deriv (γ ∘ s))) t) /
          ((deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t) ⬝ᵥ
            (deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t)) := by
  have hs2 : ContDiffAt ℝ 2 s t := hs.of_le (by norm_num)
  have hcross := ct_cross γ T N B κ τ s t hframe hs2
  obtain ⟨E1, E2⟩ := ct_derivs γ T N B κ τ s t hframe hs2
  obtain ⟨-, hTd, hNd, hTT, hNN, hTN, hB⟩ := hframe.self_of_nhds
  have hBT : B (s t) ⬝ᵥ T (s t) = 0 := by rw [hB, dotProduct_comm]; exact dot_self_cross _ _
  have hBN : B (s t) ⬝ᵥ N (s t) = 0 := by rw [hB, dotProduct_comm]; exact dot_cross_self _ _
  have hBB : B (s t) ⬝ᵥ B (s t) = 1 := by
    rw [hB, cross_dot_cross, hTT, hNN, hTN, dotProduct_comm (N _), hTN]; ring
  have hTev : T =ᶠ[𝓝 (s t)] deriv γ := hframe.mono fun σ h => h.1.deriv.symm
  have hTc : ContDiffAt ℝ 2 T (s t) :=
    (ct_contDiffAt_deriv hγ (by norm_num)).congr_of_eventuallyEq hTev
  have hGd : DifferentiableAt ℝ (deriv T) (s t) :=
    (ct_contDiffAt_deriv hTc (by norm_num) : ContDiffAt ℝ 1 _ _).differentiableAt (by simp)
  have hκev : κ =ᶠ[𝓝 (s t)] fun σ => deriv T σ ⬝ᵥ N σ := hframe.mono fun σ h => by
    show κ σ = deriv T σ ⬝ᵥ N σ
    rw [h.2.1.deriv, smul_dotProduct, h.2.2.2.2.1, smul_eq_mul, mul_one]
  have hκd : DifferentiableAt ℝ κ (s t) := by
    refine DifferentiableAt.congr_of_eventuallyEq ?_ hκev
    simp only [dotProduct]
    have hN' := hNd.differentiableAt
    fun_prop
  have hds2 : ContDiffAt ℝ 2 (deriv s) t := ct_contDiffAt_deriv_real hs (by norm_num)
  have hdds : ContDiffAt ℝ 1 (deriv (deriv s)) t := ct_contDiffAt_deriv_real hds2 (by norm_num)
  have hs1 : HasDerivAt s (deriv s t) t := (hs.differentiableAt (by simp)).hasDerivAt
  have hsd1 : HasDerivAt (deriv s) (deriv (deriv s) t) t :=
    (hds2.differentiableAt (by simp)).hasDerivAt
  have hsd2 : HasDerivAt (deriv (deriv s)) (deriv (deriv (deriv s)) t) t :=
    (hdds.differentiableAt (by simp)).hasDerivAt
  have H : HasDerivAt
      (fun u => deriv (deriv s) u • T (s u) + (deriv s u ^ 2 * κ (s u)) • N (s u)) _ t :=
    (hsd2.smul (hTd.scomp t hs1)).add
      (((hsd1.pow 2).mul (hκd.hasDerivAt.comp t hs1)).smul (hNd.scomp t hs1))
  have E3 := E2.deriv_eq.trans H.deriv
  rw [hcross, E3, E1.eq_of_nhds]
  simp only [dotProduct_add, dotProduct_smul, smul_dotProduct, hBT, hBN, hBB, hTT, smul_eq_mul]
  constructor
  · rw [mul_one, mul_one, Real.sqrt_mul_self_eq_abs, Real.sqrt_mul_self_eq_abs, abs_mul, abs_pow,
      abs_of_pos hκ]
    have : |deriv s t| ≠ 0 := abs_ne_zero.mpr hspeed
    field_simp
  · have hc : deriv s t ^ 3 * κ (s t) ≠ 0 := mul_ne_zero (pow_ne_zero _ hspeed) hκ.ne'
    simp only [Function.comp_apply, Pi.mul_apply, Pi.pow_apply, hBT, mul_zero, zero_add, add_zero, mul_one]
    field_simp

/-- **Velocity crossed with acceleration lies along the binormal.** On any clock `s` with two
derivatives, velocity crossed with acceleration is the clock rate cubed times the curvature,
pointing along the binormal: `ṙ × r̈ = ṡ³ κ B`. The part of the acceleration that only speeds the
skier up drops out. -/
theorem velocity_cross_acceleration_eq_speed_cubed_curvature_binormal
    (γ T N B : ℝ → Fin 3 → ℝ) (κ τ s : ℝ → ℝ) (t : ℝ)
    (hframe : ∀ᶠ σ in 𝓝 (s t),
      HasDerivAt γ (T σ) σ ∧ HasDerivAt T (κ σ • N σ) σ ∧
      HasDerivAt N (-κ σ • T σ + τ σ • B σ) σ ∧
      T σ ⬝ᵥ T σ = 1 ∧ N σ ⬝ᵥ N σ = 1 ∧ T σ ⬝ᵥ N σ = 0 ∧ B σ = T σ ⨯₃ N σ)
    (hs : ContDiffAt ℝ 2 s t) :
    deriv (γ ∘ s) t ⨯₃ deriv (deriv (γ ∘ s)) t = (deriv s t ^ 3 * κ (s t)) • B (s t) := by
  exact ct_cross γ T N B κ τ s t hframe hs

/-- **The bend in closed form.** The helix `θ ↦ (a cos θ, -a sin θ, -c θ)`, a bend of radius
`a > 0` seen from above that drops `c` metres per radian, labelled by the angle turned. At every
angle the any-speed formulas give the constants `κ = a / (a² + c²)` and `τ = c / (a² + c²)`. -/
theorem helix_curvature_and_torsion (a c θ : ℝ) (ha : 0 < a) :
    let r : ℝ → Fin 3 → ℝ := fun θ => ![a * cos θ, -(a * sin θ), -(c * θ)]
    √((deriv r θ ⨯₃ deriv (deriv r) θ) ⬝ᵥ (deriv r θ ⨯₃ deriv (deriv r) θ)) /
        √(deriv r θ ⬝ᵥ deriv r θ) ^ 3 = a / (a ^ 2 + c ^ 2) ∧
      ((deriv r θ ⨯₃ deriv (deriv r) θ) ⬝ᵥ deriv (deriv (deriv r)) θ) /
          ((deriv r θ ⨯₃ deriv (deriv r) θ) ⬝ᵥ (deriv r θ ⨯₃ deriv (deriv r) θ)) =
        c / (a ^ 2 + c ^ 2) := by
  intro r
  have h1 : deriv r = fun x => ![-(a * sin x), -(a * cos x), -c] :=
    funext fun x => (ct_helix_d1 a c x).deriv
  have h2 : deriv (fun x => (![-(a * sin x), -(a * cos x), -c] : Fin 3 → ℝ)) =
      fun x => ![-(a * cos x), a * sin x, 0] :=
    funext fun x => (ct_helix_d2 a c x).deriv
  have h3 : deriv (fun x => (![-(a * cos x), a * sin x, 0] : Fin 3 → ℝ)) θ =
      ![a * sin θ, a * cos θ, 0] := (ct_helix_d3 a θ).deriv
  rw [h1, h2, h3]
  simp only [cross_apply, dotProduct, Fin.sum_univ_succ]
  simp
  have hsc := sin_sq_add_cos_sq θ
  have e1 : c * (a * sin θ) * (c * (a * sin θ)) +
            (c * (a * cos θ) * (c * (a * cos θ)) +
              (-(a * sin θ * (a * sin θ)) - a * cos θ * (a * cos θ)) *
                (-(a * sin θ * (a * sin θ)) - a * cos θ * (a * cos θ))) = a ^ 2 * (a ^ 2 + c ^ 2) := by
    linear_combination (a ^ 2 * c ^ 2 + a ^ 4 * (sin θ ^ 2 + cos θ ^ 2 + 1)) * hsc
  have e2 : a * sin θ * (a * sin θ) + (a * cos θ * (a * cos θ) + c * c) = a ^ 2 + c ^ 2 := by
    linear_combination a ^ 2 * hsc
  have e3 : c * (a * sin θ) * (a * sin θ) + c * (a * cos θ) * (a * cos θ) = a ^ 2 * c := by
    linear_combination c * a ^ 2 * hsc
  have hq : 0 < a ^ 2 + c ^ 2 := by positivity
  have hsq : 0 < √(a ^ 2 + c ^ 2) := Real.sqrt_pos.mpr hq
  rw [e1, e2, e3, Real.sqrt_mul (sq_nonneg a), Real.sqrt_sq ha.le, pow_succ (√(a ^ 2 + c ^ 2)) 2,
    Real.sq_sqrt hq.le]
  constructor
  · field_simp
  · field_simp

/-! The card's worked numbers at the apex, skier A, in exact fractions: velocity
(0, -10, -2.25) m/s, acceleration (-2.5, -0.8, -0.18) m/s², jerk (-0.6, 0.625, 0) m/s³. -/

-- Angle rates: 10.25 / 41 = 0.25 rad/s and 0.82 / 41 = 0.02 rad/s².
example : (41 / 4 : ℚ) / 41 = 1 / 4 ∧ (41 / 50 : ℚ) / 41 = 1 / 50 := by norm_num

-- Velocity, acceleration and jerk by the chain rule from r_θ = (0, -40, -9),
-- r_θθ = (-40, 0, 0), r_θθθ = (0, 40, 0).
example : (1 / 4 : ℚ) • (![0, -40, -9] : Fin 3 → ℚ) = ![0, -10, -9 / 4] := by
  ext i; fin_cases i <;> norm_num
example : (1 / 50 : ℚ) • (![0, -40, -9] : Fin 3 → ℚ) + (1 / 4 : ℚ) ^ 2 • ![-40, 0, 0] =
    ![-5 / 2, -4 / 5, -9 / 50] := by
  ext i; fin_cases i <;> norm_num
example : (3 * (1 / 4) * (1 / 50) : ℚ) • (![-40, 0, 0] : Fin 3 → ℚ) + (1 / 4 : ℚ) ^ 3 • ![0, 40, 0] =
    ![-3 / 5, 5 / 8, 0] := by
  ext i; fin_cases i <;> norm_num

-- ṙ × r̈ = (0, 5.625, -25).
example : (![0, -10, -9 / 4] : Fin 3 → ℚ) ⨯₃ ![-5 / 2, -4 / 5, -9 / 50] = ![0, 45 / 8, -25] := by
  rw [cross_apply]; ext i; fin_cases i <;> norm_num

-- |ṙ × r̈|² = 656.640625 = 25.625², and |ṙ|² = 10.25².
example : (![0, 45 / 8, -25] : Fin 3 → ℚ) ⬝ᵥ ![0, 45 / 8, -25] = (205 / 8) ^ 2 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : (![0, -10, -9 / 4] : Fin 3 → ℚ) ⬝ᵥ ![0, -10, -9 / 4] = (41 / 4) ^ 2 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num

-- Curvature 25.625 / 10.25³ = 40/1681 (0.023795 per m); its radius is 1681/40 m (42.025 m).
example : (205 / 8 : ℚ) / (41 / 4) ^ 3 = 40 / 1681 ∧ 1 / (40 / 1681 : ℚ) = 1681 / 40 := by norm_num

-- Triple product 3.515625 and torsion 3.515625 / 656.640625 = 9/1681 (0.005354 per m).
example : (![0, 45 / 8, -25] : Fin 3 → ℚ) ⬝ᵥ ![-3 / 5, 5 / 8, 0] = 225 / 64 := by
  simp [dotProduct, Fin.sum_univ_succ]; norm_num
example : (225 / 64 : ℚ) / (205 / 8) ^ 2 = 9 / 1681 := by norm_num

-- Closed form with a = 40, c = 9: a² + c² = 1681 = 41², κ = 40/1681, τ = 9/1681, τ/κ = 0.225.
example : (40 : ℚ) ^ 2 + 9 ^ 2 = 41 ^ 2 ∧ (9 / 1681 : ℚ) / (40 / 1681) = 9 / 40 := by norm_num

-- What breaks: |r̈| / |ṙ|² counts speeding up as bending; |r̈|² = 6.9224 > (κ |ṙ|²)² = 6.25.
example : (![-5 / 2, -4 / 5, -9 / 50] : Fin 3 → ℚ) ⬝ᵥ ![-5 / 2, -4 / 5, -9 / 50] = 43265 / 6250 ∧
    (40 / 1681 * (41 / 4) ^ 2 : ℚ) ^ 2 < 43265 / 6250 := by
  constructor
  · simp [dotProduct, Fin.sum_univ_succ]; norm_num
  · norm_num

#print axioms curvature_and_torsion_from_any_parametrisation
#print axioms velocity_cross_acceleration_eq_speed_cubed_curvature_binormal
#print axioms helix_curvature_and_torsion
