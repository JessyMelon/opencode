import { makeEventListener } from "@solid-primitives/event-listener"
import { createMemo, onMount } from "solid-js"
import { createStore } from "solid-js/store"

export function useMobileViewport() {
  const [store, setStore] = createStore({
    windowHeight: typeof window === "undefined" ? 1000 : window.innerHeight,
    viewportHeight: typeof window === "undefined" ? 1000 : (window.visualViewport?.height ?? window.innerHeight),
  })

  onMount(() => {
    const sync = () => {
      setStore({
        windowHeight: window.innerHeight,
        viewportHeight: window.visualViewport?.height ?? window.innerHeight,
      })
    }

    sync()
    makeEventListener(window, "resize", sync)
    if (window.visualViewport) makeEventListener(window.visualViewport, "resize", sync)
  })

  const keyboardInset = createMemo(() => Math.max(0, Math.round(store.windowHeight - store.viewportHeight)))

  return {
    viewportHeight: createMemo(() => Math.round(store.viewportHeight)),
    keyboardInset,
  }
}
