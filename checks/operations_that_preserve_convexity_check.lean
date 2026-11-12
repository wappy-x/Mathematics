-- Building convex functions: sums with weights that are not negative, maxima, affine changes of variable, convex rising outer functions and partial minimisation over a convex set keep convex functions convex, and the coffee cost built this way is convex with least value 1271/128 at the recipe (67/128, 55/128, 6/128).
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Convex.StdSimplex
import Mathlib.LinearAlgebra.AffineSpace.AffineMap
import Mathlib.Data.Fin.VecNotation

/-- The card's coffee cost per kilo for a recipe `x = (x₁, x₂, x₃)` of Brazil, Colombia and
Ethiopia shares: the worst of the three quotes A (8, 12, 11), B (10, 9, 12), C (9, 11, 9),
plus half of any part above the £10 budget, plus £2 times the squared miss of the strength
`5x₁ + 9x₂ + 7x₃` from 7. -/
noncomputable def coffeeCost (x : Fin 3 → ℝ) : ℝ :=
  let Q := max (max (8 * x 0 + 12 * x 1 + 11 * x 2) (10 * x 0 + 9 * x 1 + 12 * x 2))
    (9 * x 0 + 11 * x 1 + 9 * x 2)
  (Q + 1 / 2 * max 0 (Q - 10)) + 2 * (5 * x 0 + 9 * x 1 + 7 * x 2 - 7) ^ 2

/-- A function `c₀ x₀ + c₁ x₁ + c₂ x₂ + d` is convex on all of `ℝ³`. -/
theorem coffee_affine_convexOn (c₀ c₁ c₂ d : ℝ) :
    ConvexOn ℝ Set.univ (fun x : Fin 3 → ℝ => c₀ * x 0 + c₁ * x 1 + c₂ * x 2 + d) := by
  refine ⟨convex_univ, fun x _ y _ a b _ _ hab => le_of_eq ?_⟩
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  linear_combination (-d) * hab

/-- The taste penalty `2 (5x₀ + 9x₁ + 7x₂ − 7)²` is convex on all of `ℝ³`. -/
theorem coffee_taste_convexOn :
    ConvexOn ℝ Set.univ (fun x : Fin 3 → ℝ => 2 * (5 * x 0 + 9 * x 1 + 7 * x 2 - 7) ^ 2) := by
  refine ⟨convex_univ, fun x _ y _ a b ha hb hab => ?_⟩
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  have hb' : b = 1 - a := by linarith
  subst hb'
  nlinarith [mul_nonneg ha hb, sq_nonneg ((5 * x 0 + 9 * x 1 + 7 * x 2) - (5 * y 0 + 9 * y 1 + 7 * y 2)),
    mul_nonneg (mul_nonneg ha hb) (sq_nonneg ((5 * x 0 + 9 * x 1 + 7 * x 2) - (5 * y 0 + 9 * y 1 + 7 * y 2)))]

/-- The budget step `t ↦ t + ½ max 0 (t − 10)` is convex on all of `ℝ`. -/
theorem coffee_budget_convexOn :
    ConvexOn ℝ Set.univ (fun t : ℝ => t + 1 / 2 * max 0 (t - 10)) := by
  have h1 : ConvexOn ℝ Set.univ (fun t : ℝ => t) := convexOn_id convex_univ
  have h2 : ConvexOn ℝ Set.univ (fun t : ℝ => max 0 (t - 10)) :=
    (convexOn_const 0 convex_univ).sup ((convexOn_id convex_univ).add_const (-10)) |>.congr
      (fun t _ => by simp [sub_eq_add_neg])
  exact h1.add (h2.smul (by norm_num : (0:ℝ) ≤ 1 / 2))

theorem coffee_budget_monotone : Monotone (fun t : ℝ => t + 1 / 2 * max 0 (t - 10)) := by
  intro s t hst
  have : max 0 (s - 10) ≤ max 0 (t - 10) := max_le_max le_rfl (by linarith)
  simp only
  linarith

