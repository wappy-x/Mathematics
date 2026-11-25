-- Hyperelliptic curves and the canonical map: on y² = f(x) with deg f = n the differentials x^i dx/y that stay finite at infinity are exactly those with i < ⌊(n − 1)/2⌋, the Riemann-Hurwitz genus, with deg K = 2g − 2; on a smooth plane curve of degree d they number (d − 1)(d − 2)/2; and the canonical map (1 : x : … : x^(g−1)) joins each point to its mirror and lands on the curve u_i u_j = u_k u_l.
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.NatAntidiagonal
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace HyperellipticCanonical

/-! **Orders at infinity on `y² = f(x)`, `deg f = n`** (the card's Step 2). For odd `n` the smooth
model has one point at infinity, where `ord x = −2`, `ord y = −n` and `ord dx = −3`. For even `n`
it has two, and at each `ord x = −1`, `ord y = −n/2` and `ord dx = −2`. The differential
`x^i dx/y` is finite and nonzero at every finite point (Step 1), so it is holomorphic exactly when
its order `i·ord x + ord dx − ord y` at infinity is `0` or more. -/

/-- Number of points at infinity on the smooth model of `y² = f(x)`, `deg f = n`. -/
def pointsAtInfinity (n : ℕ) : ℤ := if n % 2 = 1 then 1 else 2

/-- Order of `x^i dx/y` at (each) point at infinity of `y² = f(x)`, `deg f = n`. -/
def ordInfty (n i : ℕ) : ℤ :=
  if n % 2 = 1 then (i : ℤ) * (-2) + (-3) - (-(n : ℤ))
  else (i : ℤ) * (-1) + (-2) - (-((n : ℤ) / 2))

/-- The powers `i < n` for which `x^i dx/y` is holomorphic (order at infinity `0` or more). -/
def holomorphicPowers (n : ℕ) : Finset ℕ := (Finset.range n).filter (fun i => 0 ≤ ordInfty n i)

/-- Branch points of the two-to-one map `x`: the `n` roots of `f`, plus infinity when `n` is odd. -/
def branchPoints (n : ℕ) : ℕ := n + n % 2

/-- Degree of the canonical divisor `K = div(dx/y)`: all its zeros sit at infinity. -/
def degK (n : ℕ) : ℤ := pointsAtInfinity n * ordInfty n 0

/-- Helper: pairs `(i, j)` in `range k × range k` with `i + j < k`, counted twice: `k (k + 1)`. -/
theorem card_pairs_sum_lt_mul_two (k : ℕ) :
    ((Finset.range k ×ˢ Finset.range k).filter (fun p : ℕ × ℕ => p.1 + p.2 < k)).card * 2 =
      k * (k + 1) := by
  induction k with
  | zero => simp
  | succ k ih =>
    have hsplit : ((Finset.range (k + 1) ×ˢ Finset.range (k + 1)).filter
        (fun p : ℕ × ℕ => p.1 + p.2 < k + 1)) =
        ((Finset.range k ×ˢ Finset.range k).filter (fun p : ℕ × ℕ => p.1 + p.2 < k)) ∪
          Finset.antidiagonal k := by
      ext ⟨i, j⟩
      simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_range, Finset.mem_union,
        Finset.mem_antidiagonal]
      omega
    have hdisj : Disjoint
        ((Finset.range k ×ˢ Finset.range k).filter (fun p : ℕ × ℕ => p.1 + p.2 < k))
        (Finset.antidiagonal k) := by
      rw [Finset.disjoint_left]
      rintro ⟨i, j⟩ h1 h2
      simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_range,
        Finset.mem_antidiagonal] at h1 h2
      omega
    rw [hsplit, Finset.card_union_of_disjoint hdisj, Finset.Nat.card_antidiagonal, add_mul, ih]
    ring

#print axioms card_pairs_sum_lt_mul_two

