-- The slope transform: a proper, convex, closed function on a Banach space is rebuilt by its biconjugate, and a load is a slope at a shape exactly when the function and its conjugate tie there.
import Mathlib.Analysis.Normed.Module.Basic
import Mathlib.Analysis.Normed.Operator.Basic
import Mathlib.Analysis.Convex.Basic
import Mathlib.Topology.Semicontinuity.Defs
import Mathlib.Topology.Instances.EReal.Lemmas
import Mathlib.Data.EReal.Operations
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Topology.Semicontinuity.Basic
import Mathlib.Topology.Instances.EReal.Lemmas
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Set

variable {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]

/-- The conjugate of an energy `f` (allowed the value `+∞ = ⊤` on forbidden shapes): at a load
`F` in the dual `X'`, the most that load can gain, work `⟨F, u⟩` minus energy `f u`, over every
shape `u`. -/
noncomputable def conj (f : X → EReal) (F : StrongDual ℝ X) : EReal :=
  ⨆ u : X, ((F u : ℝ) : EReal) - f u

/-- The biconjugate `f**`: at a shape `u`, the most any load's straight line
`⟨F, u⟩ - f*(F)` reaches there. -/
noncomputable def biconj (f : X → EReal) (u : X) : EReal :=
  ⨆ F : StrongDual ℝ X, ((F u : ℝ) : EReal) - conj f F

/-- `F` is a subgradient of `f` at `u`: the line through `(u, f u)` with slope `F` stays under
`f`, that is `f v ≥ f u + ⟨F, v - u⟩` for every shape `v`. -/
def IsSubgradient (f : X → EReal) (u : X) (F : StrongDual ℝ X) : Prop :=
  ∀ v : X, f u + ((F (v - u) : ℝ) : EReal) ≤ f v

/-- `u` is a subgradient of the conjugate `f*` at the load `F`:
`f*(G) ≥ f*(F) + ⟨G - F, u⟩` for every load `G`. -/
def IsConjSubgradient (f : X → EReal) (F : StrongDual ℝ X) (u : X) : Prop :=
  ∀ G : StrongDual ℝ X, conj f F + (((G - F) u : ℝ) : EReal) ≤ conj f G

lemma ereal_cases_ne_bot {x : EReal} (hx : x ≠ ⊥) : x = ⊤ ∨ ∃ r : ℝ, x = (r : EReal) := by
  by_cases h : x = ⊤
  · exact Or.inl h
  · exact Or.inr ⟨x.toReal, (EReal.coe_toReal h hx).symm⟩

lemma conj_ge (f : X → EReal) (F : StrongDual ℝ X) (x : X) :
    ((F x : ℝ) : EReal) - f x ≤ conj f F :=
  le_iSup (fun u : X => ((F u : ℝ) : EReal) - f u) x

lemma conj_le_coe (f : X → EReal) (hbot : ∀ u, f u ≠ ⊥) (F : StrongDual ℝ X) (c : ℝ)
    (h : ∀ (x : X) (r : ℝ), f x ≤ (r : EReal) → F x - r ≤ c) : conj f F ≤ (c : EReal) := by
  refine iSup_le fun x => ?_
  rcases ereal_cases_ne_bot (hbot x) with hx | ⟨r, hx⟩
  · rw [hx, EReal.sub_top]; exact bot_le
  · rw [hx, ← EReal.coe_sub]
    exact EReal.coe_le_coe_iff.2 (h x r hx.le)

lemma conj_ne_bot (f : X → EReal) (hproper : (∃ u, f u ≠ ⊤) ∧ ∀ u, f u ≠ ⊥)
    (F : StrongDual ℝ X) : conj f F ≠ ⊥ := by
  obtain ⟨u0, hu0⟩ := hproper.1
  rcases ereal_cases_ne_bot (hproper.2 u0) with h | ⟨r, h⟩
  · exact absurd h hu0
  · intro hb
    have := conj_ge f F u0
    rw [hb, h, ← EReal.coe_sub, le_bot_iff] at this
    exact EReal.coe_ne_bot _ this

