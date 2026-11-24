-- Flux limiters: on a loop of cells, a flux-limited upwind step whose limiter stays in Sweby's region and whose Courant number is at most 1 never raises the total variation, by Harten's lemma, and the two-stage SSP Runge-Kutta step keeps that guarantee.
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.ZMod.Defs
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination

open Finset

/-- The total variation of a grid u on a loop of N cells: the sum of the sizes of all the jumps
u_(j+1) − u_j, with the last cell joined back to the first. -/
def totalVariation {α : Type*} [Field α] [LinearOrder α] {N : ℕ} [NeZero N]
    (u : ZMod N → α) : α :=
  ∑ j : ZMod N, |u (j + 1) - u j|

/-- The smoothness ratio r_j = (u_j − u_(j−1)) / (u_(j+1) − u_j): the jump behind cell j over the
jump ahead of it. -/
def smoothnessRatio {α : Type*} [Field α] {N : ℕ} (u : ZMod N → α) (j : ZMod N) : α :=
  (u j - u (j - 1)) / (u (j + 1) - u j)

/-- One flux-limited step on a loop of N cells, river speed c, time step Δt, cell length h and
Courant number ν = cΔt/h. The flux through the edge after cell j is
F_(j+1/2) = c u_j + (c/2)(1 − ν) φ(r_j)(u_(j+1) − u_j), and the new value is
u_j − (Δt/h)(F_(j+1/2) − F_(j−1/2)). -/
def fluxLimitedStep {α : Type*} [Field α] {N : ℕ} (φ : α → α) (c Δt h : α)
    (u : ZMod N → α) : ZMod N → α :=
  let ν := c * Δt / h
  let F : ZMod N → α := fun j => c * u j + c / 2 * (1 - ν) * φ (smoothnessRatio u j) * (u (j + 1) - u j)
  fun j => u j - Δt / h * (F j - F (j - 1))

/-- Helper: Harten's incremental-form bound, stated before the main theorem so it can use it. -/
theorem harten_incremental_tvd {N : ℕ} [NeZero N] (C D : ZMod N → ℝ)
    (hC : ∀ j, 0 ≤ C j) (hD : ∀ j, 0 ≤ D j) (hCD : ∀ j, C j + D j ≤ 1) (u : ZMod N → ℝ) :
    totalVariation (fun j => u j - C (j - 1) * (u j - u (j - 1)) + D j * (u (j + 1) - u j))
      ≤ totalVariation u := by
  unfold totalVariation
  calc ∑ j : ZMod N, |(u (j + 1) - C (j + 1 - 1) * (u (j + 1) - u (j + 1 - 1))
          + D (j + 1) * (u (j + 1 + 1) - u (j + 1)))
          - (u j - C (j - 1) * (u j - u (j - 1)) + D j * (u (j + 1) - u j))|
        ≤ ∑ j : ZMod N, ((1 - C j - D j) * |u (j + 1) - u j|
          + C (j - 1) * |u (j - 1 + 1) - u (j - 1)|
          + D (j + 1) * |u (j + 1 + 1) - u (j + 1)|) := by
        apply sum_le_sum
        intro j _
        simp only [add_sub_cancel_right, sub_add_cancel]
        have e : (u (j + 1) - C j * (u (j + 1) - u j) + D (j + 1) * (u (j + 1 + 1) - u (j + 1)))
            - (u j - C (j - 1) * (u j - u (j - 1)) + D j * (u (j + 1) - u j))
            = (1 - C j - D j) * (u (j + 1) - u j) + C (j - 1) * (u j - u (j - 1))
              + D (j + 1) * (u (j + 1 + 1) - u (j + 1)) := by ring
        rw [e]
        have h1 : 0 ≤ 1 - C j - D j := by linarith [hCD j]
        calc _ ≤ |(1 - C j - D j) * (u (j + 1) - u j)| + |C (j - 1) * (u j - u (j - 1))|
              + |D (j + 1) * (u (j + 1 + 1) - u (j + 1))| := abs_add_three _ _ _
          _ = _ := by
            rw [abs_mul, abs_mul, abs_mul, abs_of_nonneg h1, abs_of_nonneg (hC _),
              abs_of_nonneg (hD _)]
    _ = ∑ j : ZMod N, (1 - C j - D j) * |u (j + 1) - u j|
          + ∑ j : ZMod N, C (j - 1) * |u (j - 1 + 1) - u (j - 1)|
          + ∑ j : ZMod N, D (j + 1) * |u (j + 1 + 1) - u (j + 1)| := by
        rw [sum_add_distrib, sum_add_distrib]
    _ = ∑ j : ZMod N, (1 - C j - D j) * |u (j + 1) - u j|
          + ∑ j : ZMod N, C j * |u (j + 1) - u j|
          + ∑ j : ZMod N, D j * |u (j + 1) - u j| := by
        have h1 : ∑ j : ZMod N, C (j - 1) * |u (j - 1 + 1) - u (j - 1)|
            = ∑ j : ZMod N, C j * |u (j + 1) - u j| :=
          Fintype.sum_equiv (Equiv.subRight 1) _ (fun j => C j * |u (j + 1) - u j|) (fun j => rfl)
        have h2 : ∑ j : ZMod N, D (j + 1) * |u (j + 1 + 1) - u (j + 1)|
            = ∑ j : ZMod N, D j * |u (j + 1) - u j| :=
          Fintype.sum_equiv (Equiv.addRight 1) _ (fun j => D j * |u (j + 1) - u j|) (fun j => rfl)
        rw [h1, h2]
    _ = ∑ j : ZMod N, |u (j + 1) - u j| := by
        rw [← sum_add_distrib, ← sum_add_distrib]
        apply sum_congr rfl
        intro j _
        ring