/-- The five rules. For convex functions `φ` and `ψ`:
(1) `φ + ψ` and `a φ` with `a ≥ 0` are convex;
(2) the larger of the two, `max φ ψ`, is convex;
(3) `φ (A x + b)` is convex for any affine (straight-line) map, with no further condition;
(4) `h (φ x)` is convex when `h` is convex and never falls;
(5) `V x = inf_{y ∈ K} φ (x, y)` is convex when `φ` is convex in the pair `(x, y)`, `K` is a
convex set, and `V` is never `-∞` (each infimum is bounded below; `K` is not empty). -/
theorem operations_preserve_convexity
    {E F : Type*} [AddCommGroup E] [Module ℝ E] [AddCommGroup F] [Module ℝ F] :
    (∀ (s : Set E) (φ ψ : E → ℝ) (a : ℝ), ConvexOn ℝ s φ → ConvexOn ℝ s ψ → 0 ≤ a →
        ConvexOn ℝ s (fun x => φ x + ψ x) ∧ ConvexOn ℝ s (fun x => a * φ x)) ∧
    (∀ (s : Set E) (φ ψ : E → ℝ), ConvexOn ℝ s φ → ConvexOn ℝ s ψ →
        ConvexOn ℝ s (fun x => max (φ x) (ψ x))) ∧
    (∀ (t : Set F) (φ : F → ℝ) (A : E →ᵃ[ℝ] F), ConvexOn ℝ t φ →
        ConvexOn ℝ (A ⁻¹' t) (fun x => φ (A x))) ∧
    (∀ (s : Set E) (φ : E → ℝ) (h : ℝ → ℝ), ConvexOn ℝ s φ → ConvexOn ℝ Set.univ h →
        Monotone h → ConvexOn ℝ s (fun x => h (φ x))) ∧
    (∀ (K : Set F) (φ : E × F → ℝ), Convex ℝ K → K.Nonempty →
        ConvexOn ℝ (Set.univ ×ˢ K) φ → (∀ x, BddBelow ((fun y => φ (x, y)) '' K)) →
        ConvexOn ℝ Set.univ (fun x => sInf ((fun y => φ (x, y)) '' K))) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro s φ ψ a hφ hψ ha
    exact ⟨hφ.add hψ, hφ.smul ha⟩
  · intro s φ ψ hφ hψ
    exact hφ.sup hψ
  · intro t φ A hφ
    exact hφ.comp_affineMap A
  · intro s φ h hφ hh hmono
    exact ⟨hφ.1, fun x hx y hy a b ha hb hab =>
      (hmono (hφ.2 hx hy ha hb hab)).trans (hh.2 (Set.mem_univ _) (Set.mem_univ _) ha hb hab)⟩
  · intro K φ hK hKne hφ hbdd
    refine ⟨convex_univ, ?_⟩
    intro x₁ _ x₂ _ a b ha hb hab
    have hne : ∀ x, ((fun y => φ (x, y)) '' K).Nonempty := fun x => hKne.image _
    show sInf _ ≤ a • sInf _ + b • sInf _
    simp only [smul_eq_mul]
    refine le_of_forall_pos_le_add fun ε hε => ?_
    obtain ⟨_, ⟨y₁, hy₁, rfl⟩, h₁⟩ :=
      exists_lt_of_csInf_lt (hne x₁) (lt_add_of_pos_right (sInf ((fun y => φ (x₁, y)) '' K)) hε)
    obtain ⟨_, ⟨y₂, hy₂, rfl⟩, h₂⟩ :=
      exists_lt_of_csInf_lt (hne x₂) (lt_add_of_pos_right (sInf ((fun y => φ (x₂, y)) '' K)) hε)
    have hy : a • y₁ + b • y₂ ∈ K := hK hy₁ hy₂ ha hb hab
    have hle : sInf ((fun y => φ (a • x₁ + b • x₂, y)) '' K) ≤ φ (a • x₁ + b • x₂, a • y₁ + b • y₂) :=
      csInf_le (hbdd _) ⟨_, hy, rfl⟩
    have hconv := hφ.2 (x := (x₁, y₁)) (y := (x₂, y₂)) ⟨Set.mem_univ _, hy₁⟩ ⟨Set.mem_univ _, hy₂⟩
      ha hb hab
    simp only [Prod.smul_mk, Prod.mk_add_mk, smul_eq_mul] at hconv
    simp only at h₁ h₂
    have e1 : a * φ (x₁, y₁) ≤ a * (sInf ((fun y => φ (x₁, y)) '' K) + ε) :=
      mul_le_mul_of_nonneg_left h₁.le ha
    have e2 : b * φ (x₂, y₂) ≤ b * (sInf ((fun y => φ (x₂, y)) '' K) + ε) :=
      mul_le_mul_of_nonneg_left h₂.le hb
    have hε' : a * ε + b * ε = ε := by rw [← add_mul, hab, one_mul]
    nlinarith

/-- Step 6, the certificate: the coffee cost, assembled only from the five rules, is convex
on the set of recipes (shares at least 0 that add to 1). -/
theorem coffee_cost_convex : ConvexOn ℝ (stdSimplex ℝ (Fin 3)) coffeeCost := by
  have hA := coffee_affine_convexOn 8 12 11 0
  have hB := coffee_affine_convexOn 10 9 12 0
  have hC := coffee_affine_convexOn 9 11 9 0
  simp only [add_zero] at hA hB hC
  have hQ := (hA.sup hB).sup hC
  have hH : ConvexOn ℝ Set.univ (fun x : Fin 3 → ℝ =>
      (fun t : ℝ => t + 1 / 2 * max 0 (t - 10))
        (max (max (8 * x 0 + 12 * x 1 + 11 * x 2) (10 * x 0 + 9 * x 1 + 12 * x 2))
          (9 * x 0 + 11 * x 1 + 9 * x 2))) :=
    ⟨convex_univ, fun x hx y hy a b ha hb hab =>
      (coffee_budget_monotone (hQ.2 hx hy ha hb hab)).trans
        (coffee_budget_convexOn.2 (Set.mem_univ _) (Set.mem_univ _) ha hb hab)⟩
  exact (hH.add coffee_taste_convexOn).subset (Set.subset_univ _) (convex_stdSimplex ℝ (Fin 3))


/-- The worked numbers and the subgradient certificate: the recipe 67/128 Brazil,
55/128 Colombia, 6/128 Ethiopia costs exactly £9.9296875 = 1271/128 a kilo, and no recipe
is cheaper. -/
theorem coffee_cost_minimum :
    coffeeCost ![67 / 128, 55 / 128, 6 / 128] = 1271 / 128 ∧
      ∀ x ∈ stdSimplex ℝ (Fin 3), (1271 / 128 : ℝ) ≤ coffeeCost x := by
  refine ⟨?_, ?_⟩
  · simp only [coffeeCost, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
      Matrix.head_cons, Matrix.tail_cons]
    norm_num
  · intro x hx
    obtain ⟨h0, hsum⟩ := hx
    simp only [Fin.sum_univ_three] at hsum
    have hx0 := h0 0
    have hx1 := h0 1
    have hx2 := h0 2
    simp only [coffeeCost]
    set A := 8 * x 0 + 12 * x 1 + 11 * x 2
    set B := 10 * x 0 + 9 * x 1 + 12 * x 2
    set C := 9 * x 0 + 11 * x 1 + 9 * x 2
    set Q := max (max A B) C with hQ
    have hAQ : A ≤ Q := (le_max_left A B).trans (le_max_left _ C)
    have hCQ : C ≤ Q := le_max_right _ C
    have hP : 0 ≤ max 0 (Q - 10) := le_max_left _ _
    nlinarith [sq_nonneg (5 * x 0 + 9 * x 1 + 7 * x 2 - 872 / 128)]

-- The worked numbers, in 128ths: quotes A, B, C and the strength at the best recipe.
example : 8 * 67 + 12 * 55 + 11 * 6 = 1262 := by norm_num
example : 10 * 67 + 9 * 55 + 12 * 6 = 1237 := by norm_num
example : 9 * 67 + 11 * 55 + 9 * 6 = 1262 := by norm_num
example : 5 * 67 + 9 * 55 + 7 * 6 = 872 := by norm_num
example : 67 + 55 + 6 = 128 := by norm_num
-- The grid search lists (128 + 1)(128 + 2)/2 = 8385 recipes.
example : (128 + 1) * (128 + 2) / 2 = 8385 := by norm_num
-- Built cost in 128ths: worst quote 1262 plus taste penalty 9 (2 × (872/128 − 7)² = 9/128).
example : (2 : ℚ) * (872 / 128 - 7) ^ 2 = 9 / 128 := by norm_num
example : 1262 + 9 = 1271 := by norm_num
-- Certificate: A + C prices plus twice the taste slope are equal for every bean (2 × 4.75 = 9.5).
example : ((8 + 9 : ℚ) + 2 * (2 * 2 * (872 / 128 - 7) * 5)) = 19 / 2 ∧
    ((12 + 11 : ℚ) + 2 * (2 * 2 * (872 / 128 - 7) * 9)) = 19 / 2 ∧
    ((11 + 9 : ℚ) + 2 * (2 * 2 * (872 / 128 - 7) * 7)) = 19 / 2 := by norm_num

#print axioms coffee_affine_convexOn
#print axioms coffee_taste_convexOn
#print axioms coffee_budget_convexOn
#print axioms coffee_budget_monotone
#print axioms operations_preserve_convexity
#print axioms coffee_cost_convex
#print axioms coffee_cost_minimum