lemma biconj_le (f : X → EReal) (hbot : ∀ u, f u ≠ ⊥) (u : X) : biconj f u ≤ f u := by
  refine iSup_le fun F => ?_
  rcases ereal_cases_ne_bot (hbot u) with h | ⟨r, h⟩
  · rw [h]; exact le_top
  · have h1 := conj_ge f F u
    rw [h, ← EReal.coe_sub] at h1
    have h2 := EReal.sub_le_sub (le_refl ((F u : ℝ) : EReal)) h1
    rw [← EReal.coe_sub] at h2
    rw [h]
    refine h2.trans (le_of_eq ?_)
    congr 1; ring

lemma lt_sub_conj_of_conj_le (f : X → EReal) (F : StrongDual ℝ X) (u : X) (k a : ℝ)
    (hk : conj f F ≤ (k : EReal)) (ha : a < F u - k) :
    (a : EReal) < ((F u : ℝ) : EReal) - conj f F := by
  have h2 := EReal.sub_le_sub (le_refl ((F u : ℝ) : EReal)) hk
  rw [← EReal.coe_sub] at h2
  exact lt_of_lt_of_le (EReal.coe_lt_coe_iff.2 ha) h2

lemma epi_sep (f : X → EReal) (hdom : ∃ u, f u ≠ ⊤)
    (hconvex : Convex ℝ {p : X × ℝ | f p.1 ≤ (p.2 : EReal)})
    (hclosed : LowerSemicontinuous f) (u : X) (a : ℝ) (ha : (a : EReal) < f u) :
    ∃ (L : StrongDual ℝ X) (β c : ℝ), β ≤ 0 ∧
      (∀ (x : X) (r : ℝ), f x ≤ (r : EReal) → L x + β * r < c) ∧ c < L u + β * a := by
  have hS : IsClosed {p : X × ℝ | f p.1 ≤ (p.2 : EReal)} := by
    have h := hclosed.isClosed_epigraph
    exact h.preimage (continuous_fst.prodMk (continuous_coe_real_ereal.comp continuous_snd))
  have hnot : ((u, a) : X × ℝ) ∉ {p : X × ℝ | f p.1 ≤ (p.2 : EReal)} :=
    fun h => (not_le.2 ha) h
  obtain ⟨φ, c, hφ, hc⟩ := geometric_hahn_banach_closed_point hconvex hS hnot
  have hdec : ∀ (x : X) (r : ℝ), φ (x, r) = φ (x, 0) + φ (0, 1) * r := by
    intro x r
    have : ((x, r) : X × ℝ) = (x, 0) + r • ((0 : X), (1 : ℝ)) := by ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]; ring
  have hL : ∀ x : X, (φ.comp (ContinuousLinearMap.inl ℝ X ℝ)) x = φ (x, 0) := fun x => rfl
  refine ⟨φ.comp (ContinuousLinearMap.inl ℝ X ℝ), φ (0, 1), c, ?_, ?_, ?_⟩
  · by_contra hβ
    rw [not_le] at hβ
    obtain ⟨x0, hx0⟩ := hdom
    obtain ⟨r0, hr0⟩ : ∃ r0 : ℝ, f x0 ≤ (r0 : EReal) :=
      ⟨(f x0).toReal, (EReal.le_coe_toReal hx0)⟩
    set t := |c - φ (x0, r0)| / φ (0, 1) with ht
    have htn : 0 ≤ t := div_nonneg (abs_nonneg _) hβ.le
    have hβt : φ (0, 1) * t = |c - φ (x0, r0)| := by
      rw [ht]; field_simp
    have hmem : f x0 ≤ ((r0 + t : ℝ) : EReal) :=
      hr0.trans (EReal.coe_le_coe_iff.2 (by linarith))
    have h1 := hφ (x0, r0 + t) hmem
    rw [hdec] at h1
    have h2 := hdec x0 r0
    have h3 := le_abs_self (c - φ (x0, r0))
    nlinarith
  · intro x r hxr
    rw [hL, ← hdec]
    exact hφ (x, r) hxr
  · rw [hL, ← hdec]; exact hc