/-- **The holomorphic differentials of `y² = f(x)`.** For a squarefree `f` of degree `n ≥ 1`,
the differentials `x^i dx/y` with no pole at infinity are exactly those with
`i = 0, 1, …, g − 1`, where `g = ⌊(n − 1)/2⌋`. This `g` is also the genus that Riemann-Hurwitz
gives for a double cover of the line with `n + (n mod 2)` branch points
(`2 − 2g = 2·2 − branch points`), and the canonical divisor `div(dx/y)` has degree `2g − 2`. -/
theorem holomorphic_differentials_eq_range_genus (n : ℕ) (hn : 1 ≤ n) :
    holomorphicPowers n = Finset.range ((n - 1) / 2) ∧
    (2 : ℤ) - 2 * (((n - 1) / 2 : ℕ) : ℤ) = 2 * 2 - (branchPoints n : ℤ) ∧
    degK n = 2 * (((n - 1) / 2 : ℕ) : ℤ) - 2 := by
  rcases Nat.even_or_odd' n with ⟨m, rfl | rfl⟩
  · -- even degree `n = 2m`, `m ≥ 1`
    have h2 : ¬ (2 * m) % 2 = 1 := by omega
    have h0 : (2 * m) % 2 = 0 := by omega
    refine ⟨?_, ?_, ?_⟩
    · ext i
      simp only [holomorphicPowers, ordInfty, h2, ↓reduceIte, Finset.mem_filter, Finset.mem_range]
      push_cast
      omega
    · simp only [branchPoints, h0]
      push_cast
      omega
    · simp only [degK, pointsAtInfinity, ordInfty, h2, ↓reduceIte]
      push_cast
      omega
  · -- odd degree `n = 2m + 1`
    have h2 : (2 * m + 1) % 2 = 1 := by omega
    refine ⟨?_, ?_, ?_⟩
    · ext i
      simp only [holomorphicPowers, ordInfty, h2, ↓reduceIte, Finset.mem_filter, Finset.mem_range]
      push_cast
      omega
    · simp only [branchPoints, h2]
      push_cast
      omega
    · simp only [degK, pointsAtInfinity, ordInfty, h2, ↓reduceIte]
      push_cast
      omega

/-! **Smooth plane curves of degree `d`** (the card's Fermat-quartic proof). On
`x^d + y^d = z^d`, in the chart `z = 1`, the curve has `d` points at infinity; at each, `x` and
`y` have simple poles and `dx` a double pole, so `x^i y^j dx/y^(d−1)` has order
`−i − j − 2 + (d − 1)` there. -/

/-- Order of `x^i y^j dx/y^(d−1)` at each of the `d` points at infinity of a smooth plane curve
of degree `d`. -/
def planeOrd (d i j : ℕ) : ℤ := -(i : ℤ) - j - 2 + ((d : ℤ) - 1)

/-- The exponent pairs `(i, j)` with `x^i y^j dx/y^(d−1)` holomorphic. -/
def planeDifferentials (d : ℕ) : Finset (ℕ × ℕ) :=
  (Finset.range d ×ˢ Finset.range d).filter (fun p => 0 ≤ planeOrd d p.1 p.2)

/-- **Differentials of a smooth plane curve.** On a smooth plane curve of degree `d ≥ 1` the
holomorphic differentials `x^i y^j dx/y^(d−1)` are those with `i + j ≤ d − 3`; there are
`(d − 1)(d − 2)/2` of them, the degree-genus formula, and `deg K = d·(d − 3) = 2g − 2`. -/
theorem plane_curve_differentials_card (d : ℕ) (hd : 1 ≤ d) :
    (∀ p ∈ planeDifferentials d, (p.1 : ℤ) + p.2 ≤ (d : ℤ) - 3) ∧
    ((planeDifferentials d).card : ℤ) = ((d : ℤ) - 1) * ((d : ℤ) - 2) / 2 ∧
    (d : ℤ) * planeOrd d 0 0 = 2 * (((d : ℤ) - 1) * ((d : ℤ) - 2) / 2) - 2 := by
  have hmem : ∀ p : ℕ × ℕ, p ∈ planeDifferentials d ↔
      p ∈ Finset.range d ×ˢ Finset.range d ∧ (p.1 : ℤ) + p.2 ≤ (d : ℤ) - 3 := by
    intro p
    unfold planeDifferentials
    rw [Finset.mem_filter]
    unfold planeOrd
    constructor
    · rintro ⟨h1, h2⟩
      exact ⟨h1, by omega⟩
    · rintro ⟨h1, h2⟩
      exact ⟨h1, by omega⟩
  refine ⟨fun p hp => ((hmem p).1 hp).2, ?_⟩
  obtain ⟨k, rfl⟩ | ⟨k, rfl⟩ : d = 1 ∨ ∃ k, d = k + 2 := by
    rcases d with _ | _ | k
    · omega
    · exact Or.inl rfl
    · exact Or.inr ⟨k, rfl⟩
  · have : planeDifferentials 1 = ∅ := by
      ext ⟨i, j⟩
      rw [hmem]
      simp only [Finset.mem_product, Finset.mem_range, Finset.notMem_empty, iff_false]
      push_cast
      omega
    rw [this]
    simp [planeOrd]
  · have heq : planeDifferentials (k + 2) =
        (Finset.range k ×ˢ Finset.range k).filter (fun p : ℕ × ℕ => p.1 + p.2 < k) := by
      ext ⟨i, j⟩
      rw [hmem]
      simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_range]
      push_cast
      omega
    have hc := card_pairs_sum_lt_mul_two k
    rw [← heq] at hc
    have hcz : ((planeDifferentials (k + 2)).card : ℤ) * 2 = (k : ℤ) * ((k : ℤ) + 1) := by
      exact_mod_cast hc
    have hprod : (((k + 2 : ℕ) : ℤ) - 1) * (((k + 2 : ℕ) : ℤ) - 2) =
        ((planeDifferentials (k + 2)).card : ℤ) * 2 := by
      rw [hcz]; push_cast; ring
    rw [hprod, Int.mul_ediv_cancel _ (by norm_num)]
    refine ⟨rfl, ?_⟩
    simp only [planeOrd]
    push_cast
    linear_combination (-1 : ℤ) * hcz

