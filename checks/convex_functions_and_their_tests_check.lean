-- Convex functions: for a function with two continuous derivatives on an open convex set, the chord test, the tangent test and the curvature test are equivalent, curvature between μ and L sandwiches the function between two bowls, and the roaster's bitterness formula is convex on the strip t > −2 ln 2.
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.List.TFAE
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib

open Set

theorem cvx_core_1d {g g' g'' : ℝ → ℝ} {m : ℝ}
    (hg : ∀ t ∈ Icc (0:ℝ) 1, HasDerivAt g (g' t) t)
    (hg' : ∀ t ∈ Icc (0:ℝ) 1, HasDerivAt g' (g'' t) t)
    (hm : ∀ t ∈ Icc (0:ℝ) 1, m ≤ g'' t) :
    g 0 + g' 0 + m / 2 ≤ g 1 := by
  have hkd : ∀ t ∈ Icc (0:ℝ) 1,
      HasDerivAt (fun u => g' u - g' 0 - m * u) (g'' t - m) t := by
    intro t ht
    have h := ((hg' t ht).sub_const (g' 0)).sub ((hasDerivAt_id t).const_mul m)
    convert h using 1
    all_goals first | rfl | ring
  have hkmono : MonotoneOn (fun u => g' u - g' 0 - m * u) (Icc 0 1) :=
    monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 1) (f' := fun t => g'' t - m)
      (fun t ht => (hkd t ht).continuousAt.continuousWithinAt)
      (fun t ht => (hkd t (interior_subset ht)).hasDerivWithinAt)
      (fun t ht => sub_nonneg.2 (hm t (interior_subset ht)))
  have hk0 : ∀ t ∈ Icc (0:ℝ) 1, 0 ≤ g' t - g' 0 - m * t := by
    intro t ht
    have := hkmono ⟨le_refl 0, zero_le_one⟩ ht ht.1
    simpa using this
  have hhd : ∀ t ∈ Icc (0:ℝ) 1, HasDerivAt (fun u => g u - g 0 - u * g' 0 - m / 2 * u ^ 2)
      (g' t - g' 0 - m * t) t := by
    intro t ht
    have h1 := ((hg t ht).sub_const (g 0)).sub ((hasDerivAt_id t).mul_const (g' 0))
    have h2 := (hasDerivAt_pow 2 t).const_mul (m / 2)
    convert h1.sub h2 using 1
    all_goals first | rfl | (simp; ring)
  have hhmono : MonotoneOn (fun u => g u - g 0 - u * g' 0 - m / 2 * u ^ 2) (Icc 0 1) :=
    monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc 0 1)
      (fun t ht => (hhd t ht).continuousAt.continuousWithinAt)
      (fun t ht => (hhd t (interior_subset ht)).hasDerivWithinAt)
      (fun t ht => hk0 t (interior_subset ht))
  have := hhmono ⟨le_refl 0, zero_le_one⟩ ⟨zero_le_one, le_refl 1⟩ zero_le_one
  simp at this
  linarith

#print axioms cvx_core_1d

theorem cvx_line_deriv {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hopen : IsOpen s) (hf : ContDiffOn ℝ 2 f s)
    (x d : EuclideanSpace ℝ (Fin n)) (t : ℝ) (ht : x + t • d ∈ s) :
    HasDerivAt (fun u : ℝ => f (x + u • d)) (fderiv ℝ f (x + t • d) d) t ∧
    HasDerivAt (fun u : ℝ => fderiv ℝ f (x + u • d) d)
      (fderiv ℝ (fderiv ℝ f) (x + t • d) d d) t := by
  have hline : HasDerivAt (fun u : ℝ => x + u • d) d t := by
    simpa using ((hasDerivAt_id t).smul_const d).const_add x
  have h112 : (1 : WithTop ℕ∞) + 1 ≤ 2 := le_of_eq rfl
  have hdf : DifferentiableAt ℝ f (x + t • d) :=
    (hf.differentiableOn (by simp)).differentiableAt (hopen.mem_nhds ht)
  have hdf2 : DifferentiableAt ℝ (fderiv ℝ f) (x + t • d) :=
    ((hf.fderiv_of_isOpen hopen h112).differentiableOn
      one_ne_zero).differentiableAt (hopen.mem_nhds ht)
  refine ⟨hdf.hasFDerivAt.comp_hasDerivAt t hline, ?_⟩
  have h1 : HasDerivAt (fun u : ℝ => fderiv ℝ f (x + u • d))
      (fderiv ℝ (fderiv ℝ f) (x + t • d) d) t := hdf2.hasFDerivAt.comp_hasDerivAt t hline
  exact (ContinuousLinearMap.apply ℝ ℝ d :
    (EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ) →L[ℝ] ℝ).hasFDerivAt.comp_hasDerivAt t h1

#print axioms cvx_line_deriv

theorem cvx_lower {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hopen : IsOpen s) (hs : Convex ℝ s)
    (hf : ContDiffOn ℝ 2 f s) (μ : ℝ)
    (hμ : ∀ z ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), μ * ‖v‖ ^ 2 ≤ fderiv ℝ (fderiv ℝ f) z v v)
    {x y : EuclideanSpace ℝ (Fin n)} (hx : x ∈ s) (hy : y ∈ s) :
    f x + fderiv ℝ f x (y - x) + μ / 2 * ‖y - x‖ ^ 2 ≤ f y := by
  have hmem : ∀ t ∈ Icc (0:ℝ) 1, x + t • (y - x) ∈ s :=
    fun t ht => hs.add_smul_sub_mem hx hy ht
  have := cvx_core_1d (g := fun u => f (x + u • (y - x)))
    (g' := fun u => fderiv ℝ f (x + u • (y - x)) (y - x))
    (g'' := fun u => fderiv ℝ (fderiv ℝ f) (x + u • (y - x)) (y - x) (y - x))
    (m := μ * ‖y - x‖ ^ 2)
    (fun t ht => (cvx_line_deriv hopen hf x (y - x) t (hmem t ht)).1)
    (fun t ht => (cvx_line_deriv hopen hf x (y - x) t (hmem t ht)).2)
    (fun t ht => hμ _ (hmem t ht) _)
  simp only [zero_smul, add_zero, one_smul, add_sub_cancel] at this
  linarith

#print axioms cvx_lower

theorem cvx_upper {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hopen : IsOpen s) (hs : Convex ℝ s)
    (hf : ContDiffOn ℝ 2 f s) (L : ℝ)
    (hL : ∀ z ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), fderiv ℝ (fderiv ℝ f) z v v ≤ L * ‖v‖ ^ 2)
    {x y : EuclideanSpace ℝ (Fin n)} (hx : x ∈ s) (hy : y ∈ s) :
    f y ≤ f x + fderiv ℝ f x (y - x) + L / 2 * ‖y - x‖ ^ 2 := by
  have hmem : ∀ t ∈ Icc (0:ℝ) 1, x + t • (y - x) ∈ s :=
    fun t ht => hs.add_smul_sub_mem hx hy ht
  have := cvx_core_1d (g := fun u => -f (x + u • (y - x)))
    (g' := fun u => -fderiv ℝ f (x + u • (y - x)) (y - x))
    (g'' := fun u => -fderiv ℝ (fderiv ℝ f) (x + u • (y - x)) (y - x) (y - x))
    (m := -(L * ‖y - x‖ ^ 2))
    (fun t ht => (cvx_line_deriv hopen hf x (y - x) t (hmem t ht)).1.neg)
    (fun t ht => (cvx_line_deriv hopen hf x (y - x) t (hmem t ht)).2.neg)
    (fun t ht => neg_le_neg (hL _ (hmem t ht) _))
  simp only [zero_smul, add_zero, one_smul, add_sub_cancel] at this
  linarith

#print axioms cvx_upper

theorem roaster_aux :
    ConvexOn ℝ (Ioi (-2 * Real.log 2)) (fun t : ℝ => Real.exp (t / 2) - t ^ 2 / 16) := by
  have hd1 : ∀ t : ℝ, HasDerivAt (fun t : ℝ => Real.exp (t / 2) - t ^ 2 / 16)
      (Real.exp (t / 2) / 2 - t / 8) t := by
    intro t
    have h := ((Real.hasDerivAt_exp (t / 2)).comp t ((hasDerivAt_id t).div_const 2)).sub
      ((hasDerivAt_pow 2 t).div_const 16)
    convert h using 1
    all_goals first | rfl | (simp; ring)
  have hd2 : ∀ t : ℝ, HasDerivAt (fun t : ℝ => Real.exp (t / 2) / 2 - t / 8)
      (Real.exp (t / 2) / 4 - 1 / 8) t := by
    intro t
    have h := (((Real.hasDerivAt_exp (t / 2)).comp t ((hasDerivAt_id t).div_const 2)).div_const 2).sub
      ((hasDerivAt_id t).div_const 8)
    convert h using 1
    all_goals first | rfl | (simp; ring)
  refine convexOn_of_hasDerivWithinAt2_nonneg (convex_Ioi _)
    (f' := fun t => Real.exp (t / 2) / 2 - t / 8) (f'' := fun t => Real.exp (t / 2) / 4 - 1 / 8)
    (fun t _ => (hd1 t).continuousAt.continuousWithinAt)
    (fun t _ => (hd1 t).hasDerivWithinAt) (fun t _ => (hd2 t).hasDerivWithinAt) ?_
  intro t ht
  rw [interior_Ioi] at ht
  have hlt : Real.exp (-2 * Real.log 2 / 2) < Real.exp (t / 2) :=
    Real.exp_lt_exp.2 (by have := ht.out; linarith)
  have h2 : Real.exp (-2 * Real.log 2 / 2) = 1 / 2 := by
    rw [show -2 * Real.log 2 / 2 = -Real.log 2 by ring, Real.exp_neg,
      Real.exp_log (by norm_num)]
    norm_num
  show 0 ≤ Real.exp (t / 2) / 4 - 1 / 8
  linarith

#print axioms roaster_aux


/-- **Chord, tangent and curvature are one test.** Let s be an open set of points in n variables
that holds the whole segment between any two of its points (an open convex set), and let f have
two continuous derivatives on s. Then these three statements are equivalent:
1. (chord) f is convex on s: f(θx + (1 − θ)y) ≤ θ f(x) + (1 − θ) f(y) for x, y in s and
   0 ≤ θ ≤ 1;
2. (tangent) every tangent plane lies under the graph: f(y) ≥ f(x) + ∇f(x)ᵀ(y − x) for x, y in s;
3. (curvature) the Hessian is positive semidefinite at every point of s: vᵀ ∇²f(x) v ≥ 0 for
   every direction v. -/
theorem chord_iff_tangent_iff_curvature {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hopen : IsOpen s) (hs : Convex ℝ s)
    (hf : ContDiffOn ℝ 2 f s) :
    List.TFAE
      [ConvexOn ℝ s f,
       ∀ x ∈ s, ∀ y ∈ s, f x + fderiv ℝ f x (y - x) ≤ f y,
       ∀ x ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), 0 ≤ fderiv ℝ (fderiv ℝ f) x v v] := by
  tfae_have 1 → 2 := by
    intro hc x hx y hy
    obtain ⟨hd, -⟩ := cvx_line_deriv hopen hf x (y - x) 0 (by simpa using hx)
    simp only [zero_smul, add_zero] at hd
    rw [hasDerivAt_iff_tendsto_slope] at hd
    have hd' := hd.mono_left (nhdsWithin_mono _
      (show Ioi (0:ℝ) ⊆ {0}ᶜ from fun t ht => ne_of_gt ht))
    have key : fderiv ℝ f x (y - x) ≤ f y - f x := by
      refine le_of_tendsto hd' ?_
      filter_upwards [Ioo_mem_nhdsGT zero_lt_one] with t ht
      rw [slope_def_field]
      simp only [zero_smul, add_zero, sub_zero]
      rw [div_le_iff₀ ht.1]
      have hconv := hc.2 hx hy (show (0:ℝ) ≤ 1 - t by linarith [ht.2]) ht.1.le
        (show 1 - t + t = 1 by ring)
      have heq : (1 - t) • x + t • y = x + t • (y - x) := by
        rw [smul_sub, sub_smul, one_smul]; abel
      rw [heq, smul_eq_mul, smul_eq_mul] at hconv
      nlinarith [hconv]
    linarith
  tfae_have 2 → 1 := by
    intro h2
    refine ⟨hs, fun x hx y hy a b ha hb hab => ?_⟩
    have hz := hs hx hy ha hb hab
    have e1 := h2 _ hz x hx
    have e2 := h2 _ hz y hy
    obtain rfl : b = 1 - a := by linarith
    have hzero : a • (x - (a • x + (1 - a) • y)) + (1 - a) • (y - (a • x + (1 - a) • y)) = 0 := by
      module
    have hlin : a * fderiv ℝ f (a • x + (1 - a) • y) (x - (a • x + (1 - a) • y)) +
        (1 - a) * fderiv ℝ f (a • x + (1 - a) • y) (y - (a • x + (1 - a) • y)) = 0 := by
      rw [← smul_eq_mul, ← smul_eq_mul, ← map_smul, ← map_smul, ← map_add, hzero, map_zero]
    simp only [smul_eq_mul]
    nlinarith [mul_le_mul_of_nonneg_left e1 ha, mul_le_mul_of_nonneg_left e2 hb]
  tfae_have 2 → 3 := by
    intro h2 x hx v
    obtain ⟨-, hd⟩ := cvx_line_deriv hopen hf x v 0 (by simpa using hx)
    simp only [zero_smul, add_zero] at hd
    rw [hasDerivAt_iff_tendsto_slope] at hd
    refine ge_of_tendsto hd ?_
    have hev : ∀ᶠ t in nhds (0:ℝ), x + t • v ∈ s := by
      have hc : Continuous fun t : ℝ => x + t • v := by fun_prop
      exact hc.continuousAt.preimage_mem_nhds (by simpa using hopen.mem_nhds hx)
    filter_upwards [nhdsWithin_le_nhds hev, self_mem_nhdsWithin] with t ht htne
    have htne' : t ≠ 0 := htne
    rw [slope_def_field, sub_zero]
    simp only [zero_smul, add_zero]
    have a1 := h2 x hx _ ht
    have a2 := h2 _ ht x hx
    have r1 : x + t • v - x = t • v := by abel
    have r2 : x - (x + t • v) = -(t • v) := by abel
    rw [r1, map_smul, smul_eq_mul] at a1
    rw [r2, map_neg, map_smul, smul_eq_mul] at a2
    have hprod : 0 ≤ t * (fderiv ℝ f (x + t • v) v - fderiv ℝ f x v) := by
      rw [mul_sub]; linarith
    rw [show (fderiv ℝ f (x + t • v) v - fderiv ℝ f x v) / t =
      t * (fderiv ℝ f (x + t • v) v - fderiv ℝ f x v) / t ^ 2 by field_simp]
    exact div_nonneg hprod (sq_nonneg t)
  tfae_have 3 → 2 := by
    intro h3 x hx y hy
    have := cvx_lower hopen hs hf 0 (fun z hz v => by simpa using h3 z hz v) hx hy
    simpa using this
  tfae_finish

/-- **The μ–L sandwich.** Let f have two continuous derivatives on an open convex set s in n
variables, and let its curvature be boxed in on all of s: μ‖v‖² ≤ vᵀ ∇²f(z) v ≤ L‖v‖² for every
point z of s and every direction v. Then for any x and y in s the value f(y) sits above the
tangent plus a bowl of curvature μ and below the tangent plus a bowl of curvature L:
f(x) + ∇f(x)ᵀ(y − x) + (μ/2)‖y − x‖² ≤ f(y) ≤ f(x) + ∇f(x)ᵀ(y − x) + (L/2)‖y − x‖². -/
theorem tangent_sandwich_of_curvature_bounds {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hopen : IsOpen s) (hs : Convex ℝ s)
    (hf : ContDiffOn ℝ 2 f s) (μ L : ℝ)
    (hμ : ∀ z ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), μ * ‖v‖ ^ 2 ≤ fderiv ℝ (fderiv ℝ f) z v v)
    (hL : ∀ z ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), fderiv ℝ (fderiv ℝ f) z v v ≤ L * ‖v‖ ^ 2)
    {x y : EuclideanSpace ℝ (Fin n)} (hx : x ∈ s) (hy : y ∈ s) :
    f x + fderiv ℝ f x (y - x) + μ / 2 * ‖y - x‖ ^ 2 ≤ f y ∧
      f y ≤ f x + fderiv ℝ f x (y - x) + L / 2 * ‖y - x‖ ^ 2 := by
  exact ⟨cvx_lower hopen hs hf μ hμ hx hy, cvx_upper hopen hs hf L hL hx hy⟩

/-- **The roaster's bitterness formula is convex.** With t the roast time past first crack and
w the robusta share, B(t, w) = 1 + e^(t/2) + t·w + 4w² is convex on the whole strip of recipes
with t > −2 ln 2 (about −1.3863), which holds every real recipe: every chord of B over that strip
lies on or above its graph. -/
theorem roaster_bitterness_convex :
    ConvexOn ℝ {p : ℝ × ℝ | -2 * Real.log 2 < p.1}
      (fun p : ℝ × ℝ => 1 + Real.exp (p.1 / 2) + p.1 * p.2 + 4 * p.2 ^ 2) := by
  have e : (fun p : ℝ × ℝ => 1 + Real.exp (p.1 / 2) + p.1 * p.2 + 4 * p.2 ^ 2) =
      fun p => ((Real.exp (p.1 / 2) - p.1 ^ 2 / 16) + 4 * (p.2 + p.1 / 8) ^ 2) + 1 := by
    funext p; ring
  rw [e]
  have hA : ConvexOn ℝ {p : ℝ × ℝ | -2 * Real.log 2 < p.1}
      (fun p : ℝ × ℝ => Real.exp (p.1 / 2) - p.1 ^ 2 / 16) :=
    roaster_aux.comp_linearMap (LinearMap.fst ℝ ℝ ℝ)
  have hconv : Convex ℝ {p : ℝ × ℝ | -2 * Real.log 2 < p.1} := hA.1
  have hB : ConvexOn ℝ {p : ℝ × ℝ | -2 * Real.log 2 < p.1}
      (fun p : ℝ × ℝ => 4 * (p.2 + p.1 / 8) ^ 2) := by
    have := (((Even.convexOn_pow (𝕜 := ℝ) even_two).comp_linearMap
      (LinearMap.snd ℝ ℝ ℝ + (1 / 8 : ℝ) • LinearMap.fst ℝ ℝ ℝ)).smul
      (c := (4 : ℝ)) (by norm_num)).subset (subset_univ _) hconv
    refine this.congr ?_
    intro p _
    simp only [Function.comp_apply, LinearMap.add_apply, LinearMap.smul_apply,
      LinearMap.fst_apply, LinearMap.snd_apply, smul_eq_mul]
    ring
  exact (hA.add hB).add_const 1

-- Halfway between recipe A (1 min, 40% robusta) and recipe C (3 min, 10%) is (2 min, 25%).
example : (1 / 2 : ℝ) • ((1 : ℝ), (2 / 5 : ℝ)) + (1 / 2 : ℝ) • ((3 : ℝ), (1 / 10 : ℝ)) =
    ((2 : ℝ), (1 / 4 : ℝ)) := by
  norm_num
-- Costs at £9 arabica and £5 robusta: A £7.40, C £8.60, halfway £8.00 a kilo.
example : (9 * (3 / 5) + 5 * (2 / 5) : ℚ) = 37 / 5 ∧ (9 * (9 / 10) + 5 * (1 / 10) : ℚ) = 43 / 5 ∧
    (9 * (3 / 4) + 5 * (1 / 4) : ℚ) = 8 := by
  norm_num
-- The step from A to C is (2, −0.3); the tangent floor at (3 min, 40%) adds 4.2 × 0 in w.
example : ((3 : ℚ) - 1, (1 / 10 : ℚ) - 2 / 5) = (2, -3 / 10) ∧ (21 / 5 : ℚ) * (2 / 5 - 2 / 5) = 0 := by
  norm_num
-- Hessian [[e^(t/2)/4, k], [k, 8]]: its determinant is 2e^(t/2) − k², so 2e^(t/2) − 1 when k = 1.
example (t k : ℝ) : Real.exp (t / 2) / 4 * 8 - k * k = 2 * Real.exp (t / 2) - k ^ 2 := by ring
-- With k = 4, the corner recipe (0 min, 50% robusta) scores exactly 3.
example : 1 + Real.exp ((0 : ℝ) / 2) + 4 * 0 * (1 / 2) + 4 * (1 / 2 : ℝ) ^ 2 = 3 := by
  norm_num
-- Step 2's slope terms cancel: θ(x − z) + (1 − θ)(y − z) = 0 when z = θx + (1 − θ)y.
example (θ x y : ℝ) : θ * (x - (θ * x + (1 - θ) * y)) + (1 - θ) * (y - (θ * x + (1 - θ) * y)) = 0 := by
  ring

#print axioms chord_iff_tangent_iff_curvature
#print axioms tangent_sandwich_of_curvature_bounds
#print axioms roaster_bitterness_convex