lemma exists_of_neg (f : X → EReal) (hbot : ∀ u, f u ≠ ⊥) (L : StrongDual ℝ X) (β c : ℝ)
    (hβ : β < 0) (hsep : ∀ (x : X) (r : ℝ), f x ≤ (r : EReal) → L x + β * r < c)
    (v : X) (a : ℝ) (hc : c < L v + β * a) :
    ∃ (F : StrongDual ℝ X) (k : ℝ), conj f F ≤ (k : EReal) ∧ a < F v - k := by
  have hb : (-β)⁻¹ * (-β) = 1 := inv_mul_cancel₀ (by linarith)
  have hg : 0 < (-β)⁻¹ := inv_pos.2 (by linarith)
  refine ⟨(-β)⁻¹ • L, (-β)⁻¹ * c, ?_, ?_⟩
  · apply conj_le_coe f hbot
    intro x r hxr
    have h := hsep x r hxr
    rw [smul_apply, smul_eq_mul]
    have e : (-β)⁻¹ * (L x + β * r - c) = (-β)⁻¹ * L x - r - (-β)⁻¹ * c := by
      linear_combination (-r) * hb
    have := mul_neg_of_pos_of_neg hg (sub_neg.2 h)
    linarith
  · rw [smul_apply, smul_eq_mul]
    have e : (-β)⁻¹ * (L v + β * a - c) = (-β)⁻¹ * L v - a - (-β)⁻¹ * c := by
      linear_combination (-a) * hb
    have := mul_pos hg (sub_pos.2 hc)
    linarith

#print axioms ereal_cases_ne_bot
#print axioms conj_ge
#print axioms conj_le_coe
#print axioms conj_ne_bot
#print axioms biconj_le
#print axioms lt_sub_conj_of_conj_le
#print axioms epi_sep
#print axioms exists_of_neg

