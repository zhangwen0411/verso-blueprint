/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import Lean
import SubVerso.Highlighting

open Lean Meta

namespace Informal

/-- Client-supplied source excerpt, without the declaration docstring.
`provenance` identifies the source revision or location for client freshness checks.
Blueprint does not read files or infer source from compiled declaration values. -/
structure ExternalDeclSource where
  code : SubVerso.Highlighting.Highlighted
  provenance : String
  docNotice? : Option String := none
  deriving Inhabited

initialize externalDeclSources :
    SimplePersistentEnvExtension (Name × ExternalDeclSource) (NameMap ExternalDeclSource) ←
  registerSimplePersistentEnvExtension {
    addEntryFn := fun sources (name, source) => sources.insert name source
    addImportedFn := fun imports => imports.foldl (fun sources entries =>
      entries.foldl (fun sources (name, source) => sources.insert name source) sources) {} }

/-- Look up source by canonical declaration name. -/
def externalDeclSource? (env : Environment) (decl : Name) : Option ExternalDeclSource :=
  (externalDeclSources.getState env).find? decl

/-- Register source before elaborating an association or taking a declaration snapshot.
The caller owns extraction and freshness checks. Theorems and proof-valued declarations
are rejected. Registrations are opt-in and do not affect unregistered declarations. -/
def registerExternalDeclSource (decl : Name) (source : ExternalDeclSource) : MetaM Unit := do
  let info ← getConstInfo decl
  if info matches .thmInfo _ then throwError "cannot register theorem source: {decl}"
  if ← isProp info.type then throwError "cannot register proof-valued source: {decl}"
  unless !source.code.toString.isEmpty && !source.provenance.isEmpty do
    throwError "empty declaration source or provenance: {decl}"
  if (externalDeclSource? (← getEnv) decl).isSome then
    throwError "duplicate declaration source: {decl}"
  modifyEnv fun env => externalDeclSources.addEntry env (decl, source)

end Informal
