-- Local and global minima: no search that asks finitely many questions can tell a continuous cost from one with a far cheaper hidden dip, slope zero with positive curvature certifies a strict local minimum, and a true slope bound turns a grid into a floor under every cost.
import Mathlib.Analysis.Calculus.DerivativeTest
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.Calculus.BumpFunction.InnerProduct
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Set Filter Topology

namespace LocalGlobalMinima

/-- A search that asks `questions` questions. Each answer is the pair (cost, slope) at the point
asked. `next answers` is the point it asks about after hearing the answers so far, and
`report answers` is the point it reports once it has heard all of them. Any rule at all is
allowed: by hand, by computer, adaptive or fixed in advance. -/
structure Search where
  questions : ℕ
  next : List (ℝ × ℝ) → ℝ
  report : List (ℝ × ℝ) → ℝ

/-- The answers a search has heard from the cost `f` after `k` questions: the cost and the slope
at each point it asked about, in order. -/
noncomputable def Search.answers (S : Search) (f : ℝ → ℝ) : ℕ → List (ℝ × ℝ)
  | 0 => []
  | k + 1 =>
      S.answers f k ++ [(f (S.next (S.answers f k)), deriv f (S.next (S.answers f k)))]

/-- The point the search reports when run on the cost `f`. -/
noncomputable def Search.result (S : Search) (f : ℝ → ℝ) : ℝ :=
  S.report (S.answers f S.questions)

/-- Helper: a slope bound on `[a, b]` bounds the change in cost between two points of it. -/
theorem abs_sub_le_of_deriv_bound (f : ℝ → ℝ) (a b L : ℝ)
    (hf : DifferentiableOn ℝ f (Icc a b)) (hL : ∀ x ∈ Icc a b, |deriv f x| ≤ L)
    {u v : ℝ} (hu : u ∈ Icc a b) (hv : v ∈ Icc a b) (huv : u < v) :
    |f v - f u| ≤ L * (v - u) := by
  have hsub : Icc u v ⊆ Icc a b := Icc_subset_Icc hu.1 hv.2
  obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f huv (hf.continuousOn.mono hsub)
    ((hf.mono hsub).mono Ioo_subset_Icc_self)
  have hcI : c ∈ Icc a b := ⟨hu.1.trans hc.1.le, hc.2.le.trans hv.2⟩
  have h := hL c hcI
  have hpos : 0 < v - u := sub_pos.2 huv
  rw [hcd, abs_div, abs_of_pos hpos, div_le_iff₀ hpos] at h
  exact h

#print axioms abs_sub_le_of_deriv_bound