/-- The Fenchel-Moreau theorem. On a Banach space `X`, let the energy `f` be proper (finite
somewhere and never `-∞`), convex (the region on or above its graph is convex) and closed
(lower semicontinuous: `f u ≤ liminf f u_n` whenever `u_n → u` in norm). Then the conjugate of
the conjugate gives `f` back: `f**(u) = f(u)` for every shape `u`. -/
theorem fenchel_moreau_biconjugate_eq [CompleteSpace X] (f : X → EReal)
    (hproper : (∃ u, f u ≠ ⊤) ∧ ∀ u, f u ≠ ⊥)
    (hconvex : Convex ℝ {p : X × ℝ | f p.1 ≤ (p.2 : EReal)})
    (hclosed : LowerSemicontinuous f) :
    ∀ u : X, biconj f u = f u := by
  intro u
  obtain ⟨hdom, hbot⟩ := hproper
  have fin : ∀ (v : X) (a : ℝ), (a : EReal) < f v → f v ≠ ⊤ →
      ∃ (F : StrongDual ℝ X) (k : ℝ), conj f F ≤ (k : EReal) ∧ a < F v - k := by
    intro v a ha hv
    obtain ⟨L, β, c, hβ, hsep, hc⟩ := epi_sep f hdom hconvex hclosed v a ha
    have hβ' : β < 0 := by
      rcases hβ.lt_or_eq with h | h
      · exact h
      · exfalso
        have h1 := hsep v (f v).toReal (EReal.le_coe_toReal hv)
        rw [h, zero_mul, add_zero] at h1 hc
        linarith
    exact exists_of_neg f hbot L β c hβ' hsep v a hc
  have key : ∀ (v : X) (a : ℝ), (a : EReal) < f v →
      ∃ (F : StrongDual ℝ X) (k : ℝ), conj f F ≤ (k : EReal) ∧ a < F v - k := by
    intro v a ha
    by_cases hv : f v = ⊤
    swap
    · exact fin v a ha hv
    obtain ⟨u0, hu0⟩ := hdom
    obtain ⟨F0, k0, hk0, -⟩ := fin u0 ((f u0).toReal - 1)
      (lt_of_lt_of_eq (EReal.coe_lt_coe_iff.2 (by linarith)) (EReal.coe_toReal hu0 (hbot u0)))
      hu0
    obtain ⟨L, β, c, hβ, hsep, hc⟩ := epi_sep f ⟨u0, hu0⟩ hconvex hclosed v a ha
    rcases hβ.lt_or_eq with hβ' | hβ0
    · exact exists_of_neg f hbot L β c hβ' hsep v a hc
    rw [hβ0, zero_mul, add_zero] at hc
    have hd : 0 < L v - c := by linarith
    set t := (|a - F0 v + k0| + 1) / (L v - c) with ht
    have ht0 : 0 ≤ t := div_nonneg (by positivity) hd.le
    have htd : t * (L v - c) = |a - F0 v + k0| + 1 := by
      rw [ht]; field_simp
    refine ⟨F0 + t • L, k0 + t * c, ?_, ?_⟩
    · apply conj_le_coe f hbot
      intro x r hxr
      have h1 : F0 x - r ≤ k0 := by
        have e1 : ((F0 x : ℝ) : EReal) - (r : EReal) ≤ ((F0 x : ℝ) : EReal) - f x :=
          EReal.sub_le_sub le_rfl hxr
        have e2 := (e1.trans (conj_ge f F0 x)).trans hk0
        rw [← EReal.coe_sub, EReal.coe_le_coe_iff] at e2
        exact e2
      have h2 : L x < c := by
        have := hsep x r hxr
        rwa [hβ0, zero_mul, add_zero] at this
      rw [add_apply, smul_apply, smul_eq_mul]
      nlinarith [mul_le_mul_of_nonneg_left h2.le ht0]
    · rw [add_apply, smul_apply, smul_eq_mul]
      have := le_abs_self (a - F0 v + k0)
      nlinarith
  refine le_antisymm (biconj_le f hbot u) ?_
  by_contra hlt
  rw [not_le] at hlt
  obtain ⟨a, h1, h2⟩ := EReal.lt_iff_exists_real_btwn.1 hlt
  obtain ⟨F, k, hk, hak⟩ := key u a h2
  have h3 := lt_sub_conj_of_conj_le f F u k a hk hak
  have h4 : ((F u : ℝ) : EReal) - conj f F ≤ biconj f u :=
    le_iSup (fun G : StrongDual ℝ X => ((G u : ℝ) : EReal) - conj f G) F
  exact absurd (h3.trans_le h4) (not_lt.2 h1.le)

