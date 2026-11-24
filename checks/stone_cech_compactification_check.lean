-- Stone-Cech compactification: a completely regular space sits densely inside its Stone-Cech compactification, every continuous map into a compact Hausdorff space (so every bounded real function) extends to it in exactly one way, and for the counting numbers its points are the ultrafilters, where a bounded list reads its limit along the ultrafilter.
import Mathlib.Topology.Separation.CompletelyRegular
import Mathlib.Topology.Instances.Real.Lemmas

open Filter Topology

universe u v

/-! `StoneCech X` is Mathlib's Stone-Cech compactification, `stoneCechUnit` sends a point of `X` to
its copy there. `T35Space X` is "completely regular with closed points", the card's hypothesis.
The counting numbers `ℕ` carry the discrete topology, and `Ultrafilter ℕ` carries the topology whose
basic open sets are the ultrafilters holding a fixed set `A`. -/

/-- The card's main claim. If `X` is completely regular (points closed, and continuous functions
pry a point away from any closed set missing it), then `X` sits as a dense copy inside its
Stone-Cech compactification, which is compact and Hausdorff, and every continuous map `g` from `X`
to a compact Hausdorff space `K` extends to the compactification in exactly one continuous way. -/
theorem stone_cech_dense_embedding_and_unique_extension (X : Type u) [TopologicalSpace X]
    [T35Space X] :
    IsDenseEmbedding (stoneCechUnit : X → StoneCech X) ∧ CompactSpace (StoneCech X) ∧
      T2Space (StoneCech X) ∧
      ∀ (K : Type v) [TopologicalSpace K] [CompactSpace K] [T2Space K] (g : X → K),
        Continuous g → ∃! G : StoneCech X → K, Continuous G ∧ G ∘ stoneCechUnit = g := by
  refine ⟨isDenseEmbedding_stoneCechUnit, inferInstance, inferInstance, ?_⟩
  intro K _ _ _ g hg
  refine ⟨stoneCechExtend hg, ⟨continuous_stoneCechExtend hg, stoneCechExtend_extends hg⟩, ?_⟩
  rintro G ⟨hG, hGg⟩
  exact stoneCech_hom_ext hG (continuous_stoneCechExtend hg)
    (hGg.trans (stoneCechExtend_extends hg).symm)

#print axioms stone_cech_dense_embedding_and_unique_extension

/-- Step 4: on a completely regular space, every bounded continuous real function `f` extends
to the Stone-Cech compactification in exactly one continuous way. -/
theorem bounded_continuous_extends_uniquely (X : Type u) [TopologicalSpace X] [T35Space X]
    (f : X → ℝ) (hf : Continuous f) (hb : ∃ C, ∀ x, |f x| ≤ C) :
    ∃! F : StoneCech X → ℝ, Continuous F ∧ F ∘ stoneCechUnit = f := by
  obtain ⟨C, hC⟩ := hb
  let g : X → Set.Icc (-C) C := fun x => ⟨f x, abs_le.mp (hC x)⟩
  have hg : Continuous g := hf.subtype_mk _
  refine ⟨Subtype.val ∘ stoneCechExtend hg,
    ⟨continuous_subtype_val.comp (continuous_stoneCechExtend hg), ?_⟩, ?_⟩
  · rw [Function.comp_assoc, stoneCechExtend_extends hg]
    rfl
  · rintro G ⟨hG, hGf⟩
    refine stoneCech_hom_ext hG (continuous_subtype_val.comp (continuous_stoneCechExtend hg)) ?_
    rw [hGf, Function.comp_assoc, stoneCechExtend_extends hg]
    rfl

#print axioms bounded_continuous_extends_uniquely