/-- No finite search certifies a global minimum. Let the allowed range `[a, b]` be closed and
the cost `f` continuous on it. Whatever search is run, there is another cost `g`, continuous on
the range, that gives the search exactly the same costs and slopes at every point it asks about,
so the search reports the same point `x̂`. Yet `g` dips below any level `M` you name somewhere in
the range, and below `g(x̂)`, so `x̂` is not a global minimiser of `g`. The difference `g - f` is
a smooth hidden dip, so `g` is as smooth as `f`, and `g` equals `f` near `x̂`, so a local
minimiser of `f` stays a local minimiser of `g`. -/
theorem no_finite_search_certifies_global_minimum (a b : ℝ) (hab : a < b) (f : ℝ → ℝ)
    (hf : ContinuousOn f (Icc a b)) (S : Search) (M : ℝ) :
    ∃ g : ℝ → ℝ, ContinuousOn g (Icc a b) ∧ (∀ k : ℕ, ContDiff ℝ k (g - f)) ∧
      S.answers g S.questions = S.answers f S.questions ∧
      S.result g = S.result f ∧
      g =ᶠ[𝓝 (S.result f)] f ∧
      ∃ y ∈ Icc a b, g y < M ∧ g y < g (S.result g) := by
  classical
  let F : Finset ℝ := insert (S.result f)
    ((Finset.range S.questions).image fun k => S.next (S.answers f k))
  obtain ⟨y, hyI, hyF⟩ := (Set.Icc_infinite hab).exists_notMem_finset F
  have hδ : ∀ᶠ δ in 𝓝[>] (0:ℝ), δ ∈ Ioi (0:ℝ) ∧ ∀ p ∈ F, δ < dist p y := by
    refine Filter.Eventually.and (self_mem_nhdsWithin (s := Ioi (0:ℝ)) (a := 0)) ?_
    apply nhdsWithin_le_nhds
    refine (Finset.eventually_all F).2 ?_
    intro p hp
    exact eventually_lt_nhds (dist_pos.2 (by rintro rfl; exact hyF hp))
  obtain ⟨δ, hδ0, hδF⟩ := hδ.exists
  have hδ0' : (0:ℝ) < δ := hδ0
  let φ : ContDiffBump y := ⟨δ / 2, δ, by positivity, by linarith⟩
  let c : ℝ := |f y| + |M| + |f (S.result f)| + 1
  let g : ℝ → ℝ := fun x => f x - c * φ x
  have hφy : φ y = 1 := φ.one_of_mem_closedBall (Metric.mem_closedBall_self (by
    show (0:ℝ) ≤ δ / 2
    positivity))
  have hloc : ∀ p ∈ F, g =ᶠ[𝓝 p] f := by
    intro p hp
    have hopen : IsOpen {x : ℝ | δ < dist x y} :=
      isOpen_lt continuous_const (continuous_id.dist continuous_const)
    filter_upwards [hopen.mem_nhds (hδF p hp)] with x hx
    have h0 : φ x = 0 := φ.zero_of_le_dist (le_of_lt hx)
    simp [g, h0]
  have hans : ∀ k ≤ S.questions, S.answers g k = S.answers f k := by
    intro k
    induction k with
    | zero => intro _; rfl
    | succ k ih =>
      intro hk
      have ih' := ih (by omega)
      have hp : S.next (S.answers f k) ∈ F := Finset.mem_insert_of_mem
        (Finset.mem_image.2 ⟨k, Finset.mem_range.2 (by omega), rfl⟩)
      have he := hloc _ hp
      simp only [Search.answers, ih', he.eq_of_nhds, he.deriv_eq]
  have hres : S.result g = S.result f := by
    unfold Search.result
    rw [hans _ le_rfl]
  have hrF : S.result f ∈ F := Finset.mem_insert_self _ _
  refine ⟨g, ?_, ?_, hans _ le_rfl, hres, hloc _ hrF, y, hyI, ?_, ?_⟩
  · exact hf.sub (continuous_const.mul φ.continuous).continuousOn
  · intro k
    have hgf : g - f = fun x => -c * φ x := by
      ext x
      simp only [g, Pi.sub_apply]
      ring
    rw [hgf]
    exact contDiff_const.mul φ.contDiff
  · simp only [g, hφy, c]
    linarith [le_abs_self (f y), neg_abs_le M, abs_nonneg (f (S.result f))]
  · rw [hres, (hloc _ hrF).eq_of_nhds]
    simp only [g, hφy, c]
    linarith [le_abs_self (f y), neg_abs_le (f (S.result f)), abs_nonneg M]

/-- The local certificate. For a smooth cost, slope zero and positive curvature at `x₀` make
`x₀` a strict local minimum: every other point near `x₀` costs strictly more. -/
theorem slope_zero_positive_curvature_strict_local_min (f : ℝ → ℝ) (x₀ : ℝ)
    (hf : ContDiff ℝ 2 f) (hslope : deriv f x₀ = 0) (hcurv : 0 < deriv (deriv f) x₀) :
    ∀ᶠ x in 𝓝[≠] x₀, f x₀ < f x := by
  have hd : Differentiable ℝ f := hf.differentiable (by norm_num)
  have hs := eventually_nhdsWithin_sign_eq_of_deriv_pos (f := deriv f) hcurv hslope
  have hpos := deriv_pos_right_of_sign_deriv (nhdsWithin_le_nhds hs)
  have hneg := deriv_neg_left_of_sign_deriv (nhdsWithin_le_nhds hs)
  obtain ⟨c, hc, hcs⟩ := (nhdsGT_basis x₀).eventually_iff.mp hpos
  obtain ⟨a, ha, has⟩ := (nhdsLT_basis x₀).eventually_iff.mp hneg
  filter_upwards [nhdsWithin_le_nhds (Ioo_mem_nhds ha hc), self_mem_nhdsWithin] with x hx hne
  rcases lt_or_gt_of_ne (show x ≠ x₀ from hne) with hlt | hlt
  · have hanti : StrictAntiOn f (Icc x x₀) := by
      apply strictAntiOn_of_deriv_neg (convex_Icc x x₀) hd.continuous.continuousOn
      intro y hy
      rw [interior_Icc] at hy
      exact has ⟨hx.1.trans hy.1, hy.2⟩
    exact hanti ⟨le_rfl, hlt.le⟩ ⟨hlt.le, le_rfl⟩ hlt
  · have hmono : StrictMonoOn f (Icc x₀ x) := by
      apply strictMonoOn_of_deriv_pos (convex_Icc x₀ x) hd.continuous.continuousOn
      intro y hy
      rw [interior_Icc] at hy
      exact hcs ⟨hy.1, hy.2.trans hx.2⟩
    exact hmono ⟨le_rfl, hlt.le⟩ ⟨hlt.le, le_rfl⟩ hlt

/-- The grid certificate with a true slope bound. If no slope on `[a, b]` is steeper than `L`,
every allowed point lies within `h / 2` of some grid point, and every grid cost is at least `m`,
then no allowed point costs less than `m - L h / 2`. -/
theorem slope_bound_grid_floor (f : ℝ → ℝ) (a b L h m : ℝ) (G : Finset ℝ)
    (hf : DifferentiableOn ℝ f (Icc a b)) (hL : ∀ x ∈ Icc a b, |deriv f x| ≤ L)
    (hG : ∀ p ∈ G, p ∈ Icc a b) (hcover : ∀ x ∈ Icc a b, ∃ p ∈ G, |x - p| ≤ h / 2)
    (hm : ∀ p ∈ G, m ≤ f p) :
    ∀ x ∈ Icc a b, m - L * h / 2 ≤ f x := by
  intro x hx
  obtain ⟨p, hp, hxp⟩ := hcover x hx
  have hpI := hG p hp
  have hmp := hm p hp
  have hL0 : 0 ≤ L := (abs_nonneg _).trans (hL x hx)
  have key : |f x - f p| ≤ L * |x - p| := by
    rcases lt_trichotomy x p with hlt | hlt | hlt
    · rw [abs_sub_comm, abs_sub_comm x p, abs_of_pos (sub_pos.2 hlt)]
      exact abs_sub_le_of_deriv_bound f a b L hf hL hx hpI hlt
    · subst hlt
      simp
    · rw [abs_of_pos (sub_pos.2 hlt)]
      exact abs_sub_le_of_deriv_bound f a b L hf hL hpI hx hlt
  have h1 := neg_abs_le (f x - f p)
  have h2 : L * |x - p| ≤ L * (h / 2) := mul_le_mul_of_nonneg_left hxp hL0
  nlinarith

/-- The blend's cost of a kilo, in pounds, at Ethiopian share `x`: beans `8.2 + 5x` plus the
taste penalty `1250 (x - 0.2)² (x - 0.6)²`, written with exact fractions. -/
noncomputable def blendCost (x : ℝ) : ℝ :=
  1 / 5 * 5 + 9 * (4 / 5 - x) + 14 * x + 1250 * (x - 1 / 5) ^ 2 * (x - 3 / 5) ^ 2

/-- The taste penalty alone. -/
noncomputable def penalty (x : ℝ) : ℝ := 1250 * (x - 1 / 5) ^ 2 * (x - 3 / 5) ^ 2

/-- The card's slope formula `f'(x) = 5 + 2500 (x - 0.2)(x - 0.6)(2x - 0.8)`. -/
noncomputable def blendSlope (x : ℝ) : ℝ :=
  5 + 2500 * (x - 1 / 5) * (x - 3 / 5) * (2 * x - 4 / 5)

/-- The card's curvature formula `f''(x)`. -/
noncomputable def blendCurv (x : ℝ) : ℝ :=
  2500 * ((x - 3 / 5) * (2 * x - 4 / 5) + (x - 1 / 5) * (2 * x - 4 / 5)
    + 2 * (x - 1 / 5) * (x - 3 / 5))

-- Worked numbers, by hand: £9.20 at the chocolatey target, £11.20 at the fruity one.
example : blendCost (1 / 5) = 46 / 5 := by norm_num [blendCost]
example : blendCost (3 / 5) = 56 / 5 := by norm_num [blendCost]
-- Halfway, x = 0.4: £12.20, with a penalty of £2.00.
example : blendCost (2 / 5) = 61 / 5 := by norm_num [blendCost]
example : penalty (2 / 5) = 2 := by norm_num [penalty]
-- The two ends: £26.20 at x = 0 and £30.20 at x = 0.8.
example : blendCost 0 = 131 / 5 := by norm_num [blendCost]
example : blendCost (4 / 5) = 151 / 5 := by norm_num [blendCost]
-- Slope 5 and curvature 400 at both targets.
example : blendSlope (1 / 5) = 5 := by norm_num [blendSlope]
example : blendCurv (1 / 5) = 400 := by norm_num [blendCurv]
example : blendSlope (3 / 5) = 5 := by norm_num [blendSlope]
example : blendCurv (3 / 5) = 400 := by norm_num [blendCurv]
-- One Newton step from 0.2 lands at 0.1875; the bowl's bottom is about £9.16875.
example : (1 : ℝ) / 5 - 5 / 400 = 3 / 16 := by norm_num
example : (46 : ℝ) / 5 - 5 ^ 2 / (2 * 400) = 1467 / 160 := by norm_num
-- The same from 0.6, and the gap between the two dips: about £2.00 a kilo.
example : (3 : ℝ) / 5 - 5 / 400 = 47 / 80 := by norm_num
example : ((56 : ℝ) / 5 - 25 / 800) - (46 / 5 - 25 / 800) = 2 := by norm_num
-- Slope signs at 0, 0.3, 0.5 and 0.8: -235, 20, -10 and 245.
example : blendSlope 0 = -235 := by norm_num [blendSlope]
example : blendSlope (3 / 10) = 20 := by norm_num [blendSlope]
example : blendSlope (1 / 2) = -10 := by norm_num [blendSlope]
example : blendSlope (4 / 5) = 245 := by norm_num [blendSlope]
-- The slope bound L = 725 and the grid slack L h / 2 = 0.3625 for h = 0.001.
example : (5 : ℝ) + 2500 * (3 / 5) * (3 / 5) * (4 / 5) = 725 := by norm_num
example : (725 : ℝ) * (1 / 1000) / 2 = 29 / 80 := by norm_num
-- Dropping the penalty: £8.20 of beans at x = 0.
example : (1 : ℝ) / 5 * 5 + 9 * (4 / 5 - 0) + 14 * 0 = 41 / 5 := by norm_num

#print axioms no_finite_search_certifies_global_minimum
#print axioms slope_zero_positive_curvature_strict_local_min
#print axioms slope_bound_grid_floor

end LocalGlobalMinima
