-- The flow: for a rule y' = f(y) that reads only the state, with f locally Lipschitz, the flow on its largest time domain obeys "waiting t then s is waiting s + t", solution curves never cross, and the colony flow x / (1 - t x) of y' = y^2 composes the same way.
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Order.Interval.Set.OrdConnected
import Mathlib.Tactic.NormNum

/-- Helper: two solutions of y' = f(y) (f locally Lipschitz) on an open order-connected time set
that meet once agree everywhere on it. -/
theorem flow_helper_unique
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → E) (hf : LocallyLipschitz f)
    (I : Set ℝ) (hI_open : IsOpen I) (hI_conn : I.OrdConnected)
    (u w : ℝ → E)
    (hu : ∀ τ ∈ I, HasDerivAt u (f (u τ)) τ) (hw : ∀ τ ∈ I, HasDerivAt w (f (w τ)) τ)
    (t₀ : ℝ) (ht₀ : t₀ ∈ I) (hmeet : u t₀ = w t₀) :
    Set.EqOn u w I := by
  have hloc : ∀ τ ∈ I, u τ = w τ → ∀ᶠ σ in nhds τ, u σ = w σ := by
    intro τ hτ heq
    obtain ⟨K, U, hU, hL⟩ := hf (u τ)
    have hIn : ∀ᶠ σ in nhds τ, σ ∈ I := hI_open.mem_nhds hτ
    have huU : ∀ᶠ σ in nhds τ, u σ ∈ U := (hu τ hτ).continuousAt.preimage_mem_nhds hU
    have hwU : ∀ᶠ σ in nhds τ, w σ ∈ U :=
      (hw τ hτ).continuousAt.preimage_mem_nhds (heq ▸ hU)
    have hIn2 : ∀ᶠ σ in nhds τ, ∀ᶠ ρ in nhds σ, ρ ∈ I := hIn.eventually_nhds
    exact ODE_solution_unique_of_eventually (v := fun _ => f) (s := fun _ => U) (K := K)
      (Filter.Eventually.of_forall fun _ => hL)
      ((hIn.and huU).mono fun σ h => ⟨hu σ h.1, h.2⟩)
      ((hIn.and hwU).mono fun σ h => ⟨hw σ h.1, h.2⟩) heq
  set A := {τ : ℝ | ∀ᶠ σ in nhds τ, u σ = w σ}
  set B := {τ : ℝ | ∀ᶠ σ in nhds τ, u σ ≠ w σ}
  have hA : IsOpen A := isOpen_setOfPred_eventually_nhds
  have hB : IsOpen B := isOpen_setOfPred_eventually_nhds
  have hAB : Disjoint A B := by
    rw [Set.disjoint_left]
    intro τ h1 h2
    exact (h1.and h2).exists.elim fun σ h => h.2 h.1
  have hcover : I ⊆ A ∪ B := by
    intro τ hτ
    by_cases h : u τ = w τ
    · exact Or.inl (hloc τ hτ h)
    · right
      have hc : ContinuousAt (fun σ => u σ - w σ) τ :=
        (hu τ hτ).continuousAt.sub (hw τ hτ).continuousAt
      exact (hc.eventually_ne (sub_ne_zero.mpr h)).mono fun σ hσ => sub_ne_zero.mp hσ
  have hsub : I ⊆ A := hI_conn.isPreconnected.subset_left_of_subset_union hA hB hAB hcover
    ⟨t₀, ht₀, hloc t₀ ht₀ hmeet⟩
  intro τ hτ
  exact (hsub hτ).self_of_nhds

#print axioms flow_helper_unique

/-- The composition law of the flow. Let the rule y' = f(y) read only the state, with f locally
Lipschitz (one start gives one history, both ways in time). For each start x, let t ↦ φ t x be the
solution with φ 0 x = x on its largest open time interval J x containing 0 (its life span: every
solution from x on an open interval around 0 lives inside J x), so waiting no time changes
nothing. Then for every wait t and every extra wait s with s + t still inside the life span of x,
the wait s is inside the life span of z = φ t x and waiting t then s is the same as waiting s + t:
φ s (φ t x) = φ (s + t) x. -/
theorem flow_wait_then_wait_is_one_longer_wait
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → E) (hf : LocallyLipschitz f)
    (φ : ℝ → E → E) (J : E → Set ℝ)
    (hJ_open : ∀ x, IsOpen (J x)) (hJ_conn : ∀ x, (J x).OrdConnected)
    (hJ_zero : ∀ x, (0 : ℝ) ∈ J x)
    (hφ_start : ∀ x, φ 0 x = x)
    (hφ_solves : ∀ x, ∀ τ ∈ J x, HasDerivAt (fun σ => φ σ x) (f (φ τ x)) τ)
    (hJ_max : ∀ (x : E) (I : Set ℝ) (u : ℝ → E), IsOpen I → I.OrdConnected → (0 : ℝ) ∈ I →
      u 0 = x → (∀ τ ∈ I, HasDerivAt u (f (u τ)) τ) → I ⊆ J x)
    (x : E) (t s : ℝ) (ht : t ∈ J x) (hst : s + t ∈ J x) :
    s ∈ J (φ t x) ∧ φ s (φ t x) = φ (s + t) x := by
  set I : Set ℝ := (fun σ => σ + t) ⁻¹' J x with hIdef
  have hI_open : IsOpen I := (hJ_open x).preimage (continuous_id.add continuous_const)
  have hI_conn : I.OrdConnected := by
    refine ⟨fun a ha b hb c hc => ?_⟩
    exact (hJ_conn x).out ha hb ⟨by linarith [hc.1], by linarith [hc.2]⟩
  have hI0 : (0 : ℝ) ∈ I := by simpa [hIdef] using ht
  have hIs : s ∈ I := hst
  set u : ℝ → E := fun σ => φ (σ + t) x with hudef
  have hu0 : u 0 = φ t x := by simp [hudef]
  have hu : ∀ τ ∈ I, HasDerivAt u (f (u τ)) τ := fun τ hτ =>
    (hφ_solves x (τ + t) hτ).comp_add_const τ t
  have hsub : I ⊆ J (φ t x) := hJ_max (φ t x) I u hI_open hI_conn hI0 hu0 hu
  refine ⟨hsub hIs, ?_⟩
  have heq := flow_helper_unique f hf I hI_open hI_conn u (fun σ => φ σ (φ t x)) hu
    (fun τ hτ => hφ_solves (φ t x) τ (hsub hτ)) 0 hI0 (by simp [hu0, hφ_start])
  exact (heq hIs).symm

