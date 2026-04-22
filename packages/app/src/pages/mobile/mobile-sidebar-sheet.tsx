import { type JSX } from "solid-js"
import { useMobileViewport } from "@/pages/mobile/use-mobile-viewport"

export function MobileSidebarSheet(props: {
  opened: boolean
  onClose: () => void
  children: JSX.Element
  top?: string
}) {
  const viewport = useMobileViewport()
  const top = () => props.top ?? "2.5rem"

  return (
    <>
      <div
        classList={{
          "fixed inset-x-0 z-40 transition-opacity duration-200": true,
          "opacity-100 pointer-events-auto": props.opened,
          "opacity-0 pointer-events-none": !props.opened,
        }}
        style={{
          top: top(),
          height: `calc(${viewport.viewportHeight()}px - ${top()})`,
        }}
        onClick={(e) => {
          if (e.target === e.currentTarget) props.onClose()
        }}
      />
      <div
        data-component="mobile-sidebar-sheet"
        classList={{
          "@container fixed left-0 z-50 w-full max-w-[400px] overflow-hidden border-r border-border-weaker-base bg-background-base transition-transform duration-200 ease-out":
            true,
          "translate-x-0": props.opened,
          "-translate-x-full": !props.opened,
        }}
        style={{
          top: top(),
          height: `calc(${viewport.viewportHeight()}px - ${top()})`,
          "padding-bottom": `calc(max(env(safe-area-inset-bottom), 0px) + ${viewport.keyboardInset()}px)`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {props.children}
      </div>
    </>
  )
}