#print axioms harten_incremental_tvd

/-- Helper: the total variation of an even average is at most the average of the total variations. -/
theorem tv_half_add {N : ℕ} [NeZero N] (u v : ZMod N → ℝ) :
    totalVariation (fun j => 1 / 2 * u j + 1 / 2 * v j)
      ≤ 1 / 2 * totalVariation u + 1 / 2 * totalVariation v := by
  unfold totalVariation
  rw [mul_sum, mul_sum, ← sum_add_distrib]
  apply sum_le_sum
  intro j _
  show |1 / 2 * u (j + 1) + 1 / 2 * v (j + 1) - (1 / 2 * u j + 1 / 2 * v j)| ≤ _
  have e : 1 / 2 * u (j + 1) + 1 / 2 * v (j + 1) - (1 / 2 * u j + 1 / 2 * v j)
      = 1 / 2 * (u (j + 1) - u j) + 1 / 2 * (v (j + 1) - v j) := by ring
  rw [e]
  calc _ ≤ |1 / 2 * (u (j + 1) - u j)| + |1 / 2 * (v (j + 1) - v j)| := abs_add_le _ _
    _ = _ := by rw [abs_mul, abs_mul, abs_of_pos (by norm_num : (0:ℝ) < 1 / 2)]

#print axioms tv_half_add

