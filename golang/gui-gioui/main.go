package main

import (
	"fmt"
	"log"
	"os"
	"runtime"

	"gioui.org/app"
	"gioui.org/font/gofont"
	"gioui.org/layout"
	"gioui.org/op"
	"gioui.org/text"
	"gioui.org/unit"
	"gioui.org/widget"
	"gioui.org/widget/material"
)

func main() {
	go func() {
		w := new(app.Window)
		w.Option(app.Title("Memory Usage"), app.Size(unit.Dp(400), unit.Dp(200)))
		if err := run(w); err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	}()
	app.Main()
}

func run(w *app.Window) error {
	th := material.NewTheme()
	th.Shaper = text.NewShaper(text.WithCollection(gofont.Collection()))

	var ops op.Ops
	var button widget.Clickable
	memText := "Click the button to check memory usage"

	for {
		switch e := w.Event().(type) {
		case app.DestroyEvent:
			return e.Err
		case app.FrameEvent:
			gtx := app.NewContext(&ops, e)

			if button.Clicked(gtx) {
				var m runtime.MemStats
				runtime.ReadMemStats(&m)
				memText = fmt.Sprintf("Alloc: %.2f MiB  |  Sys: %.2f MiB",
					float64(m.Alloc)/1024/1024, float64(m.Sys)/1024/1024)
			}

			layout.Flex{Axis: layout.Vertical, Alignment: layout.Middle}.Layout(gtx,
				layout.Rigid(func(gtx layout.Context) layout.Dimensions {
					return layout.UniformInset(unit.Dp(20)).Layout(gtx, func(gtx layout.Context) layout.Dimensions {
						btn := material.Button(th, &button, "Check Memory")
						return btn.Layout(gtx)
					})
				}),
				layout.Rigid(func(gtx layout.Context) layout.Dimensions {
					lbl := material.Body1(th, memText)
					return lbl.Layout(gtx)
				}),
			)

			e.Frame(gtx.Ops)
		}
	}
}
