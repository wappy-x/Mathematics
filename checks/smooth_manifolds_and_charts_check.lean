-- Smooth manifold: the six map sheets that look straight down on the halves of a sphere form a smooth atlas, so a function's smoothness does not depend on the sheet, while the charts t and t³ on the line are not smoothly compatible.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Fin.Tuple.Basic

open scoped ContDiff

namespace SmoothManifoldsAndCharts

/-- The sphere of radius `R` in space: the points `(X, Y, Z)` with `X² + Y² + Z² = R²`. -/
def sphere (R : ℝ) : Set (Fin 3 → ℝ) :=
  {p | p 0 ^ 2 + p 1 ^ 2 + p 2 ^ 2 = R ^ 2}

/-- The open half of the sphere seen by sheet `(k, σ)`: the points whose coordinate `k`
has sign `σ` (`σ = 1` or `σ = -1`). The rim, where coordinate `k` is `0`, is left out. -/
def half (R : ℝ) (k : Fin 3) (σ : ℤˣ) : Set (Fin 3 → ℝ) :=
  {p | p ∈ sphere R ∧ 0 < ((σ : ℤ) : ℝ) * p k}

/-- The sheet that drops coordinate `k`: it keeps the point's other two coordinates. -/
def chart (k : Fin 3) (p : Fin 3 → ℝ) : Fin 2 → ℝ :=
  fun i => p (k.succAbove i)

/-- The inverse of sheet `(k, σ)`: put back the dropped coordinate as `σ √(R² - u₁² - u₂²)`. -/
noncomputable def lift (R : ℝ) (k : Fin 3) (σ : ℤˣ) (u : Fin 2 → ℝ) : Fin 3 → ℝ :=
  Fin.insertNth k (((σ : ℤ) : ℝ) * √(R ^ 2 - u 0 ^ 2 - u 1 ^ 2)) u

/-- The change of coordinates from sheet `(k, σ)` to the sheet that drops coordinate `m`. -/
noncomputable def transition (R : ℝ) (k : Fin 3) (σ : ℤˣ) (m : Fin 3) (u : Fin 2 → ℝ) :
    Fin 2 → ℝ :=
  chart m (lift R k σ u)

lemma sq_sum_succAbove (p : Fin 3 → ℝ) (k : Fin 3) :
    p 0 ^ 2 + p 1 ^ 2 + p 2 ^ 2 =
      p k ^ 2 + p (k.succAbove 0) ^ 2 + p (k.succAbove 1) ^ 2 := by
  fin_cases k <;> simp [Fin.succAbove] <;> ring

lemma units_mul_self (σ : ℤˣ) : ((σ : ℤ) : ℝ) * ((σ : ℤ) : ℝ) = 1 := by
  rcases Int.units_eq_one_or σ with h | h <;> simp [h]

lemma chart_mem_disc (R : ℝ) (k : Fin 3) (σ : ℤˣ) (p : Fin 3 → ℝ) (hp : p ∈ half R k σ) :
    chart k p 0 ^ 2 + chart k p 1 ^ 2 < R ^ 2 ∧ lift R k σ (chart k p) = p := by
  obtain ⟨hs, hpos⟩ := hp
  have hsum : p k ^ 2 + p (k.succAbove 0) ^ 2 + p (k.succAbove 1) ^ 2 = R ^ 2 := by
    rw [← sq_sum_succAbove]; exact hs
  have hne : p k ≠ 0 := by
    rintro h; rw [h, mul_zero] at hpos; exact lt_irrefl _ hpos
  have hk2 : 0 < p k ^ 2 := by positivity
  refine ⟨?_, ?_⟩
  · simp only [chart]; linarith
  · have hD : R ^ 2 - chart k p 0 ^ 2 - chart k p 1 ^ 2 = p k ^ 2 := by
      simp only [chart]; linarith
    have hval : ((σ : ℤ) : ℝ) * √(R ^ 2 - chart k p 0 ^ 2 - chart k p 1 ^ 2) = p k := by
      rw [hD, Real.sqrt_sq_eq_abs]
      rcases Int.units_eq_one_or σ with h | h
      · subst h; simp at hpos ⊢; exact hpos.le
      · subst h; simp at hpos ⊢; rw [abs_of_neg (by linarith)]; ring
    unfold lift
    rw [hval]
    exact Fin.insertNth_self_removeNth k p