/-- Flux limiters inside Sweby's region give TVD schemes. On a loop of N cells, take a river
flowing toward larger cell numbers at speed c ≥ 0, cells of length h > 0, a time step Δt > 0,
and Courant number ν = cΔt/h at most 1. Let the limiter φ be 0 for r ≤ 0, and for r > 0 lie
between 0 and both 2r and 2 (Sweby's region). Then one flux-limited step never raises the total
variation: TV(u^(n+1)) ≤ TV(u^n). -/
theorem flux_limited_step_in_swebys_region_is_tvd {N : ℕ} [NeZero N] (φ : ℝ → ℝ)
    (c Δt h : ℝ) (hc : 0 ≤ c) (hh : 0 < h) (hΔt : 0 < Δt) (hν : c * Δt / h ≤ 1)
    (hφ_nonpos : ∀ r : ℝ, r ≤ 0 → φ r = 0)
    (hφ_pos : ∀ r : ℝ, 0 < r → 0 ≤ φ r ∧ φ r ≤ 2 * r ∧ φ r ≤ 2)
    (u : ZMod N → ℝ) :
    totalVariation (fluxLimitedStep φ c Δt h u) ≤ totalVariation u := by
  set ν := c * Δt / h with hνdef
  have hν0 : 0 ≤ ν := by positivity
  set r : ZMod N → ℝ := fun j => smoothnessRatio u j with hr
  set ψ : ZMod N → ℝ := fun j => φ (r j) / r j with hψ
  have hφ0 : φ 0 = 0 := hφ_nonpos 0 le_rfl
  have hψb : ∀ j, 0 ≤ ψ j ∧ ψ j ≤ 2 := by
    intro j
    simp only [hψ]
    rcases le_or_gt (r j) 0 with hr0 | hr0
    · rw [hφ_nonpos _ hr0]; simp
    · obtain ⟨a, b, _⟩ := hφ_pos _ hr0
      exact ⟨div_nonneg a hr0.le, (div_le_iff₀ hr0).2 (by linarith)⟩
  have hφb : ∀ j, 0 ≤ φ (r j) ∧ φ (r j) ≤ 2 := by
    intro j
    rcases le_or_gt (r j) 0 with hr0 | hr0
    · rw [hφ_nonpos _ hr0]; norm_num
    · obtain ⟨a, _, b⟩ := hφ_pos _ hr0
      exact ⟨a, b⟩
  have hψe : ∀ j, ψ j * (u j - u (j - 1)) = φ (r j) * (u (j + 1) - u j) := by
    intro j
    simp only [hψ, hr, smoothnessRatio]
    by_cases ha : u (j + 1) - u j = 0
    · rw [ha]; simp [hφ0]
    by_cases hb : u j - u (j - 1) = 0
    · rw [hb]; simp [hφ0]
    field_simp
  let C : ZMod N → ℝ := fun j => ν + ν / 2 * (1 - ν) * (ψ (j + 1) - φ (r j))
  have hstep : fluxLimitedStep φ c Δt h u
      = fun j => u j - C (j - 1) * (u j - u (j - 1)) + (fun _ => (0:ℝ)) j * (u (j + 1) - u j) := by
    funext j
    simp only [fluxLimitedStep, C, sub_add_cancel]
    have e1 := hψe j
    simp only [hr] at e1
    simp only [hνdef, hr]
    linear_combination (c * Δt / h / 2 * (1 - c * Δt / h)) * e1
  rw [hstep]
  apply harten_incremental_tvd
  · intro j
    obtain ⟨a1, a2⟩ := hψb (j + 1)
    obtain ⟨b1, b2⟩ := hφb j
    have hk : 0 ≤ ν * (1 - ν) := mul_nonneg hν0 (by linarith)
    simp only [C]
    nlinarith
  · intro j; exact le_rfl
  · intro j
    obtain ⟨a1, a2⟩ := hψb (j + 1)
    obtain ⟨b1, b2⟩ := hφb j
    have hk : 0 ≤ ν * (1 - ν) := mul_nonneg hν0 (by linarith)
    simp only [C]
    nlinarith

/-- Harten's lemma. On a loop of N cells, write a step in incremental form
u_j^(n+1) = u_j − C_(j−1/2)(u_j − u_(j−1)) + D_(j+1/2)(u_(j+1) − u_j), with C j standing for
C_(j+1/2) and D j for D_(j+1/2); the weights may depend on the data. If every C ≥ 0, every D ≥ 0,
and C + D ≤ 1 at every edge, then the total variation does not grow. -/
theorem hartens_lemma {N : ℕ} [NeZero N] (C D : ZMod N → ℝ)
    (hC : ∀ j, 0 ≤ C j) (hD : ∀ j, 0 ≤ D j) (hCD : ∀ j, C j + D j ≤ 1) (u : ZMod N → ℝ) :
    totalVariation (fun j => u j - C (j - 1) * (u j - u (j - 1)) + D j * (u (j + 1) - u j))
      ≤ totalVariation u := by
  exact harten_incremental_tvd C D hC hD hCD u

/-- The two-stage strong-stability-preserving Runge-Kutta step keeps the guarantee. If one
forward Euler step E never raises the total variation, then neither does the step
u^(1) = E(u^n), u^(n+1) = ½ u^n + ½ E(u^(1)). -/
theorem ssp_rk2_step_keeps_tvd {N : ℕ} [NeZero N] (E : (ZMod N → ℝ) → (ZMod N → ℝ))
    (hE : ∀ v, totalVariation (E v) ≤ totalVariation v) (u : ZMod N → ℝ) :
    totalVariation (fun j => 1 / 2 * u j + 1 / 2 * E (E u) j) ≤ totalVariation u := by
  calc totalVariation (fun j => 1 / 2 * u j + 1 / 2 * E (E u) j)
      ≤ 1 / 2 * totalVariation u + 1 / 2 * totalVariation (E (E u)) := tv_half_add u (E (E u))
    _ ≤ 1 / 2 * totalVariation u + 1 / 2 * totalVariation u := by
        have := (hE (E u)).trans (hE u)
        linarith
    _ = totalVariation u := by ring

/-! The card's worked numbers, in exact rationals. -/

/-- The square slug: 1 in the ten cells 10 to 19 (2.50 to 4.75 km) of the 40-cell loop, 0 elsewhere. -/
def slug : ZMod 40 → ℚ := fun j => if 10 ≤ j.val ∧ j.val < 20 then 1 else 0

def minmod (r : ℚ) : ℚ := max 0 (min r 1)
def vanLeer (r : ℚ) : ℚ := (r + |r|) / (1 + |r|)
def superbee (r : ℚ) : ℚ := max 0 (max (min (2 * r) 1) (min r 2))
def laxWendroff (_ : ℚ) : ℚ := 1

-- Limiter values at r = 0.5: minmod 0.5, van Leer 0.6667, superbee 1.
example : minmod (1 / 2) = 1 / 2 := by decide +kernel
example : vanLeer (1 / 2) = 2 / 3 := by decide +kernel
example : superbee (1 / 2) = 1 := by decide +kernel

-- Courant number 2.0 × 0.0625 / 0.25 = 0.5, and Harten's bound ν² to ν(2 − ν) is 0.25 to 0.75.
example : (2 : ℚ) * (1 / 16) / (1 / 4) = 1 / 2 := by norm_num
example : ((1 : ℚ) / 2) ^ 2 = 1 / 4 ∧ (1 : ℚ) / 2 * (2 - 1 / 2) = 3 / 4 := by norm_num

-- The slug's total variation is 2.
example : totalVariation slug = 2 := by decide +kernel

-- One Lax-Wendroff step: cells at 2.25, 2.50, 4.75, 5.00 km read −0.125, 0.625, 1.125, 0.375,
-- and the total variation rises to 2.5.
example : fluxLimitedStep laxWendroff 2 (1 / 16) (1 / 4) slug 9 = -1 / 8 := by decide +kernel
example : fluxLimitedStep laxWendroff 2 (1 / 16) (1 / 4) slug 10 = 5 / 8 := by decide +kernel
example : fluxLimitedStep laxWendroff 2 (1 / 16) (1 / 4) slug 19 = 9 / 8 := by decide +kernel
example : fluxLimitedStep laxWendroff 2 (1 / 16) (1 / 4) slug 20 = 3 / 8 := by decide +kernel
example : totalVariation (fluxLimitedStep laxWendroff 2 (1 / 16) (1 / 4) slug) = 5 / 2 := by decide +kernel

-- One minmod step: the same cells read 0, 0.5, 1, 0.5, and the total variation stays 2.
example : fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug 9 = 0 := by decide +kernel
example : fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug 10 = 1 / 2 := by decide +kernel
example : fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug 19 = 1 := by decide +kernel
example : fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug 20 = 1 / 2 := by decide +kernel
example : totalVariation (fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug) = 2 := by decide +kernel

-- A second minmod step at 5.00 km gives 0.8125.
example : fluxLimitedStep minmod 2 (1 / 16) (1 / 4)
    (fluxLimitedStep minmod 2 (1 / 16) (1 / 4) slug) 20 = 13 / 16 := by decide +kernel

#print axioms flux_limited_step_in_swebys_region_is_tvd
#print axioms hartens_lemma
#print axioms ssp_rk2_step_keeps_tvd