/-- Solution curves never cross. If the rule y' = f(y) has f locally Lipschitz and two
solutions u and w on the same open time interval I read the same state at one moment t₀,
they are one history: they agree at every time in I. -/
theorem solution_curves_never_cross
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → E) (hf : LocallyLipschitz f)
    (I : Set ℝ) (hI_open : IsOpen I) (hI_conn : I.OrdConnected)
    (u w : ℝ → E)
    (hu : ∀ τ ∈ I, HasDerivAt u (f (u τ)) τ) (hw : ∀ τ ∈ I, HasDerivAt w (f (w τ)) τ)
    (t₀ : ℝ) (ht₀ : t₀ ∈ I) (hmeet : u t₀ = w t₀) :
    Set.EqOn u w I := by
  exact flow_helper_unique f hf I hI_open hI_conn u w hu hw t₀ ht₀ hmeet

/-- The colony's flow. For y' = y², the curve t ↦ x / (1 - t x) starts at x and solves the law
wherever t x < 1 (inside the life span 1/x), and it composes: if t x < 1 and the second wait s
keeps z = x / (1 - t x) inside its own life span (s z < 1), then moving z on by s lands where one
move of s + t lands, x / (1 - (s + t) x). -/
theorem colony_flow_solves_and_composes (x t s : ℝ) (ht : t * x < 1)
    (hs : s * (x / (1 - t * x)) < 1) :
    x / (1 - 0 * x) = x ∧
    HasDerivAt (fun τ => x / (1 - τ * x)) ((x / (1 - t * x)) ^ 2) t ∧
    (x / (1 - t * x)) / (1 - s * (x / (1 - t * x))) = x / (1 - (s + t) * x) := by
  have h1 : (1 - t * x) ≠ 0 := by linarith
  have h1p : 0 < 1 - t * x := by linarith
  refine ⟨by simp, ?_, ?_⟩
  · have hd : HasDerivAt (fun τ => 1 - τ * x) (-x) t := by
      simpa using ((hasDerivAt_id t).mul_const x).const_sub 1
    have := (hasDerivAt_const t x).div hd h1
    convert this using 1
    rw [div_pow]
    ring
  · have h2 : 1 - s * (x / (1 - t * x)) = (1 - (s + t) * x) / (1 - t * x) := by
      rw [eq_div_iff h1, sub_mul, mul_assoc, div_mul_cancel₀ x h1]
      ring
    have h3 : 1 - (s + t) * x ≠ 0 := by
      intro h
      have := h2
      rw [h, zero_div] at this
      linarith
    rw [h2, div_div_div_cancel_right₀ h1]

-- Worked numbers, by hand, with the colony flow φ_t(x) = x / (1 - t x), in hundreds of animals.
-- First quarter-year from 100 animals: 4/3, about 133 animals.
example : (1 : ℚ) / (1 - 1/4 * 1) = 4/3 := by norm_num
-- Second quarter-year from 4/3: 2.
example : ((4 : ℚ)/3) / (1 - 1/4 * (4/3)) = 2 := by norm_num
-- One move of half a year from 1: 2, the same place.
example : (1 : ℚ) / (1 - 1/2 * 1) = 2 := by norm_num
-- Back half a year from 2: 1.
example : (2 : ℚ) / (1 - (-1/2) * 2) = 1 := by norm_num
-- Time to grow from 1 to 2 is 1/1 - 1/2 = 1/2 year; the quarter-years add up to it.
example : (1 : ℚ)/1 - 1/2 = 1/2 ∧ ((1 : ℚ)/1 - 3/4) + (3/4 - 1/2) = 1/2 := by norm_num
-- Life span from 1 is 1 year; from 2 it is 1/2 year.
example : (1 : ℚ) / 1 = 1 ∧ (1 : ℚ) / 2 = 1/2 := by norm_num
-- The usual mistake: reusing the growth factor 4/3 gives 16/9, not 2.
example : ((4 : ℚ)/3) * (4/3) = 16/9 ∧ ((4 : ℚ)/3) * (4/3) ≠ 2 := by norm_num
-- Past the life span the formula prints -2, which is no colony.
example : (1 : ℚ) / (1 - 3/2 * 1) = -2 := by norm_num

#print axioms flow_wait_then_wait_is_one_longer_wait
#print axioms solution_curves_never_cross
#print axioms colony_flow_solves_and_composes
