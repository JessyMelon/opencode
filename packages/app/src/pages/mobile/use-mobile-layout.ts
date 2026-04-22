import { createMediaQuery } from "@solid-primitives/media"
import { createMemo } from "solid-js"

export function useMobileLayout() {
  const desktop = createMediaQuery("(min-width: 768px)")
  return createMemo(() => !desktop())
}