/-- Slopes through the conjugate. For a proper energy `f`, a load `F` is a subgradient of `f`
at the shape `u` exactly when energy plus conjugate equals the work there:
`f(u) + f*(F) = ⟨F, u⟩`, the tie case of the Fenchel-Young inequality. -/
theorem subgradient_iff_fenchel_young_tie (f : X → EReal)
    (hproper : (∃ u, f u ≠ ⊤) ∧ ∀ u, f u ≠ ⊥) (u : X) (F : StrongDual ℝ X) :
    IsSubgradient f u F ↔ f u + conj f F = ((F u : ℝ) : EReal) := by
  obtain ⟨hdom, hbot⟩ := hproper
  have hcb := conj_ne_bot f ⟨hdom, hbot⟩ F
  rcases ereal_cases_ne_bot (hbot u) with hu | ⟨a, hu⟩
  · constructor
    · intro h
      obtain ⟨u0, hu0⟩ := hdom
      have := h u0
      rw [hu, EReal.top_add_coe, top_le_iff] at this
      exact absurd this hu0
    · intro h
      rw [hu, EReal.top_add_of_ne_bot hcb] at h
      exact absurd h (EReal.top_ne_coe _)
  · rw [hu]
    constructor
    · intro h
      have hle : conj f F ≤ ((F u - a : ℝ) : EReal) := by
        apply conj_le_coe f hbot
        intro x r hxr
        have := (h x).trans hxr
        rw [hu, ← EReal.coe_add, EReal.coe_le_coe_iff, map_sub] at this
        linarith
      have hge : ((F u - a : ℝ) : EReal) ≤ conj f F := by
        have := conj_ge f F u
        rwa [hu, ← EReal.coe_sub] at this
      rw [le_antisymm hle hge, ← EReal.coe_add]
      congr 1; ring
    · intro h
      rcases ereal_cases_ne_bot hcb with hc | ⟨c, hc⟩
      · rw [hc, EReal.coe_add_top] at h
        exact absurd h (EReal.top_ne_coe _)
      · rw [hc, ← EReal.coe_add, EReal.coe_eq_coe_iff] at h
        intro v
        rcases ereal_cases_ne_bot (hbot v) with hv | ⟨b, hv⟩
        · rw [hv]; exact le_top
        · have := conj_ge f F v
          rw [hv, hc, ← EReal.coe_sub, EReal.coe_le_coe_iff] at this
          rw [hu, hv, ← EReal.coe_add, EReal.coe_le_coe_iff, map_sub]
          linarith

/-- When `f** = f` (for a proper `f`), the roles swap: the load `F` is a slope of `f` at the
shape `u` exactly when the shape `u` is a slope of the conjugate `f*` at the load `F`. -/
theorem subgradient_iff_conj_subgradient (f : X → EReal)
    (hproper : (∃ u, f u ≠ ⊤) ∧ ∀ u, f u ≠ ⊥) (hbi : ∀ u, biconj f u = f u)
    (u : X) (F : StrongDual ℝ X) :
    IsSubgradient f u F ↔ IsConjSubgradient f F u := by
  have hbot := hproper.2
  have hcb := conj_ne_bot f hproper F
  constructor
  · intro h
    have ht := (subgradient_iff_fenchel_young_tie f hproper u F).1 h
    rcases ereal_cases_ne_bot (hbot u) with hu | ⟨a, hu⟩
    · rw [hu, EReal.top_add_of_ne_bot hcb] at ht
      exact absurd ht (EReal.top_ne_coe _)
    rcases ereal_cases_ne_bot hcb with hc | ⟨c, hc⟩
    · rw [hc, hu, EReal.coe_add_top] at ht
      exact absurd ht (EReal.top_ne_coe _)
    rw [hu, hc, ← EReal.coe_add, EReal.coe_eq_coe_iff] at ht
    intro G
    have := conj_ge f G u
    rw [hu, ← EReal.coe_sub] at this
    rw [hc, ← EReal.coe_add]
    refine le_trans (le_of_eq ?_) this
    congr 1
    rw [sub_apply]
    linarith
  · intro h
    rcases ereal_cases_ne_bot hcb with hc | ⟨c, hc⟩
    · exfalso
      have hall : ∀ G, conj f G = ⊤ := fun G => by
        have := h G
        rw [hc, EReal.top_add_coe, top_le_iff] at this
        exact this
      have hb : biconj f u = ⊥ := by
        apply le_antisymm _ bot_le
        refine iSup_le fun G => ?_
        rw [hall G, EReal.sub_top]
      rw [hbi u] at hb
      exact hbot u hb
    · apply (subgradient_iff_fenchel_young_tie f hproper u F).2
      have hle : f u ≤ ((F u - c : ℝ) : EReal) := by
        rw [← hbi u]
        refine iSup_le fun G => ?_
        have h1 := h G
        rw [hc, ← EReal.coe_add] at h1
        have h2 := EReal.sub_le_sub (le_refl ((G u : ℝ) : EReal)) h1
        rw [← EReal.coe_sub] at h2
        refine h2.trans (le_of_eq ?_)
        congr 1
        rw [sub_apply]
        ring
      have hge : ((F u - c : ℝ) : EReal) ≤ f u := by
        rw [← hbi u]
        have h1 : ((F u : ℝ) : EReal) - conj f F ≤ biconj f u :=
          le_iSup (fun G : StrongDual ℝ X => ((G u : ℝ) : EReal) - conj f G) F
        rw [hc, ← EReal.coe_sub] at h1
        exact h1
      rw [le_antisymm hle hge, hc, ← EReal.coe_add]
      congr 1
      ring