/-- Steps 8 and 9: for the counting numbers, beta N is the space of ultrafilters on N, with each
`n` matched to the principal ultrafilter at `n`; and a bounded list `a` reads `L` at the ultrafilter
`p` exactly when, for every tolerance `ε > 0`, the set of `n` with `|a n - L| < ε` is in `p`. -/
theorem stone_cech_nat_is_ultrafilters :
    ∃ h : StoneCech ℕ ≃ₜ Ultrafilter ℕ, (∀ n, h (stoneCechUnit n) = pure n) ∧
      ∀ (a : ℕ → ℝ), (∃ C, ∀ n, |a n| ≤ C) →
        ∀ F : StoneCech ℕ → ℝ, Continuous F → F ∘ stoneCechUnit = a →
          ∀ (p : Ultrafilter ℕ) (L : ℝ),
            F (h.symm p) = L ↔ ∀ ε > 0, {n | |a n - L| < ε} ∈ p := by
  have hp : Continuous (pure : ℕ → Ultrafilter ℕ) := continuous_of_discreteTopology
  let φ : StoneCech ℕ → Ultrafilter ℕ := stoneCechExtend hp
  let ψ : Ultrafilter ℕ → StoneCech ℕ := Ultrafilter.extend stoneCechUnit
  have hφ : Continuous φ := continuous_stoneCechExtend hp
  have hψ : Continuous ψ := continuous_ultrafilter_extend _
  have hφu : φ ∘ stoneCechUnit = pure := stoneCechExtend_extends hp
  have hψp : ψ ∘ pure = stoneCechUnit := ultrafilter_extend_extends _
  have h1 : ψ ∘ φ = id := by
    refine stoneCech_hom_ext (hψ.comp hφ) continuous_id ?_
    rw [Function.comp_assoc, hφu, hψp]
    rfl
  have h2 : φ ∘ ψ = id := by
    refine Continuous.ext_on denseRange_pure (hφ.comp hψ) continuous_id ?_
    rintro _ ⟨n, rfl⟩
    show φ ((ψ ∘ pure) n) = pure n
    rw [hψp]
    exact congrFun hφu n
  let h : StoneCech ℕ ≃ₜ Ultrafilter ℕ :=
    { toFun := φ
      invFun := ψ
      left_inv := fun x => congrFun h1 x
      right_inv := fun x => congrFun h2 x
      continuous_toFun := hφ
      continuous_invFun := hψ }
  refine ⟨h, fun n => congrFun hφu n, ?_⟩
  intro a _ F hF hFa p L
  have hsymm : h.symm p = ψ p := rfl
  rw [hsymm]
  have ht : Tendsto a p (𝓝 (F (ψ p))) := by
    have h3 : Tendsto (F ∘ ψ) (𝓝 p) (𝓝 (F (ψ p))) := (hF.comp hψ).tendsto p
    have h4 := h3.comp (Ultrafilter.tendsto_pure_self p)
    have h5 : (F ∘ ψ) ∘ pure = a := by
      rw [Function.comp_assoc, hψp, hFa]
    rwa [h5] at h4
  have key : F (ψ p) = L ↔ Tendsto a p (𝓝 L) := by
    constructor
    · rintro rfl; exact ht
    · intro hL; exact tendsto_nhds_unique ht hL
  rw [key, Metric.tendsto_nhds]
  simp only [Real.dist_eq]
  rfl

#print axioms stone_cech_nat_is_ultrafilters

/-! The card's whole-number worked examples. -/

-- (-1)^n at n = 1000, 1001, 10^6, 10^6 + 1 gives 1, -1, 1, -1: one point at infinity cannot hold both.
example : ((-1 : ℤ) ^ 1000, (-1 : ℤ) ^ 1001, (-1 : ℤ) ^ (10 ^ 6), (-1 : ℤ) ^ (10 ^ 6 + 1))
    = (1, -1, 1, -1) := by norm_num

-- 30 halvings of [-2, 2) leave an interval of width 4/2^30 = 1/268435456.
example : (4 : ℚ) / 2 ^ 30 = 1 / 268435456 := by norm_num

-- New points forced by 1/n, (-1)^n, n mod 3, n mod 4, n mod 5: lcm of the periods 1, 2, 6, 12, 60.
example : Nat.lcm 1 2 = 2 ∧ Nat.lcm 2 3 = 6 ∧ Nat.lcm 6 4 = 12 ∧ Nat.lcm 12 5 = 60 := by decide

-- On 4 points there are 2^4 - 1 = 15 filters, one for each non-empty set of points.
example : 2 ^ 4 - 1 = 15 := by norm_num

-- Stereographic projection at t = 1000 lands on the circle: (2000/1000001, 999999/1000001).
example : (2 * 1000 / (1 + 1000 ^ 2) : ℚ) = 2000 / 1000001 ∧
    ((1000 ^ 2 - 1) / (1 + 1000 ^ 2) : ℚ) = 999999 / 1000001 ∧
    (2000 / 1000001 : ℚ) ^ 2 + (999999 / 1000001) ^ 2 = 1 := by norm_num

-- t^2/(1+t^2) reads 1000000/1000001 at both t = 1000 and t = -1000: one limit, it extends.
example : ((1000 : ℚ) ^ 2 / (1 + 1000 ^ 2), ((-1000) : ℚ) ^ 2 / (1 + (-1000) ^ 2))
    = (1000000 / 1000001, 1000000 / 1000001) := by norm_num

-- t/(1+|t|) reads 1000/1001 and -1000/1001 at t = 1000 and t = -1000: two limits, no value at the pole.
example : ((1000 : ℚ) / (1 + |(1000 : ℚ)|), (-1000 : ℚ) / (1 + |(-1000 : ℚ)|))
    = (1000 / 1001, -1000 / 1001) := by norm_num
