/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import VersoBlueprint.ExternalDeclSource

namespace Verso.VersoBlueprintTests.ExternalDeclSourceProvider

/-- Documentation stays outside the registered source. -/
def value : Nat := 7

-- Deliberate proof-valued definition: the source registry must reject it.
set_option linter.defProp false in
def proofValue : True := trivial

opaque opaqueProof : True := trivial

run_elab do
  Informal.registerExternalDeclSource
    `Verso.VersoBlueprintTests.ExternalDeclSourceProvider.value {
      code := .text "def value : Nat := 7"
      provenance := "ExternalDeclSourceProvider.lean" }

end Verso.VersoBlueprintTests.ExternalDeclSourceProvider