/-! Worked numbers from the card, one point (N = 1, h = 1 m), as exact fractions:
5 cm = 1/20 m, 3 cm = 3/100 m, 0.25 J = 1/4 J. Energy f₁(u) = 100 u², conjugate F²/400. -/

-- Spring rate 4T/L = 400/2 = 200 N/m; sag under the 10 N towel 10/200 = 1/20 m.
example : (4 * 100 : ℚ) / 2 = 200 ∧ (10 : ℚ) / 200 = 1 / 20 := by norm_num
-- Energy stored 100 × (1/20)² = 1/4 J; conjugate at 10 N is 10²/400 = 1/4 J.
example : (100 : ℚ) * (1 / 20) ^ 2 = 1 / 4 ∧ (10 : ℚ) ^ 2 / 400 = 1 / 4 := by norm_num
-- Fenchel-Young tie for the towel: 1/4 + 1/4 = 10 × 1/20.
example : (1 / 4 : ℚ) + 1 / 4 = 10 * (1 / 20) := by norm_num
-- Energy rebuilt at 5 cm: the gain (1/20) F - F²/400 at F = 10 is 1/4 J, and no load does better.
example : (1 / 20 : ℚ) * 10 - 10 ^ 2 / 400 = 1 / 4 ∧
    ∀ F : ℚ, (1 / 20) * F - F ^ 2 / 400 ≤ 1 / 4 := by
  refine ⟨by norm_num, fun F => ?_⟩
  nlinarith [sq_nonneg (F - 10)]
-- Rebuilt at 2 cm: the best gain (1/50) F - F²/400 is at F = 4, equal to 100 × (1/50)² = 1/25 J.
example : (1 / 50 : ℚ) * 4 - 4 ^ 2 / 400 = 1 / 25 ∧ (100 : ℚ) * (1 / 50) ^ 2 = 1 / 25 := by
  norm_num
-- Fence at 3 cm: the line's push-back 200 × 3/100 = 6 N; energy there 100 × (3/100)² = 9/100 J;
-- conjugate at 10 N is (3/100) × 10 - 9/100 = 21/100 J; the fence holds 10 - 6 = 4 N.
example : (200 : ℚ) * (3 / 100) = 6 ∧ (100 : ℚ) * (3 / 100) ^ 2 = 9 / 100 ∧
    (3 / 100 : ℚ) * 10 - 9 / 100 = 21 / 100 ∧ (10 : ℚ) - 6 = 4 := by norm_num