/-- The canonical map of a hyperelliptic curve of genus `g`, in the chart `u₀ = 1`:
`(x, y) ↦ (1 : x : x² : … : x^(g−1))`, the ratios of `dx/y, x dx/y, …, x^(g−1) dx/y`. -/
def canonicalMap {K : Type*} [Field K] (g : ℕ) (P : K × K) : Fin g → K :=
  fun k => P.1 ^ (k : ℕ)

/-- **The canonical map of a hyperelliptic curve folds.** Over a field where `2 ≠ 0`, let
`(x, y)` be a point of `y² = f(x)` with `y ≠ 0`. Its mirror `(x, −y)` is a different point of the
same curve, and the canonical map `(1 : x : … : x^(g−1))` sends both to the same place. Every
image point lies on the curve traced by `(1 : t : … : t^(g−1))`: `u_i u_j = u_k u_l` whenever
`i + j = k + l` (for `g = 3`, the conic `u₀ u₂ = u₁²`). -/
theorem canonical_map_joins_mirror_points {K : Type*} [Field K] (h2 : (2 : K) ≠ 0)
    (f : Polynomial K) (g : ℕ) (x y : K) (hP : y ^ 2 = f.eval x) (hy : y ≠ 0) :
    (-y) ^ 2 = f.eval x ∧ (x, -y) ≠ (x, y) ∧
    canonicalMap g (x, -y) = canonicalMap g (x, y) ∧
    ∀ i j k l : Fin g, (i : ℕ) + j = k + l →
      canonicalMap g (x, y) i * canonicalMap g (x, y) j =
        canonicalMap g (x, y) k * canonicalMap g (x, y) l := by
  refine ⟨by rw [neg_sq]; exact hP, ?_, rfl, ?_⟩
  · intro h
    have hyy : -y = y := (Prod.mk.inj h).2
    apply hy
    have h2y : (2 : K) * y = 0 := by linear_combination -hyy
    exact (mul_eq_zero.1 h2y).resolve_left h2
  · intro i j k l hijkl
    simp only [canonicalMap, ← pow_add, hijkl]

/-! The card's whole-number worked examples. -/

-- x⁵ + x + 1 = (x² + x + 1)(x³ − x² + 1).
example : ((Polynomial.X ^ 2 + Polynomial.X + 1) * (Polynomial.X ^ 3 - Polynomial.X ^ 2 + 1) :
    Polynomial ℤ) = Polynomial.X ^ 5 + Polynomial.X + 1 := by ring
-- Discriminant of x^n + x + 1 by the trinomial formula, n = 3 to 8: −31, 229, 3381, −43531,
-- −870199, 15953673, none zero.
example : [3, 4, 5, 6, 7, 8].map (fun n : ℕ =>
    (-1 : ℤ) ^ (n * (n - 1) / 2) * ((n : ℤ) ^ n + (-1) ^ (n - 1) * ((n : ℤ) - 1) ^ (n - 1))) =
    [-31, 229, 3381, -43531, -870199, 15953673] := by decide