lemma lift_mem_half (R : ℝ) (k : Fin 3) (σ : ℤˣ) (u : Fin 2 → ℝ)
    (hu : u 0 ^ 2 + u 1 ^ 2 < R ^ 2) :
    lift R k σ u ∈ half R k σ ∧ chart k (lift R k σ u) = u := by
  have hD : 0 < R ^ 2 - u 0 ^ 2 - u 1 ^ 2 := by linarith
  have hσ := units_mul_self σ
  refine ⟨⟨?_, ?_⟩, ?_⟩
  · show _ = _
    rw [sq_sum_succAbove _ k]
    simp only [lift, Fin.insertNth_apply_same, Fin.insertNth_apply_succAbove]
    have hs := Real.sq_sqrt hD.le
    have : (((σ : ℤ) : ℝ) * √(R ^ 2 - u 0 ^ 2 - u 1 ^ 2)) ^ 2 =
        R ^ 2 - u 0 ^ 2 - u 1 ^ 2 := by
      rw [mul_pow, sq ((σ : ℤ) : ℝ), hσ, one_mul, hs]
    rw [this]; ring
  · simp only [lift, Fin.insertNth_apply_same]
    rw [← mul_assoc, hσ, one_mul]
    exact Real.sqrt_pos.mpr hD
  · funext i
    simp [chart, lift]

lemma insertNth_contDiffOn (k : Fin 3) (a : (Fin 2 → ℝ) → ℝ) (s : Set (Fin 2 → ℝ))
    (ha : ContDiffOn ℝ ∞ a s) (j : Fin 3) :
    ContDiffOn ℝ ∞ (fun u => Fin.insertNth (α := fun _ => ℝ) k (a u) u j) s := by
  induction j using Fin.succAboveCases k with
  | x => simpa using ha
  | p j => simpa using (contDiff_apply ℝ (fun _ : Fin 2 => ℝ) j : ContDiff ℝ ∞ fun u : Fin 2 → ℝ => u j).contDiffOn

lemma transition_contDiffOn (R : ℝ) (k : Fin 3) (σ : ℤˣ) (m : Fin 3) (τ : ℤˣ) :
    ContDiffOn ℝ ∞ (transition R k σ m) (chart k '' (half R k σ ∩ half R m τ)) := by
  have ha : ContDiffOn ℝ ∞ (fun u : Fin 2 → ℝ => ((σ : ℤ) : ℝ) * √(R ^ 2 - u 0 ^ 2 - u 1 ^ 2))
      (chart k '' (half R k σ ∩ half R m τ)) := by
    apply contDiffOn_const.mul
    apply ContDiffOn.sqrt
    · have h0 : ContDiff ℝ ∞ fun u : Fin 2 → ℝ => u 0 := contDiff_apply ℝ (fun _ : Fin 2 => ℝ) 0
      have h1 : ContDiff ℝ ∞ fun u : Fin 2 → ℝ => u 1 := contDiff_apply ℝ (fun _ : Fin 2 => ℝ) 1
      exact ((contDiff_const.sub (h0.pow 2)).sub (h1.pow 2)).contDiffOn
    · rintro _ ⟨p, ⟨hp, -⟩, rfl⟩
      have := (chart_mem_disc R k σ p hp).1
      intro h; linarith
  refine contDiffOn_pi.mpr fun i => ?_
  exact insertNth_contDiffOn k _ _ ha (m.succAbove i)

#print axioms sq_sum_succAbove
#print axioms units_mul_self
#print axioms chart_mem_disc
#print axioms lift_mem_half
#print axioms insertNth_contDiffOn
#print axioms transition_contDiffOn

/-- The six orthographic sheets form a smooth atlas of the sphere of radius `R`:
every point lies on some sheet; each sheet matches its open half one to one with the
open disc of radius `R`, with `lift` as its inverse; and for every two sheets, the change
of coordinates from one to the other is smooth (`C^∞`) on their overlap. Taking every
ordered pair covers both directions. -/
theorem six_sheet_atlas_is_smooth (R : ℝ) (hR : 0 < R) :
    (∀ p ∈ sphere R, ∃ (k : Fin 3) (σ : ℤˣ), p ∈ half R k σ) ∧
    (∀ (k : Fin 3) (σ : ℤˣ),
      (∀ p ∈ half R k σ, chart k p 0 ^ 2 + chart k p 1 ^ 2 < R ^ 2 ∧
          lift R k σ (chart k p) = p) ∧
      (∀ u : Fin 2 → ℝ, u 0 ^ 2 + u 1 ^ 2 < R ^ 2 →
          lift R k σ u ∈ half R k σ ∧ chart k (lift R k σ u) = u)) ∧
    (∀ (k m : Fin 3) (σ τ : ℤˣ),
      ContDiffOn ℝ ∞ (transition R k σ m) (chart k '' (half R k σ ∩ half R m τ))) := by
  refine ⟨?_, fun k σ => ⟨fun p hp => chart_mem_disc R k σ p hp,
    fun u hu => lift_mem_half R k σ u hu⟩, fun k m σ τ => transition_contDiffOn R k σ m τ⟩
  intro p hp
  have : ∃ k, p k ≠ 0 := by
    by_contra h
    push Not at h
    have h' : p 0 ^ 2 + p 1 ^ 2 + p 2 ^ 2 = R ^ 2 := hp
    rw [h 0, h 1, h 2] at h'
    have : 0 < R ^ 2 := by positivity
    linarith
  obtain ⟨k, hk⟩ := this
  rcases hk.lt_or_gt with hneg | hpos
  · exact ⟨k, -1, hp, by simpa using hneg⟩
  · exact ⟨k, 1, hp, by simpa using hpos⟩