-- The two pieces of the fenced conjugate meet at 6 N: 6²/400 = (3/100) × 6 - 9/100.
example : (6 : ℚ) ^ 2 / 400 = 3 / 100 * 6 - 9 / 100 := by norm_num
-- Below 6 N the Fenchel-Young gap at the fence is (F - 6)²/400; at 5 N it is 1/400 J.
example (F : ℚ) : 9 / 100 + F ^ 2 / 400 - 3 / 100 * F = (F - 6) ^ 2 / 400 := by ring
example : (9 / 100 : ℚ) + 5 ^ 2 / 400 - 3 / 100 * 5 = 1 / 400 := by norm_num
-- From 6 N up the gap is zero: 9/100 + ((3/100) F - 9/100) = (3/100) F.
example (F : ℚ) : 9 / 100 + (3 / 100 * F - 9 / 100) = 3 / 100 * F := by ring
-- Loads 0, 1/2, ..., 20 N (k/2 for k = 0..40): exactly the 29 with k ≥ 12 (F ≥ 6 N) tie.
example : ((Finset.range 41).filter (fun k => 12 ≤ k)).card = 29 := by decide
-- Past the fence at 4 cm the rebuilt value is (1/100) F + 9/100: 109/100 J at 100 N, 1009/100 J at 1000 N.
example (F : ℚ) : 4 / 100 * F - (3 / 100 * F - 9 / 100) = 1 / 100 * F + 9 / 100 := by ring
example : (1 / 100 : ℚ) * 100 + 9 / 100 = 109 / 100 ∧ (1 / 100 : ℚ) * 1000 + 9 / 100 = 1009 / 100 := by
  norm_num
-- Two rest positions at 3 cm: energy 100 × min((3/100)², (3/100 - 6/100)²) = 9/100 J.
example : (100 : ℚ) * min ((3 / 100) ^ 2) ((3 / 100 - 6 / 100) ^ 2) = 9 / 100 := by norm_num
-- Green's function G(1, 1) = 1 × (2 - 1)/(100 × 2) = 1/200 m/N; the towel's sag 10 × 1/200 = 1/20 m.
example : (1 : ℚ) * (2 - 1) / (100 * 2) = 1 / 200 ∧ (10 : ℚ) * (1 / 200) = 1 / 20 := by norm_num
-- Step energy 0.25/h J: 1/4, 1, 4, 16 J at h = 1, 1/4, 1/16, 1/64 (N = 1, 7, 31, 127).
example : (1 / 4 : ℚ) / 1 = 1 / 4 ∧ (1 / 4 : ℚ) / (1 / 4) = 1 ∧ (1 / 4 : ℚ) / (1 / 16) = 4 ∧
    (1 / 4 : ℚ) / (1 / 64) = 16 := by norm_num
-- Spacing h = L/(N + 1) = 2/(N + 1): 1, 1/4, 1/16, 1/64 at N = 1, 7, 31, 127.
example : (2 : ℚ) / (1 + 1) = 1 ∧ (2 : ℚ) / (7 + 1) = 1 / 4 ∧ (2 : ℚ) / (31 + 1) = 1 / 16 ∧
    (2 : ℚ) / (127 + 1) = 1 / 64 := by norm_num
-- Tent slope size 10/√h: 10, 20, 40, 80, since (10/s)² × h = 100 with s² = h for s = 1, 1/2, 1/4, 1/8.
example : (10 / (1 : ℚ)) ^ 2 * 1 = 100 ∧ (20 : ℚ) ^ 2 * (1 / 4) = 100 ∧ (40 : ℚ) ^ 2 * (1 / 16) = 100 ∧
    (80 : ℚ) ^ 2 * (1 / 64) = 100 := by norm_num
-- Try changing: a 16 N towel at the fence gives conjugate (3/100) × 16 - 9/100 = 39/100 J, fence 16 - 6 = 10 N;
-- tension 200 N gives sag 10/400 = 1/40 m, conjugate 10²/800 = 1/8 J.
example : (3 / 100 : ℚ) * 16 - 9 / 100 = 39 / 100 ∧ (16 : ℚ) - 6 = 10 ∧
    (10 : ℚ) / 400 = 1 / 40 ∧ (10 : ℚ) ^ 2 / 800 = 1 / 8 := by norm_num

#print axioms fenchel_moreau_biconjugate_eq
#print axioms subgradient_iff_fenchel_young_tie
#print axioms subgradient_iff_conj_subgradient