-- n = 3 to 8: branch points 4, 4, 6, 6, 8, 8; differentials 1, 1, 2, 2, 3, 3; deg K 0, 0, 2, 2, 4, 4.
example : [3, 4, 5, 6, 7, 8].map branchPoints = [4, 4, 6, 6, 8, 8] := by decide
example : [3, 4, 5, 6, 7, 8].map (fun n => (holomorphicPowers n).card) = [1, 1, 2, 2, 3, 3] := by
  decide
example : [3, 4, 5, 6, 7, 8].map degK = [0, 0, 2, 2, 4, 4] := by decide
-- On y² = x⁵ + x + 1: x^i dx/y has order 2, 0, −2 at infinity for i = 0, 1, 2.
example : [0, 1, 2].map (ordInfty 5) = [2, 0, -2] := by decide
-- Mod 13: 14 affine points plus one at infinity make 15; f has roots x = 3 and x = 9.
example : (Finset.univ.filter (fun p : ZMod 13 × ZMod 13 =>
    p.2 ^ 2 = p.1 ^ 5 + p.1 + 1)).card + 1 = 15 := by decide
example : Finset.univ.filter (fun x : ZMod 13 => x ^ 5 + x + 1 = 0) = {3, 9} := by decide
-- Canonical image (1 : x) mod 13: 8 values of x plus the image of infinity, 9 points; the
-- 15 − 1 − 2 = 12 points off the branch points form 6 mirror pairs.
example : ((Finset.univ.filter (fun p : ZMod 13 × ZMod 13 =>
    p.2 ^ 2 = p.1 ^ 5 + p.1 + 1)).image Prod.fst).card + 1 = 9 := by decide
example : (15 - 1 - 2) / 2 = 6 := by norm_num
-- Fermat quartic x⁴ + y⁴ = z⁴ mod 13: 8 points with z = 1 and none at infinity.
example : (Finset.univ.filter (fun p : ZMod 13 × ZMod 13 => p.1 ^ 4 + p.2 ^ 4 = 1)).card = 8 := by
  decide
example : (Finset.univ.filter (fun y : ZMod 13 => 1 + y ^ 4 = 0)).card = 0 := by decide
example : 8 * (8 - 1) / 2 = 28 := by norm_num
-- y² = x⁷ + x + 1 mod 13: 21 points, canonical image 11 points, 10 mirror pairs.
example : (Finset.univ.filter (fun p : ZMod 13 × ZMod 13 =>
    p.2 ^ 2 = p.1 ^ 7 + p.1 + 1)).card + 1 = 21 := by decide
example : ((Finset.univ.filter (fun p : ZMod 13 × ZMod 13 =>
    p.2 ^ 2 = p.1 ^ 7 + p.1 + 1)).image Prod.fst).card + 1 = 11 := by decide
-- Fermat curves d = 3 to 6: 1, 3, 6, 10 differentials; deg K 0, 4, 10, 18.
example : [3, 4, 5, 6].map (fun d => (planeDifferentials d).card) = [1, 3, 6, 10] := by decide
example : [3, 4, 5, 6].map (fun d : ℕ => (d : ℤ) * planeOrd d 0 0) = [0, 4, 10, 18] := by decide
-- Mod 13²: s₁ = 13 + 1 − 15 = −1, s₂ = 169 + 1 − 177 = −7, e₂ = (s₁² − s₂)/2 = 4,
-- L(T) = 1 + T + 4T² + 13T³ + 169T⁴, L(1) = 188; genus 1 would give 169 + 1 − (s₁² − 26) = 195.
example : (13 : ℤ) + 1 - 15 = -1 ∧ (169 : ℤ) + 1 - 177 = -7 ∧ ((-1 : ℤ) ^ 2 - (-7)) / 2 = 4 ∧
    (1 : ℤ) + 1 + 4 + 13 + 169 = 188 ∧ (169 : ℤ) + 1 - ((-1) ^ 2 - 2 * 13) = 195 := by norm_num
-- What breaks: the plane genus formula on degree 5 gives (5 − 1)(5 − 2)/2 = 6, not 2.
example : (5 - 1) * (5 - 2) / 2 = 6 := by norm_num
-- The house curve y² = x²(x + 1) on its smooth model x = t² − 1, y = t(t² − 1).
example (t : ℚ) : (t * (t ^ 2 - 1)) ^ 2 = (t ^ 2 - 1) ^ 2 * ((t ^ 2 - 1) + 1) := by ring

#print axioms holomorphic_differentials_eq_range_genus
#print axioms plane_curve_differentials_card
#print axioms canonical_map_joins_mirror_points

end HyperellipticCanonical