/-- A function's smoothness does not depend on the sheet: if `f` read through sheet
`(k, σ)` is smooth on the overlap with sheet `(m, τ)`, then `f` read through sheet `(m, τ)`
is smooth there too. -/
theorem smoothness_does_not_depend_on_sheet (R : ℝ) (hR : 0 < R)
    (k m : Fin 3) (σ τ : ℤˣ) (f : (Fin 3 → ℝ) → ℝ)
    (hf : ContDiffOn ℝ ∞ (f ∘ lift R k σ) (chart k '' (half R k σ ∩ half R m τ))) :
    ContDiffOn ℝ ∞ (f ∘ lift R m τ) (chart m '' (half R k σ ∩ half R m τ)) := by
  have hT := transition_contDiffOn R m τ k σ
  rw [Set.inter_comm] at hT
  refine (hf.comp hT ?_).congr ?_
  · rintro _ ⟨p, hp, rfl⟩
    refine ⟨p, hp, ?_⟩
    simp only [transition, (chart_mem_disc R m τ p hp.2).2]
  · rintro _ ⟨p, hp, rfl⟩
    simp only [Function.comp, transition, (chart_mem_disc R m τ p hp.2).2,
      (chart_mem_disc R k σ p hp.1).2]

/-- What breaks: on the real line the chart `t ↦ t³` is smooth, but the change of
coordinates back to the chart `t`, the cube root, is not even differentiable at `0`;
so the charts `t` and `t³` are not smoothly compatible. -/
theorem cube_chart_not_compatible :
    ContDiff ℝ ∞ (fun t : ℝ => t ^ 3) ∧
    ¬ ∃ g : ℝ → ℝ, DifferentiableAt ℝ g 0 ∧ ∀ t : ℝ, g (t ^ 3) = t := by
  refine ⟨contDiff_id.pow 3, ?_⟩
  rintro ⟨g, hg, hgt⟩
  have h1 : HasDerivAt (fun t : ℝ => g (t ^ 3)) (deriv g 0 * (3 * (0:ℝ) ^ 2)) 0 := by
    have hc : HasDerivAt (fun t : ℝ => t ^ 3) (3 * (0:ℝ) ^ 2) 0 := by
      simpa using hasDerivAt_pow 3 (0:ℝ)
    have hg' : HasDerivAt g (deriv g 0) ((fun t : ℝ => t ^ 3) 0) := by
      simpa using hg.hasDerivAt
    exact HasDerivAt.comp (h := fun t : ℝ => t ^ 3) (0:ℝ) hg' hc
  have h2 : HasDerivAt (fun t : ℝ => g (t ^ 3)) 1 0 := by
    simp only [hgt]; exact hasDerivAt_id 0
  have := h1.unique h2
  norm_num at this

-- The card's whole-number counts.
-- A grid every 5° of latitude (37 rows) and longitude (72 columns) has 2664 entries.
example : 37 * 72 = 2664 := by norm_num
-- Six sheets make 15 pairs.
example : Nat.choose 6 2 = 15 := by decide
-- Sheets are (dropped coordinate, sign); two different sheets overlap exactly when they drop
-- different coordinates: 24 ordered pairs, so 12 pairs, checked both ways.
example : ((Finset.univ : Finset (Fin 3 × Bool)).offDiag.filter
    (fun a => a.1.1 ≠ a.2.1)).card = 24 := by decide
example : 15 - 3 = 12 ∧ 2 * 12 = 24 := by norm_num

#print axioms six_sheet_atlas_is_smooth
#print axioms smoothness_does_not_depend_on_sheet
#print axioms cube_chart_not_compatible

end SmoothManifoldsAndCharts
